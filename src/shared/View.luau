local Input=game:GetService("UserInputService");local Gui=game:GetService("GuiService");local U=require(script.Parent.Util);local VectorCursor=require(script.Parent.VectorCursor)
local CursorTrail=require(script.Parent.CursorTrail)
local V={};V.__index=V
local preferences=UserSettings():GetService("UserGameSettings")
-- Do not run a second shoulder controller while Roblox owns mouse lock.
function V:nativeLockAvailable()
 local ok,available=pcall(function()
  return self.player.DevEnableMouseLock and preferences.ControlMode==Enum.ControlMode.MouseLockSwitch
 end)
 -- If the setting cannot be read, yield rather than fight the native controller.
 return not ok or available
end
function V.new(player,layer)
 local self=setmetatable({player=player,angle=0,clock=0},V)
 -- This anchor marks the exact click pixel. Animated skin always rotates AROUND it.
 self.pointer=U.frame(layer,"MouseHotspot",nil,UDim2.fromOffset(1,1),nil,1)
 self.pointer.Active=false;self.pointer.Interactable=false;self.pointer.Visible=false;self.pointer.ZIndex=10
 self.skin=U.frame(self.pointer,"CursorSkin",nil,UDim2.fromOffset(32,32),nil,1)
 self.skin.Active=false;self.skin.Interactable=false;self.skin.ZIndex=10
 self.glyph=VectorCursor.new(self.skin)
 self.image=U.new("ImageLabel",{
  Name="Asset",BackgroundTransparency=1,Active=false,Selectable=false,
  Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit,ZIndex=12
 },self.skin)
 self.motionTrail=CursorTrail.new(layer)
 self.hotspotDebug=U.frame(self.pointer,"HotspotDebug",UDim2.fromOffset(-3,-3),UDim2.fromOffset(7,7),Color3.fromRGB(255,80,85),0)
 self.hotspotDebug.ZIndex=20;self.hotspotDebug.Active=false;self.hotspotDebug.Visible=false
 U.corner(self.hotspotDebug,99)
 return self
end
local function draggingCamera()
 return Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
end
function V:releaseLock(yieldNative)
 local owned=self.mouse~=nil or self.lockHum~=nil
 self.mouse=nil
 if self.lockHum then
  if self.lockHum.Parent and not self.lockHum.AutoRotate then self.lockHum.AutoRotate=self.auto end
  self.lockHum=nil
 end
 if not owned then return end
 self.shiftReticleActive=false
 self.motionTrail:hide()
 if yieldNative then self.releaseFrames=nil;return end
 -- Never restore a stale LockCurrentPosition captured during a mouse drag.
 -- Respect a real held camera button; release our own centered capture only.
 local behavior=Input.MouseBehavior
 if behavior==Enum.MouseBehavior.LockCenter then
  Input.MouseBehavior=if draggingCamera() then Enum.MouseBehavior.LockCurrentPosition else Enum.MouseBehavior.Default
 elseif behavior==Enum.MouseBehavior.LockCurrentPosition and not draggingCamera() then
  Input.MouseBehavior=Enum.MouseBehavior.Default
 end
 -- A bounded post-camera handoff prevents the old capture from surviving
 -- the frame in which our lock was released. No synthetic button events.
 self.releaseFrames=2
end
function V:finishLockRelease()
 if not self.releaseFrames then return end
 if self.mouse or self:nativeLockAvailable() then self.releaseFrames=nil;return end
 local camera=workspace.CurrentCamera
 if not camera or camera.CameraType~=Enum.CameraType.Custom or self.player.CameraMode==Enum.CameraMode.LockFirstPerson or (camera.CFrame.Position-camera.Focus.Position).Magnitude<=1.1 or draggingCamera() then
  self.releaseFrames=nil;return
 end
 if Input.MouseBehavior~=Enum.MouseBehavior.Default then Input.MouseBehavior=Enum.MouseBehavior.Default end
 self.releaseFrames-=1
 if self.releaseFrames<=0 then self.releaseFrames=nil end
end
function V:releaseCamera(yieldNative)
 self:releaseLock(yieldNative);if self.cam then local c=self.cam;local b=self.before;if c.Parent then c.FieldOfView=b.fov;c.CameraType=b.kind;if b.subject and b.subject.Parent then c.CameraSubject=b.subject end;if b.kind==Enum.CameraType.Scriptable then c.CFrame=b.cf;c.Focus=b.focus end end;self.player.CameraMode=b.mode;self.cam=nil end
 if self.hum then if self.hum.Parent then self.hum.CameraOffset=self.offset end;self.hum=nil end;self.orbitPos=nil
end
function V:preview(host,s)
 if self.previewHost~=host then
  self.glyph:preview(host)
  if self.previewImage then self.previewImage:Destroy();self.previewImage=nil end
  self.previewHost=host
  if host then
   self.previewImage=U.new("ImageLabel",{Name="ImportedCursorPreview",BackgroundTransparency=1,Active=false,Selectable=false,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit},host)
  end
 end
 if self.previewImage then
  local image=s.cursorShape=="Image" and s.image~=""
  self.previewImage.Visible=image
  if image then self.previewImage.Image="rbxassetid://"..s.image end
 end
 if host then
  local animation=if s.reduce then "Off" else (s.cursorAnimation or "Off")
  local t=os.clock()*(s.cursorMotionSpeed or 100)/100
  local rotation=if animation=="Spin" then (t*85)%360
   elseif animation=="Sway" then math.sin(t*2.8)*7 else 0
  local size=if animation=="Pulse" then 60*(1+math.abs(math.sin(t*5))*.11)
   elseif animation=="Breathe" or animation=="Sway" then 60*(1+math.sin(t*3.1)*.045)
   else 60
  host.Rotation=rotation
  host.Size=UDim2.fromOffset(size,size)
 end
end
function V:restoreCursor()
 if self.pointer and self.pointer.Parent then self.pointer.Visible=false end
 self.motionTrail:hide()
 if self.icon~=nil then Input.MouseIconEnabled=self.icon;self.icon=nil end
end
function V:destroy()
 self:releaseCamera()
 self:restoreCursor()
 if self.previewImage then self.previewImage:Destroy();self.previewImage=nil end
 self.glyph:destroy()
 self.motionTrail:destroy()
 self.pointer:Destroy()
end
-- Keep the real click hotspot and the visual pointer aligned.
-- This function runs in a separate, cheap render callback so complex SVG work
-- and HUD updates cannot defer the position assignment.
function V:cursorStep(s)
 self:finishLockRelease()
 local image=s.cursorShape=="Image"
 local camera=workspace.CurrentCamera
 local thirdPerson=camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude>1.1
 local ownsLock=self.mouse~=nil and self.lockHum~=nil
 local locked=thirdPerson and (ownsLock or (not s.lock and self:nativeLockAvailable())) and Input.MouseBehavior==Enum.MouseBehavior.LockCenter and Input.MouseEnabled and not Gui.MenuIsOpen and not self.menuOpen and not Input:GetFocusedTextBox() and Input:GetLastInputType()~=Enum.UserInputType.Touch
 self.shiftReticleActive=locked==true
 local show=s.cursor and not locked and Input.MouseEnabled and not Gui.MenuIsOpen
  and (not image or s.image~="") and Input:GetLastInputType()~=Enum.UserInputType.Touch
 if locked then
  self.pointer.Visible=false
  self.hotspotDebug.Visible=false
  self.motionTrail:hide()
  if s.cross then
   if self.icon==nil then self.icon=Input.MouseIconEnabled end
   Input.MouseIconEnabled=false
  else
   self:restoreCursor()
  end
  return
 end
 if not show then self:restoreCursor();return end
 -- Prepare the visible artwork first. If an imported asset has not loaded,
 -- keep the original cursor instead of leaving the player with no pointer.
 self.image.Visible=image
 if image then
  local asset="rbxassetid://"..s.image
  if self.image.Image~=asset then self.image.Image=asset end
  if not self.image.IsLoaded then self:restoreCursor();return end
 end
 self.glyph:step(s,os.clock())

 -- GetMouseLocation is screen-relative; AbsolutePosition is CoreUISafeInsets-
 -- relative even when ScreenInsets=None. Convert both to the same space once.
 local mouse=Input:GetMouseLocation()
 local inset=Gui:GetGuiInset()
 local origin=self.pointer.Parent.AbsolutePosition
 local hit=mouse-inset-origin+Vector2.new(s.cursorOffsetX or 0,s.cursorOffsetY or 0)
 self.pointer.Position=UDim2.fromOffset(hit.X,hit.Y)

 local hx,hy=self.glyph:hotspot(s)

 local anim=if s.reduce then "Off" else (s.cursorAnimation or "Off")
 local t=os.clock()*(s.cursorMotionSpeed or 100)/100
 local angle=0;local zoom=1
 if anim=="Sway" then
  angle=math.sin(t*2.8)*7
  zoom=1+math.sin(t*3.1)*.035
 elseif anim=="Breathe" then
  zoom=1+math.sin(t*3.3)*.06
 elseif anim=="Spin" then
  angle=(t*85)%360
 elseif anim=="Pulse" then
  zoom=1+math.abs(math.sin(t*5))*.11
 end
 local size=s.cursorSize*zoom
 self.skin.Size=UDim2.fromOffset(size,size)
 self.skin.Rotation=angle
 -- The Roblox Frame rotates about its CENTER, not AnchorPoint. Counter-rotate
 -- the center offset so the image's click hotspot remains fixed on the real pixel.
 local dx=(hx-.5)*size
 local dy=(hy-.5)*size
 local rad=math.rad(angle)
 local cx=dx*math.cos(rad)-dy*math.sin(rad)
 local cy=dx*math.sin(rad)+dy*math.cos(rad)
 self.skin.Position=UDim2.fromOffset(-cx-size*.5,-cy-size*.5)
 self.pointer.Visible=true
 self.hotspotDebug.Visible=s.cursorDebug==true
 -- Only suppress the native cursor after the custom cursor is ready and placed.
 if self.icon==nil then self.icon=Input.MouseIconEnabled end
 Input.MouseIconEnabled=false
 if s.cursorTrail and not s.reduce then
  self.motionTrail:step(hit,s,os.clock())
 else self.motionTrail:hide() end
end
function V:step(s,hum,menu,dt,t)
 self.menuOpen=menu
 local camera=workspace.CurrentCamera
 local hrp=hum and hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
 local native=self:nativeLockAvailable()
 local nativeOwnsFollow=native and s.cameraMode=="Follow"
 local requested=s.lock and s.cameraMode=="Follow" and not native
 local enabled=(s.camera or requested) and hrp and hum.Health>0 and camera and not nativeOwnsFollow
 self.lockOwner=if s.lock and nativeOwnsFollow then "Waiting for Roblox Shift Lock off" elseif nativeOwnsFollow then "Roblox" elseif requested then "AETHER" else "None"
 if self.cam and (not enabled or self.cam~=camera or self.hum~=hum) then self:releaseCamera(native) end
 if enabled then
  if not self.cam then self.cam=camera;self.before={fov=camera.FieldOfView,mode=self.player.CameraMode,kind=camera.CameraType,subject=camera.CameraSubject,cf=camera.CFrame,focus=camera.Focus};self.hum=hum;self.offset=hum.CameraOffset end
  local thirdPerson=(camera.CFrame.Position-camera.Focus.Position).Magnitude>1.1
  local lock=requested and thirdPerson and not hum.Sit and not menu and not Gui.MenuIsOpen and Input:GetFocusedTextBox()==nil and Input.MouseEnabled and Input:GetLastInputType()~=Enum.UserInputType.Touch
  -- Yield to a game-owned centered mouse rather than acquiring another lock.
  if lock and not self.mouse and (Input.MouseBehavior~=Enum.MouseBehavior.Default or draggingCamera() or self.releaseFrames~=nil) then lock=false end
  local first=s.cameraMode=="First Person" and not menu;local mode=if first then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic;if self.player.CameraMode~=mode then self.player.CameraMode=mode end
  local k=if s.reduce or s.follow==0 then 1 else 1-math.exp(-dt*1000/s.follow)
  if s.camera then camera.FieldOfView+=(s.fov-camera.FieldOfView)*k end
  local dest=self.offset+Vector3.new(if lock then s.shoulder/10 else 0,if s.camera then s.cameraHeight/10 else 0,0)
  hum.CameraOffset=hum.CameraOffset:Lerp(dest,k)
  if s.cameraMode=="Orbit" then
   self:releaseLock();camera.CameraType=Enum.CameraType.Scriptable;local center=hrp.Position+Vector3.new(0,1+s.cameraHeight/10,0);self.angle+=if s.reduce then 0 else math.rad(s.orbitSpeed)*dt
   local desired=Vector3.new(math.sin(self.angle)*s.radius,s.radius*.25,math.cos(self.angle)*s.radius);local params=self.ray or RaycastParams.new();self.ray=params;params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={hum.Parent}
   local hit=workspace:Raycast(center,desired,params);local pos=center+desired.Unit*(if hit then math.max(.4,hit.Distance-.28) else desired.Magnitude);self.orbitPos=if hit then pos else (self.orbitPos or pos):Lerp(pos,k);camera.CFrame=CFrame.lookAt(self.orbitPos,center);camera.Focus=CFrame.new(center)
  else
   if camera.CameraType~=Enum.CameraType.Custom then camera.CameraType=Enum.CameraType.Custom end;camera.CameraSubject=hum;self.orbitPos=nil
   if lock then if not self.mouse then self.mouse=Enum.MouseBehavior.Default;self.lockHum=hum;self.auto=hum.AutoRotate;self.releaseFrames=nil end;Input.MouseBehavior=Enum.MouseBehavior.LockCenter;hum.AutoRotate=false;local look=camera.CFrame.LookVector*Vector3.new(1,0,1);if look.Magnitude>.01 and not hum.Sit then hrp.CFrame=CFrame.lookAt(hrp.Position,hrp.Position+look) end else self:releaseLock(native) end
  end
 end
 -- Rasterization and gradient work is independent of pointer position.
 if self.previewHost and not self.pointer.Visible then self.glyph:step(s,os.clock()) end
 self.settings=s
end
return V