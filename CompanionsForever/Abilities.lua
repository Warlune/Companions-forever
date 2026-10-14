local _,F=...
local P=F.Pets
-- Stable IDs: existing companions keep their learned abilities.
P.specialAbilities[#P.specialAbilities+1]={ability="Rending Bite",effect="bite",power=1.9,healing=0,icon="Ability_Druid_Rake"}
P.specialAbilities[#P.specialAbilities+1]={ability="Crushing Jaw",effect="bite",power=2.0,healing=0,icon="Ability_Druid_FerociousBite"}
P.specialAbilities[#P.specialAbilities+1]={ability="Lunging Strike",effect="bite",power=1.7,healing=0,icon="Ability_Hunter_Pet_Wolf"}
P.specialAbilities[#P.specialAbilities+1]={ability="Horn Gore",effect="bite",power=1.85,healing=0,icon="Ability_Hunter_Pet_Boar"}
P.specialAbilities[#P.specialAbilities+1]={ability="Stonebreaker",effect="bite",power=1.95,healing=0,icon="Ability_Warrior_SavageBlow"}
P.specialAbilities[#P.specialAbilities+1]={ability="Quick Claws",effect="flurry",power=1.55,healing=0,icon="Ability_GhoulFrenzy"}
P.specialAbilities[#P.specialAbilities+1]={ability="Tail Lash",effect="flurry",power=1.7,healing=0,icon="Ability_Hunter_Pet_Raptor"}
P.specialAbilities[#P.specialAbilities+1]={ability="Wing Buffet",effect="flurry",power=1.6,healing=0,icon="Ability_Hunter_Pet_Bat"}
P.specialAbilities[#P.specialAbilities+1]={ability="Pouncing Fury",effect="flurry",power=1.8,healing=0,icon="Ability_Druid_Ravage"}
P.specialAbilities[#P.specialAbilities+1]={ability="Mechanical Barrage",effect="flurry",power=1.75,healing=0,icon="INV_Gizmo_02"}
P.specialAbilities[#P.specialAbilities+1]={ability="Frost Burst",effect="cleave",power=0.85,healing=0,icon="Spell_Frost_FrostNova"}
P.specialAbilities[#P.specialAbilities+1]={ability="Flame Wave",effect="cleave",power=0.95,healing=0,icon="Spell_Fire_Fire"}
P.specialAbilities[#P.specialAbilities+1]={ability="Thunder Clap",effect="cleave",power=0.8,healing=0,icon="Spell_Nature_ThunderClap"}
P.specialAbilities[#P.specialAbilities+1]={ability="Shadow Pulse",effect="cleave",power=1.0,healing=0,icon="Spell_Shadow_ShadowBolt"}
P.specialAbilities[#P.specialAbilities+1]={ability="Arcane Burst",effect="cleave",power=0.9,healing=0,icon="Spell_Arcane_ArcaneTorrent"}
P.specialAbilities[#P.specialAbilities+1]={ability="Rejuvenating Song",effect="renew",power=0.6,healing=0.22,icon="Spell_Nature_Rejuvenation"}
P.specialAbilities[#P.specialAbilities+1]={ability="Mending Roots",effect="renew",power=0.9,healing=0.16,icon="Spell_Nature_ResistNature"}
P.specialAbilities[#P.specialAbilities+1]={ability="Soothing Mist",effect="renew",power=0.7,healing=0.2,icon="Spell_Nature_HealingWaveGreater"}
P.specialAbilities[#P.specialAbilities+1]={ability="Renewing Light",effect="renew",power=0.8,healing=0.19,icon="Spell_Holy_FlashHeal"}
P.specialAbilities[#P.specialAbilities+1]={ability="Self Repair",effect="renew",power=0.5,healing=0.24,icon="INV_Gizmo_02"}
P.specialAbilities[#P.specialAbilities+1]={ability="Vampiric Bite",effect="drain",power=1.2,healing=0.5,icon="Spell_Shadow_LifeDrain02"}
P.specialAbilities[#P.specialAbilities+1]={ability="Soul Sip",effect="drain",power=0.9,healing=0.75,icon="Spell_Shadow_SiphonMana"}
P.specialAbilities[#P.specialAbilities+1]={ability="Leeching Claws",effect="drain",power=1.15,healing=0.55,icon="Spell_Shadow_LifeDrain"}
P.specialAbilities[#P.specialAbilities+1]={ability="Essence Drain",effect="drain",power=1.0,healing=0.65,icon="Spell_Shadow_SiphonMana"}
P.specialAbilities[#P.specialAbilities+1]={ability="Blood Feast",effect="drain",power=1.3,healing=0.45,icon="Ability_Druid_FerociousBite"}
P.specialAbilities[#P.specialAbilities+1]={ability="Shell Guard",effect="shield",power=0.8,reduction=0.6,icon="Ability_Hunter_Pet_Turtle"}
P.specialAbilities[#P.specialAbilities+1]={ability="Barkskin",effect="shield",power=1.1,reduction=0.5,icon="Spell_Nature_StoneClawTotem"}
P.specialAbilities[#P.specialAbilities+1]={ability="Stone Hide",effect="shield",power=0.7,reduction=0.65,icon="Spell_Nature_StoneSkinTotem"}
P.specialAbilities[#P.specialAbilities+1]={ability="Shadow Veil",effect="shield",power=1.2,reduction=0.45,icon="Spell_Shadow_DetectInvisibility"}
P.specialAbilities[#P.specialAbilities+1]={ability="Crystal Carapace",effect="shield",power=0.9,reduction=0.58,icon="Spell_Frost_FrostArmor02"}
P.specialAbilities[#P.specialAbilities+1]={ability="Frost Nova",effect="cleave",control="freeze",power=.45,healing=0,icon="Spell_Frost_FrostNova"}
P.specialAbilities[#P.specialAbilities+1]={ability="Hammer of Justice",effect="bite",control="stun",power=.7,healing=0,icon="Spell_Holy_SealOfMight"}
-- Append-only IDs: hard unlock expands new-pet rolls without rerolling owned pets.
P.hardAbilityCatalog=true
local hardAbilities={
 {"Rift Fang","bite",2.05,0,"Ability_Druid_FerociousBite"},
 {"Titan's Bite","bite",2.15,0,"Ability_Hunter_Pet_Devilsaur"},
 {"Sundering Horn","bite",2.1,0,"Ability_Hunter_Pet_Boar"},
 {"Tempest Claws","flurry",1.85,0,"Ability_Druid_Rake"},
 {"Astral Barrage","flurry",1.9,0,"Spell_Arcane_ArcaneTorrent"},
 {"Void Pounce","flurry",1.95,0,"Ability_Druid_Ravage"},
 {"Starfall Pulse","cleave",1.05,0,"Spell_Arcane_StarFire"},
 {"Volcanic Roar","cleave",1.1,0,"Spell_Fire_Fire"},
 {"Glacial Ring","cleave",.5,0,"Spell_Frost_FrostNova","freeze"},
 {"Dream Renewal","renew",.75,.24,"Spell_Nature_Rejuvenation"},
 {"Phoenix Mend","renew",.65,.26,"Spell_Holy_Renew"},
 {"Ancient Regrowth","renew",1,.2,"Spell_Nature_ResistNature"},
 {"Abyssal Siphon","drain",1.2,.7,"Spell_Shadow_SiphonMana"},
 {"Blood Moon Bite","drain",1.4,.55,"Spell_Shadow_LifeDrain02"},
 {"Soul Harvest","drain",1.05,.85,"Spell_Shadow_LifeDrain"},
 {"Obsidian Shell","shield",.9,0,"Ability_Hunter_Pet_Turtle",nil,.65},
 {"Astral Ward","shield",1.2,0,"Spell_Holy_PowerWordShield",nil,.55},
 {"Titan's Verdict","bite",.85,0,"Spell_Holy_SealOfMight","stun"},
}
for _,a in ipairs(hardAbilities)do
 P.specialAbilities[#P.specialAbilities+1]={ability=a[1],effect=a[2],power=a[3],healing=a[4],icon=a[5],control=a[6],reduction=a[7],hardOnly=true,hidden=true}
end
function P.CanRollAbility(id)
 local a=P.specialAbilities[id]
 return a and (not a.hardOnly or P.HardMode and P.HardMode.IsUnlocked())
end
local original=P.AbilityHelp
function P.AbilityHelp(value)
  if type(value)~="table"then return original(value)end
  local a=value;if not a.power then return original(a.effect)end
  local detail=string.format("%.0f%% attack damage%s.",a.power*100,a.effect=="cleave" and " to each enemy" or "")
  if a.effect=="renew"then detail=detail..string.format(" Restore %.0f%% maximum health.",a.healing*100)
  elseif a.effect=="drain"then detail=detail..string.format(" Heal for %.0f%% of damage dealt.",a.healing*100)
  elseif a.effect=="shield"then detail=detail..string.format(" Reduce incoming hits by %.0f%% during defense.",a.reduction*100)end
  if a.control then detail=detail..(a.control=="stun" and " Stuns the target for one action." or " Freezes enemies for one action.").." Brief control immunity afterward." end
  return detail.." Own "..(a.cooldown or 3).."-turn cooldown. One special per pet per turn."..(P.IsHealingAbility(a) and " Select its special button to use it next turn." or "")
end
