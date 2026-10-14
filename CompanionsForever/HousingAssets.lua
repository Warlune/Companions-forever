local _,F=...
local H=F.Housing
-- Native client assets. IDs/paths: wowdev/wow-listfile parts/world.csv.
-- No extracted Blizzard artwork or custom replacement sprites are packaged.
H.floors={
 {name="Westfall wood",id=190493,path="World\\Azeroth\\Westfall\\BUILDINGS\\BoatHouse\\WestwoodFloorWood01.blp"},
 {name="Duskwood wood",id=189413,path="World\\Azeroth\\Duskwood\\PassiveDoodads\\CHASMBRIDGE\\GP_DUSKWOOD_WOOD_FLOOR_02.BLP"},
 {name="Wood planks",id=190585,path="World\\Azeroth\\Westfall\\PassiveDoodads\\Furniture\\mm_woodplank_01.blp"},
}
local assets={
 bed={name="Westfall bed",id=190586,path="World\\Azeroth\\Westfall\\PassiveDoodads\\Furniture\\westfallbed01.m2"},
 sofa={name="Inn bench",id=198012,path="World\\Generic\\Human\\Passive Doodads\\Benches\\InnBench.M2"},
 table={name="Inn table",id=198604,path="World\\Generic\\Human\\Passive Doodads\\Tables\\InnTableSmall.m2"},
 shelf={name="Bookcase",id=198052,path="World\\Generic\\Human\\Passive Doodads\\BookShelves\\DuskwoodBookshelf01.m2"},
 plant={name="Planter",id=198395,path="World\\Generic\\Human\\Passive Doodads\\PlanterBoxes\\StormwindPlanter.M2"},
 rug={name="Stormwind rug",id=198435,path="World\\Generic\\Human\\Passive Doodads\\Rugs\\StormwindRug01.M2"},
 bowls={name="Food bowl",id=190650,path="World\\Azeroth\\Westfall\\PassiveDoodads\\UTENSILS\\Bowl.m2"},
 lamp={name="Lantern",id=190608,path="World\\Azeroth\\Westfall\\PassiveDoodads\\LampDeadMines\\LampDeadMines.m2"},
}
for key,asset in pairs(assets)do H.byKey[key].asset=asset;H.byKey[key].name=asset.name end
function H.WalkYaw(dx,dy)return math.atan2(dy,dx)end
local function bounds(actor)
 local ok,x,y,z,tx,ty,tz=pcall(actor.GetActiveBoundingBox,actor)
 if not ok then return end
 if (type(x)=="table" or type(x)=="userdata") and x.GetXYZ and y and y.GetXYZ then
  local lo,hi=x,y;x,y,z=lo:GetXYZ();tx,ty,tz=hi:GetXYZ()
 end
 if type(x)=="number" and type(y)=="number" and type(z)=="number" and type(tx)=="number" and type(ty)=="number" and type(tz)=="number"then
  return math.max(.01,tx-x),math.max(.01,ty-y),z,math.max(.01,tz-z)
 end
end
function H.CreateFurnitureView(parent)
 local v={elapsed=0}
 v.label=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");v.label:SetAllPoints();v.label:SetText("Loading...")
 local ok=pcall(function()
  local scene=CreateFrame("ModelScene",nil,parent);v.scene=scene;scene:SetAllPoints();scene:EnableMouse(false)
  scene:SetCameraNearClip(.01);scene:SetCameraFarClip(1000);scene:SetCameraFieldOfView(math.rad(36))
  scene:SetLightVisible(true);scene:SetLightAmbientColor(.8,.8,.8);scene:SetLightDiffuseColor(.8,.78,.72);scene:SetLightDirection(-.5,1,-1)
  v.actor=scene:CreateActor();v.actor:SetUseCenterForOrigin(true,true,false);v.actor:SetScale(1);v.actor:Hide()
 end)
 if not ok then if v.scene then v.scene:Hide()end;v.scene=nil;v.label:SetText("Model unavailable")end
 function v:Fit()
  if not self.scene or not self.actor:IsLoaded()then return false end
  local w,h,z,height=bounds(self.actor);if not w then return false end
  local angle=self.rot*math.pi/2;local c,s=math.abs(math.cos(angle)),math.abs(math.sin(angle))
  local worldW,worldH=w*c+h*s,w*s+h*c
  local aspect=math.max(.25,parent:GetWidth()/math.max(1,parent:GetHeight()))
  local distance=math.max(worldW/aspect,worldH*.866+height*.5)/(.6498)*1.16
  local target=z+height*.5
  self.scene:SetCameraPosition(0,-distance*.5,target+distance*.866)
  self.scene:SetCameraOrientationByAxisVectors(0,.5,-.866,-1,0,0,0,.866,.5)
  self.actor:SetPosition(0,0,0);self.actor:SetYaw(angle);self.actor:SetAlpha(1);self.actor:Show()
  self.ready=true;self.label:Hide();return true
 end
 function v:Set(key,rot)
  if not self.scene then return end
  self.scene:SetFrameLevel(parent:GetFrameLevel()+1)
  if self.key==key and self.rot==rot then return end
  local changed=self.key~=key;self.key,self.rot=key,rot;self.ready=false;self.elapsed=0
  if changed then
   self.actor:Hide();self.label:SetText("Loading...");self.label:Show()
   local asset=H.byKey[key].asset
   local loaded,accepted=pcall(self.actor.SetModelByFileID,self.actor,asset.id)
   if not loaded or accepted==false then loaded,accepted=pcall(self.actor.SetModelByPath,self.actor,asset.path)end
   self.failed=not loaded or accepted==false
  end
  self:Fit()
 end
 function v:Poll(dt)
  if not self.scene or self.ready then return end
  self.elapsed=self.elapsed+math.min(dt,.25)
  if not self.failed and self:Fit()then return end
  if self.failed or self.elapsed>8 then self.failed=true;self.actor:Hide();self.label:SetText("Model unavailable")end
 end
 return v
end
