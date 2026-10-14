local _,F=...
local P=F.Pets
local A={};A.__index=A
local serial=0
local function clamp(n,lo,hi)return math.max(lo,math.min(hi,n))end
-- ModelScene actor translations are scaled with the model. Keep layout and
-- movement in scene units, then convert to actor units at the API boundary.
local function position(s,x)
  s.visualX=x or s.x
  local scale=s.scale or 1
  s.actor:SetPosition((x or s.x)/scale,s.y/scale,(s.z or 0)/scale)
end
local function bounds(actor)
  local ok,x,y,z,tx,ty,tz=pcall(actor.GetActiveBoundingBox,actor)
  if not ok then return end
  if (type(x)=="table" or type(x)=="userdata") and x.GetXYZ and (type(y)=="table" or type(y)=="userdata") and y.GetXYZ then
    local lower,upper=x,y;x,y,z=lower:GetXYZ();tx,ty,tz=upper:GetXYZ()
  end
  if type(x)=="number" and type(y)=="number" and type(z)=="number" and type(tx)=="number" and type(ty)=="number" and type(tz)=="number" then
    return math.max(tx-x,ty-y,tz-z),z,tz-z
  end
end
-- All windows use the same visual clock and impact snapshots. The simulation
-- still owns saves, damage, XP and rewards; rendering never changes pet data.
function P.VisualEvent(round,now)
  if not round then return end
  local age=math.max(0,(now or P.sceneClock or 0)-round.at)
  local index=math.floor(age/P.eventDuration)+1
  local event=age<round.duration and round.events[index] or nil
  local snapshot=round.events[math.min(#round.events,index-1)] or round.start
  if event and age%P.eventDuration>=P.impactDelay then snapshot=event end
  if age>=round.duration and round.final then snapshot=round.final end
  return event,snapshot,index,age%P.eventDuration
end
function A:Animate(s,kind)
  if not s or not s.loaded then return end
  local ok=pcall(s.actor.SetAnimation,s.actor,P.animations[kind] or 0,0,1,0)
  if not ok then pcall(s.actor.SetAnimation,s.actor,0,0,1,0)end
  s.animation=kind
end
function A:ModelLoaded(actor)
  local s=actor.cfState
  if not s or not s.active or not s.model or not actor:IsLoaded()then return end
  local extent,bottom,height=bounds(actor)
  local scale=extent and extent>0 and clamp(s.model.size/extent,0.01,4) or 0.5
  s.z=bottom and -bottom*scale or 0
  s.height=height and height*scale or s.model.size
  s.scale=scale;actor:SetScale(scale);position(s);actor:SetYaw(s.yaw)
  actor:SetAlpha(1);actor:Show();s.loaded=true;s.error=nil
  self:Animate(s,s.dead and "dead" or "idle")
  self:Camera(self.solo)
end
function A:Camera(solo)
  local zoom=solo and 0.56 or 1.5
  -- Fit the entire line of opponents even in the narrow compact view.
  local width,height=self.scene:GetWidth(),self.scene:GetHeight()
  if width>0 and height>0 then zoom=zoom*math.max(1,1.2/(width/height))end
  local targetZ=solo and ((self.states[0] and self.states[0].height or 2.2)*0.5) or 1
  local cy=-11*zoom
  local cz=solo and (targetZ-cy*0.18) or 6*zoom
  local fy,fz=-cy,targetZ-cz;local length=math.sqrt(fy*fy+fz*fz);fy=fy/length;fz=fz/length
  self.scene:SetCameraPosition(0,cy,cz)
  -- Forward cross right must equal up. A reflected basis reverses face
  -- winding: opaque creatures appear hollow as their front faces are culled.
  self.scene:SetCameraOrientationByAxisVectors(0,fy,fz,-1,0,0,0,-fz,fy)
end
function A:Sync(pet,enemies,key)
  if not self.scene then return end
  local changed=self.key~=key;self.key=key
  if changed then self.round=nil;self.index=nil;self.cue=nil end
  local solo=#enemies==0;self.solo=solo
  if changed then self.soloYaw=-0.45 end
  self:Camera(solo)
  for i,s in pairs(self.states)do
    local unit=i==0 and pet or enemies[i]
    s.unit=unit
    s.active=unit~=nil
    if unit then
      local model=P.ModelFor(unit)
      s.x=solo and 0 or i==0 and -2.4 or 2.4
      s.y=i==0 and 0 or (i-(#enemies+1)/2)*3.1
      s.yaw=solo and (self.soloYaw or -0.45) or i==0 and 0 or math.pi
      if changed then
        s.dead=solo and unit.deadAt~=nil;s.deathAt=nil;s.deadPose=s.dead
        if s.actor.SetDesaturation then s.actor:SetDesaturation(0)end
      end
      if changed or s.model~=model then
        position(s);s.actor:SetYaw(s.yaw)
        self:Animate(s,s.dead and "dead" or "idle")
      end
      if s.model~=model then
        s.model=model;s.loaded=false;s.loadTime=0;s.error=nil;s.actor:Hide()
        local ok,accepted=pcall(s.actor.SetModelByCreatureDisplayID,s.actor,model.display)
        if not ok or accepted==false then s.error=true;if model.fallback then P.unavailableModels[model.display]=true end
        elseif s.actor:IsLoaded()then self:ModelLoaded(s.actor)end
      elseif s.loaded then s.actor:Show()end
    else s.actor:Hide()end
  end
end
function A:Rotate(delta)
  if not self.solo or not self.states[0] or not self.states[0].active then return end
  self.soloYaw=((self.soloYaw or -0.45)+delta)%(2*math.pi)
  local s=self.states[0];s.yaw=self.soloYaw;s.actor:SetYaw(s.yaw)
end
function A:Ready()
  if not self.scene then return false end
  for _,s in pairs(self.states)do if s.active and not s.loaded then return false end end
  return true
end
function A:Poll(dt)
  for _,s in pairs(self.states)do
    if s.active and self.solo and s.actor.SetDesaturation then s.actor:SetDesaturation(P.DeathFade and P.DeathFade(s.unit) or 0)end
    if s.active and not s.loaded and not s.error then
      s.loadTime=s.loadTime+math.min(dt or 0,0.25)
      if s.actor:IsLoaded()then self:ModelLoaded(s.actor)
      elseif s.loadTime>=8 then s.error=true;if s.model.fallback then P.unavailableModels[s.model.display]=true end end
    end
  end
end
function A:LevelUp()
  if not self.scene or not self.states[0] or not self.states[0].loaded then return false end
  if not self.levelEffect then
    serial=serial+1
    local ok,actor=pcall(self.scene.CreateActor,self.scene,"CompanionsForeverLevelEffect"..serial,"CompanionsForeverActorTemplate")
    if not ok then return false end
    self.levelEffect=actor
  end
  local actor=self.levelEffect
  if not actor.SetModelByPath then return false end
  -- File IDs work in Classic clients that no longer resolve this legacy path.
  local ok,accepted=pcall(actor.SetModelByPath,actor,166464)
  if not ok or accepted==false then actor:Hide();return false end
  local pet=self.states[0]
  local scale=self.states[1] and self.states[1].active and 0.8 or 0.45
  actor:SetScale(scale);actor:SetPosition(pet.x/scale,pet.y/scale,0);actor:SetYaw(0);actor:SetAlpha(1);actor:Show()
  pcall(actor.SetAnimation,actor,0,0,1,0)
  self.levelEffectAge=0
  return true
end
function A:UpdateLevelEffect(dt)
  if not self.levelEffectAge then return end
  self.levelEffectAge=self.levelEffectAge+math.min(dt,0.25)
  -- Fade out the single burst before the native emitter repeats.
  self.levelEffect:SetAlpha(math.max(0,math.min(1,(1.75-self.levelEffectAge)/0.35)))
  if self.levelEffectAge>=1.75 then self.levelEffect:Hide();self.levelEffectAge=nil end
end
-- Classic spell models from wowdev/wow-listfile/parts/spells.csv.
P.statusModels={burn=166403,freeze=166211,poison=166647,slow=166898}
function A:StatusEffects(effects,motion)
  if not self.scene then return end
  self.statusActors=self.statusActors or {}
  local pet=self.states[0]
  for key,file in pairs(P.statusModels)do
    local active=effects and effects[key] and pet and pet.loaded and not pet.dead
    local entry=self.statusActors[key]
    if active and not entry then
      serial=serial+1
      local ok,actor=pcall(self.scene.CreateActor,self.scene,"CompanionsForeverStatus"..serial,"CompanionsForeverActorTemplate")
      if ok then
        entry={actor=actor};self.statusActors[key]=entry
        local loaded,accepted=pcall(actor.SetModelByPath,actor,file);entry.failed=not loaded or accepted==false
      end
    end
    if entry then
      local show=active and motion and not entry.failed
      if show then
        local scale=self.solo and 0.5 or 0.65;entry.actor:SetScale(scale)
        entry.actor:SetPosition((pet.visualX or pet.x)/scale,pet.y/scale,0);entry.actor:SetAlpha(0.8)
        if not entry.active then pcall(entry.actor.SetAnimation,entry.actor,0,0,1,0)end
      end
      entry.actor:SetShown(not not show);entry.active=not not show
    end
  end
end
function A:Home()
  for _,s in pairs(self.states)do if s.active then
    position(s);s.actor:SetYaw(s.yaw)
    if not s.dead then self:Animate(s,"idle")end
  end end
end
function A:Die(s,at,settled)
  if not s or s.dead then return end
  s.dead=true;s.deathAt=at;s.deadPose=settled
  self:Animate(s,settled and "dead" or "death")
end
function A:Snapshot(snapshot,now,settled)
  if not snapshot then return end
  if snapshot.hp<=0 then self:Die(self.states[0],now,settled)end
  for i,hp in ipairs(snapshot.enemyHP)do if hp<=0 then self:Die(self.states[i],now,settled)end end
end
function A:StartEvent(event,round)
  self:Home()
  local label=event.label or ""
  local source=self.states[event.actor]
  local healing=event.kind=="heal" or event.actor==0 and (label=="Healing herb" or label=="Token heal" or label=="Ability heal" or label=="Renewal" or label=="Leech")
  local skip=label:find("skipped",1,true) or label:find("winding up",1,true)
  local tick=label:find("tick",1,true)
  local cast=healing
  for _,spell in pairs(P.enemySpells)do if label:find(spell.name,1,true)then cast=true end end
  if event.actor==0 and round.action=="burst" then
    local family=F.PetData.species[round.pet.species].family
    cast=cast or family=="elemental" or family=="demon" or family=="nature" or family=="dragon"
  end
  self.cue={source=source,target=self.states[event.target or (healing and event.actor or event.actor==0 and 1 or 0)],event=event,
    healing=healing,tick=tick,skip=skip,guard=label=="Guard",cast=cast}
  if skip then self:Animate(source,"stun")
  elseif label=="Guard" then self:Animate(source,"guard")
  elseif tick then
  elseif cast then self:Animate(source,"cast")
  else self:Animate(source,"attack")end
end
function A:EventAt(age,now,motion)
  local c=self.cue;if not c then return end
  local s,t=c.source,c.target
  if motion and s and t and not s.dead and not (c.healing or c.tick or c.skip or c.guard or c.cast)then
    -- Short approach only, with room for each model's attack-animation reach.
    -- Opponents keep their own row; nobody walks through another opponent.
    local clearance=(s.model.size+t.model.size)*0.5+0.9
    local travel=math.min(0.55,math.max(0,math.abs(t.x-s.x)-clearance))
    local phase=age<0.25 and age/0.25 or age<0.75 and 1 or clamp(1-(age-0.75)/0.45,0,1)
    position(s,s.x+(t.x>s.x and 1 or -1)*travel*phase)
  end
  if age>=P.impactDelay and not c.impact then
    c.impact=true;self:Snapshot(c.event,now,false)
    if t and not t.dead and not (c.event.missed or c.healing or c.skip or c.guard) and c.event.amount>0 then self:Animate(t,"wound")end
  end
end
function A:Update(round,dt,paused,motion)
  if not self.scene then return end
  self:Poll(dt)
  if not paused then self:UpdateLevelEffect(dt)end
  local ready=self:Ready()
  self.scene:SetAlpha(1) -- A loading enemy must not hide the already-loaded companion.
  -- Let asynchronous models finish loading before freezing their scene.
  local nativePaused=paused and ready
  if self.paused~=nativePaused then self.scene:SetPaused(nativePaused,false);self.paused=nativePaused end
  local now=P.sceneClock or 0
  local event,snapshot,index,age=P.VisualEvent(round,now)
  if self.round~=round or self.index~=index then
    local switched=self.round~=round
    self.round=round;self.index=index
    -- Opening a second view mid-round reconstructs deaths from earlier impacts.
    if round then self:Snapshot(round.events[(index or 1)-1] or round.start,now,true)end
    if event then self:StartEvent(event,round)
    elseif self.cue or switched then self.cue=nil;self:Home()end
  end
  if event then self:EventAt(age,now,motion)else self:Snapshot(snapshot,now,true)end
  self:StatusEffects(snapshot and snapshot.effects and (P.state.battle or (round and now<round.at+round.duration)) and snapshot.effects,motion)
  for _,s in pairs(self.states)do
    if s.dead and not s.deadPose and s.deathAt and now-s.deathAt>=1.25 then self:Animate(s,"dead");s.deadPose=true end
    if not self.solo and s.actor.SetDesaturation then
      s.actor:SetDesaturation(s.dead and (motion and s.deathAt and clamp((now-s.deathAt)/1.25,0,1) or 1) or 0)
    end
  end
end
function P.CreateArena(parent,portrait)
  serial=serial+1
  local self=setmetatable({states={}},A)
  local ok,err=pcall(function()
    local scene=CreateFrame("ModelScene",nil,parent);self.scene=scene;scene:SetAllPoints(parent)
    scene:EnableMouse(false);scene:SetFrameLevel(parent:GetFrameLevel()+1)
    F.Style.WatchModelOcclusion(parent,scene)
    scene:SetCameraNearClip(0.1);scene:SetCameraFarClip(100);scene:SetCameraFieldOfView(math.rad(36))
    scene:SetLightVisible(true);scene:SetLightAmbientColor(0.75,0.75,0.8);scene:SetLightDiffuseColor(0.9,0.85,0.75)
    scene:SetLightDirection(-0.4,1,-1)
    for i=0,portrait and 0 or 3 do
      local actor=scene:CreateActor("CompanionsForeverActor"..serial.."_"..i,"CompanionsForeverActorTemplate")
      actor:SetUseCenterForOrigin(true,true,false)
      local s={index=i,actor=actor,active=false};self.states[i]=s;actor.cfArena=self;actor.cfState=s;actor:Hide()
    end
  end)
  if not ok then
    if self.scene then self.scene:Hide()end
    self.scene=nil;self.states={};self.error=tostring(err)
  end
  return self
end
