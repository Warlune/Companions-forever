local _,F=...
local I=F.Housing.Island
-- Actor Euler rotation: roll about X, pitch about Y, then yaw about Z.
function I.RotateOffset(o,x,y,z)
 local r,p=o.roll or 0,o.pitch or 0
 y,z=y*math.cos(r)-z*math.sin(r),y*math.sin(r)+z*math.cos(r)
 x,z=x*math.cos(p)+z*math.sin(p),-x*math.sin(p)+z*math.cos(p)
 return x*math.cos(o.yaw)-y*math.sin(o.yaw),x*math.sin(o.yaw)+y*math.cos(o.yaw),z
end
-- Match the actor's Euler axes, including the opposite winding of the Y ring.
function I.GizmoRingOffset(o,axis,t)
 local c,s=math.cos(t),math.sin(t)
 if axis=='x'then return I.RotateOffset({pitch=o.pitch,yaw=o.yaw},0,c,s)
 elseif axis=='y'then return I.RotateOffset({yaw=o.yaw},c,0,-s)
 else return c,s,0 end
end
function I.BuildGizmo(f,e)
 local g=CreateFrame('Frame',nil,f.input);e.gizmo=g;g:SetAllPoints();g:EnableMouse(false);g:SetFrameLevel(f.input:GetFrameLevel()+10)
 g.lines={};g.targets={}
 g.angleLabel=g:CreateFontString(nil,'OVERLAY','GameFontNormal');g.angleLabel:Hide()
 local axes={{key='x',angle='roll',color={1,.23,.2,1}},{key='y',angle='pitch',color={.3,1,.3,1}},{key='z',angle='yaw',color={.25,.65,1,1}}}
 local function selected()for _,v in ipairs(e.actors)do if v.used and v.ready and v.object.id==e.selected then return v end end end
 local function cursor()
  local x,y=GetCursorPosition();local s=f.input:GetEffectiveScale()
  return x/s-f.input:GetLeft(),y/s-f.input:GetBottom()
 end
 local function project(x,y,z)
  local px,py=I.SceneProject(f.scene,x,y,z)
  if px then return (px+1)*f.input:GetWidth()/2,(py+1)*f.input:GetHeight()/2 end
 end
 local function ringAngle(a,x,y)
  local det=a.ux*a.vy-a.uy*a.vx
  if math.abs(det)<1 then return nil end
  x,y=x-a.cx,y-a.cy
  return math.atan2((a.ux*y-a.uy*x)/det,(x*a.vy-y*a.vx)/det)
 end
 local function line(ax,ay,bx,by,color,target)
  if not ax or not bx then return end
  local w,h=f.input:GetWidth(),f.input:GetHeight()
  if ax<0 or ax>w or bx<0 or bx>w or ay<0 or ay>h or by<0 or by>h then return end
  g.used=g.used+1;local l=g.lines[g.used]
  if not l then l=g:CreateLine(nil,'OVERLAY');g.lines[g.used]=l end
  l:SetThickness(target and target.kind=='move'and 4 or 2.5)
  l:SetStartPoint('BOTTOMLEFT',ax,ay);l:SetEndPoint('BOTTOMLEFT',bx,by);l:SetColorTexture(unpack(color));l:Show()
  if target then g.targets[#g.targets+1]={ax=ax,ay=ay,bx=bx,by=by,action=target}end
 end
 function e:EndGizmo(cancel)
  local d=self.gizmoDrag
  if d and cancel then for k,v in pairs(d.original)do d.object[k]=v end;if d.saved then table.remove(self.history)end;self:Sync()end
  self.gizmoDrag=nil;self.preview=nil
 end
 function e:GizmoDown(button)
  if self.gizmoDrag then if button=='RightButton'then self:EndGizmo(true)end;return true end
  if button~='LeftButton'or not self.enabled or self.landMode or self.placing or f.fly then return false end
  local v=selected();if not v then return false end
  local x,y=cursor();local nearest,best=nil,10*10
  for _,t in ipairs(g.targets)do
   local dx,dy=t.bx-t.ax,t.by-t.ay;local len=dx*dx+dy*dy
   if len>.01 then
    local u=I.Clamp(((x-t.ax)*dx+(y-t.ay)*dy)/len,0,1)
    local dist=(x-t.ax-u*dx)^2+(y-t.ay-u*dy)^2
    if dist<best then best=dist;nearest=t end
   end
  end
  if not nearest then return false end
  local a=nearest.action;local original={};for k,val in pairs(v.object)do original[k]=val end
  self.gizmoDrag={object=v.object,original=original,action=a,mx=x,my=y,amount=0}
  if a.kind=='rotate'then
   local angle=ringAngle(a,x,y)
   self.gizmoDrag.lastAngle=angle;self.gizmoDrag.startAngle=angle or a.startAngle;self.gizmoDrag.turn=0
  end
  f.look=false;self.drag=nil;return true
 end
 function e:GizmoUpdate()
  local d=self.gizmoDrag
  if d then
   if not IsMouseButtonDown('LeftButton')then self:EndGizmo(false)
   else
    local x,y=cursor();local a=d.action;local o={};for k,val in pairs(d.original)do o[k]=val end
    local amount=((x-d.mx)*a.dx+(y-d.my)*a.dy)/(a.dx*a.dx+a.dy*a.dy)
    if a.kind=='move'then o[a.axis.key]=I.Clamp(o[a.axis.key]+amount,a.axis.key=='z'and 0 or -130,a.axis.key=='z'and 80 or 130)
    elseif a.kind=='size'then o.size=I.Clamp(o.size*math.exp(amount),.25,3)
    else
     if d.lastAngle then
      local angle=ringAngle(a,x,y)
      local delta=(angle-d.lastAngle+math.pi)%(2*math.pi)-math.pi
      d.turn=d.turn+delta;d.lastAngle=angle;amount=d.turn
     end
     local angle=(o[a.axis.angle]or 0)+amount
     if IsShiftKeyDown and IsShiftKeyDown()then local step=math.pi/4;angle=math.floor(angle/step+.5)*step end
     amount=angle-(o[a.axis.angle]or 0);o[a.axis.angle]=angle%(2*math.pi)
    end
    local valid,reason=I.CanPlace(o,self.db.items);self.preview=o;self.previewOK=valid
    if valid then
     d.amount=amount
     if not d.saved then self:Remember();d.saved=true end
     for k,val in pairs(o)do d.object[k]=val end;self:Sync()
     f.status:SetText(string.format('X %.2f  Y %.2f  Z %.2f | Tilt %.0f / %.0f | Turn %.0f | Right-click cancels',o.x,o.y,o.z,math.deg(o.roll or 0),math.deg(o.pitch or 0),math.deg(o.yaw)))
    else f.status:SetText(reason)end
   end
  end
  d=self.gizmoDrag
  g.used=0;g.targets={};g.angleLabel:Hide()
  local v=selected()
  local visible=self.enabled and not f.fly and not self.landMode and not self.placing and not self.drag and v~=nil
  g:SetShown(visible)
  if not visible then return end
  local o=v.object;local z=o.z+v.height*v.scale/2
  local cx,cy=project(o.x,o.y,z)
  if not cx then g:Hide();return end
  local span=0
  for _,a in ipairs(axes)do
   local x,y=project(o.x+(a.key=='x'and 1 or 0),o.y+(a.key=='y'and 1 or 0),z+(a.key=='z'and 1 or 0))
   if x then span=math.max(span,math.sqrt((x-cx)^2+(y-cy)^2))end
  end
  local radius=70/math.max(span,.01)
  for _,a in ipairs(axes)do
   if not d or d.action.axis.key==a.key then
   local function point(t)
    local x,y,dz=I.GizmoRingOffset(o,a.key,t)
    return project(o.x+x*radius,o.y+y*radius,z+dz*radius)
   end
   local ux,uy=point(0);local vx,vy=point(math.pi/2)
   if not e.tool or e.tool=='rotate'then for j=0,63 do
    local t=j*math.pi/32;local ax,ay=point(t);local bx,by=point(t+math.pi/32)
    if ax and bx then
     local dx,dy=(bx-ax)/(math.pi/32),(by-ay)/(math.pi/32)
     if dx*dx+dy*dy>4 and ux and vx then line(ax,ay,bx,by,a.color,{kind='rotate',axis=a,dx=dx,dy=dy,startAngle=t+math.pi/64,cx=cx,cy=cy,ux=ux-cx,uy=uy-cy,vx=vx-cx,vy=vy-cy})end
    end
   end
   if e.tool=='rotate'then
    -- A fixed reference spoke stays at the grab point; the colored spoke tracks
    -- the applied turn. Neither reference decoration can steal a handle hit.
    local anchor=d and d.startAngle or 0
    local ax,ay=point(anchor)
    local white={1,1,1,1}
    if ax then
     line(cx,cy,ax,ay,white)
     line(ax-5,ay-5,ax+5,ay-5,white);line(ax+5,ay-5,ax+5,ay+5,white)
     line(ax+5,ay+5,ax-5,ay+5,white);line(ax-5,ay+5,ax-5,ay-5,white)
    end
    if d then
     local bx,by=point(anchor+d.amount);line(cx,cy,bx,by,a.color)
     g.angleLabel:ClearAllPoints();g.angleLabel:SetPoint('BOTTOMLEFT',g,'BOTTOMLEFT',cx+14,cy+14)
     g.angleLabel:SetText(string.format('%s: %.0f deg (%+.0f deg)',a.key:upper(),math.deg(o[a.angle]or 0),math.deg(d.amount)));g.angleLabel:Show()
    end
    line(cx-4,cy,cx+4,cy,white);line(cx,cy-4,cx,cy+4,white)
   end
   end
   local x,y=project(o.x+(a.key=='x'and radius*1.6 or 0),o.y+(a.key=='y'and radius*1.6 or 0),z+(a.key=='z'and radius*1.6 or 0))
   if x and e.tool~='rotate'then
    local dx,dy=x-cx,y-cy;local len=math.sqrt(dx*dx+dy*dy)
    if len>18 then
     local sizing=e.tool=='size'
     local action={kind=sizing and 'size'or 'move',axis=a,dx=sizing and dx or dx/(radius*1.6),dy=sizing and dy or dy/(radius*1.6)}
     line(cx+dx*.15,cy+dy*.15,x,y,a.color,action)
     local ux,uy=dx/len,dy/len
     if sizing then
      line(x-6,y-6,x+6,y-6,a.color,action);line(x+6,y-6,x+6,y+6,a.color,action)
      line(x+6,y+6,x-6,y+6,a.color,action);line(x-6,y+6,x-6,y-6,a.color,action)
     else
     line(x,y,x-ux*13-uy*7,y-uy*13+ux*7,a.color,action)
     line(x,y,x-ux*13+uy*7,y-uy*13-ux*7,a.color,action)
     end
    end
   end
   end
  end
  for j=g.used+1,#g.lines do g.lines[j]:Hide()end
 end
end
