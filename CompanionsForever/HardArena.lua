local _,F=...
local P,H=F.Pets,F.Pets.HardMode
local create=P.CreateArena
local serial=0
local function position(s)
  local scale=s.scale or 1;s.visualX=s.x
  s.actor:SetPosition(s.x/scale,s.y/scale,(s.z or 0)/scale);s.actor:SetYaw(s.yaw)
end
function P.CreateArena(parent,portrait)
  local arena=create(parent,portrait);if portrait or not arena.scene then return arena end
  serial=serial+1;local arenaID=serial
  for _,index in ipairs({-1,-2,4,5,6})do
    local actor=arena.scene:CreateActor("CFHardTeamActor"..serial.."_"..index,"CompanionsForeverActorTemplate")
    actor:SetUseCenterForOrigin(true,true,false)
    local state={index=index,actor=actor,active=false};arena.states[index]=state;actor.cfArena=arena;actor.cfState=state;actor:Hide()
  end
  local camera=arena.Camera
  function arena:Camera(solo)
    if solo or not H.IsHard()then return camera(self,solo)end
    local w,h=self.scene:GetWidth(),self.scene:GetHeight()
    local zoom=1.85*math.max(1,(h>0 and 1.2/(w/h) or 1))
    local cy,cz=-11*zoom,6*zoom;local fy,fz=-cy,1-cz;local length=math.sqrt(fy*fy+fz*fz);fy=fy/length;fz=fz/length
    self.scene:SetCameraPosition(0,cy,cz);self.scene:SetCameraOrientationByAxisVectors(0,fy,fz,-1,0,0,0,-fz,fy)
  end
  local loaded=arena.ModelLoaded
  function arena:ModelLoaded(actor)
    loaded(self,actor)
    local s=actor.cfState
    if H.IsHard() and s and s.loaded and not self.solo then
      s.scale=s.scale*.8;s.z=(s.z or 0)*.8;s.height=(s.height or 0)*.8;actor:SetScale(s.scale);position(s)
    end
  end
  local sync=arena.Sync
  function arena:Sync(pet,enemies,key)
    local team=H.IsHard() and #enemies>0 and H.Team() or {}
    local units={};for i,e in ipairs(enemies)do units[i]=e end
    units[-1]=team[2];units[-2]=team[3]
    local hardScene=H.IsHard() and #enemies>0
    local lead=pet;if hardScene then lead=team[1]end
    sync(self,lead,units,key)
    self.hardTeam=hardScene and team or nil
    for i=1,3 do local p=team[i];if p then
      local s=self.states[1-i];s.unit=p;s.active=true;s.x=-2.1;s.y=(i-2)*1.9;s.yaw=0;position(s)
      local r=P.lastRound;if p.deadAt and not P.state.battle and (not r or (P.sceneClock or 0)>=r.at+r.duration)then self:Die(s,P.sceneClock or 0,true)end
    end end
    if H.IsHard()then for i=1,#enemies do local s=self.states[i];s.x=#enemies==1 and 2.4 or 1.8+math.floor((i-1)/3)*1.8;s.y=#enemies==1 and 0 or ((i-1)%3-1)*1.9;s.yaw=math.pi;position(s)end end
  end
  local snapshot=arena.Snapshot
  function arena:Snapshot(state,now,settled)
    snapshot(self,state,now,settled)
    if state and state.allyHP then for i,hp in ipairs(state.allyHP)do if hp<=0 then self:Die(self.states[1-i],now,settled)end end end
  end
  local start=arena.StartEvent
  function arena:StartEvent(event,round)
    if not round.team then return start(self,event,round)end
    self:Home()
    local source=self.states[event.actor];local kind=event.kind
    local cast=kind=="cast" or kind=="heal"
    if kind=="burst" and event.actor<=0 then
      local pet=round.team[1-event.actor];local family=pet and F.PetData.species[pet.species].family
      cast=family=="elemental" or family=="demon" or family=="nature" or family=="dragon"
    end
    self.cue={source=source,target=self.states[event.target or 0],event=event,healing=kind=="heal",tick=kind=="tick",skip=kind=="skip",guard=kind=="guard",cast=cast}
    if kind=="skip"then self:Animate(source,"stun")
    elseif kind=="guard"then self:Animate(source,"guard")
    elseif kind=="tick"then
    elseif cast then self:Animate(source,"cast")
    else self:Animate(source,"attack")end
  end
  local status=arena.StatusEffects
  function arena:StatusEffects(effects,motion)
    self.hardStatusPools=self.hardStatusPools or {}
    local original=self.states[0];local _,state=P.VisualEvent(self.round,P.sceneClock or 0)
    for i=1,3 do
      self.states[0]=i==1 and original or self.states[1-i]
      self.statusActors=self.hardStatusPools[i] or {};self.hardStatusPools[i]=self.statusActors
      local active=self.hardTeam and self.round and ((P.state.battle~=nil) or (P.sceneClock or 0)<self.round.at+self.round.duration)
      status(self,active and state and state.allyEffects and state.allyEffects[i] or (not self.hardTeam and i==1 and effects),motion)
    end
    self.states[0]=original;self.statusActors=self.hardStatusPools[1]
  end
  local update=arena.Update
  function arena:Update(round,dt,paused,motion)
    update(self,round,dt,paused,motion)
    self.healActors=self.healActors or {}
    for i=1,3 do
      local s=self.states[1-i];local receipt=s and s.unit and P.instantHeals and P.instantHeals[s.unit.id]
      local age=receipt and (P.sceneClock or 0)-receipt.at or 99
      local entry=self.healActors[i]
      if receipt and age<1.5 and s.loaded and s.active and not entry then
        local ok,actor=pcall(self.scene.CreateActor,self.scene,"CFHardHeal"..arenaID.."_"..i,"CompanionsForeverActorTemplate")
        if ok then entry={actor=actor};self.healActors[i]=entry end
      end
      if entry then
        local show=receipt and age<1.5 and s.active and s.loaded
        if show then
          if entry.serial~=receipt.serial then
            entry.serial=receipt.serial
            local ok,result=pcall(entry.actor.SetModelByPath,entry.actor,"Spells\\Heal_Low_Base.m2");entry.failed=not ok or result==false
            pcall(entry.actor.SetAnimation,entry.actor,0,0,1,0)
          end
          entry.actor:SetScale(.65);entry.actor:SetPosition((s.visualX or s.x)/.65,s.y/.65,0)
          entry.actor:SetAlpha(math.min(1,(1.5-age)*2))
        end
        entry.actor:SetShown(not not (show and not entry.failed))
      end
    end
  end
  return arena
end
