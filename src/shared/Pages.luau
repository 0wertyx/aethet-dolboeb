local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local MotionPacks=require(script.Parent.MotionPacks);local Symbol=require(script.Parent.Symbol);local Hud=require(script.Parent.Hud);local Avatar=require(script.Parent.Avatar);local Cues=require(script.Parent.Cues);local Http=game:GetService("HttpService")
local WalkMotion=require(script.Parent.WalkMotion)
local PreviewProps=require(script.Parent.PreviewProps)
local MotionStudio=require(script.Parent.MotionStudio)
local Input=game:GetService("UserInputService")
local E={}
local function names(t) local a=U.keys(t);return a end
local function preset(ui,a,group)
 local p=S.presets[group];if p then ui:title("PRESETS");ui:chips(names(p),function(n) a:patch(p[n]);a:log("Preset",n) end,3) end
end
local function preview(ui,a,showPanels)
 local f=ui:row(if showPanels then 210 else 149,"LivePreview");f.ClipsDescendants=true;f.BackgroundTransparency=0;U.gradient(f,Color3.fromRGB(105,87,145),Color3.fromRGB(49,46,94),36)
 local h=Hud.new(ui.page,f,true,function(tab) ui:open(tab) end,function(i,k,n,v,source) a:drag(i,k,n,v,source) end,nil,showPanels);a.preview={hud=h}
 if showPanels then
  h:layoutPreview(a.s)
  ui.page:on(f:GetPropertyChangedSignal("AbsoluteSize"),function() h:layoutPreview(a.s) end)
  ui:watch(function() h:layoutPreview(a.s) end)
 end
end
local function avatarPreview(ui,a,worldMode)
 local f=ui:row(if worldMode then 300 else 230,"RigPreview")
 local view=U.new("ViewportFrame",{Size=UDim2.fromScale(1,1),Active=true,BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(21,19,36),Ambient=Color3.fromRGB(155,145,175),LightColor=Color3.fromRGB(246,222,255),LightDirection=Vector3.new(-1,-1,-.6)},f)
 U.corner(view,10)
 local w=U.new("WorldModel",{},view)
 local cam=U.new("Camera",{FieldOfView=34},view);view.CurrentCamera=cam
 local player=game:GetService("Players").LocalPlayer
 local page=ui.page
 local avatar=Avatar.new(w,true)
 local previewState=if worldMode and a.preview then a.preview else {}
 previewState.avatar=avatar;previewState.rig=nil;a.preview=previewState
 local label=U.label(view,"Loading avatar...",12)
 label.TextXAlignment=Enum.TextXAlignment.Center
 local generation=0
 local characterScope=nil
 local motion=WalkMotion.new()
 local props=PreviewProps.new(w)
 local showProps=true
 local rootPart=nil
 local joints={}
 local motors={}
 local center=Vector3.zero
 local radius=1
 local yaw,pitch,zoom=.13,.08,1
 local targetYaw,targetPitch,targetZoom=yaw,pitch,zoom
 local dragging=false
 local hovered=false
 local lastMouse=nil
 local sc=ui.sc
 local middle=Enum.UserInputType.MouseButton3
 local full=false
 local paused=false
 local speed=1
 local demoState="Walk"
 local demoStrength=100
 local demoOrigin=100
 local previewStatus=nil
 local stage=nil
 local floorOffset=2
 local centerOffset=Vector3.zero
 local moving=false
 local velocity=Vector3.zero
 local verticalSpeed=0
 local grounded=true
 local jumpRequested=false
 local startPosition=Vector3.zero
 local orbitButton=nil
 local shiftLock=false
 local sceneParams=RaycastParams.new()
 sceneParams.FilterType=Enum.RaycastFilterType.Include
 local fullGui,fullHost,fullStatus,fullPause,fullSpeed=nil,nil,nil,nil,nil
 local actionName="AETHER_Preview_"..Http:GenerateGUID(false)
 local CAS=game:GetService("ContextActionService")
 local keys={}
 local function endOrbit()
  dragging=false;lastMouse=nil;orbitButton=nil
  if sc.Parent then sc.ScrollingEnabled=not hovered end
 end
 local function applyCamera()
  if page.dead then return end
  local aspect=math.max(.1,view.AbsoluteSize.X/math.max(1,view.AbsoluteSize.Y))
  local half=math.rad(cam.FieldOfView*.5)
  local angle=math.min(half,math.atan(math.tan(half)*aspect))
  local distance=if worldMode and full then 12*zoom else radius/math.sin(angle)*(if worldMode then 1.12 else 1.48)*zoom
  local offset=Vector3.new(math.sin(yaw)*math.cos(pitch),math.sin(pitch),-math.cos(yaw)*math.cos(pitch))
  local pos=center+offset*distance
  if worldMode and full and stage then
   sceneParams.FilterDescendantsInstances={stage}
   local hit=w:Raycast(center,pos-center,sceneParams)
   if hit then pos=center+offset*math.max(.6,hit.Distance-.4) end
  end
  cam.CFrame=CFrame.lookAt(pos,center)
 end
 local function fit()
  local rig=previewState.rig
  if page.dead or not rig or not rig.Parent then return end
  local cf,size=rig:GetBoundingBox()
  center=cf.Position;radius=math.max(.5,size.Magnitude*.5)
  if rootPart then
   centerOffset=center-rootPart.Position
   startPosition=rootPart.Position
   floorOffset=math.max(.5,rootPart.Position.Y-(cf.Position.Y-size.Y*.5))
  end
  applyCamera()
 end
 local function stageStatus(message)
  if fullStatus then fullStatus.Text=message end
  if not page.dead then ui:message(message) end
 end
 local function sceneClear()
  if stage then stage:Destroy();stage=nil end
 end
 local function sceneFloor()
  local ground=U.new("Part",{Name="PreviewFloor",Size=Vector3.new(110,.25,110),CFrame=CFrame.new(startPosition-Vector3.new(0,floorOffset+.125,0)),Anchored=true,CanCollide=false,CanTouch=false,CanQuery=true,Color=Color3.fromRGB(52,44,74),Material=Enum.Material.SmoothPlastic},stage)
  return ground
 end
 local function resetScene()
  sceneClear()
  stage=U.new("Folder",{Name="PreviewEnvironment"},w)
  sceneFloor()
  stageStatus("Demo stage · capture visible scenery to preview your environment")
 end
 local function captureScene()
  if not worldMode or not rootPart or not rootPart.Parent then return end
  local character=player.Character
  local sourceRoot=character and character:FindFirstChild("HumanoidRootPart")
  local sourceCamera=workspace.CurrentCamera
  if not sourceRoot or not sourceCamera then stageStatus("Scene unavailable");return end
  sceneClear()
  stage=U.new("Folder",{Name="PreviewEnvironment"},w)
  local origin=sourceRoot.CFrame
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={character}
  local seen={}
  local count=0
  local size=sourceCamera.ViewportSize
  -- Sample only currently visible surfaces; never enumerate the whole map,
  -- copy other characters, scripts, remotes or hidden server objects.
  for y=0,13 do
   for x=0,21 do
    local ray=sourceCamera:ViewportPointToRay((x+.5)*size.X/22,(y+.5)*size.Y/14)
    local hit=workspace:Raycast(ray.Origin,ray.Direction*85,params)
    local source=hit and hit.Instance
    if source and source:IsA("BasePart") and not source:IsA("Terrain") and source.Anchored and source.Transparency<.98 and not seen[source] and count<180 then
     seen[source]=true
     local parent=source.Parent
     local characterPart=false
     while parent and parent~=workspace do
      if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then characterPart=true;break end
      parent=parent.Parent
     end
     if not characterPart then
      local ok,clone=pcall(function() return source:Clone() end)
      if ok and clone then
       for _,child in clone:GetDescendants() do
        if child.Parent and not (child:IsA("DataModelMesh") or child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance")) then child:Destroy() end
       end
       clone.Name="SceneSurface"
       clone.Anchored=true;clone.CanCollide=false;clone.CanTouch=false;clone.CanQuery=true
       clone.LocalTransparencyModifier=0
       clone.CFrame=CFrame.new(startPosition)*origin:ToObjectSpace(source.CFrame)
       clone.Parent=stage;count+=1
      end
     end
    end
   end
  end
  if count==0 then sceneFloor() end
  stageStatus(tostring(count).." visible surfaces · static local snapshot")
 end
 local function prepareRig(rig)
  motion:bind(nil);rootPart=rig:FindFirstChild("HumanoidRootPart")
  table.clear(joints);table.clear(motors)
  if not rootPart then return end
  -- Anchored viewport rigs need explicit forward kinematics. Cache joints
  -- once, including accessory welds, and keep the actual character untouched.
  local adjacency={}
  local function attach(part,edge)
   adjacency[part]=adjacency[part] or {}
   table.insert(adjacency[part],edge)
  end
  for _,joint in rig:GetDescendants() do
   if joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("ManualWeld") then
    local p0,p1=joint.Part0,joint.Part1
    if p0 and p1 and p0:IsDescendantOf(rig) and p1:IsDescendantOf(rig) then
     local edge={joint=joint,p0=p0,p1=p1,motor=joint:IsA("Motor6D")}
     attach(p0,edge);attach(p1,edge)
     if edge.motor then table.insert(motors,joint) end
    end
   end
  end
  local queue={rootPart};local seen={[rootPart]=true};local index=1
  while index<=#queue do
   local part=queue[index];index+=1
   for _,edge in adjacency[part] or {} do
    local forward=edge.p0==part
    local other=if forward then edge.p1 else edge.p0
    if not seen[other] then
     seen[other]=true;table.insert(queue,other)
     table.insert(joints,{edge=edge,forward=forward})
    end
   end
  end
 end
 previewState.pose=function(settings,dt)
  local rig=previewState.rig
  if page.dead or not ui.opened or not rootPart or not rootPart.Parent or not rig then return end
  if worldMode then
   if paused then return end
   dt=math.min(dt,.05)*speed
   previewState.effectTime=(previewState.effectTime or os.clock())+dt
   moving=false
   if full and ui.opened then
    local x=(if keys[Enum.KeyCode.D] or keys[Enum.KeyCode.Right] then 1 else 0)-(if keys[Enum.KeyCode.A] or keys[Enum.KeyCode.Left] then 1 else 0)
    local z=(if keys[Enum.KeyCode.W] or keys[Enum.KeyCode.Up] then 1 else 0)-(if keys[Enum.KeyCode.S] or keys[Enum.KeyCode.Down] then 1 else 0)
    local forward=Vector3.new(-math.sin(yaw),0,math.cos(yaw))
    local right=forward:Cross(Vector3.yAxis)
    local dir=forward*z+right*x
    if dir.Magnitude>1 then dir=dir.Unit end
    velocity=velocity:Lerp(dir*16,1-math.exp(-dt*14))
    local pos=rootPart.Position
    local delta=velocity*dt
    sceneParams.FilterDescendantsInstances=if stage then {stage} else {}
    if delta.Magnitude>.001 then
     local wall=w:Raycast(pos,delta+delta.Unit*.65,sceneParams)
     if wall and math.abs(wall.Normal.Y)<.55 then
      delta-=wall.Normal*delta:Dot(wall.Normal)
      if delta.Magnitude>.001 and w:Raycast(pos,delta+delta.Unit*.4,sceneParams) then delta=Vector3.zero end
     end
    end
    if jumpRequested and grounded then verticalSpeed=36;grounded=false end
    jumpRequested=false
    verticalSpeed-=workspace.Gravity*dt
    local nextPos=pos+delta+Vector3.new(0,verticalSpeed*dt,0)
    local ground=w:Raycast(nextPos+Vector3.new(0,1.8,0),Vector3.new(0,-(floorOffset+4+math.abs(verticalSpeed*dt)),0),sceneParams)
    if verticalSpeed<=0 and ground and ground.Normal.Y>.5 and nextPos.Y<=ground.Position.Y+floorOffset then
     nextPos=Vector3.new(nextPos.X,ground.Position.Y+floorOffset,nextPos.Z);verticalSpeed=0;grounded=true
    else grounded=false end
    if nextPos.Y<startPosition.Y-40 or (nextPos-startPosition).Magnitude>80 then
     nextPos=startPosition;velocity=Vector3.zero;verticalSpeed=0;grounded=true
    end
    moving=velocity.Magnitude>.35
    local facing=if shiftLock then forward elseif dir.Magnitude>.1 then dir else rootPart.CFrame.LookVector
    rootPart.CFrame=rootPart.CFrame:Lerp(CFrame.lookAt(nextPos,nextPos+facing),1-math.exp(-dt*20))
    rootPart.CFrame=CFrame.new(nextPos)*rootPart.CFrame.Rotation
   end
   center=rootPart.Position+centerOffset;applyCamera()
  end
  if not worldMode and paused then return end
  for _,motor in motors do motor.Transform=CFrame.identity end
  if (ui.tab=="Character" or worldMode) and not settings.reduce then
   local demo=table.clone(settings);demo.walkAnimation=true
   local virtual
   if worldMode then
    virtual={movement=math.clamp(velocity.Magnitude/16,0,1),grounded=grounded,jumping=verticalSpeed>0,fullPose=true}
   else
    dt=math.min(dt,.05)*speed
    demo.walkIntensity=demoStrength
    local state=if demoState=="Jump" then Enum.HumanoidStateType.Jumping
     elseif demoState=="Fall" then Enum.HumanoidStateType.Freefall
     elseif demoState=="Swim" then Enum.HumanoidStateType.Swimming
     elseif demoState=="Climb" then Enum.HumanoidStateType.Climbing
     else Enum.HumanoidStateType.Running
    local airborne=demoState=="Jump" or demoState=="Fall"
    virtual={movement=if demoState=="Idle" then 0 elseif demoState=="Walk" then .78 else 1,grounded=not airborne,jumping=demoState=="Jump",state=state,speed=if demoState=="Run" then 24 else 16,fullPose=true,originStrength=demoOrigin,loopAir=true}
   end
   virtual.props=showProps
   motion:step(rig,demo,dt,virtual)
  else
   motion:bind(nil)
  end
  for _,link in joints do
   local e=link.edge;local j=e.joint
   if j.Parent and e.p0.Parent and e.p1.Parent then
    local offset=j.C0*(if e.motor then j.Transform else CFrame.identity)*j.C1:Inverse()
    if link.forward then e.p1.CFrame=e.p0.CFrame*offset else e.p0.CFrame=e.p1.CFrame*offset:Inverse() end
   end
  end
  if showProps and not settings.reduce and motion.signatureActive then props:update(rig,settings.walkStyle,motion.phase,motion.previewState) else props:clear() end
 end
 local function refresh(char)
  generation+=1
  local current=generation
  task.delay(.18,function()
   if page.dead or current~=generation or not char or char~=player.Character then return end
   if not char:FindFirstChildOfClass("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then return end
   local previous=char.Archivable
   local ok,rig=pcall(function() char.Archivable=true;return char:Clone() end)
   char.Archivable=previous
   if not ok or not rig then
    label.Text="Avatar unavailable";label.Visible=not previewState.rig
    return
   end
   for _,obj in rig:GetDescendants() do
    if not obj.Parent then continue end
    if obj:IsA("LuaSourceContainer") or obj:IsA("Animator") or obj:IsA("AnimationController") or obj:IsA("Tool") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("Sound") then
     obj:Destroy()
    elseif obj:IsA("BasePart") then
     obj.Anchored=true;obj.CanCollide=false;obj.CanTouch=false;obj.CanQuery=false;obj.LocalTransparencyModifier=0
     if obj.Name=="HumanoidRootPart" then obj.Transparency=1 end
    end
   end
   local humanoid=rig:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
   local root=rig:FindFirstChild("HumanoidRootPart")
   if root then rig:PivotTo(root.CFrame:ToObjectSpace(rig:GetPivot())) end
   rig.Name="LocalAvatarPreview"
   avatar:clear()
   if previewState.rig then previewState.rig:Destroy() end
   rig.Parent=w;previewState.rig=rig;prepareRig(rig);fit();previewState.pose(a.s,0);label.Visible=false
   if worldMode then resetScene() end
  end)
 end
 local function bind(char)
  if characterScope then characterScope:clear() end
  characterScope=U.scope()
  generation+=1;avatar:clear();props:clear();motion:bind(nil);rootPart=nil;table.clear(joints);table.clear(motors)
  if previewState.rig then previewState.rig:Destroy();previewState.rig=nil end
  label.Text="Loading avatar...";label.Visible=true
  if not char then return end
  local function appearanceChanged(obj)
   if obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or obj:IsA("BasePart") or obj:IsA("Humanoid") or obj:IsA("Decal") or obj:IsA("CharacterMesh") or obj:IsA("SurfaceAppearance") then refresh(char) end
  end
  characterScope:on(char.DescendantAdded,appearanceChanged)
  characterScope:on(char.DescendantRemoving,appearanceChanged)
  refresh(char)
 end
 local function closeFull()
  if not full then return end
  full=false;velocity=Vector3.zero;shiftLock=false;jumpRequested=false
  CAS:UnbindAction(actionName);table.clear(keys)
  hovered=false;endOrbit()
  if not page.dead and f.Parent then view.Parent=f end
  if fullGui and fullGui.Parent then fullGui.Enabled=false end
  applyCamera()
 end
 local function togglePause()
  paused=not paused
  if fullPause then fullPause.Text=if paused then "Resume" else "Pause" end
  stageStatus(if paused then "Preview paused" else "Preview running")
 end
 local function cycleSpeed()
  speed=if speed==.5 then 1 elseif speed==1 then 2 else .5
  if fullSpeed then fullSpeed.Text=tostring(speed).."x" end
  stageStatus("Playback speed "..tostring(speed).."x")
 end
 local function openFull()
  if full or page.dead then return end
  if not fullGui then
   fullGui=page:add(U.new("ScreenGui",{Name="AETHER_WorldPreview",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100002,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=false},player:WaitForChild("PlayerGui")))
   local shell=U.frame(fullGui,"WorldPreview",nil,nil,Color3.fromRGB(17,14,28),0)
   shell.Active=true
   local bar=U.frame(shell,"Toolbar",UDim2.fromOffset(12,12),UDim2.new(1,-24,0,46),Color3.fromRGB(41,32,61),0);U.corner(bar,12)
   local title=U.label(bar,"AETHER / WORLD PREVIEW",16,UDim2.fromOffset(14,0),UDim2.new(1,-410,1,0))
   local function tool(text,offset,width,fn)
    local b=U.button(bar,text);b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-offset,.5,0);b.Size=UDim2.fromOffset(width,32)
    page:on(b.Activated,fn);return b
   end
   tool("Exit full screen",8,112,closeFull)
   fullSpeed=tool(tostring(speed).."x",128,54,cycleSpeed)
   fullPause=tool(if paused then "Resume" else "Pause",190,68,togglePause)
   tool("Capture",266,76,captureScene)
   fullHost=U.frame(shell,"Viewport",UDim2.fromOffset(12,68),UDim2.new(1,-24,1,-114),nil,1)
   fullStatus=U.label(shell,"WASD / arrows · Space jump · RMB camera · Shift lock · scroll zoom",13,UDim2.new(0,16,1,-42),UDim2.new(1,-32,0,30))
  end
  full=true;fullGui.Enabled=true;view.Parent=fullHost
  if worldMode then
   CAS:BindActionAtPriority(actionName,function(_,state,input)
    if state==Enum.UserInputState.Begin then
     keys[input.KeyCode]=true
     if input.KeyCode==Enum.KeyCode.Space then jumpRequested=true end
     if input.KeyCode==Enum.KeyCode.LeftAlt then shiftLock=not shiftLock end
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then keys[input.KeyCode]=nil end
    return Enum.ContextActionResult.Sink
   end,false,Enum.ContextActionPriority.High.Value+100,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Space,Enum.KeyCode.LeftShift)
  end
  hovered=false;endOrbit();applyCamera()
 end
 page:on(view:GetPropertyChangedSignal("AbsoluteSize"),applyCamera)
 page:on(view.MouseEnter,function() if ui.opened then hovered=true;sc.ScrollingEnabled=false end end)
 page:on(view.MouseLeave,function() hovered=false;if not dragging then sc.ScrollingEnabled=true end end)
 -- Use global input rather than ViewportFrame.InputBegan, which can be
 -- swallowed by the surrounding ScrollingFrame or another GUI layer.
 page:on(Input.InputBegan,function(input)
  if (input.UserInputType==middle or (full and input.UserInputType==Enum.UserInputType.MouseButton2)) and hovered and ui.opened then
   dragging=true;orbitButton=input.UserInputType;lastMouse=Input:GetMouseLocation();sc.ScrollingEnabled=false
  end
 end)
 page:on(Input.InputChanged,function(input)
  if hovered and ui.opened and input.UserInputType==Enum.UserInputType.MouseWheel then
   targetZoom=math.clamp(targetZoom*math.exp(-input.Position.Z*.15),.35,2.6)
  end
 end)
 page:on(Input.InputEnded,function(input)
  if input.UserInputType==orbitButton then endOrbit() end
 end)
 page:on(Input.WindowFocusReleased,function() table.clear(keys);hovered=false;endOrbit() end)
 page:on(game:GetService("RunService").RenderStepped,function(dt)
  if not ui.opened then
   if full then closeFull() end
   if hovered or dragging then hovered=false;endOrbit() end
   return
  end
  if dragging then
   if not orbitButton or not Input:IsMouseButtonPressed(orbitButton) then
    endOrbit()
   else
    local mouse=Input:GetMouseLocation()
    local delta=mouse-(lastMouse or mouse)
    lastMouse=mouse
    targetYaw-=delta.X*.009
    targetPitch=math.clamp(targetPitch+delta.Y*.007,-1.15,1.15)
   end
  end
  local alpha=if a.s.reduce then 1 else 1-math.exp(-math.min(dt,.1)*18)
  if math.abs(targetYaw-yaw)+math.abs(targetPitch-pitch)+math.abs(targetZoom-zoom)>.0001 then
   yaw+=(targetYaw-yaw)*alpha
   pitch+=(targetPitch-pitch)*alpha
   zoom+=(targetZoom-zoom)*alpha
   applyCamera()
  end
 end)
 ui:note(if worldMode then "Capture visible scene · Full screen: WASD, Space, RMB camera, Shift lock" else "Hold middle mouse to orbit · Scroll to zoom · Full-body preview (independent of game animation)",42)
 if not worldMode and ui.tab=="Character" then
  ui:title("FULL-BODY ANIMATION PREVIEW")
  ui:note("Preview plays the selected style even when Custom walking animation is off. Only the local GUI rig is animated here.",44)
  ui:chips({"Idle","Walk","Run","Jump","Fall","Swim","Climb"},function(n)
   demoState=n;motion:bind(nil);ui:sync()
  end,4,function() return demoState end)
  ui:chips({"0.5x","1x","1.5x","2x"},function(n) speed=tonumber(n:sub(1,-2)) or 1;ui:sync() end,4,function() return tostring(speed).."x" end)
  ui:chips({"50%","75%","100%"},function(n) demoStrength=tonumber(n:sub(1,-2)) or 100;ui:sync() end,3,function() return tostring(demoStrength).."%" end)
  ui:chips({"Props on","Props off"},function(n) showProps=n=="Props on";if not showProps then props:clear() end;ui:sync() end,2,function() return if showProps then "Props on" else "Props off" end)
  ui:title("R6 · LIMB ORIGIN MOTION")
  ui:note("Animate shoulder and hip positions as well as rotation. Compare the original rotation-only preview with the stylized offsets.",42)
  ui:chips({"Origin off","Origin 50%","Origin 100%"},function(n)
   demoOrigin=if n=="Origin off" then 0 elseif n=="Origin 50%" then 50 else 100
   ui:sync()
  end,3,function() return if demoOrigin==0 then "Origin off" else "Origin "..tostring(demoOrigin).."%" end)
  ui:chips({"Pause","Play"},function(n) paused=n=="Pause";ui:sync() end,2,function() return if paused then "Pause" else "Play" end)
  previewStatus=ui:note("",28)
  ui:watch(function()
   previewStatus.Text=(a.s.walkStyle or "Natural").." / "..demoState.." · "..tostring(demoStrength).."% · Origin "..tostring(demoOrigin).."%"
  end)
 end
 if worldMode then
  ui:chips({"Capture visible scene","Full screen"},function(n) if n=="Full screen" then openFull() else captureScene() end end,2)
  ui:chips({"Demo stage","Pause / resume","Playback speed"},function(n) if n=="Demo stage" then resetScene() elseif n=="Pause / resume" then togglePause() else cycleSpeed() end end,3)
 end
 ui:chips({"Reset view"},function()
  targetYaw=yaw+((.13-yaw+math.pi)%(2*math.pi)-math.pi)
  targetPitch,targetZoom=.08,1
 end,1)
 page:on(player.CharacterAdded,bind)
 page:on(player.CharacterRemoving,function() bind(nil) end)
 page:on(player.CharacterAppearanceLoaded,function(char) if char==player.Character then refresh(char) end end)
 page:add(function()
  generation+=1
  closeFull()
  CAS:UnbindAction(actionName)
  hovered=false;endOrbit()
  if characterScope then characterScope:clear() end
  motion:destroy();props:clear();avatar:clear();sceneClear()
 end)
 bind(player.Character)
end
local function gallery(ui,a)
 ui:title("24 DIRECTION STYLES · HD");for i=1,#S.shapes,4 do local r=ui:row(72,"ShapeGallery");for j=0,3 do local n=S.shapes[i+j];local b=U.button(r,"");b.Name=n;b.Position=UDim2.fromScale(j/4,0);b.Size=UDim2.new(.25,-3,1,0);local g=Symbol.gallery(b,n,30);g.root.Position=UDim2.fromScale(.5,.37);g.root.Size=UDim2.fromOffset(47,47);local l=U.label(b,n,10,UDim2.fromScale(0,.65),UDim2.fromScale(1,.3));l.TextXAlignment=Enum.TextXAlignment.Center;ui.page:on(b.Activated,function() a:set("shape",n) end);ui:watch(function() b.BackgroundColor3=if a.s.shape==n then U.hex("624785") else U.hex("30273E");g:paint(U.hex(a.s.arrowA),U.hex(a.s.arrowB),a.s.ink,a.s.spread) end) end end
end
local function simMap(ui,a)
 local map=ui:row(132,"VirtualMap");map.ClipsDescendants=true;map.BackgroundColor3=U.hex("211E36");local center=U.label(map,"CAMERA ↑",11,UDim2.new(.5,-32,.5,-8),UDim2.fromOffset(70,18));center.TextColor3=U.hex(a.s.accent)
 for _,p in a.sim.players do local b=U.button(map,tostring(p.id));b.AnchorPoint=Vector2.new(.5,.5);b.Size=UDim2.fromOffset(27,25);b.Position=UDim2.fromScale(.5+p.x*.45,.5+p.y*.45);ui.page:on(b.InputBegan,function(i) ui:begin(i,function(pos) local rel=pos-map.AbsolutePosition;p.x=math.clamp((rel.X/map.AbsoluteSize.X-.5)/.45,-1,1);p.y=math.clamp((rel.Y/map.AbsoluteSize.Y-.5)/.45,-1,1);b.Position=UDim2.fromScale(.5+p.x*.45,.5+p.y*.45) end) end) end
end
local function configs(ui,a)
 local selected=a.configSelection
 local current=a.bank.profiles
 local status=ui:note("",38)
 ui:watch(function() status.Text=a.store.status end)
 ui:title("CONFIG MANAGER")
 ui:note("Save your entire setup: HUD, wings, halos, animations, colors and all settings. No JSON editing required.",46)
 local list=names(current)
 if #list==0 then ui:note("No configurations yet. Enter a name and save.",28)
 else ui:chips(list,function(n) a.configSelection=n;a.configName=n;a.confirmDelete=nil;ui:open("Profiles") end,2,function() return selected or "" end) end
 local input=ui:box("Config name",a.configName or selected or "My setup",32)
 ui.page:on(input:GetPropertyChangedSignal("Text"),function() a.configName=input.Text end)
 local function validName()
  local n=input.Text:match("^%s*(.-)%s*$")
  assert(#n>0 and #n<=48 and not n:match("^@") and not n:find("%c"),"Enter a valid config name")
  return n
 end
 local function commit(bank,n,message)
  a:library(bank);a.configSelection=n;a.configName=n or ""
  a.store:save();ui:open("Profiles");ui:message(message.." · "..a.store.status)
 end
 ui:chips({"Save new","Load","Update selected"},function(op)
  local draft=S.copy(a.bank)
  if op=="Load" then
   assert(selected and current[selected],"Select a saved config")
   a:replace(S.copy(current[selected]));a.store:save();ui:message("Loaded "..selected)
  elseif op=="Update selected" then
   assert(selected and current[selected],"Select a saved config")
   draft.profiles[selected]=S.settings(a.s);commit(draft,selected,"Updated "..selected)
  else
   local n=validName();assert(not current[n],"Name exists; use Update selected")
   draft.profiles[n]=S.settings(a.s);commit(draft,n,"Saved "..n)
  end
 end,3)
 ui:chips({"Rename","Duplicate","Delete"},function(op)
  assert(selected and current[selected],"Select a saved config")
  local draft=S.copy(a.bank)
  if op=="Delete" then
   if a.confirmDelete~=selected then a.confirmDelete=selected;ui:message("Click Delete again to remove "..selected);return end
   a.confirmDelete=nil;draft.profiles[selected]=nil;commit(draft,nil,"Deleted "..selected)
  else
   local n=validName();assert(not current[n],"Name already exists")
   draft.profiles[n]=S.copy(current[selected]);if op=="Rename" then draft.profiles[selected]=nil end
   commit(draft,n,"Saved "..n)
  end
 end,3)
 ui:title("STORAGE")
 ui:note(if a.store.remote then "Server storage available. Durable saving depends on the game's DataStore configuration." else "Auto-saves during this game session. For reuse after leaving, export a backup or install server storage in your own place.",54)
 ui:chips({"Save now","Reload bank"},function(op) if op=="Save now" then a.store:save() else a.store:read(true) end;ui:message(a.store.status);if not ui.page.dead then ui:sync() end end,2)
 ui:chips({if a.showConfigJSON then "Hide JSON tools" else "Advanced / JSON backup"},function() a.showConfigJSON=not a.showConfigJSON;ui:open("Profiles") end,1)
 if a.showConfigJSON then
  local transfer=ui:box("JSON backup",a.transfer or "",100)
  ui.page:on(transfer.FocusLost,function() a.transfer=transfer.Text end)
  ui:chips({"Export bank","Import bank"},function(op)
   if op=="Export bank" then
    a.transfer=Http:JSONEncode({format="aether.bank/1",data=a.bank});transfer.Text=a.transfer;transfer:CaptureFocus();transfer.CursorPosition=#transfer.Text+1;transfer.SelectionStart=1
   else
    assert(#transfer.Text<=110100,"Import too large")
    local v=Http:JSONDecode(transfer.Text);assert(v.format=="aether.bank/1","Invalid bank format")
    a:restore(S.bank(v.data));a:dirty();a.store:save();ui:message("Bank imported")
   end
  end,2)
 end
end
local function scripts(ui,a)
 local draft=a.scriptTab=="Luau draft";ui:chips({"AETHER Lua","Luau draft"},function(n) a:stopCue();a.scriptTab=n;ui:open("Scripts") end,2,function() return a.scriptTab or "AETHER Lua" end)
 ui:note(if draft then "Author Studio source here. Copy it to a ModuleScript in Studio for compilation. In-game checks are lexical only." else "Bounded HUD language: local values, arithmetic, if/elseif/else, hud calls, onHealthChanged(hp,maxHP) and onEvent(name,hp).",42)
 local k=if draft then "luau" else "cue";local box=ui:box("Source",a.s[k],125,function(v) if a.s[k]~=v then a:stopCue();a:set(k,v) end end);box.TextTruncate=Enum.TextTruncate.None
 local function esc(v) return (v:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
 local syntax=ui:note("",45);syntax.RichText=true;local function highlight() local code=esc(box.Text:sub(1,280));syntax.Text=code:gsub("[%a_][%w_]*",function(w) return if table.find({"local","function","if","then","else","end","return","and","or","nil","true","false"},w) then '<font color="#CF9BFF">'..w..'</font>' else w end) end;ui.page:on(box:GetPropertyChangedSignal("Text"),highlight);highlight()
 ui:chips({"Template","Complete symbol","Select source","Check"},function(op)
  if op=="Template" then a:set(k,S.defs[k].default);box.Text=a.s[k]
  elseif op=="Select source" then box:CaptureFocus();box.CursorPosition=#box.Text+1;box.SelectionStart=1
  elseif op=="Complete symbol" then local i=if box.CursorPosition>0 then box.CursorPosition else #box.Text+1;local left=box.Text:sub(1,i-1);local pre=left:match("([%w%.:_]+)$") or "";local opts=if draft then {"game:GetService","Players","Humanoid","HealthChanged","MaxHealth","CharacterAdded","workspace.CurrentCamera","Vector3.new","function","return"} else {"hud.widget","hud.animate","hud.setGlow","hud.indicator","hud.theme","hud.join","onHealthChanged","onEvent"};for _,w in opts do if w:lower():sub(1,#pre)==pre:lower() then box.Text=left:sub(1,#left-#pre)..w..box.Text:sub(i);a:set(k,box.Text);return end end;ui:message("No matching symbol")
  else if draft then local depth={};local close={[")"]="(",["]"]="[",["}"]="{"};local clean=box.Text:gsub('"[^"\n]*"',''):gsub("'[^'\n]*'",''):gsub("%-%-[^\n]*",'');for ch in clean:gmatch("[%(%)%[%]{}]") do if close[ch] then assert(table.remove(depth)==close[ch],"Unbalanced delimiter") else table.insert(depth,ch) end end;assert(#depth==0,"Open delimiter");ui:message("Delimiters balanced · compile in Studio") else Cues.compile(box.Text);ui:message("HUD syntax OK") end end
 end,2)
 if not draft then ui:title("RUN PERMISSIONS · SESSION ONLY");ui:chips({"widgets","appearance","events"},function(p) a:stopCue();a.grants[p]=not a.grants[p];ui:sync() end,3);local report=ui:note("",26);ui:watch(function() local v={};for _,p in {"widgets","appearance","events"} do if a.grants[p] then table.insert(v,p) end end;report.Text="Granted: "..table.concat(v,", ").."   /   "..(if a.cue then "Running" else "Stopped") end)
  ui:chips({"Run HUD script","Stop"},function(op) if op=="Stop" then a:stopCue();ui:message("Stopped") else a:set(k,box.Text);a:runCue() end;ui:sync() end,2)
 end
end
function E.render(a,tab,ui)
 if tab=="Dashboard" then preview(ui,a);ui:note("Game reads the local Humanoid and authorized targets. Simulator edits only a separate virtual scene. F8 opens Studio. LeftAlt controls AETHER Alt Lock. Disable Roblox Shift Lock Switch first.",43);ui:title("THEMES");preset(ui,a,"Theme");ui:group("Theme",{topCapsule=true,robloxRail=true,constellationBgA=true,constellationBgB=true,constellationLineA=true,constellationLineB=true,constellationNodeA=true,constellationNodeB=true});ui:title("CONSTELLATION COLORS");for _,k in {"constellationBgA","constellationBgB","constellationLineA","constellationLineB","constellationNodeA","constellationNodeB"} do ui:colorPicker(k) end;ui:note("Upload AETHER_original_atlas_128.png to Roblox and enter the image asset ID above. Choose 128 for the new atlas or 224 for the original atlas. Native icons remain as a fallback.",53);ui:title("MOTION");preset(ui,a,"Motion");ui:group("Motion")
 elseif tab=="HUD" then preview(ui,a,true);ui:chips({"Edit HUD on screen"},function() a:editHUD(true) end,1);preset(ui,a,"HUD");ui:control("layoutMode");ui:control("locked");ui:control("compact");ui:title("TOP / LEFT PANELS");for _,v in {"topCapsule","robloxRail","movePanels"} do ui:control(v) end;ui:note("Enable moving panels to drag the AETHER capsule and CHAT / BAG / LIST shortcuts.",38);ui:chips({"Reset panel positions"},function() a:patch({topCustom=false,railCustom=false}) end,1);ui:title("HUD MOTION");for _,k in {"hudMotion","hudMotionStrength","hudSmoothness","hudShine","hudReaction"} do ui:control(k) end;ui:title("HEART GRADIENT");ui:chips(S.defs.heartPalette.min,function(v) a:set("heartPalette",v) end,3,function() return a.s.heartPalette end);for _,k in {"heartDirection","heartGradientSpeed","heartA","heartMid","heartB","heartGlow"} do ui:control(k) end;ui:note("Heart gradient is independent from the HP bar. Low health blends into warning colors; death freezes the heartbeat and removes the glow.",42);ui:note("Sketch places the HUD along screen edges. Select Custom to edit widget coordinates or drag in the unlocked preview.",29);local widgets={"hp","clock","profile","dock","top","rail"};if not table.find(widgets,a.hudTab) then a.hudTab="hp" end;ui:chips(widgets,function(n) a.hudTab=n;ui:open("HUD") end,3,function() return a.hudTab end);local k=a.hudTab
  if k=="top" or k=="rail" then for _,v in {k.."Custom",k.."X",k.."Y"} do ui:control(v) end
  else for _,suffix in {"","X","Y","Scale","Turn","Alpha"} do ui:control(k..suffix) end end
 elseif tab=="Character" or tab=="Wings" or tab=="Halos" or tab=="Neon" then
  if tab=="Character" then
   ui:title("AETHER MOTION STUDIO V12.12")
   MotionStudio.mount(ui,a)
  else avatarPreview(ui,a) end
  if tab=="Halos" then
   ui:title("HALO COLLECTION")
   ui:note("All halo styles in one list. Layered styles can be combined; classic styles share one active slot.",38)
   local collection={}
   for i,style in S.haloV2Styles do
    collection[#collection+1]={id="layer:"..i,name=style,key="haloV2"..i}
   end
   for _,style in S.defs.haloStyle.min do
    collection[#collection+1]={id="classic:"..style,name=style,classic=true}
   end
   local selected=a.haloSelected
   local function active(item)
    if item.classic then return a.s.halo and a.s.haloStyle==item.name end
    return a.s[item.key.."Enabled"]
   end
   for _,entry in collection do
    local item=entry
    local row=ui:row(42,"HaloStyle")
    local label=U.label(row,item.name,12,UDim2.fromOffset(9,0),UDim2.new(.47,-10,1,0))
    local edit=U.button(row,"EDIT");edit.Position=UDim2.new(.49,0,0,4);edit.Size=UDim2.new(.20,-4,1,-8);edit.TextSize=11
    local state=U.button(row,"");state.Position=UDim2.new(.70,0,0,4);state.Size=UDim2.new(.30,-6,1,-8);state.TextSize=10
    ui.page:on(edit.Activated,function()
     a.haloSelected=if selected==item.id then nil else item.id
     a.haloScroll=ui.sc.CanvasPosition.Y
     ui:open("Halos")
    end)
    ui.page:on(state.Activated,function()
     if item.classic then
      if active(item) then a:set("halo",false)
      else a:patch({halo=true,haloStyle=item.name}) end
     else a:set(item.key.."Enabled",not active(item)) end
    end)
    ui:watch(function()
     local enabled=active(item)
     state.Text=if enabled then "ENABLED" else "DISABLED"
     state.BackgroundColor3=if enabled then Color3.fromRGB(75,54,112) else Color3.fromRGB(43,39,52)
     edit.Text=if selected==item.id then "CLOSE" else "EDIT"
     edit.BackgroundColor3=if selected==item.id then Color3.fromRGB(84,61,118) else Color3.fromRGB(52,40,77)
     label.TextColor3=if selected==item.id then U.hex(a.s.accent) else Color3.fromRGB(229,220,242)
    end)
    if selected==item.id then
     ui:title("CUSTOMIZE / "..string.upper(item.name))
     if item.classic then
      ui:note("Classic styles share these visual settings. Enable this style to view it on your avatar.",34)
      ui:colorPicker("haloColor")
      for _,k in {"haloRadius","haloHeight","haloSpin","haloRainbow","haloDetail","haloWalk","haloGlow"} do ui:control(k) end
     else
      local k=item.key
      ui:colorPicker(k.."Color");ui:colorPicker(k.."Secondary")
      for _,suffix in {"Radius","Height","Spin","Opacity","Glow","Thickness","Count","Tilt"} do ui:control(k..suffix) end
     end
    end
   end
   if a.haloScroll then
    local y=a.haloScroll;a.haloScroll=nil
    local page,sc=ui.page,ui.sc
    task.defer(function()
     if not page.dead and sc.Parent then sc.CanvasPosition=Vector2.new(0,math.max(0,y)) end
    end)
   end
  elseif tab~="Character" then preset(ui,a,tab);ui:group(tab) end
 elseif tab=="Ambient" then local sky=ui:row(106,"SkyPreview");local grad=U.gradient(sky,Color3.new(),Color3.new(),90);local sun=U.frame(sky,"Sun",nil,UDim2.fromOffset(30,30));U.corner(sun,30);ui:watch(function() local s=a.s;sky.BackgroundColor3=Color3.new(1,1,1);grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,U.hex(s.skyA)),ColorSequenceKeypoint.new(.64,U.hex(s.skyB)),ColorSequenceKeypoint.new(1,U.hex(s.skyC))});sun.BackgroundColor3=U.hex(s.skyC);sun.Position=UDim2.fromScale(.7,.66-.45*math.sin(s.time/240*math.pi));sun.BackgroundTransparency=.04+s.fog*.004 end);preset(ui,a,tab);ui:group(tab,{starfallA=true,starfallB=true});ui:title("STARFALL COLORS");ui:colorPicker("starfallA");ui:colorPicker("starfallB")
 elseif tab=="Indicators" then preview(ui,a);gallery(ui,a);ui:group(tab,{shape=true});ui:title("PER-PLAYER OVERRIDE");local id=ui:box("UserId or simulator ID","1");local label=ui:box("Label override","");local color=ui:box("Override hex",a.s.arrowA);ui:chips({"Assign current shape","Remove override"},function(k) local p=S.copy(a.s.players);if k=="Assign current shape" then p[id.Text]={label=label.Text,color=color.Text,shape=a.s.shape} else p[id.Text]=nil end;a:set("players",p);ui:message("Overrides updated") end,2)
 elseif tab=="Cursor" then local f=ui:row(94,"CursorPreview");local host=U.frame(f,"OriginalCursorPreview",UDim2.fromScale(.5,.5),UDim2.fromOffset(60,60),nil,1);host.AnchorPoint=Vector2.new(.5,.5);a.preview={cursorHost=host};preset(ui,a,tab);ui:group(tab,{cursorTrailA=true,cursorTrailB=true});ui:title("TRAIL COLORS");ui:colorPicker("cursorTrailA");ui:colorPicker("cursorTrailB");ui:note("Cursor animation never moves its click hotspot. Enable Show hotspot marker to compare the real mouse position with the skin; use Pointer offset X/Y only for calibration. EditableImage renders desktop SVG; imports need an authorized asset ID.",57)
 elseif tab=="Camera" then ui:note("Camera framing, field of view and orbit controls. Shift-Lock settings are now in Interaction.",40);preset(ui,a,tab);ui:group(tab)
 elseif tab=="Interaction" then
  ui:title("GAME INTERACTION")
  local lockStatus=ui:note("",45)
  ui:watch(function()
   lockStatus.Text=if not a.s.lock then "ALT LOCK OFF · LeftAlt toggles; F8 opens Studio."
    elseif a.view:nativeLockAvailable() then "ALT LOCK WAITING · Roblox Settings > Shift Lock Switch > Off."
    elseif a.s.cameraMode~="Follow" then "ALT LOCK WAITING · Select Follow camera."
    else "ALT LOCK READY · LeftAlt toggles in game. Right Shift has no AETHER action."
  end)
  ui:title("SHIFT-LOCK / RETICLE")
  for _,k in {"cross","crossScale","crossAlpha"} do ui:control(k) end
  local inputKeys={inputOverlay=true,inputMouse=true,inputX=true,inputY=true,inputScale=true,inputOpacity=true,inputColor=true,wallhopHelper=true,wallhopX=true,wallhopY=true,wallhopScale=true,wallhopOpacity=true}
  ui:group(tab,inputKeys)
  ui:title("LIVE INPUT DISPLAY")
  ui:note("Shows your own WASD, Space, Shift and mouse presses. Read-only visualization: no synthetic inputs or game automation.",44)
  for _,k in {"inputOverlay","inputMouse","inputX","inputY","inputScale","inputOpacity","inputColor"} do ui:control(k) end
  ui:title("WALLHOP HELPER")
  ui:note("Practice display: tracks your jump and horizontal camera rotation. No automatic jumps or camera movement.",42)
  for _,k in {"wallhopHelper","wallhopX","wallhopY","wallhopScale","wallhopOpacity"} do ui:control(k) end
 elseif tab=="Fonts" then local text=ui:note(a.s.sample,62);text:SetAttribute("AETHERKeepFontColor",true);text.TextXAlignment=Enum.TextXAlignment.Center;local gradient=U.gradient(text,Color3.new(),Color3.new(),10);local glow=U.stroke(text,U.hex(a.s.fontB),.8);glow.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;ui:watch(function() local s=a.s;text.Text=s.sample;text.FontFace=U.font(s);text.TextSize=s.fontSize*.23;text.TextColor3=if s.fontGradient then Color3.new(1,1,1) else U.hex(s.fontA);text.TextStrokeTransparency=1-s.fontOutline/100;gradient.Enabled=s.fontGradient;gradient.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB));glow.Color=U.hex(s.fontB);glow.Transparency=1-s.fontGlow*.008;glow.Thickness=1+s.fontGlow*.023 end);local query=ui:box("Search native typefaces",a.fontQuery or "",32,function(q) if q~=(a.fontQuery or "") then a.fontQuery=q;ui:open("Fonts") end end);local fonts={};for _,n in S.fonts do if n:lower():find((a.fontQuery or ""):lower(),1,true) then table.insert(fonts,n) end end;ui:chips(fonts,function(n) a:patch({font=n,fontAsset=""}) end,3,function() return a.s.font end);ui:group(tab,{font=true});preset(ui,a,tab)
 elseif tab=="Simulator" then preview(ui,a);ui:title("WORLD PREVIEW");avatarPreview(ui,a,true);ui:chips({"Use simulator","Use game"},function(n) a:modeSet(if n=="Use game" then "Game" else "Simulator") end,2);simMap(ui,a);ui:chips({"Damage −25","Heal +25","Respawn","Add player","Move players","Clear players"},function(k) a:simulate(k);ui:open("Simulator") end,3);local hp=ui:box("Set virtual HP",tostring(a.sim.hp));local mx=ui:box("Virtual max HP",tostring(a.sim.max));ui:chips({"Apply virtual vitals"},function() local h,m=tonumber(hp.Text),tonumber(mx.Text);assert(m and h and m>=1 and m<=100000 and h>=0 and h<=m,"Invalid HP / maximum");a:modeSet("Simulator");a:simVitals(h,m,"set") end,1)
 elseif tab=="Scripts" then scripts(ui,a)
 elseif tab=="Profiles" then configs(ui,a)
 elseif tab=="List" then
  ui:title("ROBLOX PLAYER LIST")
  ui:chips({"Toggle native player list"},function() ui:togglePlayerList() end,1)
  ui:note("Roblox updates its own player list automatically as players join or leave.",36)
 elseif tab=="Updates" then
  ui:title("LIVE UPDATE CENTER")
  local state=a.liveUpdate
  state.unread=false
  local version=ui:note("",36)
  local status=ui:note("",48)
  local notes=ui:note("",52)
  local function sync()
   version.Text="RUNNING VERSION  /  "..state.version..(if state.isTest then " · TEST "..tostring(state.testCount) else "").."\nWEBSITE  /  "..(if state.connected then (state.relayStatus or "CONNECTED · AUTO") else "RELAY OFFLINE")
   status.Text=state.status
   notes.Text=state.notes or "No update applied. Your HUD, configs and menu stay active during an update."
  end
  ui:watch(sync)
  ui:chips({"Test update","Check updates","Rollback"},function(n)
   if n=="Test update" then a:testLiveUpdate() elseif n=="Check updates" then a:checkLiveUpdate() else a:rollbackLiveUpdate() end
  end,3)
  ui:note("RELAY OFFLINE: install the server relay in your own place. HTTP DISABLED: enable Allow HTTP Requests in experience settings. ONLINE: website releases apply automatically.",65)
  ui:title("UPDATE LIST")
  local changelog=ui:note("",280)
  ui:watch(function()
   local rows={}
   for i,release in state.releases do
    if i>5 then break end
    table.insert(rows,"v"..release.version.."  /  "..release.source.."  /  "..release.time.."\n"..release.notes)
   end
   changelog.Text=if #rows>0 then table.concat(rows,"\n\n") else "No updates applied in this session yet."
  end)
 elseif tab=="Diagnostics" then local info=ui:note("",54);local log=ui:box("Session events","",165);log.TextEditable=false;local function refresh() info.Text=string.format("%s  ·  HP %s / %s  ·  %d tracked\n%s",a.mode,tostring(a.frame.hp),tostring(a.frame.max),#a.frame.targets,a.store.status);log.Text=table.concat(a.logs,"\n") end;ui:chips({"Refresh","Clear log","Reset settings"},function(n) if n=="Clear log" then table.clear(a.logs) elseif n=="Reset settings" then a:replace(S.defaults()) end;refresh() end,3);refresh();ui:title("SESSION");ui:note("Unload stops AETHER, removes its HUD and effects, and releases its camera and mouse controls. Export a bank first to retain local-only settings.",52);-- Allocate one confirmation row, once per Diagnostics page. Never append rows from clicks.
  local page=ui.page
  local row=ui:row(40,"UnloadConfirmation")
  row.BackgroundTransparency=1
  local unload=U.button(row,"Unload AETHER")
  unload.Size=UDim2.fromScale(1,1)
  unload:SetAttribute("AETHERKeepFontColor",true)
  local cancel=U.button(row,"Cancel")
  cancel.Position=UDim2.fromScale(.72,0);cancel.Size=UDim2.new(.28,-2,1,0);cancel.Visible=false
  local state="idle"
  local token=0
  local red=Color3.fromRGB(135,35,53)
  local function draw()
   if page.dead or not row.Parent then return end
   unload.BackgroundColor3=if state=="waiting" then Color3.fromRGB(86,36,48) else red
   unload.TextColor3=Color3.fromRGB(255,222,226)
   unload.Size=if state=="idle" then UDim2.fromScale(1,1) else UDim2.new(.72,-4,1,0)
   unload.Active=state=="idle" or state=="ready"
   unload.Interactable=unload.Active
   unload.AutoButtonColor=unload.Active
   cancel.Visible=state=="waiting" or state=="ready"
   if state=="idle" then unload.Text="Unload AETHER"
   elseif state=="ready" then unload.Text="Confirm unload"
   elseif state=="done" then unload.Text="Unloading..." end
  end
  page:add(function() token+=1;state="closed" end)
  page:on(cancel.Activated,function()
   if state~="waiting" and state~="ready" then return end
   token+=1;state="idle";draw();ui:message("Unload cancelled.")
  end)
  page:on(unload.Activated,function()
   if page.dead or a.stopping then return end
   if state=="ready" then
    token+=1;state="done";draw();a:unload();return
   end
   if state~="idle" then return end
   token+=1
   local current=token
   state="waiting";draw();unload.Text="Confirm in 3 s"
   ui:message("Confirm after the countdown, or cancel.")
   task.spawn(function()
    local deadline=os.clock()+3
    while not page.dead and token==current and state=="waiting" do
     local remaining=deadline-os.clock()
     if remaining<=0 then break end
     unload.Text="Confirm in "..tostring(math.ceil(remaining)).." s"
     task.wait(math.min(.1,remaining))
    end
    if page.dead or token~=current or state~="waiting" or not row.Parent then return end
    state="ready";draw()
   end)
  end)
  draw()
 end
end
return E