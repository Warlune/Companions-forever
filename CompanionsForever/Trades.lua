local _,F=...
local P,L,I,H=F.Pets,F.LegacyTrades,F.Integrity,F.History
local T={prefix="CFTrade2",Encode=I and I.Encode or L.Encode,Decode=I and I.Decode or L.Decode,Eligible=L.Eligible};F.Trades=T
local function readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
local function safe(v,n)return readable(v) and type(v)=="string" and #v>0 and #v<=n and not v:find("[|%c]")end
local function int(n,a,b)return type(n)=="number" and n==math.floor(n) and n>=a and n<=b end
local function catalog()return P.hardAbilityCatalog and "19" or P.hardGearCatalog and "18" or P.xpTreatCatalog and "17" or P.soulbindingCatalog and "16" or P.sparklyCatalog and "15" or P.controlAbilityCatalog and "14" or F.Achievements and F.Achievements.adventureCatalog and "13" or P.petRollVersion and "12" or P.equipmentCrates and "11" or P.specialCrates and "10" or (#P.specialAbilities>6) and "9" or P.HardMode and "8" or F.Achievements and "7" or H and "6" or I and "5" or "3" end
local function clock()return GetTime and GetTime() or F.Now()end
local function norm(name)
  if not safe(name,100)then return end
  if not name:find("-",1,true)then name=name.."-"..(GetRealmName and GetRealmName() or "")end
  return name:lower():gsub("%s","")
end
local function changed(msg)if msg then P.notice=msg end;if P.Render then P.Render()end end
local function legacy()return P.state and type(P.state.trade)=="table" and P.state.trade.protocol~=2 end
T.IsLegacy=legacy
local function bucket(kind)return kind=="pet" and "pets" or kind=="gear" and "gear" or kind=="crate" and "crates"end
local function counts(wires,key)
  local n=0
  for _,wire in ipairs(type(wires)=="table" and wires or {})do local e=T.Decode(wire)
    if e and (e.kind==key or key=="bag" and (e.kind=="gear" or e.kind=="crate"))then n=n+1 end
  end
  return n
end
function T.RecordReserved(kind)
  if legacy()then return L.RecordReserved(kind)end
  local t=P.state and P.state.trade;if type(t)~="table" or t.applied then return 0 end
  return math.max(counts(t.ownWires,kind),counts(t.remoteWires,kind))
end
function T.Reserved(kind)
  if legacy()then return L.Reserved(kind)end
  local t=P.state and P.state.trade
  if kind=="bag" and P.StackReservation and type(t)=="table" and not t.applied then
    return math.max(P.StackReservation(t.ownWires,T.Decode),P.StackReservation(t.remoteWires,T.Decode))
  end
  return T.RecordReserved(kind)
end
function T.BlockReason()
  if legacy()then return L.BlockReason()end
  if T.broken then return "Your pending trade needs recovery. Its assets have been preserved."end
  if not T.registered or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return "Trade messaging is unavailable. Reload both updated addons."end
  -- Do not interpret the realm flag as unconditional failure. Respect active
  -- lockdown, then require a real send result and an authenticated round trip.
  if C_ChatInfo.InChatMessagingLockdown then
    local ok,v=pcall(C_ChatInfo.InChatMessagingLockdown)
    if not ok or not readable(v)then return "Messaging availability is unknown. Retry outside combat."end
    if v then return "WoW chat messaging lockdown is active. Retry outside combat or restricted instances."end
  end
end
local function send(op,t,data)
  local why=T.BlockReason();if why then T.lastError=why;return false end
  local message=op.."|"..t.id.."|"..(data or "0")
  if #message>255 then T.lastError="Trade packet exceeded the message limit.";return false end
  local ok,v=pcall(C_ChatInfo.SendAddonMessage,T.prefix,message,"WHISPER",t.peer)
  local e=Enum and Enum.SendAddonMessageResult
  if ok and readable(v) and (v==true or v==(e and e.Success or 0))then T.lastError=nil;return true end
  if ok and readable(v) and v==(e and e.AddOnMessageLockdown or 11)then
    T.lastError="WoW rejected the message because messaging is locked. Retry outside combat or restricted instances."
  elseif ok and readable(v) and v==(e and e.TargetOffline or 12)then T.lastError="The other player is offline."
  else T.lastError="WoW did not accept the message. Retry delivery when messaging is available."end
  return false
end
local function pair(t)return t.role=="A" and (t.rev..","..t.otherRev) or (t.otherRev..","..t.rev)end
local function reset(t)t.ready=nil;t.peerReady=nil;T.reviewAfter=clock()+3 end
function T.Seconds()return legacy() and L.Seconds() or math.max(0,math.ceil((T.reviewAfter or clock()+3)-clock()))end
local function validWires(wires)
  if type(wires)~="table" or #wires~=9 then return false end
  local n=0;for k,w in pairs(wires)do n=n+1;if not int(k,1,9) or not T.Decode(w)then return false end end
  return n==9
end
local function keys(entries)
  local result={};for _,e in ipairs(entries or {})do result[#result+1]={kind=e.kind,id=e.item and e.item.id or e.id}end;return result
end
local function normalize(value,id)
  if type(value)=="table"then return value end
  return value and value~="none" and {{kind=value,id=id}} or {}
end
-- Validate the complete selection before any mutation. Retained held entries
-- are matched by identity; new entries must still be eligible inventory.
local function prepare(selection,t)
  if type(selection)~="table" or #selection>9 then return nil,"Each side has nine trade slots."end
  local held={};for _,e in ipairs(t and t.escrow or {})do held[e.kind..":"..e.item.id]=e end
  local result,wires,seen={},{},{}
  for i,ref in ipairs(selection)do
    if type(ref)~="table" or not bucket(ref.kind) or not int(ref.id,1,1000000000)then return nil,"Invalid trade selection."end
    local key=ref.kind..":"..ref.id;if seen[key]then return nil,"That asset is already offered."end;seen[key]=true
    local item,wire;local prior=held[key]
    if prior then item=prior.item;wire=prior.wire
    else local ok,v=T.Eligible(ref.kind,ref.id);if not ok then return nil,v end;item=v;if I and not t then I.Stamp(ref.kind,item,"L")end;wire=(t and not t.audit and L.Encode or T.Encode)(ref.kind,item)end
    if t and not t.xpTreatCatalog and ref.kind=="crate" and P.xpTreats and P.xpTreats[item.crate]then return nil,"Finish this older trade before offering XP treats."end
    if t and not t.equipmentCrateCatalog and ref.kind=="crate" and P.equipmentCrates and P.equipmentCrates[item.crate]then return nil,"Finish this older trade before offering equipment crates."end
    if t and not t.specialCatalog and ((ref.kind=="pet" and item.species==2363) or (ref.kind=="crate" and item.crate==12))then return nil,"Finish this older trade before offering Unda's pet or crate."end
    if t and not t.adventureCatalog and ref.kind=="pet" and item.species>=2364 then return nil,"Finish the older trade before offering new achievement pets."end
    if t and not t.sparklyCatalog and ref.kind=="pet" and P.IsSparkly and P.IsSparkly(item)then return nil,"Both players must update before trading Sparkly pets."end
    if t and not t.rollCatalog and ref.kind=="pet" and item.rolls then return nil,"Finish the older trade before offering pets with new rolls."end
    if t and not t.hardAbilityCatalog and ref.kind=="pet"then for _,id in ipairs(item.abilities or {})do if P.specialAbilities[id] and P.specialAbilities[id].hardOnly then return nil,"Both players must update before trading hard-mode abilities."end end end
    if t and not t.controlCatalog and ref.kind=="pet"then for _,id in ipairs(item.abilities or {})do if id>36 then return nil,"Both players must update before trading this ability."end end end
    if t and not t.abilityCatalog and ref.kind=="pet"then for _,id in ipairs(item.abilities or {})do if id>6 then return nil,"Finish the older trade before offering newly expanded abilities."end end end
    if t and not t.hardGearCatalog and ref.kind=="gear" and P.gearTypes[item.kind].expandedHardGear then return nil,"Finish this older trade before offering the new hard-mode equipment."end
    if t and not t.hardCatalog and ref.kind=="gear" and (P.gearTypes[item.kind].hardSet or P.gearTypes[item.kind].hardTier) then return nil,"Finish this older trade before offering hard-mode equipment."end
    if t and not t.catalog48 and ((ref.kind=="gear" and item.kind>15) or (ref.kind=="crate" and item.crate>7))then return nil,"Finish this older trade before offering new equipment or pouches."end
    result[i]={kind=ref.kind,item=item,wire=wire};wires[i]=wire
  end
  for i=#wires+1,9 do wires[i]="N"end
  if I and (not t or t.audit)then
    local ok,msg=I.Check({audit=true,ownWires=wires,remoteWires={}});if not ok then return nil,msg end
  end
  return result,wires
end
local function restore(t)
  for _,e in ipairs(t.escrow or {})do local list=P.state[bucket(e.kind)];list[#list+1]=e.item end
  t.escrow={}
end
local function take(t,selection)
  local entries,wires=prepare(selection,t);if not entries then return false,wires end
  restore(t)
  for _,e in ipairs(entries)do local list=P.state[bucket(e.kind)]
    for i,item in ipairs(list)do if item==e.item then table.remove(list,i);break end end
  end
  t.escrow=entries;t.ownWires=wires
  if t.provenance then t.ownBirths={};for i=1,9 do t.ownBirths[i]=H.BirthWire(entries[i] and entries[i].item)end end
  t.rev=t.rev+1;reset(t);return true
end
local function offer(t)
  T.outbox={id=t.id,peer=t.peer,rev=t.rev,wires=t.ownWires,births=t.provenance and t.ownBirths,index=1,nextAt=clock(),failures=0}
end
local function capacity(t)
  if P.CheckSoulboundOffer then local ok,why=P.CheckSoulboundOffer(t);if not ok then return false,why end end
  if t.incoming or not t.remoteWires then return false,"Waiting for all nine slots of the other offer."end
  if P.state.battle then return false,"Finish the tower battle first."end
  if counts(t.ownWires,"pet")+counts(t.ownWires,"bag")+counts(t.remoteWires,"pet")+counts(t.remoteWires,"bag")==0 then
    return false,"Add an item or pet to at least one side."
  end
  if P.StableCount()>P.stableCapacity or P.BagCount()>P.BagCapacity()then return false,"Make enough stable and bag space for the entire offer."end
  local s=P.state
  if #s.pets+T.RecordReserved("pet")>512 or #s.gear+T.RecordReserved("gear")>500 or #s.crates+T.RecordReserved("crate")>(P.maxCrateRecords or 100)
    or s.nextID+counts(t.remoteWires,"pet")>1000000 or s.nextGearID+counts(t.remoteWires,"bag")>1000000001 then
    return false,"Your collection records cannot hold the entire offer."
  end
  for _,w in ipairs(t.remoteWires)do local e=T.Decode(w)
    if e.kind=="pet" and e.item.level>P.LevelCap()then return false,"An offered pet exceeds your pet level cap."end
  end
  if H and t.provenance then
    if not t.remoteBirths then return false,"Waiting for reward origins."end
    local ok,why=H.CheckOfferOrigins(t.remoteWires,t.remoteBirths,T.Decode);if not ok then return false,why end
    for i=1,9 do
      for side,wires in ipairs({t.ownWires,t.remoteWires})do
        local e=T.Decode(wires[i]);local birth=(side==1 and t.ownBirths or t.remoteBirths)[i]
        local ok,why=H.CheckBirth(e.item,birth);if not ok then return false,why end
      end
    end
  end
  if I then return I.Check(t)end
  return true
end
function T.CanConfirm()
  if legacy()then return false,"Finish the previous version's pending trade with Retry or Cancel."end
  local t=P.state and P.state.trade
  if not t or t.ready or t.cancel or t.decision then return false,"Waiting for the other player."end
  local why=T.BlockReason();if why then return false,why end
  local ok,msg=capacity(t);if not ok then return false,msg end
  if T.outbox then return false,"Sending all nine slots of your offer."end
  if T.Seconds()>0 then return false,"Review both offers before confirming."end
  return true
end
local function record(t,result)
  P.state.tradeHistory[t.id]={peer=t.peer,outcome=result,pair=t.remoteWires and pair(t) or "0",protocol=2,receipt=t.receipt}
end
local function apply(t)
  if t.applied then return end
  local received={};local s=P.state
  for i,wire in ipairs(t.remoteWires)do local e=T.Decode(wire);local item=e.item
    if item and t.provenance and t.remoteBirths[i]~="N" then item.birth=t.remoteBirths[i]end
    if item then
      item.isNew=true;item.source="Trade";item.found=F.Now()
      if e.kind=="pet"then item.id=s.nextID;s.nextID=s.nextID+1
      else item.id=s.nextGearID;s.nextGearID=s.nextGearID+1 end
      local list=s[bucket(e.kind)];list[#list+1]=item;received[#received+1]=e
    end
  end
  if I then I.Apply(t,received)end
  t.escrow={};t.applied=true;T.outbox=nil
  if H then H.Event("TRADE",t.id)end
  for _,e in ipairs(received)do if e.kind=="pet"then
    P.RecordDiscovery(e.item.species,e.item.rarity,"Trade")
    if P.RecordAbilityDiscovery then P.RecordAbilityDiscovery(e.item)end
    if P.IsSparkly and P.IsSparkly(e.item)then P.state.collection[e.item.species].sparkly=true end
  end end
  P.FindHistory("Trade with "..t.peer..": received "..#received.." assets")
end
local function finish(t)
  record(t,"C");P.state.trade=nil;T.outbox=nil;T.invite=nil;T.draft={}
  changed("Trade complete with "..t.peer..".");F.Print(P.notice)
end
local function decide(t)
  if t.role=="A" and not t.cancel and not t.decision and not t.incoming and t.remoteWires
    and t.ready==pair(t) and t.peerReady==pair(t)then
    local ok,msg=capacity(t);if not ok then reset(t);changed(msg);return end
    t.decision="C";apply(t);send("C",t,pair(t));changed("Trade committed. Waiting for delivery acknowledgement.")
  end
end
function T.Confirm()
  local ok,msg=T.CanConfirm();if not ok then return false,msg end
  local t=P.state.trade;t.ready=pair(t);send("R",t,t.ready);decide(t);changed();return true
end
function T.Editable()
  if legacy() or T.broken or T.probe then return false end
  local t=P.state.trade;return not t or not(t.ready or t.cancel or t.decision)
end
function T.Change(value,id)
  if not T.Editable()then return false,"Your offer is locked. Wait for the connection or safely cancel the trade."end
  if P.state.battle then return false,"Finish the battle first."end
  local selection=normalize(value,id);local t=P.state.trade
  if not t then
    local entries,msg=prepare(selection);if not entries then return false,msg end
    T.draft=keys(entries);changed();return true
  end
  if t.rev>=9999 then return false,"Cancel this trade and start another."end
  local ok,msg=take(t,selection);if not ok then return false,msg end
  offer(t);changed("Offer changed. Both players must wait three seconds and confirm again.");return true
end
function T.Add(kind,id)
  local t=P.state.trade;local selection=t and not legacy() and keys(t.escrow) or keys(T.draft)
  if #selection>=9 then return false,"Your nine trade slots are full."end
  selection[#selection+1]={kind=kind,id=id};return T.Change(selection)
end
function T.Remove(slot)
  local t=P.state.trade;local selection=t and not legacy() and keys(t.escrow) or keys(T.draft)
  if not int(slot,1,#selection)then return false,"That trade slot is empty."end
  table.remove(selection,slot);return T.Change(selection)
end
local function allowed()
  if P.state.trade then return false,"Finish or cancel your pending trade first."end
  if P.state.battle then return false,"Finish the battle first."end
  local why=T.BlockReason();if why then return false,why end
  local n=0;for _ in pairs(P.state.tradeHistory)do n=n+1 end
  if n>=2000 or (P.state.tradeSequence or 0)>=1000000000 then return false,"Trade history is full and has been preserved against replay."end
  return true
end
function T.ExpireProbe()
  if T.probe and clock()>T.probe.expires then
    T.probe=nil;T.lastError="No connection reply. Both players need the same current addon version and working addon whispers. No assets were held.";changed(T.lastError)
  end
end
local function dismissed(invite)
  T.dismissed=T.dismissed or {};local count,oldest,oldestAt=0
  for key,untilTime in pairs(T.dismissed)do
    if untilTime<clock()then T.dismissed[key]=nil
    else count=count+1;if not oldestAt or untilTime<oldestAt then oldest,oldestAt=key,untilTime end end
  end
  if count>=64 and oldest then T.dismissed[oldest]=nil end
  T.dismissed[invite.id..":"..norm(invite.peer)]=clock()+180
end
function T.ExpireInvite()
  local invite=T.invite
  if invite and clock()>invite.expires then
    T.invite=nil;dismissed(invite)
    if invite.wires then send("X",invite)end
    changed("Trade invitation expired. Ask for a new request.")
  end
end
function T.Start(peer,value,id)
  T.ExpireInvite()
  if T.invite then return false,"Join or decline the incoming trade request first."end
  T.ExpireProbe();if T.probe then return false,"Wait for the connection check or cancel it."end
  local ok,msg=allowed();if not ok then return false,msg end
  if not safe(peer,100) or norm(peer)==norm(GetUnitName and GetUnitName("player",true) or "")then return false,"Target another player."end
  local entries,wires=prepare(value==nil and (T.draft or {}) or normalize(value,id));if not entries then return false,wires end
  local s=P.state;s.tradeSequence=(s.tradeSequence or 0)+1
  local probe={id=math.floor(F.Now()).."-"..s.tradeSequence.."-"..math.random(100000,999999),peer=peer,
    selection=keys(entries),wires=wires,expires=clock()+20}
  T.probe=probe
  if not send("H",probe,catalog())then T.probe=nil;return false,T.lastError end
  changed("Checking the trade connection. Items and pets stay available until the other addon replies.");return true
end
local function connected(id,sender)
  local p=T.probe;if not p or p.id~=id or norm(p.peer)~=norm(sender)then return end
  if clock()>p.expires then T.ExpireProbe();return end
  T.probe=nil
  local ok,msg=allowed();if not ok then changed(msg);return end
  local entries,wires=prepare(p.selection)
  if not entries or table.concat(wires,";")~=table.concat(p.wires,";")then changed("Your offer changed during the connection check. Select it again.");return end
  local t={protocol=2,hardAbilityCatalog=P.hardAbilityCatalog==true,hardGearCatalog=P.hardGearCatalog==true,xpTreatCatalog=P.xpTreatCatalog==true,soulboundRules=P.soulbindingCatalog==true,audit=I~=nil,catalog48=true,hardCatalog=P.HardMode~=nil,abilityCatalog=#P.specialAbilities>6,specialCatalog=P.specialCrates~=nil,equipmentCrateCatalog=P.equipmentCrates~=nil,rollCatalog=P.petRollVersion~=nil,controlCatalog=P.controlAbilityCatalog==true,sparklyCatalog=P.sparklyCatalog==true,adventureCatalog=F.Achievements and F.Achievements.adventureCatalog or false,provenance=H~=nil,id=p.id,peer=p.peer,role="A",rev=0,escrow={}}
  ok,msg=take(t,p.selection);if not ok then changed(msg);return end
  P.state.trade=t;T.draft={};offer(t);changed("Connection verified. Offered assets are held until completion or safe cancellation.")
end
function T.Join(value,id)
  T.ExpireInvite()
  T.ExpireProbe();if T.probe then return false,"Cancel your outgoing connection check first."end
  local ok,msg=allowed();if not ok then return false,msg end
  local invite=T.invite;if not invite or not invite.wires or invite.incoming then return false,"Waiting for the complete trade request."end
  local t={protocol=2,hardAbilityCatalog=P.hardAbilityCatalog==true,hardGearCatalog=P.hardGearCatalog==true,xpTreatCatalog=P.xpTreatCatalog==true,soulboundRules=P.soulbindingCatalog==true,audit=I~=nil,catalog48=true,hardCatalog=P.HardMode~=nil,abilityCatalog=#P.specialAbilities>6,specialCatalog=P.specialCrates~=nil,equipmentCrateCatalog=P.equipmentCrates~=nil,rollCatalog=P.petRollVersion~=nil,controlCatalog=P.controlAbilityCatalog==true,sparklyCatalog=P.sparklyCatalog==true,adventureCatalog=F.Achievements and F.Achievements.adventureCatalog or false,provenance=H~=nil,id=invite.id,peer=invite.peer,role="B",rev=0,escrow={},otherRev=invite.rev,remoteWires=invite.wires,remoteBirths=invite.births}
  if P.CheckSoulboundOffer then ok,msg=P.CheckSoulboundOffer(t);if not ok then return false,msg end end
  ok,msg=take(t,value==nil and (T.draft or {}) or normalize(value,id));if not ok then return false,msg end
  P.state.trade=t;T.invite=nil;T.draft={};offer(t);changed("Review both 3x3 offers, then Confirm.");return true
end
local function abort(t)
  record(t,"B");restore(t);P.state.trade=nil;T.outbox=nil;T.draft={};send("B",t)
  changed("Trade cancelled. Every offered asset has been returned.")
end
function T.Cancel()
  if T.broken then return false,T.BlockReason()end
  if legacy()then return L.Cancel()end
  local t=P.state.trade
  if not t then
    local invite=T.invite;T.probe=nil;T.invite=nil;T.draft={};T.lastError=nil
    -- Tell the requester to release its escrow too. Declining never confirms.
    if invite then dismissed(invite);send("X",invite)end
    changed(invite and "Trade invitation declined." or "Trade request cancelled. No assets were held.");return true
  end
  if t.decision then return false,"This trade is committed. Retry delivery; it cannot be refunded."end
  if t.role=="A"then abort(t)
  else t.cancel=true;T.outbox=nil;send("X",t);changed("Cancellation requested. Assets remain held until the other addon replies.")end
  return true
end
function T.Retry()
  if T.broken then return false,T.BlockReason()end
  if legacy()then return L.Retry()end
  local t=P.state.trade;if not t then return false,"No pending trade."end
  if clock()<(T.nextRetry or 0)then return false,"Wait a few seconds before retrying."end;T.nextRetry=clock()+5
  if t.decision then local ok=send("C",t,pair(t));return ok,T.lastError
  elseif t.cancel then local ok=send("X",t);return ok,T.lastError
  else offer(t);return true end
end
function T.Pump()
  T.ExpireProbe();T.ExpireInvite()
  local q=T.outbox;if not q or clock()<q.nextAt then return end
  local t=P.state.trade
  if not t or t.id~=q.id or t.rev~=q.rev or t.decision or t.cancel then T.outbox=nil;return end
  local index=q.index>9 and q.index-9 or q.index
  if send(q.index>9 and "V" or "O",q,q.rev..","..index..","..(q.index>9 and q.births[index] or q.wires[index]))then
    q.index=q.index+1;q.failures=0;q.nextAt=clock()+0.15
    if q.index>(q.births and 18 or 9) then T.outbox=nil;if t.ready then send("R",t,t.ready)end;changed()end
  else
    q.failures=q.failures+1;q.nextAt=clock()+2
    if q.failures>=5 then T.outbox=nil;changed("Sending paused. Assets remain held; use Retry delivery.")end
  end
end
-- A new fragment revokes approval immediately; only a complete bounded snapshot
-- can become confirmable. Older revisions never overwrite a newer offer.
local function fragment(holder,rev,slot,wire,current)
  if rev<=current then return false end
  if not holder.incoming or rev>holder.incoming.rev then holder.incoming={rev=rev,parts={},count=0};if holder.protocol then reset(holder)end end
  local incoming=holder.incoming;if rev~=incoming.rev then return false end
  if not incoming.parts[slot]then incoming.parts[slot]=wire;incoming.count=incoming.count+1
  elseif incoming.parts[slot]~=wire then return false end
  if incoming.count==(holder.provenance and 18 or 9)then
    local parts,births={},{};for i=1,9 do parts[i]=incoming.parts[i];births[i]=incoming.parts[i+9]end
    holder.incoming=nil;return parts,holder.provenance and births or nil
  end
  return false
end
function T.Receive(message,channel,sender)
  if not F.ready or T.broken or not readable(channel) or channel~="WHISPER" or not safe(sender,100)
    or not readable(message) or type(message)~="string" or #message>255 then return end
  -- Apply the budget before parsing assets or assembling unsolicited invitations.
  if T.receiveWindow~=math.floor(clock())then T.receiveWindow=math.floor(clock());T.receiveCount=0 end
  T.receiveCount=(T.receiveCount or 0)+1;if T.receiveCount>60 then return end
  local op,id,data=message:match("^([ORCAXBHQV])|(%d+%-%d+%-%d+)|([^|]+)$");if not op or #id>48 then return end
  T.ExpireInvite()
  if op=="H"then
    -- If both players request at once, one yields to the same peer's request.
    -- Neither side has escrow during a probe; the local draft remains intact.
    if data==catalog() and T.probe and norm(T.probe.peer)==norm(sender) then
      local me=norm(GetUnitName and GetUnitName("player",true) or "")
      if me and me>norm(sender)then T.probe=nil;T.recipient=sender else return end
    end
    if data==(catalog()) and clock()>=(T.nextHelloReply or 0)then T.nextHelloReply=clock()+2;send("Q",{id=id,peer=sender},catalog())end;return
  elseif op=="Q"then if data==(catalog())then connected(id,sender)end;return end
  local s=P.state;local t=s.trade;local old=s.tradeHistory[id]
  if old then
    if old.protocol~=2 or norm(old.peer)~=norm(sender) or clock()<(T.nextReply or 0)then return end
    if old.outcome=="C" and op=="C" and data==old.pair then T.nextReply=clock()+1;send("A",{id=id,peer=sender})
    elseif old.outcome=="B" and (op=="X" or op=="O" or op=="R")then T.nextReply=clock()+1;send("B",{id=id,peer=sender})end
    return
  end
  if legacy()then return end
  local rev,slot,wire
  if op=="O" or op=="V"then
    rev,slot,wire=data:match("^(%d+),(%d+),(.+)$");rev,slot=tonumber(rev),tonumber(slot)
    if not int(rev,1,9999) or not int(slot,1,9) or not (op=="V" and H and H.DecodeBirth(wire) or op=="O" and T.Decode(wire))then return end
    if op=="V"then
      if t and not t.provenance then return end;slot=slot+9
    end
    local e=op=="O" and T.Decode(wire)
    if I and (not t or t.audit) and e and e.item and not e.item.assetID then return end
  end
  if not t then
    if op=="B" and T.invite and T.invite.id==id and norm(T.invite.peer)==norm(sender)then T.invite=nil;changed();return end
    if T.dismissed and (T.dismissed[id..":"..norm(sender)] or 0)>=clock()then return end
    if (op~="O" and op~="V") or T.probe or T.invite and (T.invite.id~=id or norm(T.invite.peer)~=norm(sender))then return end
    if not T.invite then
      if clock()<(T.nextInvite or 0)then return end
      T.nextInvite=clock()+10;T.invite={id=id,peer=sender,provenance=H~=nil,rev=0,expires=clock()+120}
    end
    local invite=T.invite;local wires,births=fragment(invite,rev,slot,wire,invite.rev)
    if wires then
      invite.wires=wires;invite.births=births;invite.rev=rev;T.reviewAfter=clock()+3
      if not invite.notified then invite.notified=true;F.Print("Trade request from "..sender..". Click the invitation or your mini alert to open it. /cfpets trade also works.")end
      changed("Trade request ready from "..sender..".")
    end
    return
  end
  if t.id~=id or norm(t.peer)~=norm(sender)then return end
  if (op=="O" or op=="V") and not t.decision and not t.cancel then
    local wires,births=fragment(t,rev,slot,wire,t.otherRev or 0)
    if wires then t.remoteWires=wires;t.remoteBirths=births;t.otherRev=rev;reset(t);changed("Offer updated. Review all nine slots again.")end
  elseif op=="R" and t.remoteWires and not t.incoming and not t.cancel and not t.decision and data==pair(t)then
    t.peerReady=data;decide(t);changed()
  elseif op=="C" and t.role=="B" and t.remoteWires and not t.incoming and data==pair(t) and t.ready==data then
    t.decision="C";apply(t);send("A",t);finish(t)
  elseif op=="A" and t.role=="A" and t.decision=="C"then finish(t)
  elseif op=="X" and t.role=="A"then if t.decision then send("C",t,pair(t))else abort(t)end
  elseif op=="B" and t.role=="B" and not t.decision then record(t,"B");restore(t);s.trade=nil;T.outbox=nil;changed("Trade cancelled. All offered assets returned.")end
end
function T.OwnEntries()
  if legacy()then return {}end
  local t=P.state.trade;if t then local out={};for i,w in ipairs(t.ownWires or {})do out[i]=T.Decode(w);if H and out[i].item then out[i].item.birth=t.ownBirths and t.ownBirths[i] or nil end end;return out end
  local refs,entries={},{}
  for _,ref in ipairs(T.draft or {})do local ok,item=T.Eligible(ref.kind,ref.id)
    if ok then refs[#refs+1]=ref;entries[#entries+1]={kind=ref.kind,item=item}end
  end
  T.draft=refs;return entries
end
function T.OtherEntries()
  if legacy()then return {}end
  local t=P.state.trade;local wires=t and t.remoteWires or T.invite and T.invite.wires;local out={}
  for i,w in ipairs(wires or {})do out[i]=T.Decode(w);local births=t and t.remoteBirths or T.invite and T.invite.births;if out[i].item and births then out[i].item.birth=births[i] end end;return out
end
function T.Initialize()
  T.broken=nil;T.probe=nil;T.outbox=nil;T.draft={};T.invite=nil;T.lastError=nil;T.reviewAfter=clock()+3
  local s=P.state;s.tradeHistory=s.tradeHistory or {}
  if I and I.broken then T.broken=true;return end
  if type(s.tradeHistory)~="table" or (s.tradeSequence~=nil and not int(s.tradeSequence,0,1000000000))then T.broken=true;return end
  local count=0
  for id,h in pairs(s.tradeHistory)do count=count+1
    if count>2000 or not safe(id,48) or type(h)~="table" or not safe(h.peer,100) or (h.outcome~="C" and h.outcome~="B") or not safe(h.pair,24)then T.broken=true;return end
  end
  if legacy()then L.Initialize();T.broken=L.broken
  elseif s.trade then
    local t=s.trade
    if type(t)~="table" or t.protocol~=2 or not safe(t.id,48) or not safe(t.peer,100) or (t.role~="A" and t.role~="B")
      or not int(t.rev,1,9999) or not validWires(t.ownWires) or type(t.escrow)~="table" or #t.escrow>9
      or (t.remoteWires and (not validWires(t.remoteWires) or not int(t.otherRev,1,9999)))then T.broken=true;return end
    if t.provenance then
      if type(t.ownBirths)~="table" or #t.ownBirths~=9 or (t.remoteWires and (type(t.remoteBirths)~="table" or #t.remoteBirths~=9))then T.broken=true;return end
      for i=1,9 do if not H.DecodeBirth(t.ownBirths[i]) or (t.remoteWires and not H.DecodeBirth(t.remoteBirths[i]))then T.broken=true;return end end
    end
    if not t.applied then
      local seen={}
      for i,e in ipairs(t.escrow)do
        if type(e)~="table" or not bucket(e.kind) or type(e.item)~="table" or not int(e.item.id,1,1000000000)then T.broken=true;return end
        local key=e.kind..":"..e.item.id;local ok,w=pcall(t.audit and T.Encode or L.Encode,e.kind,e.item)
        if seen[key] or not ok or not T.Decode(w) or w~=t.ownWires[i] or w~=e.wire then T.broken=true;return end
        if t.provenance and H.BirthWire(e.item)~=t.ownBirths[i]then T.broken=true;return end
        seen[key]=true
      end
      for i=#t.escrow+1,9 do if t.ownWires[i]~="N"then T.broken=true;return end end
    elseif not t.decision or #t.escrow>0 then T.broken=true;return end
    if (t.ready and (not t.remoteWires or t.ready~=pair(t))) or (t.decision and (t.decision~="C" or t.ready~=pair(t)))then T.broken=true;return end
    if t.incoming then t.incoming={rev=(t.otherRev or 0)+1,parts={},count=0};t.ready=nil;t.peerReady=nil end
    P.notice="Pending trade restored. Open /cfpets trade and Retry delivery."
  end
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    for _,channel in ipairs({T,L})do
      local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,channel.prefix)
      local outcomes=Enum and Enum.RegisterAddonMessagePrefixResult
      channel.registered=ok and readable(v) and (v==true or v==(outcomes and outcomes.Success or 0) or v==(outcomes and outcomes.DuplicatePrefix or 1))
    end
  end
end
local events=CreateFrame("Frame");T.events=events;events:RegisterEvent("CHAT_MSG_ADDON")
events:SetScript("OnEvent",function(_,_,prefix,message,channel,sender)if readable(prefix) and prefix==T.prefix then T.Receive(message,channel,sender)end end)
events:SetScript("OnUpdate",function()if T.outbox or T.probe or T.invite then T.Pump()end end)
