local _,F=...
local P=F.Pets
P.sparklyCatalog=true
P.sparklyRandom=math.random -- Independent from combat, rarity and stat rolls.
local achievementPets={}
for _,d in pairs(F.Achievements and F.Achievements.byID or {})do
  if d.pet then achievementPets[d.pet]=true end
end
-- Version 2 has exactly the same fixed numeric roll payload as version 1.
-- Its prefix records the cosmetic variant, covered by the existing asset hash.
function P.IsSparkly(pet)
  return type(pet)=="table" and type(pet.rolls)=="string" and pet.rolls:sub(1,1)=="2" and P.DecodePetRolls(pet)~=nil
end
local roll=P.RollNewPet
function P.RollNewPet(pet)
  if pet.rolls then return end
  roll(pet)
  if not achievementPets[pet.species] and pet.source~="Free recovery crate" and P.sparklyRandom(1,1000)==1 then pet.rolls="2"..pet.rolls:sub(2)end
end
local name=P.PetName
function P.PetName(pet)return (P.IsSparkly(pet) and "Sparkly " or "")..name(pet)end
local specialty=P.Specialty
function P.Specialty(pet)
  return specialty(pet)..(P.IsSparkly(pet) and "\n|cffb4efffSparkly: rare cosmetic variant.|r" or "")
end
-- Portraits retain rarity borders. A separate star identifies the cosmetic.
function P.StyleSparklyPortrait(art,pet)
  local sparkly=P.IsSparkly(pet) or (pet and pet.sparklyDiscovered==true)
  local star=rawget(art,"cfSparklyStar")
  if sparkly and not star then
    star=art:GetParent():CreateTexture(nil,"OVERLAY",nil,5);art.cfSparklyStar=star
    star:SetTexture(166961);star:SetBlendMode("ADD");star:SetVertexColor(.7,.94,1)
    star:SetSize(18,18);star:SetPoint("TOPRIGHT",art,"TOPRIGHT",-1,-1)
  end
  if star then star:SetShown(not not sparkly)end
end
-- Hand-picked native skins, with the same underlying model and animation rig.
-- No desaturation or colored lighting: gray remains reserved for dead pets.
-- Source and texture-pair audit: data/sparkly-palettes.json.
P.sparklySkins={
  [145]=937, -- Furbolg
  [175]=489, -- Gnoll
  [229]=237, -- Horse
  [236]=229, -- Old Blanchy
  [304]=589, -- Westfall Chicken
  [320]=10054, -- Stranglethorn Tiger
  [321]=3030, -- Darkshore Moonstalker
  [328]=1560, -- Rabbit
  [368]=4456, -- Darkwidow
  [415]=597, -- Ogre
  [453]=11710, -- Earth Elemental
  [490]=388, -- Redridge Condor
  [503]=381, -- Stonetusk Boar
  [527]=391, -- Murloc
  [606]=976, -- Trogg
  [719]=1006, -- Dun Morogh Bear
  [788]=677, -- Stranglethorn Raptor
  [807]=833, -- Swamp Crocolisk
  [828]=569, -- Ghoul
  [855]=643, -- Moon Moon
  [856]=857, -- Elwynn Sheep
  [857]=856, -- Black Sheep
  [864]=2451, -- Treant
  [901]=6296, -- Toad
  [903]=643, -- Wolf pup
  [955]=30, -- Duskwood Spider
  [960]=1959, -- Wetlands Raptor
  [1100]=780, -- Faithful Dog
  [1141]=1418, -- Black Rat
  [1206]=2956, -- Snake
  [1219]=1281, -- Mulgore Plainstrider
  [1244]=5126, -- Snapjaw
  [1405]=9449, -- Fire Elemental
  [1418]=2176, -- Dig Rat
  [1451]=179, -- Mulgore Kodo
  [1547]=2237, -- Gazelle
  [1560]=6302, -- Hare
  [1693]=10006, -- Abomination
  [1912]=68, -- Doomguard
  [1924]=6295, -- Biletoad
  [1938]=981, -- Ironclad Crab
  [1967]=6078, -- Quilboar
  [1973]=4424, -- Barrens Lion
  [1986]=1206, -- Adder
  [1991]=8013, -- Ashenvale Stag
  [1995]=391, -- Murloc Tidehunter
  [2010]=467, -- Satyr
  [2176]=1141, -- Whiskers the Rat
  [2429]=1921, -- Ancient Protector
  [2491]=2730, -- Scorpid Terror
  [2536]=15937, -- Spider
  [2710]=2713, -- Barrens Hyena
  [2736]=2785, -- Riding Ram
  [2954]=2955, -- King Snake
  [2955]=1986, -- Albino Snake
  [2956]=6303, -- Water Snake
  [2957]=2954, -- Brown Snake
  [2958]=1987, -- Jungle Boa
  [3194]=11086, -- Silithid Wasp
  [3210]=10891, -- Feralas Hippogryph
  [3248]=388, -- Condor Hatchling
  [4162]=2737, -- Succubus
  [4440]=2957, -- Zooey Snake
  [4449]=7552, -- Imp
  [4457]=336, -- Lava Spider
  [4615]=6298, -- Great Horned Owl
  [4626]=6302, -- The Evil Rabbit
  [4732]=4735, -- Duskbat
  [4959]=2176, -- Mouse
  [4960]=1141, -- Highlands Mouse
  [5187]=5327, -- Gust of Cyclarus
  [5207]=6192, -- Green Wing Macaw
  [5239]=5240, -- Un'Goro Devilsaur
  [5369]=14942, -- Ancona Chicken
  [5379]=6296, -- Huge Toad
  [5448]=5554, -- Black Tabby
  [5554]=5585, -- Orange Tabby
  [5555]=5448, -- Silver Tabby
  [5556]=5586, -- Effsee
  [5557]=979, -- Crab
  [5560]=981, -- Lava Crab
  [5585]=5556, -- Cat
  [5586]=9989, -- Cornish Rex
  [5927]=12238, -- Moonkin
  [5966]=4312, -- Sandfury Serpent
  [6190]=6189, -- Senegal
  [6191]=5207, -- Cockatiel
  [6192]=5865, -- Hyacinth Macaw
  [6193]=304, -- Wild Chicken
  [6288]=505, -- Dark Whelpling
  [6290]=6293, -- Whelp
  [6291]=6292, -- Emerald Whelpling
  [6292]=10095, -- Bronze Whelpling
  [6293]=621, -- Azure Whelpling
  [6295]=6297, -- Tree Frog
  [6296]=1924, -- Musical Gustjumper
  [6297]=901, -- Frog
  [6298]=6299, -- Snowy Owl
  [6299]=6212, -- Hawk Owl
  [6300]=4615, -- Crested Owl
  [6302]=328, -- Spring Rabbit
  [6303]=2958, -- Crimson Snake
  [6747]=4036, -- Naga Myrmidon
  [6805]=616, -- Teldrassil Nightsaber
  [7511]=11093, -- Silithid Beetle
  [7533]=7854, -- Gargoyle
  [7763]=8573, -- Plagued Slime
  [7891]=8180, -- Plaguehound
  [8180]=3916, -- Dark Iron Hound
  [8409]=9449, -- Searing Scorchling
  [8411]=8412, -- Un'Goro Pterrordax
  [8714]=5327, -- Air Elemental
  [8816]=5865, -- Parrot
  [8910]=14379, -- Lil' Smoky
  [8971]=11107, -- Fire Beetle
  [9563]=9370, -- Worg Pup
  [9758]=3004, -- Crypt Fiend
  [9829]=963, -- Dusk Spiderling
  [9903]=8183, -- Plagued Maggot
  [9904]=7572, -- Maggot
  [9905]=9906, -- Mr. Grubbs
  [9906]=7571, -- Larva
  [9953]=320, -- Winterspring Frostsaber
  [9989]=11709, -- White Kitten
  [9990]=11709, -- Cleo
  [9997]=513, -- Smolderweb Hatchling
  [10000]=10002, -- Wild Ram
  [10003]=10000, -- White Ram
  [10015]=381, -- Swine
  [10033]=7894, -- Belfry Bat
  [10095]=387, -- Twilight Whelpling
  [10209]=9370, -- Dog
  [10269]=3206, -- Tranquil Mechanical Yeti
  [10723]=10698, -- Shrieker
  [10832]=4615, -- Owl
  [10913]=163, -- Kobold
  [11099]=3195, -- Silithid Ravager
  [11263]=4973, -- Naga Siren
  [11709]=5555, -- Salome
  [12029]=13029, -- Majordomo Executus
  [12336]=9031, -- Spawn of Grubthor
  [12344]=1074, -- Stone Maw Basilisk
  [12682]=10807, -- Chimaera Matriarch
  [13030]=8329, -- Gehennas
  [13031]=13029, -- Lucifron
  [13032]=12029, -- Shazzrah
  [14255]=5048, -- Felguard
  [14778]=14779, -- Tiny Green Dragon
  [14779]=14778, -- Tiny Red Dragon
  [14932]=6295, -- Jungle Toad
  [14938]=6295, -- Jubling
  [15181]=7890, -- Spike
  [15204]=720, -- Lady
  [15369]=15984, -- Murky
  [15381]=15382, -- Darkmoon Tonk
  [15394]=15395, -- Subjugated Tadpole
  [15395]=15396, -- Murki
  [15396]=15397, -- Allured Tadpole
  [15398]=15393, -- White Baby Murloc
  [15436]=7763, -- Disgusting Oozeling
  [15468]=9028, -- Beetle
  [15469]=2487, -- Scorpion
  [15470]=2485, -- Durotar Scorpion
  [15471]=2729, -- Scorpid
  [15595]=12200, -- Land Shark
  [15984]=15369, -- Gurky
  [16205]=857, -- Elwynn Lamb
  [16257]=16357, -- Mr. Wiggles
  [16259]=16360, -- Speedy
  [16587]=1824, -- Spirit of Summer
  [16622]=5556, -- Mr. Bigglesworth
}
local modelFor=P.ModelFor
local variants={}
function P.ModelFor(unit)
  local base=modelFor(unit)
  local display=(P.IsSparkly(unit) or unit.sparklyDiscovered==true) and P.sparklySkins[base.display]
  if not display or P.unavailableModels[display] then return base end
  local variant=variants[base]
  if not variant or variant.display~=display then
    variant={};for k,v in pairs(base)do variant[k]=v end
    variant.display=display;variant.fallback=unit.species;variants[base]=variant
  end
  return variant
end
-- Native Classic star texture (Spells/Star4.blp). Projected particles stay
-- around the moving model, without external assets.
local function tint(arena)
  for _,s in pairs(arena.states)do
    local sparkly=s.active and P.IsSparkly(s.unit)
    if (sparkly or s.sparklyTint) and s.actor.SetDesaturation then
      local dead=s.dead or (s.unit and s.unit.deadAt)
      s.actor:SetDesaturation(dead and (P.DeathFade and P.DeathFade(s.unit) or 1) or 0)
    end
    s.sparklyTint=sparkly
  end
end
local function particles(arena,dt)
  local overlay=arena.sparklyOverlay;if not overlay then return end
  overlay.elapsed=(overlay.elapsed or 0)+dt
  if overlay.elapsed<.05 then return end;overlay.elapsed=0
  tint(arena)
  local scene=arena.scene;local w,h=scene:GetWidth(),scene:GetHeight()
  local scale=scene.GetEffectiveScale and scene:GetEffectiveScale() or 1
  if type(scale)~="number" or scale<=0 then scale=1 end
  local motion=not F.db.settings.reduceMotion
  local time=GetTime and GetTime() or P.sceneClock or 0
  local used=0
  for i=0,-2,-1 do
    local s=arena.states[i]
    if s and s.active and s.loaded and not s.dead and not s.unit.deadAt and P.IsSparkly(s.unit) then
      used=used+1;local pool=overlay.pools[used]
      if not pool then
        pool={};overlay.pools[used]=pool
        for n=1,6 do local t=overlay:CreateTexture(nil,"ARTWORK");t:SetTexture(166961);t:SetBlendMode("ADD");t:SetVertexColor(.7,.94,1);pool[n]=t end
      end
      for n,t in ipairs(pool)do
        local phase=motion and (time*.38+n*.173)%1 or n/7
        local radius=math.min(1.1,(s.height or 2)*.4)
        local angle=n*2.4+(motion and time*.35 or 0)
        local x=(s.visualX or s.x)+math.cos(angle)*radius
        local y=s.y+math.sin(angle)*radius*.4
        local z=(s.height or 2)*(.15+phase*.85)
        local ok,px,py=pcall(scene.Project3DPointTo2D,scene,x,y,z)
        -- Projection returns scaled screen pixels, while SetPoint takes UI units.
        if ok and type(px)=="number" and type(py)=="number"then px,py=px/scale,py/scale end
        local size=motion and (7+7*math.sin(phase*math.pi)) or 9
        local show=ok and type(px)=="number" and type(py)=="number" and px==px and py==py and px>size and px<w-size and py>size and py<h-size
        t:SetShown(not not show)
        if show then t:ClearAllPoints();t:SetPoint("CENTER",scene,"BOTTOMLEFT",px,py);t:SetSize(size,size);t:SetAlpha(motion and math.sin(phase*math.pi)^2 or .65)end
      end
    end
  end
  for i=used+1,#overlay.pools do for _,t in ipairs(overlay.pools[i])do t:Hide()end end
  if used==0 then overlay:Hide()end
end
local create=P.CreateArena
function P.CreateArena(parent,portrait)
  local arena=create(parent,portrait);if not arena.scene then return arena end
  local sync=arena.Sync
  function arena:Sync(...)
    sync(self,...);tint(self)
    local any=false;for i=0,-2,-1 do local s=self.states[i];if s and s.active and P.IsSparkly(s.unit)then any=true end end
    if any and self.scene.Project3DPointTo2D and not self.sparklyOverlay then
      local f=CreateFrame("Frame",nil,self.scene);self.sparklyOverlay=f;f.pools={};f.elapsed=0
      f:SetAllPoints(self.scene);f:SetFrameLevel(self.scene:GetFrameLevel()+2);f:EnableMouse(false)
      f:SetScript("OnUpdate",function(_,dt)particles(self,dt)end)
    end
    if self.sparklyOverlay then self.sparklyOverlay:SetShown(any)end
  end
  local update,poll=arena.Update,arena.Poll
  function arena:Update(...)update(self,...);tint(self)end
  function arena:Poll(...)poll(self,...);tint(self)end
  return arena
end
