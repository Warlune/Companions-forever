local _,F=...
local P,D=F.Pets,F.PetData
local shown=setmetatable({},{__mode="k"})
local watched=setmetatable({},{__mode="k"})
local installed=false
local function readable(value)
  if issecretvalue and issecretvalue(value)then return false end
  return not canaccessvalue or canaccessvalue(value)
end

local function watch(tooltip)
  if not watched[tooltip] and tooltip.HookScript then
    watched[tooltip]=true
    tooltip:HookScript("OnTooltipCleared",function(self)shown[self]=nil end)
  end
end

local function append(tooltip,guid)
  if not F.ready or not P.state or not tooltip or not tooltip.AddLine then return end
  -- A secret string still has type "string". Check before indexing, parsing,
  -- comparing or retaining it, including the modern tooltip callback path.
  if not readable(guid)then return end
  -- Use the same exact NPC IDs as kill loot, never names or look-alike models.
  local npc=type(guid)=="string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
  local species=npc and D.farmByNPC[npc]
  if not species or not P.IsAllowedSpecies(species) then return end
  watch(tooltip)
  if shown[tooltip]==guid then return end
  shown[tooltip]=guid
  tooltip:AddLine(" ")
  tooltip:AddLine("Companions Forever",0.87,0.74,0.39)
  tooltip:AddLine("Companion: "..P.species[species],1,1,1)
  local raid=IsInRaid and IsInRaid();local party=not raid and IsInGroup and IsInGroup()
  tooltip:AddLine(raid and "No farmed pet drops in raids" or party and "5% shared party chance | Requires stable space" or string.format("%g%% pet chance per eligible kill | Rarity is random",P.DropChance("pet")/100),0.8,0.8,0.8,true)
  if P.state.collection and P.state.collection[species] then
    tooltip:AddLine("Collected",0.3,1,0.4)
  else
    tooltip:AddLine("Not collected",1,0.8,0.3)
  end
  tooltip:Show()
end

local function unitGUID(tooltip)
  if tooltip and tooltip.GetUnit and UnitGUID then
    local _,unit=tooltip:GetUnit()
    if readable(unit) and type(unit)=="string" then return UnitGUID(unit) end
  end
end

function F.InstallCompanionTooltips()
  if installed or not GameTooltip then return end
  installed=true
  watch(GameTooltip)
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(tooltip,data)
      if not readable(data)then return end
      local guid
      if type(data)=="table" then guid=data.guid end
      if not readable(guid)then return end
      -- Only missing GUIDs may use the unit fallback. A restricted GUID must
      -- not be replaced with another unit that might identify the wrong NPC.
      if guid==nil then guid=unitGUID(tooltip)end
      append(tooltip,guid)
    end)
  else
    GameTooltip:HookScript("OnTooltipSetUnit",function(self)append(self,unitGUID(self))end)
  end
end
