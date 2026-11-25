local L=game:GetService("Lighting");local T=game:GetService("TweenService");local U=require(script.Parent.Util)
local Stars=require(script.Parent.Starfall)
local W={};W.__index=W
function W.new() return setmetatable({saved={},owned={},tweens={},stars=Stars.new()},W) end
function W:stop()
 for _,tw in self.tweens do tw:Cancel();tw:Destroy() end;table.clear(self.tweens)
end
function W:clearAtmosphere()
 self:stop();for obj,props in self.saved do if obj==L or obj.Parent then for k,v in props do obj[k]=v end end end;table.clear(self.saved)
 for _,obj in self.owned do obj:Destroy() end;table.clear(self.owned);self.atmo=nil;self.key=nil
end
function W:clear()
 self:clearAtmosphere();self.stars:clear()
 if self.fxBloom then self.fxBloom:Destroy();self.fxBloom=nil end
 self.fxBloomKey=nil
end
function W:visualBloom(s)
 local visual=0
 if s.visualBloom then
  if s.wings then visual=math.max(visual,s.sketchGlow/100) end
  if s.halo then visual=math.max(visual,s.haloGlow/100) end
  for i=1,7 do local k="haloV2"..i;if s[k.."Enabled"] then visual=math.max(visual,s[k.."Glow"]/100) end end
  if s.neon then visual=math.max(visual,s.neonLight/100) end
  if s.starfall and s.starfallMaterial=="Neon" and not s.reduce then visual=math.max(visual,s.starfallGlow/100) end
 end
 visual=visual*s.visualBloomStrength/100
 local ambient=if s.ambient then s.bloom/50 else 0
 local intensity=math.max(ambient,visual*1.8)
 local radius=if visual>0 then s.visualBloomRadius else s.worldBloomSize
 local key=tostring(intensity)..":"..tostring(radius)..":"..tostring(visual>0)
 if self.fxBloomKey==key then return end
 self.fxBloomKey=key
 if intensity<=0 then if self.fxBloom then self.fxBloom.Enabled=false end;return end
 if not self.fxBloom then self.fxBloom=U.new("BloomEffect",{Name="AetherVisualBloom"},L) end
 self.fxBloom.Enabled=true;self.fxBloom.Intensity=intensity;self.fxBloom.Size=radius
 self.fxBloom.Threshold=if visual>0 then .85 else 1.2
end
function W:apply(s)
 self.stars:step(s,os.clock())
 self:visualBloom(s)
 if not s.ambient then if self.atmo then self:clearAtmosphere() end;return end
 local key=table.concat({s.skyA,s.skyB,s.skyC,s.fog,s.bloom,s.time,s.light,s.saturation,s.blur,s.fade,s.worldContrast,s.worldExposure,s.worldGlare,s.worldRays,s.worldFocus,s.worldFocusDistance,s.worldBloomSize,tostring(s.reduce)},":");if self.key==key then return end;self.key=key;self:stop()
 local function own(class) local o=U.new(class,{Name="Aether"..class},L);table.insert(self.owned,o);return o end
 if not self.atmo then self.atmo=L:FindFirstChildOfClass("Atmosphere") or own("Atmosphere");self.grade=own("ColorCorrectionEffect");self.blur=own("BlurEffect");self.rays=own("SunRaysEffect");self.focus=own("DepthOfFieldEffect") end
 local function set(o,p)
  if not self.saved[o] then self.saved[o]={} end;for k in p do if self.saved[o][k]==nil then self.saved[o][k]=o[k] end end
  if s.reduce or s.fade==0 then for k,v in p do o[k]=v end else local tw=T:Create(o,TweenInfo.new(s.fade/1000,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),p);table.insert(self.tweens,tw);tw:Play() end
 end
 set(L,{Ambient=U.hex(s.skyA),OutdoorAmbient=U.hex(s.skyB),Brightness=s.light/40,ClockTime=s.time/10,ExposureCompensation=s.worldExposure/50});set(self.atmo,{Color=U.hex(s.skyC),Decay=U.hex(s.skyB),Density=s.fog/150,Haze=s.fog/30,Glare=s.worldGlare*.03});set(self.grade,{Saturation=s.saturation/100,Contrast=s.worldContrast/100,TintColor=Color3.new(1,1,1):Lerp(U.hex(s.skyC),.13)});set(self.blur,{Size=s.blur});set(self.rays,{Intensity=s.worldRays/100,Spread=.8});set(self.focus,{FarIntensity=s.worldFocus/100,NearIntensity=s.worldFocus*.003,FocusDistance=s.worldFocusDistance,InFocusRadius=25})
end
return W