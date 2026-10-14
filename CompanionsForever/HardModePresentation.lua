local _,F=...
local P,S,H=F.Pets,F.Style,F.Pets.HardMode
local M={};F.HardModePresentation=M
function S.HardTheme()
  return not S.HighContrast() and F.db and F.db.settings.hardModeTheme~=false and H.IsUnlocked()
    and (not M.pending or M.themeReady) or false
end
local theme=S.Theme
function S.Theme()
  if S.HardTheme()then return {bg={.065,.035,.10,1},panel={.085,.045,.13,1},accent={.35,.16,.48,1},fade={.08,.04,.12,1},crest=theme().crest}end
  return theme()
end
local function build()
  if M.frame then return M.frame end
  local f=CreateFrame("Frame",nil,UIParent);M.frame=f;f:SetAllPoints(UIParent);f:SetFrameStrata("FULLSCREEN_DIALOG");f:EnableMouse(false)
  f.readableBackdrop=f:CreateTexture(nil,"BACKGROUND",nil,1);f.readableBackdrop:SetPoint("CENTER",0,18);f.readableBackdrop:SetSize(960,156);f.readableBackdrop:SetColorTexture(.015,.015,.015,1);f.readableBackdrop:Hide()
  f.wash=f:CreateTexture(nil,"BACKGROUND");f.wash:SetAllPoints();f.wash:SetColorTexture(.11,.015,.19,.42)
  f.rays={}
  for i=1,3 do
    local t=f:CreateTexture(nil,"ARTWORK");f.rays[i]=t;t:SetTexture("Interface\\Cooldown\\star4");t:SetPoint("CENTER",0,45)
    t:SetBlendMode("ADD");t:SetVertexColor(.58,.22,1,.32)
  end
  f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalHuge");f.title:SetPoint("CENTER",0,45);f.title:SetWidth(900)
  f.title:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",34,"OUTLINE");f.title:SetTextColor(.90,.72,1);f.title:SetText("HARD MODE UNLOCKED")
  f.subtitle=f:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge");f.subtitle:SetPoint("TOP",f.title,"BOTTOM",0,-14);f.subtitle:SetWidth(780)
  f.subtitle:SetText("The deeper tower awaits.")
  f.detail=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");f.detail:SetPoint("TOP",f.subtitle,"BOTTOM",0,-10);f.detail:SetWidth(780)
  f.detail:SetText("Three-pet battles  |  16 stable slots")
  f:SetScript("OnUpdate",function(_,dt)M.Update(dt)end);f:Hide();return f
end
local function paintBanner(f)
  local high=S.HighContrast()
  f.readableBackdrop:SetShown(high)
  f.title:SetTextColor(high and 1 or .90,high and 1 or .72,1)
end
function M.Finish()
  M.pending=nil;M.active=nil;M.themeReady=true
  if M.frame then M.frame:Hide()end
  if F.db then S.ApplyTheme()end
end
function M.Play(preview)
  if not H.IsUnlocked()then return false,"Unlock Hard Mode first."end
  local f=build();M.active=true;M.pending=true;M.themeReady=false;M.elapsed=0;M.preview=preview
  M.still=F.db.settings.reduceMotion or S.HighContrast()
  paintBanner(f)
  if not preview then P.state.hardUnlockPresented=true end
  f.wash:SetShown(not M.still)
  for _,t in ipairs(f.rays)do t:SetShown(not M.still)end
  f:SetAlpha(M.still and 1 or 0);f:Show();S.ApplyTheme();return true
end
function M.Queue()
  if M.initializing or not P.state or P.state.hardUnlockPresented or M.pending then return end
  M.pending=true;M.themeReady=false;M.active=nil;local f=build();f:SetAlpha(0);f:Show()
end
function M.Update(dt)
  if not M.pending then return end
  if not H.IsUnlocked()then M.Finish();return end
  if M.active and not M.preview and F.db.settings.hardModeUnlockAnimation==false then M.Finish();return end
  if not M.active then
    local v=P.victory
    if P.state.battle or v and (P.sceneClock or 0)<v.readyAt then return end
    if F.db.settings.hardModeUnlockAnimation==false then P.state.hardUnlockPresented=true;M.Finish();return end
    M.Play(false)
  end
  if not M.still and (F.db.settings.reduceMotion or S.HighContrast())then
    M.still=true;M.frame.wash:Hide();for _,ray in ipairs(M.frame.rays)do ray:Hide()end
  end
  paintBanner(M.frame)
  M.elapsed=M.elapsed+math.max(0,math.min(dt or 0,.1))
  local t=M.elapsed;local duration=M.still and 2.5 or 4.5
  if not M.themeReady and t>=(M.still and 0 or 1.25)then M.themeReady=true;S.ApplyTheme()end
  if t>=duration then M.Finish();return end
  local f=M.frame
  f:SetAlpha(M.still and 1 or math.min(1,t/.65,(duration-t)/.8))
  if not M.still then
    for i,ray in ipairs(f.rays)do
      local size=240+i*65+t*48;ray:SetSize(size,size);ray:SetRotation(t*(i%2==0 and -.12 or .1)+i)
      ray:SetAlpha(.20+.10*math.sin(math.min(1,t/2)*math.pi))
    end
  end
end
local refresh=H.RefreshUnlock
function H.RefreshUnlock(...)
  local was=P.state and P.state.hardMode and P.state.hardMode.unlocked
  local result=refresh(...)
  if not was and H.IsUnlocked()then M.Queue()end
  return result
end
local init=P.Init
function P.Init(...)
  if M.frame then M.frame:Hide()end;M.pending=nil;M.active=nil;M.initializing=true
  local result=init(...);M.initializing=nil
  -- Existing unlocked saves get the theme without replaying a login cinematic.
  if H.IsUnlocked()then P.state.hardUnlockPresented=true end
  return result
end
function M.Settings(w)
  local box=S.Panel(w,566,-54,376,484);w.hardAppearancePanel=box
  S.Text(box,"Hard Mode appearance",16,-12,318,"GameFontNormalLarge",S.gold)
  local function option(label,y,key)
    local c=S.Check(box,"",12,y,key);S.Text(c,label,32,-3,278,"GameFontHighlight"):SetHeight(38);return c
  end
  option("Purple theme after unlock",-54,"hardModeTheme")
  option("Full-screen unlock animation",-102,"hardModeUnlockAnimation")
  S.Text(box,"Unlocks after normal floor 100.\nHigh Contrast takes priority; Reduced Motion uses a still banner.",16,-155,318,"GameFontHighlightSmall",S.muted):SetHeight(66)
  w.hardThemeReplay=S.Button(box,"Replay unlock animation",16,-238,318,function()M.Play(true)end)
  w.hardThemeReplay:SetEnabled(H.IsUnlocked())
  S.Text(box,"Cosmetic frames",16,-285,318,"GameFontNormalLarge",S.gold)
  w.portraitFrameOptions={
    large=option("Show frame in large Camp",-320,"showLargePortraitFrame"),
    compact=option("Show frame in compact Camp",-360,"showCompactPortraitFrame"),
    mini=option("Show frame on mini pet",-400,"showMiniPortraitFrame"),
  }
  S.Text(box,"Inspect always shows your equipped frame.",16,-444,318,"GameFontHighlightSmall",S.muted):SetHeight(32)
end
