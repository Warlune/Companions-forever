local _,F=...
local E={};F.Errors=E
-- Explicit report recipient; never learn a destination from incoming messages.
E.collector={name="War Lune",realm="Classic Beta PvP 2",faction="Horde"}
local prefix="CFErrors1"
local frame=CreateFrame("Frame");E.frame=frame
local registered,installed,handling=false,false,false
local nonce,readyUntil,helloUntil,nextHello,nextSend,pending=nil,0,0,0,0,nil
local helloRetryAt=0
local sessions={};local replySecond,replyCount=0,0;local sequence=0
local function readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
local function plain(v,limit)
  return readable(v) and type(v)=="string" and #v<=limit and not v:find("[|%c]")
end
local function normal(v)
  return plain(v,100) and v:lower():gsub("[%s%-]","") or ""
end
local function enabled()return F.db and F.db.settings.shareErrors==true end
local function now()return F.Now()end
local function allowReply(stamp)
  if stamp~=replySecond then replySecond=stamp;replyCount=0 end
  if replyCount>=8 then return false end
  replyCount=replyCount+1;return true
end
function E.Destination()
  local realm
  if GetNormalizedRealmName then realm=GetNormalizedRealmName()elseif GetRealmName then realm=GetRealmName()end
  local faction=UnitFactionGroup and UnitFactionGroup("player")
  if readable(faction) and faction==E.collector.faction and normal(realm)==normal(E.collector.realm)then return E.collector end
end
function E.IsCollector()
  if not E.Destination() or not UnitName then return false end
  local name,surname=UnitName("player")
  if not plain(name,100) then return false end
  if normal(name)==normal(E.collector.name) then return true end
  -- Forever returns first name and surname separately, not name and realm.
  return plain(surname,100) and normal(name.." "..surname)==normal(E.collector.name) or false
end
local function fromCollector(sender)
  return normal(sender)==normal(E.collector.name) or normal(sender)==normal(E.collector.name.."-"..E.collector.realm)
end
local function number(s,max)
  local n=tonumber(s);return n and n==n and n>=0 and n<=max and n==math.floor(n)
end
function E.Parse(body)
  if not readable(body) or type(body)~="string" or #body>214 or body:find("%c")then return end
  local version,build,file,line,summary=body:match("^(%d+%.%d+%.%d+)|(%d+)|([%w_]+%.lua)|(%d+)|([^|]+)$")
  if not version or #version>16 or #file>40 or #summary>128 or not number(build,99999999) or not number(line,999999)then return end
  return version,build,file,line,summary
end
local function retiredTest(body)
  local _,_,file,line,summary=E.Parse(body)
  return file=="Errors.lua" and line=="0" and summary=="TEST: automatic delivery check delivery-20261009. Not a Lua error."
end
local function trim(rows,limit,inbox)
  local kept={}
  if type(rows)=="table"then
    -- Bound work even if a saved table is much larger than our own limits.
    for i=math.max(1,#rows-limit+1),#rows do
      local row=rows[i]
      if type(row)=="table" and plain(row.id,24) and row.id:match("^%d+%-%d+$") and E.Parse(row.body) and not retiredTest(row.body)
        and type(row.time)=="number" and row.time>=now()-604800 and row.time<=now()+60
        and (not inbox or plain(row.sender,100))then kept[#kept+1]=row end
    end
  end
  return kept
end
function E.OutgoingBlocked()
  -- A realm capability flag is not proof that this whisper will fail.
  -- Respect active lockdown, then require the send result and peer reply.
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
    local ok,restricted=pcall(C_ChatInfo.InChatMessagingLockdown)
    return not ok or not readable(restricted) or restricted
  end
  return false
end
local function send(body,target)
  if not registered or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then E.lastSendError="Report messaging unavailable; reload.";return false end
  if E.OutgoingBlocked()then E.lastSendError="Active messaging lockdown; reports kept for retry.";return false end
  local ok,result
  if F.BackgroundWhispers then
    local accepted;accepted,result=F.BackgroundWhispers.Send(prefix,body,target)
    ok=accepted or result~=nil
  else ok,result=pcall(C_ChatInfo.SendAddonMessage,prefix,body,"WHISPER",target)end
  local outcomes=Enum and Enum.SendAddonMessageResult
  if ok and readable(result) and (result==true or result==(outcomes and outcomes.Success or 0))then E.lastSendError=nil;return true end
  if ok and readable(result) and type(result)=="number"then
    if result==(outcomes and outcomes.TargetOffline or 12)then E.lastSendError="Recipient offline; reports kept for retry."
    elseif result==(outcomes and outcomes.AddOnMessageLockdown or 11)then E.lastSendError="WoW rejected the send during lockdown; reports kept."
    elseif outcomes and (result==outcomes.AddonMessageThrottle or result==outcomes.ChannelThrottle)then E.lastSendError="WoW throttled delivery; reports kept for retry."
    else E.lastSendError="WoW rejected the send ("..result.."); reports kept."end
  else E.lastSendError="Send not confirmed; reports kept for retry."end
  return false
end
if F.BackgroundWhispers then F.BackgroundWhispers.handlers[prefix]=function()
  readyUntil=0;helloUntil=0;helloRetryAt=0;nextHello=now()+600
  E.lastSendError="Recipient offline; reports kept for retry."
end end
function E.Capture(message)
  if not F.db or not readable(message) or type(message)~="string"then return end
  message=message:sub(1,2048)
  local file,line,summary=message:match('CompanionsForever[/\\]([%w_]+%.lua)["%]]*:(%d+):%s*(.*)')
  if not file then return end
  -- No locals, chat, stack dumps, links or quoted runtime values in reports.
  summary=summary:gsub("'[^']*'","'<value>'"):gsub('"[^"]*"','"<value>"'):gsub("[|%c]"," "):sub(1,128)
  local build="0";if GetBuildInfo then build=select(2,GetBuildInfo())end
  if not readable(build) or not number(build,99999999)then build="0"end
  local body=table.concat({F.version,build,file,line,summary},"|")
  if not E.Parse(body)then return end
  local rows=F.db.companionErrors
  if type(rows)~="table"then rows={};F.db.companionErrors=rows end
  for _,row in ipairs(rows)do
    if row.body==body then row.count=math.min(9999,(row.count or 1)+1);return end
  end
  -- At most 30 distinct local errors; a storm cannot grow memory or its queue.
  if #rows>=30 then return end
  sequence=sequence+1
  local row={id=now().."-"..sequence,time=now(),body=body,count=1}
  rows[#rows+1]=row
  if enabled() and E.Destination() and not E.IsCollector()then
    local queue=F.db.companionErrorOutbox or {};F.db.companionErrorOutbox=queue
    if #queue<30 then queue[#queue+1]={id=row.id,time=row.time,body=body}end
  end
end
function E.Initialize()
  if not F.db then return end
  F.db.companionErrorDeliveryTests=nil
  F.db.companionErrors=trim(F.db.companionErrors,30)
  F.db.companionErrorOutbox=enabled() and trim(F.db.companionErrorOutbox,30) or nil
  F.db.companionErrorInbox=trim(F.db.companionErrorInbox,100,true)
  if enabled() and F.db.settings.betaDiagnosticsDefault and not F.db.companionErrorBetaQueued then
    F.db.companionErrorBetaQueued=true
    if E.Destination() and not E.IsCollector()then
      local queue=F.db.companionErrorOutbox or {};F.db.companionErrorOutbox=queue
      local queued={};for _,row in ipairs(queue)do queued[row.id]=true end
      for _,row in ipairs(F.db.companionErrors)do
        if #queue<30 and not queued[row.id]then queue[#queue+1]={id=row.id,time=row.time,body=row.body};queued[row.id]=true end
      end
    end
  end
  for _,row in ipairs(F.db.companionErrors)do
    row.count=number(row.count,9999) and tonumber(row.count) or 1
    sequence=math.max(sequence,tonumber(row.id:match("%-(%d+)$")) or 0)
  end
  for _,row in ipairs(F.db.companionErrorOutbox or {})do sequence=math.max(sequence,tonumber(row.id:match("%-(%d+)$")) or 0)end
  if not registered and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,prefix)
    local outcomes=Enum and Enum.RegisterAddonMessagePrefixResult
    registered=ok and readable(result) and (result==true or result==(outcomes and outcomes.Success or 0) or result==(outcomes and outcomes.DuplicatePrefix or 1))
  end
  if not installed and geterrorhandler and seterrorhandler then
    local previous=geterrorhandler()
    if type(previous)=="function"then
      seterrorhandler(function(message,...)
        if not handling then
          handling=true;pcall(E.Capture,message);handling=false
        end
        -- Preserve Blizzard/BugSack/other existing error handlers and arguments.
        return previous(message,...)
      end)
      installed=true
    end
  end
end
function E.SetEnabled(value)
  F.db.settings.shareErrors=value==true
  nonce=nil;readyUntil=0;helloUntil=0;helloRetryAt=0;pending=nil
  -- Retain the throttle when toggled, so repeated clicks cannot spam whispers.
  E.Initialize()
end
function E.Receive(body,channel,sender)
  if not F.db or not registered or not readable(channel) or channel~="WHISPER"
    or not plain(sender,100) or #sender==0 or not readable(body) or type(body)~="string" or #body>254 or body:find("%c")then return end
  local op,token,rest=body:match("^([HRDA])|(%d+)|?(.*)$")
  if not op or #token>10 then return end
  local stamp=now()
  if E.IsCollector()then
    if op=="H" and rest==""then
      local count=0
      for name,session in pairs(sessions)do
        if stamp>session.expires then sessions[name]=nil else count=count+1 end
      end
      local existing=sessions[sender]
      if existing and stamp<(existing.nextHello or 0) or not existing and count>=40 or not allowReply(stamp)then return end
      if send("R|"..token,sender)then
        if existing and existing.token==token then existing.nextHello=stamp+5
        else sessions[sender]={token=token,expires=stamp+120,received=0,next=0,nextHello=stamp+5}end
      end
    elseif op=="D"then
      local session=sessions[sender]
      if not session or session.token~=token or stamp>session.expires or stamp<session.next then return end
      local id,report=rest:match("^([%d-]+)|(.+)$")
      if not id or #id>24 or not id:match("^%d+%-%d+$") or not E.Parse(report)then return end
      -- Acknowledge old clients' retired probes so they stop retrying, but
      -- never store or announce them as errors. Keep normal reply throttles.
      if retiredTest(report)then
        if allowReply(stamp)then session.next=stamp+5;send("A|"..token.."|"..id,sender)end
        return
      end
      local inbox=F.db.companionErrorInbox
      local found=false
      for _,row in ipairs(inbox)do if row.id==id and row.sender==sender then found=true;break end end
      if not found and session.received>=5 or not allowReply(stamp)then return end
      session.next=stamp+5
      if not found then
        session.received=session.received+1
        if #inbox>=100 then table.remove(inbox,1)end
        inbox[#inbox+1]={id=id,time=stamp,body=report,sender=sender}
        if stamp>=(E.nextNotice or 0)then
          E.nextNotice=stamp+60;F.Print("New companion error report. Settings > Error reports, or /cfpets errors.")
        end
      end
      send("A|"..token.."|"..id,sender)
    end
  elseif enabled() and E.Destination() and fromCollector(sender) and token==nonce then
    if op=="R" and rest=="" and stamp<=helloUntil then readyUntil=stamp+110;helloUntil=0;helloRetryAt=0
    elseif op=="A" and stamp<=readyUntil and rest==pending then
      local queue=F.db.companionErrorOutbox or {}
      if queue[1] and queue[1].id==rest then
        table.remove(queue,1);pending=nil
      end
    end
  end
end
function E.Tick()
  if not enabled() or not E.Destination() or E.IsCollector()then return end
  -- Do not burn the ten-minute handshake interval during realm lockdown.
  if E.OutgoingBlocked()then return end
  local stamp=now();local queue=F.db.companionErrorOutbox
  if not queue or #queue==0 then return end
  -- Destination already requires the same realm; keep Forever's full surname.
  local target=E.collector.name
  if stamp>=nextHello and stamp>readyUntil then
    F.db.companionErrorOutbox=trim(queue,30)
    if #F.db.companionErrorOutbox==0 then return end
    nonce=tostring(math.random(100000,999999));helloUntil=0
    if send("H|"..nonce,target)then nextHello=stamp+600;helloUntil=stamp+30;helloRetryAt=stamp+10
    else nextHello=stamp+30;nonce=nil end
  elseif nonce and helloRetryAt>0 and stamp>=helloRetryAt and stamp<=helloUntil then
    -- One bounded retry recovers a lost readiness response within this probe.
    helloRetryAt=0;send("H|"..nonce,target)
  elseif nonce and stamp<=readyUntil and stamp>=nextSend then
    nextSend=stamp+30;pending=queue[1].id
    send("D|"..nonce.."|"..pending.."|"..queue[1].body,target)
  end
end
function E.Export()
  local lines={"Companions Forever error reports", "Incoming reports are player-supplied diagnostics, not verified game state."}
  for _,group in ipairs({{name="LOCAL",rows=F.db.companionErrors},{name="RECEIVED",rows=F.db.companionErrorInbox}})do
    for _,row in ipairs(group.rows or {})do
      local version,build,file,line,summary=E.Parse(row.body)
      if version then lines[#lines+1]=string.format("\n%s %s | time %s | v%s | build %s | x%s\n%s:%s: %s",
        group.name,row.sender or "this client",row.time,version,build,row.count or 1,file,line,summary)end
    end
  end
  if #lines==2 then lines[#lines+1]="\nNo reports recorded yet."end
  return table.concat(lines,"\n")
end
function E.Refresh()
  if not E.panel then return end
  E.check:SetChecked(enabled())
  E.status:SetText(not registered and "Report messaging unavailable; reload to register the receiver."
    or E.IsCollector() and (E.OutgoingBlocked() and "Receiver paused: WoW blocks outgoing handshakes/acknowledgements. Reports cannot be confirmed." or E.lastSendError or ("Receiver active: "..#F.db.companionErrorInbox.." reports"))
    or not enabled() and "Automatic sharing off"
    or not E.Destination() and "Sharing paused: different realm or faction"
    or E.OutgoingBlocked() and (#(F.db.companionErrorOutbox or {}).." queued; WoW currently blocks outgoing addon messages")
    or (#(F.db.companionErrorOutbox or {}).." queued; "..(E.lastSendError or (now()<=readyUntil and "receiver connected; awaiting delivery acknowledgement" or "waiting for War Lune; both players must be online"))))
  E.edit:SetText(E.Export());E.edit:SetCursorPosition(0)
end
function E.BuildSettings(parent)
  local S=F.Style;local panel=S.Panel(parent,566,-54,376,484);E.panel=panel
  S.Text(panel,"Error reports",12,-12,350,"GameFontNormalLarge",S.gold)
  local check=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate");E.check=check
  check:SetPoint("TOPLEFT",8,-42);check:SetSize(26,26)
  S.Text(panel,"Share errors with War Lune",40,-48,320,"GameFontHighlight")
  check:SetScript("OnClick",function(self)E.SetEnabled(not not self:GetChecked());E.Refresh()end)
  local description=S.Text(panel,"Error sharing defaults on: addon version, build, file/line and short error text. Your character name is visible. No chat, locals or save data. Off clears unsent reports.",12,-82,348,"GameFontHighlightSmall",S.muted)
  description:SetHeight(104)
  E.status=S.Text(panel,"",12,-194,350,"GameFontHighlightSmall",S.gold);E.status:SetHeight(76)
  local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",12,-276);scroll:SetSize(326,152)
  local edit=CreateFrame("EditBox",nil,scroll);E.edit=edit
  -- This EditBox does not inherit Blizzard's scrolling input template.
  -- Initialize its cursor state before SetText can invoke the scrolling helper.
  edit.cursorOffset=0;edit.cursorHeight=0;edit.handleCursorChange=false
  edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject("GameFontHighlightSmall");edit:SetSize(322,152)
  edit:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
  edit:SetScript("OnCursorChanged",function(self,_,y,_,height)
    self.cursorOffset=y or 0;self.cursorHeight=height or 0;self.handleCursorChange=true
  end)
  edit:SetScript("OnUpdate",function(self,elapsed)
    if self.handleCursorChange and ScrollingEdit_OnUpdate then ScrollingEdit_OnUpdate(self,elapsed,scroll)end
  end)
  edit:SetScript("OnTextChanged",function(self)if ScrollingEdit_OnTextChanged then ScrollingEdit_OnTextChanged(self,scroll)end end)
  scroll:SetScrollChild(edit)
  S.Button(panel,"Refresh",12,-444,104,E.Refresh)
  S.Button(panel,"Select / copy",124,-444,160,function()E.Refresh();edit:SetFocus();edit:HighlightText()end)
  panel:SetScript("OnShow",E.Refresh);E.Refresh()
end
function E.Command(command)
  if command=="on" or command=="off"then E.SetEnabled(command=="on")end
  F.OpenSettings();if F.settings.showSettingsSection then F.settings.showSettingsSection("errors")end;E.Refresh()
end
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,_,p,body,channel,sender)
  if readable(p) and p==prefix then E.Receive(body,channel,sender)end
end)
local elapsed=0
frame:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0;E.Tick()
end)
