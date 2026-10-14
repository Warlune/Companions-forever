local _,F=...
local P,H=F.Pets,F.Pets.HardMode
local function trainee()
 local pet=P.Active()
 return pet and not pet.deadAt and pet.level<P.LevelCap() and not P.state.battle and pet or nil
end
function H.ConfirmedJump()
 if not P.state or not H.IsUnlocked()then return end
 local h=P.state.hardMode;local rank=H.TrainingRank("pocketChange")
 if rank>0 then
  local goal=120-rank*20
  h.jumpTokenProgress=math.min(h.jumpTokenProgress or 0,goal-1)+1
  if h.jumpTokenProgress>=goal then
   h.jumpTokenProgress=0;P.ChangeTokens(1,"JUMP","Pocket Change")
  end
 end
 rank=H.TrainingRank("hopAlong");local pet=rank>0 and trainee()
 if pet then
  local goal=120-rank*20
  h.jumpXPProgress=math.min(h.jumpXPProgress or 0,goal-1)+1
  if h.jumpXPProgress>=goal then h.jumpXPProgress=0;P.AddXP(pet,1,"utility")end
 end
end
local tick=P.Tick
function P.Tick(seconds)
 tick(seconds)
 if not P.state or not H.IsUnlocked()then return end
 local rank=H.TrainingRank("daydream");if rank==0 then return end
 local h=P.state.hardMode;local pet=trainee()
 if not pet or not pet.resting or pet.food<10 or not P.InRestArea()then return end
 if h.restXPPet~=pet.id then h.restXPPet=pet.id;h.restXPSeconds=0 end
 local goal=140-rank*20
 h.restXPSeconds=math.min(h.restXPSeconds or 0,goal-0.001)+math.max(0,math.min(5,seconds))
 if h.restXPSeconds>=goal then h.restXPSeconds=h.restXPSeconds-goal;P.AddXP(pet,1,"utility")end
end
