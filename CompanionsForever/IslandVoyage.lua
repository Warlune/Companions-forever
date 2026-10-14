local _,F=...
local I,H,P=F.Housing.Island,F.Housing,F.Pets
local L=I.Life
local function distance(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)end
local function copy(o)local r={};for _,k in ipairs({'id','key','x','y','z','yaw','pitch','roll','size','quality','paid'})do r[k]=o[k]end;return r end
local function contains(t,id)for _,v in ipairs(t.ids)do if v==id then return true end end end
local function boatByID(id)for _,o in ipairs(F.char.islandPrototype.items or {})do if o.id==id and I.IsBoat(o)then return o end end end
-- Prefer water around foundations. Enclosed ponds may cross land to reach the
-- fixed offshore route; a ring of purchased land must not block expeditions.
function I.BoatRoute(o)
 if not I.CanPlaceBoat(o)then return end
 local radius=I.BoatClearance(o)
 local land=F.char.islandPrototype.land or I.LandState();local mask=0
 for _,p in pairs(land)do mask=mask+2^((p.x+2)*5+p.y+2)end
 local signature=table.concat({o.x,o.y,o.yaw,o.size,radius,I.foundationWidth,mask,I.navRevision or 0},':')
 if I.boatRouteCache and I.boatRouteCache.signature==signature then return I.boatRouteCache.route end
 local function enclosedRoute()
  local route={{x=o.x,y=o.y},{x=-96,y=96},{x=-1350,y=1300},{x=-1800,y=1640}}
  route.harborEnd=2;route.crossesLand=true
  I.boatRouteCache={signature=signature,route=route};return route
 end
 local function free(x,y)return I.BoatWaterClear(o,x,y,land)end
 local function segment(a,b)
  local n=math.max(1,math.ceil(distance(a,b)))
  for j=0,n do local t=j/n;if not free(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t)then return false end end
  return true
 end
 local nodes={};local start,best=nil,math.huge
 for x=-96,96,4 do for y=-96,96,4 do if free(x,y)then
  local node={x=x,y=y,key=x..':'..y};nodes[node.key]=node
  local d=distance(o,node);if d<best and d<9 and segment(o,node)then start=node;best=d end
 end end end
 if not start then return enclosedRoute()end
 local queue={start};local seen={[start.key]=true};local previous={};local cursor=1
 while cursor<=#queue do local node=queue[cursor];cursor=cursor+1
  if node.x==-96 and node.y==96 then
   local route={};while node~=start do table.insert(route,1,{x=node.x,y=node.y});node=previous[node.key]end
   table.insert(route,1,{x=start.x,y=start.y});table.insert(route,1,{x=o.x,y=o.y})
   route.harborEnd=#route
   -- Follow the inner bay to the pale ledge below the northern woodland.
   route[#route+1]={x=-1350,y=1300};route[#route+1]={x=-1800,y=1640}
   I.boatRouteCache={signature=signature,route=route};return route
  end
  for _,d in ipairs({{4,0},{-4,0},{0,4},{0,-4}})do local nextNode=nodes[(node.x+d[1])..':'..(node.y+d[2])]
   if nextNode and not seen[nextNode.key]and segment(node,nextNode)then seen[nextNode.key]=true;previous[nextNode.key]=node;queue[#queue+1]=nextNode end
  end
 end
 return enclosedRoute()
end
-- Smooth the visual clock between the economy's one-second ticks. Keeping a
-- separate clock never changes rewards, trip duration or offline catch-up.
function I.StepVoyageClock(f,dt)
 local trip=L.State().trip
 if not trip then f.voyageClock=nil;return end
 local c=rawget(f,'voyageClock')
 if not c or c.trip~=trip then c={trip=trip,value=trip.elapsed};f.voyageClock=c end
 c.value=math.min(trip.elapsed+.999,math.max(trip.elapsed,c.value)+I.Clamp(dt,0,.1));c.observed=trip.elapsed
end
local start=L.StartExpedition
function L.StartExpedition(...)
 local boat=L.Station('expedition')
 if not boat then return false,'Place an expedition boat in water beside your island.'end
 local route=I.BoatRoute(boat)
 if not route then return false,'Move the boat clear of the foundation before departing.'end
 local ok,why=start(...)
 if ok then
  local trip=L.State().trip;trip.boatID=boat.id;trip.departElapsed=nil
  I.voyageCache={trip=trip,boat=copy(boat),route=route}
 end
 return ok,why
end
local validate=L.ValidateSave
function L.ValidateSave(...)
 validate(...)
 local trip=L.State().trip;if not trip then return end
 if type(trip.boatID)~='number'or trip.boatID%1~=0 or trip.boatID<1 or trip.boatID>=1000000 then trip.boatID=nil end
 if type(trip.departElapsed)~='number'or trip.departElapsed~=trip.departElapsed or trip.departElapsed<0 or trip.departElapsed>trip.elapsed then trip.departElapsed=nil end
 I.voyageCache=nil
 I.boatRouteCache=nil
end
function I.VoyagePose(f)
 local trip=L.State().trip;if not trip then I.voyageCache=nil;return end
 local cache=I.voyageCache
 if not cache or cache.trip~=trip then
  local boat=boatByID(trip.boatID)or L.Station('expedition')
  if not boat then return {trip=trip,phase='away'}end
  local route=I.BoatRoute(boat);if not route then return {trip=trip,phase='away'}end
  cache={trip=trip,boat=copy(boat),route=route};I.voyageCache=cache
  -- Resume an in-progress/offline voyage without replaying its departure.
  if trip.elapsed>90 and not trip.departElapsed then trip.departElapsed=0 end
 end
 if not trip.departElapsed then
  local aboard=true
  for _,id in ipairs(trip.ids)do
   local found=false;for _,r in ipairs(f.roamingPets or {})do if r.pet and r.pet.id==id and r.aboard==cache.boat.id then found=true end end
   if not found then aboard=false end
  end
  if aboard then
   trip.departElapsed=trip.elapsed
   local clock=rawget(f,'voyageClock');if clock and clock.trip==trip then clock.value=trip.elapsed end
  end
 end
 local clock=rawget(f,'voyageClock');local now=clock and clock.trip==trip and clock.observed==trip.elapsed and clock.value or trip.elapsed
 local elapsed=trip.departElapsed and math.max(0,now-trip.departElapsed)or 0
 local pose={trip=trip,boat=cache.boat,x=cache.boat.x,y=cache.boat.y,yaw=cache.boat.yaw,phase='boarding'}
 if not trip.departElapsed then return pose end
 if elapsed>=72 then pose.phase='away';return pose end
 local route=cache.route
 -- Give the harbor its own travel time, so the long offshore stretch cannot
 -- make the boat skip several shoreline corners between rendered frames.
 local first,last=2,route.harborEnd
 local fraction=elapsed/20
 if elapsed>=20 then first,last=route.harborEnd+1,#route;fraction=(elapsed-20)/40 end
 local total=0;for j=first,last do total=total+distance(route[j-1],route[j])end
 local remaining=math.min(1,fraction)*total
 for j=first,last do local a,b=route[j-1],route[j];local length=distance(a,b)
  if remaining<=length or j==last then
   local t=length>0 and math.min(1,remaining/length)or 1
   -- The rowboat's bow faces -X; creatures walk toward +X.
   pose.x=a.x+(b.x-a.x)*t;pose.y=a.y+(b.y-a.y)*t;pose.yaw=H.WalkYaw(b.x-a.x,b.y-a.y)+math.pi;break
  end
  remaining=remaining-length
 end
 pose.phase=elapsed<60 and 'sailing'or 'landing';pose.landing=I.Clamp((elapsed-60)/12,0,1)
 return pose
end
local function seat(boat,index,x,y,yaw)
 local b=I.decorByKey[boat.key].bounds;local size=boat.size
 local width=b and b[1]or 5;local depth=b and b[2]or 2
 local offset=(index-2)*math.max(width,depth)*size*.22
 local sx,sy=width>=depth and offset or 0,depth>width and offset or 0
 return x+sx*math.cos(yaw)-sy*math.sin(yaw),y+sx*math.sin(yaw)+sy*math.cos(yaw),I.BoatWaterLevel()+(b and b[3]or 2)*size*.45
end
local function animate(r,id)
 if r.voyageAnimation~=id then r.voyageAnimation=id;r.walking=nil
  -- SitGround=97 in the client's AnimationData; unsupported creature poses
  -- fall back to idle. https://gist.github.com/Marlamin/91e5f37a1ba4d2276550525133095f5b
  local ok,result=pcall(r.actor.SetAnimation,r.actor,id,0,1,0)
  if not ok or result==false then r.actor:SetAnimation(0,0,1,0)end
 end
end
function I.UpdateVoyagePet(f,r,pet,slot,dt)
 local pose=I.VoyagePose(f);local crew=pose and contains(pose.trip,pet.id)
 if r.voyageTrip and (not crew or r.voyageTrip~=pose.trip)and f.followPetID==pet.id then f.voyageFollow=true;f:StopFlight()end
 r.voyageTrip=crew and pose.trip or nil
 local boat=crew and pose.boat or slot.job=='expedition'and L.Station('expedition')or nil
 if crew and pose.phase=='away'then
  r.voyage=true;r.actor:Hide();r.zzz:Hide();r.xpText:Hide()
  if f.followPetID==pet.id then f.voyageFollow=true;f:StopFlight();if rawget(f,'workshop')then f.workshop:RefreshTools()end end
  return true
 end
 -- Boarding owns the whole approach, not just the final step from a land
 -- station. Expedition pets may walk over water directly to their seat; a
 -- failed island-only route must never leave them waiting at the shoreline.
 if boat then
  local x,y,z=seat(boat,r.index,crew and pose.x or boat.x,crew and pose.y or boat.y,crew and pose.yaw or boat.yaw)
  r.basePetScale=r.basePetScale or r.scale
  local boarding=not crew or pose.phase=='boarding'
  if boarding and r.aboard~=boat.id then
   if r.boarding~=boat.id then
    r.boarding=boat.id;r.boardStart={x=r.x,y=r.y,z=r.z or 0};r.boardElapsed=0;r.boardWaterAt=nil
    r.boardDuration=math.max(3,distance(r,{x=x,y=y})/1.8)
   end
   r.boardElapsed=math.min(r.boardDuration,r.boardElapsed+dt);local t=r.boardElapsed/r.boardDuration
   r.x=r.boardStart.x+(x-r.boardStart.x)*t;r.y=r.boardStart.y+(y-r.boardStart.y)*t
   -- Walk over the foundation first; descend to the boat only after clearing
   -- the stone edge, rather than cutting diagonally through the slab.
   local shoreZ=math.max(0,r.boardStart.z,z)
   if I.FoundationAt(r.x,r.y,.25)then r.z=shoreZ;r.boardWaterAt=nil
   else
    r.boardWaterAt=r.boardWaterAt or t
    local progress=I.Clamp((t-r.boardWaterAt)/math.max(.001,1-r.boardWaterAt),0,1)
    r.z=shoreZ+(z-shoreZ)*progress
   end
   r.actor:SetYaw(H.WalkYaw(x-r.boardStart.x,y-r.boardStart.y));animate(r,4)
   if t>=1 then r.aboard=boat.id;r.boarding=nil;r.z=z end
  else
   r.aboard=boat.id;r.boarding=nil;r.x,r.y,r.z=x,y,z;r.actor:SetYaw((crew and pose.yaw or boat.yaw)+math.pi);animate(r,97)
   if crew and pose.phase=='landing'then
    local t=pose.landing;r.x=x+(-1950+r.index*2-x)*t;r.y=y+(1900-y)*t;r.z=z+(8.52-z)*t
    r.actor:SetYaw(H.WalkYaw(-1950-x,1900-y));animate(r,4)
   end
  end
  -- Seat sizing belongs only to seated crew. Keep island/water approaches
  -- and the walk ashore at the pet's normal housing size.
  local seated=r.aboard==boat.id and not (crew and pose.phase=='landing')
  r.scale=r.basePetScale*(seated and math.min(1,boat.size*.34)or 1);r.actor:SetScale(r.scale)
  r.voyage=true;r.path=nil;I.Position(r,r.x,r.y,r.z);r.actor:Show();r.zzz:Hide();r.xpText:Hide()
  if f.followPetID==pet.id then f.voyageFollow=true end
  return true
 end
 if r.voyage then
  r.voyage=nil;r.aboard=nil;r.boarding=nil;r.voyageAnimation=nil;r.atStation=false;r.station=nil;r.path=nil;r.wait=0;r.z=0;r.walking=nil
  if r.basePetScale then r.scale=r.basePetScale;r.basePetScale=nil;r.actor:SetScale(r.scale)end
  if f.followPetID==pet.id then f.voyageFollow=true;f:StopFlight()end
 end
 return false
end
function I.BuildVoyage(f)
 if rawget(f,'voyageBuilt')then return end;f.voyageBuilt=true
 I.HookViewportUpdate(f,function()
  local pose=I.VoyagePose(f)
  for _,v in ipairs(f.editor.actors)do if v.used and v.ready and I.IsBoat(v.object)then
   if pose and pose.boat and v.object.id==pose.boat.id then
    if pose.phase=='away'then v.actor:Hide()
    else
     v.actor:SetYaw(pose.yaw);I.Position(v,pose.x,pose.y,I.BoatWaterLevel()+v.height*v.scale*.15);v.actor:Show()
    end
    v.wasSailing=true
   elseif v.wasSailing then v.wasSailing=nil;f.editor:Transform(v,v.object)end
  end end
 end)
end
local open=I.Open
function I.Open(...)open(...);I.BuildVoyage(I.ui)end
