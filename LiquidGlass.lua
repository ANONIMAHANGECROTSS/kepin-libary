--[[
    ╔══════════════════════════════════════════════════════╗
    ║         LIQUID GLASS UI LIBRARY v2.0                ║
    ║         JAROT404 × KVNXY Team                       ║
    ║         Premium Smooth Landscape UI Framework       ║
    ╚══════════════════════════════════════════════════════╝
--]]

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

-- ╔══════════════════════════════╗
-- ║        SERVICES              ║
-- ╚══════════════════════════════╝
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ╔══════════════════════════════╗
-- ║        THEME CONFIG          ║
-- ╚══════════════════════════════╝
local Theme = {
    -- Glass base
    GlassBackground  = Color3.fromRGB(10, 10, 14),
    GlassSurface     = Color3.fromRGB(20, 20, 28),
    GlassBorder      = Color3.fromRGB(255, 255, 255),

    -- Accent
    Accent           = Color3.fromRGB(120, 180, 255),
    AccentGlow       = Color3.fromRGB(80, 140, 255),
    AccentDark       = Color3.fromRGB(40, 100, 220),

    -- Text
    TextPrimary      = Color3.fromRGB(255, 255, 255),
    TextSecondary    = Color3.fromRGB(180, 190, 210),
    TextMuted        = Color3.fromRGB(110, 120, 140),

    -- States
    Success          = Color3.fromRGB(100, 220, 160),
    Warning          = Color3.fromRGB(255, 190, 80),
    Danger           = Color3.fromRGB(255, 90, 100),

    -- Opacity levels
    GlassOpacity     = 0.12,   -- Main glass fill
    BorderOpacity    = 0.15,   -- Border transparency
    ShadowOpacity    = 0.65,   -- Drop shadow

    -- Animation
    TweenSpeed       = 0.26,
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

function Util.MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil

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

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
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
    ripple.BackgroundTransparency = 0.8
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

-- Create Standard Premium Frame
local function MakeGlassFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Theme.GlassSurface
    frame.BackgroundTransparency = 1 - Theme.GlassOpacity
    frame.BorderSizePixel = 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ClipsDescendants = props.ClipsDescendants or false
    frame.ZIndex = props.ZIndex or 1

    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.Radius or UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.GlassBorder
    stroke.Transparency = 1 - Theme.BorderOpacity
    stroke.Thickness = props.BorderThickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    return frame, stroke, corner
end

-- ╔══════════════════════════════╗
-- ║        WINDOW CLASS          ║
-- ╚══════════════════════════════╝
local Window = {}
Window.__index = Window

function LiquidGlass:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Window)

    self.Title     = config.Title    or "Liquid Glass Hub"
    self.Subtitle  = config.Subtitle or "Premium System"
    self.Width     = config.Width    or 620
    self.Height    = config.Height   or 420
    self.SidebarWidth = 160
    self.Tabs      = {}
    self.ActiveTab = nil
    self._minimized = false

    -- ── Root ScreenGui ──
    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlassPremiumUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    -- ── Outer Shadow ──
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "Shadow"
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.5
    shadowFrame.BorderSizePixel = 0
    shadowFrame.Size = UDim2.new(0, self.Width + 30, 0, self.Height + 30)
    shadowFrame.Position = UDim2.new(0.5, -(self.Width/2) - 15, 0.5, -(self.Height/2) - 15)
    shadowFrame.ZIndex = 1
    shadowFrame.Parent = gui
    self._shadow = shadowFrame

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 16)
    shadowCorner.Parent = shadowFrame

    -- ── Main Window Frame ──
    local winFrame, winStroke, winCorner = MakeGlassFrame({
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        Radius = UDim.new(0, 14),
        ClipsDescendants = true,
        ZIndex = 2,
    })
    winFrame.Name = "MainWindow"
    winFrame.Parent = gui
    self._winFrame = winFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
    })
    gradient.Rotation = 135
    gradient.Parent = winFrame

    -- ── Dynamic Island (Hidden Initially) ──
    local islandFrame = Instance.new("TextButton")
    islandFrame.Name = "DynamicIsland"
    islandFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    islandFrame.BackgroundTransparency = 0.1
    islandFrame.BorderSizePixel = 0
    islandFrame.Size = UDim2.new(0, 180, 0, 36)
    islandFrame.Position = UDim2.new(0.5, -90, 0, -50) -- Offscreen initially
    islandFrame.ZIndex = 100
    islandFrame.Visible = false
    islandFrame.Text = ""
    islandFrame.Parent = gui
    self._islandFrame = islandFrame

    local islandCorner = Instance.new("UICorner")
    islandCorner.CornerRadius = UDim.new(1, 0)
    islandCorner.Parent = islandFrame

    local islandStroke = Instance.new("UIStroke")
    islandStroke.Color = Theme.Accent
    islandStroke.Transparency = 0.7
    islandStroke.Thickness = 1
    islandStroke.Parent = islandFrame

    local islandDot = Instance.new("Frame")
    islandDot.Name = "Dot"
    islandDot.BackgroundColor3 = Theme.Success
    islandDot.Size = UDim2.new(0, 6, 0, 6)
    islandDot.Position = UDim2.new(0, 14, 0.5, -3)
    islandDot.ZIndex = 101
    islandDot.Parent = islandFrame

    local islandDotCorner = Instance.new("UICorner")
    islandDotCorner.CornerRadius = UDim.new(1, 0)
    islandDotCorner.Parent = islandDot

    local islandTitle = Instance.new("TextLabel")
    islandTitle.Name = "Title"
    islandTitle.BackgroundTransparency = 1
    islandTitle.Size = UDim2.new(1, -34, 1, 0)
    islandTitle.Position = UDim2.new(0, 26, 0, 0)
    islandTitle.Font = Enum.Font.GothamBold
    islandTitle.Text = self.Title
    islandTitle.TextColor3 = Theme.TextPrimary
    islandTitle.TextSize = 11
    islandTitle.TextXAlignment = Enum.TextXAlignment.Left
    islandTitle.ZIndex = 101
    islandTitle.Parent = islandFrame

    -- ── Canvas Group (Containers all standard Hub content for smooth fading) ──
    local canvas = Instance.new("CanvasGroup")
    canvas.Size = UDim2.new(1, 0, 1, 0)
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel = 0
    canvas.ZIndex = 3
    canvas.GroupTransparency = 0
    canvas.Parent = winFrame
    self._canvas = canvas

    -- ── Header Area ──
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 0.96
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 46)
    header.ZIndex = 4
    header.Parent = canvas

    local headerBorder = Instance.new("Frame")
    headerBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    headerBorder.BackgroundTransparency = 0.88
    headerBorder.BorderSizePixel = 0
    headerBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBorder.ZIndex = 5
    headerBorder.Parent = header

    -- Title & Subtitle
    local titleContainer = Instance.new("Frame")
    titleContainer.BackgroundTransparency = 1
    titleContainer.Size = UDim2.new(0.6, 0, 1, 0)
    titleContainer.Position = UDim2.new(0, 16, 0, 0)
    titleContainer.ZIndex = 5
    titleContainer.Parent = header

    local mainTitle = Instance.new("TextLabel")
    mainTitle.BackgroundTransparency = 1
    mainTitle.Size = UDim2.new(1, 0, 0.55, 0)
    mainTitle.Position = UDim2.new(0, 0, 0.1, 0)
    mainTitle.Font = Enum.Font.GothamBold
    mainTitle.Text = self.Title
    mainTitle.TextColor3 = Theme.TextPrimary
    mainTitle.TextSize = 15
    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
    mainTitle.ZIndex = 5
    mainTitle.Parent = titleContainer

    local subTitle = Instance.new("TextLabel")
    subTitle.BackgroundTransparency = 1
    subTitle.Size = UDim2.new(1, 0, 0.45, 0)
    subTitle.Position = UDim2.new(0, 0, 0.55, 0)
    subTitle.Font = Enum.Font.Gotham
    subTitle.Text = self.Subtitle
    subTitle.TextColor3 = Theme.TextMuted
    subTitle.TextSize = 10
    subTitle.TextXAlignment = Enum.TextXAlignment.Left
    subTitle.ZIndex = 5
    subTitle.Parent = titleContainer

    -- Window Controls
    local controls = Instance.new("Frame")
    controls.BackgroundTransparency = 1
    controls.Size = UDim2.new(0, 80, 1, 0)
    controls.Position = UDim2.new(1, -90, 0, 0)
    controls.ZIndex = 5
    controls.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Size = UDim2.new(0, 12, 0, 12)
    closeBtn.Position = UDim2.new(1, -16, 0.5, -6)
    closeBtn.Text = ""
    closeBtn.ZIndex = 6
    closeBtn.Parent = controls

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.BackgroundColor3 = Theme.Warning
    minBtn.BackgroundTransparency = 0.2
    minBtn.Size = UDim2.new(0, 12, 0, 12)
    minBtn.Position = UDim2.new(1, -38, 0.5, -6)
    minBtn.Text = ""
    minBtn.ZIndex = 6
    minBtn.Parent = controls

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minBtn

    -- Header Dragging
    Util.MakeDraggable(winFrame, header)

    -- ── Main Workspace split (Left Sidebar, Right Content) ──
    local workspaceFrame = Instance.new("Frame")
    workspaceFrame.Name = "Workspace"
    workspaceFrame.BackgroundTransparency = 1
    workspaceFrame.Size = UDim2.new(1, 0, 1, -46)
    workspaceFrame.Position = UDim2.new(0, 0, 0, 46)
    workspaceFrame.ZIndex = 4
    workspaceFrame.Parent = canvas

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebar.BackgroundTransparency = 0.98
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.new(0, self.SidebarWidth, 1, 0)
    sidebar.ZIndex = 4
    sidebar.Parent = workspaceFrame

    local sidebarBorderRight = Instance.new("Frame")
    sidebarBorderRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebarBorderRight.BackgroundTransparency = 0.88
    sidebarBorderRight.BorderSizePixel = 0
    sidebarBorderRight.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorderRight.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorderRight.ZIndex = 5
    sidebarBorderRight.Parent = sidebar

    local tabScroller = Instance.new("ScrollingFrame")
    tabScroller.Name = "TabScroller"
    tabScroller.BackgroundTransparency = 1
    tabScroller.BorderSizePixel = 0
    tabScroller.Size = UDim2.new(1, -1, 1, 0)
    tabScroller.ScrollBarThickness = 0
    tabScroller.ZIndex = 5
    tabScroller.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 4)
    tabListLayout.Parent = tabScroller

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 10)
    tabPad.PaddingRight = UDim.new(0, 10)
    tabPad.PaddingTop = UDim.new(0, 10)
    tabPad.Parent = tabScroller

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, self.SidebarWidth, 0, 0)
    contentArea.ZIndex = 4
    contentArea.ClipsDescendants = true
    contentArea.Parent = workspaceFrame
    self._contentArea = contentArea

    -- ── INTERACTIVE RESIZERS ──

    -- Width Resizer (Left Border Slider)
    local sidebarResizeHandle = Instance.new("Frame")
    sidebarResizeHandle.Name = "SidebarResizer"
    sidebarResizeHandle.BackgroundTransparency = 1
    sidebarResizeHandle.Size = UDim2.new(0, 6, 1, 0)
    sidebarResizeHandle.Position = UDim2.new(1, -3, 0, 0)
    sidebarResizeHandle.ZIndex = 15
    sidebarResizeHandle.Parent = sidebar

    -- Bottom-Right Window Resizer
    local sizeGrabber = Instance.new("ImageLabel")
    sizeGrabber.Name = "ResizeGrabber"
    sizeGrabber.BackgroundTransparency = 1
    sizeGrabber.Size = UDim2.new(0, 16, 0, 16)
    sizeGrabber.Position = UDim2.new(1, -14, 1, -14)
    sizeGrabber.Image = "rbxassetid://6031094030" -- Smooth gradient corner icon
    sizeGrabber.ImageColor3 = Theme.TextMuted
    sizeGrabber.ZIndex = 10
    sizeGrabber.Parent = winFrame

    local grabberBtn = Instance.new("TextButton")
    grabberBtn.BackgroundTransparency = 1
    grabberBtn.Size = UDim2.new(1, 0, 1, 0)
    grabberBtn.Text = ""
    grabberBtn.ZIndex = 11
    grabberBtn.Parent = sizeGrabber

    -- Resizing Logics
    local activeWindowResizing = false
    local activeSidebarResizing = false
    local rStartMouse, rStartWinSize, rStartShadowSize
    local sStartMouse, sStartWidth

    grabberBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeWindowResizing = true
            rStartMouse = UserInputService:GetMouseLocation()
            rStartWinSize = winFrame.Size
            rStartShadowSize = shadowFrame.Size
        end
    end)

    sidebarResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeSidebarResizing = true
            sStartMouse = UserInputService:GetMouseLocation()
            sStartWidth = sidebar.Size.X.Offset
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentMouse = UserInputService:GetMouseLocation()
            if activeWindowResizing then
                local delta = currentMouse - rStartMouse
                local nWidth = math.clamp(rStartWinSize.X.Offset + delta.X, 480, 900)
                local nHeight = math.clamp(rStartWinSize.Y.Offset + delta.Y, 320, 650)
                
                winFrame.Size = UDim2.new(0, nWidth, 0, nHeight)
                shadowFrame.Size = UDim2.new(0, nWidth + 30, 0, nHeight + 30)
                shadowFrame.Position = UDim2.new(0.5, -(nWidth/2) - 15, 0.5, -(nHeight/2) - 15)
            elseif activeSidebarResizing then
                local delta = currentMouse - sStartMouse
                local nWidth = math.clamp(sStartWidth + delta.X, 110, 220)
                
                self.SidebarWidth = nWidth
                sidebar.Size = UDim2.new(0, nWidth, 1, 0)
                contentArea.Size = UDim2.new(1, -nWidth, 1, 0)
                contentArea.Position = UDim2.new(0, nWidth, 0, 0)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeWindowResizing = false
            activeSidebarResizing = false
        end
    end)

    -- ── Premium Minimization (Dynamic Island Morph) ──
    local originalSize, originalPos

    local function ToggleMinimize()
        self._minimized = not self._minimized
        if self._minimized then
            -- Store previous position & size
            originalSize = winFrame.Size
            originalPos = winFrame.Position

            -- Smooth fade standard canvas out
            Util.Tween(canvas, { GroupTransparency = 1 }, 0.15)
            Util.Tween(shadowFrame, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.15, function()
                canvas.Visible = false
                shadowFrame.Visible = false
            end)

            -- Morph Main Frame to Center Pill
            Util.Tween(winFrame, {
                Size = UDim2.new(0, 180, 0, 36),
                Position = UDim2.new(0.5, -90, 0, 15),
                BackgroundTransparency = 0.08
            }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            Util.Tween(winCorner, { CornerRadius = UDim.new(1, 0) }, 0.35)

            -- Display Dynamic Island overlay elements
            task.delay(0.2, function()
                islandFrame.Size = UDim2.new(0, 180, 0, 36)
                islandFrame.Position = UDim2.new(0.5, -90, 0, 15)
                islandFrame.Visible = true
            end)
        else
            -- Reverse Dynamic Island morph
            islandFrame.Visible = false
            canvas.Visible = true
            shadowFrame.Visible = true

            Util.Tween(winFrame, {
                Size = originalSize,
                Position = originalPos,
                BackgroundTransparency = 1 - Theme.GlassOpacity
            }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Util.Tween(winCorner, { CornerRadius = UDim.new(0, 14) }, 0.35)

            Util.Tween(canvas, { GroupTransparency = 0 }, 0.3)
            Util.Tween(shadowFrame, { BackgroundTransparency = 0.5 }, 0.3)
        end
    end

    minBtn.MouseButton1Click:Connect(ToggleMinimize)
    islandFrame.MouseButton1Click:Connect(ToggleMinimize)

    closeBtn.MouseButton1Click:Connect(function()
        Util.Tween(winFrame, { Size = UDim2.new(0, self.Width, 0, 0), BackgroundTransparency = 1 }, 0.25)
        task.delay(0.3, function() gui:Destroy() end)
    end)

    -- Opening Animation
    winFrame.Size = UDim2.new(0, self.Width, 0, 0)
    winFrame.BackgroundTransparency = 1
    canvas.GroupTransparency = 1
    shadowFrame.BackgroundTransparency = 1

    Util.Tween(winFrame, {
        Size = UDim2.new(0, self.Width, 0, self.Height),
        BackgroundTransparency = 1 - Theme.GlassOpacity
    }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Util.Tween(canvas, { GroupTransparency = 0 }, 0.45)
    Util.Tween(shadowFrame, { BackgroundTransparency = 0.5 }, 0.45)

    self._tabScroller = tabScroller
    return self
end

-- ╔══════════════════════════════╗
-- ║         ADD TAB              ║
-- ╚══════════════════════════════╝
function Window:AddTab(name, icon)
    local tabData = { Name = name, Elements = {} }

    -- Tab Selection Frame
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "Tab"
    tabBtn.BackgroundColor3 = Theme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 34)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Text = ""
    tabBtn.ZIndex = 6
    tabBtn.Parent = self._tabScroller

    local tabBtnCorner = Instance.new("UICorner")
    tabBtnCorner.CornerRadius = UDim.new(0, 8)
    tabBtnCorner.Parent = tabBtn

    -- Text inside selection
    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundTransparency = 1
    tabLabel.Size = UDim2.new(1, -12, 1, 0)
    tabLabel.Position = UDim2.new(0, 12, 0, 0)
    tabLabel.Font = Enum.Font.GothamSemibold
    tabLabel.Text = (icon and icon .. "  " or "") .. name
    tabLabel.TextColor3 = Theme.TextMuted
    tabLabel.TextSize = 12
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.ZIndex = 7
    tabLabel.Parent = tabBtn

    -- Page container
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.ScrollBarImageTransparency = 0.5
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 5
    page.Parent = self._contentArea

    local pageList = Instance.new("UIListLayout")
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, 8)
    pageList.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft = UDim.new(0, 14)
    pagePad.PaddingRight = UDim.new(0, 14)
    pagePad.PaddingTop = UDim.new(0, 12)
    pagePad.PaddingBottom = UDim.new(0, 12)
    pagePad.Parent = page

    tabData._btn = tabBtn
    tabData._label = tabLabel
    tabData._page = page

    -- Premium Hover & Trigger animations
    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabData then
            Util.Tween(tabBtn, { BackgroundTransparency = 0.96 }, 0.15)
            Util.Tween(tabLabel, { TextColor3 = Theme.TextSecondary }, 0.15)
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then
            Util.Tween(tabBtn, { BackgroundTransparency = 1 }, 0.15)
            Util.Tween(tabLabel, { TextColor3 = Theme.TextMuted }, 0.15)
        end
    end)

    tabBtn.MouseButton1Click:Connect(function()
        self:_SwitchTab(tabData)
    end)

    table.insert(self.Tabs, tabData)
    if #self.Tabs == 1 then
        self:_SwitchTab(tabData)
    end

    -- Tab Element Constructors
    local Tab = {}
    Tab._page = page
    Tab._order = 0

    -- ── SECTION ──
    function Tab:AddSection(text)
        local section = Instance.new("Frame")
        section.BackgroundTransparency = 1
        section.Size = UDim2.new(1, 0, 0, 26)
        section.LayoutOrder = Tab._order
        Tab._order += 1
        section.Parent = page

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.Text = text:upper()
        label.TextColor3 = Theme.Accent
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = section
    end

    -- ── BUTTON ──
    function Tab:AddButton(config)
        config = config or {}
        local btn, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 38),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        btn.LayoutOrder = Tab._order
        Tab._order += 1
        btn.ClipsDescendants = true

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -28, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Button"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = btn

        local click = Instance.new("TextButton")
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""
        click.ZIndex = 7
        click.Parent = btn

        click.MouseEnter:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 0.84 }, 0.15)
        end)
        click.MouseLeave:Connect(function()
            Util.Tween(btn, { BackgroundTransparency = 1 - Theme.GlassOpacity }, 0.15)
        end)
        click.MouseButton1Down:Connect(function()
            Util.Ripple(btn, Mouse.X, Mouse.Y)
        end)
        click.MouseButton1Click:Connect(function()
            if config.Callback then pcall(config.Callback) end
        end)

        btn.Parent = page
        return btn
    end

    -- ── TOGGLE ──
    function Tab:AddToggle(config)
        config = config or {}
        local state = config.Default or false

        local row, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 40),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        row.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Toggle"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = row

        -- Track
        local track = Instance.new("Frame")
        track.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 60, 75)
        track.BorderSizePixel = 0
        track.Size = UDim2.new(0, 34, 0, 18)
        track.Position = UDim2.new(1, -48, 0.5, -9)
        track.ZIndex = 6
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        track.Parent = row

        -- Thumb
        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Size = UDim2.new(0, 14, 0, 14)
        thumb.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        thumb.ZIndex = 7
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb
        thumb.Parent = track

        local click = Instance.new("TextButton")
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""
        click.ZIndex = 8
        click.Parent = row

        local function updateToggle()
            Util.Tween(track, {
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 60, 75)
            }, 0.22)
            Util.Tween(thumb, {
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            }, 0.22)
        end

        click.MouseButton1Click:Connect(function()
            state = not state
            updateToggle()
            if config.Callback then pcall(config.Callback, state) end
        end)

        row.Parent = page
        return {
            Set = function(_, val)
                state = val
                updateToggle()
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
            Size = UDim2.new(1, 0, 0, 52),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -80, 0, 20)
        label.Position = UDim2.new(0, 14, 0, 6)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Slider"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local valLabel = Instance.new("TextLabel")
        valLabel.BackgroundTransparency = 1
        valLabel.Size = UDim2.new(0, 70, 0, 20)
        valLabel.Position = UDim2.new(1, -84, 0, 6)
        valLabel.Font = Enum.Font.GothamBold
        valLabel.Text = value .. suffix
        valLabel.TextColor3 = Theme.Accent
        valLabel.TextSize = 12
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.ZIndex = 6
        valLabel.Parent = container

        -- Track & Fill
        local track = Instance.new("Frame")
        track.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        track.Size = UDim2.new(1, -28, 0, 4)
        track.Position = UDim2.new(0, 14, 1, -16)
        track.BorderSizePixel = 0
        track.ZIndex = 6
        track.Parent = container

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Theme.Accent
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BorderSizePixel = 0
        fill.ZIndex = 7
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        -- Active Handle Drag
        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.Size = UDim2.new(0, 10, 0, 10)
        thumb.Position = UDim2.new((value - min) / (max - min), -5, 0.5, -5)
        thumb.ZIndex = 8
        thumb.Parent = track

        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb

        local dragging = false
        local function updateSlider(inputX)
            local ratio = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * ratio)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            thumb.Position = UDim2.new(ratio, -5, 0.5, -5)
            valLabel.Text = value .. suffix
            if config.Callback then pcall(config.Callback, value) end
        end

        thumb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        container.Parent = page
        return {
            Set = function(_, val)
                val = math.clamp(val, min, max)
                value = val
                local ratio = (val - min) / (max - min)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                thumb.Position = UDim2.new(ratio, -5, 0.5, -5)
                valLabel.Text = val .. suffix
            end,
            Get = function() return value end,
        }
    end

    -- ── DROPDOWN ──
    function Tab:AddDropdown(config)
        config = config or {}
        local options = config.Options or {}
        local selected = config.Default or (options[1] or "Select...")
        local isOpen = false

        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 38),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Dropdown"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local trigger = Instance.new("TextButton")
        trigger.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
        trigger.BorderSizePixel = 0
        trigger.Size = UDim2.new(0.45, 0, 0, 24)
        trigger.Position = UDim2.new(0.55, -14, 0.5, -12)
        trigger.Font = Enum.Font.GothamSemibold
        trigger.Text = selected .. "  ▾"
        trigger.TextColor3 = Theme.TextSecondary
        trigger.TextSize = 11
        trigger.ZIndex = 6
        trigger.Parent = container

        local trigCorner = Instance.new("UICorner")
        trigCorner.CornerRadius = UDim.new(0, 6)
        trigCorner.Parent = trigger

        -- Dropdown Drawer Panel
        local drawer, _ = MakeGlassFrame({
            Size = UDim2.new(0.45, 0, 0, 0),
            Position = UDim2.new(0.55, -14, 1, 2),
            Radius = UDim.new(0, 6),
            ZIndex = 20,
        })
        drawer.Visible = false
        drawer.ClipsDescendants = true
        drawer.Parent = container

        local drawerList = Instance.new("UIListLayout")
        drawerList.SortOrder = Enum.SortOrder.LayoutOrder
        drawerList.Parent = drawer

        local function rebuildDrawer()
            for _, c in ipairs(drawer:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end

            for index, value in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                optBtn.BackgroundTransparency = (value == selected) and 0.9 or 1
                optBtn.BorderSizePixel = 0
                optBtn.Size = UDim2.new(1, 0, 0, 28)
                optBtn.Font = Enum.Font.Gotham
                optBtn.Text = value
                optBtn.TextColor3 = (value == selected) and Theme.Accent or Theme.TextSecondary
                optBtn.TextSize = 11
                optBtn.ZIndex = 21
                optBtn.Parent = drawer

                optBtn.MouseButton1Click:Connect(function()
                    selected = value
                    trigger.Text = value .. "  ▾"
                    isOpen = false
                    Util.Tween(drawer, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.15)
                    task.delay(0.15, function() drawer.Visible = false end)
                    rebuildDrawer()
                    if config.Callback then pcall(config.Callback, value) end
                end)
            end
        end

        trigger.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                rebuildDrawer()
                drawer.Visible = true
                Util.Tween(drawer, { Size = UDim2.new(0.45, 0, 0, #options * 28) }, 0.2, Enum.EasingStyle.Quint)
            else
                Util.Tween(drawer, { Size = UDim2.new(0.45, 0, 0, 0) }, 0.15)
                task.delay(0.15, function() drawer.Visible = false end)
            end
        end)

        container.Parent = page
        return {
            Get = function() return selected end,
            Set = function(_, val)
                selected = val
                trigger.Text = val .. "  ▾"
                rebuildDrawer()
            end,
            Refresh = function(_, newOpts)
                options = newOpts
                rebuildDrawer()
            end,
        }
    end

    -- ── INPUT ──
    function Tab:AddInput(config)
        config = config or {}
        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 52),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -14, 0, 16)
        label.Position = UDim2.new(0, 14, 0, 6)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Input"
        label.TextColor3 = Theme.TextSecondary
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local box = Instance.new("TextBox")
        box.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        box.BackgroundTransparency = 0.4
        box.Size = UDim2.new(1, -28, 0, 22)
        box.Position = UDim2.new(0, 14, 1, -26)
        box.Font = Enum.Font.Gotham
        box.PlaceholderText = config.Placeholder or "Write here..."
        box.PlaceholderColor3 = Theme.TextMuted
        box.Text = config.Default or ""
        box.TextColor3 = Theme.TextPrimary
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ZIndex = 6
        box.Parent = container

        local boxPad = Instance.new("UIPadding")
        boxPad.PaddingLeft = UDim.new(0, 8)
        boxPad.Parent = box

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = box

        box.FocusLost:Connect(function(entered)
            if config.Callback then pcall(config.Callback, box.Text, entered) end
        end)

        container.Parent = page
        return {
            Get = function() return box.Text end,
            Set = function(_, txt) box.Text = txt end,
        }
    end

    -- ── KEYBIND ──
    function Tab:AddKeybind(config)
        config = config or {}
        local key = config.Default or Enum.KeyCode.Unknown
        local listening = false

        local row, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 38),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        row.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Keybind"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = row

        local trigger = Instance.new("TextButton")
        trigger.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
        trigger.Size = UDim2.new(0, 75, 0, 22)
        trigger.Position = UDim2.new(1, -89, 0.5, -11)
        trigger.Font = Enum.Font.GothamBold
        trigger.Text = (key == Enum.KeyCode.Unknown) and "NONE" or key.Name
        trigger.TextColor3 = Theme.Accent
        trigger.TextSize = 10
        trigger.ZIndex = 6
        trigger.Parent = row

        local trigCorner = Instance.new("UICorner")
        trigCorner.CornerRadius = UDim.new(0, 6)
        trigCorner.Parent = trigger

        trigger.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            trigger.Text = "..."
            trigger.TextColor3 = Theme.Warning
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
            if listening and not gp then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    listening = false
                    trigger.Text = key.Name
                    trigger.TextColor3 = Theme.Accent
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

    -- ── COLOR PICKER ──
    function Tab:AddColorPicker(config)
        config = config or {}
        local color = config.Default or Color3.fromRGB(120, 180, 255)
        local isOpen = false

        local container, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 38),
            Radius = UDim.new(0, 8),
            ZIndex = 5,
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Color Picker"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local swatch = Instance.new("TextButton")
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Size = UDim2.new(0, 32, 0, 20)
        swatch.Position = UDim2.new(1, -46, 0.5, -10)
        swatch.Text = ""
        swatch.ZIndex = 6
        swatch.Parent = container

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(0, 5)
        swatchCorner.Parent = swatch

        -- Inline Color picker layout
        local tray, _ = MakeGlassFrame({
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            Radius = UDim.new(0, 8),
            ZIndex = 15,
        })
        tray.Visible = false
        tray.ClipsDescendants = true
        tray.Parent = container

        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = UDim2.new(0, 22, 0, 22)
        gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
        gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gridLayout.Parent = tray

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 14)
        pad.PaddingTop = UDim.new(0, 10)
        pad.Parent = tray

        local presets = {
            Color3.fromRGB(120, 180, 255), Color3.fromRGB(100, 220, 160),
            Color3.fromRGB(255, 190, 80),  Color3.fromRGB(255, 90, 100),
            Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(140, 150, 170), Color3.fromRGB(60, 65, 80)
        }

        for i, col in ipairs(presets) do
            local p = Instance.new("TextButton")
            p.BackgroundColor3 = col
            p.Text = ""
            p.ZIndex = 16
            p.Parent = tray
            
            local pc = Instance.new("UICorner")
            pc.CornerRadius = UDim.new(0, 4)
            pc.Parent = p

            p.MouseButton1Click:Connect(function()
                color = col
                swatch.BackgroundColor3 = col
                if config.Callback then pcall(config.Callback, col) end
            end)
        end

        swatch.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                tray.Visible = true
                Util.Tween(tray, { Size = UDim2.new(1, 0, 0, 46) }, 0.2, Enum.EasingStyle.Quint)
            else
                Util.Tween(tray, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                task.delay(0.15, function() tray.Visible = false end)
            end
        end)

        container.Parent = page
        return {
            Get = function() return color end,
            Set = function(_, col)
                color = col
                swatch.BackgroundColor3 = col
                if config.Callback then pcall(config.Callback, col) end
            end,
        }
    end

    return Tab
end

-- ── Internal Tab Swapper ──
function Window:_SwitchTab(tabData)
    if self.ActiveTab then
        self.ActiveTab._page.Visible = false
        Util.Tween(self.ActiveTab._btn, { BackgroundTransparency = 1 }, 0.2)
        Util.Tween(self.ActiveTab._label, { TextColor3 = Theme.TextMuted }, 0.2)
    end
    self.ActiveTab = tabData
    tabData._page.Visible = true
    Util.Tween(tabData._btn, { BackgroundTransparency = 0.88 }, 0.2)
    Util.Tween(tabData._label, { TextColor3 = Theme.TextPrimary }, 0.2)
end

-- ╔══════════════════════════════╗
-- ║      NOTIFICATION SYSTEM     ║
-- ╚══════════════════════════════╝
local notifyContainer = nil

function LiquidGlass.Notify(config)
    config = config or {}
    local title    = config.Title    or "System Alert"
    local message  = config.Message  or ""
    local duration = config.Duration or 3.5
    local ntype    = config.Type     or "info"

    if not notifyContainer or not notifyContainer.Parent then
        local gui = Instance.new("ScreenGui")
        gui.Name = "LiquidGlassNotifications"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        pcall(function() gui.Parent = CoreGui end)
        if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        notifyContainer = Instance.new("Frame")
        notifyContainer.BackgroundTransparency = 1
        notifyContainer.Size = UDim2.new(0, 280, 1, 0)
        notifyContainer.Position = UDim2.new(1, -294, 0, 0)
        notifyContainer.ZIndex = 100
        notifyContainer.Parent = gui

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.VerticalAlignment = Enum.VerticalAlignment.Bottom
        list.Padding = UDim.new(0, 8)
        list.Parent = notifyContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 16)
        pad.Parent = notifyContainer
    end

    local typeColors = {
        info    = Theme.Accent,
        success = Theme.Success,
        warning = Theme.Warning,
        danger  = Theme.Danger,
    }
    local statusColor = typeColors[ntype] or Theme.Accent

    local card, _ = MakeGlassFrame({
        Size = UDim2.new(1, 0, 0, 64),
        Radius = UDim.new(0, 10),
        ZIndex = 101,
    })
    card.Name = "Notification"
    card.BackgroundTransparency = 0.08
    card.ClipsDescendants = true

    local indicator = Instance.new("Frame")
    indicator.BackgroundColor3 = statusColor
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 3, 1, 0)
    indicator.ZIndex = 102
    indicator.Parent = card

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Size = UDim2.new(1, -24, 0, 20)
    ttl.Position = UDim2.new(0, 12, 0, 8)
    ttl.Font = Enum.Font.GothamBold
    ttl.Text = title
    ttl.TextColor3 = statusColor
    ttl.TextSize = 12
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 102
    ttl.Parent = card

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency = 1
    msg.Size = UDim2.new(1, -24, 0, 28)
    msg.Position = UDim2.new(0, 12, 0, 26)
    msg.Font = Enum.Font.Gotham
    msg.Text = message
    msg.TextColor3 = Theme.TextSecondary
    msg.TextSize = 11
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.ZIndex = 102
    msg.Parent = card

    local prog = Instance.new("Frame")
    prog.BackgroundColor3 = statusColor
    prog.BackgroundTransparency = 0.4
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

function LiquidGlass:SetAccent(color)
    Theme.Accent = color
    Theme.AccentGlow = color
end

return LiquidGlass
