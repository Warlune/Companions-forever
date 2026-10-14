local _,F=...
local I,S=F.Housing.Island,F.Style
local categories=I.storeCategories
local function inside(frame)
 if not frame:IsShown()then return false end
 local x,y=GetCursorPosition();local scale=frame:GetEffectiveScale()
 local l,b=frame:GetLeft(),frame:GetBottom()
 return l and b and x/scale>=l and x/scale<=l+frame:GetWidth()and y/scale>=b and y/scale<=b+frame:GetHeight()
end
function I.BuildWorkshop(f)
 if rawget(f,'workshop')then return end
 local e=f.editor;local w={mode=nil,category='Furniture',offset=0,toolButtons={},squares={}};f.workshop=w
 f.cameraLocked=false
 function w:ButtonOpacity()
  local value=F.char.housingButtonOpacity
  return type(value)=='number'and value==value and I.Clamp(value,0,1)or F.db.settings.highContrast and .94 or .38
 end
 function w:SetButtonOpacity(value)
  F.char.housingButtonOpacity=I.Clamp(value,0,1)
  for _,b in ipairs(self.squares)do b:Paint(b.active)end
  for _,card in ipairs(self.cards or {})do card:SetBackdropColor(.04,.07,.09,self:ButtonOpacity())end
  local lifeUI=rawget(f,'lifeUI');if lifeUI then for _,row in ipairs(lifeUI.rows)do row:SetBackdropColor(.025,.025,.035,self:ButtonOpacity())end;if lifeUI.RefreshRewardSummary then lifeUI:RefreshRewardSummary()end end
  self.opacityLabel:SetText('UI backgrounds: '..math.floor(self:ButtonOpacity()*100+.5)..'%')
 end
 e.legacyEdit:Hide();f.side:Hide();e.panel:Hide()
 e.tool='move'
 local camera=CreateFrame('Frame',nil,f);w.camera=camera;camera:Hide()
 local browser=CreateFrame('Frame',nil,f);w.browser=browser;browser:SetFrameLevel(f.input:GetFrameLevel()+32);browser:EnableMouse(true);browser:EnableMouseWheel(true);browser:SetSize(158,408);browser:SetPoint('TOPRIGHT',f,'TOPRIGHT',-8,-40);browser:Hide()
 S.Text(browser,'FURNISHINGS',6,-4,146,'GameFontNormal')
 function w:ShowMode(mode,keepCamera)
  if mode and mode~='Camera'and mode~='Edit'and mode~='Buy'and mode~='Settings'and mode~='Assets'then return end
  if mode=='Settings'then
   self.settings:SetShown(not self.settings:IsShown());self:RefreshTools();return
  end
  if mode=='Assets'then if self.mode~='Edit'then self:ShowMode('Edit')else self:RefreshTools()end;return end
  if self.mode==mode then mode=nil end
  self.settings:Hide()
  f:StopFlight();e:EndGizmo(false);e.catalogDrag=nil;e.placing=false;e.placementTemplate=nil;e.drag=nil;e.preview=nil;e.landMode=false
  if f.atmosphere.open then f.atmosphere:Close()end
  local editing=mode=='Edit'or mode=='Buy'
  if (not not e.enabled)~=editing then e:Toggle(keepCamera)end
  self.mode=mode
  e.landMode=mode=='Buy';e.landChoice=nil
  if not keepCamera then
   if mode=='Buy'then I.GlideCamera(f,I.BuyCamera())elseif mode=='Edit'then I.GlideCamera(f,I.EditCamera())end
  end
  camera:Hide();browser:Hide();self.editbar:SetShown(mode=='Edit');self.viewbar:SetShown(mode=='Edit'or mode=='Camera'or mode=='Buy');e.panel:Hide();e.buyPanel:SetShown(mode=='Buy');f.side:Hide()
  self:RefreshTools()
  f.status:SetText(mode=='Buy'and 'Gold outlines show land you can buy. Select a plot.'or editing and 'Select an object, then choose Move, Rotate or Size. Drag furnishings from the list. Red marks the boundary.'or 'Island workshop')
 end
 function w:CategoryKeys()
  local available,locked={},{}
  for _,key in ipairs(categories[self.category])do
   local list=I.Life.Unlocked(key)and available or locked;list[#list+1]=key
  end
  for _,key in ipairs(locked)do available[#available+1]=key end
  return available
 end
 function w:Refresh()
  local list=self:CategoryKeys();local maximum=math.max(0,#list-4)
  self.offset=I.Clamp(self.offset,0,maximum)
  self.updatingScroll=true;self.scrollbar:SetMinMaxValues(0,maximum);self.scrollbar:SetValue(self.offset);self.scrollbar:SetShown(maximum>0);self.updatingScroll=nil
  if self.categoryButton then self.categoryButton:SetText(self.category..'  v')end
  for j,card in ipairs(self.cards)do
   local key=list[self.offset+j];card:SetShown(key~=nil);card.key=key
   if key then
    local d=I.decorByKey[key];card.label:SetText(I.Life.UtilityName(key));S.TextColor(card.label,I.Life.UtilityColor(key));card:SetBackdropBorderColor(unpack(I.Life.UtilityColor(key)));card.locked=I.Life and not I.Life.Unlocked(key);card.lock:SetText((card.locked and 'Locked | 'or '')..I.Life.PriceText());card.loading:SetText('Loading...');card.loading:Show()
    card.actor:Hide();card.actor:SetScale(1);card.actor:SetYaw(-.6);card.actor:SetPitch(0);card.actor:SetRoll(0);card.actor:SetPosition(0,0,0);card.actor:SetUseCenterForOrigin(true,true,true)
    card.scene:Show();card.ready=false;card.age=0;card.failed=false
    card.previewID=card.locked and 219372 or d.asset.id -- Native treasure chest conceals locked furniture.
    local ok,result=pcall(card.actor.SetModelByFileID,card.actor,card.previewID)
    card.failed=not ok or result==false
    if card.failed then card.loading:SetText('Unavailable in this client')end
   end
  end
 end
 function e:BeginAssetDrag(key,source)
  if #self.db.items>=I.objectLimit then f.status:SetText('This island holds 100 objects.');return end
  if I.Life and not I.Life.Unlocked(key)then f.status:SetText(I.Life.LockText(key));return end
  local price=I.Life and (I.Life.FurniturePrice and I.Life.FurniturePrice()or I.Life.price)or 10
  if F.Pets.state.tokens<price then f.status:SetText('You need '..price..' tokens.');return end
  for index,d in ipairs(I.decor)do if d.key==key then self.catalogIndex=index;break end end
  self.placementTemplate=nil
  if source then
   self.placementTemplate={key=key}
   for _,field in ipairs({'z','yaw','pitch','roll','size','quality'})do self.placementTemplate[field]=source[field]end
  end
  f:StopFlight();self:EndGizmo(false);self.drag=nil;self.placing=true;self.landMode=false;self.catalogDrag=true;browser:Hide();w:RefreshTools();self:Refresh()
 end
 function e:EndAssetDrag(onLand)
  if not self.catalogDrag then return end
  self.catalogDrag=nil
  local placed=false
  if onLand then local x,y=self.PlaceXY(self:PlacementObject(0,0).z);if x then placed=self:PlaceAt(x,y)end end
  if placed then self.tool='move'end
  self.placing=false;self.placementTemplate=nil;self.preview=nil;self:Refresh();w:RefreshTools()
 end
 w.cards={}
 for j=1,4 do
  local card=CreateFrame('Button',nil,browser,'BackdropTemplate');w.cards[j]=card
  card:SetSize(132,84);card:SetPoint('TOPLEFT',4,-54-(j-1)*88)
  card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});card:SetBackdropColor(.04,.07,.09,.25);card:SetBackdropBorderColor(.6,.67,.7,.6)
  local scene=CreateFrame('ModelScene',nil,card);card.scene=scene;scene:SetPoint('TOPLEFT',6,-2);scene:SetPoint('BOTTOMRIGHT',-6,39);scene:EnableMouse(false);scene:SetClipsChildren(true)
  -- Thumbnail scenes overlap the island viewport, but must render independently
  -- of its close-up terrain and furniture. Older clients may lack this option.
  scene:SetFrameLevel(card:GetFrameLevel()+1);scene:SetDrawLayer('OVERLAY')
  if type(scene.SetAllowOverlappedModels)=='function'then pcall(scene.SetAllowOverlappedModels,scene,true)end
  scene:SetCameraFieldOfView(math.rad(36));scene:SetCameraNearClip(.01);scene:SetCameraFarClip(1000)
  scene:SetLightVisible(true);scene:SetLightAmbientColor(.75,.75,.75);scene:SetLightDiffuseColor(.6,.6,.55);scene:SetLightDirection(-.5,1,-1)
  card.actor=scene:CreateActor();card.actor:Hide()
  card:SetBackdropColor(.04,.07,.09,w:ButtonOpacity())
  card.label=S.Text(card,'',3,-44,126,'GameFontHighlightSmall');card.label:SetJustifyH('CENTER');card.label:SetMaxLines(2);card.label:SetHeight(26)
  card.lock=S.Text(card,'',3,-69,126,'GameFontNormalSmall');card.lock:SetJustifyH('CENTER')
  card.loading=S.Text(card,'Loading...',3,-23,126,'GameFontHighlightSmall');card.loading:SetJustifyH('CENTER')
  card:EnableMouseWheel(true);card:SetScript('OnMouseWheel',function(_,delta)w:ScrollBy(-delta)end)
  card:SetScript('OnEnter',function()if card.key then GameTooltip:SetOwner(card,'ANCHOR_TOP');GameTooltip:SetText(I.Life.UtilityName(card.key),unpack(I.Life.UtilityColor(card.key)));local source=I.Life.UnlockSource(card.key);if source then GameTooltip:AddLine(source,.65,.85,.65,true)end;GameTooltip:AddLine(I.Life and I.Life.LockText(card.key)or 'Drag to place',1,1,1,true);GameTooltip:Show()end end)
  card:SetScript('OnLeave',function()GameTooltip:Hide()end)
  card:SetScript('OnMouseDown',function(_,button)if button=='LeftButton'and card.key and card.ready and not card.locked then e:BeginAssetDrag(card.key)end end)
 end
 local menu=S.Panel(browser,-226,-24,220,#I.storeCategoryOrder*30+12);w.categoryMenu=menu;menu:SetFrameLevel(browser:GetFrameLevel()+20);menu:EnableMouse(true);menu:Hide()
 function w:ChooseCategory(name)
  if not categories[name]then return end
  self.category=name;self.offset=0;menu:Hide();self:Refresh()
 end
 w.categoryButton=S.Button(browser,'Furniture  v',4,-24,148,function()menu:SetShown(not menu:IsShown())end)
 for j,name in ipairs(I.storeCategoryOrder)do S.Button(menu,name,6,-6-(j-1)*30,208,function()w:ChooseCategory(name)end)end
 browser:HookScript('OnHide',function()menu:Hide()end)
 local scroll=CreateFrame('Slider',nil,browser,'BackdropTemplate');w.scrollbar=scroll;scroll:SetSize(12,348);scroll:SetPoint('TOPRIGHT',-3,-54);scroll:SetOrientation('VERTICAL');scroll:SetValueStep(1);scroll:SetObeyStepOnDrag(true)
 scroll:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});scroll:SetBackdropColor(.02,.02,.02,.8)
 local thumb=scroll:CreateTexture(nil,'OVERLAY');thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob');thumb:SetSize(18,26);scroll:SetThumbTexture(thumb)
 scroll:SetScript('OnValueChanged',function(_,value)if not w.updatingScroll then w.offset=math.floor(value+.5);w:Refresh()end end)
 function w:ScrollBy(delta)
  local offset=I.Clamp(self.offset+delta,0,math.max(0,#categories[self.category]-4))
  if offset~=self.offset then self.offset=offset;self:Refresh()end
 end
 browser:SetScript('OnMouseWheel',function(_,delta)w:ScrollBy(-delta)end)
 local function square(parent,name,x,width,callback,icon)
  local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetSize(width,width);b:SetPoint('LEFT',x,0)
  b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  local icons={Camera='INV_Misc_Spyglass_03',Edit='Trade_Engineering',Buy='INV_Misc_Map_01',Settings='INV_Misc_Gear_01',Lock='INV_Misc_Key_03',Fly='Ability_Druid_FlightForm',Move='Spell_Arcane_Blink',Rotate='Spell_Nature_Cyclone',Size='Spell_Nature_Strength',Delete='INV_Misc_Bone_01'}
  local art=b:CreateTexture(nil,'ARTWORK');b.art=art;art:SetPoint('TOPLEFT',4,-3);art:SetPoint('BOTTOMRIGHT',-4,12);art:SetTexture('Interface\\Icons\\'..(icon or icons[name]or 'INV_Misc_Spyglass_03'));art:SetTexCoord(.07,.93,.07,.93)
  local label=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');label:SetPoint('BOTTOM',0,2);label:SetText(name);b.label=label
  function b:Paint(active)
   self.active=active;self:SetBackdropColor(active and .16 or .03,active and .25 or .05,active and .32 or .08,w:ButtonOpacity())
   self:SetBackdropBorderColor(active and 1 or .7,active and .85 or .8,active and .25 or .85,active and 1 or .55)
  end
  b:SetScript('OnClick',callback);b:Paint(false)
  b:SetScript('OnEnter',function()b:SetBackdropColor(.12,.24,.28,w:ButtonOpacity());GameTooltip:SetOwner(b,'ANCHOR_TOP');GameTooltip:SetText(name);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()b:Paint(b.active);GameTooltip:Hide()end)
  w.squares[#w.squares+1]=b;return b
 end
 w.Square=square
 local toolbar=CreateFrame('Frame',nil,f);w.toolbar=toolbar;toolbar:SetSize(198,42);toolbar:SetPoint('BOTTOMLEFT',12,8);toolbar:SetFrameLevel(f.input:GetFrameLevel()+30)
 w.objectCount=toolbar:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');w.objectCount:SetPoint('TOP',f,'TOP',0,-40);w.objectCount:SetWidth(240);w.objectCount:SetJustifyH('CENTER')
 w.mainButtons={}
 for j,name in ipairs({'Camera','Edit','Buy','Settings'})do
  w.mainButtons[name]=square(toolbar,name,(j-1)*52,42,function()w:ShowMode(name)end)
 end
 local editbar=CreateFrame('Frame',nil,f);w.editbar=editbar;editbar:SetSize(166,34);editbar:SetPoint('BOTTOMRIGHT',-12,48);editbar:SetFrameLevel(f.input:GetFrameLevel()+30);editbar:Hide()
 local viewbar=CreateFrame('Frame',nil,f);w.viewbar=viewbar;viewbar:SetSize(222,32);viewbar:SetPoint('BOTTOMLEFT',54,58);viewbar:SetFrameLevel(f.input:GetFrameLevel()+30);viewbar:Hide()
 w.viewButtons={}
 local views={
  {'Front',I.EditCamera},
  {'Back',function()return{x=-32,y=44,z=38,yaw=2.187+math.pi,pitch=-.62}end},
  {'Left',function()return{x=-54,y=0,z=38,yaw=0,pitch=-.62}end},
  {'Right',function()return{x=54,y=0,z=38,yaw=math.pi,pitch=-.62}end},
  {'Top',function()return{x=0,y=0,z=80,yaw=math.pi/2,pitch=-1.569}end},
 }
 for j,view in ipairs(views)do
  local name,target=view[1],view[2]
  w.viewButtons[name]=square(viewbar,name,(j-1)*38,32,function()
   e:EndGizmo(false);e.drag=nil;e.preview=nil;e.catalogDrag=nil;e.placing=false
   I.GlideCamera(f,target());w:RefreshTools();f.status:SetText(name..' camera view')
  end)
 end
 w.lockButton=square(viewbar,'Lock',190,32,function()
  f.cameraLocked=not f.cameraLocked;f:StopFlight();w:RefreshTools()
  f.status:SetText(f.cameraLocked and 'Camera locked.'or 'Camera unlocked. Right-drag to look; scroll to move.')
 end)
 w.cameraFly=square(f,'Fly',0,32,function()w:SelectTool('Fly')end)
 w.cameraFly:ClearAllPoints();w.cameraFly:SetPoint('BOTTOMLEFT',12,58);w.cameraFly:SetFrameLevel(viewbar:GetFrameLevel());w.cameraFly:Hide()
 w.toolButtons.Fly=w.cameraFly
 local settings=S.Panel(f,0,0,268,228);w.settings=settings;settings:ClearAllPoints();settings:SetPoint('BOTTOMLEFT',12,58);settings:SetFrameLevel(toolbar:GetFrameLevel()+20);settings:EnableMouse(true);settings:Hide()
 S.Text(settings,'HOUSING SETTINGS',12,-12,214,'GameFontNormal')
 w.settingsClose=S.Button(settings,'X',236,-6,26,function()settings:Hide();w:RefreshTools()end);w.settingsClose:SetHeight(24)
 w.opacityLabel=S.Text(settings,'UI backgrounds: '..math.floor(w:ButtonOpacity()*100+.5)..'%',12,-37,240,'GameFontHighlightSmall')
 local opacity=CreateFrame('Slider',nil,settings,'BackdropTemplate');w.opacitySlider=opacity;opacity:SetSize(228,16);opacity:SetPoint('TOPLEFT',18,-66);opacity:SetOrientation('HORIZONTAL');opacity:SetMinMaxValues(0,100);opacity:SetValueStep(1);opacity:SetObeyStepOnDrag(true)
 opacity:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});opacity:SetBackdropColor(.1,.1,.1,1)
 local knob=opacity:CreateTexture(nil,'OVERLAY');knob:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob');knob:SetSize(22,22);opacity:SetThumbTexture(knob);opacity:SetValue(w:ButtonOpacity()*100)
 opacity:SetScript('OnValueChanged',function(_,value)w:SetButtonOpacity(value/100)end)
 local fpsLabel=S.Text(settings,'Viewport FPS',12,-104,104,'GameFontHighlightSmall')
 w.fpsButtons={}
 function w:RefreshFPS()
  for value,button in pairs(self.fpsButtons)do button:SetEnabled(value~=I.ViewportFPS())end
 end
 for index,value in ipairs({30,60})do
  local fps=value
  local b=S.Button(settings,tostring(fps),116+(index-1)*70,-96,62,function()I.SetViewportFPS(fps);w:RefreshFPS()end)
  w.fpsButtons[fps]=b
  b:SetScript('OnEnter',function(self)
   GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('Viewport FPS')
   GameTooltip:AddLine('Housing updates per second. Applies instantly. 30 uses less CPU; 60 gives smoother movement. WoW still controls model rendering.',1,1,1,true);GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 w:RefreshFPS()
 local timeLabel=S.Text(settings,'Day / night',12,-140,240,'GameFontHighlightSmall')
 w.timeButtons={}
 function w:RefreshTime()
  for mode,button in pairs(self.timeButtons)do button:SetEnabled(mode~=I.HousingTimeMode())end
 end
 for index,spec in ipairs({{'cycle','5 min','A full day and night every 5 minutes. Pauses with Reduced Motion.'},{'realm','Realm','Follows realm time.'},{'day','Day','Always daytime in housing.'},{'night','Night','Always nighttime in housing.'}})do
  local mode,label,help=unpack(spec)
  local b=S.Button(settings,label,12+(index-1)*62,-164,58,function()I.SetHousingTimeMode(mode);w:RefreshTime()end)
  w.timeButtons[mode]=b
  b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText(label);GameTooltip:AddLine(help..((mode=='day'or mode=='night')and ' Changes smoothly.'or ' Applies instantly.'),1,1,1,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 w:RefreshTime()
 w.speedLabel=S.Text(settings,'Camera speed: '..math.floor(I.CameraSpeed()*100+.5)..'%',12,-204,240,'GameFontHighlightSmall')
 local speed=CreateFrame('Slider',nil,settings,'BackdropTemplate');w.speedSlider=speed;speed:SetSize(228,16);speed:SetPoint('TOPLEFT',18,-238);speed:SetOrientation('HORIZONTAL');speed:SetMinMaxValues(25,300);speed:SetValueStep(5);speed:SetObeyStepOnDrag(true)
 speed:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8'});speed:SetBackdropColor(.1,.1,.1,1)
 local thumb=speed:CreateTexture(nil,'OVERLAY');thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob');thumb:SetSize(22,22);speed:SetThumbTexture(thumb);speed:SetValue(I.CameraSpeed()*100)
 speed:SetScript('OnValueChanged',function(_,value)I.SetCameraSpeed(value/100);w.speedLabel:SetText('Camera speed: '..math.floor(I.CameraSpeed()*100+.5)..'%')end)
 local skyboxes={}
 for _,spec in ipairs({{321486,'Original (Lost Isles)'},{130497,'Dire Maul'},{130485,'Coldarra'},{130575,'Nagrand'},{130629,'Stars'},{235357,'Storm Peaks'},{235374,'Ulduar Clouds'},{130465,"Blade's Edge"},{130502,'Dragonblight'},{235302,'Dalaran'},{317347,'Mount Hyjal'},{366242,'Skywall'},{375466,'Uldum'},{392407,'Twilight Highlands'}})do
  local asset=I.SceneryAsset('sky',spec[1]);if asset then skyboxes[#skyboxes+1]={asset=asset,name=spec[2]}end
 end
 local skyLabel=S.Text(settings,'Skybox',12,-272,150,'GameFontHighlightSmall')
 w.skyboxIndex=1
 for j,option in ipairs(skyboxes)do if option.asset.id==f.sky.asset.id then w.skyboxIndex=j;break end end
 w.skyboxOriginal=S.Button(settings,'Original',184,-264,72,function()
  w.skyboxIndex=1;f:UseScenery('sky',I.SceneryAsset('sky',I.assets.sky.id));w:RefreshSkybox()
 end);w.skyboxOriginal:SetHeight(22)
 w.skyboxLabel=S.Text(settings,'',48,-301,172,'GameFontHighlightSmall');w.skyboxLabel:SetJustifyH('CENTER')
 function w:RefreshSkybox()
  local name='Original (Lost Isles)'
  for _,option in ipairs(skyboxes)do if option.asset.id==f.sky.asset.id then name=option.name;break end end
  if not f.sky.loaded then name=name..'...'end
  if self.skyboxText~=name then self.skyboxText=name;self.skyboxLabel:SetText(name)end
 end
 function w:CycleSkybox(direction)
  if #skyboxes==0 or (direction~=-1 and direction~=1)then return false end
  -- Keep the browsing cursor separate from the rendered fallback sky. Otherwise
  -- an unavailable model resets the arrows and traps the user in the same choices.
  self.skyboxIndex=(self.skyboxIndex-1+direction)%#skyboxes+1
  local option=skyboxes[self.skyboxIndex]
  local ok=f:UseScenery('sky',option.asset);self:RefreshSkybox();return ok
 end
 w.skyboxPrevious=S.Button(settings,'<',12,-294,30,function()w:CycleSkybox(-1)end)
 w.skyboxNext=S.Button(settings,'>',226,-294,30,function()w:CycleSkybox(1)end)
 w:RefreshSkybox()
 -- Two short pages keep controls readable without covering the resident frames.
 w.settingsPages={};w.settingsTabs={}
 for index,name in ipairs({'View','Scene'})do
  local page=CreateFrame('Frame',nil,settings);page:SetPoint('TOPLEFT',0,-62);page:SetSize(268,154);w.settingsPages[name]=page
  local tab=S.Button(settings,name,12+(index-1)*124,-33,120,function()w:SelectSettingsPage(name)end);tab:SetHeight(22);w.settingsTabs[name]=tab
 end
 function w:SelectSettingsPage(name)
  if not self.settingsPages[name]then return end
  self.settingsPage=name
  for key,page in pairs(self.settingsPages)do page:SetShown(key==name);self.settingsTabs[key]:SetEnabled(key~=name)end
 end
 local function settingAt(control,page,x,y)
  control:SetParent(w.settingsPages[page]);control:ClearAllPoints();control:SetPoint('TOPLEFT',x,y)
 end
 settingAt(w.opacityLabel,'View',12,-4);settingAt(opacity,'View',18,-28)
 settingAt(w.speedLabel,'View',12,-57);settingAt(speed,'View',18,-81)
 settingAt(fpsLabel,'View',12,-124)
 for index,value in ipairs({30,60})do settingAt(w.fpsButtons[value],'View',116+(index-1)*70,-116);w.fpsButtons[value]:SetHeight(24)end
 settingAt(timeLabel,'Scene',12,-4)
 for index,mode in ipairs({'cycle','realm','day','night'})do settingAt(w.timeButtons[mode],'Scene',12+(index-1)*62,-23);w.timeButtons[mode]:SetHeight(22)end
 settingAt(skyLabel,'Scene',12,-62);settingAt(w.skyboxOriginal,'Scene',184,-54)
 settingAt(w.skyboxLabel,'Scene',48,-88);settingAt(w.skyboxPrevious,'Scene',12,-81);settingAt(w.skyboxNext,'Scene',226,-81)
 w.skyboxPrevious:SetHeight(22);w.skyboxNext:SetHeight(22)
 S.Text(w.settingsPages.Scene,'Soft shadows',12,-126,104,'GameFontHighlightSmall')
 w.shadowButtons={}
 function w:RefreshShadows()
  for _,button in ipairs(self.shadowButtons)do button:SetEnabled(button.shadowValue~=I.SoftShadowsEnabled())end
 end
 for index,value in ipairs({true,false})do
  local enabled=value
  local b=S.Button(w.settingsPages.Scene,enabled and 'On'or 'Off',116+(index-1)*70,-118,62,function()I.SetSoftShadows(enabled);w:RefreshShadows()end)
  b.shadowValue=enabled;b:SetHeight(24);w.shadowButtons[index]=b
  b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('Soft shadows');GameTooltip:AddLine('Soft ground shading beneath pets and furniture. Turn off for less work on busy islands. Applies instantly.',1,1,1,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 w:RefreshShadows();w:SelectSettingsPage('View')
 function w:LayoutCameraButtons()
  self.viewbar:ClearAllPoints()
  if self.mode=='Edit'then self.viewbar:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-12,8)
  else self.viewbar:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',54,58)end
  self.cameraFly:SetShown(self.mode=='Camera'or self.mode=='Edit'or self.mode=='Buy')
  self.cameraFly:ClearAllPoints();self.cameraFly:SetPoint('RIGHT',self.viewbar,'LEFT',-6,0)
 end
 function w:RefreshTools()
  self:LayoutCameraButtons()
  browser:SetShown(self.mode=='Edit'and not e.catalogDrag)
  for name,b in pairs(self.toolButtons)do b:Paint(name=='Fly'and f.fly or name:lower()==e.tool and not f.fly)end
  for name,b in pairs(self.mainButtons)do b:Paint(name=='Settings'and self.settings:IsShown()or self.mode==name)end
  self.lockButton:Paint(f.cameraLocked);self.cameraFly:Paint(f.fly)
  self.toolButtons.Delete:SetEnabled(e.selected~=nil)
 end
 function w:SelectTool(name)
  e:EndGizmo(false);e.drag=nil;e.preview=nil;e.catalogDrag=nil;e.placing=false
  if name=='Fly'then
   f:Flight()
   f.status:SetText(f.fly and 'Fly: WASD | E/Q: up/down | Hold right mouse to look | Esc releases camera' or 'Select an object to edit.')
  else
   f:StopFlight()
   if name=='Delete'then
    e:DeleteSelected()
   else e.tool=name:lower();f.status:SetText(name=='Move'and 'Drag an arrow, or drag the object across the land.'or name=='Rotate'and 'Drag a ring to turn or tilt. White marks the start. Hold Shift for 45-degree steps.'or 'Drag a square handle outward to enlarge; inward to shrink.')end
  end
  self:RefreshTools()
 end
 function w:EditFromFlight(object)
  local tool=e.tool
  if tool~='move'and tool~='rotate'and tool~='size'then tool='move'end
  if self.mode~='Edit'then self:ShowMode('Edit',true)end
  self:SelectTool(tool:sub(1,1):upper()..tool:sub(2))
  e.selected=object.id;e:Refresh();e:GizmoUpdate();self:RefreshTools()
  f.status:SetText(I.decorByKey[object.key].name..' selected.')
 end
 for j,name in ipairs({'Move','Rotate','Size','Delete'})do
  w.toolButtons[name]=square(editbar,name,(j-1)*44,34,function()w:SelectTool(name)end)
 end
 -- Fade only for translation: turning the camera should leave browsing usable.
 w.focusAlpha=1;w.movementHold=0
 function w:UpdateFlightFocus(dt)
  local c=f.camera;local previous=self.focusPosition
  local moved=f.fly and previous and previous.fly and (math.abs(c.x-previous.x)+math.abs(c.y-previous.y)+math.abs(c.z-previous.z)>.00001)
  previous=previous or {};previous.x,previous.y,previous.z,previous.fly=c.x,c.y,c.z,f.fly;self.focusPosition=previous
  self.movementHold=moved and .18 or math.max(0,self.movementHold-dt)
  local target=f.fly and self.movementHold>0 and .08 or 1
  local alpha=self.focusAlpha
  if F.db.settings.reduceMotion then alpha=target
  elseif alpha<target then alpha=math.min(target,alpha+dt*5)
  else alpha=math.max(target,alpha-dt*5)end
  if alpha~=self.focusAlpha then
   self.focusAlpha=alpha;browser:SetAlpha(alpha)
   local ui=rawget(f,'lifeUI');if ui then ui.pets:SetAlpha(alpha);ui.menu:SetAlpha(alpha)end
  end
 end
 local ghost={actor=f.objectScene:CreateActor()};ghost.actor:Hide()
 I.HookViewportUpdate(f,function(_,dt)
  w:UpdateFlightFocus(dt)
  if settings:IsShown()then w:RefreshSkybox()end
  local count=#e.db.items;if w.lastCount~=count then w.lastCount=count;w.objectCount:SetText(count..' / '..I.objectLimit..' furnishings')end
  if e.catalogDrag and not IsMouseButtonDown('LeftButton')then
   e:EndAssetDrag(inside(f.input)and not inside(browser)and not inside(toolbar)and not inside(editbar)and not inside(viewbar)and not inside(w.cameraFly)and not inside(settings)and not inside(f.header))
  end
  if w.lastFly~=f.fly or w.lastSelected~=e.selected then w.lastFly=f.fly;w.lastSelected=e.selected;w:RefreshTools()end
  if browser:IsShown()then for _,card in ipairs(w.cards)do if card.key and not card.ready and not card.failed then
   card.age=card.age+dt
   if card.age>.4 and card.actor:IsLoaded()then
    local width,depth,height=I.ModelBounds(card.actor)
    if width then
     if not card.locked then I.CacheDecorBounds(card.key,width,depth,height)end
     -- Normalize wildly different native model sizes before fitting the card.
     I.FitPreview(card.actor,card.scene,width,depth,height)
     card.actor:Show();card.ready=true;card.loading:Hide()
    end
   end
   if card.age>8 and not card.ready then card.failed=true;card.loading:SetText('Unavailable in this client')end
  end end end
  if e.enabled and e.placing and e.preview then
   local o=e.preview;local d=I.decorByKey[o.key]
   if ghost.key~=o.key then
    ghost.key=o.key;ghost.ready=false;ghost.actor:Hide();ghost.actor:SetScale(1);ghost.actor:SetPosition(0,0,0);ghost.actor:SetUseCenterForOrigin(true,true,true)
    local ok,result=pcall(ghost.actor.SetModelByFileID,ghost.actor,d.asset.id);ghost.failed=not ok or result==false
   end
   if not ghost.failed and ghost.actor:IsLoaded()then
    local width,depth,height=I.ModelBounds(ghost.actor)
    if width then I.CacheDecorBounds(o.key,width,depth,height);ghost.baseScale=d.width/math.max(width,depth);ghost.height=height;ghost.ready=true end
   end
   if ghost.ready then e:Transform(ghost,o);ghost.actor:SetAlpha(.55)end
  else ghost.actor:Hide()end
 end)
 f:HookScript('OnHide',function()e.catalogDrag=nil;e.placementTemplate=nil;ghost.actor:Hide();settings:Hide()end)
 f:HookScript('OnShow',function()
  w:LayoutCameraButtons()
  camera:Hide();browser:SetShown(w.mode=='Edit'and not e.catalogDrag);editbar:SetShown(w.mode=='Edit');viewbar:SetShown(w.mode=='Edit'or w.mode=='Camera'or w.mode=='Buy');e.panel:Hide();e.buyPanel:SetShown(w.mode=='Buy');f.side:Hide()
 end)
 browser:HookScript('OnShow',function()w:Refresh()end)
 w:Refresh()
end
local open=I.Open
function I.Open(...)open(...);I.BuildWorkshop(I.ui)end
