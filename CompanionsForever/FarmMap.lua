local _,F=...
local P,D=F.Pets,F.PetData
local paw="Interface\\AddOns\\CompanionsForever\\Art\\PetPaw"
local green={0.6,1,0.65}

-- Project only onto the source zone or its parents. Overlapping city/zone
-- rectangles must never turn a farming hint into a different-zone claim.
function F.ProjectFarmPin(entry,mapID)
  if entry[1]==mapID then return entry[2]/100,entry[3]/100 end
  if not C_Map or not C_Map.GetMapInfo or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos or not CreateVector2D then return end
  local id=entry[1]
  for _=1,12 do
    local info=C_Map.GetMapInfo(id)
    id=info and info.parentMapID
    if not id or id==0 then return end
    if id==mapID then
      local instance,position=C_Map.GetWorldPosFromMapPos(entry[1],CreateVector2D(entry[2]/100,entry[3]/100))
      if not position then return end
      local projected,point=C_Map.GetMapPosFromWorldPos(instance,position,mapID)
      if projected==mapID and point then return point:GetXY()end
      return
    end
  end
end

local function pinTooltip(self)
  local e=self.entry;if not e then return end
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:SetText(P.species[e[5]],unpack(green))
  GameTooltip:AddLine("Companions Forever",0.87,0.74,0.39)
  GameTooltip:AddLine(e[6],1,1,1)
  GameTooltip:AddLine(string.format("%s: %.1f, %.1f",e[7],e[2],e[3]),1,1,1)
  GameTooltip:AddLine(string.format("%g%% pet chance per eligible kill; random rarity.",P.DropChance("pet")/100),0.8,0.8,0.8,true)
  local found=P.state.collection and P.state.collection[e[5]]
  GameTooltip:AddLine(found and "Collected" or "Not collected",unpack(found and green or {1,0.8,0.3}))
  GameTooltip:AddLine("Approximate farming spot. Spawns and patrols vary.",0.8,0.8,0.8,true)
  GameTooltip:Show()
end

function F.RefreshFarmMap()
  local overlay=F.farmMapOverlay
  if not overlay or not F.ready then return end
  local map=overlay.map
  local enabled=F.db.settings.petMapPins~=false
  F.farmMapToggle:SetChecked(enabled)
  F.farmMapToggle.paw:SetDesaturated(not enabled)
  for _,pin in ipairs(overlay.pins)do
    if pin:IsShown() and GameTooltip.IsOwned and GameTooltip:IsOwned(pin)then GameTooltip:Hide()end
    pin:Hide();pin.entry=nil
  end
  local manager=map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
  if manager and manager.GetValidFrameLevel then
    overlay:SetFrameLevel(math.max(manager:GetValidFrameLevel("PIN_FRAME_LEVEL_QUEST_BLOB"),
      manager:GetValidFrameLevel("PIN_FRAME_LEVEL_MAP_EXPLORATION")+1,
      manager:GetValidFrameLevel("PIN_FRAME_LEVEL_FOG_OF_WAR")+1))
  end
  -- Keep the control inside the visible viewport in both map sizes. Its
  -- level must clear map artwork even while pins are disabled; its strata
  -- still belongs to the map, rather than floating over other windows.
  local toggle=F.farmMapToggle
  toggle:ClearAllPoints();toggle:SetPoint("BOTTOMLEFT",map.ScrollContainer,"BOTTOMLEFT",12,12)
  toggle:SetFrameLevel(math.max(map:GetFrameLevel(),map.ScrollContainer:GetFrameLevel(),overlay:GetFrameLevel())+20)
  if not enabled then return end
  local mapID=map:GetMapID();local n=0
  local w,h=overlay:GetWidth(),overlay:GetHeight()
  local info=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
  local mapType=info and info.mapType or 3
  local size=mapType<=1 and 10 or mapType==2 and 12 or 16
  -- The canvas scales while zooming. Keep paws small in UI pixels instead
  -- of letting the map magnify them over nearby locations and labels.
  size=size*(UIParent:GetEffectiveScale() or 1)/(overlay:GetEffectiveScale() or 1)
  for _,e in ipairs(D.farmMapPins)do
    -- Recheck the reward map and policy, so future roster changes cannot
    -- leave stale pins advertising removed or crate-only species.
    if D.farmByNPC[e[4]]==e[5] and P.IsAllowedSpecies(e[5])then
      local x,y=F.ProjectFarmPin(e,mapID)
      if x and y and x>=0 and x<=1 and y>=0 and y<=1 then
        n=n+1;local pin=overlay.pins[n]
        if not pin then
          pin=CreateFrame("Button",nil,overlay)
          pin.icon=pin:CreateTexture(nil,"ARTWORK");pin.icon:SetAllPoints()
          pin.icon:SetTexture(paw);pin.icon:SetVertexColor(unpack(green))
          pin:SetScript("OnEnter",pinTooltip)
          pin:SetScript("OnLeave",function()GameTooltip:Hide()end)
          overlay.pins[n]=pin
        end
        pin:SetSize(size,size)
        pin.entry=e;pin:ClearAllPoints();pin:SetPoint("CENTER",overlay,"TOPLEFT",x*w,-y*h);pin:Show()
      end
    end
  end
end

function F.InstallFarmMap()
  if F.farmMapOverlay or not WorldMapFrame or not WorldMapFrame.ScrollContainer then return end
  local map=WorldMapFrame;local canvas=map.ScrollContainer.Child;if not canvas then return end
  local overlay=CreateFrame("Frame",nil,canvas);F.farmMapOverlay=overlay
  overlay:SetAllPoints(canvas);overlay:EnableMouse(false);overlay:SetClipsChildren(true)
  overlay:SetFrameLevel(canvas:GetFrameLevel()+5);overlay.map=map;overlay.pins={}
  local toggle=CreateFrame("CheckButton",nil,map,"UICheckButtonTemplate");F.farmMapToggle=toggle
  toggle:SetSize(26,26)
  toggle.background=toggle:CreateTexture(nil,"BACKGROUND")
  toggle.background:SetPoint("TOPLEFT",-4,4);toggle.background:SetPoint("BOTTOMRIGHT",112,-4)
  toggle.background:SetColorTexture(0.025,0.025,0.04,0.9)
  toggle.paw=toggle:CreateTexture(nil,"ARTWORK");toggle.paw:SetSize(22,22)
  toggle.paw:SetPoint("LEFT",toggle,"RIGHT",1,0);toggle.paw:SetTexture(paw);toggle.paw:SetVertexColor(unpack(green))
  toggle.label=toggle:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  toggle.label:SetPoint("LEFT",toggle.paw,"RIGHT",3,0);toggle.label:SetText("Pet locations")
  toggle:SetHitRectInsets(0,-105,0,0)
  toggle:SetScript("OnClick",function(self)
    F.db.settings.petMapPins=self:GetChecked() and true or false
    F.RefreshFarmMap()
  end)
  toggle:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText("Companions Forever")
    GameTooltip:AddLine("Show light green paws at known pet farming spots.",unpack(green))
    GameTooltip:AddLine("Hover a paw for the pet, creature and coordinates.",1,1,1,true)
    GameTooltip:AddLine("Only verified addon kill sources with coordinates are shown.",0.8,0.8,0.8,true)
    GameTooltip:Show()
  end)
  toggle:SetScript("OnLeave",function()GameTooltip:Hide()end)
  map:HookScript("OnShow",function()F.RefreshFarmMap()end)
  map:HookScript("OnSizeChanged",function()F.RefreshFarmMap()end)
  local elapsed,lastMap,lastW,lastH,lastScale=0
  overlay:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed<0.2 or not F.ready then return end;elapsed=0
    local id,w,h=map:GetMapID(),overlay:GetWidth(),overlay:GetHeight()
    local scale=(overlay:GetEffectiveScale() or 1)/(UIParent:GetEffectiveScale() or 1)
    if id~=lastMap or w~=lastW or h~=lastH or scale~=lastScale then
      lastMap,lastW,lastH,lastScale=id,w,h,scale;F.RefreshFarmMap()
    end
  end)
  F.RefreshFarmMap()
end

-- The world map can be loaded after PLAYER_LOGIN on some clients.
local events=CreateFrame("Frame");events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function()if F.ready then F.InstallFarmMap()end end)
