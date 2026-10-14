local _,F=...
local P,S=F.Pets,F.Style
local ink={.24,.14,.065};local faded={.40,.36,.31}
local perPage=12
local function valid(id)return type(id)=="number" and id==math.floor(id) and P.specialAbilities[id]~=nil end
function P.RecordAbilityDiscovery(pet)
  if not P.state or type(pet)~="table" or (pet.rarity or 0)<3 then return end
  local known=P.state.knownAbilities
  if type(known)~="table"then known={};P.state.knownAbilities=known end
  for _,id in ipairs(pet.abilities or {})do if valid(id)then known[id]=true end end
end
function P.InitAbilityBook()
  local s=P.state;local known={}
  for id,value in pairs(type(s.knownAbilities)=="table" and s.knownAbilities or {})do
    if valid(id) and value==true then known[id]=true end
  end
  s.knownAbilities=known
  local seen={}
  for id,value in pairs(type(s.seenAbilities)=="table" and s.seenAbilities or {})do if known[id] and value==true then seen[id]=true end end
  s.seenAbilities=seen
  -- Backfill actual owned pets, including memorials, overflow and outgoing escrow.
  -- Species discoveries alone cannot tell us which random abilities a pet had.
  for _,pet in ipairs(s.pets or {})do P.RecordAbilityDiscovery(pet)end
  for _,entry in ipairs(s.mailbox or {})do if entry.kind=="pet"then P.RecordAbilityDiscovery(entry.item)end end
  local trade=s.trade
  if trade and type(trade.escrow)=="table"then
    if trade.escrow.kind=="pet"then P.RecordAbilityDiscovery(trade.escrow.item)
    else for _,entry in ipairs(trade.escrow)do if entry.kind=="pet"then P.RecordAbilityDiscovery(entry.item)end end end
  end
end
local init=P.Init
function P.Init(...)local result=init(...);P.InitAbilityBook();return result end
local function paperArtwork(texture,width,height)
  -- Use Forever's actual spellbook page. Crop to fill instead of squeezing
  -- its paper grain and curled edges into the journal's much wider shape.
  for _,name in ipairs({"spellbook-Page-Right-C60","spellbook-background-evergreen-right","QuestBG-Parchment"})do
    local info=C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
    if info then
      texture:SetAtlas(name)
      if type(info.width)=="number" and type(info.height)=="number" and info.width>0 and info.height>0
        and type(info.leftTexCoord)=="number" and type(info.rightTexCoord)=="number"
        and type(info.topTexCoord)=="number" and type(info.bottomTexCoord)=="number" and width>0 and height>0 then
        local l,r,t,b=info.leftTexCoord,info.rightTexCoord,info.topTexCoord,info.bottomTexCoord
        local source=info.width/info.height;local target=width/height
        if target>source then local trim=(b-t)*(1-source/target)/2;t=t+trim;b=b-trim
        else local trim=(r-l)*(1-target/source)/2;l=l+trim;r=r-trim end
        texture:SetTexCoord(l,r,t,b)
      end
      return
    end
  end
  texture:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
  -- Legacy fallback artwork is approximately 2:1; keep that aspect too.
  local target=width/height
  if target>2 then local trim=(1-2/target)/2;texture:SetTexCoord(0,1,trim,1-trim)
  else local trim=(1-target/2)/2;texture:SetTexCoord(trim,1-trim,0,1)end
end
local function label(parent,value,x,y,w,h,font)
  local t=S.Text(parent,value,x,y,w,font or "GameFontHighlight",ink);t:SetHeight(h);return t
end
local function known(id)return P.state.knownAbilities and P.state.knownAbilities[id]==true end
function P.AbilityBookRows(query,filter)
  query=(query or ""):lower();local rows={};local found=0
  for id,a in pairs(P.specialAbilities)do
    local discovered=known(id);if discovered then found=found+1 end
    -- Do not leak undiscovered effects through keyword search.
    local searchable=a.ability:lower()..(a.housing and ' housing buff' or ' combat ability')
    if discovered then searchable=searchable.." "..P.AbilityHelp(a):lower()end
    if (not a.hidden or discovered) and (filter==1 or filter==2 and discovered or filter==3 and not discovered or filter==4 and not a.housing or filter==5 and a.housing) and (query=="" or searchable:find(query,1,true))then rows[#rows+1]=id end
  end
  table.sort(rows,function(a,b)return P.specialAbilities[a].ability<P.specialAbilities[b].ability end)
  return rows,found
end
local defaults={bite={1.8,0},flurry={1.65,0},cleave={.9,0},renew={.8,.18},drain={1.1,.6},shield={1,0,.55}}
function P.AbilityBookHelp(id)
  if not valid(id)then return end
  if not known(id)then return "Not found yet. Collect a companion with this ability."end
  local a={};for k,v in pairs(P.specialAbilities[id])do a[k]=v end
  local d=defaults[a.effect];a.power=a.power or d[1];a.healing=a.healing or d[2];a.reduction=a.reduction or d[3]
  -- Catalogue values describe the ability, not a made-up roll or a selected pet.
  return P.AbilityHelp(a):gsub("\nLegacy / fixed ability: no random roll recorded%.","").."\n\nBase values. Your companion's ability roll can change them."
end
function P.ShowAbilityBookTooltip(row)
  if not row.abilityID then return end
  GameTooltip:SetOwner(row,"ANCHOR_RIGHT");GameTooltip:SetText(P.specialAbilities[row.abilityID].ability)
  GameTooltip:AddLine(P.AbilityBookHelp(row.abilityID),1,1,1,true);GameTooltip:Show()
  if known(row.abilityID)then
    P.state.seenAbilities[row.abilityID]=true
    if P.UpdateJournalNewMarkers then P.UpdateJournalNewMarkers(P.journal)end
  end
end
local function turnPage(book,delta)
  book.page=math.max(1,math.min(book.pages or 1,book.page+delta));GameTooltip:Hide();P.RenderAbilityBook(book)
end
local function arrow(book,direction,x)
  local b=CreateFrame("Button",nil,book);b:SetPoint("BOTTOMRIGHT",x,16);b:SetSize(30,30)
  local base="Interface\\Buttons\\UI-SpellbookIcon-"..direction.."Page-"
  b:SetNormalTexture(base.."Up");b:SetPushedTexture(base.."Down");b:SetDisabledTexture(base.."Disabled")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
  b:SetScript("OnClick",function()turnPage(book,direction=="Prev" and -1 or 1)end)
  return b
end
function P.BuildAbilityBook(journal)
  local b=CreateFrame("Frame",nil,journal,"BackdropTemplate");journal.abilityBook=b
  b:SetPoint("TOPLEFT",0,-42);b:SetSize(960,508);b.page=1;b.pages=1;b.query="";b.filter=1;b.rows={}
  b.paper=CreateFrame("Frame",nil,b,"BackdropTemplate");b.paper:SetPoint("TOPLEFT",0,-40);b.paper:SetPoint("BOTTOMRIGHT")
  b.paper:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
  b.paper.art=b.paper:CreateTexture(nil,"BACKGROUND",nil,1);b.paper.art:SetPoint("TOPLEFT",5,-5);b.paper.art:SetPoint("BOTTOMRIGHT",-5,5)
  paperArtwork(b.paper.art,950,458)
  b.paper:SetScript("OnSizeChanged",function(_,width,height)if width>10 and height>10 then paperArtwork(b.paper.art,width-10,height-10)end end)
  -- Keep all text and buttons above the parchment child frame.
  b.content=CreateFrame("Frame",nil,b);b.content:SetAllPoints();b.content:SetFrameLevel(b.paper:GetFrameLevel()+1)
  local c=b.content
  b.count=label(c,"",4,0,390,28);b.title=label(c,"Companion Abilities",34,-62,720,38,"GameFontNormalHuge")
  b.rule=c:CreateTexture(nil,"ARTWORK");b.rule:SetPoint("TOPLEFT",34,-108);b.rule:SetSize(888,2)
  b.search=CreateFrame("EditBox",nil,c,"InputBoxTemplate");b.search:SetPoint("TOPLEFT",492,-2);b.search:SetSize(270,28);b.search:SetAutoFocus(false);b.search:SetMaxLetters(60)
  b.searchHint=label(c,"Search abilities",500,-2,250,28);S.TextColor(b.searchHint,S.muted)
  b.search:SetScript("OnTextChanged",function(self)b.query=self:GetText() or "";b.page=1;P.RenderAbilityBook(b)end)
  b.search:SetScript("OnEditFocusGained",function()b.searchHint:Hide()end)
  b.search:SetScript("OnEditFocusLost",function()b.searchHint:SetShown(b.query=="")end)
  b.search:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);b.search:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
  b.filterButton=S.Dropdown(c,"All abilities",780,-2,180,{{1,"All abilities"},{2,"Found"},{3,"Not found"},{4,"Combat abilities"},{5,"Housing buffs"}},function()return b.filter end,function(value)b.filter=value;b.page=1;GameTooltip:Hide();P.RenderAbilityBook(b)end)
  for i=1,perPage do
    local row=CreateFrame("Button",nil,c);b.rows[i]=row;row:SetPoint("TOPLEFT",34+((i-1)%3)*300,-132-math.floor((i-1)/3)*76);row:SetSize(284,66)
    row.art=row:CreateTexture(nil,"ARTWORK");row.art:SetPoint("TOPLEFT",5,-8);row.art:SetSize(36,36)
    row.rim=row:CreateTexture(nil,"OVERLAY")
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("spellbook-item-iconframe")then
      row.rim:SetAtlas("spellbook-item-iconframe")
      -- WoW's ornament is asymmetric: the scrollwork extends left and below
      -- the square opening. Match its native anchors around a 36px icon.
      row.rim:SetPoint("TOPLEFT",row.art,"TOPLEFT",-13,3)
      row.rim:SetPoint("BOTTOMRIGHT",row.art,"BOTTOMRIGHT",3,-9)
    else
      row.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
      row.rim:SetPoint("CENTER",row.art,"CENTER");row.rim:SetSize(56,56)
    end
    row.name=label(row,"",60,0,222,30);row.name:SetMaxLines(2)
    row.detail=label(row,"",60,-30,222,18,"GameFontHighlightSmall")
    -- An additive white highlight washes the dark lettering out on parchment.
    -- Put a faint tint behind the text instead, leaving its color unchanged.
    row.hover=row:CreateTexture(nil,"BACKGROUND");row.hover:SetAllPoints();row.hover:SetColorTexture(.25,.14,.035,.10)
    row:SetHighlightTexture(row.hover,"BLEND")
    row:SetScript("OnEnter",P.ShowAbilityBookTooltip);row:SetScript("OnLeave",function()GameTooltip:Hide()end)
    row:SetScript("OnHide",function(self)if GameTooltip.IsOwned and GameTooltip:IsOwned(self)then GameTooltip:Hide()end end)
  end
  b.empty=label(c,"No abilities match your search.",60,-230,840,40);b.empty:SetJustifyH("CENTER")
  b.pageLabel=label(c,"",640,-464,194,28);b.pageLabel:SetJustifyH("RIGHT")
  b.prev=arrow(c,"Prev",-78);b.next=arrow(c,"Next",-36)
  -- Page callbacks use the book's data, not the artwork's overlay frame.
  b.prev:SetScript("OnClick",function()turnPage(b,-1)end);b.next:SetScript("OnClick",function()turnPage(b,1)end)
  b:EnableMouseWheel(true);b:SetScript("OnMouseWheel",function(_,delta)turnPage(b,delta>0 and -1 or 1)end)
  b:SetScript("OnHide",function()b.search:ClearFocus();GameTooltip:Hide()end)
  b:Hide()
end
function P.RenderAbilityBook(b)
  if not b or not P.state then return end
  local entries,found=P.AbilityBookRows(b.query,b.filter);local high=S.HighContrast()
  b.pages=math.max(1,math.ceil(#entries/perPage));b.page=math.max(1,math.min(b.page,b.pages))
  b.paper:SetBackdropColor(high and .025 or .78,high and .025 or .63,high and .025 or .4,1)
  b.paper:SetBackdropBorderColor(high and 1 or .65,high and 1 or .48,high and 1 or .24,1);b.paper.art:SetShown(not high)
  b.rule:SetColorTexture(high and .8 or .42,high and .8 or .25,high and .8 or .1,.7)
  S.TextColor(b.count,S.gold);S.TextColor(b.title,ink);S.TextColor(b.pageLabel,ink);S.TextColor(b.empty,ink)
  local total=0;for id,a in pairs(P.specialAbilities)do if not a.hidden or known(id)then total=total+1 end end
  b.count:SetText(found.." / "..total.." abilities found")
  b.filterButton:SetText(({"All abilities","Found","Not found","Combat abilities","Housing buffs"})[b.filter]);b.searchHint:SetShown(b.query=="" and not b.search:HasFocus())
  for i,row in ipairs(b.rows)do
    local id=entries[(b.page-1)*perPage+i];row.abilityID=id;row:SetShown(id~=nil)
    if id then
      local a=P.specialAbilities[id];local unlocked=known(id)
      row.art:SetTexture("Interface\\Icons\\"..a.icon);row.art:SetDesaturated(not unlocked);row.art:SetAlpha(unlocked and 1 or .45)
      row.rim:SetDesaturated(not unlocked);row.rim:SetAlpha(unlocked and 1 or .5)
      row.name:SetText(a.ability);row.detail:SetText(a.housing and (unlocked and 'Housing buff' or 'Housing buff | Not found') or not unlocked and "Not found" or P.IsManualAbility(a) and "Manual special" or "Automatic special")
      S.TextColor(row.name,unlocked and ink or faded);S.TextColor(row.detail,unlocked and ink or faded)
      row.hover:SetColorTexture(high and 1 or .25,high and 1 or .14,high and 1 or .035,high and .09 or .10)
    end
  end
  b.empty:SetShown(#entries==0);b.pageLabel:SetText("Page "..b.page.." / "..b.pages)
  b.prev:SetEnabled(b.page>1);b.next:SetEnabled(b.page<b.pages)
end
