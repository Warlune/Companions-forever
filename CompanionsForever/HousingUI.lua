local _,F=...
local P,S,H=F.Pets,F.Style,F.Housing
local CELL=32
local function label(parent,value,x,y,w,h)
 local t=S.Text(parent,value,x,y,w,"GameFontHighlightSmall",{1,1,1});t:SetHeight(h or 22);return t
end
local function block(parent,x,y,w,h,color,layer)
 local t=parent:CreateTexture(nil,layer or "ARTWORK");t:SetPoint("TOPLEFT",x,-y);t:SetSize(w,h);t:SetColorTexture(unpack(color));return t
end
local function border(parent)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");f:SetAllPoints();f:EnableMouse(false)
 f:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2});f:SetBackdropBorderColor(1,.88,.4,1);return f
end
local function cursor(floor)
 local x,y=GetCursorPosition();local scale=floor:GetEffectiveScale()
 return (x/scale-floor:GetLeft())/CELL,(floor:GetTop()-y/scale)/CELL
end
local function status(message)H.ui.status:SetText(message or "Layout saved automatically. Your pet stays in your stable.")end
local function clearDrag()
 H.drag=nil;if H.ui then H.ui.ghost:Hide()end
end
function H.FinishDrag(cancel)
 local drag=H.drag;if not drag then return end
 clearDrag()
 if not cancel then
  local x,y=cursor(H.ui.floor);local ok,msg=H.Move(drag.id,math.floor(x-drag.ox+.5),math.floor(y-drag.oy+.5))
  status(ok and "Furniture moved. Layout saved." or msg)
 end
 H.Paint()
end
function H.Build()
 if H.ui then return end
 H.Initialize()
 local f=P.NewPage();H.ui=f;f.items={};f.edit=false
 label(f,"PET HOUSING",0,0,300,26)
 label(f,"A little place to call home",420,0,284,26):SetJustifyH("RIGHT")
 local room=CreateFrame("Frame",nil,f);f.room=room;room:SetPoint("TOPLEFT",0,-38);room:SetSize(704,464);room:EnableMouse(true)
 block(room,0,0,704,464,{.085,.065,.055,1},"BACKGROUND")
 block(room,12,14,680,439,{.19,.13,.10,1})
 f.wall=block(room,24,18,656,50,{.35,.46,.40,1})
 for x=32,671,32 do block(room,x,18,2,44,{.72,.73,.56,.22})end
 block(room,19,12,666,8,{.66,.46,.26,1});block(room,24,56,656,10,{.31,.20,.12,1})
 block(room,28,62,648,4,{.85,.65,.38,1})
 block(room,21,64,11,378,{.43,.30,.19,1});block(room,672,64,11,378,{.43,.30,.19,1})
 -- Windows and curtains are fixed architecture; furnishings stay movable.
 for _,x in ipairs({102,510})do
  block(room,x-7,19,104,42,{.27,.19,.13,1});block(room,x,22,90,32,{.53,.75,.76,1})
  block(room,x+3,40,84,11,{.28,.48,.35,1});block(room,x+42,22,5,32,{.85,.72,.47,1})
  block(room,x-12,19,17,37,{.77,.62,.41,1});block(room,x+86,19,17,37,{.77,.62,.41,1})
  block(room,x-9,54,107,6,{.72,.48,.26,1})
 end
 local floor=CreateFrame("Frame",nil,room);f.floor=floor;floor:SetPoint("TOPLEFT",32,-66);floor:SetSize(640,384);floor:EnableMouse(true)
 f.floorArt=floor:CreateTexture(nil,"BACKGROUND");f.floorArt:SetAllPoints();f.floorArt:SetTexCoord(0,2.5,0,1.5)
 f.grid={}
 for x=0,H.width do f.grid[#f.grid+1]=block(floor,x*CELL,0,1,384,{1,1,1,.22},"OVERLAY")end
 for y=0,H.height do f.grid[#f.grid+1]=block(floor,0,y*CELL,640,1,{1,1,1,.22},"OVERLAY")end
 block(room,18,448,272,10,{.65,.45,.27,1});block(room,414,448,272,10,{.65,.45,.27,1})
 block(room,290,450,124,9,{.40,.28,.18,1})
 floor:SetScript("OnMouseDown",function(_,button)
  if f.edit or button~="LeftButton" or not H.Pet()then return end
  local x,y=cursor(floor);local m=H.Step(0,true)
  local path=m and H.Path(math.floor(m.x),math.floor(m.y),math.floor(x),math.floor(y))
  if path then m.path=path;m.index=1;m.wait=0;status("Coming over!")end
 end)
 local side=S.Panel(f,720,-38,240,464);f.side=side
 label(side,"AT HOME",14,-10,210)
 f.petName=label(side,"",14,-36,212,38);f.petName:SetJustifyH("CENTER")
 S.Button(side,"<",14,-76,36,function()H.CyclePet(-1);H.Paint()end)
 S.Button(side,"Choose pet",56,-76,128,function()H.CyclePet(1);H.Paint()end)
 S.Button(side,">",190,-76,36,function()H.CyclePet(1);H.Paint()end)
 f.wallButton=S.Button(side,"",14,-118,212,function()H.state.wall=H.state.wall%3+1;H.Paint()end)
 f.floorButton=S.Button(side,"",14,-152,212,function()H.state.floor=H.state.floor%3+1;H.Paint()end)
 f.editButton=S.Button(side,"Decorate",14,-193,212,function()f.edit=not f.edit;clearDrag();H.Paint()end)
 f.catalog={}
 for i,d in ipairs(H.catalog)do
  local key=d.key
  local b=S.Button(side,d.name,14+((i-1)%2)*110,-233-math.floor((i-1)/2)*31,102,function()
   local ok,result=H.Add(key);if ok then H.selected=result end;status(ok and "Added. Drag it into place." or result);H.Paint()
  end);f.catalog[#f.catalog+1]=b
 end
 f.selected=label(side,"",14,-365,212,28)
 f.rotate=S.Button(side,"Rotate",14,-401,102,function()
  local item=H.Item(H.selected);if item then local ok,msg=H.Move(item.id,item.x,item.y,(item.rot+1)%4);status(ok and "Furniture rotated." or msg);H.Paint()end
 end)
 f.store=S.Button(side,"Put away",124,-401,102,function()if H.Remove(H.selected)then H.selected=nil;status("Put away. Add it again whenever you like.");H.Paint()end end)
 f.status=label(f,"",0,-508,960,24)
 f.hint=label(f,"",0,-534,960,20)
 local ghost=CreateFrame("Frame",nil,floor);f.ghost=ghost;ghost:SetFrameLevel(floor:GetFrameLevel()+80);ghost:EnableMouse(false)
 ghost.view=H.CreateFurnitureView(ghost);ghost:SetAlpha(.65);ghost:Hide()
 local petFrame=CreateFrame("Frame",nil,floor);f.petFrame=petFrame;petFrame:SetSize(92,92);petFrame:EnableMouse(false)
 local shadow=petFrame:CreateTexture(nil,"BACKGROUND");shadow:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
 shadow:SetPoint("BOTTOM",0,12);shadow:SetSize(36,16);shadow:SetVertexColor(.05,.04,.03,.35)
 local view=P.CreateArena(petFrame,true);f.petView=view
 if view.scene then
  function view:Camera()
   local cy,cz,target=-4,7,.6;local fy,fz=-cy,target-cz;local length=math.sqrt(fy*fy+fz*fz)
   fy,fz=fy/length,fz/length
   self.scene:SetCameraPosition(0,cy,cz);self.scene:SetCameraOrientationByAxisVectors(0,fy,fz,-1,0,0,0,-fz,fy)
  end
 end
 f.petFallback=petFrame:CreateTexture(nil,"ARTWORK");f.petFallback:SetSize(36,36);f.petFallback:SetPoint("CENTER")
 f.petCaption=label(petFrame,"",-34,12,160,18);f.petCaption:SetJustifyH("CENTER")
 f.elapsed=0
 f:SetScript("OnUpdate",function(_,dt)
  f.elapsed=f.elapsed+dt;if f.elapsed<1/60 then return end;dt=f.elapsed;f.elapsed=0
  if H.drag then
   if IsMouseButtonDown and not IsMouseButtonDown("LeftButton")then H.FinishDrag(false)
   else
    local x,y=cursor(floor);local drag=H.drag
    ghost:ClearAllPoints();ghost:SetPoint("TOPLEFT",floor,"TOPLEFT",math.floor(x-drag.ox+.5)*CELL,-math.floor(y-drag.oy+.5)*CELL)
   end
  end
  for _,b in pairs(f.items)do if b:IsShown()then b.view:Poll(dt)end end
  if H.drag then ghost.view:Poll(dt)end
  local m=H.Step(dt,f.edit or F.db.settings.reduceMotion)
  if not m then petFrame:Hide();return end
  petFrame:Show();petFrame:ClearAllPoints();petFrame:SetPoint("CENTER",floor,"TOPLEFT",m.x*CELL,-m.y*CELL+12)
  petFrame:SetFrameLevel(floor:GetFrameLevel()+20+math.floor(m.y))
  if view.scene then
   view.scene:SetFrameLevel(petFrame:GetFrameLevel()+1);view:Poll(dt)
   local s=view.states[0]
   if s and s.loaded then
    local animation=m.walking and "run" or "idle"
    if s.animation~=animation then view:Animate(s,animation)end
    if m.walking then s.actor:SetYaw(H.WalkYaw(m.dx,m.dy))end
    view.scene:SetPaused(not not F.db.settings.reduceMotion,false)
   end
   f.petFallback:SetShown(not view:Ready())
  end
 end)
 f:SetScript("OnHide",function()clearDrag();f.elapsed=0;if view.scene then view.scene:SetPaused(true,false)end end)
 f:SetScript("OnShow",function()if view.scene then view.scene:SetPaused(false,false)end end)
 status()
end
function H.Paint()
 local f=H.ui;if not f then return end
 local s=H.state;local pet=H.Pet()
 local walls={"Sage","Rose","Twilight"}
 local colors={{.36,.47,.39,1},{.58,.36,.32,1},{.37,.35,.52,1}}
 f.wall:SetColorTexture(unpack(colors[s.wall]));f.floorArt:SetTexture(H.floors[s.floor].id,"REPEAT","REPEAT")
 f.floorButton:SetText("Floor: "..H.floors[s.floor].name);f.wallButton:SetText("Walls: "..walls[s.wall])
 f.petName:SetText(pet and P.PetName(pet) or "Choose a living pet")
 f.editButton:SetText(f.edit and "Done decorating" or "Decorate")
 f.hint:SetText(f.edit and "Drag furniture to move it. Select a piece to rotate or put it away. Everything is free in this prototype."
  or "Click a clear floor tile to call your pet. Decorating and your chosen pet are saved between visits.")
 for _,b in ipairs(f.catalog)do b:SetEnabled(f.edit and #s.items<H.limit)end
 for _,t in ipairs(f.grid)do t:SetShown(f.edit)end
 local selected=H.Item(H.selected);f.selected:SetText(selected and H.byKey[selected.key].name or "Select a furnishing")
 f.rotate:SetEnabled(f.edit and selected~=nil);f.store:SetEnabled(f.edit and selected~=nil)
 for _,b in pairs(f.items)do b:Hide()end
 for _,item in ipairs(s.items)do
  local b=f.items[item.id]
  if not b then
   b=CreateFrame("Frame",nil,f.floor);f.items[item.id]=b;b.view=H.CreateFurnitureView(b);b.selection=border(b)
   b:SetScript("OnMouseDown",function(self,button)
    if not f.edit then return end
    local entry=H.Item(self.itemID);if not entry then return end;H.selected=entry.id
    if button=="RightButton"then local ok,msg=H.Move(entry.id,entry.x,entry.y,(entry.rot+1)%4);status(ok and "Furniture rotated." or msg)
    else
     local x,y=cursor(f.floor);H.drag={id=entry.id,ox=x-entry.x,oy=y-entry.y}
     f.ghost:SetSize(self:GetSize());f.ghost.view:Set(entry.key,entry.rot);f.ghost:Show()
    end
    H.Paint()
   end)
   b:SetScript("OnMouseUp",function()H.FinishDrag(false)end)
  end
  local w,h=H.Size(item);b.itemID=item.id;b:SetSize(w*CELL,h*CELL);b:ClearAllPoints();b:SetPoint("TOPLEFT",f.floor,"TOPLEFT",item.x*CELL,-item.y*CELL)
  b:SetFrameLevel(f.floor:GetFrameLevel()+(H.byKey[item.key].walkable and 1 or 5));b.view:Set(item.key,item.rot);b.selection:SetFrameLevel(b:GetFrameLevel()+3)
  b:EnableMouse(f.edit);b.selection:SetShown(f.edit and H.selected==item.id);b:Show()
 end
 local key=pet and tostring(pet.id)..":"..tostring(P.ModelFor(pet).display) or "empty"
 if f.petKey~=key then
  f.petKey=key;f.petView:Sync(pet,{},key);H.motion=nil
  if pet then P.ShowPetPortrait(f.petFallback,pet)end
 end
 f.petFrame:SetShown(pet~=nil);f.petCaption:SetText(pet and P.PetName(pet) or "")
end
local build=P.BuildUI
function P.BuildUI(...)
 local result=build(...);local w=P.window
 if w and not w.tabs.housing then
  w.tabs.housing=S.Button(w,"Housing",0,-52,112,function()P.OpenPage("housing")end)
  for i,key in ipairs({"collection","tower","housing","equipment","talents","journal","adoption","peers"})do
   local b=w.tabs[key];b:ClearAllPoints();b:SetPoint("TOPLEFT",20+(i-1)*121,-52);b:SetSize(113,36)
  end
  if F.NativeUI then F.NativeUI.Navigation()end
 end
 return result
end
local open=P.OpenPage
function P.OpenPage(mode,...)
 if mode=="housing"then H.Build()end
 return open(mode,...)
end
local render=P.Render
function P.Render(...)
 local result=render(...)
 if H.ui then H.ui:SetShown(P.mode=="housing");if H.ui:IsShown()then H.Paint()end end
 return result
end
local command=SlashCmdList.COMPANIONSFOREVER
SlashCmdList.COMPANIONSFOREVER=function(message)
 if (message or ""):lower():match("^%s*housing%s*$")then if F.ready then P.OpenPage("housing")end
 else command(message)end
end
