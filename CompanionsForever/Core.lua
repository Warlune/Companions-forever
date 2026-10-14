local _,F=...
CompanionsForever=F
F.version="1.3.3"
F.displayName="Companions Forever: Pet Battles & Adventures"
F.defaults={ledgerScale=1,compassScale=1,miniScale=1,textSize=0,highContrast=false,reduceMotion=false,petMapPins=true,shareErrors=true,petRollChat=true,partyWitnesses=true,towerPetHealthBars=false,shortPetTooltips=false,showPetRollRanges=false,hardModeTheme=true,hardModeUnlockAnimation=true}
F.defaults.showLargePortraitFrame=true
F.defaults.showCompactPortraitFrame=true
F.defaults.showMiniPortraitFrame=true
F.defaults.announcePartyDrops=false
F.defaults.receiveGuildDrops=true
F.defaults.closeInCombat=false
function F.Now()return GetServerTime and GetServerTime() or time()end
function F.Print(message,compact)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffdfbc65[CF Pets]|r "..message)end
end
local function copy(value,seen)
  if type(value)~="table" then return value end
  seen=seen or {};if seen[value]then return seen[value]end
  local result={};seen[value]=result
  for key,item in pairs(value)do result[copy(key,seen)]=copy(item,seen)end
  return result
end
local function legacyPets()
  local source=type(WaylaidForeverCharDB)=="table" and WaylaidForeverCharDB.pets and WaylaidForeverCharDB or ForeverWaylaidCharDB
  return type(source)=="table" and source.pets
end
function F.ImportLegacy(replace)
  if F.char.sharedGame then return false,"Your account stable is shared. Old character saves merge when that character logs in; the shared game will not be replaced."end
  if F.char.pets and F.char.pets.trade then return false,"Finish your pending trade before importing pets."end
  local pets=legacyPets()
  if type(pets)~="table" then return false,"Enable updated Waylaid Forever on this character and log in once to import its pets." end
  if F.char.legacyImportedAt then return false,"This character's Waylaid pets have already been imported." end
  if F.char.pets~=nil and not replace then return false,"Your current stable is kept. Use Import old pets in Settings to replace it with a backup." end
  if F.Pets.state and F.Pets.state.battle then return false,"Finish your battle before importing pets." end
  if F.char.pets then F.char.beforeLegacyImport=copy(F.char.pets)end
  F.char.pets=copy(pets)
  F.char.legacyImportedAt=F.Now()
  F.Pets.Init()
  return true,"Imported Waylaid pets, tokens, supplies and tower progress. The original save was kept."
end
function F.Initialize()
  -- Old bundled builds would run a second pet engine and answer peer messages.
  local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  local metadata=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  -- Another author's addon also uses this folder name. A name alone is not
  -- evidence of our old engine, and its saved globals must never be imported.
  local ourLegacyLoader=CompanionsForeverLegacyLoader==true
  local oldCompanion=loaded and loaded("ForeverCompanions") and not ourLegacyLoader
    and metadata and metadata("ForeverCompanions","Author")=="Warlune"
  if loaded and ((loaded("ForeverWaylaid") and not WaylaidForeverLegacyLoader)
      or oldCompanion) then
    F.blocked=true
    F.Print("Disable the old Warlune companion/bundled addon before enabling Companions Forever. Keep its saved data; do not overwrite another author's addon.")
    return
  end
  CompanionsForeverDB=type(CompanionsForeverDB)=="table" and CompanionsForeverDB or (ourLegacyLoader and type(ForeverCompanionsDB)=="table" and copy(ForeverCompanionsDB)) or {}
  CompanionsForeverCharDB=type(CompanionsForeverCharDB)=="table" and CompanionsForeverCharDB or (ourLegacyLoader and type(ForeverCompanionsCharDB)=="table" and copy(ForeverCompanionsCharDB)) or {}
  F.db,F.char=CompanionsForeverDB,CompanionsForeverCharDB
  -- Repair old loading-screen hides; preserve only explicit mini preferences.
  F.char.petIconHidden=F.char.petIconManuallyHidden==true
  if F.char.preferredView~="large" and F.char.preferredView~="compact"then F.char.preferredView=F.char.navPets and "compact" or "large"end
  if type(F.db.settings)~="table" then
    F.db.settings={}
    local account=WaylaidForeverDB or ForeverWaylaidDB
    local old=type(account)=="table" and account.settings
    if type(old)=="table" then
      for key in pairs(F.defaults)do F.db.settings[key]=copy(old[key])end
    end
  end
  -- Preserve an existing CF-message opt-out when splitting guild receiving
  -- from the retired public-guild announcement option.
  if F.db.settings.receiveGuildDrops==nil and F.db.settings.announceSystemDrops==false then F.db.settings.receiveGuildDrops=false end
  for key,value in pairs(F.defaults)do if F.db.settings[key]==nil then F.db.settings[key]=value end end
  F.db.settings.announceGuildDrops=nil;F.db.settings.announceSystemDrops=nil
  F.db.settings.nativeUITrial=nil -- The accepted native layout is now the default.
  if not F.db.settings.betaDiagnosticsDefault then
    F.db.settings.shareErrors=true;F.db.settings.betaDiagnosticsDefault=true
    F.Print("Error sharing with War Lune is on. Only Companions Forever error summaries are shared; Settings > Error reports controls it.")
  end
  if F.Errors then F.Errors.Initialize()end
  if not F.char.sharedGame and F.char.pets==nil and type(legacyPets())=="table" then
    local _,notice=F.ImportLegacy(false);F.Pets.notice=notice;F.Print(notice)
  elseif not F.AccountSave then F.Pets.Init()end
  if F.AccountSave and not F.AccountSave.Initialize()then F.ready=false;return end
  F.ready=true
end
local events=CreateFrame("Frame");F.events=events
events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UI_SCALE_CHANGED");events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" and name=="CompanionsForever" then F.Initialize()
  elseif event=="PLAYER_LOGOUT" and F.AccountSave then F.AccountSave.Logout()
  elseif event=="PLAYER_REGEN_DISABLED" and F.ready and F.CloseCombatWindows then F.CloseCombatWindows()
  elseif event=="PLAYER_ENTERING_WORLD" and F.ready and F.petIcon then F.RenderPetIcon();F.UpdateNavigator()
  elseif (event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED") and F.ready then
    F.PlaceMinimap();F.PlacePetIcon();F.ApplySettings()
  elseif event=="PLAYER_LOGIN" then
    if not F.ready then F.Initialize()end
    if not F.ready then if F.AccountSave and F.AccountSave.error then F.Print(F.AccountSave.error)end;return end
    F.BuildDesktop();F.ApplySettings();F.InstallCompanionTooltips();F.InstallFarmMap()
    if F.AccountSave and F.AccountSave.ShowNotice then F.AccountSave.ShowNotice()end
    F.Print("v"..F.version.." - /cfpets to open, /cfpets small for the compact window, /cfpets pet for your screen portrait.")
    if not F.char.legacyImportedAt and type(legacyPets())=="table" then
      F.Print("An older Waylaid stable is available. Settings can import it; your current stable will be backed up first.")
    end
  end
end)
SLASH_COMPANIONSFOREVER1="/cfpets"
SLASH_COMPANIONSFOREVER2="/companionsforever"
-- Keep non-conflicting legacy macros. /cf belongs to other addons such as Hermes.
SLASH_COMPANIONSFOREVER3="/fcp"
SLASH_COMPANIONSFOREVER4="/companions"
SlashCmdList.COMPANIONSFOREVER=function(message)
  if not F.ready then F.Print(F.AccountSave and F.AccountSave.error or "Update or disable the old bundled Waylaid Forever addon, then reload.");return end
  message=(message or ""):lower():match("^%s*(.-)%s*$")
  if F.Errors and (message=="errors" or message:match("^errors "))then F.Errors.Command(message:match("^errors%s+(.*)$"))
  elseif message=="small" then F.Pets.ToggleCompass()
  elseif message=="settings" then F.OpenSettings()
  elseif message=="pet" then F.TogglePetIcon()
  elseif message=="collection" then F.Pets.OpenJournal()
  elseif message=="trade" then F.Pets.OpenTrade()
  elseif message=="gear" then F.Pets.OpenEquipment()
  elseif message=="mail" then F.Mailbox.Open()
  elseif message=="merge" then F.AccountSave.ShowNotice(true)
  elseif message=="xp" then F.Pets.KillXPStatus()
  elseif message=="rolls" or message=="rolls on" or message=="rolls off" then
    local enabled=message=="rolls on" or (message=="rolls" and not F.db.settings.petRollChat)
    F.db.settings.petRollChat=enabled
    if F.settings and rawget(F.settings,"petRolls")then F.settings.petRolls:SetChecked(enabled)end
    F.Print("Pet farming rolls: "..(enabled and "on" or "off")..". Change in Settings or /cfpets rolls.")
  elseif message=="reset" then
    F.char.petPosition=nil;F.char.petIconPosition=nil;F.char.minimapAngle=nil
    F.PlaceDesktop();F.PlacePetIcon();F.PlaceMinimap();F.TogglePetIcon(true)
  else F.Pets.Toggle()end
end
