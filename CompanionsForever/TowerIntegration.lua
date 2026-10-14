local _,F=...
local P,H=F.Pets,F.Pets.HardMode
-- Normal and hard combat remain separate; each battle owns its selected mode.
local function hard()return P.state and P.state.battle and P.state.battle.hard or H.IsHard()end
for _,name in ipairs({"Unlocked","FloorStatus","BattleReadiness","StartBattle","BattleAction","AdvanceBattle","Tick","OpenPage","HealChoice","RequestHeal","CycleStyle","AbilityHelp"})do
 local ordinary,advanced=H.Normal[name],H.Combat[name]
 P[name]=function(...)if hard()then return advanced(...)end;return ordinary(...)end
end
function P.Enemies(...)if H.IsHard()then return H.Enemies(...)end;return H.Normal.Enemies(...)end
function P.TowerXP(floor,first)if H.IsHard()then return math.floor((200+20*floor)*(first and 1 or .6))end;return H.Normal.TowerXP(floor,first)end
function P.TowerLoot(b,first)if b.hard then return H.RewardLoot(b)end;return H.Normal.TowerLoot(b,first)end
function P.CurrentVictory()
 if H.IsHard()then local v=P.victory;if v and v.hard and not P.state.battle and v.floor==P.floor then return v end;return end
 return H.Normal.CurrentVictory()
end
function P.UseCare(item)
 if H.IsHard() and item=="medicine" and (P.mode=="tower" or P.miniMode=="tower" and F.char.navPets)then return P.RequestHeal()end
 return H.Normal.UseCare(item)
end
local battleAction=P.BattleAction
function P.BattleAction(...)
 local ok,msg=battleAction(...);if ok then H.RefreshUnlock()end;return ok,msg
end
function P.Init()H.Normal.Init();H.Initialize()end
function P.Select(id)
 local ok,msg=H.Normal.Select(id);if ok and H.IsHard()then P.floor=math.min(100,P.state.hardMode.best+1)end;return ok,msg
end
local unit=H.Unit
function H.Unit(id,b)
 b=b or P.state.battle
 if b and not b.hard and b.petID==id then return b end
 return unit(id,b)
end
-- World XP can arrive during a battle. Only its actual recipient gains the heal.
function P.AddXP(pet,amount,source)
 -- Carry fractional bonuses so a one-XP world kill still benefits from gear.
 -- The anti-pull budget counts base kill XP; equipped gear and training add afterward.
 local base=math.max(0,math.floor(amount));local gear=(source=="utility" or source=="treat") and 0 or H.XPBonus(pet)
 local training=source=="kill" and H.TrainingRank("worldXP")*25 or source=="tower" and not H.IsHard() and H.TrainingRank("towerXP")*10 or 0
 local factor=(100+gear)*(100+training)
 if pet and not pet.deadAt and pet.level<P.LevelCap() and base>0 and factor>10000 then
  local carry=pet.bonusXPUnits
  if type(carry)~="number" or carry~=math.floor(carry) or carry<0 or carry>=10000 then carry=0 end
  local bonus=base*(factor-10000)+carry
  pet.bonusXPUnits=bonus%10000;amount=base+math.floor(bonus/10000)
 end
 local old=pet and pet.level;local xp=H.Normal.AddXP(pet,amount,source)
 if pet and pet.level>=P.LevelCap()then pet.bonusXPUnits=0 end
 local b=P.state.battle
 if b and b.hard and pet and pet.level>old then
  for _,u in ipairs(b.allies)do if u.pet==pet and not pet.deadAt then u.maxHP,u.attack,u.armor,u.speed=P.Stats(pet);u.hp=u.maxHP end end
  local first=b.allies[1];b.hp=first.hp;b.maxHP=first.maxHP;b.attack=first.attack;b.armor=first.armor;b.speed=first.speed
 end
 return xp
end
