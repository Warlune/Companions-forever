local _,F=...
local H,I,S=F.Housing,F.Housing.Island,F.Style
I.objectLimit=100
I.decor={}
for _,key in ipairs({'table','sofa','bed','shelf','plant','rug','bowls','lamp'})do
 local d=H.byKey[key];I.decor[#I.decor+1]={key=key,name=d.name,asset=d.asset,width=key=='bowls'and 1 or key=='lamp'and 1 or d.w}
end
for _,spec in ipairs({{'palm','Palm tree',202973,4},{'pine','Pine tree',189924,3},{'rock','Mossy rock',193399,5}})do
 local asset=I.SceneryAsset('island',spec[3])
 I.decor[#I.decor+1]={key=spec[1],name=spec[2],asset=asset,width=spec[4]}
end
for _,d in ipairs({
 {key='chair',name='Wooden chair',asset={id=198115,path='World/Generic/Human/Passive Doodads/Chairs/GeneralChairLoEnd01.m2'},width=1.3},
 {key='armchair',name='Carved chair',asset={id=198114,path='World/Generic/Human/Passive Doodads/Chairs/GeneralChairHighEnd01.m2'},width=1.6},
 {key='fir',name='Fir tree',asset=I.SceneryAsset('island',189923),width=4},
 {key='pine2',name='Forest pine',asset=I.SceneryAsset('island',189925),width=4},
})do I.decor[#I.decor+1]=d end
for _,d in ipairs(I.storeExtras or {})do I.decor[#I.decor+1]=d end
I.decorByKey={};for _,d in ipairs(I.decor)do I.decorByKey[d.key]=d end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function I.CleanObjects(items)
 local result,seen={},{}
 if type(items)~='table'then return result end
 for i=1,math.min(#items,I.objectLimit)do local o=items[i]
  if type(o)=='table'and I.decorByKey[o.key]and finite(o.id)and o.id%1==0 and o.id>0 and o.id<1000000 and not seen[o.id]
   and finite(o.x)and finite(o.y)and finite(o.z)and finite(o.yaw)and finite(o.size)then
   result[#result+1]={id=o.id,key=o.key,quality=finite(o.quality)and math.max(1,math.min(5,math.floor(o.quality)))or 1,paid=finite(o.paid)and o.paid%1==0 and o.paid>=5 and o.paid<=10 and o.paid or nil,x=I.Clamp(o.x,-130,130),y=I.Clamp(o.y,-130,130),z=I.Clamp(o.z,-10,80),yaw=o.yaw%(2*math.pi),pitch=finite(o.pitch)and o.pitch%(2*math.pi)or 0,roll=finite(o.roll)and o.roll%(2*math.pi)or 0,size=I.Clamp(o.size,.25,3)};seen[o.id]=true
  end
 end
 return result
end
function I.RayPlane(c,nx,ny,aspect,z)
 local f,r,u=I.Basis(c);local t=math.tan(math.rad(45)/2)
 local dx,dy,dz=f[1]+r[1]*nx*t*aspect+u[1]*ny*t,f[2]+r[2]*nx*t*aspect+u[2]*ny*t,f[3]+r[3]*nx*t*aspect+u[3]*ny*t
 if math.abs(dz)<.00001 then return end
 local distance=(z-c.z)/dz
 if distance<=0 or distance>1000 then return end
 local x,y=c.x+dx*distance,c.y+dy*distance
 if math.abs(x)>130 or math.abs(y)>130 then return end
 return x,y
end
function I.Project(c,x,y,z,aspect)
 local f,r,u=I.Basis(c);local dx,dy,dz=x-c.x,y-c.y,z-c.z
 local depth=dx*f[1]+dy*f[2]+dz*f[3]
 if depth<=.05 then return end
 local t=math.tan(math.rad(45)/2)*depth
 return (dx*r[1]+dy*r[2]+dz*r[3])/(t*aspect),(dx*u[1]+dy*u[2]+dz*u[3])/t,depth
end
-- Use the client's projection: its handedness and FOV/aspect conversion differ
-- from a conventional perspective matrix. Returned offsets are physical pixels.
function I.SceneProject(scene,x,y,z)
 local px,py,depth=scene:Project3DPointTo2D(x,y,z)
 local scale=scene:GetEffectiveScale()
 if not finite(px)or not finite(py)or not finite(depth)or depth<0 or depth>=1 then return end
 return px/(scene:GetWidth()*scale)*2-1,py/(scene:GetHeight()*scale)*2-1
end
function I.SolvePlane(project,nx,ny,z,x,y)
 x,y=x or 0,y or 0
 for _=1,10 do
  local px,py=project(x,y,z);if not finite(px)or not finite(py)then return end
  local ex,ey=nx-px,ny-py
  if math.abs(ex)+math.abs(ey)<.00001 then
   if math.abs(x)<=130 and math.abs(y)<=130 then return x,y end;return
  end
  local ax,ay=project(x+.05,y,z);local bx,by=project(x,y+.05,z)
  if not finite(ax)or not finite(ay)or not finite(bx)or not finite(by)then return end
  ax,ay,bx,by=(ax-px)/.05,(ay-py)/.05,(bx-px)/.05,(by-py)/.05
  local det=ax*by-ay*bx;if math.abs(det)<.00000001 then return end
  x=x+I.Clamp((ex*by-ey*bx)/det,-100,100);y=y+I.Clamp((ey*ax-ex*ay)/det,-100,100)
 end
end
local function state()
 local db=F.char.islandPrototype
 if type(db)~='table'then db={};F.char.islandPrototype=db end
 db.items=I.CleanObjects(db.items);db.version=1
 return db
end
function I.BuildEditor(f)
 if f.editor then return end
 local e={db=state(),actors={},catalogIndex=1,history={}};f.editor=e
 local panel=I.Dock(f,194);e.panel=panel;panel:Hide()
 local function selected()for _,o in ipairs(e.db.items)do if o.id==e.selected then return o end end end
 function e:Remember()self.history[#self.history+1]=I.CleanObjects(self.db.items);if #self.history>20 then table.remove(self.history,1)end end
 function e:Refresh()
  local o=selected();self.catalog:SetText(I.decor[self.catalogIndex].name)
  self.label:SetText(o and string.format('%s\nX %.1f  Y %.1f  Height %.1f\nSize %.2f  |  Rotation %.0f',I.decorByKey[o.key].name,o.x,o.y,o.z,o.size,math.deg(o.yaw))or 'Select an object, or place a new one.')
  self.hint:SetText(self.placing and 'Click the island to place.\nRight-click cancels placement.'or 'Click an object to select it.\nDrag to move at its current height.\nChanges save automatically.')
 end
 function e:Transform(v,o)
  v.scale=v.baseScale*o.size;v.actor:SetScale(v.scale);v.actor:SetYaw(o.yaw);v.actor:SetPitch(o.pitch or 0);v.actor:SetRoll(o.roll or 0)
  -- Campfire bounds include effects below the visible stones. Its native origin
  -- is already at ground level; centering the bounds makes the fire float.
  local groundOrigin=I.decorByKey[o.key].groundOrigin
  v.actor:SetUseCenterForOrigin(true,true,not groundOrigin)
  local boat=I.IsBoat and I.IsBoat(o)
  I.Position(v,o.x,o.y,boat and (I.BoatWaterLevel()+v.height*v.scale*.15)or o.z+(groundOrigin and 0 or v.height*v.scale/2));v.actor:Show()
 end
 function e:Sync()
  I.navRevision=(I.navRevision or 0)+1
  for _,v in ipairs(self.actors)do v.used=false end
  for i,o in ipairs(self.db.items)do
   local v=self.actors[i]
   if not v then v={actor=f.objectScene:CreateActor()};self.actors[i]=v end
   v.used=true;v.object=o
   if v.key~=o.key then
    v.key=o.key;v.ready=false;v.failed=false;v.age=0;v.actor:Hide();v.actor:SetScale(1);v.actor:SetPosition(0,0,0);v.actor:SetUseCenterForOrigin(true,true,true)
    local a=I.decorByKey[o.key].asset;assert(a.path:lower():match('%.m2$'),'Native furniture required')
    local ok,result=pcall(v.actor.SetModelByFileID,v.actor,a.id);v.failed=not ok or result==false
   end
   if v.ready then self:Transform(v,o)end
  end
  for _,v in ipairs(self.actors)do if not v.used then v.actor:Hide()end end
  self:Refresh()
 end
 function e:Toggle(keepCamera)
  self.enabled=not self.enabled;self.placing=false;self.drag=nil;self.gizmoDrag=nil;self.preview=nil;self.landMode=false;self.landChoice=nil;f:StopFlight()
  if self.enabled and not keepCamera and f.camera.pitch>-.35 then f.camera={x=60,y=-84,z=70,yaw=2.187,pitch=-.58};f:Camera()end
  self.panel:SetShown(self.enabled);f.side:Hide();self:Refresh()
 end
 e.legacyEdit=S.Button(f.header,'Edit objects',750,-10,116,function()e:Toggle()end)
 e.label=S.Text(panel,'',18,-14,228,'GameFontHighlightSmall');e.label:SetHeight(72)
 e.catalog=S.Text(panel,'',268,-14,284,'GameFontNormal');e.catalog:SetJustifyH('CENTER')
 S.Button(panel,'<',268,-40,42,function()e.catalogIndex=(e.catalogIndex-2)%#I.decor+1;e:Refresh()end)
 S.Button(panel,'Place new',318,-40,176,function()if #e.db.items>=I.objectLimit then f.status:SetText('This island holds 100 objects.');return end;e.placing=true;e:Refresh()end)
 S.Button(panel,'>',502,-40,50,function()e.catalogIndex=e.catalogIndex%#I.decor+1;e:Refresh()end)
 local function change(fn)local o=selected();if o then
  local candidate={};for k,v in pairs(o)do candidate[k]=v end;fn(candidate)
  local ok,reason=I.CanPlace(candidate,e.db.items);if not ok then f.status:SetText(reason);return end
  e:Remember();for k,v in pairs(candidate)do o[k]=v end;e:Sync()
 end end
 e.Change=change
 local function undo()local old=table.remove(e.history);if old then e.db.items=old;e.selected=nil;e:Sync()end end
 S.Button(panel,'Turn left',572,-16,114,function()change(function(o)o.yaw=(o.yaw-math.pi/12)%(2*math.pi)end)end)
 S.Button(panel,'Turn right',696,-16,114,function()change(function(o)o.yaw=(o.yaw+math.pi/12)%(2*math.pi)end)end)
 S.Button(panel,'Smaller',572,-52,114,function()change(function(o)o.size=I.Clamp(o.size-.1,.25,3)end)end)
 S.Button(panel,'Larger',696,-52,114,function()change(function(o)o.size=I.Clamp(o.size+.1,.25,3)end)end)
 S.Button(panel,'Lower',572,-88,114,function()change(function(o)o.z=I.Clamp(o.z-.25,-10,80)end)end)
 S.Button(panel,'Raise',696,-88,114,function()change(function(o)o.z=I.Clamp(o.z+.25,-10,80)end)end)
 S.Button(panel,'Undo',414,-80,138,undo)
 S.Button(panel,'Remove',572,-124,114,function()e:DeleteSelected()end)
 S.Button(panel,'Camera',822,-52,118,function()if f.workshop then f.workshop:ShowMode('Camera')else e:Toggle()end end)
 e.hint=S.Text(panel,'',18,-94,228,'GameFontHighlightSmall');e.hint:SetHeight(84)
 S.Button(panel,'Done editing',822,-16,118,function()if f.workshop then f.workshop:ShowMode(nil)else e:Toggle()end end)
 local function cursor()
  local x,y=GetCursorPosition();local scale=f.input:GetEffectiveScale();local w,h=f.input:GetWidth(),f.input:GetHeight()
  return ((x/scale-f.input:GetLeft())/w)*2-1,((y/scale-f.input:GetBottom())/h)*2-1,w/h
 end
 local function project(x,y,z)return I.SceneProject(f.scene,x,y,z)end
 local function placeXY(z)
  local nx,ny,aspect=cursor();local x,y=I.RayPlane(f.camera,nx,ny,aspect,z)
  x,y=I.SolvePlane(project,nx,ny,z,x,y)
  return x,y
 end
 e.PlaceXY=placeXY
 function e:ScreenBounds(v)
  local o=v.object;local loX,loY,hiX,hiY=math.huge,math.huge,-math.huge,-math.huge
  local c,s=math.cos(o.yaw),math.sin(o.yaw)
  for _,x in ipairs({-v.width*v.scale/2,v.width*v.scale/2})do for _,y in ipairs({-v.depth*v.scale/2,v.depth*v.scale/2})do for _,z in ipairs({0,v.height*v.scale})do
   local rx,ry,rz=I.RotateOffset(o,x,y,z-v.height*v.scale/2)
   local px,py=project(o.x+rx,o.y+ry,o.z+v.height*v.scale/2+rz)
   if px then loX=math.min(loX,px);loY=math.min(loY,py);hiX=math.max(hiX,px);hiY=math.max(hiY,py)end
  end end end
  if loX~=math.huge then local padding=10/f.input:GetWidth();return{loX-padding,loY-padding,hiX+padding,hiY+padding}end
 end
 function e:PlacementObject(x,y,id)
  local o={id=id or -1,key=I.decor[self.catalogIndex].key,x=x,y=y,z=0,yaw=0,pitch=0,roll=0,size=1}
  if I.PlacementHeight then o.z=I.PlacementHeight(o.key)end
  local template=self.placementTemplate
  if template and template.key==o.key then
   for _,field in ipairs({'z','yaw','pitch','roll','size','quality'})do if template[field]~=nil then o[field]=template[field]end end
  end
  return o
 end
 function e:PlaceAt(x,y)
  if #self.db.items>=I.objectLimit then f.status:SetText('This island holds 100 objects.');return false end
  local id=1;for _,o in ipairs(self.db.items)do id=math.max(id,o.id+1)end
  local o=self:PlacementObject(x,y,id)
  local ok,reason=I.CanPlace(o,self.db.items);if not ok then f.status:SetText(reason);return false end
  if I.Life then
   local purchased,why=I.Life.PurchaseObject(o);if not purchased then f.status:SetText(why);return false end
  end
  if self.placementTemplate then o.quality=self.placementTemplate.quality end
  self.history={};self.db.items[#self.db.items+1]=o;self.selected=id;self.placing=false;if I.Life and I.Life.HousingMilestones then I.Life.HousingMilestones()end;self:Sync();return true
 end
 local deleteWarning=CreateFrame('Frame',nil,f);e.deleteWarning=deleteWarning;deleteWarning:SetAllPoints();deleteWarning:SetFrameLevel(f.input:GetFrameLevel()+100);deleteWarning:EnableMouse(true);deleteWarning:EnableMouseWheel(true);deleteWarning:Hide()
 local deleteDialog=S.Panel(deleteWarning,0,0,420,170);deleteDialog:ClearAllPoints();deleteDialog:SetPoint('CENTER');deleteDialog:EnableMouse(true)
 S.Text(deleteDialog,'BOAT IN USE',18,-16,384,'GameFontNormalLarge')
 local deleteText=S.Text(deleteDialog,'Your pets are on an expedition. Finish it before deleting this boat, or cancel it from Expeditions.\n\nCanceling loses this trip\'s rewards.',18,-44,384,'GameFontHighlight');deleteText:SetHeight(80)
 S.Button(deleteDialog,'Keep boat',120,-132,180,function()deleteWarning:Hide()end)
 f:HookScript('OnHide',function()deleteWarning:Hide()end)
 function e:DeleteSelected()
  for j,o in ipairs(self.db.items)do if o.id==self.selected then
   local refund=o.paid
   if I.Life then local ok,why=I.Life.RefundObject(o);if not ok then
    f.status:SetText(why)
    if I.VoyageBoatLocked and I.VoyageBoatLocked(o.id)then f:StopFlight();deleteWarning:Show()end
    return false
   end end
   self.history={};table.remove(self.db.items,j);self.selected=nil;self:Sync();f.status:SetText(refund and ('Deleted. '..refund..' tokens refunded.')or 'Deleted.');return true
  end end
 end
 function e:PickFurniture()
  local nx,ny=cursor();local nearest,best=nil,math.huge
  -- Only saved, player-placed furniture is selectable. World entries never
  -- participate, including coast trees and ships that use the same model type.
  for _,v in ipairs(self.actors)do if v.used and v.ready then
   local box=self:ScreenBounds(v)
   if box and nx>=box[1]and nx<=box[3]and ny>=box[2]and ny<=box[4]then
    local o=v.object;local d=(o.x-f.camera.x)^2+(o.y-f.camera.y)^2+(o.z-f.camera.z)^2
    if d<best then best=d;nearest=o end
   end
  end end
  return nearest
 end
 f.input:HookScript('OnMouseDown',function(_,button)
  if button=='MiddleButton'then return end
  if f.fly then
   if button=='LeftButton'and not e.landMode then
    local object=e:PickFurniture()
    if object and f.workshop then f.workshop:EditFromFlight(object);if IsShiftKeyDown and IsShiftKeyDown()then e:BeginAssetDrag(object.key,object)end end
   end
   return
  end
  if not e.enabled or e.landMode then return end
  -- Right-drag remains camera look while editing, unless explicitly locked.
  if button=='RightButton'then e.catalogDrag=nil;e.placing=false;e.placementTemplate=nil;e:Refresh();return end
  f.look=false
  local nearest
  if button=='LeftButton'and not e.placing and not e.gizmoDrag then
   nearest=e:PickFurniture()
   if nearest and IsShiftKeyDown and IsShiftKeyDown()then
    -- Keep Shift's 45-degree snapping on rotation handles.
    if e:GizmoDown(button)then return end
    e:BeginAssetDrag(nearest.key,nearest);return
   end
   -- Clicking another object's body selects it before old overlapping handles.
   if nearest and nearest.id~=e.selected then
    e.selected=nearest.id;e.drag=nil;e.preview=nil;e:Refresh();e:GizmoUpdate()
    if f.workshop then f.workshop:RefreshTools()end
    f.status:SetText(I.decorByKey[nearest.key].name..' selected. Use Move, Rotate or Size.')
    return
   end
  end
  if e:GizmoDown(button)then return end
  if button=='RightButton'then e.catalogDrag=nil;e.placing=false;e:Refresh();return end
  if button~='LeftButton'then return end
  if e.placing then
   local x,y=placeXY(I.PlacementHeight and I.PlacementHeight(I.decor[e.catalogIndex].key)or 0);if not x then f.status:SetText('Aim at the island or shoreline to place an object.');return end
   e:PlaceAt(x,y);return
  end
  e.selected=nearest and nearest.id;e:Refresh()
  if nearest and (not e.tool or e.tool=='move')then local x,y=placeXY(nearest.z);if x then e.drag={object=nearest,dx=nearest.x-x,dy=nearest.y-y};e:Remember()end end
 end)
 f.input:HookScript('OnMouseUp',function(_,button)if button=='LeftButton'then e:EndGizmo(false);e.drag=nil;e.preview=nil end end)
 f:HookScript('OnHide',function()e:EndGizmo(false);e.catalogDrag=nil;e.drag=nil;e.placing=false end)
 I.HookViewportUpdate(f,function(_,dt)
  dt=math.min(dt,.1)
  if e.drag then
   if not IsMouseButtonDown('LeftButton')then e.drag=nil else
    local o=e.drag.object;local x,y=placeXY(o.z);if x then
     x,y=I.Clamp(x+e.drag.dx,-130,130),I.Clamp(y+e.drag.dy,-130,130)
     if x~=o.x or y~=o.y then
      local candidate={};for k,v in pairs(o)do candidate[k]=v end;candidate.x,candidate.y=x,y
      local valid,reason=I.CanPlace(candidate,e.db.items);e.preview=candidate;e.previewOK=valid;f.status:SetText(reason)
      if valid then o.x,o.y=x,y;e:Sync()end
     end
    end
   end
  end
  for _,v in ipairs(e.actors)do if v.used and not v.ready and not v.failed then
   v.age=v.age+dt
   if v.age>.3 and v.actor:IsLoaded()then
    local w,h,height=I.ModelBounds(v.actor)
    if w then
     I.CacheDecorBounds(v.key,w,h,height)
     v.baseScale=I.decorByKey[v.key].width/math.max(w,h);v.width=w;v.depth=h;v.height=height;v.ready=true;I.decorByKey[v.key].depthRatio=h/math.max(w,h);I.navRevision=(I.navRevision or 0)+1;e:Transform(v,v.object)
    end
   end
   if v.age>8 and not v.ready then v.failed=true;v.actor:Hide();f.status:SetText('An object model is unavailable in this client.')end
  end end
  e:GizmoUpdate()
 end)
 I.BuildGizmo(f,e)
 e:Sync()
end
local open=I.Open
function I.Open(...)open(...);I.BuildEditor(I.ui)end
