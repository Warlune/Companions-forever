local _,F=...
local P,I,H=F.Pets,F.Integrity,F.History
local A={prefix="CFHistory1"};F.HistoryPeers=A
local function clock()return GetTime and GetTime() or F.Now()end
local function integer(n,a,b)return type(n)=="number" and n==math.floor(n) and n>=a and n<=b end
local function epoch(v)return I.Safe(v,16) and #v==16 and v:match("^%x+$")~=nil end
local function send(body,target)
  if not A.registered or #body>255 then return false end
  local ok,v=pcall(C_ChatInfo.SendAddonMessage,A.prefix,body,"WHISPER",target)
  return ok and I.Readable(v) and (v==true or v==((Enum and Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success) or 0))
end
function A.Initialize()
  A.pending=nil;A.outbox=nil
  if type(F.char.historyPeers)~="table"then F.char.historyPeers={}end
  local count=0
  for name,e in pairs(F.char.historyPeers)do count=count+1
    if count>64 or not I.Safe(name,180) or type(e)~="table" or not epoch(e.epoch) or not integer(e.seq,0,1000000000)
      or not H.Digest(e.hash) or not integer(e.balance,0,P.maxTokens) or not I.Safe(e.status,50) or not I.Safe(e.reason,250) or not integer(e.seen,0,99999999999) or (e.conflict~=nil and not I.Safe(e.conflict,250))then F.char.historyPeers[name]=nil end
  end
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    local ok,v=pcall(C_ChatInfo.RegisterAddonMessagePrefix,A.prefix);A.registered=ok and I.Readable(v) and (v==true or v==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.Success) or 0) or v==((Enum and Enum.RegisterAddonMessagePrefixResult and Enum.RegisterAddonMessagePrefixResult.DuplicatePrefix) or 1))
  end
end
function A.Request(name)
  if not P.state.share or not I.Name(name) or clock()<(A.nextRequest or 0)then return end
  A.nextRequest=clock()+5
  local previous=F.char.historyPeers[I.Name(name)]
  local sequence=tonumber(F.char.historyRequestSequence) or 0;F.char.historyRequestSequence=sequence%1000000000+1
  local nonce=math.floor(F.Now()).."-"..F.char.historyRequestSequence
  local body=table.concat({"Q",nonce,previous and previous.epoch or "0",previous and previous.seq or 0,previous and previous.hash or "0",previous and previous.balance or 0},"|")
  if send(body,name)then A.pending={nonce=nonce,name=I.Name(name),previous=previous,expires=clock()+18,rows={}}end
end
local function snapshot(nonce,oldEpoch,seq,hash,balance,sender)
  H.Check();local h=P.state.tokenHistory;if H.broken or not h then return end
  local mode,rows="N",{}
  local start=h.anchor
  for _,r in ipairs(h.rows)do if r.seq==seq then start=r;break end end
  if oldEpoch==h.epoch and seq<=h.seq and h.seq-seq<=32 and start.seq==seq and start.hash==hash and start.balance==balance then
    mode="C";for _,r in ipairs(h.rows)do if r.seq>seq then rows[#rows+1]=r.wire end end
  end
  local flag=#h.conflicts>0 and "C" or h.legacy and "L" or "S"
  local messages={table.concat({"B",nonce,mode,h.epoch,h.seq,h.hash,h.expected,#rows,flag},"|")}
  for _,wire in ipairs(rows)do messages[#messages+1]="E|"..nonce.."|"..wire end
  A.outbox={messages=messages,target=sender,index=1,at=clock(),expires=clock()+12}
end
local function finish(q,sender)
  local b=q.header;if not b then return end
  local prior=q.previous;local status,reason="Limited history","Starting checkpoint saved. No prior history was available for comparison."
  local conflict
  if prior and prior.epoch==b.epoch then
    if b.seq<prior.seq then conflict="History is older than a previously observed checkpoint. A restored save may explain this."
    elseif b.seq==prior.seq and (b.hash~=prior.hash or b.balance~=prior.balance)then conflict="The same history checkpoint now has a different digest or balance."
    elseif b.mode=="C"then
      if b.seq-prior.seq~=b.count or (q.rowCount or 0)<b.count then return end
      local seq,hash,balance=prior.seq,prior.hash,prior.balance
      for i=1,b.count do
        local wire=q.rows[seq+1];if not wire then return end
        local row=H.Parse(wire)
        if row.balance~=balance+row.delta then conflict="The supplied token transactions do not add up.";break end
        hash=F.HistoryHash(hash.."/"..wire);seq,balance=row.seq,row.balance
      end
      if not conflict and (hash~=b.hash or balance~=b.balance)then conflict="The transaction chain does not match its advertised checkpoint."end
      if not conflict then status="No known conflicts";reason="Recent token transactions extend the checkpoint previously seen by your addon. This does not prove the rewards were earned."end
    else reason="A history gap exceeds the retained proof window. A new checkpoint was saved; the gap is not evidence of cheating."end
  elseif prior then reason="This player has a new history baseline, possibly after a reset or migration. Earlier continuity is unavailable."end
  if b.flag=="L" and status=="No known conflicts"then reason=reason.." Earlier balance is legacy."end
  if b.flag=="C" and not conflict then status="History conflict";reason="Their addon reports a local accounting mismatch. Your addon has not independently verified that claim."end
  if prior and prior.conflict then conflict=prior.conflict end
  if conflict then status="History conflict";reason=conflict end
  local key=I.Name(sender);local count,oldest=0
  for name,e in pairs(F.char.historyPeers)do count=count+1;if not oldest or (e.seen or 0)<(F.char.historyPeers[oldest].seen or 0)then oldest=name end end
  if count>=64 and not F.char.historyPeers[key] and oldest then F.char.historyPeers[oldest]=nil end
  -- A contradiction never replaces the last known good checkpoint.
  local result=conflict and prior or b
  F.char.historyPeers[key]={epoch=result.epoch,seq=result.seq,hash=result.hash,balance=result.balance,seen=F.Now(),status=status,reason=reason,conflict=conflict}
  A.pending=nil;if P.RenderInspect then P.RenderInspect()end
end
function A.Receive(message,channel,sender)
  if not F.ready or not P.state or not P.state.share or not I.Readable(channel) or channel~="WHISPER" or not I.Safe(sender,100)
    or not I.Readable(message) or type(message)~="string" or #message>255 then return end
  local nonce,oldEpoch,seq,hash,balance=message:match("^Q|(%d+%-%d+)|([^|]+)|(%d+)|([^|]+)|(%d+)$")
  if nonce then
    seq,balance=tonumber(seq),tonumber(balance)
    if #nonce>26 or not integer(seq,0,1000000000) or not integer(balance,0,P.maxTokens) or not ((oldEpoch=="0" and hash=="0" and seq==0) or (epoch(oldEpoch) and H.Digest(hash)))
      or A.outbox or clock()<(A.nextReply or 0)then return end
    A.nextReply=clock()+5;snapshot(nonce,oldEpoch,seq,hash,balance,sender);return
  end
  local q=A.pending;if not q or clock()>q.expires or I.Name(sender)~=q.name then return end
  local op,token,body=message:match("^([BE])|(%d+%-%d+)|(.+)$");if token~=q.nonce then return end
  if op=="B"then
    local mode,ep,n,digest,value,count,flag=body:match("^([CN])|(%x+)|(%d+)|(%x+)|(%d+)|(%d+)|([CLS])$")
    n,value,count=tonumber(n),tonumber(value),tonumber(count)
    if not epoch(ep) or not H.Digest(digest) or not integer(n,0,1000000000) or not integer(value,0,P.maxTokens) or not integer(count,0,32) or (mode=="N" and count~=0)then return end
    if mode=="C" and (not q.previous or q.previous.epoch~=ep or n-q.previous.seq~=count)then return end
    if q.header and q.header.raw~=body then A.pending=nil;return end
    q.header={mode=mode,epoch=ep,seq=n,hash=digest,balance=value,count=count,flag=flag,raw=body}
  elseif op=="E"then
    local e=H.Parse(body);if not e or not q.previous or e.seq<=q.previous.seq or e.seq>q.previous.seq+32 then return end
    if q.rows[e.seq] then if q.rows[e.seq]~=body then A.pending=nil end;return end
    q.rows[e.seq]=body;q.rowCount=(q.rowCount or 0)+1
  end
  finish(q,sender)
end
function A.Status(name)
  local e=F.char.historyPeers[I.Name(name) or ""]
  if not e then return "Limited history","No history checkpoint received. Both addons need the update and sharing enabled."end
  return e.status,e.reason.."\nLast checked "..math.max(0,F.Now()-(e.seen or F.Now())).." seconds ago."
end
function A.Pump()
  if not P.state or not P.state.share then A.pending=nil;A.outbox=nil;return end
  if A.pending and clock()>A.pending.expires then A.pending=nil end
  local q=A.outbox;if not q or clock()<q.at then return end
  if clock()>q.expires then A.outbox=nil;return end
  if send(q.messages[q.index],q.target)then q.index=q.index+1;q.at=clock()+0.2 else q.at=clock()+1 end
  if q.index>#q.messages then A.outbox=nil end
end
local frame=CreateFrame("Frame");frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent",function(_,_,prefix,message,channel,sender)if I.Readable(prefix) and prefix==A.prefix then A.Receive(message,channel,sender)end end)
frame:SetScript("OnUpdate",function()if A.pending or A.outbox then A.Pump()end end)
