local _,F=...
local P,S,T=F.Pets,F.Style,F.Trades
local function label(e)
  if not e or not e.item then return "Empty trade slot"end
  local item=e.item;local name=e.kind=="pet" and P.PetName(item) or P.BagDefinition(item).name
  local c=P.colors[item.rarity or 2]
  return string.format("|cff%02x%02x%02x%s|r",math.floor(c[1]*255),math.floor(c[2]*255),math.floor(c[3]*255),name)
end
local function details(e)
  if not e or not e.item then return "Up to nine pets, items or unopened crates per side. Either side may offer nothing as a gift."end
  local item=e.item
  if e.kind=="pet"then return P.rarities[item.rarity].." | Level "..item.level.." | XP "..item.xp.."\n"..P.Specialty(item).."\n"..P.AbilityText(item)..
    "\nHealth "..math.floor(item.health).."% | Food "..math.floor(item.food).."% | Energy "..math.floor(item.energy).."%\nTrading unlocks the recipient's collection. The sender keeps their discovery."end
  return P.BagDescription(item)
end
local function act(fn,...)
  local ok,msg=fn(...);if not ok and msg then P.notice=msg;F.Print(msg)end;P.Render()
end
local function text(parent,value,x,y,w,h)
  local f=S.Text(parent,value,x,y,w,"GameFontHighlightSmall");f:SetHeight(h);return f
end
local function panel(parent,x,y,w,h)
  local bg=parent:CreateTexture(nil,"BACKGROUND");bg:SetPoint("TOPLEFT",x,y);bg:SetSize(w,h);bg:SetColorTexture(0.065,0.06,0.08,1)
end
local function slot(parent,x,y,size,kind,index)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(size,size)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  b:SetBackdropColor(0.045,0.04,0.055,1);b:SetBackdropBorderColor(0.3,0.3,0.3,1)
  b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",3,-3);b.art:SetPoint("BOTTOMRIGHT",-3,3)
  b.mark=text(b,"",1,-size+17,size-2,16);b.mark:SetJustifyH("CENTER")
  b.locks={}
  for _,v in ipairs({{0,-4,12,9},{-4,2,3,7},{4,2,3,7},{0,6,9,3}})do
    local p=b:CreateTexture(nil,"OVERLAY");p:SetColorTexture(0.65,0.56,0.36,1);p:SetSize(v[3],v[4]);p:SetPoint("CENTER",v[1],v[2]);b.locks[#b.locks+1]=p;p:Hide()
  end
  b:RegisterForClicks("RightButtonUp");b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
  b:SetScript("OnClick",function()
    if kind=="theirs" or b.locked then return end
    if kind=="offer"then act(T.Remove,index)
    elseif b.entry and b.entry.item then act(T.Add,b.entry.kind,b.entry.item.id)end
  end)
  b:SetScript("OnEnter",function(self)
    local e=rawget(self,"entry");GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    if self.locked then GameTooltip:SetText("Locked bag slot");GameTooltip:AddLine("Unlock this slot in Equipment.",1,0.82,0.3,true)
    else
      GameTooltip:SetText(label(e));GameTooltip:AddLine(details(e),1,1,1,true)
      if F.Integrity and e and e.item then
        if F.History then GameTooltip:AddLine(F.History.DescribeBirth(e.item),0.65,0.75,1,true)end
        GameTooltip:AddLine(F.Integrity.Label(e.item).."\n"..(e.item.assetID or "No permanent ID").."\nIDs and receipts detect known conflicts; they do not prove earning.",0.65,0.75,1,true)
      end
      if kind=="offer"then GameTooltip:AddLine("Right-click to remove from your offer.",1,0.82,0.3,true)
      elseif kind=="theirs"then GameTooltip:AddLine("The other player's offer. Hover every slot before confirming.",1,0.82,0.3,true)
      elseif e and e.item then
        local ok,why=T.Eligible(e.kind,e.item.id)
        GameTooltip:AddLine(ok and "Right-click to add to your offer." or why,1,0.82,0.3,true)
      end
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  return b
end
local function draw(b,e,locked,offered)
  b.entry=e;b.locked=locked or false;local item=e and e.item
  local bound=item and P.IsSoulbound and P.IsSoulbound(e.kind,item)
  for _,p in ipairs(b.locks)do p:SetShown(b.locked or bound)end
  b.art:SetShown(item~=nil and not b.locked);b.mark:SetText("")
  b:SetBackdropBorderColor(unpack(item and P.colors[item.rarity or 2] or {0.26,0.26,0.3}))
  if item and not b.locked then
    if e.kind=="pet"then P.ShowPetPortrait(b.art,item);b.mark:SetText((item.id==P.state.active and "*" or "")..item.level)
    else b.art.cfPortraitDisplay=nil;b.art.cfPortraitRenderer=nil;b.art:SetTexture("Interface\\Icons\\"..P.BagDefinition(item).icon);b.art:SetTexCoord(0,1,0,1)end
    b.art:SetDesaturated(offered or bound or false);b.art:SetAlpha(offered and 0.4 or bound and 0.55 or 1)
    if offered then b.mark:SetText("+")end
  end
end
function P.OpenTrade()P.OpenPage("trade")end
function P.BuildTrade()
  local f=P.NewPage();P.trade=f;f.own={};f.other={};f.bag={};f.pets={};f.bagPage=0
  f.title=S.Text(f,"TRADE",12,-8,720,"GameFontNormalLarge",S.gold)
  S.Button(f,"Back to Inspect",790,-4,156,function()P.OpenPage("peers")end)
  f.status=text(f,"",12,-40,932,54)
  panel(f,12,-104,220,256);panel(f,244,-104,220,256)
  text(f,"YOUR OFFER",24,-114,194,26);f.theirName=text(f,"THEIR OFFER",256,-114,194,26)
  for i=1,9 do
    local x,y=((i-1)%3)*62,-146-math.floor((i-1)/3)*62
    f.own[i]=slot(f,30+x,y,54,"offer",i);f.other[i]=slot(f,262+x,y,54,"theirs",i)
  end
  f.ownReady=text(f,"",24,-336,196,20);f.otherReady=text(f,"",256,-336,196,20)
  text(f,"Right-click your bag or stable to add. Right-click your offer to remove. Hover an icon for its details.",14,-376,448,56)
  text(f,"Only living inactive pets with no worn gear can trade. Collection discoveries stay with you.",14,-440,448,46)
  panel(f,480,-104,306,352);text(f,"YOUR EQUIPMENT BAG",492,-114,274,24)
  for i=1,P.maxBagSlots do f.bag[i]=slot(f,493+((i-1)%10)*28,-148-math.floor((i-1)/10)*35,25,"bag",i)end
  f.capacity=text(f,"",492,-434,280,20)
  f.more=S.Button(f,"More bag items",490,-464,146,function()f.bagPage=(f.bagPage+1)%(f.maxBagPage+1);P.RenderTrade()end)
  S.Button(f,"Equipment",648,-464,136,function()P.OpenEquipment()end)
  panel(f,798,-104,150,246);text(f,"YOUR PETS",804,-114,138,26)
  for i=1,16 do f.pets[i]=slot(f,804+((i-1)%3)*47,-148-math.floor((i-1)/3)*47,44,"pet",i)end
  f.petCount=text(f,"",804,-302,138,38)
  text(f,"Gold lock: buy space in Equipment.\n\n+ means already in your offer.",800,-366,148,112)
  f.start=S.Button(f,"Request target",12,-508,188,function()
    if T.invite then act(T.Join)
    elseif T.recipient then act(T.Start,T.recipient)
    elseif not UnitIsPlayer("target") or UnitIsUnit("target","player")then P.notice="Target another player first.";P.Render()
    else act(T.Start,GetUnitName("target",true))end
  end)
  f.confirm=S.Button(f,"Confirm",212,-508,188,function()act(T.Confirm)end)
  f.cancel=S.Button(f,"Cancel trade",412,-508,188,function()act(T.Cancel)end)
  f.retry=S.Button(f,"Retry delivery",612,-508,188,function()act(T.Retry)end)
  f.elapsed=0;f:SetScript("OnUpdate",function(_,dt)
    f.elapsed=f.elapsed+dt;if f.elapsed<0.2 then return end;f.elapsed=0
    if P.mode=="trade"then P.RenderTrade()end
  end)
end
function P.RenderTrade()
  local f=P.trade;if not f or P.mode~="trade"then return end
  if T.broken then
    f.status:SetText(T.BlockReason());f.start:Disable();f.confirm:Disable();f.cancel:Disable();f.retry:Disable()
    for _,group in ipairs({f.own,f.other,f.bag,f.pets})do for _,b in ipairs(group)do b:Disable()end end
    return
  end
  local t=P.state.trade;local probe=T.probe;local invite=T.invite;local old=T.IsLegacy();local why=T.BlockReason()
  local own=T.OwnEntries();local other=T.OtherEntries();local selected={}
  for _,e in ipairs(t and not old and t.escrow or T.draft or {})do local id=e.item and e.item.id or e.id;selected[e.kind..":"..id]=true end
  local editable=T.Editable();local peer=t and t.peer or probe and probe.peer or invite and invite.peer
  peer=peer or T.recipient
  f.title:SetText(peer and ("TRADE  |  "..peer) or "TRADE")
  f.theirName:SetText(peer or "THEIR OFFER")
  local _,confirmReason=T.CanConfirm()
  local status=old and "Previous-version trade: use Retry delivery or Cancel before starting a new trade." or
    probe and "Connecting... Waiting for the other addon to reply." or
    t and (t.decision and "Committed. Waiting for delivery acknowledgement." or t.cancel and "Waiting for safe cancellation." or
      (not t.remoteWires and not t.incoming) and "Invitation sent. Waiting for the other player to join. You can add items while you wait." or
      (not t.remoteWires and t.incoming) and "The other player is joining. Receiving their offer..." or
      t.ready and "You confirmed. Your offer is locked." or confirmReason or "Review every slot, then Confirm.") or
    invite and (invite.incoming and "Receiving the other player's complete offer..." or "Invitation received. Join trade to enter; add your items before confirming.") or
    (T.recipient and ("Recipient: "..T.recipient..". Add assets, then Request selected.") or "Choose someone in Inspect or target a player, then request a trade.")
  f.status:SetText((peer and ("Trading with "..peer.."\n") or "")..(why or T.lastError or status))
  for i=1,9 do
    draw(f.own[i],own[i]);draw(f.other[i],other[i]);f.own[i]:SetEnabled(editable)
  end
  f.ownReady:SetText(t and t.ready and "|cff40ff40Confirmed|r" or "Up to 9 assets")
  f.otherReady:SetText(t and t.peerReady and "|cff40ff40Confirmed|r" or t and t.incoming and "Updating offer..." or "Review all slots")
  local owners=P.GearOwners();local rows={}
  for i=#P.state.crates,1,-1 do rows[#rows+1]={kind="crate",item=P.state.crates[i]}end
  for i=#P.state.gear,1,-1 do local item=P.state.gear[i];if not owners[item.id]then rows[#rows+1]={kind="gear",item=item}end end
  local cap=P.BagCapacity();f.maxBagPage=math.max(0,math.ceil((#rows-cap)/P.maxBagSlots));f.bagPage=math.min(f.bagPage,f.maxBagPage)
  local cursor=f.bagPage==0 and 0 or cap+(f.bagPage-1)*P.maxBagSlots
  local openPosition,lockedPosition=0,cap
  for i,b in ipairs(f.bag)do
    local locked=f.bagPage==0 and not P.BagSlotUnlocked(i);local e
    local position=i
    if f.bagPage==0 then
      if locked then lockedPosition=lockedPosition+1;position=lockedPosition
      else openPosition=openPosition+1;position=openPosition end
    end
    b:ClearAllPoints();b:SetPoint("TOPLEFT",493+((position-1)%10)*28,-148-math.floor((position-1)/10)*35)
    if not locked then cursor=cursor+1;e=rows[cursor]end
    local offered=e and selected[e.kind..":"..e.item.id]
    draw(b,e,locked,offered);b:SetEnabled(editable and not locked and not offered)
  end
  f.more:SetShown(f.maxBagPage>0);f.more:SetText(f.bagPage==0 and "More bag items" or "Previous items")
  f.capacity:SetText(P.BagCount().." / "..cap.." slots"..(t and " (includes held)" or ""))
  local pets={};for _,pet in ipairs(P.state.pets)do if not pet.deadAt and not P.IsHoused(pet)then pets[#pets+1]=pet end end
  for i,b in ipairs(f.pets)do
    local cols=P.stableCapacity>9 and 4 or 3;local cell=141/cols
    b:ClearAllPoints();b:SetPoint("TOPLEFT",804+((i-1)%cols)*cell,-148-math.floor((i-1)/cols)*cell);b:SetSize(cell-3,cell-3);b:SetShown(i<=P.stableCapacity);b.mark:ClearAllPoints();b.mark:SetPoint("BOTTOMLEFT",1,0);b.mark:SetWidth(cell-5)
    local item=pets[i];local e=item and {kind="pet",item=item};local offered=item and selected["pet:"..item.id]
    draw(b,e,false,offered);b:SetEnabled(editable and not offered)
  end
  f.petCount:SetText(P.StableCount().." / "..P.stableCapacity.." living\n* Active pet")
  f.start:SetShown(not t);f.start:SetEnabled(not why and not probe and (not invite or invite.wires~=nil and not invite.incoming))
  f.start:SetText(probe and "Checking connection..." or invite and "Join trade" or T.recipient and "Request selected" or "Request target")
  f.confirm:SetShown(t~=nil);f.confirm:SetEnabled(T.CanConfirm())
  local seconds=T.Seconds();f.confirm:SetText(t and t.ready and "Confirmed" or seconds>0 and ("Confirm ("..seconds..")") or "Confirm trade")
  f.cancel:SetText(invite and not t and "Decline request" or probe and "Cancel request" or "Cancel trade")
  f.cancel:SetEnabled(not T.broken and ((t and not t.decision) or invite~=nil or probe~=nil or #own>0))
  f.retry:SetEnabled(t~=nil and not why)
end
