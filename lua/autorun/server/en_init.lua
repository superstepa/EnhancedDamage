print("Superstepa's enhanced damage addon initialized")
--[[
   Code is a mess, gotta fix
]]--
AddCSLuaFile()
EnhancedDamage = {}
EnhancedDamage.EntTable = {}

include "en_hitgroups.lua"
include "en_painsounds.lua"
include "en_models.lua"
include "en_functions.lua"

HITGROUP_NUTS = 98
HITGROUP_HAND = 99

function EnhancedDamage.debug_print(msg)
   if (GetConVar("enhanceddamage_debug"):GetBool()) and (msg ~= nil) then
      print("DEBUG: " .. msg)
   end
end

function EnhancedDamage.Initialize()
   EnhancedDamage.debug_print("Initialize hook")
   EnhancedDamage.EntTable = {}
   timer.Create("UpdateEntTable", 5, 0, function()
                   EnhancedDamage.EntTable = ents.GetAll()
   end)
end

function EnhancedDamage.Damage(ply,hitgroup,dmginfo)
   if (GetConVar("enhanceddamage_enabled"):GetBool()) then
      --Pseudo support for my sandbox teams addon
      if (ConVarExists("sandboxteams_npcdamage") and ply:Team() ~= 1 ) then return end
      if not dmginfo then EnhancedDamage.debug_print(hitgroup) return end
      local dmgpos = dmginfo:GetDamagePosition()

      local PelvisIndx = ply:LookupBone("ValveBiped.Bip01_Pelvis")
      if (PelvisIndx == nil) then return dmginfo end
      local PelvisPos = ply:GetBonePosition(PelvisIndx)
      local NutsDistance = dmgpos:Distance(PelvisPos)

      local LHandIndex = ply:LookupBone("ValveBiped.Bip01_L_Hand")
      local LHandPos = ply:GetBonePosition(LHandIndex)
      local LHandDistance = dmgpos:Distance(LHandPos)

      local RHandIndex = ply:LookupBone("ValveBiped.Bip01_R_Hand")
      local RHandPos = ply:GetBonePosition(RHandIndex)
      local RHandDistance = dmgpos:Distance(RHandPos)

      if (NutsDistance <= 7 and NutsDistance >= 5) then
         hitgroup = EnhancedDamage.HITGROUP_NUTS
      elseif (LHandDistance < 6 || RHandDistance < 6 ) then
         hitgroup = EnhancedDamage.HITGROUP_HAND
      end

      --The hitgroups are loaded from a en_hitgroups
      for k, v in pairs(EnhancedDamage.HitGroups) do
         if (hitgroup == k) then
            name = v["name"]
            command = "enhanceddamage_"..name.."damagescale"
            EnhancedDamage.debug_print(command)
            if (command ~= "enhanceddamage_genericdamagescale") then
               dmginfo:ScaleDamage(GetConVar(command):GetFloat())
            end
            EnhancedDamage.HurtSound(ply, v["name"])
            if (v["func"] ~= nil) then
               v["func"](ply)
            end
            return k
         end
      end


   end
end

function EnhancedDamage.ThinkDamage()
   for _, v in pairs(EnhancedDamage.EntTable) do
      if IsValid(v) and (v:IsPlayer() or v:IsNPC()) then
         if v:WaterLevel() == 3 then
            if v:IsOnFire() then
               v:Extinguish()
            end
            if v.drowning then
               if v.drowning < CurTime() and GetConVar("enhanceddamage_drowningdamage"):GetBool() then
                  local dmginfo = DamageInfo()
                  dmginfo:SetDamage(10)
                  dmginfo:SetDamageType(DMG_DROWN)
                  dmginfo:SetAttacker(game.GetWorld())
                  dmginfo:SetInflictor(game.GetWorld())
                  v:TakeDamageInfo(dmginfo)
                  v.drowning = CurTime()+1
               end
            else
               v.drowning = CurTime()+10
            end
         else
            v.drowning = nil
         end

         if not v:IsOnGround() and v:IsNPC() then
            if not table.HasValue(falldamageblacklist, v:GetClass()) and GetConVar("enhanceddamage_npcfalldamage") then
               v.lastvelocity = v:GetVelocity():Length()
            end
         elseif (v.lastvelocity or 0) > 500 then
            local dmginfo = DamageInfo()
            local damage = v.lastvelocity/10
            dmginfo:SetDamage(damage)
            dmginfo:SetDamageType(DMG_FALL)
            dmginfo:SetAttacker(game.GetWorld())
            dmginfo:SetInflictor(game.GetWorld())
            dmginfo:SetDamagePosition(v:GetPos())
            v:TakeDamageInfo(dmginfo)
            v.lastvelocity = 0
         end
      end
   end
end
function EnhancedDamage.CreateRagdoll (ply,attacker,dmginfo)
   if not (GetConVar("enhanceddamage_ragdolls"):GetBool()) then return end

   oldbody = ply:GetNetworkedEntity("body")
   if IsValid(oldbody) then oldbody:Remove() end

   if not IsValid(ply) then return end
   local rag = ents.Create("prop_ragdoll")

   rag.dmginfo = dmginfo
   if not IsValid(rag) then return nil end
   rag:SetPos(ply:GetPos())
   rag:SetModel(ply:GetModel())
   rag:SetAngles(ply:GetAngles())
   rag:SetColor(ply:GetColor())

   local bodygroup = EnhancedDamage.Get_Bodygroup(ply)
   if bodygroup then
      rag:SetBodygroup(bodygroup,1)
   end

   rag:Spawn()
   rag:Activate()
   rag.is_player = true
   rag.nick = ply:Nick()
   rag.dmgtype = dmginfo:GetDamageType()

   ply:AddDeaths( 1 ) --Changing the scores since we overrode that

   if ( attacker:IsValid() and attacker:IsPlayer() ) then
      if ( attacker == ply ) then
         attacker:AddFrags( -1 )
      else
         attacker:AddFrags( 1 )
      end
   end

   local num = rag:GetPhysicsObjectCount()-1
   local v = ply:GetVelocity()
   for i = 0, num do
      local bone = rag:GetPhysicsObjectNum(i)
      if IsValid(bone) then
         local bonepos,boneang = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))
         if bonepos and boneang then
            bone:SetPos(bonepos)
            bone:SetAngles(boneang)
         end
         bone:SetVelocity(v)
      end
   end


   ply:Spectate( OBS_MODE_CHASE )
   ply:SpectateEntity( rag )
   ply:SetNetworkedEntity("body",rag)

   if dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_DIRECT) or dmginfo:IsExplosionDamage()  then
      local burntime = 30
      rag:SetColor(Color( 0, 0, 0, 255 ))
      rag:Ignite(burntime,1)
      timer.Create( ply:Nick().."_burntimer", 1, math.random(1,10), function()
                       if IsValid(rag) then EnhancedDamage.HurtSound(ply, "burn", 25)  end
      end)
   end

   local autoremove = GetConVar("enhanceddamage_autoremoveragdolls"):GetInt()
   if autoremove ~= 0 then
      timer.Simple(autoremove, function()
                      if (IsValid(rag)) then rag:Remove() end
      end)
   end
   return rag
end

function EnhancedDamage.CleanCorpses(ply)
   oldbody = ply:GetNetworkedEntity("body")
   if IsValid(oldbody) then oldbody:Remove() end
end

weaponblacklist = {"gmod_tool","weapon_physgun","gmod_camera","arrest_stick",
                   "keys","pocket","weapon_ttt_unarmed","weapon_fists",
                   "weapon_keypadchecker"}

falldamageblacklist = {"npc_fastzombie",
                       "npc_headcrab","npc_headcrab_poison",
                       "npc_headcrab_black","npc_headcrab_fast", "npc_antlion",
                       "npc_pigeon","npc_seagull", "npc_crow"}

drownblacklist = {}

CreateConVar("enhanceddamage_enabled", 1, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable enhanced damage")

CreateConVar("enhanceddamage_headdamagescale", 3 , {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_armdamagescale", 0.50, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_legdamagescale",0.50, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_chestdamagescale", 1.25, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_stomachdamagescale",0.75, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_nutsdamagescale", 2, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")
CreateConVar("enhanceddamage_handdamagescale", 0.25, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")

CreateConVar("enhanceddamage_armdropchance",20, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"The weapon drop chance for arm")
CreateConVar("enhanceddamage_handdropchance", 40, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Change the scale for this bodypart")

CreateConVar("enhanceddamage_enablesounds", 1, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable the sounds when hurt ")

CreateConVar("enhanceddamage_legbreak", 1, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable leg breaking")
CreateConVar("enhanceddamage_npcweapondrop",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable weapon dropping for npcs (Really buggy)")
CreateConVar("enhanceddamage_falldamage",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable enhanced falldamage (Much more 'realistic' and breaks your bones)")

--CreateConVar("enhanceddamage_advanced_npcdamage",0,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE}, "Enable falldamge and drowning damage for NPC's (WARNING: VERY UNOPTIMZED)")
CreateConVar("enhanceddamage_npcfalldamage",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable falldamage for NPC. Only works if advanced_npcdamage is on")
CreateConVar("enhanceddamage_drowningdamage",1,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Toggle drowning.")


CreateConVar("enhanceddamage_ragdolls", 0 ,{FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Enable enhanced ragdolls.")
CreateConVar("enhanceddamage_autoremoveragdolls", 20, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_NOTIFY,FCVAR_ARCHIVE},"Time before the ragdolls are removed (0 for never)")

CreateConVar("enhanceddamage_debug", 0, {FCVAR_SERVER_CAN_EXECUTE,FCVAR_ARCHIVE},"Enable debug printouts")

hook.Add("ScalePlayerDamage","EnhancedPlayerDamage", EnhancedDamage.Damage)
hook.Add("ScaleNPCDamage","EnhancedNPCDamage", EnhancedDamage.Damage)
hook.Add("GetFallDamage","EnhancedFallDamage", EnhancedDamage.FallDamage)
hook.Add("DoPlayerDeath","CustomRagdoll", EnhancedDamage.CreateRagdoll)
hook.Add("PlayerDisconnected","CleanUp", EnhancedDamage.CleanCorpses)

hook.Add("Think","OtherDamage",EnhancedDamage.ThinkDamage)

hook.Add( "Initialize", "EnhancedDamageInit", EnhancedDamage.Initialize )
