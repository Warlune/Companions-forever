local _,F=...
local P,D=F.Pets,F.PetData
-- A separate cosmetic companion, never a rename of an existing saved pet.
local id,base=2363,664
local name="Unda's Darnak the Tunneler"
local data,model={},{}
for k,v in pairs(D.species[base])do data[k]=v end
for k,v in pairs(P.models[base])do model[k]=v end
data.name=name;data.raid=false
D.species[id]=data;D.names[id]=name;P.models[id]=model
D.allowedSpecies[id]=true;D.hiddenSpecies[id]=true
-- Anyone can discover this cosmetic pet in an ordinary adoption crate.
-- Keep it a surprise in Collection until found, like the other secret pets.
local included=false
for _,species in ipairs(D.rosterPool)do if species==id then included=true;break end end
if not included then D.rosterPool[#D.rosterPool+1]=id end
P.portraits=P.portraits or {}
P.portraits[id]="Interface\\AddOns\\CompanionsForever\\Art\\UndasDarnak.tga"
D.specialSources=D.specialSources or {}
D.specialSources[id]="Secret crate companion.\nFound in any regular adoption crate; rarity follows the crate's chances.\nNot a wild drop. Discovery remains after retirement or trading."
P.specialCrates={
  [12]={name="Unda's Darnak Gift Crate",icon="INV_Crate_01",species=id,rarity=3},
}
