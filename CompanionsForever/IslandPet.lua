local _,F=...
local I,H,P=F.Housing.Island,F.Housing,F.Pets
function I.IslandPet()
 local chosen=H.Pet();if chosen and chosen.species==3 then return chosen end
 local active=P.Active();if active and active.species==3 and not active.deadAt then return active end
 for _,pet in ipairs(P.state.pets)do if pet.species==3 and not pet.deadAt then return pet end end
 return chosen or (active and not active.deadAt and active)
end
function I.PetGroundFree(x,y)
 for _,d in ipairs({{-.45,-.45},{.45,-.45},{-.45,.45},{.45,.45}})do if not I.OwnedAt(x+d[1],y+d[2])then return false end end
 for _,o in ipairs(F.char.islandPrototype.items or {})do if o.key~='rug'and o.z<2 then
  local w,h=I.Footprint(o)
  if math.abs(x-o.x)<w+.45 and math.abs(y-o.y)<h+.45 then return false end
 end end
 return true
end
function I.PetPathClear(x,y,tx,ty)
 local distance=math.sqrt((tx-x)^2+(ty-y)^2)
 local steps=math.max(1,math.ceil(distance/.3))
 for j=0,steps do if not I.PetGroundFree(x+(tx-x)*j/steps,y+(ty-y)*j/steps)then return false end end
 return true
end
function I.BuildIslandPet(f)
 if rawget(f,'roamingPet')then return end
 local r={actor=f.objectScene:CreateActor(),seed=719,wait=0};f.roamingPet=r;r.actor:Hide()
 local function random()r.seed=r.seed*48271%2147483647;return r.seed/2147483647 end
 local function animate(walk)
  if r.walking==walk then return end;r.walking=walk
  r.actor:SetAnimation(walk and (P.animations.walk or 4)or 0,0,1,0)
 end
 local function home()
  for radius=0,39 do for x=-radius,radius do for _,y in ipairs({-radius,radius})do
   if I.PetGroundFree(x,y)then r.x,r.y=x,y;r.tx=nil;r.wait=1;return true end
  end end end
 end
 I.HookViewportUpdate(f,function(_,dt)
  r.poll=(r.poll or 0)+dt
  if r.poll>=1 or not r.pet then
   r.poll=0;local pet=I.IslandPet();local model=pet and P.ModelFor(pet)
   local display=model and model.display
   if r.display~=display then
    r.display=display;r.pet=pet;r.ready=false;r.failed=false;r.age=0;r.actor:Hide();r.walking=nil
    if display then
     r.actor:SetScale(1);r.actor:SetUseCenterForOrigin(true,true,true)
     local ok,result=pcall(r.actor.SetModelByCreatureDisplayID,r.actor,display);r.failed=not ok or result==false
    end
   end
  end
  if not r.pet or r.failed then return end
  if not r.ready then
   r.age=r.age+dt
   if r.actor:IsLoaded()then
    local w,d,h=I.ModelBounds(r.actor)
    if w then r.scale=2.2/math.max(w,d);r.height=h;r.actor:SetScale(r.scale);r.ready=home();r.actor:SetYaw(0)end
   end
   if r.age>8 and not r.ready then r.failed=true end
   if not r.ready then return end
  end
  dt=math.min(.05,dt)
  if not I.PetGroundFree(r.x,r.y)then if not home()then r.actor:Hide();return end end
  local paused=F.db.settings.reduceMotion or f.editor.drag or f.editor.gizmoDrag or f.editor.placing
  r.wait=math.max(0,r.wait-dt)
  if not paused and r.tx then
   local dx,dy=r.tx-r.x,r.ty-r.y;local distance=math.sqrt(dx*dx+dy*dy)
   local step=math.min(distance,dt*1.5)
   if distance<.05 or not I.PetPathClear(r.x,r.y,r.tx,r.ty)then r.tx=nil;r.wait=1+random()*3;animate(false)
   else r.x=r.x+dx/distance*step;r.y=r.y+dy/distance*step;r.actor:SetYaw(H.WalkYaw(dx,dy));animate(true)end
  else
   animate(false)
   if not paused and r.wait==0 then
    for _=1,16 do local a=random()*math.pi*2;local length=2+random()*5;local x,y=r.x+math.cos(a)*length,r.y+math.sin(a)*length
     if I.PetPathClear(r.x,r.y,x,y)then r.tx,r.ty=x,y;break end
    end
    r.wait=.5
   end
  end
  I.Position(r,r.x,r.y,r.height*r.scale/2);r.actor:Show()
 end)
 f:HookScript('OnHide',function()animate(false)end)
end
local open=I.Open
function I.Open(...)open(...);I.BuildIslandPet(I.ui)end
