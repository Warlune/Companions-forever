local _,F=...
local P=F.Pets
local T={prefix="CFTrade1"};F.Trades=T;F.LegacyTrades=T
local function readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
local function safe(v,n)return readable(v) and type(v)=="string" and #v>0 and #v<=n and not v:find("[|%c]")end
local function int(v,a,b)return type(v)=="number" and v==math.floor(v) and v>=a and v<=b end
local function clock()return GetTime and GetTime() or F.Now()end
local function norm(name)
  if not safe(name,100)then return nil end
  if not name:find("-",1,true)then name=name.."-"..(GetRealmName and GetRealmName() or "")end
  return name:lower():gsub("%s","")
end
local function changed(message)
  if message then P.notice=message end
  if P.Render then P.Render()end
end
local fields={"species","rarity","level","xp","health","food","energy","born","age","best","wins","style"}
local limits={{1,10000},{1,5},{1,100},{0,1e12},{0.000001,100},{0,100},{0,100},{0,1e12},{0,1e12},{0,100},{0,1e7},{1,4}}
local fractional={xp=true,health=true,food=true,energy=true,age=true}
-- Only a fixed numeric schema crosses the wire. No Lua deserialization, links or remote text.
function T.Encode(kind,item)
  if kind=="none"then return "N"end
  if kind=="gear"then return "G,"..item.kind..","..item.rarity..","..(item.enemyLevel or 0)end
  if kind=="crate"then return "C,"..item.crate end
  if kind=="pet"then
    local out={"P"}
    for _,k in ipairs(fields)do local n=item[k] or (k=="style" and 1 or 0)
      out[#out+1]=fractional[k] and string.format("%.6f",n):gsub("0+$",""):gsub("%.$","") or tostring(math.floor(n))
    end
    out[#out+1]=tostring(item.abilities and item.abilities[1] or 0)
    out[#out+1]=tostring(item.abilities and item.abilities[2] or 0)
    if item.towerSeed then out[#out+1]=tostring(item.towerSeed)end
    return table.concat(out,",")..(item.rolls and (":"..item.rolls) or "")
  end
end
function T.Decode(wire)
  if not safe(wire,190)then return end
  if wire=="N"then return {kind="none"}end
  local rollWire
  if wire:find(":",1,true)then
    local base,roll=wire:match("^([^:]+):(%x+)$")
    if not base or not P.DecodePetRolls then return end
    wire=base;rollWire=roll
  end
  if not wire:match("^[PGC],%d+[,%d%.]*$")then return end
  local values={};for v in wire:gmatch("[^,]+")do values[#values+1]=v end
  if table.concat(values,",")~=wire then return end
  for i=2,#values do values[i]=tonumber(values[i]);if not values[i] or values[i]~=values[i] or values[i]<0 or values[i]>1e12 then return end end
  local item={}
  if values[1]=="P" and (#values==15 or #values==16) then
    for i,k in ipairs(fields)do local n=values[i+1]
      if n<limits[i][1] or n>limits[i][2] or (not fractional[k] and n~=math.floor(n))then return end;item[k]=n
    end
    if not P.species[item.species] or (P.IsAllowedSpecies and not P.IsAllowedSpecies(item.species))then return end
    local count=item.rarity>=4 and 2 or item.rarity>=3 and 1 or 0
    item.abilities={}
    for i=1,2 do local n=values[13+i]
      if not int(n,i<=count and 1 or 0,i<=count and #P.specialAbilities or 0)then return end
      if i<=count then item.abilities[i]=n end
    end
    if count==2 and item.abilities[1]==item.abilities[2]then return end
    if #values==16 then if not int(values[16],1,1000000000)then return end;item.towerSeed=values[16]end
    item.rolls=rollWire
    if rollWire and not P.DecodePetRolls(item)then return end
    item.gear={};return {kind="pet",item=item}
  elseif not rollWire and values[1]=="G" and #values==4 and int(values[2],1,#P.gearTypes) and int(values[3],0,5) and values[3]>=(P.gearTypes[values[2]].minRarity or 0) and int(values[4],0,1000)then
    return {kind="gear",item={kind=values[2],rarity=values[3],enemyLevel=values[4]}}
  elseif not rollWire and values[1]=="C" and #values==2 and (int(values[2],1,11) or (P.xpTreats and P.xpTreats[values[2]]) or (P.specialCrates and P.specialCrates[values[2]]) or (P.equipmentCrates and P.equipmentCrates[values[2]]))then return {kind="crate",item={crate=values[2],rarity=P.CrateRarity(values[2])}}end
end
local function bucket(kind)return kind=="pet" and "pets" or kind=="gear" and "gear" or kind=="crate" and "crates"end
local function space(kind)return kind=="pet" and "pet" or (kind=="gear" or kind=="crate") and "bag"end
function T.Reserved(kind)
  local t=P.state and P.state.trade
  if type(t)~="table" or t.applied then return 0 end
  local remote=t.remote and T.Decode(t.remote)
  return (space(t.kind)==kind or remote and space(remote.kind)==kind) and 1 or 0
end
function T.RecordReserved(kind)
  local t=P.state and P.state.trade;if type(t)~="table" or t.applied then return 0 end
  local remote=t.remote and T.Decode(t.remote)
  return (t.kind==kind or remote and remote.kind==kind) and 1 or 0
end
function T.BlockReason()
  if T.broken then return "The saved trade needs recovery. Its assets have been preserved."end
  if not T.registered or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return "The trade message channel is unavailable. Reload both addons."end
  -- The realm restriction flag alone is not evidence that this particular send
  -- will fail. Inspect uses the normal send API successfully on this client.
  -- Respect current lockdown, then check the actual send result and peer reply.
  if C_ChatInfo.InChatMessagingLockdown then
    local ok,v=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not readable(v)then return "WoW's current messaging availability could not be checked. Retry outside combat."end
    if v then return "WoW's chat messaging lockdown is active. Retry outside combat or restricted instances; pending trades remain saved."end
  end
end
local function send(op,t,data)
  local why=T.BlockReason();if why then T.lastError=why;return false end
  local message=op.."|"..t.id.."|"..(data or "0")
  if #message>255 then T.lastError="Trade message is too large.";return false end
  local ok,result=pcall(C_ChatInfo.SendAddonMessage,T.prefix,message,"WHISPER",t.peer)
  local outcomes=Enum and Enum.SendAddonMessageResult
  local success=ok and readable(result) and (result==true or result==(outcomes and outcomes.Success or 0))
  T.lastError=nil
  if not success then
    if ok and readable(result) and result==(outcomes and outcomes.AddOnMessageLockdown or 11)then
      T.lastError="WoW rejected the trade message because messaging is locked. Retry outside combat or restricted instances."
    elseif ok and readable(result) and result==(outcomes and outcomes.TargetOffline or 12)then
      T.lastError="WoW reports that the trade recipient is offline."
    else T.lastError="WoW did not accept the trade message. Retry in a few seconds; existing pending trades remain saved."end
  end
  return success
end
local function pair(t)
  return t.role=="A" and (t.rev..","..t.otherRev) or (t.otherRev..","..t.rev)
end
local function reset(t)
  t.ready=nil;t.peerReady=nil;T.reviewAfter=clock()+3
end
function T.Seconds()return math.max(0,math.ceil((T.reviewAfter or (clock()+3))-clock()))end
local function eligible(kind,id)
  if kind=="none"then return true end
  local list=P.state[bucket(kind) or ""]
  if not list then return false,"Choose a pet, item or crate."end
  for i,item in ipairs(list)do if item.id==id then
    local bound=P.SoulboundReason and P.SoulboundReason(kind,item);if bound then return false,bound end
    if kind=="pet"then
      if item.deadAt or item.health<1 then return false,"Only living pets can be traded."end
      if item.id==P.state.active then return false,"Equip a different pet before trading this one."end
      if next(item.gear or {})then return false,"Remove the pet's equipment first."end
      if item.recovery then return false,"Free recovery pets cannot be traded."end
    elseif kind=="gear" and P.GearOwner(id)then return false,"Unequip this item first."end
    if not T.Decode(T.Encode(kind,item))then return false,"This asset cannot be represented safely in a trade."end
    return true,item,i
  end end
  return false,"That asset is no longer available."
end
T.Eligible=eligible
local function restore(t)
  if t.escrow then local list=P.state[bucket(t.kind)];list[#list+1]=t.escrow;t.escrow=nil end
end
local function take(t,kind,id)
  local ok,item,index=eligible(kind,id);if not ok then return false,item end
  restore(t);t.kind=kind;t.escrow=kind~="none" and table.remove(P.state[bucket(kind)],index) or nil
  t.wire=T.Encode(kind,t.escrow);t.rev=t.rev+1;reset(t);return true
end
local function validEscrow(t)
  if t.kind=="none"then return t.escrow==nil end
  local item=t.escrow
  if type(item)~="table" or not int(item.id,1,t.kind=="pet" and 999999 or 1000000000)then return false end
  if t.kind=="pet" and (item.deadAt or item.recovery or type(item.gear or {})~="table" or next(item.gear or {}))then return false end
  local ok,wire=pcall(T.Encode,t.kind,item)
  return ok and wire==t.wire and T.Decode(wire)~=nil
end
local function capacity(t)
  if P.CheckSoulboundOffer then local ok,why=P.CheckSoulboundOffer(t);if not ok then return false,why end end
  local remote=t.remote and T.Decode(t.remote);if not remote then return false,"Waiting for the other player's offer."end
  if t.wire=="N" and remote.kind=="none"then return false,"At least one player must offer something."end
  if P.state.battle then return false,"Finish the tower battle first."end
  if P.StableCount()>P.stableCapacity or P.BagCount()>P.BagCapacity()then return false,"Make space in your stable or bag before confirming."end
  if #P.state.pets+T.RecordReserved("pet")>512 or #P.state.gear+T.RecordReserved("gear")>500 or #P.state.crates+T.RecordReserved("crate")>(P.maxCrateRecords or 100) then
    return false,"Your collection records are full. Make space before confirming."
  end
  if remote.kind=="pet"then
    if #P.state.pets>=512 or P.state.nextID>=1000000 then return false,"Your stable records are full."end
    if remote.item.level>P.LevelCap()then return false,"This pet exceeds your current pet level cap."end
  elseif remote.kind~="none"then
    if #P.state.gear>=500 or #P.state.crates>=(P.maxCrateRecords or 100) or P.state.nextGearID>1000000000 then return false,"Your item records are full."end
  end
  return true
end
function T.CanConfirm()
  local t=P.state and P.state.trade
  if not t or t.decision or t.cancel or t.ready then return false,"Waiting for the other player."end
  local why=T.BlockReason();if why then return false,why end
  local ok,msg=capacity(t);if not ok then return ok,msg end
  if T.Seconds()>0 then return false,"Review both offers before confirming."end
  return true
end
local function record(t,outcome)
  P.state.tradeHistory[t.id]={peer=t.peer,outcome=outcome,pair=t.remote and pair(t) or "0"}
end
local function finish(t)
  record(t,"C");P.state.trade=nil;T.invite=nil
  changed("Trade complete with "..t.peer..".");F.Print(P.notice)
end
local function apply(t)
  if t.applied then return end
  local offer=assert(T.Decode(t.remote));local s=P.state;local item=offer.item
  -- A saved commit decision is irrevocable. Capacity was reserved before either Confirm.
  if item then
    item.isNew=true;item.source="Trade";item.found=F.Now()
    if offer.kind=="pet"then item.id=s.nextID;s.nextID=s.nextID+1
    else item.id=s.nextGearID;s.nextGearID=s.nextGearID+1 end
    s[bucket(offer.kind)][#s[bucket(offer.kind)]+1]=item
  end
  t.escrow=nil;t.applied=true
  if offer.kind=="pet"then P.RecordDiscovery(item.species,item.rarity,"Trade");if P.RecordAbilityDiscovery then P.RecordAbilityDiscovery(item)end end
  P.FindHistory("Trade received from "..t.peer..": "..(offer.kind=="none" and "gift sent" or offer.kind))
end
local function decide(t)
  if t.role=="A" and not t.cancel and not t.decision and t.ready==pair(t) and t.peerReady==pair(t)then
    t.decision="C";apply(t);send("C",t,pair(t));changed("Trade committed. Waiting for delivery acknowledgement; Retry if needed.")
  end
end
function T.Confirm()
  local ok,msg=T.CanConfirm();if not ok then return false,msg end
  local t=P.state.trade;t.ready=pair(t);send("R",t,t.ready);decide(t);changed();return true
end
function T.Change(kind,id)
  local t=P.state.trade
  if not t or t.ready or t.cancel or t.decision then return false,"Your confirmed offer is locked. Cancel safely before starting another."end
  if P.state.battle then return false,"Finish the battle first."end
  if t.rev>=9999 then return false,"Cancel this trade and start another."end
  local ok,msg=take(t,kind,id);if not ok then return ok,msg end
  send("O",t,t.rev..","..t.wire);changed("Offer changed. Both players must confirm again after three seconds.");return true
end
local function newAllowed()
  if P.state.trade then return false,"Finish or cancel your pending trade first."end
  if P.state.battle then return false,"Finish the battle first."end
  local why=T.BlockReason();if why then return false,why end
  local count=0;for _ in pairs(P.state.tradeHistory)do count=count+1 end
  if count>=2000 then return false,"Trade history is full; it is retained to prevent replayed deliveries."end
  return true
end
function T.ExpireProbe()
  if T.probe and clock()>T.probe.expires then
    T.probe=nil;T.lastError="No trade connection reply. Both players need version 0.6.42 or newer and working addon whispers. No assets were held."
    changed(T.lastError)
  end
end
function T.Start(peer,kind,id)
  T.ExpireProbe()
  if T.probe then return false,"Checking the current recipient. Wait for a reply or cancel the check."end
  local ok,msg=newAllowed();if not ok then return ok,msg end
  if not safe(peer,100) or norm(peer)==norm(GetUnitName and GetUnitName("player",true) or "")then return false,"Target another player to trade."end
  kind=kind or "none"
  local item;ok,item=eligible(kind,id);if not ok then return false,item end
  local s=P.state
  if (s.tradeSequence or 0)>=1000000000 then return false,"Trade sequence is full; pending history has been preserved."end
  s.tradeSequence=(s.tradeSequence or 0)+1
  local probe={id=math.floor(F.Now()).."-"..s.tradeSequence.."-"..math.random(100000,999999),peer=peer,
    kind=kind,assetID=id,wire=T.Encode(kind,item),expires=clock()+20}
  T.probe=probe
  if not send("H",probe,"1")then T.probe=nil;changed();return false,T.lastError end
  changed("Checking the trade connection with "..peer..". Your assets stay available until their addon replies.");return true
end
local function completeProbe(id,sender)
  local probe=T.probe
  if not probe or id~=probe.id or norm(sender)~=norm(probe.peer)then return end
  if clock()>probe.expires then T.ExpireProbe();return end
  T.probe=nil
  local ok,msg=newAllowed();if not ok then changed(msg);return end
  local item;ok,item=eligible(probe.kind,probe.assetID)
  if not ok or T.Encode(probe.kind,item)~=probe.wire then
    changed("Your selected offer changed during the connection check. Choose an offer and request the trade again.");return
  end
  local t={id=probe.id,peer=probe.peer,role="A",rev=0}
  ok,msg=take(t,probe.kind,probe.assetID);if not ok then changed(msg);return end
  P.state.trade=t;T.reviewAfter=clock()+3
  if P.trade then P.trade.selection=nil end
  send("O",t,t.rev..","..t.wire)
  changed("Trade connection verified. Your offer is held until completion or safe cancellation.")
end
function T.Join(kind,id)
  T.ExpireProbe()
  if T.probe then return false,"Cancel your outgoing connection check before joining another trade."end
  local ok,msg=newAllowed();if not ok then return ok,msg end
  local invite=T.invite;if not invite then return false,"No trade request is waiting."end
  local t={id=invite.id,peer=invite.peer,role="B",rev=0,otherRev=invite.rev,remote=invite.wire}
  ok,msg=take(t,kind or "none",id);if not ok then return ok,msg end
  P.state.trade=t;T.invite=nil;send("O",t,t.rev..","..t.wire);changed("Review both offers, then Confirm.");return true
end
local function abort(t)
  record(t,"B");restore(t);P.state.trade=nil;send("B",t)
  changed("Trade cancelled. Your offered asset has been returned.")
end
function T.Cancel()
  local t=P.state.trade
  if not t then T.probe=nil;T.invite=nil;T.lastError=nil;changed("Trade request cancelled. No assets were held.");return true end
  if t.decision then return false,"This trade is committed. Retry to finish delivery; it cannot be refunded."end
  if t.role=="A"then abort(t)
  else t.cancel=true;send("X",t);changed("Cancellation requested. Your offer stays held until the other addon acknowledges it.")end
  return true
end
function T.Retry()
  local t=P.state.trade;if not t then return false,"No pending trade."end
  if clock()<(T.nextRetry or 0)then return false,"Wait a few seconds before retrying."end
  T.nextRetry=clock()+5
  if t.decision then send("C",t,pair(t))
  elseif t.cancel then send("X",t)
  else send("O",t,t.rev..","..t.wire);if t.ready then send("R",t,t.ready)end end
  return not T.lastError,T.lastError
end
function T.Receive(message,channel,sender)
  if not F.ready or T.broken or not readable(channel) or channel~="WHISPER" or not safe(sender,100)
    or not readable(message) or type(message)~="string" or #message>255 then return end
  local op,id,data=message:match("^([ORCAXBHQ])|(%d+%-%d+%-%d+)|([^|]+)$")
  if not op or #id>48 then return end
  if op=="H"then
    if data~="1" or clock()<(T.nextProbeReply or 0)then return end
    T.nextProbeReply=clock()+2;send("Q",{id=id,peer=sender},"1");return
  elseif op=="Q"then
    if data=="1"then completeProbe(id,sender)end
    return
  end
  local s=P.state;local t=s.trade;local old=s.tradeHistory[id]
  if not old and (not t or t.protocol==2)then return end
  if old and norm(old.peer)==norm(sender)then
    -- B acknowledges X/O only; never echo B to B. Terminal replies are throttled.
    if clock()<(T.nextReply or 0)then return end
    if old.outcome=="C" and op=="C" and data==old.pair then T.nextReply=clock()+1;send("A",{id=id,peer=sender})
    elseif old.outcome=="B" and (op=="X" or op=="O" or op=="R")then T.nextReply=clock()+1;send("B",{id=id,peer=sender})end
    return
  end
  if not t then
    if old or op~="O" or T.invite and (T.invite.id~=id or norm(T.invite.peer)~=norm(sender))then return end
    local rev,wire=data:match("^(%d+),(.+)$");rev=tonumber(rev)
    if not int(rev,1,9999) or not T.Decode(wire)then return end
    if T.invite then
      if rev>T.invite.rev then T.invite.rev=rev;T.invite.wire=wire;T.reviewAfter=clock()+3;changed()end
    elseif clock()>=(T.nextInvite or 0)then
      T.nextInvite=clock()+10;T.invite={id=id,peer=sender,rev=rev,wire=wire}
      F.Print("Trade request from "..sender..". Open Inspect > Trade or /cfpets trade to review.");changed()
    end
    return
  end
  if t.id~=id or norm(t.peer)~=norm(sender)then return end
  if T.receiveWindow~=math.floor(clock())then T.receiveWindow=math.floor(clock());T.receiveCount=0 end
  T.receiveCount=(T.receiveCount or 0)+1;if T.receiveCount>20 then return end
  if op=="O" and not t.decision and not t.cancel then
    local rev,wire=data:match("^(%d+),(.+)$");rev=tonumber(rev)
    if not int(rev,1,9999) or not T.Decode(wire)then return end
    if not t.otherRev or rev>t.otherRev then t.otherRev=rev;t.remote=wire;reset(t);changed("Offer updated. Review both offers again.")end
  elseif op=="R" and t.remote and data==pair(t) and not t.cancel and not t.decision then
    t.peerReady=data;decide(t);changed()
  elseif op=="C" and t.role=="B" and t.remote and data==pair(t) and t.ready==data then
    -- A cancel request can cross an already committed decision. Commit wins.
    t.decision="C";apply(t);send("A",t);finish(t)
  elseif op=="A" and t.role=="A" and t.decision=="C"then finish(t)
  elseif op=="X" and t.role=="A"then
    if t.decision then send("C",t,pair(t))else abort(t)end
  elseif op=="B" and t.role=="B" and not t.decision then
    record(t,"B");restore(t);s.trade=nil;changed("Trade cancelled. Your offered asset has been returned.")
  end
end
function T.Initialize()
  T.broken=nil;T.probe=nil;T.lastError=nil;T.reviewAfter=clock()+3
  local s=P.state;s.tradeHistory=s.tradeHistory or {}
  if type(s.tradeHistory)~="table" or (s.tradeSequence~=nil and not int(s.tradeSequence,0,1000000000))then T.broken=true;return end
  local count=0
  for id,h in pairs(s.tradeHistory)do
    count=count+1
    if count>2000 or not safe(id,48) or type(h)~="table" or not safe(h.peer,100) or (h.outcome~="C" and h.outcome~="B") or not safe(h.pair,24)then T.broken=true;return end
  end
  if s.trade then
    local t=s.trade
    if type(t)~="table" or not safe(t.id,48) or not safe(t.peer,100) or (t.role~="A" and t.role~="B")
      or not int(t.rev,1,9999) or not T.Decode(t.wire) or (t.remote and (not T.Decode(t.remote) or not int(t.otherRev,1,9999)))
      or (t.kind~="none" and not bucket(t.kind)) or T.Decode(t.wire).kind~=t.kind
      or (not t.applied and not validEscrow(t))
      or (t.applied and (t.decision~="C" or t.escrow~=nil))
      or (t.ready and (not t.remote or t.ready~=pair(t)))
      or (t.decision and (t.decision~="C" or not t.remote or t.ready~=pair(t)))then T.broken=true;return end
    P.notice="A pending trade was restored. Open Inspect > Trade to retry or safely cancel."
  end
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,T.prefix)
    local outcomes=Enum and Enum.RegisterAddonMessagePrefixResult
    T.registered=ok and readable(v) and (v==true or v==(outcomes and outcomes.Success or 0) or v==(outcomes and outcomes.DuplicatePrefix or 1))
  end
end
local events=CreateFrame("Frame");T.events=events;events:RegisterEvent("CHAT_MSG_ADDON")
events:SetScript("OnEvent",function(_,_,prefix,message,channel,sender)
  if readable(prefix) and prefix==T.prefix then T.Receive(message,channel,sender)end
end)
