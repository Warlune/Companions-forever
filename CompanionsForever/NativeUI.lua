-- Default native-style presentation. High Contrast keeps the same layout.
local _,F=...
local P,S=F.Pets,F.Style
local N={panels={},buttons={},roots={}};F.NativeUI=N
local function texture(parent,file,layer,sub)
  local t=parent:CreateTexture(nil,layer or "BACKGROUND",nil,sub or 0)
  t:SetTexture(file,"REPEAT","REPEAT");return t
end
local function border(parent,layout)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  f:SetAllPoints(parent);f:EnableMouse(false);f:SetFrameLevel(parent:GetFrameLevel())
  local layouts=NineSliceLayouts
  local supported=layouts and layouts[layout] and C_Texture and C_Texture.GetAtlasInfo
  if supported then
    for _,part in pairs(layouts[layout])do
      if type(part)=="table" and part.atlas and not C_Texture.GetAtlasInfo(part.atlas)then supported=false;break end
    end
  end
  if supported and NineSliceUtil and NineSliceUtil.ApplyLayoutByName then
    NineSliceUtil.ApplyLayoutByName(f,layout)
  else
    f:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    f:SetBackdropBorderColor(0.68,0.49,0.25,1)
  end
  return f
end
function N.Panel(p)
  if N.panels[p]then return end
  local skin={file="Interface\\FrameGeneral\\UI-Background-Marble"};N.panels[p]=skin
  skin.bg=texture(p,skin.file,"BORDER",-6)
  skin.bg:SetPoint("TOPLEFT",4,-4);skin.bg:SetPoint("BOTTOMRIGHT",-4,4)
  skin.bg:SetHorizTile(true);skin.bg:SetVertTile(true);skin.bg:SetVertexColor(0.72,0.60,0.43,0.86)
  skin.trim=border(p,"InsetFrameTemplate")
  skin.contrast=CreateFrame("Frame",nil,p,"BackdropTemplate")
  skin.contrast:SetAllPoints(p);skin.contrast:EnableMouse(false)
  skin.contrast:SetFrameLevel(p:GetFrameLevel())
  skin.contrast:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  skin.contrast:SetBackdropBorderColor(.85,.85,.85,1)
  N.PaintPanel(p,skin)
end
function N.PaintPanel(p,skin)
  local high=S.HighContrast();local decorate=p~=F.petIcon
  skin.bg:SetShown(decorate);skin.trim:SetShown(decorate and not high and not N.roots[p])
  skin.contrast:SetShown(decorate and high)
  if high then skin.bg:SetColorTexture(.025,.025,.025,1);skin.bg:SetVertexColor(1,1,1,1)
  else
    skin.bg:SetTexture(skin.file,"REPEAT","REPEAT")
    if S.HardTheme()then skin.bg:SetVertexColor(.45,.28,.65,N.roots[p] and 1 or .86)
    elseif N.roots[p]then skin.bg:SetVertexColor(.74,.62,.46,1)
    else skin.bg:SetVertexColor(.72,.60,.43,.86)end
  end
  if rawget(p,"paper")then p.paper:Hide()end
end
local panel=S.Panel
local settingsButton=P.SettingsButton
function P.SettingsButton(parent,...)
  local b=settingsButton(parent,...)
  if parent==F.compass then N.compactSettingsOriginal=b end
  return b
end
function S.Panel(...)
  local p=panel(...);N.Panel(p);return p
end
local function root(w,compact)
  if not w or N.roots[w]then return end
  N.Panel(w);local skin=N.panels[w];N.roots[w]=skin;skin.compact=compact
  skin.trim:Hide();skin.outer=border(w,"ButtonFrameTemplateNoPortrait")
  local top=compact and -6 or -16
  skin.outer:ClearAllPoints();skin.outer:SetPoint("TOPLEFT",0,top);skin.outer:SetPoint("BOTTOMRIGHT",0,0)
  skin.outer:SetFrameLevel(w:GetFrameLevel())
  skin.contrast:ClearAllPoints();skin.contrast:SetAllPoints(skin.outer)
  -- The native top edge includes the brown title strip and its lower gold rule.
  -- Grow that artwork too; enlarging only the background leaves the rule
  -- running through the header buttons.
  if compact then
    for _,part in ipairs({"TopLeftCorner","TopEdge","TopRightCorner"})do
      local region=rawget(skin.outer,part)
      if region then region:SetHeight(region:GetHeight()+8)end
    end
  end
  skin.file="Interface\\FrameGeneral\\UI-Background-Rock"
  skin.bg:SetTexture(skin.file,"REPEAT","REPEAT")
  skin.bg:ClearAllPoints();skin.bg:SetPoint("TOPLEFT",4,top);skin.bg:SetPoint("BOTTOMRIGHT",-4,4)
  skin.bg:SetVertexColor(0.74,0.62,0.46,1)
  skin.header=texture(w,"Interface\\DialogFrame\\UI-DialogBox-Background","BORDER",-4)
  skin.header:SetPoint("TOPLEFT",3,top);skin.header:SetPoint("TOPRIGHT",-3,top);skin.header:SetHeight(compact and 40 or 28)
  skin.header:SetVertexColor(0.53,0.37,0.17,1)
  skin.shelf=texture(w,"Interface\\FrameGeneral\\UI-Background-Marble","BORDER",-4)
  skin.shelf:SetPoint("TOPLEFT",4,compact and -46 or -44);skin.shelf:SetPoint("TOPRIGHT",-4,compact and -46 or -44)
  skin.shelf:SetHeight(compact and 40 or 44);skin.shelf:SetVertexColor(0.53,0.45,0.34,1)
  if not compact then
    skin.tabRail=w:CreateTexture(nil,"BORDER",nil,-3)
    skin.tabRail:SetPoint("TOPLEFT",4,-88);skin.tabRail:SetPoint("TOPRIGHT",-4,-88)
    skin.tabRail:SetHeight(1);skin.tabRail:SetColorTexture(.56,.46,.31,1)
  end
  skin.footer=texture(w,"Interface\\DialogFrame\\UI-DialogBox-Background","BORDER",-4)
  skin.footer:SetPoint("BOTTOMLEFT",3,3);skin.footer:SetPoint("BOTTOMRIGHT",-3,3);skin.footer:SetHeight(40)
  skin.footer:SetVertexColor(0.53,0.37,0.17,1)
  -- Reuse existing title labels without moving any working controls.
  skin.labels={}
  skin.backgrounds={};skin.controls={}
  for _,region in ipairs({w:GetRegions()})do
    if region:GetObjectType()=="Texture" and region:GetDrawLayer()=="BACKGROUND" then
      skin.backgrounds[#skin.backgrounds+1]={region=region,alpha=region:GetAlpha()}
    end
  end
  for _,child in ipairs({w:GetChildren()})do
    if child:GetObjectType()=="Button" then
      local point,relative,relativePoint,x,y=child:GetPoint()
      if point=="TOPRIGHT" and (x==-3 or x==-1) and (y==-3 or y==-1)then
        skin.controls[#skin.controls+1]={frame=child}
      elseif compact and child==N.compactSettingsOriginal then
        skin.controls[#skin.controls+1]={frame=child,cog=true}
        local b=CreateFrame("Button",nil,w,"UIPanelButtonTemplate");skin.settings=b
        b:SetSize(26,26);b:SetPoint("TOPRIGHT",w,"TOPRIGHT",-36,-9)
        b:SetScript("OnClick",child:GetScript("OnClick"));b:SetScript("OnEnter",child:GetScript("OnEnter"));b:SetScript("OnLeave",child:GetScript("OnLeave"))
        b.icon=b:CreateTexture(nil,"OVERLAY");b.icon:SetSize(14,14);b.icon:SetPoint("CENTER")
        b.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01");b.icon:SetTexCoord(.12,.88,.12,.88)
        for _,atlas in ipairs({"GM-icon-settings","common-icon-gear","common-icon-settings"})do
          if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)then b.icon:SetAtlas(atlas);break end
        end
      end
    end
  end
  for _,t in ipairs(S.texts)do
    if t:GetParent()==w then
      local value=t:GetText()
      if value=="COMPANIONS FOREVER" or value=="YOUR COMPANIONS. YOUR ADVENTURE."then
        skin.labels[#skin.labels+1]={text=t,point={t:GetPoint()},width=t:GetWidth(),value=value}
      end
    end
  end

end
local function skinButton(b,drop)
  if not b or N.buttons[b]then return end
  local skin={original={}};N.buttons[b]=skin
  -- Modern UIPanelButtonTemplate also has separate left/middle/right art;
  -- hiding only GetNormalTexture leaves those red pieces visible.
  for _,t in ipairs({b:GetRegions()})do
    if t:GetObjectType()=="Texture"then skin.original[#skin.original+1]={texture=t,alpha=t:GetAlpha()}end
  end
  -- Draw on the button itself: a lower frame can disappear behind the
  -- window's opaque panel. Join the navigation strip, with no bottom rim.
  drop=drop or 6;skin.art={};skin.edges={}
  local function art()
    local t=b:CreateTexture(nil,"ARTWORK",nil,-2);skin.art[#skin.art+1]=t;return t
  end
  skin.fill=art();skin.fill:SetPoint("TOPLEFT",2,-2);skin.fill:SetPoint("BOTTOMRIGHT",-2,-drop)
  local top=art();top:SetPoint("TOPLEFT",3,0);top:SetPoint("TOPRIGHT",-3,0);top:SetHeight(2);skin.edges[1]=top
  for i,side in ipairs({"LEFT","RIGHT"})do
    local edge=art();edge:SetPoint("TOP"..side,side=="LEFT" and 1 or -1,-2)
    edge:SetPoint("BOTTOM"..side,side=="LEFT" and 1 or -1,-drop);edge:SetWidth(2);skin.edges[i+1]=edge
  end
  skin.label=b:GetFontString()
  for _,t in ipairs(skin.art)do t:Show()end
end
function N.Navigation()
  if P.window then for _,b in pairs(P.window.tabs)do skinButton(b,4)end end
  if P.mini then
    skinButton(P.mini.careButton);skinButton(P.mini.towerButton)
    N.buttons[P.mini.careButton].miniMode="care";N.buttons[P.mini.towerButton].miniMode="tower"
  end
  if P.journal then for _,b in pairs(P.journal.subButtons)do skinButton(b)end end
  for b,skin in pairs(N.buttons)do
    local selected=skin.miniMode and P.miniMode==skin.miniMode or not skin.miniMode and not b:IsEnabled();local high=not not S.HighContrast()
    -- Enable/disable can refresh template art even if the selected tab did not change.
    for _,v in ipairs(skin.original)do v.texture:SetAlpha(0)end
    local purple=S.HardTheme()
    if skin.selected~=selected or skin.high~=high or skin.purple~=purple then
      skin.selected=selected;skin.high=high;skin.purple=purple
      skin.fill:SetColorTexture(selected and .38 or .26,selected and .29 or .22,selected and .15 or .16,1)
      if high then
        skin.fill:SetColorTexture(selected and .30 or .035,selected and .30 or .035,selected and .30 or .035,1)
        if CreateColor and skin.fill.SetGradient then
          local shade=selected and .30 or .035
          skin.fill:SetColorTexture(1,1,1,1)
          skin.fill:SetGradient("VERTICAL",CreateColor(shade,shade,shade,1),CreateColor(shade,shade,shade,1))
        end
      elseif purple then
        skin.fill:SetColorTexture(selected and .43 or .23,selected and .23 or .12,selected and .58 or .34,1)
        if CreateColor and skin.fill.SetGradient then
          skin.fill:SetColorTexture(1,1,1,1)
          skin.fill:SetGradient("VERTICAL",CreateColor(.18,.08,.27,1),selected and CreateColor(.55,.28,.72,1) or CreateColor(.29,.17,.39,1))
        end
      elseif CreateColor and skin.fill.SetGradient then
        skin.fill:SetColorTexture(1,1,1,1)
        skin.fill:SetGradient("VERTICAL",
          CreateColor(.26,.20,.13,1),
          selected and CreateColor(.68,.49,.14,1) or CreateColor(.35,.30,.23,1))
      end
      for _,edge in ipairs(skin.edges)do
        if high then edge:SetColorTexture(1,1,selected and 0 or 1,1)
        elseif purple then edge:SetColorTexture(selected and .88 or .53,selected and .66 or .36,selected and 1 or .69,1)
        else edge:SetColorTexture(selected and 1 or .56,selected and .83 or .46,selected and .26 or .31,1)end
      end
      if skin.label then
        if high then skin.label:SetTextColor(1,1,1)
        else skin.label:SetTextColor(selected and 1 or .77,selected and .94 or .73,selected and .78 or .64)end
      end
    end
  end
end
function N.Apply()
  for _,p in ipairs(S.panels)do N.Panel(p)end
  root(P.window,false);root(F.compass,true)
  local high=S.HighContrast();local purple=S.HardTheme()
  for p,skin in pairs(N.panels)do N.PaintPanel(p,skin)end
  for w,skin in pairs(N.roots)do
    skin.header:SetVertexColor(purple and .40 or .53,purple and .19 or .37,purple and .58 or .17,1)
    skin.shelf:SetVertexColor(purple and .42 or .53,purple and .26 or .45,purple and .62 or .34,1)
    skin.footer:SetVertexColor(purple and .40 or .53,purple and .19 or .37,purple and .58 or .17,1)
    for _,region in ipairs({skin.outer:GetRegions()})do
      if region:GetObjectType()=="Texture"then
        local title=region==rawget(skin.outer,"TopLeftCorner") or region==rawget(skin.outer,"TopEdge") or region==rawget(skin.outer,"TopRightCorner")
        -- Every native edge and corner has baked brown/gold artwork. Neutralize
        -- it before the purple tint, including the side rails and bottom rim.
        region:SetDesaturated(purple)
        region:SetVertexColor(purple and .78 or 1,purple and (title and .42 or .58) or 1,1,1)
      end
    end
    skin.outer:SetBackdropBorderColor(purple and .72 or .68,purple and .46 or .49,purple and .96 or .25,1)
    skin.outer:SetShown(not high);skin.header:SetShown(not high)
    skin.shelf:SetShown(not high);skin.footer:SetShown(not high)
    if skin.tabRail then
      skin.tabRail:Show()
      if high then skin.tabRail:SetColorTexture(.85,.85,.85,1)
      elseif purple then skin.tabRail:SetColorTexture(.66,.43,.85,1)
      else skin.tabRail:SetColorTexture(.56,.46,.31,1)end
    end
    w:SetBackdropColor(0,0,0,0);w:SetBackdropBorderColor(0,0,0,0)
    for _,v in ipairs(skin.backgrounds)do v.region:SetAlpha(0)end
    for _,v in ipairs(skin.controls)do
      if v.cog then v.frame:Hide();skin.settings:Show()
      else
        v.frame:ClearAllPoints()
        v.frame:SetPoint("TOPRIGHT",w,"TOPRIGHT",skin.compact and -6 or -3,skin.compact and -9 or -13)
        if skin.compact then v.frame:SetSize(26,26)end
      end
    end
    for _,v in ipairs(skin.labels)do
      if v.value=="YOUR COMPANIONS. YOUR ADVENTURE."then v.text:Hide()
      else
        v.text:ClearAllPoints()
        v.text:SetPoint("TOPLEFT",skin.compact and 12 or 22,skin.compact and -15 or -14)
        v.text:SetWidth(skin.compact and 210 or 650);v.text:SetText("Companions Forever")
      end
    end
  end
  for _,skin in pairs(N.buttons)do skin.high=nil end
  N.Navigation()
  if N.Layout then N.Layout()end
end
local theme=S.ApplyTheme
function S.ApplyTheme(...)local result=theme(...);N.Apply();return result end
local build=P.BuildUI
function P.BuildUI(...)local result=build(...);if P.window and not N.roots[P.window]then N.Apply()end;return result end
local desktop=F.BuildDesktop
function F.BuildDesktop(...)local result=desktop(...);N.Apply();return result end
local render=P.Render
function P.Render(...)local result=render(...);N.Navigation();if N.Layout then N.Layout()end;return result end
local settings=F.OpenSettings
function F.OpenSettings(...)
  local result=settings(...);if F.settings and rawget(F.settings,"hardThemeReplay")then F.settings.hardThemeReplay:SetEnabled(P.HardMode.IsUnlocked())end;N.Apply();return result
end

local A=F.Achievements
local function metrics(...)local t={};for _,key in ipairs({...})do t[key]=true end;return t end
N.groups={
  {id="all",name="All achievements"},
  {id="pets",name="Companions",children={
    {id="collection",name="Collection",metrics=metrics("collection","sparklyPets")},
    {id="abilities",name="Abilities",metrics=metrics("abilitiesFound")},
    {id="native",name="WoW pets",metrics=metrics("native")},
    {id="training",name="Training & care",metrics=metrics("training","retired","treatsEaten","goldStat")}}},
  {id="tower",name="Tower",children={
    {id="ascent",name="Climbing",metrics=metrics("tower")},
    {id="challenges",name="Challenges",metrics=metrics("common","commonTower","rares")}}},
  {id="adventure",name="Adventure",children={
    {id="kills",name="Creature kills",metrics=metrics("kills")},
    {id="exploration",name="Exploration",metrics=metrics("zones","east","west","both","desert","cold","horizons")},
    {id="forever",name="Forever zones",metrics=metrics("forever")},
    {id="jumps",name="Jumping",metrics=metrics("jumps")}}},
  {id="pvp",name="Player vs. Player",metrics=metrics("pvpKills")},
  {id="dungeons",name="Dungeons",children={
    {id="classic",name="Dungeon runs",metrics=metrics("dungeons","uniqueDungeons","dungeonBosses")},
    {id="newDungeons",name="Forever dungeons",metrics=metrics("foreverDungeons","uniqueForever")}}}
}
N.categories={};N.category="all";N.expanded={}
for _,group in ipairs(N.groups)do
  N.categories[group.id]=group
  if group.children then
    group.metrics={}
    for _,child in ipairs(group.children)do
      N.categories[child.id]=child
      for key in pairs(child.metrics)do group.metrics[key]=true end
    end
  end
end
local browse=A.Browse
function A.Browse(mode)
  local rows=browse(mode);local category=N.categories[N.category]
  if not category or not category.metrics then return rows end
  local filtered={};for _,d in ipairs(rows)do if category.metrics[d.metric]then filtered[#filtered+1]=d end end
  return filtered
end
local function place(object,x,y,w,h,anchor)
  object:ClearAllPoints();object:SetPoint(anchor or "TOPLEFT",x,y)
  if w then object:SetWidth(w)end;if h then object:SetHeight(h)end
end
function N.Journal(f)
  if not f or not f.achievementPanel then return end
  local a=f.achievementPanel
  if not N.journal then
    local j={buttons={}};N.journal=j
    j.side=S.Panel(a,0,-36,174,414)
    j.empty=S.Text(a,"No matching achievements",190,-52,398,"GameFontHighlight",S.muted)
    local function button(d,child)
      local b=CreateFrame("Button",nil,j.side,"BackdropTemplate");j.buttons[d.id]=b
      b:SetSize(child and 154 or 166,26)
      b:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8})
      b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
      b.label=S.Text(b,d.name,child and 6 or 8,-3,child and 142 or 140,"GameFontHighlightSmall",S.gold);b.label:SetHeight(20);b.label:SetWordWrap(false)
      if d.children then b.symbol=S.Text(b,"+",145,-3,16,"GameFontHighlight",S.gold)end
      b:SetScript("OnClick",function()
        if d.children then local open=not N.expanded[d.id];N.expanded={};N.expanded[d.id]=open end
        N.category=d.id;a.offset=0;P.RenderJournal()
      end)
      b:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(d.name);GameTooltip:Show()end)
      b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
    for _,group in ipairs(N.groups)do button(group);for _,child in ipairs(group.children or {})do button(child,true)end end
  end
  local j=N.journal;j.side:Show();j.high=not not S.HighContrast()
  if not j.laidOut then
    j.laidOut=true
      place(a.count,622,0,338,28)
      place(a.details,622,-36,338,414)
      place(a.title,82,-12,240,54)
      place(a.desc,16,-78,306,62)
      for _,t in ipairs(S.texts)do
        if t:GetParent()==a.details and t:GetText()=="REWARDS"then place(t,16,-147,306,24)end
      end
      for k,v in ipairs(a.rewardIcons)do place(v,18+(k-1)*70,-178,44,44)end
      place(a.reward,16,-235,306,66)
      place(a.status,16,-309,306,44)
      place(a.claim,16,-374,306,26)
      place(a.sort,0,-480,184,26)
      place(a.pageLabel,196,-480,404,26)
      for i,row in ipairs(a.rows)do
        place(row,182,-36-(i-1)*84,418,78)
        place(row.icon,10,-10,40,40);row.rim:SetSize(62,62)
        place(row.title,64,-4,342,28)
        place(row.progress,64,-36,206,22);row.progress:SetJustifyH("LEFT")
        place(row.fill,64,12,nil,nil,"BOTTOMLEFT")
        -- Give completion its own space below the icon, clear of its rim.
        place(row.done,21,-52,20,20)
        row.done:SetDrawLayer("OVERLAY",7)
        for k,v in ipairs(row.rewards)do
          place(v,286+(k-1)*30,-34,24,24)
          -- Portrait decorations are designed for larger portraits. Scale the
          -- preview geometry so its corners cannot spill into nearby rewards.
          v.border:SetScale(.5)
        end
        row.desc:Hide()
      end
  end
  j.empty:SetShown(f.subtab=="achievements" and not rawget(a.rows[1],"entry"))
  local y=-6
  local function position(d,child,shown)
    local b=j.buttons[d.id];b:SetShown(shown);if not shown then return end
    b:ClearAllPoints();b:SetPoint("TOPLEFT",child and 14 or 4,y);y=y-28
    local selected=N.category==d.id
    if S.HighContrast()then
      b:SetBackdropColor(selected and .30 or .035,selected and .30 or .035,selected and .30 or .035,1)
      b:SetBackdropBorderColor(1,1,selected and 0 or 1,1)
    else
      b:SetBackdropColor(selected and .38 or .12,selected and .26 or .09,selected and .08 or .05,1)
      b:SetBackdropBorderColor(selected and 1 or .55,selected and .8 or .4,.2,1)
    end
    S.TextColor(b.label,S.gold)
    if rawget(b,"symbol")then b.symbol:SetText(N.expanded[d.id] and "-" or "+")end
  end
  -- Only one branch is expanded at once, keeping the sidebar within its panel.
  for _,group in ipairs(N.groups)do
    position(group,false,true)
    for _,child in ipairs(group.children or {})do position(child,true,N.expanded[group.id])end
  end
  a.pageLabel:SetText("PvP kills: "..(P.state.achievements.pvpKills or 0))
  for _,row in ipairs(a.rows)do
    if rawget(row,"entry")then
      row.fill:SetWidth(math.max(1,342*math.min(1,A.Progress(row.entry)/row.entry.goal)))
      if S.HighContrast()then
        local selected=row.entry.id==a.selected
        row:SetBackdropColor(selected and .16 or .025,selected and .16 or .025,selected and .16 or .025,1)
        row:SetBackdropBorderColor(1,1,selected and 0 or 1,1)
        row.fill:SetColorTexture(1,1,1,1)
      else
        local n=A.Progress(row.entry);local achieved=P.state.achievements.claimed[row.entry.id] or n>=row.entry.goal
        row:SetBackdropColor(row.entry.id==a.selected and .16 or .055,.08,.09,1)
        row:SetBackdropBorderColor(unpack(n>=row.entry.goal and S.gold or S.muted))
        row.fill:SetColorTexture(achieved and .9 or .3,achieved and .7 or .32,.25,1)
      end
    end
  end
end
local renderJournal=P.RenderJournalExtras
function P.RenderJournalExtras(f,...)
  local result=renderJournal(f,...);N.Journal(f);return result
end

function N.Stock(bar)
  if not bar then return end
  local signature=tostring(S.HighContrast())..":"..tostring(bar.fontSize)
  for _,key in ipairs({"tokens","food","medicine"})do signature=signature..":"..tostring(bar.fields[key].amount)end
  if bar.cfNativeStockKey==signature then return end;bar.cfNativeStockKey=signature
  if not rawget(bar,"cfNativeStock")then
    bar.cfNativeStock=true
    local update=bar:GetScript("OnUpdate")
    bar:SetScript("OnUpdate",function(self,dt)update(self,dt);N.Stock(self)end)
  end
  if not bar.compact then bar:ClearAllPoints();bar:SetPoint("TOPLEFT",22,-704)end
  for i,key in ipairs({"tokens","food","medicine"})do
    local field=bar.fields[key];local x=(i-1)*164
    if not field.cfNativeIcon then
      field.cfNativeIcon=bar:CreateTexture(nil,"ARTWORK")
      field.cfNativeIcon:SetTexture(key=="tokens" and P.tokenIcon or "Interface\\Icons\\"..P.items[key].icon)
      field.cfNativeIcon:SetSize(20,20)
    end
    field.total:SetText(field.amount..field.suffix)
    local textWidth=132
    if bar.compact then
      local measured=field.total:GetStringWidth()
      textWidth=math.min(60,math.ceil(type(measured)=="number" and measured or #tostring(field.amount)*math.max(12,bar.fontSize or 0)*.6)+2)
      x=(i-1)*88+(88-26-textWidth)/2
    end
    field.cfNativeIcon:ClearAllPoints();field.cfNativeIcon:SetPoint("TOPLEFT",x,0)
    field.cfNativeIcon:Show()
    field.total:ClearAllPoints();field.total:SetPoint("TOPLEFT",bar,"TOPLEFT",x+26,0);field.total:SetWidth(textWidth)
    field.gain:ClearAllPoints();field.gain:SetPoint("TOPLEFT",bar,"TOPLEFT",x+26,bar.compact and -20 or 20);field.gain:SetWidth(textWidth)
  end
end
local function compactSideTab(button,m,index,icon,title)
  local skin=rawget(button,"cfSideTab")
  if not skin then
    skin={original={}};button.cfSideTab=skin
    for _,region in ipairs({button:GetRegions()})do
      if region:GetObjectType()=="Texture"then skin.original[#skin.original+1]=region end
    end
    skin.label=button:GetFontString()
    skin.back=button:CreateTexture(nil,"BACKGROUND")
    skin.back:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
    skin.back:SetSize(64,64);skin.back:SetPoint("TOPLEFT",-3,11)
    skin.icon=button:CreateTexture(nil,"ARTWORK");skin.icon:SetAllPoints()
    skin.icon:SetTexture("Interface\\Icons\\"..icon)
    skin.rim=CreateFrame("Frame",nil,button,"BackdropTemplate");skin.rim:EnableMouse(false)
    skin.rim:SetPoint("TOPLEFT",-2,2);skin.rim:SetPoint("BOTTOMRIGHT",2,-2)
    skin.rim:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    skin.hover=button:CreateTexture(nil,"HIGHLIGHT");skin.hover:SetAllPoints()
    skin.hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square");skin.hover:SetBlendMode("ADD")
    if index==1 then
      skin.new=S.Text(button,"NEW",0,0,40,"GameFontNormalSmall",{.2,1,.2});skin.new:SetJustifyH("CENTER")
      skin.new:ClearAllPoints();skin.new:SetPoint("BOTTOM",button,"TOP",0,5);skin.new:SetHeight(18)
    else
      button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(button,"ANCHOR_LEFT");GameTooltip:SetText(title)
        GameTooltip:AddLine("Buy food and healing supplies. Click again to close.",1,1,1,true);GameTooltip:Show()
      end)
      button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
  end
  button:SetParent(m);button:ClearAllPoints();button:SetPoint("TOPLEFT",m,"TOPRIGHT",4,-48-(index-1)*42)
  button:SetSize(32,32);button:SetFrameLevel(m:GetFrameLevel()+65)
  for _,region in ipairs(skin.original)do region:SetAlpha(0)end
  if skin.label then skin.label:SetAlpha(0)end
  local high,purple=S.HighContrast(),S.HardTheme()
  skin.back:SetDesaturated(high or purple)
  skin.back:SetVertexColor(high and .35 or purple and .72 or 1,high and .35 or purple and .42 or 1,1,1)
  if high then skin.back:SetVertexColor(.25,.25,.25,1)end
  skin.rim:SetShown(high)
  skin.rim:SetBackdropBorderColor(1,1,1,1)
  if skin.new then skin.new:SetShown(F.Mailbox.HasUnreadMail())end
end
function N.CompactTabs()
  local m=P.mini;if not m then return end
  if rawget(m,"mailButton")then compactSideTab(m.mailButton,m,1,"INV_Letter_15","Mail")end
  compactSideTab(m.supplies,m,2,"INV_Misc_Bag_10","Supplies")
  if F.compass then F.compass:SetClampRectInsets(0,-64,0,0)end
end
function N.Compact()
  local m=P.mini;if not m then return end
  local tower=P.miniMode=="tower"
  -- Both Camp arrows follow the resized scene, instead of its original height.
  for _,v in ipairs({{m.scene.campPrev,"BOTTOMLEFT",6},{m.scene.campNext,"BOTTOMRIGHT",-6}})do
    v[1]:ClearAllPoints();v[1]:SetPoint(v[2],m.scene,v[2],v[3],6)
  end
  if rawget(m,"mailButton")then
    place(m.careButton,8,-8,80,26);place(m.towerButton,98,-8,80,26)
    place(m.openButton,188,-8,86,26)
  end
  N.CompactTabs()
  place(m.stock,10,tower and -408 or -358,264,40)
  N.Stock(m.stock)
  if tower and rawget(m,"hardChoices")then
    local tactics=m.hardChoices.tactics[1]:IsShown()
    for i,b in ipairs(m.hardChoices.styles)do place(b,(tactics and 10 or 85)+(i-1)*30,-262,24,24)end
  end
  if tower then
    local count=3
    for _,b in ipairs(rawget(m,"specialButtons") or {})do if b:IsShown()then count=count+1 end end
    local width=284/count-4
    local function actionLabel(b,label)
      label:ClearAllPoints();label:SetPoint("TOP",b,"BOTTOM",0,-4)
      label:SetSize(width,24);label:SetJustifyH("CENTER");label:SetMaxLines(2)
      label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",math.max(12,math.min(16,S.MinimumTextSize())),"OUTLINE")
      S.TextColor(label,S.gold);label:SetShown(b:IsShown())
    end
    m.battle[3].label:SetText("Heal")
    for _,b in ipairs(m.battle)do actionLabel(b,b.label)end
    for _,b in ipairs(rawget(m,"specialButtons") or {})do
      if not rawget(b,"actionLabel")then b.actionLabel=b:CreateFontString(nil,"OVERLAY")end
      actionLabel(b,b.actionLabel)
      b.actionLabel:SetText("Special")
    end
    m.notice:ClearAllPoints();m.notice:SetPoint("TOPLEFT",m.footer,"TOPLEFT",10,-386)
    m.notice:SetHeight(18);m.notice:SetMaxLines(1)
  end
  if rawget(m,"hardTeam")then
    local hard=P.HardMode.IsHard()
    for i,row in ipairs(m.hardTeam.rows)do
      row:SetWidth(not hard and i==1 and 260 or (268-14)/3)
      row.info:SetWidth(not hard and i==1 and 220 or 49)
    end
  end
end
local renderCompact=P.RenderCompass
function P.RenderCompass(...)
  local result=renderCompact(...);N.Compact();N.Navigation();return result
end
function N.TalentXP()
  local f=P.talents;if not f then return end
  local bar=f.xp
  -- The scenic talent-tree artwork is decorative, not a model viewport.
  if not N.talentArt then
    N.talentArt={}
    for _,region in ipairs({f.tree:GetRegions()})do
      if region:GetObjectType()=="Texture"then
        local file=region:GetTexture()
        if type(file)=="string" and file:find("Art\\PetScenes",1,true)then N.talentArt[#N.talentArt+1]=region end
      end
    end
  end
  for _,region in ipairs(N.talentArt)do region:SetAlpha(S.HighContrast() and 0 or .22)end
  local skin=P.StyleXPBar(bar,true)
  bar.cfNativeCells=skin.cells;bar.cfNativeRim=skin.rim
  -- Keep the retirement preview under the same metallic frame and dividers.
  if not S.HighContrast() and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-HUD-ExperienceBar-Fill-Prediction")then
    f.xpPreview:SetAtlas("UI-HUD-ExperienceBar-Fill-Prediction");f.xpPreview:SetVertexColor(1,1,1,.85)
  else f.xpPreview:SetColorTexture(.25,.65,1,.85)end
end
local renderTalents=P.RenderTalents
function P.RenderTalents(...)
  local result=renderTalents(...);N.TalentXP();return result
end
function N.Layout()
  if P.window then
    P.window.notice:Hide();N.Stock(P.window.stock)
  end
  if P.mini then P.mini.notice:Hide();N.Compact()end
  N.TalentXP()
  if P.journal and rawget(P.journal,"abilityBook") and P.journal.subtab=="abilities"then P.RenderAbilityBook(P.journal.abilityBook)end
  if P.journal and (not N.journal or N.journal.high~=not not S.HighContrast())then N.Journal(P.journal)end
end
