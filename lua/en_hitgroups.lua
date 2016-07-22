EnhancedDamage.HITGROUP_NUTS = 98
EnhancedDamage.HITGROUP_HAND = 99

EnhancedDamage.HitGroups =  {}
EnhancedDamage.HitGroups[HITGROUP_HEAD] = {
   name="head",
   func= nil,
}

EnhancedDamage.HitGroups[HITGROUP_LEFTARM] = {
   name="arm",
   func = function(ply)
      EnhancedDamage.DropWeapon(
         ply,100 - GetConVar("enhanceddamage_armdropchance"):GetInt())
   end
}

EnhancedDamage.HitGroups[HITGROUP_RIGHTARM] = {
   name = "arm",
   func = function(ply)
      EnhancedDamage.DropWeapon(
         ply,100 -GetConVar("enhanceddamage_armdropchance"):GetInt())
   end
}

EnhancedDamage.HitGroups[HITGROUP_CHEST] = {
   name = "generic",
   func = nil
}

EnhancedDamage.HitGroups[HITGROUP_STOMACH] = {
   name = "stomach",
   func = nil
}

EnhancedDamage.HitGroups[HITGROUP_LEFTLEG] = {
   name="leg",
   func=function(ply)
      if (ply:IsPlayer()) then
         EnhancedDamage.BreakLeg(ply,5)
      end
   end
}

EnhancedDamage.HitGroups[HITGROUP_RIGHTLEG] = {
   name="leg",
   func=function(ply)
      if (ply:IsPlayer()) then
         EnhancedDamage.BreakLeg(ply,5)
      end
   end
}

EnhancedDamage.HitGroups[EnhancedDamage.HITGROUP_NUTS] = {
   name="nuts",
   func = function(ply)
      local SoundsEnabled = GetConVar("enhanceddamage_enablesounds"):GetBool()
      if ((EnhancedDamage.GetVoiceType(ply) != "female") and SoundsEnabled) then
         local sound = Sound("vo/npc/male01/ow01.wav")

         --Very high pitch "OW"
         ply:EmitSound(sound,100,125)
      end
   end
}

EnhancedDamage.HitGroups[EnhancedDamage.HITGROUP_HAND] = {
   name="arm",
   func = function(ply, dmginfo)
      EnhancedDamage.DropWeapon(
         ply,GetConVar("enhanceddamage_handdropchance"):GetInt())
   end
}
