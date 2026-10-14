-- Optional projected contact shading. ModelScene does not expose cast shadows.
local _,F=...
local I=F.Housing.Island
function I.SoftShadowsEnabled()return not F.char or F.char.housingSoftShadows~=false end
function I.SetSoftShadows(enabled)
 if type(enabled)~='boolean'then return false end
 F.char.housingSoftShadows=enabled
 local f=I.ui;local shadows=f and rawget(f,'softShadows')
 if shadows then shadows:Update(true)end
 return true
end
local corners={{0,1},{0,0},{1,1},{1,0}}
local vertices={UPPER_LEFT_VERTEX or 1,LOWER_LEFT_VERTEX or 2,UPPER_RIGHT_VERTEX or 3,LOWER_RIGHT_VERTEX or 4}
local function hideUnused(pool)
 for n=pool.used+1,#pool do pool[n]:Hide()end
end
function I.BuildSoftShadows(f)
 if rawget(f,'softShadows')then return end
 local g=CreateFrame('Frame',nil,f.canvas);f.softShadows=g;g:SetAllPoints();g:EnableMouse(false)
 g:SetFrameLevel(f.scene:GetFrameLevel()+1)
 g.furniture={used=0};g.pets={used=0}
 local function quad(pool,l,b,r,t,ul,ur,vt,vb,alpha)
  local width,height=f.input:GetWidth(),f.input:GetHeight()
  local points={};local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
  for n,c in ipairs(corners)do
   local x,y=I.SceneProject(f.scene,l+(r-l)*c[1],b+(t-b)*c[2],.045)
   if not x or math.abs(x)>16 or math.abs(y)>16 then return end
   x,y=(x+1)*width/2,(y+1)*height/2;points[n]={x,y}
   left,bottom,right,top=math.min(left,x),math.min(bottom,y),math.max(right,x),math.max(top,y)
  end
  if right<0 or left>width or top<0 or bottom>height or right-left<.1 or top-bottom<.1 then return end
  -- A maximum of four parcel pieces per object, bounded even on stress-test saves.
  if pool.used>=400 then return end
  pool.used=pool.used+1;local texture=pool[pool.used]
  if not texture then
   texture=g:CreateTexture(nil,'BACKGROUND');pool[pool.used]=texture
   texture:SetTexture('Interface\\AddOns\\CompanionsForever\\Art\\HousingShadow','CLAMP','CLAMP','LINEAR')
   texture:SetSnapToPixelGrid(false);texture:SetTexelSnappingBias(0)
  end
  texture:ClearAllPoints();texture:SetPoint('BOTTOMLEFT',g,'BOTTOMLEFT',left,bottom);texture:SetSize(right-left,top-bottom)
  texture:SetTexCoord(ul,ur,vt,vb)
  for n,p in ipairs(points)do
   texture:SetVertexOffset(vertices[n],p[1]-(n<=2 and left or right),p[2]-(n%2==1 and top or bottom))
  end
  texture:SetVertexColor(1,1,1,alpha);texture:Show()
 end
 local function ground(pool,x,y,rx,ry,alpha)
  local land=F.char.islandPrototype and F.char.islandPrototype.land
  if not land then return end
  rx,ry=I.Clamp(rx,.18,6),I.Clamp(ry,.18,6)
  local l,b,r,t=x-rx,y-ry,x+rx,y+ry
  -- Clip against actual owned parcels, including holes and concave coastlines.
  -- Keeping the matching UV slice avoids dark squares or shadows on the water.
  for px=math.floor((l+8)/16),math.floor((r+8-.001)/16)do
   for py=math.floor((b+8)/16),math.floor((t+8-.001)/16)do
    if land[px..':'..py]then
     local cl,cb,cr,ct=math.max(l,px*16-8),math.max(b,py*16-8),math.min(r,px*16+8),math.min(t,py*16+8)
     if cr>cl and ct>cb then quad(pool,cl,cb,cr,ct,(cl-l)/(2*rx),(cr-l)/(2*rx),(t-ct)/(2*ry),(t-cb)/(2*ry),alpha)end
    end
   end
  end
 end
 function g:Update(force)
  if not I.SoftShadowsEnabled()or f.camera.z<=.1 then
   self:Hide();self.signature=nil;return
  end
  self:Show()
  local a=rawget(f,'atmosphere');local hour=a and a.db.hour or 12
  local daylight=(1-math.cos(hour/12*math.pi))/2
  local alpha=.075+.16*daylight
  local c=f.camera
  local signature=table.concat({c.x,c.y,c.z,c.yaw,c.pitch,I.navRevision or 0,math.floor(hour*60),f.input:GetWidth(),f.input:GetHeight()},':')
  local e=f.editor
  if force or self.signature~=signature or e.drag or e.gizmoDrag or e.placing then
   self.signature=signature;self.furniture.used=0
   for index,v in ipairs(e.actors)do if index>100 then break end
    if v.used and v.ready and v.actor:IsShown()then
     local o=v.object
     if not I.Walkable(o.key)and not (I.IsBoat and I.IsBoat(o))and o.z<8 then
      local rx,ry=I.Footprint(o)
      ground(self.furniture,o.x,o.y,rx*.85,ry*.85,alpha*(1-math.max(0,o.z)/8))
     end
    end
   end
   hideUnused(self.furniture)
  end
  self.pets.used=0
  for _,pet in ipairs(rawget(f,'roamingPets')or {})do
   if pet.pet and pet.ready and not pet.failed and not pet.voyage and pet.actor:IsShown()and pet.x and pet.y then
    ground(self.pets,pet.x,pet.y,1.05,.85,alpha)
   end
  end
  hideUnused(self.pets)
 end
 I.HookViewportUpdate(f,function()g:Update()end)
 f:HookScript('OnShow',function()g.signature=nil end)
 g:Update(true)
end
local open=I.Open
function I.Open(...)open(...);I.BuildSoftShadows(I.ui)end
