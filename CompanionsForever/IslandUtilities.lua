local _,F=...
local I,P,A=F.Housing.Island,F.Pets,F.Achievements
local L=I.Life
L.ranks={{name='Novice',slow=3600,fast=2700},{name='Journeyman',slow=2700,fast=1800},{name='Expert',slow=1800,fast=900},{name='Artisan',slow=900,fast=600}}
local stationKeys={'cookfire','herbgarden','goldwork','trainingpost','expeditionboat'}
local requirements={food={0,0},herbs={5,0},gold={0,5},xp={0,10},expedition={20,0}}
L.rankRequirements={{0,0},{10,5},{30,20},{60,40}}
local function quality(n)
 n=tonumber(n);if not n or n~=n or math.abs(n)==math.huge then return 1 end
 return math.max(1,math.min(5,math.floor(n)))
end
function L.UtilityQuality(key)
 local library=L.Library();if type(library.quality)~='table'then library.quality={}end
 return quality(library.quality[key])
end
function L.HousingMilestones()
 local a=L.Library();local count=#(F.char.islandPrototype and F.char.islandPrototype.items or {})
 local peak=tonumber(a.placedPeak);if not peak or peak~=peak or peak<0 or peak>100 then peak=0 end
 a.placedPeak=math.max(peak,count)
 local found=0;for key,known in pairs(a.unlocked)do local d=I.decorByKey[key];if known and d and d.unlock and not d.station then found=found+1 end end
 return a.placedPeak,found
end
function L.UtilityUnlocked(d)
 local library=L.Library();L.UtilityQuality(d.key)
 if type(library.quality[d.key])=='number'then return true end -- A found blueprint unlocks only this station.
 local placed,found=L.HousingMilestones();local need=requirements[d.station]
 local legacyBoat=d.station=='expedition'and L.Library().secrets.housingVoyage==true
 if not legacyBoat and (placed<need[1]or found<need[2])then return false end
 local rank=L.rankRequirements[d.rank or 1]
 return placed>=rank[1]and found>=rank[2]
end
for _,key in ipairs(stationKeys)do
 local d=I.decorByKey[key];d.rank=1;d.baseName=d.name;d.name='Novice '..d.baseName;d.unlock='housingUtility'
 for rank=2,4 do
  local v={};for k,value in pairs(d)do v[k]=value end
  v.key=key..rank;v.rank=rank;v.name=L.ranks[rank].name..' '..d.baseName
  I.decor[#I.decor+1]=v;I.decorByKey[v.key]=v;I.storeCategories.Workstations[#I.storeCategories.Workstations+1]=v.key
 end
end
local unlocked=L.Unlocked
function L.Unlocked(key)
 local d=I.decorByKey[key];if d and d.station then return L.UtilityUnlocked(d)end
 return unlocked(key)
end
function L.StationSeconds(object)
 local d=I.decorByKey[object.key];local rank=L.ranks[d.rank or 1]
 return math.floor(rank.slow-(rank.slow-rank.fast)*(quality(object.quality)-1)/4+.5)
end
function L.Station(job)
 if job=='roam'then return true end
 local best
 for _,object in ipairs(F.char.islandPrototype and F.char.islandPrototype.items or {})do
  local d=I.decorByKey[object.key]
  if d and d.station==job and type(object.paid)=='number'and object.paid%1==0 and object.paid>=5 and object.paid<=L.price and (not best or L.StationSeconds(object)<L.StationSeconds(best))then best=object end
 end
 return best
end
function L.WorkSeconds(_,job)local station=L.Station(job);return type(station)=='table'and L.StationSeconds(station)or 3600 end
function L.TripSeconds()return L.WorkSeconds(nil,'expedition')end
function L.UtilityColor(key,q)
 local d=I.decorByKey[key];return d and d.station and P.colors[quality(q or L.UtilityQuality(key))]or {1,1,1}
end
function L.PriceText()return (L.FurniturePrice and L.FurniturePrice()or L.price)..' |T'..P.tokenIcon..':14:14|t'end
function L.DurationText(seconds)
 seconds=math.floor(seconds);return math.floor(seconds/60)..'m'..(seconds%60>0 and (' '..(seconds%60)..'s')or '')
end
function L.UtilityName(key)
 local d=I.decorByKey[key]
 return d and (d.station and P.rarities[L.UtilityQuality(key)]..' '..d.name or d.name)or ''
end
local function icon(name)return '|TInterface\\Icons\\'..name..':16:16|t'end
function L.UtilityReward(job)
 if job=='food'then return icon('INV_Misc_Food_15')..' 1 food'
 elseif job=='herbs'then return icon('INV_Misc_Herb_07')..' 1 herb'
 elseif job=='gold'then return '|T'..P.tokenIcon..':16:16|t 2 tokens'
 elseif job=='xp'then return icon('XP_Icon')..' 25 XP: equipped + housed pets'
 else return icon('INV_Misc_Coin_01')..' Tokens  '..icon('INV_Chest_Chain_04')..' Gear  '..icon('INV_Crate_01')..' Crates / furniture'end
end
local unlockSource=L.UnlockSource
function L.UnlockSource(key)
 local d=I.decorByKey[key];if not d or not d.station then return unlockSource(key)end
 if not L.Unlocked(key)then return nil end
 if type(L.Library().quality[key])=='number'then return 'From: Furniture crate' end
 local need=requirements[d.station];local rank=L.rankRequirements[d.rank or 1]
 local p,n=math.max(need[1],rank[1]),math.max(need[2],rank[2])
 if d.station=='expedition'and L.Library().secrets.housingVoyage and (d.rank or 1)==1 then return 'From: Beyond the Shore' end
 if p==0 and n==0 then return 'Available from the start' end
 return 'From: '..(p>0 and ('Place '..p)or '')..(p>0 and n>0 and ' + 'or '')..(n>0 and ('discover '..n)or '')..' furnishings'
end
local lockText=L.LockText
function L.LockText(key)
 local d=I.decorByKey[key];if not d or not d.station then return lockText(key)end
 local duration=L.DurationText(L.StationSeconds({key=key,quality=L.UtilityQuality(key)}))
 local lines={L.UtilityReward(d.station)..(d.station=='expedition'and ('\n'..duration..' per trip. Rewards depend on route.')or (' every '..duration..' (base).'))}
 lines[#lines+1]=icon('XP_Icon')..' +20 XP to housed pets per completion.'
 if not L.Unlocked(key)then
  local placed,found=L.HousingMilestones();local need=requirements[d.station];local rank=L.rankRequirements[d.rank]
  local p,n=math.max(need[1],rank[1]),math.max(need[2],rank[2])
  if placed<p then lines[#lines+1]='Place furnishings: '..placed..'/'..p end
  if found<n then lines[#lines+1]='Discover furnishings: '..found..'/'..n end
  lines[#lines+1]='Or find this station in a furniture crate.'
 end
 lines[#lines+1]=L.PriceText()..' | Delete for full refund'
 return table.concat(lines,'\n')
end
local purchase=L.PurchaseObject
function L.PurchaseObject(o)
 local ok,why=purchase(o);if ok and I.decorByKey[o.key].station then o.quality=L.UtilityQuality(o.key)end
 return ok,why
end
function L.RollUtilityQuality()
 local roll=P.random(1,100);local q=roll<=50 and 1 or roll<=80 and 2 or roll<=95 and 3 or roll<=99 and 4 or 5
 if q<5 and L.SpecialProc and L.SpecialProc('furniture')then q=q+1 end
 return q
end
function L.FindUtility(key,q)
 local d=I.decorByKey[key];if not d or not d.station then return false end
 local a=L.Library();L.UtilityQuality(key);q=quality(q);local previous=L.UtilityQuality(key)
 a.quality[key]=math.max(previous,q)
 return true,q>previous
end
L.difficulties={
 {name='Coastal Waters',level=5,enemies=1,strength=.3,tokensPerHour=6,gear=2,crate=2,floor=1,label='Easy',icon='INV_Misc_Map_01'},
 {name="Corsair's Reach",level=40,enemies=1,tokensPerHour=8,gear=3,crate=3,floor=25,label='Challenging',icon='Ability_Hunter_Pathfinding'},
 {name='Shipwreck Straits',level=70,enemies=2,tokensPerHour=10,gear=4,crate=4,floor=50,label='Dangerous',icon='INV_Misc_Map_01'},
 {name='Stormbreak Passage',level=100,tokensPerHour=12,gear=5,crate=6,floor=75,label='Extreme',icon='Spell_Nature_StormReach'},
 {name='Maelstrom Frontier',level=120,tokensPerHour=14,gear=5,crate=6,floor=100,label='Treacherous',icon='Spell_Nature_StormReach'},
 {name='Dreadwake Depths',level=145,tokensPerHour=16,gear=5,crate=6,hardFloor=25,label='Brutal',icon='Spell_Shadow_Possession'},
 {name="Leviathan's Grave",level=170,tokensPerHour=18,gear=5,crate=6,hardFloor=50,label='Deadly',icon='Ability_Creature_Cursed_02'},
 {name='Voidstorm Expanse',level=200,tokensPerHour=20,gear=5,crate=6,hardFloor=75,label='Nightmarish',icon='Spell_Shadow_ShadowBolt'},
 {name="World's End",level=230,tokensPerHour=22,gear=5,crate=6,hardFloor=100,label='Cataclysmic',icon='Spell_Fire_SelfDestruct'},
 {name="The Masters' Veil",level=260,tokensPerHour=25,gear=5,crate=6,masters=2,label='Mythic',icon='INV_Misc_Book_11'},
}
function L.TowerProgress()
 local best=P.state.achievements and P.state.achievements.tower or 0
 for _,pet in ipairs(P.state.pets or {})do best=math.max(best,pet.best or 0)end
 if P.state.hardMode and P.state.hardMode.unlocked then best=100 end
 return best
end
function L.HardTowerProgress()
 local h=P.state.hardMode;local best=0
 -- Read actual cleared floors. Merely unlocking Hard Mode is not a clear.
 while best<100 and h and h.cleared and h.cleared[best+1]==true do best=best+1 end
 return best
end
function L.MasterTrainerProgress()
 -- Reserved for the future Master Trainers feature; no preview unlocks.
 return 0
end
function L.ExpeditionRequirement(index)
 local d=L.difficulties[index];if not d then return 'Choose an expedition route.'end
 if d.masters then return 'Defeat 2 of 8 Master Trainers (coming later).'end
 if d.hardFloor then return 'Clear Hard Mode tower floor '..d.hardFloor..'.'end
 return 'Clear Normal tower floor '..d.floor..'.'
end
function L.ExpeditionUnlocked(index)
 local d=L.difficulties[index];if not d then return false end
 if d.masters then return L.HardTowerProgress()>=100 and L.MasterTrainerProgress()>=d.masters end
 if d.hardFloor then return L.HardTowerProgress()>=d.hardFloor end
 return L.TowerProgress()>=d.floor
end
local start=L.StartExpedition
function L.StartExpedition(index,...)
 if not L.ExpeditionUnlocked(index)then return false,L.ExpeditionRequirement(index)end
 return start(index,...)
end
local entries={
{id='housingPlace5',name='A Cozy Start',text='Place 5 furnishings at once. Unlocks Novice herb gardens.',metric='housePlaced',goal=5},
 {id='housingPlace20',name='Island Builder',text='Place 20 furnishings at once. Unlocks Novice expedition boats.',metric='housePlaced',goal=20},
 {id='housingFind5',name='Furnishing Finder',text='Discover 5 furnishing blueprints. Unlocks Novice token stations.',metric='houseFound',goal=5},
 {id='housingFind10',name='Island Collector',text='Discover 10 furnishing blueprints. Unlocks Novice XP stations.',metric='houseFound',goal=10},
}
for _,d in ipairs(entries)do d.tokens=25;d.housing=true;d.icon='Trade_Engineering';d.order=#A.list+1;A.list[d.order]=d;A.byID[d.id]=d end
local progress=A.Progress
function A.Progress(d)
 if d.metric=='housePlaced'or d.metric=='houseFound'then local placed,found=L.HousingMilestones();return d.metric=='housePlaced'and placed or found end
 return progress(d)
end
