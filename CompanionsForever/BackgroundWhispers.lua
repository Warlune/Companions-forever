local _,F=...
-- Only automatic CF probes/replies use this transport. Player chat is untouched.
local B={recent={},blocked={},manual={},handlers={}};F.BackgroundWhispers=B
local function now()return GetTime and GetTime()or F.Now()end
local function readable(v)return(not issecretvalue or not issecretvalue(v))and(not canaccessvalue or canaccessvalue(v))end
local function key(name)
 if not readable(name)or type(name)~='string'or #name==0 or #name>100 or name:find('[|%c]')then return end
 return name:lower()
end
local function prune()
 local stamp=now();local count=0
 for name,row in pairs(B.recent)do if row.expires<stamp then B.recent[name]=nil else count=count+1 end end
 for name,expiry in pairs(B.blocked)do if expiry<stamp then B.blocked[name]=nil end end
 for name,expiry in pairs(B.manual)do if expiry<stamp then B.manual[name]=nil end end
 return count
end
function B.Offline(name)
 local k=key(name);local row=k and B.recent[k]
 if not row or row.expires<now()then return false end
 B.blocked[k]=now()+600
 if not row.failed then
  row.failed=true
  local callback=B.handlers[row.prefix]
  if callback then callback(row.name)end
 end
 return true
end
function B.Send(prefix,body,target)
 local k=key(target);local count=prune()
 local outcomes=Enum and Enum.SendAddonMessageResult
 if not k or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false end
 if B.blocked[k]and B.blocked[k]>now()then return false,outcomes and outcomes.TargetOffline or 12 end
 -- Bound memory even if a busy channel produces many distinct speakers.
 local blocked=0;for _ in pairs(B.blocked)do blocked=blocked+1 end
 if count+blocked>=128 and not B.recent[k]then return false end
 B.recent[k]={name=target,prefix=prefix,expires=now()+10}
 local ok,result=pcall(C_ChatInfo.SendAddonMessage,prefix,body,'WHISPER',target)
 if ok and readable(result)and result==(outcomes and outcomes.TargetOffline or 12)then B.Offline(target)end
 return ok and readable(result)and(result==true or result==(outcomes and outcomes.Success or 0)),result
end
function B.Manual(_,channel,_,target)
 if not readable(channel)or channel~='WHISPER'then return end
 local k=key(target);if not k then return end
 prune();local count=0;for _ in pairs(B.manual)do count=count+1 end
 if count<128 or B.manual[k]then B.manual[k]=now()+30 end
end
local function escaped(text)return(text:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])','%%%1'))end
function B.Filter(_,_,message)
 if not readable(message)or type(message)~='string'or #message>512 then return end
 local format=ERR_CHAT_PLAYER_NOT_FOUND_S
 if type(format)~='string'then return end
 local first,last=format:find('%%s')
 if not first then first,last=format:find('%%1%$s')end
 if not first then return end
 local name=message:match('^'..escaped(format:sub(1,first-1))..'(.-)'..escaped(format:sub(last+1))..'$')
 local k=key(name)
 if not k then return end
 local ours=B.Offline(name)
 -- Keep actual player whisper failures visible, including same-target races.
 if ours and B.manualObserved and not(B.manual[k]and B.manual[k]>=now())then return true end
end
local frame=CreateFrame('Frame');B.frame=frame
frame:RegisterEvent('CHAT_MSG_ADDON')
frame:RegisterEvent('PLAYER_LOGIN')
frame:SetScript('OnEvent',function(_,event,prefix,_,channel,sender)
 if event=='PLAYER_LOGIN'then B.Install();return end
 if not readable(prefix)or not readable(channel)or channel~='WHISPER'then return end
 local k=key(sender);local row=k and B.recent[k]
 if row and row.prefix==prefix then B.blocked[k]=nil;B.recent[k]=nil end
end)
function B.Install()
 local addFilter=ChatFrame_AddMessageEventFilter or(ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter)
 if addFilter and not B.filtered then addFilter('CHAT_MSG_SYSTEM',B.Filter);B.filtered=true end
 if hooksecurefunc then
  if type(SendChatMessage)=='function'and not B.hookedLegacy then hooksecurefunc('SendChatMessage',B.Manual);B.hookedLegacy=true;B.manualObserved=true end
  if C_ChatInfo and type(C_ChatInfo.SendChatMessage)=='function'and not B.hookedModern then hooksecurefunc(C_ChatInfo,'SendChatMessage',B.Manual);B.hookedModern=true;B.manualObserved=true end
 end
end
B.Install()
