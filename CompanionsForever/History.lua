local _,F=...
local P,I=F.Pets,F.Integrity
local H={limit=256,origins={}};F.History=H
local function integer(n,a,b)return type(n)=="number" and n==math.floor(n) and n>=a and n<=b end
function H.Digest(v)return I.Safe(v,64) and #v==64 and v:match("^%x+$")~=nil end
local function ref(v)return type(v)=="string" and #v<=60 and v:match("^[%w%-:]*$")~=nil end
function H.Parse(wire)
  if not I.Safe(wire,160)then return end
  local seq,delta,balance,code,key=wire:match("^(%d+),(%-?%d+),(%d+),([A-Z]+),([%w%-:]*)$")
  seq,delta,balance=tonumber(seq),tonumber(delta),tonumber(balance)
  if not integer(seq,1,1000000000) or not integer(delta,-P.maxTokens,P.maxTokens) or not integer(balance,0,P.maxTokens) or #code>16 or not ref(key)then return end
  return {seq=seq,delta=delta,balance=balance,code=code,ref=key,wire=wire}
end
function H.Append(s,delta,code,key)
  local h=s.tokenHistory;if not h or H.broken or h.seq>=1000000000 then return end
  code=type(code)=="string" and code:match("^[A-Z]+$") and code:sub(1,16) or "OTHER"
  key=ref(key) and key or ""
  local seq=h.seq+1
  local wire=table.concat({seq,delta,s.tokens,code,key},",")
  local hash=F.HistoryHash(h.hash.."/"..wire)
  local row={seq=seq,balance=s.tokens,hash=hash,wire=wire}
  h.rows[#h.rows+1]=row;h.seq=seq;h.hash=hash;h.expected=s.tokens
  if #h.rows>H.limit then local old=table.remove(h.rows,1);h.anchor={seq=old.seq,hash=old.hash,balance=old.balance}end
  return {seq=seq,hash=hash,ref=h.epoch.."-"..seq}
end
function H.Check(s)
  s=s or P.state;local h=s and s.tokenHistory
  if not h or H.broken then return false end
  if s.tokens~=h.expected then
    h.conflicts=h.conflicts or {};if #h.conflicts>=8 then table.remove(h.conflicts,1)end
    h.conflicts[#h.conflicts+1]="Unexplained balance change: "..h.expected.." -> "..s.tokens.." tokens. A restored or edited save can cause this."
    H.Append(s,s.tokens-h.expected,"UNEXPLAINED","")
    return false
  end
  return true
end
function H.Initialize(s,fresh)
  H.broken=nil
  if not s.tokenHistory then
    F.db.historySequence=(tonumber(F.db.historySequence) or 0)+1
    local epoch=F.HistoryHash(I.Owner()..":"..F.Now()..":"..F.db.historySequence):sub(1,16)
    local hash=F.HistoryHash(epoch..":"..s.tokens)
    s.tokenHistory={epoch=epoch,seq=0,hash=hash,expected=s.tokens,rows={},anchor={seq=0,hash=hash,balance=s.tokens},legacy=not fresh,conflicts={}}
  end
  local h=s.tokenHistory
  if type(h)~="table" or not I.Safe(h.epoch,16) or #h.epoch~=16 or not h.epoch:match("^%x+$") or not integer(h.seq,0,1000000000)
    or not H.Digest(h.hash) or not integer(h.expected,0,P.maxTokens) or type(h.rows)~="table" or #h.rows>H.limit or type(h.anchor)~="table"
    or not integer(h.anchor.seq,0,h.seq) or not integer(h.anchor.balance,0,P.maxTokens) or not H.Digest(h.anchor.hash)then H.broken=true;return end
  local seq,hash,balance=h.anchor.seq,h.anchor.hash,h.anchor.balance
  for _,row in ipairs(h.rows)do
    local e=type(row)=="table" and H.Parse(row.wire)
    if not e or e.seq~=seq+1 or e.balance~=balance+e.delta or row.seq~=e.seq or row.balance~=e.balance or not H.Digest(row.hash)then H.broken=true;return end
    hash=F.HistoryHash(hash.."/"..e.wire);if hash~=row.hash then H.broken=true;return end
    seq,balance=e.seq,e.balance
  end
  if seq~=h.seq or hash~=h.hash or balance~=h.expected then H.broken=true;return end
  if type(h.conflicts)~="table"then h.conflicts={}end
  local cleaned={};for _,reason in ipairs(h.conflicts)do if #cleaned<8 and I.Safe(reason,180)then cleaned[#cleaned+1]=reason end end;h.conflicts=cleaned
  H.Check(s)
end
function H.Event(code,key)H.Check();return H.Append(P.state,0,code,key)end
function H.Purchase(code,index,cost)
  local receipt=P.ChangeTokens(-cost,code,tostring(index))
  return type(receipt)=="table" and receipt or nil
end
-- Compact immutable provenance travels in separate trade fragments, not in a
-- user-supplied Lua table. A receipt is a claim with checkable consistency, not a signature.
function H.Birth(item,code,parent,index,cost,receipt)
  if not item or not item.assetID then return end
  receipt=receipt or H.Event("REWARD",item.assetID)
  if not receipt then return end
  local wire=table.concat({code,parent or receipt.ref,index or 0,cost or 0,receipt.hash},",")
  if not H.DecodeBirth(wire)then return end
  item.birth=wire
  local r=P.state.integrity and P.state.integrity.records[item.assetID];if r then r.birth=wire end
  H.RememberBirth(item)
end
function H.DecodeBirth(wire)
  if wire=="N"then return {}end
  if not I.Safe(wire,170)then return end
  local code,parent,index,cost,hash=wire:match("^([BPEDR]),([%w%-:]+),(%d+),(%d+),(%x+)$")
  index,cost=tonumber(index),tonumber(cost)
  if not code or not ref(parent) or not integer(index,0,75) or not integer(cost,0,100000) or not H.Digest(hash)then return end
  if code=="P" and (not F.PetData.packs[index] or F.PetData.packs[index].cost~=cost)then return end
  if code=="E" and (not P.equipmentBoxes[index] or P.equipmentBoxes[index].cost~=cost)then return end
  local special=P.specialCrates and P.specialCrates[index]
  if code=="B" and (not I.ValidID(parent) or (not integer(index,1,6) and not special and not (P.equipmentCrates and P.equipmentCrates[index])) or cost~=0)then return end
  if code=="D" and ((index~=7 and not special) or cost~=0)then return end
  if code=="R" and cost~=0 then return end
  return {code=code,parent=parent,index=index,cost=cost,hash=hash}
end
function H.BirthWire(item)return item and H.DecodeBirth(item.birth) and item.birth or "N"end
local function originKey(b)
  if b and b.code=="B"then return "crate:"..b.parent end
  if b and (b.code=="P" or b.code=="E")then return "purchase:"..b.parent end
end
function H.RememberBirth(item)
  local key=originKey(H.DecodeBirth(item.birth));if not key then return end
  local prior=H.origins[key]
  if prior~=nil and prior~=item.assetID then H.origins[key]=false else H.origins[key]=item.assetID end
end
function H.IndexOrigins()
  H.origins={};if I.broken then return end
  local records=P.state.integrity and P.state.integrity.records
  for id,r in pairs(records or {})do H.RememberBirth({assetID=id,birth=r.birth})end
end
function H.CheckBirth(item,wire)
  if I.broken then return false,"Asset history needs recovery. Your assets are preserved."end
  local b=H.DecodeBirth(wire);if not b then return false,"Invalid reward origin."end
  if not item then return wire=="N","An empty slot cannot have a reward origin."end
  local equipment=P.equipmentCrates and P.equipmentCrates[b.index]
  if ((b.code=="P" or b.code=="B" and not equipment) and not item.species)
    or ((b.code=="E" or b.code=="B" and equipment) and not item.kind)then return false,"Reward origin does not match this item type."end
  local special=P.specialCrates and P.specialCrates[b.index]
  if special and ((b.code=="B" and (item.species~=special.species or item.rarity~=special.rarity)) or (b.code=="D" and item.crate~=b.index))then return false,"Gift contents do not match their receipt."end
  local r=item and item.assetID and P.state.integrity.records[item.assetID]
  if r and r.birth and r.birth~=wire then return false,"Reward origin differs from a saved receipt."end
  local key=originKey(b);local known=key and H.origins[key]
  if known~=nil and known~=item.assetID then return false,"This source already created a different reward."end
  if b.code=="B" then
    local parent=P.state.integrity.records[b.parent]
    if parent and parent.child and parent.child~=item.assetID then return false,"This crate already created a different reward."end
  end
  return true
end
function H.CheckOfferOrigins(wires,births,decode)
  local seen={}
  for i,wire in ipairs(wires)do
    local item=decode(wire).item;local key=originKey(H.DecodeBirth(births[i]))
    if item and key then
      if seen[key] and seen[key]~=item.assetID then return false,"Two offered rewards claim the same crate or purchase."end
      seen[key]=item.assetID
    end
  end
  return true
end
function H.DescribeBirth(item)
  local b=item and H.DecodeBirth(item.birth)
  if not b or not b.code then return "Limited history: no reward-origin receipt. Older items remain usable."end
  local labels={P="Purchased pet crate",E="Purchased equipment box",B="Opened bag crate",D="Developer gift",R="Self-recorded reward"}
  return labels[b.code].."\nSource ID: "..b.parent..(b.cost>0 and ("\nRecorded cost: "..b.cost.." tokens") or "").."\nReceipt: "..b.hash:sub(1,16).."...\nPreserved through trades; not proof of honest earning."
end
function H.Details()
  local status,reason=H.LocalStatus();local h=P.state.tokenHistory
  local lines={reason,"Balance: "..P.state.tokens.." tokens"}
  local labels={ACHIEVEMENT="Achievement reward",MOB="Enemy reward",TOWER="Tower reward",ONLINE="Online reward",PARTY="Party bonus",POUCH="Coin pouch",SALE="Equipment sale",PETCRATE="Pet crate purchase",GEARBOX="Equipment box",BAGSLOT="Bag expansion",SUPPLIES="Supplies",RESPEC="Talent respec",DEV="Developer grant",DEVGIFT="Developer gift",BATTLEHERB="Battle herbs",BOSS="Boss reward",MIGRATION="Upgrade refund",UNEXPLAINED="Unexplained adjustment"}
  if type(h)=="table" and type(h.rows)=="table"then local count=0
    for i=#h.rows,1,-1 do local e=type(h.rows[i])=="table" and H.Parse(h.rows[i].wire)
      if e and e.delta~=0 then lines[#lines+1]=(labels[e.code] or "Recorded change")..": "..(e.delta>0 and "+" or "")..e.delta.." tokens";count=count+1;if count==6 then break end end
    end
  end
  return status,table.concat(lines,"\n")
end
function H.LocalStatus()
  H.Check();local h=P.state.tokenHistory
  if H.broken then return "History conflict","Local accounting record is unreadable. Progress is preserved; no accusation is made."end
  if h and #h.conflicts>0 then return "History conflict",table.concat(h.conflicts,"\n")end
  return h and h.legacy and "Limited history" or "No known conflicts",h and h.legacy and "Existing tokens became a starting checkpoint. Older earnings cannot be reconstructed." or "Recorded token changes agree with the current balance. This is not proof of honest earning."
end
