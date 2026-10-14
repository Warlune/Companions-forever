local _,F=...
local P=F.Pets
-- Positions are presentation metadata, separate from ownership/history wires.
-- Asset IDs survive account merges that renumber local item IDs.
local function key(item)
  return (item.crate and "C:" or "G:")..(item.assetID or tostring(item.id))
end
P.BagLayoutKey=key
local function validSlot(slot)return type(slot)=="number" and slot==math.floor(slot) and slot>=1 and slot<=3040 end
function P.GetBagLayout()
  local s=P.state;local owners=P.GearOwners();local items,lookup={},{}
  for i=#s.crates,1,-1 do items[#items+1]=s.crates[i]end
  for i=#s.gear,1,-1 do local item=s.gear[i];if not owners[item.id]then items[#items+1]=item end end
  for _,item in ipairs(items)do lookup[key(item)]=item;lookup[(item.crate and "C:" or "G:")..item.id]=item end
  local saved=type(s.bagLayout)=="table" and s.bagLayout or {}
  local layout,rows,positions,seen,partial={},{},{},{},{}
  local function limit(item)return P.StackLimit and P.StackLimit(item) or 1 end
  local function add(item,slot)
    layout[slot]=layout[slot] or {};layout[slot][#layout[slot]+1]=key(item)
    rows[slot]=rows[slot] or item;positions[item.id]=slot;seen[item.id]=true
  end
  for slot=1,3040 do
    local entries=saved[slot]
    -- Most saved bags have only a handful of occupied slots. Do not allocate
    -- thousands of empty compatibility tables on every count or UI refresh.
    if entries~=nil and (slot>P.maxBagSlots or P.BagSlotUnlocked(slot))then
      if type(entries)~="table"then entries={entries}end
      for i=1,math.min(30,#entries)do local item=lookup[entries[i]];local first=rows[slot]
        if item and not seen[item.id] and (not first or (limit(first)>1 and item.crate==first.crate and #layout[slot]<limit(first)))then add(item,slot)end
      end
      local first=rows[slot]
      if first and limit(first)>1 and #layout[slot]<limit(first)then
        partial[first.crate]=partial[first.crate] or {};table.insert(partial[first.crate],slot)
      end
    end
  end
  local free=1
  for _,item in ipairs(items)do if not seen[item.id]then
    local target
    if limit(item)>1 then
      for _,slot in ipairs(partial[item.crate] or {})do if #layout[slot]<30 then target=slot;break end end
    end
    if not target then
      while free<=3040 and (layout[free] or (free<=P.maxBagSlots and not P.BagSlotUnlocked(free)))do free=free+1 end
      target=free
      if limit(item)>1 then partial[item.crate]=partial[item.crate] or {};table.insert(partial[item.crate],target)end
    end
    if target<=3040 then add(item,target)end
  end end
  local highest=P.maxBagSlots;for slot in pairs(layout)do highest=math.max(highest,slot)end
  s.bagLayout=layout
  return rows,math.ceil(highest/P.maxBagSlots)-1,positions
end
function P.MoveBagItem(id,slot)
  if P.state.battle then return false,"Finish the battle before moving equipment."end
  local rows,pages,positions=P.GetBagLayout();local from=positions[id]
  if not from then return false,"That item is no longer in your bag."end
  if not validSlot(slot) or (slot<=P.maxBagSlots and not P.BagSlotUnlocked(slot)) or slot>(pages+1)*P.maxBagSlots then return false,"Choose an unlocked bag slot."end
  local layout=P.state.bagLayout
  if from==slot then return true end
  local source,target=rows[from],rows[slot]
  if target and P.StackLimit and P.StackLimit(source)>1 and source.crate==target.crate and #layout[slot]<30 then
    while #layout[slot]<30 and #layout[from]>0 do table.insert(layout[slot],table.remove(layout[from],1))end
    if #layout[from]==0 then layout[from]=nil end
  else layout[from],layout[slot]=layout[slot],layout[from]end
  return true
end
local equip=P.EquipGear
function P.EquipGear(id)
  local _,_,positions=P.GetBagLayout();local source=positions[id]
  local item=P.GearItem(id);local pet=P.Active()
  local previous=item and pet and pet.gear and P.GearItem(pet.gear[P.gearTypes[item.kind].slot])
  local ok,message=equip(id)
  if ok then
    if source then P.state.bagLayout[source]=previous and previous.id~=id and key(previous) or nil end
    P.GetBagLayout()
  end
  return ok,message
end
function P.DropEquipmentItem(drag,bagSlot,equipSlot)
  local item=drag and P.BagItem(drag.id);local pet=P.Active()
  if not item or drag.state~=P.state or drag.key~=key(item) or drag.petID~=(pet and pet.id)
    or drag.owner~=(P.GearOwner(item.id) and P.GearOwner(item.id).id)then
    return false,"The item or companion changed. Drag it again."
  end
  if P.state.battle then return false,"Finish the battle before changing equipment."end
  if equipSlot then
    if item.crate or P.gearTypes[item.kind].slot~=equipSlot then return false,"That item does not fit this equipment slot."end
    if drag.owner then return true end -- Dropping back on itself is not unequip.
    return P.EquipGear(item.id)
  end
  local rows,pages=P.GetBagLayout()
  if not validSlot(bagSlot) or (bagSlot<=P.maxBagSlots and not P.BagSlotUnlocked(bagSlot)) or bagSlot>(pages+1)*P.maxBagSlots then return false,"Choose an unlocked bag slot."end
  if not drag.owner then return P.MoveBagItem(item.id,bagSlot)end
  local target=rows[bagSlot]
  if target then
    if target.crate or P.gearTypes[target.kind].slot~=P.gearTypes[item.kind].slot then return false,"Drop onto an empty bag slot or matching equipment to swap."end
    return P.EquipGear(target.id)
  end
  local ok,message=P.EquipGear(item.id)
  if not ok then return ok,message end
  return P.MoveBagItem(item.id,bagSlot)
end
function P.CancelEquipmentDrag()
  P.equipmentDrag=nil
  if P.equipmentDragIcon then P.equipmentDragIcon:Hide()end
end
local function finish(frame)
  local drag=P.equipmentDrag;if not drag then return end
  P.CancelEquipmentDrag()
  if frame then
    frame.cfDragClick=true
    local ok,message=P.DropEquipmentItem(drag,rawget(frame,"bagSlot"),rawget(frame,"equipSlot"))
    if not ok then P.notice=message end
  end
  P.Render()
end
local function readableNumber(value)
  return not (issecretvalue and issecretvalue(value)) and (not canaccessvalue or canaccessvalue(value)) and type(value)=="number"
end
function P.EquipmentDropTarget()
  local f=P.equipment;if not f or not f:IsShown() or P.mode~="equipment"then return nil,true end
  local x,y;if GetCursorPosition then x,y=GetCursorPosition()end
  local geometry=false
  if readableNumber(x) and readableNumber(y)then
    for _,frames in ipairs({f.slots,f.rows})do for _,frame in ipairs(frames)do if frame:IsShown()then
      local left,right,bottom,top=frame:GetLeft(),frame:GetRight(),frame:GetBottom(),frame:GetTop()
      local scale=frame:GetEffectiveScale()
      if readableNumber(left) and readableNumber(right) and readableNumber(bottom) and readableNumber(top) and readableNumber(scale) and scale>0 then
        geometry=true
        local px,py=x/scale,y/scale
        if px>=left and px<=right and py>=bottom and py<=top then return frame,true end
      end
    end end end
  end
  -- Native mouse focus can remain captured by the drag source. Prefer the
  -- physical cursor and each target's effective scale over focus-based hover.
  if geometry then return nil,true end
  if MouseIsOver then
    for _,frames in ipairs({f.slots,f.rows})do for _,frame in ipairs(frames)do
      if frame:IsShown() and MouseIsOver(frame)then return frame,true end
    end end
  end
  return nil,false
end
local function stop(fallback)
  if not P.equipmentDrag then return end
  local target,measured=P.EquipmentDropTarget()
  finish(target or (not measured and fallback or nil))
end
function P.BeginEquipmentDrag(frame,id)
  local item=P.BagItem(id);local pet=P.Active()
  if not item or P.state.battle then return end
  local owner=P.GearOwner(id)
  if owner and owner~=pet then return end
  P.GetBagLayout()
  P.equipmentDrag={id=id,key=key(item),owner=owner and owner.id,petID=pet and pet.id,state=P.state}
  frame.cfDragClick=true;GameTooltip:Hide()
  if not P.equipmentDragIcon then
    local icon=CreateFrame("Frame","CompanionsForeverEquipmentDragIcon",UIParent);P.equipmentDragIcon=icon
    _G.CompanionsForeverEquipmentDragIcon=icon;UISpecialFrames[#UISpecialFrames+1]="CompanionsForeverEquipmentDragIcon"
    icon:SetSize(38,38);icon:SetFrameStrata("TOOLTIP");icon:EnableMouse(false)
    icon.art=icon:CreateTexture(nil,"OVERLAY");icon.art:SetAllPoints()
    icon:SetScript("OnHide",function()P.equipmentDrag=nil end)
    icon:SetScript("OnUpdate",function(self)
      local drag=P.equipmentDrag;local active=P.Active()
      if not drag or drag.state~=P.state or P.state.battle or not P.equipment:IsShown() or P.mode~="equipment"
        or drag.petID~=(active and active.id) or not P.BagItem(drag.id)then P.CancelEquipmentDrag();return end
      -- This is an addon-owned icon, not a native inventory cursor payload.
      -- Some clients do not dispatch OnReceiveDrag/OnDragStop for it.
      if IsMouseButtonDown and not IsMouseButtonDown("LeftButton")then stop();return end
      if GetCursorPosition then
        local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
        self:ClearAllPoints();self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale,y/scale)
      end
    end)
  end
  P.equipmentDragIcon.art:SetTexture("Interface\\Icons\\"..P.BagDefinition(item).icon)
  P.equipmentDragIcon:Show()
end
function P.EquipmentDragClick(frame,button)
  if P.equipmentDrag then
    if button=="RightButton"then P.CancelEquipmentDrag();P.Render()else stop()end
    return true
  end
  if rawget(frame,"cfDragClick")then frame.cfDragClick=false;return true end
end
local build=P.BuildEquipment
function P.BuildEquipment(...)
  local result=build(...);local f=P.equipment
  for _,frames in ipairs({f.slots,f.rows})do for _,frame in ipairs(frames)do
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown",function(self)self.cfDragClick=false end)
    frame:SetScript("OnDragStart",function(self)
      local id=rawget(self,"itemID")
      if rawget(self,"equipSlot")then local pet=P.Active();id=pet and pet.gear and pet.gear[self.equipSlot]end
      P.BeginEquipmentDrag(self,id)
    end)
    frame:SetScript("OnReceiveDrag",function(self)stop(self)end)
    frame:SetScript("OnDragStop",function()stop()end)
    frame:SetScript("OnMouseUp",function(_,button)if button=="LeftButton"then stop()end end)
  end end
  f:HookScript("OnHide",P.CancelEquipmentDrag)
  return result
end
