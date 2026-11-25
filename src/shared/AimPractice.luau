-- Independent volleyball practice scene; optional world display in a developer-configured place.
local U=require(script.Parent.Util)
local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local M={}
local origin=Vector3.new(0,3,9)
local gravity=18
local ballRadius=.45
local flight=1.65
local zones={Left=Vector3.new(-5,ballRadius,-8),Center=Vector3.new(0,ballRadius,-10),Right=Vector3.new(5,ballRadius,-8)}
local function landing(pos,vel)
 local height=pos.Y-ballRadius
 local t=(vel.Y+math.sqrt(math.max(0,vel.Y^2+2*gravity*height)))/gravity
 return Vector3.new(pos.X+vel.X*t,ballRadius,pos.Z+vel.Z*t),t
end
local function shot(yaw,range)
 local direction=Vector3.new(math.sin(yaw),0,-math.cos(yaw))
 local vy=(ballRadius-origin.Y+.5*gravity*flight^2)/flight
 return direction*(range/flight)+Vector3.new(0,vy,0)
end
local function angleDiff(a,b) return math.atan2(math.sin(b-a),math.cos(b-a)) end
local function part(parent,name,size,pos,color,shape)
 return U.new("Part",{Name=name,Size=size,CFrame=CFrame.new(pos),Color=color,Material=Enum.Material.SmoothPlastic,Shape=shape or Enum.PartType.Block,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false},parent)
end
function M.mount(ui,a)
 local page=ui.page
 ui:note("VOLLEYBALL PRACTICE · Preview or show your own practice court in the world. Auto turn controls the practice dummy.",42)
 local host=ui:row(300,"AimPractice")
 local vp=U.new("ViewportFrame",{Name="PracticeCourt",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(19,17,33),BorderSizePixel=0,Ambient=Color3.fromRGB(175,175,205),LightColor=Color3.fromRGB(245,233,255),LightDirection=Vector3.new(-1,-1,-1)},host)
 U.corner(vp,10)
 local world=U.new("WorldModel",{},vp)
 local camera=U.new("Camera",{FieldOfView=44,CFrame=CFrame.lookAt(Vector3.new(24,25,29),Vector3.new(0,0,0))},vp)
 vp.CurrentCamera=camera
 local function fitCamera()
  local size=vp.AbsoluteSize
  if size.X<2 or size.Y<2 then return end
  local halfV=math.rad(camera.FieldOfView*.5)
  local halfH=math.atan(math.tan(halfV)*size.X/size.Y)
  local distance=17.5/math.sin(math.min(halfV,halfH))*1.06
  local focus=Vector3.new(0,2,0)
  camera.CFrame=CFrame.lookAt(focus+Vector3.new(24,23,29).Unit*distance,focus)
 end
 page:on(vp:GetPropertyChangedSignal("AbsoluteSize"),fitCamera)
 fitCamera()
 local court=part(world,"Court",Vector3.new(16,.2,28),Vector3.new(0,-.1,0),Color3.fromRGB(61,48,90))
 local white=Color3.fromRGB(205,193,232)
 for _,x in {-7.8,7.8} do part(world,"Sideline",Vector3.new(.08,.04,28),Vector3.new(x,.03,0),white) end
 for _,z in {-13.9,0,13.9} do part(world,"CourtLine",Vector3.new(16,.04,.08),Vector3.new(0,.03,z),white) end
 for _,x in {-8.1,8.1} do part(world,"NetPost",Vector3.new(.16,3.7,.16),Vector3.new(x,1.85,0),white) end
 local net=part(world,"Net",Vector3.new(16,1.1,.05),Vector3.new(0,2.9,0),white);net.Transparency=.65
 local top=part(world,"NetTop",Vector3.new(16,.09,.12),Vector3.new(0,3.45,0),white)
 local dummy=U.new("Model",{Name="PracticeDummy"},world)
 local base=part(dummy,"Body",Vector3.new(1.05,1.5,.65),Vector3.new(0,1.15,9),Color3.fromRGB(165,128,244))
 local head=part(dummy,"Head",Vector3.new(.78,.78,.78),Vector3.new(0,2.3,9),Color3.fromRGB(228,213,255),Enum.PartType.Ball)
 local arrow=part(dummy,"Facing",Vector3.new(.22,.14,1.8),Vector3.new(0,.3,7.7),Color3.fromRGB(255,211,126))
 arrow.Material=Enum.Material.Neon
 dummy.PrimaryPart=base
 local ball=part(world,"PracticeBall",Vector3.one*(ballRadius*2),origin,Color3.fromRGB(255,232,156),Enum.PartType.Ball)
 local ballHalo=part(world,"BallFollowMarker",Vector3.new(.035,1.55,1.55),origin,Color3.fromRGB(130,225,255),Enum.PartType.Cylinder)
 ballHalo.Material=Enum.Material.Neon
 local marker=part(world,"PredictedLanding",Vector3.new(.06,1.6,1.6),Vector3.zero,Color3.fromRGB(130,225,255),Enum.PartType.Cylinder)
 marker.Material=Enum.Material.Neon
 local target=part(world,"SelectedTarget",Vector3.new(.04,.7,.7),Vector3.zero,Color3.fromRGB(255,205,117),Enum.PartType.Cylinder)
 target.Material=Enum.Material.Neon
 local trail={}
 for j=1,24 do
  local dot=part(world,"TrajectoryPoint",Vector3.one*.13,origin,Color3.fromRGB(191,155,255),Enum.PartType.Ball)
  dot.Material=Enum.Material.Neon;trail[j]=dot
 end
 local yaw=0
 local launched=false
 local elapsed=0
 local vel=Vector3.zero
 local hitTime=0
 local predicted=origin
 local status=ui:note("",40)
 local lastAimKey=nil
 local worldModel=nil
 local worldAnchor=nil
 local mirrors={}
 local worldStatus=nil
 local follow=true
 local liveEnabled=false
 local liveMarks={}
 local liveStatus=nil
 local liveTag="AETHERPracticeBall"
 local function removeLive(obj)
  local visual=liveMarks[obj]
  if visual then visual:Destroy();liveMarks[obj]=nil end
 end
 local function clearLive()
  for obj,visual in liveMarks do visual:Destroy() end
  table.clear(liveMarks)
 end
 local function updateLive()
  if not liveEnabled then return end
  local allow=Run:IsStudio() or workspace:GetAttribute("AETHERPracticeEnabled")==true
  if not allow then
   clearLive()
   liveStatus.Text="Enable AETHERPracticeEnabled on Workspace in your own place."
   return
  end
  for obj,visual in liveMarks do
   if not obj:IsDescendantOf(workspace) or not Collection:HasTag(obj,liveTag) or visual.Parent~=obj then removeLive(obj) end
  end
  local count=0
  for _,obj in Collection:GetTagged(liveTag) do
   if obj:IsA("BasePart") and obj:IsDescendantOf(workspace) then
    local visual=liveMarks[obj]
    if not visual then
     visual=U.new("Highlight",{Name="AETHERBallFollow",Adornee=obj,DepthMode=Enum.HighlightDepthMode.Occluded,FillTransparency=.83,OutlineTransparency=.05},obj)
     liveMarks[obj]=visual
    end
    visual.Enabled=follow
    visual.OutlineColor=U.hex(a.s.aimPracticeColor)
    visual.FillColor=visual.OutlineColor
    count+=1
   end
  end
  liveStatus.Text=if count>0 then "Ball bound: "..tostring(count) else "Waiting for a BasePart tagged AETHERPracticeBall."
 end
 page:add(clearLive)
 page:on(Collection:GetInstanceAddedSignal(liveTag),function() if liveEnabled then updateLive() end end)
 page:on(Collection:GetInstanceRemovedSignal(liveTag),function(obj) removeLive(obj);if liveEnabled then updateLive() end end)
 local function hideWorld()
  if worldModel then worldModel:Destroy() end
  worldModel=nil;worldAnchor=nil;table.clear(mirrors)
 end
 page:add(hideWorld)
 local function showWorld()
  hideWorld()
  local anchor=workspace:FindFirstChild("AETHERPracticeOrigin")
  if not anchor or not anchor:IsA("BasePart") or (not Run:IsStudio() and anchor:GetAttribute("AETHERPracticeEnabled")~=true) then
   worldStatus.Text="Create AETHERPracticeOrigin in your place. In a published place enable its AETHERPracticeEnabled attribute."
   return
  end
  worldAnchor=anchor
  worldModel=U.new("Model",{Name="AETHERPracticeCourt"},workspace)
  for _,source in world:GetDescendants() do
   if source:IsA("BasePart") then
    local clone=source:Clone()
    clone.CFrame=anchor.CFrame*source.CFrame
    clone.Parent=worldModel
    mirrors[source]=clone
   end
  end
  worldStatus.Text="World court visible at AETHERPracticeOrigin."
 end
 ui:chips({"Left","Center","Right"},function(n)
  a:set("aimPracticeZone",n);launched=false;elapsed=0;ball.Position=origin
 end,3,function() return a.s.aimPracticeZone end)
 local function reset()
  launched=false;elapsed=0;ball.Position=origin
 end
 local function parameters()
  local st=a.s
  local goal=zones[st.aimPracticeZone] or zones.Center
  local delta=goal-origin
  local range=Vector3.new(delta.X,0,delta.Z).Magnitude
  return st,goal,range,math.atan2(delta.X,-delta.Z)
 end
 local function aimKey(st)
  return tostring(st.aimPracticeZone)..":"..tostring(st.aimPracticeAuto)..":"..(if st.aimPracticeAuto then "auto" else tostring(st.aimPracticeAngle))
 end
 ui:chips({"Hit practice ball","Reset"},function(n)
  if n=="Reset" then reset();return end
  local st,goal,range,desired=parameters()
  lastAimKey=aimKey(st)
  yaw=if st.aimPracticeAuto then desired else math.rad(st.aimPracticeAngle)
  vel=shot(yaw,range);predicted,hitTime=landing(origin,vel)
  launched=true;elapsed=0;ball.Position=origin
 end,2)
 worldStatus=ui:note("Optional: place a BasePart named AETHERPracticeOrigin in your own Roblox place.",44)
 ui:chips({"Show world court","Hide world court"},function(n)
  if n=="Show world court" then showWorld() else hideWorld();worldStatus.Text="World court hidden." end
 end,2)
 liveStatus=ui:note("Ball Follow · follows the practice ball. For your own game tag its ball AETHERPracticeBall.",44)
 ui:chips({"Ball follow ON/OFF","Bind tagged ball","Unbind ball"},function(n)
  if n=="Ball follow ON/OFF" then follow=not follow
  elseif n=="Bind tagged ball" then liveEnabled=true
  else liveEnabled=false;clearLive() end
  if liveEnabled then updateLive() else liveStatus.Text=if follow then "Practice ball marker ON." else "Practice ball marker OFF." end
 end,1)
 ui:group("Aim Helper",{aimPracticeZone=true})
 local liveClock=0
 local function tick(dt)
  if page.dead or not vp.Parent then return end
  local st,goal,range,desired=parameters()
  local key=aimKey(st)
  if lastAimKey~=key then reset();lastAimKey=key end
  if not launched then
   if st.aimPracticeAuto then yaw+=angleDiff(yaw,desired)*(1-math.exp(-dt*st.aimPracticeTurn/10))
   else yaw=math.rad(st.aimPracticeAngle) end
   vel=shot(yaw,range);predicted,hitTime=landing(origin,vel)
  end
  dummy:PivotTo(CFrame.lookAt(Vector3.new(0,1.15,9),Vector3.new(math.sin(yaw),1.15,9-math.cos(yaw))))
  if launched then
   elapsed=math.min(elapsed+dt*st.aimPracticeSpeed/100,hitTime)
   ball.Position=origin+vel*elapsed-Vector3.new(0,.5*gravity*elapsed^2,0)
  else ball.Position=origin end
  local color=U.hex(st.aimPracticeColor)
  local followSize=math.max(ball.Size.X,ball.Size.Y,ball.Size.Z)+.5
  ballHalo.Size=Vector3.new(.035,followSize,followSize)
  ballHalo.CFrame=CFrame.new(ball.Position-Vector3.new(0,ballRadius*.65,0))*CFrame.Angles(0,0,math.pi/2)
  ballHalo.Color=color
  ballHalo.Transparency=if follow then .16 else 1
  liveClock+=dt
  if liveEnabled and liveClock>=.25 then liveClock=0;updateLive() end
  marker.Size=Vector3.new(.06,st.aimPracticeSize/50,st.aimPracticeSize/50)
  marker.CFrame=CFrame.new(predicted.X,.06,predicted.Z)*CFrame.Angles(0,0,math.pi/2)
  marker.Color=color;marker.Transparency=if st.aimPracticeMarker then 1-st.aimPracticeOpacity/100 else 1
  target.CFrame=CFrame.new(goal.X,.12,goal.Z)*CFrame.Angles(0,0,math.pi/2)
  for j,dot in trail do
   local t=hitTime*j/(#trail+1)
   dot.Position=origin+vel*t-Vector3.new(0,.5*gravity*t^2,0)
   dot.Color=color;dot.Transparency=if st.aimPracticeTrail then .2 else 1
  end
  if worldModel then
   if not worldAnchor or not worldAnchor:IsDescendantOf(workspace) then
    hideWorld();worldStatus.Text="Practice origin removed; world court hidden."
   else
    local transform=worldAnchor.CFrame
    for source,clone in mirrors do
     clone.CFrame=transform*source.CFrame
     clone.Size=source.Size;clone.Color=source.Color;clone.Transparency=source.Transparency
    end
   end
  end
  local error=(Vector3.new(predicted.X,0,predicted.Z)-Vector3.new(goal.X,0,goal.Z)).Magnitude
  status.Text=string.format("%s  /  %s\nLanding: %.1f, %.1f  ·  Target error: %.2f",if launched then (if elapsed>=hitTime then "LANDED" else "IN FLIGHT") else "READY",if st.aimPracticeAuto then "AUTO TURN" else "MANUAL",predicted.X,predicted.Z,error)
 end
 tick(0)
 page:on(Run.RenderStepped,function(dt) tick(math.min(dt,.1)) end)
end
return M