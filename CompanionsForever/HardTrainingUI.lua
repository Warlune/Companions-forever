local _,F=...
local P,H,S=F.Pets,F.Pets.HardMode,F.Style
local function text(parent,value,x,y,w,h)
 local t=S.Text(parent,value,x,y,w,"GameFontHighlightSmall",S.gold);t:SetHeight(h);return t
end
local function clear(f)f.hardPending=false;f.hardReset=false;f.hardPurchase=false end
local build=P.BuildTalents
function P.BuildTalents()
 build();local f=P.talents;f.hardView=false;clear(f)
 f.hardToggle=S.Button(f.tree,"Hard-mode training",392,-508,198,function()
  f.hardView=not f.hardView;clear(f);f.plan=false;f.planBase=false;f.resetConfirm=nil;P.RenderTalents()
 end)
 local panel=S.Panel(f,0,0,960,548);f.hardTraining=panel
 panel:SetBackdropColor(.035,.025,.06,1)
 text(panel,"HARD-MODE TRAINING",20,-16,920,28):SetJustifyH("CENTER")
 panel.pointBox=S.Panel(panel,20,-50,610,44)
 panel.points=text(panel.pointBox,"",8,-4,594,36);panel.points:SetJustifyH("CENTER")
 panel.points:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",18,"OUTLINE")
 panel.buy=S.Button(panel,"Buy talent point",646,-58,294,function()
  local cost=H.TrainingPointCost()
  if not cost or P.state.battle or P.state.tokens<cost then return end
  clear(f);f.hardPurchase={owned=H.TrainingOwned(),revision=P.state.hardMode.trainingRevision};P.RenderTalents()
 end)
 panel.heading=text(panel,"",20,-96,920,22);panel.heading:SetJustifyH("CENTER")
 panel.nodes={}
 for i,node in ipairs(H.trainingNodes)do
  local key=node.key;local col,row=(i-1)%5,math.floor((i-1)/5)
  local b=CreateFrame("Button",nil,panel,"BackdropTemplate");panel.nodes[i]=b
  b:SetPoint("TOPLEFT",68+col*192,-128-row*86);b:SetSize(56,56)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",4,-4);b.art:SetPoint("BOTTOMRIGHT",-4,4);b.art:SetTexture("Interface\\Icons\\"..node.icon)
  b.rank=text(b,"",0,-36,56,18);b.rank:SetJustifyH("CENTER")
  b.rankBackdrop=b:CreateTexture(nil,"ARTWORK",nil,1);b.rankBackdrop:SetPoint("BOTTOMLEFT",4,2);b.rankBackdrop:SetPoint("BOTTOMRIGHT",-4,2);b.rankBackdrop:SetHeight(20);b.rankBackdrop:SetColorTexture(0,0,0,1);b.rankBackdrop:Hide()
  b.name=text(panel,node.name,10+col*192,-188-row*86,172,22);b.name:SetJustifyH("CENTER")
  b:SetScript("OnClick",function()
   local rank=H.TrainingRank(key)
   if H.IsUnlocked() and rank<4 and H.TrainingSpent()<H.TrainingOwned() and not P.state.battle then
    clear(f);f.hardPending={key=key,rank=rank,revision=P.state.hardMode.trainingRevision}
   end;P.RenderTalents()
  end)
  b:SetScript("OnEnter",function(self)
   P.ShowTalentTooltip(self,H.TrainingTooltip(node))
  end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
 end
 panel.confirm=S.Button(panel,"Select a talent",20,-414,610,function()
  local pending,reset,purchase=f.hardPending,f.hardReset,f.hardPurchase;clear(f)
  if reset then local ok,msg=H.RespecTraining(reset);P.notice=msg
  elseif purchase then local ok,msg=H.BuyTrainingPoint(purchase.owned,purchase.revision);P.notice=msg
  elseif pending then local ok,msg=H.AllocateTraining(pending.key,pending.rank,pending.revision);P.notice=msg end
  P.Render()
 end)
 panel.cancel=S.Button(panel,"Cancel",646,-414,294,function()clear(f);P.RenderTalents()end)
 panel.respec=S.Button(panel,"Respec: 500 tokens",20,-482,222,function()
  clear(f);f.hardReset=P.state.hardMode.trainingRevision;P.RenderTalents()
 end)
 text(panel,"Respec keeps purchased points.\nNormal talents stay unchanged.",258,-479,370,42)
 panel.back=S.Button(panel,"Back to trainer talents",646,-482,294,function()
  f.hardView=false;clear(f);P.RenderTalents()
 end)
 f:HookScript("OnHide",function()clear(f)end)
 panel:Hide();f.hardToggle:Hide()
end
local render=P.RenderTalents
function P.RenderTalents()
 render();local f=P.talents;if not f or not rawget(f,"hardTraining")or not f:IsShown()then return end
 local unlocked=H.IsUnlocked();f.hardToggle:SetShown(unlocked and rawget(f,"resetConfirm")~=true)
 if not unlocked then f.hardView=false;clear(f)end
 local show=f.hardView;local panel=f.hardTraining;panel:SetShown(show)
 f.tree:SetShown(not show);f.retirement:SetShown(not show)
 -- Keep the switch beside Reset, reserving the same space for reset's Cancel.
 for _,v in ipairs({{f.apply,16,unlocked and 76 or 110},{f.discard,unlocked and 100 or 134,unlocked and 68 or 100},{f.respec,unlocked and 176 or 244,unlocked and 208 or 226},{f.cancel,unlocked and 392 or 478,unlocked and 198 or 110}})do
  v[1]:ClearAllPoints();v[1]:SetPoint("TOPLEFT",f.tree,"TOPLEFT",v[2],-508);v[1]:SetWidth(v[3])
 end
 for _,button in ipairs({f.apply,f.discard,f.respec})do button:SetShown(not show)end
 f.cancel:SetShown(not show and not not f.resetConfirm)
 if not show then return end
 local revision=P.state.hardMode.trainingRevision
 if P.state.battle or f.hardPending and f.hardPending.revision~=revision or f.hardReset and f.hardReset~=revision or f.hardPurchase and f.hardPurchase.revision~=revision then clear(f)end
 local pending,reset,purchase=f.hardPending,f.hardReset,f.hardPurchase
 local spent,owned,cost=H.TrainingSpent(),H.TrainingOwned(),H.TrainingCost()
 local price=H.TrainingPointCost()
 panel.points:SetText("AVAILABLE POINTS: "..(owned-spent))
 panel.buy:SetText(price and "Buy 1 point: "..P.TokenText(price) or "All 16 points purchased")
 panel.buy:SetEnabled(price~=nil and not P.state.battle and P.state.tokens>=(price or 0))
 panel.heading:SetText(owned.." / 16 points purchased  |  "..spent.." allocated. "..(cost==nil and "Respec to try another build." or cost==0 and "Select a talent to spend a point." or "Buy a point to begin training."))
 for i,b in ipairs(panel.nodes)do
  local node=H.trainingNodes[i];local rank=H.TrainingRank(node.key);local selected=pending and pending.key==node.key
  b.art:SetDesaturated(rank==0 and not selected);b.rank:SetText(rank.."/4");b:SetEnabled(rank<4 and cost==0 and not P.state.battle)
  b.name:SetText((selected and "> " or "")..node.name)
  b.rankBackdrop:SetShown(S.HighContrast())
  if S.HighContrast()then b:SetBackdropBorderColor(1,1,selected and 0 or 1,1)
  else b:SetBackdropBorderColor(selected and .3 or rank==4 and 1 or .4,selected and .7 or rank==4 and .82 or .4,selected and 1 or .2,1)end
 end
 panel.confirm:SetText(reset and "Confirm respec: 500 tokens" or purchase and price and "Confirm purchase: "..P.TokenText(price) or pending and "Confirm allocation: 1 point" or cost==nil and "All 16 points allocated" or "Select a talent or buy a point")
 panel.confirm:SetEnabled(not P.state.battle and (reset~=false and P.state.tokens>=H.trainingRespecCost or not not purchase and price~=nil and P.state.tokens>=(price or 0) or not not pending and cost==0))
 panel.cancel:SetEnabled(not not pending or reset~=false or not not purchase)
 panel.respec:SetEnabled(spent>0 and P.state.tokens>=H.trainingRespecCost and not P.state.battle)
end
local retirement=P.OpenRetirement
function P.OpenRetirement(...)
 if P.talents then P.talents.hardView=false;clear(P.talents)end
 return retirement(...)
end
