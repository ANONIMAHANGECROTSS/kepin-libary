--[[
    ╔══════════════════════════════════════════════════════╗
    ║         LIQUID GLASS UI LIBRARY v1.0                ║
    ║         JAROT404 × KVNXY Team                       ║
    ║         Premium Smooth Roblox UI Framework          ║
    ╚══════════════════════════════════════════════════════╝

    USAGE:
        local LiquidGlass = loadstring(...)()
        local Window = LiquidGlass:CreateWindow({ Title = "My Hub" })
        local Tab = Window:AddTab("Main")
        Tab:AddButton({ Text = "Click Me", Callback = function() end })
--]]

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

-- ╔══════════════════════════════╗
-- ║        SERVICES              ║
-- ╚══════════════════════════════╝
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ╔══════════════════════════════╗
-- ║        THEME CONFIG          ║
-- ╚══════════════════════════════╝
local Theme = {
    -- Glass base
    GlassBackground  = Color3.fromRGB(12, 12, 16),
    GlassSurface     = Color3.fromRGB(255, 255, 255),
    GlassBorder      = Color3.fromRGB(255, 255, 255),

    -- Accent
    Accent           = Color3.fromRGB(120, 180, 255),
    AccentGlow       = Color3.fromRGB(80, 140, 255),
    AccentDark       = Color3.fromRGB(40, 100, 220),

    -- Text
    TextPrimary      = Color3.fromRGB(255, 255, 255),
    TextSecondary    = Color3.fromRGB(180, 190, 210),
    TextMuted        = Color3.fromRGB(100, 115, 140),

    -- States
    Success          = Color3.fromRGB(100, 220, 160),
    Warning          = Color3.fromRGB(255, 190, 80),
    Danger           = Color3.fromRGB(255, 90, 100),

    -- Opacity levels
    GlassOpacity     = 0.08,   -- Main glass fill
    BorderOpacity    = 0.18,   -- Border transparency
    ShadowOpacity    = 0.60,   -- Drop shadow

    -- Animation
    TweenSpeed       = 0.22,
    TweenStyle       = Enum.EasingStyle.Quint,
    TweenDirection   = Enum.EasingDirection.Out,
}

-- ╔══════════════════════════════╗
-- ║        UTILITIES             ║
-- ╚══════════════════════════════╝
local Util = {}

function Util.Tween(obj, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or Theme.TweenSpeed,
        style or Theme.TweenStyle,
        dir or Theme.TweenDirection
    )
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function Util.GlassColor(color, alpha)
    return Color3.new(color.R, color.G, color.B)
end

function Util.MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Util.Tween(frame, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }, 0.08)
        end
    end)
end

function Util.Ripple(parent, x, y)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.75
    ripple.BorderSizePixel = 0
    ripple.ZIndex = parent.ZIndex + 10
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    ripple.Parent = parent

    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2

    Util.Tween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, 0.5,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- ╔══════════════════════════════╗
-- ║     CREATE BASE GLASS FRAME  ║
-- ╚══════════════════════════════╝
local function MakeGlassFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Theme.GlassSurface
    frame.BackgroundTransparency = 1 - Theme.GlassOpacity
    frame.BorderSizePixel = 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ClipsDescendants = props.ClipsDescendants or false
    frame.ZIndex = props.ZIndex or 1

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.Radius or UDim.new(0, 12)
    corner.Parent = frame

    -- Glass border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.GlassBorder
    stroke.Transparency = 1 - Theme.BorderOpacity
    stroke.Thickness = props.BorderThickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    return frame, stroke
end

-- ╔══════════════════════════════╗
-- ║        WINDOW CLASS          ║
-- ╚══════════════════════════════╝
local Window = {}
Window.__index = Window

function LiquidGlass:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Window)

    self.Title    = config.Title    or "Liquid Glass"
    self.Subtitle = config.Subtitle or "JAROT404 × KVNXY"
    self.Width    = config.Width    or 520
    self.Height   = config.Height   or 400
    self.Tabs     = {}
    self.ActiveTab = nil

    -- ── Root ScreenGui ──
    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlassUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    -- ── Blur Effect ──
    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = game:GetService("Lighting")
    self._blur = blur

    -- ── Ambient shadow ──
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.4
    shadowFrame.BorderSizePixel = 0
    shadowFrame.Size = UDim2.new(0, self.Width + 40, 0, self.Height + 40)
    shadowFrame.Position = UDim2.new(0.5, -(self.Width/2) - 20, 0.5, -(self.Height/2) - 10)
    shadowFrame.ZIndex = 1
    shadowFrame.Parent = gui

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadowFrame

    -- ── Main Window Frame ──
    local winFrame, winStroke = MakeGlassFrame({
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        Radius = UDim.new(0, 16),
        ClipsDescendants = true,
        ZIndex = 2,
    })
    winFrame.Name = "MainWindow"
    winFrame.Parent = gui
    self._winFrame = winFrame

    -- Frosted inner gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 35, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 22)),
    })
    gradient.Rotation = 135
    gradient.Parent = winFrame

    -- ── Top highlight line ──
    local topLine = Instance.new("Frame")
    topLine.Name = "TopHighlight"
    topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topLine.BackgroundTransparency = 0.6
    topLine.BorderSizePixel = 0
    topLine.Size = UDim2.new(0.7, 0, 0, 1)
    topLine.Position = UDim2.new(0.15, 0, 0, 0)
    topLine.ZIndex = 10
    topLine.Parent = winFrame

    -- ── Titlebar ──
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleBar.BackgroundTransparency = 0.94
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.ZIndex = 3
    titleBar.Parent = winFrame

    -- Bottom border of titlebar
    local titleBorder = Instance.new("Frame")
    titleBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleBorder.BackgroundTransparency = 0.82
    titleBorder.BorderSizePixel = 0
    titleBorder.Size = UDim2.new(1, 0, 0, 1)
    titleBorder.Position = UDim2.new(0, 0, 1, -1)
    titleBorder.ZIndex = 4
    titleBorder.Parent = titleBar

    -- Accent dot
    local accentDot = Instance.new("Frame")
    accentDot.BackgroundColor3 = Theme.Accent
    accentDot.BorderSizePixel = 0
    accentDot.Size = UDim2.new(0, 6, 0, 6)
    accentDot.Position = UDim2.new(0, 16, 0.5, -3)
    accentDot.ZIndex = 5
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = accentDot
    accentDot.Parent = titleBar

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 30, 0, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = self.Title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 5
    titleLabel.Parent = titleBar

    -- Subtitle
    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Subtitle"
    subLabel.BackgroundTransparency = 1
    subLabel.Size = UDim2.new(1, -100, 1, 0)
    subLabel.Position = UDim2.new(0, 0, 0, 0)
    subLabel.Font = Enum.Font.Gotham
    subLabel.Text = self.Subtitle
    subLabel.TextColor3 = Theme.TextMuted
    subLabel.TextSize = 11
    subLabel.TextXAlignment = Enum.TextXAlignment.Right
    subLabel.ZIndex = 5
    subLabel.Parent = titleBar

    -- Padding for subtitle
    local subPadding = Instance.new("UIPadding")
    subPadding.PaddingRight = UDim.new(0, 14)
    subPadding.Parent = subLabel

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.Size = UDim2.new(0, 14, 0, 14)
    closeBtn.Position = UDim2.new(1, -50, 0.5, -7)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.ZIndex = 6
    closeBtn.BorderSizePixel = 0
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(1, 0)
    closeBtnCorner.Parent = closeBtn
    closeBtn.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinBtn"
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 50)
    minBtn.BackgroundTransparency = 0.3
    minBtn.Size = UDim2.new(0, 14, 0, 14)
    minBtn.Position = UDim2.new(1, -70, 0.5, -7)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 12
    minBtn.ZIndex = 6
    minBtn.BorderSizePixel = 0
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(1, 0)
    minBtnCorner.Parent = minBtn
    minBtn.Parent = titleBar

    self._minimized = false
    local contentOriginalSize = UDim2.new(0, self.Width, 0, self.Height)

    minBtn.MouseButton1Click:Connect(function()
        self._minimized = not self._minimized
        if self._minimized then
            Util.Tween(winFrame, { Size = UDim2.new(0, self.Width, 0, 48) }, 0.3)
        else
            Util.Tween(winFrame, { Size = contentOriginalSize }, 0.3)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Util.Tween(winFrame, { Size = UDim2.new(0, self.Width, 0, 0), BackgroundTransparency = 1 }, 0.25)
        task.delay(0.3, function() gui:Destroy() end)
    end)

    -- Drag
    Util.MakeDraggable(winFrame, titleBar)

    -- ── Tab Bar ──
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabBar.BackgroundTransparency = 0.96
    tabBar.BorderSizePixel = 0
    tabBar.Size = UDim2.new(1, 0, 0, 38)
    tabBar.Position = UDim2.new(0, 0, 0, 48)
    tabBar.ZIndex = 3
    tabBar.Parent = winFrame

    local tabBorderBottom = Instance.new("Frame")
    tabBorderBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabBorderBottom.BackgroundTransparency = 0.86
    tabBorderBottom.BorderSizePixel = 0
    tabBorderBottom.Size = UDim2.new(1, 0, 0, 1)
    tabBorderBottom.Position = UDim2.new(0, 0, 1, -1)
    tabBorderBottom.ZIndex = 4
    tabBorderBottom.Parent = tabBar

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Padding = UDim.new(0, 2)
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center
    tabList.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.Parent = tabBar

    self._tabBar = tabBar

    -- ── Content Area ──
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Size = UDim2.new(1, 0, 1, -88)
    contentArea.Position = UDim2.new(0, 0, 0, 88)
    contentArea.ZIndex = 3
    contentArea.ClipsDescendants = true
    contentArea.Parent = winFrame
    self._contentArea = contentArea

    -- Entrance animation
    winFrame.Size = UDim2.new(0, self.Width, 0, 0)
    winFrame.BackgroundTransparency = 1
    Util.Tween(winFrame, {
        Size = contentOriginalSize,
        BackgroundTransparency = 1 - Theme.GlassOpacity
    }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return self
end

-- ╔══════════════════════════════╗
-- ║         ADD TAB              ║
-- ╚══════════════════════════════╝
function Window:AddTab(name, icon)
    local tabData = { Name = name, Elements = {} }

    -- Tab button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "Tab"
    tabBtn.BackgroundColor3 = Theme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(0, 0, 1, -8)
    tabBtn.AutomaticSize = Enum.AutomaticSize.X
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Text = (icon and icon .. "  " or "") .. name
    tabBtn.TextColor3 = Theme.TextMuted
    tabBtn.TextSize = 12
    tabBtn.ZIndex = 4
    tabBtn.Parent = self._tabBar

    local tabBtnPad = Instance.new("UIPadding")
    tabBtnPad.PaddingLeft = UDim.new(0, 12)
    tabBtnPad.PaddingRight = UDim.new(0, 12)
    tabBtnPad.Parent = tabBtn

    local tabBtnCorner = Instance.new("UICorner")
    tabBtnCorner.CornerRadius = UDim.new(0, 6)
    tabBtnCorner.Parent = tabBtn

    -- Active indicator line
    local activeBar = Instance.new("Frame")
    activeBar.BackgroundColor3 = Theme.Accent
    activeBar.BorderSizePixel = 0
    activeBar.Size = UDim2.new(0.7, 0, 0, 2)
    activeBar.Position = UDim2.new(0.15, 0, 1, -1)
    activeBar.BackgroundTransparency = 1
    activeBar.ZIndex = 5
    local activeBarCorner = Instance.new("UICorner")
    activeBarCorner.CornerRadius = UDim.new(1, 0)
    activeBarCorner.Parent = activeBar
    activeBar.Parent = tabBtn

    -- Tab content page
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.ScrollBarImageTransparency = 0.4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 3
    page.Parent = self._contentArea

    local pageList = Instance.new("UIListLayout")
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, 8)
    pageList.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft = UDim.new(0, 12)
    pagePad.PaddingRight = UDim.new(0, 12)
    pagePad.PaddingTop = UDim.new(0, 10)
    pagePad.PaddingBottom = UDim.new(0, 10)
    pagePad.Parent = page

    tabData._btn = tabBtn
    tabData._page = page
    tabData._activeBar = activeBar

    -- Tab switching
    tabBtn.MouseButton1Click:Connect(function()
        self:_SwitchTab(tabData)
    end)

    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabData then
            Util.Tween(tabBtn, { TextColor3 = Theme.TextSecondary }, 0.15)
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then
            Util.Tween(tabBtn, { TextColor3 = Theme.TextMuted }, 0.15)
        end
    end)

    table.insert(self.Tabs, tabData)

    if #self.Tabs == 1 then
        self:_SwitchTab(tabData)
    end

    -- Tab API
    local Tab = {}
    Tab._page = page
    Tab._order = 0

    -- ── SECTION LABEL ──
    function Tab:AddSection(text)
        local section = Instance.new("Frame")
        section.BackgroundTransparency = 1
        section.BorderSizePixel = 0
        section.Size = UDim2.new(1, 0, 0, 28)
        section.ZIndex = 4
        section.LayoutOrder = Tab._order
        Tab._order += 1
        section.Parent = page

        local line = Instance.new("Frame")
        line.BackgroundColor3 = Theme.TextMuted
        line.BackgroundTransparency = 0.75
        line.BorderSizePixel = 0
        line.Size = UDim2.new(1, -80, 0, 1)
        line.Position = UDim2.new(0, 0, 0.5, 0)
        line.ZIndex = 4
        line.Parent = section

        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Theme.GlassBackground
        label.BackgroundTransparency = 0
        label.BorderSizePixel = 0
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Position = UDim2.new(0, 10, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.Text = text:upper()
        label.TextColor3 = Theme.Accent
        label.TextSize = 10
        label.ZIndex = 5
        label.Parent = section

        local labelPad = Instance.new("UIPadding")
        labelPad.PaddingLeft = UDim.new(0, 4)
        labelPad.PaddingRight = UDim.new(0, 4)
        labelPad.Parent = label
    end

    -- ── BUTTON ──
    function Tab:AddButton(config)
        config = config or {}
        local btn, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 42),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        btn.LayoutOrder = Tab._order
        Tab._order += 1
        btn.Name = "Button"
        btn.ClipsDescendants = true

        local icon = Instance.new("TextLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.Position = UDim2.new(0, 10, 0, 0)
        icon.Font = Enum.Font.GothamBold
        icon.Text = config.Icon or "▶"
        icon.TextColor3 = Theme.Accent
        icon.TextSize = 14
        icon.ZIndex = 5
        icon.Parent = btn

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 42, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Button"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = btn

        local click = Instance.new("TextButton")
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""
        click.ZIndex = 6
        click.Parent = btn

        click.MouseEnter:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 0.88 }, 0.15)
        end)
        click.MouseLeave:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 1 - Theme.GlassOpacity }, 0.2)
        end)
        click.MouseButton1Down:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 0.80 }, 0.08)
            Util.Ripple(btn, Mouse.X, Mouse.Y)
        end)
        click.MouseButton1Up:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 0.88 }, 0.1)
        end)
        click.MouseButton1Click:Connect(function()
            if config.Callback then
                pcall(config.Callback)
            end
        end)

        btn.Parent = page
        return btn
    end

    -- ── TOGGLE ──
    function Tab:AddToggle(config)
        config = config or {}
        local state = config.Default or false

        local row, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 42),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        row.LayoutOrder = Tab._order
        Tab._order += 1
        row.Name = "Toggle"

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Toggle"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = row

        if config.Description then
            label.Size = UDim2.new(1, -70, 0, 22)
            label.Position = UDim2.new(0, 14, 0, 6)

            local desc = Instance.new("TextLabel")
            desc.BackgroundTransparency = 1
            desc.Size = UDim2.new(1, -70, 0, 14)
            desc.Position = UDim2.new(0, 14, 0, 24)
            desc.Font = Enum.Font.Gotham
            desc.Text = config.Description
            desc.TextColor3 = Theme.TextMuted
            desc.TextSize = 11
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.ZIndex = 5
            desc.Parent = row
        end

        -- Track (pill background)
        local track = Instance.new("Frame")
        track.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 65, 80)
        track.BorderSizePixel = 0
        track.Size = UDim2.new(0, 40, 0, 22)
        track.Position = UDim2.new(1, -54, 0.5, -11)
        track.ZIndex = 5
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        track.Parent = row

        -- Thumb
        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Size = UDim2.new(0, 16, 0, 16)
        thumb.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        thumb.ZIndex = 6
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb
        thumb.Parent = track

        local click = Instance.new("TextButton")
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""
        click.ZIndex = 7
        click.Parent = row

        click.MouseButton1Click:Connect(function()
            state = not state
            Util.Tween(track, {
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 65, 80)
            }, 0.2)
            Util.Tween(thumb, {
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            }, 0.2, Enum.EasingStyle.Back)

            if config.Callback then
                pcall(config.Callback, state)
            end
        end)

        row.Parent = page

        return {
            Set = function(_, val)
                state = val
                Util.Tween(track, {
                    BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 65, 80)
                }, 0.2)
                Util.Tween(thumb, {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }, 0.2, Enum.EasingStyle.Back)
                if config.Callback then pcall(config.Callback, state) end
            end,
            Get = function() return state end,
        }
    end

    -- ── SLIDER ──
    function Tab:AddSlider(config)
        config = config or {}
        local min   = config.Min   or 0
        local max   = config.Max   or 100
        local value = config.Value or min
        local suffix = config.Suffix or ""

        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 58),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1
        container.Name = "Slider"

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -80, 0, 20)
        label.Position = UDim2.new(0, 14, 0, 8)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Slider"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = container

        local valLabel = Instance.new("TextLabel")
        valLabel.BackgroundTransparency = 1
        valLabel.Size = UDim2.new(0, 70, 0, 20)
        valLabel.Position = UDim2.new(1, -84, 0, 8)
        valLabel.Font = Enum.Font.GothamBold
        valLabel.Text = value .. suffix
        valLabel.TextColor3 = Theme.Accent
        valLabel.TextSize = 13
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.ZIndex = 5
        valLabel.Parent = container

        -- Track
        local track = Instance.new("Frame")
        track.BackgroundColor3 = Color3.fromRGB(50, 55, 75)
        track.BorderSizePixel = 0
        track.Size = UDim2.new(1, -28, 0, 4)
        track.Position = UDim2.new(0, 14, 1, -18)
        track.ZIndex = 5
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        track.Parent = container

        -- Fill
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.ZIndex = 6
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill
        fill.Parent = track

        -- Thumb
        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Size = UDim2.new(0, 14, 0, 14)
        thumb.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
        thumb.ZIndex = 7
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb
        thumb.Parent = track

        -- Glow on thumb
        local thumbStroke = Instance.new("UIStroke")
        thumbStroke.Color = Theme.Accent
        thumbStroke.Transparency = 0.4
        thumbStroke.Thickness = 2
        thumbStroke.Parent = thumb

        -- Drag logic
        local dragging = false

        local function updateSlider(inputX)
            local rel = math.clamp(
                (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
            valLabel.Text = value .. suffix
            if config.Callback then pcall(config.Callback, value) end
        end

        thumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                Util.Tween(thumb, { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(thumb.Position.X.Scale, -9, 0.5, -9) }, 0.1)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if dragging then
                    dragging = false
                    Util.Tween(thumb, { Size = UDim2.new(0, 14, 0, 14) }, 0.1)
                end
            end
        end)

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                updateSlider(input.Position.X)
            end
        end)

        container.Parent = page
        return {
            Set = function(_, v)
                v = math.clamp(v, min, max)
                value = v
                local rel = (v - min) / (max - min)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -7, 0.5, -7)
                valLabel.Text = v .. suffix
            end,
            Get = function() return value end,
        }
    end

    -- ── DROPDOWN ──
    function Tab:AddDropdown(config)
        config = config or {}
        local options = config.Options or {}
        local selected = config.Default or (options[1] or "Select...")
        local open = false

        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 42),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1
        container.Name = "Dropdown"
        container.ClipsDescendants = false

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Dropdown"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = container

        local selectedBtn = Instance.new("TextButton")
        selectedBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
        selectedBtn.BorderSizePixel = 0
        selectedBtn.Size = UDim2.new(0.5, -14, 0, 28)
        selectedBtn.Position = UDim2.new(0.5, 0, 0.5, -14)
        selectedBtn.Font = Enum.Font.GothamSemibold
        selectedBtn.Text = selected .. " ▾"
        selectedBtn.TextColor3 = Theme.TextSecondary
        selectedBtn.TextSize = 12
        selectedBtn.ZIndex = 5
        selectedBtn.ClipsDescendants = false
        local selCorner = Instance.new("UICorner")
        selCorner.CornerRadius = UDim.new(0, 7)
        selCorner.Parent = selectedBtn
        selectedBtn.Parent = container

        -- Dropdown panel
        local panel, _ = MakeGlassFrame({
            Size = UDim2.new(0.5, -14, 0, 0),
            Position = UDim2.new(0.5, 0, 1, 4),
            Radius = UDim.new(0, 8),
            ZIndex = 20,
        })
        panel.Visible = false
        panel.ClipsDescendants = true
        panel.Parent = container

        local panelList = Instance.new("UIListLayout")
        panelList.SortOrder = Enum.SortOrder.LayoutOrder
        panelList.Parent = panel

        local function refreshPanel()
            for _, child in pairs(panel:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                optBtn.BackgroundTransparency = opt == selected and 0.88 or 1
                optBtn.BorderSizePixel = 0
                optBtn.Size = UDim2.new(1, 0, 0, 32)
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = opt
                optBtn.TextColor3 = opt == selected and Theme.Accent or Theme.TextSecondary
                optBtn.TextSize = 12
                optBtn.ZIndex = 21
                optBtn.LayoutOrder = i
                optBtn.Parent = panel

                optBtn.MouseEnter:Connect(function()
                    Util.Tween(optBtn, { BackgroundTransparency = 0.92 }, 0.12)
                end)
                optBtn.MouseLeave:Connect(function()
                    Util.Tween(optBtn, { BackgroundTransparency = opt == selected and 0.88 or 1 }, 0.12)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    selectedBtn.Text = opt .. " ▾"
                    open = false
                    Util.Tween(panel, { Size = UDim2.new(0.5, -14, 0, 0) }, 0.2)
                    task.delay(0.2, function() panel.Visible = false end)
                    refreshPanel()
                    if config.Callback then pcall(config.Callback, selected) end
                end)
            end
            panel.Size = UDim2.new(0.5, -14, 0, #options * 32)
        end

        refreshPanel()

        selectedBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                panel.Visible = true
                panel.Size = UDim2.new(0.5, -14, 0, 0)
                Util.Tween(panel, { Size = UDim2.new(0.5, -14, 0, #options * 32) }, 0.25, Enum.EasingStyle.Back)
            else
                Util.Tween(panel, { Size = UDim2.new(0.5, -14, 0, 0) }, 0.2)
                task.delay(0.2, function() panel.Visible = false end)
            end
        end)

        container.Parent = page
        return {
            Get = function() return selected end,
            Set = function(_, val)
                selected = val
                selectedBtn.Text = val .. " ▾"
                refreshPanel()
            end,
            Refresh = function(_, newOpts)
                options = newOpts
                refreshPanel()
            end,
        }
    end

    -- ── TEXT INPUT ──
    function Tab:AddInput(config)
        config = config or {}

        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 58),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1
        container.Name = "Input"

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -14, 0, 18)
        label.Position = UDim2.new(0, 14, 0, 7)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Input"
        label.TextColor3 = Theme.TextSecondary
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = container

        local box = Instance.new("TextBox")
        box.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
        box.BackgroundTransparency = 0.3
        box.BorderSizePixel = 0
        box.Size = UDim2.new(1, -28, 0, 26)
        box.Position = UDim2.new(0, 14, 1, -32)
        box.Font = Enum.Font.Gotham
        box.PlaceholderText = config.Placeholder or "Type here..."
        box.PlaceholderColor3 = Theme.TextMuted
        box.Text = config.Default or ""
        box.TextColor3 = Theme.TextPrimary
        box.TextSize = 13
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = config.ClearOnFocus or false
        box.ZIndex = 5
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = box
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Theme.Accent
        boxStroke.Transparency = 1
        boxStroke.Thickness = 1.5
        boxStroke.Parent = box

        local boxPad = Instance.new("UIPadding")
        boxPad.PaddingLeft = UDim.new(0, 8)
        boxPad.Parent = box

        box.Focused:Connect(function()
            Util.Tween(boxStroke, { Transparency = 0.3 }, 0.15)
        end)
        box.FocusLost:Connect(function(enter)
            Util.Tween(boxStroke, { Transparency = 1 }, 0.15)
            if config.Callback then pcall(config.Callback, box.Text, enter) end
        end)

        box.Parent = container
        container.Parent = page
        return {
            Get = function() return box.Text end,
            Set = function(_, v) box.Text = v end,
        }
    end

    -- ── LABEL ──
    function Tab:AddLabel(config)
        config = config or {}

        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, 0, 0, 28)
        row.LayoutOrder = Tab._order
        Tab._order += 1
        row.Name = "Label"

        local txt = Instance.new("TextLabel")
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.Font = Enum.Font.Gotham
        txt.Text = config.Text or ""
        txt.TextColor3 = config.Color or Theme.TextMuted
        txt.TextSize = config.Size or 12
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.ZIndex = 4
        txt.RichText = true
        txt.Parent = row
        row.Parent = page

        return {
            Set = function(_, v) txt.Text = v end,
            Get = function() return txt.Text end,
        }
    end

    -- ── KEYBIND ──
    function Tab:AddKeybind(config)
        config = config or {}
        local key = config.Default or Enum.KeyCode.Unknown
        local listening = false

        local row, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 42),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        row.LayoutOrder = Tab._order
        Tab._order += 1
        row.Name = "Keybind"

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Keybind"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = row

        local keyBtn = Instance.new("TextButton")
        keyBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
        keyBtn.BorderSizePixel = 0
        keyBtn.Size = UDim2.new(0, 70, 0, 26)
        keyBtn.Position = UDim2.new(1, -84, 0.5, -13)
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.Text = key == Enum.KeyCode.Unknown and "NONE" or key.Name
        keyBtn.TextColor3 = Theme.Accent
        keyBtn.TextSize = 11
        keyBtn.ZIndex = 5
        keyBtn.BorderSizePixel = 0
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 6)
        keyCorner.Parent = keyBtn
        keyBtn.Parent = row

        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = Theme.Warning
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
            if listening and not gp then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    listening = false
                    keyBtn.Text = key.Name
                    keyBtn.TextColor3 = Theme.Accent
                    if config.Callback then pcall(config.Callback, key) end
                end
            elseif not listening and not gp then
                if input.KeyCode == key and config.OnPress then
                    pcall(config.OnPress)
                end
            end
        end)

        row.Parent = page
        return {
            Get = function() return key end,
        }
    end

    -- ── COLOR PICKER (Simplified) ──
    function Tab:AddColorPicker(config)
        config = config or {}
        local color = config.Default or Color3.fromRGB(120, 180, 255)

        local row, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 42),
            Radius = UDim.new(0, 10),
            ZIndex = 4,
        })
        row.LayoutOrder = Tab._order
        Tab._order += 1
        row.Name = "ColorPicker"

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Color"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = row

        local swatch = Instance.new("TextButton")
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Size = UDim2.new(0, 36, 0, 22)
        swatch.Position = UDim2.new(1, -50, 0.5, -11)
        swatch.Text = ""
        swatch.ZIndex = 5
        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(0, 5)
        swatchCorner.Parent = swatch
        local swatchStroke = Instance.new("UIStroke")
        swatchStroke.Color = Color3.fromRGB(255, 255, 255)
        swatchStroke.Transparency = 0.7
        swatchStroke.Thickness = 1
        swatchStroke.Parent = swatch
        swatch.Parent = row

        -- Full color picker panel
        local pickerOpen = false
        local pickerPanel, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            Radius = UDim.new(0, 8),
            ZIndex = 15,
        })
        pickerPanel.Visible = false
        pickerPanel.ClipsDescendants = true
        pickerPanel.Parent = row

        -- Preset colors
        local presets = {
            Color3.fromRGB(120, 180, 255), Color3.fromRGB(100, 220, 160),
            Color3.fromRGB(255, 190, 80),  Color3.fromRGB(255, 90, 100),
            Color3.fromRGB(200, 120, 255), Color3.fromRGB(80, 200, 220),
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 150, 170),
        }

        local presetGrid = Instance.new("Frame")
        presetGrid.BackgroundTransparency = 1
        presetGrid.Size = UDim2.new(1, -20, 0, 36)
        presetGrid.Position = UDim2.new(0, 10, 0, 8)
        presetGrid.ZIndex = 16
        presetGrid.Parent = pickerPanel

        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0, 26, 0, 26)
        gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = presetGrid

        for i, col in ipairs(presets) do
            local p = Instance.new("TextButton")
            p.BackgroundColor3 = col
            p.BorderSizePixel = 0
            p.Size = UDim2.new(0, 26, 0, 26)
            p.Text = ""
            p.ZIndex = 17
            p.LayoutOrder = i
            local pc = Instance.new("UICorner")
            pc.CornerRadius = UDim.new(0, 4)
            pc.Parent = p
            p.MouseButton1Click:Connect(function()
                color = col
                swatch.BackgroundColor3 = col
                if config.Callback then pcall(config.Callback, col) end
            end)
            p.Parent = presetGrid
        end

        swatch.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                pickerPanel.Visible = true
                Util.Tween(pickerPanel, { Size = UDim2.new(1, 0, 0, 56) }, 0.25, Enum.EasingStyle.Back)
            else
                Util.Tween(pickerPanel, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                task.delay(0.2, function() pickerPanel.Visible = false end)
            end
        end)

        row.Parent = page
        return {
            Get = function() return color end,
            Set = function(_, c) color = c; swatch.BackgroundColor3 = c end,
        }
    end

    -- ── NOTIFICATION (static method-like via Tab) ──
    function Tab:Notify(config)
        LiquidGlass.Notify(config)
    end

    return Tab
end

-- ── Internal tab switch ──
function Window:_SwitchTab(tabData)
    if self.ActiveTab then
        self.ActiveTab._page.Visible = false
        Util.Tween(self.ActiveTab._btn, { TextColor3 = Theme.TextMuted, BackgroundTransparency = 1 }, 0.2)
        Util.Tween(self.ActiveTab._activeBar, { BackgroundTransparency = 1 }, 0.2)
    end
    self.ActiveTab = tabData
    tabData._page.Visible = true
    Util.Tween(tabData._btn, { TextColor3 = Theme.TextPrimary, BackgroundTransparency = 0.88 }, 0.2)
    Util.Tween(tabData._activeBar, { BackgroundTransparency = 0 }, 0.2)
end

-- ╔══════════════════════════════╗
-- ║      NOTIFICATION SYSTEM     ║
-- ╚══════════════════════════════╝
local notifyContainer = nil

function LiquidGlass.Notify(config)
    config = config or {}
    local title    = config.Title    or "Notification"
    local message  = config.Message  or ""
    local duration = config.Duration or 4
    local ntype    = config.Type     or "info"  -- info | success | warning | danger

    -- Create container if missing
    if not notifyContainer or not notifyContainer.Parent then
        local gui = Instance.new("ScreenGui")
        gui.Name = "LGNotifications"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        notifyContainer = Instance.new("Frame")
        notifyContainer.BackgroundTransparency = 1
        notifyContainer.Size = UDim2.new(0, 300, 1, 0)
        notifyContainer.Position = UDim2.new(1, -314, 0, 0)
        notifyContainer.ZIndex = 100
        notifyContainer.Parent = gui

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.VerticalAlignment = Enum.VerticalAlignment.Bottom
        list.Padding = UDim.new(0, 8)
        list.Parent = notifyContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 20)
        pad.Parent = notifyContainer
    end

    local typeColor = {
        info    = Theme.Accent,
        success = Theme.Success,
        warning = Theme.Warning,
        danger  = Theme.Danger,
    }
    local accentColor = typeColor[ntype] or Theme.Accent

    local card, _ = MakeGlassFrame({
        Size = UDim2.new(1, 0, 0, 70),
        Radius = UDim.new(0, 12),
        ZIndex = 101,
    })
    card.Name = "Notification"
    card.BackgroundTransparency = 0.05
    card.ClipsDescendants = true

    -- Accent left bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.ZIndex = 102
    bar.Parent = card

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Size = UDim2.new(1, -20, 0, 22)
    ttl.Position = UDim2.new(0, 14, 0, 10)
    ttl.Font = Enum.Font.GothamBold
    ttl.Text = title
    ttl.TextColor3 = accentColor
    ttl.TextSize = 13
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 102
    ttl.Parent = card

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency = 1
    msg.Size = UDim2.new(1, -20, 0, 28)
    msg.Position = UDim2.new(0, 14, 0, 32)
    msg.Font = Enum.Font.Gotham
    msg.Text = message
    msg.TextColor3 = Theme.TextSecondary
    msg.TextSize = 12
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.ZIndex = 102
    msg.Parent = card

    -- Progress bar
    local prog = Instance.new("Frame")
    prog.BackgroundColor3 = accentColor
    prog.BackgroundTransparency = 0.5
    prog.BorderSizePixel = 0
    prog.Size = UDim2.new(1, 0, 0, 2)
    prog.Position = UDim2.new(0, 0, 1, -2)
    prog.ZIndex = 102
    prog.Parent = card

    card.Position = UDim2.new(1, 20, 0, 0)
    card.Parent = notifyContainer

    Util.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)
    Util.Tween(prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Util.Tween(card, { Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1 }, 0.3)
        task.delay(0.3, function() card:Destroy() end)
    end)
end

-- ── Set theme accent color ──
function LiquidGlass:SetAccent(color)
    Theme.Accent = color
    Theme.AccentGlow = color
end

return LiquidGlass
