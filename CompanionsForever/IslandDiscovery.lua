local _,F=...
local I,P,A=F.Housing.Island,F.Pets,F.Achievements
local L=I.Life
L.stationNames={food='Cooking fire',herbs='Herb garden',gold='Prospector supplies',xp='Training post',expedition='Expedition rowboat'}
L.places={
 human={map=1453,name='Stormwind'},dwarf={map=1455,name='Ironforge'},orc={map=1454,name='Orgrimmar'},
 nightelf={map=1457,name='Darnassus'},tauren={map=1456,name='Thunder Bluff'},undead={map=1458,name='Undercity'},
 westfall={map=1436,name='Sentinel Hill',x=.56,y=.48},elwynn={map=1429,name='Goldshire',x=.42,y=.65},
 redridge={map=1433,name='Lakeshire',x=.27,y=.45},duskwood={map=1431,name='Darkshire',x=.74,y=.46},
 barrens={map=1413,name='Ratchet',x=.63,y=.37},stranglethorn={map=1434,name='Booty Bay',x=.27,y=.77},
 tanaris={map=1446,name='Gadgetzan',x=.51,y=.28},ashenvale={map=1440,name='Astranaar',x=.36,y=.50},
 winterspring={map=1452,name='Everlook',x=.61,y=.38},diremaul={map=1444,name='Dire Maul entrance',x=.60,y=.31},
}
function L.PurchaseObject(o)
 if not L.Unlocked(o.key)then return false,'Discover this furnishing first.'end
 local price=L.FurniturePrice and L.FurniturePrice()or L.price
 if P.state.tokens<price then return false,'You need '..price..' tokens to place this furnishing.'end
 local _,paid=P.ChangeTokens(-price,'HOUSINGBUY',tostring(o.id));if paid~=-price then return false,'Purchase could not be completed.'end
 o.paid=price;return true
end
function L.RefundObject(o)
 L.Advance(F.Now())
 if I.VoyageBoatLocked and I.VoyageBoatLocked(o.id)then return false,'Finish or cancel the expedition before deleting its boat. Canceling loses this trip\'s rewards.'end
 local refund=o.paid
 if type(refund)~='number'or refund%1~=0 or refund<5 or refund>L.price then return true end
 if P.state.tokens>P.maxTokens-refund then return false,'Spend '..refund..' tokens first so the full refund will fit.'end
 local _,paid=P.ChangeTokens(refund,'HOUSINGREFUND',tostring(o.id));if paid==refund then o.paid=nil;return true end;return false,'Refund could not be completed.'
end
function L.Visit(map,x,y)
 if UnitIsDeadOrGhost and UnitIsDeadOrGhost('player')then return 0 end
 local a=L.Library();local count=0
 for key,place in pairs(L.places)do if map==place.map and (not place.x or type(x)=='number'and type(y)=='number'and (x-place.x)^2+(y-place.y)^2<.07^2)and not a.places[key]then
  a.places[key]=true
  for _,d in ipairs(I.decor)do if d.unlock==key and L.Unlock(d.key,'place:'..key)then count=count+1 end end
  F.Print('Housing: discovered '..place.name..' furnishings.')
 end end
 return count
end
function L.CheckLocation()
 if not F.ready or not C_Map or not C_Map.GetBestMapForUnit then return end
 local ok,map=pcall(C_Map.GetBestMapForUnit,'player');if not ok or type(map)~='number'then return end
 local x,y
 if C_Map.GetPlayerMapPosition then local valid,pos=pcall(C_Map.GetPlayerMapPosition,map,'player');if valid and pos and pos.GetXY then x,y=pos:GetXY()end end
 L.Visit(map,x,y)
end
function L.UnlockSource(key)
 local d=I.decorByKey[key];if not d or not L.Unlocked(key)then return nil end
 local source=L.Library().sources[key]
 if source=='crate'then return 'From: Furniture crate' end
 if source=='expedition'or d.unlock=='expedition'then return 'From: Expedition' end
 local place=type(source)=='string'and L.places[source:match('^place:(.+)$')]
 if place then return 'From: '..place.name end
 local achievement=type(source)=='string'and A.byID[source:match('^achievement:(.+)$')]
 if achievement then return 'From: '..achievement.name end
 if not d.unlock then return 'Available from the start' end
 if d.unlock=='crate'then return 'From: Furniture crate' end
 place=L.places[d.unlock]
 -- Older saves did not record whether a landmark furnishing came from a visit or a crate.
 if place then return 'Sources: '..place.name..' / Furniture crate' end
 return 'From: Achievement'
end
function L.LockText(key)
 local d=I.decorByKey[key];if not d then return ''end
 if L.Unlocked(key)then return L.PriceText()..' | Delete for full refund'end
 local place=L.places[d.unlock]
 return place and ('Visit '..place.name..' alive, or open furniture crates.')or d.unlock=='expedition'and 'Find on expeditions.'or 'Unlock through a secret achievement.'
end
-- Register with the existing persistent crate registry so mail, validation,
-- bag placement and reloads use exactly the same item identity machinery.
P.equipmentCrates[L.crateID]={name='Furniture Crate',icon='INV_Crate_01',rarity=3,housing=true}
local description=P.EquipmentCrateDescription
function P.EquipmentCrateDescription(id)
 if id==L.crateID then
  local upgrade=L.SpecialBonus and L.SpecialBonus('furniture')or 0
  local double=L.SpecialBonus and L.SpecialBonus('double')or 0
  return '|TInterface\\Icons\\INV_Crate_01:16:16|t 75% furniture blueprint\n|TInterface\\Icons\\Trade_Engineering:16:16|t 25% workstation blueprint\nWorkstations can unlock early. Keeps your best rarity.'..(upgrade>0 and ('\nFurniture Expert: '..upgrade..'% better rarity chance.')or '')..(double>0 and ('\nDouble Delivery: '..double..'% extra reward chance.')or '')..'\nAll furniture known: 10 |T'..P.tokenIcon..':14:14|t instead.\nRight-click to open.'
 end
 return description(id)
end
local open=P.OpenEquipmentCrate
function P.OpenEquipmentCrate(id)
 local item=P.CrateItem(id);if not item or item.crate~=L.crateID then return open(id)end
 if P.state.battle or P.openingBagCrate then return false,'Finish the battle or current crate first.'end
 local integrity=F.Integrity;local valid,why=integrity.Check({audit=true,ownWires={integrity.Encode('crate',item)},remoteWires={}})
 if not valid then return false,why end
 local pool={};for _,d in ipairs(I.decor)do if d.unlock and d.unlock~='secret'and d.unlock~='expedition'and not d.station and not L.Unlocked(d.key)then pool[#pool+1]=d end end
 local double=L.SpecialBonus and L.SpecialBonus('double')or 0
 local reserve=double>0 and 20 or 10
 if #pool<(double>0 and 2 or 1)and P.state.tokens>P.maxTokens-reserve then return false,'Spend '..reserve..' tokens before opening this crate so every reward will fit.'end
 local weights={70,22,7,1}
 local utilityPool={};for _,d in ipairs(I.decor)do if d.station then for n=1,weights[d.rank or 1]do utilityPool[#utilityPool+1]=d end end end
 local count=L.SpecialProc and L.SpecialProc('double')and 2 or 1
 local rewards={}
 for n=1,count do
  local utility=#utilityPool>0 and P.random(1,100)<=25
  local reward
  if utility then reward=utilityPool[P.random(1,#utilityPool)]
  elseif #pool>0 then reward=table.remove(pool,P.random(1,#pool))end
  rewards[n]={item=reward,utility=utility,rarity=utility and L.RollUtilityQuality()or 1}
 end
 integrity.Consumed('crate',item)
 for j,crate in ipairs(P.state.crates)do if crate==item then table.remove(P.state.crates,j);break end end
 local messages={};local display={};local models={};local displayRarity=1;local tokens=0
 for _,entry in ipairs(rewards)do local reward,utility,rarity=entry.item,entry.utility,entry.rarity
  if reward then
   if utility then L.FindUtility(reward.key,rarity)else L.Unlock(reward.key,'crate')end
   local name=(utility and P.rarities[rarity]..' 'or '')..reward.name
   display[#display+1]=name;displayRarity=math.max(displayRarity,rarity)
   models[#models+1]={key=reward.key,name=name,rarity=rarity}
   messages[#messages+1]=utility and name..' blueprint found. Best quality is kept for future purchases.'or name..' unlocked for your account.'
  else tokens=tokens+10;display[#display+1]='10 tokens';messages[#messages+1]='All furnishings known: 10 tokens.'end
 end
 if tokens>0 then P.ChangeTokens(tokens,'FURNITURECRATE',item.assetID)end
 P.Reward('item',count==2 and 'Double Delivery!'or 'Housing reward found!',table.concat(display,'\n'),'INV_Crate_01',nil,displayRarity,nil,nil,nil,models)
 return true,table.concat(messages,'\n')
end
local towerLoot=P.TowerLoot
function P.TowerLoot(b,first)
 local result=towerLoot(b,first)
 if not b.housingCrateRolled then
  b.housingCrateRolled=true
  if P.random(1,100)<=5 then
   local presentation=P.RewardPresentation;local prior=presentation.tower
   b.presentationLoot=b.presentationLoot or {};presentation.tower=b.presentationLoot
   local ok,why=pcall(P.GrantCrate,L.crateID,'Tower furniture drop');presentation.tower=prior
   if not ok then error(why)end
  end
 end
 return result
end
-- Furniture is the only live-world reward enabled for this housing test.
-- The existing sandbox prohibition on pet, gear and money drops stays intact.
local tracker=CreateFrame('Frame');L.tracker=tracker
for _,event in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED','ZONE_CHANGED_NEW_AREA','PARTY_KILL'})do tracker:RegisterEvent(event)end
local seen={}
tracker:SetScript('OnEvent',function(_,event,...)
 if not F.ready then return end
 if event~='PARTY_KILL'then L.CheckLocation();L.Advance(F.Now());return end
 local source,guid=...
 if issecretvalue and (issecretvalue(source)or issecretvalue(guid))then return end
 if canaccessvalue and (not canaccessvalue(source)or not canaccessvalue(guid))then return end
 if type(guid)~='string'or not guid:match('^Creature%-')or seen[guid]then return end
 if P.EligibleKill and not P.EligibleKill(guid)then return end
 seen[guid]=F.Now();for k,t in pairs(seen)do if F.Now()-t>120 then seen[k]=nil end end
 if P.random(1,100)<=1 then P.GrantCrate(L.crateID,'World furniture drop')end
end)
local elapsed=0
tracker:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed>=10 then elapsed=0;L.CheckLocation()end end)
local entries={
 {id='housingFirstCrew',name='A Place for Everyone',text='House three companions together.',metric='houseCrew',goal=3,tokens=40,crate=19,secret=true,housing=true},
 {id='housingWorking',name='Small Paws, Big Plans',text='Complete 20 housing work payouts.',metric='houseWork',goal=20,tokens=75,crate=20,secret=true,housing=true},
 {id='housingVoyage',name='Beyond the Shore',text='Discover furnishings at five places and complete 20 work payouts.',metric='houseBoat',goal=1,tokens=100,furniture='expeditionboat',secret=true,housing=true},
 {id='housingCaptain',name='Little Captain',text='Return from five successful expeditions.',metric='houseTrips',goal=5,tokens=150,crate=21,secret=true,housing=true},
}
for _,d in ipairs(entries)do d.icon='INV_Misc_Map_01';d.order=#A.list+1;A.list[d.order]=d;A.byID[d.id]=d end
local progress=A.Progress
function A.Progress(d)
 local s=L.State()
 if d.metric=='houseCrew'then local count=0;for _ in pairs(s.slots)do count=count+1 end;return count
 elseif d.metric=='houseWork'then return s.stats.work or 0
 elseif d.metric=='houseTrips'then return s.stats.expeditions or 0
 elseif d.metric=='houseBoat'then local count=0;for _ in pairs(L.Library().places)do count=count+1 end;return count>=5 and (s.stats.work or 0)>=20 and 1 or 0 end
 return progress(d)
end
local rewardText=A.RewardText
function A.RewardText(d,reveal,remaining)
 if not d.housing then return rewardText(d,reveal,remaining)end
 return (d.tokens or 0)..' gold'..(d.crate and '\nXP treats'or '')..(d.furniture and '\n'..(reveal and 'Expedition rowboat'or 'Secret furnishing')or '')
end
local claim=A.Claim
function A.Claim(id)
 local d=A.byID[id];if not d or not d.housing then return claim(id)end
 local a=L.Library();if a.secrets[id]then return false,'Already claimed on this account.'end
 if A.Progress(d)<d.goal then return false,'This secret has not been discovered yet.'end
 if P.state.battle then return false,'Finish your battle first.'end
 if P.state.tokens>P.maxTokens-d.tokens then return false,'Spend some gold before claiming.'end
 if d.crate then local ok,why=P.GrantCrate(d.crate,'Housing achievement',true);if not ok then return false,why end end
 a.secrets[id]=true;P.state.achievements.claimed[id]=true;P.state.achievements.paid[id]={tokens=d.tokens,crate=d.crate}
 P.ChangeTokens(d.tokens,'HOUSINGSECRET',id)
 if d.furniture then L.Unlock(d.furniture,'achievement:'..id)end
 return true,'Housing secret claimed.'
end
local settled=A.Settled
function A.Settled(d)if d.housing then return L.Library().secrets[d.id]==true end;return settled(d)end
-- The first login on another character can re-number local pet IDs during
-- account merging. Keep housing attached to the immutable pet identities.
local merge=F.AccountSave.Merge
function F.AccountSave.Merge(shared,source)
 local out=merge(shared,source);local s=out.housingLife
 if type(s)=='table'then
  local old,new={},{}
  for _,pet in ipairs(shared.pets or {})do if pet.assetID then old[pet.id]=pet.assetID end end
  for _,pet in ipairs(out.pets or {})do if pet.assetID then new[pet.assetID]=pet.id end end
  for j,slot in pairs(s.slots or {})do if type(slot)=='table'then local id=new[old[slot.petID]];if id then slot.petID=id else s.slots[j]=nil end end end
  if s.pending and type(s.pending.xp)=='table'then local xp={};for id,n in pairs(s.pending.xp)do if new[old[id]]then xp[new[old[id]]]=n end end;s.pending.xp=xp end
  if type(s.trip)=='table'and type(s.trip.ids)=='table'then
   local ids={};for _,id in ipairs(s.trip.ids)do if new[old[id]]then ids[#ids+1]=new[old[id]]end end
   if #ids==#s.trip.ids then s.trip.ids=ids else s.trip=nil;s.repeatTrip=false end
  end
 end
 return out
end
local initialize=F.Initialize
function F.Initialize(...)
 initialize(...)
 -- Account recovery and pending-trade protection can intentionally stop login.
 -- Do not initialize housing against a missing or blocked adventure save.
 if not F.ready or not P.state then return end
 -- Housing and its pets travel together with the shared realm adventure.
 if type(P.state.housingIsland)~='table'then P.state.housingIsland=F.char.islandPrototype or {}end
 F.char.islandPrototype=P.state.housingIsland
 if F.char.islandPrototype.items~=nil then F.char.islandPrototype.items=I.CleanObjects(F.char.islandPrototype.items)end
 if F.char.islandPrototype.land~=nil then I.LandState()end
 L.ValidateSave()
 for _,o in ipairs(F.char.islandPrototype.items or {})do if I.decorByKey[o.key]then L.Library().unlocked[o.key]=true end end
 L.Advance(F.Now())
end
