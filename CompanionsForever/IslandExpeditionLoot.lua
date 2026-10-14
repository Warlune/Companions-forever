local _,F=...
local P,I=F.Pets,F.Housing.Island
local L,H=I.Life,P.HardMode
-- One find roll per successful voyage, independent of speed and housing buffs.
L.expeditionFindOdds={gear=10,crate=5,furniture=15}
local profiles={
 {{weight=1,rarity=1,label='Common'}},
 {{weight=50,rarity=1,label='Common'},{weight=30,rarity=2,label='Uncommon'},{weight=15,rarity=3,label='Rare'}},
 {{weight=9,rarity=3,label='Rare'},{weight=1,rarity=4,label='Epic'}},
 {{weight=3,rarity=3,label='Rare'},{weight=2,rarity=4,label='Epic'},{weight=1,rarity=5,label='Legendary'}},
 {{weight=3,rarity=3,label='Rare'},{weight=2,rarity=4,label='Epic'},{weight=1,rarity=5,label='Legendary'}},
 {{weight=1,rarity=4,label='Epic'},{weight=1,rarity=5,label='Legendary'}},
 {{weight=75,rarity=5,nonSet=true,label='Tier 1 Legendary (non-set)'},{weight=25,rarity=4,tier=1,label='Tier 1 set'}},
 {{weight=1,rarity=4,tier=2,label='Tier 2 Ascendant set'}},
 {{weight=95,rarity=4,tier=2,label='Tier 2 Ascendant set'},{weight=5,rarity=4,tier=3,label='Tier 3 Mythic set'}},
 {{weight=95,rarity=4,tier=2,label='Tier 2 Ascendant set'},{weight=5,rarity=4,tier=3,label='Tier 3 Mythic set'}},
}
function L.ExpeditionTokens(index,duration,outputBonus)
 local rate=L.difficulties[index].tokensPerHour
 return math.max(1,math.floor(rate*duration/3600*(1+(outputBonus or 0)/100)+.5))
end
function L.ExpeditionFindType(roll)
 local odds=L.expeditionFindOdds
 if roll<=odds.gear then return 'gear'
 elseif roll<=odds.gear+odds.crate then return 'crate'
 elseif roll<=odds.gear+odds.crate+odds.furniture then return 'furniture'end
end
function L.ExpeditionGearHelp(index)
 local pool=profiles[index];local total=0;for _,entry in ipairs(pool)do total=total+entry.weight end
 local lines={'10% per successful voyage. Within that gear roll:'}
 for _,entry in ipairs(pool)do lines[#lines+1]=string.format('%g%% %s',math.floor(entry.weight/total*1000+.5)/10,entry.label)end
 if index>=9 then lines[#lines+1]='Mythic: 0.5% per successful voyage overall.'end
 lines[#lines+1]='Boat speed and housing buffs do not increase these chances.'
 return table.concat(lines,'\n')
end
function L.RollExpeditionGear(index,random)
 local pool=profiles[index];local total=0;for _,entry in ipairs(pool)do total=total+entry.weight end
 local roll=random(total);local choice
 for _,entry in ipairs(pool)do roll=roll-entry.weight;if roll<=0 then choice=entry;break end end
 local kind
 if choice.nonSet then kind=H.nonSetKinds[random(#H.nonSetKinds)]
 elseif choice.tier then
  local sets=H.tierKinds[choice.tier];local set=sets[random(#sets)];kind=set[random(#set)]
 else
  -- Same ordinary item pools and 1% Equip-effect chance as tower gear,
  -- but use the voyage's saved seed so reloads cannot change its loot.
  local pools=P.distinctGearPools
  local items=choice.rarity>=3 and random(10000)<=100 and pools.special or pools.normal
  kind=items[random(#items)]
 end
 return {kind=kind,rarity=choice.rarity}
end
