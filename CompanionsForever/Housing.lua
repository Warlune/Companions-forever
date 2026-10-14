-- Isolated sandbox prototype. Display a stable pet without moving or copying it.
local _,F=...
local P=F.Pets
local H={width=20,height=12,limit=24};F.Housing=H
H.catalog={
 {key="bed",name="Pet bed",w=3,h=2},{key="sofa",name="Sofa",w=4,h=2},
 {key="table",name="Table",w=2,h=2},{key="shelf",name="Bookcase",w=3,h=1},
 {key="plant",name="Plant",w=1,h=1},{key="rug",name="Rug",w=5,h=3,walkable=true},
 {key="bowls",name="Bowls",w=2,h=1},{key="lamp",name="Lamp",w=1,h=1},
}
H.byKey={};for _,d in ipairs(H.catalog)do H.byKey[d.key]=d end
local function whole(n,lo,hi)return type(n)=="number" and n==math.floor(n) and n>=lo and n<=hi end
function H.Size(item)
 local d=H.byKey[item.key];if item.rot%2==1 then return d.h,d.w end;return d.w,d.h
end
function H.Fits(item,items,ignore)
 local w,h=H.Size(item)
 if not whole(item.x,0,H.width-w) or not whole(item.y,0,H.height-h)then return false end
 -- Keep the entrance and its landing clear.
 if not H.byKey[item.key].walkable and item.x<12 and item.x+w>8 and item.y+h>10 then return false end
 for _,other in ipairs(items)do if other.id~=ignore and not H.byKey[item.key].walkable and not H.byKey[other.key].walkable then
  local ow,oh=H.Size(other)
  if item.x<other.x+ow and item.x+w>other.x and item.y<other.y+oh and item.y+h>other.y then return false end
 end end
 return true
end
function H.Pet()
 local id=F.char.housingPrototype and F.char.housingPrototype.petID
 for _,pet in ipairs(P.state.pets)do if pet.id==id and not pet.deadAt then return pet end end
end
function H.Initialize()
 local s=F.char.housingPrototype
 if type(s)~="table"then
  local pet=P.Active();s={version=1,floor=1,wall=1,petID=pet and pet.id,items={
   {id=1,key="rug",x=7,y=4,rot=0},{id=2,key="sofa",x=7,y=1,rot=0},
   {id=3,key="table",x=8,y=5,rot=0},{id=4,key="bed",x=1,y=2,rot=0},
   {id=5,key="shelf",x=15,y=0,rot=0},{id=6,key="plant",x=18,y=3,rot=0},
   {id=7,key="bowls",x=2,y=7,rot=0},{id=8,key="lamp",x=13,y=2,rot=0},
  }};F.char.housingPrototype=s
 end
 s.floor=whole(s.floor,1,3) and s.floor or 1;s.wall=whole(s.wall,1,3) and s.wall or 1
 local clean,seen={},{};local maxID=0
 if type(s.items)=="table"then for i=1,math.min(#s.items,H.limit)do local item=s.items[i]
  if type(item)=="table" and H.byKey[item.key] and whole(item.id,1,1000000) and not seen[item.id] and whole(item.rot,0,3)then
   local copy={id=item.id,key=item.key,x=item.x,y=item.y,rot=item.rot}
   if H.Fits(copy,clean)then clean[#clean+1]=copy;seen[item.id]=true;maxID=math.max(maxID,item.id)end
  end
 end end
 s.items=clean;s.nextID=maxID+1;s.version=1
 if not H.Pet()then s.petID=nil end
 H.state=s;H.motion=nil;return s
end
function H.SelectPet(id)
 if id==nil then H.state.petID=nil;H.motion=nil;return true end
 for _,pet in ipairs(P.state.pets)do if pet.id==id and not pet.deadAt then H.state.petID=id;H.motion=nil;return true end end
 return false,"Choose a living pet from your stable."
end
function H.CyclePet(delta)
 local pets={};local index=0
 for _,pet in ipairs(P.state.pets)do if not pet.deadAt then pets[#pets+1]=pet;if pet.id==H.state.petID then index=#pets end end end
 if #pets==0 then return H.SelectPet(nil)end
 return H.SelectPet(pets[(index-1+delta)%#pets+1].id)
end
function H.Item(id)for _,item in ipairs(H.state.items)do if item.id==id then return item end end end
function H.Move(id,x,y,rot)
 local old=H.Item(id);if not old then return false,"That furnishing is no longer here."end
 local item={id=id,key=old.key,x=x,y=y,rot=rot==nil and old.rot or rot}
 if not whole(item.rot,0,3) or not H.Fits(item,H.state.items,id)then return false,"Leave space around furniture and the doorway."end
 old.x,old.y,old.rot=item.x,item.y,item.rot;H.motion=nil;return true
end
function H.Add(key)
 if not H.byKey[key]then return false,"Unknown furniture."end
 if #H.state.items>=H.limit then return false,"This room holds up to 24 furnishings."end
 local item={id=H.state.nextID,key=key,rot=0}
 for y=0,H.height-1 do for x=0,H.width-1 do
  item.x,item.y=x,y
  if H.Fits(item,H.state.items)then
   H.state.items[#H.state.items+1]=item;H.state.nextID=item.id+1;H.motion=nil;return true,item.id
  end
 end end
 return false,"Make some room first."
end
function H.Remove(id)
 for i,item in ipairs(H.state.items)do if item.id==id then table.remove(H.state.items,i);H.motion=nil;return true end end
 return false
end
function H.Free(x,y)
 if x<0 or y<0 or x>=H.width or y>=H.height then return false end
 for _,item in ipairs(H.state.items)do if not H.byKey[item.key].walkable then
  local w,h=H.Size(item);if x>=item.x and x<item.x+w and y>=item.y and y<item.y+h then return false end
 end end
 return true
end
-- Bounded breadth-first paths prevent walking through furniture or walls.
function H.Path(sx,sy,tx,ty)
 if not H.Free(sx,sy) or not H.Free(tx,ty)then return end
 local start=sy*H.width+sx;local target=ty*H.width+tx
 local queue,seen,previous={start},{[start]=true},{};local head=1
 while head<=#queue do
  local n=queue[head];head=head+1
  if n==target then
   local path={};while n~=start do table.insert(path,1,{x=n%H.width+.5,y=math.floor(n/H.width)+.5});n=previous[n]end
   return path
  end
  local x,y=n%H.width,math.floor(n/H.width)
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do local xx,yy=x+d[1],y+d[2];local key=yy*H.width+xx
   if not seen[key] and H.Free(xx,yy)then seen[key]=true;previous[key]=n;queue[#queue+1]=key end
  end
 end
end
-- Own random state: cosmetic wandering must never consume gameplay loot rolls.
local seed=173
local function random(n)seed=(seed*48271)%2147483647;return seed%n+1 end
function H.Step(dt,paused)
 if not H.Pet()then H.motion=nil;return end
 local m=H.motion
 if not m then
  for y=H.height-1,0,-1 do for x=0,H.width-1 do if H.Free(x,y)then m={x=x+.5,y=y+.5,wait=1,path={},index=1};break end end;if m then break end end
  H.motion=m
 end
 if not m then return end
 if paused then m.walking=false;return m end
 dt=math.max(0,math.min(.1,dt or 0));m.wait=math.max(0,m.wait-dt)
 local target=m.path[m.index]
 if not target then
  m.walking=false
  if m.wait>0 then return m end
  for i=1,12 do
   local path=H.Path(math.floor(m.x),math.floor(m.y),random(H.width)-1,random(H.height)-1)
   if path and #path>0 then m.path=path;m.index=1;break end
  end
  m.wait=1+random(30)/10;return m
 end
 local dx,dy=target.x-m.x,target.y-m.y;local distance=math.sqrt(dx*dx+dy*dy)
 if distance<.001 then m.index=m.index+1;m.walking=false;return m end
 local step=math.min(distance,dt*1.1);m.x=m.x+dx/distance*step;m.y=m.y+dy/distance*step
 m.dx,m.dy,m.walking=dx,dy,true;return m
end
