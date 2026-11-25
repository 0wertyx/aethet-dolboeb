-- Additive R6 / R15 walking, graceful glide, and ethereal hover.
-- Poses are visual-only; HumanoidRootPart physics and game controls are unchanged.
-- Evaluated at PreSimulation after Animator's own animation tracks.
local MotionPacks=require(script.Parent.MotionPacks)
local Signature=require(script.Parent.SignatureR6)
local MotionStudio=require(script.Parent.MotionStudio)
local W={}
W.__index=W
local function motor(rig,...)
 for _,name in {...} do
  local m=rig:FindFirstChild(name,true)
  if m and m:IsA("Motor6D") then return m end
 end
 return nil
end
function W.new()
 return setmetatable({character=nil,motors={},phase=0,blend=0,hover=0,liveWrites={},livePose={},liveTime=0,liveAir=0,liveRetry=0},W)
end
function W:restoreLive()
 for m,entry in self.liveWrites do
  if m.Parent and m.Transform==entry.applied then m.Transform=entry.base end
 end
 table.clear(self.liveWrites)
end
function W:bind(character)
 if self.character==character then return end
 self:restoreLive();table.clear(self.livePose)
 self.liveTime=0;self.liveAir=0;self.liveWasAir=false;self.liveStyle=nil;self.liveState=nil;self.liveTransition=nil;self.liveRetry=0
 self.character=character;self.phase=0;self.blend=0;self.hover=0;self.airTime=0;self.wasAir=false;self.signatureActive=false;self.airProgress=0
 table.clear(self.motors)
 if not character then return end
 local j=self.motors
 j.RightHip=motor(character,"RightHip","Right Hip")
 j.LeftHip=motor(character,"LeftHip","Left Hip")
 j.RightShoulder=motor(character,"RightShoulder","Right Shoulder")
 j.LeftShoulder=motor(character,"LeftShoulder","Left Shoulder")
 j.RightElbow=motor(character,"RightElbow")
 j.LeftElbow=motor(character,"LeftElbow")
 j.RightKnee=motor(character,"RightKnee")
 j.LeftKnee=motor(character,"LeftKnee")
 j.RightAnkle=motor(character,"RightAnkle")
 j.LeftAnkle=motor(character,"LeftAnkle")
 j.Waist=motor(character,"Waist")
 j.Neck=motor(character,"Neck")
 j.Root=motor(character,"RootJoint","Root")
end
local function add(j,cf)
 if j and j.Parent then j.Transform=j.Transform*cf end
end
-- Periodic interpolated contact / passing / lift / reach poses.
-- Z represents forward displacement (Roblox forward is negative Z).
local function curve(keys,t)
 local u=(t%1)*#keys
 local i=math.floor(u)
 local k=u-i
 k=k*k*(3-2*k)
 local a,b=keys[i+1],keys[(i+1)%#keys+1]
 return a+(b-a)*k
end
local tracks={
 step={z={.85,.42,-.42,-.85,-.32,.38},y={0,0,0,.12,.94,.72}},
 stride={z={1,.5,-.5,-1,-.28,.62},y={0,0,0,.14,1,.82}},
 hop={z={.75,.32,-.55,-.72,-.24,.46},y={0,.08,.18,.48,1,.85}},
 stiff={z={.8,.8,0,-.8,-.8,0},y={0,0,0,.2,.85,.85}},
 strut={z={.9,.3,-.35,-.75,-.2,.63},y={0,0,.05,.2,.8,.65}},
 slow={z={.78,.48,-.26,-.7,-.42,.25},y={.05,.04,.12,.36,.9,.72}},
 drag={z={.5,.35,.1,-.78,-.68,-.05},y={0,0,0,.02,.2,.35}},
 float={z={.18,.6,.4,-.18,-.6,-.4},y={.25,.45,.8,.9,.6,.35}},
 paired={z={.22,.62,.48,-.18,-.55,-.36},y={.2,.45,.9,.8,.5,.24}},
 sweep={z={.75,.4,-.15,-.65,-.35,.25},y={0,.1,.35,.75,.9,.48}},
 skip={z={.9,.3,-.4,-.65,-.15,.58},y={.02,.12,.1,.55,1,.95}},
 prance={z={.78,.4,-.42,-.64,.1,.8},y={0,0,.06,.4,1,.9}},
 skate={z={.35,.15,-.25,-.72,-.48,.12},y={0,0,0,.12,.55,.4}},
 waddle={z={.55,.3,-.3,-.55,-.3,.3},y={0,0,.12,.2,.7,.6}},
}
local runtimeNames={"Root","RightShoulder","LeftShoulder","RightHip","LeftHip","Neck"}
local secondaryNames={"Waist","RightElbow","LeftElbow","RightKnee","LeftKnee","RightAnkle","LeftAnkle"}
local function mapped(m,cf)
 local basis=m.C0.Rotation
 local scale=if m.Part0 then math.clamp(m.Part0.Size.Y/2,.5,1.7) else 1
 return basis:Inverse()*CFrame.new(cf.Position*scale)*cf.Rotation*basis
end
function W:liveStep(character,s,dt)
 self:restoreLive()
 self:bind(character)
 if not character then return end
 local hum=character:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 or hum.Sit or s.reduce or not s.walkAnimation or (s.walkIntensity or 0)<=0 then
  table.clear(self.livePose);self.liveStyle=nil;self.liveState=nil;self.liveWasAir=false;self.liveTime=0;self.liveTransition=nil
  return
 end
 local hs=hum:GetState()
 if hs==Enum.HumanoidStateType.Seated or hs==Enum.HumanoidStateType.Dead or hs==Enum.HumanoidStateType.Physics or hs==Enum.HumanoidStateType.Ragdoll or hs==Enum.HumanoidStateType.FallingDown or hs==Enum.HumanoidStateType.PlatformStanding or hs==Enum.HumanoidStateType.GettingUp then
  table.clear(self.livePose);self.liveStyle=nil;self.liveState=nil;self.liveWasAir=false;self.liveTransition=nil;return
 end
 dt=math.clamp(dt,0,.1)
 self.liveRetry+=dt
 if self.liveRetry>=.35 and (not self.motors.Root or not self.motors.Root.Parent or not self.motors.RightHip or not self.motors.RightHip.Parent or not self.motors.LeftHip or not self.motors.LeftHip.Parent) then
  self:bind(nil);self:bind(character)
 end
 local rootPart=character:FindFirstChild("HumanoidRootPart")
 local v=if rootPart and rootPart:IsA("BasePart") then rootPart.AssemblyLinearVelocity else Vector3.zero
 local horizontal=Vector3.new(v.X,0,v.Z).Magnitude
 local isRun=horizontal>(if self.liveState=="Run" then 11 else 13)
 local state=if hs==Enum.HumanoidStateType.Climbing then "Climb"
  elseif hs==Enum.HumanoidStateType.Swimming then "Swim"
  elseif hs==Enum.HumanoidStateType.Jumping then "Jump"
  elseif hs==Enum.HumanoidStateType.Freefall then "Fall"
  elseif hum.MoveDirection.Magnitude<.08 then "Idle"
  elseif isRun then "Run" else "Walk"
 local movementSpeed=if state=="Climb" then math.abs(v.Y) elseif state=="Swim" then v.Magnitude else horizontal
 local air=state=="Jump" or state=="Fall"
 if self.liveSettings~=s then self.liveSettings=s;self.liveConfig=MotionStudio.runtimeSettings(s) end
 local config=self.liveConfig
 local styleChanged=self.liveStyle~=config.style
 local changed=styleChanged or self.liveState~=state
 if styleChanged then self.liveTime=0;self.liveAir=0;self.liveRate=nil end
 if air then
  self.liveAir=if self.liveWasAir and not styleChanged then self.liveAir+dt*config.speed else 0
 else self.liveAir=0 end
 self.liveWasAir=air
 if changed then
  self.liveFrom=table.clone(self.livePose);self.liveTransition=0
 end
 self.liveStyle=config.style;self.liveState=state
 local targetRate=MotionStudio.speedFactor(config,state,movementSpeed)
 self.liveRate=if changed or self.liveRate==nil then targetRate else self.liveRate+(targetRate-self.liveRate)*(1-math.exp(-dt*12))
 self.liveTime+=dt*config.speed*self.liveRate
 local authored,hover=MotionStudio.runtimePose(config,self.liveTime,state,self.liveAir)
 local targets={}
 for _,name in runtimeNames do
  local m=self.motors[name]
  if m and m.Parent then targets[m]=mapped(m,authored[name]) end
 end
 for _,name in secondaryNames do
  local m=self.motors[name]
  if m and m.Parent then targets[m]=CFrame.identity end
 end
 local root=self.motors.Root
 -- Match grounded foot contact on R6 without changing HumanoidRootPart position.
 if root and targets[root] and root.Part1 and not air and state~="Climb" and state~="Swim" then
  local neutral=root.C0*root.C1:Inverse()
  local posed=root.C0*targets[root]*root.C1:Inverse()
  local floor,low=math.huge,math.huge
  if hum.RigType==Enum.HumanoidRigType.R6 then
   for _,m in {self.motors.RightHip,self.motors.LeftHip} do
    if m and targets[m] and m.Part1 then
     local sz=m.Part1.Size/2
     local function bottom(cf)
      return cf.Position.Y-math.abs(cf.RightVector.Y)*sz.X-math.abs(cf.UpVector.Y)*sz.Y-math.abs(cf.LookVector.Y)*sz.Z
     end
     floor=math.min(floor,bottom(neutral*m.C0*m.C1:Inverse()))
     low=math.min(low,bottom(posed*m.C0*targets[m]*m.C1:Inverse()))
    end
   end
  end
  local correction=if floor<math.huge and low<math.huge then math.clamp(floor-low,-1.5,1.5) else 0
  local basis=root.C0.Rotation
  targets[root]=basis:Inverse()*CFrame.new(0,correction+hover,0)*basis*targets[root]
 end
 self.liveTransition=math.min(1,(self.liveTransition or 0)+dt/.14)
 local k=self.liveTransition*self.liveTransition*(3-2*self.liveTransition)
 for m,target in targets do
  local base=m.Transform
  local old=self.liveFrom and self.liveFrom[m] or base
  local result=if k<1 then old:Lerp(target,k) else target
  self.liveWrites[m]={base=base,applied=result};self.livePose[m]=result
  m.Transform=result
 end
end
function W:step(character,s,dt,preview)
 if not preview then self:liveStep(character,s,dt);return end
 self:bind(character)
 if not character then return end
 local hum=character:FindFirstChildOfClass("Humanoid")
 if not hum or (not preview and not hum:FindFirstChildOfClass("Animator")) then return end
 dt=math.clamp(dt,0,.07)
 local style=s.walkStyle or "Natural"
 local pack=MotionPacks.get(style)
 local floating=style=="Floating" or style=="Glide" or style=="Ethereal"
 local enabled=s.walkAnimation and not s.reduce and (preview or (hum.Health>0 and not hum.Sit))
 local virtual=if type(preview)=="table" then preview else nil
 local state=if virtual and virtual.state then virtual.state elseif virtual and not virtual.grounded then (if virtual.jumping then Enum.HumanoidStateType.Jumping else Enum.HumanoidStateType.Freefall) elseif preview then Enum.HumanoidStateType.Running else hum:GetState()
 local jumping=state==Enum.HumanoidStateType.Jumping
 local falling=state==Enum.HumanoidStateType.Freefall
 local climbing=state==Enum.HumanoidStateType.Climbing
 local swimming=state==Enum.HumanoidStateType.Swimming
 local airborne=jumping or falling
 local grounded=if virtual then virtual.grounded elseif preview then true else hum.FloorMaterial~=Enum.Material.Air
 local movement=if virtual then virtual.movement elseif preview then 1 else hum.MoveDirection.Magnitude
 local intensity=math.clamp((s.walkIntensity or 65)/100,0,1)
 local fullPreview=virtual and virtual.fullPose==true
 local target=0
 if enabled then
  if pack then
   target=intensity*(if movement>.08 or airborne or climbing or swimming then 1
    elseif pack.hover then .82 else .6)
  elseif floating then
   target=intensity*(if grounded then .62+.38*movement else 1)
  else
   target=intensity*(if grounded then movement else 0)
  end
 end
 if fullPreview and enabled then target=intensity end
 self.blend+=(target-self.blend)*(1-math.exp(-dt*(if fullPreview then 14 else 9)))
 if self.blend<.002 then return end
 local speed=math.clamp((if virtual and virtual.speed then virtual.speed else hum.WalkSpeed)/16,.6,2.3)
 local moving=math.clamp(movement,0,1)
 local cadence=if pack then pack.cadence*(.62+.38*moving)*speed
  elseif floating then (2.3+2.8*moving)*speed else 7.8*speed
 self.phase+=dt*cadence
 local ph=self.phase;local wave=math.sin(ph);local cross=math.cos(ph)
 local weight=self.blend
 local j=self.motors
 self.signatureActive=false;self.airProgress=0;self.previewState=state
 if fullPreview and hum.RigType==Enum.HumanoidRigType.R6 and not swimming and not climbing then
  if airborne then self.airTime=(if self.wasAir and self.lastAirState==state then self.airTime or 0 else 0)+dt else self.airTime=0 end
  self.lastAirState=state
  self.wasAir=airborne
  -- Character tab repeats its preview jump; the simulator plays one turn.
  local airProgress=if airborne then (if virtual.loopAir then (self.airTime/.82)%1 else math.clamp(self.airTime/.82,0,1)) else 0
  if style=="Godly Aura" then
   self.godlyClock=(if self.lastStyle=="Godly Aura" then self.godlyClock or 0 else 0)+dt
  end
  self.lastStyle=style
  local signaturePhase=if style=="Godly Aura" then (self.godlyClock or 0)/3.6 else ph/(2*math.pi)
  local signature=Signature.get(style,signaturePhase,moving,airborne,airProgress,jumping)
  if signature then
   local strength=math.clamp((virtual.originStrength or 100)/100,0,1)
   local function apply(m,v)
    if not m or not m.Parent then return end
    local scale=if m.Part0 then math.clamp(m.Part0.Size.Y/2,.65,1.6) else 1
    local basis=m.C0.Rotation
    local body=CFrame.new(Vector3.new(v[4],v[5],v[6])*weight*strength*scale)
      *CFrame.Angles(math.rad(v[1])*weight,math.rad(v[2])*weight,math.rad(v[3])*weight)
    m.Transform=basis:Inverse()*body*basis
   end
   for name,v in signature do apply(j[name],v) end
   -- Root-local foot contact for the anchored viewport rig.
   local root=j.Root
   if root and j.RightHip and j.LeftHip and root.Part1 then
    local function legCF(m,torso,animated)
     return torso*m.C0*(if animated then m.Transform else CFrame.identity)*m.C1:Inverse()
    end
    local function bottom(m,cf)
     local sz=m.Part1.Size/2
     return cf.Position.Y-math.abs(cf.RightVector.Y)*sz.X-math.abs(cf.UpVector.Y)*sz.Y-math.abs(cf.LookVector.Y)*sz.Z
    end
    local neutral=root.C0*root.C1:Inverse()
    local posed=root.C0*root.Transform*root.C1:Inverse()
    local r,l=j.RightHip,j.LeftHip
    local board=style=="Skater" and not falling and virtual.props~=false
    local rlow=bottom(r,legCF(r,posed,true))
    local llow=bottom(l,legCF(l,posed,true))
    if board or style=="Harpy Glide" and not airborne then
     local low=math.min(rlow,llow)
     for _,m in {r,l} do
      local d=low-bottom(m,legCF(m,posed,true))
      local localDelta=posed:VectorToObjectSpace(Vector3.new(0,d,0))
      m.Transform=m.C0.Rotation:Inverse()*CFrame.new(localDelta)*m.C0.Rotation*m.Transform
     end
     rlow=bottom(r,legCF(r,posed,true));llow=bottom(l,legCF(l,posed,true))
    end
    local floor=math.min(bottom(r,legCF(r,neutral,false)),bottom(l,legCF(l,neutral,false)))
    local low=math.min(rlow,llow)
    local hover=if style=="Godly Aura" then .16+.045*math.sin(signaturePhase*2*math.pi) elseif board then .40 else 0
    local dy=0
    if not airborne then
     dy=floor-low+hover*weight
    elseif virtual.loopAir then
     local h=if jumping then 1.7*math.sin(math.pi*airProgress) else 1.7*(1-airProgress*airProgress)
     dy=floor-low+h+hover*weight
     if style=="Harpy Glide" and jumping then dy=1.8*math.sin(math.pi*airProgress)+.85 end
    else
     dy=hover*weight
    end
    root.Transform=root.C0.Rotation:Inverse()*CFrame.new(0,dy,0)*root.C0.Rotation*root.Transform
   end
   self.signatureActive=true;self.airProgress=airProgress
   return
  end
 else
  self.wasAir=false;self.airTime=0
 end
 local r6Origin=fullPreview and hum.RigType==Enum.HumanoidRigType.R6
 local origin=MotionPacks.origin(style)
 local originAmount=math.clamp((virtual and virtual.originStrength or 100)/100,0,1)*weight
 local family=origin[9]
 local trajectory=tracks[family] or tracks.step
 local cycle=ph/(2*math.pi)
 local function originOffset(m)
  if not r6Origin or originAmount<=0 then return Vector3.zero end
  local shoulder=m==j.RightShoulder or m==j.LeftShoulder
  local hip=m==j.RightHip or m==j.LeftHip
  local side=if m==j.RightShoulder or m==j.RightHip then 1 else -1
  local paired=family=="paired"
  local t=cycle+(if side<0 and not paired then .5 else 0)
  local walk=if moving>.08 then .35+.65*moving else 0
  local run=if virtual.speed and virtual.speed>19 then 1.18 else 1
  local foot=curve(trajectory.z,t)
  local lift=curve(trajectory.y,t)
  local arm=curve(trajectory.z,t+.5)
  local sx,sy,sz=0,0,0
  if shoulder then
   sx=side*origin[5]*(.65+.35*math.abs(wave))
   sy=origin[2]*(.18+.82*lift)*walk
   sz=-origin[7]-origin[1]*arm*walk*run
   if family=="sweep" then sx+=side*.045*math.sin(ph*.5+side) end
   if airborne then sy+=.10;sz-=if jumping then .12 else .04 end
   if climbing or swimming then sy+=.12+.07*wave*side;sz-=.14 end
  elseif hip then
   local buoyant=family=="float" or paired
   local motion=if buoyant then .5+.5*walk else walk
   sx=side*(if family=="skate" then .045+.10*lift else .015+.025*lift)*motion
   sy=origin[4]*lift*motion*run
   sz=-origin[8]-origin[3]*foot*motion*run
   if airborne then sy+=.12;sz-=if jumping then .10*side+.08 else .04 end
   if climbing then sy+=.13+.09*wave*side end
  elseif m==j.Root then
   sx=origin[6]*math.sin(ph)*walk
   sy=if family=="hop" or family=="skip" or family=="prance" then .075*math.abs(cross)*walk else 0
   sz=if family=="stride" then -.055*walk else 0
  elseif m==j.Neck then
   sx=-origin[6]*.16*wave*walk
   sz=origin[7]*.12
  end
  -- Scale with R6 body dimensions; never change the base C0 or Part sizes.
  local rigScale=if m.Part0 then math.clamp(m.Part0.Size.Y/2,.65,1.6) else 1
  return Vector3.new(sx,sy,sz)*originAmount*rigScale
 end
 -- In the isolated viewport, author full poses in body-part axes. R6 uses
 -- rotated C0 joint frames, so transform the pose into each motor's basis.
 -- Keep the existing additive live-character behavior unchanged.
 local function pose(m,cf)
  if not m or not m.Parent then return end
  if not fullPreview then add(m,cf);return end
  local x,y,z=cf:ToOrientation()
  local isShoulder=m==j.RightShoulder or m==j.LeftShoulder
  local isHip=m==j.RightHip or m==j.LeftHip
  local isElbow=m==j.RightElbow or m==j.LeftElbow
  if isShoulder or isHip then z=-z end
  if isElbow then x=-x end
  local limb=isShoulder or isHip or isElbow or m==j.RightKnee or m==j.LeftKnee or m==j.RightAnkle or m==j.LeftAnkle
  local gain=if limb then 2.35 elseif m==j.Root then 1.8 else 1.65
  local rx=math.clamp(x*gain,-1.7,1.7)
  local ry=math.clamp(y*gain,-1.2,1.2)
  local rz=math.clamp(z*gain,-1.5,1.5)
  local basis=m.C0.Rotation
  local body=CFrame.new(cf.Position*(if m==j.Root then 2 else 1.4)+originOffset(m))*CFrame.fromOrientation(rx,ry,rz)
  m.Transform=m.Transform*basis:Inverse()*body*basis
 end
 local add=pose
 if fullPreview and (airborne or climbing or swimming) then
  -- Full-body state-specific choreography; these are original preview poses.
  local st=pack or {}
  local flair=math.clamp((st.spread or .12)*.32,0,.2)
  local airRest=st.rest or 0;local airLean=st.lean or 0;local airStride=st.stride or .20;local airRoll=st.roll or .04
  local function ang(m,x,y,z) add(m,CFrame.Angles(x*weight,y*weight,z*weight)) end
  if swimming then
   local stroke=math.sin(ph*.8)
   add(j.Root,CFrame.Angles(-.55*weight,0,.07*wave*weight))
   ang(j.RightShoulder,.65+.22*stroke,.12,-.16-flair)
   ang(j.LeftShoulder,.65-.22*stroke,-.12,.16+flair)
   ang(j.RightElbow,-.45-.12*stroke,0,0);ang(j.LeftElbow,-.45+.12*stroke,0,0)
   ang(j.RightHip,.27*wave,0,0);ang(j.LeftHip,-.27*wave,0,0)
   ang(j.RightKnee,-.22-.14*cross,0,0);ang(j.LeftKnee,-.22+.14*cross,0,0)
   ang(j.Neck,.22,0,0)
  elseif climbing then
   local lift=math.sin(ph*.85)
   add(j.Root,CFrame.new(0,.07*math.abs(cross)*weight,0)*CFrame.Angles(.07*weight,0,0))
   ang(j.RightShoulder,.58+.23*lift,.08,-.13-flair)
   ang(j.LeftShoulder,.58-.23*lift,-.08,.13+flair)
   ang(j.RightElbow,-.36-.16*lift,0,0);ang(j.LeftElbow,-.36+.16*lift,0,0)
   ang(j.RightHip,.22+.31*lift,0,0);ang(j.LeftHip,.22-.31*lift,0,0)
   ang(j.RightKnee,-.3-.17*lift,0,0);ang(j.LeftKnee,-.3+.17*lift,0,0)
   ang(j.Neck,-.12,0,0)
  else
   local float=st.hover or 0
   local tuck=(if jumping then .18 else .06)+airStride*.45
   add(j.Root,CFrame.new(0,(if jumping then .25 else .12)*weight+float*.5*weight,0)*CFrame.Angles(((if jumping then -.12 else .10)+airLean)*weight,0,(.035+airRoll*.4)*wave*weight))
   ang(j.RightShoulder,(if jumping then .48 else .16)+airRest,0,-.29-flair)
   ang(j.LeftShoulder,(if jumping then .38 else .16)+airRest,0,.29+flair)
   ang(j.RightElbow,-.24,0,0);ang(j.LeftElbow,-.24,0,0)
   ang(j.RightHip,tuck+.10,0,0);ang(j.LeftHip,tuck-.08,0,0)
   ang(j.RightKnee,-tuck-.12,0,0);ang(j.LeftKnee,-tuck,0,0)
   ang(j.Neck,if jumping then -.07 else .07,0,0)
  end
  return
 end
 if pack then
  -- Original procedural interpretation of an avatar pack (not purchased clips).
  -- Each state has its own posture, on both R6 and R15; optional joints on R15.
  local snap=pack.snap or 0
  local stepped=if wave>=0 then math.sqrt(wave) else -math.sqrt(-wave)
  local gait=wave*(1-snap)+stepped*snap
  local stride=if airborne then .08 elseif climbing then .25
   elseif swimming then .15 else pack.stride
  local walk=if airborne then .14 elseif moving>.08 then moving else 0
  local run=if moving>.08 and ((virtual and virtual.speed or hum.WalkSpeed)>19) then 1 else 0
  local cycle=gait*walk
  local swing=stride*cycle*(1+run*.3)
  local pitch=pack.lean*(if moving>.08 or airborne then 1 else .32)
  local roll=(pack.roll or 0)*math.sin(ph*.5)*(.32+walk*.68)
  local twist=(pack.twist or 0)*cycle
  local hover=pack.hover or 0
  local floatY=hover*(.75+.25*math.sin(ph*.53))
  local bounce=(pack.bob or .03)*math.abs(cross)*walk
  local jumpAngle=if jumping then -.13 elseif falling then .12 else 0
  local rest=pack.rest or 0
  local spread=pack.spread or 0
  local arms=pack.arms or .2
  local armCycle=cycle*arms
  local idleWave=math.sin(ph*.65)*.045
  if swimming then
   pitch=-.22
   armCycle=math.cos(ph)*.18
   spread+=.30
  elseif climbing then
   pitch=.08
   armCycle=math.cos(ph)*.31
   swing=math.sin(ph)*.21
  elseif airborne then
   spread+=.11
   rest-=.12
  end
  if style=="Ninja" then
   -- Quiet forward lean and arms back, restrained footfall.
   rest-=.12*walk;pitch+=.085*walk;roll*=.5
  elseif style=="Bubbly" or style=="Cartoony" then
   bounce*=1.16
   spread+=math.abs(cross)*.09*walk
  elseif style=="Robot" or style=="Toy" then
   -- Sharper cadence with an intentionally stiff trunk.
   roll*=.35
   twist*=.35
  elseif style=="Stylish" then
   roll+=.045
   twist+=.02
  elseif style=="Zombie" then
   -- Uneven, slow shuffling gait.
   swing*=.72
   rest+=.08
   pitch+=.08
  elseif style=="Mage" or style=="Levitation" or style=="Astronaut" then
   -- Soft sustained buoyancy even at rest. No physical lift.
   swing*=.45
   rest-=.09
  end
  -- UGC-inspired choreography. These are ORIGINAL and purposely subtle
  -- additive poses; we do not download or replay creator animation clips.
  local mode=pack.mode
  local bodyShift=0
  local headPitch=0
  local headRoll=0
  local hipPair=0
  local hipSide=0
  local armYaw=0
  local elbowBend=0
  local kneeBend=0
  local rootRoll=0
  local shoulderAsym=0
  if mode=="angel" then
   -- Open shoulders with feather-light landing and a hovering silhouette.
   spread+=.13;rest-=.09;floatY+=math.sin(ph*.5)*.04
   armYaw=math.sin(ph*.42)*.08;hipPair=.13;headPitch=-.045
  elseif mode=="bat" then
   -- Sweeping wings, low forward soar, pitched fall recovery.
   spread+=math.sin(ph*1.1)*.16
   rest-=.13*walk;pitch+=.11*walk
   shoulderAsym=math.sin(ph*1.3)*.14
   rootRoll=math.sin(ph*.4)*.055
  elseif mode=="mermaid" then
   -- Paired legs form a tail-like wave, without changing the avatar's rig.
   swing*=.12;hipPair=.08+math.sin(ph*.76)*.21
   kneeBend=-.16-.12*math.sin(ph*.8)
   rootRoll=math.sin(ph*.5)*.12
   armYaw=math.sin(ph*.7)*.13
  elseif mode=="serpent" then
   -- Smooth S-curves along torso and alternating shoulder/hip yaw.
   swing*=.5;twist+=math.sin(ph*.5)*.17
   rootRoll=math.sin(ph*.5+.6)*.085
   bodyShift=math.sin(ph*.5)*.065
   armYaw=math.sin(ph*.5+.9)*.17
  elseif mode=="cartwheel" then
   -- Suggestive rolling acrobatic pose; no physical tumbling.
   rootRoll=math.sin(ph*.54)*.22*walk
   spread+=.22
   armYaw=math.sin(ph*.54)*.15
   hipSide=.13*math.cos(ph*.54)*walk
  elseif mode=="rubber" then
   -- Rubber-hose, overshooting arms and exaggerated stretch-squash.
   bounce*=1.4
   rootRoll=math.sin(ph*.77)*.09
   elbowBend=-.28+.16*math.sin(ph*1.4)
   hipPair=math.abs(math.sin(ph))*.08*walk
  elseif mode=="sleep" then
   -- Drifting doze with tucked arms and gently dangling feet.
   pitch-=.09;headPitch=.19;rest+=.18
   spread-=.09;hipPair=.12;kneeBend=-.25
   rootRoll=math.sin(ph*.3)*.09
  elseif mode=="plush" then
   -- Rounded plush-toy posture and tiny alternating feet.
   swing*=.48;rest+=.18
   elbowBend=-.35;hipPair=.09;headPitch=-.05
   bounce*=1.15
  elseif mode=="paws" then
   -- Cat-paw elbows and quick foot-taps.
   rest+=.14;elbowBend=-.42
   armYaw=.12;headRoll=math.sin(ph*.6)*.07
   swing*=.74;bounce*=1.09
  elseif mode=="shy" then
   -- Small crossed-in arms, inward-looking posture.
   rest+=.20;spread-=.07;elbowBend=-.28
   headPitch=.09;hipSide=-.09
   bodyShift=math.sin(ph*.65)*.032
  elseif mode=="gymnast" then
   -- Open arms and controlled lateral balance.
   spread+=.25;armYaw=.16*math.sin(ph*.8)
   rootRoll=math.sin(ph*.6)*.13
   hipSide=math.sin(ph*.6)*.13
   kneeBend=-math.abs(math.sin(ph*.5))*.12
  elseif mode=="skip" then
   -- Distinct skipping rhythm: hop on alternate steps.
   bounce+=math.max(0,math.sin(ph))*.095*walk
   hipPair=math.max(0,math.sin(ph))*.11*walk
   shoulderAsym=.13*math.sin(ph)
  elseif mode=="prance" then
   -- High light steps with upright neck and extra knee lift.
   swing*=1.15;bounce*=1.17
   kneeBend=-math.max(0,math.sin(ph))*.17*walk
   headPitch=-.075;spread+=.09
  elseif mode=="fighter" then
   -- A balanced athletic guard and precise quick steps.
   rest+=.13;elbowBend=-.42
   spread+=.07;pitch+=.08*walk
   kneeBend=-.08;rootRoll=math.sin(ph)*.045*walk
  elseif mode=="harpy" then
   -- Hovering upper arms resembling wings with descending swoop.
   spread+=.21;floatY+=.045*math.sin(ph*.6)
   rest-=.15;shoulderAsym=.13*math.sin(ph*1.1)
   hipPair=.15
  elseif mode=="aura" then
   -- Centered ceremonial float with circling arms.
   spread+=.21;armYaw=math.sin(ph*.4)*.22
   rootRoll=math.sin(ph*.4)*.035
   floatY+=.06*math.sin(ph*.45);headPitch=-.055
  elseif mode=="wavy" then
   -- Asymmetric hand and hip waves.
   armYaw=math.sin(ph*.6)*.19
   bodyShift=math.sin(ph*.7)*.055
   rootRoll=math.sin(ph*.8)*.12
   elbowBend=-.15+.08*math.sin(ph*.8)
  elseif mode=="shuffle" then
   -- Uneven shamble with heavy shoulder tilt.
   swing*=.6;rest+=.12
   headRoll=.08+math.sin(ph*.42)*.07
   rootRoll=math.sin(ph*.64)*.10
   hipSide=.06
  elseif mode=="bashful" then
   -- Expressive folded arms and shifting weight.
   rest+=.14;elbowBend=-.33
   armYaw=.09;headRoll=-.09+.06*math.sin(ph*.4)
   bodyShift=math.sin(ph*.6)*.045
  elseif mode=="doll" then
   -- Doll-like posture with semi-stiff wrists and pointed step.
   swing*=.67;rest+=.08
   headPitch=-.045;elbowBend=-.16
   hipSide=.055;rootRoll=math.sin(ph*.55)*.065
  elseif mode=="skate" then
   -- Push and glide alternating weight to the sides.
   swing*=.50;bodyShift=math.sin(ph*.74)*.11*walk
   rootRoll=-math.sin(ph*.74)*.07
   hipSide=math.sin(ph*.74)*.15
   spread+=.08;pitch+=.055*walk
  elseif mode=="waddle" then
   -- Side-by-side wobble with little flapping arms.
   swing*=.60;rootRoll=math.sin(ph)*.13
   spread+=.19;shoulderAsym=math.cos(ph)*.16
   bounce*=1.12;hipSide=.10
  elseif mode=="head" then
   -- Floating presentation focused on head and shoulder gestures.
   swing*=.18;hipPair=.16
   headRoll=math.sin(ph*.42)*.16
   headPitch=math.sin(ph*.56)*.06
   spread+=.12
  elseif mode=="dark" then
   -- Cloak-like drawn-back arms, angled float.
   rest-=.18;spread+=.13
   armYaw=-.09;headPitch=.07
   floatY+=math.sin(ph*.4)*.035
  elseif mode=="anime" then
   -- Forward heroic sprint, wind-swept arms and high steps.
   pitch+=.16*walk;rest-=.18*walk
   swing*=1.18;hipPair=.07
   elbowBend=-.15;rootRoll=.035*math.sin(ph)
  elseif mode=="ghost" then
   -- Dissolving-looking drift represented with shoulder and head sways.
   swing*=.10;hipPair=.12
   bodyShift=math.sin(ph*.42)*.085
   headRoll=math.sin(ph*.4+.7)*.13
   rootRoll=math.sin(ph*.5)*.08
  end
  local r6=hum.RigType==Enum.HumanoidRigType.R6
  local scale=if r6 and not fullPreview then .78 else 1
  local leftKnee=-(pack.knee or 0)*(.3+.7*math.max(0,-gait))*walk+kneeBend
  local rightKnee=-(pack.knee or 0)*(.3+.7*math.max(0,gait))*walk+kneeBend
  if airborne then rightKnee-=.13;leftKnee-=.13 end
  add(j.Root,CFrame.new(bodyShift*weight,(floatY+bounce)*weight,0)
    *CFrame.Angles((pitch+jumpAngle)*weight,twist*.38*weight,(roll*.5+rootRoll)*weight))
  add(j.Waist,CFrame.Angles((-pitch*.34+idleWave*.3)*weight,twist*weight,(roll+rootRoll*.45)*weight))
  add(j.Neck,CFrame.Angles((-pitch*.25+idleWave+headPitch)*weight,-twist*.4*weight,(-roll*.35+headRoll)*weight))
  add(j.RightHip,CFrame.Angles((swing+jumpAngle*.45+hipPair)*weight*scale,0,(-spread*.14+roll*.25+hipSide)*weight))
  add(j.LeftHip,CFrame.Angles((-swing+jumpAngle*.45+hipPair)*weight*scale,0,(spread*.14+roll*.25-hipSide)*weight))
  add(j.RightShoulder,CFrame.Angles((rest-armCycle+idleWave+shoulderAsym)*weight*scale,armYaw*weight,(-spread+roll*.14)*weight))
  add(j.LeftShoulder,CFrame.Angles((rest+armCycle-idleWave-shoulderAsym)*weight*scale,-armYaw*weight,(spread+roll*.14)*weight))
  add(j.RightElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33+elbowBend)*weight,0,0))
  add(j.LeftElbow,CFrame.Angles((-.055-(pack.knee or 0)*.33+elbowBend)*weight,0,0))
  add(j.RightKnee,CFrame.Angles(rightKnee*weight,0,0))
  add(j.LeftKnee,CFrame.Angles(leftKnee*weight,0,0))
  add(j.RightAnkle,CFrame.Angles(((pack.ankle or 0)*gait*walk)*weight,0,0))
  add(j.LeftAnkle,CFrame.Angles((-(pack.ankle or 0)*gait*walk)*weight,0,0))
 elseif floating then
  -- The floating pose is visible at rest and in air; no physical elevation.
  local spread=if style=="Ethereal" then .37 elseif style=="Glide" then .16 else .22
  local graceful=if style=="Ethereal" then 1.18 elseif style=="Glide" then .9 else .75
  local hover=math.sin(ph)*.065*graceful
  local lean=math.clamp(moving*(if style=="Glide" then .19 else .105),0,.22)
  local foot=if style=="Ethereal" then .26 else .15
  local back=if style=="Glide" then -.25 else .03
  add(j.Root,CFrame.new(0,(.13+hover)*weight,0)*CFrame.Angles(lean*weight,math.sin(ph*.5)*.045*weight,math.sin(ph*.65)*.045*weight))
  add(j.Waist,CFrame.Angles((-lean*.48+wave*.025)*weight,math.sin(ph*.55)*.045*weight,-wave*.06*weight))
  add(j.Neck,CFrame.Angles((-lean*.18+math.sin(ph+.5)*.03)*weight,0,math.sin(ph*.5)*.045*weight))
  -- Loose, buoyant shoulders: R6 and R15 both have shoulder motors.
  add(j.RightShoulder,CFrame.Angles((back+wave*.1)*weight,0,(-spread+cross*.10)*weight))
  add(j.LeftShoulder,CFrame.Angles((back-wave*.1)*weight,0,(spread-cross*.10)*weight))
  add(j.RightElbow,CFrame.Angles(-.21*weight,0,.09*weight))
  add(j.LeftElbow,CFrame.Angles(-.21*weight,0,-.09*weight))
  add(j.RightHip,CFrame.Angles((.12+wave*.13*graceful)*weight,0,.10*weight))
  add(j.LeftHip,CFrame.Angles((.12-wave*.13*graceful)*weight,0,-.10*weight))
  add(j.RightKnee,CFrame.Angles((-foot-wave*.07)*weight,0,0))
  add(j.LeftKnee,CFrame.Angles((-foot+wave*.07)*weight,0,0))
  add(j.RightAnkle,CFrame.Angles((foot*.53+wave*.035)*weight,0,0))
  add(j.LeftAnkle,CFrame.Angles((foot*.53-wave*.035)*weight,0,0))
 else
  -- Natural / Heroic / Bouncy: subtle animation layered over existing walk.
  local power=if fullPreview then (if style=="Heroic" then .37 elseif style=="Bouncy" then .32 else .29) else (if style=="Heroic" then .22 elseif style=="Bouncy" then .21 else .15)
  local leg=wave*power*weight*(if fullPreview then moving else 1)
  local arm=-leg*.82
  local dip=(if style=="Bouncy" then .085 else .036)*math.abs(cross)*weight*(if fullPreview then .2+.8*moving else 1)
  local twist=wave*(if style=="Heroic" then .09 else .043)*weight*(if fullPreview then .2+.8*moving else 1)
  add(j.RightHip,CFrame.Angles(leg,0,0))
  add(j.LeftHip,CFrame.Angles(-leg,0,0))
  add(j.RightShoulder,CFrame.Angles(arm,0,twist*.32))
  add(j.LeftShoulder,CFrame.Angles(-arm,0,-twist*.32))
  add(j.RightKnee,CFrame.Angles(-math.max(0,-leg)*.2,0,0))
  add(j.LeftKnee,CFrame.Angles(-math.max(0,leg)*.2,0,0))
  add(j.Waist,CFrame.new(0,dip,0)*CFrame.Angles(dip*.18,twist,0))
  add(j.Neck,CFrame.Angles(0,-twist*.36,0))
  add(j.Root,CFrame.new(0,dip*.5,0)*CFrame.Angles(0,twist*.55,0))
 end
 if fullPreview and style=="Cartwheel Flow" and moving>.08 and j.Root then
  -- Full cartwheel roll is confined to the isolated GUI rig.
  local basis=j.Root.C0.Rotation
  j.Root.Transform=j.Root.Transform*basis:Inverse()*CFrame.Angles(0,0,ph*.52)*basis
 end
end
function W:destroy()
 self:restoreLive();table.clear(self.livePose)
 self.character=nil
 table.clear(self.motors)
end
return W
