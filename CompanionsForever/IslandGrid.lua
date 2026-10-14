local _,F=...
local I,S=F.Housing.Island,F.Style
-- Owned-land perimeter in Edit; neighboring purchasable plots only in Buy.
function I.BuildGrid(f)
 if rawget(f,'buildGrid')then return end
 local e=f.editor
 local g=CreateFrame('Frame',nil,f.canvas);f.buildGrid=g;g:SetAllPoints();g:EnableMouse(false);g:SetFrameLevel(f.scene:GetFrameLevel()+1)
 g.lines={};g.elapsed=0
 local buyPanel=I.Dock(f,70);e.buyPanel=buyPanel;buyPanel:Hide()
 buyPanel:SetScale(1);buyPanel:ClearAllPoints();buyPanel:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',12,110);buyPanel:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-12,110)
 local label=S.Text(buyPanel,'',12,-10,690,'GameFontHighlightSmall');label:ClearAllPoints();label:SetPoint('TOPLEFT',12,-10);label:SetPoint('TOPRIGHT',-190,-10);label:SetHeight(48)
 local buy=S.Button(e.panel,'Expand land',696,-124,114,function()
  e.landMode=not e.landMode;e.placing=false;e.drag=nil;e.preview=nil;e.landChoice=nil
  f.status:SetText(e.landMode and 'Choose a neighboring parcel, then buy it below.'or 'Object editing.')
 end)
 local warning=CreateFrame('Frame',nil,f);e.landWarning=warning;warning:SetAllPoints();warning:SetFrameLevel(f.input:GetFrameLevel()+100);warning:EnableMouse(true);warning:EnableMouseWheel(true);warning:Hide()
 local dialog=S.Panel(warning,0,0,440,224);dialog:ClearAllPoints();dialog:SetPoint('CENTER');dialog:EnableMouse(true)
 S.Text(dialog,'CANCEL EXPEDITION?',18,-16,404,'GameFontNormalLarge')
 local warningText=S.Text(dialog,'',18,-46,404,'GameFontHighlight');warningText:SetHeight(126)
 local purchase
 purchase=function(x,y,trip)
  local ok,reason,affected=I.BuyLand(x,y,trip);f.status:SetText(reason)
  if affected then
   f:StopFlight();warning.x,warning.y,warning.trip=x,y,affected
   warningText:SetText('Buying this land will cancel the current expedition and lose this trip\'s rewards, even if the boat has sailed away.\n\nThe boat will be removed and fully refunded. Repeat trips stop. Buy for '..I.LandPrice()..' gold?')
   warning:Show();return
  end
  warning:Hide()
  if ok then f:SyncLand();e.landChoice=nil end
 end
 S.Button(dialog,'Buy and cancel trip',18,-186,212,function()purchase(warning.x,warning.y,warning.trip)end)
 S.Button(dialog,'Keep expedition',242,-186,180,function()warning:Hide()end)
 buyPanel:HookScript('OnHide',function()warning:Hide()end)
 local confirm=S.Button(buyPanel,'Buy: '..I.LandPrice()..' gold',776,-18,160,function()
  local p=e.landChoice;if not p then f.status:SetText('Select an outlined plot first.');return end
  purchase(p.x,p.y)
 end)
 confirm:ClearAllPoints();confirm:SetPoint('RIGHT',buyPanel,'RIGHT',-12,0)
 local function line(x1,y1,x2,y2,color)
  -- Clip projected segments to the scene before passing coordinates to the UI.
  local a,b=I.SceneProject(f.scene,x1,y1,.08);local c,d=I.SceneProject(f.scene,x2,y2,.08)
  if not a or not c then return end
  local dx,dy=c-a,d-b;local lo,hi=0,1
  for _,v in ipairs({{-dx,a+1},{dx,1-a},{-dy,b+1},{dy,1-b}})do
   if math.abs(v[1])<.000001 then if v[2]<0 then return end
   else local t=v[2]/v[1];if v[1]<0 then lo=math.max(lo,t)else hi=math.min(hi,t)end end
  end
  if lo>hi then return end
  local w,h=f.input:GetWidth()/2,f.input:GetHeight()/2
  g.used=g.used+1;local l=g.lines[g.used]
  if not l then l=g:CreateLine(nil,'OVERLAY');g.lines[g.used]=l;l:SetThickness(1.5)end
  l:SetStartPoint('BOTTOMLEFT',(a+lo*dx+1)*w,(b+lo*dy+1)*h)
  l:SetEndPoint('BOTTOMLEFT',(a+hi*dx+1)*w,(b+hi*dy+1)*h)
  l:SetColorTexture(unpack(color));l:Show()
 end
 local function rect(x,y,w,h,color)
  line(x-w,y-h,x+w,y-h,color);line(x+w,y-h,x+w,y+h,color)
  line(x+w,y+h,x-w,y+h,color);line(x-w,y+h,x-w,y-h,color)
 end
 local bad={1,.15,.12,.9};local edge={1,.78,.25,.9};local selected={.25,.85,1,1}
 f.input:HookScript('OnMouseDown',function(_,button)
  if not e.enabled or not e.landMode then return end
  if button=='RightButton'then e.landChoice=nil;return end
  if button~='LeftButton'then return end
  local x,y=e.PlaceXY(0);if not x then return end
  local px,py=math.floor((x+8)/16),math.floor((y+8)/16)
  local ok,reason=I.CanBuyLand(px,py)
  if ok then e.landChoice={x=px,y=py};f.status:SetText('Selected land. Buy below for '..I.LandPrice()..' gold.')else e.landChoice=nil;f.status:SetText(reason)end
 end)
 I.HookViewportUpdate(f,function(_,dt)
  g.elapsed=g.elapsed+dt;if g.elapsed<.05 then return end;g.elapsed=0
  g:SetShown(e.enabled);buyPanel:SetShown(e.enabled and e.landMode==true)
  if not e.enabled then return end
  local land=F.char.islandPrototype.land;g.used=0;local count=0
  for _,p in pairs(land)do
   count=count+1;local x,y=p.x*16,p.y*16
   if not land[(p.x-1)..':'..p.y]then line(x-8,y-8,x-8,y+8,bad)end
   if not land[(p.x+1)..':'..p.y]then line(x+8,y-8,x+8,y+8,bad)end
   if not land[p.x..':'..(p.y-1)]then line(x-8,y-8,x+8,y-8,bad)end
   if not land[p.x..':'..(p.y+1)]then line(x-8,y+8,x+8,y+8,bad)end
  end
  for x=-2,2 do for y=-2,2 do if not land[x..':'..y]then
   local adjacent=land[(x-1)..':'..y]or land[(x+1)..':'..y]or land[x..':'..(y-1)]or land[x..':'..(y+1)]
   if e.landMode and adjacent then rect(x*16,y*16,8,8,edge)end
  end end end
  if e.landChoice then rect(e.landChoice.x*16,e.landChoice.y*16,7.7,7.7,selected)end
  if e.placing and not e.landMode then
   local z=e:PlacementObject(0,0).z
   local x,y=e.PlaceXY(z)
   if x then e.preview=e:PlacementObject(x,y);e.previewOK=I.CanPlace(e.preview,e.db.items)else e.preview=nil end
  elseif not e.drag and not e.gizmoDrag then e.preview=nil end
  if e.preview then
   if not e.previewOK then local w,h=I.Footprint(e.preview);rect(e.preview.x,e.preview.y,w,h,bad)end
   local ok,reason=I.CanPlace(e.preview,e.db.items);f.status:SetText(reason)
  end
  for n=g.used+1,#g.lines do g.lines[n]:Hide()end
  label:SetText(string.format('%d / 25 plots owned  |  %d |T%s:14:14|t\nChoose a gold outlined plot to expand.',count,F.Pets.state.tokens,F.Pets.tokenIcon))
  if f.workshop then buyPanel:SetBackdropColor(.025,.025,.035,f.workshop:ButtonOpacity())end
  confirm:SetText('Buy: '..I.LandPrice(land)..' gold')
  confirm:SetEnabled(e.landChoice~=nil and I.CanBuyLand(e.landChoice.x,e.landChoice.y)==true)
 end)
 f:HookScript('OnHide',function()g:Hide();buyPanel:Hide();e.landChoice=nil;e.landMode=false end)
end
local open=I.Open
function I.Open(...)open(...);I.BuildGrid(I.ui)end
