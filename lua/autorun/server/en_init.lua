print("Superstepa's enhanced damage addon initialized")
--[[
  Code is a mess, gotta fix
  Todo:Stop having the same piece of code multiple times, thats a bad practice
]]--
AddCSLuaFile()
EnhancedDamage = {}
EnhancedDamage.EntTable = {}
include "en_hitgroups.lua"
include "en_painsounds.lua"
include "en_models.lua"

HITGROUP_NUTS = 98
HITGROUP_HAND = 99

function debug_print(msg)
  if (GetConVar("enhanceddamage_debug"):GetBool()) and (msg != nil) then
    print("DEBUG: " .. msg)
  end
end

function EnhancedDamage.Initialize()
  debug_print("Initialize hook")
  EnhancedDamage.EntTable = {}
  timer.Create("UpdateEntTable", 5, 0, function()
      EnhancedDamage.EntTable = ents.GetAll()
    end)
end

function EnhancedDamage.Damage(ply,hitgroup,dmginfo) --Gotta separate this into more functions
  if (GetConVar("enhanceddamage_enabled"):GetBool()) then
    if (ConVarExists("sandboxteams_npcdamage") and ply:Team() != 1 ) then return end --Pseudo support for my sandbox teams addon
    if !dmginfo then debug_print(hitgroup) return end
    local dmgpos = dmginfo:GetDamagePosition()

    local PelvisIndx = ply:LookupBone("ValveBiped.Bip01_Pelvis")
    if (PelvisIndx == nil) then return dmginfo end --Maybe Hitgroup still works, need testing
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
    for k, v in pairs(EnhancedDamage.HitGroups) do
      if (hitgroup == k) then
        name = v["name"]
        command = "enhanceddamage_"..name.."damagescale"
        debug_print(command)
        if (command != "enhanceddamage_genericdamagescale") then
            dmginfo:ScaleDamage(GetConVar(command):GetFloat())
        end
        EnhancedDamage.HurtSound(ply, v["name"])
        if (v["func"] != nil) then
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

function EnhancedDamage.FallDamage(ply,speed)
if  GetConVar("enhanceddamage_falldamage"):GetBool() then
  local damage = speed / 15
  if (damage > ply:Health() / 2 and damage < ply:Health()) then
    EnhancedDamage.BreakLeg(ply, 10)
  end
  return damage
else --Default valve falldamage calculations
  if GetConVarNumber("mp_falldamage") == 1 then
    speed = speed - 580
    return speed * (100/(1024-580))
  end
  return 10
end
end

function EnhancedDamage.BreakLeg(ply, duration)
  debug_print("Breaking leg for ")
  if !GetConVar("enhanceddamage_legbreak"):GetBool() then return end
  if (!duration) then duration = 5 end
  if !RUNSPEED and !WALKSPEED then
    RUNSPEED = ply:GetRunSpeed()
    WALKSPEED = ply:GetWalkSpeed()
  end

  if !ply.legshot then
    EnhancedDamage.HurtSound(ply, "leg")
    ply.legshot = true
    ply:SetRunSpeed(RUNSPEED/2)
    ply:SetWalkSpeed(WALKSPEED/2)
    timer.Simple(duration,function() ply:SetRunSpeed(RUNSPEED) ply:SetWalkSpeed(WALKSPEED) ply.legshot = false end)
  end
end

function EnhancedDamage.HurtSound(ply,zone,level)
  local SoundsEnabled = GetConVar("enhanceddamage_enablesounds"):GetBool()
  local voicetype = EnhancedDamage.GetVoiceType(ply)


  local location = nil
  local level = level or 75
  if !ply.hurttimer and SoundsEnabled then
      location = EnhancedDamage.PainSounds[EnhancedDamage.GetVoiceType(ply)][zone]

      if !(location) then
        location = EnhancedDamage.PainSounds[EnhancedDamage.GetVoiceType(ply)]["generic"]
      end
      if zone == "head" then
        location = EnhancedDamage.PainSounds["headshotsounds"]
      end
      local sound = table.Random(location)

      ply:EmitSound(sound, level)
  end
  ply.hurttimer = true
  timer.Simple(1, function() ply.hurttimer = false end)
end

function EnhancedDamage.DropWeapon(ply,chance,attacker)
  local chnc = math.random(1,100)
  if (chnc > chance) then
    if (ply:IsPlayer()) then
      if (table.HasValue(weaponblacklist,ply:GetActiveWeapon():GetClass() )) then return end --Exclude the blacklist stuff
      ply:ConCommand("-zoom")
      ply:DropWeapon(ply:GetActiveWeapon())
    else --if it's an npc
      if GetConVar("enhanceddamage_npcweapondrop"):GetBool() then
      local weapon = ply:GetActiveWeapon()
      if IsValid(weapon) then

        local newwep = ents.Create(weapon:GetClass())
        newwep:SetPos(ply:GetPos())
        newwep:Spawn()

        weapon:Remove()
        ply:ClearEnemyMemory()
        ply:SetNPCState(2)
        for _, v in pairs(EnhancedDamage.EntTable) do
            if (v:IsPlayer()) then
                ply:AddEntityRelationship(v, 2, 99) -- Attempt to make the npc run away from players
            end
        end
      end
    end
    end
  end
end

function EnhancedDamage.GetVoiceType(ply)
  debug_print("Model: " .. string.lower( ply:GetModel() ) )

  if (ply:IsPlayer()) then
    local clientvar = string.lower(ply:GetInfo("enhanceddamage_cl_voice"))
    if (clientvar !="" and clientvar != "default" && clientvar) then
      --Return the client variable only if it's not default
      return clientvar
    end
  end

  for k, v in pairs(EnhancedDamage.PlayerModels) do
    if table.HasValue(v, string.lower(ply:GetModel()) ) then
      --Return the name of the player group if it's found in any of the tables
      return k
    end
  end
  --If everything else fails, male is our default voice type
  debug_print("Going back to the default male voice")
  return "male"
end

function EnhancedDamage.Get_Bodygroup(ply)
  for i = 0, 10 do --Is there a better way to do this?
    if ply:GetBodygroup(i) == 1 then
      return i
    end
  end
end

function EnhancedDamage.CreateRagdoll (ply,attacker,dmginfo)
  if !(GetConVar("enhanceddamage_ragdolls"):GetBool()) then return end

  oldbody = ply:GetNetworkedEntity("body")
  if IsValid(oldbody) then oldbody:Remove() end

  if !IsValid(ply) then return end
  local rag = ents.Create("prop_ragdoll")

  rag.dmginfo = dmginfo
  if !IsValid(rag) then return nil end
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
    if autoremove != 0 then
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

weaponblacklist = {"gmod_tool","weapon_physgun","gmod_camera","arrest_stick","keys","pocket","weapon_ttt_unarmed","weapon_fists","weapon_keypadchecker"}

falldamageblacklist = {"npc_fastzombie","npc_headcrab","npc_headcrab_poison","npc_headcrab_black","npc_headcrab_fast","npc_antlion","npc_pigeon", "npc_seagull", "npc_crow"}

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
