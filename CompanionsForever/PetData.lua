local _,F=...
-- Stable numeric IDs are also used by saved pets and the inspect protocol.
local D={};F.PetData=D
D.families={
  beast={hp=1,attack=1.08,armor=5,speed=12,ability="Savage Bite",effect="bite"},
  swift={hp=0.92,attack=1.02,armor=3,speed=18,ability="Flurry",effect="flurry"},
  guardian={hp=1.18,attack=0.9,armor=12,speed=7,ability="Iron Hide",effect="shield"},
  dragon={hp=1.05,attack=1,armor=7,speed=11,ability="Dragon Breath",effect="cleave"},
  nature={hp=1.08,attack=0.94,armor=6,speed=10,ability="Wild Growth",effect="renew"},
  elemental={hp=1,attack=1.04,armor=6,speed=10,ability="Elemental Nova",effect="cleave"},
  demon={hp=0.96,attack=1.12,armor=4,speed=13,ability="Fel Strike",effect="bite"},
  undead={hp=1.08,attack=0.96,armor=8,speed=8,ability="Life Drain",effect="drain"},
  mechanical={hp=1.06,attack=0.98,armor=10,speed=9,ability="Emergency Plating",effect="shield"},
}
local entries={
  {"Murloc","beast"},{"Whelp","dragon"},{"Wolf pup","beast"},{"Owl","swift"},
  {"Stonetusk Boar","guardian"},{"Barrens Lion","beast"},{"Stranglethorn Tiger","beast"},{"Dun Morogh Bear","guardian"},
  {"Winterspring Frostsaber","swift"},{"Ashenvale Stag","nature"},{"Mulgore Plainstrider","swift"},{"Stranglethorn Raptor","beast"},
  {"Barrens Hyena","beast"},{"Duskwood Spider","swift"},{"Redridge Condor","swift"},{"Swamp Crocolisk","guardian"},
  {"Scorpid Terror","guardian"},{"Stone Maw Basilisk","guardian"},{"Un'Goro Devilsaur","beast"},{"Felwood Felhound","demon"},
  {"Elwynn Sheep","nature"},{"Westfall Chicken","swift"},{"Wild Ram","guardian"},{"Mulgore Prairie Dog","swift"},
  {"Teldrassil Nightsaber","swift"},{"Duskbat","swift"},{"Plaguehound","undead"},{"Darkshore Moonstalker","beast"},
  {"Wetlands Raptor","beast"},{"Hinterlands Owl","swift"},{"Feralas Hippogryph","nature"},{"Chimaera Matriarch","dragon"},
  {"Silithid Beetle","guardian"},{"Un'Goro Pterrordax","swift"},{"Snapjaw","guardian"},{"Mulgore Kodo","guardian"},
  {"Azure Whelpling","dragon"},{"Crimson Whelpling","dragon"},{"Emerald Whelpling","dragon"},{"Bronze Whelpling","dragon"},
  {"Dark Whelpling","dragon"},{"Sprite Darter","nature"},{"Faerie Dragon","dragon"},{"Moonkin","nature"},
  {"Treant","nature"},{"Ancient Protector","guardian"},{"Water Elemental","elemental"},{"Fire Elemental","elemental"},
  {"Earth Elemental","guardian"},{"Air Elemental","swift"},{"Arcane Elemental","elemental"},{"Mana Wyrm","elemental"},
  {"Gnoll","beast"},{"Kobold","guardian"},{"Furbolg","nature"},{"Quilboar","guardian"},
  {"Trogg","guardian"},{"Ogre","guardian"},{"Satyr","demon"},{"Imp","demon"},
  {"Voidwalker","guardian"},{"Succubus","demon"},{"Felguard","demon"},{"Doomguard","demon"},
  {"Infernal","elemental"},{"Gargoyle","undead"},{"Ghoul","undead"},{"Abomination","undead"},
  {"Naga Myrmidon","guardian"},{"Naga Siren","elemental"},{"Murloc Tidehunter","beast"},{"Dark Iron Hound","beast"},
  {"Core Hound","beast"},{"Lava Spider","swift"},{"Fire Beetle","elemental"},{"Silithid Wasp","swift"},
  {"Silithid Ravager","beast"},{"Sandfury Serpent","swift"},{"Bloodscalp Raptor","beast"},{"Zandalari Raptor","beast"},
  {"Pandaren Cub","nature"},{"Mechanical Squirrel","mechanical"},{"Clockwork Gnome","mechanical"},{"Walking Bombling","mechanical"},
  {"Ragnaros","elemental"},{"Onyxia","dragon"},{"Nefarian","dragon"},{"C'Thun","elemental"},
  {"Kel'Thuzad","undead"},{"Hakkar","undead"},{"Ossirian the Unscarred","guardian"},{"Lucifron","demon"},
  {"Magmadar","beast"},{"Gehennas","demon"},{"Garr","guardian"},{"Baron Geddon","elemental"},
  {"Shazzrah","elemental"},{"Sulfuron Harbinger","guardian"},{"Golemagg the Incinerator","guardian"},{"Majordomo Executus","demon"},
}
D.species={};D.names={};D.bosses={}
-- Search compatibility only: old regional labels must not imply farm locations.
D.nameAliases={[5]="Durotar Boar",[12]="Durotar Raptor",[17]="Desolace Scorpid",
  [18]="Tanaris Basilisk",[23]="Dun Morogh Ram",[26]="Silverpine Bat",
  [27]="Tirisfal Plaguehound",[32]="Azshara Chimaera",[35]="Loch Modan Turtle"}
for id,entry in ipairs(entries)do
  D.names[id]=entry[1]
  D.species[id]={name=entry[1],family=entry[2],raid=id>=85,atlas=id<=4 and 0 or math.floor((id-5)/16)+1,cell=id<=4 and id-1 or (id-5)%16}
  if id>=85 then D.bosses[entry[1]]=id end
end
D.packs={
  {name="Traveler's Adoption Crate",cost=100,odds={80,20,0,0,0},icon="INV_Crate_01"},
  {name="Scout's Adoption Crate",cost=200,odds={50,35,13,2,0},icon="INV_Crate_01"},
  {name="Adventurer's Adoption Crate",cost=400,odds={0,70,23,7,0},icon="INV_Crate_01"},
  {name="Veteran's Adoption Crate",cost=800,odds={0,55,32,12,1},icon="INV_Crate_01"},
  {name="Champion's Adoption Crate",cost=1600,odds={0,35,40,22,3},icon="INV_Crate_01"},
  {name="Azeroth's Adoption Crate",cost=3200,odds={0,15,45,33,7},icon="INV_Crate_01"},
}
