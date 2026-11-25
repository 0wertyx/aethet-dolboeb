-- Shared, normalized, filled silhouettes for decorative effects.
local M={}
M.names={"Rounded Star","Soft Star","Sparkle","Long Sparkle","Six Point Star","Eight Point Star","Circle","Rounded Square","Diamond","Rounded Triangle","Rounded Hexagon","Rounded Pentagon","Heart"}
local specs={
 ["Rounded Star"]={5,.58,.46},["Soft Star"]={5,.73,.49},
 ["Sparkle"]={4,.36,.38},["Long Sparkle"]={4,.28,.32, .67},
 ["Six Point Star"]={6,.59,.42},["Eight Point Star"]={8,.66,.35},
 ["Circle"]={20,1,0},["Rounded Square"]={4,1,.48,1,math.pi/4},
 ["Diamond"]={4,1,.26},["Rounded Triangle"]={3,1,.43},
 ["Rounded Hexagon"]={6,1,.38},["Rounded Pentagon"]={5,1,.4}
}
local cache={}
function M.outline(name)
 if cache[name] then return cache[name] end
 local raw={}
 local spec=specs[name] or specs["Rounded Star"]
 if name=="Heart" then
  for i=0,19 do
   local t=i*math.pi/10
   raw[#raw+1]=Vector3.new(16*math.sin(t)^3,13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t)+2,0)/18
  end
  -- This parametric heart is clockwise; normalize the winding.
  local ordered={}
  for i=#raw,1,-1 do ordered[#ordered+1]=raw[i] end
  raw=ordered
 else
  local n,inner,round,aspect,phase=spec[1],spec[2],spec[3],spec[4] or 1,spec[5] or math.pi/2
  local star=inner<1
  local count=if star then n*2 else n
  for i=0,count-1 do
   local a=phase+i*math.pi*2/count
   local r=if star and i%2==1 then inner else 1
   raw[#raw+1]=Vector3.new(math.cos(a)*r*aspect,math.sin(a)*r,0)
  end
  if round>0 then
   local curved={}
   for i,p in raw do
    local a=p:Lerp(raw[(i-2)%#raw+1],round)
    local b=p:Lerp(raw[i%#raw+1],round)
    local samples=if #raw<=10 then {.18,.82} elseif #raw==12 and i%2==1 then {.18,.82} else {.5}
    for _,t in samples do curved[#curved+1]=a*(1-t)^2+p*(2*t*(1-t))+b*t^2 end
   end
   raw=curved
  end
 end
 local maxRadius=0
 for _,p in raw do maxRadius=math.max(maxRadius,p.Magnitude) end
 for i,p in raw do raw[i]=p/maxRadius end
 cache[name]=raw
 return raw
end
-- Cache scanline spans for filled UI shapes without needing uploaded images.
local raster={}
function M.spans(name)
 if raster[name] then return raster[name] end
 local outline=M.outline(name)
 local result={}
 local rows=24
 for row=0,rows-1 do
  local y=1-2*(row+.5)/rows
  local hits={}
  for i,a in outline do
   local b=outline[i%#outline+1]
   if (a.Y>y)~=(b.Y>y) then hits[#hits+1]=a.X+(b.X-a.X)*(y-a.Y)/(b.Y-a.Y) end
  end
  table.sort(hits)
  for j=1,#hits-1,2 do
   local left,right=hits[j],hits[j+1]
   if right-left>.001 then result[#result+1]={x=(left+1)/2,y=row/rows,w=(right-left)/2,h=1/rows} end
  end
 end
 raster[name]=result
 return result
end
return M
