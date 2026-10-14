local _,F=...
local P,S,I=F.Pets,F.Style,F.Integrity
local function text(parent,value,x,y,width,height,font,color)
  local t=S.Text(parent,value,x,y,width,font or "GameFontHighlight",color or S.muted);t:SetHeight(height);return t
end
local function tip(frame,body)
  frame:SetScript("OnEnter",function(self)
    local title,detail=body(self);if not title then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(title);GameTooltip:AddLine(detail,1,1,1,true);GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function action(fn)
  local ok,msg=fn();if not ok and msg then P.notice=msg end;P.Render()
end
local function peerFor(name)
  if F.Inspect.IsSelf(name)then return F.Inspect.LocalSnapshot()end
  if P.peers[name]then return P.peers[name]end
  local key=I.Name(name)
  for n,peer in pairs(P.peers)do if I.Name(n)==key then return peer end end
end
P.InspectPeer=peerFor
local function layoutPortrait(f,frameID)
  local definition=F.Achievements and F.Achievements.frames[frameID]
  local illustrated=definition and definition.texture~=nil or false
  if rawget(f,"illustratedPortrait")==illustrated then return end
  f.illustratedPortrait=illustrated
  -- Illustrated rewards are square artwork. Keep their silhouette intact and
  -- inset the scene so its rectangular corners stay beneath the ornament.
  f.art:ClearAllPoints()
  f.art:SetPoint("TOPLEFT",illustrated and 62 or 12,illustrated and -68 or -54)
  f.art:SetSize(illustrated and 178 or 278,illustrated and 178 or 192)
  local border=rawget(f,"portraitBorder")
  if border then
    border:ClearAllPoints();border:SetPoint("CENTER",f.art,"CENTER")
    border:SetSize(illustrated and 206 or 278,illustrated and 206 or 192)
  end
  f.meta:ClearAllPoints();f.meta:SetPoint("TOPLEFT",12,illustrated and -266 or -252)
  f.meta:SetHeight(illustrated and 84 or 98)
end
function P.InspectDirectory()
  local now=GetTime and GetTime() or F.Now()
  if P.inspectDirectory and now<(P.inspectDirectoryUntil or 0)then return P.inspectDirectory end
  local list,byName={},{}
  -- Roster membership alone does not prove this player has the addon.
  local known={}
  for name,peer in pairs(P.peers)do
    local key=I.Name(name)
    if key and type(peer.seen)=="number" and F.Now()-peer.seen<=600 then known[key]=true end
  end
  local function add(name,kind,rank,trade)
    local key=I.Name(name);if not key then return end
    if rank>0 and not known[key] and not trade then return end
    local old=byName[key]
    if old then if rank<old.rank then old.kind=kind;old.rank=rank end;old.trade=old.trade or trade;return end
    local item={name=name,kind=kind,rank=rank,trade=trade};byName[key]=item;list[#list+1]=item
  end
  add(F.Inspect.SelfName(),"You",0)
  local function unit(unitID,kind,rank)
    if not GetUnitName then return end
    local ok,name=pcall(GetUnitName,unitID,true);if ok and I.Safe(name,100)then add(name,kind,rank)end
  end
  for i=1,4 do unit("party"..i,"Party",1)end
  for i=1,40 do unit("raid"..i,"Raid",2)end
  if GetNumGuildMembers and GetGuildRosterInfo then
    if now>=(P.inspectGuildRequest or 0)then
      local request=C_GuildInfo and C_GuildInfo.GuildRoster or GuildRoster
      local inGuild=IsInGuild and IsInGuild()
      if request and I.Readable(inGuild) and inGuild==true then pcall(request)end
      P.inspectGuildRequest=now+30
    end
    local ok,count=pcall(GetNumGuildMembers)
    if ok and I.Readable(count) and type(count)=="number" and count==count then
      for i=1,math.min(1000,math.max(0,math.floor(count)))do
        local valid,name,rank,rankIndex,level,class,zone,note,offNote,online=pcall(GetGuildRosterInfo,i)
        if valid and I.Readable(online) and online==true then add(name,"Guild",3)end
      end
    end
  end
  for name,peer in pairs(P.peers)do add(name,({PARTY="Party",RAID="Raid",GUILD="Guild",TRADE="Trade chat",GLOBAL="Global"})[peer.channel] or "Recent",4)end
  if P.inspectName then add(P.inspectName,"Selected",4)end
  local trade=P.state.trade or F.Trades.probe or (F.Social and F.Social.PendingTrade())
  if trade then add(trade.peer,"Trade",1,true)end
  if F.Social then
    local filtered={};for _,entry in ipairs(list)do if entry.rank==0 or entry.trade or F.Social.Filter(entry.kind)then filtered[#filtered+1]=entry end end;list=filtered
  end
  table.sort(list,function(a,b)if a.rank~=b.rank then return a.rank<b.rank end;return a.name:lower()<b.name:lower()end)
  P.inspectDirectory=list;P.inspectDirectoryUntil=now+2;return list
end
local function buildPlayers(f)
  local strip=CreateFrame("Frame",nil,f);f.players=strip;strip:SetPoint("TOPLEFT",12,-482);strip:SetSize(934,64)
  strip.rows={};strip.offset=0;strip.maxOffset=0
  for i=1,15 do
    local b=CreateFrame("Button",nil,strip,"BackdropTemplate");strip.rows[i]=b;b.contact=false
    b:SetPoint("TOPLEFT",(i-1)*62,0);b:SetSize(54,46)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    b:SetBackdropColor(0.04,0.045,0.055,1)
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("CENTER");b.art:SetSize(40,40)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetScript("OnClick",function()
      if b.contact and b.contact.trade then P.OpenTrade()
      elseif b.contact then action(function()return P.InspectPlayer(b.contact.name)end)end
    end)
    tip(b,function(self)local c=self.contact;if c then return c.name,c.trade and "Click to open your trade with this player." or c.kind=="You" and "Your living stable, with current stats and abilities. Available even when sharing is off." or c.kind.." | Click to refresh this stable.\nBoth players need Companions Forever and sharing enabled. Messages must be available."end end)
  end
  local slider=CreateFrame("Slider",nil,strip,"BackdropTemplate");strip.scroll=slider
  slider:SetPoint("TOPLEFT",0,-50);slider:SetSize(922,12);slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(0,0);slider:SetValueStep(1);slider:SetObeyStepOnDrag(true)
  slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  slider:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});slider:SetBackdropColor(0.15,0.15,0.17,1)
  local function move(v)
    v=math.max(0,math.min(strip.maxOffset,math.floor(v+0.5)))
    if strip.offset~=v then strip.offset=v;P.RenderInspect()end
  end
  slider:SetScript("OnValueChanged",function(_,v)move(v)end)
  local function wheel(_,delta)move(strip.offset-delta*3)end
  strip:EnableMouseWheel(true);strip:SetScript("OnMouseWheel",wheel)
  for _,b in ipairs(strip.rows)do b:EnableMouseWheel(true);b:SetScript("OnMouseWheel",wheel)end
end
local function renderPlayers(f)
  local strip=f.players;local list=P.InspectDirectory()
  strip.maxOffset=math.max(0,#list-#strip.rows);strip.offset=math.min(strip.offset,strip.maxOffset)
  strip.scroll:SetMinMaxValues(0,strip.maxOffset);strip.scroll:SetValue(strip.offset);strip.scroll:SetShown(strip.maxOffset>0)
  for i,b in ipairs(strip.rows)do
    local c=list[strip.offset+i];b.contact=c or false;b:SetShown(c~=nil)
    if c then
      local peer=peerFor(c.name);local pet=peer and (peer.stable and (peer.stable[peer.stableActive] or peer.stable[1]) or (peer.species and peer))
      if pet then P.ShowPetPortrait(b.art,pet)
      else b.art.cfPortraitDisplay=nil;b.art:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking");b.art:SetDesaturated(false);b.art:Show()end
      b:SetBackdropBorderColor(unpack(I.Name(c.name)==I.Name(P.inspectName) and S.gold or pet and P.colors[pet.rarity] or S.muted))
    end
  end
end
function P.BuildInspect()
  local f=P.NewPage();P.inspect=f;f.slots={};f.abilities={};f.values={};f.statLabels={};f.historySelf=false
  f.owner=text(f,"INSPECT A PLAYER",12,-2,780,36,"GameFontNormalLarge",S.gold)
  f.status=text(f,"Target a player and choose Inspect target.",12,-34,932,32)
  local stable=S.Panel(f,12,-70,298,360);local preview=S.Panel(f,322,-70,302,360);local details=S.Panel(f,636,-70,310,360)
  f.count=text(stable,"STABLE",12,-8,274,28,"GameFontNormal",S.gold)
  for i=1,16 do
    local slot=i;local b=CreateFrame("Button",nil,stable,"BackdropTemplate");f.slots[i]=b;b.pet=false
    b:SetPoint("TOPLEFT",11+((i-1)%3)*94,-38-math.floor((i-1)/3)*104);b:SetSize(88,98)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    b:SetBackdropColor(0.035,0.04,0.05,1)
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT",12,-5);b.art:SetSize(64,64)
    b.name=text(b,"",4,-64,80,32,"GameFontHighlightSmall");b.name:SetJustifyH("CENTER");b.name:SetMaxLines(2)
    b.level=text(b,"",2,-46,84,20,"GameFontNormal",S.gold);b.level:SetJustifyH("RIGHT")
    b.selected=b:CreateTexture(nil,"OVERLAY");b.selected:SetAllPoints();b.selected:SetTexture("Interface\\Buttons\\CheckButtonHilight");b.selected:SetBlendMode("ADD")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:SetScript("OnClick",function()if b.pet then P.inspectSlot=slot;P.RenderInspect()end end)
    tip(b,function(self)
      local pet=self.pet;if not pet then return "Empty stable slot","Living companions appear here. Memorials and pets currently held in a trade are not in the stable."end
      return P.PetName(pet),P.rarities[pet.rarity].." | Level "..pet.level.."\n"..P.Specialty(pet).."\n"..P.AbilityText(pet,"\n").."\nClick to view this pet."
    end)
  end
  f.petName=text(preview,"Select a companion",12,-8,278,46,"GameFontNormalLarge",S.gold);f.petName:SetMaxLines(2)
  f.art=preview:CreateTexture(nil,"ARTWORK");f.art:SetPoint("TOPLEFT",12,-54);f.art:SetSize(278,192)
  f.background=P.PreviewBackground(preview,f.art)
  if P.CreatePortraitFrame then f.portraitBorder=P.CreatePortraitFrame(preview,f.art)end
  f.meta=text(preview,"",12,-252,278,98)
  text(details,"PET STATS",12,-8,280,24,"GameFontNormal",S.gold)
  f.statHighlights={}
  for i,name in ipairs({"Max health","Attack","Armor","Speed"})do
    f.statLabels[i]=text(details,name,12,-35-(i-1)*26,162,25)
    local hover=CreateFrame("Frame",nil,details);hover:SetPoint("TOPLEFT",10,-35-(i-1)*26);hover:SetSize(288,25);hover:EnableMouse(true)
    tip(hover,function()return name,f.viewedPet and P.StatHelp(f.viewedPet,i) or "Select a pet."end)
    f.values[i]=text(details,"-",178,-35-(i-1)*26,118,25,"GameFontHighlight",{1,1,1});f.values[i]:SetJustifyH("RIGHT")
    f.statHighlights[i]=P.BuildStatRollBar(details,f.statLabels[i],f.values[i])
  end
  text(details,"Totals shared by this player",12,-144,280,24,"GameFontHighlightSmall")
  text(details,"SPECIAL ABILITIES",12,-174,280,24,"GameFontNormal",S.gold)
  for i=1,2 do
    local b=CreateFrame("Button",nil,details);f.abilities[i]=b;b.ability=false
    b:SetPoint("TOPLEFT",12,-207-(i-1)*48);b:SetSize(284,44)
    b.art=b:CreateTexture(nil,"ARTWORK");b.art:SetPoint("TOPLEFT");b.art:SetSize(40,40)
    b.name=text(b,"",50,0,228,44,"GameFontHighlight",{1,1,1})
    tip(b,function(self)local a=self.ability;if a then return a.ability,P.AbilityHelp(a)end end)
  end
  f.noAbilities=text(details,"",12,-207,280,84)
  f.history=text(details,"",12,-307,280,46,"GameFontHighlightSmall")
  f.historyHover=CreateFrame("Frame",nil,details);f.historyHover:SetPoint("TOPLEFT",10,-305);f.historyHover:SetSize(286,52);f.historyHover:EnableMouse(true)
  tip(f.historyHover,function()
    if not F.History then return end
    local status,reason
    if f.historySelf or F.Inspect.IsSelf(P.inspectName) then status,reason=F.History.Details()
    else status,reason=F.HistoryPeers.Status(P.inspectName)end
    local peer=peerFor(P.inspectName or "");local pet=peer and peer.stable and peer.stable[P.inspectSlot or 1]
    return status,reason..(not f.historySelf and pet and ("\n\n"..F.History.DescribeBirth(pet)) or "")
  end)
  S.Button(f,"My history",538,-440,118,function()f.historySelf=not f.historySelf;P.RenderInspect()end)
  details:EnableMouse(true)
  tip(details,function()return "Shared pet details","Shared by this player; includes gear and trainer bonuses. Not server-verified."end)
  S.Button(f,"Inspect target",12,-440,180,function()action(P.InspectTarget)end)
  f.share=S.Button(f,"Sharing: ON",204,-440,180,function()P.SetSharing(not P.state.share);P.Render()end)
  f.tradeButton=S.Button(f,"Request trade",396,-440,130,function()
    if F.TradeEntry then F.TradeEntry.FromInspect()
    else F.Trades.recipient=not F.Inspect.IsSelf(P.inspectName) and P.inspectName or nil;P.OpenTrade()end
  end)
  S.Button(f,"Refresh selected",668,-440,278,function()action(function()return P.InspectPlayer(P.inspectName or F.Inspect.SelfName())end)end)
  buildPlayers(f)
  if F.Social then F.Social.BuildFilters(f)end

end
function P.RenderInspect()
  local f=P.inspect;if not f or not f:IsShown() or not P.state then return end
  local name=P.inspectName or F.Inspect.SelfName();P.inspectName=name
  local peer=peerFor(name);local stable=peer and (peer.stable or (peer.species and {peer})) or {}
  local active=peer and (peer.stableActive or 1) or 0
  local index=math.max(1,math.min(P.inspectSlot or active,#stable));P.inspectSlot=index
  local pet=stable[index]
  f.owner:SetText(name or "INSPECT A PLAYER")
  f.status:SetText(peer and (peer.isSelf and "Your full living stable. Select a pet to view its stats and abilities." or peer.stable and ("Stable snapshot: "..math.max(0,F.Now()-(peer.stableSeen or peer.seen)).."s ago. Click a player portrait below to refresh.")
    or "Basic active-pet broadcast. Click this player's portrait to request the full stable and stats.") or "Click a party or guild portrait below, or target another addon user and choose Inspect target.")
  if F.Inspect.pending and F.Inspect.pending.name==I.Name(name)then f.status:SetText("Requesting this player's full stable. Older formats can take up to 40 seconds; the last snapshot stays visible.")
  elseif F.Inspect.lastError and F.Inspect.lastTarget==I.Name(name) and not (peer and peer.isSelf)then f.status:SetText(F.Inspect.lastError)end
  local capacity=peer and peer.stableCapacity or (#stable>9 and 16 or 9)
  f.count:SetText(peer and peer.stable and ("STABLE  "..#stable.." / "..capacity) or "SHARED COMPANION")
  f.share:SetText(P.state.share and "Sharing: ON" or "Sharing: OFF")
  for i,b in ipairs(f.slots)do
    local cols=capacity>9 and 4 or 3;local dx,dy=282/cols,312/cols
    b:ClearAllPoints();b:SetPoint("TOPLEFT",11+((i-1)%cols)*dx,-38-math.floor((i-1)/cols)*dy);b:SetSize(dx-6,dy-6);b:SetShown(i<=capacity)
    b.art:ClearAllPoints();b.art:SetPoint("TOP",0,-5);b.art:SetSize(dx-30,dx-30)
    b.name:ClearAllPoints();b.name:SetPoint("BOTTOMLEFT",4,2);b.name:SetSize(dx-14,cols==4 and 24 or 32)
    b.level:ClearAllPoints();b.level:SetPoint("TOPRIGHT",-2,-dy+48);b.level:SetWidth(dx-10)
    local p=stable[i];b.pet=p or false;P.ShowPetPortrait(b.art,p)
    b:SetBackdropBorderColor(unpack(p and P.colors[p.rarity] or {0.20,0.22,0.26}))
    b.selected:SetShown(p~=nil and index==i)
    b.name:SetText(p and P.PetName(p) or "Empty");S.TextColor(b.name,p and P.colors[p.rarity] or S.muted)
    b.level:SetText(p and ((i==active and "* " or "")..p.level) or "")
  end
  local frameID=peer and peer.portraitFrame or 1
  layoutPortrait(f,frameID)
  P.UpdatePreviewBackground(f.background);P.ShowPetArt(f.art,pet)
  if rawget(f,"portraitBorder") then P.UpdatePortraitFrame(f.portraitBorder,frameID);f.portraitBorder:SetShown(pet~=nil)end
  f.petName:SetText(pet and P.PetName(pet) or "Select a companion");S.TextColor(f.petName,pet and P.colors[pet.rarity] or S.gold)
  f.meta:SetText(pet and (P.rarities[pet.rarity].." | Level "..pet.level..(index==active and " | Equipped" or "").."\n"..P.Specialty(pet).."\nHighest floor: "..pet.best.." / 100\nTower wins: "..pet.wins) or "Their living companions will appear here.")
  for i,v in ipairs(f.values)do
    if P.SetStatRollLabel then P.SetStatRollLabel(f.statLabels[i],pet,i)end
    local n=pet and pet.sharedStats and pet.sharedStats[i]
    v:SetText(n and (string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")..(i==3 and "%" or "")) or "Not shared")
    if P.SetStatRollLabel then P.SetStatRollLabel(v,n and pet or nil,i,{1,1,1})end
    P.SetStatRollBar(f.statHighlights[i],n and pet or nil,i)
  end
  f.viewedPet=pet or false
  local abilities=P.Abilities(pet)
  for i,b in ipairs(f.abilities)do
    b.ability=abilities[i] or false;b:SetShown(not not b.ability)
    if b.ability then b.art:SetTexture("Interface\\Icons\\"..b.ability.icon);b.name:SetText((b.ability.rollTier and (P.abilityQualities[b.ability.rollTier].." ") or "")..b.ability.ability);S.TextColor(b.name,b.ability.rollTier and P.abilityColors[b.ability.rollTier] or {1,1,1})end
  end
  f.noAbilities:SetShown(#abilities==0)
  f.noAbilities:SetText(pet and (pet.rarity>=3 and (peer and peer.stable and "No special abilities recorded." or "Request the full stable to see abilities.") or "Basic attacks. Rare pets unlock special abilities.") or "Select a pet to see its abilities.")
  if F.History and F.HistoryPeers then
    local mine=f.historySelf or (peer and peer.isSelf)
    local status=mine and F.History.LocalStatus() or F.HistoryPeers.Status(name)
    f.history:SetText((mine and "Your history: " or "History: ")..status.."\nHover for details and reward origin.")
    S.TextColor(f.history,status=="History conflict" and {1,0.55,0.25} or S.muted)
  else f.history:SetText("Limited history")end
  renderPlayers(f)
end
