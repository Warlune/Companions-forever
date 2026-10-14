local _,F=...
local P,S,D=F.Pets,F.Style,F.PetData
local function text(parent,value,x,y,w,h,color)
  local t=S.Text(parent,value,x,y,w,"GameFontHighlightSmall",color or S.gold);t:SetHeight(h);return t
end
local function act(fn)
  local ok,message=fn();if not ok then P.notice=message end;P.Render()
end
local function tooltip(frame,fn)
  frame:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(fn());GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
-- Recycle visible cards instead of creating a hundred animated model scenes.
local function scrollControls(f,x,y,height,render)
  local parent=rawget(f,"body") or f
  f.offset=0;f.maxOffset=0
  f.scroll=CreateFrame("Slider",nil,parent,"BackdropTemplate");f.scroll:SetPoint("TOPLEFT",x,y-28);f.scroll:SetSize(14,height-56)
  f.scroll:SetOrientation("VERTICAL");f.scroll:SetMinMaxValues(0,0);f.scroll:SetValueStep(1);f.scroll:SetObeyStepOnDrag(true)
  f.scroll:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  f.scroll:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});f.scroll:SetBackdropColor(0.15,0.15,0.17,1)
  f.scroll:SetScript("OnValueChanged",function(_,value)
    local offset=math.floor(value+0.5)
    if f.offset~=offset then f.offset=offset;f.portraitQuiet=0.12;render()end
  end)
  local function move(delta)local offset=math.max(0,math.min(f.maxOffset,f.offset+delta));if offset~=f.offset then f.offset=offset;f.portraitQuiet=0.12;render()end end
  f.up=S.Button(parent,"^",x-6,y,26,function()move(-1)end)
  f.down=S.Button(parent,"v",x-6,y-height+26,26,function()move(1)end)
  parent:EnableMouseWheel(true);parent:SetScript("OnMouseWheel",function(_,delta)move(-delta)end)
end
local function updateScroll(f,count,columns,visible)
  f.maxOffset=math.max(0,math.ceil(count/columns)-visible)
  f.offset=math.max(0,math.min(f.offset,f.maxOffset))
  f.scroll:SetMinMaxValues(0,f.maxOffset);f.scroll:SetValue(f.offset)
  f.up:SetEnabled(f.offset>0);f.down:SetEnabled(f.offset<f.maxOffset)
end
-- Native creature portraits can synchronously load/render model assets. Never
-- run that work in a wheel/slider callback, or in a burst after a long frame.
local function journalPortrait(f,art,pet)
  if P.StyleSparklyPortrait then P.StyleSparklyPortrait(art,pet)end
  if P.portraits and P.portraits[pet.species]then f.portraitJobs[art]=nil;P.ShowPetPortrait(art,pet);return end
  local model=P.ModelFor(pet)
  local jobs=f.portraitJobs
  if rawget(art,"cfPortraitDisplay")==model.display and rawget(art,"cfPortraitRenderer")==SetPortraitTextureFromCreatureDisplayID then
    jobs[art]=nil;P.ShowPetPortrait(art,pet);return
  end
  local prior=jobs[art]
  if not prior or prior.display~=model.display then
    art.cfPortraitDisplay=nil;art.cfPortraitRenderer=nil
    art:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");art:SetTexCoord(0,1,0,1)
    art:SetDesaturated(pet.deadAt~=nil);art:Show()
  end
  jobs[art]={display=model.display,pet=pet}
  f.portraitLoader:Show()
end
local function loadJournalPortraits(f,dt)
  if not f:IsShown() or not f.body:IsShown() or (f.subtab and f.subtab~="collections")then return end
  if not next(f.portraitJobs)then f.portraitLoader:Hide();return end
  if (f.portraitQuiet or 0)>0 then f.portraitQuiet=math.max(0,f.portraitQuiet-dt);return end
  f.portraitElapsed=(f.portraitElapsed or 0)+dt
  if f.portraitElapsed<0.04 then return end
  f.portraitElapsed=0 -- At most one native render per frame, capped at 25/second.
  local art=f.art
  if not f.portraitJobs[art]then
    art=nil
    for _,row in ipairs(f.rows)do if row:IsShown() and f.portraitJobs[row.art]then art=row.art;break end end
  end
  if art then
    local job=f.portraitJobs[art];f.portraitJobs[art]=nil
    P.ShowPetPortrait(art,job.pet)
  else
    -- Discard hidden/recycled work; never retain a catalogue of model textures.
    f.portraitJobs={}
  end
  if not next(f.portraitJobs)then f.portraitLoader:Hide()end
end
function P.BuildJournal()
  local f=P.NewPage();P.journal=f;f.filter=1;f.query="";f.selected=1;f.rows={}
  f.body=CreateFrame("Frame",nil,f);f.body:SetPoint("TOPLEFT",0,-42);f.body:SetSize(960,508)
  f.portraitJobs={};f.portraitQuiet=0;f.portraitElapsed=0
  f.portraitLoader=CreateFrame("Frame",nil,f.body)
  f.portraitLoader:SetScript("OnUpdate",function(_,dt)loadJournalPortraits(f,dt)end);f.portraitLoader:Hide()
  f.count=text(f.body,"",0,0,540,28)
  f.filterButton=S.Dropdown(f.body,"",0,-38,152,{{1,"All companions"},{2,"Collected"},{3,"Undiscovered"},{4,"Farmable"},{5,"Crate only"}},function()return f.filter end,function(value)f.filter=value;f.offset=0;P.RenderJournal()end)
  text(f.body,"Search",172,-38,58,28,S.muted)
  f.search=CreateFrame("EditBox",nil,f.body,"InputBoxTemplate");f.search:SetPoint("TOPLEFT",235,-38);f.search:SetSize(360,28)
  f.search:SetAutoFocus(false);f.search:SetMaxLetters(60)
  f.search:SetScript("OnTextChanged",function(self)f.query=self:GetText():lower();f.offset=0;f.portraitQuiet=0.12;P.RenderJournal()end)
  f.search:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
  f.search:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
  for i=1,24 do
    local row=CreateFrame("Button",nil,f.body,"BackdropTemplate");f.rows[i]=row
    row:SetPoint("TOPLEFT",((i-1)%6)*101,-82-math.floor((i-1)/6)*88);row:SetSize(94,84)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    row.art=row:CreateTexture(nil,"ARTWORK");row.art:SetSize(48,48);row.art:SetPoint("TOP",0,-2)
    row.rarity=text(row,"",3,-51,88,12);row.rarity:SetJustifyH("CENTER")
    row.label=text(row,"",3,-64,88,18);row.label:SetJustifyH("CENTER");row.label:SetMaxLines(1)
    row.mark=text(row,"",47,-2,43,18);row.mark:SetJustifyH("RIGHT")
    row:SetScript("OnClick",function(self)f.selected=self.species;P.MarkSpeciesSeen(self.species);P.RenderJournal()end)
    tooltip(row,function()return P.species[row.species].."\nSpecialty: "..P.Specialty({species=row.species}).."\n"..P.SourceText(row.species)end)
  end
  scrollControls(f,619,-82,358,P.RenderJournal)
  f.empty=text(f.body,"No companions match your search.",30,-238,550,50,S.muted);f.empty:SetJustifyH("CENTER")
  f.preview=S.Panel(f.body,654,0,306,444)
  f.petName=text(f.preview,"",16,-16,274,44);f.petName:SetJustifyH("CENTER")
  f.art=f.preview:CreateTexture(nil,"ARTWORK");f.art:SetPoint("TOP",0,-58);f.art:SetSize(172,136)
  f.status=text(f.preview,"",16,-198,274,26);f.status:SetJustifyH("CENTER")
  f.source=text(f.preview,"",20,-232,266,154,{0.88,0.88,0.86})
  f.record=text(f.preview,"",20,-394,266,42,S.muted)
  f.pending=text(f.body,"",0,-462,960,38,S.muted)
  if P.BuildJournalExtras then P.BuildJournalExtras(f)end
end
function P.OpenJournal()P.OpenPage("journal")end
-- The roster is static for this client build. Discovery changes invalidate only
-- the filtered view; scrolling never sorts the 2,000+ compatibility catalogue.
local function journalRows(f,s)
  local catalog=rawget(f,"catalog")
  if not catalog or catalog.species~=P.species or catalog.size~=#P.species or catalog.allowed~=D.allowedSpecies then
    catalog={species=P.species,size=#P.species,allowed=D.allowedSpecies,entries={}}
    for id,name in ipairs(P.species)do if not P.IsAllowedSpecies or P.IsAllowedSpecies(id)then
      catalog.entries[#catalog.entries+1]={id=id,name=name:lower(),alias=(D.nameAliases[id] or ""):lower()}
    end end
    table.sort(catalog.entries,function(a,b)if a.name==b.name then return a.id<b.id end;return a.name<b.name end)
    f.catalog=catalog;f.collectionView=nil
  end
  local view=rawget(f,"collectionView")
  if view and view.collection==s.collection and view.revision==P.collectionRevision and view.query==f.query and view.filter==f.filter then
    return view.rows,view.count,view.secrets
  end
  view={collection=s.collection,revision=P.collectionRevision,query=f.query,filter=f.filter,rows={},count=0,secrets=0}
  for _,entry in ipairs(catalog.entries)do
    local id=entry.id;local hidden=D.hiddenSpecies and D.hiddenSpecies[id];local owned=s.collection[id]~=nil
    if not hidden or owned then
      if owned then if hidden then view.secrets=view.secrets+1 else view.count=view.count+1 end end
      local farm=D.farmSources[id]~=nil
      local include=f.filter==1 or f.filter==2 and owned or f.filter==3 and not owned or f.filter==4 and farm or f.filter==5 and not farm and not hidden
      if include then
        local match=f.query=="" or entry.name:find(f.query,1,true) or entry.alias:find(f.query,1,true)
        if not match then entry.source=entry.source or P.SourceText(id):lower();match=entry.source:find(f.query,1,true)end
        if match then view.rows[#view.rows+1]=id end
      end
    end
  end
  f.collectionView=view;return view.rows,view.count,view.secrets
end
local function recycleJournalRows(f,rows)
  local existing,used,ordered={},{},{}
  for _,row in ipairs(f.rows)do local id=rawget(row,"species");if id then existing[id]=row end end
  for i=1,24 do local id=rows[f.offset*6+i];local row=id and existing[id];if row then ordered[i]=row;used[row]=true end end
  local free={};for _,row in ipairs(f.rows)do if not used[row]then free[#free+1]=row end end
  for i=1,24 do
    local row=ordered[i] or table.remove(free);ordered[i]=row
    if rawget(row,"cfGridSlot")~=i then
      row:ClearAllPoints();row:SetPoint("TOPLEFT",((i-1)%6)*101,-82-math.floor((i-1)/6)*88);row.cfGridSlot=i
    end
  end
  f.rows=ordered
end
function P.RenderJournal()
  local f=P.journal;local s=P.state;if not f or not f:IsShown() or not s then return end
  if P.RenderJournalExtras and P.RenderJournalExtras(f)then return end
  local rows,count,secrets=journalRows(f,s)
  f.filterButton:SetText(({"All companions","Collected","Undiscovered","Farmable","Crate only"})[f.filter])
  f.count:SetText("COLLECTION  |  "..count.." / "..(P.RosterCount and P.RosterCount() or #P.species).." discovered"..(secrets>0 and (" | "..secrets.." secret"..(secrets==1 and "" or "s").." found") or ""))
  if (P.IsAllowedSpecies and not P.IsAllowedSpecies(f.selected)) or (D.hiddenSpecies and D.hiddenSpecies[f.selected] and not s.collection[f.selected])then f.selected=rows[1] or D.rosterPool[1]end
  updateScroll(f,#rows,6,4);f.empty:SetShown(#rows==0)
  recycleJournalRows(f,rows)
  for i,row in ipairs(f.rows)do
    local species=rows[f.offset*6+i];row.species=species;row:SetShown(species~=nil)
    if not species then f.portraitJobs[row.art]=nil end
    if species then
      local e=s.collection[species];journalPortrait(f,row.art,{species=species,deadAt=not e and 1 or nil,sparklyDiscovered=e and e.sparkly})
      row.art:SetAlpha(e and 1 or 0.48);row.label:SetText(P.species[species]);S.TextColor(row.label,e and P.colors[e.rarity] or S.muted)
      row.rarity:SetText(e and P.rarities[e.rarity] or "");S.TextColor(row.rarity,e and P.colors[e.rarity] or S.muted)
      row.mark:SetText(e and (e.isNew and "NEW" or "*") or "")
      if f.selected==species then row:SetBackdropColor(0.18,0.16,0.1,1)else row:SetBackdropColor(0.075,0.085,0.1,1)end
      row:SetBackdropBorderColor(unpack(e and P.colors[e.rarity] or {0.22,0.24,0.28}))
    end
  end
  local species=f.selected;local e=s.collection[species]
  journalPortrait(f,f.art,{species=species,rarity=e and e.rarity or 1,deadAt=not e and 1 or nil,sparklyDiscovered=e and e.sparkly})
  f.petName:SetText(P.species[species]);S.TextColor(f.petName,e and P.colors[e.rarity] or S.muted)
  f.status:SetText(e and ("Highest found: "..P.rarities[e.rarity]..(e.sparkly and " | Sparkly found" or "")) or "Undiscovered")
  S.TextColor(f.status,e and P.colors[e.rarity] or S.muted)
  f.preview:SetBackdropBorderColor(unpack(e and P.colors[e.rarity] or S.muted))
  f.source:SetText(P.SourceText(species))
  f.record:SetText(e and ("Found "..e.count.." times | "..e.source) or "Discoveries stay unlocked, even after retirement.")
  f.pending:SetText(#s.finds>0 and ("NEW: "..#s.finds.." pets waiting in Mail.") or "Scroll to explore. Select a portrait to see where the pet drops.")
end
function P.GearComparison(item,pet)
  if not item or item.crate or not pet then return end
  local d=P.gearTypes[item.kind];if not d then return end
  local equipped=pet.gear and P.GearItem(pet.gear[d.slot])
  if equipped and equipped.id==item.id then return end
  local old=equipped and P.gearTypes[equipped.kind] or {};local delta={}
  for _,key in ipairs({"hp","attack","armor","speed"})do
    delta[key]=(d[key] or 0)*P.GearMultiplier(item)-(old[key] or 0)*(equipped and P.GearMultiplier(equipped) or 0)
  end
  return equipped,delta
end
local equipmentTooltipFonts={}
local equipmentTooltipBackings={}
local function hideComparison()
  if P.equipmentCompareTooltip then P.equipmentCompareTooltip:Hide()end
  for label,font in pairs(equipmentTooltipFonts)do label:SetFont(unpack(font))end
  equipmentTooltipFonts={}
  for _,bg in pairs(equipmentTooltipBackings)do bg:Hide()end
end
GameTooltip:HookScript("OnHide",hideComparison)
GameTooltip:HookScript("OnTooltipCleared",hideComparison)
local function comparisonTooltip()
  if not P.equipmentCompareTooltip then
    local tip=CreateFrame("GameTooltip","CompanionsForeverEquipmentCompareTooltip",UIParent,"GameTooltipTemplate")
    tip:SetFrameStrata("TOOLTIP");tip:SetClampedToScreen(true);tip:EnableMouse(false)
    P.equipmentCompareTooltip=tip
  end
  return P.equipmentCompareTooltip
end
local function readableEquipmentTooltip(tip)
  local bg=equipmentTooltipBackings[tip]
  if not bg then
    bg=tip:CreateTexture(nil,"BACKGROUND",nil,-8)
    bg:SetPoint("TOPLEFT",3,-3);bg:SetPoint("BOTTOMRIGHT",-3,3)
    bg:SetColorTexture(.025,.025,.035,1);equipmentTooltipBackings[tip]=bg
  end
  bg:Show()
  local name=tip:GetName();local count=tip:NumLines() or 0
  if name then for i=1,count do for _,side in ipairs({"Left","Right"})do
    local label=_G[name.."Text"..side..i]
    if label then
      local path,size,flags=label:GetFont()
      if path and size then
        if not equipmentTooltipFonts[label] then equipmentTooltipFonts[label]={path,size,flags}end
        label:SetFont(path,math.max(size,S.MinimumTextSize()),flags)
      end
    end
  end end end
end
local function placeComparison(tip)
  tip:ClearAllPoints()
  local scale=GameTooltip:GetEffectiveScale() or 1
  local ownScale=tip:GetEffectiveScale() or 1
  local left,right=GameTooltip:GetLeft(),GameTooltip:GetRight()
  local width=tip:GetWidth()*ownScale
  local screen=UIParent:GetWidth()*(UIParent:GetEffectiveScale() or 1)
  -- Prefer the equipped item to the left, but keep both panels on screen.
  if left and left*scale>=width+8 then tip:SetPoint("TOPRIGHT",GameTooltip,"TOPLEFT",-8,0)
  elseif right and screen-right*scale>=width+8 then tip:SetPoint("TOPLEFT",GameTooltip,"TOPRIGHT",8,0)
  else
    GameTooltip:ClearAllPoints();GameTooltip:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-12,-90)
    tip:SetPoint("TOPRIGHT",GameTooltip,"TOPLEFT",-8,0)
  end
end
function P.EquipmentTooltip(frame,item,instruction,compare)
  hideComparison()
  GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
  if not item then GameTooltip:SetText("Empty equipment slot");GameTooltip:Show();return end
  local d=P.BagDefinition(item);local owner=P.GearOwner(item.id)
  GameTooltip:SetText((item.crate and "" or P.rarities[item.rarity].." ")..d.name,unpack(S.RarityColor(P.colors[item.rarity])))
  local treat=P.xpTreats and P.xpTreats[item.crate]
  GameTooltip:AddLine(treat and "XP treat" or item.crate and (P.coinPouches[item.crate] and "Coin pouch" or "Companion crate") or P.gearSlotNames[d.slot],1,1,1)
  if P.StackLimit and P.StackLimit(item)>1 then
    local _,_,positions=P.GetBagLayout();local slot=positions[item.id]
    if slot then GameTooltip:AddLine("Stack: "..#P.state.bagLayout[slot].." / 30. Use consumes one.",1,1,1)end
  end
  GameTooltip:AddLine(P.BagDescription(item),S.HighContrast() and 1 or .2,1,S.HighContrast() and 1 or .2,true)
  if owner then GameTooltip:AddLine("Equipped: "..P.species[owner.species],1,0.82,0.3,true)end
  if item.enemyLevel then GameTooltip:AddLine("Dropped by level "..item.enemyLevel.." enemy",0.7,0.7,0.7)end
  if not item.crate then GameTooltip:AddLine("Sell value: "..P.TokenText(P.GearSellPrice(item)),1,0.82,0.3)end
  local comparison
  if compare and not item.crate then
    local pet=P.Active();local equipped,delta=P.GearComparison(item,pet)
    if delta then
      comparison=comparisonTooltip();comparison:SetOwner(frame,"ANCHOR_NONE");comparison:ClearLines()
      comparison:SetText("Equipped",1,.82,.3)
      comparison:AddLine(P.species[pet.species],1,1,1,true)
      if equipped then
        comparison:AddLine(P.rarities[equipped.rarity].." "..P.BagDefinition(equipped).name,unpack(S.RarityColor(P.colors[equipped.rarity])))
        comparison:AddLine(P.gearSlotNames[d.slot],1,1,1)
        comparison:AddLine(P.BagDescription(equipped),1,1,1,true)
        comparison:AddLine("Sell value: "..P.TokenText(P.GearSellPrice(equipped)),1,.82,.3)
      else comparison:AddLine("Empty "..P.gearSlotNames[d.slot].." slot",1,1,1)end
      comparison:AddLine(" ")
      comparison:AddLine("If you equip the hovered item:",1,1,1,true)
      local changed=false
      for _,key in ipairs({"hp","attack","armor","speed"})do local value=delta[key]
        if math.abs(value)>0.0001 then
          changed=true;comparison:AddLine(string.format("%+.1f %s",value,key=="hp" and "health" or key),value>0 and 0.2 or 1,value>0 and 1 or 0.45,0.3)
        end
      end
      if not changed then comparison:AddLine("Same base item stats",1,1,1)end
      comparison:AddLine("Item stats only. Effects and set bonuses may differ.",1,1,1,true)
    end
  end
  if instruction then GameTooltip:AddLine(instruction,0.7,0.7,0.7,true)end
  readableEquipmentTooltip(GameTooltip);GameTooltip:Show()
  if comparison then readableEquipmentTooltip(comparison);comparison:Show();placeComparison(comparison)end
end
function P.BuildEquipment()
  local f=P.NewPage();P.equipment=f;f.filter=1;f.slots={};f.rows={};f.bagPage=0;f.selectedSlot=false;f.selectedItems={}
  f.preview=S.Panel(f,0,0,456,438)
  f.pet=text(f.preview,"",16,-16,424,46);f.pet:SetJustifyH("CENTER")
  f.art=f.preview:CreateTexture(nil,"ARTWORK");f.art:SetPoint("TOP",0,-62);f.art:SetSize(330,218)
  f.background=P.PreviewBackground(f.preview,f.art)
  text(f.preview,"EQUIPMENT BONUSES",20,-280,246,28)
  f.bonuses=text(f.preview,"",20,-314,246,76,{0.88,0.88,0.86})
  S.Button(f.preview,"Choose companion",230,-398,206,function()P.OpenPage("collection")end)
  for i,slot in ipairs(P.gearSlots)do
    local key=slot;local b=CreateFrame("Button",nil,f,"BackdropTemplate");f.slots[i]=b
    b.equipSlot=slot
    b:SetPoint("TOPLEFT",472+(i-1)*98,0);b:SetSize(96,80)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.075,0.085,0.1,1)
    b.title=text(b,P.gearSlotNames[slot],0,-2,96,18);b.title:SetJustifyH("CENTER")
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetSize(32,32);b.art:SetPoint("TOP",0,-20)
    b.rarityRim=b:CreateTexture(nil,"OVERLAY");b.rarityRim:SetTexture("Interface\\Buttons\\UI-Quickslot2");b.rarityRim:SetSize(56,56);b.rarityRim:SetPoint("CENTER",b.art,"CENTER")
    b.label=text(b,"",2,-54,92,24);b.label:SetJustifyH("CENTER");b.label:SetMaxLines(2)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick",function(self,button)
      if P.EquipmentDragClick(self,button)then return end
      local pet=P.Active();local id=pet and pet.gear and pet.gear[key]
      if id then act(function()return P.EquipGear(id)end)end
    end)
    b:SetScript("OnEnter",function(self)
      local pet=P.Active();local item=pet and pet.gear and P.GearItem(pet.gear[key])
      P.EquipmentTooltip(self,item,"Drag matching gear here to equip. Drag to your bag or click to unequip.")
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  local filters={{1,"All bag items"}}
  for i,slot in ipairs(P.gearSlots)do filters[#filters+1]={i+1,P.gearSlotNames[slot]}end
  filters[#filters+1]={7,"Crates & bags"};filters[#filters+1]={8,"XP treats"}
  f.filterButton=S.Dropdown(f,"",472,-508,140,filters,function()return f.filter end,function(value)f.filter=value;f.offset=0;f.selectedItems={};f.selected=nil;P.RenderEquipment()end)
  f.capacity=text(f,"",472,-477,404,24,S.muted)
  f.bag=S.Panel(f,472,-92,488,376)
  f.bag:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
  for i=1,P.maxBagSlots do
    local row=CreateFrame("Button",nil,f.bag,"BackdropTemplate");f.rows[i]=row
    row:SetPoint("TOPLEFT",24+((i-1)%10)*44,-10-math.floor((i-1)/10)*44);row:SetSize(42,42)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    row:SetBackdropColor(0.035,0.035,0.045,1)
    row.art=row:CreateTexture(nil,"ARTWORK");row.art:SetPoint("TOPLEFT",3,-3);row.art:SetSize(36,36)
    -- Draw the lock from native solid textures; Classic clients do not all ship
    -- the same LFG lock artwork.
    row.lockPieces={}
    for _,part in ipairs({{12,5,4,11},{28,5,4,11},{12,5,20,4},{9,14,26,16},{20,18,4,8}})do
      local piece=row:CreateTexture(nil,"ARTWORK",nil,1)
      piece:SetPoint("TOPLEFT",part[1],-part[2]);piece:SetSize(part[3],part[4])
      if #row.lockPieces==4 then piece:SetColorTexture(0.08,0.07,0.05,1)
      else piece:SetColorTexture(0.55,0.47,0.29,1)end
      row.lockPieces[#row.lockPieces+1]=piece;piece:Hide()
    end
    local rim=row:CreateTexture(nil,"OVERLAY");rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    rim:SetSize(70,70);rim:SetPoint("CENTER")
    row.rarityRim=rim
    row.selection=row:CreateTexture(nil,"OVERLAY");row.selection:SetPoint("TOPLEFT",3,-3);row.selection:SetPoint("BOTTOMRIGHT",-3,3);row.selection:SetTexture("Interface\\Buttons\\CheckButtonHilight");row.selection:SetBlendMode("ADD");row.selection:Hide()
    row:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    row.mark=text(row,"",2,-1,42,18);row.mark:SetJustifyH("CENTER")
    row.stackCount=text(row,"",10,-25,28,14,{1,1,1});row.stackCount:SetJustifyH("RIGHT")
    row.stackCount:SetShadowColor(0,0,0,1);row.stackCount:SetShadowOffset(1,-1)
    row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    row:RegisterForClicks("LeftButtonUp","RightButtonUp")
    row:SetScript("OnClick",function(_,button)
      if P.EquipmentDragClick(row,button)then return end
      if row.locked then
        if button=="LeftButton" then f.selectedSlot=i;f.selected=nil;f.selectedItems={};P.RenderEquipment()end
        GameTooltip:Hide();return
      end
      f.selectedSlot=false
      local item=P.BagItem(row.itemID)
      if button=="LeftButton" and IsShiftKeyDown and IsShiftKeyDown() and item and not item.crate then
        local previous=P.GearItem(f.selected)
        if not next(f.selectedItems) and previous then f.selectedItems[previous.id]=true end
        f.selectedItems[item.id]=not f.selectedItems[item.id] or nil
        f.selected=nil
      else f.selectedItems={};f.selected=row.itemID end
      if item then item.isNew=nil;P.UpdateNewMarkers()end
      if button=="RightButton" and row.itemID then act(function()return P.UseBagItem(row.itemID)end)
      else P.RenderEquipment()end
      GameTooltip:Hide()
    end)
    row:SetScript("OnEnter",function(self)
      local item=P.BagItem(self.itemID);GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      if self.locked then
        GameTooltip:SetText("Locked bag slot")
        GameTooltip:AddLine(P.BagUnlockCredits()>0 and ("Use 1 free unlock ("..P.BagUnlockCredits().." left)")or ("Unlock for "..P.TokenText(P.BagSlotPrice())),1,0.82,0.3,true)
        GameTooltip:AddLine("Each purchase raises the next price: 1, 2, 4, 7, 11...",0.7,0.7,0.7,true)
        GameTooltip:AddLine("Select this slot, then click Buy at the bottom to unlock it.",1,1,1,true)
      elseif not item then GameTooltip:SetText("Empty bag slot")
      else
        item.isNew=nil;self.mark:SetText("");P.UpdateNewMarkers()
        P.EquipmentTooltip(self,item,not item.crate and "Drag to move or equip. Right-click to equip. Shift-left-click to select multiple items for sale." or "Drag to move. Right-click to open.",true);return
      end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  f.selection=text(f,"Select an item in your bag.",0,-450,456,58)
  f.equip=S.Button(f,"Equip",622,-508,110,function()act(function()return P.UseBagItem(f.selected)end)end)
  f.sell=S.Button(f,"Sell",742,-508,218,function()
    act(function()
      local ids={};for id in pairs(f.selectedItems)do ids[#ids+1]=id end
      if #ids==0 then return P.SellGear(f.selected)end
      table.sort(ids)
      local ok,msg=P.SellGearBatch(ids)
      f.selectedItems={};f.selected=nil
      return ok,msg
    end)
  end)
  f.buy=S.Button(f,"Buy",622,-508,338,function()
    local slot=f.selectedSlot
    if not slot then return end
    act(function()
      local ok,message=P.UnlockBagSlot(slot)
      if ok then f.selectedSlot=false end
      return ok,message
    end)
  end)
  f.claimCrate=S.Button(f,"Claim waiting crate",10,-402,218,function()act(P.ClaimWaitingCrate)end)
  f.notice=text(f,"Drag to move or equip. Filters dim other items. Shift-click to select several items for sale.",0,-514,456,36,S.muted)
  -- Only legacy saves can exceed the unlocked bag capacity. Keep those items reachable.
  f.overflow=S.Button(f,"",886,-477,74,function()f.selectedItems={};f.selected=nil;f.bagPage=(f.bagPage+1)%(f.maxBagPage+1);P.RenderEquipment()end)

end
function P.OpenEquipment()
  if P.equipment then P.equipment.filter=1;P.equipment.bagPage=0;P.equipment.selectedItems={};P.equipment.selected=nil end
  P.OpenPage("equipment")
end
function P.RenderEquipment()
  local f=P.equipment;local s=P.state;if not f or not f:IsShown() or not s then return end
  local owners=P.GearOwners()
  local saleCount,saleTotal=0,0
  for id in pairs(f.selectedItems)do
    local item=P.GearItem(id)
    if not item or owners[id] then f.selectedItems[id]=nil
    else saleCount=saleCount+1;saleTotal=saleTotal+P.GearSellPrice(item)end
  end
  local pet=P.Active();local hp,atk,armor,speed=0,0,0,0
  if pet then hp,atk,armor,speed=P.GearBonuses(pet)end
  P.UpdatePreviewBackground(f.background);P.ShowPetArt(f.art,pet)
  f.pet:SetText(pet and (P.species[pet.species].."\nLevel "..pet.level) or "Choose a companion in Camp")
  f.bonuses:SetText("Health     +"..hp.."\nAttack      +"..atk.."\nArmor      +"..armor.."%\nSpeed      +"..speed)
  for i,slot in ipairs(P.gearSlots)do
    local b=f.slots[i];local item=pet and pet.gear and P.GearItem(pet.gear[slot])
    local d=item and P.gearTypes[item.kind]
    b.label:SetText(d and d.name or "Empty");S.TextColor(b.label,item and P.colors[item.rarity] or S.muted)
    b.art:SetTexture("Interface\\Icons\\"..(d and d.icon or P.gearSlotIcons[slot]));b.art:SetDesaturated(not item);b.art:SetAlpha(item and 1 or 0.3)
    b.rarityRim:SetVertexColor(unpack(item and P.colors[item.rarity] or {0.5,0.5,0.5}))
    b:SetBackdropBorderColor(unpack(item and P.colors[item.rarity] or {0.25,0.26,0.3}));b:SetEnabled(not s.battle)
  end
  f.filterButton:SetText(f.filter==1 and "All bag items" or f.filter==7 and "Crates & bags" or f.filter==8 and "XP treats" or P.gearSlotNames[P.gearSlots[f.filter-1]])
  f.claimCrate:SetShown(P.WaitingLootCount()>0);f.claimCrate:SetText("Claim waiting loot ("..P.WaitingLootCount()..")")
  local used=P.BagCount(owners)
  local capacity=P.BagCapacity()
  f.capacity:SetText(used.." / "..capacity.." used | "..(P.maxBagSlots-capacity).." locked | "..P.BagUnlockCredits().." free unlocks")
  local rows,pages=P.GetBagLayout();f.maxBagPage=pages
  f.bagPage=math.min(f.bagPage,f.maxBagPage)
  f.overflow:SetShown(f.maxBagPage>0);f.overflow:SetText(f.bagPage==0 and "More >" or "< More")
  local price=P.BagSlotPrice()
  if f.selectedSlot and P.BagSlotUnlocked(f.selectedSlot)then f.selectedSlot=false end
  local openPosition,lockedPosition=0,capacity
  for i,row in ipairs(f.rows)do
    row.locked=f.bagPage==0 and not P.BagSlotUnlocked(i)
    row.bagSlot=f.bagPage*P.maxBagSlots+i
    -- Arrange the spaces, without sorting items or changing saved slot IDs.
    local position=i
    if f.bagPage==0 then
      if row.locked then lockedPosition=lockedPosition+1;position=lockedPosition
      else openPosition=openPosition+1;position=openPosition end
    end
    row.displaySlot=position;row:ClearAllPoints()
    row:SetPoint("TOPLEFT",24+((position-1)%10)*44,-10-math.floor((position-1)/10)*44)
    local item=not row.locked and rows[row.bagSlot] or nil
    row:Show();row.itemID=item and item.id
    row.selection:SetShown((item and (item.id==f.selected or f.selectedItems[item.id])) or (row.locked and f.selectedSlot==i) or false)
    local treat=item and P.xpTreats and P.xpTreats[item.crate]
    local matches=not item or f.filter==1 or (item.crate and f.filter==7 and not treat) or (treat and f.filter==8) or (not item.crate and P.gearTypes[item.kind].slot==P.gearSlots[f.filter-1])
    row.art:SetShown(item~=nil);row.art:SetAlpha(matches and 1 or .22)
    row.rarityRim:SetVertexColor(unpack(item and P.colors[item.rarity] or {0.5,0.5,0.5}))
    row.rarityRim:SetAlpha(matches and 1 or .35)
    for _,piece in ipairs(row.lockPieces)do piece:SetShown(row.locked)end
    row.mark:SetText("")
    local count=item and #s.bagLayout[row.bagSlot] or 0
    row.stackCount:SetText(count>1 and tostring(count) or "")
    row.stackCount:SetAlpha(matches and 1 or .4)
    row:SetBackdropBorderColor(0.24,0.24,0.28,1)
    if row.locked then
      if f.selectedSlot==i then row:SetBackdropBorderColor(unpack(S.gold))end
    elseif item then
      local d=P.BagDefinition(item);row.art:SetTexture("Interface\\Icons\\"..d.icon)
      row.mark:SetText(item.isNew and "NEW" or "")
      row:SetBackdropBorderColor(unpack(P.colors[item.rarity]))
    end
  end
  local selected=P.BagItem(f.selected);local owner=selected and owners[selected.id]
  if owner then selected=nil;f.selected=nil end
  local selectedTreat=selected and P.xpTreats and P.xpTreats[selected.crate]
  f.selection:SetText(selected and ((selected.crate and ((P.coinPouches[selected.crate] or selectedTreat) and "" or "Crate") or P.rarities[selected.rarity]).." "..P.BagDefinition(selected).name.."\n"..(selectedTreat and ("Use one: +"..selectedTreat.xp.." flat XP to the equipped pet.") or selected.crate and (P.coinPouches[selected.crate] and P.BagDescription(selected) or "Open for your reward. Hover for contents and rarity chances.") or P.BagDescription(selected))) or "Select an item in your bag.")
  if f.selectedSlot then f.selection:SetText("Locked bag slot "..f.rows[f.selectedSlot].displaySlot.."\n"..(P.BagUnlockCredits()>0 and "Use a free unlock to open this slot."or ("Unlock for "..P.TokenText(price)..". Click Buy below.")))end
  S.TextColor(f.selection,f.selectedSlot and S.gold or selected and P.colors[selected.rarity] or S.muted)
  f.buy:SetShown(not not f.selectedSlot)
  f.buy:SetText(P.BagUnlockCredits()>0 and ("Use free unlock ("..P.BagUnlockCredits().." left)")or ("Buy - "..P.TokenText(price or 0)))
  f.buy:SetEnabled(not not f.selectedSlot and price~=nil and s.tokens>=price and not s.battle)
  f.equip:SetShown(not f.selectedSlot);f.sell:SetShown(not f.selectedSlot)
  f.equip:SetText(selectedTreat and "Use treat" or selected and selected.crate and (P.coinPouches[selected.crate] and "Open pouch" or "Open crate") or "Equip")
  f.equip:SetEnabled(selected~=nil and (selected.crate~=nil or pet~=nil) and not s.battle)
  f.sell:SetText(selected and not selected.crate and ("Sell for "..P.TokenText(P.GearSellPrice(selected))) or "Sell")
  f.sell:SetEnabled(selected~=nil and not selected.crate and not owner and not s.battle)
  if saleCount>0 then
    f.selection:SetText(saleCount.." equipment items selected\nShift-left-click to add or remove items.")
    S.TextColor(f.selection,S.gold);f.equip:SetEnabled(false)
    f.sell:SetText("Sell "..saleCount.." - "..P.TokenText(saleTotal))
    f.sell:SetEnabled(not s.battle and s.tokens+saleTotal<=P.maxTokens)
  end

end
function P.BuildEquipmentBoxes()
  local f=P.NewPage();P.boxes=f;f.cards={}
  f.crateTitle=text(f,"CRATES",16,-12,500,30)
  P.CrateTabs(f,"boxes")
  for i,box in ipairs(P.equipmentBoxes)do
    local index=i;local c=S.Panel(f,16+((i-1)%3)*320,-58-math.floor((i-1)/3)*190,308,180);f.cards[i]=c
    text(c,box.name,12,-7,284,30)
    P.BuildCrateModel(c,i)
    P.BuildCrateOdds(c,P.CrateOdds("gear",i),126,-42,170,i)
    c.buy=S.Button(c,"Buy - "..P.TokenText(box.cost),12,-148,284,function()act(function()return P.BuyEquipmentBox(index)end)end)
    c:EnableMouse(true)
    c:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(box.name);GameTooltip:AddLine(P.CrateOddsHelp("gear",index),1,1,1,true);GameTooltip:Show()end)
    c:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  f.info=text(f,"",18,-446,918,86,S.muted)
end
function P.RenderEquipmentBoxes()
  local f=P.boxes;if not f or not f:IsShown()then return end
  f.crateTitle:SetText(P.HardMode and P.HardMode.IsHard() and "CRATES - HARD MODE" or "CRATES")
  local s=P.state
  local full=P.BagCount()>=P.BagCapacity() or #s.gear+(F.Trades and F.Trades.RecordReserved("gear") or 0)>=500
    or s.nextGearID+(F.Trades and F.Trades.Reserved("bag") or 0)>1000000000
  for i,c in ipairs(f.cards)do
    P.BuildCrateOdds(c,P.CrateOdds("gear",i),126,-42,170,i)
    c.buy:SetText(full and "Bag full" or "Buy - "..P.TokenText(P.equipmentBoxes[i].cost))
    c.buy:SetEnabled(not full and not s.battle and s.tokens>=P.equipmentBoxes[i].cost)
  end
  f.info:SetText(P.TokenText(s.tokens).." | Bag "..P.BagCount().." / "..P.BagCapacity().."\nOne gear item. Duplicates can be sold. Gear survives retirement.\nShown chances include your loot-rarity talent bonuses.")
end
-- Loot stays inside the floating pet window, never a separate popup.
function P.StartRewards()
  if not F.petIcon then return end
  if not P.rewardFrame then
    local f=CreateFrame("Frame",nil,F.petIcon,"BackdropTemplate");P.rewardFrame=f
    f:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetPoint("TOPLEFT",4,-4);f:SetSize(68,64);f:SetFrameLevel(F.petIcon.button:GetFrameLevel()+5);f:EnableMouse(false)
    local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.04,0.03,0.06,0.94)
    f.glow=f:CreateTexture(nil,"ARTWORK");f.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square");f.glow:SetBlendMode("ADD");f.glow:SetPoint("CENTER",0,6)
    f.art=f:CreateTexture(nil,"OVERLAY");f.art:SetPoint("TOP",0,-2);f.art:SetSize(38,38)
    f.title=text(f,"",0,-40,68,12);f.title:SetJustifyH("CENTER")
    f.rarity=text(f,"",0,-52,68,12);f.rarity:SetJustifyH("CENTER")
    f:SetScript("OnUpdate",function(self,dt)
      local event=P.ProgressEvent(P.Active())
      local now=GetTime and GetTime() or F.Now()
      if event and now>=event.at and now-event.at<4 then
        self:SetAlpha(0);return -- Show XP/ding above the pet before revealing loot.
      end
      if not rawget(self,"item") then
        self.item=table.remove(P.rewards,1);self.age=0
        if not rawget(self,"item")then self:Hide();return end
        local item=self.item;F.petIcon.lastLoot=item
        self.title:SetText(item.kind=="pet" and "NEW PET!" or item.kind=="crate" and "OPENING" or item.kind=="crate_found" and "NEW CRATE!" or item.kind=="item" and "NEW ITEM!" or "NEW LOOT!")
        S.RarityText(self.title,P.colors[item.rarity])
        self.rarity:SetText(item.kind~="crate" and P.rarities[item.rarity] or "")
        S.RarityText(self.rarity,P.colors[item.rarity])
        self:SetBackdropBorderColor(unpack(P.colors[item.rarity]))
        self.glow:SetVertexColor(unpack(P.colors[item.rarity]))
        if item.species then P.ShowPetPortrait(self.art,{species=item.species,rarity=item.rarity,rolls=item.rolls})
        else
          if P.StyleSparklyPortrait then P.StyleSparklyPortrait(self.art,nil)end
          self.art.cfPortraitDisplay=nil;self.art.cfPortraitRenderer=nil
          self.art:SetTexture("Interface\\Icons\\"..(item.icon or "INV_Crate_01"));self.art:SetTexCoord(0,1,0,1);self.art:SetDesaturated(false)
        end
        self.art:SetAlpha(1);self.art:SetVertexColor(1,1,1);self.art:Show()
      end
      self.age=self.age+math.min(dt,0.1)
      local duration=self.item.kind=="crate" and 1.6 or 3.4
      local motion=not F.db.settings.reduceMotion and not S.HighContrast()
      local alpha=math.min(1,self.age/0.2,(duration-self.age)/0.35)
      self:SetAlpha(motion and math.max(0,alpha) or 1)
      local pulse=motion and math.sin(self.age*8)*0.1 or 0
      self.glow:SetSize(56*(1+pulse),56*(1+pulse));self.glow:SetAlpha(0.6+pulse)
      if self.age>=duration then self.item=nil end
    end)
    f:Hide()
  end
  F.LayoutPetIcon()
  P.rewardFrame:Show()
end
