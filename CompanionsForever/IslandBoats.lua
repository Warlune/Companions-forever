local _,F=...
local I,P=F.Housing.Island,F.Pets
local L=I.Life
I.boatShoreReach=16
function I.IsBoat(o)local d=type(o)=='table'and I.decorByKey[o.key];return d and d.station=='expedition'end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function I.ValidBoat(o)
 if not I.IsBoat(o)then return false end
 for _,key in ipairs({'x','y','z','yaw','size'})do if not finite(o[key])then return false end end
 return math.abs(o.x)<=130 and math.abs(o.y)<=130 and o.size>=.25 and o.size<=3 and finite(o.pitch or 0)and finite(o.roll or 0)
end
local function land()return F.char.islandPrototype.land or I.LandState()end
function I.BoatWaterLevel()
 local db=F.char and F.char.islandPrototype
 return db and type(db.waterLevel)=='number'and I.Clamp(db.waterLevel,-6,3)or -2
end
function I.PlacementHeight(key)return I.IsBoat({key=key})and I.BoatWaterLevel()or 0 end
function I.BoatClearance(o)
 -- A rotation-independent hull envelope protects the bow/stern during turns.
 local d=I.decorByKey[o.key];local b=d.bounds
 local width=b and b[1]or d.width;local depth=b and b[2]or d.width*(d.depthRatio or 1)
 return math.sqrt(width*width+depth*depth)*o.size/2+.5
end
function I.BoatWaterClear(o,x,y,plots)
 local extent=I.foundationWidth/2+I.BoatClearance(o)
 for _,p in pairs(plots or land())do
  if math.abs(x-p.x*16)<extent and math.abs(y-p.y*16)<extent then return false end
 end
 return true
end
function I.FoundationAt(x,y,padding)
 local extent=I.foundationWidth/2+(padding or 0)
 for _,p in pairs(land())do if math.abs(x-p.x*16)<extent and math.abs(y-p.y*16)<extent then return true end end
 return false
end
function I.BoatTouchesLand(o,land)
 if not I.ValidBoat(o)then return false end
 return not I.BoatWaterClear(o,o.x,o.y,land)
end
function I.CanPlaceBoat(o)
 if not I.ValidBoat(o)then return false,'Place the boat again from the furnishings store.'end
 if math.abs(math.sin(o.pitch or 0))>.001 or math.abs(math.sin(o.roll or 0))>.001 or math.cos(o.pitch or 0)<0 or math.cos(o.roll or 0)<0 then return false,'Keep the boat upright on the water.'end
 if math.abs(o.z-I.BoatWaterLevel())>.05 then return false,'Boats float at water level. Move them along the shore.'end
 if I.BoatTouchesLand(o,land())then return false,'Move the boat clear of the stone foundation, with room to turn.'end
 local extent=I.foundationWidth/2+I.BoatClearance(o);local nearest=math.huge
 for _,p in pairs(land())do
  local dx=math.max(0,math.abs(o.x-p.x*16)-extent);local dy=math.max(0,math.abs(o.y-p.y*16)-extent)
  nearest=math.min(nearest,math.sqrt(dx*dx+dy*dy))
 end
 if nearest>I.boatShoreReach then return false,'Move the boat a little closer to the island.'end
 return true,'Ready to place in water.'
end
function I.VoyageBoatLocked(id)
 local trip=L.State().trip
 return trip and (trip.boatID==id or not trip.boatID and (function()
  for _,o in ipairs(F.char.islandPrototype.items or {})do if o.id==id then return I.IsBoat(o)end end
 end)())or false
end
-- Invalid legacy land boats remain editable/refundable, but cannot launch.
local station=L.Station
function L.Station(job)
 if job~='expedition'then return station(job)end
 local best
 for _,o in ipairs(F.char.islandPrototype and F.char.islandPrototype.items or {})do
  if I.IsBoat(o)and type(o.paid)=='number'and o.paid%1==0 and o.paid>=5 and o.paid<=L.price and I.CanPlaceBoat(o)and (not best or L.StationSeconds(o)<L.StationSeconds(best))then best=o end
 end
 return best
end
local lockText=L.LockText
function L.LockText(key)
 local d=I.decorByKey[key]
 if d and d.unlock=='crate'and not L.Unlocked(key)then return 'Find in furniture crates.'end
 local text=lockText(key)
 if I.IsBoat({key=key})then text=text..'\nPlace in water beside your island.'end
 return text
end
local buyLand=I.BuyLand
function I.LandVoyage(x,y)
 local trip=L.State().trip;if not trip then return end
 for _,o in ipairs(F.char.islandPrototype.items or {})do
  if I.IsBoat(o)and (not trip.boatID or trip.boatID==o.id)and I.BoatTouchesLand(o,{new={x=x,y=y}})then return trip end
 end
end
function I.BuyLand(x,y,confirmedTrip)
 local ok,why=I.CanBuyLand(x,y);if not ok then return false,why end
 local affected=I.LandVoyage(x,y)
 if affected and affected~=confirmedTrip then
  return false,'This expansion will cancel the expedition and lose its rewards. The boat will be removed and refunded.',affected
 end
 local covered,refund={},0
 local plot={new={x=x,y=y}}
 for _,o in ipairs(F.char.islandPrototype.items or {})do if I.IsBoat(o)and I.BoatTouchesLand(o,plot)then
  covered[o.id]=true
  if type(o.paid)=='number'and o.paid%1==0 and o.paid>=5 and o.paid<=L.price then refund=refund+o.paid end
 end end
 if P.state.tokens-I.LandPrice()+refund>P.maxTokens then return false,'Spend some tokens first so the boat refunds will fit.'end
 ok,why=buyLand(x,y);if not ok then return false,why end
 local count=0;local items=F.char.islandPrototype.items or {}
 local s=L.State();local trip=s.trip
 for j=#items,1,-1 do local o=items[j];if covered[o.id]then
  -- The land purchase removes this placement receipt exactly once. Cancelling
  -- an affected voyage awards nothing and leaves prior completed finds intact.
  if trip and (not trip.boatID or trip.boatID==o.id)then s.trip=nil;s.repeatTrip=false end
  table.remove(items,j);count=count+1
 end end
 if refund>0 then P.ChangeTokens(refund,'HOUSINGREFUND','land:'..x..':'..y)end
 if count>0 then
  local f=I.ui
  if f and f.editor then f:StopFlight();f.editor.selected=nil;f.editor.history={};f.editor:Sync()end
  why=why..' '..count..' boat(s) removed; '..refund..' tokens refunded. Place them again beside the new shore.'
 end
 return true,why
end
