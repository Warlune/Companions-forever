local _,F=...
local I,H,P=F.Housing.Island,F.Housing,F.Pets
function I.IslandPet(index)
 local slot=I.Life and I.Life.State().slots[index or 1]
 return slot and I.Life.Pet(slot.petID)
end
function I.PetGroundFree(x,y)
 if not I.OwnedAt(x-.45,y-.45)or not I.OwnedAt(x+.45,y-.45)or not I.OwnedAt(x-.45,y+.45)or not I.OwnedAt(x+.45,y+.45)then return false end
 local revision=I.navRevision or 0
 if not I.petObstacles or I.petObstacleRevision~=revision or I.petObstacleScene~=F.char.islandPrototype then
  I.petObstacles={};I.petObstacleBins={};I.petObstacleRevision=revision;I.petObstacleScene=F.char.islandPrototype
  for _,o in ipairs(F.char.islandPrototype.items or {})do if not I.Walkable(o.key)and o.z<2 then
   local w,h=I.Footprint(o);local obstacle={x=o.x,y=o.y,w=w+.45,h=h+.45};I.petObstacles[#I.petObstacles+1]=obstacle
   -- Index the full footprint, including rotated/oversized furniture. Only
   -- owned land can be walked on, so very large models cannot grow this index.
   for bx=math.max(-10,math.floor((o.x-obstacle.w)/4)),math.min(10,math.floor((o.x+obstacle.w)/4))do
    local column=I.petObstacleBins[bx]or {};I.petObstacleBins[bx]=column
    for by=math.max(-10,math.floor((o.y-obstacle.h)/4)),math.min(10,math.floor((o.y+obstacle.h)/4))do
     local bin=column[by]or {};column[by]=bin;bin[#bin+1]=obstacle
    end
   end
  end end
 end
 local column=I.petObstacleBins[math.floor(x/4)];local bin=column and column[math.floor(y/4)]
 if bin then for _,o in ipairs(bin)do if math.abs(x-o.x)<o.w and math.abs(y-o.y)<o.h then return false end end end
 return true
end
function I.Navigation()
 if I.navigation and I.navigation.revision==(I.navRevision or 0)and I.navigation.scene==F.char.islandPrototype then return I.navigation end
 local n={revision=I.navRevision or 0,scene=F.char.islandPrototype,nodes={},list={}}
 for x=-39,39 do for y=-39,39 do if I.PetGroundFree(x,y)then
  local key=(x+40)*81+y+40;local node={x=x,y=y,key=key};n.nodes[key]=node;n.list[#n.list+1]=node
 end end end
 I.navigation=n;return n
end
local directions={81,-81,1,-1}
local function ahead(a,b)return a.score<b.score or (a.score==b.score and a.distance<b.distance)end
local function push(heap,entry)
 local index=#heap+1
 while index>1 do local parent=math.floor(index/2);if not ahead(entry,heap[parent])then break end;heap[index]=heap[parent];index=parent end
 heap[index]=entry
end
local function pop(heap)
 local first,last=heap[1],table.remove(heap)
 if #heap>0 then
  local index=1
  while index*2<=#heap do
   local child=index*2;if child<#heap and ahead(heap[child+1],heap[child])then child=child+1 end
   if not ahead(heap[child],last)then break end;heap[index]=heap[child];index=child
  end
  heap[index]=last
 end
 return first
end
local function connected(node,near)
 -- Geometry only changes when the editor/land revision changes. Share edge
 -- checks across pets and routes instead of resampling every explored edge.
 node.edges=node.edges or {}
 local clear=node.edges[near.key]
 if clear==nil then
  clear=I.PetPathClear(node.x,node.y,near.x,near.y)
  node.edges[near.key]=clear;near.edges=near.edges or {};near.edges[node.key]=clear
 end
 return clear
end
function I.PetRoute(x,y,tx,ty)
 if I.PetPathClear(x,y,tx,ty)then return {{x=tx,y=ty}}end
 local n=I.Navigation();local start,finish,ds,df=nil,nil,math.huge,math.huge
 for _,node in ipairs(n.list)do
  local a=(x-node.x)^2+(y-node.y)^2;local b=(tx-node.x)^2+(ty-node.y)^2
  if a<ds and a<9 and I.PetPathClear(x,y,node.x,node.y)then start=node;ds=a end
  if b<df and b<9 and I.PetPathClear(node.x,node.y,tx,ty)then finish=node;df=b end
 end
 if not start or not finish then return end
 -- A* prioritizes progress toward the destination; wandering pets no longer
 -- flood-search the entire island for each distant target.
 local queue={};local seen={};local costs={[start.key]=0};local previous={}
 local function enqueue(node,cost)
  local distance=math.abs(node.x-finish.x)+math.abs(node.y-finish.y)
  push(queue,{node=node,cost=cost,distance=distance,score=cost+distance})
 end
 enqueue(start,0)
 while #queue>0 do local entry=pop(queue);local node=entry.node
 if not seen[node.key]then
  seen[node.key]=true
  if node==finish then
   local reverse={};while node do reverse[#reverse+1]={x=node.x,y=node.y};node=previous[node.key]end
   local path={};for j=#reverse,1,-1 do path[#path+1]=reverse[j]end
   if finish.x~=tx or finish.y~=ty then path[#path+1]={x=tx,y=ty}end
   return path
  end
  for _,delta in ipairs(directions)do local near=n.nodes[node.key+delta]
   if near and not seen[near.key]and math.abs(near.x-node.x)+math.abs(near.y-node.y)==1 and connected(node,near)then
    local cost=entry.cost+1
    if not costs[near.key]or cost<costs[near.key]then costs[near.key]=cost;previous[near.key]=node;enqueue(near,cost)end
   end
  end
 end
 end
end
function I.BuildIslandPet(f)
 if rawget(f,'roamingPets')then return end
 f.roamingPets={}
 local labels=CreateFrame('Frame',nil,f.canvas);labels:SetAllPoints();labels:EnableMouse(false);labels:SetFrameLevel(f.input:GetFrameLevel()+1)
 for index=1,3 do
  local r={actor=f.objectScene:CreateActor(),seed=719+index*131,wait=0,index=index};f.roamingPets[index]=r;r.actor:Hide()
  r.zzz=labels:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');r.zzz:SetText('Zzz');r.zzz:SetTextColor(1,.9,.25);r.zzz:Hide()
  r.xpText=labels:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');r.xpText:SetTextColor(.8,.35,1);r.xpText:Hide()
  r.zzz:SetShadowOffset(1,-1);r.xpText:SetShadowOffset(1,-1)
  if index==1 then f.roamingPet=r end
  local function random()r.seed=r.seed*48271%2147483647;return r.seed/2147483647 end
  local function animate(walk)if r.walking~=walk then r.walking=walk;r.actor:SetAnimation(walk and (P.animations.walk or 4)or 0,0,1,0)end end
  local function home()
   local best,distance=nil,math.huge
   for _,node in ipairs(I.Navigation().list)do local d=node.x^2+(node.y-index)^2;if d<distance then best=node;distance=d end end
   if not best then return false end
   r.x,r.y=best.x,best.y;r.path=nil;r.wait=1;r.station=nil;r.atStation=false;return true
  end
  I.HookViewportUpdate(f,function(_,dt)
   local pet=I.IslandPet(index);local slot=I.Life and I.Life.State().slots[index]
   if not pet then r.pet=nil;r.actor:Hide();r.zzz:Hide();r.xpText:Hide();return end
   if r.pet~=pet then
    r.voyage=nil;r.aboard=nil;r.boarding=nil;r.basePetScale=nil;r.voyageAnimation=nil;r.voyageTrip=nil;r.z=0
    r.pet=pet;r.ready=false;r.failed=false;r.age=0;r.actor:Hide();r.walking=nil
    local model=P.ModelFor(pet);local display=model and model.display
    if display then r.actor:SetScale(1);r.actor:SetPosition(0,0,0);r.actor:SetUseCenterForOrigin(true,true,false);local ok,result=pcall(r.actor.SetModelByCreatureDisplayID,r.actor,display);r.failed=not ok or result==false else r.failed=true end
   end
   if r.failed then return end
   local editing=f.editor.drag or f.editor.gizmoDrag or f.editor.placing
   if not r.ready then
    r.age=r.age+dt
    if r.age>.4 and r.actor:IsLoaded()then local w,d,h=I.ModelBounds(r.actor);if w then r.scale=4.5/math.max(w,d);r.height=h;r.actor:SetScale(r.scale);r.ready=home();r.actor:SetYaw(0)end end
    if r.age>8 and not r.ready then r.failed=true end;if not r.ready then return end
   end
   dt=math.min(.05,dt)
   if I.UpdateVoyagePet and I.UpdateVoyagePet(f,r,pet,slot,dt)then return end
   if editing then animate(false);return end
   if not I.PetGroundFree(r.x,r.y)then if not home()then r.actor:Hide();return end end
   local resting=I.Life.IsResting(slot)
   local station=slot.job~='roam'and I.Life.Station(slot.job)or nil
   local revision=I.navRevision or 0
   if r.station~=station or r.job~=slot.job or r.routeRevision~=revision then
    r.station=station;r.job=slot.job;r.routeRevision=revision;r.path=nil;r.wait=0;r.atStation=false
   end
   -- Reduce Motion pauses ambient wandering, not an explicitly assigned trip
   -- to a workstation or boat. Otherwise crew can never reach boarding.
   local paused=(F.db.settings.reduceMotion and not station)or f.editor.drag or f.editor.gizmoDrag or f.editor.placing
   r.wait=math.max(0,r.wait-dt);local target=r.path and r.path[1]
   if not paused and target then
    local dx,dy=target.x-r.x,target.y-r.y;local distance=math.sqrt(dx*dx+dy*dy);local step=math.min(distance,dt*1.8)
    if distance<.05 then
     table.remove(r.path,1);animate(false)
     if #r.path==0 then
      r.path=nil;r.atStation=station~=nil
      if station then r.actor:SetYaw(H.WalkYaw(station.x-r.x,station.y-r.y))end
     end
    elseif not I.PetPathClear(r.x,r.y,target.x,target.y)then r.path=nil;r.wait=1;animate(false)
    else r.x=r.x+dx/distance*step;r.y=r.y+dy/distance*step;r.actor:SetYaw(H.WalkYaw(dx,dy));animate(true)end
   else
    animate(false)
    if not paused and not r.atStation and r.wait==0 then
     local nodes=I.Navigation().list
     for attempt=1,station and 1 or 8 do local destination
      if station then local best=math.huge;local angle=(index-1)*math.pi*2/3;local sx,sy=station.x+math.cos(angle)*2,station.y+math.sin(angle)*2;for _,node in ipairs(nodes)do local d=(node.x-sx)^2+(node.y-sy)^2;if d<best then best=d;destination=node end end
      elseif #nodes>0 then destination=nodes[math.floor(random()*#nodes)+1]end
      if destination then r.path=I.PetRoute(r.x,r.y,destination.x,destination.y);if r.path then break end end
     end
     r.wait=station and 10 or 2+random()*4
    end
   end
   -- Creature origins are at their feet. Animation bounds include wings, tails
   -- and effects, so half the bounding height is not a ground offset.
   I.Position(r,r.x,r.y,0);r.actor:Show()
   local x,y=I.SceneProject(f.scene,r.x,r.y,r.height*r.scale+.4)
   local visible=x and math.abs(x)<1 and math.abs(y)<1
   r.zzz:SetShown(visible and resting)
   local notice=I.Life.xpNotices and I.Life.xpNotices[pet.id]
   if notice and notice.serial~=r.xpSerial then
    r.xpSerial=notice.serial
    if F.Now()-notice.at<=2 then r.xpAge=0;r.xpText:SetText('+'..notice.amount..' XP')end
   end
   if r.xpAge then r.xpAge=r.xpAge+dt;if r.xpAge>=2 then r.xpAge=nil end end
   r.xpText:SetShown(visible and r.xpAge~=nil)
   if visible then
    local px,py=(x+1)*f.input:GetWidth()/2,(y+1)*f.input:GetHeight()/2
    r.zzz:ClearAllPoints();r.zzz:SetPoint('BOTTOM',labels,'BOTTOMLEFT',px,py)
    if r.xpAge then r.xpText:ClearAllPoints();r.xpText:SetPoint('BOTTOM',labels,'BOTTOMLEFT',px,py+18+(F.db.settings.reduceMotion and 0 or r.xpAge*18));r.xpText:SetAlpha(math.min(1,(2-r.xpAge)*2))end
   end
  end)
  f:HookScript('OnHide',function()animate(false)end)
 end
end
