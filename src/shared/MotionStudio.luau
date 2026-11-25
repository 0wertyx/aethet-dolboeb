-- AETHER Motion Studio V12.2: native avatar ViewportFrame editor, staged selection.
-- No game-character changes, browser, network, or external asset dependencies.
local U=require(script.Parent.Util)
local Schema=require(script.Parent.Schema)
local Http=game:GetService("HttpService")
local Packs=require(script.Parent.MotionPacks)
local Props=require(script.Parent.PreviewProps)
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local M={}
local function J(a,b,c,x,y,z) return {a or 0,b or 0,c or 0,x or 0,y or 0,z or 0} end
local function P(root,ra,la,rl,ll,head) return {Root=root,RightShoulder=ra,LeftShoulder=la,RightHip=rl,LeftHip=ll,Neck=head or J()} end
local function mirrorJoint(a) return J(a[1],-a[2],-a[3],-a[4],a[5],a[6]) end
local function mirror(p)
 return P(mirrorJoint(p.Root),mirrorJoint(p.LeftShoulder),mirrorJoint(p.RightShoulder),mirrorJoint(p.LeftHip),mirrorJoint(p.RightHip),mirrorJoint(p.Neck))
end
local function cycle(a)
 local out=table.clone(a)
 for _,p in a do out[#out+1]=mirror(p) end
 return out
end
local clips={}
-- Contact, compression, passing, lift, opposite contact.
clips.Heroic=cycle({
 P(J(-17,-10,-3,.04,0,-.08),J(-42,-8,12,.02,0,.12),J(47,5,-10,-.02,.07,-.16),J(41,0,3,.03,.06,-.24),J(-35,0,-3,-.03,.04,.20),J(12,9,2)),
 P(J(-24,-5,-4,.06,-.14,-.13),J(-27,-6,11,.04,.04,.16),J(30,8,-10,-.04,.05,-.15),J(15,0,4,.03,.04,-.12),J(-47,0,-4,-.02,.22,.26),J(19,5,3)),
 P(J(-21,3,-2,.03,.04,-.11),J(4,-4,12,.02,0,.05),J(2,7,-12,-.02,.01,-.04),J(-15,0,3,.02,0,.03),J(20,0,-3,-.02,.32,-.13),J(15,-3)),
 P(J(-16,9,2,-.02,.12,-.08),J(37,-8,13,.02,.06,-.15),J(-34,4,-13,-.02,0,.13),J(-39,0,4,.02,.12,.19),J(47,0,-4,-.03,.20,-.28),J(11,-8))
})
clips["Anime Hero"]=cycle({
 P(J(-36,-4,-3,.03,.02,-.18),J(-59,-9,16,.07,.02,.29),J(-65,9,-17,-.07,.03,.32),J(57,1,4,.02,.12,-.29),J(-46,-3,-6,-.04,.11,.31),J(28,4,2)),
 P(J(-41,-2,-4,.05,-.15,-.23),J(-66,-8,18,.06,.01,.31),J(-55,7,-15,-.05,.01,.29),J(21,0,3,.03,.03,-.12),J(-65,0,-6,-.03,.30,.39),J(32,2,3)),
 P(J(-39,2,-1,.01,.02,-.2),J(-62,-10,15,.06,.03,.28),J(-57,8,-15,-.06,.03,.28),J(-21,0,3,.02,0,.12),J(36,0,-4,-.03,.39,-.22),J(30,-2)),
 P(J(-34,4,2,-.03,.17,-.18),J(-52,-9,16,.06,.04,.25),J(-66,10,-18,-.06,.05,.33),J(-57,0,5,.04,.20,.35),J(62,0,-4,-.04,.24,-.37),J(26,-4))
})
clips.Zombie={
 P(J(-23,18,9,.08,-.05,-.13),J(83,-15,20,.05,.15,-.18),J(48,25,-32,-.09,.13,-.22),J(48,7,12,.03,.09,-.2),J(-31,-5,-7,-.04,.02,.22),J(-12,-24,18)),
 P(J(-37,-10,-13,-.08,-.20,-.23),J(105,18,31,.1,.18,-.22),J(18,-18,-45,-.12,.05,.04),J(10,-8,5,.02,.03,-.07),J(-57,-3,-14,-.06,.19,.31),J(17,29,-22)),
 P(J(-20,22,16,.09,.1,-.18),J(37,-20,43,.11,.09,-.07),J(95,16,-24,-.04,.15,-.23),J(-25,5,16,.07,.18,.21),J(59,-8,-10,-.07,.29,-.29),J(-10,-31,26)),
 P(J(-42,-17,-11,-.08,-.13,-.22),J(70,21,15,.03,.12,-.19),J(112,-7,-37,-.09,.19,-.25),J(-59,8,7,.03,.11,.27),J(19,-4,-6,-.06,.04,-.08),J(22,20,-25)),
 P(J(-16,8,20,.09,.15,-.1),J(115,-18,42,.09,.19,-.26),J(28,12,-17,-.04,.02,.06),J(32,6,13,.04,.29,-.25),J(-27,-3,-16,-.06,.04,.15),J(-18,-13,30)),
 P(J(-34,-21,-15,-.1,-.08,-.2),J(43,12,18,.06,.06,-.08),J(102,-19,-44,-.12,.17,-.22),J(-18,8,8,.04,.04,.14),J(35,-4,-7,-.03,.2,-.23),J(13,30,-18))
}
clips["Retro Zombie"]=clips.Zombie
clips.Tsundere={
 P(J(4,-14,7,.05,.015,-.02),J(60,-28,-14,-.11,.08,-.20),J(14,22,-10,.03,.02,.03),J(23,3,-4,-.02,.03,-.15),J(-17,-4,3,.02,0,.1),J(-8,27,-13)),
 P(J(-4,-6,3,.03,-.06,-.02),J(66,-34,-21,-.15,.11,-.23),J(29,16,-17,-.01,.04,-.11),J(7,0,-3,-.01,0,-.06),J(-32,-4,4,.02,.12,.16),J(2,19,-10)),
 P(J(3,10,-5,-.04,.06,0),J(49,-22,-13,-.10,.07,-.16),J(-18,19,-15,-.02,.02,.09),J(-22,3,-5,-.01,.03,.13),J(29,-3,4,.01,.16,-.16),J(-5,-22,12)),
 P(J(7,14,-8,-.06,.025,.01),J(72,-32,-18,-.15,.09,-.22),J(3,25,-13,-.03,.03,.02),J(-28,3,-4,-.02,.05,.14),J(19,-3,3,.01,.04,-.12),J(-10,-29,16)),
 P(J(-3,4,-3,-.02,-.04,-.01),J(58,-26,-18,-.11,.08,-.18),J(24,16,-20,-.04,.06,-.10),J(-32,3,-4,-.03,.12,.16),J(7,-2,4,.02,0,-.04),J(2,-13,8)),
 P(J(6,-10,5,.04,.07,0),J(48,-24,-11,-.09,.06,-.15),J(-22,20,-12,-.01,.02,.10),J(27,3,-4,-.01,.15,-.17),J(-22,-3,4,.01,.02,.12),J(-9,21,-10))
}
clips["Little Duck"]=cycle({
 P(J(-5,-10,17,.12,.04,-.02),J(3,-14,58,.07,.03,.02),J(-15,18,-26,-.03,.08,.08),J(23,15,10,.04,.12,-.09),J(-13,-17,-8,-.05,.01,.08),J(4,9,-14)),
 P(J(1,-4,11,.08,-.07,0),J(-12,-10,30,.04,.01,.04),J(15,18,-67,-.07,.1,-.05),J(7,12,11,.04,.04,-.05),J(-22,-18,-10,-.05,.16,.11),J(-2,4,-10)),
 P(J(-3,6,-5,-.03,.09,-.01),J(17,-17,73,.07,.12,-.05),J(-8,15,-44,-.04,.04,.02),J(-19,15,10,.05,.02,.08),J(31,-15,-9,-.06,.20,-.13),J(3,-6,7)),
 P(J(-6,10,-16,-.1,.03,0),J(-9,-13,35,.04,.02,.02),J(7,18,-66,-.07,.09,-.04),J(-26,16,9,.06,.08,.12),J(28,-15,-10,-.06,.08,-.11),J(5,-9,14))
})
clips["Doll Walk"]=cycle({
 P(J(6,-12,6,.045,.03,0),J(36,-10,16,.05,.13,-.10),J(-18,9,-24,-.05,.07,.06),J(27,0,3,.02,.09,-.12),J(-22,0,-3,-.02,.03,.09),J(-10,14,-9)),
 P(J(-5,-5,-3,.02,-.06,-.03),J(9,-12,12,.04,.08,-.03),J(5,10,-19,-.04,.11,-.02),J(6,0,3,.02,0,-.03),J(-32,0,-4,-.02,.20,.15),J(12,8,6)),
 P(J(9,9,9,-.03,.13,.01),J(-16,-15,22,.07,.09,.09),J(40,12,-18,-.07,.17,-.12),J(-19,0,3,.02,.03,.07),J(39,0,-4,-.03,.27,-.19),J(-14,-15,-10)),
 P(J(2,13,-4,-.04,.02,0),J(-22,-10,17,.05,.08,.07),J(44,14,-15,-.05,.14,-.12),J(-27,0,3,.02,.08,.13),J(29,0,-4,-.02,.09,-.13),J(5,-17,7))
})
clips["Wavy Expressive"]=cycle({
 P(J(-12,-20,10,.12,.02,-.22),J(56,-13,25,.09,.13,-.36),J(-23,19,-21,-.08,.04,.13),J(34,4,6,.05,.07,-.33),J(-27,-4,-6,-.04,.02,.14),J(6,17,-9)),
 P(J(-21,-7,4,.06,-.12,-.31),J(36,-10,40,.13,.09,-.42),J(8,15,-28,-.09,.07,-.12),J(11,3,5,.04,.03,-.24),J(-38,-3,-5,-.04,.19,.13),J(13,5,-5)),
 P(J(-8,9,-7,-.08,.10,-.21),J(-6,-8,47,.13,.08,-.21),J(43,15,-17,-.1,.15,-.38),J(-20,4,5,.03,.03,.09),J(41,-4,-7,-.05,.28,-.32),J(4,-12,9)),
 P(J(-10,20,-10,-.12,.11,-.19),J(-32,-14,24,.09,.03,.15),J(62,18,-32,-.12,.13,-.41),J(-35,4,6,.04,.11,.12),J(47,-4,-6,-.04,.13,-.36),J(6,-17,10))
})
-- Positive torso pitch leans back from the -Z facing direction.
-- Relaxed levitation silhouette. Independent continuous channels below
-- replace the previous rigid three-pose loop for grounded Godly Aura.
clips["Godly Aura"]={
 P(J(19),J(-37,-5,18),J(-34,5,-17),J(-35,0,3,.015,.05,.15),J(-21,0,-2,-.015,0,.04),J(-16))
}
clips["Harpy Glide"]={
 P(J(-23,0,0,0,0,-.1),J(-30,-10,56,.06,.03,.12),J(-30,10,-56,-.06,.03,.12),J(-5,0,2),J(-5,0,-2),J(21)),
 P(J(-25,3,2,0,0,-.1),J(-36,-10,48),J(-28,10,-62),J(-5,0,2),J(-5,0,-2),J(23,-3,-2)),
 P(J(-22,-3,-2,0,0,-.1),J(-28,-10,62),J(-36,10,-48),J(-5,0,2),J(-5,0,-2),J(19,3,2))
}
clips.Skater={
 P(J(-8,52,-8,.05,-.18,0),J(15,-12,64,.05,.03,-.07),J(-22,13,-35,-.06,.03,.06),J(8,0,8,.12,.03,-.12),J(-6,0,-9,-.12,.03,.1),J(5,-45,5)),
 P(J(-12,57,3,-.06,-.23,0),J(-11,-10,47,.06,.04,.05),J(22,12,-62,-.06,.05,-.09),J(11,0,7,.12,.07,-.1),J(-10,0,-8,-.12,.07,.1),J(8,-50,-2)),
 P(J(-4,50,8,-.08,-.13,0),J(-16,-10,37,.05,.01,.07),J(12,12,-66,-.05,.06,-.06),J(5,0,8,.12,.02,-.12),J(-4,0,-8,-.12,.02,.12),J(2,-43,-5)),
 P(J(-7,46,-2,.04,-.17,0),J(13,-10,63,.06,.04,-.05),J(-19,12,-43,-.05,.03,.06),J(8,0,8,.12,.03,-.12),J(-6,0,-9,-.12,.03,.12),J(4,-40,2))
}
clips.Fighter=cycle({
 P(J(-13,-8,-3,.03,0,-.07),J(44,-5,9,.03,.08,-.12),J(21,18,-22,-.06,.07,-.09),J(37,0,4,.03,.06,-.22),J(-28,0,-3,-.03,.03,.19),J(9,7,2)),
 P(J(-19,-3,-4,.04,-.10,-.13),J(49,-5,9,.03,.08,-.13),J(13,18,-22,-.05,.05,-.05),J(12,0,4,.02,0,-.08),J(-42,0,-4,-.02,.21,.26),J(15,3,3)),
 P(J(-15,3,0,0,.04,-.1),J(45,-4,9,.03,.07,-.12),J(24,18,-22,-.06,.07,-.10),J(-18,0,3,.02,.02,.09),J(33,0,-4,-.03,.30,-.19),J(11,-3)),
 P(J(-10,8,3,-.02,.08,-.06),J(42,-5,9,.03,.08,-.12),J(19,18,-22,-.05,.06,-.07),J(-35,0,4,.03,.14,.22),J(42,0,-4,-.03,.17,-.25),J(7,-8,-2))
})
-- Keep the decorative prop in the same right hand across the entire cycle.
for _,p in clips.Fighter do p.RightShoulder=J(44,-5,9,.03,.08,-.12) end
local idle={
 Tsundere=P(J(5,-10,6,.03,0,0),J(66,-29,-17,-.12,.09,-.19),J(8,20,-11,-.02,.01,0),J(0,4,-3),J(0,-4,3),J(-8,25,-12)),
 Zombie=P(J(-16,8,7,0,0,-.06),J(48,-10,17,.02,.05,-.06),J(27,10,-17,-.02,.03,-.02),J(4,0,3),J(-5,0,-4),J(-9,-10,12)),
 ["Godly Aura"]=P(J(28,0,0,0,.01,.07),J(-55,-8,20,.035,.02,.14),J(-53,8,-20,-.035,.02,.14),J(-49,0,3,.015,.11,.25),J(-32,0,-2,-.015,.02,.12),J(-25)),
 ["Harpy Glide"]=P(J(-4),J(-5,-12,40),J(-5,12,-40),J(),J(),J(4)),
 Fighter=P(J(-3,-5,0),J(44,-5,9,.03,.08,-.12),J(14,18,-22,-.05,.05,-.05),J(4,0,3),J(-4,0,-3),J(3,4)),
 Skater=clips.Skater[1],["Doll Walk"]=clips["Doll Walk"][1],["Little Duck"]=P(J(),J(0,0,25),J(0,0,-25),J(),J()),
}
idle["Retro Zombie"]=idle.Zombie
local jump={
 Heroic=P(J(-18,-12,3),J(112,-8,23),J(-24,12,-18),J(62,0,4,.03,.3,-.25),J(-36,0,-4),J(13)),
 ["Anime Hero"]=P(J(-38),J(-68,-8,15),J(-68,8,-15),J(55,0,4,.03,.32,-.22),J(-48,0,-4),J(31)),
 Zombie=P(J(-28,20,-17),J(137,-22,46),J(68,17,-64),J(61,8,18,.04,.3,-.25),J(-38,-13,-21),J(-20,28,24)),
 ["Retro Zombie"]=P(J(-12,14,12),J(94,-10,21),J(73,10,-24),J(28,8,12),J(-19,-7,-13),J(-15,-16,15)),
 Tsundere=P(J(8,-18,9),J(74,-34,-18,-.13,.12,-.24),J(40,14,-26),J(38,5,-5,.02,.23,-.19),J(20,-4,4,-.03,.2,-.09),J(-10,26,-15)),
 ["Little Duck"]=P(J(-7,0,5),J(6,-12,105),J(6,12,-105),J(36,18,10,.04,.23,-.13),J(36,-18,-10,-.04,.23,-.13),J(7)),
 ["Doll Walk"]=P(J(10,18,8),J(58,-14,45,.06,.17,-.13),J(63,15,-48,-.06,.17,-.15),J(19,0,8,.05,.24,-.06),J(-27,0,-8),J(-16,-16,-10)),
 ["Wavy Expressive"]=P(J(-26,16,-10,.1,0,-.32),J(112,-8,35,.1,.2,-.4),J(33,13,-64,-.1,.1,-.24),J(57,5,5,.04,.34,-.35),J(-22,-5,-7),J(20,-18,9)),
 ["Godly Aura"]=P(J(23),J(-46,-8,30),J(-44,8,-29),J(-40,0,4,.02,.10,.18),J(-25,0,-3,-.02,.025,.06),J(-19)),
 Fighter=P(J(-18,-6),J(45),J(45),J(57,0,4,.03,.29,-.24),J(-29,0,-4),J(13,4)),
 Skater=P(J(-30,58,0,0,-.15,0),J(36,-10,52),J(-12,10,-58),J(38,0,9,.12,.35,-.1),J(38,0,-9,-.12,.35,.1),J(26,-51)),
}
local fall={
 Heroic=P(J(9,3,-3),J(21,-10,62),J(35,12,-56),J(18,0,5),J(-12,0,-5),J(-9)),
 ["Anime Hero"]=P(J(-14),J(-44,-10,27),J(-44,10,-27),J(23,0,4,.02,.13,-.08),J(18,0,-4,-.02,.13,-.08),J(11)),
 Zombie=P(J(14,-22,24),J(158,25,52),J(-24,-17,-82),J(-39,17,24),J(53,-14,-19,.02,.15,-.16),J(-22,32,-29)),
 ["Retro Zombie"]=P(J(13,12,-16),J(78,-14,58),J(97,18,-42),J(-12,14,15),J(20,-9,-12),J(12,-17,20)),
 Tsundere=P(J(12,12,-7),J(82,-28,-13,-.13,.09,-.23),J(82,22,-37),J(12,2,-4),J(8,-2,4),J(-16,-24,13)),
 ["Little Duck"]=P(J(7,0,-4),J(15,-10,65),J(15,10,-65),J(-8,20,13),J(-8,-20,-13),J(-6)),
 ["Doll Walk"]=P(J(19,-14,-11),J(136,-8,29,.04,.12,0),J(117,10,-33,-.04,.12,0),J(-12,0,10),J(24,0,-10),J(-22,12,14)),
 ["Wavy Expressive"]=P(J(12,-15,17,.12,0,-.14),J(30,-13,92,.08,.1,-.22),J(102,15,-30,-.1,.1,-.28),J(22,5,10),J(-19,-4,-6),J(-8,20,-15)),
 ["Godly Aura"]=P(J(17),J(-30,-10,43),J(-29,10,-42),J(-31,0,3,.02,.06,.12),J(-19,0,-2,-.02,.015,.04),J(-14)),
 ["Harpy Glide"]=P(J(-13),J(-11,-12,78),J(-11,12,-78),J(-13,0,3),J(-13,0,-3),J(10)),
 Skater=P(J(5,10,-3),J(48),J(48),J(16,0,7),J(-10,0,-6),J(-4,-8)),
 Fighter=P(J(7,-6),J(40),J(40),J(23,0,6),J(16,0,-6),J(-5,5)),
}

-- Browser V12.2 Godly six-key loop, independently delayed limbs.
clips["Godly Aura"]={
 P(J(8,-6,4,0,0,.02),J(-30,-8,20,.02,.01,.06),J(14,9,-24,-.02,.01,-.04),J(34,2,5,.02,.17,-.15),J(-22,-4,-3,-.01,.015,.08),J(-7,6,-3)),
 P(J(16,-3,1,.015,0,.03),J(-24,-5,25,.02,.02,.05),J(26,12,-17,-.03,.04,-.09),J(47,4,6,.02,.24,-.23),J(-26,-3,-3,-.02,.025,.11),J(-13,4,-1)),
 P(J(9,3,-4,0,0,.01),J(-13,-4,31,.03,.025,.01),J(30,7,-22,-.03,.045,-.07),J(37,3,5,.02,.19,-.18),J(-18,-2,-3,-.015,.02,.08),J(-7,-3,3)),
 P(J(-5,7,-5,-.01,0,-.025),J(-25,-7,39,.025,.02,.07),J(4,8,-38,-.025,.025,.01),J(20,3,5,.02,.10,-.06),J(-16,-2,-3,-.015,.02,.05),J(4,-6,4)),
 P(J(-12,4,-1,0,0,-.06),J(-39,-9,32,.02,.02,.09),J(-19,8,-33,-.02,.02,.06),J(9,2,4,.015,.06,.01),J(-21,-3,-3,-.015,.02,.08),J(9,-4,1)),
 P(J(-2,-4,3,0,0,-.02),J(-37,-9,19,.02,.01,.09),J(-2,10,-27,-.02,.01,.02),J(22,2,5,.02,.12,-.08),J(-23,-3,-3,-.015,.02,.09),J(2,4,-3))
}
idle["Godly Aura"]=P(J(7),J(-13,-4,17),J(-6,5,-18),J(21,2,4,.01,.12,-.1),J(-15,-2,-3,-.01,.01,.05),J(-5))
jump["Godly Aura"]=P(J(-12,-4,3),J(-38,-9,43),J(-20,9,-35),J(44,4,6,.02,.25,-.21),J(-22,-3,-4,-.02,.04,.11),J(10,3,-2))
fall["Godly Aura"]=P(J(9,4,-2),J(4,-9,53),J(9,10,-49),J(22,3,5,.02,.14,-.1),J(-13,-2,-3,-.01,.02,.03),J(-7,-3,1))
local joints={"Root","RightShoulder","LeftShoulder","RightHip","LeftHip","Neck"}
local V=Vector3.new
local rad=math.rad
local tau=2*math.pi
local function angle(x,y,z) return CFrame.Angles(rad(x or 0),rad(y or 0),rad(z or 0)) end
local function qdot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]+a[4]*b[4] end
local function qscale(a,k) return {a[1]*k,a[2]*k,a[3]*k,a[4]*k} end
local function qadd(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3],a[4]+b[4]} end
local function qnorm(a) return qscale(a,1/math.max(1e-9,math.sqrt(qdot(a,a)))) end
local function qmul(a,b)
 local x,y,z,w=table.unpack(a);local u,v,t,s=table.unpack(b)
 return {w*u+x*s+y*t-z*v,w*v-x*t+y*s+z*u,w*t+x*v-y*u+z*s,w*s-x*u-y*v-z*t}
end
local function qinv(a) return {-a[1],-a[2],-a[3],a[4]} end
local function qalign(a,b) return if qdot(a,b)<0 then qscale(b,-1) else b end
local function axis(i,a) local q={0,0,0,math.cos(rad(a)/2)};q[i]=math.sin(rad(a)/2);return q end
local function euler(a,b,c) return qmul(qmul(axis(1,a),axis(2,b)),axis(3,c)) end
local function qframe(q) return CFrame.new(0,0,0,q[1],q[2],q[3],q[4]) end
local ident={0,0,0,1}
local function qslerp(a,b,t)
 b=qalign(a,b);local d=math.clamp(qdot(a,b),-1,1)
 if d>.9995 then return qnorm(qadd(qscale(a,1-t),qscale(b,t))) end
 local h=math.acos(d);local s=math.sin(h)
 return qnorm(qadd(qscale(a,math.sin((1-t)*h)/s),qscale(b,math.sin(t*h)/s)))
end
local function qlog(a)
 local v=V(a[1],a[2],a[3]);return if v.Magnitude<1e-8 then Vector3.zero else v.Unit*math.acos(math.clamp(a[4],-1,1))
end
local function qexp(v)
 local a=v.Magnitude;if a<1e-8 then return ident end
 local w=v.Unit*math.sin(a);return {w.X,w.Y,w.Z,math.cos(a)}
end
local function tangent(p,q,n) return qmul(q,qexp(-.25*(qlog(qmul(qinv(q),qalign(q,p)))+qlog(qmul(qinv(q),qalign(q,n)))))) end
local function convert(p)
 local r={};for i,name in joints do local j=p[name];r[i]={q=euler(j[1],j[2],j[3]),v=V(j[4],j[5],j[6])} end;return r
end
local function blend(a,b,u)
 local r={};for i,j in a do r[i]={q=qslerp(j.q,b[i].q,u),v=j.v:Lerp(b[i].v,u)} end;return r
end
local neutral=convert(P(J(),J(),J(),J(),J(),J()))
local retro={}
for i,p in clips.Zombie do
 local copy={};for n,j in p do copy[n]=J(j[1]*.78,j[2]*.78,j[3]*.78,j[4],j[5],j[6]) end;retro[i]=copy
end
clips["Retro Zombie"]=retro
local keys={}
for name,poses in clips do
 local c={};for i,p in poses do c[i]=convert(p) end
 for i,p in c do for j,k in p do k.tangent=tangent(c[(i-2)%#c+1][j].q,k.q,c[i%#c+1][j].q) end end
 keys[name]=c
end
local rests,upPoses,downPoses={},{},{}
for n,p in idle do rests[n]=convert(p) end
for n,p in jump do upPoses[n]=convert(p) end
for n,p in fall do downPoses[n]=convert(p) end
local delays={0,.06,.10,.035,.11,.045}
local function sample(name,t)
 local c=keys[name];local out={}
 for j=1,6 do
  local d=if name=="Godly Aura" then delays[j] else 0
  local f=((t-d)%1)*#c;local i=math.floor(f);local u=f-i
  local function k(n) return c[(i+n)%#c+1][j] end
  local p,a,b,n=k(-1),k(0),k(1),k(2)
  local v=.5*(2*a.v+(-p.v+b.v)*u+(2*p.v-5*a.v+4*b.v-n.v)*u*u+(-p.v+3*a.v-3*b.v+n.v)*u*u*u)
  out[j]={q=qslerp(qslerp(a.q,b.q,u),qslerp(a.tangent,b.tangent,u),2*u*(1-u)),v=v}
 end
 return out
end
local ground=keys["Harpy Glide"][1]
local prep=convert(P(J(-34),J(-42,-8,28),J(-42,8,-28),J(20,0,3,0,.12,-.04),J(20,0,-3,0,.12,-.04),J(21)))
local tuck=convert(P(J(0),J(24,-8,20,0,.06,-.04),J(24,8,-20,0,.06,-.04),J(50,0,4,0,.28,-.18),J(46,0,-4,0,.26,-.16),J(2)))
local opened=convert(P(J(-13),J(-11,-12,78),J(-11,12,-78),J(-13,0,3),J(-13,0,-3),J(10)))
local function ease(x) x=math.clamp(x,0,1);return x*x*x*(10+x*(-15+6*x)) end
local function harpy(t)
 local x=t%2.8
 if x<.30 then return blend(ground,prep,ease(x/.30)),0,0,"PREPARE"
 elseif x<.62 then local u=ease((x-.30)/.32);return blend(prep,tuck,u),0,3.3*u,"TAKEOFF"
 elseif x<1.62 then local u=x-.62;return blend(tuck,opened,ease((u-.58)/.42)),-360*ease(u),3.3+.35*math.sin(math.pi*u)^2,"360 FLIP"
 elseif x<2.35 then local u=ease((x-1.62)/.73);return blend(opened,prep,u),-360,3.3*(1-u),"GLIDE"
 else return blend(prep,ground,ease((x-2.35)/.45)),-360,0,"LAND" end
end
local extra={
 ["Natural"]={cadence=7.5,stride=.29,arms=.30,rest=0,spread=.08,lean=.08,roll=.04,bob=.04,hover=0},
 ["Bouncy"]={cadence=8.6,stride=.23,arms=.37,rest=.10,spread=.16,lean=.06,roll=.1,bob=.15,hover=0},
 ["Floating"]={cadence=3.5,stride=.06,arms=.10,rest=-.15,spread=.25,lean=-.03,roll=.04,bob=.04,hover=.21},
 ["Glide"]={cadence=4,stride=.08,arms=.08,rest=-.25,spread=.16,lean=.15,roll=.03,bob=.02,hover=.07},
 ["Ethereal"]={cadence=3.2,stride=.06,arms=.12,rest=-.10,spread=.37,lean=-.05,roll=.05,bob=.04,hover=.25},
 ["Toy"]={cadence=7.6,stride=.25,arms=.31,rest=.07,spread=.04,lean=-.015,roll=.025,bob=.042,hover=0},
 ["Robot"]={cadence=6.4,stride=.19,arms=.27,rest=-.14,spread=.02,lean=.04,roll=0,bob=.018,hover=0},
 ["Ninja"]={cadence=10.2,stride=.31,arms=.12,rest=-.38,spread=.10,lean=.18,roll=.035,bob=.024,hover=0},
 ["Bubbly"]={cadence=7.4,stride=.20,arms=.34,rest=.08,spread=.16,lean=-.05,roll=.13,bob=.115,hover=0},
 ["Stylish"]={cadence=6.1,stride=.21,arms=.23,rest=-.025,spread=.065,lean=-.055,roll=.10,bob=.055,hover=0},
 ["Mage"]={cadence=4.3,stride=.10,arms=.13,rest=-.16,spread=.34,lean=-.055,roll=.06,bob=.045,hover=.13},
 ["Levitation"]={cadence=3.5,stride=.08,arms=.09,rest=-.20,spread=.40,lean=.065,roll=.06,bob=.04,hover=.21},
 ["Oldschool"]={cadence=7.3,stride=.30,arms=.31,rest=0,spread=0,lean=0,roll=0,bob=.024,hover=0},
 ["Vampire"]={cadence=5.8,stride=.19,arms=.17,rest=-.06,spread=.20,lean=-.085,roll=.03,bob=.033,hover=0},
 ["Astronaut"]={cadence=4.4,stride=.16,arms=.17,rest=-.06,spread=.15,lean=.028,roll=.07,bob=.045,hover=.09},
 ["Cartoony"]={cadence=8.8,stride=.29,arms=.38,rest=.055,spread=.12,lean=.02,roll=.13,bob=.13,hover=0},
 ["Angel Glide"]={cadence=3.6,stride=.09,arms=.08,rest=-.24,spread=.47,lean=-.045,roll=.06,bob=.045,hover=.21},
 ["Bat Swoop"]={cadence=4.9,stride=.11,arms=.2,rest=-.33,spread=.61,lean=.15,roll=.18,bob=.03,hover=.17},
 ["Mermaid Drift"]={cadence=3.1,stride=.045,arms=.16,rest=-.03,spread=.3,lean=.06,roll=.11,bob=.015,hover=.14},
 ["Serpent Slither"]={cadence=5.1,stride=.10,arms=.07,rest=-.14,spread=.1,lean=.11,roll=.18,bob=.016,hover=0},
 ["Cartwheel Flow"]={cadence=6.2,stride=.19,arms=.35,rest=-.1,spread=.45,lean=.02,roll=.1,bob=.06,hover=0},
 ["Rubberhose"]={cadence=7.9,stride=.3,arms=.42,rest=.08,spread=.22,lean=.09,roll=.16,bob=.15,hover=0},
 ["Dream Sleep"]={cadence=2.4,stride=.04,arms=.035,rest=-.3,spread=.15,lean=-.13,roll=.15,bob=.016,hover=.25},
 ["Plushie"]={cadence=6.5,stride=.11,arms=.14,rest=.25,spread=.1,lean=-.045,roll=.06,bob=.07,hover=0},
 ["Cat Paws"]={cadence=7.4,stride=.17,arms=.16,rest=.40,spread=.19,lean=-.085,roll=.12,bob=.06,hover=0},
 ["Shy Kawaii"]={cadence=6.1,stride=.13,arms=.08,rest=.35,spread=.08,lean=-.09,roll=.10,bob=.04,hover=0},
 ["Gymnast"]={cadence=6.6,stride=.27,arms=.37,rest=-.1,spread=.32,lean=-.02,roll=.08,bob=.09,hover=0},
 ["Skip Hop"]={cadence=8.3,stride=.24,arms=.37,rest=.04,spread=.30,lean=.02,roll=.17,bob=.15,hover=0},
 ["Reindeer Prance"]={cadence=8.1,stride=.21,arms=.26,rest=.18,spread=.17,lean=-.04,roll=.09,bob=.15,hover=0},
 ["Floating Head"]={cadence=3.2,stride=.02,arms=.05,rest=-.25,spread=.19,lean=.02,roll=.12,bob=.02,hover=.31},
 ["Dark Aura"]={cadence=3.8,stride=.07,arms=.07,rest=-.33,spread=.30,lean=.035,roll=.08,bob=.025,hover=.22},
 ["Headless Float"]={cadence=3.7,stride=.035,arms=.06,rest=-.33,spread=.24,lean=.015,roll=.12,bob=.02,hover=.29},
 ["Godly Aura"]={cadence=3.2,stride=.06,arms=.07,rest=-.23,spread=.41,lean=-.06,roll=.085,bob=.025,hover=.18},
 ["Harpy Glide"]={cadence=4.7,stride=.09,arms=.15,rest=-.22,spread=.59,lean=.09,roll=.15,bob=.045,hover=0},
 ["Skater"]={cadence=4.9,stride=.18,arms=.22,rest=-.14,spread=.18,lean=.14,roll=.13,bob=.025,hover=0},
 ["Fighter"]={cadence=8.2,stride=.26,arms=.21,rest=.41,spread=.17,lean=.15,roll=.04,bob=.036,hover=0},
 ["Heroic"]={cadence=7.8,stride=.34,arms=.34,rest=.1,spread=.14,lean=.15,roll=.08,bob=.06,hover=0},
 ["Anime Hero"]={cadence=9.2,stride=.35,arms=.24,rest=-.22,spread=.17,lean=.19,roll=.09,bob=.045,hover=0},
 ["Zombie"]={cadence=5.1,stride=.19,arms=.08,rest=.28,spread=.08,lean=.21,roll=.11,bob=.035,hover=0},
 ["Retro Zombie"]={cadence=4.2,stride=.15,arms=.06,rest=.39,spread=.1,lean=.23,roll=.13,bob=.02,hover=0},
 ["Tsundere"]={cadence=6.6,stride=.17,arms=.12,rest=.23,spread=.04,lean=-.08,roll=.12,bob=.05,hover=0},
 ["Little Duck"]={cadence=7.4,stride=.13,arms=.21,rest=.06,spread=.36,lean=-.06,roll=.19,bob=.1,hover=0},
 ["Doll Walk"]={cadence=5.6,stride=.14,arms=.16,rest=.11,spread=.075,lean=-.055,roll=.13,bob=.055,hover=0},
 ["Wavy Expressive"]={cadence=6.8,stride=.22,arms=.31,rest=-.01,spread=.2,lean=-.04,roll=.18,bob=.075,hover=0},
}
local families={
 ["Natural"]="step",
 ["Bouncy"]="hop",
 ["Floating"]="float",
 ["Glide"]="float",
 ["Ethereal"]="float",
 ["Toy"]="stiff",
 ["Robot"]="stiff",
 ["Ninja"]="stride",
 ["Bubbly"]="hop",
 ["Stylish"]="strut",
 ["Mage"]="float",
 ["Levitation"]="float",
 ["Oldschool"]="step",
 ["Vampire"]="strut",
 ["Astronaut"]="slow",
 ["Cartoony"]="hop",
 ["Angel Glide"]="wing",
 ["Bat Swoop"]="wing",
 ["Mermaid Drift"]="paired",
 ["Serpent Slither"]="sweep",
 ["Cartwheel Flow"]="cartwheel",
 ["Rubberhose"]="hop",
 ["Dream Sleep"]="sleep",
 ["Plushie"]="stiff",
 ["Cat Paws"]="prance",
 ["Shy Kawaii"]="shy",
 ["Gymnast"]="gym",
 ["Skip Hop"]="skip",
 ["Reindeer Prance"]="prance",
 ["Floating Head"]="float",
 ["Dark Aura"]="float",
 ["Headless Float"]="float",
 ["Godly Aura"]="signature",
 ["Harpy Glide"]="signature",
 ["Skater"]="signature",
 ["Fighter"]="signature",
 ["Heroic"]="signature",
 ["Anime Hero"]="signature",
 ["Zombie"]="signature",
 ["Retro Zombie"]="signature",
 ["Tsundere"]="signature",
 ["Little Duck"]="signature",
 ["Doll Walk"]="signature",
 ["Wavy Expressive"]="signature",
}
local function profile(name) return extra[name] or Packs.get(name) or extra.Natural end
local function procedural(name,t,state)
 local p=profile(name);local f=families[name] or "step"
 local m=if state=="Idle" then 0 elseif state=="Walk" then .65 else 1
 local a=t*p.cadence*(if state=="Run" then 1.3 else .9)
 local s,c=math.sin(a),math.cos(a);local w=if f=="stiff" then math.tanh(2.2*s) else s
 local L,A,B,R,S=p.stride*165*m,p.arms*135*m,-p.lean*90*m,p.rest*90,p.spread*100
 local ra,la,rl,ll=R-A*w,R+A*w,L*w,-L*w
 local rz,lz,br,turn=S,-S,p.roll*90*s*m,5*s*m
 local h1,h2=math.max(0,c)*.2*m,math.max(0,-c)*.2*m
 if state=="Run" then
  B-=7+12*p.stride
  ra*=1.12;la*=1.12;rl*=1.20;ll*=1.20;h1*=1.35;h2*=1.35
 end
 if f=="float" or f=="wing" or f=="paired" or f=="sleep" then
  rl=-10+6*s;ll=-12+6*math.sin(a-.6);ra=R+A*.7*s;la=R+A*.7*math.sin(a-.7);h1=.05+.025*s;h2=.05+.025*c
  if f=="wing" then rz=45+25*s;lz=-rz elseif f=="paired" then rl=18*s;ll=rl;turn=12*s elseif f=="sleep" then B=28+4*s;rl=25;ll=-10 end
 end
 if f=="sweep" then rl=15*s;ll=15*math.sin(a-.7);br=20*s;turn=18*s
 elseif f=="shy" then ra=56+8*s;la=48-8*s;rz=-18;lz=18;rl*=.6;ll*=.6
 elseif f=="prance" then ra=40+12*s;la=40-12*s;h1*=1.6;h2*=1.6
 elseif f=="skip" then ll*=.7;h1=.2*math.max(0,s);h2=.28*math.max(0,-s);br=9*c
 elseif f=="gym" then ra=40+A*s;la=40-A*s;rz=40+15*s;lz=-40+15*s
 elseif f=="strut" then turn=12*s;br=10*s
 elseif f=="stiff" then h1*=.4;h2*=.4;turn*=.25
 elseif f=="slow" then rl*=.75;ll*=.75;h1*=1.5;h2*=1.5 end
 if state=="Idle" and not (f=="float" or f=="wing" or f=="paired" or f=="sleep") then
  -- Breathing, relaxed shoulder motion and weight shifts without a walk cycle.
  local breath=math.sin(t*(1.25+p.cadence*.10))
  B=-p.lean*30+1.8*breath
  br=p.roll*25*breath;turn=p.roll*15*math.sin(t*.9)
  ra+=2.2*breath;la-=2.2*breath
  rl=2.5*breath;ll=-2.5*breath
 end
 if state=="Jump" or state=="Fall" then
  local up=state=="Jump";B+=if up then -9 else 8
  ra=R+(if up then 75 else 22);la=R+(if up then 45 else 16)
  rz+=if up then 10 else 40;lz-=if up then 14 else 40
  rl=if up then 35+p.stride*60 else 12;ll=if up then -12-p.stride*30 else 18
  h1=if up then .22 else .06;h2=if up then .12 else .03
  if (p.hover or 0)>0 or f=="wing" then ra=-20;la=-20;rz=S+20;lz=-S-20;rl=8;ll=8 end
  local drift=math.sin(t*(2+p.cadence*.35))
  if up then ra+=6*drift;la-=5*drift;rl+=5*drift
  else rz+=7*drift;lz-=7*drift;rl+=6*drift;ll-=6*drift;B+=3*drift end
 end
 return convert(P(J(B,turn,br,.06*s*m,p.bob*math.abs(s)*m,-.05*m),J(ra,-5,rz,.015,.04*math.max(0,s),.1*s*m),J(la,5,lz,-.015,.04*math.max(0,-s),-.1*s*m),J(rl,0,3,.02,h1,-.12*s*m),J(ll,0,-3,-.02,h2,.12*s*m),J(-B*.75,-turn*.65,-br*.6)))
end
-- Independent climb and swimming cycles, using the personality of each pack.
-- Hands reach in alternating phases on a ladder; swimming uses a horizontal
-- root, alternating strokes or synchronized sweeps, and style-specific kicks.
local aquaticTraits={
 Natural={1,1,0,0},Heroic={1.18,1.10,-5,8},Bouncy={1.13,1.2,5,12},
 Floating={.72,.55,6,15},Glide={.78,.55,-9,18},Ethereal={.68,.65,12,23},
 Toy={.80,.76,0,0},Robot={.72,.70,0,0},Ninja={1.30,1.18,-12,5},
 Bubbly={1.06,1.18,9,15},Stylish={.88,.78,7,10},Mage={.76,.64,5,25},
 Levitation={.68,.55,4,30},Oldschool={1,1,-2,0},Vampire={.90,.82,10,16},
 Astronaut={.62,.72,-4,10},Zombie={.74,.60,14,12},Cartoony={1.22,1.30,8,20},
 ["Angel Glide"]={.74,.66,-3,32},["Bat Swoop"]={1.12,.90,-13,40},
 ["Mermaid Drift"]={.70,.60,4,36},["Serpent Slither"]={.82,.55,8,24},
 ["Cartwheel Flow"]={1.04,1.02,-6,27},Rubberhose={1.12,1.25,7,24},
 ["Dream Sleep"]={.54,.44,19,13},Plushie={.72,.65,3,14},["Cat Paws"]={1.13,1.05,9,20},
 ["Shy Kawaii"]={.78,.70,12,-8},Gymnast={1.14,1.12,-7,36},
 ["Skip Hop"]={1.15,1.20,5,15},["Reindeer Prance"]={1.18,1.12,2,21},
 Fighter={1.06,1.10,-10,7},["Harpy Glide"]={.92,.78,-7,42},
 ["Godly Aura"]={.65,.58,13,30},["Wavy Expressive"]={1.05,1.10,11,34},
 ["Retro Zombie"]={.62,.68,7,5},Tsundere={.90,.83,10,3},
 ["Doll Walk"]={.70,.76,8,19},Skater={.91,.85,-8,15},["Little Duck"]={1.24,.95,6,38},
 ["Floating Head"]={.65,.52,12,18},["Dark Aura"]={.72,.60,-11,30},
 ["Anime Hero"]={1.30,1.18,-15,11},["Headless Float"]={.76,.58,5,32}
}
local function waterClimbPose(name,t,state)
 local p=profile(name);local family=families[name] or "step"
 local q=aquaticTraits[name] or aquaticTraits.Natural
 local rate=q[1];local amp=q[2];local lean=q[3];local spread=q[4]
 local a=t*(if state=="Climb" then 5.4 else 4.5)*rate
 local wave=math.sin(a);local cross=math.cos(a)
 if family=="stiff" or name=="Doll Walk" then wave=math.tanh(wave*2.6);cross=math.tanh(cross*2.6) end
 if state=="Climb" then
  local r=math.max(0,wave);local l=math.max(0,-wave)
  local arm=math.clamp(39*amp+12*p.arms,28,65);local leg=math.clamp(32*amp+18*p.stride,23,60)
  local ra,la=125+arm*wave,125-arm*wave
  local rl,ll=12-leg*wave,12+leg*wave
  local handSpread=8+spread*.45
  if name=="Little Duck" then handSpread+=12
  elseif name=="Fighter" then ra=145+arm*.45*wave
  elseif name=="Godly Aura" then ra+=8;la-=8
  elseif name=="Harpy Glide" then handSpread+=10 end
  return convert(P(J(-9+lean*.35,7*wave,4*cross*amp,.045*wave,.04*math.sin(2*a),-.10),
   J(ra,-8,handSpread,.04,.22*r,-.12*r),J(la,8,-handSpread,-.04,.22*l,-.12*l),
   J(rl,0,5,.02,.18*l,-.16*l),J(ll,0,-5,-.02,.18*r,-.16*r),J(12-lean*.3,-5*wave,-3*cross)))
 end
 local paired=family=="paired" or family=="float" or family=="wing" or name=="Harpy Glide" or name=="Godly Aura" or name=="Little Duck"
 local stroke=math.clamp(46*amp+18*p.arms,30,75)
 local ra,la=75+stroke*wave,75-stroke*wave
 local rz,lz=20+spread*.7,-20-spread*.7
 local rl,ll=24*amp*wave,-24*amp*wave
 if paired then
  ra=72+stroke*wave;la=ra;rz+=25*cross;lz=-rz
  rl=18*amp*math.sin(a-.6);ll=rl
 elseif family=="sweep" then
  rl=22*wave;ll=22*math.sin(a-.5);rz+=14*cross;lz-=14*cross
 elseif name=="Fighter" then ra=102+24*wave;la=55-46*wave
 elseif name=="Zombie" or name=="Retro Zombie" then ra=92+35*wave;la=77+32*math.cos(a*.9) end
 local rootPitch=-78+lean*.38+4*cross
 return convert(P(J(rootPitch,7*wave,6*cross*amp,.055*wave,.04*cross,0),
  J(ra,-8,rz,.025,.05*math.max(0,wave),.10*cross),J(la,8,lz,-.025,.05*math.max(0,-wave),-.10*cross),
  J(rl,0,5,.025,.045*math.max(0,-wave),0),J(ll,0,-5,-.025,.045*math.max(0,wave),0),J(65-lean*.25,-4*wave,-3*cross)))
end
local function pose(name,t,state)
 if state=="Climb" or state=="Swim" then return waterClimbPose(name,t,state) end
 if not keys[name] then return procedural(name,t,state) end
 local r=rests[name] or neutral
 local period=if name=="Godly Aura" then (if state=="Walk" then 4.2 else 3.6) else tau/(profile(name).cadence*(if state=="Run" then 1.5 else 1))
 local p=sample(name,t/period)
 if state=="Idle" then return blend(r,p,.12+.04*math.sin(t*2))
 elseif state=="Walk" then return blend(r,p,.72)
 elseif state=="Jump" or state=="Fall" then
  if name=="Harpy Glide" then return opened end
  local up=state=="Jump";local target=(if up then upPoses else downPoses)[name] or r
  local u=t%1.2/1.2
  if name=="Godly Aura" then return if up then blend(r,target,.45+.55*math.sin(math.pi*u)) else blend(target,r,.2+.15*math.sin(t*2)) end
  if name=="Skater" and up then return blend(keys.Skater[1],target,.35+.65*math.sin(math.pi*u)) end
  local b=blend(target,target,0)
  if name=="Little Duck" then b[2].q=qmul(b[2].q,euler(0,0,20*math.sin(t*10)));b[3].q=qmul(b[3].q,euler(0,0,-20*math.sin(t*10)))
  elseif string.find(name,"Zombie",1,true) then b[2].q=qmul(b[2].q,euler(20*math.sin(t*13),0,0));b[3].q=qmul(b[3].q,euler(-25*math.cos(t*13),0,0)) end
  return b
 end
 return p
end
-- Pose the user's own cloned R6/R15 rig with its real joints and limb lengths.
local channelFor={
 RootJoint=1,Root=1,RightShoulder=2,["Right Shoulder"]=2,
 LeftShoulder=3,["Left Shoulder"]=3,RightHip=4,["Right Hip"]=4,
 LeftHip=5,["Left Hip"]=5,Neck=6
}
local bodyNames={
 Torso=true,Head=true,["Right Arm"]=true,["Left Arm"]=true,["Right Leg"]=true,["Left Leg"]=true,
 UpperTorso=true,LowerTorso=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
 LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
 LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true
}
local function cloneRig(char)
 if not char or not char:FindFirstChildOfClass("Humanoid") then return nil end
 local old=char.Archivable
 local ok,model=pcall(function() char.Archivable=true;return char:Clone() end)
 char.Archivable=old
 if not ok or not model then return nil end
 local root=model:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then model:Destroy();return nil end
 local humanoid=model:FindFirstChildOfClass("Humanoid")
 if not humanoid then model:Destroy();return nil end
 local kind=if humanoid.RigType==Enum.HumanoidRigType.R15 then "R15" else "R6"
 local parts,body,original,localCF,decals={},{},{},{},{}
 for _,obj in model:GetDescendants() do
  if not obj.Parent then continue end
  if obj:IsA("LuaSourceContainer") or obj:IsA("Animator") or obj:IsA("AnimationController") or obj:IsA("Tool") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Highlight") or obj:IsA("Sound") then
   obj:Destroy()
  elseif obj:IsA("Decal") or obj:IsA("Texture") then
   table.insert(decals,{object=obj,transparency=obj.Transparency})
  elseif obj:IsA("BasePart") then
   obj.Anchored=true;obj.CanCollide=false;obj.CanTouch=false;obj.CanQuery=false;obj.CastShadow=false;obj.LocalTransparencyModifier=0
   if obj==root then obj.Transparency=1 end
   table.insert(parts,obj);original[obj]=obj.Transparency;localCF[obj]=root.CFrame:ToObjectSpace(obj.CFrame)
   if obj.Parent==model and bodyNames[obj.Name] then table.insert(body,obj) end
  end
 end
 if #body<6 then model:Destroy();return nil end
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 local adjacency={}
 local function attach(p,e) adjacency[p]=adjacency[p] or {};table.insert(adjacency[p],e) end
 for _,j in model:GetDescendants() do
  if j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("ManualWeld") or j:IsA("WeldConstraint") then
   local a,b=j.Part0,j.Part1
   if a and b and localCF[a] and localCF[b] then
    local constraint=j:IsA("WeldConstraint")
    local e={p0=a,p1=b,joint=j,c0=if constraint then a.CFrame:ToObjectSpace(b.CFrame) else j.C0,c1=if constraint then CFrame.identity else j.C1,channel=if j:IsA("Motor6D") then channelFor[j.Name] else nil}
    if j:IsA("Motor6D") then j.Transform=CFrame.identity end
    attach(a,e);attach(b,e)
   end
  end
 end
 local queue={root};local seen={[root]=true};local owner={[root]=root};local links={};local index=1
 while index<=#queue do
  local a=queue[index];index+=1
  for _,e in adjacency[a] or {} do
   local forward=e.p0==a;local b=if forward then e.p1 else e.p0
   if not seen[b] then
    seen[b]=true;owner[b]=if b.Parent==model and bodyNames[b.Name] then b else owner[a]
    table.insert(queue,b);table.insert(links,{edge=e,forward=forward,from=a,to=b})
   end
  end
 end
 -- A disconnected accessory retains its matching attachment if possible.
 local attachByName={}
 for _,b in body do
  for _,at in b:GetChildren() do if at:IsA("Attachment") then attachByName[at.Name]=at end end
 end
 local detached={}
 for _,b in parts do
  if not seen[b] then
   local parent=root;local offset=localCF[b]
   for _,at in b:GetChildren() do
    if at:IsA("Attachment") and attachByName[at.Name] then
     local target=attachByName[at.Name];parent=target.Parent;offset=target.CFrame*at.CFrame:Inverse();break
    end
   end
   owner[b]=if b.Parent==model and bodyNames[b.Name] then b else parent
   table.insert(detached,{part=b,parent=parent,offset=offset})
  end
 end
 local followers={}
 for _,b in parts do
  local o=owner[b]
  if o and o~=b and o~=root then table.insert(followers,{part=b,owner=o}) end
 end
 model.Name="MotionStudioAvatar"
 return {model=model,root=root,kind=kind,parts=parts,body=body,original=original,links=links,detached=detached,owner=owner,followers=followers,decals=decals}
end
local function avatarPose(r,p,O,intensity)
 local cf={[r.root]=CFrame.identity};local pivots={}
 local jointsCF={}
 for i=1,6 do jointsCF[i]=CFrame.new(p[i].v*O*intensity)*qframe(qslerp(ident,p[i].q,intensity)) end
 for _,link in r.links do
  local e=link.edge;local motion=CFrame.identity
  if e.channel then
   local basis=e.c0.Rotation
   local scale=math.clamp(e.p0.Size.Y/2,.5,1.7)
   local poseCF=jointsCF[e.channel]
   motion=basis:Inverse()*CFrame.new(poseCF.Position*scale)*poseCF.Rotation*basis
  end
  local offset=e.c0*motion*e.c1:Inverse()
  cf[link.to]=cf[link.from]*(if link.forward then offset else offset:Inverse())
  if e.channel then
   local parentCF=cf[e.p0]
   if parentCF then pivots[e.channel]=(parentCF*e.c0*motion).Position end
  end
 end
 for _,v in r.detached do cf[v.part]=(cf[v.parent] or CFrame.identity)*v.offset end
 return cf,pivots
end
local function bottom(cf,s)
 return cf.Position.Y-(math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)/2
end
local function part(parent,name,size,color)
 return U.new("Part",{Name=name,Size=size,Color=color,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.SmoothPlastic},parent)
end
-- Only confirmed editor settings enter the shared settings bank.
-- Playback position and pause are transport commands, never autosaved.
local previewKeys={"state","auto","speed","adaptive","previewVelocity","origin","pitch","yaw","roll","cam","zoom","height","props","grid","joints"}
local liveKeys={pack="walkStyle",enabled="walkAnimation",intensity="walkIntensity",aura="aura",trail="trail",auraRate="auraRate",trailLife="trailLife",auraColor="auraColor"}
local limits={speed={.25,2},previewVelocity={0,40},origin={0,150},pitch={-360,360},yaw={-360,360},roll={-360,360},cam={-180,180},zoom={.65,1.5},height={0,1.5}}
local function defaults(pack)
 return {state="Run",auto=false,speed=1,adaptive=true,previewVelocity=16,packRates={},origin=100,pitch=if pack=="Godly Aura" then 9 else 0,yaw=0,roll=0,cam=45,zoom=1,height=0,props=true,grid=true,joints=false}
end
local function readSaved(settings)
 local out=defaults(settings.walkStyle)
 for key,k in liveKeys do out[key]=settings[k] end
 local raw=settings.motionStudioConfig
 if type(raw)=="string" and raw~="" then
  local ok,data=pcall(function() return Http:JSONDecode(raw) end)
  if ok and type(data)=="table" then
   for _,key in previewKeys do
    local v=data[key];local d=out[key];local lim=limits[key]
    if lim and type(v)=="number" and v==v and v>=lim[1] and v<=lim[2] then out[key]=v
    elseif type(d)=="boolean" and type(v)=="boolean" then out[key]=v
    elseif key=="state" and table.find({"Idle","Walk","Run","Climb","Fall","Jump","Swim"},v) then out[key]=v end
   end
   if type(data.packRates)=="table" then
    for name,value in data.packRates do
     if extra[name] and type(value)=="number" and value==value and value>=.25 and value<=2 and math.abs(value-1)>1e-7 then out.packRates[name]=value end
    end
   elseif out.speed~=1 then out.packRates[out.pack]=out.speed end
   out.speed=out.packRates[out.pack] or 1
  end
 end
 return out
end
-- Shared pose evaluator for the editor and authorized local avatar animation.
function M.runtimeSettings(settings)
 local saved=readSaved(settings)
 return {style=saved.pack,speed=saved.speed,adaptive=saved.adaptive,origin=saved.origin/100,intensity=math.clamp(saved.intensity/100,0,1),props=saved.props}
end
-- Speed scales cadence only, never WalkSpeed, velocity or movement physics.
function M.speedFactor(config,state,velocity)
 if not config.adaptive then return 1 end
 local name=config.style or config.pack or "Natural"
 local p=profile(name)
 local reference
 if state=="Walk" or state=="Run" then
  local stride=math.clamp(p.stride/.24,.7,1.3)
  local cadence=math.clamp(p.cadence/7.5,.75,1.25)
  reference=(if state=="Run" then 16 else 8)*math.clamp(stride*cadence,.68,1.35)
 elseif state=="Climb" then reference=5
 elseif state=="Swim" then reference=8
 else return 1 end
 local low=if state=="Swim" then .28 elseif state=="Climb" then 0 else .12
 return math.clamp(math.max(0,velocity or reference)/reference,low,3)
end
function M.runtimePose(config,t,state,airTime)
 local name=config.style
 local p,spin=pose(name,t,state),0
 local airborne=state=="Jump" or state=="Fall"
 if name=="Harpy Glide" and airborne then
  -- One authored flip per real jump, with a continuous clock into freefall.
  p,spin=harpy(math.min(.30+math.max(0,airTime)*2.2,1.62))
 end
 local result={}
 for i,key in joints do
  result[key]=CFrame.new(p[i].v*config.origin*config.intensity)*qframe(qslerp(ident,p[i].q,config.intensity))
 end
 local tilt=if name=="Godly Aura" then 9 else 0
 if name=="Cartwheel Flow" and (state=="Walk" or state=="Run") then
  result.Root=angle(0,0,t*240)*result.Root
 else
  result.Root=angle(spin+tilt,0,0)*result.Root
 end
 local hover=if name=="Godly Aura" then .18+.045*math.sin(t*tau/3.6) else (profile(name).hover or 0)
 if name=="Harpy Glide" then hover=0 end
 if name=="Skater" then hover=if config.props and not airborne then .40 else 0 end
 if state=="Climb" or state=="Swim" then hover=0 end
 if (state=="Walk" or state=="Run") and families[name]=="hop" then
  hover+=profile(name).bob*math.abs(math.sin(t*profile(name).cadence))
 end
 return result,hover*config.intensity
end
local function differences(draft,saved)
 local n=0
 for _,k in previewKeys do
  local x,y=draft[k],saved[k]
  if type(x)=="number" and type(y)=="number" then
   if math.abs(x-y)>1e-7 then n+=1 end
  elseif x~=y then n+=1 end
 end
 for k in liveKeys do if draft[k]~=saved[k] then n+=1 end end
 for name in extra do if name~=draft.pack and math.abs((draft.packRates[name] or 1)-(saved.packRates[name] or 1))>1e-7 then n+=1 end end
 return n
end
local function buildPatch(draft)
 local p,config={},{}
 for k,name in liveKeys do p[name]=Schema.value(name,draft[k]) end
 for _,k in previewKeys do config[k]=draft[k] end
 config.packRates=table.clone(draft.packRates)
 config.packRates[draft.pack]=if math.abs(draft.speed-1)>1e-7 then draft.speed else nil
 p.motionStudioConfig=Http:JSONEncode(config)
 return p
end
function M.mount(ui,a)
 local scope=ui.page
 local frame=ui:row(340,"MotionStudioViewport")
 local view=U.new("ViewportFrame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(26,24,36),BorderSizePixel=0,Ambient=Color3.fromRGB(155,147,174),LightColor=Color3.fromRGB(247,240,255),LightDirection=V(-1,-1,-.6),Active=true},frame);U.corner(view,10)
 local world=U.new("WorldModel",{},view)
 local camera=U.new("Camera",{FieldOfView=35},view);view.CurrentCamera=camera
 local rigData=nil;local avatarStatus="Loading avatar..."
 local player=game:GetService("Players").LocalPlayer
 local violet=Color3.fromRGB(186,153,243)
 local avatarSize=V(4,5,2)
 local floor=part(world,"Floor",V(14,.14,14),Color3.fromRGB(46,47,57));floor.CFrame=CFrame.new(0,-.075,0)
 local lines={}
 for i=-7,7 do
  table.insert(lines,part(world,"Grid",V(.018,.012,14),Color3.fromRGB(69,67,82)));lines[#lines].CFrame=CFrame.new(i,.006,0)
  table.insert(lines,part(world,"Grid",V(14,.012,.018),Color3.fromRGB(69,67,82)));lines[#lines].CFrame=CFrame.new(0,.006,i)
 end
 local markers={};for i=2,6 do local p=part(world,"Origin",V(.14,.14,.14),violet);p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon;p.Transparency=1;markers[i]=p end
 local props=Props.new(world)
 local fxDots,fxTrail={},{}
 for i=1,20 do
  local p=part(world,"PreviewAura",V(.09,.09,.09),violet);p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon;p.Transparency=1;fxDots[i]=p
 end
 for i=1,12 do
  local p=part(world,"PreviewTrail",V(.05,.05,.05),violet);p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon;p.Transparency=1;fxTrail[i]=p
 end
 local caption=U.label(frame,"",12,UDim2.fromOffset(12,8),UDim2.new(1,-108,0,22))
 local fpsLabel=U.label(frame,"-- FPS",11,UDim2.new(1,-85,0,8),UDim2.fromOffset(74,22));fpsLabel.TextXAlignment=Enum.TextXAlignment.Right
 local status=U.label(frame,"",11,UDim2.fromOffset(12,32),UDim2.new(1,-24,0,18));status.TextColor3=violet
 local s=readSaved(a.s)
 s.t=0;s.seek=0;s.paused=false
 local dirty=true;local updates={};local sliding=nil;local oldScroll=nil
 local function mark() dirty=true end
 local function sync() dirty=true;s.seek=s.t%2.8;for _,f in updates do f() end;ui:sync() end
 local actionRows={}
 local selection=ui:note("",50)
 local function updateSelection()
  local saved=readSaved(a.s)
  local n=differences(s,saved)
  local ready=rigData~=nil
  for _,row in actionRows do
   row.confirm.Text=if not ready then "AVATAR NOT READY" elseif n==0 then "SAVED ✓" else "CONFIRM ALL ("..tostring(n)..")"
   row.confirm.Active=ready and n>0;row.confirm.AutoButtonColor=ready and n>0
   row.confirm.BackgroundColor3=if ready and n>0 then Color3.fromRGB(106,74,158) else Color3.fromRGB(49,43,62)
   row.cancel.Text=if n>0 then "CANCEL" else "NO CHANGES";row.cancel.Active=n>0;row.cancel.AutoButtonColor=n>0
  end
  selection.Text="Preview: "..s.pack.." / Saved: "..saved.pack.." · "..(if n==0 then "All settings saved" else tostring(n).." unsaved changes")..(if rigData and rigData.kind=="R15" then " · R15 adapted poses" else "")
 end
 local function confirmAll()
  if not rigData or differences(s,readSaved(a.s))==0 then return end
  a:patch(buildPatch(s))
  sync();ui:message("Motion Studio settings saved")
 end
 local function cancelAll()
  local saved=readSaved(a.s)
  for k,v in saved do s[k]=v end
  s.t=0;s.seek=0;s.paused=false
  sync();ui:message("All unconfirmed changes discarded")
 end
 local function actionRow()
  ui.sc.Size=UDim2.new(1,0,1,-50)
  local row=scope:add(U.frame(ui.pageBox,"ConfirmAllMotionStudio",UDim2.new(0,0,1,-44),UDim2.new(1,-8,0,44),Color3.fromRGB(34,27,53),.05));U.corner(row,8);row.ZIndex=5
  local confirm=U.button(row,"CONFIRM ALL")
  confirm.Position=UDim2.fromOffset(4,4);confirm.Size=UDim2.new(.65,-8,1,-8)
  local cancel=U.button(row,"CANCEL")
  cancel.Position=UDim2.new(.65,0,0,4);cancel.Size=UDim2.new(.35,-4,1,-8)
  table.insert(actionRows,{confirm=confirm,cancel=cancel})
  scope:on(confirm.Activated,function() ui:action(confirmAll) end)
  scope:on(cancel.Activated,function() ui:action(cancelAll) end)
  updateSelection()
 end
 actionRow()
 ui:watch(updateSelection)
 local function stopSlide()
  sliding=nil
  if oldScroll~=nil and ui.sc and ui.sc.Parent then ui.sc.ScrollingEnabled=oldScroll end
  oldScroll=nil
 end
 scope:add(stopSlide)
 local function slider(label,min,max,step,key,format,onChange)
  local row=ui:row(54,"MotionStudioSlider")
  local text=U.label(row,label,12,UDim2.fromOffset(10,3),UDim2.new(.65,-10,0,22))
  local val=U.label(row,"",12,UDim2.new(.65,0,0,3),UDim2.new(.35,-10,0,22));val.TextXAlignment=Enum.TextXAlignment.Right;val.TextColor3=violet
  local track=U.new("TextButton",{Text="",AutoButtonColor=false,Active=true,BackgroundColor3=Color3.fromRGB(60,51,77),BorderSizePixel=0,Position=UDim2.fromOffset(10,30),Size=UDim2.new(1,-20,0,16)},row);U.corner(track,8)
  local fill=U.frame(track,"Fill",nil,UDim2.fromScale(0,1),violet,0);U.corner(fill,8)
  local function update()
   local n=math.clamp(s[key],min,max);fill.Size=UDim2.fromScale((n-min)/(max-min),1);val.Text=format(n)
  end
  updates[#updates+1]=update;update()
  local function move(x)
   local k=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
   s[key]=math.clamp(math.round((min+math.floor(k*(max-min)/step+.5)*step)*1000)/1000,min,max)
   if onChange then onChange() end;update();mark();updateSelection()
  end
  scope:on(track.InputBegan,function(input)
   if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
   stopSlide();sliding={input=input,move=move};if ui.sc and ui.sc.Parent then oldScroll=ui.sc.ScrollingEnabled;ui.sc.ScrollingEnabled=false end;move(input.Position.X)
  end)
  return update
 end
 scope:on(Input.InputChanged,function(input)
  if not sliding then return end
  if input==sliding.input or (sliding.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then sliding.move(input.Position.X) end
 end)
 scope:on(Input.InputEnded,function(input)
  if sliding and (input==sliding.input or input.UserInputType==Enum.UserInputType.MouseButton1) then stopSlide() end
 end)
 local function percent(v) return string.format("%d%%",math.floor(v+.5)) end
 local function degrees(v) return string.format("%d°",math.floor(v+.5)) end
 local function decimal(v) return string.format("%.2f",v) end
 ui:title("TIMELINE · 60 FPS TARGET")
 local timeline=slider("Time",0,2.8,.001,"seek",function(v) return string.format("%.2f / 2.80 s",v) end,function() s.paused=true;s.t=math.min(s.seek,2.8-.000001) end)
 ui:chips({"Play","Pause","Replay","+1 frame"},function(n)
  if n=="Play" then s.paused=false elseif n=="Pause" then s.paused=true elseif n=="Replay" then s.t=0;s.paused=false else s.paused=true;s.t+=1/60 end;sync()
 end,4,function() return if s.paused then "Pause" else "Play" end)
 ui:chips({"Idle","Walk","Run","Climb","Fall","Jump","Swim"},function(n)
  s.state=n;s.auto=false;s.t=0
  s.previewVelocity=if n=="Walk" then 8 elseif n=="Run" then 16 elseif n=="Climb" then 5 elseif n=="Swim" then 8 else 0
  sync()
 end,4,function() return s.state end)
 ui:chips({"Jump / Fall / Land","Manual"},function(n) s.auto=n~="Manual";s.t=0;sync() end,2,function() return if s.auto then "Jump / Fall / Land" else "Manual" end)
 ui:title("ANIMATION PACKS · 44")
 local order={"Natural","Heroic","Bouncy","Floating","Glide","Ethereal"};for _,n in Packs.order do table.insert(order,n) end
 ui:chips(order,function(n)
  s.packRates[s.pack]=if math.abs(s.speed-1)>1e-7 then s.speed else nil
  s.pack=n;s.speed=s.packRates[n] or 1;s.enabled=true;s.t=0;s.pitch=if n=="Godly Aura" then 9 else 0;s.yaw=0;s.roll=0;sync()
 end,3,function() return s.pack end)
 ui:chips({"Animation on","Animation off"},function(n) s.enabled=n=="Animation on";sync() end,2,function() return if s.enabled then "Animation on" else "Animation off" end)
 ui:title("PLAYBACK & CAMERA")
 ui:chips({"Adaptive speed","Fixed speed"},function(n) s.adaptive=n=="Adaptive speed";sync() end,2,function() return if s.adaptive then "Adaptive speed" else "Fixed speed" end)
 slider("Pack speed multiplier",.25,2,.05,"speed",function(v) return string.format("%.2fx",v) end,function()
  s.packRates[s.pack]=if math.abs(s.speed-1)>1e-7 then s.speed else nil
 end)
 slider("Preview movement speed (stud/s)",0,40,1,"previewVelocity",function(v) return string.format("%.0f",v) end)
 local speedInfo=ui:note("",35)
 slider("Camera orbit",-180,180,1,"cam",degrees)
 slider("Zoom",.65,1.5,.05,"zoom",decimal)
 slider("Origin Motion",0,150,5,"origin",percent)
 slider("Intensity",0,100,1,"intensity",percent,updateSelection)
 slider("Extra levitation",0,1.5,.02,"height",decimal)
 ui:title("FULL BODY ROTATION")
 slider("Pitch / X",-360,360,1,"pitch",degrees)
 slider("Yaw / Y",-360,360,1,"yaw",degrees)
 slider("Roll / Z",-360,360,1,"roll",degrees)
 ui:chips({"Zero rotation","Default pose"},function(n) s.pitch=if n=="Default pose" and s.pack=="Godly Aura" then 9 else 0;s.yaw=0;s.roll=0;sync() end,2)
 ui:title("VIEWPORT")
 local function switch(label,key)
  ui:chips({label.." on",label.." off"},function(n) s[key]=n==label.." on";sync() end,2,function() return label..(if s[key] then " on" else " off") end)
 end
 switch("Props","props");switch("Grid","grid");switch("Origins","joints")
 ui:title("CHARACTER EFFECTS · PREVIEW")
 switch("Aura","aura");switch("Trail","trail")
 slider("Aura emission / second",1,45,1,"auraRate",function(v) return tostring(math.round(v)) end)
 slider("Trail lifetime (ms)",80,1300,10,"trailLife",function(v) return tostring(math.round(v)) end)
 local colorBox=ui:box("Aura / trail color (HEX)",s.auraColor,34,function(value)
  local hex=string.upper((value:gsub("^#","")))
  s.auraColor=Schema.value("auraColor",hex);sync()
 end)
 ui:watch(function() if not colorBox:IsFocused() then colorBox.Text=s.auraColor end end)
 ui:chips({"Reset editor"},function()
  local rates=s.packRates
  for k,v in defaults(s.pack) do s[k]=v end
  s.packRates=rates;s.packRates[s.pack]=nil
  s.t=0;s.seek=0;s.paused=false;sync()
 end,1)
 ui:note("Confirm All saves the pack, intensity, animation speed and origins. Camera, manual rotation and extra levitation remain preview-only.",64)
 local function visible(b)
  local r=rigData
  if not r or b==r.root then return false end
  local o=r.owner[b] or b
  if s.pack=="Floating Head" then return o.Name=="Head" end
  if s.pack=="Headless Float" then return o.Name~="Head" end
  return true
 end
 local function render()
  local t=s.t;local cy=t%2.8;local name=s.pack;local state=s.state;local lt=t
  if s.auto then state=if cy<1.2 then "Jump" elseif cy<2.4 then "Fall" else "Run";lt=if cy<1.2 then cy elseif cy<2.4 then cy-1.2 else cy-2.4 end
  local special=name=="Harpy Glide" and (s.state=="Jump" or s.auto)
  local spin,h,phase=0,0,state;local p
  if special then p,spin,h,phase=harpy(t);state=if cy<1.62 then "Jump" elseif cy<2.35 then "Fall" else "Land" else p=pose(name,lt,state) end
  local air=state=="Jump" or state=="Fall"
  local O,I=s.origin/100,s.intensity/100
  local r=rigData
  if not r then
   for _,b in fxDots do b.Transparency=1 end;for _,b in fxTrail do b.Transparency=1 end
   for _,b in markers do b.Transparency=1 end
   caption.Text="YOUR AVATAR";status.Text=avatarStatus;dirty=false;return
  end
  local cf,pivots=avatarPose(r,p,O,I)
  for _,b in r.parts do
   b.CFrame=cf[b] or CFrame.identity
   b.Transparency=if visible(b) then r.original[b] else 1
  end
  for _,d in r.decals do
   local parent=d.object.Parent
   d.object.Transparency=if parent and visible(parent) then d.transparency else 1
  end
  -- Real R6 props are positioned before the global rigid-body rotation.
  local model=r.model
  local follow={}
  for i,v in r.followers do follow[i]=v.owner.CFrame:ToObjectSpace(v.part.CFrame) end
  if r.kind=="R6" and (state=="Idle" or state=="Walk" or state=="Run") and ((name=="Skater" and s.props) or (name=="Harpy Glide" and not special)) then
   local left,right=model:FindFirstChild("Left Leg"),model:FindFirstChild("Right Leg")
   if left and right then
    local l=math.min(bottom(left.CFrame,left.Size),bottom(right.CFrame,right.Size))
    for _,b in {left,right} do b.CFrame+=V(0,l-bottom(b.CFrame,b.Size),0) end
   end
  end
  if s.props then props:update(model,name,t*4,if state=="Climb" then Enum.HumanoidStateType.Climbing elseif state=="Swim" then Enum.HumanoidStateType.Swimming elseif state=="Fall" then Enum.HumanoidStateType.Freefall elseif state=="Jump" then Enum.HumanoidStateType.Jumping else Enum.HumanoidStateType.Running) else props:clear() end
  for i,v in r.followers do v.part.CFrame=v.owner.CFrame*follow[i] end
  local rotation=angle(s.pitch,s.yaw,s.roll)*angle(spin,0,0)
  if name=="Cartwheel Flow" and (state=="Walk" or state=="Run") then rotation*=angle(0,0,lt*240) end
  local center=if model:FindFirstChild("Torso") then model.Torso.Position elseif model:FindFirstChild("UpperTorso") then model.UpperTorso.Position else r.root.Position
  local transform=CFrame.new(center)*rotation*CFrame.new(-center)
  local all={};local support=math.huge
  for _,b in r.parts do table.insert(all,b);b.CFrame=transform*b.CFrame end
  for _,b in r.body do if visible(b) then support=math.min(support,bottom(b.CFrame,b.Size)) end end
  if props.root then for _,b in props.root:GetDescendants() do if b:IsA("BasePart") then table.insert(all,b);b.CFrame=transform*b.CFrame;support=math.min(support,bottom(b.CFrame,b.Size)) end end end
  if support==math.huge then support=0 end
  local gap=(profile(name).hover or 0)+s.height
  if name=="Godly Aura" then gap=.18+.045*math.sin(t*tau/3.6)+s.height end
  if name=="Harpy Glide" then gap=s.height end
  if state=="Climb" or state=="Swim" then gap=.65+s.height end
  if name=="Floating Head" then gap+=4 end
  if not special and air then local u=lt%1.2/1.2;gap+=if state=="Jump" then 1.65*math.sin(math.pi*u/(if s.auto then 2 else 1)) else 1.65*(1-u*u) end
  if (state=="Walk" or state=="Run") and families[name]=="hop" then gap+=profile(name).bob*math.abs(math.sin(t*profile(name).cadence)) end
  local dy=gap-support
  if special then
   local fixed=math.huge;local g=avatarPose(r,ground,O,I)
   for _,b in r.body do if g[b] then fixed=math.min(fixed,bottom(g[b],b.Size)) end end
   if fixed==math.huge then fixed=support end
   local k=ease(h/1.2);dy=gap+h-(1-k)*support-k*fixed
  end
  local lift=V(0,dy,0)
  for _,b in all do b.CFrame+=lift end
  -- Viewport-compatible visual approximation; no live emitters or trails are changed.
  local torso=model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or r.root
  local color=Color3.fromHex(s.auraColor)
  local count=math.clamp(math.floor(s.auraRate*.44+.5),1,#fxDots)
  for i,b in fxDots do
   b.Transparency=if s.aura and i<=count then .18+.55*((t*.65+i/count)%1) else 1
   if s.aura and i<=count then
    local u=(t*.65+i/count)%1;local th=i*2.39996+t*1.4
    b.Color=color;b.Position=torso.CFrame:PointToWorldSpace(V(math.cos(th)*(1.45+.25*u),-1.8+u*3.6,math.sin(th)*(1.1+.35*u)))
   end
  end
  for i,b in fxTrail do
   local u=i/#fxTrail;b.Transparency=if s.trail then .18+.78*u else 1
   if s.trail then
    local len=.4+3*s.trailLife/1300
    b.Color=color;b.Size=Vector3.one*(.16*(1-u)+.025)
    b.Position=torso.CFrame:PointToWorldSpace(V(.28*math.sin(t*7-u*5),-.9-.3*u,.65+len*u))
   end
  end
  for i,b in markers do
   local pos=pivots[i]
   if pos then b.Position=transform:PointToWorldSpace(pos)+lift end
   b.Transparency=if s.joints and pos then 0 else 1
  end
  for i,b in lines do b.Transparency=if s.grid then 0 else 1;if i%2==0 then b.CFrame=CFrame.new(0,.006,math.floor((i-1)/2)-7+(if state=="Idle" or air or special then 0 else (lt*(if state=="Run" then 4 else 2))%1)) end end
  local a=math.rad(s.cam);local scale=math.clamp(avatarSize.Y/5,.7,2.5);local focus=V(0,(if special then 4 else 3.1+(if air then .4 else 0))*scale,0)
  local aspect=math.max(.2,view.AbsoluteSize.X/math.max(1,view.AbsoluteSize.Y));local dist=math.max(if special then 17.5 else 12.6,(if special then 11 else 8)/aspect)*math.max(scale,math.clamp(avatarSize.X/4,.8,2.5))/s.zoom
  if name=="Doll Walk" then dist*=1.15 end
  camera.CFrame=CFrame.lookAt(focus+V(math.sin(a)*dist,2.1,-math.cos(a)*dist),focus)
  caption.Text=string.upper(name).." · "..player.DisplayName;status.Text=r.kind.." / "..string.upper(state).." / "..phase
  dirty=false
 end
 -- Refresh only when the local avatar or appearance changes.
 local generation=0;local charScope=nil
 local function clearAvatar()
  props:clear()
  if rigData then rigData.model:Destroy();rigData=nil end
  updateSelection();mark()
 end
 local function refresh(char)
  generation+=1;local ticket=generation
  task.delay(.18,function()
   if scope.dead or ticket~=generation or char~=player.Character or not char then return end
   local ok,new=pcall(cloneRig,char)
   if not ok or not new then
    if not rigData then avatarStatus="Avatar unavailable · refresh or respawn";mark() end
    return
   end
   clearAvatar();rigData=new
   new.model.Parent=world
   local neutralCF=avatarPose(new,neutral,1,1)
   for _,b in new.parts do b.CFrame=neutralCF[b] or CFrame.identity end
   local _,size=new.model:GetBoundingBox()
   avatarSize=V(math.clamp(size.X,2,10),math.clamp(size.Y,3,10),math.clamp(size.Z,1,10))
   updateSelection();mark()
  end)
 end
 local function bind(char)
  if charScope then charScope:clear();charScope=nil end
  generation+=1;avatarStatus="Loading avatar...";clearAvatar()
  if not char then return end
  charScope=U.scope()
  local function appearance(obj)
   if obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") or obj:IsA("BasePart") or obj:IsA("Humanoid") or obj:IsA("Decal") or obj:IsA("CharacterMesh") or obj:IsA("SurfaceAppearance") or obj:IsA("Motor6D") then refresh(char) end
  end
  charScope:on(char.DescendantAdded,appearance);charScope:on(char.DescendantRemoving,appearance)
  refresh(char)
 end
 scope:on(player.CharacterAdded,bind)
 scope:on(player.CharacterRemoving,function() bind(nil) end)
 scope:on(player.CharacterAppearanceLoaded,function(char) if char==player.Character then refresh(char) end end)
 ui:chips({"Refresh avatar"},function() refresh(player.Character) end,1)
 scope:add(function() generation+=1;if charScope then charScope:clear();charScope=nil end;props:clear();if rigData then rigData.model:Destroy();rigData=nil end end)
 bind(player.Character)
 local frames,elapsed=0,0;local previous=0
 scope:on(view:GetPropertyChangedSignal("AbsoluteSize"),mark)
 scope:on(Run.RenderStepped,function(dt)
  if scope.dead or not ui.opened or ui.tab~="Character" then return end
  elapsed+=dt
  local factor=M.speedFactor(s,s.state,s.previewVelocity)
  if s.auto then factor=1 end
  if not s.paused then s.t+=math.min(dt,.1)*s.speed*factor;dirty=true end
  if dirty then render();frames+=1 end
  if elapsed>=.75 then fpsLabel.Text=if s.paused then "PAUSED" else string.format("%.0f FPS",frames/elapsed);frames=0;elapsed=0 end
  previous+=dt;if previous>=1/20 then s.seek=s.t%2.8;timeline();speedInfo.Text=string.format("Effective speed %.2fx · %s",s.speed*factor,if s.adaptive then "Adaptive" else "Fixed");previous=0 end
 end)
 scope:add(function() props:clear() end)
 render()
end
return M
