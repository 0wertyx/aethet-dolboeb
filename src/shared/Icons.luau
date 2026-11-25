-- The ORIGINAL AETHER desktop icons are 32 PNG images of 224 x 224.
-- Upload the original 8x4 atlas to Roblox. Supports 128px or legacy 224px tiles.
-- The atlas is included separately for importing; Roblox cannot draw GitHub PNG URLs directly.
local AssetService=game:GetService("AssetService")
local U=require(script.Parent.Util)
local I={}
I.TILE=128
I.columns=8
I.order={
 "Home","Dashboard","HUD","Fonts","Themes","World_FX","Indicators","Simulator",
 "Workshop","Downloads","Plugins","Extensions","AI_Assistant","Music","Media","Games",
 "Console","Logs","Settings","Profile","Health","Performance","Update","About",
 "Tests","Debug","Bridge","Launch","Files","Assets","Cloud","Favorites"
}
I.tabs={
 Dashboard="Dashboard",HUD="HUD",Character="Profile",Wings="Favorites",
 Halos="AI_Assistant",Neon="Themes",Ambient="World_FX",Indicators="Indicators",
 Cursor="Assets",Camera="Media",Interaction="Games",List="Update",Fonts="Fonts",Simulator="Simulator",
 Scripts="Console",Profiles="Cloud",Diagnostics="Debug"
}
-- Procedural silhouettes supply HD textures and offline line-art fallback.
-- Coordinates are normalized to a 24 by 24 icon, independent of display size.
local drawings={
 Dashboard={{3,3,10,3,10,10,3,10,3,3},{14,3,21,3,21,10,14,10,14,3},{3,14,10,14,10,21,3,21,3,14},{14,14,21,14,21,21,14,21,14,14}},
 HUD={{2,4,22,4,22,20,2,20,2,4},{5,7,11,7,11,11,5,11,5,7},{5,16,19,16},{15,8,19,8}},
 Profile={{12,3,16,5,17,9,14,12,10,12,7,9,8,5,12,3},{4,21,4,18,8,15,16,15,20,18,20,21}},
 Favorites={{12,2,15,9,22,9,17,14,19,21,12,17,5,21,7,14,2,9,9,9,12,2}},
 AI_Assistant={{12,2,15,9,22,12,15,15,12,22,9,15,2,12,9,9,12,2},{19,2,19,6},{17,4,21,4}},
 Themes={{12,2,21,7,21,16,12,22,3,16,3,7,12,2},{12,6,15,12,12,18,9,12,12,6}},
 World_FX={{3,19,9,10,13,15,17,8,22,19,3,19},{6,4,9,4},{7.5,2.5,7.5,5.5}},
 Indicators={{12,2,22,21,12,16,2,21,12,2}},
 Assets={{4,2,18,2,21,5,21,22,4,22,4,2},{8,7,17,7},{8,12,17,12},{8,17,14,17}},
 Media={{3,6,15,6,15,18,3,18,3,6},{15,10,21,6,21,18,15,14}},
 Fonts={{3,21,10,3,13,3,21,21},{6,14,18,14}},
 Simulator={{12,2,22,7,22,17,12,22,2,17,2,7,12,2},{2,7,12,12,22,7},{12,12,12,22}},
 Console={{2,4,22,4,22,20,2,20,2,4},{5,8,9,12,5,16},{12,16,18,16}},
 Workshop={{3,5,21,5,21,21,3,21,3,5},{8,5,8,2,16,2,16,5},{3,11,21,11},{10,10,14,10,14,13,10,13,10,10}},
 Cloud={{4,18,2,15,4,10,8,10,9,5,14,3,18,6,19,10,22,12,22,16,19,18,4,18}},
 Debug={{7,7,17,7,19,10,19,17,15,21,9,21,5,17,5,10,7,7},{8,7,6,3},{16,7,18,3},{2,11,5,11},{19,11,22,11},{2,16,5,16},{19,16,22,16},{12,8,12,20}},
}
-- Clean vector traces of the user's 24 November sketch, on a common 24-unit grid.
-- Cubic curves are sampled into the same distance-field renderer as straight strokes.
local function curve(path,x1,y1,x2,y2,x3,y3,steps)
 local x0,y0=path[#path-1],path[#path]
 for j=1,steps or 8 do
  local t=j/(steps or 8);local a=1-t
  table.insert(path,a^3*x0+3*a*a*t*x1+3*a*t*t*x2+t^3*x3)
  table.insert(path,a^3*y0+3*a*a*t*y1+3*a*t*t*y2+t^3*y3)
 end
 return path
end
local function roundedRect(x,y,w,h,r)
 local p={x+r,y,x+w-r,y}
 curve(p,x+w,y,x+w,y,x+w,y+r,4)
 table.insert(p,x+w);table.insert(p,y+h-r)
 curve(p,x+w,y+h,x+w,y+h,x+w-r,y+h,4)
 table.insert(p,x+r);table.insert(p,y+h)
 curve(p,x,y+h,x,y+h,x,y+h-r,4)
 table.insert(p,x);table.insert(p,y+r)
 return curve(p,x,y,x,y,x+r,y,4)
end
local heart={12,21}
curve(heart,9,18,2.4,13.3,2.4,8.5,12)
curve(heart,2.4,1.5,8.6,1.3,12,5.5,12)
curve(heart,15.4,1.3,21.6,1.5,21.6,8.5,12)
curve(heart,21.6,13.3,15,18,12,21,12)
drawings.Health={heart,{5.3,11.8,9.1,11.8,10.7,8.5,12.5,14.7,14.2,11.2,18.0,11.2}}
drawings.Dashboard={roundedRect(3,3,7,7,1.5),roundedRect(14,3,7,7,1.5),roundedRect(3,14,7,7,1.5),roundedRect(14,14,7,7,1.5)}
drawings.Home=drawings.Dashboard
drawings.HUD={{2,8,12,2.6,22,8,12,13.5,2,8},{2,14.2,6.9,11.6},{17.1,11.6,22,14.2,12,20,2,14.2}}
local function sparkle(x,y,r)
 local p={x,y-r}
 curve(p,x+r*.23,y-r*.25,x+r*.25,y-r*.23,x+r,y,5)
 curve(p,x+r*.25,y+r*.23,x+r*.23,y+r*.25,x,y+r,5)
 curve(p,x-r*.23,y+r*.25,x-r*.25,y+r*.23,x-r,y,5)
 return curve(p,x-r*.25,y-r*.23,x-r*.23,y-r*.25,x,y-r,5)
end
local moon={21,16}
curve(moon,17,16,17,12.8,19.5,11,8)
curve(moon,14.2,11.8,14.4,20.5,21,20.5,10)
curve(moon,22,20.5,23,18.5,21,16,5)
drawings.World_FX={sparkle(9,13,7),sparkle(18.5,5,3.2),moon}
local arrow={4,7}
curve(arrow,8,5.5,16,2.1,19.1,2.7,8)
curve(arrow,22.8,2.8,22.4,5.6,21.5,8,8)
curve(arrow,20,11.9,17.5,17.8,16,20.5,8)
curve(arrow,14.7,23,12.6,21.6,12,19,8)
curve(arrow,10.9,14.4,9.3,12.5,5.1,11.4,8)
curve(arrow,1.2,10.4,1.6,8.2,4,7,8)
drawings.Indicators={arrow}
drawings.Fonts={{2,21,4.5,13,8.5,14,7,21,2,21},{1.5,6,6,5,6.7,8,2.2,9,1.5,6},{8.5,4,10,3,11,5,10,6.5,8.5,6.5,8.5,4},{8,11.5,10.5,7.5,12,8.4,11,12.5,8,11.5},{12,13.5,17,17.5,13.5,22,9.5,17.5,12,13.5},{15.5,2.5,22,2.5,22,12,15.5,12,15.5,2.5},{17,9,19,5,21,9},{17.8,7.6,20.2,7.6}}
drawings.Console={roundedRect(2.5,3,19,18,1),{3,7,21,7},{10,7,10,20},{4.5,5,7,5},{4.5,9.5,8,9.5},{4.5,12.2,8,12.2},{4.5,15,8,15},{4.5,17.8,8,17.8},{12,10,19,10},{16,13,19,13},{12,16,19,16},{14,18.8,19,18.8}}
drawings.Downloads={{12,2,12,15},{7,10,12,15,17,10},{3,16,3,20,4.5,21.5,19.5,21.5,21,20,21,16}}
drawings.Plugins={{2,10,8,10,8,7,13,7,13,17,8,17,8,14,2,14,2,10},{13,10,17,10},{13,14,17,14},roundedRect(18,7,4,10,1),{19.5,10,20.5,10},{19.5,13,20.5,13}}
local puzzle={3,4,8,4,8,2.8}
curve(puzzle,8,0.8,12,0.8,12,2.8,8)
for _,v in {12,4,20,4,20,9,21.2,9} do table.insert(puzzle,v) end
curve(puzzle,23.8,9,23.8,13,21.2,13,8)
for _,v in {20,13,20,21,14,21,14,19.7} do table.insert(puzzle,v) end
curve(puzzle,14,17,10,17,10,19.7,8)
for _,v in {10,21,3,21,3,15,4.4,15} do table.insert(puzzle,v) end
curve(puzzle,7,15,7,11,4.4,11,8)
for _,v in {3,11,3,4} do table.insert(puzzle,v) end
drawings.Extensions={puzzle}
drawings.Workshop=drawings.Extensions
-- The two unlabeled figure sketches are interpreted as Character and Simulator.
drawings.Profile={{11,2,14,2,15,5,13,7,10,6,9,4,11,2},{10,8,6.5,10,5,15,8,16,10,12},{13,8,17,10,19,7,21,9,17,14,14,12},{10,8,14,8,15.5,15,9,15,10,8},{9,16,7,22,3.5,21,6,16},{12,16,16,22,20,21,16,16}}
drawings.Simulator={{10.5,2,13.5,2,15,4.5,13,6.5,10,5.5,10.5,2},{9,8,14,8,15,14,8,14,9,8},{8.5,8,4,10,3,5,1.5,6,2.5,13,7,12},{14.5,8,17.5,10,20.5,3,22.5,4,19.5,13,16,12},{9,15,7,22,4,22,6,15},{13,15,16,22,19,22,16,15}}
function I.drawing(name) return drawings[name] or drawings.Assets end
-- Rasterize each silhouette once at 128 x 128 with smooth round caps.
-- The texture is shared by the main menu, HUD and simulator preview.
I.RES=128
drawings.Games={{4,9,8,5,16,5,20,9,22,17,19,20,15,16,9,16,5,20,2,17,4,9},{5,11,11,11},{8,8,8,14},{15,10,17,10},{18,13,20,13}}
drawings.Update={{4,5,20,5,20,21,4,21,4,5},{7,9,17,9},{7,13,17,13},{7,17,14,17},{8,2,8,5},{16,2,16,5}}
local textures={}
local function raster(name,glow)
 local key=name..(if glow then ":glow" else "")
 local cached=textures[key]
 if cached~=nil then return cached or nil end
 local edit
 local ok,err=pcall(function()
  edit=AssetService:CreateEditableImage({Size=Vector2.new(I.RES,I.RES)})
  assert(edit,"EditableImage unavailable")
  local segments={}
  for _,path in drawings[name] or drawings.Assets do
   for j=1,#path-2,2 do
    local a=Vector2.new(path[j],path[j+1])
    local d=Vector2.new(path[j+2],path[j+3])-a
    if d.Magnitude>0 then table.insert(segments,{a=a,d=d,length=d:Dot(d)}) end
   end
  end
  local n=I.RES
  local data=buffer.create(n*n*4)
  -- Analytic signed distance coverage: subpixel antialiasing with rounded joins.
  local radius=if name=="Health" then .72 else .76
  local pixel=24/n
  for y=0,n-1 do
   for x=0,n-1 do
    local p=Vector2.new((x+.5)*pixel,(y+.5)*pixel)
    local dist2=math.huge
    for _,seg in segments do
     local v=p-seg.a
     local q=math.clamp(v:Dot(seg.d)/seg.length,0,1)
     local delta=v-seg.d*q
     dist2=math.min(dist2,delta:Dot(delta))
    end
    local dist=math.sqrt(dist2)
    local coverage=if glow then math.exp(-((math.max(0,dist-radius)/1.05)^2))*.75 else math.clamp((radius-dist)/pixel+.5,0,1)
    local offset=(y*n+x)*4
    buffer.writeu32(data,offset,0x00FFFFFF)
    buffer.writeu8(data,offset+3,math.round(coverage*255))
   end
  end
  edit:WritePixelsBuffer(Vector2.zero,Vector2.new(n,n),data)
 end)
 if not ok then
  if edit then edit:Destroy() end
  textures[key]=false
  return nil
 end
 textures[key]=edit
 return edit
end
function I.texture(name,glow) return raster(name,glow) end
function I.clear()
 for _,edit in textures do if edit then edit:Destroy() end end
 table.clear(textures)
end
local function lineArt(button,name,iconOnly)
 local root=U.frame(button,"NativeIcon",nil,UDim2.fromOffset(20,20),nil,1)
 root.Active=false;root.Interactable=false;root.ZIndex=button.ZIndex+1
 root.Position=if iconOnly then UDim2.new(.5,-10,.5,-10) else UDim2.new(0,7,.5,-10)
 local color=Color3.fromRGB(231,216,255)
 for _,path in drawings[name] or drawings.Assets do
  for j=1,#path-2,2 do
   local x,y=path[j],path[j+1];local dx,dy=path[j+2]-x,path[j+3]-y
   local edge=U.frame(root,"Stroke",UDim2.fromScale((x+dx*.5)/24,(y+dy*.5)/24),UDim2.new(math.sqrt(dx*dx+dy*dy)/24,0,0,1.6),color,0)
   edge.AnchorPoint=Vector2.new(.5,.5);edge.Rotation=math.deg(math.atan2(dy,dx));edge.Active=false;edge.Interactable=false;edge.ZIndex=root.ZIndex
   U.corner(edge,2)
  end
 end
 return root
end
local lookup={}
for index,name in I.order do lookup[name]=index-1 end
function I.new(button,tab)
 local visual=U.new("ImageLabel",{
  Name="AetherDesktopIcon",BackgroundTransparency=1,Active=false,Selectable=false,
  Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(5,4),
  ScaleType=Enum.ScaleType.Crop,Visible=false,ZIndex=button.ZIndex+1
 },button)
 local iconOnly=button:GetAttribute("AETHERIconOnly")==true
 if iconOnly then visual.Position=UDim2.new(.5,-12,.5,-12) end
 local name=I.tabs[tab] or tab
 local index=lookup[name]
 if index then visual.ImageRectOffset=Vector2.new(index%8*I.TILE,math.floor(index/8)*I.TILE) end
 visual.ImageRectSize=Vector2.new(I.TILE,I.TILE)
 local native=lineArt(button,name,iconOnly)
 local hd,halo
 local texture=raster(name)
 if texture then
  local ok,result=pcall(function()
   return U.new("ImageLabel",{Name="HDIcon128",BackgroundTransparency=1,Active=false,Selectable=false,Interactable=false,
    Size=UDim2.fromOffset(23,23),Position=if iconOnly then UDim2.new(.5,-11.5,.5,-11.5) else UDim2.new(0,6,.5,-11.5),
    ScaleType=Enum.ScaleType.Fit,ResampleMode=Enum.ResamplerMode.Default,
    ImageColor3=Color3.fromRGB(237,222,255),ImageContent=Content.fromObject(texture),ZIndex=button.ZIndex+2},button)
  end)
  if ok then
   hd=result
   halo=hd:Clone();halo.Name="IconGlow";halo.ZIndex=hd.ZIndex-1;halo.ImageTransparency=.76
   local glowTexture=raster(name,true)
   if glowTexture then halo.ImageContent=Content.fromObject(glowTexture);halo.Parent=button else halo:Destroy();halo=nil end
   U.new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(220,187,255),Color3.fromRGB(255,209,245)),Rotation=45},hd)
  end
 end
 local self={visual=visual,button=button,native=native,hd=hd,last=nil}
 local function refresh()
  local ready=self.last~=nil and self.last~="" and index~=nil and visual.IsLoaded
  visual.Visible=ready
  if hd then hd.Visible=not ready end
  if halo then halo.Visible=not ready end
  native.Visible=not ready and hd==nil
  if iconOnly then
   button.Text=""
  else
   button.TextXAlignment=Enum.TextXAlignment.Right
   button.TextSize=11
   local pad=button:FindFirstChild("IconTextPadding")
   if pad then pad:Destroy() end
  end
  button.TextColor3=Color3.fromRGB(241,234,255)
  button.TextTransparency=0
 end
 visual:GetPropertyChangedSignal("IsLoaded"):Connect(refresh)
 function self:sync(asset,tile)
  tile=if tonumber(tile)==224 then 224 else 128
  if self.tile~=tile then
   self.tile=tile
   visual.ImageRectSize=Vector2.new(tile,tile)
   if index then visual.ImageRectOffset=Vector2.new(index%8*tile,math.floor(index/8)*tile) end
  end
  asset=tostring(asset or ""):match("^%d+$") or ""
  if asset~=self.last then
   self.last=asset
   visual.Image=if asset~="" and index~=nil then "rbxassetid://"..asset else ""
  end
  refresh()
 end
 self:sync("")
 return self
end
return I
