-- Deliberately bounded HUD dialect. Parse data into an AST; never compile user strings as Roblox scripts.
local S=require(script.Parent.Schema)
local C={}
local api={widget=4,animate=2,setGlow=2,indicator=1,theme=1,join=2}
local precedence={['or']=1,['and']=2,['==']=3,['~=']=3,['<']=3,['>']=3,['<=']=3,['>=']=3,['..']=4,['+']=5,['-']=5,['*']=6,['/']=6,['%']=6}
local function lex(source)
 assert(type(source)=="string" and #source<=8192,"Source limit: 8192 bytes");local t={};local i,line=1,1
 while i<=#source do local c=source:sub(i,i);local rest=source:sub(i);local val,kind,n
  if c:match("%s") then if c=="\n" then line+=1 end;i+=1;continue elseif rest:sub(1,2)=="--" then i=source:find("\n",i,true) or #source+1;continue
  elseif c=='"' or c=="'" then local s="";local j=i+1;while j<=#source and source:sub(j,j)~=c do local ch=source:sub(j,j);if ch=="\\" then j+=1;ch=source:sub(j,j);ch=({n="\n",t="\t",r="\r"})[ch] or ch end;s..=ch;j+=1 end;assert(j<=#source,"Line "..line..": unterminated string");assert(#s<=256,"Literal exceeds 256 bytes");val,kind,n=s,"lit",j-i+1
  elseif c:match("[%a_]") then val=rest:match("^[%a_][%w_]*");kind="id";n=#val
  elseif c:match("%d") then local s=rest:match("^%d+%.%d+") or rest:match("^%d+");val,kind,n=tonumber(s),"lit",#s
  else val=rest:sub(1,2);if not precedence[val] then val=c end;assert(precedence[val] or string.find("().,=;",val,1,true),"Line "..line..": unsupported token "..val);kind="op";n=#val end
  table.insert(t,{v=val,k=kind,line=line});assert(#t<2048,"Program too large");i+=n
 end;table.insert(t,{v="<eof>",k="end",line=line});return t
end
function C.compile(source)
 local tok=lex(source);local at=1;local depth=0;local handlers={};local expr,block
 local function enter() depth+=1;assert(depth<=36,"Nesting limit") end
 local function err(msg) error("Line "..tok[at].line..": "..msg,0) end
 local function is(s) return tok[at].k~="lit" and tok[at].v==s end
 local function take(s) if is(s) then at+=1;return true end;return false end
 local function want(s) if not take(s) then err("expected "..s) end end
 local function ident() local t=tok[at];if t.k~="id" then err("expected a name") end;at+=1;return t.v end
 local function call() want(".");local k=ident();if not api[k] then err("unknown hud."..k) end;want("(");local args={};if not is(")") then repeat table.insert(args,expr(1)) until not take(",") end;want(")");if #args~=api[k] then err("wrong argument count for hud."..k) end;return {"call",k,args} end
 expr=function(min)
  enter();local t=tok[at];local n;if t.k=="lit" then at+=1;n={"lit",t.v} elseif take("true") then n={"lit",true} elseif take("false") then n={"lit",false} elseif take("(") then n=expr(1);want(")") elseif take("-") then n={"neg",expr(7)} elseif take("not") then n={"not",expr(7)} else local k=ident();n=if k=="hud" then call() else {"var",k} end
  while true do local op=tok[at];local rank=if op.k~="lit" then precedence[op.v] else nil;if not rank or rank<min then break end;at+=1;n={"bin",op.v,n,expr(rank+1)} end;depth-=1;return n
 end
 block=function(top)
  enter();local body={};while not(is("<eof>") or is("end") or is("else") or is("elseif")) do
   if take(";") then continue elseif take("function") then local k=ident();if not top or handlers[k] or (k~="onHealthChanged" and k~="onEvent") then err("invalid event handler") end;want("(");local a=ident();want(",");local b=ident();want(")");handlers[k]={a,b,block(false)};want("end")
   elseif take("if") then local branches={};repeat local test=expr(1);want("then");table.insert(branches,{test,block(false)}) until not take("elseif");local fallback=if take("else") then block(false) else {};want("end");table.insert(body,{"if",branches,fallback})
   else local loc=take("local");local k=ident();if k=="hud" and not loc then table.insert(body,call()) else want("=");table.insert(body,{"assign",k,expr(1)}) end end
  end;depth-=1;return body
 end
 local main=block(true);want("<eof>");return {main=main,events=handlers}
end
function C.start(source,grants)
 local program=C.compile(source);local vm={widgets={},overrides={},running=true};local base={};local steps=0;local eval,exec
 local function tick() steps+=1;assert(steps<=1500,"Callback operation budget exceeded") end
 local function text(v,n) assert(type(v)=="string" or type(v)=="number","Expected text");v=tostring(v);assert(#v<=n,"Text limit exceeded");return v end
 local function num(n,lo,hi) assert(type(n)=="number" and n>=lo and n<=hi,"Numeric value out of range");return n end
 local function invoke(k,a)
  if k=="join" then return text(text(a[1],128)..text(a[2],128),128) end
  if k=="widget" or k=="animate" then assert(grants.widgets,"Grant Widgets permission");local id=text(a[1],32);assert(#id>0,"Empty widget ID");if k=="widget" then local n=0;for _ in vm.widgets do n+=1 end;assert(vm.widgets[id] or n<8,"Widget limit: 8");vm.widgets[id]={text=text(a[2],128),x=num(a[3],0,100),y=num(a[4],0,100),animation=if vm.widgets[id] then vm.widgets[id].animation else "none"}
   else assert(vm.widgets[id] and table.find({"none","pulse","float"},a[2]),"Expected widget and motion name");vm.widgets[id].animation=a[2] end
  else assert(grants.appearance,"Grant Appearance permission");if k=="setGlow" then assert(a[1]=="heart","Expected heart");vm.overrides.rim=math.round(num(a[2],0,100)) elseif k=="indicator" then local target=text(a[1],32):lower();local found;for _,s in S.shapes do if s:lower()==target then found=s;break end end;assert(found,"Unknown indicator");vm.overrides.shape=found elseif k=="theme" then local label=text(a[1],16);local theme=S.presets.Theme[label:sub(1,1):upper()..label:sub(2):lower()];assert(theme,"Unknown theme");for key,v in theme do vm.overrides[key]=v end end end;return true
 end
 eval=function(n,env) tick();local k=n[1];if k=="lit" then return n[2] elseif k=="var" then local v=env[n[2]];assert(v~=nil,"Unknown variable: "..n[2]);return v elseif k=="neg" then return -eval(n[2],env) elseif k=="not" then return not eval(n[2],env) elseif k=="call" then local args={};for i,e in n[3] do args[i]=eval(e,env) end;return invoke(n[2],args) end
  local op=n[2];local a=eval(n[3],env);if op=="and" then return a and eval(n[4],env) elseif op=="or" then return a or eval(n[4],env) end;local b=eval(n[4],env)
  if op=="==" then return a==b elseif op=="~=" then return a~=b elseif op=="<" then return a<b elseif op==">" then return a>b elseif op=="<=" then return a<=b elseif op==">=" then return a>=b elseif op==".." then return invoke("join",{a,b}) end
  local v=if op=="+" then a+b elseif op=="-" then a-b elseif op=="*" then a*b elseif op=="/" then a/b else a%b;return num(v,-1e12,1e12)
 end
 exec=function(body,env) for _,n in body do tick();if n[1]=="assign" then env[n[2]]=eval(n[3],env) elseif n[1]=="call" then eval(n,env) else local branch=n[3];for _,pair in n[2] do if eval(pair[1],env) then branch=pair[2];break end end;exec(branch,env) end end end
 exec(program.main,base)
 function vm:event(action,hp,max,changed)
  if not self.running or not grants.events then return end;steps=0;local function run(k,a,b) local h=program.events[k];if h then local e=table.clone(base);e[h[1]]=a;e[h[2]]=b;exec(h[3],e) end end;if changed then run("onHealthChanged",hp,max) end;run("onEvent",action,hp)
 end
 function vm:stop() self.running=false;table.clear(self.widgets);table.clear(self.overrides) end
 return vm
end
return C