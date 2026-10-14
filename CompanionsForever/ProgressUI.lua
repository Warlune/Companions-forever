local _,F=...
local P=F.Pets
local function clock()return GetTime and GetTime() or F.Now()end
-- Presentation only: saved balances change once, independently of their animation.
function P.ResetResourceDisplay()
  local s=P.state
  P.resourceDisplay={}
  for _,key in ipairs({"tokens","food","medicine"})do
    local value=key=="tokens" and s.tokens or s.inventory[key]
    P.resourceDisplay[key]={value=value,from=value,at=0,gain=0}
  end
end
function P.ResourceDisplay(key,motion)
  if not P.resourceDisplay then P.ResetResourceDisplay()end
  local s=P.state;local value=key=="tokens" and s.tokens or s.inventory[key]
  local r=P.resourceDisplay[key];local now=clock()
  if value~=r.value then
    local gain=value-r.value
    r.from=gain>0 and r.value or value;r.value=value;r.at=now
    r.gain=gain>0 and gain or 0
  end
  local age=math.max(0,now-r.at)
  local amount=motion and math.floor(r.from+(r.value-r.from)*math.min(1,age/0.8)) or r.value
  return amount,age<3 and r.gain or 0,math.min(1,math.max(0,(3-age)/0.5))
end
function P.BuildResourceBar(parent,x,y,width,compact)
  local bar=CreateFrame("Frame",nil,parent);bar:SetPoint("TOPLEFT",x,y);bar:SetSize(width,40)
  bar.fields={};bar.compact=compact
  for i,key in ipairs({"tokens","food","medicine"})do
    local field={};bar.fields[key]=field
    local icon=key=="tokens" and P.tokenIcon or "Interface\\Icons\\"..P.items[key].icon
    field.prefix="|T"..icon..":20:20|t "
    field.suffix=compact and "" or ({tokens=" tokens",food=" Food",medicine=" Herbs"})[key]
    field.total=F.Style.Text(bar,"",(i-1)*width/3,0,width/3,"GameFontHighlight",F.Style.gold)
    field.gain=F.Style.Text(bar,"",(i-1)*width/3,-20,width/3,"GameFontHighlightSmall",{0.3,1,0.3})
    field.total:SetHeight(20);field.gain:SetHeight(20)
    field.total:SetWordWrap(false)
  end
  local function update()
    if not P.state then return end
    local dirty=bar.fontSize~=F.Style.MinimumTextSize();bar.fontSize=F.Style.MinimumTextSize()
    for key,field in pairs(bar.fields)do
      local amount,gain,alpha=P.ResourceDisplay(key,not F.db.settings.reduceMotion)
      if field.amount~=amount then field.amount=amount;field.total:SetText(field.prefix..amount..field.suffix);dirty=true end
      if field.lastGain~=gain then field.lastGain=gain;field.gain:SetText(gain>0 and ("+"..gain) or "")end
      if field.alpha~=alpha then field.alpha=alpha;field.gain:SetAlpha(alpha)end
    end
    if dirty then
      local x=0;local gap=compact and 10 or 18
      for _,key in ipairs({"tokens","food","medicine"})do
        local field=bar.fields[key]
        field.total:SetWidth(width)
        local measured=field.total:GetStringWidth()
        local natural=type(measured)=="number" and measured>0 and measured or 24+(#tostring(field.amount)+#field.suffix)*math.max(12,bar.fontSize)*.6
        local size=math.ceil(natural)+2;field.offset=x;field.width=size
        field.total:ClearAllPoints();field.total:SetPoint("TOPLEFT",bar,"TOPLEFT",x,0);field.total:SetWidth(size)
        field.gain:ClearAllPoints();field.gain:SetPoint("TOPLEFT",bar,"TOPLEFT",x,-20);field.gain:SetWidth(size)
        x=x+size+gap
      end
    end
  end
  local elapsed=0
  bar.refresh=update;bar:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+(dt or 0);if elapsed<0.05 then return end;elapsed=0;update()
  end);update();return bar
end
function P.DisplayPet()
  local pet=P.Active();if pet then return pet end
  if P.defeat then
    for _,owned in ipairs(P.state.pets)do if owned==P.defeat.pet then return owned end end
  end
end
function P.DeathFade(pet)
  if not pet or not pet.deadAt then return 0 end
  if F.db.settings.reduceMotion then return 1 end
  local death=P.defeat
  if not death or death.pet~=pet then return 1 end
  return math.max(0,math.min(1,(clock()-death.at)/1.25))
end
function P.ProgressEvent(pet)
  if not pet or not pet.id then return end
  local event=P.progressEvents[pet.id]
  local preview=P.levelPreview
  local now=GetTime and GetTime() or F.Now()
  if preview and preview.petID==pet.id and now>=preview.at and now-preview.at<4
    and (not event or preview.serial>event.serial)then return preview end
  return event
end
function P.UpdateProgressScene(frame,dt,motion)
  local pet=frame.needsPet
  local event=P.ProgressEvent(pet)
  local now=GetTime and GetTime() or F.Now()
  local age=event and now-event.at or 99
  local active=event and age>=0 and age<4
  local ding=active and event.level>event.fromLevel
  frame.progressText:SetShown(not not active)
  frame.leftHP.dingArrow:SetShown(not not ding)
  if not active then return end
  local x=frame.width*(frame.tower and 0.23 or 0.5)
  local y=frame.tower and -(frame.hudHeight+frame.arenaHeight*0.3) or -frame.height*0.3
  frame.progressText:ClearAllPoints()
  frame.progressText:SetPoint("CENTER",frame,"TOPLEFT",x,y+(motion and math.min(24,age*10) or 0))
  frame.progressText:SetWidth(frame.width*(frame.tower and 0.48 or 0.95))
  frame.progressText:SetText(event.preview and "LEVEL UP!\nPreview" or ((ding and "LEVEL "..event.level.."!\n" or "").."+"..event.amount.." XP"))
  frame.progressText:SetAlpha(math.min(1,(4-age)/0.5))
  if ding and frame.levelSerial~=(event.dingSerial or event.serial) and frame.arena:Ready()then
    frame.levelSerial=event.dingSerial or event.serial
    if motion then frame.arena:LevelUp()end
    -- Both views can be open, but one level-up only plays one sound.
    if not event.sound then
      event.sound=true
      if PlaySoundFile then pcall(PlaySoundFile,567431,"SFX")end
    end
  end
  if frame.tower and pet and not event.preview then
    local start=event.fromLevel+event.fromXP/(20+event.fromLevel*5)
    local finish=event.level+event.xp/(20+event.level*5)
    local progress=motion and math.min(1,age/1.2) or 1
    local value=start+(finish-start)*progress
    local fraction=value-math.floor(value)
    if progress==1 and pet.level>=P.LevelCap()then fraction=1 end
    frame.leftHP.resource:SetValue(fraction*100)
  end
end
