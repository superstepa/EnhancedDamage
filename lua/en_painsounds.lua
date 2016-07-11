EnhancedDamage.PainSounds = {}
EnhancedDamage.PainSounds['headshotsounds'] = {
  Sound("physics/flesh/flesh_squishy_impact_hard1.wav"),
  Sound("physics/flesh/flesh_squishy_impact_hard2.wav"),
  Sound("physics/flesh/flesh_squishy_impact_hard3.wav"),
  Sound("physics/flesh/flesh_squishy_impact_hard4.wav")}

EnhancedDamage.PainSounds['male'] = {
  ['generic'] = {Sound("vo/npc/male01/pain01.wav"),
      Sound("vo/npc/male01/pain02.wav"),
      Sound("vo/npc/male01/pain03.wav"),
      Sound("vo/npc/male01/pain04.wav"),
      Sound("vo/npc/male01/pain05.wav"),
      Sound("vo/npc/male01/pain06.wav"),
      Sound("vo/npc/male01/pain07.wav"),
      Sound("vo/npc/male01/pain08.wav"),
      Sound("vo/npc/male01/pain09.wav"),
      Sound("vo/ravenholm/monk_pain01"),
      Sound("vo/ravenholm/monk_pain02"),
      Sound("vo/ravenholm/monk_pain03"),
      Sound("vo/ravenholm/monk_pain04"),
      Sound("vo/ravenholm/monk_pain05"),
      Sound("vo/ravenholm/monk_pain06"),
      Sound("vo/ravenholm/monk_pain07"),
      Sound("vo/ravenholm/monk_pain08"),
      Sound("vo/ravenholm/monk_pain09"),
      Sound("vo/ravenholm/monk_pain10"),
      Sound("vo/ravenholm/monk_pain12"),
      Sound("vo/npc/male01/moan01.wav"),
      Sound("vo/npc/male01/moan02.wav"),
      Sound("vo/npc/male01/moan03.wav"),
      Sound("vo/npc/male01/moan04.wav"),
      Sound("vo/npc/male01/moan05.wav"),},
  ['burn'] ={
    Sound("player/pl_burnpain1.wav"),
    Sound("player/pl_burnpain2.wav"),
    Sound("player/pl_burnpain3.wav")},
  ['arm'] = {Sound("vo/npc/male01/myarm01.wav"),
             Sound("vo/npc/male01/myarm02.wav")},
  ['leg'] = {Sound("vo/npc/male01/myleg01.wav"),
             Sound("vo/npc/male01/myleg02.wav")},
  ['gut'] = {Sound("vo/npc/male01/mygut02.wav"),
             Sound("vo/npc/male01/hitingut01.wav"),
             Sound("vo/npc/male01/hitingut02.wav")}
  }
EnhancedDamage.PainSounds['female'] = {
  ['generic'] =
    {Sound("vo/npc/female01/pain01.wav"),
    Sound("vo/npc/female01/pain02.wav"),
    Sound("vo/npc/female01/pain03.wav"),
    Sound("vo/npc/female01/pain04.wav"),
    Sound("vo/npc/female01/pain05.wav"),
    Sound("vo/npc/female01/pain06.wav"),
    Sound("vo/npc/female01/pain07.wav"),
    Sound("vo/npc/female01/pain08.wav"),
    Sound("vo/npc/female01/pain09.wav"),
    Sound("vo/npc/female01/moan01.wav"),
    Sound("vo/npc/female01/moan02.wav"),
    Sound("vo/npc/female01/moan03.wav"),
    Sound("vo/npc/female01/moan04.wav"),
    Sound("vo/npc/female01/moan05.wav")},
  ['arm'] = {Sound("vo/npc/female01/myarm01.wav"),
             Sound("vo/npc/female01/myarm02.wav")},
  ['leg'] = {Sound("vo/npc/female01/myleg01.wav"),
             Sound("vo/npc/female01/myleg02.wav")},
  ['gut'] = {Sound("vo/npc/female01/mygut02.wav"),
             Sound("vo/npc/female01/hitingut01.wav"),
             Sound("vo/npc/female01/hitingut02.wav")}
}


EnhancedDamage.PainSounds['zombie'] = {}
EnhancedDamage.PainSounds['zombie']['generic'] = {Sound("npc/zombie/pain1"),
  Sound("npc/zombie/pain2"),
  Sound("npc/zombie/pain3"),
  Sound("npc/zombie/pain4"),
  Sound("npc/zombie/pain5"),
  Sound("npc/zombie/pain6"),
  Sound("npc/zombie/die1"),
  Sound("npc/zombie/die2"),
  Sound("npc/zombie/die3"),
  Sound("npc/zombie_poison/pz_pain1"),
  Sound("npc/zombie_poison/pz_pain2"),
  Sound("npc/zombie_poison/pz_pain3"),
  Sound("npc/zombie_poison/pz_die3")
}

EnhancedDamage.PainSounds['combine'] = {}
EnhancedDamage.PainSounds['combine']['generic'] =
{
  Sound("npc/combine_soldier/pain1.wav"),
  Sound("npc/combine_soldier/pain2.wav"),
  Sound("npc/combine_soldier/pain3.wav"),
  Sound("npc/metropolice/pain1.wav"),
  Sound("npc/metropolice/pain2.wav"),
  Sound("npc/metropolice/pain3.wav"),
  Sound("npc/metropolice/pain4.wav")
}
