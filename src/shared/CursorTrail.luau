-- Local GUI-only cursor trail, independent of cursor hit testing.
local U=require(script.Parent.Util)
local T={};T.__index=T
local SEGMENTS=12
local MAX_RAILS=3
local function newLine(parent,z)
 local f=U.frame(parent,"TrailSegment",nil,UDim2.fromOffset(1,1),Color3.new(1,1,1),1)
 f.AnchorPoint=Vector2.new(.5,.5);f.Active=false;f.Interactable=false;f.Visible=false;f.ZIndex=z
 U.corner(f,99)
 return f
end
local function draw(f,a,b,width,color,alpha,dot)
 local d=b-a
 f.Visible=alpha>.005 and d.Magnitude>.15
 if not f.Visible then return end
 local p=if dot then b else (a+b)*.5
 f.Position=UDim2.fromOffset(p.X,p.Y)
 f.Size=UDim2.fromOffset(if dot then width else d.Magnitude+width*.35,width)
 f.Rotation=if dot then 0 else math.deg(math.atan2(d.Y,d.X))
 f.BackgroundColor3=color;f.BackgroundTransparency=1-math.clamp(alpha,0,1)
end
function T.new(parent)
 local folder=U.frame(parent,"CursorTrailLayer",nil,nil,nil,1)
 folder.Active=false;folder.Interactable=false;folder.ZIndex=8
 return setmetatable({root=folder,pool={},history={},points={},visible=false},T)
end
function T:hide()
 if self.visible then
  self.root.Visible=false;table.clear(self.history);self.visible=false
 end
end
function T:destroy()
 self:hide();self.root:Destroy()
end
function T:step(hit,s,now)
 local h=self.history;local last=h[#h]
 if not self.visible then self.root.Visible=true;self.visible=true end
 if last and (now-last.t>.2 or (hit-last.p).Magnitude>300) then table.clear(h);last=nil end
 -- Time-based history: frame rate changes do not stretch or shorten the trail.
 h[#h+1]={p=hit,t=now}
 local life=s.cursorTrailLength/1000
 while #h>2 and (h[2].t<now-life or #h>256) do table.remove(h,1) end
 local index=#h
 local pts=self.points;pts[1]=hit
 for j=1,SEGMENTS do
  local target=now-life*j/SEGMENTS
  while index>1 and h[index-1].t>target do index-=1 end
  local hi=h[index];local lo=h[math.max(1,index-1)]
  local t=if hi.t>lo.t then math.clamp((target-lo.t)/(hi.t-lo.t),0,1) else 0
  pts[j+1]=lo.p:Lerp(hi.p,t)
 end
 local rails=if s.cursorTrailStyle=="Triple" then MAX_RAILS else 1
 local dot=s.cursorTrailStyle=="Dots"
 local width=s.cursorTrailWidth/10;local spread=s.cursorTrailSpread
 local glow=s.cursorTrailGlow/100
 local ca,cb=U.hex(s.cursorTrailA),U.hex(s.cursorTrailB)
 local normal=Vector2.new(0,1)
 local direction=pts[1]-pts[2]
 if direction.Magnitude>.1 then normal=Vector2.new(-direction.Y,direction.X).Unit
 elseif self.normal then normal=self.normal end
 self.normal=normal
 local used=0
 for rail=1,rails do
  local offset=if rails==3 then (rail-2)*spread else 0
  for j=1,SEGMENTS do
   used+=1
   local item=self.pool[used]
   if not item then item={halo=newLine(self.root,8),core=newLine(self.root,9)};self.pool[used]=item end
   local u=(j-1)/SEGMENTS;local v=j/SEGMENTS
   local a=pts[j]+normal*offset*(1-u*.65)
   local b=pts[j+1]+normal*offset*(1-v*.65)
   local c=ca:Lerp(cb,u);local alpha=(1-u)^1.65
   if (pts[j]-pts[j+1]).Magnitude<.12 then alpha=0 end
   draw(item.core,a,b,width*(1-u*.45)*(if dot then 2.2 else 1),c,alpha*.9,dot)
   draw(item.halo,a,b,width+glow*7,c,alpha*glow*.23,dot)
  end
 end
 for i=used+1,#self.pool do self.pool[i].core.Visible=false;self.pool[i].halo.Visible=false end
end
return T
