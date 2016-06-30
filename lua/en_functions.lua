EnhancedDamage.Functions = {}


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
  if (chnc > (100 - chance) then
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
    if (clientvar !="" && clientvar != "default" && clientvar) then
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
