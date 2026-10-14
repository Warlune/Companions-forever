-- Bounded, optional corroboration of a party kill. Not proof of rarity or honesty.
local _,F=...
local P,I=F.Pets,F.Integrity
local W={prefix="CFWitness1",kills={},requests={},claims={}};F.Witnesses=W
local function enabled()return P.state and F.db.settings.partyWitnesses~=false end
local function party()
  if not IsInRaid or not IsInGroup then return false end
  local raid,group=IsInRaid(),IsInGroup()
  return I.Readable(raid) and I.Readable(group) and not raid and group==true
end
local function member(sender)
  if not party()then return false end
  local who=I.Name(sender);if not who or who==I.Owner()then return false end
  for i=1,4 do if I.Name(GetUnitName and GetUnitName("party"..i,true))==who then return true end end
  return false
end
local function send(message,channel,target)
  if not W.registered or #message>255 then return end
  if channel=='WHISPER'and F.BackgroundWhispers then F.BackgroundWhispers.Send(W.prefix,message,target)
  else pcall(C_ChatInfo.SendAddonMessage,W.prefix,message,channel,target)end
end
function W.Initialize()
  W.kills={};W.requests={};W.claims={};W.acks={}
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,W.prefix)
    local outcomes=Enum and Enum.RegisterAddonMessagePrefixResult
    W.registered=ok and I.Readable(v) and (v==true or v==(outcomes and outcomes.Success or 0) or v==(outcomes and outcomes.DuplicatePrefix or 1))
  end
end
local function prune()
  local now=F.Now()
  for _,list in ipairs({W.kills,W.requests,W.claims})do for key,e in pairs(list)do if now-e.at>30 then list[key]=nil end end end
end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function valid(guid,species)
  if not I.Safe(guid,90)then return false end
  if P.ExcludedKill(guid)then return false end
  local npc=tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
  return npc and F.PetData.farmByNPC[npc]==species and P.IsAllowedSpecies(species) and P.PartyPetRoll(guid)<=500
end
local function reply(key,r)
  if W.kills[r.guid] and member(r.sender)then
    send("A|"..r.guid.."|"..r.id,"WHISPER",r.sender);W.requests[key]=nil
  end
end
function W.Observe(guid)
  if not enabled() or not party() or not I.Safe(guid,90)then return end
  if P.ExcludedKill(guid)then return end
  prune();if count(W.kills)>=128 then return end
  W.kills[guid]={at=F.Now()}
  for key,r in pairs(W.requests)do if r.guid==guid then reply(key,r)end end
end
function W.Found(guid,pet)
  if not enabled() or not party() or not pet.assetID or not W.kills[guid] or not valid(guid,pet.species)then return end
  prune();if count(W.claims)>=9 then return end
  W.claims[pet.assetID]={guid=guid,pet=pet,at=F.Now()}
  send("W|"..guid.."|"..pet.assetID.."|"..pet.species,"PARTY")
end
function W.Receive(message,channel,sender)
  if not enabled() or not I.Readable(channel) or not I.Safe(sender,100) or not I.Readable(message) or type(message)~="string" or #message>220 or not member(sender)then return end
  prune();local now=F.Now()
  if not W.window or now-W.window>=60 or now<W.window then W.window=now;W.messages=0 end
  W.messages=(W.messages or 0)+1;if W.messages>64 then return end
  if channel=="PARTY"then
    local guid,id,sp=message:match("^W|([^|]+)|([^|]+)|(%d+)$");sp=tonumber(sp)
    if not I.ValidID(id) or not valid(guid,sp) or count(W.requests)>=32 then return end
    local key=I.Name(sender)..":"..id
    -- Keep a short acknowledgement cache so repeated requests cannot spam replies.
    W.acks=W.acks or {};for k,at in pairs(W.acks)do if now-at>30 then W.acks[k]=nil end end
    if W.acks[key]then return end;W.acks[key]=now
    W.requests[key]={guid=guid,id=id,sender=sender,at=now};reply(key,W.requests[key])
  elseif channel=="WHISPER"then
    local guid,id=message:match("^A|([^|]+)|([^|]+)$");local claim=id and W.claims[id]
    if not claim or claim.guid~=guid or not W.kills[guid]then return end
    local pet=claim.pet;pet.killWitnesses=pet.killWitnesses or {};pet.killWitnesses[I.Name(sender)]=true
  end
end
local frame=CreateFrame("Frame");frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,_,prefix,message,channel,sender)if I.Readable(prefix) and prefix==W.prefix then W.Receive(message,channel,sender)end end)
