local _,F=...
local I,P,S=F.Housing.Island,F.Pets,F.Style
I.parcelSize=16
I.parcelPrice=500
I.parcelPriceStep=250
local function key(x,y)return x..':'..y end
local function coordinate(n)return type(n)=='number'and n==math.floor(n)and math.abs(n)<=2 end
function I.LandState()
 I.SavedScene()
 local db=F.char.islandPrototype
 local clean={['0:0']={x=0,y=0}}
 if type(db.land)=='table'then
  -- Only keep bounded parcels connected to the starting island.
  for _=1,8 do for _,p in pairs(db.land)do
   if type(p)=='table'and coordinate(p.x)and coordinate(p.y)and
    (clean[key(p.x-1,p.y)]or clean[key(p.x+1,p.y)]or clean[key(p.x,p.y-1)]or clean[key(p.x,p.y+1)])then clean[key(p.x,p.y)]={x=p.x,y=p.y}end
  end end
 end
 db.land=clean;return clean
end
function I.CanBuyLand(x,y)
 if not coordinate(x)or not coordinate(y)then return false,'Outside the expansion area.'end
 local land=I.LandState()
 if land[key(x,y)]then return false,'You already own this land.'end
 if not(land[key(x-1,y)]or land[key(x+1,y)]or land[key(x,y-1)]or land[key(x,y+1)])then return false,'Choose land touching your island.'end
 local price=I.LandPrice(land)
 if not P.state or type(P.state.tokens)~='number'or P.state.tokens<price then return false,'You need '..price..' gold.'end
 return true
end
function I.LandPrice(land)
 local count=0;for _ in pairs(land or I.LandState())do count=count+1 end
 return I.parcelPrice+I.parcelPriceStep*math.max(0,count-1)
end
function I.BuyLand(x,y)
 if I.PrepareLandRefund then I.PrepareLandRefund()end
 local ok,reason=I.CanBuyLand(x,y);if not ok then return false,reason end
 local price=I.LandPrice()
 local _,paid=P.ChangeTokens(-price,'HOUSINGLAND',key(x,y))
 if paid~=-price then return false,'Purchase could not be completed.'end
 F.char.islandPrototype.land[key(x,y)]={x=x,y=y}
 I.navRevision=(I.navRevision or 0)+1
 return true,'Land purchased. Your island has grown!'
end
function I.OwnedAt(x,y)
 local land=F.char.islandPrototype.land or I.LandState()
 return land[key(math.floor((x+8)/16),math.floor((y+8)/16))]~=nil
end
function I.Footprint(o,collision)
 local d=I.decorByKey[o.key];local h=F.Housing.byKey[o.key]
 if d.bounds and not collision then
  local b=d.bounds;local w,depth,height=b[1]*o.size/2,b[2]*o.size/2,b[3]*o.size/2
  local ex,ey=0,0
  for _,x in ipairs({-w,w})do for _,y in ipairs({-depth,depth})do for _,z in ipairs({-height,height})do
   local rx,ry=I.RotateOffset(o,x,y,d.groundOrigin and z+height or z)
   ex=math.max(ex,math.abs(rx));ey=math.max(ey,math.abs(ry))
  end end end
  return ex,ey
 end
 local ratio=d.depthRatio or (h and h.h/h.w) or 1
 local factor=collision and (d.collision or .62)or 1
 local w=d.width*o.size/2*factor;local depth=w*ratio
 local c,s=math.abs(math.cos(o.yaw)),math.abs(math.sin(o.yaw))
 return w*c+depth*s,depth*c+w*s
end
function I.CanPlace(o,items)
 if I.VoyageBoatLocked and I.VoyageBoatLocked(o.id)then return false,'Finish or cancel the voyage before moving its boat.'end
 if I.IsBoat and I.IsBoat(o)then return I.CanPlaceBoat(o)end
 local w,h=I.Footprint(o)
 -- Check every grid crossing, not just corners (L-shaped coastlines have holes).
 local land=F.char.islandPrototype.land or I.LandState()
 for x=math.floor((o.x-w+8)/16),math.floor((o.x+w+8-.001)/16)do for y=math.floor((o.y-h+8)/16),math.floor((o.y+h+8-.001)/16)do
  if not land[key(x,y)]then return false,'Blocked: outside owned land.'end
 end end
 if o.z<0 then return false,'Blocked: below the ground.'end
 return true,'Ready to place.'
end
function I.CacheDecorBounds(key,w,d,h)
 local entry=I.decorByKey[key];if not entry then return end
 local scale=entry.width/math.max(w,d)
 entry.bounds={w*scale,d*scale,h*scale};entry.depthRatio=d/math.max(w,d)
end
function I.Walkable(key)return key=='rug'or I.decorByKey[key]and I.decorByKey[key].walkable==true end
-- Controls share a bottom dock inside the scene; no reserved side column.
function I.Dock(f,height)
 local p=S.Panel(f,0,0,960,height);p:SetScale(.94);p:ClearAllPoints();p:SetPoint('BOTTOM',f,'BOTTOM',0,58)
 p:SetFrameLevel(f.input:GetFrameLevel()+12);p:EnableMouse(true)
 return p
end
