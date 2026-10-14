local _,F=...
local P,I=F.Pets,F.Integrity
local G={prefix="CFParty1",seen={},seconds={}};P.PartyRewards=G
local function now()return GetTime and GetTime() or F.Now()end
local function flag(fn,...)
 if type(fn)~="function"then return false end
 local ok,value=pcall(fn,...);return ok and I.Readable(value) and value==true
end
function G.Roster()
 local members={}
 if not flag(IsInGroup) or flag(IsInRaid)then return members end
 local nameFn=NameUtil and NameUtil.GetUnmodifiedUnitFullName or GetUnitName
 if type(nameFn)~="function"then return members end
 for i=1,4 do local unit="party"..i
  if flag(UnitExists,unit) and flag(UnitIsConnected,unit)then
   local ok,name=pcall(nameFn,unit,true)
   local key=ok and I.Safe(name,100) and I.Name(name)
   if key and not F.Inspect.IsSelf(name)then members[key]=true end
  end
 end
 return members
end
function G.Receive(body,channel,sender)
 if not I.Readable(channel) or channel~="PARTY" or not I.Safe(body,8) or body~="1" or not I.Safe(sender,100)then return end
 local key=I.Name(sender)
 if key and G.Roster()[key]then G.seen[key]=now()end
end
function G.Tick(dt)
 if not F.ready or not P.state then return end
 dt=type(dt)=="number" and dt==dt and math.max(0,math.min(5,dt)) or 0
 local clock=now();local roster=G.Roster();local present={}
 -- Accept already-validated sharing/inspect peers from older addon builds too.
 for name,peer in pairs(P.peers or {})do
  local key=I.Name(name);local age=type(peer.seen)=="number" and F.Now()-peer.seen
  if key and roster[key] and age and age>=0 and age<=150 then present[key]=true end
 end
 for key,seen in pairs(G.seen)do
  if not roster[key] or clock-seen>90 or clock<seen then G.seen[key]=nil else present[key]=true end
 end
 local count,payments=0,0
 for key in pairs(G.seconds)do if not present[key]then G.seconds[key]=nil end end
 for key in pairs(present)do
  count=count+1;local seconds=(G.seconds[key] or 0)+dt
  if seconds>=60 then payments=payments+math.floor(seconds/60);seconds=seconds%60 end
  G.seconds[key]=seconds
 end
 G.count=count
 if payments>0 then P.ChangeTokens(math.min(P.maxTokens-P.state.tokens,payments*2),"PARTY","")end -- Flat bonus; no talent multiplier.
 if not next(roster)then G.nextSend=nil;return end
 if clock<(G.nextSend or 0)then return end
 G.nextSend=clock+30
 if not C_ChatInfo then return end
 if not G.registered and C_ChatInfo.RegisterAddonMessagePrefix then
  local ok,value=pcall(C_ChatInfo.RegisterAddonMessagePrefix,G.prefix)
  G.registered=ok and I.Readable(value) and (value==true or value==0 or value==1)
 end
 if not G.registered or not C_ChatInfo.SendAddonMessage then return end
 if C_ChatInfo.InChatMessagingLockdown then
  local ok,locked=pcall(C_ChatInfo.InChatMessagingLockdown)
  if not ok or not I.Readable(locked) or locked then return end
 end
 -- One quiet party heartbeat per 30 seconds. No whispers, public chat or retries.
 local ok,value=pcall(C_ChatInfo.SendAddonMessage,G.prefix,"1","PARTY")
 local success=Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0
 if not ok or not I.Readable(value) or not (value==true or value==success)then G.nextSend=clock+300 end
end
local tick=P.Tick
function P.Tick(dt,...)local result=tick(dt,...);G.Tick(dt);return result end
local frame=CreateFrame("Frame");G.frame=frame
frame:RegisterEvent("CHAT_MSG_ADDON");frame:RegisterEvent("GROUP_ROSTER_UPDATE");frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent",function(_,event,prefix,body,channel,sender)
 if event=="CHAT_MSG_ADDON"then
  if I.Readable(prefix) and prefix==G.prefix then G.Receive(body,channel,sender)end
 else
  local roster=G.Roster()
  for key in pairs(G.seen)do if not roster[key]then G.seen[key]=nil end end
  for key in pairs(G.seconds)do if not roster[key]then G.seconds[key]=nil end end
 end
end)
