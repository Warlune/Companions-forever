local _,F=...
local P,S,M,A=F.Pets,F.Style,F.Mailbox,F.AccountSave
local ink={.22,.13,.07}
local function pulseMail(self,elapsed)
  if F.db.settings.reduceMotion then self:SetAlpha(1);return end
  self.pulseTime=(self.pulseTime+elapsed)%1.8
  local minimum=S.HighContrast() and .8 or .6
  self:SetAlpha(minimum+(1-minimum)*(.5+.5*math.cos(self.pulseTime*math.pi*2/1.8)))
end
local function mailIndicator(parent,mini,hasNew)
  local badge=rawget(parent,"mailIndicator")
  if not badge then
    badge=CreateFrame("Frame",nil,parent,"BackdropTemplate");parent.mailIndicator=badge
    badge:EnableMouse(false)
    badge:SetSize(mini and 24 or 30,mini and 24 or 30)
    badge:SetPoint("TOPLEFT",parent,"TOPLEFT",mini and 4 or 8,mini and -4 or -8)
    badge:SetFrameLevel(parent:GetFrameLevel()+12)
    badge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});badge:SetBackdropColor(0,0,0,1)
    badge.icon=badge:CreateTexture(nil,"ARTWORK");badge.icon:SetPoint("TOPLEFT",1,-1);badge.icon:SetPoint("BOTTOMRIGHT",-1,1)
    badge.icon:SetTexture("Interface\\Icons\\INV_Letter_15")
    badge.pulseTime=0
  end
  badge:SetShown(hasNew)
  badge:SetScript("OnUpdate",hasNew and not F.db.settings.reduceMotion and pulseMail or nil)
  if not hasNew or F.db.settings.reduceMotion then badge.pulseTime=0;badge:SetAlpha(1)end
end
local function updateMailMarkers()
  if not P.state then return end
  local hasNew=M.Count()>0 or M.Unread()>0 or #(P.state.finds or {})>0 or P.WaitingLootCount()>0
  local unread=M.HasUnreadMail()
  local label=hasNew and "Mail |cff33ff33NEW|r" or "Mail"
  for _,key in ipairs({"window","mini"})do
    local view=P[key];local button=view and rawget(view,"mailButton")
    if button then button:SetText(label)end
    local scene=view and rawget(view,"scene")
    local tower=(key=="mini" and P.miniMode=="tower") or (key=="window" and P.mode=="tower")
    if scene then mailIndicator(scene,false,unread and not tower)end
  end
  if F.petIcon then mailIndicator(F.petIcon,true,unread)end
  if F.NativeUI and F.NativeUI.CompactTabs then F.NativeUI.CompactTabs()end
end
local function position(frame,x,y,w,h)
  frame:ClearAllPoints();frame:SetPoint("TOPLEFT",x,y);frame:SetSize(w,h)
end
function M.Close()
  if M.page then M.page:Hide();M.page.selected=nil end
  M.host=nil
end
local function choose(entry)
  M.page.selected=entry;M.page.status:SetText("");M.page.scroll:SetVerticalScroll(0)
  M.MarkEntryRead(entry)
  M.Render()
end
function M.Build(parent)
  if M.page then return end
  local page=S.Panel(parent,0,0,320,420);M.page=page
  page:EnableMouse(true);page.offset=0
  local seal=page:CreateTexture(nil,"ARTWORK");seal:SetTexture("Interface\\Icons\\INV_Letter_15");position(seal,12,-10,28,28)
  page.title=S.Text(page,"Mailbox",48,-13,200,"GameFontNormalLarge",S.gold)
  page.close=S.Button(page,"X",278,-8,28,M.Close)
  page.heading=S.Text(page,"Inbox",14,-48,240,"GameFontNormal",S.gold)
  page.rows={}
  for i=1,6 do
    local row=CreateFrame("Button",nil,page);page.rows[i]=row;row:SetHeight(52)
    row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetColorTexture(.08,.06,.03,.9)
    row.rule=row:CreateTexture(nil,"BORDER");row.rule:SetPoint("BOTTOMLEFT");row.rule:SetPoint("BOTTOMRIGHT");row.rule:SetHeight(1);row.rule:SetColorTexture(.5,.4,.2,1)
    row.hover=row:CreateTexture(nil,"BORDER");row.hover:SetAllPoints();row.hover:SetColorTexture(.7,.5,.14,.24);row:SetHighlightTexture(row.hover,"BLEND")
    row.icon=row:CreateTexture(nil,"ARTWORK");position(row.icon,6,-8,34,34)
    row.subject=S.Text(row,"",48,-6,232,"GameFontNormal",S.gold);row.subject:SetMaxLines(1)
    row.sender=S.Text(row,"",48,-28,232,"GameFontHighlightSmall",S.muted);row.sender:SetMaxLines(1)
    row:SetScript("OnClick",function()if row.entry then choose(row.entry)end end)
    row:SetScript("OnEnter",function()
      if not row.entry then return end
      GameTooltip:SetOwner(row,"ANCHOR_LEFT");GameTooltip:SetText(row.entry.subject)
      GameTooltip:AddLine(row.entry.sender,1,1,1,true);GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  page.prev=S.Button(page,"<",14,-382,32,function()page.offset=math.max(0,page.offset-page.visibleRows);M.Render()end)
  page.next=S.Button(page,">",274,-382,32,function()page.offset=math.min(math.max(0,M.InboxCount()-page.visibleRows),page.offset+page.visibleRows);M.Render()end)
  page.total=S.Text(page,"",54,-389,206,"GameFontHighlightSmall");page.total:SetJustifyH("CENTER")
  page.letter=CreateFrame("Frame",nil,page);local letter=page.letter
  letter.stationery=letter:CreateTexture(nil,"BACKGROUND");letter.stationery:SetAllPoints()
  letter.stationery:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
  page.subject=S.Text(letter,"",12,-12,264,"GameFontNormal",ink);page.subject:SetHeight(44);page.subject:SetMaxLines(2)
  page.sender=S.Text(letter,"",12,-58,264,"GameFontHighlightSmall",ink);page.sender:SetMaxLines(1)
  page.scroll=CreateFrame("ScrollFrame",nil,letter,"UIPanelScrollFrameTemplate");page.scroll:EnableMouseWheel(true)
  page.content=CreateFrame("Frame",nil,page.scroll);page.scroll:SetScrollChild(page.content)
  page.body=S.Text(page.content,"",0,0,264,"GameFontHighlight",ink)
  page.attachments={}
  for i=1,6 do
    local slot=CreateFrame("Button",nil,page.content,"BackdropTemplate");page.attachments[i]=slot
    slot:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    slot:SetBackdropColor(0,0,0,1)
    slot.icon=slot:CreateTexture(nil,"ARTWORK");slot.icon:SetPoint("TOPLEFT",3,-3);slot.icon:SetPoint("BOTTOMRIGHT",-3,3)
    slot.count=S.Text(slot,"1",2,-24,36,"GameFontHighlightSmall",{1,1,1});slot.count:SetJustifyH("RIGHT")
    slot:SetScript("OnEnter",function(self)
      local attachment=self.attachment;if not attachment then return end
      GameTooltip:SetOwner(self,"ANCHOR_LEFT")
      GameTooltip:SetText(attachment.name,unpack(S.RarityColor(P.colors[attachment.rarity] or S.gold)))
      GameTooltip:AddLine(attachment.description,1,1,1,true)
      GameTooltip:AddLine("Use Collect below to take this mail's attachments.",1,.82,0,true);GameTooltip:Show()
    end)
    slot:SetScript("OnLeave",function()GameTooltip:Hide()end)
    slot:Hide()
  end
  page.scroll:SetScript("OnMouseWheel",function(self,delta)
    self:SetVerticalScroll(math.max(0,math.min(page.scrollRange or 0,(self:GetVerticalScroll() or 0)-delta*36)))
  end)
  page.status=S.Text(page,"",14,-338,288,"GameFontHighlightSmall",S.gold);page.status:SetHeight(38)
  page.back=S.Button(page,"Inbox",14,-382,88,function()page.selected=nil;page.status:SetText("");M.Render()end)
  page.collect=S.Button(page,"Collect",112,-382,194,function()
    local ok,result=M.Collect(rawget(page,"selected"))
    page.status:SetText(type(result)=="string" and result or ok and "Collected." or "Make room first.")
    if ok then page.selected=nil end
    P.Render();M.Render()
  end)
  page.delete=S.Button(page,"Delete mail",14,-350,292,function()
    local ok,result=M.Delete(rawget(page,"selected"));page.status:SetText(result)
    if ok then page.selected=nil end
    P.Render();M.Render()
  end)
  page:EnableMouseWheel(true);page:SetScript("OnMouseWheel",function(_,delta)
    if rawget(page,"selected")then
      page.scroll:SetVerticalScroll(math.max(0,math.min(page.scrollRange or 0,(page.scroll:GetVerticalScroll() or 0)-delta*36)))
      return
    end
    page.offset=math.max(0,math.min(math.max(0,M.InboxCount()-page.visibleRows),page.offset-delta));M.Render()
  end)
  page:SetScript("OnHide",function()GameTooltip:Hide()end)
  page:Hide()
end
function M.Render()
  updateMailMarkers()
  local page=M.page;if not page or not M.host or not page:IsShown()then return end
  local width=math.min(340,M.host:GetWidth()-16)
  local height=math.min(460,M.host:GetHeight()-100)
  local mail=rawget(M.host,"mailButton")
  if mail and not rawget(mail,"cfSideTab")then
    local hostTop,mailTop=M.host:GetTop(),mail:GetTop()
    if type(hostTop)=="number" and type(mailTop)=="number" and hostTop-mailTop>100 then
      height=math.min(height,hostTop-mailTop-52)
    end
  end
  local font=math.max(12,S.MinimumTextSize());local rowHeight=math.max(52,font*2+20)
  page:SetSize(width,height);page:SetFrameLevel(M.host:GetFrameLevel()+60)
  page.close:ClearAllPoints();page.close:SetPoint("TOPRIGHT",-10,-8)
  local total=M.InboxCount();page.visibleRows=math.max(1,math.min(6,math.floor((height-154)/rowHeight)))
  page.offset=math.max(0,math.min(math.max(0,total-page.visibleRows),page.offset))
  local selected=rawget(page,"selected");local high=S.HighContrast()
  local attachments=M.Attachments(selected)
  local columns=math.max(1,math.floor((width-64)/48))
  page.attachmentOffset=#attachments>0 and math.ceil(#attachments/columns)*48+4 or 0
  for i,slot in ipairs(page.attachments)do
    local attachment=attachments[i];slot.attachment=attachment;slot:SetShown(attachment~=nil)
    if attachment then
      position(slot,((i-1)%columns)*48,-math.floor((i-1)/columns)*48,42,42)
      slot.icon:SetTexture("Interface\\Icons\\"..attachment.icon)
      slot.count:SetText(attachment.count)
      slot:SetBackdropBorderColor(unpack(S.RarityColor(P.colors[attachment.rarity] or S.gold)))
    end
  end
  page.heading:SetText(selected and "Letter" or "Inbox")
  for i,row in ipairs(page.rows)do
    local entry=i<=page.visibleRows and M.InboxEntry(page.offset+i)
    row.entry=entry;row:SetShown(not selected and entry~=nil and entry~=false)
    if entry then
      position(row,12,-70-(i-1)*rowHeight,width-24,rowHeight)
      row.subject:SetWidth(width-82);row.sender:SetWidth(width-82)
      row.subject:SetText((entry.unread and "* " or "")..entry.subject)
      row.sender:SetText(entry.sender..(M.HasAttachments(entry) and " - Attachment" or ""))
      row.icon:SetTexture("Interface\\Icons\\"..(entry.icon or "INV_Letter_15"))
      row.bg:SetColorTexture(high and .015 or .08,high and .015 or .06,high and .015 or .03,1)
      S.TextColor(row.subject,entry.unread and S.gold or {1,.94,.8})
    end
  end
  position(page.prev,14,-height+36,32,26);position(page.next,width-46,-height+36,32,26)
  position(page.total,50,-height+31,width-100,22)
  page.prev:SetShown(not selected);page.next:SetShown(not selected);page.total:SetShown(not selected)
  page.prev:SetEnabled(page.offset>0);page.next:SetEnabled(page.offset+page.visibleRows<total)
  page.total:SetText(total==0 and "No mail" or (page.offset+1).."-"..math.min(total,page.offset+page.visibleRows).." of "..total)
  page.letter:SetShown(selected~=nil);page.back:SetShown(selected~=nil);page.collect:SetShown(M.HasAttachments(selected)==true)
  page.delete:SetShown(selected~=nil);page.delete:SetEnabled(M.CanDelete(selected))
  position(page.delete,14,-height+68,width-28,26)
  position(page.status,14,-height+110,width-28,38)
  position(page.back,14,-height+36,82,26);position(page.collect,102,-height+36,width-116,26)
  if selected then
    position(page.letter,12,-68,width-24,height-182)
    page.letter.stationery:SetShown(not high)
    page.subject:SetText(selected.subject);page.subject:SetWidth(width-48)
    page.sender:SetText("From: "..selected.sender);page.sender:SetWidth(width-48)
    position(page.scroll,12,-82,width-64,height-276)
    page.body:ClearAllPoints();page.body:SetPoint("TOPLEFT",0,-page.attachmentOffset)
    page.body:SetHeight(0);page.body:SetText(selected.body.."\n\n");page.body:SetWidth(width-68)
    local bodyHeight=math.max(height-276,(page.body:GetStringHeight() or 240)+8)
    page.body:SetHeight(bodyHeight);page.content:SetSize(width-64,bodyHeight+page.attachmentOffset)
    page.scrollRange=math.max(0,bodyHeight+page.attachmentOffset-(height-276))
    for _,label in ipairs({page.subject,page.sender,page.body})do S.TextColor(label,ink)end
    page.collect:SetEnabled(not P.state.battle and not P.state.trade)
  end
end
function M.Open(letterID)
  if type(letterID)~="string"then letterID=nil end
  local host=F.compass and F.compass:IsShown() and P.mini or P.window
  if not host or not host:IsShown()then P.OpenPage(P.mode=="mailbox" and "collection" or P.mode or "collection");host=P.window end
  if M.page and M.page:IsShown() and M.host==host and not letterID then M.Close();return end
  M.Build(host);local page=M.page;M.host=host;page:SetParent(host)
  if P.supplyTrays then for _,tray in ipairs(P.supplyTrays)do tray:Hide()end end
  page:ClearAllPoints();page:SetPoint("TOPRIGHT",host,"TOPRIGHT",-8,-44)
  page.selected=nil;page.status:SetText("");page:Show()
  if letterID then for i=1,M.InboxCount()do local letter=M.InboxEntry(i)
    if letter.id==letterID then choose(letter);break end
  end end
  M.Render()
end
local openPage=P.OpenPage
function P.OpenPage(mode)
  if mode=="mail" or mode=="mailbox"then return M.Open()end
  M.Close();return openPage(mode)
end
local function mailTip(button)
  button:SetScript("OnEnter",function()
    GameTooltip:SetOwner(button,"ANCHOR_LEFT");GameTooltip:SetText("Mailbox")
    GameTooltip:AddLine(M.Count().." attachments and "..M.Unread().." unread announcements.\nClick again to close. Deliveries never expire.",1,1,1,true);GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local build=P.BuildUI
function P.BuildUI()
  build();local w=P.window
  if w and not rawget(w,"mailButton")then w.mailButton=S.Button(w,"Mail",680,-704,108,M.Open);mailTip(w.mailButton)end
end
local compact=P.BuildCompass
function P.BuildCompass(parent)
  compact(parent);local m=P.mini
  m.notice:SetWidth(64);m.mailButton=S.Button(m.footer,"Mail",80,-321,88,M.Open);mailTip(m.mailButton)
end
local render=P.Render
function P.Render()
  render();M.Render()
end
local renderPetIcon=F.RenderPetIcon
function F.RenderPetIcon()
  renderPetIcon();updateMailMarkers()
end
function A.ShowNotice(force)
  if force then M.Open("sharing")end
end
