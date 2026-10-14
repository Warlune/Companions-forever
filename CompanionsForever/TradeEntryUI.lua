local _,F=...
local P,T,S,I=F.Pets,F.Trades,F.Style,F.Integrity
local E={};F.TradeEntry=E
local function now()return GetTime and GetTime() or F.Now()end
local function invitation()
  local v=T.invite
  return v and v.wires and v.expires>=now() and not P.state.trade and v
end
local function report(ok,why)
  if not ok and why then P.notice=why;F.Print(why)end
  P.Render();return ok,why
end
function E.Request(name)
  if not I.Safe(name,100) or F.Inspect.IsSelf(name)then return report(false,"Select another player in Inspect first.")end
  if P.state.trade or T.probe then P.OpenTrade();return true end
  if invitation()then return E.Join()end
  T.recipient=name;P.OpenTrade()
  return report(T.Start(name))
end
function E.Join(id,peer)
  local v=invitation()
  if not v or (id and (v.id~=id or I.Name(v.peer)~=I.Name(peer)))then return report(false,"That invitation changed or expired. Open the current request.")end
  if v.incoming then return report(false,"The offer is updating. Wait for it to finish.")end
  T.recipient=v.peer
  -- A hidden draft must be reviewed before moving any of its assets into escrow.
  if #(T.draft or {})>0 then P.OpenTrade();return true end
  local ok,why=T.Join({})
  if ok then P.OpenTrade()end
  return report(ok,why)
end
function E.Decline(id,peer)
  local v=invitation()
  if not v or v.id~=id or I.Name(v.peer)~=I.Name(peer)then return report(false,"That invitation is no longer pending.")end
  return report(T.Cancel())
end
function E.FromInspect()
  if P.state.trade or T.probe then P.OpenTrade();return end
  if invitation()then E.Join();return end
  E.Request(P.inspectName)
end
local function tooltip(button,title,body)
  button:SetScript("OnEnter",function()
    GameTooltip:SetOwner(button,"ANCHOR_TOP");GameTooltip:SetText(title)
    GameTooltip:AddLine(body,1,1,1,true);GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
function E.Build()
  if E.card then return end
  local w=S.Panel(UIParent,0,0,460,198);E.card=w
  w:ClearAllPoints();w:SetPoint("TOP",UIParent,"TOP",0,-120)
  S.RegisterWindow(w,6);w:EnableMouse(true)
  w.icon=w:CreateTexture(nil,"ARTWORK");w.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
  w.icon:SetSize(34,34);w.icon:SetPoint("TOPLEFT",16,-16)
  S.Text(w,"TRADE REQUEST",60,-16,384,"GameFontNormalLarge",S.gold)
  w.name=S.Text(w,"",16,-56,428,"GameFontNormalLarge",S.gold);w.name:SetMaxLines(1)
  w.info=S.Text(w,"",16,-89,428,"GameFontHighlightSmall");w.info:SetHeight(50)
  w.join=S.Button(w,"Join trade",16,-150,136,function()E.Join(w.inviteID,w.peer)end)
  w.view=S.Button(w,"View offer",162,-150,136,function()P.OpenTrade()end)
  w.decline=S.Button(w,"Decline",308,-150,136,function()E.Decline(w.inviteID,w.peer)end)
  tooltip(w.join,"Join trade","Opens the trade window. No items change owners until both players confirm. A prepared offer opens for review first.")
  tooltip(w.view,"View offer","Open the request without joining or changing your offer.")
  tooltip(w.decline,"Decline request","Dismiss this invitation and notify the sender to return their offered items.")
  w:Hide()
end
function E.Update()
  if not P.state then if E.card then E.card:Hide()end;return end
  local v=invitation();local t=P.state.trade;local probe=T.probe
  local key=v and (v.id or "")..":"..v.peer or t and t.id or probe and probe.id or false
  if key~=E.directoryKey then E.directoryKey=key;P.inspectDirectoryUntil=0 end
  if v then
    E.Build();local w=E.card;w.inviteID=v.id;w.peer=v.peer
    w.name:SetText(v.peer)
    local why=T.BlockReason()
    w.info:SetText(P.state.battle and "Finish your tower battle to join. You can view the offer now." or why or v.incoming and "Offer updating..." or
      ("Expires in "..math.max(0,math.ceil(v.expires-now())).."s. Joining does not confirm the trade."))
    w.join:SetEnabled(not P.state.battle and not why and not v.incoming)
    w.join:SetText(#(T.draft or {})>0 and "Review offer" or "Join trade")
    local textHeight=w.info:GetStringHeight()
    local infoHeight=type(textHeight)=="number" and math.max(50,textHeight+6) or 50
    w.info:SetHeight(infoHeight);w:SetHeight(148+infoHeight)
    for index,button in ipairs({w.join,w.view,w.decline})do
      button:ClearAllPoints();button:SetPoint("TOPLEFT",16+(index-1)*146,-100-infoHeight)
    end
    w:SetScale(F.AccessibleScale(1,460,148+infoHeight));w:SetShown(not (P.mode=="trade" and P.window and P.window:IsShown()))
    if E.announced~=key then
      E.announced=key
      if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN then pcall(PlaySound,SOUNDKIT.IG_MAINMENU_OPEN,"SFX")end
    end
  elseif E.card then E.card:Hide()end
  local f=P.inspect
  if f and rawget(f,"tradeButton")then
    local name=P.inspectName
    f.tradeButton:SetText((t or probe) and "Open trade" or v and "Join trade" or "Request trade")
    f.tradeButton:SetEnabled(not not (t or probe or v or (I.Safe(name,100) and not F.Inspect.IsSelf(name))))
    if f:IsShown()then
      if v then f.status:SetText("Trade request from "..v.peer..". Join trade, or use the invitation to view or decline.")
      elseif probe then f.status:SetText("Connecting to "..probe.peer.."... Open trade to follow the request.")
      elseif t then f.status:SetText("Trade with "..t.peer.." is open. Click Open trade to return.")end
    end
  end
end
local render=P.Render
function P.Render()render();E.Update()end
local inspect=P.RenderInspect
function P.RenderInspect()inspect();E.Update()end
local alerts=F.Social.Alerts
function F.Social.Alerts()alerts();E.Update()end
