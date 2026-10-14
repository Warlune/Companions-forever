local _,F=...
local P,S,I=F.Pets,F.Style,F.Housing.Island
local L=I.Life
-- IDs and rolled quality stay attached to pets; the shared combat catalogue
-- supplies the current mechanics for both existing and newly acquired pets.
local canRoll=P.CanRollAbility
function P.CanRollAbility(id)
 local a=P.specialAbilities[id];return a and not a.housing and (not canRoll or canRoll(id))
end
local function owned(pet)
 if pet.rolls or pet.assetID or pet.birth then return true end
 local state=P.state or {}
 for _,v in ipairs(state.pets or {})do if v==pet then return true end end
 for _,entry in ipairs(state.mailbox or {})do if entry.kind=='pet'and entry.item==pet then return true end end
 return false
end
L.housingAbilities={};L.housingAbilityByID={}
local jobs={
 {key='food',name='Cooking',icon='INV_Misc_Food_15',names={'Quick Cook','More Cook','Efficient Cook','Cook Teacher','Cook Rest','Cook Learner'}},
 {key='gold',name='Prospecting',icon='INV_Misc_Coin_01',names={'Quick Coin','More Coin','Efficient Coin','Coin Teacher','Coin Rest','Coin Learner'}},
 {key='xp',name='Training',icon='Ability_Hunter_Pet_Bear',names={'Quick XP','More XP','Efficient XP','XP Teacher','XP Rest','XP Learner'}},
 {key='herbs',name='Gardening',icon='INV_Misc_Herb_07',names={'Quick Herb','More Herb','Efficient Herb','Herb Teacher','Herb Rest','Herb Learner'}},
 {key='expedition',name='Expeditions',icon='INV_Misc_Map_01',names={'Quick Expedition','More Expedition','Efficient Expedition','Expedition Teacher','Expedition Rest','Expedition Learner'}},
}
local stats={'speed','output','thrift','taskXP','rest','insight'}
local descriptions={speed='%s tasks take %s%% less time.',output='%s rewards: +%s%% %s.',thrift='%s uses %s%% less energy.',taskXP='%s completion: +%s%% housing task XP.',rest='Recover %s%% faster while assigned to %s.',insight='Passive housing XP: +%s%% while assigned to %s.'}
for j,job in ipairs(jobs)do for k,stat in ipairs(stats)do
 local id=10000+(j-1)*6+k
 local a={id=id,ability=job.names[k],icon=job.icon,job=job.key,jobName=job.name,housing=true,stat=stat}
 L.housingAbilities[#L.housingAbilities+1]=a;L.housingAbilityByID[id]=a
 -- Sparse catalogue IDs are visible to the book, never to ipairs combat pools.
 P.specialAbilities[id]=a
end end
for index,special in ipairs({
 {ability='Shared Wisdom',icon='Spell_Holy_GreaterBlessingofWisdom',stat='mentor'},
 {ability='Furniture Expert',icon='Trade_Engineering',stat='furniture'},
 {ability='Double Delivery',icon='INV_Crate_01',stat='double'},
})do
 local id=10030+index
 special.id=id;special.job='special';special.housing=true;special.special=true
 L.housingAbilities[#L.housingAbilities+1]=special;L.housingAbilityByID[id]=special;P.specialAbilities[id]=special
end
local function integer(n,lo,hi)return type(n)=='number'and n==math.floor(n)and n>=lo and n<=hi end
function L.EnsureHousingAbilities(pet,newPet)
 if not pet then return end
 -- Login, inspection and discovery only register existing rolls. Never backfill,
 -- reroll or replace an existing pet's housing abilities.
 if not newPet or pet.housingAbilities~=nil then
  if P.state then
   P.state.knownAbilities=P.state.knownAbilities or {}
   for _,roll in ipairs(type(pet.housingAbilities)=='table'and pet.housingAbilities or {})do
    if type(roll)=='table'and L.housingAbilityByID[roll.id]then P.state.knownAbilities[roll.id]=true end
   end
  end
  return pet.housingAbilities
 end
 local count=(pet.rarity or 0)>=4 and 2 or (pet.rarity or 0)>=3 and 1 or 0
 local valid,seen={},{}
 for _,roll in ipairs(type(pet.housingAbilities)=='table'and pet.housingAbilities or {})do
  if type(roll)=='table'and L.housingAbilityByID[roll.id]and not seen[roll.id]and integer(roll.quality,1,5)and integer(roll.roll,1,100)and #valid<count then
   valid[#valid+1]={id=roll.id,quality=roll.quality,roll=roll.roll};seen[roll.id]=true
  end
 end
 while #valid<count do
  local pool={};for _,a in ipairs(L.housingAbilities)do if not seen[a.id]then pool[#pool+1]=a.id end end
  local id=pool[P.rollRandom(1,#pool)];local chance=P.rollRandom(1,100)
  valid[#valid+1]={id=id,quality=chance<=50 and 1 or chance<=80 and 2 or chance<=95 and 3 or chance<=99 and 4 or 5,roll=P.rollRandom(1,100)};seen[id]=true
 end
 pet.housingAbilities=valid
 if P.state then
  P.state.knownAbilities=P.state.knownAbilities or {}
  for _,roll in ipairs(valid)do P.state.knownAbilities[roll.id]=true end
 end
 return valid
end
function L.HousingPercent(roll)return math.floor(5*roll.quality*(.8+.2*(roll.roll-1)/99)*10+.5)/10 end
function L.HousingBonus(pet,job,stat)
 local result=0
 for _,roll in ipairs(pet and pet.housingAbilities or {})do local a=L.housingAbilityByID[roll.id]
  if a and a.job==job and a.stat==stat and integer(roll.quality,1,5)and integer(roll.roll,1,100)then result=result+L.HousingPercent(roll)end
 end
 return math.min(50,result)
end
function L.TeamHousingBonus(stat,ids)
 local total,count=0,0
 for _,id in ipairs(ids or {})do local pet=L.Pet(id);if pet then total=total+L.HousingBonus(pet,'expedition',stat);count=count+1 end end
 return count>0 and total/count or 0
end
-- Island-wide perks require a living resident; duplicate copies never stack.
function L.SpecialBonus(stat,excludeID)
 local strongest,discount=0,0
 for _,slot in pairs(L.State().slots)do
  local pet=L.Pet(slot.petID)
  if pet and pet.id~=excludeID then
   strongest=math.max(strongest,L.HousingBonus(pet,'special',stat))
   if stat=='furniture'and L.HousingBonus(pet,'special',stat)>0 then
    for _,roll in ipairs(pet.housingAbilities or {})do
     if roll.id==10032 and integer(roll.quality,1,5)and integer(roll.roll,1,100)then discount=math.max(discount,roll.quality)end
    end
   end
  end
 end
 return strongest,discount
end
function L.FurniturePrice()
 local _,discount=L.SpecialBonus('furniture');return L.price-discount
end
function L.SharedHousingXP(pet,amount)
 local percent=L.SpecialBonus('mentor',pet.id);if percent==0 then return 0 end
 pet.housingCarry=type(pet.housingCarry)=='table'and pet.housingCarry or {}
 local carry=pet.housingCarry.sharedWisdom
 if type(carry)~='number'or carry~=carry or carry<0 or carry>=1 then carry=0 end
 local value=amount*percent/100+carry;local whole=math.floor(value+1e-8)
 pet.housingCarry.sharedWisdom=math.max(0,value-whole);return whole
end
function L.SpecialProc(stat)
 local percent=L.SpecialBonus(stat);return percent>0 and P.random(1,10000)<=math.floor(percent*100+.5)
end
function L.HousingScale(pet,job,stat,amount)
 local bonus=L.HousingBonus(pet,job,stat);if bonus==0 then return amount end
 pet.housingCarry=type(pet.housingCarry)=='table'and pet.housingCarry or {}
 local key=job..':'..stat;local carry=pet.housingCarry[key]
 if type(carry)~='number'or carry~=carry or carry<0 or carry>=1 then carry=0 end
 local value=amount*(1+bonus/100)+carry;local whole=math.floor(value+1e-8)
 pet.housingCarry[key]=math.max(0,value-whole);return whole
end
function L.HousingAbilityHelp(a,roll)
 local percent=roll and string.format('%.1f',L.HousingPercent(roll)):gsub('%.0$','')or '4–25'
 local effect
 if a.special then
  if a.stat=='mentor'then effect='Other housed pets earn +'..percent..'% passive housing XP. Does not boost this pet.'
  elseif a.stat=='furniture'then effect='Furniture costs '..(roll and roll.quality or '1–5')..' fewer tokens. Utility crate rewards have a '..percent..'% chance to improve by one rarity, up to Legendary.'
  else effect='Furniture crates have a '..percent..'% chance to give a second reward.'end
  effect=effect..'\nActive while housed. Strongest copy only.'
 elseif a.stat=='rest'or a.stat=='insight'then effect=string.format(descriptions[a.stat],percent,a.jobName)
 elseif a.stat=='output'then effect=string.format(descriptions.output,a.jobName,percent,({food='food',gold='tokens',xp='training XP',herbs='herbs',expedition='voyage tokens'})[a.job])
 else effect=string.format(descriptions[a.stat],a.jobName,percent)end
 return 'Housing buff\n'..(roll and (P.rarities[roll.quality]..' | Roll '..roll.roll..'/100\n')or '')..effect..(a.job=='expedition'and '\nCrew bonuses are averaged.'or '')
end
local rollPet=P.RollNewPet
function P.RollNewPet(pet)
 if owned(pet)then L.EnsureHousingAbilities(pet);return end
 local value=rollPet(pet);L.EnsureHousingAbilities(pet,true);return value
end
local initBook=P.InitAbilityBook
function P.InitAbilityBook(...)
 local value=initBook(...)
 for _,pet in ipairs(P.state.pets or {})do L.EnsureHousingAbilities(pet)end
 for _,entry in ipairs(P.state.mailbox or {})do if entry.kind=='pet'then L.EnsureHousingAbilities(entry.item)end end
 return value
end
local discover=P.RecordAbilityDiscovery
function P.RecordAbilityDiscovery(pet)local value=discover(pet);L.EnsureHousingAbilities(pet);return value end
local ensureCombat=P.EnsureAbilities
function P.EnsureAbilities(pet,...)
 if pet and (pet.abilities~=nil or owned(pet))then return end
 if pet then
  local pool={};for id in ipairs(P.specialAbilities)do if P.CanRollAbility(id)then pool[#pool+1]=id end end
  local count=pet.rarity>=4 and 2 or pet.rarity>=3 and 1 or 0
  pet.abilities={}
  for slot=1,count do pet.abilities[slot]=table.remove(pool,P.random(1,#pool))end
 end
 return ensureCombat(pet,...)
end
local help=P.AbilityHelp
function P.AbilityHelp(a,...)
 if type(a)=='table'and a.housing then return L.HousingAbilityHelp(a)end
 return help(a,...)
end
local bookHelp=P.AbilityBookHelp
function P.AbilityBookHelp(id)
 local a=L.housingAbilityByID[id];if not a then return bookHelp(id)end
 if not(P.state.knownAbilities and P.state.knownAbilities[id])then return 'Not found yet. Collect a Rare or better companion with this housing buff.'end
 return L.HousingAbilityHelp(a)..'\nRarity rolls independently from Common to Legendary.'
end
local work=L.WorkSeconds
function L.WorkSeconds(pet,job)return math.max(1,math.floor(work(pet,job)*(1-L.HousingBonus(pet,job,'speed')/100)+.5))end
local trip=L.TripSeconds
function L.TripSeconds()
 local ids={};for _,pet in ipairs(L.Team())do ids[#ids+1]=pet.id end
 return math.max(1,math.floor(trip()*(1-L.TeamHousingBonus('speed',ids)/100)+.5))
end
function L.RefreshHousingEffects()
 local w=P.window;if not w or not rawget(w,'housingEffects')then return end
 local pet=L.Pet(P.viewID)or P.Active()
 if P.mode=='peers'then pet=nil elseif P.mode=='tower'then pet=P.Active()end
 w.effects:SetText('')
 for index,button in ipairs(w.housingEffects)do
  local roll=pet and pet.housingAbilities and pet.housingAbilities[index];local a=roll and L.housingAbilityByID[roll.id]
  button:SetShown(a~=nil);button.ability=a;button.roll=roll
  if a then button.art:SetTexture('Interface\\Icons\\'..a.icon);button:SetBackdropBorderColor(unpack(P.colors[roll.quality]))end
 end
end
local build=P.BuildUI
function P.BuildUI(...)
 local value=build(...);local w=P.window
 if w and not rawget(w,'housingEffects')then
  for _,region in ipairs({w.statsPanel:GetRegions()})do if region.GetText and region:GetText()=='ACTIVE EFFECTS'then region:SetText('HOUSING EFFECTS')end end
  w.effects:SetText('');w.housingEffects={}
  for index=1,2 do
   local b=CreateFrame('Frame',nil,w.statsPanel,'BackdropTemplate');w.housingEffects[index]=b;b:SetPoint('TOPLEFT',12+(index-1)*44,-385);b:SetSize(28,28);b:EnableMouse(true)
   b:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
   b.art=b:CreateTexture(nil,'ARTWORK');b.art:SetPoint('TOPLEFT',2,-2);b.art:SetPoint('BOTTOMRIGHT',-2,2)
   b:SetScript('OnEnter',function()if b.ability then GameTooltip:SetOwner(b,'ANCHOR_RIGHT');GameTooltip:SetText(b.ability.ability);GameTooltip:AddLine(L.HousingAbilityHelp(b.ability,b.roll),1,1,1,true);GameTooltip:Show()end end)
   b:SetScript('OnLeave',function()GameTooltip:Hide()end)
  end
 end
 L.RefreshHousingEffects();return value
end
local render=P.Render
function P.Render(...)local value=render(...);L.RefreshHousingEffects();return value end
