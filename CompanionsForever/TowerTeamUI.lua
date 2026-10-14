local _,F=...
local P,S,H=F.Pets,F.Style,F.Pets.HardMode
local function lab()return P.state.hardMode end
local function find(id)
  for _,pet in ipairs(P.state and P.state.pets or {})do if pet.id==id then return pet end end
end
local function text(parent,value,x,y,width,height)local t=S.Text(parent,value,x,y,width,"GameFontHighlightSmall",S.gold);t:SetHeight(height);return t end
local function run(fn)local ok,msg=fn();if msg then P.notice=msg end;P.Render();return ok,msg end
local function buildTeam(parent,x,y,width,height,compact)
  local panel=S.Panel(parent,x,y,width,height);panel.rows={}
  for i=1,3 do
    local button=CreateFrame("Button",nil,panel,"BackdropTemplate");panel.rows[i]=button;button.compact=compact
    button:SetPoint("TOPLEFT",4+(i-1)*(width-8)/3,-4);button:SetSize((width-14)/3,height-8)
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2});button:SetBackdropColor(0.04,0.04,0.06,1)
    button.art=button:CreateTexture(nil,"ARTWORK");button.art:SetSize(compact and 24 or 30,compact and 24 or 30);button.art:SetPoint("TOPLEFT",4,-4)
    button.info=text(button,"",compact and 31 or 46,-2,compact and 49 or 96,20)
    button.hp=CreateFrame("StatusBar",nil,button);button.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");button.hp:SetStatusBarColor(0.1,0.8,0.2);button.hp:SetMinMaxValues(0,1)
    button.hp:SetPoint("BOTTOMLEFT",4,13);button.hp:SetPoint("BOTTOMRIGHT",-4,13);button.hp:SetHeight(16)
    button.petXP=P.BuildPetXP(button,false);button.petXP:SetPoint("BOTTOMLEFT",4,4);button.petXP:SetPoint("BOTTOMRIGHT",-4,4);button.petXP:SetHeight(5)
    local bg=button.hp:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(0.05,0.1,0.05,1)
    button.hpText=text(button.hp,"",0,0,(width-14)/3-8,compact and 16 or 19);button.hpText:ClearAllPoints();button.hpText:SetAllPoints();button.hpText:SetJustifyH("CENTER")
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:SetScript("OnClick",function(self,key)if key=="RightButton"then H.OpenStable(self,i)elseif self.petID then run(function()return H.SelectTarget(self.petID)end)end end)
    button:SetScript("OnEnter",function(self)
      local pet=self.petID and find(self.petID);if not pet then return end
      local hp,maxHP=H.Health(pet,true)
      GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(P.PetName(pet));GameTooltip:AddLine("Level "..pet.level.." | "..math.ceil(hp).." / "..maxHP.." HP",1,1,1)
      GameTooltip:AddLine("Left click: select for herbs and abilities. Right click: equip a pet.",1,0.82,0.3,true);GameTooltip:Show()
    end);button:SetScript("OnLeave",function()GameTooltip:Hide()end)
  end
  panel:SetScript("OnUpdate",function(self,dt)
    self.elapsed=(self.elapsed or 0)+dt;if self.elapsed<0.1 then return end;self.elapsed=0
    if H.RefreshTeam and P.state and lab()then H.RefreshTeam(self)end
  end)
  return panel
end
local build=P.BuildUI
function P.BuildUI()
  build();local w=P.window;if rawget(w,"hardTeam")then return end
  w.hardTeam=buildTeam(w.home,20,-494,456,70,false)
  local panel=S.Panel(w.home,492,-530,488,124);w.hardPanel=panel
  panel.target=text(panel,"",10,-5,464,23)
  panel.equipHint=text(panel,"Right-click a portrait to choose a pet.",10,-33,464,26)
  panel.bonus=text(panel,"",10,-62,464,26)
  panel.normal=S.Button(panel,"Normal",10,-92,142,function()run(function()return H.SetMode("normal")end)end)
  panel.hard=S.Button(panel,"Hard Mode",164,-92,142,function()run(function()return H.SetMode("hard")end)end)
  panel.claim=S.Button(panel,"Claim rewards",318,-92,156,function()run(P.ClaimWaitingCrate)end)
end
local function refreshTeam(panel)
  local team=H.Team()
  for i,row in ipairs(panel.rows)do local pet=team[i];row.petID=pet and pet.id;row:SetShown(H.IsHard() or i==1)
    row.art:SetShown(pet~=nil);row.hp:SetShown(pet~=nil);P.UpdatePetXP(row.petXP,pet)
    if not pet then row.info:SetText("Choose pet");row:SetBackdropBorderColor(.3,.3,.3,1)end
    if pet then
      P.ShowPetPortrait(row.art,pet);row.art:SetDesaturated(not not pet.deadAt);row.info:SetText(pet.deadAt and "Dead" or "Lv "..pet.level)
      local hp,maxHP=H.Health(pet,true);row.hp:SetMinMaxValues(0,maxHP);row.hp:SetValue(hp);row.hpText:SetText(math.ceil(hp).."/"..maxHP)
      row.hp:SetStatusBarColor(hp>0 and 0.1 or 0.4,hp>0 and 0.8 or 0.4,0.2)
      row:SetBackdropBorderColor(unpack(pet.id==lab().target and {1,0.82,0.25,1} or P.colors[pet.rarity]))
    end
  end
end
H.RefreshTeam=refreshTeam
local render=P.Render
function P.Render()
  render();local w=P.window;if not w or not rawget(w,"hardPanel")or not P.state or not lab()then return end
  local show=P.mode=="tower";w.hardTeam:SetShown(P.mode=="tower");w.hardPanel:SetShown(show);if show then w.gearPreview:Hide()end
  if not show then return end
  refreshTeam(w.hardTeam);local b=P.state.battle;local target=H.Target();local panel=w.hardPanel
  local queued=nil
  panel.target:SetText(queued and ("Queued heal: "..P.PetName(queued)) or ("Selected: "..(target and P.PetName(target) or "select teammate")))
  local ready;if H.IsHard()then ready=H.HealReady(target)else ready=P.HealChoice()~=nil end
  panel.normal:SetEnabled(not b and H.IsHard());panel.hard:SetEnabled(not b and not H.IsHard() and H.IsUnlocked())
  panel.hard:SetText(H.IsUnlocked() and "Hard Mode" or "Hard: clear 100")
  panel.claim:SetEnabled(not b and P.WaitingLootCount()>0)
  local active=target;local c=H.Counts(active);local parts={}
  for i,n in ipairs(c)do if n>0 then parts[#parts+1]=H.sets[i].name.." "..n.."/5"..(n>=4 and " (2+4 active)" or n>=2 and " (2 active)" or "")end end
  panel.bonus:SetText(table.concat(parts," | "))
  if P.HardRefreshScene then P.HardRefreshScene(w.scene)end
  w.tower.floor:SetText((H.IsHard() and "Hard " or "Normal ")..(b and b.floor or P.floor).." / 100")
  w.fight[3]:SetEnabled(ready);w.fight[3].label:SetText("Heal target")
  w.readiness:SetText(b and "Selected: "..(target and P.PetName(target) or "none") or select(3,P.BattleReadiness(P.floor)))
end
local buildCompass=P.BuildCompass
function P.BuildCompass(parent)
  buildCompass(parent);local m=P.mini
  m.hardTeam=buildTeam(m,8,-373,268,70,true)
  m.hardTeam:ClearAllPoints();m.hardTeam:SetPoint("TOPLEFT",m.scene,"BOTTOMLEFT",0,-6)
  -- Keep floor navigation above the native model scene, inside its lower edge.
  m.prev:SetParent(m.scene.hud);m.prev:ClearAllPoints();m.prev:SetPoint("BOTTOMLEFT",m.scene,"BOTTOMLEFT",6,6);m.prev:SetWidth(26)
  m.next:SetParent(m.scene.hud);m.next:ClearAllPoints();m.next:SetPoint("BOTTOMRIGHT",m.scene,"BOTTOMRIGHT",-6,6);m.next:SetWidth(26)
  m.floor:SetParent(m.scene.hud);m.floor:ClearAllPoints();m.floor:SetPoint("BOTTOM",m.scene,"BOTTOM",0,8);m.floor:SetWidth(190)
end
local renderCompass=P.RenderCompass
function P.RenderCompass()
  renderCompass();local m=P.mini;if not m or not rawget(m,"hardTeam")or not P.state or not lab()then return end
  local tower=P.miniMode=="tower";m.hardTeam:SetShown(tower)
  if tower then
    m:SetHeight(640);refreshTeam(m.hardTeam);if P.HardRefreshScene then P.HardRefreshScene(m.scene)end;m.floor:SetText((H.IsHard() and "Hard " or "Floor ")..(P.floor or 1).." / 100")
    m.scene.caption:ClearAllPoints();m.scene.caption:SetPoint("BOTTOMLEFT",m.scene,"BOTTOMLEFT",8,34)
    m.readiness:ClearAllPoints();m.readiness:SetPoint("TOPLEFT",10,-293)
    for i,button in ipairs(m.battle)do button:ClearAllPoints();button:SetPoint("TOPLEFT",37+(i-1)*86,-322);button.label:Hide()end
    local target=H.Target();local b=P.state.battle;m.readiness:SetText("Selected: "..(target and P.PetName(target) or "select teammate"))
    local ready;if H.IsHard()then ready=H.HealReady(target)else ready=P.HealChoice()~=nil end
    m.battle[3]:SetEnabled(ready);m.battle[3].label:SetText("Heal target")
  end
  m.notice:ClearAllPoints();m.notice:SetPoint("TOPLEFT",10,tower and -372 or -324)
  m.supplies:ClearAllPoints();m.supplies:SetPoint("TOPLEFT",178,tower and -372 or -321)
  m.stock:ClearAllPoints();m.stock:SetPoint("TOPLEFT",10,tower and -404 or -352)
end
local navigator=F.UpdateNavigator
function F.UpdateNavigator()
  navigator();if F.compass and P.miniMode=="tower"then F.compass:SetHeight(682);F.compass:SetScale(F.AccessibleScale(F.db.settings.compassScale,300,682))end
end
