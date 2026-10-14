local _,F=...
local I,P,S=F.Housing.Island,F.Pets,F.Style
local L=I.Life
local function panel(parent,width,height)
 local f=CreateFrame('Frame',nil,parent,'BackdropTemplate');f:SetSize(width,height)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 f:SetBackdropColor(.1,.08,.05,F.db.settings.highContrast and 1 or .94);f:EnableMouse(true);return f
end
local function result(ok,message)P.notice=message or '';if I.ui and message then I.ui.status:SetText(message)end;P.Render()end
local function tip(frame,title,body)
 frame:SetScript('OnEnter',function()GameTooltip:SetOwner(frame,'ANCHOR_RIGHT');GameTooltip:SetText(title);GameTooltip:AddLine(type(body)=='function'and body()or body,1,1,1,true);GameTooltip:Show()end)
 frame:SetScript('OnLeave',function()GameTooltip:Hide()end)
end
function L.BuildUI(f)
 if rawget(f,'lifeUI')then return end
 local ui={};f.lifeUI=ui
 local pets=CreateFrame('Frame',nil,f);ui.pets=pets;pets:SetSize(228,344);pets:SetPoint('TOPLEFT',0,-30);pets:SetFrameLevel(f.input:GetFrameLevel()+35)
 ui.rows={}
 local menu=panel(f,236,242);ui.menu=menu;menu:SetFrameLevel(pets:GetFrameLevel()+20);menu:Hide()
 menu.title=S.Text(menu,'Assign companion',14,-14,208,'GameFontNormal')
 menu.summary=S.Text(menu,'Choose an activity',14,-35,208,'GameFontHighlightSmall')
 local jobIcons={roam='Ability_Tracking',food='INV_Misc_Food_15',gold='INV_Misc_Coin_01',xp='Ability_Hunter_Pet_Bear',herbs='INV_Misc_Herb_07',expedition='INV_Misc_Map_01'}
 local jobLabels={roam='Roam',food='Food',gold='Gold',xp='XP',herbs='Herbs',expedition='Sail'}
 local jobTips={roam='Explore the island and recover energy.',food='Earn 1 food per payout.',gold='Earn 2 tokens per payout.',xp='Earn 25 XP for your equipped pet and all housing pets per payout.',herbs='Earn 1 herb per payout.',expedition='Walk to the boat and wait aboard. Press Depart in Expeditions to sail.'}
 ui.jobButtons={}
 for j,job in ipairs(L.jobs)do
  local b=f.workshop.Square(menu,jobLabels[job],0,54,function()result(L.SetJob(menu.petID,job));menu:Hide()end,jobIcons[job]);ui.jobButtons[job]=b
  b:ClearAllPoints();b:SetPoint('TOPLEFT',18+((j-1)%3)*74,-60-math.floor((j-1)/3)*66)
  tip(b,L.jobNames[job],function()local station=L.Station(job);return jobTips[job]..(job~='roam'and (station and '\n'..L.DurationText(L.WorkSeconds(nil,job))..' per '..(job=='expedition'and 'voyage.'or 'payout.')..'\nSpeed comes from station rank and furniture quality.'or '\nBuy and place its workstation first.')or '')end)
 end
 S.Button(menu,'Return to stable',12,-199,144,function()result(L.Remove(menu.petID));menu:Hide()end)
 S.Button(menu,'Close',162,-199,62,function()menu:Hide()end)
 for index=1,3 do
  local row=CreateFrame('Frame',nil,pets,'BackdropTemplate');row:SetSize(220,100);row:EnableMouse(true);row:SetPoint('TOPLEFT',4,-(index-1)*104);ui.rows[index]=row
  row:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  row:SetBackdropColor(.025,.025,.035,f.workshop:ButtonOpacity());row:SetBackdropBorderColor(.45,.4,.55,1)
  row.portrait=row:CreateTexture(nil,'ARTWORK',nil,0);row.portrait:SetSize(60,60);row.portrait:SetPoint('TOPLEFT',20,-10)
  local mask=row:CreateMaskTexture();mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask','CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE');mask:SetAllPoints(row.portrait);row.portrait:AddMaskTexture(mask)
  local art=row:CreateTexture(nil,'ARTWORK',nil,1);art:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame');art:SetTexCoord(1,0,0,1);art:SetSize(256,128);art:SetPoint('TOPLEFT',-24,0);row.art=art
  local nameBack=row:CreateTexture(nil,'BACKGROUND');nameBack:SetColorTexture(.03,.03,.03,.9);nameBack:SetSize(120,17);nameBack:SetPoint('TOPLEFT',82,-21)
  row.name=S.Text(row,'Empty housing slot',84,-22,115,'GameFontNormalSmall');row.name:SetMaxLines(1);row.name:SetHeight(15);row.name:SetJustifyV('MIDDLE');row.name:SetJustifyH('LEFT')
  local function bar(y,height,r,g,b)
   local v=CreateFrame('StatusBar',nil,row);v:SetPoint('TOPLEFT',82,y);v:SetSize(119,height);v:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');v:SetMinMaxValues(0,100);v:SetStatusBarColor(r,g,b)
   local bg=v:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.03,.03,.03,1)
   local text=v:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');text:SetAllPoints();text:SetTextColor(1,1,1);text:SetShadowOffset(1,-1);v.text=text;return v
  end
  row.energy=bar(-40,12,1,.82,.05);row.bar=bar(-53,12,.65,.25,1);row.status=row.bar.text
  local job=CreateFrame('Frame',nil,row,'BackdropTemplate');row.job=job;job:SetSize(24,24);job:SetPoint('TOPLEFT',84,-70);job:EnableMouse(true)
  job:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1});job:SetBackdropBorderColor(.8,.7,.4,1)
  job.art=job:CreateTexture(nil,'ARTWORK');job.art:SetPoint('TOPLEFT',1,-1);job.art:SetPoint('BOTTOMRIGHT',-1,1)
  job.timer=S.Text(row,'',113,-75,95,'GameFontHighlightSmall')
  tip(job,'Housing job',function()
   local state=L.State();local slot=state.slots[index];local pet=slot and L.Pet(slot.petID);local activity,progress=L.Activity(slot,pet,state)
   return string.format('%s: %.0f%% complete\n%s',activity,progress*100,slot and slot.job=='expedition'and 'Cancelling discards this expedition.'or 'Utility progress stays with this housing slot.')
  end)
  row.level=S.Text(row,'',36,-72,32,'GameFontNormalSmall')
  row.level:ClearAllPoints();row.level:SetPoint('TOPLEFT',14,-61);row.level:SetJustifyH('CENTER')
  row.zzz=S.Text(row,'Zzz',0,0,42,'GameFontNormal');row.zzz:ClearAllPoints();row.zzz:SetPoint('TOP',row.portrait,'TOP',0,2);row.zzz:SetJustifyH('CENTER');row.zzz:SetDrawLayer('OVERLAY',7);row.zzz:SetShadowOffset(1,-1);row.zzz:SetTextColor(1,.9,.3);row.zzz:Hide()
  row:SetScript('OnMouseUp',function(_,button)
   if button=='RightButton'then menu:Hide();I.LockPetCamera(f,index);return end
   if button~='LeftButton'then return end
   local slot=L.State().slots[index]
   if not slot then P.OpenPage('collection');return end
   f:StopFlight();menu.petID=slot.petID;menu:ClearAllPoints();menu:SetPoint('TOPLEFT',row,'TOPRIGHT',4,0);menu:SetShown(not menu:IsShown()or menu.lastID~=slot.petID);menu.lastID=slot.petID;ui:Refresh()
  end)
  tip(row,'Island companion',function()
   local state=L.State();local slot=state.slots[index];local pet=slot and L.Pet(slot.petID);local activity,progress=L.Activity(slot,pet,state)
   return pet and string.format('%s: %.0f%% complete\nEnergy: %.0f%%%s\n3 XP per minute.\nCompleted tasks: 20 XP for housing pets.\nLeft-click: assign work or return to stable.\nRight-click: close-up camera lock / release.',activity,progress*100,pet.energy or 0,state.cityRest and '\nCity rest: tasks continue while energy recovers.'or '')or 'Move a pet here from Camp.'
  end)
 end
 local rewards=CreateFrame('Frame',nil,f,'BackdropTemplate');ui.rewardsPanel=rewards
 rewards:SetSize(408,68);rewards:SetPoint('BOTTOM',0,4);rewards:SetFrameLevel(pets:GetFrameLevel());rewards:EnableMouse(true)
 rewards:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 rewards:SetBackdropBorderColor(.55,.46,.28,1)
 local claim=S.Button(rewards,'Claim all',0,0,116,function()result(L.Claim())end);ui.claim=claim;claim:ClearAllPoints();claim:SetPoint('BOTTOM',0,5)
 ui.rewardSummary={}
 local summary={
  {key='food',name='Food',icon='Interface\\Icons\\'..P.items.food.icon,help='Food waiting to claim. Your supply caps at 20; excess is discarded.'},
  {key='herbs',name='Herbs',icon='Interface\\Icons\\'..P.items.medicine.icon,help='Herbs waiting to claim. Your supply caps at 20; excess is discarded.'},
  {key='gold',name='Tokens',icon=P.tokenIcon,help='Housing tokens waiting to claim.'},
  {key='xp',name='Pet XP',icon='Interface\\Icons\\XP_Icon',help='Total XP waiting across its assigned pet recipients.'},
  {key='finds',name='Finds',icon='Interface\\Icons\\INV_Crate_01',help='Gear, crates and furnishing blueprints waiting to claim.'},
 }
 for index,data in ipairs(summary)do
  local cell=CreateFrame('Frame',nil,rewards);cell:SetSize(76,25);cell:SetPoint('TOPLEFT',10+(index-1)*78,-7);cell:EnableMouse(true)
  cell.icon=cell:CreateTexture(nil,'ARTWORK');cell.icon:SetSize(22,22);cell.icon:SetPoint('LEFT');cell.icon:SetTexture(data.icon)
  cell.count=S.Text(cell,'0',26,-5,50,'GameFontHighlightSmall');cell.count:SetTextColor(unpack(data.key=='xp'and {.8,.5,1}or {1,1,1}));cell.count:SetShadowOffset(1,-1)
  cell.key=data.key;ui.rewardSummary[index]=cell
  tip(cell,data.name,function()return tostring(cell.amount or 0)..' waiting\n'..data.help end)
 end
 function ui:RefreshRewardSummary()
  local q=L.State().pending;local xp=0;for _,n in pairs(q.xp)do xp=xp+n end
  local values={food=q.food,herbs=q.herbs,gold=q.gold,xp=xp,finds=#q.items}
  rewards:SetBackdropColor(.025,.025,.035,f.workshop:ButtonOpacity())
  for _,cell in ipairs(self.rewardSummary)do
   local n=values[cell.key];cell.amount=n
   cell.count:SetText(n>=1000000 and string.format('%.1fm',n/1000000)or n>=10000 and string.format('%.1fk',n/1000)or tostring(n))
  end
 end
 local expedition=S.Button(pets,'Expeditions',14,-316,200,function()ui.expedition:SetShown(not ui.expedition:IsShown());f:StopFlight();ui:Refresh()end)
 local exp=L.BuildExpeditionUI(f,ui,pets)
 function ui:Refresh()
  local state=L.State();self:RefreshRewardSummary()
  if menu:IsShown()then
   local pet=L.Pet(menu.petID);local selected='roam';for _,slot in pairs(state.slots)do if slot.petID==menu.petID then selected=slot.job end end
   menu.title:SetText(pet and P.PetName(pet)or 'Assign companion');menu.summary:SetText('Activity: '..L.jobNames[selected])
   for job,b in pairs(self.jobButtons)do b:Paint(job==selected);b.art:SetDesaturated(not L.Station(job))end
  end
  for _,frame in ipairs({menu,exp})do frame:SetBackdropColor(.1,.08,.05,F.db.settings.highContrast and 1 or .94)end
  for index,row in ipairs(self.rows)do
   local slot=state.slots[index];local pet=slot and L.Pet(slot.petID)
   row.name:SetText(pet and P.PetName(pet)or 'Empty housing slot');row.energy:SetValue(pet and pet.energy or 0);row.energy.text:SetText(pet and (math.floor(pet.energy or 0)..' / 100')or '')
   row.level:SetText(pet and pet.level or '');row.zzz:SetShown(pet~=nil and L.IsResting(slot))
   if row.petID~=(pet and pet.id or false)then row.petID=pet and pet.id or false;if pet then P.ShowPetPortrait(row.portrait,pet)else row.portrait:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')end end
   P.StyleSparklyPortrait(row.portrait,pet)
   row:SetBackdropColor(.025,.025,.035,f.workshop:ButtonOpacity())
   local needed=pet and (20+pet.level*5)or 1;local capped=pet and pet.level>=P.LevelCap()
   row.status:SetText(pet and (capped and 'MAX XP'or (pet.xp or 0)..' / '..needed..' XP')or 'Move pet here');row.bar:SetValue(pet and (capped and 100 or (pet.xp or 0)/needed*100)or 0)
   row.job:SetShown(pet~=nil);row.job.timer:SetShown(pet~=nil)
   if pet then
    row.job.art:SetTexture('Interface\\Icons\\'..(jobIcons[slot.job]or jobIcons.roam))
    local remaining=0;local title='Roaming'
    if slot.job=='expedition'then
     local resident=f.roamingPets and f.roamingPets[index];local boat=L.Station('expedition')
     title=not boat and 'No boat'or resident and resident.pet==pet and resident.aboard==boat.id and 'Aboard'or 'To boat'
     if state.trip then for _,id in ipairs(state.trip.ids)do if id==pet.id then remaining=(state.trip.duration or 1800)-state.trip.elapsed;title=nil end end end
    elseif slot.job~='roam'then
     if L.Station(slot.job)then remaining=L.WorkSeconds(pet,slot.job)-(slot.elapsed or 0);title=nil
     else title='No station'end
    end
    if remaining>0 and not title then remaining=math.ceil(remaining);title=string.format('%d:%02d',math.floor(remaining/60),remaining%60)end
    row.job.timer:SetText(title or 'Ready')
   end
  end
  self:RefreshExpedition()
 end
 local elapsed=0;I.HookViewportUpdate(f,function(_,dt)elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;ui:Refresh()end end)
 f:HookScript('OnHide',function()menu:Hide();exp:Hide()end);ui:Refresh()
end
function L.CampMenu(row)
 if not L.campMenu then
  local m=panel(UIParent,220,112);L.campMenu=m;m:SetFrameStrata('DIALOG')
  m.action=S.Button(m,'Move to housing',12,-12,196,function()
   local id=m.petID;m:Hide();if L.IsHoused(id)then result(L.Remove(id))else result(L.Assign(id))end
  end)
  S.Button(m,'Open housing',12,-44,196,function()m:Hide();I.Open()end)
  S.Button(m,'Cancel',12,-76,196,function()m:Hide()end)
 end
 local m=L.campMenu;m.petID=row.petID;m:ClearAllPoints();m:SetPoint('TOPLEFT',row,'TOPRIGHT',4,0);m.action:SetText(L.IsHoused(row.petID)and 'Return to stable'or 'Move to housing');m:Show()
end
local build=P.BuildUI
function P.BuildUI(...)
 local value=build(...);local w=P.window
 if w and w.collection and not rawget(w.collection,'housingBound')then
  w.collection.housingBound=true
  for _,row in ipairs(w.collection.rows)do
   local click=row:GetScript('OnClick');row:RegisterForClicks('LeftButtonUp','RightButtonUp')
   row:SetScript('OnClick',function(self,button)if button=='RightButton'and self.petID then L.CampMenu(self)elseif click then click(self,button)end end)
   row:HookScript('OnEnter',function(self)if self.petID and L.IsHoused(self.petID)then GameTooltip:AddLine('Lives on your island. Right-click to return to the stable.',.3,1,.4,true);GameTooltip:Show()end end)
  end
 end
 return value
end
local equip=P.HardMode.EquipViewed
function P.HardMode.EquipViewed()if L.IsHoused(P.viewID)then return false,'Return this pet from housing before equipping it.'end;return equip()end
local open=I.Open
function I.Open(...)
 if L.opening then return end;L.opening=true;open(...);L.opening=nil;L.BuildUI(I.ui)
end
local page=P.OpenPage
function P.OpenPage(mode,...)
 if mode=='housing'and not L.opening then return I.Open()end
 return page(mode,...)
end
