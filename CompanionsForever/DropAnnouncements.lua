local _,F=...
local P,S=F.Pets,F.Style
local N={depth=0,queue={},nextSend=0,nextPublic={},prefix='CFDrops1',sequence=0,received={},status={},warned={},blockedChannels={},blockedContexts={}};F.DropAnnouncements=N
local function readable(v)return (not issecretvalue or not issecretvalue(v)) and (not canaccessvalue or canaccessvalue(v))end
local function party()
  local grouped=IsInGroup and IsInGroup();local raid=IsInRaid and IsInRaid()
  return readable(grouped) and readable(raid) and grouped==true and not raid
end
local function guild()
  local joined=IsInGuild and IsInGuild()
  return readable(joined) and joined==true
end
local function clean(text)
  if not readable(text) or type(text)~='string'then return ''end
  return text:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('[|%c]',' '):sub(1,160)
end
local gearNames,petNames={},{}
local gearCount,petCount=0,0
function N.RewardType(name,rarity)
  if not readable(name) or type(name)~='string' or type(rarity)~='number' or not P.rarities[rarity]then return end
  if gearCount~=#P.gearTypes then
    gearNames={};gearCount=#P.gearTypes
    for kind,d in ipairs(P.gearTypes)do gearNames[d.name]=kind end
  end
  if petCount~=#P.species then
    petNames={};petCount=#P.species
    for id,label in ipairs(P.species)do petNames[label]=id;petNames['Sparkly '..label]=id end
  end
  local prefix=P.rarities[rarity]..' '
  if name:sub(1,#prefix)~=prefix then return end
  local label=name:sub(#prefix+1)
  if gearNames[label]then return 'gear',gearNames[label]end
  if petNames[label]then return 'pet',petNames[label]end
end
function N.Color(text,rarity)
  local c=P.colors[rarity] or P.colors[1];c=S.RarityColor(c)
  local kind,id=N.RewardType(text,rarity)
  if kind=='gear'then text='|Haddon:CFGear:'..id..':'..rarity..'|h['..text..']|h'end
  return string.format('|cff%02x%02x%02x%s|r',math.floor(c[1]*255+.5),math.floor(c[2]*255+.5),math.floor(c[3]*255+.5),text)
end
local function queueGroup(event,name,rarity)
  if F.Sandbox or not F.db or #N.queue>=20 or not N.RewardType(name,rarity)then return end
  if not party() and not guild()then return end
  N.sequence=N.sequence+1
  local entry={event=event,name=name,rarity=rarity or 1,id=F.Now()..'-'..N.sequence,expires=F.Now()+60,routes={}}
  if party()then entry.routes.PARTY={attempts=0}end
  if guild()then entry.routes.GUILD={attempts=0}end
  N.last=entry
  -- Public chat must stay on the original action/event stack. A timer loses
  -- the client context and can produce ForceTaint_Strong / UNKNOWN().
  N.SendPublic(entry)
  if next(entry.routes)then N.queue[#N.queue+1]=entry;if N.frame then N.frame:Show()end end
end
function P.AnnounceChestReward(kind,title,detail,icon,species,rarity)
  if kind~='pet' and kind~='item'then return end
  local name=clean(type(detail)=='string' and detail:match('^[^\n]*') or '')
  if name~=''then queueGroup('Chest',name,rarity)end
end
function P.AnnounceReward(kind,title,detail,rarity)
  if F.Sandbox or not F.db or (kind~='pet' and kind~='item' and kind~='crate_found' and kind~='supply')then return end
  local first=type(detail)=='string' and detail:match('^[^\n]*') or ''
  local name=clean(first);if name==''then return end
  F.Print(clean(title)..' '..N.Color(name,rarity))
  if N.depth>0 then queueGroup('Drop',name,rarity)end
end
local frame=CreateFrame('Frame');N.frame=frame;frame:Hide()
function N.Register()
  if N.registered or not C_ChatInfo or not C_ChatInfo.RegisterAddonMessagePrefix then return end
  local ok,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,N.prefix)
  N.registered=ok and readable(result) and (result==true or result==0 or result==1)
end
function N.PublicChatAllowed(channel)
  -- Guild announcements use only the addon transport, never public guild chat.
  return channel=='PARTY' and not N.blockedChannels.PARTY
end
local function status(channel,message,warn)
  N.status[channel]=message
  if warn and F.Now()>=(N.warned[channel] or 0)then
    N.warned[channel]=F.Now()+60
    F.Print((channel=='GUILD' and 'Guild' or 'Party')..' announcements: '..message)
  end
end
local errors={[1]='invalid prefix',[2]='invalid message',[3]='addon throttled',[4]='invalid channel type',[5]='not in a party',
  [6]='target required',[7]='invalid channel',[8]='channel throttled',[9]='client error',[10]='not in a guild',[11]='chat lockdown',[12]='target offline'}
local function message(entry)
  return '[CF Pets] '..entry.event..' ('..(P.rarities[entry.rarity] or 'Common')..'): '..entry.name
end
function N.StatusText()
  return 'Guild notices appear in CF messages.'
    ..'\nGuild: '..(N.status.GUILD or 'No announcement yet.')..'\nParty: '..(N.status.PARTY or 'No announcement yet.')
end
function N.Draft(channel)
  if F.Sandbox or not N.last or not ChatFrame_OpenChat then return end
  if channel=='PARTY' and party()then
    -- Prepare native chat only. The player reviews it and presses Enter to send.
    ChatFrame_OpenChat('/p '..message(N.last))
  end
end
local function sendNotice(entry,channel)
  N.Register()
  if not N.registered or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    status(channel,'Unavailable: addon messaging is not registered.',true);return true
  end
  local body=entry.id..'|'..entry.event..'|'..entry.rarity..'|'..entry.name
  -- Use the client wrapper so chat hooks do not inherit this addon's taint.
  -- This does not override the client's transport restrictions.
  local ok,result
  if securecall then ok,result=pcall(securecall,C_ChatInfo.SendAddonMessage,N.prefix,body,channel)
  else ok,result=pcall(C_ChatInfo.SendAddonMessage,N.prefix,body,channel)end
  if ok and readable(result) and (result==true or result==0)then
    status(channel,'Accepted by WoW for CF delivery. Receipt not confirmed.')
    return true
  end
  if ok and readable(result) and result==nil then
    -- Legacy clients have no return code. Do not retry an unconfirmed send.
    status(channel,'Submitted to CF; this client returned no delivery status.');return true
  end
  local code=ok and readable(result) and type(result)=='number' and result or -1
  local retry=code==3 or code==8 or code==9 or code==11
  status(channel,(retry and 'Waiting to retry: ' or 'Not sent: ')..(errors[code] or 'unknown client result')..'.',not retry)
  return not retry
end
local function publicSend(send,message,entry,channel)
  N.currentPublicChannel=channel
  N.currentPublicEvent=entry.event;N.currentPublicBlocked=false
  local ok=pcall(send,message,channel)
  local blocked=N.currentPublicBlocked
  N.currentPublicChannel=nil;N.currentPublicEvent=nil;N.currentPublicBlocked=nil
  if not ok then N.blockedChannels[channel]=true end
  if blocked or N.blockedChannels[channel]then status(channel,'Public chat blocked; CF delivery queued. Share is available.');return false end
  status(channel,'Submitted to public chat.');return true
end
function N.SendPublic(entry)
  local settings=F.db.settings
  local send=C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  if not send then return end
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
    local ok,blocked=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not readable(blocked) or blocked then return end
  end
  for _,channel in ipairs({'PARTY'})do
    local blocked=N.blockedContexts[entry.event]
    if entry.routes[channel] and settings.announcePartyDrops
      and N.PublicChatAllowed(channel) and not (blocked and blocked[channel])
      and F.Now()>=(N.nextPublic[channel] or 0)then
      N.nextPublic[channel]=F.Now()+2
      if publicSend(send,message(entry),entry,channel)then entry.routes[channel]=nil end
    end
  end
end
local function flush()
  if F.Sandbox or not F.db then N.queue={};frame:Hide();return end
  local partyRoute=party()
  local guildRoute=guild()
  if not partyRoute and not guildRoute then N.queue={};frame:Hide();return end
  if #N.queue==0 then frame:Hide();return end
  if F.Now()<N.nextSend then return end
  N.nextSend=F.Now()+2
  local entry=N.queue[1]
  if entry.expires<F.Now()then
    for channel in pairs(entry.routes)do status(channel,'Not sent: announcement expired.',true)end
    table.remove(N.queue,1);if #N.queue==0 then frame:Hide()end;return
  end
  if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
    local ok,blocked=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not readable(blocked) or blocked then
      for channel in pairs(entry.routes)do status(channel,'Waiting for chat lockdown to end.')end
      return
    end
  end
  for _,channel in ipairs({'GUILD','PARTY'})do
    local route=entry.routes[channel]
    if route then
      local enabled=(channel=='GUILD' and guildRoute) or (channel=='PARTY' and partyRoute)
      if not enabled then entry.routes[channel]=nil
      else
        route.attempts=route.attempts+1
        -- Never retry public chat from OnUpdate, even after lockdown ends.
        local done=sendNotice(entry,channel)
        if not done and route.attempts>=5 then status(channel,'Not sent after 5 attempts. '..(N.status[channel] or ''),true);done=true end
        if done then entry.routes[channel]=nil end
      end
    end
  end
  if not next(entry.routes)then table.remove(N.queue,1)end
  if #N.queue==0 then frame:Hide()end
end
N.Flush=flush
frame:SetScript('OnUpdate',flush)
local announce=P.AnnounceReward
function P.AnnounceReward(...)announce(...);if #N.queue>0 then frame:Show()end end
-- Chest results send from the opening action; achievements remain local.
for _,key in ipairs({'CombatKill','HiddenDungeonKill','RollKillLoot','RollEquipmentLoot','RollCoinPouch','RollXPTreat','RollEquipmentCrateDrop','EncounterEnd','BossKill'})do
  local original=P[key]
  if original then P[key]=function(...)
    N.depth=N.depth+1
    local food=key=='CombatKill' and P.state and P.state.inventory.food
    local ok,a,b,c=pcall(original,...)
    if ok and food and P.state.inventory.food>food then P.AnnounceReward('supply','Food found!','1 Food',1)end
    N.depth=N.depth-1
    if not ok then error(a)end
    return a,b,c
  end end
end
-- Public party text has no event ID. Match it one-for-one with CF delivery,
-- in either arrival order, without hiding repeated drops on the same route.
local echoes,chatLines={},{}
local function duplicateDisplay(sender,event,rarity,name,route)
  if not F.Integrity.Safe(sender,100) or F.Inspect.IsSelf(sender)then return false end
  local key=F.Integrity.Name(sender);if not key then return false end
  local now=F.Now()
  for i=#echoes,1,-1 do if echoes[i].expires<now then table.remove(echoes,i)end end
  for i,row in ipairs(echoes)do
    if row.sender==key and row.event==event and row.rarity==rarity and row.name==name and row.route~=route then
      table.remove(echoes,i);return true
    end
  end
  if #echoes>=160 then table.remove(echoes,1)end
  echoes[#echoes+1]={sender=key,event=event,rarity=rarity,name=name,route=route,expires=now+60}
  return false
end
local function duplicateChat(sender,event,rarity,name,lineID)
  -- Filters run once for each chat frame. Reuse the decision for this line.
  local cacheable=readable(lineID) and type(lineID)=='number' and lineID>0
  local now=F.Now()
  for i=#chatLines,1,-1 do if chatLines[i].expires<now then table.remove(chatLines,i)end end
  if cacheable then
    for _,row in ipairs(chatLines)do if row.id==lineID then return row.hidden end end
  end
  local hidden=duplicateDisplay(sender,event,rarity,name,'public')
  if cacheable then
    if #chatLines>=160 then table.remove(chatLines,1)end
    chatLines[#chatLines+1]={id=lineID,hidden=hidden,expires=now+60}
  end
  return hidden
end
function N.ChatFilter(_,_,message,...)
  if not readable(message) or type(message)~='string' or #message>240 then return end
  local event,rarity,name=message:match('^%[CF Pets%] (%a+) %((%a+)%)%: ([^|%c]+)$')
  if event~='Drop' and event~='Chest'then return end
  for i=0,6 do if P.rarities[i]==rarity then
    if not N.RewardType(name,i)then return true end
    if not F.Sandbox and F.db and duplicateChat(select(1,...),event,i,name,select(10,...))then return true end
    return false,'[CF Pets] '..event..' ('..rarity..'): '..N.Color(name,i),...
  end end
end
function N.Receive(body,channel,sender)
  if F.Sandbox or not F.db
    or not readable(channel) or not ((channel=='PARTY' and party()) or (channel=='GUILD' and guild() and F.db.settings.receiveGuildDrops~=false))
    or not readable(body) or type(body)~='string' or #body>220
    or not F.Integrity.Safe(sender,100) or F.Inspect.IsSelf(sender)then return end
  local id,event,rarity,name=body:match('^(%d+%-%d+)|(%a+)|([0-6])|([^|%c]+)$')
  if not id or #id>24 or #name>160 or (event~='Drop' and event~='Chest')then return end
  if not N.RewardType(name,tonumber(rarity))then return end
  -- Only current party members may supply display-only notices. Never grant loot.
  local key=F.Integrity.Name(sender);local member=channel=='GUILD'
  if not key then return end
  local getName=NameUtil and NameUtil.GetUnmodifiedUnitFullName or GetUnitName
  if channel=='PARTY' and not getName then return end
  for i=1,channel=='PARTY' and 4 or 0 do
    local unitName=getName('party'..i,true);local unitKey=F.Integrity.Name(unitName)
    if unitKey and unitKey==key then member=true end
  end
  if not member then return end
  -- The sender uses the same event ID for both routes; keep one shared receipt.
  local count=0
  for k,record in pairs(N.received)do if (record.expires or 0)<F.Now()then N.received[k]=nil else count=count+1 end end
  if count>=80 and not N.received[key]then return end
  local record=N.received[key] or {seen={},order={},next=0};N.received[key]=record
  if record.seen[id] or F.Now()<record.next then return end
  record.next=F.Now()+1;record.expires=F.Now()+600;record.seen[id]=true;record.order[#record.order+1]=id
  if #record.order>40 then record.seen[table.remove(record.order,1)]=nil end
  if duplicateDisplay(sender,event,tonumber(rarity),name,'addon')then return end
  F.Print((channel=='GUILD' and 'Guild: ' or '')..clean(sender)..(event=='Chest' and ' opened: ' or ' found: ')..N.Color(name,tonumber(rarity)))
end
function N.GearLinkItem(link)
  if not readable(link) or type(link)~='string' or #link>60 then return end
  local kind,rarity=link:match('^addon:CFGear:(%d+):([0-6])$')
  kind,rarity=tonumber(kind),tonumber(rarity)
  local d=kind and P.gearTypes[kind]
  if not d or not rarity or rarity<(d.minRarity or 0)then return end
  return {kind=kind,rarity=rarity}
end
function N.GearLinkEnter(owner,link)
  local item=N.GearLinkItem(link);if not item or not GameTooltip then return end
  local d=P.gearTypes[item.kind];local color=S.RarityColor(P.colors[item.rarity] or S.gold)
  GameTooltip:SetOwner(owner,'ANCHOR_CURSOR');GameTooltip:ClearLines()
  GameTooltip:SetText(P.rarities[item.rarity]..' '..d.name,unpack(color))
  GameTooltip:AddLine('Companions Forever - '..(P.gearSlotNames[d.slot] or d.slot),.8,.8,.8)
  for _,key in ipairs({'hp','attack','armor','speed'})do
    if d[key]then GameTooltip:AddLine('+'..(d[key]*P.GearMultiplier(item))..' '..(key=='hp' and 'health' or key),1,1,1)end
  end
  local effect=P.GearEffect(item);if effect then GameTooltip:AddLine(effect.text,.2,1,.2,true)end
  if d.petXP then GameTooltip:AddLine('Equip: +'..d.petXP..'% pet XP.',.2,1,.2,true)end
  if d.hardTier then GameTooltip:AddLine('Hard Mode - Tier '..d.hardTier,.78,.55,1)end
  local set=d.hardSet and P.HardMode.sets[d.hardSet]
  if set then
    GameTooltip:AddLine(set.name,1,.82,0)
    GameTooltip:AddLine('2 pieces: '..set.two,.2,1,.2,true)
    GameTooltip:AddLine('4 pieces: '..set.four,.2,1,.2,true)
  end
  N.hoverOwner=owner;GameTooltip:Show()
end
function N.GearLinkLeave(owner,link)
  if N.hoverOwner==owner and N.GearLinkItem(link)then N.hoverOwner=nil;GameTooltip:Hide()end
end
local hookedChats=setmetatable({},{__mode='k'})
function N.HookChatLinks()
  for index=1,(NUM_CHAT_WINDOWS or 10)do
    local chat=_G['ChatFrame'..index]
    if chat and chat.HookScript and not hookedChats[chat]then
      hookedChats[chat]=true
      chat:HookScript('OnHyperlinkEnter',N.GearLinkEnter)
      chat:HookScript('OnHyperlinkLeave',N.GearLinkLeave)
    end
  end
end
frame:RegisterEvent('CHAT_MSG_ADDON');frame:RegisterEvent('PLAYER_LOGIN');frame:RegisterEvent('GROUP_ROSTER_UPDATE')
frame:RegisterEvent('ADDON_ACTION_BLOCKED');frame:RegisterEvent('ADDON_ACTION_FORBIDDEN')
frame:SetScript('OnEvent',function(_,event,prefix,body,channel,sender)
  if event=='PLAYER_LOGIN'then N.Register();N.HookChatLinks()
  elseif event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN'then
    if N.currentPublicChannel then
      -- The client can anonymize this as ForceTaint_Strong / UNKNOWN().
      -- Only observe blocks synchronously inside our own public send.
      N.currentPublicBlocked=true
      if readable(prefix) and type(prefix)=='string' and prefix:find('ForceTaint_Strong',1,true)then
        local event=N.currentPublicEvent
        N.blockedContexts[event]=N.blockedContexts[event] or {}
        N.blockedContexts[event][N.currentPublicChannel]=true
      else
        N.blockedChannels[N.currentPublicChannel]=true
      end
    end
  elseif event=='GROUP_ROSTER_UPDATE'then
    -- A party change must not discard a pending guild announcement.
    for i=#N.queue,1,-1 do N.queue[i].routes.PARTY=nil;if not next(N.queue[i].routes)then table.remove(N.queue,i)end end
    -- Keep shared receipts across roster changes so a later guild copy stays quiet.
    if #N.queue==0 then frame:Hide()end
  elseif readable(prefix) and prefix==N.prefix then N.Receive(body,channel,sender)end
end)
N.Register()
N.HookChatLinks()
if hooksecurefunc and FCF_OpenNewWindow then hooksecurefunc('FCF_OpenNewWindow',N.HookChatLinks)end
if hooksecurefunc and FCF_OpenTemporaryWindow then hooksecurefunc('FCF_OpenTemporaryWindow',N.HookChatLinks)end
if ChatFrame_AddMessageEventFilter then
  ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY',N.ChatFilter)
  ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY_LEADER',N.ChatFilter)
end
