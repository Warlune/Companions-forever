local _,F=...
local H,P,S=F.Housing,F.Pets,F.Style
local I=H.Island
function I.ViewportFPS()return F.char and F.char.housingViewportFPS==30 and 30 or 60 end
function I.SetViewportFPS(value)
 if value~=30 and value~=60 then return false end
 F.char.housingViewportFPS=value
 return true
end
-- Throttle housing work only. Native model rendering still follows WoW's FPS.
-- Retain fractional time so a 60 FPS choice doesn't become 30 on a 59 FPS client.
function I.ViewportUpdate(callback)
 local credit,elapsed=0,0
 return function(frame,dt)
  credit=credit+dt;elapsed=elapsed+dt
  local interval=1/I.ViewportFPS()
  if credit+1e-9<interval then return end
  credit=math.max(0,credit-interval*math.floor((credit+1e-9)/interval))
  local step=elapsed;elapsed=0
  callback(frame,step)
 end
end
function I.HookViewportUpdate(frame,callback)frame:HookScript('OnUpdate',I.ViewportUpdate(callback))end
-- Native M2 assets only, verified by wowdev/wow-listfile. No WMO loader.
I.assets={
 island={id=202710,path="World/Kalimdor/THOUSANDNEEDLES/PASSIVEDOODADS/ROCKS/SaltFlatRock_01.m2"},
 water={id=1093938,path="World/Expansion05/Doodads/6XP_Generic_Waterplane01.m2"},
 floor={id=202713,path="World/Kalimdor/THOUSANDNEEDLES/PASSIVEDOODADS/ROCKS/SaltFlatRock_04.m2"},
 sky={id=321486,path="Environments/Stars/LostIsleSkyBox.m2"},
 mountain={id=189715,path="World/Azeroth/ELWYNN/PASSIVEDOODADS/CLIFFROCKS/ElwynnCliffRock01.M2"},
}
-- Each visible foundation is wider than its 16-unit editable parcel.
I.foundationWidth=40
local bounds=I.ModelBounds
function I.Allowed(asset)
 for _,v in pairs(I.assets)do if v==asset and v.path:lower():match("%.m2$")then return true end end
 return false
end
function I.SavedScene()
 if type(F.char.islandPrototype)~='table'then F.char.islandPrototype={}end
 local db=F.char.islandPrototype
 if type(db.scenery)~='table'then db.scenery={}end
 return db.scenery
end
function I.SceneryAsset(kind,id)
 local group=kind=='island'and 'land'or kind
 for _,a in ipairs(I.candidates or {})do if a.id==id and a.group==group and a.path:lower():match('%.m2$')then return a end end
end
function I.Open()
 P.OpenPage("housing")
 if H.buildingLab then H.buildingLab:Hide()end
 H.ui.room:Hide();H.ui.side:Hide()
 -- Use the space down to the existing footer instead of the fixed page height.
 H.ui:ClearAllPoints();H.ui:SetPoint('TOPLEFT',P.window,'TOPLEFT',20,-94);H.ui:SetPoint('BOTTOMRIGHT',P.window,'BOTTOMRIGHT',-20,42)
 if I.ui then I.ui:Show();I.ui:SetHousingInput(true);return end
 local f=CreateFrame("Frame",nil,H.ui,"BackdropTemplate");I.ui=f
 -- Stay inside the large addon's housing page and inherit its UI scale.
 f:SetAllPoints(H.ui)
 f:SetFrameLevel(H.ui:GetFrameLevel()+10);f:EnableMouse(true)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});f:SetBackdropColor(.025,.035,.05,1)
 
 local canvas=CreateFrame("Frame",nil,f);f.canvas=canvas;canvas:SetAllPoints(f);canvas:SetClipsChildren(true)
 local bg=canvas:CreateTexture(nil,"BACKGROUND");f.skyBackground=bg;bg:SetAllPoints();bg:SetColorTexture(.32,.60,.75,1)
 local skyScene=CreateFrame("ModelScene",nil,canvas);f.skyScene=skyScene;skyScene:SetAllPoints();skyScene:EnableMouse(false)
 skyScene:SetCameraFieldOfView(math.rad(45));skyScene:SetCameraNearClip(.05);skyScene:SetCameraFarClip(20000)
 local scene=CreateFrame("ModelScene",nil,canvas);f.scene=scene;scene:SetAllPoints();scene:EnableMouse(false);scene:SetFrameLevel(skyScene:GetFrameLevel()+1)
 scene:SetCameraFieldOfView(math.rad(45));scene:SetCameraNearClip(.05);scene:SetCameraFarClip(40000)
 scene:SetLightVisible(true);scene:SetLightAmbientColor(.55,.55,.55);scene:SetLightDiffuseColor(.45,.44,.40);scene:SetLightDirection(-.6,.8,-1)
 -- Furniture renders above the projected grid, with exactly the same camera.
 local objects=CreateFrame('ModelScene',nil,canvas);f.objectScene=objects;objects:SetAllPoints();objects:EnableMouse(false);objects:SetFrameLevel(scene:GetFrameLevel()+3)
 objects:SetCameraFieldOfView(math.rad(45));objects:SetCameraNearClip(.05);objects:SetCameraFarClip(40000)
 objects:SetLightVisible(true);objects:SetLightAmbientColor(.55,.55,.55);objects:SetLightDiffuseColor(.45,.44,.40);objects:SetLightDirection(-.6,.8,-1)
 local input=CreateFrame("Frame",nil,canvas);f.input=input;input:SetAllPoints();input:SetFrameLevel(scene:GetFrameLevel()+5);input:EnableMouse(true);input:EnableMouseWheel(true)
 f.camera=I.HomeCamera();f.entries={};f.keys={};f.waterLevel=-2;f.floorLevel=-4;f.elapsed=0;f.fly=false
 local saved=I.SavedScene()
 if type(saved.waterLevel)=='number'and saved.waterLevel==saved.waterLevel then f.waterLevel=I.Clamp(saved.waterLevel,-6,3)end
 if type(saved.floorLevel)=='number'and saved.floorLevel==saved.floorLevel then f.floorLevel=I.Clamp(saved.floorLevel,-10,f.waterLevel-.5)end
 local header=S.Panel(f,0,0,960,34);f.header=header;header:ClearAllPoints();header:SetPoint('TOPLEFT');header:SetPoint('TOPRIGHT');header:SetFrameLevel(input:GetFrameLevel()+15);header:EnableMouse(true)
 S.Text(header,'ISLAND WORKSHOP',10,-9,180,'GameFontNormal')
 local side=I.Dock(f,164);f.side=side
 f.info=S.Text(side,"Loading island...",18,-14,225,"GameFontHighlightSmall");f.info:SetHeight(76)
 f.status=S.Text(header,"",190,-5,680,"GameFontHighlightSmall");f.status:SetHeight(26)
 function f:Camera()
  local c=self.camera;local a,r,u=I.Basis(c)
  scene:SetCameraPosition(c.x,c.y,c.z);scene:SetCameraOrientationByAxisVectors(unpack({a[1],a[2],a[3],r[1],r[2],r[3],u[1],u[2],u[3]}))
  objects:SetCameraPosition(c.x,c.y,c.z);objects:SetCameraOrientationByAxisVectors(unpack({a[1],a[2],a[3],r[1],r[2],r[3],u[1],u[2],u[3]}))
  skyScene:SetCameraPosition(0,0,0);skyScene:SetCameraOrientationByAxisVectors(unpack({a[1],a[2],a[3],r[1],r[2],r[3],u[1],u[2],u[3]}))
  -- These native water meshes have one face. Turn that same plane toward an
  -- underwater camera; never tile or duplicate it to simulate a larger ocean.
  for _,v in ipairs(self.entries)do if v.kind=='water'and v.loaded then
   local below=c.z<self.waterLevel
   if v.below~=below then v.below=below;v.actor:SetRoll(below and math.pi or 0)end
  end end
  self.info:SetText(string.format("Camera height: %.1f\nWater: %.1f | Seabed: %.1f\n%s",c.z,self.waterLevel,self.floorLevel,self.fly and "FLY CAMERA ACTIVE" or "Camera released"))
 end
 local function propagate(value)
  if not (InCombatLockdown and InCombatLockdown())then input:SetPropagateKeyboardInput(value)end
 end
 function f:SetHousingInput(enabled)
  self.housingInput=enabled;self.keys={}
  -- Capture only this viewport's keys. Character movement APIs are protected,
  -- including the stop functions, and must never run when opening housing.
  if InCombatLockdown and InCombatLockdown()then self.inputPending=true;return end
  self.inputPending=nil;input:EnableKeyboard(enabled);propagate(not enabled)
 end
 input:RegisterEvent('PLAYER_REGEN_ENABLED')
 input:SetScript('OnEvent',function()if f.inputPending then f:SetHousingInput(f.housingInput)end end)
 function f:StopFlight()
  if rawget(self,'voyageFollow')then self.camera=I.HomeCamera();self.voyageFollow=nil end
  if rawget(self,'followPetID')then self.cameraLocked=false;self.followPetID=nil;self.followPetIndex=nil;self.followPetYaw=nil end
  self.cameraTransition=nil;self.fly=false;self.look=false;self.pan=false;self.keys={};self.flyButton:SetText("Fly camera");self:Camera()
 end
 function f:Flight()
  self.cameraTransition=nil
  if self.cameraLocked then self.status:SetText('Unlock the camera to move around.');return end
  if self.fly then self:StopFlight();return end
  if InCombatLockdown and InCombatLockdown()then self.status:SetText("Finish combat before using the editor camera.");return end
  self.fly=true;self.keys={};input:EnableKeyboard(true);propagate(false);self.flyButton:SetText("Release camera");self:Camera()
 end
 f.flyButton=S.Button(side,"Fly camera",260,-16,144,function()f:Flight()end)
 S.Button(side,"Island view",414,-16,120,function()f:StopFlight();f.camera=I.HomeCamera();f:Camera()end)
 S.Button(side,"Shore view",544,-16,120,function()f:StopFlight();f.camera={x=25,y=-32,z=4,yaw=2.23,pitch=-.05};f:Camera()end)
 S.Button(side,"Underwater",674,-16,120,function()f:StopFlight();f.camera={x=25,y=-25,z=-3,yaw=2.35,pitch=-.05};f:Camera()end)
 S.Button(side,"Overhead",804,-16,136,function()f:StopFlight();f.camera={x=0,y=-.1,z=70,yaw=math.pi/2,pitch=-1.569};f:Camera()end)
 S.Button(side,"Water lower",260,-54,144,function()f.waterLevel=I.Clamp(f.waterLevel-.5,-6,3);f:Environment()end)
 S.Button(side,"Water higher",414,-54,120,function()f.waterLevel=I.Clamp(f.waterLevel+.5,-6,3);f:Environment()end)
 S.Button(side,"Bed lower",544,-54,120,function()f.floorLevel=I.Clamp(f.floorLevel-.5,-10,f.waterLevel-.5);f:Environment()end)
 S.Button(side,"Bed higher",674,-54,120,function()f.floorLevel=math.min(f.waterLevel-.5,f.floorLevel+.5);f:Environment()end)
 S.Button(side,'Default scenery',804,-54,136,function()
  f.waterLevel,f.floorLevel=-2,-4
  for _,kind in ipairs({'island','water','sky'})do f:UseScenery(kind,I.SceneryAsset(kind,I.assets[kind].id))end
  f:Environment()
 end)
 S.Text(side,"Fly: W A S D | Up/down: E/Q\nLook: hold right mouse\nSpeed: Shift | Esc: release\nWheel: forward / back",18,-94,228,"GameFontHighlightSmall"):SetHeight(64)
 S.Button(side,"Back",804,-122,136,function()f:Hide()end)
 function f:Environment()
  self.floorLevel=math.min(self.floorLevel,self.waterLevel-.5)
  saved.waterLevel,saved.floorLevel=self.waterLevel,self.floorLevel
  for _,v in ipairs(self.entries)do if v.loaded then
   local z=v.kind=="water" and self.waterLevel or v.kind=="floor" and self.floorLevel or v.z
   if v.waterline then z=self.waterLevel end
   if v.kind~="sky"then I.Position(v,v.x,v.y,z+(v.offset or 0))end
  end end
  self:Camera()
 end
 local function add(kind,x,y,z,width,top,override)
  local asset=override or I.SceneryAsset(kind,saved[kind])or I.assets[kind]
  assert(asset and (I.Allowed(asset)or (kind=='coast' and I.coastVerified[asset.id] and I.SceneryAsset('coast',asset.id)==asset)or (kind~='coast' and (I.SceneryAsset(kind,asset.id)==asset or I.SceneryAsset('island',asset.id)==asset))),"Native M2 allowlist required")
  local actor=(kind=="sky"and skyScene or scene):CreateActor();actor:Hide();actor:SetScale(1);actor:SetUseCenterForOrigin(true,true,true)
  local v={actor=actor,asset=asset,kind=kind,x=x,y=y,z=z,width=width,top=top,age=0};f.entries[#f.entries+1]=v
  local ok,accepted=pcall(actor.SetModelByFileID,actor,asset.id);v.failed=not ok or accepted==false
  return v
 end
 f.AddScenery=add
 f.parcels={}
 function f:SyncLand()
  for id,p in pairs(I.LandState())do if not self.parcels[id]then
   -- Tiny deterministic height offsets prevent coplanar native meshes flickering.
   self.parcels[id]=add('island',p.x*16,p.y*16,-.004*(p.x*5+p.y),I.foundationWidth,true)
  end end
 end
 f.sky=add("sky",0,0,0,18000,false)
 f:SyncLand()
 add("water",0,0,f.waterLevel,10000,false)
 -- One broad native terrain surface beneath the continuous water plane.
 add("floor",0,0,f.floorLevel,9500,true)
 I.BuildCoast(f)
 function f:UseScenery(kind,asset)
  if not asset or I.SceneryAsset(kind,asset.id)~=asset then return false end
  for _,v in ipairs(self.entries)do if v.kind==kind then
   v.actor:Hide();v.actor:SetScale(1);v.actor:SetPosition(0,0,0);v.actor:SetUseCenterForOrigin(true,true,true)
   v.asset=asset;v.loaded=false;v.failed=false;v.age=0;v.pendingSave=true;v.below=nil;v.retried=nil
   local ok,result=pcall(v.actor.SetModelByFileID,v.actor,asset.id);v.failed=not ok or result==false
   return not v.failed
  end end
 end
 S.Button(side,'Switch water style',260,-92,180,function()
  for _,v in ipairs(f.entries)do if v.kind=='water'then
   f:UseScenery('water',I.SceneryAsset('water',v.asset.id==1093938 and 5097445 or 1093938));break
  end end
 end)
 local function keyDown(_,key)
  if not f.housingInput then propagate(true);return end
  local typing=(ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow())or (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus())
  if typing then f.keys={};propagate(true);return end
  if key=="ENTER"or key=="NUMPADENTER"then
   -- Release held movement before passing Enter to WoW's normal chat binding.
   if f.fly then f:StopFlight()end
   propagate(true);return
  end
  if key=="ESCAPE"then f:StopFlight();propagate(true);return end
  local movement={W='W',A='A',S='S',D='D',E='E',Q='Q',UP='W',DOWN='S',LEFT='A',RIGHT='D',SPACE='E',X='Q',LSHIFT='LSHIFT',RSHIFT='RSHIFT'}
  local mapped=movement[key]
  propagate(not mapped and key~='NUMLOCK')
  if mapped and not f.cameraLocked and not (InCombatLockdown and InCombatLockdown())then f.cameraTransition=nil;f.keys[mapped]=true end
 end
 input:SetScript("OnKeyDown",keyDown);input:SetScript("OnKeyUp",function(_,key)local aliases={UP='W',DOWN='S',LEFT='A',RIGHT='D',SPACE='E',X='Q'};f.keys[aliases[key]or key]=nil end)
 input:SetScript("OnMouseDown",function(_,button)
  if not f.cameraLocked and (button=='RightButton'or button=='MiddleButton')then
   f.cameraTransition=nil;f.look=button=='RightButton';f.pan=button=='MiddleButton';f.mx,f.my=GetCursorPosition()
  end
 end)
 input:SetScript("OnMouseUp",function(_,button)if button=='RightButton'then f.look=false elseif button=='MiddleButton'then f.pan=false end end)
 input:SetScript("OnMouseWheel",function(_,delta)if not f.cameraLocked then
  f.cameraTransition=nil
  local c=f.camera;local a=I.Basis(c);local limit=c.explore and 6200 or 130;local height=c.explore and 32000 or 200
  local step=(c.explore and math.max(2,c.z*.03)or 2)*I.CameraSpeed()
  c.x=I.Clamp(c.x+a[1]*delta*step,-limit,limit);c.y=I.Clamp(c.y+a[2]*delta*step,-limit,limit);c.z=I.Clamp(c.z+a[3]*delta*step,-6,height);f:Camera()
 end end)
 f:SetScript("OnUpdate",I.ViewportUpdate(function(_,dt)
  dt=math.min(.1,dt)
  I.StepCameraTransition(f,dt)
  if I.StepVoyageClock then I.StepVoyageClock(f,dt)end
  I.StepPetCamera(f)
  if rawget(f,'pan')then
   if f.cameraLocked or not IsMouseButtonDown('MiddleButton')then f.pan=false
   else local x,y=GetCursorPosition();I.PanCamera(f.camera,(x-f.mx)/input:GetEffectiveScale(),(y-f.my)/input:GetEffectiveScale());f.mx,f.my=x,y;f:Camera()end
  end
  if (InCombatLockdown and InCombatLockdown())or (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow())or (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus())then f.keys={};if f.fly then f:StopFlight()end end
  if f.look then
   if IsMouseButtonDown and not IsMouseButtonDown("RightButton")then f.look=false
   else local x,y=GetCursorPosition();f.camera.yaw=f.camera.yaw-(x-f.mx)*.004;f.camera.pitch=I.Clamp(f.camera.pitch+(y-f.my)*.004,-1.569,1.4);f.mx,f.my=x,y;f:Camera()end
  end
  if f.housingInput and not f.cameraLocked and next(f.keys)then I.Fly(f.camera,f.keys,dt);f:Camera()end
  local loaded,failed,changed=0,{},false
  for _,v in ipairs(f.entries)do
   if not v.loaded and not v.failed then
    v.age=v.age+dt
    if v.age>.3 and v.actor:IsLoaded()then
     local ok,w,h,height,bottom,top=pcall(bounds,v.actor)
     if ok and not w and h=='missing'then v.failed=true;v.actor:Hide()end
     if ok and w then
      v.actor:SetUseCenterForOrigin(true,true,v.kind~='coast')
      v.scale=v.width/math.max(w,h);v.offset=v.top and -height*v.scale/2 or v.bottom and height*v.scale/2 or 0
      v.modelHeight=height*v.scale
      if v.kind=='coast'then v.offset=v.top and -top*v.scale or v.bottom and -bottom*v.scale or 0 end
      if v.waterline then v.offset=-bottom*v.scale-height*v.scale*v.waterline end
      if v.kind=="sky"then v.offset=0 end
      v.actor:SetScale(v.scale);v.actor:SetAlpha(1);v.actor:Show();v.loaded=true;changed=true
      if v.pendingSave then saved[v.kind]=v.asset.id;v.pendingSave=nil end
     end
    end
    if not v.loaded and v.age>8 then v.failed=true;v.actor:Hide()end
   end
   if v.failed and I.assets[v.kind]and v.asset.id~=I.assets[v.kind].id and not v.retried then
    v.retried=true;v.asset=I.assets[v.kind];v.loaded=false;v.age=0;v.pendingSave=true;v.below=nil
    v.actor:Hide();v.actor:SetScale(1);v.actor:SetPosition(0,0,0)
    local ok,result=pcall(v.actor.SetModelByFileID,v.actor,v.asset.id);v.failed=not ok or result==false
   end
   if v.loaded then loaded=loaded+1 elseif v.failed then failed[v.kind]=true end
  end
  if changed then f:Environment()end
  local names={};for kind in pairs(failed)do names[#names+1]=kind end;table.sort(names)
  local message=#names>0 and "Unavailable in this client: "..table.concat(names,", ")or loaded==#f.entries and "Scenery prototype. Use Fly camera or the view buttons to inspect the island."or "Loading native scenery..."
  if f.message~=message then f.message=message;f.status:SetText(message)end
  local paused=not not F.db.settings.reduceMotion
  if f.paused~=paused then f.paused=paused;scene:SetPaused(paused,false);objects:SetPaused(paused,false);skyScene:SetPaused(paused,false)end
 end))
 f:SetScript("OnHide",function()f:SetHousingInput(false);f:StopFlight();scene:SetPaused(true,false);objects:SetPaused(true,false);skyScene:SetPaused(true,false);f.paused=nil;H.ui.room:Show();H.ui.side:Show()end)
 f:SetScript("OnShow",function()f:SetHousingInput(true);H.ui.room:Hide();H.ui.side:Hide();f.paused=nil;f:Camera()end)
 H.ui:HookScript("OnHide",function()f:SetHousingInput(false);if f:IsShown()then f:StopFlight()end end)
 f:SetHousingInput(true)
 f:Camera()
end
local build=H.Build
function H.Build(...)
 local result=build(...)
 if not H.ui.islandButton then H.ui.islandButton=S.Button(H.ui,"Island workshop",720,0,240,function()I.Open()end)end
 return result
end
local command=SlashCmdList.COMPANIONSFOREVER
SlashCmdList.COMPANIONSFOREVER=function(message)
 if(message or ""):lower():match("^%s*island%s*$")then if F.ready then I.Open()end else command(message)end
end
