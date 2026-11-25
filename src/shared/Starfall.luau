-- Local cosmetic falling stars; pooled, anchored, non-colliding geometry.
local U=require(script.Parent.Util)
local Input=game:GetService("UserInputService")
local Shapes=require(script.Parent.FxShapes)
local F={};F.__index=F
local RNG=Random.new()
local MAX_STARS=16
local fillCache={}
local function triangle(fill,a,b,c)
 local ab,ac,bc=b-a,c-a,c-b
 local ab2,ac2,bc2=ab:Dot(ab),ac:Dot(ac),bc:Dot(bc)
 if ab2>ac2 and ab2>bc2 then c,a=a,c
 elseif ac2>bc2 then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit
 local up=bc:Cross(right).Unit
 local back=bc.Unit
 local height=math.abs(ab:Dot(up))
 local function add(position,x,y,z,length)
  if height>.0001 and length>.0001 then
   fill[#fill+1]={cf=CFrame.fromMatrix(position,x,y,z),height=height,length=length}
  end
 end
 add((a+b)*.5,right,up,back,math.abs(ab:Dot(back)))
 add((a+c)*.5,-right,up,-back,math.abs(ac:Dot(back)))
end
local function geometry(name)
 if fillCache[name] then return fillCache[name] end
 local outline=Shapes.outline(name)
 local fill={}
 -- Heart is star-shaped about this interior point, with the notch above it.
 for i,p in outline do triangle(fill,Vector3.zero,p,outline[i%#outline+1]) end
 fillCache[name]=fill
 return fill
end
local function fillPart(parent)
 return U.new("WedgePart",{Name="StarFill",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(.1,.1,.1),Material=Enum.Material.Neon},parent)
end
local function part(parent,shape)
 return U.new("Part",{Name="StarRay",Shape=shape or Enum.PartType.Block,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(.1,.1,.1),Material=Enum.Material.Neon},parent)
end
local function segment(p,a,b,width)
 local d=b-a
 if d.Magnitude<.001 then p.Transparency=1;return false end
 local cf=CFrame.lookAt((a+b)*.5,b,if math.abs(d.Unit.Y)>.98 then Vector3.xAxis else Vector3.yAxis)
 if p.Shape==Enum.PartType.Cylinder then
  p.Size=Vector3.new(d.Magnitude,width,width)
  p.CFrame=cf*CFrame.Angles(0,math.pi/2,0)
 else
  p.Size=Vector3.new(width,width,d.Magnitude)
  p.CFrame=cf
 end
 return true
end
function F.new() return setmetatable({pool={}},F) end
function F:clear()
 if self.root then self.root:Destroy();self.root=nil end
 table.clear(self.pool);self.camera=nil;self.last=nil
end
function F:spawn(star,cam,initial)
 local origin=cam.CFrame.Position
 local forward=cam.CFrame.LookVector*Vector3.new(1,0,1)
 if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
 local right=Vector3.new(-forward.Z,0,forward.X)
 star.pos=origin+forward*RNG:NextNumber(15,85)+right*RNG:NextNumber(-65,65)+Vector3.new(0,if initial then RNG:NextNumber(-10,70) else RNG:NextNumber(45,80),0)
 star.age=0;star.scale=RNG:NextNumber(.65,1.3);star.speed=RNG:NextNumber(.7,1.35);star.phase=RNG:NextNumber(0,math.pi*2);star.tint=RNG:NextNumber();star.spinDirection=if RNG:NextNumber()<.5 then -1 else 1;star.kind=Shapes.names[RNG:NextInteger(1,#Shapes.names)]
end
function F:step(s,now)
 local cam=workspace.CurrentCamera
 if not s.starfall or s.reduce or not cam then if self.root then self:clear() end;return end
 if cam~=self.camera then self:clear();self.camera=cam end
 if not self.root then self.root=U.new("Folder",{Name="AetherStarfall"},cam) end
 local dt=math.clamp(now-(self.last or now),0,.1);self.last=now
 local count=math.clamp(math.floor(s.starfallCount),1,if Input.TouchEnabled and not Input.KeyboardEnabled then 8 else MAX_STARS)
 local colorA,colorB=U.hex(s.starfallA),U.hex(s.starfallB)
 local material=Enum.Material[s.starfallMaterial] or Enum.Material.Neon
 if material==Enum.Material.Neon and s.starfallGlow==0 then material=Enum.Material.SmoothPlastic end
 while #self.pool<count do
  local star={rays={}}
  star.tail=part(self.root)
  self:spawn(star,cam,true);self.pool[#self.pool+1]=star
 end
 for i,star in self.pool do
  if i>count then for _,p in star.rays do p.Transparency=1 end;star.tail.Transparency=1;continue end
  star.age+=dt
  star.pos+=Vector3.new(2*dt,-s.starfallSpeed*star.speed*dt,0)
  if star.pos.Y<cam.CFrame.Position.Y-25 or (star.pos-cam.CFrame.Position).Magnitude>150 or star.age>12 then self:spawn(star,cam,false) end
  local r=s.starfallSize/10*star.scale
  local opacity=s.starfallOpacity/100
  local tint=if s.starfallRainbow then Color3.fromHSV((now*.12+star.tint)%1,.55,1) else colorA:Lerp(colorB,star.tint)
  star.phase=(star.phase+dt*math.rad(s.starfallRotation)*star.spinDirection)%(2*math.pi)
  local cf=CFrame.new(star.pos)*cam.CFrame.Rotation*CFrame.Angles(0,0,star.phase)
  local kind=if s.starfallShape=="Mixed" then star.kind else s.starfallShape
  local fill=geometry(kind)
  while #star.rays<#fill do star.rays[#star.rays+1]=fillPart(self.root) end
  for j=#fill+1,#star.rays do star.rays[j].Transparency=1 end
  local thickness=math.max(.045,r*.22)
  for j,shape in fill do
   local p=star.rays[j]
   if star.renderRadius~=r or star.renderKind~=kind then
    p.Size=Vector3.new(thickness,shape.height*r,shape.length*r)
   end
   p.CFrame=cf*CFrame.new(shape.cf.Position*r)*shape.cf.Rotation
   if p.Color~=tint then p.Color=tint end
   if p.Material~=material then p.Material=material end
   if p.Transparency~=1-opacity then p.Transparency=1-opacity end
  end
  star.renderRadius=r;star.renderKind=kind
  local tail=star.tail
  if s.starfallTail then
   local len=math.min(10,s.starfallSpeed*.12)
   if segment(tail,star.pos+Vector3.new(0,r*.5,0),star.pos+Vector3.new(0,r+len,0),math.max(.04,r*.08)) then tail.Material=material;tail.Color=tint;tail.Transparency=1-opacity*.35 end
  else tail.Transparency=1 end
 end
end
return F
