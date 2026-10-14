local _,F=...
local I,S=F.Housing.Island,F.Style
local L={};I.Atmosphere=L
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function bound(n,default,lo,hi)return finite(n)and I.Clamp(n,lo,hi)or default end
function L.Clean(value)
 local v=type(value)=='table'and value or {}
 return {mode=(v.mode=='realm'or v.mode=='cycle')and v.mode or 'fixed',hour=bound(v.hour,12,0,24)%24,
  fog=(v.fog=='haze'or v.fog=='dense')and v.fog or 'off',gain=bound(v.gain,1,.5,1.5),angle=bound(v.angle,0,-360,360)}
end
-- Local scene lighting, never world time or the world's weather renderer.
local keys={
 {hour=0,ambient={.13,.17,.28},diffuse={.14,.19,.32},sky={.025,.04,.09},alpha=.18},
 {hour=6,ambient={.36,.28,.30},diffuse={.65,.36,.22},sky={.52,.31,.35},alpha=.60},
 {hour=12,ambient={.55,.55,.55},diffuse={.45,.44,.40},sky={.32,.60,.75},alpha=1},
 {hour=18,ambient={.38,.25,.24},diffuse={.65,.30,.16},sky={.55,.27,.22},alpha=.55},
 {hour=24,ambient={.13,.17,.28},diffuse={.14,.19,.32},sky={.025,.04,.09},alpha=.18},
}
function L.Sample(hour)
 hour=bound(hour,12,0,24)%24
 local a,b=keys[1],keys[2]
 for j=1,#keys-1 do if hour>=keys[j].hour and hour<=keys[j+1].hour then a,b=keys[j],keys[j+1];break end end
 local t=(hour-a.hour)/(b.hour-a.hour);t=t*t*(3-2*t)
 local r={alpha=a.alpha+(b.alpha-a.alpha)*t}
 for _,key in ipairs({'ambient','diffuse','sky'})do r[key]={};for j=1,3 do r[key][j]=a[key][j]+(b[key][j]-a[key][j])*t end end
 return r
end
function L.Advance(v,dt,reduced)
 if v.mode=='cycle'and not reduced then v.hour=(v.hour+bound(dt,0,0,60)*24/300)%24
 elseif v.mode=='realm'and type(GetGameTime)=='function'then
  local ok,h,m=pcall(GetGameTime)
  if ok and finite(h)and finite(m)then v.hour=(h+m/60)%24 end
 end
end
function I.HousingTimeMode()
 local mode=F.char and F.char.housingTimeMode
 return (mode=='day'or mode=='night'or mode=='realm')and mode or 'cycle'
end
function L.UseTimeSetting(v)
 local mode=I.HousingTimeMode()
 v.mode=(mode=='cycle'or mode=='realm')and mode or 'fixed'
 if mode=='day'or mode=='night'then v.hour=mode=='day'and 12 or 0 end
 L.Advance(v,0,F.db.settings.reduceMotion)
end
function L.StepTimeTransition(a,dt)
 local t=a.timeTransition;if not t then return false end
 t.elapsed=math.min(3,t.elapsed+bound(dt,0,0,60))
 local progress=t.elapsed/3;local eased=progress*progress*(3-2*progress)
 a.db.hour=(t.from+t.delta*eased)%24
 if progress>=1 then a.db.hour=t.target;a.timeTransition=nil end
 return true
end
function I.SetHousingTimeMode(mode)
 if mode~='cycle'and mode~='realm'and mode~='day'and mode~='night'then return false end
 F.char.housingTimeMode=mode
 local f=I.ui;local a=f and rawget(f,'atmosphere')
 if a then
  local from=a.db.hour;a.timeTransition=nil
  L.UseTimeSetting(a.db)
  if mode=='day'or mode=='night'then
   local target=a.db.hour;local delta=(target-from)%24;if delta>12 then delta=delta-24 end
   if math.abs(delta)>.0001 then a.timeTransition={from=from,delta=delta,target=target,elapsed=0};a.db.hour=from end
  end
  L.Apply(f)
 end
 return true
end
local function invoke(a,scene,key,...)
 if a.support[key]==false then return false end
 if type(scene[key])~='function'then a.support[key]=false;return false end
 local ok,result=pcall(scene[key],scene,...)
 a.support[key]=ok and result~=false
 return a.support[key]
end
function L.Apply(f)
 local a=f.atmosphere;local v=a.db;local p=L.Sample(v.hour)
 local ambient,diffuse={},{}
 for j=1,3 do
  ambient[j]=I.Clamp(p.ambient[j]*v.gain,F.db.settings.highContrast and .32 or .05,1)
  diffuse[j]=I.Clamp(p.diffuse[j]*v.gain,0,1)
 end
 local angle=math.rad(v.hour/24*360+v.angle)
 local lit=invoke(a,f.scene,'SetLightVisible',true)
 local am=invoke(a,f.scene,'SetLightAmbientColor',unpack(ambient))
 local di=invoke(a,f.scene,'SetLightDiffuseColor',unpack(diffuse))
 local direction=invoke(a,f.scene,'SetLightDirection',math.cos(angle),math.sin(angle),-.8)
 a.lighting=lit and am and di and direction
 if f.objectScene then
  f.objectScene:SetLightVisible(true);f.objectScene:SetLightAmbientColor(unpack(ambient));f.objectScene:SetLightDiffuseColor(unpack(diffuse));f.objectScene:SetLightDirection(math.cos(angle),math.sin(angle),-.8)
 end
 f.skyBackground:SetColorTexture(p.sky[1],p.sky[2],p.sky[3],1)
 -- Sky models may be self-lit; blend the existing native sky against its tint.
 if f.sky.loaded then f.sky.actor:SetAlpha(p.alpha)end
 if v.fog=='off'then a.fog=invoke(a,f.scene,'ClearFog')else
  local near,far=v.fog=='dense'and 12 or 100,v.fog=='dense'and 110 or 550
  local color=invoke(a,f.scene,'SetFogColor',unpack(p.sky))
  local first=invoke(a,f.scene,'SetFogNear',near)
  local last=invoke(a,f.scene,'SetFogFar',far)
  a.fog=color and first and last
  if not a.fog then invoke(a,f.scene,'ClearFog')end
 end
 a:Refresh()
end
function L.Build(f)
 if rawget(f,'atmosphere')then return end
 local saved=I.SavedScene();saved.atmosphere=L.Clean(saved.atmosphere)
 L.UseTimeSetting(saved.atmosphere)
 local a={db=saved.atmosphere,support={},elapsed=0};f.atmosphere=a
 local panel=I.Dock(f,194);a.panel=panel;panel:Hide()
 S.Text(panel,'LIGHT & ATMOSPHERE',18,-14,230,'GameFontNormal')
 a.info=S.Text(panel,'',18,-44,230,'GameFontHighlightSmall');a.info:SetHeight(78)
 function a:Refresh()
  local v=self.db;local minutes=math.floor(v.hour*60)%1440
  local mode=v.mode=='cycle'and '5-minute cycle'or v.mode=='realm'and 'Realm clock'or 'Fixed time'
  if v.mode=='realm'and type(GetGameTime)~='function'then mode='Realm clock unavailable'end
  if F.db.settings.reduceMotion and v.mode=='cycle'then mode='Cycle paused: reduced motion'end
  self.info:SetText(string.format('%02d:%02d | %s\nLighting: %s\nFog: %s',math.floor(minutes/60),minutes%60,mode,self.lighting and 'ready'or 'unavailable',self.fog and 'experimental (no visible effect yet)'or 'unavailable'))
  self.fogButton:SetText('Fog: '..v.fog)
  self.help:SetText(string.format('Brightness: %.0f%% | Light angle: %.0f\nWater buttons compare native models. World-map liquid rendering is separate.',v.gain*100,v.angle))
 end
 function a:Close()self.open=false;self.panel:Hide();f.side:Hide()end
 function a:Toggle()
  if self.open then self:Close();return end
  if f.editor.enabled then f.editor:Toggle()end
  f:StopFlight();self.open=true;f.side:Hide();self.panel:Show();L.Apply(f)
 end
 local toggle=f.editor.Toggle
 function f.editor:Toggle(...)if a.open then a:Close()end;return toggle(self,...)end
 S.Button(f.side,'Light & atmosphere',604,-92,190,function()a:Toggle()end)
 for j,spec in ipairs({{'Dawn',6},{'Day',12},{'Dusk',18},{'Night',0}})do
  local hour=spec[2]
  S.Button(panel,spec[1],268+(j-1)*114,-16,106,function()a.db.mode='fixed';a.db.hour=hour;L.Apply(f)end)
 end
 S.Button(panel,'Realm time',268,-52,150,function()a.db.mode='realm';L.Advance(a.db,0,F.db.settings.reduceMotion);L.Apply(f)end)
 S.Button(panel,'Preview cycle',428,-52,150,function()a.db.mode=a.db.mode=='cycle'and 'fixed'or 'cycle';L.Apply(f)end)
 a.fogButton=S.Button(panel,'Fog: off',588,-52,154,function()a.db.fog=({off='haze',haze='dense',dense='off'})[a.db.fog];L.Apply(f)end)
 S.Button(panel,'Light -',268,-88,106,function()a.db.gain=I.Clamp(a.db.gain-.1,.5,1.5);L.Apply(f)end)
 S.Button(panel,'Light +',382,-88,106,function()a.db.gain=I.Clamp(a.db.gain+.1,.5,1.5);L.Apply(f)end)
 S.Button(panel,'Turn light -',496,-88,118,function()a.db.angle=(a.db.angle-30)%360;L.Apply(f)end)
 S.Button(panel,'Turn light +',624,-88,118,function()a.db.angle=(a.db.angle+30)%360;L.Apply(f)end)
 S.Button(panel,'6XP water',268,-124,150,function()f:UseScenery('water',I.SceneryAsset('water',1093938))end)
 S.Button(panel,'10XP water',428,-124,150,function()f:UseScenery('water',I.SceneryAsset('water',5097445))end)
 a.help=S.Text(panel,'',760,-54,178,'GameFontHighlightSmall');a.help:SetHeight(124)
 S.Button(panel,'Back to camera',760,-16,178,function()a:Close()end)
 I.HookViewportUpdate(f,function(_,dt)
  local transitioned=L.StepTimeTransition(a,dt)
  if not transitioned then L.Advance(a.db,dt,F.db.settings.reduceMotion)end
  a.elapsed=a.elapsed+dt;if not transitioned and a.elapsed<.25 then return end;a.elapsed=0;L.Apply(f)
 end)
 f:HookScript('OnHide',function()a.elapsed=0;a:Close()end)
 f:HookScript('OnShow',function()L.Advance(a.db,0,F.db.settings.reduceMotion);L.Apply(f)end)
 L.Apply(f)
end
local open=I.Open
function I.Open(...)open(...);L.Build(I.ui)end
