-- Public, inspectable consistency checks. IDs and receipts are not signatures.
local _,F=...
local P,L=F.Pets,F.LegacyTrades
local I={limit=20000};F.Integrity=I
function I.Readable(v)
  if issecretvalue and issecretvalue(v)then return false end
  return not canaccessvalue or canaccessvalue(v)
end
function I.Safe(v,n)return I.Readable(v) and type(v)=="string" and #v>0 and #v<=n and not v:find("[|%c]")end
function I.Name(name)
  if not I.Safe(name,100)then return end
  if not name:find("-",1,true)then local realm=GetRealmName and GetRealmName();if not I.Safe(realm,80)then return end;name=name.."-"..realm end
  return name:lower():gsub("%s","")
end
function I.Owner()return I.Name(GetUnitName and GetUnitName("player",true)) or I.Name(F.name) or "unknown"end
function I.ValidID(id)return I.Safe(id,48) and id:match("^%x+%-%x+%-%x+$")~=nil end
local function integer(n,a,b)return type(n)=="number" and n==math.floor(n) and n>=a and n<=b end
function I.Fingerprint(kind,item)
  if kind=="pet"then return table.concat({"P",item.species,item.rarity,item.abilities and item.abilities[1] or 0,item.abilities and item.abilities[2] or 0},",")..(item.rolls and ":"..item.rolls or "")end
  return kind=="gear" and ("G,"..item.kind..","..item.rarity) or ("C,"..item.crate)
end
local function ledger()return P.state and P.state.integrity end
function I.Stamp(kind,item,origin)
  local s=ledger();if not s or I.broken then return end
  if not item.assetID then
    if I.count>=I.limit or s.sequence>=1000000000 then return end
    s.sequence=s.sequence+1
    local hash=7;local owner=I.Owner();for i=1,#owner do hash=(hash*131+owner:byte(i))%2147483647 end
    item.assetID=string.format("%x-%x-%x",hash,math.floor(F.Now()),s.sequence)
    item.assetRevision=0;item.assetOrigin=origin or "S"
  end
  local id=item.assetID
  if not I.ValidID(id) or not integer(item.assetRevision,0,1000000000) or not ({S=true,L=true})[item.assetOrigin]then return end
  if not s.records[id] and I.count<I.limit then
    s.records[id]={owner=I.Owner(),revision=item.assetRevision,fingerprint=I.Fingerprint(kind,item),status="owned"};I.count=I.count+1
  end
end
function I.Initialize()
  local state=P.state;I.broken=nil;I.count=0
  if state.integrity==nil then state.integrity={sequence=0,records={}}end
  local s=state.integrity
  if type(s)~="table" or not integer(s.sequence,0,1000000000) or type(s.records)~="table"then I.broken=true;return end
  for id,r in pairs(s.records)do
    I.count=I.count+1
    if I.count>I.limit or not I.ValidID(id) or type(r)~="table" or not I.Safe(r.owner,180) or not integer(r.revision,0,1000000000)
      or not I.Safe(r.fingerprint,100) or not ({owned=true,sent=true,consumed=true})[r.status]then I.broken=true;return end
  end
  for kind,key in pairs({pet="pets",gear="gear",crate="crates"})do for _,item in ipairs(state[key] or {})do I.Stamp(kind,item,"L")end end
  for _,entry in ipairs(state.mailbox or {})do
    I.Stamp(entry.kind,entry.item,"L")
    for _,item in ipairs(entry.gear or {})do I.Stamp("gear",item,"L")end
  end
  if F.History then F.History.IndexOrigins()end
  -- Old pending trades keep their exact old wire until recovered/cancelled.
end
function I.Encode(kind,item)
  local wire=L.Encode(kind,item);if wire=="N"then return wire end
  if not item.assetID then return wire end
  return wire.."~"..item.assetID.."~"..(item.assetRevision or 0).."~"..(item.assetOrigin or "L")
end
function I.Decode(wire)
  if not I.Safe(wire,205)then return end
  if not wire:find("~",1,true)then return L.Decode(wire)end
  local base,id,revision,origin=wire:match("^([^~]+)~([^~]+)~(%d+)~([SL])$")
  revision=tonumber(revision)
  if not base or not I.ValidID(id) or not integer(revision,0,999999999)then return end
  local e=L.Decode(base);if not e or not e.item then return end
  e.item.assetID=id;e.item.assetRevision=revision;e.item.assetOrigin=origin;return e
end
local function localIDs()
  local found={}
  for _,key in ipairs({"pets","gear","crates"})do for _,item in ipairs(P.state[key] or {})do
    if item.assetID then found[item.assetID]=(found[item.assetID] or 0)+1 end
  end end
  for _,entry in ipairs(P.state.mailbox or {})do
    local item=entry.item;if item.assetID then found[item.assetID]=(found[item.assetID] or 0)+1 end
    for _,gear in ipairs(entry.gear or {})do if gear.assetID then found[gear.assetID]=(found[gear.assetID] or 0)+1 end end
  end
  for _,e in ipairs(P.state.trade and P.state.trade.escrow or {})do if e.item.assetID then found[e.item.assetID]=(found[e.item.assetID] or 0)+1 end end
  return found
end
function I.Check(t)
  if not t.audit then return true end
  local s=ledger();if I.broken or not s then return false,"Asset history needs recovery. Your assets are preserved."end
  local known=localIDs();local seen={};local new=0
  for side,wires in ipairs({t.ownWires or {},t.remoteWires or {}})do for _,wire in ipairs(wires)do
    local e=I.Decode(wire)
    if not e then return false,"Invalid asset data."end
    if e.item then
      local item=e.item;local id=item.assetID
      if not I.ValidID(id)then return false,"Both players need the updated asset-history version. Cancel and update."end
      if seen[id]then return false,"The offer contains a duplicate asset ID."end;seen[id]=true
      local r=s.records[id];local owner=side==1 and I.Owner() or I.Name(t.peer)
      if not owner then return false,"The other player's identity is unavailable."end
      if (side==1 and known[id]~=1) or (side==2 and known[id])then return false,"This asset conflicts with an asset already in your collection."end
      if r and (r.status=="consumed" or (side==2 and r.status=="owned") or r.fingerprint~=I.Fingerprint(e.kind,item) or item.assetRevision<r.revision
        or (item.assetRevision==r.revision and r.owner~=owner) or (side==1 and r.status~="owned"))then
        return false,"Asset history conflicts with a saved receipt. Cancel and review; nothing has been deleted."
      end
      if not r then new=new+1 end
    end
  end end
  if I.count+new>I.limit then return false,"Asset history is full. Assets remain safe; trading is paused."end
  return true
end
function I.Apply(t,received)
  if not t.audit then for _,e in ipairs(received)do I.Stamp(e.kind,e.item,"L")end;return end
  local s=ledger();t.receipt={sent={},received={}}
  for _,e in ipairs(t.escrow or {})do
    local item=e.item;local id=item.assetID
    s.records[id]={owner=I.Name(t.peer),revision=item.assetRevision+1,fingerprint=I.Fingerprint(e.kind,item),status="sent",trade=t.id,birth=item.birth}
    t.receipt.sent[#t.receipt.sent+1]=id..":"..(item.assetRevision+1)
  end
  for _,e in ipairs(received)do
    local item=e.item;local id=item.assetID;item.assetRevision=item.assetRevision+1
    if not s.records[id]then I.count=I.count+1 end
    s.records[id]={owner=I.Owner(),revision=item.assetRevision,fingerprint=I.Fingerprint(e.kind,item),status="owned",trade=t.id,birth=item.birth}
    if F.History then F.History.RememberBirth(item)end
    t.receipt.received[#t.receipt.received+1]=id..":"..item.assetRevision
  end
end
function I.Consumed(kind,item)
  I.Stamp(kind,item,"L");local s=ledger();local r=s and s.records[item.assetID]
  if r then r.status="consumed" end
end
function I.Label(item)
  if not item or not item.assetID then return "Legacy / no asset history"end
  local r=ledger() and ledger().records[item.assetID]
  if r and r.status=="consumed"then return "History conflict"end
  if type(item.killWitnesses)=="table" and next(item.killWitnesses)then return "Party kill witnessed; rarity self-recorded"end
  return item.assetOrigin=="L" and "Legacy asset" or "Self-recorded origin"
end
