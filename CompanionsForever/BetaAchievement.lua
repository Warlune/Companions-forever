local _,F=...
local P,A,H=F.Pets,F.Achievements,F.History
-- Turn enrollment off in the launch build; keep this account record when
-- wiping realm adventures so the badge and payment cannot be earned twice.
A.betaEnrollmentOpen=true
A.betaAchievement=true
local id="foreverBeta"
local d={id=id,name="Forever Companion Beta Tester",text="Play the Companions Forever beta. Thank you for helping shape the adventure!",metric="betaParticipant",goal=1,tokens=1000,icon="INV_Letter_15",order=#A.list+1}
A.list[#A.list+1]=d;A.byID[id]=d
local function record()
  if F.db.foreverBeta==nil then F.db.foreverBeta={}end
  if type(F.db.foreverBeta)~="table"then return end
  local r=F.db.foreverBeta
  local a=P.state and P.state.achievements
  if a and a.claimed[id] then r.earned=true;r.paid=true end
  return r
end
local initialize=A.Initialize
function A.Initialize()
  initialize()
  local r=record();if not r then return end
  if A.betaEnrollmentOpen then r.earned=true end
  if r.paid then
    P.state.achievements.claimed[id]=true;P.state.achievements.paid[id]={tokens=1000}
  end
end
local progress=A.Progress
function A.Progress(entry)
  if entry.id==id then local r=record();return r and r.earned and 1 or 0 end
  return progress(entry)
end
local help=A.ProgressHelp
function A.ProgressHelp(entry)
  if entry.id==id then return "Awarded for playing the beta. Grants 1,000 companion tokens once per addon account, across characters and realms. The beta badge and claim record are kept separately from realm progress."end
  return help(entry)
end
local settled=A.Settled
function A.Settled(entry)
  if entry.id==id then local r=record();return not r or r.paid==true end
  return settled(entry)
end
local claim=A.Claim
function A.Claim(key)
  if key~=id then return claim(key)end
  local r=record();local s=P.state
  if not r or r.paid or A.claiming then return false,"This beta reward has already been claimed or needs recovery."end
  if not r.earned then return false,"This achievement is for beta participants."end
  if s.battle or s.trade then return false,"Finish your battle or trade before claiming rewards."end
  if s.tokens>P.maxTokens-1000 then return false,"Spend some tokens first. Your reward will wait here."end
  if H.broken or not H.Check(s) or s.tokenHistory.seq>=1000000000 then return false,"Token history needs recovery. Your reward will wait here."end
  A.claiming=true
  local tokens,history=s.tokens,s.tokenHistory;s.tokenHistory=F.AccountSave.Copy(history)
  local ok,receipt,amount=pcall(P.ChangeTokens,1000,"ACHIEVEMENT",id)
  if not ok or not receipt or amount~=1000 then
    s.tokens,s.tokenHistory=tokens,history;A.claiming=nil
    return false,"Could not save the reward receipt. Your reward remains unclaimed."
  end
  r.paid=true;s.achievements.claimed[id]=true;s.achievements.paid[id]={tokens=1000}
  A.claiming=nil;P.notice="Forever Companion Beta Tester: "..P.TokenText(1000)..". Thank you for playing!"
  F.Print(P.notice);return true
end
