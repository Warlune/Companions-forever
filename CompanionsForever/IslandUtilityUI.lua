local addonName,F=...
local I,P,S=F.Housing.Island,F.Pets,F.Style
local L=I.Life
local function tip(frame,title,body)
 frame:SetScript('OnEnter',function()GameTooltip:SetOwner(frame,'ANCHOR_RIGHT');GameTooltip:SetText(title);GameTooltip:AddLine(type(body)=='function'and body()or body,1,1,1,true);GameTooltip:Show()end)
 frame:SetScript('OnLeave',function()GameTooltip:Hide()end)
end
local function token(n)return n..' |T'..P.tokenIcon..':14:14|t'end
function L.BuildExpeditionUI(f,ui,pets)
 local exp=S.Panel(f,0,0,660,422);ui.expedition=exp;exp:ClearAllPoints();exp:SetPoint('CENTER',0,12);exp:SetFrameLevel(pets:GetFrameLevel()+25);exp:EnableMouse(true);exp:Hide()
 local art=exp:CreateTexture(nil,'BACKGROUND',nil,1);exp.expeditionArt=art
 art:SetPoint('TOPLEFT',3,-3);art:SetPoint('BOTTOMRIGHT',-3,3)
 art:SetTexture('Interface\\AddOns\\'..addonName..'\\Art\\ExpeditionChart.tga')
 -- The original 1536x1024 art is packed into a power-of-two game texture.
 art:SetTexCoord(0,.75,0,1)
 local shade=exp:CreateTexture(nil,'BACKGROUND',nil,2);exp.expeditionShade=shade;shade:SetAllPoints(art)
 S.Text(exp,'EXPEDITIONS',18,-14,400,'GameFontNormalLarge')
 S.Text(exp,'Choose a route',18,-44,178,'GameFontNormal')
 ui.difficulty=1;ui.repeatVoyages=false;ui.routes={}
 local routeScroll=CreateFrame('ScrollFrame',nil,exp,'UIPanelScrollFrameTemplate');ui.routeScroll=routeScroll
 routeScroll:SetPoint('TOPLEFT',14,-67);routeScroll:SetSize(184,280)
 local routeList=CreateFrame('Frame',nil,routeScroll);routeList:SetSize(184,#L.difficulties*70);routeScroll:SetScrollChild(routeList)
 routeScroll:EnableMouseWheel(true)
 routeScroll:SetScript('OnMouseWheel',function(self,delta)self:SetVerticalScroll(math.max(0,math.min(#L.difficulties*70-280,(self:GetVerticalScroll()or 0)-delta*70)))end)
 S.Text(exp,'Scroll for more routes',18,-351,180,'GameFontHighlightSmall')
 for index,d in ipairs(L.difficulties)do
  local row=CreateFrame('Button',nil,routeList,'BackdropTemplate');ui.routes[index]=row;row:SetSize(184,65);row:SetPoint('TOPLEFT',0,-(index-1)*70)
  row:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});row:SetBackdropColor(.025,.025,.03,1)
  row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(26,26);row.icon:SetPoint('TOPLEFT',7,-8);row.icon:SetTexture('Interface\\Icons\\'..d.icon)
  row.name=S.Text(row,d.name,39,-8,138,'GameFontNormalSmall');row.name:SetHeight(28)
  row.lock=S.Text(row,'',7,-37,170,'GameFontHighlightSmall');row.lock:SetHeight(26)
  row:SetScript('OnClick',function()ui.difficulty=index;ui.confirmCancel=false;ui:RefreshExpedition()end)
  tip(row,d.name,function()return d.label..' route\n'..L.ExpeditionRequirement(index)..'\nSend 1-3 pets. Stronger crews have better odds. Failure returns no rewards.'end)
 end
 ui.routeTitle=S.Text(exp,'',218,-46,420,'GameFontNormalLarge')
 ui.routeInfo=S.Text(exp,'',220,-75,418,'GameFontHighlight');ui.routeInfo:SetHeight(58)
 ui.crewCards={}
 for index=1,3 do
  local card=CreateFrame('Frame',nil,exp,'BackdropTemplate');ui.crewCards[index]=card;card:SetSize(134,46);card:SetPoint('TOPLEFT',220+(index-1)*140,-138)
  card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});card:SetBackdropColor(.015,.015,.02,1);card:SetBackdropBorderColor(.5,.5,.5,1)
  card.art=card:CreateTexture(nil,'ARTWORK');card.art:SetSize(30,30);card.art:SetPoint('TOPLEFT',5,-7)
  card.name=S.Text(card,'',40,-7,89,'GameFontNormalSmall');card.name:SetHeight(30)
 end
 S.Text(exp,'Rewards on success',220,-196,410,'GameFontNormal')
 ui.rewardCards={}
 for index=1,4 do
  local card=CreateFrame('Frame',nil,exp,'BackdropTemplate');ui.rewardCards[index]=card;card:SetSize(98,88);card:SetPoint('TOPLEFT',220+(index-1)*105,-220);card:EnableMouse(true)
  card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});card:SetBackdropColor(.015,.015,.02,1)
  card.art=card:CreateTexture(nil,'ARTWORK');card.art:SetSize(32,32);card.art:SetPoint('TOP',0,-6)
  card.name=S.Text(card,'',3,-43,92,'GameFontHighlightSmall');card.name:SetJustifyH('CENTER');card.name:SetHeight(27)
  card.odds=S.Text(card,'',3,-72,92,'GameFontNormalSmall');card.odds:SetJustifyH('CENTER')
  tip(card,'Expedition reward',function()return card.help or ''end)
 end
 ui.voyageBar=CreateFrame('StatusBar',nil,exp);ui.voyageBar:SetPoint('TOPLEFT',220,-321);ui.voyageBar:SetSize(414,7);ui.voyageBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');ui.voyageBar:SetMinMaxValues(0,1);ui.voyageBar:SetStatusBarColor(.2,.65,1)
 ui.voyageStatus=S.Text(exp,'',220,-335,416,'GameFontHighlightSmall');ui.voyageStatus:SetHeight(33)
 local function action(ok,message)ui.voyageMessage=message;ui.messageUntil=F.Now()+5;P.notice=message;ui:RefreshExpedition()end
 ui.depart=S.Button(exp,'Depart',18,-374,144,function()action(L.StartExpedition(ui.difficulty,ui.repeatVoyages))end)
 ui.repeatButton=S.Button(exp,'Repeat: off',174,-374,144,function()
  ui.repeatVoyages=not ui.repeatVoyages;L.State().repeatTrip=ui.repeatVoyages and L.State().trip~=nil;ui:RefreshExpedition()
 end)
 ui.cancel=S.Button(exp,'Cancel voyage',330,-374,144,function()
  if not ui.confirmCancel then ui.confirmCancel=true;ui.voyageMessage='Cancel again to abandon this voyage and all its rewards.';ui:RefreshExpedition();return end
  ui.confirmCancel=false;action(L.CancelExpedition())
 end)
 S.Button(exp,'Close',486,-374,154,function()exp:Hide();ui.confirmCancel=false end)
 function ui:RefreshExpedition()
  if not exp:IsShown()then return end
  shade:SetColorTexture(0,0,0,S.HighContrast()and .88 or .38)
  if self.messageUntil and F.Now()>=self.messageUntil then self.voyageMessage=nil;self.messageUntil=nil end
  local state=L.State();local d=L.difficulties[self.difficulty];local crew=L.Team();local trip=state.trip
  for index,row in ipairs(self.routes)do
   local route=L.difficulties[index];local open=L.ExpeditionUnlocked(index);row.icon:SetDesaturated(not open)
   row.lock:SetText(open and route.label or route.masters and '2/8 Master Trainers\nComing later' or (route.hardFloor and 'Hard Mode floor '..route.hardFloor or 'Normal floor '..route.floor)..' | Locked')
   S.TextColor(row.name,open and P.colors[route.gear]or S.muted)
   row:SetBackdropBorderColor(index==self.difficulty and 1 or .4,index==self.difficulty and .8 or .4,index==self.difficulty and .2 or .4,1)
  end
  self.routeTitle:SetText(d.name);S.TextColor(self.routeTitle,P.colors[d.gear])
  local open=L.ExpeditionUnlocked(self.difficulty);local station=L.Station('expedition')
  local chance=open and L.ExpeditionChance(self.difficulty,crew)or 0
  self.routeInfo:SetText((open and d.label..' | Estimated success: '..chance..'%'or L.ExpeditionRequirement(self.difficulty))..'\n'..(station and L.DurationText(L.TripSeconds())..' voyage | 10 min rest' or 'Buy and place an expedition boat.')..'\nCrew: 1-3 pets. Solo voyages allowed.')
  local displayed=crew;if trip then displayed={};for _,id in ipairs(trip.ids)do displayed[#displayed+1]=L.Pet(id)end end
  for index,card in ipairs(self.crewCards)do
   local pet=displayed[index];card.art:SetShown(pet~=nil);card.name:SetText(pet and P.PetName(pet)..'\nLv '..pet.level or (#displayed>0 and 'Optional crew slot'or 'Empty crew slot'))
   if pet then P.ShowPetPortrait(card.art,pet);card:SetBackdropBorderColor(unpack(P.colors[pet.rarity]))else card:SetBackdropBorderColor(.4,.4,.4,1)end
  end
  local crate=P.BagDefinition({crate=d.crate})
  local ids={};for _,pet in ipairs(crew)do ids[#ids+1]=pet.id end
  local active=trip and trip.difficulty==self.difficulty and trip
  local tokens=L.ExpeditionTokens(self.difficulty,active and active.duration or L.TripSeconds(),active and active.outputBonus or L.TeamHousingBonus('output',ids))
  local odds=L.expeditionFindOdds
  local rewards={
   {icon=P.tokenIcon,name=token(tokens),odds='Guaranteed',color={1,.82,.2},help='On success: '..tokens..' tokens. Scales with voyage length and token bonuses. A find is not guaranteed.'},
   {icon='Interface\\Icons\\'..(crate and crate.icon or 'INV_Crate_01'),name='Pet crate',odds=odds.crate..'%',color=P.colors[P.CrateRarity(d.crate)],help=odds.crate..'% on success: '..(crate and crate.name or 'Adoption crate')..'. Contains a pet, not equipment.'},
   {icon='Interface\\Icons\\INV_Chest_Plate06',name='Gear',odds=odds.gear..'%',color=P.colors[d.gear],help=L.ExpeditionGearHelp(self.difficulty)},
   {icon='Interface\\Icons\\INV_Misc_Note_01',name='Furnishing',odds=odds.furniture..'%',color={1,1,1},help=odds.furniture..'% on success: one undiscovered expedition furnishing. If all are known, 1 extra token.'},
  }
  for index,card in ipairs(self.rewardCards)do local r=rewards[index];card.art:SetTexture(r.icon);card.name:SetText(r.name);card.odds:SetText(r.odds);card.help=r.help;S.TextColor(card.name,r.color);card:SetBackdropBorderColor(unpack(r.color))end
  self.repeatButton:SetText('Repeat: '..(self.repeatVoyages and 'on'or 'off'))
  self.depart:SetEnabled(not trip and open and station~=nil and #crew>0)
  self.cancel:SetEnabled(trip~=nil)
  self.voyageBar:SetValue(trip and trip.elapsed/(trip.duration or 1800)or 0)
  self.voyageStatus:SetText(self.voyageMessage or (trip and L.difficulties[trip.difficulty].name..': '..math.ceil(((trip.duration or 1800)-trip.elapsed)/60)..' min remaining' or state.lastTrip and (state.lastTrip.success and 'Last voyage: success. Claim your rewards on the island.'or 'Last voyage: crew returned without rewards.')or 'Requires 80% energy. Failure does not kill your pets.'))
 end
 exp:HookScript('OnShow',function()
  ui.voyageMessage=nil;ui.repeatVoyages=L.State().repeatTrip==true
  routeScroll:SetVerticalScroll(math.min(#L.difficulties*70-280,(ui.difficulty-1)*70));ui:RefreshExpedition()
 end)
 return exp
end
function I.BuildUtilityRings(f)
 if rawget(f,'utilityRings')then return end
 local g=CreateFrame('Frame',nil,f.canvas);f.utilityRings=g;g:SetAllPoints();g:EnableMouse(false);g:SetFrameLevel(f.scene:GetFrameLevel()+1);g.rings={}
 local last,elapsed
 local corners={{-1,1},{-1,-1},{1,1},{1,-1}}
 local vertices={UPPER_LEFT_VERTEX or 1,LOWER_LEFT_VERTEX or 2,UPPER_RIGHT_VERTEX or 3,LOWER_RIGHT_VERTEX or 4}
 local function ring(o,radius,color)
  local w,h=f.input:GetWidth(),f.input:GetHeight()
  local points={};local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
  for n,corner in ipairs(corners)do
   local x,y=I.SceneProject(f.scene,o.x+corner[1]*radius,o.y+corner[2]*radius,o.z+.06)
   -- Hide quads crossing the near plane; the canvas clips ordinary screen edges.
   if not x or math.abs(x)>16 or math.abs(y)>16 then return end
   x,y=(x+1)*w/2,(y+1)*h/2;points[n]={x,y}
   left,bottom,right,top=math.min(left,x),math.min(bottom,y),math.max(right,x),math.max(top,y)
  end
  if right<0 or left>w or top<0 or bottom>h or right-left<.1 or top-bottom<.1 then return end
  g.used=g.used+1;local t=g.rings[g.used]
  if not t then
   t=g:CreateTexture(nil,'OVERLAY');g.rings[g.used]=t
   -- Blizzard's player selection circle, projected onto the station's ground plane.
   t:SetTexture(186224,'CLAMP','CLAMP','LINEAR') -- Textures/UnitSelectTexture.blp
   t:SetSnapToPixelGrid(false);t:SetTexelSnappingBias(0)
  end
  t:ClearAllPoints();t:SetPoint('BOTTOMLEFT',g,'BOTTOMLEFT',left,bottom);t:SetSize(right-left,top-bottom)
  for n,point in ipairs(points)do
   local baseX=n<=2 and left or right;local baseY=n%2==1 and top or bottom
   -- Verified in the client: positive vertex Y offsets move upward.
   t:SetVertexOffset(vertices[n],point[1]-baseX,point[2]-baseY)
  end
  t:SetVertexColor(unpack(color));t:Show()
 end
 local colors={food={.25,1,.3,1},herbs={.1,.9,.8,1},gold={1,.8,.15,1},xp={.65,.4,1,1},expedition={.2,.65,1,1}}
 I.HookViewportUpdate(f,function(_,dt)
  elapsed=(elapsed or 0)+dt;if elapsed<.1 then return end;elapsed=0
  local c=f.camera;local signature=table.concat({c.x,c.y,c.z,c.yaw,c.pitch,I.navRevision or 0,f.input:GetWidth(),f.input:GetHeight()},':')
  if last==signature then return end;last=signature;g.used=0
  for _,v in ipairs(f.editor.actors)do if v.used and v.ready then
   local o=v.object;local d=I.decorByKey[o.key]
   if d.station then
    local radius=math.max(.65,d.width*o.size*.48);local color=colors[d.station]
    ring(o,radius,color)
   end
  end end
  for n=g.used+1,#g.rings do g.rings[n]:Hide()end
 end)
 f:HookScript('OnShow',function()last=nil end)
end
local open=I.Open
function I.Open(...)open(...);I.BuildUtilityRings(I.ui)end
