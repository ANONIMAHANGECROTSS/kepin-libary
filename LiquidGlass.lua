local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Theme = {
    GlassBackground = Color3.fromRGB(6, 7, 10),
    GlassSurface = Color3.fromRGB(20, 22, 32), -- Slightly brighter for contrast
    ElementSurface = Color3.fromRGB(28, 30, 42), -- More solid for elements
    GlassBorder = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(44, 94, 254),
    AccentGlow = Color3.fromRGB(116, 54, 240),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(190, 200, 220),
    TextMuted = Color3.fromRGB(130, 140, 160),
    Success = Color3.fromRGB(100, 225, 160),
    Warning = Color3.fromRGB(255, 195, 85),
    Danger = Color3.fromRGB(255, 95, 105),
    
    -- Opacity Levels (More solid now)
    WinOpacity = 0.35,
    GroupOpacity = 0.15,
    ElementOpacity = 0.05,
    BorderOpacity = 0.20,
    ShadowOpacity = 0.60,
    
    -- Modern Fonts
    FontBold = Enum.Font.BuilderSansBold,
    FontSemiBold = Enum.Font.BuilderSansMedium,
    FontRegular = Enum.Font.BuilderSans,
    
    TweenSpeed = 0.22,
    TweenStyle = Enum.EasingStyle.Quint, -- Smoother easing
    TweenDirection = Enum.EasingDirection.Out
}

local function SmoothTween(obj, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or Theme.TweenSpeed,
        style or Theme.TweenStyle,
        dir or Theme.TweenDirection
    )
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function GetExecutorName()
    if identifyexecutor then
        local success, name = pcall(identifyexecutor)
        if success and name then return name end
    end
    return "Roblox Client"
end

local function SetupUnifiedDrag(triggerFrame, onDragStart, onDragMove, onDragEnd)
    local dragging = false
    local dragConnection = nil

    triggerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            if onDragStart then onDragStart(input.Position) end
            
            if dragConnection then dragConnection:Disconnect() end
            dragConnection = UserInputService.InputChanged:Connect(function(moveInput)
                if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    if onDragMove then onDragMove(moveInput.Position) end
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if dragConnection then dragConnection:Disconnect() end
                if onDragEnd then onDragEnd() end
            end
        end
    end)
end

local function BuildGlassFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.Color or Theme.ElementSurface
    frame.BackgroundTransparency = props.Transparency or Theme.ElementOpacity
    frame.BorderSizePixel = 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ClipsDescendants = props.ClipsDescendants or false
    frame.ZIndex = props.ZIndex or 1

    local corner = Instance.new("UICorner")
    corner.CornerRadius = props.Radius or UDim.new(0, 8)
    corner.Parent = frame

    if props.AddStroke ~= false then
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.GlassBorder
        stroke.Transparency = props.StrokeTransparency or Theme.BorderOpacity
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = frame

        if props.StrokeGradient ~= false then
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 105, 130))
            })
            gradient.Rotation = 45
            gradient.Parent = stroke
        end
    end

    return frame
end

local Window = {}
Window.__index = Window

function LiquidGlass:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Window)

    self.Title = config.Title or "Liquid Glass Hub"
    self.Subtitle = config.Subtitle or "v1.0"
    self.Width = config.Width or 600
    self.Height = config.Height or 440
    self.SidebarWidth = 160
    self.Tabs = {}
    self.ActiveTab = nil
    self._minimized = false
    self.Executor = GetExecutorName()

    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlassV8_Ultra"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    local lightingBlur = Lighting:FindFirstChild("LiquidGlassBackdropBlur")
    if not lightingBlur then
        lightingBlur = Instance.new("BlurEffect")
        lightingBlur.Name = "LiquidGlassBackdropBlur"
        lightingBlur.Size = 0
        lightingBlur.Enabled = true
        lightingBlur.Parent = Lighting
    end
    self._lightingBlur = lightingBlur

    local winFrame = BuildGlassFrame({
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        Radius = UDim.new(0, 12),
        Color = Theme.GlassSurface,
        Transparency = Theme.WinOpacity,
        ClipsDescendants = false,
        ZIndex = 2
    })
    winFrame.Parent = gui
    self._winFrame = winFrame

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.8
    uiScale.Parent = winFrame

    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 17, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 14))
    })
    mainGradient.Rotation = 135
    mainGradient.Parent = winFrame

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "AnchoredShadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 50, 1, 50)
    shadow.Position = UDim2.new(0, -25, 0, -25)
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 1
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(47, 47, 450, 450)
    shadow.ZIndex = 1
    shadow.Parent = winFrame
    self._shadow = shadow

    local sheen = Instance.new("ImageLabel")
    sheen.Name = "Sheen"
    sheen.BackgroundTransparency = 1
    sheen.Size = UDim2.new(1, 0, 1, 0)
    sheen.Image = "rbxassetid://15623104935"
    sheen.ImageColor3 = Color3.fromRGB(255, 255, 255)
    sheen.ImageTransparency = 0.95
    sheen.ZIndex = 10
    sheen.Parent = winFrame

    local sheenCorner = Instance.new("UICorner")
    sheenCorner.CornerRadius = UDim.new(0, 12)
    sheenCorner.Parent = sheen

    local islandFrame = Instance.new("TextButton")
    islandFrame.Name = "DynamicIsland"
    islandFrame.BackgroundColor3 = Color3.fromRGB(8, 9, 14)
    islandFrame.BackgroundTransparency = 0.05
    islandFrame.BorderSizePixel = 0
    islandFrame.Size = UDim2.new(0, 220, 0, 38)
    islandFrame.Position = UDim2.new(0.5, -110, 0, -50)
    islandFrame.ZIndex = 100
    islandFrame.Visible = false
    islandFrame.Text = ""
    islandFrame.Parent = gui

    local islandCorner = Instance.new("UICorner")
    islandCorner.CornerRadius = UDim.new(0, 8)
    islandCorner.Parent = islandFrame

    local islandStroke = Instance.new("UIStroke")
    islandStroke.Color = Theme.Accent
    islandStroke.Transparency = 0.5
    islandStroke.Thickness = 1
    islandStroke.Parent = islandFrame

    local islandDot = Instance.new("Frame")
    islandDot.BackgroundColor3 = Theme.Success
    islandDot.Size = UDim2.new(0, 6, 0, 6)
    islandDot.Position = UDim2.new(0, 14, 0.5, -3)
    islandDot.ZIndex = 101
    islandDot.Parent = islandFrame
    Instance.new("UICorner", islandDot).CornerRadius = UDim.new(0, 3)

    local islandTitle = Instance.new("TextLabel")
    islandTitle.BackgroundTransparency = 1
    islandTitle.Size = UDim2.new(1, -34, 1, 0)
    islandTitle.Position = UDim2.new(0, 26, 0, 0)
    islandTitle.Font = Theme.FontBold
    islandTitle.Text = self.Title .. " | " .. self.Executor
    islandTitle.TextColor3 = Theme.TextPrimary
    islandTitle.TextSize = 12
    islandTitle.TextXAlignment = Enum.TextXAlignment.Left
    islandTitle.ZIndex = 101
    islandTitle.Parent = islandFrame

    local canvas = Instance.new("CanvasGroup")
    canvas.Size = UDim2.new(1, 0, 1, 0)
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel = 0
    canvas.ZIndex = 3
    canvas.GroupTransparency = 1
    canvas.Parent = winFrame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 0.95
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

    local titleGroup = Instance.new("Frame")
    titleGroup.BackgroundTransparency = 1
    titleGroup.Size = UDim2.new(0, 200, 1, 0)
    titleGroup.Position = UDim2.new(0, 16, 0, 0)
    titleGroup.ZIndex = 5
    titleGroup.Parent = header

    local mainTitle = Instance.new("TextLabel")
    mainTitle.BackgroundTransparency = 1
    mainTitle.Size = UDim2.new(1, 0, 1, 0)
    mainTitle.Font = Theme.FontBold
    mainTitle.Text = self.Title
    mainTitle.TextColor3 = Theme.TextPrimary
    mainTitle.TextSize = 15
    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
    mainTitle.ZIndex = 5
    mainTitle.Parent = titleGroup

    local versionTag = Instance.new("TextLabel")
    versionTag.BackgroundColor3 = Theme.Accent
    versionTag.Size = UDim2.new(0, 36, 0, 18)
    versionTag.Position = UDim2.new(0, 104, 0.5, -9)
    versionTag.Font = Theme.FontBold
    versionTag.Text = self.Subtitle
    versionTag.TextColor3 = Theme.TextPrimary
    versionTag.TextSize = 10
    versionTag.ZIndex = 6
    versionTag.Parent = titleGroup
    Instance.new("UICorner", versionTag).CornerRadius = UDim.new(0, 4)

    local controls = Instance.new("Frame")
    controls.BackgroundTransparency = 1
    controls.Size = UDim2.new(0, 76, 1, 0)
    controls.Position = UDim2.new(1, -86, 0, 0)
    controls.ZIndex = 5
    controls.Parent = header

    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Horizontal
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlLayout.Padding = UDim.new(0, 8)
    controlLayout.Parent = controls

    local minBtn = Instance.new("ImageButton")
    minBtn.BackgroundColor3 = Theme.ElementSurface
    minBtn.BackgroundTransparency = 0.2
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Image = "rbxassetid://10734896206"
    minBtn.ImageColor3 = Theme.Warning
    minBtn.ZIndex = 6
    minBtn.Parent = controls
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    local closeBtn = Instance.new("ImageButton")
    closeBtn.BackgroundColor3 = Theme.ElementSurface
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Image = "rbxassetid://10747384394"
    closeBtn.ImageColor3 = Theme.Danger
    closeBtn.ZIndex = 6
    closeBtn.Parent = controls
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    minBtn.MouseEnter:Connect(function() SmoothTween(minBtn, { BackgroundTransparency = 0.0 }, 0.1, Enum.EasingStyle.Quad) end)
    minBtn.MouseLeave:Connect(function() SmoothTween(minBtn, { BackgroundTransparency = 0.2 }, 0.1, Enum.EasingStyle.Quad) end)
    closeBtn.MouseEnter:Connect(function() SmoothTween(closeBtn, { BackgroundTransparency = 0.0 }, 0.1, Enum.EasingStyle.Quad) end)
    closeBtn.MouseLeave:Connect(function() SmoothTween(closeBtn, { BackgroundTransparency = 0.2 }, 0.1, Enum.EasingStyle.Quad) end)

    local dragStart, startPos
    SetupUnifiedDrag(header, function(mousePos)
        dragStart = mousePos
        startPos = winFrame.Position
    end, function(mousePos)
        local delta = mousePos - dragStart
        winFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)

    local workspaceFrame = Instance.new("Frame")
    workspaceFrame.BackgroundTransparency = 1
    workspaceFrame.Size = UDim2.new(1, 0, 1, -74)
    workspaceFrame.Position = UDim2.new(0, 0, 0, 46)
    workspaceFrame.ZIndex = 4
    workspaceFrame.Parent = canvas

    local sidebar = Instance.new("Frame")
    sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebar.BackgroundTransparency = 0.98
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.new(0, self.SidebarWidth, 1, 0)
    sidebar.ZIndex = 4
    sidebar.Parent = workspaceFrame

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebarBorder.BackgroundTransparency = 0.88
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.ZIndex = 5
    sidebarBorder.Parent = sidebar

    local tabScroller = Instance.new("ScrollingFrame")
    tabScroller.BackgroundTransparency = 1
    tabScroller.BorderSizePixel = 0
    tabScroller.Size = UDim2.new(1, -1, 1, 0)
    tabScroller.ScrollBarThickness = 0
    tabScroller.ZIndex = 5
    tabScroller.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.Parent = tabScroller

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.PaddingRight = UDim.new(0, 8)
    tabPad.PaddingTop = UDim.new(0, 32)
    tabPad.Parent = tabScroller

    local catTitle = Instance.new("TextLabel")
    catTitle.BackgroundTransparency = 1
    catTitle.Size = UDim2.new(1, -16, 0, 18)
    catTitle.Position = UDim2.new(0, 16, 0, 10)
    catTitle.Font = Theme.FontBold
    catTitle.Text = "NAVIGATION"
    catTitle.TextColor3 = Theme.TextMuted
    catTitle.TextSize = 10
    catTitle.TextXAlignment = Enum.TextXAlignment.Left
    catTitle.ZIndex = 6
    catTitle.Parent = sidebar

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, self.SidebarWidth, 0, 0)
    contentArea.ZIndex = 4
    contentArea.ClipsDescendants = true
    contentArea.Parent = workspaceFrame
    self._contentArea = contentArea

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.BackgroundTransparency = 0.95
    footer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    footer.BorderSizePixel = 0
    footer.Size = UDim2.new(1, 0, 0, 28)
    footer.Position = UDim2.new(0, 0, 1, -28)
    footer.ZIndex = 4
    footer.Parent = canvas

    local footerBorder = Instance.new("Frame")
    footerBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    footerBorder.BackgroundTransparency = 0.88
    footerBorder.BorderSizePixel = 0
    footerBorder.Size = UDim2.new(1, 0, 0, 1)
    footerBorder.Position = UDim2.new(0, 0, 0, 0)
    footerBorder.ZIndex = 5
    footerBorder.Parent = footer

    local footerLabel = Instance.new("TextLabel")
    footerLabel.BackgroundTransparency = 1
    footerLabel.Size = UDim2.new(0.6, 0, 1, 0)
    footerLabel.Position = UDim2.new(0, 14, 0, 0)
    footerLabel.Font = Theme.FontSemiBold
    footerLabel.Text = self.Title .. "  |  " .. self.Executor
    footerLabel.TextColor3 = Theme.TextSecondary
    footerLabel.TextSize = 10
    footerLabel.TextXAlignment = Enum.TextXAlignment.Left
    footerLabel.ZIndex = 5
    footerLabel.Parent = footer

    local perfLabel = Instance.new("TextLabel")
    perfLabel.BackgroundTransparency = 1
    perfLabel.Size = UDim2.new(0.4, -14, 1, 0)
    perfLabel.Position = UDim2.new(0.6, 0, 0, 0)
    perfLabel.Font = Theme.FontRegular
    perfLabel.Text = "FPS: --  |  " .. LocalPlayer.Name
    perfLabel.TextColor3 = Theme.TextMuted
    perfLabel.TextSize = 10
    perfLabel.TextXAlignment = Enum.TextXAlignment.Right
    perfLabel.ZIndex = 5
    perfLabel.Parent = footer

    local fps = 0
    RunService.RenderStepped:Connect(function(dt)
        fps = math.floor(1 / dt)
        perfLabel.Text = "FPS: " .. fps .. "  |  " .. LocalPlayer.Name
    end)

    local sidebarResizeHandle = Instance.new("Frame")
    sidebarResizeHandle.BackgroundTransparency = 1
    sidebarResizeHandle.Size = UDim2.new(0, 8, 1, 0)
    sidebarResizeHandle.Position = UDim2.new(1, -4, 0, 0)
    sidebarResizeHandle.ZIndex = 15
    sidebarResizeHandle.Parent = sidebar

    local sizeGrabber = Instance.new("ImageLabel")
    sizeGrabber.BackgroundTransparency = 1
    sizeGrabber.Size = UDim2.new(0, 18, 0, 18)
    sizeGrabber.Position = UDim2.new(1, -16, 1, -16)
    sizeGrabber.Image = "rbxassetid://6031094030"
    sizeGrabber.ImageColor3 = Theme.TextMuted
    sizeGrabber.ZIndex = 10
    sizeGrabber.Parent = winFrame

    local rStartMouse, rStartWinSize
    SetupUnifiedDrag(sizeGrabber, function(mousePos)
        rStartMouse = mousePos
        rStartWinSize = winFrame.Size
    end, function(mousePos)
        local delta = mousePos - rStartMouse
        local nWidth = math.clamp(rStartWinSize.X.Offset + delta.X, 500, 900)
        local nHeight = math.clamp(rStartWinSize.Y.Offset + delta.Y, 320, 650)
        
        SmoothTween(winFrame, {Size = UDim2.new(0, nWidth, 0, nHeight)}, 0.1, Enum.EasingStyle.Quad)
        contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    end)

    local sStartMouse, sStartWidth
    SetupUnifiedDrag(sidebarResizeHandle, function(mousePos)
        sStartMouse = mousePos
        sStartWidth = sidebar.Size.X.Offset
    end, function(mousePos)
        local delta = mousePos - sStartMouse
        local nWidth = math.clamp(sStartWidth + delta.X, 140, 240)
        
        self.SidebarWidth = nWidth
        sidebar.Size = UDim2.new(0, nWidth, 1, 0)
        contentArea.Size = UDim2.new(1, -nWidth, 1, 0)
        contentArea.Position = UDim2.new(0, nWidth, 0, 0)
    end)

    local originalSize, originalPos

    local function ToggleMinimize()
        self._minimized = not self._minimized
        if self._minimized then
            originalSize = winFrame.Size
            originalPos = winFrame.Position

            SmoothTween(uiScale, { Scale = 0.9 }, 0.12, Enum.EasingStyle.Quad)
            SmoothTween(canvas, { GroupTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
            SmoothTween(shadow, { ImageTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
            SmoothTween(lightingBlur, { Size = 0 }, 0.15, Enum.EasingStyle.Quad)
            
            task.delay(0.1, function()
                canvas.Visible = false
                SmoothTween(winFrame, {
                    Size = UDim2.new(0, 220, 0, 38),
                    Position = UDim2.new(0.5, -110, 0, 15),
                    BackgroundTransparency = 0.05
                }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                SmoothTween(uiScale, { Scale = 1.0 }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            end)

            task.delay(0.2, function()
                islandFrame.Size = UDim2.new(0, 220, 0, 38)
                islandFrame.Position = UDim2.new(0.5, -110, 0, 15)
                islandFrame.Visible = true
            end)
        else
            islandFrame.Visible = false
            canvas.Visible = true

            SmoothTween(winFrame, {
                Size = originalSize,
                Position = originalPos,
                BackgroundTransparency = Theme.WinOpacity
            }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            SmoothTween(uiScale, { Scale = 1.0 }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            SmoothTween(canvas, { GroupTransparency = 0 }, 0.15, Enum.EasingStyle.Quad)
            SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.15, Enum.EasingStyle.Quad)
            SmoothTween(lightingBlur, { Size = 16 }, 0.2, Enum.EasingStyle.Quad)
        end
    end

    minBtn.MouseButton1Click:Connect(ToggleMinimize)
    islandFrame.MouseButton1Click:Connect(ToggleMinimize)

    closeBtn.MouseButton1Click:Connect(function()
        SmoothTween(uiScale, { Scale = 0.9 }, 0.12, Enum.EasingStyle.Quad)
        SmoothTween(winFrame, { 
            Size = UDim2.new(0, self.Width, 0, 0), 
            Position = UDim2.new(0.5, -self.Width/2, 0.5, 0),
            BackgroundTransparency = 1 
        }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        SmoothTween(canvas, { GroupTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
        SmoothTween(shadow, { ImageTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
        SmoothTween(lightingBlur, { Size = 0 }, 0.2, Enum.EasingStyle.Quad)

        task.delay(0.25, function() 
            gui:Destroy() 
            if lightingBlur then lightingBlur:Destroy() end
        end)
    end)

    -- SPAWN ANIMATION
    SmoothTween(lightingBlur, { Size = 16 }, 0.5, Enum.EasingStyle.Quint)
    SmoothTween(uiScale, { Scale = 1.0 }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    SmoothTween(winFrame, { Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2), BackgroundTransparency = Theme.WinOpacity }, 0.4, Enum.EasingStyle.Quint)
    SmoothTween(canvas, { GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Quad)
    SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.4, Enum.EasingStyle.Quad)

    self._tabScroller = tabScroller
    return self
end

function Window:AddTab(name, iconId)
    local tabData = { Name = name, Elements = {} }

    local tabBtn = Instance.new("TextButton")
    tabBtn.BackgroundColor3 = Theme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 38)
    tabBtn.Font = Theme.FontSemiBold
    tabBtn.Text = ""
    tabBtn.ZIndex = 6
    tabBtn.Parent = self._tabScroller
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    local offset = 8
    if iconId then
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 10, 0.5, -8)
        icon.Image = iconId
        icon.ImageColor3 = Theme.TextMuted
        icon.ZIndex = 7
        icon.Parent = tabBtn
        tabData._icon = icon
        offset = 32
    end

    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundTransparency = 1
    tabLabel.Size = UDim2.new(1, -offset, 1, 0)
    tabLabel.Position = UDim2.new(0, offset, 0, 0)
    tabLabel.Font = Theme.FontSemiBold
    tabLabel.Text = name
    tabLabel.TextColor3 = Theme.TextMuted
    tabLabel.TextSize = 12
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.ZIndex = 7
    tabLabel.Parent = tabBtn

    local pageGroup = Instance.new("CanvasGroup")
    pageGroup.Size = UDim2.new(1, 0, 1, 0)
    pageGroup.BackgroundTransparency = 1
    pageGroup.BorderSizePixel = 0
    pageGroup.Visible = false
    pageGroup.ZIndex = 5
    pageGroup.Parent = self._contentArea

    local pageGlass = BuildGlassFrame({
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        Radius = UDim.new(0, 10),
        Color = Theme.GlassBackground,
        Transparency = 0.5,
        ZIndex = 5
    })
    pageGlass.ClipsDescendants = true
    pageGlass.Parent = pageGroup

    local page = Instance.new("ScrollingFrame")
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Accent
    page.ScrollBarImageTransparency = 0.6
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ZIndex = 6
    page.Parent = pageGlass

    local leftCol = Instance.new("Frame")
    leftCol.Name = "LeftColumn"
    leftCol.BackgroundTransparency = 1
    leftCol.Size = UDim2.new(0.5, -6, 0, 0)
    leftCol.AutomaticSize = Enum.AutomaticSize.Y
    leftCol.ZIndex = 6
    leftCol.Parent = page

    local leftColLayout = Instance.new("UIListLayout")
    leftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftColLayout.Padding = UDim.new(0, 10)
    leftColLayout.Parent = leftCol

    local rightCol = Instance.new("Frame")
    rightCol.Name = "RightColumn"
    rightCol.BackgroundTransparency = 1
    rightCol.Size = UDim2.new(0.5, -6, 0, 0)
    rightCol.AutomaticSize = Enum.AutomaticSize.Y
    rightCol.ZIndex = 6
    rightCol.Parent = page

    local rightColLayout = Instance.new("UIListLayout")
    rightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightColLayout.Padding = UDim.new(0, 10)
    rightColLayout.Parent = rightCol

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.FillDirection = Enum.FillDirection.Horizontal
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 12)
    pageLayout.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft = UDim.new(0, 14)
    pagePad.PaddingRight = UDim.new(0, 14)
    pagePad.PaddingTop = UDim.new(0, 14)
    pagePad.PaddingBottom = UDim.new(0, 14)
    pagePad.Parent = page

    tabData._btn = tabBtn
    tabData._label = tabLabel
    tabData._pageGroup = pageGroup
    tabData._page = page
    tabData._leftCol = leftCol
    tabData._rightCol = rightCol
    tabData._groupCount = 0

    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabData then
            SmoothTween(tabBtn, { BackgroundTransparency = 0.92 }, 0.1, Enum.EasingStyle.Quad)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextSecondary }, 0.1, Enum.EasingStyle.Quad)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextSecondary }, 0.1, Enum.EasingStyle.Quad) end
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then
            SmoothTween(tabBtn, { BackgroundTransparency = 1 }, 0.1, Enum.EasingStyle.Quad)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextMuted }, 0.1, Enum.EasingStyle.Quad)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextMuted }, 0.1, Enum.EasingStyle.Quad) end
        end
    end)

    tabBtn.MouseButton1Click:Connect(function()
        self:_SwitchTab(tabData)
    end)

    table.insert(self.Tabs, tabData)
    if #self.Tabs == 1 then
        self:_SwitchTab(tabData)
    end

    local Tab = {}
    Tab._order = 0

    function Tab:AddGroup(title)
        tabData._groupCount = tabData._groupCount + 1
        local activeColumn = (tabData._groupCount % 2 == 1) and tabData._leftCol or tabData._rightCol

        local groupFrame = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 40),
            Radius = UDim.new(0, 8),
            Color = Theme.GlassSurface,
            Transparency = Theme.GroupOpacity, -- More solid
            ZIndex = 5
        })
        groupFrame.AutomaticSize = Enum.AutomaticSize.Y
        groupFrame.ClipsDescendants = true
        groupFrame.LayoutOrder = Tab._order
        Tab._order = Tab._order + 1
        groupFrame.Parent = activeColumn

        local gHeader = Instance.new("Frame")
        gHeader.Size = UDim2.new(1, 0, 0, 40)
        gHeader.BackgroundColor3 = Theme.ElementSurface
        gHeader.BackgroundTransparency = 0.8
        gHeader.BorderSizePixel = 0
        gHeader.ZIndex = 6
        gHeader.Parent = groupFrame
        Instance.new("UICorner", gHeader).CornerRadius = UDim.new(0, 8)

        local pin = Instance.new("Frame")
        pin.BackgroundColor3 = Theme.Accent
        pin.Size = UDim2.new(0, 3, 0, 16)
        pin.Position = UDim2.new(0, 10, 0.5, -8)
        pin.BorderSizePixel = 0
        pin.ZIndex = 7
        pin.Parent = gHeader
        Instance.new("UICorner", pin).CornerRadius = UDim.new(0, 2)

        local gTitle = Instance.new("TextLabel")
        gTitle.BackgroundTransparency = 1
        gTitle.Size = UDim2.new(1, -48, 1, 0)
        gTitle.Position = UDim2.new(0, 20, 0, 0)
        gTitle.Font = Theme.FontBold
        gTitle.Text = title:upper()
        gTitle.TextColor3 = Theme.TextPrimary
        gTitle.TextSize = 11
        gTitle.TextXAlignment = Enum.TextXAlignment.Left
        gTitle.ZIndex = 7
        gTitle.Parent = gHeader

        local colBtn = Instance.new("ImageButton")
        colBtn.BackgroundTransparency = 1
        colBtn.Size = UDim2.new(0, 16, 0, 16)
        colBtn.Position = UDim2.new(1, -26, 0.5, -8)
        colBtn.Image = "rbxassetid://10723415903"
        colBtn.ImageColor3 = Theme.TextSecondary
        colBtn.ZIndex = 7
        colBtn.Parent = gHeader

        local gBody = Instance.new("Frame")
        gBody.BackgroundTransparency = 1
        gBody.Position = UDim2.new(0, 0, 0, 40)
        gBody.Size = UDim2.new(1, 0, 1, -40)
        gBody.AutomaticSize = Enum.AutomaticSize.Y
        gBody.ZIndex = 6
        gBody.Parent = groupFrame

        local gBodyLayout = Instance.new("UIListLayout")
        gBodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        gBodyLayout.Padding = UDim.new(0, 10)
        gBodyLayout.Parent = gBody

        local gBodyPad = Instance.new("UIPadding")
        gBodyPad.PaddingLeft = UDim.new(0, 12)
        gBodyPad.PaddingRight = UDim.new(0, 12)
        gBodyPad.PaddingTop = UDim.new(0, 14)
        gBodyPad.PaddingBottom = UDim.new(0, 14)
        gBodyPad.Parent = gBody

        local isCollapsed = false
        colBtn.MouseButton1Click:Connect(function()
            isCollapsed = not isCollapsed
            if isCollapsed then
                SmoothTween(colBtn, { Rotation = -90 }, 0.22, Theme.TweenStyle)
                SmoothTween(groupFrame, { Size = UDim2.new(1, 0, 0, 40) }, 0.22, Theme.TweenStyle)
                task.delay(0.1, function() gBody.Visible = false end)
            else
                gBody.Visible = true
                SmoothTween(colBtn, { Rotation = 0 }, 0.22, Theme.TweenStyle)
            end
        end)

        local Group = {}
        Group._order = 0

        function Group:AddButton(btnConfig)
            btnConfig = btnConfig or {}
            local btn = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 38),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            btn.LayoutOrder = Group._order
            Group._order = Group._order + 1
            btn.ClipsDescendants = true

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -24, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Font = Theme.FontSemiBold
            label.Text = btnConfig.Text or "Button"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = btn

            local click = Instance.new("TextButton")
            click.BackgroundTransparency = 1
            click.Size = UDim2.new(1, 0, 1, 0)
            click.Text = ""
            click.ZIndex = 9
            click.Parent = btn

            local btnScale = Instance.new("UIScale")
            btnScale.Scale = 1.0
            btnScale.Parent = btn

            local function pressIn() SmoothTween(btnScale, {Scale = 0.97}, 0.08, Enum.EasingStyle.Quad) end
            local function releaseOut() SmoothTween(btnScale, {Scale = 1.0}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end
            
            click.MouseButton1Down:Connect(pressIn)
            click.MouseButton1Up:Connect(releaseOut)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and btnScale.Scale < 1.0 then
                    releaseOut()
                end
            end)

            click.MouseEnter:Connect(function() SmoothTween(btn, { BackgroundTransparency = 0 }, 0.1, Enum.EasingStyle.Quad) end)
            click.MouseLeave:Connect(function() SmoothTween(btn, { BackgroundTransparency = Theme.ElementOpacity }, 0.1, Enum.EasingStyle.Quad) end)
            click.MouseButton1Click:Connect(function()
                if btnConfig.Callback then pcall(btnConfig.Callback) end
            end)

            btn.Parent = gBody
            return btn
        end

        function Group:AddToggle(togConfig)
            togConfig = togConfig or {}
            local state = togConfig.Default or false

            local row = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 38),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            row.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -64, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Font = Theme.FontSemiBold
            label.Text = togConfig.Text or "Toggle"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = row

            local track = Instance.new("Frame")
            track.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 60, 75)
            track.BorderSizePixel = 0
            track.Size = UDim2.new(0, 36, 0, 16)
            track.Position = UDim2.new(1, -48, 0.5, -8)
            track.ZIndex = 8
            Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)
            track.Parent = row

            local thumb = Instance.new("Frame")
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thumb.BorderSizePixel = 0
            thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            thumb.Size = UDim2.new(0, 12, 0, 12)
            thumb.Position = state and UDim2.new(1, -8, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
            thumb.ZIndex = 9
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)
            thumb.Parent = track

            local click = Instance.new("TextButton")
            click.BackgroundTransparency = 1
            click.Size = UDim2.new(1, 0, 1, 0)
            click.Text = ""
            click.ZIndex = 10
            click.Parent = row

            local function updateToggle()
                if state then
                    SmoothTween(thumb, {Size = UDim2.new(0, 16, 0, 10)}, 0.08, Enum.EasingStyle.Sine)
                    SmoothTween(thumb, {Position = UDim2.new(1, -8, 0.5, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    task.delay(0.15, function()
                        SmoothTween(thumb, {Size = UDim2.new(0, 12, 0, 12)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    SmoothTween(track, {BackgroundColor3 = Theme.Accent}, 0.2, Theme.TweenStyle)
                else
                    SmoothTween(thumb, {Size = UDim2.new(0, 16, 0, 10)}, 0.08, Enum.EasingStyle.Sine)
                    SmoothTween(thumb, {Position = UDim2.new(0, 8, 0.5, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    task.delay(0.15, function()
                        SmoothTween(thumb, {Size = UDim2.new(0, 12, 0, 12)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    SmoothTween(track, {BackgroundColor3 = Color3.fromRGB(55, 60, 75)}, 0.2, Theme.TweenStyle)
                end
            end

            click.MouseButton1Click:Connect(function()
                state = not state
                updateToggle()
                if togConfig.Callback then pcall(togConfig.Callback, state) end
            end)

            row.Parent = gBody
            return {
                Set = function(_, val)
                    state = val
                    updateToggle()
                    if togConfig.Callback then pcall(togConfig.Callback, state) end
                end,
                Get = function() return state end
            }
        end

        function Group:AddSlider(slidConfig)
            slidConfig = slidConfig or {}
            local min = slidConfig.Min or 0
            local max = slidConfig.Max or 100
            local value = slidConfig.Value or min
            local suffix = slidConfig.Suffix or ""

            local container = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 50),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            container.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -70, 0, 22)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.Font = Theme.FontSemiBold
            label.Text = slidConfig.Text or "Slider"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = container

            local valLabel = Instance.new("TextLabel")
            valLabel.BackgroundTransparency = 1
            valLabel.Size = UDim2.new(0, 60, 0, 22)
            valLabel.Position = UDim2.new(1, -72, 0, 6)
            valLabel.Font = Theme.FontBold
            valLabel.Text = value .. suffix
            valLabel.TextColor3 = Theme.Accent
            valLabel.TextSize = 12
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.ZIndex = 8
            valLabel.Parent = container

            local track = Instance.new("Frame")
            track.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
            track.Size = UDim2.new(1, -24, 0, 4)
            track.Position = UDim2.new(0, 12, 1, -14)
            track.BorderSizePixel = 0
            track.ZIndex = 8
            track.Parent = container
            Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2)

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = Theme.Accent
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BorderSizePixel = 0
            fill.ZIndex = 9
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

            local thumb = Instance.new("Frame")
            thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            thumb.Size = UDim2.new(0, 12, 0, 12)
            thumb.Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6)
            thumb.ZIndex = 10
            thumb.Parent = track
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)

            local tooltip = Instance.new("TextLabel")
            tooltip.AnchorPoint = Vector2.new(0.5, 1)
            tooltip.Size = UDim2.new(0, 40, 0, 20)
            tooltip.BackgroundColor3 = Theme.Accent
            tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
            tooltip.Font = Theme.FontBold
            tooltip.TextSize = 10
            tooltip.Text = value .. suffix
            tooltip.BackgroundTransparency = 1
            tooltip.TextTransparency = 1
            tooltip.ZIndex = 11
            tooltip.Parent = container
            Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 4)

            local function showTooltip()
                SmoothTween(tooltip, {BackgroundTransparency = 0, TextTransparency = 0}, 0.15)
            end
            local function hideTooltip()
                SmoothTween(tooltip, {BackgroundTransparency = 1, TextTransparency = 1}, 0.15)
            end

            local function updateSlider(inputX)
                local ratio = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * ratio)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                thumb.Position = UDim2.new(ratio, -6, 0.5, -6)
                tooltip.Position = UDim2.new(ratio, 0, 0, 24) 
                valLabel.Text = value .. suffix
                tooltip.Text = value .. suffix
                if slidConfig.Callback then pcall(slidConfig.Callback, value) end
            end

            SetupUnifiedDrag(track, function(pos) showTooltip() updateSlider(pos.X) end, function(pos) updateSlider(pos.X) end, function() hideTooltip() end)
            SetupUnifiedDrag(thumb, function(pos) showTooltip() updateSlider(pos.X) end, function(pos) updateSlider(pos.X) end, function() hideTooltip() end)

            container.Parent = gBody
            return {
                Set = function(_, val)
                    val = math.clamp(val, min, max)
                    value = val
                    local ratio = (val - min) / (max - min)
                    fill.Size = UDim2.new(ratio, 0, 1, 0)
                    thumb.Position = UDim2.new(ratio, -6, 0.5, -6)
                    valLabel.Text = val .. suffix
                    if slidConfig.Callback then pcall(slidConfig.Callback, val) end
                end,
                Get = function() return value end
            }
        end

        function Group:AddDropdown(dropConfig)
            dropConfig = dropConfig or {}
            local options = dropConfig.Options or {}
            local selected = dropConfig.Default or (options[1] or "Select...")
            local isOpen = false
            local useSearch = #options > 5

            local container = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 40),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            container.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -110, 1, 0) -- Fixed width to prevent overlap
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Font = Theme.FontSemiBold
            label.Text = dropConfig.Text or "Dropdown"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.ZIndex = 8
            label.Parent = container

            local trigger = Instance.new("TextButton")
            trigger.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            trigger.BorderSizePixel = 0
            trigger.Size = UDim2.new(0, 90, 0, 26)
            trigger.Position = UDim2.new(1, -102, 0.5, -13) -- Fixed right position
            trigger.Font = Theme.FontSemiBold
            trigger.Text = selected .. "  ▾"
            trigger.TextColor3 = Theme.TextSecondary
            trigger.TextSize = 11
            trigger.TextWrapped = false
            trigger.ZIndex = 8
            trigger.Parent = container
            Instance.new("UICorner", trigger).CornerRadius = UDim.new(0, 4)

            local listHolder = Instance.new("Frame")
            listHolder.BackgroundTransparency = 1
            listHolder.Position = UDim2.new(0, 0, 0, 40)
            listHolder.Size = UDim2.new(1, 0, 1, -40)
            listHolder.ClipsDescendants = true
            listHolder.ZIndex = 8
            listHolder.Parent = container

            local searchBox = Instance.new("TextBox")
            searchBox.Size = UDim2.new(1, 0, 0, useSearch and 30 or 0)
            searchBox.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            searchBox.BackgroundTransparency = 0.2
            searchBox.Font = Theme.FontRegular
            searchBox.PlaceholderText = "Search..."
            searchBox.PlaceholderColor3 = Theme.TextMuted
            searchBox.TextColor3 = Theme.TextPrimary
            searchBox.TextSize = 11
            searchBox.Text = ""
            searchBox.ZIndex = 9
            searchBox.Visible = useSearch
            searchBox.Parent = listHolder
            Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
            Instance.new("UIPadding", searchBox).PaddingLeft = UDim.new(0, 8)

            local optionsContainer = Instance.new("Frame")
            optionsContainer.BackgroundTransparency = 1
            optionsContainer.Size = UDim2.new(1, 0, 1, useSearch and -34 or 0)
            optionsContainer.Position = UDim2.new(0, 0, 0, useSearch and 34 or 0)
            optionsContainer.Parent = listHolder

            local optLayout = Instance.new("UIListLayout")
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optionsContainer

            local hoverInd = Instance.new("Frame")
            hoverInd.BackgroundColor3 = Theme.Accent
            hoverInd.BackgroundTransparency = 0.85
            hoverInd.Size = UDim2.new(1, 0, 0, 28)
            hoverInd.ZIndex = 8
            hoverInd.Visible = false
            Instance.new("UICorner", hoverInd).CornerRadius = UDim.new(0, 4)
            hoverInd.Parent = optionsContainer

            local function rebuildList()
                for _, c in ipairs(optionsContainer:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                local filterText = string.lower(searchBox.Text)
                local count = 0
                for index, value in ipairs(options) do
                    if filterText == "" or string.find(string.lower(value), filterText) then
                        count = count + 1
                        local optBtn = Instance.new("TextButton")
                        optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        optBtn.BackgroundTransparency = 1
                        optBtn.BorderSizePixel = 0
                        optBtn.Size = UDim2.new(1, 0, 0, 28)
                        optBtn.Font = Theme.FontRegular
                        optBtn.Text = "  " .. value
                        optBtn.TextColor3 = (value == selected) and Theme.Accent or Theme.TextSecondary
                        optBtn.TextSize = 11
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.ZIndex = 9
                        optBtn.Parent = optionsContainer

                        optBtn.MouseEnter:Connect(function()
                            hoverInd.Visible = true
                            SmoothTween(hoverInd, {Position = UDim2.new(0, 0, 0, (count-1)*28), BackgroundTransparency = 0.7}, 0.12, Enum.EasingStyle.Quad)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            SmoothTween(hoverInd, {BackgroundTransparency = 0.85}, 0.12, Enum.EasingStyle.Quad)
                        end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            selected = value
                            trigger.Text = value .. "  ▾"
                            isOpen = false
                            SmoothTween(container, { Size = UDim2.new(1, 0, 0, 40) }, 0.15)
                            searchBox.Text = ""
                            rebuildList()
                            if dropConfig.Callback then pcall(dropConfig.Callback, value) end
                        end)
                    end
                end
            end
            
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                if isOpen then rebuildList() end
            end)

            trigger.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    rebuildList()
                    local visCount = 0
                    local filterText = string.lower(searchBox.Text)
                    for _, v in ipairs(options) do
                        if filterText == "" or string.find(string.lower(v), filterText) then visCount = visCount + 1 end
                    end
                    local baseHeight = 40
                    local searchHeight = useSearch and 34 or 0
                    local listHeight = visCount * 28
                    local targetHeight = baseHeight + searchHeight + listHeight
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2, Enum.EasingStyle.Quint)
                else
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, 40) }, 0.15)
                end
            end)

            container.Parent = gBody
            return {
                Get = function() return selected end,
                Set = function(_, val)
                    selected = val
                    trigger.Text = val .. "  ▾"
                    rebuildList()
                end,
                Refresh = function(_, newOpts)
                    options = newOpts
                    rebuildList()
                end
            }
        end

        function Group:AddInput(inpConfig)
            inpConfig = inpConfig or {}
            local container = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 50),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            container.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -12, 0, 20)
            label.Position = UDim2.new(0, 12, 0, 6)
            label.Font = Theme.FontSemiBold
            label.Text = inpConfig.Text or "Input"
            label.TextColor3 = Theme.TextSecondary
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = container

            local box = Instance.new("TextBox")
            box.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            box.BackgroundTransparency = 0.2
            box.Size = UDim2.new(1, -24, 0, 22)
            box.Position = UDim2.new(0, 12, 1, -28)
            box.Font = Theme.FontRegular
            box.PlaceholderText = inpConfig.Placeholder or "Write here..."
            box.PlaceholderColor3 = Theme.TextMuted
            box.Text = inpConfig.Default or ""
            box.TextColor3 = Theme.TextPrimary
            box.TextSize = 11
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ZIndex = 8
            box.Parent = container
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
            Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 6)

            box.FocusLost:Connect(function(entered)
                if inpConfig.Callback then pcall(inpConfig.Callback, box.Text, entered) end
            end)

            container.Parent = gBody
            return {
                Get = function() return box.Text end,
                Set = function(_, txt) box.Text = txt end
            }
        end

        function Group:AddKeybind(kbConfig)
            kbConfig = kbConfig or {}
            local key = kbConfig.Default or Enum.KeyCode.Unknown
            local listening = false

            local row = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 38),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            row.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -100, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Font = Theme.FontSemiBold
            label.Text = kbConfig.Text or "Keybind"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = row

            local trigger = Instance.new("TextButton")
            trigger.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            trigger.Size = UDim2.new(0, 84, 0, 26)
            trigger.Position = UDim2.new(1, -96, 0.5, -13)
            trigger.Font = Theme.FontBold
            trigger.Text = (key == Enum.KeyCode.Unknown) and "NONE" or key.Name
            trigger.TextColor3 = Theme.Accent
            trigger.TextSize = 11
            trigger.ZIndex = 8
            trigger.Parent = row
            Instance.new("UICorner", trigger).CornerRadius = UDim.new(0, 4)

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
                        if kbConfig.Callback then pcall(kbConfig.Callback, key) end
                    end
                elseif not listening and not gp then
                    if input.KeyCode == key and kbConfig.OnPress then
                        pcall(kbConfig.OnPress)
                    end
                end
            end)

            row.Parent = gBody
            return {
                Get = function() return key end
            }
        end

        function Group:AddColorPicker(cpConfig)
            cpConfig = cpConfig or {}
            local color = cpConfig.Default or Color3.fromRGB(120, 180, 255)
            local isOpen = false

            local container = BuildGlassFrame({
                Size = UDim2.new(1, 0, 0, 42),
                Radius = UDim.new(0, 6),
                Color = Theme.ElementSurface,
                Transparency = Theme.ElementOpacity,
                ZIndex = 7
            })
            container.LayoutOrder = Group._order
            Group._order = Group._order + 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -70, 0, 42)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.Font = Theme.FontSemiBold
            label.Text = cpConfig.Text or "Color Picker"
            label.TextColor3 = Theme.TextPrimary
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 8
            label.Parent = container

            local swatch = Instance.new("TextButton")
            swatch.BackgroundColor3 = color
            swatch.BorderSizePixel = 0
            swatch.Size = UDim2.new(0, 38, 0, 24)
            swatch.Position = UDim2.new(1, -50, 0, 9)
            swatch.Text = ""
            swatch.ZIndex = 8
            swatch.Parent = container
            Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)

            local tray = Instance.new("Frame")
            tray.BackgroundTransparency = 1
            tray.Position = UDim2.new(0, 0, 0, 42)
            tray.Size = UDim2.new(1, 0, 0, 0)
            tray.ClipsDescendants = true
            tray.ZIndex = 8
            tray.Parent = container

            local svPicker = Instance.new("Frame")
            svPicker.Size = UDim2.new(0, 110, 0, 110)
            svPicker.Position = UDim2.new(0, 14, 0, 10)
            svPicker.ZIndex = 9
            svPicker.Parent = tray
            Instance.new("UICorner", svPicker).CornerRadius = UDim.new(0, 4)

            local whiteGradFrame = Instance.new("Frame")
            whiteGradFrame.Size = UDim2.new(1, 0, 1, 0)
            whiteGradFrame.ZIndex = 10
            whiteGradFrame.Parent = svPicker
            Instance.new("UICorner", whiteGradFrame).CornerRadius = UDim.new(0, 4)

            local whiteGrad = Instance.new("UIGradient")
            whiteGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))})
            whiteGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
            whiteGrad.Parent = whiteGradFrame

            local blackGradFrame = Instance.new("Frame")
            blackGradFrame.Size = UDim2.new(1, 0, 1, 0)
            blackGradFrame.ZIndex = 11
            blackGradFrame.Parent = svPicker
            Instance.new("UICorner", blackGradFrame).CornerRadius = UDim.new(0, 4)

            local blackGrad = Instance.new("UIGradient")
            blackGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))})
            blackGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
            blackGrad.Rotation = 90
            blackGrad.Parent = blackGradFrame

            local cursor = Instance.new("Frame")
            cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cursor.Size = UDim2.new(0, 8, 0, 8)
            cursor.ZIndex = 12
            cursor.Parent = svPicker
            Instance.new("UICorner", cursor).CornerRadius = UDim.new(0, 3)
            local cs = Instance.new("UIStroke", cursor)
            cs.Color = Color3.fromRGB(0,0,0); cs.Thickness = 1

            local hueSlider = Instance.new("Frame")
            hueSlider.Size = UDim2.new(0, 18, 0, 110)
            hueSlider.Position = UDim2.new(1, -32, 0, 10)
            hueSlider.ZIndex = 9
            hueSlider.Parent = tray
            Instance.new("UICorner", hueSlider).CornerRadius = UDim.new(0, 4)

            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
                ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
                ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
            })
            hueGrad.Rotation = 90
            hueGrad.Parent = hueSlider

            local hueCursor = Instance.new("Frame")
            hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueCursor.Size = UDim2.new(1, 4, 0, 4)
            hueCursor.Position = UDim2.new(0, -2, 0, 0)
            hueCursor.ZIndex = 10
            hueCursor.Parent = hueSlider
            local hcs = Instance.new("UIStroke", hueCursor)
            hcs.Color = Color3.fromRGB(0,0,0); hcs.Thickness = 1

            local infoDeck = Instance.new("Frame")
            infoDeck.BackgroundTransparency = 1
            infoDeck.Size = UDim2.new(1, -182, 0, 110)
            infoDeck.Position = UDim2.new(0, 136, 0, 10)
            infoDeck.ZIndex = 9
            infoDeck.Parent = tray

            local previewBox = Instance.new("Frame")
            previewBox.BackgroundColor3 = color
            previewBox.Size = UDim2.new(1, 0, 0, 34)
            previewBox.Position = UDim2.new(0, 0, 0, 4)
            previewBox.ZIndex = 10
            previewBox.Parent = infoDeck
            Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 4)

            local hexLabel = Instance.new("TextLabel")
            hexLabel.BackgroundTransparency = 1
            hexLabel.Size = UDim2.new(1, 0, 0, 16)
            hexLabel.Position = UDim2.new(0, 0, 0, 46)
            hexLabel.Font = Theme.FontBold
            hexLabel.Text = "HEX: #78B4FF"
            hexLabel.TextColor3 = Theme.TextPrimary
            hexLabel.TextSize = 11
            hexLabel.TextXAlignment = Enum.TextXAlignment.Left
            hexLabel.ZIndex = 10
            hexLabel.Parent = infoDeck

            local rgbLabel = Instance.new("TextLabel")
            rgbLabel.BackgroundTransparency = 1
            rgbLabel.Size = UDim2.new(1, 0, 0, 16)
            rgbLabel.Position = UDim2.new(0, 0, 0, 64)
            rgbLabel.Font = Theme.FontSemiBold
            rgbLabel.Text = "RGB: 120, 180, 255"
            rgbLabel.TextColor3 = Theme.TextSecondary
            rgbLabel.TextSize = 10
            rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
            rgbLabel.ZIndex = 10
            rgbLabel.Parent = infoDeck

            local hsvLabel = Instance.new("TextLabel")
            hsvLabel.BackgroundTransparency = 1
            hsvLabel.Size = UDim2.new(1, 0, 0, 16)
            hsvLabel.Position = UDim2.new(0, 0, 0, 82)
            hsvLabel.Font = Theme.FontSemiBold
            hsvLabel.Text = "HSV: 213°, 52%, 100%"
            hsvLabel.TextColor3 = Theme.TextMuted
            hsvLabel.TextSize = 10
            hsvLabel.TextXAlignment = Enum.TextXAlignment.Left
            hsvLabel.ZIndex = 10
            hsvLabel.Parent = infoDeck

            local value_H, value_S, value_V = color:ToHSV()

            local function updatePickers()
                svPicker.BackgroundColor3 = Color3.fromHSV(value_H, 1, 1)
                color = Color3.fromHSV(value_H, value_S, value_V)
                swatch.BackgroundColor3 = color
                previewBox.BackgroundColor3 = color
                
                local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
                local hex = string.format("#%02X%02X%02X", r, g, b)
                hexLabel.Text = "HEX: " .. hex
                rgbLabel.Text = "RGB: " .. r .. ", " .. g .. ", " .. b
                hsvLabel.Text = string.format("HSV: %d°, %d%%, %d%%", math.floor(value_H * 360), math.floor(value_S * 100), math.floor(value_V * 100))

                if cpConfig.Callback then pcall(cpConfig.Callback, color) end
            end

            local function dragSV(mouseX, mouseY)
                local relX = math.clamp((mouseX - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
                local relY = math.clamp((mouseY - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
                cursor.Position = UDim2.new(relX, -4, relY, -4)
                value_S = relX
                value_V = 1 - relY
                updatePickers()
            end

            local function dragHue(mouseY)
                local relY = math.clamp((mouseY - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y, 0, 1)
                hueCursor.Position = UDim2.new(0, -2, relY, -2)
                value_H = relY
                updatePickers()
            end

            SetupUnifiedDrag(svPicker, function(pos) dragSV(pos.X, pos.Y) end, function(pos) dragSV(pos.X, pos.Y) end)
            SetupUnifiedDrag(blackGradFrame, function(pos) dragSV(pos.X, pos.Y) end, function(pos) dragSV(pos.X, pos.Y) end)
            SetupUnifiedDrag(hueSlider, function(pos) dragHue(pos.Y) end, function(pos) dragHue(pos.Y) end)

            swatch.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    value_H, value_S, value_V = color:ToHSV()
                    svPicker.BackgroundColor3 = Color3.fromHSV(value_H, 1, 1)
                    cursor.Position = UDim2.new(value_S, -4, 1 - value_V, -4)
                    hueCursor.Position = UDim2.new(0, -2, value_H, -2)
                    updatePickers()
                    
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, 168) }, 0.22, Theme.TweenStyle)
                    SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 130) }, 0.22, Theme.TweenStyle)
                else
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, 42) }, 0.18, Enum.EasingStyle.Quad)
                    SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 0) }, 0.18, Enum.EasingStyle.Quad)
                end
            end)

            container.Parent = gBody
            return {
                Get = function() return color end,
                Set = function(_, col)
                    color = col
                    swatch.BackgroundColor3 = col
                    previewBox.BackgroundColor3 = col
                    value_H, value_S, value_V = col:ToHSV()
                    svPicker.BackgroundColor3 = Color3.fromHSV(value_H, 1, 1)
                    cursor.Position = UDim2.new(value_S, -4, 1 - value_V, -4)
                    hueCursor.Position = UDim2.new(0, -2, value_H, -2)
                    updatePickers()
                end
            }
        end

        return Group
    end

    return Tab
end

function Window:_SwitchTab(tabData)
    if self.ActiveTab then
        local activePageGroup = self.ActiveTab._pageGroup
        SmoothTween(activePageGroup, { GroupTransparency = 1, Position = UDim2.new(0, -30, 0, 0) }, 0.18, Theme.TweenStyle)
        task.delay(0.18, function()
            activePageGroup.Visible = false
        end)
        
        SmoothTween(self.ActiveTab._btn, { BackgroundTransparency = 1 }, 0.15, Enum.EasingStyle.Quad)
        SmoothTween(self.ActiveTab._label, { TextColor3 = Theme.TextMuted }, 0.15, Enum.EasingStyle.Quad)
        if self.ActiveTab._icon then SmoothTween(self.ActiveTab._icon, { ImageColor3 = Theme.TextMuted }, 0.15, Enum.EasingStyle.Quad) end
    end
    
    self.ActiveTab = tabData
    local targetPageGroup = tabData._pageGroup
    
    targetPageGroup.Visible = true
    targetPageGroup.GroupTransparency = 1
    targetPageGroup.Position = UDim2.new(0, 30, 0, 0)
    
    SmoothTween(targetPageGroup, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.24, Theme.TweenStyle)
    SmoothTween(tabData._btn, { BackgroundTransparency = 0.88 }, 0.15, Enum.EasingStyle.Quad)
    SmoothTween(tabData._label, { TextColor3 = Theme.TextPrimary }, 0.15, Enum.EasingStyle.Quad)
    if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextPrimary }, 0.15, Enum.EasingStyle.Quad) end
end

local notifyContainer = nil

function LiquidGlass.Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local message = config.Message or ""
    local duration = config.Duration or 3.5
    local ntype = config.Type or "info"

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
        notifyContainer.Size = UDim2.new(0, 320, 1, 0)
        notifyContainer.Position = UDim2.new(0.5, -160, 0, 0)
        notifyContainer.ZIndex = 150
        notifyContainer.Parent = gui

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.VerticalAlignment = Enum.VerticalAlignment.Top
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.Padding = UDim.new(0, 10)
        list.Parent = notifyContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 16)
        pad.Parent = notifyContainer
    end

    local typeColors = {
        info = Theme.Accent,
        success = Theme.Success,
        warning = Theme.Warning,
        danger = Theme.Danger
    }
    local statusColor = typeColors[ntype] or Theme.Accent

    local card = Instance.new("Frame")
    card.Name = "iPhoneNotification"
    card.BackgroundColor3 = Theme.GlassSurface
    card.BackgroundTransparency = 0.05 -- More solid
    card.Size = UDim2.new(1, 0, 0, 56)
    card.ClipsDescendants = true
    card.ZIndex = 151
    card.Parent = notifyContainer
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Theme.GlassBorder
    cardStroke.Transparency = 0.7
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, statusColor)
    })
    strokeGrad.Rotation = 45
    strokeGrad.Parent = cardStroke

    local ringGlow = Instance.new("Frame")
    ringGlow.BackgroundColor3 = statusColor
    ringGlow.BackgroundTransparency = 0.65
    ringGlow.Size = UDim2.new(0, 32, 0, 32)
    ringGlow.Position = UDim2.new(0, 12, 0.5, -16)
    ringGlow.ZIndex = 152
    ringGlow.Parent = card
    Instance.new("UICorner", ringGlow).CornerRadius = UDim.new(0, 6)

    local icon = Instance.new("Frame")
    icon.BackgroundColor3 = statusColor
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0.5, -12, 0.5, -12)
    icon.ZIndex = 153
    icon.Parent = ringGlow
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 5)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.BackgroundTransparency = 1
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Font = Theme.FontBold
    iconLabel.Text = (ntype == "success" and "✓") or (ntype == "warning" and "⚠") or (ntype == "danger" and "✕") or "i"
    iconLabel.TextColor3 = Color3.fromRGB(12, 13, 20)
    iconLabel.TextSize = 14
    iconLabel.ZIndex = 154
    iconLabel.Parent = icon

    local textGroup = Instance.new("Frame")
    textGroup.BackgroundTransparency = 1
    textGroup.Size = UDim2.new(1, -114, 1, 0)
    textGroup.Position = UDim2.new(0, 52, 0, 0)
    textGroup.ZIndex = 152
    textGroup.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0.45, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
    titleLabel.Font = Theme.FontBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 152
    titleLabel.Parent = textGroup

    local msgLabel = Instance.new("TextLabel")
    msgLabel.BackgroundTransparency = 1
    msgLabel.Size = UDim2.new(1, 0, 0.45, 0)
    msgLabel.Position = UDim2.new(0, 0, 0.45, 0)
    msgLabel.Font = Theme.FontRegular
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.TextSecondary
    msgLabel.TextSize = 11
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.ZIndex = 152
    msgLabel.Parent = textGroup

    local timeLabel = Instance.new("TextLabel")
    timeLabel.BackgroundTransparency = 1
    timeLabel.Size = UDim2.new(0, 50, 0, 14)
    timeLabel.Position = UDim2.new(1, -62, 0, 10)
    timeLabel.Font = Theme.FontSemiBold
    timeLabel.Text = "now"
    timeLabel.TextColor3 = Theme.TextMuted
    timeLabel.TextSize = 10
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.ZIndex = 152
    timeLabel.Parent = card

    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundTransparency = 1
    cardStroke.Transparency = 1
    ringGlow.BackgroundTransparency = 1
    icon.BackgroundTransparency = 1
    iconLabel.TextTransparency = 1
    titleLabel.TextTransparency = 1
    msgLabel.TextTransparency = 1
    timeLabel.TextTransparency = 1

    SmoothTween(card, { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 0.05 }, 0.22, Enum.EasingStyle.Back)
    SmoothTween(cardStroke, { Transparency = 0.7 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(ringGlow, { BackgroundTransparency = 0.65 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(icon, { BackgroundTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(iconLabel, { TextTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(titleLabel, { TextTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(msgLabel, { TextTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)
    SmoothTween(timeLabel, { TextTransparency = 0 }, 0.22, Enum.EasingStyle.Quad)

    task.delay(duration, function()
        SmoothTween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.16)
        SmoothTween(cardStroke, { Transparency = 1 }, 0.16)
        SmoothTween(ringGlow, { BackgroundTransparency = 1 }, 0.16)
        SmoothTween(icon, { BackgroundTransparency = 1 }, 0.16)
        SmoothTween(iconLabel, { TextTransparency = 1 }, 0.16)
        SmoothTween(titleLabel, { TextTransparency = 1 }, 0.16)
        SmoothTween(msgLabel, { TextTransparency = 1 }, 0.16)
        SmoothTween(timeLabel, { TextTransparency = 1 }, 0.16)
        task.delay(0.18, function() card:Destroy() end)
    end)
end

function LiquidGlass:SetAccent(color)
    Theme.Accent = color
    Theme.AccentGlow = color
end

return LiquidGlass
