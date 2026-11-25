-- Optional first-party Roblox persistence. No HTTP, no player-selected keys and no game commands.
local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage");local Run=game:GetService("RunService");local Http=game:GetService("HttpService");local S=require(script.Schema)
if RS:FindFirstChild("AetherFullStoreV1") then warn("AETHER: store already installed");return end
local durable=script:GetAttribute("UseDataStore")~=false and game.GameId~=0 and (not Run:IsStudio() or script:GetAttribute("PersistentStudio")==true)
local ds=if durable then game:GetService("DataStoreService"):GetDataStore("AetherFull_Bank1") else nil
local remote=Instance.new("RemoteEvent");remote.Name="AetherFullStoreV1";remote.Parent=RS
local sessions={};local inflight=0
local function record(v)
 if v==nil then return {rev=0,json=Http:JSONEncode(S.blank())} end;assert(type(v)=="table" and type(v.rev)=="number" and v.rev>=0 and type(v.json)=="string" and #v.json<=110000,"Unrecognized stored record");S.bank(Http:JSONDecode(v.json));return v
end
remote.OnServerEvent:Connect(function(player,id,op,rev,data)
 if type(id)~="number" or id~=math.floor(id) or id<1 or id>2^31 or (op~="read" and op~="write") then return end
 local s=sessions[player];if not s then s={last=-100,lastWrite=-100,ready=false};sessions[player]=s end
 local function reply(ok,msg,value,body) if player.Parent==Players then remote:FireClient(player,id,ok,msg,value,body) end end
 local now=os.clock();if s.busy or now-s.last<.25 then reply(false,"Store busy · retry",0);return end;s.last=now
 if op=="write" and (not s.ready or rev~=s.record.rev) then reply(false,"Revision conflict · reload or export",0);return end
 if op=="write" and (type(data)~="string" or #data>110000 or now-s.lastWrite<(if durable then 6 else .4)) then reply(false,"Save limit · retry later",0);return end
 s.busy=true;inflight+=1;local ok,msg=pcall(function()
  local key="user:"..player.UserId
  if op=="read" then if ds then s.record=record(ds:GetAsync(key)) else s.record=s.record or record(nil) end;s.ready=true;reply(true,if ds then "Cloud bank loaded" else "Session bank loaded · cloud off",s.record.rev,s.record.json);return end
  local bank=S.bank(Http:JSONDecode(data));local nextRecord={rev=rev+1,json=Http:JSONEncode(bank)};assert(#nextRecord.json<=110000,"Bank too large");s.lastWrite=now
  if ds then local saved=ds:UpdateAsync(key,function(old) if record(old).rev~=rev then return nil end;return nextRecord end);if not saved then s.ready=false;reply(false,"Revision conflict · reload or export",0);return end end
  s.record=nextRecord;reply(true,if ds then "Saved in Roblox DataStore" else "Saved for this session · export for reuse",nextRecord.rev)
 end);inflight-=1;s.busy=false;if not ok then if op=="read" then s.ready=false end;warn("AETHER store:",tostring(msg):sub(1,160));reply(false,"Store unavailable or invalid bank · local edits retained",0) end
end)
local function join(p) if script:GetAttribute("DemoShareBearings")==true then p:SetAttribute("AetherShareBearing",true) end end
Players.PlayerAdded:Connect(join);for _,p in Players:GetPlayers() do join(p) end
Players.PlayerRemoving:Connect(function(p) sessions[p]=nil end)
game:BindToClose(function() local start=os.clock();while inflight>0 and os.clock()-start<18 do task.wait(.1) end end)