--!strict
-- AETHER client entry: regular Roblox LocalScript, no external loader.
-- Modules are synchronized by Rojo into ReplicatedStorage.Aether.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("Aether", 30)
assert(modules, "AETHER: ReplicatedStorage.Aether is missing; sync the Rojo project")
local function module(name)
    return require(modules:WaitForChild(name, 15))
end

local U = module("Util")
local S = module("Schema")
local Hud = module("Hud")
local Avatar = module("Avatar")
local WalkMotion = module("WalkMotion")
local PreviewProps = module("PreviewProps")
local World = module("World")
local View = module("View")
local Controls = module("Controls")
local Pages = module("Pages")
local Storage = module("Storage")
local Cues = module("Cues")

-- Prevent multiple copies if the script is restarted in Studio.
local pg = player:WaitForChild("PlayerGui")
local prior = pg:FindFirstChild("AETHER_Studio")
if prior then prior:Destroy() end
-- Reloads must not leave a previous high-order pointer behind.
local priorPointer = pg:FindFirstChild("AETHER_Pointer")
if priorPointer then priorPointer:Destroy() end
local scope = U.scope()
local gui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Studio", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100000,
}, pg))
local overlay = U.frame(gui, "HUDLayer", nil, nil, nil, 1)
local pointerGui = scope:add(U.new("ScreenGui", {
    Name = "AETHER_Pointer", ResetOnSpawn = false,
    IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None,
    ClipToDeviceSafeArea = false, DisplayOrder = 100003,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, pg))
local pointer = U.frame(pointerGui, "PointerLayer", nil, nil, nil, 1)
pointer.Active=false;pointer.Interactable=false
local studioLayer = U.frame(gui, "StudioLayer", nil, nil, nil, 1)
studioLayer.ZIndex=2

local app = {
    bank = S.blank(), mode = "Game", logs = {}, preview = nil,
    hudTab = "hp", scriptTab = "AETHER Lua",
    grants = {widgets = false, appearance = false, events = false},
    sim = {hp = 100, max = 100, gen = 0, players = {}},
    frame = {hp = nil, max = nil, gen = 0, name = player.DisplayName, mode = "GAME", targets = {}, widgets = {}},
    cues = nil, lastVitals = nil, altLock = false,
}
app.s = app.bank.settings

function app:log(topic, message)
    local stamp = os.date("%H:%M:%S")
    table.insert(self.logs, string.format("%s [%s] %s", stamp, tostring(topic), tostring(message)))
    while #self.logs > 35 do table.remove(self.logs, 1) end
end
function app:dirty()
    self.store:edit()
end
function app:set(key, value)
    local normalized = S.value(key, value)
    self.s = table.clone(self.s)
    self.s[key] = normalized
    self.bank.settings = self.s
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:patch(patch)
    local next = table.clone(self.s)
    for k, v in patch do next[k] = S.value(k, v) end
    self.s = next
    self.bank.settings = next
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:replace(settings)
    self.s = S.settings(settings)
    self.bank.settings = self.s
    self:stopCue()
    self:dirty()
    if self.ui then self.ui:sync() end
end
function app:restore(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self:stopCue()
    if self.ui and self.ui.tab then self.ui:open(self.ui.tab) end
end
function app:library(bank)
    self.bank = S.bank(bank)
    self.s = self.bank.settings
    self:dirty()
end
function app:modeSet(mode)
    assert(mode == "Game" or mode == "Simulator", "Invalid AETHER mode")
    self.mode = mode
    if self.ui then self.ui:sync() end
end
function app:simVitals(hp, maximum, kind)
    self.sim.hp, self.sim.max = hp, maximum
    if kind == "respawn" then self.sim.gen += 1 end
    self:modeSet("Simulator")
end
function app:simulate(kind)
    self:modeSet("Simulator")
    local sim = self.sim
    if kind == "Damage −25" then sim.hp = math.max(0, sim.hp - 25)
    elseif kind == "Heal +25" then sim.hp = math.min(sim.max, sim.hp + 25)
    elseif kind == "Respawn" then sim.gen += 1; sim.hp = sim.max
    elseif kind == "Clear players" then table.clear(sim.players)
    elseif kind == "Add player" then
        if #sim.players < 10 then
            local id = #sim.players + 1
            table.insert(sim.players, {id = id, x = math.sin(id * 2), y = math.cos(id * 2)})
        end
    elseif kind == "Move players" then
        for _, p in sim.players do p.x = math.clamp(p.x * .8 + .18, -1, 1); p.y = math.clamp(p.y * .8 - .13, -1, 1) end
    end
end
function app:stopCue()
    if self.cues then self.cues:stop(); self.cues = nil end
end
function app:runCue()
    self:stopCue()
    local ok, vm = pcall(Cues.start, self.s.cue, self.grants)
    if ok then self.cues = vm; self:log("Scripts", "HUD script started")
    else self:log("Scripts", vm); error(vm, 0) end
end
-- Live updates are bounded data packages, never downloaded executable Luau.
local updateHttp=game:GetService("HttpService")
local updateState={version="1.0.0",publishedVersion="1.0.0",revision=0,status="Waiting for update relay",busy=false,history={},releases={},generation=0,connected=false,unread=false,testCount=0,isTest=false}
app.liveUpdate=updateState
local function validateUpdate(raw)
    assert(type(raw)=="table" and raw.format=="aether.live/1","Invalid update format")
    assert(type(raw.revision)=="number" and raw.revision%1==0 and raw.revision>=1 and raw.revision<=1000000,"Invalid revision")
    assert(type(raw.version)=="string" and #raw.version<=20 and raw.version:match("^%d+%.%d+%.%d+$"),"Invalid version")
    assert(type(raw.notes)=="string" and #raw.notes<=240,"Invalid release notes")
    assert(type(raw.presets)=="table","Missing preset data")
    local presets={};local count=0
    for group,items in raw.presets do
        assert(table.find({"Theme","Wings","Halos","Character","Neon","Ambient","Motion","HUD","Cursor","Camera","Fonts"},group) and type(items)=="table","Invalid preset group")
        presets[group]={}
        for name,values in items do
            count+=1
            assert(count<=24 and type(name)=="string" and #name>=1 and #name<=40 and not name:find("%c"),"Invalid preset name/count")
            presets[group][name]=S.settings(values,group)
        end
    end
    return {revision=raw.revision,version=raw.version,notes=raw.notes,presets=presets}
end
local function versionGreater(a,b)
    local ax,ay,az=a:match("^(%d+)%.(%d+)%.(%d+)$")
    local bx,by,bz=b:match("^(%d+)%.(%d+)%.(%d+)$")
    local aa={tonumber(ax),tonumber(ay),tonumber(az)}
    local bb={tonumber(bx),tonumber(by),tonumber(bz)}
    for i=1,3 do if aa[i]~=bb[i] then return aa[i]>bb[i] end end
    return false
end
function app:updateStatus(message)
    updateState.status=message
    self:log("Update",message)
    if self.ui then self.ui:sync() end
end
function app:applyLiveUpdate(raw,force)
    if updateState.busy or self.stopping then return end
    updateState.busy=true;updateState.generation+=1
    local gen=updateState.generation
    self:updateStatus("Validating update...")
    task.delay(.35,function()
        if self.stopping or gen~=updateState.generation then return end
        local ok,pack=pcall(validateUpdate,raw)
        if not ok then updateState.busy=false;self:updateStatus("Rejected: "..tostring(pack):sub(-100));return end
        if not force and (pack.revision<=updateState.revision or not versionGreater(pack.version,updateState.publishedVersion)) then updateState.busy=false;self:updateStatus("Already up to date");return end
        local before={version=updateState.version,publishedVersion=updateState.publishedVersion,revision=updateState.revision,notes=updateState.notes,presets=S.copy(S.presets),isTest=updateState.isTest}
        local staged=S.copy(S.presets)
        for group,items in pack.presets do
            staged[group]=staged[group] or {}
            for name,values in items do staged[group][name]=values end
        end
        -- Swap one validated data table. Preserve all settings, profile bank,
        -- current page, HUD, avatar, render callbacks and the session itself.
        S.presets=staged
        updateState.version=pack.version;updateState.isTest=force==true;if not force then updateState.revision=pack.revision;updateState.publishedVersion=pack.version end;updateState.notes=pack.notes
        local applied,err=pcall(function() self:updateStatus("Updated live to "..pack.version) end)
        if not applied then
            S.presets=before.presets;updateState.version=before.version;updateState.publishedVersion=before.publishedVersion;updateState.revision=before.revision;updateState.notes=before.notes;updateState.isTest=before.isTest
            updateState.status="Update rolled back: "..tostring(err):sub(-100)
        else
            table.insert(updateState.history,before)
            while #updateState.history>5 do table.remove(updateState.history,1) end
            if force then updateState.testCount+=1 end
            table.insert(updateState.releases,1,{version=pack.version,notes=pack.notes,source=if force then "LOCAL TEST "..tostring(updateState.testCount) else "WEBSITE",time=os.date("%H:%M:%S")})
            while #updateState.releases>12 do table.remove(updateState.releases) end
            updateState.unread=not (self.ui and self.ui.opened and self.ui.tab=="Updates")
        end
        updateState.busy=false
        if self.ui then self.ui:sync() end
    end)
end
function app:testLiveUpdate()
    local revision=updateState.revision+1
    self:applyLiveUpdate({format="aether.live/1",revision=revision,version=updateState.publishedVersion,notes="Live test: new Aurora glass theme and Lunar halo preset. Existing settings remain intact.",presets={Theme={["Live Aurora"]={accent="8DEBFF",secondary="D8ACFF",glassColor="22243E"}},Halos={["Live Lunar"]={halo=true,haloStyle="Lunar",haloColor="C4B5FF"}}}},true)
end
function app:checkLiveUpdate()
    if updateState.busy then return end
    local manifest=game:GetService("ReplicatedStorage"):FindFirstChild("AetherLiveManifestV1")
    if not manifest or not manifest:IsA("StringValue") or manifest.Value=="" then self:updateStatus("No update manifest available. Use Test update or enable the server relay.");return end
    if #manifest.Value>32000 then self:updateStatus("Manifest too large");return end
    local ok,raw=pcall(function() return updateHttp:JSONDecode(manifest.Value) end)
    if not ok then self:updateStatus("Invalid manifest JSON");return end
    self:applyLiveUpdate(raw,false)
end
function app:rollbackLiveUpdate()
    if updateState.busy then return end
    local before=table.remove(updateState.history)
    if not before then self:updateStatus("No previous update");return end
    S.presets=before.presets;updateState.version=before.version;updateState.publishedVersion=before.publishedVersion;updateState.revision=before.revision;updateState.notes=before.notes;updateState.isTest=before.isTest
    updateState.unread=false
    self:updateStatus("Rolled back to "..before.version)
end

function app:page(tab, ui)
    Pages.render(self, tab, ui)
end
function app:onMenu(open)
    if open and self.editingHUD then self.editingHUD=false;self.ui.drag=nil end
    if open and self.view then self.view:releaseLock(self.view:nativeLockAvailable()) end
end
function app:drag(input, key, widget, frame, source)
    local panel=key=="top" or key=="rail"
    if panel then if not self.s.movePanels then return end
    elseif self.s.locked then return end
    if key=="cross" then return end
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local start=Vector2.new(input.Position.X,input.Position.Y)
    local vp=frame.AbsoluteSize
    local size=widget.AbsoluteSize
    local original=widget.AbsolutePosition-frame.AbsolutePosition
    local centered=key=="input" or key=="wallhop"
    local function normalized(pos,sz,center)
        if center then
            return math.clamp(math.round((pos.X+sz.X*.5)/math.max(1,vp.X)*100),0,100),math.clamp(math.round((pos.Y+sz.Y*.5)/math.max(1,vp.Y)*100),0,100)
        end
        return math.clamp(math.round(pos.X/math.max(1,vp.X-sz.X)*100),0,100),math.clamp(math.round(pos.Y/math.max(1,vp.Y-sz.Y)*100),0,100)
    end
    local migrated=false
    self.ui:begin(input,function(pos)
        local delta=pos-start
        if delta.Magnitude<1 and not migrated then return end
        local dest=original+delta
        dest=Vector2.new(math.clamp(dest.X,0,math.max(0,vp.X-size.X)),math.clamp(dest.Y,0,math.max(0,vp.Y-size.Y)))
        local x,y=normalized(dest,size,centered)
        local patch={[key.."X"]=x,[key.."Y"]=y}
        if panel then
            if not self.s.movePanels then return end
            patch[key.."Custom"]=true
        elseif not centered and self.s.layoutMode=="Sketch" then
            patch.layoutMode="Custom"
            local preview=source or (self.preview and self.preview.hud)
            if preview then
                for _,other in {"hp","clock","profile","dock"} do
                    if other~=key then
                        local w=preview.widgets[other].p
                        local nx,ny=normalized(w.AbsolutePosition-frame.AbsolutePosition,w.AbsoluteSize,false)
                        patch[other.."X"]=nx;patch[other.."Y"]=ny
                    end
                end
            end
        end
        migrated=true
        self:patch(patch)
    end)
end

local hud = Hud.new(scope, overlay, false, function(tab) app.ui:open(tab) end,nil,function(key) app:set(key,false) end)
local avatar = Avatar.new(workspace, false)
local walkMotion = WalkMotion.new()
local motionProps = PreviewProps.new(workspace, true)
local world = World.new()
local view = View.new(player, pointer)
app.view = view
local ui = Controls.new(app, studioLayer, scope)
app.ui = ui
local store = Storage.new(app, scope)
app.store = store

-- Observe the first-party replicated manifest. A revision that arrives
-- during validation remains queued; rollback is not immediately undone.
local updateRS=game:GetService("ReplicatedStorage")
local relayConnection=nil
local relayStatusConnection=nil
local relayInstance=nil
local pendingManifest=nil
local lastManifest=nil
local function observeRelay(value)
    if value.Name~="AetherLiveManifestV1" or not value:IsA("StringValue") then return end
    if relayConnection then relayConnection:Disconnect() end
    if relayStatusConnection then relayStatusConnection:Disconnect() end
    relayInstance=value
    updateState.connected=true
    local function receive()
        if value.Value~="" and value.Value~=lastManifest then
            lastManifest=value.Value
            pendingManifest=value.Value
        end
    end
    relayConnection=value:GetPropertyChangedSignal("Value"):Connect(receive)
    local function refreshRelayStatus()
        updateState.relayStatus=tostring(value:GetAttribute("RelayStatus") or "CONNECTED / STATUS UNKNOWN")
        if app.ui then app.ui:sync() end
    end
    relayStatusConnection=value:GetAttributeChangedSignal("RelayStatus"):Connect(refreshRelayStatus)
    refreshRelayStatus()
    receive()
    app:updateStatus("Website update relay connected")
end
scope:on(updateRS.ChildAdded,observeRelay)
scope:on(updateRS.ChildRemoved,function(value)
    if value~=relayInstance then return end
    if relayConnection then relayConnection:Disconnect();relayConnection=nil end
    if relayStatusConnection then relayStatusConnection:Disconnect();relayStatusConnection=nil end
    relayInstance=nil;pendingManifest=nil;lastManifest=nil;updateState.connected=false;updateState.relayStatus=nil
    app:updateStatus("Website update relay disconnected")
end)
scope:add(function()
    if relayConnection then relayConnection:Disconnect() end
    if relayStatusConnection then relayStatusConnection:Disconnect() end
end)
local existingRelay=updateRS:FindFirstChild("AetherLiveManifestV1")
if existingRelay then observeRelay(existingRelay) end
scope:on(RunService.Heartbeat,function()
    if app.stopping or updateState.busy or not pendingManifest then return end
    local body=pendingManifest;pendingManifest=nil
    if #body>32000 then app:updateStatus("Manifest too large");return end
    local ok,raw=pcall(function() return updateHttp:JSONDecode(body) end)
    if not ok then app:updateStatus("Invalid manifest JSON");return end
    if type(raw)=="table" and type(raw.revision)=="number" and raw.revision<=updateState.revision then return end
    app:applyLiveUpdate(raw,false)
end)

-- Non-persistent editing session. Handles exist only while arranging the live HUD.
local editorGui=scope:add(U.new("ScreenGui",{Name="AETHER_HUD_Editor",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100002,ZIndexBehavior=Enum.ZIndexBehavior.Global,Enabled=false},pg))
local editor=U.frame(editorGui,"Editor",nil,nil,nil,1)
local header=U.frame(editor,"EditorBar",UDim2.new(.5,0,0,58),UDim2.new(.9,0,0,44),Color3.fromRGB(27,21,44),.04)
header.AnchorPoint=Vector2.new(.5,0);header.ZIndex=20
U.new("UISizeConstraint",{MaxSize=Vector2.new(440,44)},header)
U.corner(header,12);U.stroke(header,Color3.fromRGB(188,151,255),.3)
local instruction=U.label(header,"HUD EDIT",11,UDim2.fromOffset(10,0),UDim2.new(.32,-10,1,0));instruction.ZIndex=21
local panelToggle=U.button(header,"PANELS: LOCKED");panelToggle.Position=UDim2.new(.32,0,0,5);panelToggle.Size=UDim2.new(.43,-4,1,-10);panelToggle.ZIndex=22;panelToggle.Modal=true
local done=U.button(header,"DONE");done.Position=UDim2.new(.75,0,0,5);done.Size=UDim2.new(.25,-5,1,-10);done.Modal=true;done.ZIndex=22
scope:on(panelToggle.Activated,function()
    if not app.editingHUD then return end
    ui.drag=nil
    app:set("movePanels",not app.s.movePanels)
    app:updateEditor()
end)
local handles={}
local positions={"hp","clock","profile","dock","input","wallhop","top","rail"}
local function isPanel(key) return key=="top" or key=="rail" end
local function widgetFor(key)
    if key=="input" then return hud.inputRoot end
    if key=="wallhop" then return hud.wallhop end
    if key=="top" then return ui.top end
    if key=="rail" then return ui.rail end
    return hud.widgets[key].p
end
local function coord(key,topLeft,size,vp)
    if key=="input" or key=="wallhop" then
        return math.clamp(math.round((topLeft.X+size.X*.5)/math.max(1,vp.X)*100),0,100),math.clamp(math.round((topLeft.Y+size.Y*.5)/math.max(1,vp.Y)*100),0,100)
    end
    return math.clamp(math.round(topLeft.X/math.max(1,vp.X-size.X)*100),0,100),math.clamp(math.round(topLeft.Y/math.max(1,vp.Y-size.Y)*100),0,100)
end
function app:editHUD(on)
    if self.stopping then return end
    if on then
        ui:show(false)
        self.editingHUD=true
        editorGui.Enabled=true
        self.view:releaseLock(self.view:nativeLockAvailable())
    else
        self.editingHUD=false
        editorGui.Enabled=false
        ui.drag=nil
        ui:open("HUD")
    end
end
scope:on(done.Activated,function() app:editHUD(false) end)
for _,key in positions do
    local b=U.button(editor,key:upper())
    b.Name="Move_"..key;b.TextSize=12;b.BackgroundTransparency=.84;b.TextColor3=Color3.fromRGB(255,242,255);b.ZIndex=9;b.Active=true;b.AutoButtonColor=false;b.Visible=false;b.Modal=true
    b.TextStrokeTransparency=.35
    U.stroke(b,Color3.fromRGB(224,183,255),0,2.5)
    handles[key]=b
    scope:on(b.InputBegan,function(input)
        if not app.editingHUD or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
        local target=widgetFor(key)
        if not target.Visible or (isPanel(key) and not app.s.movePanels) then return end
        local vp=overlay.AbsoluteSize
        local size=target.AbsoluteSize
        local original=target.AbsolutePosition-overlay.AbsolutePosition
        -- Preserve all currently visible classic widget positions before leaving Sketch.
        local patch={}
        if app.s.layoutMode=="Sketch" and key~="input" and key~="wallhop" and not isPanel(key) then
            patch.layoutMode="Custom"
            for _,other in {"hp","clock","profile","dock"} do
                local w=widgetFor(other)
                local x,y=coord(other,w.AbsolutePosition-overlay.AbsolutePosition,w.AbsoluteSize,vp)
                patch[other.."X"]=x;patch[other.."Y"]=y
            end
            app:patch(patch)
        end
        local start=Vector2.new(input.Position.X,input.Position.Y)
        ui:begin(input,function(pos)
            if not app.editingHUD then return end
            local dest=original+(pos-start)
            dest=Vector2.new(math.clamp(dest.X,0,math.max(0,vp.X-size.X)),math.clamp(dest.Y,0,math.max(0,vp.Y-size.Y)))
            local x,y=coord(key,dest,size,vp)
            if isPanel(key) then
                if not app.s.movePanels then return end
                if not app.s[key.."Custom"] or app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."Custom"]=true,[key.."X"]=x,[key.."Y"]=y}) end
            elseif app.s[key.."X"]~=x or app.s[key.."Y"]~=y then app:patch({[key.."X"]=x,[key.."Y"]=y}) end
        end)
    end)
end
function app:updateEditor()
    editorGui.Enabled=self.editingHUD==true
    if not self.editingHUD then return end
    panelToggle.Text=if self.s.movePanels then "PANELS: MOVE" else "PANELS: LOCKED"
    panelToggle.BackgroundColor3=if self.s.movePanels then Color3.fromRGB(105,71,164) else Color3.fromRGB(52,40,77)
    for _,key in positions do
        local b,target=handles[key],widgetFor(key)
        b.Visible=target.Visible and (if key=="top" then self.s.topCapsule elseif key=="rail" then self.s.robloxRail elseif key=="input" then self.s.inputOverlay elseif key=="wallhop" then self.s.wallhopHelper else self.s[key])
        local locked=isPanel(key) and not self.s.movePanels
        b.Active=not locked;b.Interactable=not locked
        b.Text=key:upper()..(if locked then " · LOCKED" else " · MOVE")
        local rim=b:FindFirstChildOfClass("UIStroke")
        if rim then rim.Color=if locked then Color3.fromRGB(153,148,170) else Color3.fromRGB(224,183,255);rim.Transparency=if locked then .3 else 0 end
        if b.Visible then
            local xy=target.AbsolutePosition-editor.AbsolutePosition
            local sz=target.AbsoluteSize
            b.Position=UDim2.fromOffset(xy.X,xy.Y);b.Size=UDim2.fromOffset(sz.X,sz.Y)
        end
    end
end
function app:unload()
    if self.stopping then return end
    self.stopping=true
    self.editingHUD=false;editorGui.Enabled=false
    if store.dirty and store.ready and not store.pending then pcall(function() store:save() end) end
    -- Defer destruction until the current GUI activation callback has returned.
    task.defer(function() scope:clear() end)
end
ui:open("Dashboard")
ui:show(false)
app:log("Startup", "AETHER modules initialized")

local humanoid, character, generation = nil, nil, 0
local function bind(char)
    generation += 1
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
end
scope:on(player.CharacterAdded, bind)
scope:on(player.CharacterRemoving, function(char)
    if character == char then
        view:releaseCamera(view:nativeLockAvailable())
        character, humanoid = nil, nil
    end
    avatar:clear()
    motionProps:clear()
end)
if player.Character then bind(player.Character) end

scope:on(UserInputService.InputBegan, function(input, processed)
    if app.stopping or processed or UserInputService:GetFocusedTextBox() then return end
    if app.editingHUD then if input.KeyCode==Enum.KeyCode.F8 then app:editHUD(false) end;return end
    if input.KeyCode == Enum.KeyCode.F8 then
        ui:show(not ui.opened)
    elseif input.KeyCode == Enum.KeyCode.LeftAlt and app.mode=="Game" and not ui.opened and not game:GetService("GuiService").MenuIsOpen then
        local enable=not app.s.lock
        if enable then
            app:patch({lock=true,cameraMode="Follow"})
            if view:nativeLockAvailable() then ui:message("Alt Lock requested. Turn Roblox Settings > Shift Lock Switch OFF.") end
        else
            app:set("lock",false)
            view:releaseLock(view:nativeLockAvailable())
        end
    end
end)

local function targetsFromGame()
    local results = {}
    local cam = workspace.CurrentCamera
    local ownRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not cam or not ownRoot then return results end
    local center = cam.ViewportSize * .5
    for _, other in Players:GetPlayers() do
        if other == player then continue end
        local c = other.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local life = c and c:FindFirstChildOfClass("Humanoid")
        if root and life and life.Health > 0 then
            local dist = (root.Position - ownRoot.Position).Magnitude
            if dist <= app.s.reach then
                local screen, inViewport = cam:WorldToViewportPoint(root.Position)
                local v = Vector2.new(screen.X, screen.Y) - center
                if screen.Z < 0 then v = -v end
                if v.Magnitude < .001 then v = Vector2.yAxis end
                local dir = v.Unit
                table.insert(results, {
                    id = tostring(other.UserId), label = other.DisplayName,
                    distance = dist, visible = inViewport and screen.Z > 0,
                    x = dir.X, y = dir.Y,
                })
            end
        end
    end
    return results
end
local targetTimer, cachedTargets = 0, {}
local function frame(dt, now)
    local result = app.frame
    if dt>0 then result.fps=U.approach(result.fps or 1/dt,1/dt,dt,.6) end
    result.name = player.DisplayName
    result.mode = app.mode:upper()
    if app.mode == "Simulator" then
        result.hp, result.max, result.gen = app.sim.hp, app.sim.max, app.sim.gen
        local list = {}
        for _, p in app.sim.players do
            table.insert(list, {id = tostring(p.id), label = "Test " .. p.id,
                distance = 100, visible = false, x = p.x, y = p.y})
        end
        result.targets = list
    else
        result.hp = if humanoid then humanoid.Health else nil
        result.max = if humanoid then humanoid.MaxHealth else nil
        result.gen = generation
        targetTimer += dt
        if targetTimer > .13 then targetTimer = 0; cachedTargets = targetsFromGame() end
        result.targets = cachedTargets
    end
    result.widgets = if app.cues then app.cues.widgets else {}
    if app.cues then
        local old = app.lastVitals
        local h, m = result.hp, result.max
        local changed = h ~= nil and (not old or old.hp ~= h or old.max ~= m or old.gen ~= result.gen)
        if changed then
            local event = if old and old.gen ~= result.gen then "Respawn"
                elseif old and h < old.hp then "Damage"
                elseif old and h > old.hp then "Heal" else "Vitals"
            local ok, err = pcall(function() app.cues:event(event, h, m, true) end)
            if not ok then app:log("Scripts", err); app:stopCue() end
        end
        if h ~= nil then app.lastVitals = {hp = h, max = m, gen = result.gen} end
    end
    local styled = app.s
    if app.cues and next(app.cues.overrides) then
        styled = table.clone(app.s)
        for k,v in app.cues.overrides do styled[k] = v end
    end
    result.editingHUD=app.editingHUD==true
    result.shiftLock=view.shiftReticleActive==true and not ui.opened and not app.editingHUD and app.mode=="Game"
    ui:animateBackground(now)
    hud:step(styled, result, dt)
    avatar:step(if app.mode == "Game" then character else nil, styled, now)
    world:apply(styled)
    view:step(styled, if app.mode=="Game" then humanoid else nil, ui.opened or app.editingHUD==true, dt, now)
    if app.preview then
        if app.preview.hud then app.preview.hud:step(styled, result, dt) end
        if app.preview.pose then app.preview.pose(styled, dt) end
        if app.preview.avatar then app.preview.avatar:step(app.preview.rig, styled, app.preview.effectTime or now) end
        view:preview(app.preview.cursorHost,styled)
    end
    store:tick(now)
end
-- Cursor tracking is isolated from the expensive AETHER/EditableImage frame.
-- Use a unique binding: cleaning up an older reload cannot unbind the newer one.
local pointerRenderBinding = "AETHER_Pointer_" .. game:GetService("HttpService"):GenerateGUID(false)
RunService:BindToRenderStep(pointerRenderBinding, Enum.RenderPriority.Last.Value, function()
    if app.stopping or not gui.Parent then return end
    local ok, err = pcall(view.cursorStep, view, app.s)
    if not ok then
        pcall(view.restoreCursor,view)
        if not app.pointerError then
            app.pointerError = true
            warn("AETHER cursor position:", err)
        end
    else
        app.pointerError = false
    end
end)
scope:add(function() RunService:UnbindFromRenderStep(pointerRenderBinding) end)

-- Remove last frame's local visual layer before Animator evaluates.
scope:on(RunService.PreAnimation, function()
    if not app.stopping and gui.Parent then walkMotion:restoreLive() end
end)
-- Motion Studio poses follow the real humanoid state, after Animator evaluates.
scope:on(RunService.PreSimulation, function(dt)
    if app.stopping or not gui.Parent then return end
    local characterToAnimate = if app.mode == "Game" then character else nil
    local ok, err = pcall(walkMotion.step, walkMotion, characterToAnimate, app.s, dt)
    if not ok and not app.walkError then
        app.walkError = true
        app:log("Motion", tostring(err))
        warn("AETHER walk cycle:", err)
    elseif ok then app.walkError = false end
end)

-- Props follow the already evaluated local pose without modifying character parts.
scope:on(RunService.RenderStepped, function()
    if app.stopping or not gui.Parent then motionProps:clear();return end
    local config = walkMotion.liveConfig
    local active = app.mode == "Game" and character and humanoid and humanoid.Health > 0
        and app.s.walkAnimation and not app.s.reduce and walkMotion.liveStyle == app.s.walkStyle
        and config and config.props and walkMotion.liveSettings == app.s
    local ok, err = pcall(function()
        if active then motionProps:update(character, config.style, walkMotion.liveTime * 4, humanoid:GetState())
        else motionProps:clear() end
    end)
    if not ok then
        motionProps:clear()
        if not app.motionPropError then app.motionPropError = true;warn("AETHER motion props:", err) end
    else app.motionPropError = false end
end)

local elapsed = 0
scope:on(RunService.RenderStepped, function(dt)
    if app.stopping then return end
    if not gui.Parent then scope:clear(); return end
    elapsed += math.min(dt, .1)
    local ok, err = pcall(frame, math.min(dt, .1), elapsed)
    -- Keep drag handles synchronized even if another cosmetic module faults.
    if app.preview and app.preview.hud and app.preview.hud.previewPanels then
        local good, problem=pcall(app.preview.hud.layoutPreview,app.preview.hud,app.s)
        if not good and not app.previewLayoutError then app.previewLayoutError=true;warn("AETHER preview panels:",problem) end
    end
    if app.editingHUD then
        local good, problem=pcall(app.updateEditor,app)
        if not good and not app.editorError then app.editorError=true;warn("AETHER HUD editor:",problem) end
    end
    if not ok then
        if not app.lastError or elapsed - app.lastError > 2 then
            app.lastError = elapsed
            app:log("Runtime", tostring(err))
            warn("AETHER runtime:", err)
        end
    end
end)
-- Individual cleanup callbacks: one failing subsystem cannot skip the others.
scope:add(function() app:stopCue() end)
scope:add(function() avatar:clear() end)
scope:add(function() walkMotion:destroy() end)
scope:add(function() motionProps:clear() end)
scope:add(function() world:clear() end)
scope:add(function() view:destroy() end)