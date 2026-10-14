local _,F=...
local I=F.Housing.Island
-- Composition uses only M2s visually checked in this client. Discovery candidates
-- stay in the lab; no speculative model, WMO or world terrain is auto-loaded.
I.coastVerified={}
for _,id in ipairs({189528,202710,189927,201223,201224,190311,514776,189692,189744,
 189629,189632,197240,197241,372897,242696,190511,189904,190095,
 531274,243881,195782,195783,522491,522498,203569,190623})do I.coastVerified[id]=true end

function I.CoastCamera(name)
 if name=='map'then return{x=0,y=0,z=30000,yaw=math.pi/2,pitch=-1.569,explore=true}end
 if name=='stacks'then return{x=550,y=-1150,z=480,yaw=-.68,pitch=-.14,explore=true}end
 return{x=-1700,y=400,z=430,yaw=2.08,pitch=-.13,explore=true}
end

function I.BuildCoast(f)
 local function item(id,x,y,z,width,anchor,yaw)
  assert(I.coastVerified[id],'Coast model needs a live visual check')
  local a=assert(I.SceneryAsset('coast',id),'Coast model missing from catalog')
  local v=f.AddScenery('coast',x,y,z,width,anchor=='top',a)
  v.bottom=anchor=='bottom';v.actor:SetYaw(yaw or 0)
  return v
 end
 -- North is +Y, west is -X. The water plane spans roughly +/-5000.
 -- These overlapping banks follow the sketch's western inlet and northern cape.
 -- The central player land and its saved parcels are deliberately untouched.
 local banks={
  {-4900,-1450,1700,135},{-4620,-420,1750,160},{-4440,700,1800,185},
  {-3970,1690,1900,205},{-3190,2260,1900,180},{-2040,2670,1700,170},
  {-990,3310,1750,210},{-440,4320,1800,195},{800,4780,2050,165},
  {2320,4910,2100,150},{3800,4850,1900,140},
  {-5400,1790,2550,230},{-4860,3720,2600,260},{-3230,4290,2400,220},
  {-1840,4910,2200,210},
 }
 for j,p in ipairs(banks)do
  item(202710,p[1],p[2],12+j*.07,p[3]*1.55,'top',j*.91)
  item(189528,p[1],p[2],85,p[3]*.38,'top',j*.91)
  -- Broad canopies and varied firs break up the skyline over the low slab.
  for n=1,24 do
   local angle=n*2.399+j*.71;local radius=p[3]*(.08+.019*(n%17))
   local x,y=p[1]+math.cos(angle)*radius,p[2]+math.sin(angle)*radius
   local z=0
   -- Booty Bay's leaning tree has exposed cut ends at this angle. Use rooted
   -- oaks and upright firs instead, with their bases slightly buried.
   local id=n%5==0 and 201223 or n%4==0 and 201224 or 189927
   item(id,x,y,z,160+(j*17+n*29)%110,'bottom',angle)
  end
  for n=1,3 do
   local a=n*2.1+j*.5
   item(n%2==0 and 189692 or 514776,p[1]+math.cos(a)*p[3]*.20,p[2]+math.sin(a)*p[3]*.20,6,160,'bottom',a)
  end
 end
 -- An irregular rocky ridge inland behind the woods fills the distant skyline.
 -- These are verified Grizzly Hills meshes, not enlarged dirt pyramids.
 for j,p in ipairs({{-6100,-1500,1700},{-6250,-100,2100},{-6200,1550,2300},
  {-6050,3330,1900},{-4880,5100,2300},{-3280,5830,2000},
  {-1670,6120,2350},{120,6420,2200},{1920,6530,2400},
  {3710,6380,2150},{5220,5900,1850}})do
  item(j%2==0 and 195783 or 195782,p[1]*1.45,p[2]*1.45,-240,p[3]*.70,'bottom',j*.83)
 end
 -- Pale low ledges give the shoreline a beach-like margin until a better
 -- actual sand mesh is verified. They are not advertised as sand terrain.
 for j,p in ipairs({{-4100,-650,950},{-3730,500,950},{-3290,1460,1100},
  {-2140,2030,980},{-1080,2600,950},{-140,3620,1000},{1290,4210,1100}})do
  item(202710,p[1],p[2],8+j*.13,p[3],'top',j*.7)
 end
 -- Castle on a supported stone headland, toward the upper-left of the map.
 item(202710,-4200,2640,205,780,'top',.5)
 item(203569,-4530,2830,235,510,'top',1.3)
 for _,p in ipairs({{-4370,2510},{-4030,2510},{-4370,2810},{-4030,2810}})do
  item(189629,p[1],p[2],203,95,'bottom',0)
 end
 item(197240,-4200,2740,203,210,'bottom',0)
 item(189632,-4200,2890,203,110,'bottom',0)
 item(242696,-4200,2560,203,160,'bottom',0)
 for _,p in ipairs({{-4200,2480,0},{-4200,2820,0},{-4390,2650,math.pi/2},{-4010,2650,math.pi/2}})do
  item(372897,p[1],p[2],204,300,'bottom',p[3])
 end
 -- Smaller harbor on the inner western coast; ships remain offshore.
 item(202710,-3550,1140,15,460,'top',.1)
 item(190511,-3650,1190,14,70,'bottom',0)
 item(190095,-3430,1040,12,160,'top',.6)
 item(189904,-3290,980,10,130,'top',.6)
 for _,p in ipairs({{-3020,40,260,.95},{-1790,1380,285,.7},{720,2870,260,.5}})do
  local ship=item(531274,p[1],p[2],0,p[3],'bottom',p[4])
  ship.waterline=.07
 end
 -- Additional working ships on the ocean side. Forsaken ships are distinct
 -- scenery, not placeholders for the still-unverified Barrens pirate hull.
 for _,p in ipairs({{243881,2850,-2020,280,-.65},{243881,-2350,-3540,250,.45},
  {531274,1340,-3270,245,2.25}})do
  local ship=item(p[1],p[2],p[3],0,p[4],'bottom',p[5])
  ship.waterline=p[1]==243881 and .10 or .07
 end
 -- Scattered tall pale stacks, not a ring or a wall around the player's land.
 local stacks={{4190,2160,200},{4250,-950,250},{3680,-3800,290},
  {1780,-4390,215},{-830,-3960,255},{-3850,-3670,250}}
 for j,p in ipairs(stacks)do
  item(522491,p[1],p[2],-20,p[3],'bottom',j*.8)
  item(522498,p[1]+p[3]*.7,p[2]-p[3]*.35,-22,p[3]*.8,'bottom',j)
 end
 for j,p in ipairs({{3020,1520},{1990,-10},{3900,410},{2260,-1640},
  {-1950,-1300},{-1130,-2450},{630,-2740},{-320,-3430},{2930,-2690}})do
  item(522498,p[1],p[2],-15,45+(j%4)*18,'bottom',j*.4)
 end
 -- Pirate positions from the sketch are reserved, not filled with a different
 -- faction ship. No Barrens pirate hull has been verified yet.
 f.pirateLocations={{x=-2900,y=-4300},{x=-600,y=-3960},{x=3330,y=-2080}}
end
