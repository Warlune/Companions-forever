local _,F=...
local P,S=F.Pets,F.Style
local function text(p,v,x,y,w,h,c)
  local t=S.Text(p,v,x,y,w,"GameFontHighlightSmall",c or S.gold);t:SetHeight(h);return t
end
local function tip(b,fn)
  b:SetScript("OnEnter",function(self)P.ShowTalentTooltip(self,fn())end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function clearPlan(f)f.plan=false;f.planBase=false;f.planTraining=false end
local function preview(f)
  local t=P.state.training
  if f.planTraining~=t then clearPlan(f)end
  if f.planBase then
    for _,branch in ipairs(P.talentBranches)do if f.planBase[branch.key]~=t[branch.key]then clearPlan(f);break end end
  end
  if not f.plan then
    f.plan={};f.planBase={};f.planTraining=t
    for _,branch in ipairs(P.talentBranches)do f.planBase[branch.key]=t[branch.key]end
  end
  local ranks={};local count=0
  for _,branch in ipairs(P.talentBranches)do
    local key=branch.key;local added=f.plan[key] or 0;ranks[key]=t[key]+added;count=count+added
  end
  return ranks,t.points-count,count
end
function P.BuildTalents()
  local f=P.NewPage();P.talents=f;f.offset=0;f.selected=false;f.confirm=false;f.confirmValue=false
  f:SetScript("OnHide",function()clearPlan(f);f.resetConfirm=nil end)
  f.tree=S.Panel(f,0,0,606,548)
  local art=f.tree:CreateTexture(nil,"BORDER");art:SetPoint("TOPLEFT",4,-4);art:SetPoint("BOTTOMRIGHT",-4,4)
  art:SetTexture("Interface\\AddOns\\CompanionsForever\\Art\\PetScenes"..S.Faction()..".tga");art:SetTexCoord(0,0.5,0,1);art:SetAlpha(0.22)
  local badge=CreateFrame("Frame",nil,f.tree);badge:SetPoint("TOPLEFT",14,-10);badge:SetSize(46,46)
  -- The minimap border has asymmetric transparent padding. Build two centered
  -- circles so the level stays inside the visible ring at every font size.
  for i=1,2 do
    local disk=badge:CreateTexture(nil,"BACKGROUND",nil,i)
    disk:SetPoint("CENTER");disk:SetSize(i==1 and 46 or 40,i==1 and 46 or 40)
    if i==1 then disk:SetColorTexture(unpack(S.gold))else disk:SetColorTexture(0.06,0.05,0.04,1)end
    local mask=badge:CreateMaskTexture();mask:SetAtlas("CircleMask");mask:SetAllPoints(disk);disk:AddMaskTexture(mask)
  end
  f.level=text(badge,"",0,0,40,40);f.level:ClearAllPoints();f.level:SetPoint("CENTER",badge,"CENTER",0,0)
  f.level:SetJustifyH("CENTER");f.level:SetJustifyV("MIDDLE")
  f.xp=CreateFrame("StatusBar",nil,f.tree);f.xp:SetPoint("TOPLEFT",70,-21);f.xp:SetSize(518,10);f.xp:SetMinMaxValues(0,1)
  f.xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");f.xp:SetStatusBarColor(0.55,0.25,0.85)
  local xpbg=f.xp:CreateTexture(nil,"BACKGROUND");xpbg:SetAllPoints();xpbg:SetColorTexture(0.07,0.04,0.09,1)
  f.xpPreview=f.xp:CreateTexture(nil,"BACKGROUND",nil,1);f.xpPreview:SetPoint("TOPLEFT");f.xpPreview:SetHeight(10);f.xpPreview:SetColorTexture(0.25,0.65,1,0.85)
  f.rank=text(f.tree,"",70,-15,518,22);f.rank:SetJustifyH("CENTER")
  f.xpHint=text(f.tree,"",70,-37,518,20,S.muted)
  f.pointBox=S.Panel(f.tree,16,-65,574,44)
  f.points=text(f.pointBox,"",8,-4,558,36);f.points:SetJustifyH("CENTER")
  f.points:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",18,"OUTLINE")
  f.nodes={}
  for i=1,10 do
    local cap,required=i*10,(i-1)*3
    local b=CreateFrame("Button",nil,f.tree,"BackdropTemplate");f.nodes[i]=b
    b:SetPoint("TOPLEFT",22+(i-1)*57,-116);b:SetSize(36,28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10})
    b.label=text(b,tostring(cap),0,0,36,28);b.label:SetJustifyH("CENTER")
    tip(b,function()return "Pet level cap "..cap.."\nUnlocked at trainer level "..required..".\nRespec keeps this unlock."end)
  end
  f.talentNodes={}
  for i,branch in ipairs(P.talentBranches)do
    local key,name=branch.key,branch.name;local cx=77+(i-1)*151
    text(f.tree,name,cx-72,-150,144,26):SetJustifyH("CENTER")
    for tier=1,#branch.nodes do
      local level=tier;local node=branch.nodes[tier];local y=-184-(tier-1)*70
      local b=CreateFrame("Button",nil,f.tree,"BackdropTemplate");f.talentNodes[#f.talentNodes+1]=b
      b.key=key;b.tier=level;b:SetPoint("TOPLEFT",cx-24,y);b:SetSize(42,42)
      b:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
      b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",5,-5);b.art:SetPoint("BOTTOMRIGHT",-5,5)
      b.art:SetTexture("Interface\\Icons\\"..node.icon)
      b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress");b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
      b.rank=text(b,"",19,-32,34,20);b.rank:SetJustifyH("CENTER")
      text(f.tree,node.name,cx-72,y-43,144,22):SetJustifyH("CENTER")
      if tier>1 then
        b.link=f.tree:CreateTexture(nil,"BORDER");b.link:SetSize(3,8);b.link:SetPoint("TOPLEFT",cx-1,y+10)
        b.arrow=text(f.tree,"v",cx-6,y+9,14,14);b.arrow:SetJustifyH("CENTER")
      end
      b:RegisterForClicks("LeftButtonUp","RightButtonUp")
      b:SetScript("OnClick",function(_,button)
        local ranks,available=preview(f);local _,before=P.TalentNode(key,level)
        if P.state.battle then P.notice="Finish the battle before training."
        elseif button=="RightButton" then
          if (f.plan[key] or 0)>0 and ranks[key]>before and ranks[key]<=before+node.ranks then f.plan[key]=f.plan[key]-1 end
        elseif available>0 and ranks[key]>=before and ranks[key]<before+node.ranks then
          f.plan[key]=(f.plan[key] or 0)+1
        end
        f.resetConfirm=nil;P.Render()
      end)
      tip(b,function()return P.TalentTooltip(key,level)
      end)
    end
  end
  f.racial=P.BuildRacialIcon(f.tree,16,-475);text(f.tree,"Trainer racial",52,-477,240,24,S.muted)
  f.apply=S.Button(f.tree,"Confirm",16,-508,110,function()
    preview(f)
    local ok,msg=P.ConfirmTalentPlan(f.plan,f.planBase)
    if ok then clearPlan(f)else P.notice=msg end
    P.Render()
  end)
  f.discard=S.Button(f.tree,"Cancel",134,-508,100,function()clearPlan(f);P.RenderTalents()end)
  f.respec=S.Button(f.tree,"",244,-508,226,function()
    if not f.resetConfirm then f.resetConfirm=true;P.RenderTalents();return end
    local ok,msg=P.RespecTalents();if not ok then P.notice=msg else clearPlan(f)end;f.resetConfirm=nil;P.Render()
  end)
  f.cancel=S.Button(f.tree,"Cancel",478,-508,110,function()f.resetConfirm=nil;P.RenderTalents()end)
  tip(f.respec,function()return "Reset talents: "..P.TokenText(P.respecCost).."\nRefunds spent points. Keeps trainer XP, level and pet level caps."end)
  f.retirement=S.Panel(f,624,0,336,548)
  text(f.retirement,"RETIRE A COMPANION",14,-12,308,26)
  text(f.retirement,"Retire at any level. Every 10 levels adds a 25% level bonus. Dead pets earn 50% less. Collection kept; gear returned.",14,-44,308,64,S.muted)
  f.rows={}
  f.stableScroll=CreateFrame("Slider",nil,f.retirement,"BackdropTemplate")
  f.stableScroll:SetPoint("TOPLEFT",310,-112);f.stableScroll:SetSize(12,156)
  f.stableScroll:SetOrientation("VERTICAL");f.stableScroll:SetMinMaxValues(0,0)
  f.stableScroll:SetValueStep(1);f.stableScroll:SetObeyStepOnDrag(true)
  f.stableScroll:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  f.stableScroll:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});f.stableScroll:SetBackdropColor(.15,.15,.17,1)
  local function scroll(value)
    value=math.max(0,math.min(math.max(0,#P.state.pets-3),math.floor(value+0.5)))
    if value~=f.offset then f.offset=value;f.confirm=false;P.RenderTalents()end
  end
  f.stableScroll:SetScript("OnValueChanged",function(_,value)scroll(value)end)
  local function wheel(_,delta)scroll(f.offset-delta)end
  f.retirement:EnableMouseWheel(true);f.retirement:SetScript("OnMouseWheel",wheel)
  for i=1,3 do
    local row=CreateFrame("Button",nil,f.retirement);f.rows[i]=row
    row:SetPoint("TOPLEFT",12,-112-(i-1)*52);row:SetSize(288,50)
    row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",wheel)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.art=row:CreateTexture(nil,"ARTWORK");row.art:SetSize(36,36);row.art:SetPoint("LEFT")
    row.label=text(row,"",44,0,240,50)
    row.selection=CreateFrame("Frame",nil,row,"BackdropTemplate");row.selection:SetAllPoints();row.selection:EnableMouse(false)
    row.selection:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14})
    row.selection:SetBackdropBorderColor(1,.8,.15,1)
    row.glow=row:CreateTexture(nil,"BACKGROUND");row.glow:SetAllPoints()
    row.glow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");row.glow:SetBlendMode("ADD");row.glow:SetVertexColor(1,.75,.15,.4)
    row:SetScript("OnClick",function()f.selected=row.petID;f.confirm=false;P.RenderTalents()end)
    tip(row,function()
      for _,pet in ipairs(P.state.pets)do if pet.id==row.petID then return P.PetName(pet).."\n"..P.RetirementDetails(pet)end end
      return "Companion no longer available."
    end)
  end
  f.count=text(f.retirement,"",14,-274,308,26,S.muted)
  f.details=text(f.retirement,"",14,-310,308,126,{1,1,1})
  f.retire=S.Button(f.retirement,"Select a pet",14,-452,222,function()
    if not f.selected then return end
    local pet
    for _,candidate in ipairs(P.state.pets)do if candidate.id==f.selected then pet=candidate;break end end
    if not pet then f.selected=false;f.confirm=false;P.RenderTalents();return end
    if pet.retirementLocked then f.confirm=false;P.RenderTalents();return end
    local value,unit=P.RetirementReward(pet)
    if f.confirm~=f.selected or f.confirmValue~=value or f.confirmUnit~=unit then f.confirm=f.selected;f.confirmValue=value;f.confirmUnit=unit;P.RenderTalents();return end
    local ok,msg=P.RetirePet(f.selected);if not ok then P.notice=msg end
    f.confirm=false;f.selected=false;P.Render()
  end)
  f.retireCancel=S.Button(f.retirement,"Cancel",244,-452,78,function()f.confirm=false;P.RenderTalents()end)
  f.warning=text(f.retirement,"",14,-486,308,56,{1,0.65,0.3})
end
function P.OpenRetirement(id)
  P.OpenPage("talents")
  local f=P.talents;f.selected=false;f.confirm=false
  for i,pet in ipairs(P.state.pets)do if pet.id==id then
    f.selected=id;f.offset=math.max(0,math.min(i-1,#P.state.pets-3));f.confirm=not pet.retirementLocked and id or false;f.confirmValue,f.confirmUnit=P.RetirementReward(pet);break
  end end
  P.RenderTalents()
end
function P.RenderTalents()
  local f=P.talents;if not f or not f:IsShown()then return end
  local t=P.state.training
  local ranks,available,pending=preview(f)
  P.UpdateRacialIcon(f.racial)
  f.level:SetText(t.level)
  local needed=P.TrainingNeeded(t.level);local capped=t.level==P.MaxTraining()
  f.xp:SetValue(capped and 1 or t.xp/needed)
  f.rank:SetText(capped and "Maximum mastery" or (t.xp.." / "..needed.." XP"))
  local retiring;for _,pet in ipairs(P.state.pets)do if pet.id==f.selected then retiring=pet end end
  local gain=retiring and P.RetirementValue(retiring) or 0
  f.xpPreview:SetWidth(math.max(1,518*math.min(1,(t.xp+gain)/needed)));f.xpPreview:SetShown(gain>0 and not capped)
  local level,xp=t.level,t.xp+gain
  while level<P.MaxTraining() and xp>=P.TrainingNeeded(level)do xp=xp-P.TrainingNeeded(level);level=level+1 end
  local progress=level>=P.MaxTraining() and "MAX" or math.floor(xp/P.TrainingNeeded(level)*100).."%"
  f.xpHint:SetText(retiring and retiring.retirementLocked and "Locked - unlock this pet in Camp." or retiring and capped and ("Retire preview: +"..P.RetirementRewardText(retiring)) or gain>0 and ("Retire preview: Level "..level.." - "..progress.."  |  +"..gain.." XP") or ("Pet level cap "..P.LevelCap().."  |  Select a pet to preview retirement."))

  for i,b in ipairs(f.nodes)do
    local unlocked=t.level>=(i-1)*3
    b:SetBackdropColor(unlocked and 0.15 or 0.03,unlocked and 0.12 or 0.03,0.03,1)
    b:SetBackdropBorderColor(unpack(unlocked and S.gold or {0.25,0.25,0.25}));S.TextColor(b.label,unlocked and S.gold or S.muted)
  end
  f.points:SetText("AVAILABLE POINTS: "..available..(pending>0 and "   |   Pending: "..pending or ""))
  f.apply:SetEnabled(pending>0 and not P.state.battle);f.discard:SetEnabled(pending>0)
  for _,b in ipairs(f.talentNodes)do
    local total=ranks[b.key];local node,before=P.TalentNode(b.key,b.tier);local rank=math.max(0,math.min(node.ranks,total-before))
    local unlocked=total>=before;local train=unlocked and rank<node.ranks and available>0
    b.art:SetDesaturated(not unlocked);b.art:SetAlpha(unlocked and 1 or 0.35);b.rank:SetText(rank.."/"..node.ranks)
    local color=rank>P.TalentRank(b.key,b.tier) and {0.3,0.7,1} or rank==node.ranks and S.gold or train and {0.2,1,0.2} or S.muted
    b:SetBackdropBorderColor(unpack(color));S.TextColor(b.rank,color)
    if rawget(b,"link") then b.link:SetColorTexture(unpack(unlocked and S.gold or {0.25,0.25,0.25}));S.TextColor(b.arrow,unlocked and S.gold or S.muted)end
  end
  f.respec:SetText((f.resetConfirm and "Confirm reset: " or "Reset talents: ")..P.TokenText(P.respecCost))
  f.respec:SetEnabled(t.points<t.level and P.state.tokens>=P.respecCost and not P.state.battle);f.cancel:SetShown(not not f.resetConfirm)
  local pets={};local selected
  for _,pet in ipairs(P.state.pets)do pets[#pets+1]=pet;if pet.id==f.selected then selected=pet end end
  if not selected then f.selected=false;f.confirm=false end
  local rewardValue,rewardUnit=P.RetirementReward(selected)
  if selected and f.confirm and (selected.retirementLocked or f.confirmValue~=rewardValue or f.confirmUnit~=rewardUnit)then f.confirm=false end
  local maxOffset=math.max(0,#pets-3);f.offset=math.min(f.offset,maxOffset)
  f.stableScroll:SetMinMaxValues(0,maxOffset);f.stableScroll:SetValue(f.offset);f.stableScroll:SetShown(maxOffset>0)
  for i,row in ipairs(f.rows)do
    local pet=pets[f.offset+i];row:SetShown(pet~=nil);row.petID=pet and pet.id
    row.selection:SetShown(pet~=nil and pet.id==f.selected);row.glow:SetShown(pet~=nil and pet.id==f.selected)
    if pet then
      P.ShowPetPortrait(row.art,pet)
      row.label:SetText((pet.id==f.selected and "> " or "")..P.PetName(pet).."\nLv "..pet.level.." "..P.rarities[pet.rarity]..(pet.retirementLocked and " | Locked" or " | +"..P.RetirementRewardText(pet))..(pet.deadAt and " | Dead" or ""))
      row.art:SetDesaturated(not not pet.retirementLocked);row.art:SetAlpha(pet.retirementLocked and .35 or 1)
      S.TextColor(row.label,pet.retirementLocked and S.muted or pet.id==f.selected and S.gold or P.colors[pet.rarity])
    end
  end
  f.count:SetText(#pets==0 and "No companions" or (f.offset+1).."-"..math.min(#pets,f.offset+3).." of "..#pets.."  |  Scroll to browse")
  f.details:SetText(selected and (P.species[selected.species].."\n"..P.RetirementDetails(selected)) or (capped and "Select a companion to preview its token reward.\nUp to 30 tokens per retirement." or "Select a companion to see its reward.\n1 reward point = 10 talent XP."))
  f.retire:SetEnabled(selected~=nil and not selected.retirementLocked and not P.state.battle)
  f.retire:SetText(not selected and "Select a pet above" or selected.retirementLocked and "Locked" or f.confirm==selected.id and "Confirm retirement" or "Retire: +"..P.RetirementRewardText(selected))
  f.retireCancel:SetShown(not not f.confirm)
  f.warning:SetText(selected and selected.retirementLocked and "Unlock this companion in Camp to retire it." or f.confirm and "Are you sure? This permanently removes this pet. Gear returns; collection stays unlocked." or t.level>=P.MaxTraining() and "Maximum mastery: retirement now gives tokens." or "Retirement is permanent. Review the reward above, then click Retire to confirm.")
end
