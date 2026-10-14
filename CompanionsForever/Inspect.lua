local _,F=...
local P,I=F.Pets,F.Integrity
local X={prefix="CFStable1"};F.Inspect=X
local function now()return GetTime and GetTime() or F.Now()end
local function integer(n,a,b)return type(n)=="number" and n==math.floor(n) and n>=a and n<=b end
local function send(body,target)
  if not X.registered or not C_ChatInfo or not C_ChatInfo.SendAddonMessage or #body>255 then return false end
  local ok,v=pcall(C_ChatInfo.SendAddonMessage,X.prefix,body,"WHISPER",target)
  return ok and I.Readable(v) and (v==true or v==((Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success) or 0))
end
function X.Initialize()
  X.pending=nil;X.outbox=nil;X.lastError=nil;X.lastTarget=nil;X.nextRequest=nil
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,X.prefix);X.registered=ok and I.Readable(v) and (v==true or v==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.Success) or 0) or v==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix) or 1))
  end
end
function X.Request(name,fallbackVersion)
  if not P.state.share or not I.Name(name)then return false end
  X.sequence=(X.sequence or 0)+1
  local nonce=math.floor(F.Now()).."-"..X.sequence
  local protocol=fallbackVersion or (P.hardAbilityCatalog and 12 or P.sparklyCatalog and 11 or P.controlAbilityCatalog and 10 or F.Achievements and F.Achievements.adventureCatalog and 9 or P.petRollVersion and 8 or #P.specialAbilities>6 and 7 or F.Pets.HardMode and 6 or F.Achievements and 5 or F.History and 2 or 1)
  local pending={name=I.Name(name),target=name,protocol=protocol,nonce=nonce,expires=now()+(protocol>=6 and 25 or 15),nextAttempt=now()+5,pets={},stats={},origins={},wantOrigins=protocol>=2,wantFrame=protocol>=3}
  if not send((protocol==1 and "Q|" or "Q"..protocol.."|")..nonce,name)then
    X.lastTarget=I.Name(name);X.lastError="Full-stable request was not accepted. Retry outside combat or restricted instances.";return false
  end
  X.lastError=nil;X.lastTarget=I.Name(name)
  X.pending=pending;if F.HistoryPeers and not fallbackVersion then F.HistoryPeers.Request(name)end;return true
end
function X.SelfName()
  local name=GetUnitName and GetUnitName("player",true) or UnitName and UnitName("player")
  return I.Safe(name,100) and name or "Your character"
end
function X.IsSelf(name)return I.Name(name)~=nil and I.Name(name)==I.Name(X.SelfName())end
function X.LocalSnapshot()
  local stable,active={},0
  for _,pet in ipairs(P.state.pets)do if not pet.deadAt and not P.IsHoused(pet) and pet.health>0 and #stable<P.stableCapacity then
    local copy={};for k,v in pairs(pet)do copy[k]=v end
    copy.sharedStats={P.Stats(pet)};stable[#stable+1]=copy
    if pet.id==P.state.active then active=#stable end
  end end
  return {stableCapacity=P.stableCapacity,stable=stable,stableActive=active,portraitFrame=F.Achievements and F.Achievements.Frame() or 1,seen=F.Now(),stableSeen=F.Now(),isSelf=true}
end
function P.InspectPlayer(name)
  if not I.Safe(name,100)then return false,"This player's name is unavailable."end
  if I.Name(name)~=I.Name(P.inspectName)then X.pending=nil;P.pendingInspect=nil end
  P.inspectName=name;P.inspectSlot=nil
  if X.IsSelf(name)then X.pending=nil;P.pendingInspect=nil;return true end
  if not P.state.share then return false,"Enable pet sharing before inspecting another player."end
  if now()<(X.nextRequest or 0)then return false,"Wait a few seconds before refreshing another stable."end
  X.nextRequest=now()+3
  -- The old active-pet reply is a fallback only; newer clients send all stats.
  P.RequestBasicInspect(name)
  if X.Request(name)then P.notice="Requesting "..name.."'s full stable.";return true end
  return false,X.lastError or "Full-stable messaging is unavailable. Reload the addon and retry."
end
function P.InspectTarget()
  local player=UnitIsPlayer and UnitIsPlayer("target")
  if not I.Readable(player) or not player then return false,"Target a player with Companions Forever."end
  local name=GetUnitName and GetUnitName("target",true) or UnitName and UnitName("target")
  return P.InspectPlayer(name)
end
local oldReceive=P.Receive
function P.Receive(message,channel,sender)
  local prior=I.Safe(sender,100) and P.peers[sender]
  oldReceive(message,channel,sender)
  local entry=I.Safe(sender,100) and P.peers[sender]
  if entry and I.Readable(channel) then entry.channel=channel end
  if prior and entry and entry~=prior and prior.stable then
    entry.stable=prior.stable;entry.stableCapacity=prior.stableCapacity;entry.stableSeen=prior.stableSeen;entry.stableActive=prior.stableActive;entry.portraitFrame=prior.portraitFrame
  end
end
local function snapshot(nonce,sender,origins,framed)
  local rows={};local active=0
  for _,pet in ipairs(P.state.pets)do if not pet.deadAt and not P.IsHoused(pet) and pet.health>0 and #rows<(framed and framed>=6 and P.stableCapacity or 9) and (not (F.PetData.hiddenSpecies and F.PetData.hiddenSpecies[pet.species]) or framed and framed>=5 or (framed and pet.species<=2349))then
    local supported=pet.species<2364 or framed and framed>=9
    if not framed or framed<7 then for _,id in ipairs(pet.abilities or {})do if id>6 then supported=false end end end
    if not framed or framed<10 then for _,id in ipairs(pet.abilities or {})do if id>36 then supported=false end end end
    if not framed or framed<12 then for _,id in ipairs(pet.abilities or {})do if id>38 then supported=false end end end
    if P.IsSparkly and P.IsSparkly(pet) and (not framed or framed<11)then supported=false end
    local visible=pet
    if pet.rolls and (not framed or framed<8)then
      visible={};for k,v in pairs(pet)do visible[k]=v end;visible.rolls=nil
    end
    local wire=I.Encode("pet",visible)
    if supported and I.Decode(wire) and #wire<=205 then
      local hp,attack,armor,speed=P.Stats(pet)
      local stats=string.format("%.3f,%.3f,%.3f,%.3f",hp,attack,armor,speed)
      rows[#rows+1]={wire=wire,stats=stats,birth=F.History and F.History.BirthWire(pet)};if pet.id==P.state.active then active=#rows end
    end
  end end
  local border=F.Achievements and F.Achievements.Frame() or 1
  if framed==3 and border>4 then border=1 end -- 0.6.50 understands only the original four borders.
  local messages={"B|"..nonce.."|"..#rows.."|"..active..(framed and (","..border) or "")..(framed and framed>=6 and (","..P.stableCapacity) or "")}
  for i,row in ipairs(rows)do
    messages[#messages+1]="P|"..nonce.."|"..i.."|"..row.wire
    messages[#messages+1]="S|"..nonce.."|"..i.."|"..row.stats
    if origins then messages[#messages+1]="O|"..nonce.."|"..i.."|"..row.birth end
  end
  X.outbox={messages=messages,target=sender,index=1,at=now(),expires=now()+15}
end
local function complete(q,sender)
  if not q.count then return end
  for i=1,q.count do if not q.pets[i] or not q.stats[i] or (q.wantOrigins and not q.origins[i])then return end end
  local stable={};for i=1,q.count do local pet=q.pets[i];pet.sharedStats=q.stats[i];pet.birth=q.origins[i]~="N" and q.origins[i] or nil;stable[i]=pet end
  local selected=stable[q.active] or stable[1];local entry={}
  if selected then for k,v in pairs(selected)do entry[k]=v end end
  entry.seen=F.Now();entry.stableSeen=F.Now();entry.stable=stable;entry.stableCapacity=q.capacity or 9;entry.stableActive=q.active;entry.portraitFrame=q.frame or 1
  local count,oldest=0;for name,e in pairs(P.peers)do count=count+1;if not oldest or e.seen<P.peers[oldest].seen then oldest=name end end
  if count>=40 and not P.peers[sender] and oldest then P.peers[oldest]=nil end
  P.peers[sender]=entry;P.inspectName=sender;P.inspectSlot=q.active>0 and q.active or 1
  X.pending=nil;X.lastError=nil;P.pendingInspect=nil;P.notice="Received "..sender.."'s stable ("..q.count.." / "..(q.capacity or 9)..")."
  if P.Render then P.Render()end
end
function X.Receive(message,channel,sender)
  if not F.ready or not P.state or not P.state.share or not I.Readable(channel) or channel~="WHISPER" or not I.Safe(sender,100)
    or not I.Readable(message) or type(message)~="string" or #message>255 then return end
  local frame12=P.hardAbilityCatalog and message:match("^Q12|(%d+%-%d+)$")
  local frame11=P.sparklyCatalog and message:match("^Q11|(%d+%-%d+)$")
  local frame10=P.controlAbilityCatalog and message:match("^Q10|(%d+%-%d+)$")
  local frame9=F.Achievements and F.Achievements.adventureCatalog and message:match("^Q9|(%d+%-%d+)$")
  local frame8=P.petRollVersion and message:match("^Q8|(%d+%-%d+)$")
  local frame7=#P.specialAbilities>6 and message:match("^Q7|(%d+%-%d+)$")
  local frame6=F.Pets.HardMode and message:match("^Q6|(%d+%-%d+)$")
  local frame5=F.Achievements and message:match("^Q5|(%d+%-%d+)$")
  local frame4=F.Achievements and message:match("^Q4|(%d+%-%d+)$")
  local frame3=F.Achievements and message:match("^Q3|(%d+%-%d+)$")
  local framed=frame12 or frame11 or frame10 or frame9 or frame8 or frame7 or frame6 or frame5 or frame4 or frame3
  local origins=framed or F.History and message:match("^Q2|(%d+%-%d+)$")
  local request=origins or message:match("^Q|(%d+%-%d+)$")
  if request then
    if #request>26 or X.outbox or now()<(X.nextReply or 0)then return end
    X.nextReply=now()+5;snapshot(request,sender,origins,frame12 and 12 or frame11 and 11 or frame10 and 10 or frame9 and 9 or frame8 and 8 or frame7 and 7 or frame6 and 6 or frame5 and 5 or frame4 and 4 or frame3 and 3 or nil);return
  end
  local q=X.pending
  if not q or now()>q.expires or I.Name(sender)~=q.name then return end
  local op,nonce,index,data=message:match("^([BPSO])|(%d+%-%d+)|(%d+)|([^|]+)$")
  index=tonumber(index);if nonce~=q.nonce then return end
  if op=="B"then
    local active,frame,capacity=tonumber(data),1,9
    if q.wantFrame then
      local a,b,c
      if q.protocol>=6 then a,b,c=data:match("^(%d+),(%d+),(%d+)$");capacity=tonumber(c);if capacity~=9 and capacity~=16 then return end
      else a,b=data:match("^(%d+),(%d+)$")end
      active,frame=tonumber(a),tonumber(b)
      if not integer(frame,1,#F.Achievements.frames)then return end
    end
    if not integer(index,0,capacity) or not integer(active,0,index)then return end
    if q.count and (q.count~=index or q.active~=active or q.frame~=frame or q.capacity~=capacity)then X.pending=nil;return end
    q.count=index;q.active=active;q.frame=frame;q.capacity=capacity
  elseif integer(index,1,q.protocol>=6 and 16 or 9)then
    if op=="P"then
      local e=I.Decode(data);if not e or e.kind~="pet"then return end
      if q.pets[index] and I.Encode("pet",q.pets[index])~=data then X.pending=nil;return end
      q.pets[index]=e.item
    elseif op=="O" and F.History then
      if not F.History.DecodeBirth(data)then return end
      if q.origins[index] and q.origins[index]~=data then X.pending=nil;return end;q.origins[index]=data
    elseif op=="S"then
      local a,b,c,d=data:match("^(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*)$")
      if not a then return end
      local values={tonumber(a),tonumber(b),tonumber(c),tonumber(d)}
      for _,v in ipairs(values)do if not v or v<0 or v>10000000 then return end end
      if q.stats[index] and table.concat(q.stats[index],",")~=table.concat(values,",")then X.pending=nil;return end
      q.stats[index]=values
    end
  end
  complete(q,sender)
end
function X.Pump()
  if not P.state or not P.state.share then X.pending=nil;X.outbox=nil;return end
  if X.pending and not X.pending.count and X.pending.protocol>1 and now()>=X.pending.nextAttempt then
    local pending=X.pending;pending.nextAttempt=now()+5
    X.Request(pending.target,pending.protocol-1)
  end
  if X.pending and now()>X.pending.expires then
    X.lastTarget=X.pending.name;X.pending=nil;X.lastError="No complete stable reply. The player may have sharing off, be offline, use an older addon, or have restricted messages. Click their portrait to retry.";P.notice=X.lastError
  end
  local q=X.outbox;if not q or now()<q.at then return end
  if now()>q.expires then X.outbox=nil;return end
  if send(q.messages[q.index],q.target)then q.index=q.index+1;q.at=now()+0.15 else q.at=now()+1 end
  if q.index>#q.messages then X.outbox=nil end
end
local frame=CreateFrame("Frame");frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,_,prefix,message,channel,sender)if I.Readable(prefix) and prefix==X.prefix then X.Receive(message,channel,sender)end end)
frame:SetScript("OnUpdate",function()if X.outbox or X.pending then X.Pump()end end)
