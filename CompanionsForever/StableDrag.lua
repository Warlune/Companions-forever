local _,F=...
local P=F.Pets
-- Presentation only: never reorder the pets array or change active/team IDs.
-- Asset keys survive the local-ID reassignment performed by account merges.
local function key(pet)return pet.assetID or ("pet:"..pet.id)end
local function validSlot(slot)return type(slot)=="number" and slot==math.floor(slot) and slot>=1 and slot<=576 end
function P.GetStableLayout()
  local s=P.state;local saved=type(s.stableLayout)=="table" and s.stableLayout or {}
  local lookup,seen,rows,layout,positions={},{},{},{},{}
  for _,pet in ipairs(s.pets)do if not P.IsHoused(pet)then lookup[key(pet)]=pet end end
  local highest=0
  for slot=1,576 do
    local id=saved[slot];local pet=type(id)=="string" and lookup[id]
    if pet and not seen[pet.id]then
      rows[slot]=pet;layout[slot]=key(pet);seen[pet.id]=true;positions[pet.id]=slot;highest=slot
    end
  end
  local slot=1
  for _,pet in ipairs(s.pets)do if not P.IsHoused(pet) and not seen[pet.id]then
    while rows[slot]do slot=slot+1 end
    rows[slot]=pet;layout[slot]=key(pet);positions[pet.id]=slot;highest=math.max(highest,slot)
  end end
  s.stableLayout=layout
  return rows,math.max(1,math.ceil(highest/P.stableCapacity)),positions
end
function P.MoveStablePet(id,slot)
  if P.state.battle or P.state.trade then return false,"Finish your battle or trade before arranging pets."end
  local _,pages,positions=P.GetStableLayout();local source=positions[id]
  if not source or not validSlot(slot) or slot>pages*P.stableCapacity then return false,"Choose a visible stable slot."end
  local layout=P.state.stableLayout
  layout[source],layout[slot]=layout[slot],layout[source]
  return true
end
function P.CancelStableDrag()
  P.stableDrag=nil
  if P.stableDragIcon then P.stableDragIcon:Hide()end
end
local function number(v)
  return not (issecretvalue and issecretvalue(v)) and (not canaccessvalue or canaccessvalue(v)) and type(v)=="number"
end
function P.StableDropTarget()
  local c=P.window and P.window.collection
  if not c or not c:IsShown() or P.mode~="collection"then return nil,true end
  local x,y;if GetCursorPosition then x,y=GetCursorPosition()end
  local measured=false
  if number(x) and number(y)then
    for _,row in ipairs(c.rows)do if row:IsShown()then
      local l,r,b,t,scale=row:GetLeft(),row:GetRight(),row:GetBottom(),row:GetTop(),row:GetEffectiveScale()
      if number(l) and number(r) and number(b) and number(t) and number(scale) and scale>0 then
        measured=true
        if x/scale>=l and x/scale<=r and y/scale>=b and y/scale<=t then return row,true end
      end
    end end
  end
  if measured then return nil,true end
  if MouseIsOver then for _,row in ipairs(c.rows)do if row:IsShown() and MouseIsOver(row)then return row,true end end end
  return nil,false
end
function P.DropStablePet(drag,slot)
  if not drag or drag.state~=P.state then return false,"The stable changed. Drag the pet again."end
  local rows,_,positions=P.GetStableLayout();local source=positions[drag.id];local pet=source and rows[source]
  if not pet or key(pet)~=drag.key or source~=drag.source then return false,"The pet moved. Drag it again."end
  return P.MoveStablePet(drag.id,slot)
end
local function stop(fallback)
  local drag=P.stableDrag;if not drag then return end
  local row,measured=P.StableDropTarget();row=row or (not measured and fallback or nil)
  P.CancelStableDrag()
  if row then
    row.cfStableDragClick=true
    local ok,message=P.DropStablePet(drag,rawget(row,"stableSlot"));if not ok then P.notice=message end
  end
  P.Render()
end
function P.BeginStableDrag(row)
  if P.mode~="collection" or P.state.battle or P.state.trade then return end
  local rows,_,positions=P.GetStableLayout();local id=rawget(row,"petID");local source=positions[id];local pet=source and rows[source]
  if not pet then return end
  P.stableDrag={id=id,key=key(pet),source=source,state=P.state};row.cfStableDragClick=true;GameTooltip:Hide()
  if not P.stableDragIcon then
    local icon=CreateFrame("Frame","CompanionsForeverStableDragIcon",UIParent);P.stableDragIcon=icon
    _G.CompanionsForeverStableDragIcon=icon;UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverStableDragIcon"
    icon:SetSize(38,38);icon:SetFrameStrata("TOOLTIP");icon:EnableMouse(false)
    icon.art=icon:CreateTexture(nil,"OVERLAY");icon.art:SetAllPoints()
    icon:SetScript("OnHide",function()P.stableDrag=nil end)
    icon:SetScript("OnUpdate",function(self)
      local drag=P.stableDrag
      if not drag or drag.state~=P.state or P.state.battle or P.state.trade or P.mode~="collection"
        or not P.window:IsShown() or not P.window.collection:IsShown()then P.CancelStableDrag();return end
      if IsMouseButtonDown and not IsMouseButtonDown("LeftButton")then stop();return end
      if GetCursorPosition then
        local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
        self:ClearAllPoints();self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
      end
    end)
  end
  local species=F.PetData.species[pet.species]
  P.stableDragIcon.art:SetTexture("Interface\\Icons\\"..(species and species.icon or "INV_Box_PetCarrier_01"))
  P.stableDragIcon:Show()
end
local build=P.BuildUI
function P.BuildUI(...)
  local result=build(...);local c=P.window and P.window.collection
  if not c or rawget(c,"cfStableDragReady")then return result end
  c.cfStableDragReady=true
  for _,row in ipairs(c.rows)do
    local click=row:GetScript("OnClick")
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnMouseDown",function(self)self.cfStableDragClick=false end)
    row:SetScript("OnDragStart",P.BeginStableDrag)
    row:SetScript("OnReceiveDrag",stop)
    row:SetScript("OnDragStop",function()stop()end)
    row:SetScript("OnMouseUp",function(_,button)if button=="LeftButton"then stop()end end)
    row:SetScript("OnClick",function(self,...)
      if P.stableDrag then stop(self);return end
      if rawget(self,"cfStableDragClick")then self.cfStableDragClick=false;return end
      if click then click(self,...)end
    end)
  end
  c:EnableMouseWheel(true)
  c:SetScript("OnMouseWheel",function(_,delta)
    local _,pages=P.GetStableLayout();P.page=math.max(1,math.min(pages,(P.page or 1)+(delta>0 and -1 or 1)));P.Render()
  end)
  c:HookScript("OnHide",P.CancelStableDrag)
  return result
end
