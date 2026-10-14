local _,F=...
local P,S,A=F.Pets,F.Style,F.Achievements
local function label(parent,value,x,y,w,h,color)
  local t=S.Text(parent,value,x,y,w,"GameFontHighlightSmall",color or S.muted);t:SetHeight(h);return t
end
local function act(fn)local ok,msg=fn();if not ok then P.notice=msg end;P.Render()end
function A.Browse(mode)
  local rows={};local s=P.state.achievements
  for index,d in ipairs(A.list)do
    local progress=math.min(d.goal,A.Progress(d));local complete=s.claimed[d.id] or progress>=d.goal
    if mode=="all" or mode=="completed" and complete or mode=="closest" and not complete then
      rows[#rows+1]={entry=d,index=index,ratio=progress/d.goal,ready=complete and not A.Settled(d)}
    end
  end
  table.sort(rows,function(a,b)
    if mode~="closest" and a.ready~=b.ready then return not not a.ready end
    if mode=="closest" and a.ratio~=b.ratio then return a.ratio>b.ratio end
    return a.index<b.index
  end)
  local result={};for i,row in ipairs(rows)do result[i]=row.entry end;return result
end
-- Borders use native geometry or a transparent illustration, never an overhead crest.
function P.CreatePortraitFrame(parent,art)
  local frame=CreateFrame("Frame",nil,parent,"BackdropTemplate");frame:SetAllPoints(art);frame:EnableMouse(false)
  frame:SetFrameLevel(parent:GetFrameLevel()+8)
  frame:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
  frame.inner=CreateFrame("Frame",nil,frame,"BackdropTemplate");frame.inner:SetPoint("TOPLEFT",5,-5);frame.inner:SetPoint("BOTTOMRIGHT",-5,5)
  frame.inner:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});frame.inner:EnableMouse(false)
  frame.illustration=frame:CreateTexture(nil,"OVERLAY");frame.illustration:SetAllPoints();frame.illustration:Hide()
  frame.pieces={};for i=1,32 do frame.pieces[i]=frame:CreateTexture(nil,"OVERLAY")end
  return frame
end
function P.UpdatePortraitFrame(frame,index,locked)
  local id=A.frames[index] and index or 1
  if rawget(frame,"cfBorderID")==id and rawget(frame,"cfBorderLocked")==not not locked then return end
  frame.cfBorderID=id;frame.cfBorderLocked=not not locked
  local d=A.frames[id];frame.frameID=id
  if d.texture and not locked then
    frame:SetBackdropBorderColor(0,0,0,0);frame.inner:Hide()
    for _,t in ipairs(frame.pieces)do t:Hide()end
    frame.illustration:SetTexture(d.texture);frame.illustration:SetDesaturated(false);frame.illustration:Show();return
  end
  frame.illustration:Hide();frame.inner:Show()
  local c=locked and {0.32,0.34,0.36} or d.color
  frame:SetBackdropBorderColor(unpack(c));frame.inner:SetBackdropBorderColor(c[1]*0.55,c[2]*0.55,c[3]*0.55,1)
  local used=0
  local function piece(anchor,x,y,w,h,angle)
    used=used+1;local t=frame.pieces[used];t:ClearAllPoints();t:SetPoint(anchor,x,y);t:SetSize(w,h)
    t:SetColorTexture(c[1],c[2],c[3],1);if t.SetRotation then t:SetRotation(angle or 0)end;t:Show()
  end
  for _,corner in ipairs({{"TOPLEFT",1,-1},{"TOPRIGHT",-1,-1},{"BOTTOMLEFT",1,1},{"BOTTOMRIGHT",-1,1}})do
    local anchor,x,y=unpack(corner);local style=d.style or 1
    if style==1 then piece(anchor,0,0,22,3);piece(anchor,0,0,3,22)
    elseif style==2 then piece(anchor,x*2,y*2,9,9,math.pi/4);piece(anchor,x*14,0,17,3);piece(anchor,0,y*14,3,17)
    elseif style==3 then
      piece(anchor,0,0,26,3);piece(anchor,0,0,3,26)
      for j=1,2 do piece(anchor,x*j*8,y*6,3,3);piece(anchor,x*6,y*j*8,3,3)end
    elseif style==4 then
      for j=0,2 do piece(anchor,x*j*4,y*j*4,25-j*7,2);piece(anchor,x*j*4,y*j*4,2,25-j*7)end
    else
      piece(anchor,0,0,28,3);piece(anchor,0,0,3,28)
      for j=1,3 do piece(anchor,x*(j*5),y*(j*5),10,2,x*y*math.pi/4)end
    end
  end
  for i=used+1,#frame.pieces do frame.pieces[i]:Hide()end
end
local function rewardView(parent,x,y,size)
  local v=CreateFrame("Frame",nil,parent);v:SetPoint("TOPLEFT",x,y);v:SetSize(size,size)
  v:EnableMouse(true)
  v:SetScript("OnEnter",function(self)if self.entry then A.ShowRewardTooltip(self,self.entry,self.rewardKind)end end)
  v:SetScript("OnLeave",function()GameTooltip:Hide()end)
  v.art=v:CreateTexture(nil,"ARTWORK");v.art:SetAllPoints()
  v.border=P.CreatePortraitFrame(v,v.art);return v
end
local function rewardArt(views,d)
  local rewards={}
  if d.pet then rewards[#rewards+1]={kind="pet",known=A.PetKnown(d)}end
  if d.frame then rewards[#rewards+1]={kind="frame",known=A.FrameVisible(d.frame)}end
  if d.crate then rewards[#rewards+1]={kind="crate",known=true}end
  if d.tokens then rewards[#rewards+1]={kind="tokens",known=true}end
  for i,v in ipairs(views)do
    local r=rewards[i];v.entry=d;v.rewardKind=r and r.kind;v:SetShown(r~=nil)
    if r then
      v.border:Hide();v.art.cfPortraitDisplay=nil;v.art:SetDesaturated(false)
      if not r.known then v.art:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      elseif r.kind=="frame"then v.art:SetColorTexture(0.035,0.04,0.055,1);v.border:Show();P.UpdatePortraitFrame(v.border,d.frame)
      elseif r.kind=="pet"then P.ShowPetPortrait(v.art,{species=d.pet,rarity=d.rarity})
      else v.art:SetTexture("Interface\\Icons\\"..(r.kind=="tokens" and "INV_Misc_Coin_01" or P.BagDefinition({crate=d.crate}).icon))end
    end
  end
end
local function scrollList(panel,y,height,maxOffset)
  panel.offset=0;panel.maxOffset=maxOffset
  local slider=CreateFrame("Slider",nil,panel,"BackdropTemplate");panel.scroll=slider
  slider:SetPoint("TOPLEFT",604,y);slider:SetSize(12,height);slider:SetOrientation("VERTICAL")
  slider:SetMinMaxValues(0,maxOffset);slider:SetValueStep(1);slider:SetObeyStepOnDrag(true)
  slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  slider:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});slider:SetBackdropColor(0.15,0.15,0.17,1)
  local function move(value)
    value=math.max(0,math.min(panel.maxOffset,math.floor(value+0.5)))
    if panel.offset~=value then panel.offset=value;slider:SetValue(value);P.RenderJournal()end
  end
  slider:SetScript("OnValueChanged",function(_,v)move(v)end)
  panel.wheel=function(_,delta)move(panel.offset-delta)end
  panel:EnableMouseWheel(true);panel:SetScript("OnMouseWheel",panel.wheel)
  for _,row in ipairs(panel.rows)do row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",panel.wheel)end
end
function P.BuildJournalExtras(f)
  f.subtab=P.state.journalTab or "collections";f.subButtons={}
  for i,key in ipairs({"collections","achievements","frames","abilities"})do
    local title=({"Pets","Achievements","Frames","Abilities"})[i]
    f.subButtons[key]=S.Button(f,title,(i-1)*168,0,158,function()f.search:ClearFocus();if rawget(f,"abilityBook")then f.abilityBook.search:ClearFocus()end;GameTooltip:Hide();f.subtab=key;P.state.journalTab=key;P.RenderJournal()end)
  end
  local a=CreateFrame("Frame",nil,f);f.achievementPanel=a;a:SetPoint("TOPLEFT",0,-42);a:SetSize(960,508);a.rows={};a.selected="first"
  a.count=label(a,"",0,0,590,28,S.gold)
  a.batchStatus=label(a,"",0,0,600,28,S.gold)
  a.claimAll=S.Button(a,"Claim all",622,-480,338,function()
    local ok,message,_,_,warning=A.ClaimAll()
    a.batchStatus:SetText(message);a.batchWarning=warning or (not ok and message or nil);P.Render()
  end)
  a.claimAll:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Claim all ready achievements")
    GameTooltip:AddLine("Claims rewards from every category. Pets go to Mail when your stable is full. Rewards that cannot fit stay unclaimed.",1,1,1,true);GameTooltip:Show()
  end)
  a.claimAll:SetScript("OnLeave",function()GameTooltip:Hide()end)
  for i=1,5 do
    local row=CreateFrame("Button",nil,a,"BackdropTemplate");a.rows[i]=row
    row:SetPoint("TOPLEFT",0,-36-(i-1)*84);row:SetSize(600,78)
    row:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=32,edgeSize=12})
    row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("TOPLEFT",12,-12);row.icon:SetSize(50,50)
    row.rim=row:CreateTexture(nil,"OVERLAY");row.rim:SetPoint("CENTER",row.icon,"CENTER");row.rim:SetSize(78,78);row.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    row.title=label(row,"",78,-6,390,22,S.gold);row.progress=label(row,"",468,-6,115,22);row.progress:SetJustifyH("RIGHT")
    row.desc=label(row,"",78,-31,380,34)
    row.rewards={};for k=1,4 do row.rewards[k]=rewardView(row,480+(k-1)*28,-36,26)end;row.reward=row.rewards[1]
    row.fill=row:CreateTexture(nil,"ARTWORK");row.fill:SetPoint("BOTTOMLEFT",78,7);row.fill:SetHeight(2)
    row.done=row:CreateTexture(nil,"OVERLAY");row.done:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");row.done:SetPoint("BOTTOMRIGHT",row.icon,"BOTTOMRIGHT",4,-4);row.done:SetSize(22,22)
    row:SetScript("OnEnter",function(self)if self.entry then A.ShowRewardTooltip(self,self.entry)end end)
    row:SetScript("OnLeave",function()GameTooltip:Hide()end)
    row:SetScript("OnClick",function()if row.entry then a.selected=row.entry.id;a.batchWarning=nil;P.state.achievements.seenAchievements[row.entry.id]=true;P.RenderJournal()end end)
  end
  scrollList(a,-36,414,math.max(0,#A.list-5))
  a.sortMode="all"
  a.sort=S.Dropdown(a,"Sort: All",0,-458,184,{{"all","All"},{"completed","Completed"},{"closest","Closest"}},function()return a.sortMode end,function(value)
    a.sortMode=value
    a.offset=0;P.RenderJournal()
  end)
  a.pageLabel=label(a,"Scroll to browse achievements",196,-458,404,42)
  local details=S.Panel(a,622,0,338,498);a.details=details
  a.icon=details:CreateTexture(nil,"ARTWORK");a.icon:SetPoint("TOPLEFT",16,-18);a.icon:SetSize(54,54)
  a.title=label(details,"",82,-16,240,58,S.gold)
  a.desc=label(details,"",16,-86,306,96)
  local help=CreateFrame("Frame",nil,details);help:SetPoint("TOPLEFT",16,-18);help:SetSize(54,54);help:EnableMouse(true)
  help:SetScript("OnEnter",function(self)local d=A.byID[a.selected];if d then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(d.name);GameTooltip:AddLine(A.ProgressHelp(d),1,1,1,true);GameTooltip:Show()end end)
  help:SetScript("OnLeave",function()GameTooltip:Hide()end)
  label(details,"REWARDS",16,-186,306,24,S.gold)
  a.rewardIcons={};for k=1,4 do a.rewardIcons[k]=rewardView(details,18+(k-1)*70,-214,52)end;a.rewardIcon=a.rewardIcons[1]
  a.reward=label(details,"",16,-278,306,88,{0.95,0.95,0.9})
  a.status=label(details,"",16,-376,306,58)
  a.claim=S.Button(details,"Claim reward",16,-444,306,function()a.batchWarning=nil;act(function()return A.Claim(a.selected)end)end)
  local g=CreateFrame("Frame",nil,f);f.framesPanel=g;g:SetPoint("TOPLEFT",0,-42);g:SetSize(960,508);g.selected=A.Frame();g.rows={}
  label(g,"PORTRAIT FRAMES",0,0,592,28,S.gold)
  label(g,"Choose the border other players see around your Inspect preview.",0,-32,590,44)
  for i=1,6 do
    local row=CreateFrame("Button",nil,g,"BackdropTemplate");g.rows[i]=row
    row:SetPoint("TOPLEFT",((i-1)%2)*300,-84-math.floor((i-1)/2)*118);row:SetSize(286,108)
    row:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    row:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    row.sample=rewardView(row,14,-25,58)
    row.title=label(row,"",90,-14,184,38)
    row.info=label(row,"",90,-54,184,42)
    row:SetScript("OnClick",function()if row.frameID then g.selected=row.frameID;P.state.achievements.seenFrames[row.frameID]=true;P.RenderJournal()end end)
  end
  scrollList(g,-84,344,math.max(0,math.ceil(#A.frames/2)-3))
  g.pageLabel=label(g,"Scroll to browse portrait frames",0,-466,590,28)
  local preview=S.Panel(g,622,0,338,498)
  g.title=label(preview,"",16,-12,306,42,S.gold)
  g.art=preview:CreateTexture(nil,"ARTWORK");g.art:SetPoint("TOPLEFT",22,-62);g.art:SetSize(294,268)
  g.border=P.CreatePortraitFrame(preview,g.art)
  g.help=label(preview,"",18,-346,302,74)
  g.equip=S.Button(preview,"Use frame",16,-444,306,function()act(function()return A.SelectFrame(g.selected)end)end)
  P.BuildAbilityBook(f)
end
function P.UpdateJournalNewMarkers(f)
  if not f or not rawget(f,"subButtons")then return end
  local newAchievement,newFrame=false,false
  for _,d in ipairs(A.list)do if A.IsNew(d.id)then newAchievement=true;break end end
  for i in ipairs(A.frames)do if A.FrameNew(i)then newFrame=true;break end end
  f.subButtons.achievements:SetText("Achievements"..(newAchievement and " |cff40ff40NEW|r" or ""))
  f.subButtons.frames:SetText("Frames"..(newFrame and " |cff40ff40NEW|r" or ""))
  local newPet=#P.state.finds>0
  for _,entry in pairs(P.state.collection)do if entry.isNew then newPet=true;break end end
  local newAbility=false
  for id in pairs(P.state.knownAbilities or {})do if not (P.state.seenAbilities or {})[id]then newAbility=true;break end end
  f.subButtons.collections:SetText("Pets"..(newPet and " |cff40ff40NEW|r" or ""))
  f.subButtons.abilities:SetText("Abilities"..(newAbility and " |cff40ff40NEW|r" or ""))
end
function P.RenderJournalExtras(f)
  P.UpdateJournalNewMarkers(f)
  local tab=f.subtab;if tab~="collections" and tab~="achievements" and tab~="frames" and tab~="abilities"then tab="collections";f.subtab=tab end
  f.body:SetShown(tab=="collections");f.achievementPanel:SetShown(tab=="achievements");f.framesPanel:SetShown(tab=="frames")
  f.abilityBook:SetShown(tab=="abilities")
  for key,b in pairs(f.subButtons)do b:SetEnabled(key~=tab)end
  if tab=="abilities"then P.RenderAbilityBook(f.abilityBook);return true end
  if tab=="achievements"then
    local a=f.achievementPanel;local claimed,ready=0,0;local s=P.state.achievements
    for _,d in ipairs(A.list)do if A.Settled(d)then claimed=claimed+1 elseif s.claimed[d.id] or A.Progress(d)>=d.goal then ready=ready+1 end end
    a.count:SetText(claimed.." / "..#A.list.." claimed  |  "..ready.." rewards ready")
    a.claimAll:SetEnabled(ready>0 and not P.state.battle and not A.claimingAll)
    local entries=A.Browse(a.sortMode)
    local selected=false;for _,d in ipairs(entries)do if d.id==a.selected then selected=true;break end end
    if not selected and entries[1]then a.selected=entries[1].id end
    a.details:SetShown(#entries>0)
    a.sort:SetText("Sort: "..({all="All",completed="Completed",closest="Closest"})[a.sortMode])
    a.maxOffset=math.max(0,#entries-5);a.offset=math.min(a.offset,a.maxOffset)
    a.scroll:SetMinMaxValues(0,a.maxOffset);a.scroll:SetValue(a.offset);a.scroll:SetShown(a.maxOffset>0)
    for i,row in ipairs(a.rows)do
      local d=entries[a.offset+i];row.entry=d;row:SetShown(d~=nil)
      if d then
        local n=math.min(d.goal,A.Progress(d));local achieved=s.claimed[d.id] or n>=d.goal
        row.title:SetText(d.name..(A.IsNew(d.id) and " |cff40ff40NEW|r" or ""));S.TextColor(row.title,achieved and S.gold or S.muted)
        row.icon:SetTexture("Interface\\Icons\\"..d.icon);row.icon:SetDesaturated(not achieved);row.icon:SetAlpha(achieved and 1 or 0.42)
        row.done:SetShown(achieved);row.fill:SetWidth(math.max(1,450*n/d.goal));row.fill:SetColorTexture(achieved and 0.9 or 0.3,achieved and 0.7 or 0.32,0.25,1)
        rewardArt(row.rewards,d)
        row.progress:SetText(A.Settled(d) and "Claimed" or s.claimed[d.id] and "BONUS" or n>=d.goal and "READY" or n.." / "..d.goal)
        row.desc:SetText(d.text);row:SetBackdropColor(d.id==a.selected and 0.16 or 0.055,0.08,0.09,1)
        row:SetBackdropBorderColor(unpack(n>=d.goal and S.gold or S.muted))
      end
    end
    local d=A.byID[a.selected] or A.list[1];local n=math.min(d.goal,A.Progress(d));local done=A.Settled(d);local bonus=s.claimed[d.id] and not done
    a.title:SetText(d.name);a.desc:SetText(d.text);a.reward:SetText(A.RewardText(d,A.PetKnown(d),bonus))
    a.icon:SetTexture("Interface\\Icons\\"..d.icon);a.icon:SetDesaturated(not done and n<d.goal);rewardArt(a.rewardIcons,d)
    a.status:SetText(done and "Reward claimed. This achievement stays completed." or bonus and "Bonus rewards ready. Previously received rewards are kept and will not be paid twice." or n>=d.goal and "Ready to claim. Full-stable pets go to Mail; crates need bag space." or ("Progress: "..n.." / "..d.goal..". Hover the challenge icon for tracking details."))
    if rawget(a,"batchWarning")then a.status:SetText(a.batchWarning)
    elseif not done and (bonus or n>=d.goal) and d.pet and P.StableCount()>=P.stableCapacity then a.status:SetText(F.Mailbox.CanReceive() and "Stable full: this pet will be sent to Mail." or "Stable full and Mail unavailable. Your reward will wait here.")end
    a.claim:SetText(done and "Claimed" or bonus and "Claim bonus" or "Claim rewards");a.claim:SetEnabled(not done and (bonus or n>=d.goal) and not P.state.battle)
    a.pageLabel:SetText((#entries==0 and "No matching achievements" or ((a.offset+1).."-"..math.min(#entries,a.offset+5).." of "..#entries)).."\nPvP kills: "..(s.pvpKills or 0))
  elseif tab=="frames"then
    local g=f.framesPanel;local available={}
    for index in ipairs(A.frames)do if A.FrameVisible(index)then available[#available+1]=index end end
    if not A.FrameVisible(g.selected)then g.selected=1 end
    local selected=A.frames[g.selected]
    g.maxOffset=math.max(0,math.ceil(#available/2)-3);g.offset=math.min(g.offset,g.maxOffset)
    g.scroll:SetMinMaxValues(0,g.maxOffset);g.scroll:SetValue(g.offset);g.scroll:SetShown(g.maxOffset>0)
    for i,row in ipairs(g.rows)do
      local index=available[g.offset*2+i];local d=index and A.frames[index];row.frameID=d and index or nil;row:SetShown(d~=nil)
      if d then local unlocked=A.FrameUnlocked(index)
        row.title:SetText(d.name..(A.FrameNew(index) and " |cff40ff40NEW|r" or ""));S.TextColor(row.title,unlocked and d.color or S.muted)
        row:SetBackdropBorderColor(unpack(index==g.selected and S.gold or S.muted));row:SetBackdropColor(0.05,0.07,0.08,1)
        row.sample.art:SetColorTexture(0.03,0.035,0.045,1);row.sample.border:Show();P.UpdatePortraitFrame(row.sample.border,index,not unlocked)
        row.info:SetText(index==A.Frame() and "Equipped" or unlocked and "Unlocked - preview" or ("Locked\n"..A.byID[d.achievement].name))
      end
    end
    g.pageLabel:SetText("Scroll to browse  |  "..(g.offset*2+1).."-"..math.min(#available,g.offset*2+6).." of "..#available)
    g.title:SetText(selected.name);P.ShowPetArt(g.art,P.Active() or {species=3,rarity=1,level=1,health=100})
    P.UpdatePortraitFrame(g.border,g.selected)
    g.help:SetText(selected.help or ("Unlock: "..A.byID[selected.achievement].name.."\n"..A.byID[selected.achievement].text))
    g.equip:SetText(g.selected==A.Frame() and "Equipped" or A.FrameUnlocked(g.selected) and "Use frame" or "Locked")
    g.equip:SetEnabled(A.FrameUnlocked(g.selected) and g.selected~=A.Frame())
  end
  return tab~="collections"
end
