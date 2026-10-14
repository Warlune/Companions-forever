-- Camp keeps housing residents separate from the stable, without moving save records.
local _,F=...
local P,S,I=F.Pets,F.Style,F.Housing.Island
local L=I.Life
local function finish(ok,message)
 P.notice=message or '';P.Render();return ok
end
local function timeLeft(seconds)
 seconds=math.max(0,math.ceil(seconds));return math.floor(seconds/60)..':'..string.format('%02d',seconds%60)
end
function L.CampProgress(slot,pet,state)
 if not slot or not pet then return 'Drag a stable pet here',0 end
 if state.cityRest then local activity,progress=L.Activity(slot,pet,state);return activity..' | City rest',progress end
 if state.trip then for _,id in ipairs(state.trip.ids)do if id==pet.id then
  return 'Sailing '..timeLeft((state.trip.duration or 1800)-state.trip.elapsed),state.trip.elapsed/(state.trip.duration or 1800)
 end end end
 if (slot.rest or 0)>0 then return 'Resting '..timeLeft(slot.rest),math.max(0,math.min(1,(pet.energy or 0)/100))end
 if slot.job=='roam'then return 'Roaming | '..math.floor(pet.energy or 0)..'% energy',(pet.energy or 0)/100 end
 if slot.job=='expedition'then return 'Crew | '..math.floor(pet.energy or 0)..'% energy',(pet.energy or 0)/100 end
 if not L.Station(slot.job)then return 'Needs workstation',0 end
 local interval=L.WorkSeconds(pet,slot.job)
 return (L.jobNames[slot.job]or 'Working')..' '..timeLeft(interval-(slot.elapsed or 0)),math.min(1,(slot.elapsed or 0)/interval)
end
function L.RefreshCamp()
 local w=P.window;local box=w and rawget(w,'housingCamp');if not box or not P.state then return end
 local visible=P.mode=='collection';box:SetShown(visible)
 w.notice:SetWidth(visible and 456 or 732)
 if not visible then return end
 for _,slot in ipairs(w.gearPreview.slots)do
  local item=rawget(slot,'item');slot.status:Hide();S.TextColor(slot.label,item and P.colors[item.rarity]or S.muted)
 end
 local state=L.State()
 for index,row in ipairs(box.rows)do
  local slot=state.slots[index];local pet=slot and L.Pet(slot.petID)
  row.petID=pet and pet.id;row.pet=pet
  row.name:SetText(pet and P.PetName(pet)or 'Housing slot '..index)
  S.TextColor(row.name,pet and P.colors[pet.rarity]or S.muted)
  local status,progress=L.CampProgress(slot,pet,state);row.status:SetText(status);row.bar:SetValue(progress)
  row.level:SetText(pet and ('Lv '..pet.level)or '')
  local energy=pet and math.max(0,math.min(100,pet.energy or 0))or 0
  row.energy:SetValue(energy);row.energy.text:SetText(pet and (math.floor(energy)..' / 100')or '')
  local cap=pet and pet.level>=P.LevelCap();local needed=pet and P.XPNeeded(pet)or 1
  row.xp:SetValue(pet and (cap and 100 or (pet.xp or 0)/needed*100)or 0)
  row.xp.text:SetText(pet and (cap and 'MAX XP'or ((pet.xp or 0)..' / '..needed..' XP'))or '')
  row.portrait:SetShown(pet~=nil)
  P.StyleSparklyPortrait(row.portrait,pet)
  if pet then P.ShowPetPortrait(row.portrait,pet)end
  row:SetBackdropBorderColor(unpack(pet and P.colors[pet.rarity]or {.35,.35,.35}))
 end
 local pets={};local living=0
 for _,pet in ipairs(P.state.pets)do if not pet.deadAt and not L.IsHoused(pet.id)then pets[#pets+1]=pet;living=living+1 end end
 for _,pet in ipairs(P.state.pets)do if pet.deadAt then pets[#pets+1]=pet end end
 local pages=math.max(1,math.ceil(#pets/P.stableCapacity));P.page=math.max(1,math.min(P.page,pages))
 if P.GetStableLayout then
  pets,pages=P.GetStableLayout()
  for index,pet in pairs(pets)do if L.IsHoused(pet.id)then pets[index]=nil end end
  P.page=math.max(1,math.min(P.page,pages))
 end
 local c=w.collection;c.page:SetText(living..' in stable'..(pages>1 and (' | '..P.page..'/'..pages)or ''))
 c.prev:SetShown(pages>1);c.next:SetShown(pages>1)
 c.equip:SetEnabled(not L.IsHoused(P.viewID)and not P.state.battle and L.Pet(P.viewID)~=nil and P.viewID~=P.state.active)
 for index,row in ipairs(c.rows)do
  local pet=pets[(P.page-1)*P.stableCapacity+index];row.pet=pet;row.petID=pet and pet.id
  if P.GetStableLayout then row.stableSlot=(P.page-1)*P.stableCapacity+index end
  row.art:SetShown(pet~=nil);row.selected:SetShown(pet~=nil and pet.id==P.viewID)
  P.StyleSparklyPortrait(row.art,pet)
  if pet then
   P.ShowPetPortrait(row.art,pet);row.art:SetDesaturated(pet.deadAt~=nil)
   row.info:SetText((pet.id==P.state.active and '* 'or pet.isNew and '+ 'or '')..(P.stableCapacity>9 and ''or 'Lv ')..pet.level)
   S.TextColor(row.info,P.colors[pet.rarity]);row:SetBackdropBorderColor(unpack(P.colors[pet.rarity]))
  else row.info:SetText('');row:SetBackdropBorderColor(.2,.2,.2,1)end
 end
end
function L.BuildCamp()
 local w=P.window;if not w or rawget(w,'housingCamp')then return end
 local gear=w.gearPreview
 -- Remove the old heading and its Equipment shortcut (including the boot icon).
 for _,region in ipairs({gear:GetRegions()})do if region:GetObjectType()=='FontString'and region:GetText()=='EQUIPPED GEAR'then region:Hide()end end
 for _,child in ipairs({gear:GetChildren()})do if child:GetObjectType()=='Button'then child:Hide()end end
 gear:ClearAllPoints();gear:SetPoint('TOPLEFT',w.home,'TOPLEFT',492,-524);gear:SetSize(488,54)
 for index,slot in ipairs(gear.slots)do
  slot:ClearAllPoints();slot:SetPoint('TOPLEFT',6+(index-1)*96,-4);slot:SetSize(92,46)
  slot.art:ClearAllPoints();slot.art:SetPoint('TOP',0,-1);slot.art:SetSize(26,26)
  slot.label:ClearAllPoints();slot.label:SetPoint('TOP',0,-28);slot.label:SetSize(92,16);slot.status:Hide()
  slot:SetScript('OnMouseUp',function(_,button)if button=='LeftButton'then P.OpenEquipment()end end)
  slot:SetScript('OnEnter',function(self)P.EquipmentTooltip(self,self.item,'Click to open Equipment.')end)
 end
 local box=S.Panel(w.home,492,-582,488,108);w.housingCamp=box;box.rows={}
 S.Text(box,'HOUSING PETS',10,-5,230,'GameFontNormalSmall')
 local hint=S.Text(box,'Drag here | Right-click to return',222,-5,254,'GameFontHighlightSmall');hint:SetJustifyH('RIGHT')
 local function validDrag(drag)
  if drag.state~=P.state or P.state.battle or P.state.trade then return false end
  local rows,_,positions=P.GetStableLayout();local pet=drag.housed and L.Pet(drag.id)or rows[positions[drag.id]]
  if not pet or pet.assetID~=drag.assetID then return false end
  if drag.housed then
   local slot=L.State().slots[drag.source];return slot and slot.petID==drag.id
  end
  return not L.IsHoused(drag.id)and positions[drag.id]==drag.source
 end
 local function endDrag(target)
  local drag=rawget(box,'drag');if not drag then return end;box.drag=nil;box.ghost:Hide()
  if not validDrag(drag)then finish(false,'The pet moved. Drag it again.');return end
  if not target then for index,row in ipairs(box.rows)do if row:IsMouseOver()then target=index;break end end end
  if target and not drag.housed then finish(L.Assign(drag.id,target))
  elseif P.StableDropTarget then
   local row=P.StableDropTarget()
   if row then
    if drag.housed then local ok,message=L.Remove(drag.id);if not ok then finish(ok,message);return end end
    finish(P.MoveStablePet(drag.id,row.stableSlot))
   elseif drag.housed and w.collection:IsMouseOver()then finish(L.Remove(drag.id))end
  elseif drag.housed and w.collection:IsMouseOver()then finish(L.Remove(drag.id))end
 end
 box.ghost=CreateFrame('Frame',nil,UIParent);box.ghost:SetSize(38,38);box.ghost:SetFrameStrata('TOOLTIP');box.ghost:EnableMouse(false)
 box.ghost.art=box.ghost:CreateTexture(nil,'OVERLAY');box.ghost.art:SetAllPoints();box.ghost:Hide()
 local function bindDrag(row,housed)
  row:RegisterForDrag('LeftButton')
  row:SetScript('OnDragStart',function(self)
   if P.state.battle or P.state.trade then return end
   local rows,_,positions=P.GetStableLayout();local pet=housed and L.Pet(self.petID)or rows[positions[self.petID]]
   if not pet then return end
   if not housed then self.cfStableDragClick=true end
   local source=positions[pet.id]
   if housed then for index,slot in pairs(L.State().slots)do if slot.petID==pet.id then source=index;break end end end
   box.drag={id=pet.id,housed=housed,state=P.state,assetID=pet.assetID,source=source};P.ShowPetPortrait(box.ghost.art,pet);box.ghost:Show();GameTooltip:Hide()
  end)
  row:SetScript('OnDragStop',function()endDrag()end)
 end
 for index=1,3 do
  local row=CreateFrame('Button',nil,box,'BackdropTemplate');box.rows[index]=row
  row:SetPoint('TOPLEFT',8+(index-1)*158,-22);row:SetSize(156,79)
  row:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});row:SetBackdropColor(.025,.025,.035,1)
  row.portrait=row:CreateTexture(nil,'ARTWORK');row.portrait:SetSize(27,27);row.portrait:SetPoint('TOPLEFT',4,-4)
  row.name=S.Text(row,'',35,-4,117,'GameFontNormalSmall');row.name:SetMaxLines(1)
  row.status=S.Text(row,'',35,-21,117,'GameFontHighlightSmall');row.status:SetMaxLines(1)
  row.level=S.Text(row,'',3,-32,42,'GameFontNormalSmall');row.level:SetHeight(10);row.level:SetJustifyH('CENTER')
  local function meter(y,r,g,b)
   local bar=CreateFrame('StatusBar',nil,row);bar:SetPoint('TOPLEFT',4,y);bar:SetSize(148,12)
   bar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');bar:SetStatusBarColor(r,g,b);bar:SetMinMaxValues(0,100)
   local bg=bar:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.05,.05,.06,1)
   bar.text=bar:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');bar.text:SetAllPoints();bar.text:SetTextColor(1,1,1);bar.text:SetShadowColor(0,0,0,1);bar.text:SetShadowOffset(1,-1)
   return bar
  end
  row.energy=meter(-43,1,.82,.05);row.xp=meter(-57,.65,.25,1)
  row.bar=CreateFrame('StatusBar',nil,row);row.bar:SetPoint('BOTTOMLEFT',4,4);row.bar:SetSize(148,4);row.bar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');row.bar:SetStatusBarColor(.2,.7,1);row.bar:SetMinMaxValues(0,1)
  row:RegisterForClicks('LeftButtonUp','RightButtonUp')
  row:SetScript('OnClick',function(self,button)
   if rawget(box,'drag')then endDrag(index);return end
   if self.petID then if button=='RightButton'then finish(L.Remove(self.petID))else L.CampMenu(self)end
   elseif button=='LeftButton'and P.viewID then finish(L.Assign(P.viewID,index))end
  end)
  row:SetScript('OnReceiveDrag',function()endDrag(index)end)
  row:SetScript('OnEnter',function(self)
   GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.pet and P.PetName(self.pet)or 'Housing slot '..index)
   GameTooltip:AddLine(self.pet and (L.CampProgress(L.State().slots[index],self.pet,L.State())..'\nClick for housing options. Right-click or drag to the stable to return.\nHoused pets cannot battle.')or 'Drag a stable pet here, or select a pet and click this slot.',1,1,1,true);GameTooltip:Show()
  end)
  row:SetScript('OnLeave',function()GameTooltip:Hide()end);bindDrag(row,true)
 end
 for _,row in ipairs(w.collection.rows)do
  bindDrag(row,false)
  local receive=row:GetScript('OnReceiveDrag')
  row:SetScript('OnReceiveDrag',function(self,...)
   if rawget(box,'drag')then
    -- ReceiveDrag identifies the destination even without a cursor hit-test.
    if P.MoveStablePet then
     local drag=box.drag;box.drag=nil;box.ghost:Hide()
     if not validDrag(drag)then finish(false,'The pet moved. Drag it again.');return end
     if drag.housed then local ok,message=L.Remove(drag.id);if not ok then finish(ok,message);return end end
     finish(P.MoveStablePet(drag.id,self.stableSlot))
    else endDrag()end
   elseif receive then receive(self,...)end
  end)
 end
 box:SetScript('OnHide',function()box.drag=nil;box.ghost:Hide()end)
 local elapsed=0
 box:SetScript('OnUpdate',function(_,dt)
  if rawget(box,'drag')then
   local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale();box.ghost:ClearAllPoints();box.ghost:SetPoint('CENTER',UIParent,'BOTTOMLEFT',x/scale,y/scale)
   if not IsMouseButtonDown('LeftButton')then endDrag()end
  end
  elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;L.RefreshCamp()end
 end)
end
local build=P.BuildUI
function P.BuildUI(...)local value=build(...);L.BuildCamp();return value end
local render=P.Render
function P.Render(...)local value=render(...);L.RefreshCamp();return value end

-- Housing has its own energy/rest cycle; it must not trigger the travel-pet alarm.
local updateNeeds=P.UpdateNeeds
function P.UpdateNeeds(frame,...)
 local pet=frame.needsPet
 if pet and L.IsHoused(pet.id)then
  frame.needs.alert:Hide();frame.needs.hungry:Hide()
  for _,z in ipairs(frame.needs.sleep)do z:Hide()end
  return
 end
 return updateNeeds(frame,...)
end
