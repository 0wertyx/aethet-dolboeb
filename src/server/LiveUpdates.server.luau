-- First-party data-only relay. Install in your own experience.
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
if script:GetAttribute("EnabledRelay")~=true then return end
local url="https://raw.githubusercontent.com/0wertyx/aethet-dolboeb/main/updates/live.json"
local manifest=RS:FindFirstChild("AetherLiveManifestV1")
if manifest and not manifest:IsA("StringValue") then warn("AETHER: manifest name conflict");return end
if not manifest then manifest=Instance.new("StringValue");manifest.Name="AetherLiveManifestV1";manifest.Parent=RS end
manifest:SetAttribute("RelayStatus","STARTING")
local previousStatus=nil
local function status(message)
 manifest:SetAttribute("RelayStatus",message)
 if previousStatus~=message then
  previousStatus=message
  if message~="ONLINE" then warn("AETHER LiveUpdates: "..message) end
 end
end
while script.Parent do
 if not Http.HttpEnabled then
  status("HTTP DISABLED: enable Allow HTTP Requests")
 else
  local ok,body=pcall(function() return Http:GetAsync(url,true) end)
  if not ok then
   status("HTTP ERROR: check server Output")
   warn("AETHER LiveUpdates:",tostring(body):sub(1,180))
  elseif #body>32000 then
   status("MANIFEST TOO LARGE")
  else
   local good,data=pcall(function() return Http:JSONDecode(body) end)
   if good and type(data)=="table" and data.format=="aether.live/1" and type(data.revision)=="number" and type(data.version)=="string" and type(data.presets)=="table" then
    if manifest.Value~=body then manifest.Value=body end
    manifest:SetAttribute("PublishedVersion",data.version)
    status("ONLINE")
   else
    status("INVALID MANIFEST")
   end
  end
 end
 task.wait(15)
end
