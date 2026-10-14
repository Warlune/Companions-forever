local _,F=...
local P=F.Pets
local pulse=CreateFrame("Frame");pulse:Hide()
local labels=setmetatable({},{__mode="k"})
local elapsed=0
local gold,silver="|cffFFD700","|cffC0C0C0"
function P.RollNumber(text,rank)
  if not rank or rank<91 then return text end
  if not F.db.settings.reduceMotion then pulse:Show()end
  return (rank==100 and gold or silver)..text.."|r"
end
function P.UpdateRollGlow(dt)
  if not GameTooltip:IsShown() or F.db.settings.reduceMotion then pulse:Hide();return end
  elapsed=elapsed+dt;if elapsed<.08 then return end;elapsed=0
  local t=GetTime and GetTime() or P.sceneClock or 0
  local wave=(math.sin(t*4)+1)/2
  local golden=string.format("|cff%02x%02x%02x",255,math.floor(180+65*wave),math.floor(20+100*wave))
  local silvery=string.format("|cff%02x%02x%02x",math.floor(165+80*wave),math.floor(170+80*wave),math.floor(185+70*wave))
  local found=false
  for _,region in ipairs({GameTooltip:GetRegions()})do
    if region.GetText then
      local ok,text=pcall(region.GetText,region)
      if ok and F.Integrity.Readable(text) and type(text)=="string"then
        local entry=labels[region]
        if not entry or text~=entry.last then
          entry=nil
          if text:find(gold,1,true) or text:find(silver,1,true)then entry={source=text};labels[region]=entry
          else labels[region]=nil end
        end
        if entry then
          local value=entry.source:gsub(gold,golden):gsub(silver,silvery)
          region:SetText(value);entry.last=value;found=true
        end
      end
    end
  end
  if not found then pulse:Hide()end
end
pulse:SetScript("OnUpdate",function(_,dt)P.UpdateRollGlow(dt)end)
GameTooltip:HookScript("OnHide",function()pulse:Hide();labels=setmetatable({},{__mode="k"});elapsed=0 end)

-- Borderless row highlights share one pulse; text stays steady.
local statPulse=CreateFrame("Frame");statPulse:Hide();P.statRollPulse=statPulse
local statBars=setmetatable({},{__mode="k"});local statElapsed=0
function P.BuildStatRollBar(parent,label,value)
  local bar=parent:CreateTexture(nil,"ARTWORK",nil,-3)
  bar:SetPoint("TOPLEFT",label,"TOPLEFT",-4,0)
  bar:SetPoint("BOTTOMRIGHT",value,"BOTTOMRIGHT",4,0)
  bar:Hide();return bar
end
function P.SetStatRollLabel(label,pet,index,normalColor)
  if label then F.Style.TextColor(label,normalColor or F.Style.muted)end
end
function P.SetStatRollBar(bar,pet,index)
  if not bar then return end
  local rolls=pet and P.DecodePetRolls(pet);local rank=rolls and rolls.stats[index]
  if rank and rank>=91 then
    if statBars[bar]~=rank then
      if rank==100 then bar:SetColorTexture(1,.72,.12,1)
      else bar:SetColorTexture(.78,.84,.94,1)end
      bar:SetAlpha(F.Style.HighContrast() and .15 or .3)
    end
    statBars[bar]=rank;bar:Show()
    if F.db.settings.reduceMotion then bar:SetAlpha(F.Style.HighContrast() and .15 or .3)end
    if not F.db.settings.reduceMotion then statPulse:Show()end
  else statBars[bar]=nil;bar:Hide()end
end
function P.UpdateStatRollLabels(dt)
  statElapsed=statElapsed+dt;if statElapsed<.08 then return end;statElapsed=0
  local motion=not F.db.settings.reduceMotion
  local wave=motion and (.5+.5*math.sin((GetTime and GetTime() or P.sceneClock or 0)*5)) or 1
  local visible=false
  for bar in pairs(statBars)do
    if bar:IsVisible()then bar:SetAlpha(F.Style.HighContrast() and (.05+.1*wave) or (.1+.2*wave));visible=true end
  end
  if not visible or not motion then statPulse:Hide()end
end
statPulse:SetScript("OnUpdate",function(_,dt)P.UpdateStatRollLabels(dt)end)
