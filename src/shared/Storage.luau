local RS=game:GetService("ReplicatedStorage");local Http=game:GetService("HttpService");local S=require(script.Parent.Schema)
local Store={};Store.__index=Store
function Store.new(app,scope)
 local self=setmetatable({app=app,revision=0,serial=0,dirty=false,id=0,lastEdit=0,lastWrite=-100,status="Local session · JSON available",ready=false},Store)
 local pg=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
 local cache=pg:FindFirstChild("AETHER_SessionBank")
 if not cache then cache=Instance.new("StringValue");cache.Name="AETHER_SessionBank";cache.Parent=pg end
 self.cache=cache
 if cache:IsA("StringValue") and cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(cache.Value)) end)
  if ok then app:restore(bank);self.status="Local session restored" end
 end
 local function attach(r)
  if self.remote or r.Name~="AetherFullStoreV1" or not r:IsA("RemoteEvent") then return end;self.remote=r
  scope:on(r.OnClientEvent,function(id,ok,msg,rev,body)
   local p=self.pending;if not p or id~=p.id then return end;self.pending=nil;self.status=msg
   if not ok then if msg=="Revision conflict · reload or export" or p.op=="read" then self.ready=false end;app:log("Store",msg);return end
   self.revision=rev;if p.op=="read" then local good,bank=pcall(function() return S.bank(Http:JSONDecode(body)) end);if not good then self.status="Unreadable bank · local edits retained";return end
    if p.serial==self.serial and (p.force or not self.dirty) then app:restore(bank);self.dirty=false;self:cacheBank() end;self.ready=true
   elseif self.serial==p.serial then self.dirty=false end;app:log("Store",msg)
  end);self:read(false)
 end
 scope:on(RS.ChildAdded,attach);local r=RS:FindFirstChild("AetherFullStoreV1");if r then attach(r) end;return self
end
function Store:cacheBank()
 local ok,data=pcall(function() return Http:JSONEncode(S.bank(self.app.bank)) end)
 if not ok or #data>110000 then self.status="Bank invalid or too large";return false end
 if self.cache and self.cache:IsA("StringValue") then self.cache.Value=data;return true end
 return false
end
function Store:edit()
 self.serial+=1;self.dirty=true;self.lastEdit=os.clock()
 self:cacheBank()
end
function Store:request(op,body,force)
 if not self.remote or not self.remote.Parent then self.status="Local session only · export a JSON bank";return false end
 if self.pending then return false end;self.id+=1;self.pending={id=self.id,op=op,serial=self.serial,force=force,start=os.clock()};self.status=if op=="read" then "Reading bank…" else "Saving bank…";self.remote:FireServer(self.id,op,self.revision,body);return true
end
function Store:read(force)
 if self.remote then return self:request("read",nil,force) end
 if force and self.cache and self.cache:IsA("StringValue") and self.cache.Value~="" then
  local ok,bank=pcall(function() return S.bank(Http:JSONDecode(self.cache.Value)) end)
  if ok then self.app:restore(bank);self.status="Session bank restored";return true end
 end
 self.status="No saved session bank";return false
end
function Store:save()
 if not self.ready then if self:cacheBank() then self.status="Saved for this game session";return true end;return false end
 local data=Http:JSONEncode(self.app.bank);if #data>110000 then self.status="Bank exceeds 110 KB · remove or export assets";return false end;self.lastWrite=os.clock();return self:request("write",data,false)
end
function Store:tick(now)
 if self.pending and now-self.pending.start>18 then self.pending=nil;self.ready=false;self.status="Store timeout · reload or export" end
 if self.dirty and self.ready and not self.pending and now-self.lastEdit>2 and now-self.lastWrite>12 then self:save() end
end
return Store