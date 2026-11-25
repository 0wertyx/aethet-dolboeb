local StarterGui=game:GetService("StarterGui");local Chat=game:GetService("TextChatService");local Input=game:GetService("UserInputService");local Tween=game:GetService("TweenService");local U=require(script.Parent.Util);local S=require(script.Parent.Schema);local Icons=require(script.Parent.Icons)
local Constellation=require(script.Parent.Constellation)
local UI={};UI.__index=UI
local bg=Color3.fromRGB(19,16,32);local dim=Color3.fromRGB(173,163,197);local soft=Color3.fromRGB(43,35,60)
-- Native GUI at rest: CanvasGroup is only a short-lived fade compositor.
-- Restore direct descendants at full opacity so text, glyphs and ViewportFrames
-- do not keep rendering into a potentially downsampled offscreen surface.
local function transition(root,q)
 local group=root:FindFirstChild("AETHERTransitionSurface")
 if q>=.99999 then
  if group then
   for _,child in group:GetChildren() do child.Parent=root end
   group:Destroy()
  end
  return
 end
 if not group then
  group=U.new("CanvasGroup",{Name="AETHERTransitionSurface",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=1-q},root)
 end
 for _,child in root:GetChildren() do
  if child~=group and child:IsA("GuiObject") then child.Parent=group end
 end
 group.GroupTransparency=1-q
end
function UI.new(app,gui,scope)
 local self=setmetatable({app=app,gui=gui,scope=scope,syncs={},icons={},tab="Dashboard",opened=true,seq=0,menuProgress=0,pageProgress=0,navHover={},navAmount={}},UI)
 self.stage=U.frame(gui,"StudioArea",nil,nil,nil,1)
 -- The backdrop is deliberately not a fullscreen CanvasGroup: each particle fades separately.
 self.screenFX=U.frame(self.stage,"MenuScreenEffects",nil,nil,nil,1)
 self.screenFX.Active=false;self.screenFX.Interactable=false
 self.screenFX.Visible=false
 self.screenDim=U.frame(self.screenFX,"Veil",nil,nil,Color3.fromRGB(19,12,38),1)
 self.screenDim.Active=false;self.screenDim.Interactable=false
 self.stars={}
 for i=1,48 do
  local root=U.frame(self.screenFX,"Particle"..i,nil,UDim2.fromOffset(12,12),nil,1)
  root.Active=false;root.Interactable=false;root.AnchorPoint=Vector2.new(.5,.5)
  local bars={}
  for j=1,4 do
   local line=U.frame(root,"Ray",UDim2.fromScale(.5,.5),UDim2.fromScale(1,.13),Color3.new(1,1,1),1)
   line.AnchorPoint=Vector2.new(.5,.5);line.Active=false;line.Interactable=false;line.Rotation=(j-1)*45;U.corner(line,9);bars[j]=line
  end
  local dot=U.frame(root,"Core",UDim2.fromScale(.5,.5),UDim2.fromScale(.5,.5),Color3.new(1,1,1),1)
  dot.AnchorPoint=Vector2.new(.5,.5);dot.Active=false;dot.Interactable=false;U.corner(dot,99)
  self.stars[i]={root=root,bars=bars,dot=dot}
 end
 self.top,self.topRim,self.topButtons=U.topPanel(self.stage)
 self.updateChip=U.button(self.top,"v1.0.0")
 self.updateChip.Name="LiveVersion"
 self.updateChip.AnchorPoint=Vector2.new(.5,0)
 self.updateChip.Position=UDim2.new(.5,0,1,6)
 self.updateChip.Size=UDim2.fromOffset(112,22)
 self.updateChip.TextSize=10;self.updateChip.ZIndex=self.top.ZIndex+2
 self.updateChip.BackgroundTransparency=.15
 self.updateRim=U.stroke(self.updateChip,Color3.fromRGB(166,138,255),.45)
 scope:on(self.updateChip.Activated,function() self:open("Updates") end)
 scope:on(self.topButtons[1].Activated,function() self:show(not self.opened) end)
 self.rail,self.railRim,self.railButtons,self.railCollapse=U.railPanel(self.stage)
 local coreOriginal,coreApplied={},{}
 local chatOriginal,chatApplied,chatConfig=nil,nil,nil
 scope:add(function()
  for kind,original in coreOriginal do pcall(function() if StarterGui:GetCoreGuiEnabled(kind)==coreApplied[kind] then StarterGui:SetCoreGuiEnabled(kind,original) end end) end
  if chatConfig and chatConfig.Parent and chatConfig.Enabled==chatApplied then chatConfig.Enabled=chatOriginal end
 end)
 for index,item in {{"CHAT",Enum.CoreGuiType.Chat},{"BAG",Enum.CoreGuiType.Backpack},{"LIST",Enum.CoreGuiType.PlayerList}} do
  local button=self.railButtons[index]
  scope:on(button.Activated,function()
   self:action(function()
    if item[2]==Enum.CoreGuiType.PlayerList then self:open("List");return end
    if item[2]==Enum.CoreGuiType.Chat then
     local config=Chat:FindFirstChildOfClass("ChatWindowConfiguration")
     if config then if chatConfig~=config then chatConfig=config;chatOriginal=config.Enabled end;config.Enabled=not config.Enabled;chatApplied=config.Enabled;button.BackgroundTransparency=if config.Enabled then .12 else .6;return end
    end
    local enabled=StarterGui:GetCoreGuiEnabled(item[2])
    if coreOriginal[item[2]]==nil then coreOriginal[item[2]]=enabled end
    StarterGui:SetCoreGuiEnabled(item[2],not enabled);coreApplied[item[2]]=not enabled
    button.BackgroundTransparency=if enabled then .6 else .12
    if item[2]==Enum.CoreGuiType.Backpack and not enabled then self:message("Roblox backpack enabled; use the native inventory control to expand it.") end
   end)
  end)
 end
 function self:togglePlayerList()
  local kind=Enum.CoreGuiType.PlayerList
  local enabled=StarterGui:GetCoreGuiEnabled(kind)
  if coreOriginal[kind]==nil then coreOriginal[kind]=enabled end
  StarterGui:SetCoreGuiEnabled(kind,not enabled);coreApplied[kind]=not enabled
  self:message(if enabled then "Roblox player list hidden" else "Roblox player list enabled")
 end
 scope:on(self.railCollapse.Activated,function() self.railCollapsed=not self.railCollapsed;self:layout() end)
 self.panel=U.new("Frame",{Name="Studio",BackgroundColor3=bg,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,Active=true},self.stage);U.corner(self.panel,17);self.outline=U.stroke(self.panel,Color3.fromRGB(159,127,230),.3)
 self.panelBackground=U.frame(self.panel,"GlassBackground",nil,nil,Color3.new(1,1,1),.035);self.panelBackground.Active=false;self.panelBackground.Interactable=false;self.panelBackground.ZIndex=1;U.corner(self.panelBackground,17)
 self.backgroundGradient=U.gradient(self.panelBackground,bg,Color3.fromRGB(39,30,58),82)
 self.geoLayer=U.frame(self.panel,"GeometryBackground",UDim2.fromOffset(3,3),UDim2.new(1,-6,1,-6),nil,1)
 self.geoLayer.ClipsDescendants=true;self.geoLayer.Active=false;self.geoLayer.ZIndex=1
 self.constellation=Constellation.new(self.geoLayer)
 self.header=U.frame(self.panel,"Titlebar",nil,UDim2.new(1,0,0,46),nil,1);self.header.Active=true;self.brand=U.label(self.header,"A E T H E R",18,UDim2.fromOffset(16,2),UDim2.fromOffset(135,40));self.tag=U.label(self.header,"",10,UDim2.fromOffset(147,3),UDim2.new(1,-190,0,40));self.tag.TextColor3=dim
 self.close=U.button(self.header,"×");self.close.Modal=true;self.close.Size=UDim2.fromOffset(33,29);self.close.Position=UDim2.new(1,-43,0,8);scope:on(self.close.Activated,function() self:show(false) end)
 self.dockPicker=U.button(self.header,"←");self.dockPicker.Size=UDim2.fromOffset(32,29);self.dockPicker.Position=UDim2.new(1,-79,0,8);self.dockPicker.TextSize=18
 local sides={"Left","Right","Top","Bottom","Floating"}
 scope:on(self.dockPicker.Activated,function()
  self.app:set("menuDock",sides[(table.find(sides,self.app.s.menuDock) or 0)%#sides+1])
 end)
 self.grip=U.button(self.panel,"◢");self.grip.Name="ResizeGrip";self.grip.Size=UDim2.fromOffset(26,26);self.grip.TextSize=18;self.grip.ZIndex=6;self.grip.BackgroundTransparency=.42
 self.tag.Size=UDim2.new(1,-231,0,40)
 self.place=U.label(self.panel,"PLACE  /  "..tostring(game.PlaceId),10,nil,nil);self.place.TextColor3=dim
 self.nav=U.new("ScrollingFrame",{Name="Navigation",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3},self.panel);self.navList=U.new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},self.nav)
 self.pageBox=U.new("Frame",{Name="PageArea",BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true},self.panel);self.status=U.label(self.panel,"",11,UDim2.new(0,16,1,-28),UDim2.new(1,-32,0,22));self.status.TextColor3=dim
 self.buttons={};for i,name in {"Dashboard","HUD","Character","Wings","Halos","Neon","Ambient","Indicators","Cursor","Camera","Interaction","Fonts","Simulator","Scripts","Profiles","Updates","List","Diagnostics"} do local b=U.button(self.nav,name);b.Name=name;b.LayoutOrder=i;self.buttons[name]=b;self.icons[name]=Icons.new(b,name);scope:on(b.Activated,function() self:open(name) end);scope:on(b.MouseEnter,function() self.navHover[name]=true end);scope:on(b.MouseLeave,function() self.navHover[name]=false end) end
 function self:layout()
  local sz=self.stage.AbsoluteSize
  if sz.X<2 or sz.Y<2 then return end
  local s=self.app.s;local draft=self.menuDraft
  local side=if draft then draft.side else s.menuDock
  local narrow=sz.X<740
  local left=if s.robloxRail and not narrow then 78 else 12
  local top=if narrow then 92 else 62
  local bottom=if narrow then 126 else 76
  if sz.Y<420 then top=12;bottom=12 end
  local maxW=math.max(1,math.min(1600,sz.X-left-14))
  local maxH=math.max(1,math.min(1200,sz.Y-top-bottom))
  local w=math.clamp(if draft then draft.w else s.menuWidth,math.min(280,maxW),maxW)
  local h=math.clamp(if draft then draft.h else s.menuHeight,math.min(260,maxH),maxH)
  local x,y
  if draft and draft.xy then
   x=draft.xy.X;y=draft.xy.Y
  elseif side=="Left" then
   x=left;y=top+math.max(0,maxH-h)*.5
  elseif side=="Right" then
   x=sz.X-w-14;y=top+math.max(0,maxH-h)*.5
  elseif side=="Top" then
   x=(sz.X-w)*.5;y=top
  elseif side=="Bottom" then
   x=(sz.X-w)*.5;y=sz.Y-h-bottom
  else
   x=(sz.X-w)*s.menuFloatX/100;y=(sz.Y-h)*s.menuFloatY/100
  end
  self.xy=Vector2.new(math.clamp(x,0,math.max(0,sz.X-w)),math.clamp(y,0,math.max(0,sz.Y-h)))
  self.panel.Size=UDim2.fromOffset(w,h);self.panel.Position=UDim2.fromOffset(self.xy.X,self.xy.Y)
  self.layoutSide=side;self.panelExtent=Vector2.new(w,h)
  self.dockPicker.Text=({Left="←",Right="→",Top="↑",Bottom="↓",Floating="◇"})[side] or "◇"
  self.grip.Visible=s.menuResize
  self.grip.Position=if side=="Right" then UDim2.new(0,4,1,-30) elseif side=="Bottom" then UDim2.fromOffset(4,4) else UDim2.new(1,-30,1,-30)
  self.grip.Text=if side=="Right" then "◣" elseif side=="Bottom" then "◤" else "◢"
  self.brand.Position=UDim2.fromOffset(if side=="Bottom" and s.menuResize then 34 else 16,2)
  self.brand.Size=UDim2.fromOffset(if side=="Bottom" and s.menuResize then 111 else 135,40)
  self.top.Size=UDim2.fromOffset(math.min(136,math.max(90,sz.X-24)),38)
  self.top.Position=UDim2.new(.5,0,0,if narrow then 48 else 12)
  self.rail.Position=UDim2.new(0,12,.46,0)
  self.rail.Size=UDim2.fromOffset(54,if self.railCollapsed then 44 else 176)
  for _,button in self.railButtons do button.Visible=not self.railCollapsed end
  for _,spec in {{self.top,"top"},{self.rail,"rail"}} do
   local panel,key=spec[1],spec[2]
   if s[key.."Custom"] then
    panel.AnchorPoint=Vector2.zero
    panel.Position=UDim2.fromOffset(math.max(0,sz.X-panel.Size.X.Offset)*s[key.."X"]/100,math.max(0,sz.Y-panel.Size.Y.Offset)*s[key.."Y"]/100)
   else
    panel.AnchorPoint=if key=="top" then Vector2.new(.5,0) else Vector2.new(0,.5)
   end
  end
  self.railCollapse.Position=UDim2.fromOffset(5,if self.railCollapsed then 5 else 136)
  self.railCollapse.Text=if self.railCollapsed then "›" else "‹"
  self.place.Position=UDim2.fromOffset(12,48);self.place.Size=UDim2.new(1,-24,0,17)
  self.nav.Position=UDim2.fromOffset(10,69);self.nav.Size=UDim2.new(1,-20,0,37)
  self.navList.FillDirection=Enum.FillDirection.Horizontal
  self.nav.AutomaticCanvasSize=Enum.AutomaticSize.X;self.nav.ScrollingDirection=Enum.ScrollingDirection.X
  for _,b in self.buttons do b.Size=UDim2.fromOffset(106,32) end
  self.pageBox.Position=UDim2.fromOffset(10,114);self.pageBox.Size=UDim2.new(1,-20,1,-145)
  self.layoutKey=table.concat({s.menuDock,s.menuWidth,s.menuHeight,s.menuFloatX,s.menuFloatY,tostring(s.menuResize),tostring(s.robloxRail),tostring(s.topCustom),s.topX,s.topY,tostring(s.railCustom),s.railX,s.railY},":")
 end
 function self:finishMenuDrag(point,resize)
  local s=self.app.s;local d=self.menuDraft
  if not d then return end
  local sz=self.stage.AbsoluteSize;local size=self.panelExtent;local xy=self.xy
  self.menuDraft=nil
  local patch={}
  if resize then
   patch.menuWidth=math.clamp(math.round(size.X),280,1600)
   patch.menuHeight=math.clamp(math.round(size.Y),260,1200)
  else
   local side="Floating"
   local distances={Left=point.X-self.stage.AbsolutePosition.X,Right=sz.X-(point.X-self.stage.AbsolutePosition.X),Top=point.Y-self.stage.AbsolutePosition.Y,Bottom=sz.Y-(point.Y-self.stage.AbsolutePosition.Y)}
   local best=65
   for _,edge in {"Left","Right","Top","Bottom"} do
    if distances[edge]<best then best=distances[edge];side=edge end
   end
   if side=="Floating" then
    local left=if s.robloxRail and sz.X>=740 then 78 else 12
    local margins={Left=math.abs(xy.X-left),Right=math.abs(sz.X-size.X-14-xy.X),Top=math.abs(xy.Y-(if sz.X<740 then 92 else 62)),Bottom=math.abs(sz.Y-size.Y-(if sz.X<740 then 126 else 76)-xy.Y)}
    best=26
    for _,edge in {"Left","Right","Top","Bottom"} do
     if margins[edge]<best then best=margins[edge];side=edge end
    end
   end
   patch.menuDock=side
   patch.menuFloatX=math.clamp(math.round(100*xy.X/math.max(1,sz.X-size.X)),0,100)
   patch.menuFloatY=math.clamp(math.round(100*xy.Y/math.max(1,sz.Y-size.Y)),0,100)
  end
  self.app:patch(patch);self:layout()
 end
 local function moveStart(input)
  if not self.app.s.menuDrag or self.drag or not self.opened then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  if input.Position.X>self.header.AbsolutePosition.X+self.header.AbsoluteSize.X-84 then return end
  if not self.xy or not self.panelExtent then return end
  local origin=self.xy;local size=self.panelExtent
  self:begin(input,function(point,start)
   self.menuDraft={side="Floating",w=size.X,h=size.Y,xy=origin+point-start}
   self:layout()
  end,origin)
  if self.drag then self.drag.finish=function(point) self:finishMenuDrag(point,false) end end
 end
 scope:on(self.header.InputBegan,moveStart)
 self.brand.Active=true;self.tag.Active=true
 scope:on(self.brand.InputBegan,moveStart);scope:on(self.tag.InputBegan,moveStart)
 scope:on(self.grip.InputBegan,function(input)
  if not self.app.s.menuResize or self.drag or not self.opened then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  if not self.xy or not self.panelExtent then return end
  local side=self.app.s.menuDock;local size=self.panelExtent;local origin=self.xy
  self:begin(input,function(point,start)
   local delta=point-start
   local w=math.max(280,size.X+delta.X*(if side=="Right" or side=="Bottom" then -1 else 1))
   local h=math.max(260,size.Y+delta.Y*(if side=="Bottom" then -1 else 1))
   self.menuDraft={side=side,w=w,h=h,xy=if side=="Floating" then origin else nil}
   self:layout()
  end,origin)
  if self.drag then self.drag.finish=function(point) self:finishMenuDrag(point,true) end end
 end)
 scope:on(self.stage:GetPropertyChangedSignal("AbsoluteSize"),function() self:layout() end);self:layout()
 scope:on(Input.InputChanged,function(i) local d=self.drag;if d and (i==d.i or d.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement) then d.fn(Vector2.new(i.Position.X,i.Position.Y),d.start,d.origin) end end)
 scope:on(Input.InputEnded,function(i) if self.drag and (self.drag.i==i or self.drag.i.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseButton1) then local d=self.drag;self.drag=nil;if d.finish then d.finish(Vector2.new(i.Position.X,i.Position.Y)) end end end)
 scope:on(Input.WindowFocusReleased,function() self.drag=nil;if self.menuDraft then self.menuDraft=nil;self:layout() end end);scope:add(function() if self.page then self.page:clear() end;Icons.clear() end);return self
end
function UI:animateBackground(t)
 local s=self.app.s
 local dt=math.clamp(t-(self.motionAt or t-1/60),0,.1)
 self.motionAt=t
 local immediate=s.reduce or s.menuTransition=="Off"
 local duration=math.max(.06,s.duration/1000*100/s.speed)
 local target=if self.opened then 1 else 0
 local step=dt/duration
 if immediate then self.menuProgress=target
 else self.menuProgress=math.clamp(self.menuProgress+step*(if self.opened then 1 else -1),0,1) end
 self.panel.Visible=self.opened or self.menuProgress>0
 local q=U.ease(self.menuProgress,s.ease)
 transition(self.panel,if self.panel.Visible then q else 1)
 local strength=s.menuAnimStrength/100
 if self.xy then
  local dx,dy=0,0
  local side=self.layoutSide or s.menuDock
  local distance=(1-q)*(.65+.35*strength)
  if not immediate and s.menuTransition~="Fade" and not self.menuDraft then
   local extent=self.panelExtent or self.panel.AbsoluteSize;local sz=self.stage.AbsoluteSize
   if side=="Left" then dx=-(self.xy.X+extent.X+8)*distance
   elseif side=="Right" then dx=(sz.X-self.xy.X+8)*distance
   elseif side=="Top" then dy=-(self.xy.Y+extent.Y+8)*distance
   elseif side=="Bottom" then dy=(sz.Y-self.xy.Y+8)*distance
   else dy=18*strength*(1-q) end
  end
  self.panel.Position=UDim2.fromOffset(math.round(self.xy.X+dx),math.round(self.xy.Y+dy))
 end
 local accent=U.hex(s.accent)
 local secondary=U.hex(s.secondary)
 self.top.Visible=s.topCapsule;self.rail.Visible=s.robloxRail
 local live=self.app.liveUpdate
 if live then
  local unread=live.unread==true
  local version=live.version..(if (live.testCount or 0)>0 and live.isTest then " · TEST "..tostring(live.testCount) else "")
  local text=if unread then "v"..version.."  |  VERSION UPDATED  |  CHECK UPDATE LIST" else "v"..version
  if self.updateChip.Text~=text then self.updateChip.Text=text end
  local width=if unread then math.min(370,math.max(150,self.stage.AbsoluteSize.X-24)) else math.min(180,math.max(90,#text*7+20))
  self.updateChip.Size=UDim2.fromOffset(width,if unread then 28 else 22)
  self.updateChip.BackgroundColor3=if unread then accent:Lerp(Color3.fromRGB(22,17,35),.65) else Color3.fromRGB(24,20,40)
  self.updateRim.Color=accent
  self.updateRim.Transparency=if unread then .15 else .55
 end
 self.topRim.Color=accent;self.railRim.Color=accent
 self.topButtons[1].BackgroundColor3=if self.opened then accent:Lerp(bg,.55) else soft
 local visible=s.screenParticles and q>.001
 self.screenFX.Visible=visible
 if visible then
  local motion=if s.reduce then 0 else t*s.menuMotion/100
  local alpha=q*s.screenParticleOpacity/100
  self.screenDim.BackgroundTransparency=1-alpha*.12
  local style=s.screenParticleStyle
  for index,particle in self.stars do
   local active=index<=s.screenParticleCount
   particle.root.Visible=active
   if not active then continue end
   local kind=if style=="Mixed" then ({"Stars","Dust","Diamonds"})[index%3+1] else style
   local phase=motion*.64+index*1.73
   local twinkle=if s.reduce then .7 else .54+.46*math.sin(phase)
   local size=(if kind=="Dust" then 3+index%4 else 7+index%10)*( .82+.18*twinkle)
   particle.root.Size=UDim2.fromOffset(math.max(2,math.round(size)),math.max(2,math.round(size)))
   particle.root.Position=UDim2.fromScale(.03+((index*.618)%1)*.94+math.sin(phase*.43)*.014,(index*.381+1-motion*.012)%1)
   particle.root.Rotation=if kind=="Diamonds" then 45+motion*4 elseif kind=="Stars" then motion*5+index*19 else 0
   local color=accent:Lerp(secondary,(index%7)/6)
   particle.dot.BackgroundColor3=color
   particle.dot.BackgroundTransparency=1-alpha*twinkle*.65
   particle.dot.Size=if kind=="Diamonds" then UDim2.fromScale(.65,.65) else UDim2.fromScale(.45,.45)
   for j,bar in particle.bars do
    bar.Visible=kind=="Stars"
    if bar.Visible then
     bar.Size=UDim2.fromOffset(math.max(1,math.round(size*(if j%2==1 then 1 else .63))),math.max(1,math.round(size*.13)))
     bar.BackgroundColor3=color;bar.BackgroundTransparency=1-alpha*twinkle*.77
    end
   end
  end
 end
 if not self.panel.Visible then return end
 local tm=if s.reduce then 0 else t*s.speed/100
 self.outline.Color=accent:Lerp(U.hex(s.secondary),if s.reduce or not s.navGlow then 0 else .18+.15*math.sin(tm*1.6))
 self.outline.Transparency=1-math.clamp(s.rim/100*(if s.reduce or not s.navGlow then 1 else .85+.15*math.sin(tm*1.8)),0,1)
 self.outline.Transparency=1-(1-self.outline.Transparency)*q
 self.outline.Thickness=if s.reduce or not s.navGlow then 1 else 1.2+.3*math.sin(tm*1.6)
 self.pageProgress=if immediate or not s.tabTransition then 1 else math.min(1,self.pageProgress+dt/math.max(.06,duration*.72))
 local pageQ=U.ease(self.pageProgress,s.ease)
 transition(self.pageBox,pageQ)
 if self.sc and self.sc.Parent then self.sc.Position=UDim2.fromOffset((1-pageQ)*12*strength,0) end
 for name,b in self.buttons do
  local desired=if name==self.tab then 1 elseif self.navHover[name] then .45 else 0
  local amount=self.navAmount[name] or 0
  local k=if s.reduce or not s.navGlow then 1 else 1-math.exp(-dt*15)
  amount+=(desired-amount)*k
  self.navAmount[name]=amount
  b.BackgroundColor3=soft:Lerp(accent:Lerp(bg,.42),amount)
 end
 self.geoLayer.Visible=s.menuGeometry and self.panel.Visible
 if self.geoLayer.Visible then self.constellation:step(dt,s) end
end
function UI:begin(i,fn,origin) if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end;local v=Vector2.new(i.Position.X,i.Position.Y);self.drag={i=i,start=v,fn=fn,origin=origin};fn(v,v,origin) end
function UI:show(on)
 self.opened=on
 self.panel.Interactable=on
 if on then self.panel.Visible=true end
 self.drag=nil
 if self.menuDraft then self.menuDraft=nil;self:layout() end
 if self.app.s.reduce or self.app.s.menuTransition=="Off" then
  self.menuProgress=if on then 1 else 0
  transition(self.panel,1)
  self.panel.Visible=on
 end
 if self.app.onMenu then self.app:onMenu(on) end
end
function UI:message(s) self.status.Text=s end
function UI:open(tab)
 if not self.buttons[tab] then return end;self:show(true);self.drag=nil;if self.page then self.page:clear() end;self.app.preview=nil;self.page=U.scope();self.syncs={};self.controlKeys={};self.colorKeys={};self.seq=0;self.tab=tab
 self.pageProgress=if self.app.s.reduce or not self.app.s.tabTransition or self.app.s.menuTransition=="Off" then 1 else 0
 transition(self.pageBox,U.ease(self.pageProgress,self.app.s.ease))
 local sc=self.page:add(U.new("ScrollingFrame",{Name="Page_"..tab,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=dim,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},self.pageBox));U.new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sc);self.sc=sc
 self:title(tab:upper().."   /   AETHER STUDIO");self.app:page(tab,self);self:sync()
end
function UI:row(h,name) self.seq+=1;local f=U.frame(self.sc,name or "Row",nil,UDim2.new(1,-8,0,h),soft,.47);f.LayoutOrder=self.seq;U.corner(f,8);return f end
function UI:title(str) local f=self:row(26,"Heading");f.BackgroundTransparency=1;local n=U.label(f,str,13);n.TextColor3=U.hex(self.app.s.accent);self.titleLabel=n;return n end
function UI:note(str,h) local f=self:row(h or 36,"Note");f.BackgroundTransparency=1;local l=U.label(f,str,12);l.TextWrapped=true;l.TextTruncate=Enum.TextTruncate.None;l.TextColor3=dim;l:SetAttribute("AETHERMuted",true);return l end
function UI:watch(fn) table.insert(self.syncs,fn);fn() end
function UI:sync()
 if not self.panel.Parent then return end
 local st=self.app.s
 self.backgroundGradient.Color=ColorSequence.new(U.hex(st.constellationBgA),U.hex(st.constellationBgB))
 self.backgroundGradient.Rotation=st.constellationAngle
 local layoutKey=table.concat({st.menuDock,st.menuWidth,st.menuHeight,st.menuFloatX,st.menuFloatY,tostring(st.menuResize),tostring(st.robloxRail),tostring(st.topCustom),st.topX,st.topY,tostring(st.railCustom),st.railX,st.railY},":")
 if self.layoutKey~=layoutKey and not self.menuDraft then self:layout() end
 local primary=U.hex(st.uiFontColor or "F1E6FF")
 local muted=U.hex(st.uiMutedColor or "ADA3C5")
 self.brand.TextColor3=U.hex(st.accent)
 self.outline.Color=self.brand.TextColor3
 self.tag.Text=self.app.mode.." / "..(self.app.liveUpdate and self.app.liveUpdate.version or "LIVE 1.0")
 self.tag.TextColor3=muted
 self.status.TextColor3=muted
 for _,asset in self.icons do asset:sync(st.iconAtlas,st.iconAtlasTile) end
 for _,f in self.syncs do f() end
 -- Only recolor editor controls, not HUD/3D previews or their own palette.
 for _,obj in self.panel:GetDescendants() do
  if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
   if obj==self.brand or obj==self.tag or obj==self.status then continue end
   if obj:GetAttribute("AETHERKeepFontColor") then continue end
   local holder=obj.Parent
   local skip=false
   while holder and holder~=self.panel do
    if holder.Name=="LivePreview" or holder.Name=="RigPreview"
      or holder.Name=="CursorPreview" or holder.Name=="ShapeGallery" then
     skip=true;break
    end
    if S.defs[holder.Name] and S.defs[holder.Name].kind=="color" and obj:IsA("TextLabel") then
     skip=true;break
    end
    holder=holder.Parent
   end
   if skip then continue end
   if obj:IsA("TextLabel") and obj.Parent and obj.Parent.Name=="Heading" then
    obj.TextColor3=U.hex(st.accent)
   elseif obj:GetAttribute("AETHERMuted") then
    obj.TextColor3=muted
   else
    obj.TextColor3=primary
   end
  end
 end
end
function UI:action(fn) local ok,err=pcall(fn);if not ok then self.app:log("Error",tostring(err));self:message(tostring(err):sub(-150)) end end
function UI:chips(items,fn,cols,selected)
 cols=cols or 3;for start=1,#items,cols do local row=self:row(33,"Actions");row.BackgroundTransparency=1;for j=0,math.min(cols-1,#items-start) do local item=items[start+j];local b=U.button(row,item);b.Name=item;b.Size=UDim2.new(1/cols,-4,1,0);b.Position=UDim2.fromScale(j/cols,0);self.page:on(b.Activated,function() self:action(function() fn(item) end) end);if selected then self:watch(function() b.BackgroundColor3=if selected()==item then Color3.fromRGB(98,68,150) else soft end) end end end
end
function UI:box(label,initial,h,commit)
 self:title(label);local r=self:row(h or 34,"Field");local t=U.new("TextBox",{Name=label,Size=UDim2.new(1,-12,1,-4),Position=UDim2.fromOffset(6,2),ClearTextOnFocus=false,MultiLine=(h or 0)>45,TextWrapped=(h or 0)>45,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=if (h or 0)>45 then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,BackgroundTransparency=1,Text=initial or "",PlaceholderText=label,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(232,222,255)},r);if commit then self.page:on(t.FocusLost,function() self:action(function() commit(t.Text) end) end) end;return t
end
function UI:control(k)
 self.controlKeys=self.controlKeys or {}
 if self.controlKeys[k] then return end
 self.controlKeys[k]=true
 local d=S.defs[k];local app=self.app;local a=d.kind;if a=="players" then return end
 if a=="text" or a=="asset" then local box=self:box(d.label,tostring(app.s[k]),32,function(v) app:set(k,v) end);self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end end);return end
 local row=self:row(if a=="number" then 48 else 34,k);local label=U.label(row,d.label,12,UDim2.fromOffset(9,0),UDim2.new(.57,0,0,30));label.TextColor3=Color3.fromRGB(219,210,234)
 if a=="bool" or a=="choice" then local b=U.button(row,"");b.Name="Value";b.Position=UDim2.new(.58,0,0,3);b.Size=UDim2.new(.42,-6,1,-6);self.page:on(b.Activated,function() if a=="bool" then app:set(k,not app.s[k]) else app:set(k,d.min[(table.find(d.min,app.s[k]) or 0)%#d.min+1]) end end);self:watch(function() b.Text=if a=="bool" then (if app.s[k] then "ON" else "OFF") else tostring(app.s[k]).."  ›";b.BackgroundColor3=if a=="bool" and not app.s[k] then Color3.fromRGB(48,45,59) else Color3.fromRGB(84,61,118) end);return end
 local box=U.new("TextBox",{Name="Value",Position=UDim2.new(.6,0,0,3),Size=UDim2.new(.4,-7,0,23),BackgroundColor3=bg,ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=12,Text="",BorderSizePixel=0},row);U.corner(box,6)
 self.page:on(box.FocusLost,function() self:action(function() app:set(k,if a=="number" then math.clamp(math.round(assert(tonumber(box.Text),"Enter a number")),d.min,d.max) else (box.Text:gsub("^#",""))) end);self:sync() end)
 if a=="color" then self:watch(function() if not box:IsFocused() then box.Text="#"..app.s[k] end;label.TextColor3=U.hex(app.s[k]) end);return end
 local hit=U.new("TextButton",{Name="Slider",Position=UDim2.fromOffset(10,26),Size=UDim2.new(1,-20,0,21),BackgroundTransparency=1,Text="",AutoButtonColor=false},row);local track=U.frame(hit,"Track",UDim2.fromScale(0,.37),UDim2.new(1,0,0,5),bg);U.corner(track,4);local fill=U.frame(track,"Fill",nil,nil,U.hex(app.s.accent));U.corner(fill,4);local dot=U.frame(fill,"Thumb",UDim2.fromScale(1,.5),UDim2.fromOffset(11,11),Color3.fromRGB(237,225,255));dot.AnchorPoint=Vector2.new(.5,.5);U.corner(dot,9)
 self.page:on(hit.InputBegan,function(i) self:begin(i,function(pos) local t=math.clamp((pos.X-hit.AbsolutePosition.X)/math.max(1,hit.AbsoluteSize.X),0,1);app:set(k,math.round(d.min+t*(d.max-d.min))) end) end)
 self:watch(function() if not box:IsFocused() then box.Text=tostring(app.s[k]) end;fill.Size=UDim2.fromScale((app.s[k]-d.min)/(d.max-d.min),1);fill.BackgroundColor3=U.hex(app.s.accent) end)
end
function UI:colorPicker(k)
 self.colorKeys=self.colorKeys or {}
 if self.colorKeys[k] then return end
 self.colorKeys[k]=true
 local app=self.app
 self:control(k)
 local row=self:row(188,"SquareColorPicker")
 local field=U.new("TextButton",{Name="SaturationValue",Position=UDim2.fromOffset(9,8),Size=UDim2.fromOffset(170,170),BackgroundColor3=Color3.new(1,0,0),Text="",AutoButtonColor=false,BorderSizePixel=0},row)
 U.corner(field,8)
 local white=U.frame(field,"Saturation",nil,nil,Color3.new(1,1,1),0);white.Active=false
 U.corner(white,8);U.new("UIGradient",{Transparency=NumberSequence.new(0,1)},white)
 local black=U.frame(field,"Value",nil,nil,Color3.new(),0);black.Active=false
 U.corner(black,8);U.new("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0)},black)
 local marker=U.frame(field,"Marker",nil,UDim2.fromOffset(12,12),Color3.new(1,1,1),1);marker.AnchorPoint=Vector2.new(.5,.5);U.corner(marker,10);U.stroke(marker,Color3.new(1,1,1),0)
 local hue=U.new("TextButton",{Name="Hue",Position=UDim2.fromOffset(190,8),Size=UDim2.fromOffset(22,170),BackgroundColor3=Color3.new(1,1,1),Text="",AutoButtonColor=false,BorderSizePixel=0},row)
 U.corner(hue,8)
 local keys={}
 for i=0,6 do keys[#keys+1]=ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1)) end
 U.new("UIGradient",{Rotation=90,Color=ColorSequence.new(keys)},hue)
 local hm=U.frame(hue,"HueMarker",nil,UDim2.new(1,6,0,3),Color3.new(1,1,1));hm.AnchorPoint=Vector2.new(.5,.5);U.stroke(hm,Color3.new(),.3)
 local h,s,v=U.hex(app.s[k]):ToHSV();local last=app.s[k]
 local function commit()
  local next=Color3.fromHSV(h,s,v):ToHex():upper()
  last=next
  if app.s[k]~=next then app:set(k,next) else self:sync() end
 end
 self.page:on(field.InputBegan,function(i) self:begin(i,function(pos)
  s=math.clamp((pos.X-field.AbsolutePosition.X)/math.max(1,field.AbsoluteSize.X),0,1)
  v=1-math.clamp((pos.Y-field.AbsolutePosition.Y)/math.max(1,field.AbsoluteSize.Y),0,1);commit()
 end) end)
 self.page:on(hue.InputBegan,function(i) self:begin(i,function(pos)
  h=math.clamp((pos.Y-hue.AbsolutePosition.Y)/math.max(1,hue.AbsoluteSize.Y),0,1);commit()
 end) end)
 self:watch(function()
  if last~=app.s[k] then last=app.s[k];h,s,v=U.hex(last):ToHSV() end
  field.BackgroundColor3=Color3.fromHSV(h,1,1);marker.Position=UDim2.fromScale(s,1-v);hm.Position=UDim2.fromScale(.5,h)
 end)
end
function UI:group(g,skip) for _,k in S.order do if S.defs[k].group==g and not(skip and skip[k]) then self:control(k) end end end
return UI