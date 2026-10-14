local _,F=...
local P=F.Pets
local function number(n)return string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")end
local statHelp=P.StatHelp
function P.StatHelp(pet,index)
  local result
  if F.db.settings.shortPetTooltips or pet.sharedStats then
    local stats=pet.sharedStats or {P.Stats(pet)}
    local speed=stats[4];local b=P.state.battle
    local hit=P.HitChance(speed,b and b.enemy and b.enemy.speed or speed)
    local lines={number(stats[1]).." maximum HP.",number(stats[2]).." attack before enemy armor.",number(stats[3]).."% damage reduction (60% cap).",number(speed).." speed: turn order and hit chance.",hit.."% hit chance.",(100-hit).."% miss chance.","Level "..pet.level.." | "..P.XPText(pet)}
    result=lines[index] or ""
  else result=statHelp(pet,index)end
  if F.db.settings.showPetRollRanges and index<=4 then
    local low,high,rank=P.BaseRollRange(pet,index)
    if low then
      local base=P.StatBreakdown(pet)[index].base
      result=result.."\nBase: "..P.RollNumber(number(base),rank).." ("..number(low).." - "..number(high)..")\nRoll: "..P.RollNumber(tostring(rank),rank).." / 100"..(rank==100 and " |cffffd166Perfect roll!|r" or rank>=91 and " | Top 10%" or "")
    else result=result.."\nLegacy / fixed stats: no random roll recorded."end
  end
  return result
end
local abilityHelp=P.AbilityHelp
function P.AbilityHelp(a)
  if type(a)~="table"then return abilityHelp(a)end
  local result=abilityHelp(a)
  if F.db.settings.shortPetTooltips then
    result=result:gsub(" Own (%d+)%-turn cooldown%. One special per pet per turn%."," | Own %1-turn cooldown; 1 special/turn"):gsub(" Activate with Heal in normal tower combat%.","")
  end
  if a.rollTier then
    result=P.abilityQualities[a.rollTier].." ability\n"..result
    if F.db.settings.showPetRollRanges then
      local low=P.AbilityRollFactor(a.rollTier,1);local high=P.AbilityRollFactor(a.rollTier,100)
      local key,value,base,cap="Damage",a.power,a.basePower,10
      if a.effect=="drain" then key,value,base="Lifesteal",a.healing,a.baseHealing
      elseif a.effect=="renew"then key,value,base="Max-HP healing",a.healing,a.baseHealing
      elseif a.effect=="shield"then key,value,base,cap="Damage reduction",a.reduction,a.baseReduction,.75 end
      result=result.."\n"..key..": "..P.RollNumber(number(value*100).."%",a.rollPercentile).." ("..number(math.min(cap,base*low)*100).." - "..number(math.min(cap,base*high)*100).."%)"
        .."\nRoll: "..P.RollNumber(tostring(a.rollPercentile),a.rollPercentile).." / 100"..(a.rollPercentile==100 and " |cffffd166Perfect roll!|r" or a.rollPercentile>=91 and " | Top 10%" or "")
    end
  elseif F.db.settings.showPetRollRanges then result=result.."\nLegacy / fixed ability: no random roll recorded."end
  return result
end
