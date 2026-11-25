-- AETHER visual pointer. Separate top-layer ScreenGui, no input capture.
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local U = require(script.Parent.Util)
local Symbol = require(script.Parent.Symbol)
local Cursor = {}
Cursor.__index = Cursor

function Cursor.new(playerGui, scope)
    local screen = U.new("ScreenGui", {
        Name = "AETHER_Cursor", ResetOnSpawn = false,
        IgnoreGuiInset = true, DisplayOrder = 10000,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, playerGui)
    scope:add(screen)
    local root = U.new("Frame", {
        Name = "VisualPointer", BackgroundTransparency = 1,
        BorderSizePixel = 0, Active = false,
        AnchorPoint = Vector2.new(0, 0),
        Size = UDim2.fromOffset(32, 32), ZIndex = 10,
    }, screen)
    local glyph = Symbol.new(root, "Rounded Triangle", 40)
    glyph.root.ZIndex = 10
    local picture = U.new("ImageLabel", {
        Name = "CustomImage", BackgroundTransparency = 1,
        BorderSizePixel = 0, Active = false, Visible = false,
        Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit,
        ZIndex = 11,
    }, root)
    return setmetatable({screen=screen, root=root, glyph=glyph,
        picture=picture, previousMouseIcon=nil}, Cursor)
end

function Cursor:step(s, menuOpen, t)
    local enabled = s.cursor and Input.MouseEnabled
        and Input.MouseBehavior ~= Enum.MouseBehavior.LockCenter
    self.root.Visible = enabled
    if not enabled then
        if self.previousMouseIcon ~= nil then
            Input.MouseIconEnabled = self.previousMouseIcon
            self.previousMouseIcon = nil
        end
        return
    end
    if self.previousMouseIcon == nil then
        self.previousMouseIcon = Input.MouseIconEnabled
    end
    Input.MouseIconEnabled = false
    local pos = Input:GetMouseLocation()
    local size = s.cursorSize
    self.root.Size = UDim2.fromOffset(size, size)
    self.root.Position = UDim2.fromOffset(
        pos.X - size * s.hotX / 100,
        pos.Y - size * s.hotY / 100
    )
    local isImage = s.cursorShape == "Image" and s.image ~= ""
    self.picture.Visible = isImage
    self.glyph.root.Visible = not isImage
    if isImage then
        local id = "rbxassetid://" .. s.image
        if self.picture.Image ~= id then self.picture.Image = id end
    else
        local a, b = U.hex(s.cursorA), U.hex(s.cursorB)
        if s.cursorRainbow and not s.reduce then
            local h = (t * s.cursorSpeed / 700) % 1
            a = Color3.fromHSV(h, .65, 1)
            b = Color3.fromHSV((h + .28) % 1, .65, 1)
        end
        self.glyph:shape(s.cursorShape, 40)
        self.glyph:paint(a, b, s.cursorGlow, 6)
    end
end

function Cursor:destroy()
    if self.previousMouseIcon ~= nil then
        Input.MouseIconEnabled = self.previousMouseIcon
        self.previousMouseIcon = nil
    end
    if self.screen then self.screen:Destroy() end
end
return Cursor
