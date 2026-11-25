-- Native vector masks. Scan-convert once per silhouette/softness, merge identical runs vertically.
-- No image uploads, EditableImage permissions, or external texture dependencies for built-ins.
local AssetService=game:GetService("AssetService")
local U=require(script.Parent.Util)
local Icons=require(script.Parent.Icons)
local M={};local masks={};local N=96
local paths={
 ["Soft Triangle"]="16,1 30,29 16,22 2,29",Chevron="4,8 6,7 16,15 26,7 28,8 28,14 16,26 4,14",Diamond="16,2 18,4 30,16 18,29 16,30 14,29 2,16",
 ["Neon Pointer"]="16,1 27,30 16,21 5,30|16,8 19,19 13,19",["Double Chevron"]="3,16 16,3 29,16 25,20 16,11 7,20|3,26 16,13 29,26 25,30 16,21 7,30",
 ["Angel Wings"]="1,4 12,10 16,21 20,10 31,4 28,16 23,18 25,20 19,25 16,31 13,25 7,20 9,18 4,16",
 Arrowhead="16,2 30,29 16,22 2,29",["Split Arrow"]="16,2 30,27 18,20 16,30 14,20 2,27",Needle="16,1 22,30 16,23 10,30",["Broad Chevron"]="2,24 16,7 30,24 25,29 16,18 7,29",
 ["Hollow Diamond"]="16,1 31,16 16,31 1,16|16,8 8,16 16,24 24,16",Crystal="16,1 29,14 22,30 10,30 3,14",Spear="16,1 28,29 16,21 4,29|16,8 17,19 15,19",
 ["Twin Wings"]="1,8 13,14 16,28 19,14 31,8 24,26 16,31 8,26",Shield="16,2 29,8 26,23 16,31 6,23 3,8",Beacon="16,1 26,10 26,25 16,31 6,25 6,10",
 ["Star Pointer"]="16,1 21,12 31,16 21,20 16,31 11,20 1,16 11,12",Compass="16,1 20,12 31,16 20,20 16,31 12,20 1,16 12,12|16,12 20,16 16,20 12,16",
 ["Double Spike"]="16,1 28,18 16,14 4,18|16,19 25,31 16,27 7,31",["Arc Pointer"]="2,21 5,15 10,9 16,6 22,9 27,15 30,21 24,26 20,19 16,15 12,19 8,26",Kite="16,1 29,14 16,31 3,14",Crosshair="14,1 18,1 18,12 21,15 31,15 31,18 20,18 18,22 18,31 14,31 14,22 12,18 1,18 1,15 12,15 14,12",
 ["Rounded Triangle"]="8,3 6,5 6,29 8,30 15,22 24,22 26,20",["Soft Arrow"]="6,4 8,4 27,17 28,19 26,21 18,22 13,30 11,28",Spark="16,2 19,12 29,16 29,18 19,21 16,30 13,21 3,18 3,16 13,12",
 Heart="16,29 4,18 1,12 2,7 5,4 10,3 14,5 16,8 19,4 23,3 28,5 31,9 30,15 26,21",
 Studio="16,1 20,12 31,16 20,20 16,31 12,20 1,16 12,12",
}
local function smooth(poly,r)
 if r==0 then return poly end;local out={};for i,p in poly do local a=poly[(i-2)%#poly+1]-p;local b=poly[i%#poly+1]-p
  local s=p+a.Unit*math.min(r,a.Magnitude*.43);local e=p+b.Unit*math.min(r,b.Magnitude*.43)
  for j=0,3 do local t=j/3;table.insert(out,s*(1-t)^2+p*2*t*(1-t)+e*t^2) end
 end;return out
end
local function build(name,round)
 if name=="Heart" then
  -- Native frame fallback uses the same outline, not the old solid silhouette.
  local segments={}
  for _,path in Icons.drawing("Health") do
   for j=1,#path-2,2 do
    local a=Vector2.new(path[j],path[j+1]);local d=Vector2.new(path[j+2],path[j+3])-a
    if d.Magnitude>0 then table.insert(segments,{a=a,d=d,len=d:Dot(d)}) end
   end
  end
  local rows={}
  for y=0,N-1 do
   local start=nil
   for x=0,N do
    local hit=false
    if x<N then
     local p=Vector2.new((x+.5)*24/N,(y+.5)*24/N)
     for _,seg in segments do
      local v=p-seg.a;local q=math.clamp(v:Dot(seg.d)/seg.len,0,1)
      if (v-seg.d*q).Magnitude<=.75 then hit=true;break end
     end
    end
    if hit and not start then start=x elseif not hit and start then table.insert(rows,{x=start,y=y,w=x-start,h=1});start=nil end
   end
  end
  return rows
 end
 local polys={};for sub in string.gmatch(paths[name] or paths.Diamond,"[^|]+") do local a={};for x,y in sub:gmatch("(%d+),(%d+)") do table.insert(a,Vector2.new(tonumber(x),tonumber(y))) end;table.insert(polys,smooth(a,round*.055)) end
 local rows={};local last={}
 for y=0,N-1 do local yy=(y+.5)*32/N;local inter={};for _,p in polys do for i,a in p do local b=p[i%#p+1];if (a.Y>yy)~=(b.Y>yy) then table.insert(inter,a.X+(yy-a.Y)*(b.X-a.X)/(b.Y-a.Y)) end end end;table.sort(inter)
  local function pixel(x) local xx=(x+.5)*32/N
   if name=="Location Pin" then return ((xx-16)^2+(yy-20)^2<112 or (yy>=2 and yy<21 and math.abs(xx-16)<(yy-1)*.56)) and (xx-16)^2+(yy-20)^2>15 end
   if name=="Orbit Arc" or name=="Orbit" then local d=(xx-16)^2+(yy-17)^2;return (d<186 and d>93 and (yy>=13 or xx<13)) or (yy<13 and math.abs(xx-18)<yy*.55) end
   for i=1,#inter-1,2 do if xx>=inter[i] and xx<inter[i+1] then return true end end;return false end
  local x=0;local nextRow={};while x<N do if not pixel(x) then x+=1;continue end;local l=x;repeat x+=1 until x==N or not pixel(x);local id=l*(N+1)+x;local b=last[id];if b then b.h+=1 else b={x=l,y=y,w=x-l,h=1};table.insert(rows,b) end;nextRow[id]=b end;last=nextRow
 end;return rows
end
-- Share the exact outline / ECG geometry with the Health navigation icon.
local function heartImage(parent)
 local edit=Icons.texture("Health")
 if not edit then return nil,nil,nil end
 local ok,label,gradient,halo=pcall(function()
  local image=U.new("ImageLabel",{Name="HeartHD128",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
   Active=false,Selectable=false,Interactable=false,ScaleType=Enum.ScaleType.Fit,
   ImageContent=Content.fromObject(edit),ResampleMode=Enum.ResamplerMode.Default,ZIndex=parent.ZIndex+2},parent)
  local grad=U.new("UIGradient",{Rotation=90},image)
  local glow=Icons.texture("Health",true)
  local aura=nil
  if glow then
   aura=U.new("ImageLabel",{Name="HeartNeon",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,
    Selectable=false,Interactable=false,ScaleType=Enum.ScaleType.Fit,ImageContent=Content.fromObject(glow),
    ImageTransparency=.5,ZIndex=parent.ZIndex+1},parent)
  end
  return image,grad,aura
 end)
 if not ok then return nil,nil,nil end
 return label,gradient,halo
end
local function galleryRaster(name,round)
 local n,ss=128,4
 local resolution=n*ss
 local polys={}
 for sub in string.gmatch(paths[name] or paths.Diamond,"[^|]+") do
  local points={}
  for x,y in sub:gmatch("(%d+),(%d+)") do table.insert(points,Vector2.new(tonumber(x),tonumber(y))) end
  table.insert(polys,smooth(points,round*.055))
 end
 local alpha=buffer.create(n*n)
 local function add(x,y)
  local at=math.floor(y/ss)*n+math.floor(x/ss)
  buffer.writeu8(alpha,at,buffer.readu8(alpha,at)+1)
 end
 for y=0,resolution-1 do
  local yy=(y+.5)*32/resolution
  if name=="Location Pin" or name=="Orbit Arc" then
   for x=0,resolution-1 do
    local xx=(x+.5)*32/resolution
    local d=(xx-16)^2+(yy-17)^2
    local inside
    if name=="Location Pin" then
     local p=(xx-16)^2+(yy-20)^2
     inside=(p<112 or (yy>=2 and yy<21 and math.abs(xx-16)<(yy-1)*.56)) and p>15
    else inside=(d<186 and d>93 and (yy>=13 or xx<13)) or (yy<13 and math.abs(xx-18)<yy*.55) end
    if inside then add(x,y) end
   end
  else
   local intersections={}
   for _,poly in polys do
    for i,a in poly do
     local b=poly[i%#poly+1]
     if (a.Y>yy)~=(b.Y>yy) then table.insert(intersections,a.X+(yy-a.Y)*(b.X-a.X)/(b.Y-a.Y)) end
    end
   end
   table.sort(intersections)
   for i=1,#intersections-1,2 do
    local first=math.clamp(math.ceil(intersections[i]*resolution/32-.5),0,resolution)
    local last=math.clamp(math.ceil(intersections[i+1]*resolution/32-.5)-1,-1,resolution-1)
    for x=first,last do add(x,y) end
   end
  end
 end
 local core=buffer.create(n*n*4)
 local glow=buffer.create(n*n*4)
 -- Separate alpha blur follows the silhouette, not a circular backdrop.
 local weights={1,4,7,10,12,10,7,4,1}
 local temp=buffer.create(n*n*4)
 for y=0,n-1 do
  for x=0,n-1 do
   local at=y*n+x
   buffer.writeu32(core,at*4,0x00FFFFFF)
   buffer.writeu8(core,at*4+3,math.round(buffer.readu8(alpha,at)*255/(ss*ss)))
   local sum=0
   for i,w in weights do local xx=x+i-5;if xx>=0 and xx<n then sum+=buffer.readu8(alpha,y*n+xx)*w end end
   buffer.writef32(temp,at*4,sum/56)
  end
 end
 for y=0,n-1 do
  for x=0,n-1 do
   local sum=0
   for i,w in weights do local yy=y+i-5;if yy>=0 and yy<n then sum+=buffer.readf32(temp,(yy*n+x)*4)*w end end
   local at=(y*n+x)*4
   buffer.writeu32(glow,at,0x00FFFFFF)
   buffer.writeu8(glow,at+3,math.clamp(math.round(sum*255/(56*ss*ss)),0,255))
  end
 end
 return core,glow,n
end
function M.gallery(parent,name,round)
 local edits={}
 local root
 local ok,result=pcall(function()
  local core,glow,n=galleryRaster(name,round or 30)
  root=U.new("Frame",{Name="HDGalleryGlyph",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),Active=false,Interactable=false},parent)
  local function image(data,label,z)
   local edit=AssetService:CreateEditableImage({Size=Vector2.new(n,n)})
   assert(edit,"EditableImage unavailable")
   table.insert(edits,edit)
   edit:WritePixelsBuffer(Vector2.zero,Vector2.new(n,n),data)
   return U.new("ImageLabel",{Name=label,Size=UDim2.fromScale(.90,.90),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Active=false,Interactable=false,Selectable=false,ScaleType=Enum.ScaleType.Fit,ImageContent=Content.fromObject(edit),ResampleMode=Enum.ResamplerMode.Default,ZIndex=z},root)
  end
  local aura=image(glow,"ContourGlow128",parent.ZIndex+1)
  local ink=image(core,"Silhouette128",parent.ZIndex+2)
  local gradient=U.new("UIGradient",{Rotation=90},ink)
  local self={root=root}
  function self:paint(a,b,intensity,spread)
   gradient.Color=ColorSequence.new(a,b)
   aura.ImageColor3=a:Lerp(b,.5)
   aura.ImageTransparency=1-math.clamp(intensity/100*.75,0,1)
   aura.Size=UDim2.fromScale(.90+spread*.004,.90+spread*.004)
  end
  root.Destroying:Once(function() for _,edit in edits do edit:Destroy() end end)
  return self
 end)
 if ok then return result end
 if root then root:Destroy() end
 for _,edit in edits do pcall(function() edit:Destroy() end) end
 return M.new(parent,name,round)
end
function M.new(parent,name,round)
 local root=U.new("Frame",{Name="Glyph",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),Active=false,Interactable=false},parent)
 local outer=U.frame(root,"OuterGlow",nil,nil,nil,.89);U.corner(outer,999);local inner=U.frame(root,"InnerGlow",nil,nil,nil,.80);U.corner(inner,999)
 local ink=U.frame(root,"Ink",nil,nil,nil,1);for _,f in {outer,inner,ink} do f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5) end
 local self={root=root,ink=ink,parts={},key="",alpha=0}
 function self:opacity(value)
  local alpha=math.clamp(value,0,1)
  if self.alpha==alpha then return end
  self.alpha=alpha
  for _,part in self.parts do part.BackgroundTransparency=alpha end
  if self.hd then self.hd.ImageTransparency=alpha end
  local glow=self.glow or 0
  outer.BackgroundTransparency=1-(1-alpha)*glow*.0016
  inner.BackgroundTransparency=1-(1-alpha)*glow*.0024
  if self.hdGlow then self.hdGlow.ImageTransparency=1-(1-alpha)*glow*.008 end
 end
 if name=="Heart" then self.hd,self.hdGradient,self.hdGlow=heartImage(ink) end
 function self:shape(n,r)
  r=math.round(r/10)*10;local key=n..r;if self.key==key then return end;self.key=key
  if self.hd then
   self.hd.Visible=n=="Heart"
   if self.hdGlow then self.hdGlow.Visible=n=="Heart" end
   if n=="Heart" then for _,part in self.parts do part.Visible=false end;self.mask={};self.a=nil;return end
  end
  local mask=masks[key];if not mask then mask=build(n,r);masks[key]=mask end
  for i,rect in mask do local part=self.parts[i] or U.frame(ink,"Run",nil,nil,Color3.new(1,1,1));self.parts[i]=part;part.Position=UDim2.fromScale(rect.x/N,rect.y/N);part.Size=UDim2.fromScale(rect.w/N,rect.h/N);part.BackgroundTransparency=self.alpha;part.Visible=true end
  for i=#mask+1,#self.parts do self.parts[i].Visible=false end;self.mask=mask;self.a=nil
 end
 function self:paint(a,b,glow,spread,middle,angle)
  angle=angle or 90
  if self.a~=a or self.b~=b or self.mid~=middle or self.angle~=angle then
   if self.hdGradient and self.hd.Visible then
    if self.a~=a or self.b~=b or self.mid~=middle then
     self.hdGradient.Color=if middle then ColorSequence.new({ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(.5,middle),ColorSequenceKeypoint.new(1,b)}) else ColorSequence.new(a,b)
    end
    if self.angle~=angle then self.hdGradient.Rotation=angle end
   end
   local rad=math.rad(angle);local dx,dy=math.cos(rad),math.sin(rad)
   local span=math.abs(dx)+math.abs(dy)
   for i,rect in self.mask do
    local x=(rect.x+rect.w*.5)/N-.5;local y=(rect.y+rect.h*.5)/N-.5
    local q=math.clamp(.5+(x*dx+y*dy)/math.max(.001,span),0,1)
    self.parts[i].BackgroundColor3=if middle then (if q<.5 then a:Lerp(middle,q*2) else middle:Lerp(b,q*2-1)) else a:Lerp(b,q)
   end
   if self.hdGlow then self.hdGlow.ImageColor3=middle or a:Lerp(b,.5) end
   outer.BackgroundColor3=b;inner.BackgroundColor3=a;self.a=a;self.b=b;self.mid=middle;self.angle=angle
  end
  if self.glow~=glow or self.spread~=spread then outer.BackgroundTransparency=1-(1-self.alpha)*glow*.0016;inner.BackgroundTransparency=1-(1-self.alpha)*glow*.0024;outer.Visible=glow>0 and not (self.hd and self.hd.Visible);inner.Visible=outer.Visible;if self.hdGlow then self.hdGlow.ImageTransparency=1-(1-self.alpha)*glow*.008 end;local k=.69+spread*.016;outer.Size=UDim2.fromScale(k,k);inner.Size=UDim2.fromScale(k*.77,k*.77);ink.Size=if self.hd and self.hd.Visible then UDim2.fromScale(.94,.94) else UDim2.fromScale(.73,.73);self.glow=glow;self.spread=spread end
 end
 self:shape(name,round or 30);self:paint(Color3.fromRGB(185,150,255),Color3.fromRGB(255,165,220),50,8);return self
end
return M