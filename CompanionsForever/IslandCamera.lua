local _,F=...
local I={};F.Housing.Island=I
local function clamp(n,a,b)return math.max(a,math.min(b,n))end
I.Clamp=clamp
function I.CameraSpeed()
 local value=F.char and F.char.housingCameraSpeed
 return type(value)=='number'and value==value and clamp(value,.25,3)or 1
end
function I.SetCameraSpeed(value)
 if type(value)~='number'or value~=value or math.abs(value)==math.huge then return false end
 F.char.housingCameraSpeed=clamp(value,.25,3);return true
end
function I.ModelBounds(actor)
 local a,b,c,d,e,f=actor:GetMaxBoundingBox()
 if(type(a)=='table'or type(a)=='userdata')and a.GetXYZ then local lo,hi=a,b;a,b,c=lo:GetXYZ();d,e,f=hi:GetXYZ()end
 local values={a,b,c,d,e,f}
 for i=1,6 do local n=values[i];if type(n)~='number'or n~=n or math.abs(n)==math.huge then return end end
 local w,h,z=d-a,e-b,f-c
 if w<=0 or h<=0 or z<0 then return end
 -- The client reports its missing-model cube as successfully loaded.
 if math.abs(w-.28)<.002 and math.abs(h-.28)<.002 and math.abs(z-.28)<.002 then return nil,'missing' end
 return w,h,z,c,f
end
function I.FitPreview(actor,scene,w,d,h)
 local extent=math.max(w,d,h);local scale=math.max(.01,1/extent)
 actor:SetScale(scale)
 if actor.GetScale then local ok,value=pcall(actor.GetScale,actor);if ok and type(value)=='number'and value>0 then scale=value end end
 -- Some native trees hit the client's minimum actor scale. Move the camera
 -- back as well, so the entire model still fits instead of filling the card.
 local distance=2.8*math.max(1,extent*scale)
 scene:SetCameraPosition(0,-distance,distance*.65)
 scene:SetCameraOrientationByAxisVectors(0,.838,-.545,-1,0,0,0,.545,.838)
end
function I.Basis(c)
 local ca,sa,cp,sp=math.cos(c.yaw),math.sin(c.yaw),math.cos(c.pitch),math.sin(c.pitch)
 return {ca*cp,sa*cp,sp},{-sa,ca,0},{-ca*sp,-sa*sp,cp}
end
function I.HomeCamera()return{x=60,y=-84,z=14,yaw=2.187,pitch=-.10}end
function I.EditCamera()return{x=32,y=-44,z=38,yaw=2.187,pitch=-.62}end
function I.BuyCamera()return{x=0,y=0,z=200,yaw=math.pi/2,pitch=-1.569}end
function I.GlideCamera(f,target)
 f:StopFlight()
 if F.db.settings.reduceMotion then f.camera=target;f:Camera();return end
 local from={};for k,v in pairs(f.camera)do from[k]=v end
 f.cameraTransition={from=from,to=target,elapsed=0,duration=.7}
end
function I.StepCameraTransition(f,dt)
 local t=rawget(f,'cameraTransition');if not t then return end
 t.elapsed=math.min(t.duration,t.elapsed+dt)
 local p=t.elapsed/t.duration;local eased=p*p*(3-2*p)
 for _,key in ipairs({'x','y','z','pitch'})do f.camera[key]=t.from[key]+(t.to[key]-t.from[key])*eased end
 local angle=(t.to.yaw-t.from.yaw+math.pi)%(2*math.pi)-math.pi
 f.camera.yaw=t.from.yaw+angle*eased;f.camera.explore=t.from.explore or t.to.explore
 if p>=1 then f.camera=t.to;f.cameraTransition=nil end
 f:Camera()
end
function I.CenterCamera(yaw)return{x=0,y=0,z=6,yaw=yaw or 2.187,pitch=0}end
function I.PetCameraTarget(resident,yaw)
 local height=(resident.height or 2)*(resident.scale or 1)
 local distance=math.max(7,height*2.5)
 return {x=resident.x-math.cos(yaw)*distance,y=resident.y-math.sin(yaw)*distance,
  z=(resident.z or 0)+height*.6+distance*.4,yaw=yaw,pitch=-math.atan(.4)}
end
function I.LockPetCamera(f,index)
 local resident=f.roamingPets and f.roamingPets[index]
 if not resident or not resident.pet or not resident.ready or not resident.actor:IsShown()then
  f.status:SetText('This pet is not on the island right now.');return false
 end
 if f.followPetID==resident.pet.id then f:StopFlight();if f.workshop then f.workshop:RefreshTools()end;return true end
 local yaw=f.camera.yaw
 I.GlideCamera(f,I.PetCameraTarget(resident,yaw))
 f.followPetID=resident.pet.id;f.followPetIndex=index;f.followPetYaw=yaw;f.cameraLocked=true
 f.voyageFollow=resident.voyage==true
 if f.workshop then f.workshop:RefreshTools()end
 f.status:SetText('Following '..F.Pets.PetName(resident.pet)..'. Right-click its frame again to release.')
 return true
end
function I.StepPetCamera(f)
 if not rawget(f,'followPetID')then return end
 local resident=f.roamingPets and f.roamingPets[f.followPetIndex]
 if not resident or not resident.pet or resident.pet.id~=f.followPetID or not resident.actor:IsShown()then
  f:StopFlight();if f.workshop then f.workshop:RefreshTools()end;return
 end
 local target=I.PetCameraTarget(resident,f.followPetYaw)
 if resident.voyage then f.voyageFollow=true end
 if rawget(f,'cameraTransition')then f.cameraTransition.to=target
 else f.camera=target;f:Camera()end
end
function I.PanCamera(c,dx,dy)
 local _,left,up=I.Basis(c);local speed=I.Clamp(math.max(8,math.abs(c.z))*.0015,.025,30)*I.CameraSpeed()
 local limit,height=c.explore and 6200 or 130,c.explore and 32000 or 200
 c.x=clamp(c.x+(left[1]*dx-up[1]*dy)*speed,-limit,limit)
 c.y=clamp(c.y+(left[2]*dx-up[2]*dy)*speed,-limit,limit)
 c.z=clamp(c.z-up[3]*dy*speed,-6,height)
end
function I.Fly(c,keys,dt)
 dt=clamp(type(dt)=="number" and dt==dt and dt or 0,0,.1)
 local f,r=I.Basis(c);local a=(keys.W and 1 or 0)-(keys.S and 1 or 0)
 -- ModelScene projects its second orientation axis toward screen-left.
 local b=(keys.A and 1 or 0)-(keys.D and 1 or 0);local u=(keys.E and 1 or 0)-(keys.Q and 1 or 0)
 local n=math.max(1,math.sqrt(a*a+b*b+u*u));local speed=(keys.LSHIFT or keys.RSHIFT)and 28 or 10
 local limit,height=130,200
 if c.explore then
  limit,height=6200,32000
  speed=clamp(math.max(10,c.z*.16),10,800)
  if keys.LSHIFT or keys.RSHIFT then speed=math.max(180,speed*3)end
 end
 speed=speed*I.CameraSpeed()
 c.x=clamp(c.x+(f[1]*a+r[1]*b)*dt*speed/n,-limit,limit)
 c.y=clamp(c.y+(f[2]*a+r[2]*b)*dt*speed/n,-limit,limit)
 c.z=clamp(c.z+(f[3]*a+u)*dt*speed/n,-6,height)
end
-- Actor translations are scaled by ModelScene. Keep scene positions independent
-- of model dimensions by converting once at this boundary.
function I.Position(entry,x,y,z)
 local s=entry.scale or 1
 entry.actor:SetPosition(x/s,y/s,z/s)
end
