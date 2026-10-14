local _,F=...
local P,I=F.Pets,F.Integrity
local D={prefix="CFNearby1",queue={},seen={},pending={},sequence=0};F.Social=D
local function now()return GetTime and GetTime() or F.Now()end
function D.Settings()
  if type(F.char.inspectFilters)~="table"then F.char.inspectFilters={}end
  local s=F.char.inspectFilters
  for _,key in ipairs({"guild","party","raid","world"})do if type(s[key])~="boolean"then s[key]=true end end
  return s
end
function D.Filter(kind)
  return D.Settings()[({Guild="guild",Party="party",Raid="raid"})[kind] or "world"]
end
local function available()
  if not F.ready or not P.state or not P.state.share or not D.Settings().world then return false end
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
    local ok,v=pcall(C_ChatInfo.InChatMessagingLockdown);if not ok or not I.Readable(v) or v then return false end
  end
  return D.registered and C_ChatInfo and C_ChatInfo.SendAddonMessage
end
local function send(body,name)
  if not available()then return false end
  if F.BackgroundWhispers then return F.BackgroundWhispers.Send(D.prefix,body,name)end
  local ok,v=pcall(C_ChatInfo.SendAddonMessage,D.prefix,body,"WHISPER",name)
  return ok and I.Readable(v) and (v==true or v==((Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success) or 0))
end
if F.BackgroundWhispers then F.BackgroundWhispers.handlers[D.prefix]=function(name)
  local key=I.Name(name);if key then D.pending[key]=nil;D.seen[key]=now()+600 end
  D.chatFailedUntil=now()+600
  if D.chatCandidate and D.chatCandidate.key==key then D.chatCandidate=nil end
end end
local function unitFlag(fn,...)
  if type(fn)~="function"then return nil end
  local ok,value=pcall(fn,...)
  return ok and I.Readable(value) and value==true
end
local function reachableName(unit)
  if not I.Safe(unit,30) or unitFlag(UnitIsPlayer,unit)~=true then return end
  if UnitExists and not unitFlag(UnitExists,unit)then return end
  if UnitIsVisible and not unitFlag(UnitIsVisible,unit)then return end
  if UnitIsConnected and not unitFlag(UnitIsConnected,unit)then return end
  -- Enemy nameplates are visible too, but are not reliable whisper recipients.
  if UnitCanCooperate and not unitFlag(UnitCanCooperate,"player",unit)then return end
  -- Forever's name utility preserves surnames and avoids disguised display names.
  local getName=NameUtil and NameUtil.GetUnmodifiedUnitFullName or GetUnitName
  if type(getName)~="function"then return end
  local ok,name=pcall(getName,unit,true)
  if ok and I.Safe(name,100)then return name end
end
function D.Observe(unit)
  if not available() or not I.Safe(unit,30)then return end
  local name=reachableName(unit);local key=I.Name(name)
  if not key or F.Inspect.IsSelf(name) or (D.seen[key] or 0)>now()then return end
  if #D.queue>=64 then return end
  local count=0;for k,expiry in pairs(D.seen)do if expiry<=now()then D.seen[k]=nil else count=count+1 end end
  if count>=128 then return end
  D.seen[key]=now()+300;D.queue[#D.queue+1]={name=name,key=key,unit=unit,expires=now()+60}
end
function D.ObserveChannel(sender,base,channelID,guid)
  if not available() or now()<(D.chatNext or 0) or now()<(D.chatFailedUntil or 0) or D.chatCandidate then return end
  if not I.Safe(sender,100) or F.Inspect.IsSelf(sender) or not I.Safe(base,100)
    or not I.Safe(guid,100) or not guid:match('^Player%-') or not I.Readable(channelID)then return end
  local label=base:lower():gsub('^%d+%.%s*','')
  local kind=(channelID==2 or label=='trade' or label:match('^trade%s+%-')) and 'TRADE'
    or (label=='global' or label=='world') and 'GLOBAL'
  if not kind then return end
  local key=I.Name(sender)
  if not key or (D.seen[key] or 0)>now()then return end
  local count=0;for k,expiry in pairs(D.seen)do if expiry<=now()then D.seen[k]=nil else count=count+1 end end
  if count>=128 then return end
  -- A single fresh speaker, never a backlog of channel members or chat text.
  D.chatCandidate={name=sender,key=key,kind=kind,expires=now()+5}
end
function D.Receive(body,channel,sender)
  if not available() or not I.Readable(channel) or channel~="WHISPER" or not I.Safe(sender,100)
    or not I.Readable(body) or type(body)~="string" or #body>80 then return end
  local op,nonce,version=body:match("^([HR])|(%d+%-%d+)|(%d+%.%d+%.%d+)$")
  if not op or #nonce>26 or #version>16 or F.Inspect.IsSelf(sender)then return end
  if op=="H"then
    if now()<(D.replyAt or 0)then return end;D.replyAt=now()+2
    send("R|"..nonce.."|"..F.version,sender);return
  end
  local key=I.Name(sender);local q=D.pending[key]
  if not q or q.nonce~=nonce or q.expires<now()then return end
  D.pending[key]=nil
  local count,oldest=0,nil
  for name,p in pairs(P.peers)do count=count+1;if not oldest or p.seen<P.peers[oldest].seen then oldest=name end end
  if count>=40 and not P.peers[sender]then P.peers[oldest]=nil end
  local peer=P.peers[sender] or {};P.peers[sender]=peer
  peer.seen=F.Now();peer.channel=peer.channel or q.kind or "WORLD";peer.version=version
  P.inspectDirectoryUntil=0
end
function D.Tick()
  if not F.ready then return end
  if not D.registered and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and now()>=(D.registerAt or 0)then
    D.registerAt=now()+30
    local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,D.prefix)
    D.registered=ok and I.Readable(v) and (v==true or v==0 or v==1)
  end
  for key,q in pairs(D.pending)do if q.expires<now()then D.pending[key]=nil end end
  if not available()then D.queue={};D.pending={};D.chatCandidate=nil;return end
  if D.chatCandidate and D.chatCandidate.expires<now()then D.chatCandidate=nil end
  if now()<(D.nextSend or 0)then return end
  local chat=D.chatCandidate
  if chat and now()>=(D.chatNext or 0) and now()>=(D.chatFailedUntil or 0)then
    D.chatCandidate=nil;D.chatNext=now()+30;D.nextSend=now()+10
    D.seen[chat.key]=now()+600;D.sequence=D.sequence+1
    local nonce=math.floor(F.Now()).."-"..D.sequence
    if send("H|"..nonce.."|"..F.version,chat.name)then
      D.pending[chat.key]={nonce=nonce,expires=now()+20,kind=chat.kind}
    else D.chatFailedUntil=now()+600 end
    return
  end
  local q=table.remove(D.queue,1)
  -- Nameplates/target/mouseover can disappear or refer to somebody else during
  -- the send delay. Never whisper a queued name without a fresh identity check.
  local current=q and q.expires>=now() and reachableName(q.unit)
  if current and I.Name(current)==q.key then
    D.nextSend=now()+10;D.sequence=D.sequence+1
    local nonce=math.floor(F.Now()).."-"..D.sequence
    if send("H|"..nonce.."|"..F.version,current)then D.pending[q.key]={nonce=nonce,expires=now()+20}end
  end
end
function D.BuildFilters(f)
  f:SetHeight(576)
  f.discoveryFilters={};f.players:ClearAllPoints();f.players:SetPoint("TOPLEFT",12,-512)
  for i,key in ipairs({"guild","party","raid","world"})do
    local b=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");f.discoveryFilters[key]=b
    b:SetSize(24,24);b:SetPoint("TOPLEFT",12+(i-1)*155,-478);b:SetChecked(D.Settings()[key])
    local t=F.Style.Text(b,key:sub(1,1):upper()..key:sub(2),26,-4,125,"GameFontHighlightSmall",F.Style.gold)
    b:SetScript("OnClick",function(self)D.Settings()[key]=not not self:GetChecked();P.inspectDirectoryUntil=0;P.RenderInspect()end)
    b:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(key=="world" and "World discovery" or "Inspect list filter");GameTooltip:AddLine(key=="world" and "Discover nearby friendly players and recent Trade/Global speakers. Only confirmed addon replies appear. Requires Sharing ON. At most six checks per minute total; chat checks at most twice per minute. Failed chat sends pause for ten minutes." or "Show confirmed addon users from this group in Inspect.",1,1,1,true);GameTooltip:Show()end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
end
function D.PendingTrade()
  local invite=F.Trades.invite
  return invite and invite.wires and not invite.incoming and P.state and not P.state.trade and invite.expires>=now() and invite
end
function D.Alerts()
  if not P.state then return end
  local pending=D.PendingTrade();local w=F.petIcon
  if w then
    if not rawget(w,"tradeAlert")then
      local b=CreateFrame("Button",nil,w,"BackdropTemplate");w.tradeAlert=b
      b:SetAllPoints();b:SetFrameLevel(w:GetFrameLevel()+5)
      b:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=3});b:SetBackdropBorderColor(1,.75,.1,1)
      b.label=F.Style.Text(b,"Pending\ntrade",2,-10,100,"GameFontNormal",F.Style.gold);b.label:ClearAllPoints();b.label:SetPoint("BOTTOMLEFT",2,6);b.label:SetPoint("BOTTOMRIGHT",-2,6);b.label:SetHeight(34);b.label:SetJustifyH("CENTER")
      b:SetScript("OnClick",function()P.OpenTrade()end)
    end
    w.tradeAlert:SetShown(not not pending)
    if pending then w.tradeAlert:SetAlpha(F.db.settings.reduceMotion and 1 or .55+.45*math.abs(math.sin(now()*3)))end
  end
  local f=P.inspect
  if f and rawget(f,"players")then for _,b in ipairs(f.players.rows)do
    if not rawget(b,"tradePulse")then b.tradePulse=b:CreateTexture(nil,"OVERLAY");b.tradePulse:SetAllPoints();b.tradePulse:SetColorTexture(1,.7,.1,.45)end
    local show=pending and b.contact and (F.Inspect.IsSelf(b.contact.name) or I.Name(b.contact.name)==I.Name(pending.peer))
    b.tradePulse:SetShown(not not show);if show then b.tradePulse:SetAlpha(F.db.settings.reduceMotion and .7 or .2+.8*math.abs(math.sin(now()*3)))end
  end end
end
local frame=CreateFrame("Frame");D.frame=frame
for _,event in ipairs({"CHAT_MSG_ADDON","CHAT_MSG_CHANNEL","NAME_PLATE_UNIT_ADDED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT"})do frame:RegisterEvent(event)end
frame:SetScript("OnEvent",function(_,event,p,body,channel,sender,...)
  if event=="CHAT_MSG_ADDON"then if I.Readable(p) and p==D.prefix then D.Receive(body,channel,sender)end
  elseif event=="CHAT_MSG_CHANNEL"then
    local _,_,channelID,_,base,_,_,guid=...
    D.ObserveChannel(body,base,channelID,guid)
  elseif event=="NAME_PLATE_UNIT_ADDED"then D.Observe(p)
  else D.Observe(event=="PLAYER_TARGET_CHANGED" and "target" or "mouseover")end
end)
local elapsed=0
frame:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0;D.Tick();D.Alerts()end)
