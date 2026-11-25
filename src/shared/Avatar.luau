local U=require(script.Parent.Util)
local S=require(script.Parent.Schema)
local A={};A.__index=A

-- Cosmetic, anchored geometry. The character's own joints, collision and animations
-- are never modified by this module. All FX are local to the AETHER client.
local function part(parent,name,size,shape,neon)
 return U.new("Part",{
  Name=name,Size=size or Vector3.one,
  Shape=shape or Enum.PartType.Block,
  Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
  CastShadow=false,Material=if neon==false then Enum.Material.SmoothPlastic else Enum.Material.Neon
 },parent)
end
local function is(style,...)
 for _,v in {...} do if style==v then return true end end
 return false
end
local wingFigures={["Prism Wings"]=3,["Triad Wings"]=3,["Hex Wings"]=6,["Star Wings"]=10,["Orbital Wings"]=16,["Diamond Wings"]=4}
local haloFigures={Triangle=3,Square=4,Pentagon=5,Hexagon=6,Octagon=8,Star=10,["Double Diamond"]=4,Infinity=40}
local function outlinePoint(index,sides,radius,star,phase)
 local angle=phase+index/sides*math.pi*2
 local r=radius*(if star and index%2==1 then .48 else 1)
 return Vector3.new(math.cos(angle)*r,math.sin(angle)*r,0)
end
local function segment(p,a,b,thick)
 local d=b-a
 if d.Magnitude<.001 then p.Transparency=1;return end
 p.Transparency=0
 p.Size=Vector3.new(thick,thick,d.Magnitude)
 p.CFrame=CFrame.lookAt((a+b)*.5,b)
end
-- Each path is traced from one half of the supplied drawing in image coordinates.
-- Mirror the path around the centre seam, retaining gaps and internal facet lines.
-- All geometry is cosmetic only: anchored, noncolliding and nonqueryable.
local sketchWings={
 ["Geo Bloom"]={origin={220,136},unit=61,colors={"D9A0FF","F4D3FF"},paths={
  {220,136,127,10,84,95,48,48,56,94,14,54,88,188,88,158,120,121,114,158,156,87,220,136},
  {120,53,125,69,136,80,123,82,123,96,115,85,108,95,111,81,104,70,116,69,120,53},
  {78,100,78,124},{67,112,89,112}
 }},
 Kagune={origin={237,345},unit=70,colors={"C91435","FF455B"},paths={
  {230,323,201,295,174,238,153,227,128,222,98,222,60,245,48,274,49,322,79,348,60,308,80,279,108,278,147,319},
  {145,312,160,296,202,331,226,335},
  {226,347,158,357,119,406,45,377,1,393,25,455,68,455,34,423,36,408,111,434,143,416,168,375,211,377,237,351},
  {212,385,193,478,128,497,166,455,199,396,212,385}
 }},
 Seraphim={origin={270,685},unit=82,colors={"F8F5FF","ACD9FF"},paths={
  {265,683,200,676,178,646,165,611,146,636,144,663},
  {174,638,159,671},{185,655,178,694},{199,676,196,707},{215,679,219,710},{235,686,229,710},
  {156,677,157,701},{181,700,189,721},{205,712,220,733},
  {265,683,247,720,184,751,121,742,48,636,12,665,1,740,25,696,64,724,89,775,60,845,99,797,75,836,116,796,91,839,132,795,108,842,148,805,125,842,197,784,179,816,249,741,265,698},
  {234,717,231,726}
 }},
 ["Burnt Fallen"]={origin={1411,12},unit=93,colors={"3D3038","BC5B43"},paths={
  {1396,2,1370,85,1335,116,1287,129,1231,120,1167,116,1128,129,1112,159,1113,199,1146,229},
  {1359,94,1380,134,1389,139},{1334,117,1364,159,1391,171},
  {1281,118,1329,173,1347,182},{1228,116,1286,201,1321,218},
  {1168,117,1212,173,1243,201},{1140,125,1160,178,1205,205},
  {1124,141,1141,195,1183,218}
 }},
 ["Knife Wing"]={origin={1507,292},unit=62,colors={"E5E8F2","889CB9"},paths={
  {1384,239,1447,346,1440,350,1428,329,1418,334,1383,272,1384,239},
  {1338,288,1426,373,1416,383,1396,361,1388,369,1340,323,1338,288},
  {1305,328,1379,389,1371,398,1357,385,1350,395,1303,354,1305,328},
  {1392,479,1330,517,1360,521,1383,506,1380,494,1395,486,1392,479},
  {1409,494,1415,495,1415,511,1424,513,1424,535,1406,551,1409,494}
 }},
 ["Crystal Wing"]={origin={1424,680},unit=90,colors={"82E5FF","B995FF"},paths={
  {1418,643,1383,646,1342,713,1410,676,1418,643},
  {1342,713,1331,674,1269,631,1241,650,1213,713,1269,677,1298,698,1342,713},
  {1269,631,1298,698,1311,762,1269,705,1269,677},
  {1213,713,1199,683,1138,673,1188,718,1213,713,1242,732,1253,791,1213,747,1213,713},
  {1188,718,1171,743,1184,813,1206,741,1188,718},
  {1311,762,1349,775,1362,844,1311,791,1311,762}
 }}
}
local function config(detail)
 if detail=="Balanced" then return 8,5,24,12
 elseif detail=="Ultra" then return 15,9,48,32
 else return 11,7,36,24 end
end
-- Original outlined geometry, independently layered over the legacy halo.
local function haloV2Paths(index,count)
 local paths={}
 local function ring(x,z,r,y,segments)
  local pts={}
  for i=0,segments do local t=i/segments*math.pi*2;pts[#pts+1]=Vector3.new(x+math.cos(t)*r,y,z+math.sin(t)*r) end
  paths[#paths+1]=pts
 end
 local function triangle(x,z,r,rot,y)
  local pts={}
  for i=0,3 do local t=rot+i/3*math.pi*2;pts[#pts+1]=Vector3.new(x+math.cos(t)*r,y,z+math.sin(t)*r) end
  paths[#paths+1]=pts
 end
 if index==1 or index==6 then
  for n=1,count do
   local t=(n-1)/count*math.pi*2
   local r=if n%2==0 then .65 else 1.03
   local size=if n%2==0 then .24 else .43
   triangle(math.cos(t)*r,math.sin(t)*r,size,t+math.pi*.4,if index==6 then (n%3-1)*.16 else 0)
  end
 elseif index==2 or index==3 then
  ring(0,0,1.02,0,32);ring(0,0,.78,0,32)
  if index==3 then ring(0,0,.84,.28,28);ring(0,0,.65,.28,28) end
 elseif index==4 or index==5 then
  local n=if index==5 then count-1 else count
  if index==5 then ring(0,0,.29,0,16);ring(0,0,.19,0,16) end
  for j=1,n do
   local t=(j-1)/n*math.pi*2
   local orbit=if index==5 then .68 else .96
   local x,z=math.cos(t)*orbit,math.sin(t)*orbit
   local y=if index==4 then math.sin(t*2)*.13 else 0
   ring(x,z,.30,y,16);ring(x,z,.20,y,16)
  end
 else
  ring(0,0,1,0,32)
  for n=1,count do
   local t=(n-1)/count*math.pi*2;local delta=math.pi/count
   paths[#paths+1]={Vector3.new(math.cos(t-delta),0,math.sin(t-delta)),Vector3.new(math.cos(t)*1.10,.45,math.sin(t)*1.10),Vector3.new(math.cos(t+delta),0,math.sin(t+delta))}
  end
 end
 return paths
end
function A.new(parent,preview)
 return setmetatable({
  parent=parent,preview=preview,feathers={},trims={},beads={},ornaments={},
  parts={},frames={},geoWings={},geoHalos={},haloV2={},sketchEdges={},diamonds={},diamondTime={},key="",paintAt=-1,walk=0,phase=0,lastAt=nil
 },A)
end
function A:clear()
 if self.scope then self.scope:clear();self.scope=nil end
 self.root=nil;self.highlight=nil;self.emitter=nil;self.trail=nil;self.light=nil;self.neonEnergy=0;self.neonHP=nil
 self.key="";self.char=nil;self.lastAt=nil;self.walk=0;self.phase=0;self.glowKey=nil
 table.clear(self.feathers);table.clear(self.trims);table.clear(self.beads)
 table.clear(self.ornaments);table.clear(self.parts);table.clear(self.frames);table.clear(self.geoWings);table.clear(self.geoHalos);table.clear(self.haloV2);table.clear(self.sketchEdges);table.clear(self.diamonds);table.clear(self.diamondTime)
end
function A:add(partInstance)
 partInstance:SetAttribute("AetherEmissive",partInstance.Material==Enum.Material.Neon)
 table.insert(self.parts,partInstance)
 return partInstance
end
function A:bind(char,body,head,s)
 local wdetail=s.wingDetail or "High";local hdetail=s.haloDetail or "High"
 local v2Key={};local hasV2=false
 for i in S.haloV2Styles do local k="haloV2"..i
  if s[k.."Enabled"] then hasV2=true;table.insert(v2Key,k..":"..tostring(s[k.."Count"])) end
 end
 local key=table.concat({tostring(s.wings),s.wingStyle,wdetail,
  tostring(s.halo),s.haloStyle,hdetail,tostring(s.neon),tostring(s.aura),tostring(s.trail),table.concat(v2Key,",")},"/")
 if not (char and body and head) or not(s.wings or s.halo or hasV2 or s.neon or s.aura or s.trail or s.redDiamond or s.blueDiamond) then
  if self.root then self:clear() end;return
 end
 if self.key==key and self.char==char then return end
 self:clear()
 self.key=key;self.char=char;self.scope=U.scope()
 self.root=self.scope:add(U.new("Folder",{Name="AetherAvatarFX"},self.parent))
 self.paintAt=-1
 if s.wings and sketchWings[s.wingStyle] then
  local def=sketchWings[s.wingStyle]
  for _,side in {-1,1} do
   for index,path in def.paths do
    for j=1,#path-2,2 do
     local function vertex(k)
      return Vector3.new(side*(def.origin[1]-path[k])/def.unit,(def.origin[2]-path[k+1])/def.unit,0)
     end
     local p0,p1=vertex(j),vertex(j+2)
     if (p1-p0).Magnitude>.002 then
      local edge=self:add(part(self.root,"SketchWingContour",Vector3.new(.03,.03,.03),Enum.PartType.Block,true))
      edge.Transparency=1
      local glow=self:add(part(self.root,"SketchWingGlow",Vector3.new(.03,.03,.03),Enum.PartType.Block,true))
      glow.Transparency=1
      table.insert(self.sketchEdges,{p=edge,glow=glow,a=p0,b=p1,side=side,index=index})
     end
    end
   end
  end
 elseif s.wings and wingFigures[s.wingStyle] then
  local sides=wingFigures[s.wingStyle]
  local count=if wdetail=="Ultra" then 5 elseif wdetail=="Balanced" then 3 else 4
  for _,side in {-1,1} do
   for tier=1,count do
    local edges={}
    for i=1,sides do edges[i]=self:add(part(self.root,"GeometricWingEdge",Vector3.one,Enum.PartType.Block,true)) end
    local gem=self:add(part(self.root,"GeometricWingCore",Vector3.one,Enum.PartType.Ball,true))
    table.insert(self.geoWings,{side=side,tier=tier,count=count,edges=edges,gem=gem,sides=sides})
   end
  end
 elseif s.wings then
  local primary,secondary=config(wdetail)
  for _,side in {-1,1} do
   for layer,count in {primary,secondary} do
    for index=1,count do
     local sharp=is(s.wingStyle,"Blade","Crystal","Storm","Frost")
     local core=self:add(part(self.root,"FeatherBody",Vector3.one,if sharp then Enum.PartType.Block else Enum.PartType.Ball,false))
     local vein=self:add(part(self.root,"FeatherVein",Vector3.one,Enum.PartType.Block,true))
     local tip=nil
     if index%3==1 then tip=self:add(part(self.root,"FeatherGlimmer",Vector3.one,Enum.PartType.Ball,true)) end
     table.insert(self.feathers,{core=core,vein=vein,tip=tip,index=index,count=count,side=side,layer=layer})
    end
   end
   -- Tiny ornamentation along the base makes the feathers read as attached wings.
   for i=1,5 do
    local p=self:add(part(self.root,"WingFiligree",Vector3.one,Enum.PartType.Ball,true))
    table.insert(self.trims,{p=p,side=side,index=i})
   end
  end
 end
 if s.halo and haloFigures[s.haloStyle] then
  local sides=haloFigures[s.haloStyle]
  if s.haloStyle=="Infinity" then sides=if hdetail=="Balanced" then 24 elseif hdetail=="Ultra" then 48 else 40 end
  for ring=1,(if s.haloStyle=="Double Diamond" then 2 else 1) do
   local edges={}
   for i=1,sides do edges[i]=self:add(part(self.root,"GeometricHaloEdge",Vector3.one,Enum.PartType.Block,true)) end
   table.insert(self.geoHalos,{ring=ring,edges=edges,sides=sides})
  end
  for i=1,math.min(sides,8) do
   local p=self:add(part(self.root,"HaloOrbitGem",Vector3.one,Enum.PartType.Block,true))
   table.insert(self.ornaments,{p=p,index=i,count=math.min(sides,8)})
  end
 elseif s.halo then
  local _,_,outer,inner=config(hdetail)
  local second=is(s.haloStyle,"Binary","Double Ring","Solar","Lunar","Orbitals","Prism","Eclipse","Lotus")
  for ring,count in {outer,if second then inner else 0} do
   for index=1,count do
    local p=self:add(part(self.root,"HaloSegment",Vector3.one,Enum.PartType.Block,true))
    table.insert(self.beads,{p=p,ring=ring,index=index,count=count})
   end
  end
  local ornaments=if hdetail=="Ultra" then 16 elseif hdetail=="Balanced" then 8 else 12
  for i=1,ornaments do
   local style=s.haloStyle
   local p=self:add(part(self.root,"HaloGem",Vector3.one,if is(style,"Starfall","Lotus","Comet") then Enum.PartType.Ball else Enum.PartType.Block,true))
   table.insert(self.ornaments,{p=p,index=i,count=ornaments})
  end
 end
 for index in S.haloV2Styles do
  local k="haloV2"..index
  if s[k.."Enabled"] then
   local layer={index=index,paths={}}
   for _,points in haloV2Paths(index,s[k.."Count"]) do
    local edges={}
    for i=1,#points-1 do edges[i]=self:add(part(self.root,"HaloV2Outline",Vector3.one,Enum.PartType.Block,true)) end
    table.insert(layer.paths,{points=points,edges=edges})
   end
   table.insert(self.haloV2,layer)
  end
 end
 if s.neon then self.highlight=U.new("Highlight",{Name="Neon",Adornee=char,DepthMode=Enum.HighlightDepthMode.Occluded},self.root) end
 if not self.preview and (s.neon or s.aura or s.trail) then
  local a=self.scope:add(U.new("Attachment",{Name="AetherEmitter",Position=Vector3.new(0,.5,.5)},body))
  if s.neon then self.light=U.new("PointLight",{Range=9,Shadows=false},a) end
  if s.aura then self.emitter=U.new("ParticleEmitter",{
   Name="Aura",Texture="rbxasset://textures/particles/sparkles_main.dds",
   Lifetime=NumberRange.new(.55,1.3),Speed=NumberRange.new(.8,2.5),
   SpreadAngle=Vector2.new(80,80),LightEmission=.9,
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.18),NumberSequenceKeypoint.new(1,0)})
  },a) end
  if s.trail then
   local b=self.scope:add(U.new("Attachment",{Name="AetherTrailEnd",Position=Vector3.new(0,-.65,.5)},body))
   self.trail=U.new("Trail",{Name="AetherTrail",Attachment0=a,Attachment1=b,
    LightEmission=.85,MinLength=.08,FaceCamera=true,
    Transparency=NumberSequence.new(.15,1)},a)
  end
 end
end
local function wingMetrics(style,v,layer)
 local broad=is(style,"Sylph","Butterfly","Petal")
 local long=is(style,"Phoenix","Storm","Celestial","Royal")
 local dark=is(style,"Raven","Dusk","Eclipse")
 local folded=is(style,"Crystal","Blade","Frost")
 local spread=(.55+2.65*v)*(if broad then .94 else 1)
 local y=if broad then .18+math.sin(v*math.pi)*.84
  elseif long then .05+v*1.07
  elseif dark then .12-v*.58
  elseif folded then .12+v*.52
  else .2+v*.78
 local length=if broad then 1.18-v*.2
  elseif long then 2.1-v*.55
  elseif dark then 1.2+v*.82
  elseif folded then 1.48-v*.48
  else 1.72-v*.69
 local width=if broad then .39 elseif folded then .18 else .27
 if layer==2 then
  spread=spread*.68
  y-=.38
  length*=.61
  width*=.79
 end
 return spread,y,length,width
end
function A:step(char,s,t)
 local body=char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart"))
 local head=char and char:FindFirstChild("Head")
 self:bind(char,body,head,s);if not self.root then return end
 self:syncVisualGlow(s)
 local dt=math.clamp(t-(self.lastAt or t),0,.08);self.lastAt=t
 local hum=char:FindFirstChildOfClass("Humanoid")
 local running=if hum then hum.MoveDirection.Magnitude else 0
 if self.preview and s.walkAnimation then running=1 end
 if hum and (hum.Health<=0 or hum.Sit) then running=0 end
 local smooth=1-math.exp(-dt*9)
 self.walk+=(math.clamp(running,0,1)-self.walk)*smooth
 local speed=if hum then math.clamp(hum.WalkSpeed/16,.55,2) else 1
 self.phase+=dt*(7.7*speed)
 local walk=self.walk
 local time=if s.reduce then 0 else t
 if s.reduce then walk=0 end
 local walkPower=(s.walkIntensity or 65)/100
 local wingWalk=if s.wingWalk==false then 0 else walk*walkPower
 local haloWalk=if s.haloWalk==false then 0 else walk*walkPower
 local scale=s.wingSpan/100*math.clamp(body.Size.X/2,.65,1.5)
 local beat=math.sin(time*s.wingBeat*.032)*.17
 local gait=math.sin(self.phase)*wingWalk
 local bob=math.abs(math.sin(self.phase))*haloWalk
 local mount=body.CFrame*CFrame.new(0,.17,body.Size.Z*.6+.08)
 local function submit(p,cf)
  p.CFrame=cf
 end
 for _,f in self.feathers do
  local v=(f.index-1)/math.max(f.count-1,1)
  local span,y,length,width=wingMetrics(s.wingStyle,v,f.layer)
  local side=f.side
  local rhythm=beat+gait*(.12+.16*v)
  local sweep=math.rad(s.wingSweep)
  local fold=side*(sweep*.25-wingWalk*.12)
  local drift=math.sin(time*1.6+f.index*.51+f.layer)*.055*(if s.reduce then 0 else 1)
  local orientation=mount*CFrame.Angles(0,side*(rhythm-sweep)+fold,0)
    *CFrame.new(side*(.32+span)*scale,(y+drift)*scale,(if f.layer==1 then .23 else .34)*scale)
    *CFrame.Angles(.12+wingWalk*.13,side*.06,-side*(.35+v*.72+gait*.11))
  local len=length*scale
  local thick=(if f.layer==1 then .16 else .12)*scale
  local size=Vector3.new(width*scale,len,thick)
  f.core.Size=size
  submit(f.core,orientation*CFrame.new(0,len*.24,0))
  local veinLength=len*.85
  f.vein.Size=Vector3.new(math.max(.025,len*.035),veinLength,math.max(.035,thick*.35))
  submit(f.vein,orientation*CFrame.new(0,len*.24,thick*.43))
  if f.tip then
   f.tip.Size=Vector3.new(width*.32*scale,width*.32*scale,.09*scale)
   submit(f.tip,orientation*CFrame.new(0,len*.73,thick*.18))
  end
 end
 for _,f in self.geoWings do
  local v=(f.tier-1)/math.max(1,f.count-1)
  local phase=time*(s.wingBeat/100)*.72+f.tier*.42
  local drift=if s.reduce then 0 else math.sin(phase)*.12
  local basis=mount*CFrame.Angles(0,f.side*(beat+gait*.18-math.rad(s.wingSweep)*.35),0)
   *CFrame.new(f.side*(.85+v*2.35)*scale,(.05+v*.75+drift)*scale,.35*scale)
   *CFrame.Angles(.1+drift,f.side*.18,-f.side*(.38+v*.65))
  local radius=(.83-v*.31)*scale*(1+drift*.24)
  local spin=if s.reduce then 0 else f.side*phase*.55
  local function point(i)
   local p=outlinePoint(i,f.sides,radius,s.wingStyle=="Star Wings",spin)
   if s.wingStyle=="Prism Wings" then p=Vector3.new(p.X,p.Y,p.Y*.28) end
   if s.wingStyle=="Triad Wings" then p=Vector3.new(p.X*.75,p.Y*1.35,0) end
   return basis:PointToWorldSpace(p)
  end
  local previous=point(0)
  for i,p in f.edges do local nextPoint=point(i);segment(p,previous,nextPoint,.055*scale);previous=nextPoint end
  f.gem.Size=Vector3.one*(.12+.025*math.sin(phase))*scale
  f.gem.CFrame=basis*CFrame.Angles(phase*.5,phase*.7,0)
 end
 -- Shared movement per side keeps the traced outlines connected.
 if #self.sketchEdges>0 then
  local def=sketchWings[s.wingStyle]
  local motion=if s.reduce then 0 else s.sketchMotion/100
  local hover=math.sin(time*1.8)*.10*motion
  local flap=(beat+gait*.09)*motion
  local span=scale
  local glow=s.sketchGlow/100
  local bases={}
  for _,side in {-1,1} do
   bases[side]=mount*CFrame.new(side*.28*span,hover*span,.26*span)*CFrame.Angles(0,side*(flap-math.rad(s.wingSweep)*.25),-side*math.sin(time*1.25)*.025*motion)
  end
  local primary=if s.sketchColors then U.hex(def.colors[1]) else U.hex(s.wingColor)
  local secondary=if s.sketchColors then U.hex(def.colors[2]) else U.hex(s.secondary)
  for _,f in self.sketchEdges do
   local basis=bases[f.side]
   local p0=basis:PointToWorldSpace(f.a*span)
   local p1=basis:PointToWorldSpace(f.b*span)
   local width=(if s.wingStyle=="Burnt Fallen" then .040 else .052)*span
   local color=if s.wingRainbow then Color3.fromHSV((time*.10+f.index*.13)%1,.62,1) else primary:Lerp(secondary,((f.index-1)%4)/5)
   segment(f.p,p0,p1,width);f.p.Color=color
   if glow>0 then
    segment(f.glow,p0,p1,width*(1.8+glow));f.glow.Color=color;f.glow.Transparency=1-glow*.24
   else f.glow.Transparency=1 end
  end
 end
 -- Red above the raised hand, blue below the opposite hand. Independent timers
 -- preserve opposite rotation and allow either effect to be toggled on its own.
 for index,key in {"redDiamond","blueDiamond"} do
  local on=s[key]
  local group=self.diamonds[key]
  if on and not group then
   group={}
   for echo=1,3 do
    local ring={}
    for j=1,4 do
     local edge=self:add(part(self.root,"DiamondFX_"..key,Vector3.new(.03,.03,.03),Enum.PartType.Block,true))
     edge.Transparency=1;ring[j]=edge
    end
    group[echo]=ring
   end
   self.diamonds[key]=group
  end
  if group then
   if not on then
    self.diamondTime[key]=nil
    for _,ring in group do for _,edge in ring do edge.Transparency=1 end end
   else
    self.diamondTime[key]=(self.diamondTime[key] or 0)+dt
    local age=self.diamondTime[key]
    local q=if s.reduce then 1 else U.ease(age/.3,"Smooth")
    local spin=(if index==1 then 1 else -1)*math.rad(140)*s.diamondSpeed/100*(if s.reduce then 0 else age)
    local radius=.62*s.diamondSize/100*math.max(.02,q)
    local arm=if index==1 then (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")) else (char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"))
    local pos=if arm and arm:IsA("BasePart") then arm.Position else body.Position+body.CFrame.RightVector*(if index==1 then 1.5 else -1.5)
    local color=if index==1 then Color3.fromRGB(255,38,64) else Color3.fromRGB(44,85,255)
    for echo,ring in group do
     if echo>1 and (not s.diamondEcho or s.reduce) then for _,edge in ring do edge.Transparency=1 end;continue end
     local angle=spin-(echo-1)*(if index==1 then .52 else -.52)
     local center=pos+Vector3.new(0,(if index==1 then .95 else -.95)+(if s.reduce then 0 else math.sin(age*2.4)*.09),0)
     local basis=CFrame.new(center)*CFrame.Angles(.5,angle*.7,angle)
     local function point(j)
      local theta=(j-1)*math.pi/2
      return basis:PointToWorldSpace(Vector3.new(math.cos(theta)*radius,math.sin(theta)*radius,0))
     end
     for j,edge in ring do
      segment(edge,point(j),point(j%4+1),.055)
      edge.Color=color:Lerp(Color3.new(1,1,1),(echo-1)*.13)
      edge.Transparency=1-q*(if echo==1 then 1 else .34/(echo-1))
     end
    end
   end
  end
 end
 for _,f in self.trims do
  local v=(f.index-1)/4
  local a=mount*CFrame.Angles(0,f.side*(beat+gait*.15-math.rad(s.wingSweep)),0)
  f.p.Size=Vector3.new(.09,.09,.09)*scale
  submit(f.p,a*CFrame.new(f.side*(.38+v*1.65)*scale,(-.19+v*.3)*scale,.42*scale))
 end
 local haloY=s.haloHeight/100+.07
  +math.sin(time*1.8)*.045
  +bob*.11
 for _,layer in self.haloV2 do
  local k="haloV2"..layer.index
  local radius=s[k.."Radius"]/100
  local phase=time*s[k.."Spin"]*.012
  local height=s[k.."Height"]/100+(layer.index-1)*.08+math.sin(time*1.8+layer.index)*.035
  local basis=head.CFrame*CFrame.new(0,height,0)*CFrame.Angles(math.rad(s[k.."Tilt"]),phase,0)
  local primary,secondary=U.hex(s[k.."Color"]),U.hex(s[k.."Secondary"])
  local opacity=s[k.."Opacity"]/100
  local glow=s[k.."Glow"]/100
  local thick=.045*s[k.."Thickness"]/100
  for j,path in layer.paths do
   local col=primary:Lerp(secondary,(j-1)/math.max(1,#layer.paths-1))
   for i,edge in path.edges do
    local x=basis:PointToWorldSpace(path.points[i]*radius)
    local y=basis:PointToWorldSpace(path.points[i+1]*radius)
    segment(edge,x,y,thick)
    edge.Color=col
    edge.Transparency=1-opacity
    edge.Material=if glow>.15 then Enum.Material.Neon else Enum.Material.SmoothPlastic
    if glow>.15 then edge.Color=col:Lerp(Color3.new(1,1,1),glow*.23) end
   end
  end
 end
 local hRadius=s.haloRadius/100
 for _,g in self.geoHalos do
  local spin=time*s.haloSpin*.012*(if g.ring==2 then -1 else 1)
  local r=hRadius*(if g.ring==2 then .65 else 1)
  local basis=head.CFrame*CFrame.new(0,haloY+(g.ring-1)*.12,0)*CFrame.Angles(.12+math.sin(time*.7)*.12,spin+(g.ring-1)*math.pi/4,0)
  local function point(i)
   local angle=i/g.sides*math.pi*2
   if s.haloStyle=="Infinity" then return basis:PointToWorldSpace(Vector3.new(math.sin(angle)*r*1.2,math.sin(angle*2)*.10,math.sin(angle*2)*r*.55)) end
   local p=outlinePoint(i,g.sides,r,s.haloStyle=="Star",math.pi/2)
   return basis:PointToWorldSpace(Vector3.new(p.X,0,p.Y))
  end
  local previous=point(0)
  for i,p in g.edges do local nextPoint=point(i);segment(p,previous,nextPoint,.075);previous=nextPoint end
 end
 for _,b in self.beads do
  local style=s.haloStyle
  local ring=b.ring
  local t0=(b.index-1)/b.count*math.pi*2
  local spin=time*s.haloSpin*.012*(if ring==2 then -1 else 1)
  local a=t0+spin
  local r=hRadius*(if ring==1 then 1 elseif style=="Orbitals" then 1.18 else .72)
  local tilt=if style=="Orbitals" then (if ring==2 then .97 else -.19)
   elseif style=="Lunar" then -.44
   elseif style=="Solar" then .12
   elseif style=="Eclipse" then (if ring==2 then -.62 else .45)
   elseif style=="Prism" then (if ring==2 then .65 else -.35)
   else (if ring==2 then -.17 else .07)
  local rise=if style=="Spiral" then t0/math.pi*.23
   elseif style=="Comet" then math.sin(t0*2)*.15
   else 0
  local ringBasis=head.CFrame*CFrame.new(0,haloY,0)
   *CFrame.Angles(tilt+haloWalk*math.sin(self.phase)*.11,0,0)
   *CFrame.Angles(0,a,0)*CFrame.new(0,rise,r)
  local crown=is(style,"Crown","Thorns","Starfall") and b.index%4==0 and ring==1
  b.p.Size=Vector3.new(2*r*math.sin(math.pi/b.count)*1.025,if crown then .22 else .077,if ring==2 then .055 else .10)
  submit(b.p,ringBasis)
 end
 for _,o in self.ornaments do
  local style=s.haloStyle
  local n=o.index
  local a=(n-1)/o.count*math.pi*2+time*s.haloSpin*.011
  local radius=hRadius*(if style=="Starfall" or style=="Comet" then 1.23 else .97)
  local height=if style=="Crown" then .35
   elseif style=="Thorns" then .24
   elseif style=="Lotus" then .14
   elseif style=="Solar" then math.sin(n*1.57)*.15
   else .06
  local size
  if is(style,"Crown","Thorns","Solar") then
   size=Vector3.new(.12,if style=="Crown" then .43 else .30,.12)
  elseif is(style,"Lotus","Starfall","Comet") then
   size=Vector3.new(.17,.25,.1)
  else size=Vector3.new(.15,.16,.15) end
  o.p.Size=size
  local basis=head.CFrame*CFrame.new(0,haloY,0)*CFrame.Angles(.1,0,0)
   *CFrame.Angles(0,a,0)*CFrame.new(0,height,radius)
   *CFrame.Angles(if style=="Lotus" then .66 else 0,0,a)
  submit(o.p,basis)
 end
 if t-self.paintAt>=.09 or self.settings~=s then
  self.settings=s;self.paintAt=t
  local accent=U.hex(s.secondary)
  local wingColor=U.hex(s.wingColor)
  for _,f in self.feathers do
   local v=(f.index-1)/math.max(f.count-1,1)
   local color=if s.wingRainbow then Color3.fromHSV((time*.1+v*.25+f.layer*.1)%1,.56,1)
    else wingColor:Lerp(accent,math.clamp(v*.32+(.11*(f.layer-1)),0,.6))
   f.core.Color=color
   f.vein.Color=color:Lerp(Color3.new(1,1,1),.55)
   if f.tip then f.tip.Color=accent:Lerp(color,.4) end
  end
  for _,f in self.trims do f.p.Color=accent:Lerp(wingColor,f.index*.1) end
  local haloColor=U.hex(s.haloColor)
  for _,g in self.geoWings do
   for i,p in g.edges do p.Color=if s.wingRainbow then Color3.fromHSV((time*.09+i/#g.edges+g.tier*.13)%1,.55,1) else wingColor:Lerp(accent,(i/#g.edges)*.6) end
   g.gem.Color=accent
  end
  for _,g in self.geoHalos do
   for i,p in g.edges do p.Color=if s.haloRainbow then Color3.fromHSV((time*.10+i/#g.edges)%1,.55,1) else haloColor:Lerp(accent,i/#g.edges*.5) end
  end
  for _,b in self.beads do
   b.p.Color=if s.haloRainbow then Color3.fromHSV((time*.1+b.index/b.count+(.23*(b.ring-1)))%1,.58,1)
    else haloColor:Lerp(accent,if b.ring==2 then .46 else .12)
  end
  for _,o in self.ornaments do
   o.p.Color=if s.haloRainbow then Color3.fromHSV((time*.1+o.index/o.count)%1,.5,1)
    else accent:Lerp(haloColor,.53)
  end
   if self.emitter then
   self.emitter.Color=ColorSequence.new(U.hex(s.auraColor),accent)
   self.emitter.Rate=if s.reduce then 0 else s.auraRate
  end
  if self.trail then
   self.trail.Enabled=not s.reduce
   self.trail.Color=ColorSequence.new(U.hex(s.auraColor),accent)
   self.trail.Lifetime=s.trailLife/1000
  end
 end
 if self.highlight then
  local style=s.neonMotion
  local strength=if s.reduce or style=="Solid" then 0 else s.neonMotionStrength/100
  local speed=s.neonMotionSpeed/100
  local phase=time*speed
  local hp=if hum then hum.Health else nil
  if hp~=nil and self.neonHP~=nil and hp~=self.neonHP then
   self.neonEnergy=math.min(1,(self.neonEnergy or 0)+.65)
  end
  self.neonHP=hp
  self.neonEnergy=(self.neonEnergy or 0)*math.exp(-dt*3)
  local wave=.5+.5*math.sin(phase*2)
  local glow=if style=="Breathe" then wave
   elseif style=="Aurora" then .5+.5*math.sin(phase*1.4)
   elseif style=="Heartbeat" then (math.sin(phase*math.pi*2)*.5+.5)^3
   elseif style=="Flow" then .5+.5*math.sin(phase*2.8)
   elseif style=="Reactive" then math.clamp(walk*.65+self.neonEnergy,0,1)
   else 0
  local base=U.hex(s.neonColor)
  local accent=U.hex(s.secondary)
  local color=base
  if not s.reduce and s.neonRainbow then
   color=Color3.fromHSV((phase*.11)%1,.58,1)
  elseif style=="Aurora" or style=="Flow" then
   color=base:Lerp(accent,glow*strength*.8)
  end
  local energy=glow*strength
  self.highlight.OutlineColor=color
  self.highlight.FillColor=color:Lerp(accent,energy*.18)
  self.highlight.FillTransparency=1-math.clamp(s.neonFill/100*(.85+energy*.55),0,.85)
  self.highlight.OutlineTransparency=math.clamp(.12-energy*.10,0,1)
  if self.light then
   self.light.Color=color
   self.light.Range=s.neonRange
   self.light.Brightness=s.neonLight*.035*(1+energy*.45)
  end
 end
end
function A:syncVisualGlow(s)
 local key=tostring(s.sketchGlow)..":"..tostring(s.haloGlow)
 if self.glowKey==key then return end
 self.glowKey=key
 for _,p in self.parts do
  if not p:GetAttribute("AetherEmissive") or p.Name=="HaloV2Outline" then continue end
  local intensity=nil
  if p.Name:find("Wing") or p.Name:find("Feather") then intensity=s.sketchGlow
  elseif p.Name:find("Halo") then intensity=s.haloGlow end
  if intensity~=nil then p.Material=if intensity>0 then Enum.Material.Neon else Enum.Material.SmoothPlastic end
 end
end
function A.mannequin(world)
 local m=U.new("Model",{Name="PreviewRig"},world)
 for _,v in {{"UpperTorso",0,1.8,0,2,1.6,1},{"Head",0,3.15,0,1.2,1.2,1.2},
  {"LeftArm",-1.4,1.8,0,.65,1.9,.7},{"RightArm",1.4,1.8,0,.65,1.9,.7},
  {"LeftLeg",-.5,.1,0,.85,1.8,.8},{"RightLeg",.5,.1,0,.85,1.8,.8}} do
  local p=part(m,v[1],Vector3.new(v[5],v[6],v[7]),if v[1]=="Head" then Enum.PartType.Ball else Enum.PartType.Block,false)
  p.Color=Color3.fromRGB(89,80,119);p.Position=Vector3.new(v[2],v[3],v[4])
 end
 return m
end
return A
