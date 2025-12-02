-- // High-Performance Drawing Library v2.0 - Fixed & Beautiful \\
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local DrawingUI = Instance.new("ScreenGui")
DrawingUI.Name = "DrawingLib_v2"
DrawingUI.IgnoreGuiInset = true
DrawingUI.DisplayOrder = 999999999
DrawingUI.ResetOnSpawn = false
DrawingUI.Parent = CoreGui

local Fonts = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3
}

local FontMap = {
    [0] = Font.fromEnum(Enum.Font.Roboto),
    [1] = Font.fromEnum(Enum.Font.Legacy),
    [2] = Font.fromEnum(Enum.Font.SourceSans),
    [3] = Font.fromEnum(Enum.Font.RobotoMono),
}

local function GetFont(index)
    return FontMap[math.clamp(index or 0, 0, 3)]
end

local Drawing = {}
Drawing.__index = Drawing
Drawing.Fonts = Fonts

-- Utility
local function Color3ToHex(c3)
    return string.format("#%02X%02X%02X", c3.R*255, c3.G*255, c3.B*255)
end

-- Base object
local function NewDrawing(className)
    local obj = { Visible = true, Transparency = 0, Color = Color3.new(1,1,1), ZIndex = 1 }
    local guiObj

    if className == "Line" then
        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = obj.Color
        guiObj = frame

        function obj:Update()
            if not (self.From and self.To) then return end
            local from, to = self.From, self.To
            local diff = to - from
            local center = from + diff/2
            local length = diff.Magnitude
            local rot = math.deg(math.atan2(diff.Y, diff.X))

            frame.Size = UDim2.fromOffset(length, self.Thickness or 1)
            frame.Position = UDim2.fromOffset(center.X, center.Y)
            frame.Rotation = rot
        end

        obj.From = Vector2.new(0,0)
        obj.To = Vector2.new(100,100)
        obj.Thickness = 2

    elseif className == "Text" then
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.TextColor3 = obj.Color
        label.FontFace = GetFont(0)
        label.TextSize = 14
        label.Text = ""
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.AnchorPoint = Vector2.new(0, 0.5)
        guiObj = label

        local stroke = Instance.new("UIStroke", label)
        stroke.Thickness = 1.5
        stroke.Enabled = false

        function obj:Update()
            label.Text = self.Text or ""
            label.FontFace = GetFont(self.Font)
            label.TextSize = self.Size or 14
            label.TextColor3 = self.Color
            label.Visible = self.Visible
            label.ZIndex = self.ZIndex
            label.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)

            if self.Center then
                local bounds = label.TextBounds
                label.Position = UDim2.fromOffset(
                    self.Position.X - bounds.X/2,
                    self.Position.Y - bounds.Y/2
                )
            end

            if self.Outline then
                stroke.Enabled = true
                stroke.Color = self.OutlineColor or Color3.new()
                stroke.Transparency = self.Transparency
            else
                stroke.Enabled = false
            end

            label.TextTransparency = self.Transparency
        end

        obj.Position = Vector2.new(100,100)
        obj.Text = "Text"
        obj.Size = 16
        obj.Font = 0
        obj.Center = false
        obj.Outline = false
        obj.OutlineColor = Color3.new()

    elseif className == "Circle" then
        local frame = Instance.new("ImageLabel")
        frame.BackgroundTransparency = 1
        frame.Image = "rbxassetid://3570695787" -- Perfect circle
        frame.ImageColor3 = obj.Color
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        guiObj = frame

        local stroke = Instance.new("UIStroke", frame)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        function obj:Update()
            local r = self.Radius * 2
            frame.Size = UDim2.fromOffset(r, r)
            frame.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
            frame.ImageColor3 = self.Color
            frame.ImageTransparency = self.Filled and self.Transparency or 1
            frame.Visible = self.Visible
            frame.ZIndex = self.ZIndex

            stroke.Thickness = self.Thickness
            stroke.Color = self.Color
            stroke.Transparency = self.Filled and 1 or self.Transparency
            stroke.Enabled = not self.Filled
        end

        obj.Radius = 50
        obj.Position = Vector2.new(200,200)
        obj.Thickness = 3
        obj.Filled = false

    elseif className == "Square" then
        local frame = Instance.new("Frame")
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = obj.Color
        guiObj = frame

        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 0)

        local stroke = Instance.new("UIStroke", frame)

        function obj:Update()
            frame.Size = UDim2.fromOffset(self.Size.X, self.Size.Y)
            frame.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
            frame.BackgroundColor3 = self.Color
            frame.BackgroundTransparency = self.Filled and self.Transparency or 1
            frame.Visible = self.Visible
            frame.ZIndex = self.ZIndex

            stroke.Thickness = self.Thickness
            stroke.Color = self.Color
            stroke.Transparency = self.Filled and 1 or self.Transparency
            stroke.Enabled = not self.Filled
        end

        obj.Size = Vector2.new(100,100)
        obj.Position = Vector2.new(100,100)
        obj.Thickness = 3
        obj.Filled = false

    elseif className == "Triangle" or className == "Quad" then
        local points = className == "Triangle" and 3 or 4
        local image = Instance.new("ImageLabel")
        image.BackgroundTransparency = 1
        image.Size = UDim2.fromOffset(500,500)
        image.Position = UDim2.fromOffset(0,0)
        image.AnchorPoint = Vector2.new(0.5,0.5)
        image.ImageColor3 = obj.Color
        guiObj = image

        local stroke = Instance.new("UIStroke", image)
        stroke.Enabled = false

        local function GeneratePolygonSVG(p)
            local s = {'<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/200200/svg"><polygon points="'}
            for i = 1, points do
                local pt = p[i]
                table.insert(s, string.format("%d,%d", pt.X, pt.Y))
            end
            table.insert(s, '" fill="'..Color3ToHex(obj.Color)..'"')
            if obj.Filled then
                table.insert(s, ' opacity="'..(1 - obj.Transparency)..'"')
            else
                table.insert(s, ' fill="none" stroke="'..Color3ToHex(obj.Color)..'" stroke-width="'..(obj.Thickness * 5)..'"')
            end
            table.insert(s, "/></svg>")
            return "data:image/svg+xml;base64," .. game.HttpService:Base64Encode(table.concat(s))
        end

        function obj:Update()
            local pts = {}
            for i = 1, points do
                pts[i] = self["Point"..(i == 4 and "D" or i == 3 and "C" or i == 2 and "B" or "A")]
            end

            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            for _, p in ipairs(pts) do
                minX = math.min(minX, p.X)
                minY = math.min(minY, p.Y)
                maxX = math.max(maxX, p.X)
                maxY = math.max(maxY, p.Y)
            end
            local center = Vector2.new((minX+maxX)/2, (minY+maxY)/2)

            -- Translate points to center
            for i, p in ipairs(pts) do
                pts[i] = Vector2.new(p.X - center.X + 250, p.Y - center.Y + 250)
            end

            image.Image = GeneratePolygonSVG(pts)
            image.Position = UDim2.fromOffset(center.X, center.Y)
            image.ImageTransparency = obj.Transparency
            image.Visible = self.Visible
            image.ZIndex = self.ZIndex
        end

        if className == "Triangle" then
            obj.PointA = Vector2.new(100,100)
            obj.PointB = Vector2.new(200,100)
            obj.PointC = Vector2.new(150,200)
        else
            obj.PointA = Vector2.new(100,100)
            obj.PointB = Vector2.new(300,100)
            obj.PointC = Vector2.new(300,300)
            obj.PointD = Vector2.new(100,300)
        end
        obj.Thickness = 3
        obj.Filled = true
    end

    guiObj.Parent = DrawingUI

    -- Metamethods
    setmetatable(obj, {
        __index = function(t, k)
            if k == "Remove" or k == "Destroy" then
                return function()
                    if guiObj then guiObj:Destroy() end
                    setmetatable(t, nil)
                end
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            rawset(t, k, v)
            if obj.Update then
                task.spawn(obj.Update, obj)
            end
            if guiObj then
                if k == "Visible" then guiObj.Visible = v
                elseif k == "ZIndex" then guiObj.ZIndex = v
                elseif k == "Color" then
                    if guiObj:IsA("GuiObject") then guiObj.BackgroundColor3 = v end
                    if guiObj:IsA("TextLabel") then guiObj.TextColor3 = v end
                    if guiObj:IsA("ImageLabel") then guiObj.ImageColor3 = v end
                elseif k == "Transparency" then
                    local a = 1 - v
                    if guiObj.BackgroundTransparency ~= nil then guiObj.BackgroundTransparency = 1 - a end
                    if guiObj.ImageTransparency ~= nil then guiObj.ImageTransparency = 1 - a end
                    if guiObj.TextTransparency ~= nil then guiObj.TextTransparency = 1 - a end
                end
            end
        end
    })

    if obj.Update then obj:Update() end
    return obj
end

-- Factory
function Drawing.new(type)
    if type == "Line" then return NewDrawing("Line")
    elseif type == "Text" then return NewDrawing("Text")
    elseif type == "Circle" then return NewDrawing("Circle")
    elseif type == "Square" then return NewDrawing("Square")
    elseif type == "Triangle" then return NewDrawing("Triangle")
    elseif type == "Quad" then return NewDrawing("Quad")
    else error("Invalid drawing type: " .. tostring(type)) end
end

-- Clear all
function Drawing.clear()
    DrawingUI:ClearAllChildren()
end

return Drawing
