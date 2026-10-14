local _,F=...
local I,P,M,A=F.Housing.Island,F.Pets,F.Mailbox,F.AccountSave
local id='housingLandRefund250'
table.insert(M.letters,1,{id=id,subject='A little land-price mix-up!',sender='Tommy Nookle - Companion Real Estate',
 body='Brr-bip, na-na! Hello, island neighbor!\n\nWhile checking my books, I found a little miscalculation. I was adding 500 to each new plot\'s price instead of 250. Oh dear... bip-brr!\n\nYour first expansion still costs 500, then 750, then 1,000, and so on. I\'ve attached the extra Bells you paid... uh, um... I mean gold tokens!\n\nSorry for the mix-up. May your island grow and your pockets stay happy! Na-na, bip!\n\nTommy Nookle\nCompanion Real Estate'})
local function valid(record)
 return type(record)=='table'and type(record.amount)=='number'and record.amount==math.floor(record.amount)and record.amount>=0 and record.amount<=69000
end
local function record()
 if not F.db or not P.state then return end
 local scope=A.Identity();local root=F.db[id]
 local r=scope and type(root)=='table'and root[scope]
 if not valid(r)then return nil end
 local saved=P.state and P.state[id]
 if valid(saved)then
  r.claimed=r.claimed==true or saved.claimed==true
  r.read=r.read==true or saved.read==true;r.deleted=r.deleted==true or saved.deleted==true
 end
 P.state[id]=r;return r
end
function I.LandRefundAmount(land)
 local expansions=-1;for _ in pairs(land)do expansions=expansions+1 end
 expansions=math.max(0,math.min(24,expansions))
 -- Old expansion k cost 500*k; new cost is 500+250*(k-1).
 return 125*expansions*(expansions-1)
end
function I.PrepareLandRefund()
 if not F.ready or not P.state then return end
 local scope=A.Identity();if not scope then return end
 if F.db[id]==nil then F.db[id]={}end
 local root=F.db[id];if type(root)~='table'then return end
 if root[scope]==nil then
  local saved=P.state[id]
  root[scope]=valid(saved)and A.Copy(saved)or {amount=I.LandRefundAmount(I.LandState())}
 end
 return record()
end
local initialize=F.Initialize
function F.Initialize(...)
 local result=initialize(...);I.PrepareLandRefund();return result
end
local merge=A.Merge
function A.Merge(shared,source)
 local out=merge(shared,source)
 local a,b=out[id],source[id]
 if valid(a)and valid(b)then a.claimed=a.claimed==true or b.claimed==true;a.read=a.read==true or b.read==true;a.deleted=a.deleted==true or b.deleted==true
 elseif not valid(a)and valid(b)then out[id]=A.Copy(b)end
 return out
end
local deleted,read,mark,remove=M.LetterDeleted,M.LetterRead,M.MarkRead,M.Delete
function M.LetterDeleted(key)
 if key~=id then return deleted(key)end
 local r=record();return not r or r.amount==0 or r.deleted==true
end
function M.LetterRead(key)if key~=id then return read(key)end;local r=record();return not r or r.read==true end
function M.MarkRead(key)if key==id then local r=record();if r then r.read=true end end;return mark(key)end
function M.Delete(entry)
 local ok,why=remove(entry)
 if ok and entry.id==id then local r=record();if r then r.deleted=true end end
 return ok,why
end
local attachments,has,collect=M.Attachments,M.HasAttachments,M.Collect
function M.HasAttachments(entry)
 if type(entry)~='table'or entry.kind~='letter'or entry.id~=id then return has(entry)end
 local r=record();return r~=nil and r.amount>0 and not r.claimed
end
function M.Attachments(entry)
 if type(entry)~='table'or entry.kind~='letter'or entry.id~=id then return attachments(entry)end
 if not M.HasAttachments(entry)then return {}end
 local amount=record().amount
 return {{name=amount..' gold',icon='INV_Misc_Coin_01',rarity=1,count=amount,description='Refund for your earlier land expansions.'}}
end
function M.Collect(entry)
 if type(entry)~='table'or entry.kind~='letter'or entry.id~=id then return collect(entry)end
 local r=record();local s=P.state;local H=F.History
 if not r or r.amount==0 or r.claimed or M.claiming then return false,'This refund has already been collected or is not available.'end
 if s.battle or s.trade then return false,'Finish your battle or trade before collecting mail.'end
 if s.tokens>P.maxTokens-r.amount then return false,'Spend some gold first. Your full refund will wait here.'end
 if not H.Check(s)or H.broken or s.tokenHistory.seq>=1000000000 then return false,'Gold history needs recovery. Your refund will wait here.'end
 local balance,history=s.tokens,A.Copy(s.tokenHistory)
 M.claiming=true
 local ok,receipt,paid=pcall(P.ChangeTokens,r.amount,'LANDREFUND','price250')
 M.claiming=nil
 if not ok or type(receipt)~='table'or paid~=r.amount then
  s.tokens=balance;s.tokenHistory=history;return false,'Could not collect the refund. Please try again.'
 end
 r.claimed=true;r.read=true
 return true,'Collected '..r.amount..' gold from Companion Real Estate.'
end
