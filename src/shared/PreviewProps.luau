-- Local decorative props for the viewport and the local avatar. No Tools, hitboxes or collision.
local P={};P.__index=P
local function part(parent,name,size,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
local violet=Color3.fromRGB(149,107,230)
local pale=Color3.fromRGB(218,191,255)
local dark=Color3.fromRGB(40,33,55)
function P.new(parent,live) return setmetatable({parent=parent,live=live==true},P) end
function P:clear() if self.root then self.root:Destroy() end;self.root=nil;self.kind=nil;self.parts=nil end
function P:build(kind)
 self:clear();self.kind=kind
 local root=Instance.new("Folder");root.Name=if self.live then "AetherMotionProps" else "AetherPreviewProps";root.Parent=self.parent;self.root=root
 local items={};self.parts=items
 if kind=="Skater" then
  items.deck=part(root,"FantasyDeck",Vector3.new(1.45,.14,3.55),violet)
  items.grip=part(root,"DeckTop",Vector3.new(1.34,.025,3.42),dark)
  items.ends={}
  for i=1,2 do items.ends[i]=part(root,"RoundedDeckEnd",Vector3.new(.14,1.45,.48),violet,Enum.PartType.Cylinder) end
  items.wheels={}
  for i=1,4 do items.wheels[i]=part(root,"DecorativeWheel",Vector3.new(.27,.38,.38),pale,Enum.PartType.Cylinder) end
 elseif kind=="Doll Walk" then
  items.bar=part(root,"PuppetBar",Vector3.new(2.5,.10,.16),dark)
  items.cross=part(root,"PuppetCross",Vector3.new(.16,.10,1.6),dark)
  items.strings={}
  for i=1,5 do items.strings[i]=part(root,"PuppetThread",Vector3.new(.025,.025,1),pale) end
 elseif kind=="Fighter" then
  items.handle=part(root,"FantasyPropGrip",Vector3.new(.21,.91,.21),dark)
  items.guard=part(root,"FantasyPropOrnament",Vector3.new(.65,.12,.24),violet)
  items.blade=part(root,"FantasyLightBlade",Vector3.new(.24,2.05,.10),pale)
  items.blade.Material=Enum.Material.Neon
  items.tip=part(root,"FantasyLightTip",Vector3.new(.18,.18,.18),pale,Enum.PartType.Ball)
  items.tip.Material=Enum.Material.Neon
 end
end
local function line(p,a,b)
 local d=b-a;p.Size=Vector3.new(.025,.025,math.max(.025,d.Magnitude));p.CFrame=CFrame.lookAt((a+b)/2,b)
end
function P:update(rig,kind,phase,state)
 local function limb(a,b)
  return rig and (rig:FindFirstChild(a) or rig:FindFirstChild(b))
 end
 local torso=limb("Torso","UpperTorso")
 local ra=limb("Right Arm","RightHand")
 local la=limb("Left Arm","LeftHand")
 local rl=limb("Right Leg","RightFoot")
 local ll=limb("Left Leg","LeftFoot")
 local r6=ra and ra.Name=="Right Arm"
 local head=rig and rig:FindFirstChild("Head")
 local root=rig and rig:FindFirstChild("HumanoidRootPart")
 if not torso or not ra or not la or not rl or not ll or not head or not root or (kind~="Skater" and kind~="Doll Walk" and kind~="Fighter") then self:clear();return end
 if self.kind~=kind or not self.root or self.root.Parent~=self.parent then self:build(kind) end
 local q=self.parts
 local suspended=state==Enum.HumanoidStateType.Climbing or state==Enum.HumanoidStateType.Swimming
 local function grip(arm,side,target)
  if self.live or not r6 or suspended then return end
  local shoulder=torso.CFrame:PointToWorldSpace(Vector3.new(side*(torso.Size.X/2+arm.Size.X*.35),torso.Size.Y*.25,0))
  local d=target-shoulder;if d.Magnitude<.001 then return end
  local y=-d.Unit;local x=y:Cross(torso.CFrame.LookVector)
  if x.Magnitude<.001 then x=y:Cross(torso.CFrame.UpVector) end
  if x.Magnitude<.001 then return end
  x=x.Unit;local z=x:Cross(y).Unit
  arm.CFrame=CFrame.fromMatrix(target+y*(arm.Size.Y/2),x,y,z)
 end
 if kind=="Skater" and suspended then self:clear();return end
 if kind=="Fighter" then
  local cf=torso.CFrame*CFrame.new(0,-.12,-1.26)*CFrame.Angles(math.rad(-22),0,math.rad(-13))
  if self.live or not r6 or suspended then
   -- Follow the actual hand, not the other way around.
   local hand=ra.CFrame*CFrame.new(0,-ra.Size.Y*(if r6 then .5 else .1),0)
   cf=hand*CFrame.Angles(math.rad(-85),0,math.rad(-8))*CFrame.new(0,-.23,0)
  else
   grip(ra,1,cf:PointToWorldSpace(Vector3.new(0,.23,0)))
   grip(la,-1,cf:PointToWorldSpace(Vector3.new(0,-.23,0)))
  end
  q.handle.CFrame=cf;q.guard.CFrame=cf*CFrame.new(0,.48,0);q.blade.CFrame=cf*CFrame.new(0,1.56,0);q.tip.CFrame=cf*CFrame.new(0,2.58,0)
 elseif kind=="Doll Walk" then
  local bar=CFrame.new(head.Position+Vector3.new(.08*math.sin(phase),1.65,0))*root.CFrame.Rotation*CFrame.Angles(0,0,.12*math.sin(phase))
  q.bar.CFrame=bar;q.cross.CFrame=bar
  local targets={ra.CFrame:PointToWorldSpace(Vector3.new(0,-ra.Size.Y/2,0)),la.CFrame:PointToWorldSpace(Vector3.new(0,-la.Size.Y/2,0)),head.Position+Vector3.new(0,head.Size.Y/2,0),rl.Position,ll.Position}
  local anchors={Vector3.new(1.2,0,0),Vector3.new(-1.2,0,0),Vector3.new(0,0,0),Vector3.new(.45,0,.7),Vector3.new(-.45,0,-.7)}
  for i=1,5 do line(q.strings[i],bar:PointToWorldSpace(anchors[i]),targets[i]) end
 else
  local cf
  if state==Enum.HumanoidStateType.Freefall then
   cf=torso.CFrame*CFrame.new(0,-.5,-1.35)*CFrame.Angles(math.rad(8),math.rad(90),math.rad(8))
   if self.live or not r6 then
    local hand=ra.CFrame*CFrame.new(0,-ra.Size.Y*(if r6 then .5 else .1),0)
    cf=hand*CFrame.Angles(0,math.pi/2,0)*CFrame.new(0,-.12,-1.03)
   else
    grip(ra,1,cf:PointToWorldSpace(Vector3.new(0,.12,1.03)))
    grip(la,-1,cf:PointToWorldSpace(Vector3.new(0,.12,-1.03)))
   end
  else
   local a=rl.CFrame:PointToWorldSpace(Vector3.new(0,-rl.Size.Y/2,0))
   local b=ll.CFrame:PointToWorldSpace(Vector3.new(0,-ll.Size.Y/2,0))
   local function bottom(p)
    local sz=p.Size/2;local r=p.CFrame
    return p.Position.Y-math.abs(r.RightVector.Y)*sz.X-math.abs(r.UpVector.Y)*sz.Y-math.abs(r.LookVector.Y)*sz.Z
   end
   local center=(a+b)/2
   local z=Vector3.new(a.X-b.X,0,a.Z-b.Z)
   if z.Magnitude<.001 then local f=root.CFrame.LookVector;z=Vector3.new(f.X,0,f.Z) end
   if z.Magnitude<.001 then z=Vector3.new(0,0,-1) end
   z=z.Unit;local y=Vector3.yAxis;local x=y:Cross(z).Unit
   cf=CFrame.fromMatrix(Vector3.new(center.X,math.min(bottom(rl),bottom(ll))-.095,center.Z),x,y,z)
  end
  q.deck.CFrame=cf;q.grip.CFrame=cf*CFrame.new(0,.08,0)
  for i=1,2 do local side=if i==1 then -1 else 1;q.ends[i].CFrame=cf*CFrame.new(0,.01,side*1.65)*CFrame.Angles(0,0,math.pi/2) end
  for i=1,4 do local x=if i%2==0 then .65 else -.65;local z=if i<3 then 1.02 else -1.02;q.wheels[i].CFrame=cf*CFrame.new(x,-.20,z)*CFrame.Angles(phase*2,0,0) end
 end
end
return P
