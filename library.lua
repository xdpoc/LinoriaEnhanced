--  █████╗ ██████╗  ██████╗     ██████╗██╗     ██╗███████╗███╗   ██╗████████╗
-- ██╔══██╗██╔══██╗██╔════╝    ██╔════╝██║     ██║██╔════╝████╗  ██║╚══██╔══╝
-- ███████║██████╔╝██║         ██║     ██║     ██║█████╗  ██╔██╗ ██║   ██║   
-- ██╔══██║██╔══██╗██║         ██║     ██║     ██║██╔══╝  ██║╚██╗██║   ██║   
-- ██║  ██║██║  ██║╚██████╗    ╚██████╗███████╗██║███████╗██║ ╚████║   ██║   
-- ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝     ╚═════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
-- made by @mqp6 on discord
-- LinoriaEnhanced

local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local TweenService = game:GetService('TweenService')
local CoreGui = game:GetService('CoreGui')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local GuiService = game:GetService('GuiService')

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RenderStepped = RunService.RenderStepped

local protect = protectgui or (syn and syn.protect_gui) or function() end

local container = Instance.new('ScreenGui')
protect(container)
container.ZIndexBehavior = Enum.ZIndexBehavior.Global
container.Parent = CoreGui
container.Name = "ArcClient"
container.ResetOnSpawn = false

getgenv().Toggles = {}
getgenv().Options = {}
getgenv().Flags = {}

local Toggles = getgenv().Toggles
local Options = getgenv().Options
local Flags = getgenv().Flags

local Library = {
    registry = {},
    registryMap = {},
    hudRegistry = {},
    openFrames = {},
    
    colors = {
        text = Color3.fromRGB(255, 255, 255),
        main = Color3.fromRGB(28, 28, 28),
        background = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(0, 120, 255),
        outline = Color3.fromRGB(50, 50, 50),
        black = Color3.new(0, 0, 0),
    },
    
    state = {
        unloaded = false,
        rainbowHue = 0,
        rainbowColor = Color3.fromHSV(0, 0.8, 1),
    },
    
    callbacks = {},
    
    mobile = {
        enabled = (InputService.TouchEnabled and not InputService.MouseEnabled) or GuiService:IsTenFootInterface(),
        touchSize = 44,
    },
}

do
    local hue = 0
    local last = tick()
    
    task.spawn(function()
        while RenderStepped:Wait() and not Library.state.unloaded do
            if tick() - last >= 0.016 then
                hue = (hue + 0.0025) % 1
                Library.state.rainbowHue = hue
                Library.state.rainbowColor = Color3.fromHSV(hue, 0.8, 1)
                last = tick()
            end
        end
    end)
end

function Library:darken(color, factor)
    factor = factor or 1.5
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, v / factor)
end
Library.colors.accentDark = Library:darken(Library.colors.accent)

function Library:new(class, props)
    local obj = typeof(class) == "string" and Instance.new(class) or class
    
    if self.mobile.enabled and props then
        if (class == 'TextButton' or class == 'Frame') and props.Size then
            if props.Size.Y.Offset > 0 and props.Size.Y.Offset < self.mobile.touchSize then
                props.Size = UDim2.new(
                    props.Size.X.Scale,
                    props.Size.X.Offset,
                    0,
                    self.mobile.touchSize
                )
            end
        end
    end
    
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    
    return obj
end

function Library:label(props, hud)
    local label = self:new('TextLabel', {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextColor3 = self.colors.text,
        TextSize = 14,
        TextStrokeTransparency = 0.8,
        RichText = true,
    })
    
    self:track(label, { TextColor3 = 'text' }, hud)
    return self:new(label, props)
end

function Library:map(val, min1, max1, min2, max2)
    return min2 + (val - min1) * (max2 - min2) / (max1 - min1)
end

function Library:measure(text, font, size)
    return TextService:GetTextSize(text, size, font, Vector2.new(1920, 1080)).X
end

function Library:round(val, precision)
    precision = 10 ^ (precision or 0)
    return math.floor(val * precision + 0.5) / precision
end

function Library:track(inst, props, hud)
    local data = {
        instance = inst,
        properties = props,
        idx = #self.registry + 1
    }
    
    table.insert(self.registry, data)
    self.registryMap[inst] = data
    
    if hud then
        table.insert(self.hudRegistry, data)
    end
end

function Library:untrack(inst)
    local data = self.registryMap[inst]
    if not data then return end
    
    for i = #self.registry, 1, -1 do
        if self.registry[i] == data then
            table.remove(self.registry, i)
            break
        end
    end
    
    for i = #self.hudRegistry, 1, -1 do
        if self.hudRegistry[i] == data then
            table.remove(self.hudRegistry, i)
            break
        end
    end
    
    self.registryMap[inst] = nil
end

container.DescendantRemoving:Connect(function(inst)
    if Library.registryMap[inst] then
        Library:untrack(inst)
    end
end)

function Library:updateColors()
    for _, obj in pairs(self.registry) do
        for prop, color in pairs(obj.properties) do
            obj.instance[prop] = self.colors[color] or color
        end
    end
end

function Library:drag(frame, area, callback)
    frame.Active = true
    local dragging = false
    local input
    var start
    local pos
    
    local function move(i)
        local delta = i.Position - start
        local new = UDim2.new(
            pos.X.Scale,
            pos.X.Offset + delta.X,
            pos.Y.Scale,
            pos.Y.Offset + delta.Y
        )
        
        local abs = frame.AbsolutePosition
        var size = frame.AbsoluteSize
        local vp = workspace.CurrentCamera.ViewportSize
        
        if abs.X < 0 then
            new = UDim2.new(0, 0, new.Y.Scale, new.Y.Offset)
        elseif abs.X + size.X > vp.X then
            new = UDim2.new(0, vp.X - size.X, new.Y.Scale, new.Y.Offset)
        end
        
        if abs.Y < 0 then
            new = UDim2.new(new.X.Scale, new.X.Offset, 0, 0)
        elseif abs.Y + size.Y > vp.Y then
            new = UDim2.new(new.X.Scale, new.X.Offset, 0, vp.Y - size.Y)
        end
        
        frame.Position = new
        if callback then callback(new) end
    end
    
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if area then
                local abs = frame.AbsolutePosition
                if i.Position.Y - abs.Y > area then return end
            end
            
            dragging = true
            start = i.Position
            pos = frame.Position
            
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            input = i
        end
    end)
    
    InputService.InputChanged:Connect(function(i)
        if i == input and dragging then
            move(i)
        end
    end)
end

function Library:over(frame)
    local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
    return Mouse.X >= pos.X and Mouse.X <= pos.X + size.X
        and Mouse.Y >= pos.Y and Mouse.Y <= pos.Y + size.Y
end

function Library:touchOver(frame, touch)
    local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
    return touch.X >= pos.X and touch.X <= pos.X + size.X
        and touch.Y >= pos.Y and touch.Y <= pos.Y + size.Y
end

function Library:anyOpen()
    for frame in pairs(self.openFrames) do
        if frame.Visible and self:over(frame) then
            return true
        end
    end
    return false
end

do
    function Library:mobileBar()
        if not self.mobile.enabled then return end
        
        self.mobileBar = self:new('Frame', {
            BackgroundColor3 = self.colors.main,
            BorderColor3 = self.colors.accent,
            BorderMode = Enum.BorderMode.Inset,
            Position = UDim2.new(0, 0, 1, -60),
            Size = UDim2.new(1, 0, 0, 60),
            ZIndex = 1000,
            Visible = false,
            Parent = container
        })
        
        self:track(self.mobileBar, {
            BackgroundColor3 = 'main',
            BorderColor3 = 'accent'
        }, true)
        
        self.mobileTabs = self:new('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -70, 1, -10),
            Position = UDim2.new(0, 10, 0, 5),
            ZIndex = 1001,
            Parent = self.mobileBar
        })
        
        self:new('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            Parent = self.mobileTabs
        })
        
        self.mobileClose = self:new('TextButton', {
            Text = "✕",
            Font = Enum.Font.Code,
            TextColor3 = self.colors.text,
            TextSize = 24,
            BackgroundColor3 = self.colors.accentDark,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(1, -55, 0, 5),
            ZIndex = 1002,
            Parent = self.mobileBar
        })
        
        self:track(self.mobileClose, {
            BackgroundColor3 = 'accentDark',
            TextColor3 = 'text'
        }, true)
        
        self.mobileClose.MouseButton1Click:Connect(function()
            for _, win in pairs(getgenv().ArcWindows or {}) do
                if win.holder then
                    win.holder.Visible = false
                end
            end
            self.mobileBar.Visible = false
            if self.float then
                self.float.Visible = true
            end
        end)
        
        self.float = self:new('TextButton', {
            Text = "☰",
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 32,
            BackgroundColor3 = self.colors.accent,
            BorderColor3 = self.colors.accentDark,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 70, 0, 70),
            Position = UDim2.new(0, 20, 1, -90),
            AnchorPoint = Vector2.new(0, 1),
            ZIndex = 1000,
            Parent = container
        })
        
        self:track(self.float, {
            BackgroundColor3 = 'accent',
            BorderColor3 = 'accentDark',
            TextColor3 = 'text'
        }, true)
        
        self:drag(self.float)
        
        self.float.MouseButton1Click:Connect(function()
            for _, win in pairs(getgenv().ArcWindows or {}) do
                if win.holder then
                    win.holder.Visible = not win.holder.Visible
                    self.mobileBar.Visible = win.holder.Visible
                    self.float.Visible = not win.holder.Visible
                end
            end
        end)
    end
    
    function Library:touchGestures()
        if not self.mobile.enabled then return end
        
        local start = nil
        local startTime = nil
        local threshold = 50
        
        InputService.TouchStarted:Connect(function(t, proc)
            if proc then return end
            start = t.Position
            startTime = tick()
        end)
        
        InputService.TouchMoved:Connect(function(t, proc)
            if proc or not start then return end
            
            local delta = (t.Position - start).Magnitude
            if delta > threshold then
                start = nil
            end
        end)
        
        InputService.TouchEnded:Connect(function(t, proc)
            if proc or not start then return end
            
            local delta = (t.Position - start).Magnitude
            
            if delta > threshold then
                for _, win in pairs(getgenv().ArcWindows or {}) do
                    if win.holder then
                        local vis = not win.holder.Visible
                        win.holder.Visible = vis
                        if self.mobileBar then
                            self.mobileBar.Visible = vis
                        end
                        if self.float then
                            self.float.Visible = not vis
                        end
                    end
                end
            end
            
            start = nil
            startTime = nil
        end)
    end
end

function Library:notify(text, duration, cb)
    duration = duration or 5
    
    local width = self:measure(text, Enum.Font.Code, 14) + 20
    if self.mobile.enabled then
        width = math.min(width, 300)
    end
    
    local height = self.mobile.enabled and 50 or 32
    
    local notif = self:new('Frame', {
        BackgroundColor3 = self.colors.black,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, height),
        Position = UDim2.new(0, 10, 1, self.mobile.enabled and -70 or -42),
        AnchorPoint = Vector2.new(0, 1),
        ClipsDescendants = true,
        ZIndex = 1000,
        Parent = container
    })
    
    local inner = self:new('Frame', {
        BackgroundColor3 = self.colors.main,
        BorderColor3 = self.colors.accent,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        ZIndex = 1001,
        Parent = notif
    })
    
    self:track(inner, {
        BackgroundColor3 = 'main',
        BorderColor3 = 'accent'
    }, true)
    
    local bar = self:new('Frame', {
        BackgroundColor3 = self.colors.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        ZIndex = 1002,
        Parent = inner
    })
    
    self:track(bar, { BackgroundColor3 = 'accent' }, true)
    
    local label = self:label({
        Text = text,
        Size = UDim2.new(1, -15, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = self.mobile.enabled,
        TextSize = self.mobile.enabled and 16 or 14,
        ZIndex = 1002,
        Parent = inner
    }, true)
    
    notif:TweenSize(UDim2.new(0, width, 0, height), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    
    task.spawn(function()
        task.wait(duration)
        notif:TweenSize(UDim2.new(0, 0, 0, height), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        task.wait(0.3)
        notif:Destroy()
        if cb then cb() end
    end)
    
    return notif
end

function Library:watermark(text)
    if not self.watermark then
        local h = self.mobile.enabled and 30 or 22
        
        self.watermark = self:new('Frame', {
            BackgroundColor3 = self.colors.black,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 0, h),
            Position = UDim2.new(0, 10, 0, 10),
            ZIndex = 1000,
            Parent = container
        })
        
        local inner = self:new('Frame', {
            BackgroundColor3 = self.colors.main,
            BorderColor3 = self.colors.accent,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            ZIndex = 1001,
            Parent = self.watermark
        })
        
        self:track(inner, {
            BackgroundColor3 = 'main',
            BorderColor3 = 'accent'
        }, true)
        
        self.watermarkText = self:label({
            Text = "",
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = self.mobile.enabled and 16 or 14,
            ZIndex = 1002,
            Parent = inner
        }, true)
        
        self:drag(self.watermark)
    end
    
    local w = self:measure(text, Enum.Font.Code, self.mobile.enabled and 16 or 14) + 12
    self.watermark.Size = UDim2.new(0, w, 0, self.mobile.enabled and 30 or 22)
    self.watermarkText.Text = text
    self.watermark.Visible = true
end

function Library:showWatermark(bool)
    if self.watermark then
        self.watermark.Visible = bool
    end
end

do
    function Library:keybinds()
        if self.keybindFrame then return end
        
        local h = self.mobile.enabled and 30 or 22
        
        self.keybindFrame = self:new('Frame', {
            BackgroundColor3 = self.colors.black,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 250, 0, h),
            Position = UDim2.new(1, -260, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Visible = false,
            ZIndex = 1000,
            Parent = container
        })
        
        local inner = self:new('Frame', {
            BackgroundColor3 = self.colors.main,
            BorderColor3 = self.colors.accent,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            ZIndex = 1001,
            Parent = self.keybindFrame
        })
        
        self:track(inner, {
            BackgroundColor3 = 'main',
            BorderColor3 = 'accent'
        }, true)
        
        local title = self:label({
            Text = "Keybinds",
            Size = UDim2.new(1, 0, 0, h),
            TextSize = self.mobile.enabled and 16 or 14,
            ZIndex = 1002,
            Parent = inner
        }, true)
        
        self.keybindContainer = self:new('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, -h),
            Position = UDim2.new(0, 0, 0, h),
            ZIndex = 1002,
            Parent = inner
        })
        
        self:new('UIListLayout', {
            Padding = UDim.new(0, 2),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.keybindContainer
        })
        
        self:drag(self.keybindFrame)
    end
end

local Element = {}
Element.__index = Element

function Element:setVisible(bool)
    self.container.Visible = bool
end

function Element:kill()
    if self.container then
        self.container:Destroy()
    end
end

function Library:window(opts)
    opts = opts or {}
    
    if self.mobile.enabled then
        opts.Size = opts.Size or UDim2.new(0, 400, 0, 700)
        opts.Position = opts.Position or UDim2.new(0.5, -200, 0.5, -350)
    else
        opts.Size = opts.Size or UDim2.new(0, 550, 0, 600)
        opts.Position = opts.Position or UDim2.new(0.5, -275, 0.5, -300)
    end
    
    local win = {
        tabs = {},
        opts = opts,
        pos = opts.Position,
        size = opts.Size,
        title = opts.Title or "Arc Client",
        center = opts.Center,
    }
    
    win.holder = self:new('Frame', {
        BackgroundColor3 = self.colors.black,
        BorderSizePixel = 0,
        Position = win.pos,
        Size = win.size,
        Visible = opts.AutoShow or false,
        ZIndex = 1,
        Parent = container
    })
    
    win.inner = self:new('Frame', {
        BackgroundColor3 = self.colors.main,
        BorderColor3 = self.colors.accent,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 2,
        Parent = win.holder
    })
    
    self:track(win.inner, {
        BackgroundColor3 = 'main',
        BorderColor3 = 'accent'
    })
    
    local barH = self.mobile.enabled and 40 or 25
    
    win.bar = self:new('Frame', {
        BackgroundColor3 = self.colors.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, barH),
        ZIndex = 3,
        Parent = win.inner
    })
    
    self:track(win.bar, { BackgroundColor3 = 'accent' })
    
    win.titleLabel = self:label({
        Text = win.title,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = self.mobile.enabled and 18 or 16,
        ZIndex = 4,
        Parent = win.bar
    })
    
    win.close = self:new('TextButton', {
        Text = "✕",
        Font = Enum.Font.Code,
        TextColor3 = self.colors.text,
        TextSize = self.mobile.enabled and 24 or 18,
        BackgroundColor3 = self.colors.accentDark,
        BorderSizePixel = 0,
        Size = UDim2.new(0, barH, 1, 0),
        Position = UDim2.new(1, -barH, 0, 0),
        ZIndex = 4,
        Parent = win.bar
    })
    
    win.close.MouseButton1Click:Connect(function()
        win.holder.Visible = false
        if self.mobileBar then
            self.mobileBar.Visible = false
        end
        if self.float then
            self.float.Visible = true
        end
        if win.onClose then win.onClose() end
    end)
    
    local offset = barH + 8
    win.container = self:new('Frame', {
        BackgroundColor3 = self.colors.background,
        BorderColor3 = self.colors.outline,
        Position = UDim2.new(0, 8, 0, offset),
        Size = UDim2.new(1, -16, 1, -(offset + 8)),
        ZIndex = 3,
        Parent = win.inner
    })
    
    self:track(win.container, {
        BackgroundColor3 = 'background',
        BorderColor3 = 'outline'
    })
    
    local tabH = self.mobile.enabled and 40 or 30
    
    win.tabBar = self:new('Frame', {
        BackgroundColor3 = self.colors.background,
        BorderColor3 = self.colors.outline,
        Size = UDim2.new(1, 0, 0, tabH),
        ZIndex = 4,
        Parent = win.container
    })
    
    self:track(win.tabBar, {
        BackgroundColor3 = 'background',
        BorderColor3 = 'outline'
    })
    
    win.tabContainer = self:new('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, -5),
        Position = UDim2.new(0, 5, 0, 5),
        ZIndex = 5,
        Parent = win.tabBar
    })
    
    self:new('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = win.tabContainer
    })
    
    win.content = self:new('ScrollingFrame', {
        BackgroundColor3 = self.colors.main,
        BorderColor3 = self.colors.outline,
        Position = UDim2.new(0, 0, 0, tabH + 5),
        Size = UDim2.new(1, 0, 1, -(tabH + 10)),
        ScrollBarThickness = self.mobile.enabled and 6 or 4,
        ScrollBarImageColor3 = self.colors.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 4,
        Parent = win.container
    })
    
    self:track(win.content, {
        BackgroundColor3 = 'main',
        BorderColor3 = 'outline'
    })
    
    win.left = self:new('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(0.5, -7, 1, -10),
        ZIndex = 5,
        Parent = win.content
    })
    
    win.right = self:new('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 2, 0, 5),
        Size = UDim2.new(0.5, -7, 1, -10),
        ZIndex = 5,
        Parent = win.content
    })
    
    local leftLayout = self:new('UIListLayout', {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = win.left
    })
    
    local rightLayout = self:new('UIListLayout', {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = win.right
    })
    
    local function resizeCanvas()
        local lh = 0
        local rh = 0
        
        for _, c in pairs(win.left:GetChildren()) do
            if not c:IsA('UIListLayout') then
                lh = lh + c.Size.Y.Offset + 5
            end
        end
        
        for _, c in pairs(win.right:GetChildren()) do
            if not c:IsA('UIListLayout') then
                rh = rh + c.Size.Y.Offset + 5
            end
        end
        
        win.content.CanvasSize = UDim2.new(0, 0, 0, math.max(lh, rh) + 10)
    end
    
    leftLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(resizeCanvas)
    rightLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(resizeCanvas)
    
    self:drag(win.holder, barH)
    
    function win:setTitle(t)
        win.titleLabel.Text = t
    end
    
    function win:setVisible(v)
        win.holder.Visible = v
        if Library.mobileBar then
            Library.mobileBar.Visible = v
        end
        if Library.float then
            Library.float.Visible = not v
        end
    end
    
    function win:toggle()
        win.holder.Visible = not win.holder.Visible
        if Library.mobileBar then
            Library.mobileBar.Visible = win.holder.Visible
        end
        if Library.float then
            Library.float.Visible = not win.holder.Visible
        end
    end
    
    function win:tab(name)
        local tab = {
            name = name,
            elements = {},
            boxes = {},
        }
        
        local btnW = self:measure(name, Enum.Font.Code, self.mobile.enabled and 16 or 14) + (self.mobile.enabled and 24 or 16)
        
        local btn = self:new('TextButton', {
            Text = name,
            Font = Enum.Font.Code,
            TextColor3 = self.colors.text,
            TextSize = self.mobile.enabled and 16 or 14,
            BackgroundColor3 = self.colors.main,
            BorderColor3 = self.colors.outline,
            AutoButtonColor = false,
            Size = UDim2.new(0, btnW, 1, -2),
            ZIndex = 6,
            Parent = win.tabContainer
        })
        
        self:track(btn, {
            BackgroundColor3 = 'main',
            BorderColor3 = 'outline',
            TextColor3 = 'text'
        })
        
        tab.container = self:new('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 5,
            Parent = win.content
        })
        
        if self.mobile.enabled and self.mobileBar then
            local mobileBtn = self:new('TextButton', {
                Text = name,
                Font = Enum.Font.Code,
                TextColor3 = self.colors.text,
                TextSize = 18,
                BackgroundColor3 = self.colors.main,
                BorderColor3 = self.colors.outline,
                Size = UDim2.new(0, 100, 0, 45),
                ZIndex = 1002,
                Parent = self.mobileTabs
            })
            
            self:track(mobileBtn, {
                BackgroundColor3 = 'main',
                BorderColor3 = 'outline',
                TextColor3 = 'text'
            }, true)
            
            mobileBtn.MouseButton1Click:Connect(function()
                for _, b in pairs(self.mobileTabs:GetChildren()) do
                    if b:IsA('TextButton') then
                        b.BackgroundColor3 = self.colors.main
                        b.TextColor3 = self.colors.text
                    end
                end
                mobileBtn.BackgroundColor3 = self.colors.accent
                mobileBtn.TextColor3 = Color3.new(1, 1, 1)
                btn:Click()
            end)
            
            tab.mobileBtn = mobileBtn
        end
        
        btn.MouseButton1Click:Connect(function()
            for _, other in pairs(win.tabs) do
                if other.btn then
                    other.btn.BackgroundColor3 = self.colors.main
                    other.btn.TextColor3 = self.colors.text
                end
                if other.container then
                    other.container.Visible = false
                end
                if self.mobile.enabled and other.mobileBtn then
                    other.mobileBtn.BackgroundColor3 = self.colors.main
                    other.mobileBtn.TextColor3 = self.colors.text
                end
            end
            
            btn.BackgroundColor3 = self.colors.accent
            btn.TextColor3 = Color3.new(1, 1, 1)
            tab.container.Visible = true
            
            if self.mobile.enabled and tab.mobileBtn then
                tab.mobileBtn.BackgroundColor3 = self.colors.accent
                tab.mobileBtn.TextColor3 = Color3.new(1, 1, 1)
            end
        end)
        
        tab.btn = btn
        
        function tab:leftGroup(name)
            return self:group({
                name = name,
                side = "left"
            })
        end
        
        function tab:rightGroup(name)
            return self:group({
                name = name,
                side = "right"
            })
        end
        
        function tab:group(info)
            local group = {
                name = info.name,
                elements = {},
            }
            
            group.container = self:new('Frame', {
                BackgroundColor3 = self.colors.background,
                BorderColor3 = self.colors.outline,
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 6,
                Parent = (info.side == "left" and win.left or win.right)
            })
            
            self:track(group.container, {
                BackgroundColor3 = 'background',
                BorderColor3 = 'outline'
            })
            
            local headerH = self.mobile.enabled and 35 or 20
            
            local header = self:new('Frame', {
                BackgroundColor3 = self.colors.accent,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, headerH),
                ZIndex = 7,
                Parent = group.container
            })
            
            self:track(header, { BackgroundColor3 = 'accent' })
            
            local title = self:label({
                Text = info.name,
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = self.mobile.enabled and 16 or 14,
                ZIndex = 8,
                Parent = header
            })
            
            group.content = self:new('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 5, 0, headerH + 5),
                Size = UDim2.new(1, -10, 1, -(headerH + 10)),
                ZIndex = 7,
                Parent = group.container
            })
            
            local contentList = self:new('UIListLayout', {
                Padding = UDim.new(0, self.mobile.enabled and 5 or 3),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = group.content
            })
            
            function group:resize()
                local h = headerH + 10
                for _, c in pairs(group.content:GetChildren()) do
                    if not c:IsA('UIListLayout') then
                        h = h + c.Size.Y.Offset + (self.mobile.enabled and 5 or 3)
                    end
                end
                group.container.Size = UDim2.new(1, 0, 0, h)
                resizeCanvas()
            end
            
            function group:toggle(id, info)
                local toggle = {
                    value = info.Default or false,
                    id = id,
                }
                
                local elH = self.mobile.enabled and 45 or 25
                
                local cont = self:new('Frame', {
                    BackgroundColor3 = self.colors.main,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, 0, 0, elH),
                    ZIndex = 7,
                    Parent = group.content
                })
                
                self:track(cont, {
                    BackgroundColor3 = 'main',
                    BorderColor3 = 'outline'
                })
                
                local togW = self.mobile.enabled and 60 or 40
                local togH = self.mobile.enabled and 25 or 15
                local knobS = self.mobile.enabled and 19 or 11
                
                local tog = self:new('Frame', {
                    BackgroundColor3 = toggle.value and self.colors.accent or self.colors.background,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(0, togW, 0, togH),
                    Position = UDim2.new(0, 5, 0.5, -togH/2),
                    ZIndex = 8,
                    Parent = cont
                })
                
                self:track(tog, {
                    BackgroundColor3 = toggle.value and 'accent' or 'background',
                    BorderColor3 = 'outline'
                })
                
                local knob = self:new('Frame', {
                    BackgroundColor3 = self.colors.text,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, knobS, 0, knobS),
                    Position = UDim2.new(toggle.value and 1 or 0, toggle.value and -(knobS+2) or 2, 0.5, -knobS/2),
                    ZIndex = 9,
                    Parent = tog
                })
                
                self:track(knob, { BackgroundColor3 = 'text' })
                
                local label = self:label({
                    Text = info.Text,
                    Size = UDim2.new(1, -(togW + 15), 1, 0),
                    Position = UDim2.new(0, togW + 10, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = self.mobile.enabled and 16 or 14,
                    ZIndex = 8,
                    Parent = cont
                })
                
                function toggle:set(v)
                    toggle.value = v
                    tog.BackgroundColor3 = v and self.colors.accent or self.colors.background
                    knob.Position = UDim2.new(v and 1 or 0, v and -(knobS+2) or 2, 0.5, -knobS/2)
                    if toggle.changed then toggle.changed(v) end
                    Flags[id] = v
                end
                
                function toggle:onChange(cb)
                    toggle.changed = cb
                end
                
                cont.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        toggle:set(not toggle.value)
                        self:save()
                    end
                end)
                
                Toggles[id] = toggle
                Flags[id] = toggle.value
                
                group:resize()
                return toggle
            end
            
            function group:button(text, cb)
                local btn = {}
                
                local elH = self.mobile.enabled and 45 or 25
                
                local cont = self:new('Frame', {
                    BackgroundColor3 = self.colors.main,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, 0, 0, elH),
                    ZIndex = 7,
                    Parent = group.content
                })
                
                self:track(cont, {
                    BackgroundColor3 = 'main',
                    BorderColor3 = 'outline'
                })
                
                local txt = self:label({
                    Text = text,
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = self.mobile.enabled and 16 or 14,
                    ZIndex = 8,
                    Parent = cont
                })
                
                cont.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        if cb then cb() end
                    end
                end)
                
                cont.MouseEnter:Connect(function()
                    cont.BackgroundColor3 = self.colors.accent
                end)
                
                cont.MouseLeave:Connect(function()
                    cont.BackgroundColor3 = self.colors.main
                end)
                
                group:resize()
                return btn
            end
            
            function group:slider(id, info)
                local slider = {
                    value = info.Default or info.Min or 0,
                    min = info.Min or 0,
                    max = info.Max or 100,
                    round = info.Rounding or 1,
                    id = id,
                }
                
                local elH = self.mobile.enabled and 60 or 35
                
                local cont = self:new('Frame', {
                    BackgroundColor3 = self.colors.main,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, 0, 0, elH),
                    ZIndex = 7,
                    Parent = group.content
                })
                
                self:track(cont, {
                    BackgroundColor3 = 'main',
                    BorderColor3 = 'outline'
                })
                
                local labelY = self.mobile.enabled and 5 or 2
                local sliderY = self.mobile.enabled and 35 or 22
                
                if not info.Compact then
                    local label = self:label({
                        Text = info.Text,
                        Size = UDim2.new(1, -10, 0, 20),
                        Position = UDim2.new(0, 5, 0, labelY),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = self.mobile.enabled and 16 or 14,
                        ZIndex = 8,
                        Parent = cont
                    })
                end
                
                local valLabel = self:label({
                    Text = tostring(slider.value),
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -65, 0, labelY),
                    TextSize = self.mobile.enabled and 16 or 14,
                    ZIndex = 8,
                    Parent = cont
                })
                
                local bar = self:new('Frame', {
                    BackgroundColor3 = self.colors.background,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, -80, 0, self.mobile.enabled and 12 or 8),
                    Position = UDim2.new(0, 5, 0, sliderY),
                    ZIndex = 8,
                    Parent = cont
                })
                
                self:track(bar, {
                    BackgroundColor3 = 'background',
                    BorderColor3 = 'outline'
                })
                
                local fill = self:new('Frame', {
                    BackgroundColor3 = self.colors.accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = 9,
                    Parent = bar
                })
                
                self:track(fill, { BackgroundColor3 = 'accent' })
                
                local function update()
                    local p = (slider.value - slider.min) / (slider.max - slider.min)
                    local w = bar.AbsoluteSize.X * p
                    fill.Size = UDim2.new(0, w, 1, 0)
                    valLabel.Text = tostring(self:round(slider.value, slider.round))
                end
                
                function slider:set(v)
                    slider.value = math.clamp(v, slider.min, slider.max)
                    update()
                    if slider.changed then slider.changed(slider.value) end
                    Flags[id] = slider.value
                end
                
                function slider:onChange(cb)
                    slider.changed = cb
                end
                
                local dragging = false
                bar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        
                        if self.mobile.enabled then
                            local conn
                            conn = RunService.Heartbeat:Connect(function()
                                if not dragging then conn:Disconnect() return end
                                local touch = InputService:GetTouchInput()
                                if touch then
                                    local barX = bar.AbsolutePosition.X
                                    local barW = bar.AbsoluteSize.X
                                    local p = math.clamp((touch.X - barX) / barW, 0, 1)
                                    local v = self:map(p, 0, 1, slider.min, slider.max)
                                    slider:set(v)
                                end
                            end)
                        else
                            while dragging and RenderStepped:Wait() do
                                local barX = bar.AbsolutePosition.X
                                local barW = bar.AbsoluteSize.X
                                local p = math.clamp((Mouse.X - barX) / barW, 0, 1)
                                local v = self:map(p, 0, 1, slider.min, slider.max)
                                slider:set(v)
                            end
                        end
                    end
                end)
                
                local function stop(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        self:save()
                    end
                end
                
                InputService.InputEnded:Connect(stop)
                
                update()
                Options[id] = slider
                Flags[id] = slider.value
                
                group:resize()
                return slider
            end
            
            function group:dropdown(id, info)
                local drop = {
                    values = info.Values or {},
                    value = info.Multi and {} or (info.Default and info.Values[info.Default] or nil),
                    multi = info.Multi or false,
                    open = false,
                    id = id,
                }
                
                local elH = self.mobile.enabled and 45 or 25
                
                local cont = self:new('Frame', {
                    BackgroundColor3 = self.colors.main,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, 0, 0, elH),
                    ZIndex = 7,
                    Parent = group.content
                })
                
                self:track(cont, {
                    BackgroundColor3 = 'main',
                    BorderColor3 = 'outline'
                })
                
                local label = self:label({
                    Text = info.Text,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = self.mobile.enabled and 16 or 14,
                    ZIndex = 8,
                    Parent = cont
                })
                
                local arrow = self:label({
                    Text = "▼",
                    Size = UDim2.new(0, 30, 1, 0),
                    Position = UDim2.new(1, -35, 0, 0),
                    TextSize = self.mobile.enabled and 18 or 12,
                    ZIndex = 8,
                    Parent = cont
                })
                
                local list = self:new('Frame', {
                    BackgroundColor3 = self.colors.background,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, -10, 0, 0),
                    Position = UDim2.new(0, 5, 0, elH + 5),
                    Visible = false,
                    ZIndex = 100,
                    Parent = group.content.Parent.Parent
                })
                
                self:track(list, {
                    BackgroundColor3 = 'background',
                    BorderColor3 = 'outline'
                })
                
                local scroll = self:new('ScrollingFrame', {
                    BackgroundTransparency = 1,
                    ScrollBarThickness = self.mobile.enabled and 6 or 4,
                    ScrollBarImageColor3 = self.colors.accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    Position = UDim2.new(0, 1, 0, 1),
                    ZIndex = 101,
                    Parent = list
                })
                
                local layout = self:new('UIListLayout', {
                    Padding = UDim.new(0, 0),
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = scroll
                })
                
                function drop:update()
                    if drop.multi then
                        local sel = {}
                        for v, e in pairs(drop.value) do
                            if e then table.insert(sel, v) end
                        end
                        label.Text = info.Text .. ": " .. (#sel > 0 and table.concat(sel, ", ") or "None")
                    else
                        label.Text = info.Text .. ": " .. (drop.value or "None")
                    end
                end
                
                function drop:toggle()
                    drop.open = not drop.open
                    list.Visible = drop.open
                    arrow.Text = drop.open and "▲" or "▼"
                    
                    if drop.open then
                        self.openFrames[list] = true
                    else
                        self.openFrames[list] = nil
                    end
                end
                
                function drop:set(v)
                    if drop.multi then
                        if type(v) == "table" then
                            drop.value = v
                        end
                    else
                        drop.value = v
                    end
                    drop:update()
                    if drop.changed then drop.changed(drop.value) end
                    Flags[id] = drop.value
                end
                
                function drop:onChange(cb)
                    drop.changed = cb
                end
                
                local itemH = self.mobile.enabled and 40 or 20
                
                for i, v in ipairs(info.Values) do
                    local item = self:new('TextButton', {
                        Text = v,
                        Font = Enum.Font.Code,
                        TextColor3 = self.colors.text,
                        TextSize = self.mobile.enabled and 16 or 14,
                        BackgroundColor3 = self.colors.main,
                        BorderColor3 = self.colors.outline,
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, itemH),
                        ZIndex = 102,
                        Parent = scroll
                    })
                    
                    self:track(item, {
                        BackgroundColor3 = 'main',
                        BorderColor3 = 'outline',
                        TextColor3 = 'text'
                    })
                    
                    item.MouseButton1Click:Connect(function()
                        if drop.multi then
                            drop.value[v] = not drop.value[v]
                            item.TextColor3 = drop.value[v] and self.colors.accent or self.colors.text
                        else
                            drop:set(v)
                            drop:toggle()
                            
                            for _, other in pairs(scroll:GetChildren()) do
                                if other:IsA('TextButton') then
                                    other.TextColor3 = self.colors.text
                                end
                            end
                            item.TextColor3 = self.colors.accent
                        end
                        
                        drop:update()
                        self:save()
                    end)
                    
                    if not drop.multi and info.Default == i then
                        item.TextColor3 = self.colors.accent
                    elseif drop.multi and info.Default and info.Default[v] then
                        drop.value[v] = true
                        item.TextColor3 = self.colors.accent
                    end
                end
                
                layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    local maxH = self.mobile.enabled and 200 or 150
                    local h = math.min(#info.Values * itemH, maxH)
                    list.Size = UDim2.new(1, -10, 0, h)
                    scroll.CanvasSize = UDim2.new(0, 0, 0, #info.Values * itemH)
                end)
                
                cont.InputBegan:Connect(function(i)
                    if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) 
                        and not self:anyOpen() then
                        drop:toggle()
                    end
                end)
                
                InputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        if drop.open then
                            local pos = i.Position
                            if not self:touchOver(list, pos) and not self:touchOver(cont, pos) then
                                drop:toggle()
                            end
                        end
                    end
                end)
                
                drop:update()
                Options[id] = drop
                Flags[id] = drop.value
                
                group:resize()
                return drop
            end
            
            function group:input(id, info)
                local input = {
                    value = info.Default or "",
                    id = id,
                }
                
                local elH = self.mobile.enabled and 70 or 45
                
                local cont = self:new('Frame', {
                    BackgroundColor3 = self.colors.main,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, 0, 0, elH),
                    ZIndex = 7,
                    Parent = group.content
                })
                
                self:track(cont, {
                    BackgroundColor3 = 'main',
                    BorderColor3 = 'outline'
                })
                
                local label = self:label({
                    Text = info.Text,
                    Size = UDim2.new(1, -10, 0, 20),
                    Position = UDim2.new(0, 5, 0, 2),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = self.mobile.enabled and 16 or 14,
                    ZIndex = 8,
                    Parent = cont
                })
                
                local box = self:new('TextBox', {
                    Text = info.Default or "",
                    PlaceholderText = info.Placeholder or "",
                    Font = Enum.Font.Code,
                    TextColor3 = self.colors.text,
                    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                    BackgroundColor3 = self.colors.background,
                    BorderColor3 = self.colors.outline,
                    Size = UDim2.new(1, -10, 0, self.mobile.enabled and 35 or 20),
                    Position = UDim2.new(0, 5, 0, 25),
                    TextSize = self.mobile.enabled and 18 or 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    ZIndex = 8,
                    Parent = cont
                })
                
                self:track(box, {
                    TextColor3 = 'text',
                    BackgroundColor3 = 'background',
                    BorderColor3 = 'outline'
                })
                
                function input:set(v)
                    if info.Numeric then
                        v = v:gsub("[^%d.]", "")
                    end
                    
                    if info.MaxLength and #v > info.MaxLength then
                        v = v:sub(1, info.MaxLength)
                    end
                    
                    input.value = v
                    box.Text = v
                    if input.changed then input.changed(v) end
                    Flags[id] = v
                end
                
                function input:onChange(cb)
                    input.changed = cb
                end
                
                box.FocusLost:Connect(function(enter)
                    if not info.Finished or enter then
                        input:set(box.Text)
                        self:save()
                    end
                end)
                
                Options[id] = input
                Flags[id] = input.value
                
                group:resize()
                return input
            end
            
            function group:label(text, wrap)
                local label = self:label({
                    Text = text,
                    Size = UDim2.new(1, -10, 0, wrap and 0 or (self.mobile.enabled and 25 or 15)),
                    Position = UDim2.new(0, 5, 0, 2),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = self.mobile.enabled and 16 or 14,
                    TextWrapped = wrap,
                    ZIndex = 8,
                    Parent = group.content
                })
                
                if wrap then
                    local function updateH()
                        local bounds = TextService:GetTextSize(
                            text,
                            self.mobile.enabled and 16 or 14,
                            Enum.Font.Code,
                            Vector2.new(label.AbsoluteSize.X, 1000)
                        )
                        label.Size = UDim2.new(1, -10, 0, bounds.Y + (self.mobile.enabled and 8 or 4))
                        group:resize()
                    end
                    
                    label:GetPropertyChangedSignal('AbsoluteSize'):Connect(updateH)
                    task.spawn(updateH)
                end
                
                group:resize()
                return label
            end
            
            function group:divider()
                local div = self:new('Frame', {
                    BackgroundColor3 = self.colors.outline,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 0, 1),
                    Position = UDim2.new(0, 5, 0, 2),
                    ZIndex = 8,
                    Parent = group.content
                })
                
                group:resize()
                return div
            end
            
            table.insert(win.tabs, tab)
            self.tabs[name] = tab
            
            if #win.tabs == 1 then
                btn.BackgroundColor3 = self.colors.accent
                btn.TextColor3 = Color3.new(1, 1, 1)
                tab.container.Visible = true
                if self.mobile.enabled and tab.mobileBtn then
                    tab.mobileBtn.BackgroundColor3 = self.colors.accent
                    tab.mobileBtn.TextColor3 = Color3.new(1, 1, 1)
                end
            end
            
            return tab
        end
        
        return tab
    end
    
    if win.center then
        win.holder.Position = UDim2.new(0.5, -win.size.X.Offset/2, 0.5, -win.size.Y.Offset/2)
    end
    
    return win
end

function Library:save()
    if self.SaveManager then
        self.SaveManager:Save()
    end
end

function Library:onUnload(cb)
    table.insert(self.callbacks, cb)
end

function Library:unload()
    self.state.unloaded = true
    for _, cb in ipairs(self.callbacks) do
        pcall(cb)
    end
    container:Destroy()
end

Library:mobileBar()
Library:touchGestures()
Library:keybinds()

InputService.InputBegan:Connect(function(i, proc)
    if proc then return end
    
    if Library.ToggleKeybind then
        local key = Library.ToggleKeybind.value
        if key then
            if i.KeyCode == Enum.KeyCode[key] or 
               (key == "MB1" and i.UserInputType == Enum.UserInputType.MouseButton1) or
               (key == "MB2" and i.UserInputType == Enum.UserInputType.MouseButton2) or
               (Library.mobile.enabled and i.UserInputType == Enum.UserInputType.Touch) then
                
                for _, win in pairs(getgenv().ArcWindows or {}) do
                    if win.holder then
                        local vis = not win.holder.Visible
                        win.holder.Visible = vis
                        if Library.mobileBar then
                            Library.mobileBar.Visible = vis
                        end
                        if Library.float then
                            Library.float.Visible = not vis
                        end
                    end
                end
            end
        end
    end
end)

getgenv().ArcWindows = getgenv().ArcWindows or {}
getgenv().Library = Library

return Library
