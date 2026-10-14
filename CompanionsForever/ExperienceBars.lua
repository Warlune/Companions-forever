local _,F=...
local P,S=F.Pets,F.Style
local function available(name)
  return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end
function P.StyleXPBar(bar,numbers)
  local skin=rawget(bar,"cfExperienceSkin")
  if not skin then
    skin={cells={}};bar.cfExperienceSkin=skin
    skin.track=bar:CreateTexture(nil,"BACKGROUND",nil,0);skin.track:SetAllPoints()
    skin.rim=CreateFrame("Frame",nil,bar);skin.rim:SetAllPoints();skin.rim:EnableMouse(false)
    skin.edge=skin.rim:CreateTexture(nil,"OVERLAY")
    skin.edge:SetPoint("TOPLEFT",bar,"TOPLEFT",-3,2);skin.edge:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",3,-2)
    skin.fallback=CreateFrame("Frame",nil,skin.rim,"BackdropTemplate")
    skin.fallback:SetPoint("TOPLEFT",-2,2);skin.fallback:SetPoint("BOTTOMRIGHT",2,-2);skin.fallback:EnableMouse(false)
    skin.fallback:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    for i=1,19 do skin.cells[i]=bar:CreateTexture(nil,"ARTWORK",nil,4)end
  end
  local width,height=bar:GetWidth(),bar:GetHeight();local high=not not S.HighContrast()
  if skin.width==width and skin.height==height and skin.high==high and skin.numbers==numbers then return skin end
  skin.width,skin.height,skin.high,skin.numbers=width,height,high,numbers
  -- Use the complete native artwork exactly as the game does. Do not slice
  -- packed atlas coordinates or enlarge its end caps for a small pet bar.
  if high then skin.track:SetColorTexture(.015,.015,.015,1)
  elseif available("UI-HUD-ExperienceBar-Background")then skin.track:SetAtlas("UI-HUD-ExperienceBar-Background")
  else skin.track:SetColorTexture(.055,.035,.02,1)end
  local framed=not not available("UI-HUD-ExperienceBar-Frame")
  skin.edge:SetShown(framed);skin.fallback:SetShown(not framed)
  if framed then skin.edge:SetAtlas("UI-HUD-ExperienceBar-Frame");skin.edge:SetDesaturated(high);skin.edge:SetVertexColor(1,1,1,1)end
  skin.fallback:SetBackdropBorderColor(high and 1 or .65,high and 1 or .67,high and 1 or .7,1)
  if not high and available("UI-HUD-ExperienceBar-Fill-Experience")then
    bar:GetStatusBarTexture():SetAtlas("UI-HUD-ExperienceBar-Fill-Experience");bar:SetStatusBarColor(1,1,1)
  else
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(high and (numbers and .2 or .6) or .5,high and (numbers and .3 or .75) or .2,high and (numbers and .5 or 1) or .85)
  end
  local count=math.max(4,math.min(20,math.floor(width/32)))
  for i,t in ipairs(skin.cells)do
    t:SetShown(i<count)
    if i<count then
      t:ClearAllPoints();t:SetPoint("TOP",bar,"TOPLEFT",width*i/count,0);t:SetPoint("BOTTOM",bar,"BOTTOMLEFT",width*i/count,0);t:SetWidth(2)
      if high then t:SetColorTexture(.9,.9,.9,1);t:SetWidth(1)
      elseif available("ui-hud-experiencebar-divider")then t:SetAtlas("ui-hud-experiencebar-divider");t:SetDesaturated(false)
      else t:SetColorTexture(.65,.65,.65,.7);t:SetWidth(1)end
    end
  end
  return skin
end
