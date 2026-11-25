-- Isolated volleyball practice scene. No live-game ball, player, camera or input hooks.
local U=require(script.Parent.Util)
local Run=game:GetService("RunService")
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
 ui:note("TRAINING ONLY · isolated court. Aim Assist rotates the practice dummy, not your real character or camera.",42)
 local host=ui:row(300,"AimPractice")
 local vp=U.new("ViewportFrame",{Name="PracticeCourt",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(19,17,33),BorderSizePixel=0,Ambient=Color3.fromRGB(175,175,205),LightColor=Color3.fromRGB(245,233,255),LightDirection=Vector3.new(-1,-1,-1)},host)
 U.corner(vp,10)
 local world=U.new("WorldModel",{},vp)
 local camera=U.new("Camera",{FieldOfView=44,CFrame=CFrame.lookAt(Vector3.new(24,25,29),Vector3.new(0,0,0))},vp)
 vp.CurrentCamera=camera
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
 ui:chips({"Left","Center","Right"},function(n)
  a:set("aimPracticeZone",n);launched=false;elapsed=0;ball.Position=origin
 end,3,function() return a.s.aimPracticeZone end)
 ui:group("Aim Helper",{aimPracticeZone=true})
 local function reset()
  launched=false;elapsed=0;ball.Position=origin
 end
 local function parameters()
  local st=a.s
  local goal=zones[st.aimPracticeZone]
  local delta=goal-origin
  local range=Vector3.new(delta.X,0,delta.Z).Magnitude
  return st,goal,range,math.atan2(delta.X,-delta.Z)
 end
 ui:chips({"Hit practice ball","Reset"},function(n)
  if n=="Reset" then reset();return end
  local st,goal,range,desired=parameters()
  if st.aimPracticeAuto then yaw=desired end
  vel=shot(yaw,range);predicted,hitTime=landing(origin,vel)
  launched=true;elapsed=0;ball.Position=origin
 end,2)
 local function tick(dt)
  if page.dead or not vp.Parent then return end
  local st,goal,range,desired=parameters()
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
  marker.Size=Vector3.new(.06,st.aimPracticeSize/50,st.aimPracticeSize/50)
  marker.CFrame=CFrame.new(predicted.X,.06,predicted.Z)*CFrame.Angles(0,0,math.pi/2)
  marker.Color=color;marker.Transparency=if st.aimPracticeMarker then 1-st.aimPracticeOpacity/100 else 1
  target.CFrame=CFrame.new(goal.X,.05,goal.Z)*CFrame.Angles(0,0,math.pi/2)
  for j,dot in trail do
   local t=hitTime*j/(#trail+1)
   dot.Position=origin+vel*t-Vector3.new(0,.5*gravity*t^2,0)
   dot.Color=color;dot.Transparency=if st.aimPracticeTrail then .2 else 1
  end
  local error=(Vector3.new(predicted.X,0,predicted.Z)-Vector3.new(goal.X,0,goal.Z)).Magnitude
  status.Text=string.format("%s  /  %s\nLanding: %.1f, %.1f  ·  Target error: %.2f",if launched then (if elapsed>=hitTime then "LANDED" else "IN FLIGHT") else "READY",if st.aimPracticeAuto then "AUTO TURN" else "MANUAL",predicted.X,predicted.Z,error)
 end
 tick(0)
 page:on(Run.RenderStepped,function(dt) tick(math.min(dt,.1)) end)
end
return M