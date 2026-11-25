local U=require(script.Parent.Util);local Symbol=require(script.Parent.Symbol);local Icons=require(script.Parent.Icons)
local H={};H.__index=H
local UIS=game:GetService("UserInputService")
local sizes={hp=Vector2.new(264,94),clock=Vector2.new(116,58),profile=Vector2.new(124,58),dock=Vector2.new(239,49),cross=Vector2.new(18,18)}
local heartPalettes={
 Aurora={"7DE3FF","B78AFF","FC82D6"},
 Amethyst={"7550E8","BB8CFF","F2B8FF"},
 Ocean={"245BD9","56C9F5","A2FFF1"},
 Sakura={"FF7CAA","FFD1E4","C48EFF"},
 Sunset={"FFD17E","FF847D","C46CFF"},
 Ember={"FFCE70","FF7043","CE315F"},
 Mint={"46CDB3","BDFFE0","62BAF1"},
 Ice={"E4F6FF","97D7FF","7596ED"},
 Galaxy={"5856D6","A97DFF","FF91C9"},
}
local function heartColors(s,ratio,dead,t)
 if dead then return Color3.fromRGB(91,85,102),Color3.fromRGB(98,92,110),Color3.fromRGB(104,98,115) end
 local a,m,b
 if s.heartPalette=="Rainbow" then
  local phase=if s.reduce then 0 else t*s.heartGradientSpeed/100*.12
  a=Color3.fromHSV(phase%1,.62,1);m=Color3.fromHSV((phase+.14)%1,.50,1);b=Color3.fromHSV((phase+.28)%1,.64,1)
 elseif s.heartPalette=="Adaptive" then
  a=U.hex(s.accent);b=U.hex(s.secondary);m=a:Lerp(b,.5)
 elseif s.heartPalette=="Custom" then
  a=U.hex(s.heartA);m=U.hex(s.heartMid);b=U.hex(s.heartB)
 else
  local palette=heartPalettes[s.heartPalette] or heartPalettes.Aurora
  a=U.hex(palette[1]);m=U.hex(palette[2]);b=U.hex(palette[3])
 end
 -- Only the heart uses the selected palette. HP warnings remain recognizable.
 local yellowA,yellowM,yellowB=Color3.fromRGB(255,225,99),Color3.fromRGB(255,187,75),Color3.fromRGB(255,144,60)
 local redA,redM,redB=Color3.fromRGB(245,46,78),Color3.fromRGB(255,78,114),Color3.fromRGB(255,109,169)
 if ratio<=.30 then
  local danger=1-ratio/.30
  return yellowA:Lerp(redA,.7+.3*danger),yellowM:Lerp(redM,.7+.3*danger),yellowB:Lerp(redB,.7+.3*danger)
 elseif ratio<=.65 then
  local q=(.65-ratio)/.35
  return yellowA:Lerp(redA,q*.7),yellowM:Lerp(redM,q*.7),yellowB:Lerp(redB,q*.7)
 end
 local q=math.clamp((.82-ratio)/.17,0,1)
 return a:Lerp(yellowA,q),m:Lerp(yellowM,q),b:Lerp(yellowB,q)
end
local function smoothPulse(phase,center,width)
 local distance=math.abs((phase-center+.5)%1-.5)
 if distance>=width then return 0 end
 return .5+.5*math.cos(math.pi*distance/width)
end
local function setText(label,value)
 if label.Text~=value then label.Text=value end
end
local function center(p,t,size) local n=U.label(p,t,size);n.TextXAlignment=Enum.TextXAlignment.Center;return n end
function H.new(scope,parent,preview,go,drag,close,showPanels)
 local self=setmetatable({view=parent,preview=preview,widgets={},markers={},extras={},spark={},time=0,phase=0,paintAt=0,last=-1,dockIcons={}},H)
 self.layer=U.frame(parent,"Directions",nil,nil,nil,1);self.layer.ClipsDescendants=true
 for i=1,9 do
  local n=U.frame(parent,"Dust",UDim2.fromScale((i*.617)%1,(i*.349)%1),UDim2.fromOffset(2+i%2,2+i%2),nil,.54)
  U.corner(n,8);self.spark[i]=n
 end
 for _,k in {"hp","clock","profile","dock","cross"} do
  local d=sizes[k]
  local p=U.new(if k=="cross" then "Frame" else "CanvasGroup",{Name=k,BackgroundTransparency=1,Size=UDim2.fromOffset(d.X,d.Y),BorderSizePixel=0,ZIndex=3},parent)
  -- A gradient on a CanvasGroup tints the entire composited texture.
  -- Put glass shading on a separate first child; leave text and glyphs untouched.
  local background=U.frame(p,"GlassBackground",nil,nil,Color3.new(1,1,1),0)
  background.Active=false
  background.Interactable=false
  background.ZIndex=1
  background.Visible=k~="cross"
  local g=U.gradient(background,Color3.fromRGB(53,40,75),Color3.fromRGB(22,21,36))
  U.corner(background,if k=="cross" then 0 else 15)
  U.corner(p,if k=="cross" then 0 else 15)
  local rim=U.stroke(p,Color3.fromRGB(189,156,255),.4,1.15)
  local scale=U.new("UIScale",{},p)
  self.widgets[k]={p=p,g=g,background=background,rim=rim,scale=scale}
  if drag then
   p.Active=true
   scope:on(p.InputBegan,function(i) drag(i,k,p,parent) end)
  end
 end
 local hp=self.widgets.hp.p
 self.hpAccent=U.frame(hp,"AccentLine",UDim2.fromOffset(0,0),UDim2.new(1,0,0,3),Color3.fromRGB(188,150,255))
 U.gradient(self.hpAccent,Color3.fromRGB(190,144,255),Color3.fromRGB(111,220,249),0)
 self.heart=Symbol.new(hp,"Heart",50)
 self.heart.root.AnchorPoint=Vector2.new(.5,.5)
 self.heart.root.Position=UDim2.fromOffset(40,44)
 self.heart.root.Size=UDim2.fromOffset(35,35)
 self.hpTitle=U.label(hp,"VITALS  /  HEALTH",10,UDim2.fromOffset(77,14),UDim2.fromOffset(127,17))
 self.hpTitle.TextColor3=Color3.fromRGB(194,177,229)
 self.value=U.label(hp,"— / — HP",20,UDim2.fromOffset(76,35),UDim2.fromOffset(165,27))
 self.stateText=U.label(hp,"READY",10,UDim2.fromOffset(192,14),UDim2.fromOffset(53,17))
 self.stateText.TextXAlignment=Enum.TextXAlignment.Right
 self.track=U.frame(hp,"HealthMeter",UDim2.fromOffset(16,77),UDim2.new(1,-32,0,7),Color3.fromRGB(62,52,86),.06)
 U.corner(self.track,6)
 self.trail=U.frame(self.track,"DamageTrail",nil,UDim2.fromScale(1,1),Color3.fromRGB(245,208,255))
 U.corner(self.trail,6)
 self.fill=U.frame(self.track,"Fill",nil,UDim2.fromScale(1,1),Color3.new(1,1,1))
 U.corner(self.fill,6)
 self.fillG=U.gradient(self.fill,Color3.fromRGB(167,130,249),Color3.fromRGB(241,147,213),0)
 self.fill.ClipsDescendants=true
 self.shine=U.frame(self.fill,"HealthShimmer",nil,nil,Color3.new(1,1,1),.32)
 self.shine.ZIndex=5;self.shine.Active=false
 self.shineGradient=U.gradient(self.shine,Color3.new(1,1,1),Color3.new(1,1,1),0)
 self.shineGradient.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.38,1),
  NumberSequenceKeypoint.new(.5,.08),NumberSequenceKeypoint.new(.62,1),NumberSequenceKeypoint.new(1,1)})
 self.shine.Visible=false
 self.reactionStroke=U.stroke(hp,Color3.fromRGB(195,150,255),1,2.5)
 self.reactionStroke.Enabled=false
 local clock=self.widgets.clock.p
 self.clock=U.label(clock,"--:--",21,UDim2.fromOffset(13,6),UDim2.new(1,-24,0,29))
 self.clockSub=U.label(clock,"AETHER · TIME",9,UDim2.fromOffset(13,34),UDim2.new(1,-23,0,15))
 local profile=self.widgets.profile.p
 self.profileDot=U.frame(profile,"Online",UDim2.fromOffset(13,18),UDim2.fromOffset(7,7),Color3.fromRGB(152,240,210))
 U.corner(self.profileDot,9)
 self.profileTitle=U.label(profile,"PERFORMANCE",9,UDim2.fromOffset(25,9),UDim2.new(1,-43,0,18))
 self.name=U.label(profile,"",15,UDim2.fromOffset(14,28),UDim2.new(1,-27,0,22))
 local dock=self.widgets.dock.p
 if close then
  for _,key in {"clock","profile"} do
   local button=U.button(self.widgets[key].p,"×")
   button.Size=UDim2.fromOffset(16,16);button.Position=UDim2.new(1,-19,0,3)
   button.TextSize=12;button.BackgroundTransparency=.6;button.ZIndex=5
   scope:on(button.Activated,function() close(key) end)
  end
 end
 for i,item in {{"HOME","Dashboard"},{"HUD","HUD"},{"FX","Character"},{"SKY","Ambient"},{"MORE","Profiles"}} do
  local b=U.button(dock,item[1])
  b.Name="Dock_"..item[2]
  b:SetAttribute("AETHERIconOnly",true)
  b:SetAttribute("AETHERText",item[1])
  b.Size=UDim2.fromOffset(42,35)
  b.Position=UDim2.fromOffset(6+(i-1)*46,7)
  b.TextSize=11
  table.insert(self.dockIcons,Icons.new(b,item[2]))
  scope:on(b.Activated,function() go(item[2]) end)
 end
 local cr=self.widgets.cross.p
 cr.BackgroundTransparency=1
 self.widgets.cross.rim.Enabled=false
 self.reticleRoot=U.frame(cr,"ShiftReticle",UDim2.fromScale(.5,.5),UDim2.fromScale(1,1),nil,1)
 self.reticleRoot.AnchorPoint=Vector2.new(.5,.5);self.reticleRoot.Active=false
 self.reticleEdges={};self.reticleGlowEdges={}
 for i=1,48 do
  local glow=U.frame(self.reticleRoot,"SoftGlow"..i,nil,UDim2.fromOffset(1,1),Color3.new(1,1,1),1)
  glow.AnchorPoint=Vector2.new(.5,.5);glow.Active=false;glow.Interactable=false;glow.Visible=false;glow.ZIndex=4
  U.new("UICorner",{CornerRadius=UDim.new(.5,0)},glow);self.reticleGlowEdges[i]=glow
  local edge=U.frame(self.reticleRoot,"Line"..i,nil,UDim2.fromOffset(1,1),Color3.new(1,1,1),0)
  edge.AnchorPoint=Vector2.new(.5,.5);edge.Active=false;edge.Interactable=false;edge.Visible=false;edge.ZIndex=5
  U.new("UICorner",{CornerRadius=UDim.new(.5,0)},edge);self.reticleEdges[i]=edge
 end
 -- A read-only key display. It neither intercepts nor generates any game input.
 self.inputRoot=U.new("CanvasGroup",{Name="InputOverlay",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(172,114),BackgroundTransparency=1,Active=false,Interactable=false,Visible=false,ZIndex=6},parent)
 self.inputKeys={}
 for _,def in {
  {"W",60,4,42,Enum.KeyCode.W},{"A",14,42,42,Enum.KeyCode.A},{"S",60,42,42,Enum.KeyCode.S},{"D",106,42,42,Enum.KeyCode.D},
  {"SPACE",14,80,134,Enum.KeyCode.Space},{"SHIFT",106,4,58,Enum.KeyCode.LeftShift},
  {"LMB",2,118,81,Enum.UserInputType.MouseButton1},{"RMB",88,118,81,Enum.UserInputType.MouseButton2}
 } do
  local key=U.frame(self.inputRoot,"Key_"..def[1],UDim2.fromOffset(def[2],def[3]),UDim2.fromOffset(def[4],34),Color3.fromRGB(33,27,49),.18)
  key.Active=false;key.Interactable=false;key.ZIndex=7;U.corner(key,8)
  local rim=U.stroke(key,Color3.fromRGB(185,155,231),.55,1)
  local label=center(key,def[1],12);label.ZIndex=8
  table.insert(self.inputKeys,{p=key,rim=rim,label=label,code=def[5],mouse=def[1]=="LMB" or def[1]=="RMB"})
 end
 self.wallhop=U.new("CanvasGroup",{Name="WallhopHelper",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(210,86),BackgroundColor3=Color3.fromRGB(28,22,44),BackgroundTransparency=.15,Active=false,Interactable=false,Visible=false,ZIndex=6},parent)
 U.corner(self.wallhop,12);U.stroke(self.wallhop,Color3.fromRGB(177,146,255),.35,1)
 self.wallhopScale=U.new("UIScale",{},self.wallhop)
 self.wallhopTitle=U.label(self.wallhop,"WALLHOP  /  PRACTICE",10,UDim2.fromOffset(12,7),UDim2.fromOffset(186,16))
 self.wallhopText=U.label(self.wallhop,"READY",15,UDim2.fromOffset(12,27),UDim2.fromOffset(186,23))
 self.wallhopDetail=U.label(self.wallhop,"Jump · camera angle",10,UDim2.fromOffset(12,55),UDim2.fromOffset(186,19))
 if preview and showPanels then
  self.previewPanels={}
  self.previewHandles={}
  local top,topRim,topButtons=U.topPanel(parent)
  local rail,railRim,railButtons,collapse=U.railPanel(parent)
  self.previewPanels.top={p=top,rim=topRim,buttons=topButtons}
  self.previewPanels.rail={p=rail,rim=railRim,buttons=railButtons,collapse=collapse}
  for _,item in self.previewPanels do
   item.p.AnchorPoint=Vector2.zero;item.p.ZIndex=7
   item.scale=U.new("UIScale",{Scale=.55},item.p)
   for _,button in item.buttons do button.Active=false;button.Interactable=false;button.ZIndex=8 end
   if item.collapse then item.collapse.Active=false;item.collapse.Interactable=false;item.collapse.ZIndex=8 end
  end
  top.Position=UDim2.new(.5,-95,0,6);rail.Position=UDim2.new(0,6,.25,0)
  for _,key in {"top","rail","input","wallhop","hp","clock","profile","dock"} do
   local target=if key=="top" or key=="rail" then self.previewPanels[key].p elseif key=="input" then self.inputRoot elseif key=="wallhop" then self.wallhop else self.widgets[key].p
   local hit=U.new("TextButton",{Name="PreviewDrag_"..key,Text="",BackgroundTransparency=1,AutoButtonColor=false,Active=true,Visible=false,ZIndex=15},parent)
   local outline=U.stroke(hit,Color3.fromRGB(224,183,255),0,1.5);U.corner(hit,6)
   self.previewHandles[key]={p=hit,target=target,rim=outline}
   if drag then scope:on(hit.InputBegan,function(input) drag(input,key,target,parent,self) end) end
  end
 end
 return self
end
function H:layoutPreview(s)
 if not self.previewPanels then return end
 local vp=self.view.AbsoluteSize
 if vp.X<2 or vp.Y<2 then return end
 for _,key in {"top","rail"} do
  local item=self.previewPanels[key]
  local panel=item.p
  local factor=math.clamp(math.min(vp.X/850,vp.Y/420),.35,.74)
  local originalW=if key=="top" then 136 else 54
  local originalH=if key=="top" then 38 else 176
  local w,height=originalW*factor,originalH*factor
  item.scale.Scale=factor
  local x,y
  if s[key.."Custom"] then
   x=math.max(0,vp.X-w)*s[key.."X"]/100;y=math.max(0,vp.Y-height)*s[key.."Y"]/100
  elseif key=="top" then x=(vp.X-w)*.5;y=6
  else x=6;y=vp.Y*.46-height*.5 end
  panel.AnchorPoint=Vector2.zero
  panel.Size=UDim2.fromOffset(originalW,originalH)
  panel.Position=UDim2.fromOffset(math.clamp(x,0,math.max(0,vp.X-w)),math.clamp(y,0,math.max(0,vp.Y-height)))
  panel.Visible=if key=="top" then s.topCapsule else s.robloxRail
  item.rim.Color=U.hex(s.accent)
  item.rim.Transparency=if key=="top" then .42 else .48
  item.rim.Thickness=1
  local face=U.font(s)
  for _,button in item.buttons do button.FontFace=face;button.TextColor3=U.hex(s.uiFontColor or "F1E6FF") end
  if item.collapse then item.collapse.FontFace=face end
 end
 for key,item in self.previewHandles do
  local isPanel=key=="top" or key=="rail"
  local allowed=if isPanel then s.movePanels else not s.locked
  item.p.Visible=item.target.Visible and allowed
  item.p.Active=allowed;item.p.Interactable=allowed
  if item.p.Visible then
   -- Panel positions are set directly, so the drag target can follow without waiting
   -- for AbsolutePosition propagation during the current input event.
   if isPanel then local factor=self.previewPanels[key].scale.Scale;item.p.Position=item.target.Position;item.p.Size=UDim2.fromOffset(item.target.Size.X.Offset*factor,item.target.Size.Y.Offset*factor)
   else local xy=item.target.AbsolutePosition-self.view.AbsolutePosition;item.p.Position=UDim2.fromOffset(xy.X,xy.Y);item.p.Size=UDim2.fromOffset(item.target.AbsoluteSize.X,item.target.AbsoluteSize.Y) end
  end
 end
end
function H:clearMarkers() for _,m in self.markers do m.root:Destroy() end;table.clear(self.markers) end
function H:placement(s,k)
 local x,y=s[k.."X"]/100,s[k.."Y"]/100
 if s.layoutMode~="Sketch" then return x,y,0,0 end
 local factor=self.factor or 1
 local pad=if self.preview then 5 else 14
 if k=="hp" then return 1,0,-pad,if self.preview then 5 else 12 end
 if k=="clock" then return 0,1,pad,-pad end
 if k=="profile" then return 0,1,pad+116*factor*s.clockScale/100+8,-pad end
 if k=="dock" then
  local narrow=self.view.AbsoluteSize.X<760 and not self.preview
  return .5,1,0,if narrow then -84 else -pad
 end
 return .5,.5,0,0
end
function H:setStyle(s)
 local factor=if self.preview then math.clamp(self.view.AbsoluteSize.X/850,.43,.74) else math.clamp(self.view.AbsoluteSize.X/770,.66,1)
 self.factor=factor
 local accent=U.hex(s.accent)
 local a,b=U.hex(s.glassColor),Color3.fromRGB(17,16,30)
 local face=U.font(s)
 for k,w in self.widgets do
  local x,y,ox,oy=self:placement(s,k)
  w.p.AnchorPoint=Vector2.new(x,y)
  w.p.Position=UDim2.new(x,ox,y,oy)
  w.p.Rotation=s[k.."Turn"]
  w.scale.Scale=if k=="cross" then 1 else factor*s[k.."Scale"]/100
  if w.p:IsA("CanvasGroup") then w.p.GroupTransparency=1-s[k.."Alpha"]/100 end
  w.p.Visible=s[k]
  w.rim.Color=accent
  w.rim.Transparency=1-s.rim/100
  w.g.Color=ColorSequence.new(a,b)
  w.p.BackgroundTransparency=1
  if w.p:IsA("CanvasGroup") then w.p.GroupColor3=Color3.new(1,1,1) end
  local legacyGradient=w.p:FindFirstChildOfClass("UIGradient")
  if legacyGradient then legacyGradient:Destroy() end
  w.background.BackgroundTransparency=1-s.glass/100
 end
 self.widgets.hp.p.Size=UDim2.fromOffset(264,if s.compact then 72 else 94)
 self.track.Visible=true
 self.track.Position=UDim2.fromOffset(16,if s.compact then 60 else 77)
 self.hpTitle.Position=UDim2.fromOffset(77,if s.compact then 7 else 14)
 self.stateText.Position=UDim2.fromOffset(192,if s.compact then 7 else 14)
 self.value.Position=UDim2.fromOffset(76,if s.compact then 25 else 35)
 self.heart.root.Position=UDim2.fromOffset(40,if s.compact then 32 else 44)
 self.reticleKey=nil
 self.hpAccent.BackgroundColor3=accent
 self.profileDot.BackgroundColor3=U.hex(s.secondary)
 for _,icon in self.dockIcons do icon:sync(s.iconAtlas,s.iconAtlasTile) end
 for _,item in {{self.clock,21},{self.clockSub,9},{self.hpTitle,10},{self.value,19},{self.stateText,10},{self.name,15},{self.profileTitle,9}} do
  local n=item[1]
  n.FontFace=face
  n.TextSize=item[2]*s.fontSize/100
  n.TextColor3=if s.fontGradient then Color3.new(1,1,1) else U.hex(s.fontA)
  n.TextStrokeColor3=Color3.fromRGB(20,16,32)
  n.TextStrokeTransparency=1-s.fontOutline/100
  local grad=n:FindFirstChildOfClass("UIGradient") or U.gradient(n,accent,b,0)
  grad.Color=ColorSequence.new(U.hex(s.fontA),U.hex(s.fontB))
  grad.Enabled=s.fontGradient
 end
 self.settings=s
 self.width=self.view.AbsoluteSize.X
end
function H:reticle(s,f,t)
 local widget=self.widgets.cross
 widget.p.Visible=s.cross and s.lockReticle~="None" and (self.preview or f.shiftLock==true)
 if not widget.p.Visible then return end
 if not self.preview then widget.p.AnchorPoint=Vector2.new(.5,.5);widget.p.Position=UDim2.fromScale(.5,.5);widget.p.Rotation=0 end
 local scale=(if self.preview then self.factor or 1 else 1)*s.crossScale/100
 local px=math.max(6,math.round(s.reticleSize*scale))
 local strokePx=math.max(1,math.round(s.reticleStroke*scale))
 widget.p.Size=UDim2.fromOffset(px,px)
 local style=s.lockReticle
 local key=style..":"..px..":"..strokePx
 if self.reticleKey~=key then
  self.reticleKey=key
  local used=0
  local function line(x1,y1,x2,y2)
   used+=1
   local edge=self.reticleEdges[used];if not edge then return end
   local dx,dy=x2-x1,y2-y1
   edge.Position=UDim2.fromOffset((x1+x2)*.5*px,(y1+y2)*.5*px)
   edge.Size=UDim2.fromOffset(math.max(strokePx,math.sqrt(dx*dx+dy*dy)*px+strokePx*.65),strokePx)
   edge.Rotation=math.deg(math.atan2(dy,dx));edge.Visible=true
  end
  local function poly(count,r,phase,star)
   for i=0,count-1 do
    local a=phase+i/count*math.pi*2;local b=phase+(i+1)/count*math.pi*2
    local r1=r*(if star and i%2==1 then .44 else 1)
    local r2=r*(if star and (i+1)%2==1 then .44 else 1)
    line(.5+math.cos(a)*r1,.5+math.sin(a)*r1,.5+math.cos(b)*r2,.5+math.sin(b)*r2)
   end
  end
  if style=="Dot" then
   used=1;local d=self.reticleEdges[1];d.Position=UDim2.fromScale(.5,.5);d.Size=UDim2.fromOffset(strokePx*2,strokePx*2);d.Rotation=0;d.Visible=true
  elseif style=="Cross" then line(.08,.5,.92,.5);line(.5,.08,.5,.92)
  elseif style=="Split Cross" then for i=0,3 do local a=i*math.pi/2;line(.5+.18*math.cos(a),.5+.18*math.sin(a),.5+.44*math.cos(a),.5+.44*math.sin(a)) end
  elseif style=="Corners" then for _,x in {-1,1} do for _,y in {-1,1} do line(.5+x*.43,.5+y*.43,.5+x*.23,.5+y*.43);line(.5+x*.43,.5+y*.43,.5+x*.43,.5+y*.23) end end
  elseif style=="Diamond" then poly(4,.42,-math.pi/2,false)
  elseif style=="Triangle" then poly(3,.45,-math.pi/2,false)
  elseif style=="Hexagon" then poly(6,.42,0,false)
  elseif style=="Star" then poly(10,.45,-math.pi/2,true)
  elseif style=="Petal" then poly(8,.43,-math.pi/2,true)
  elseif style=="Compass" then poly(4,.43,0,false);poly(4,.22,0,false)
  elseif style=="Double Ring" then poly(24,.44,0,false);poly(20,.25,0,false)
  elseif style=="Orbit" then for i=0,21 do local a=i/24*math.pi*2;local b=(i+1)/24*math.pi*2;line(.5+.40*math.cos(a),.5+.40*math.sin(a),.5+.40*math.cos(b),.5+.40*math.sin(b)) end
  else poly(28,.42,0,false) end
  for i=used+1,#self.reticleEdges do self.reticleEdges[i].Visible=false;self.reticleGlowEdges[i].Visible=false end
  self.reticleUsed=math.min(used,#self.reticleEdges)
  self.reticlePaint=nil
 end
 local tm=if s.reduce or not s.reticleMotion then 0 else t*s.reticleSpeed/100
 self.reticleRoot.Rotation=if style=="Orbit" or style=="Star" or style=="Petal" or style=="Compass" or style=="Double Ring" then tm*22 else 0
 local col=if s.reticleRainbow then Color3.fromHSV((tm*.12)%1,.55,1) else U.hex(s.reticleColor)
 if self.reticlePaint~=col then
  self.reticlePaint=col
  for i=1,self.reticleUsed do
   self.reticleEdges[i].BackgroundColor3=col
   self.reticleGlowEdges[i].BackgroundColor3=col
  end
 end
 local intensity=s.reticleGlow/100
 local pulse=if s.reduce or not s.reticleGlowPulse then 1 else .82+.18*math.sin(t*s.reticleSpeed/100*3)
 local enabled=s.reticleNeon and intensity>0
 local alpha=s.crossAlpha/100
 local radius=math.max(1,s.reticleGlowRadius*scale*(.72+.28*pulse))
 for i=1,self.reticleUsed do
  local edge=self.reticleEdges[i];local glow=self.reticleGlowEdges[i]
  edge.BackgroundTransparency=1-alpha
  glow.Visible=enabled
  if enabled then
   glow.Position=edge.Position;glow.Rotation=edge.Rotation
   glow.Size=UDim2.fromOffset(edge.Size.X.Offset+radius*2,edge.Size.Y.Offset+radius*2)
   glow.BackgroundTransparency=1-intensity*pulse*alpha*.16
  end
 end
end
function H:vitals(s,f,dt)
 local hp,max=f.hp,f.max;local w=self.widgets.hp;w.p.Visible=s.hp and hp~=nil;if hp==nil then self.last=-1;self.phase=0;self.hpShake=0;self.shine.Visible=false;self.reactionStroke.Enabled=false;return end
 local ratio=math.clamp(hp/math.max(.001,max),0,1);local dead=hp<=0;local band=if dead then "DEAD" elseif ratio<=.30 then "CRITICAL" elseif ratio<=.65 then "ALERT" else "CALM"
 if self.last~=hp or self.gen~=f.gen or self.maximum~=max then
  self.effect=if self.gen~=nil and (f.gen~=self.gen or self.last==0 and hp>0) then "Revive" elseif self.last>=0 and hp<self.last then "Damage" elseif self.last>=0 and hp>self.last then "Heal" else "None";self.age=0;self.from=self.shown or hp;self.fromRatio=self.bar or ratio;self.fromTrail=math.max(self.trailRatio or ratio,self.bar or ratio);self.last=hp;self.gen=f.gen;self.maximum=max;w.p:SetAttribute("Effect",self.effect);w.p:SetAttribute("Health",hp);w.p:SetAttribute("MaxHealth",max);w.p:SetAttribute("Life",band)
 end
 self.age+=dt
 local dur=s.hudSmoothness/1000*100/s.speed
 local q=if dead or s.reduce then 1 else U.ease(self.age/math.max(.01,dur),s.ease)
 -- Exponential smoothing preserves continuous motion even during rapid HP changes.
 if dead or s.reduce or self.effect=="Revive" and self.age<=dt then
  self.shown=hp;self.bar=ratio;self.trailRatio=ratio
 else
  self.shown=U.approach(self.shown or hp,hp,dt,dur/4.6)
  self.bar=U.approach(self.bar or ratio,ratio,dt,dur/4.6)
  if self.effect=="Damage" then
   if self.age<=.18 then self.trailRatio=math.max(self.fromTrail,self.bar)
   else self.trailRatio=math.max(self.bar,U.approach(self.trailRatio or self.fromTrail,ratio,dt,dur/2.6)) end
  else self.trailRatio=self.bar end
 end
 self.fill.Size=UDim2.fromScale(self.bar,1)
 self.trail.Size=UDim2.fromScale(self.trailRatio,1)
 local number=math.ceil(self.shown-.00001)
 if self.displayHP~=number or self.displayMax~=max then
  self.displayHP=number;self.displayMax=max
  setText(self.value,string.format("%d / %d HP",number,math.ceil(max)))
 end
 setText(self.stateText,band)
 local a,b;if dead then a,b=Color3.fromRGB(91,85,102),Color3.fromRGB(104,98,115) elseif ratio<=.3 then a,b=Color3.fromRGB(245,46,78),Color3.fromRGB(255,109,169) elseif ratio<=.65 then a,b=Color3.fromRGB(255,225,99),Color3.fromRGB(255,144,60) else a,b=U.hex(s.accent),U.hex(s.secondary) end
 local mix=if s.reduce or dead then 1 else 1-math.exp(-dt*12);self.tint=(self.tint or a):Lerp(a,mix);self.tint2=(self.tint2 or b):Lerp(b,mix);self.fillG.Color=ColorSequence.new(self.tint,self.tint2)
 local beat=0
 if not dead and not s.reduce then
  local period=.43+1.06*ratio^1.2
  self.beatPeriod=U.approach(self.beatPeriod or period,period,dt,.14)
  self.phase=(self.phase+dt*s.speed/100/self.beatPeriod)%1
  beat=smoothPulse(self.phase,.14,.13)+.55*smoothPulse(self.phase,.36,.105)
 else self.phase=0;self.beatPeriod=nil end
 local bump=if not s.reduce and not dead and (self.effect=="Heal" or self.effect=="Revive") then math.sin(math.pi*q)*(if self.effect=="Revive" then .22 else .09) else 0
 local side=35*(1+beat*(.12+.15*(1-ratio))+bump)
 self.heart.root.Size=UDim2.fromOffset(side,side)
 local ha,hm,hb=heartColors(s,ratio,dead,self.time)
 self.heartTint=(self.heartTint or ha):Lerp(ha,mix)
 self.heartMid=(self.heartMid or hm):Lerp(hm,mix)
 self.heartTint2=(self.heartTint2 or hb):Lerp(hb,mix)
 local angle=if s.heartDirection=="Horizontal" then 0 elseif s.heartDirection=="Diagonal" then 45 elseif s.heartDirection=="Reverse" then 270 elseif s.heartDirection=="Orbit" and not dead and not s.reduce then (90+self.time*s.heartGradientSpeed*.6)%360 else 90
 self.heart:paint(self.heartTint,self.heartTint2,if dead then 0 else math.clamp(s.heartGlow+beat*25,0,100),8,self.heartMid,angle)
 self.heart:opacity(if dead then .55 else 0)
 local shake=if not s.reduce and not dead and self.effect=="Damage" and self.age<.28 then math.sin(self.age*100)*3*(1-self.age/.28) else 0;self.hpShake=shake;w.rim.Color=self.tint;w.rim.Transparency=if dead then .9 else 1-math.min(1,(s.rim+beat*15)/100)
 self.shine.Visible=s.hudShine and not dead and not s.reduce and self.bar>.02 and s.hudMotion~="Off"
 if self.shine.Visible then
  local progress=(self.time*s.speed/100*.42)%1
  self.shineGradient.Offset=Vector2.new(-1.15+progress*2.3,0)
 end
 local reaction=if s.hudReaction and not s.reduce and s.hudMotion~="Off" and self.effect~="None" and not dead then math.exp(-self.age*5)*s.hudMotionStrength/100 else 0
 self.reactionStroke.Enabled=reaction>.01
 if self.reactionStroke.Enabled then
  self.reactionStroke.Color=if self.effect=="Damage" then Color3.fromRGB(255,100,145) elseif self.effect=="Heal" then Color3.fromRGB(123,234,193) else U.hex(s.secondary)
  self.reactionStroke.Transparency=1-reaction*.7
  self.reactionStroke.Thickness=1.5+reaction*2
 end
end
function H:animateWidgets(s,f,dt,t)
 local enabled=not s.reduce and s.hudMotion~="Off"
 local strength=s.hudMotionStrength/100
 local dur=math.max(.08,s.hudSmoothness/1000*100/s.speed)
 local time=t*s.speed/100
 for index,key in {"hp","clock","profile","dock"} do
  local w=self.widgets[key]
  local want=s[key] and (key~="hp" or f.hp~=nil)
  local target=if want then 1 else 0
  local progress=w.motion or 0
  if not enabled then progress=target
  else progress=math.clamp(progress+dt/dur*(if want then 1 else -1),0,1) end
  w.motion=progress
  local q=U.ease(progress,s.ease)
  w.p.Visible=want or progress>0
  w.p.GroupTransparency=1-q*s[key.."Alpha"]/100
  local x,y,ox,oy=self:placement(s,key)
  local alive=key~="hp" or (f.hp~=nil and f.hp>0)
  local idle=enabled and alive and want and not self.preview and not f.editingHUD
  local phase=time*1.8+index*.8
  local bob=if idle and s.hudMotion=="Float" then math.sin(phase)*3*strength else 0
  local pulse=if idle and s.hudMotion=="Pulse" then math.sin(phase)*.025*strength else 0
  local entry=if enabled then (1-q)*strength else 0
  local shake=if key=="hp" and not f.editingHUD then (self.hpShake or 0) else 0
  w.p.Position=UDim2.new(x,ox+shake,y,oy+bob+(if y>.5 then 1 else -1)*entry*14)
  w.scale.Scale=self.factor*s[key.."Scale"]/100*(1-entry*.08+pulse)
  if key~="hp" then
   local glow=if idle and s.hudMotion~="Off" then (.5+.5*math.sin(phase))*.18*strength else 0
   w.rim.Transparency=1-math.clamp(s.rim/100+glow,0,1)
   w.rim.Color=U.hex(s.accent):Lerp(U.hex(s.secondary),glow*2)
  end
  w.g.Rotation=if idle and s.hudMotion=="Glass" then 90+math.sin(phase*.5)*18*strength else 90
 end
 self.profileDot.BackgroundTransparency=if enabled then .12+.16*(1-math.sin(time*1.7)) else 0
end
function H:marker(id)
 local root=U.frame(self.layer,"Marker_"..id,nil,UDim2.fromOffset(40,40),nil,1);root.AnchorPoint=Vector2.new(.5,.5);local glyph=Symbol.new(root,"Soft Triangle",30)
 local label=U.label(root,"",11,UDim2.new(.5,-65,1,-4),UDim2.fromOffset(130,15));label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeTransparency=.3
 local m={root=root,glyph=glyph,label=label,fade=0};self.markers[id]=m;return m
end
function H:directions(s,f,dt,t,paint)
 self.serial=(self.serial or 0)+1;local view=self.view.AbsoluteSize;local w,h=view.X,view.Y
 if s.indicators and w>0 and h>0 then for _,p in f.targets do if p.visible or p.distance>s.reach then continue end;local id=p.id;local m=self.markers[id] or self:marker(id);m.serial=self.serial;local custom=s.players[id];m.glyph:shape(if custom then custom.shape else s.shape,s.corners)
  local dir=Vector2.new(p.x*w,p.y*h);if dir.Magnitude<.001 then dir=Vector2.yAxis end;dir=dir.Unit;local sz=s.size*self.factor*math.clamp(1.35/(1+p.distance*.002),.65,1.35);local px=math.max(sz*.7,w*s.edge/100);local py=math.max(sz*.7+(if s.labels=="Off" then 0 else 12),h*s.edge/100);local d=math.max(0,math.min((w/2-px)/math.max(.0001,math.abs(dir.X)),(h/2-py)/math.max(.0001,math.abs(dir.Y))));local dest=view*.5+dir*d
  local k=if s.reduce or s.turn==0 then 1 else 1-math.exp(-dt*4500/s.turn);local angle=math.deg(math.atan2(dir.X,-dir.Y));m.pos=(m.pos or dest):Lerp(dest,k);m.angle=m.angle or angle;m.angle+=((angle-m.angle+180)%360-180)*k;m.root.Position=UDim2.fromOffset(m.pos.X,m.pos.Y);m.glyph.root.Rotation=m.angle
  local pulse=if s.pulse and not s.reduce then 1+.075*math.sin(t*4*s.arrowSpeed/100) else 1;m.root.Size=UDim2.fromOffset(sz*pulse,sz*pulse);m.fade=if s.reduce then 1 else math.min(1,m.fade+dt*6)
  if paint or m.style~=s then local time=if s.reduce then 0 else t;local c=if custom then U.hex(custom.color) elseif s.arrowRainbow then Color3.fromHSV((time*.14*s.arrowSpeed/100)%1,.68,1) else U.hex(s.arrowA);local b=if s.arrowRainbow then Color3.fromHSV((time*.14*s.arrowSpeed/100+.29)%1,.62,1) else U.hex(s.arrowB);m.glyph:paint(c,b,s.ink,s.spread);m.label.FontFace=U.font(s);m.style=s end
  local title=if custom and custom.label~="" then custom.label else p.label;local dist=math.round(p.distance).."m";m.glyph:opacity(1-m.fade*s.arrowAlpha/100);m.label.TextTransparency=1-m.fade*s.arrowAlpha/100;m.label.Visible=s.labels~="Off";m.label.Text=if s.labels=="Both" then title.." · "..math.round(p.distance).." st" elseif s.labels=="Distance" then math.round(p.distance).." st" else title
 end end
 for id,m in self.markers do if m.serial~=self.serial then m.fade=if s.reduce then 0 else math.max(0,m.fade-dt*7) end;if m.fade<=0 then m.root:Destroy();self.markers[id]=nil else local alpha=1-m.fade*s.arrowAlpha/100;m.glyph:opacity(alpha);m.label.TextTransparency=alpha end end
end
function H:step(s,f,dt)
 if self.settings~=s or self.width~=self.view.AbsoluteSize.X then self:setStyle(s) end;self.time+=dt;local t=self.time;local paint=t>=self.paintAt;if paint then self.paintAt=t+.075 end
 self:reticle(s,f,t);self:vitals(s,f,dt);self:animateWidgets(s,f,dt,t);self:directions(s,f,dt,t,paint)
 local overlay=self.inputRoot
 overlay.Visible=s.inputOverlay
 if overlay.Visible then
  local k=s.inputScale/100*(if self.preview then self.factor else 1)
  local w,h=172*k,(if s.inputMouse then 156 else 114)*k
  local vp=self.view.AbsoluteSize
  overlay.Size=UDim2.fromOffset(172,if s.inputMouse then 156 else 114)
  if not self.inputScale then self.inputScale=U.new("UIScale",{},overlay) end
  self.inputScale.Scale=k
  overlay.Position=UDim2.fromOffset(math.clamp(vp.X*s.inputX/100,w/2,math.max(w/2,vp.X-w/2)),math.clamp(vp.Y*s.inputY/100,h/2,math.max(h/2,vp.Y-h/2)))
  overlay.GroupTransparency=1-s.inputOpacity/100
  local focused=UIS:GetFocusedTextBox()~=nil
  local tint=U.hex(s.inputColor)
  for _,key in self.inputKeys do
   key.p.Visible=not key.mouse or s.inputMouse
   local down=false
   if not focused then
    if key.mouse then down=UIS:IsMouseButtonPressed(key.code)
    else down=UIS:IsKeyDown(key.code) or (key.code==Enum.KeyCode.LeftShift and UIS:IsKeyDown(Enum.KeyCode.RightShift)) end
   end
   key.p.BackgroundColor3=if down then tint else Color3.fromRGB(33,27,49)
   key.label.TextColor3=if down then Color3.fromRGB(25,18,39) else Color3.fromRGB(240,233,255)
   key.rim.Color=tint;key.rim.Transparency=if down then .1 else .55
  end
 end
 local wh=self.wallhop
 wh.Visible=s.wallhopHelper
 if wh.Visible then
  local vp=self.view.AbsoluteSize
  local scale=s.wallhopScale/100*(if self.preview then self.factor else 1)
  self.wallhopScale.Scale=scale;wh.GroupTransparency=1-s.wallhopOpacity/100
  local halfW,halfH=105*scale,43*scale
  wh.Position=UDim2.fromOffset(math.clamp(vp.X*s.wallhopX/100,halfW,math.max(halfW,vp.X-halfW)),math.clamp(vp.Y*s.wallhopY/100,halfH,math.max(halfH,vp.Y-halfH)))
  local camera=workspace.CurrentCamera
  local direction=camera and camera.CFrame.LookVector
  local yaw=if direction then math.atan2(direction.X,direction.Z) else 0
  local down=UIS:GetFocusedTextBox()==nil and UIS:IsKeyDown(Enum.KeyCode.Space)
  if down and not self.whDown then self.whStart=t;self.whYaw=yaw;self.whAngle=0 end
  self.whDown=down
  if self.whStart and t-self.whStart<=1.5 then
   local delta=math.deg(math.atan2(math.sin(yaw-self.whYaw),math.cos(yaw-self.whYaw)))
   self.whAngle=math.max(self.whAngle or 0,math.abs(delta))
   setText(self.wallhopText,if down then "JUMP INPUT" else "CAMERA ROTATION")
   setText(self.wallhopDetail,string.format("%d° turn   ·   %d ms",math.floor(self.whAngle+.5),math.floor((t-self.whStart)*1000)))
   self.wallhopText.TextColor3=U.hex(s.accent)
  elseif self.whStart then
   setText(self.wallhopText,"LAST ATTEMPT")
   setText(self.wallhopDetail,string.format("Peak rotation: %d°",math.floor((self.whAngle or 0)+.5)))
  else
   setText(self.wallhopText,"READY")
   setText(self.wallhopDetail,"Space · manual camera turn")
  end
 else self.whStart=nil;self.whDown=false;self.whAngle=nil end
 if not self.fpsAt or t>=self.fpsAt then
  self.fpsAt=t+.25
  setText(self.name,if f.fps then string.format("%d FPS",math.floor(f.fps+.5)) else "— FPS")
 end
 setText(self.clockSub,f.mode)
 if not self.clockAt or t>=self.clockAt then
  self.clockAt=t+.25
  setText(self.clock,os.date("%H:%M"))
 end
 -- Decorative motion is evaluated every render frame, not on the text refresh timer.
 local sparkleTint=U.hex(s.secondary)
 for i,n in self.spark do
  n.Visible=s.sparkles
  if s.sparkles then
   if paint then n.BackgroundColor3=sparkleTint end
   if not s.reduce or paint then n.Position=UDim2.fromScale((i*.617)%1,(i*.349-(if s.reduce then 0 else t*.014))%1) end
  end
 end
 for id,n in self.extras do if not f.widgets[id] then n:Destroy();self.extras[id]=nil end end
 for id,w in f.widgets do local n=self.extras[id];if not n then n=U.label(self.view,"",14,nil,UDim2.fromOffset(150,25));n.Name="Cue_"..id;n.ZIndex=4;self.extras[id]=n end;n.Text=w.text;n.FontFace=U.font(s);n.TextColor3=U.hex(s.fontA);n.TextStrokeTransparency=.4;local wave=if s.reduce then 0 else math.sin(t*3);n.Position=UDim2.new(w.x/100,0,w.y/100,if w.animation=="float" then wave*5 else 0);n.TextTransparency=if w.animation=="pulse" then .17+wave*.16 else 0 end
end
return H