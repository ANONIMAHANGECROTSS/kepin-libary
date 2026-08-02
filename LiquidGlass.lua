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
    GlassBackground = Color3.fromRGB(11, 12, 20),
    GlassSurface = Color3.fromRGB(16, 18, 30),
    GlassBorder = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(44, 94, 254),
    AccentGlow = Color3.fromRGB(116, 54, 240),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(190, 195, 215),
    TextMuted = Color3.fromRGB(115, 125, 145),
    Success = Color3.fromRGB(100, 225, 160),
    Warning = Color3.fromRGB(255, 195, 85),
    Danger = Color3.fromRGB(255, 95, 105),
    GlassOpacity = 0.18,
    BorderOpacity = 0.22,
    ShadowOpacity = 0.70,
    TweenSpeed = 0.15, -- Significantly faster animations
    TweenStyle = Enum.EasingStyle.Quad,
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

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 105, 130))
    })
    gradient.Rotation = 45
    gradient.Parent = stroke

    return frame, stroke, corner
end

local Window = {}
Window.__index = Window

function LiquidGlass:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Window)

    self.Title = config.Title or "AURA UI"
    self.Subtitle = config.Subtitle or "v1.0"
    self.Width = config.Width or 640
    self.Height = config.Height or 440
    self.SidebarWidth = 165
    self.Tabs = {}
    self.ActiveTab = nil
    self._minimized = false

    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlassV4"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    -- Backdrop blur system
    local lightingBlur = Lighting:FindFirstChild("LiquidGlassBackdropBlur")
    if not lightingBlur then
        lightingBlur = Instance.new("BlurEffect")
        lightingBlur.Name = "LiquidGlassBackdropBlur"
        lightingBlur.Size = 0
        lightingBlur.Enabled = true
        lightingBlur.Parent = Lighting
    end
    self._lightingBlur = lightingBlur
    SmoothTween(lightingBlur, { Size = 16 }, 0.25)

    local winFrame, winStroke, winCorner = BuildGlassFrame({
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        Radius = UDim.new(0, 14),
        ClipsDescendants = false,
        ZIndex = 2
    })
    winFrame.Parent = gui
    self._winFrame = winFrame

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.95
    uiScale.Parent = winFrame

    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 16, 26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 13))
    })
    mainGradient.Rotation = 135
    mainGradient.Parent = winFrame

    local shadow = Instance.new("ImageLabel")
    shadow.Name = "AnchoredShadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 44, 1, 44)
    shadow.Position = UDim2.new(0, -22, 0, -22)
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 1 - Theme.ShadowOpacity
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(47, 47, 450, 450)
    shadow.ZIndex = winFrame.ZIndex - 1
    shadow.Parent = winFrame
    self._shadow = shadow

    local sheen = Instance.new("ImageLabel")
    sheen.Name = "Sheen"
    sheen.BackgroundTransparency = 1
    sheen.Size = UDim2.new(1, 0, 1, 0)
    sheen.Image = "rbxassetid://15623104935"
    sheen.ImageColor3 = Color3.fromRGB(255, 255, 255)
    sheen.ImageTransparency = 0.94
    sheen.ZIndex = winFrame.ZIndex + 5
    sheen.Parent = winFrame

    local sheenCorner = Instance.new("UICorner")
    sheenCorner.CornerRadius = UDim.new(0, 14)
    sheenCorner.Parent = sheen

    local islandFrame = Instance.new("TextButton")
    islandFrame.Name = "DynamicIsland"
    islandFrame.BackgroundColor3 = Color3.fromRGB(8, 9, 14)
    islandFrame.BackgroundTransparency = 0.08
    islandFrame.BorderSizePixel = 0
    islandFrame.Size = UDim2.new(0, 180, 0, 36)
    islandFrame.Position = UDim2.new(0.5, -90, 0, -50)
    islandFrame.ZIndex = 100
    islandFrame.Visible = false
    islandFrame.Text = ""
    islandFrame.Parent = gui

    local islandCorner = Instance.new("UICorner")
    islandCorner.CornerRadius = UDim.new(1, 0)
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

    local islandDotCorner = Instance.new("UICorner")
    islandDotCorner.CornerRadius = UDim.new(1, 0)
    islandDotCorner.Parent = islandDot

    local islandTitle = Instance.new("TextLabel")
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

    local canvas = Instance.new("CanvasGroup")
    canvas.Size = UDim2.new(1, 0, 1, 0)
    canvas.BackgroundTransparency = 1
    canvas.BorderSizePixel = 0
    canvas.ZIndex = 3
    canvas.GroupTransparency = 0
    canvas.Parent = winFrame

    -- Integrated Header Bar matches target style
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 0.98
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 48)
    header.ZIndex = 4
    header.Parent = canvas

    local headerBorder = Instance.new("Frame")
    headerBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    headerBorder.BackgroundTransparency = 0.92
    headerBorder.BorderSizePixel = 0
    headerBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBorder.ZIndex = 5
    headerBorder.Parent = header

    local titleGroup = Instance.new("Frame")
    titleGroup.BackgroundTransparency = 1
    titleGroup.Size = UDim2.new(0, 140, 1, 0)
    titleGroup.Position = UDim2.new(0, 16, 0, 0)
    titleGroup.ZIndex = 5
    titleGroup.Parent = header

    local mainTitle = Instance.new("TextLabel")
    mainTitle.BackgroundTransparency = 1
    mainTitle.Size = UDim2.new(1, 0, 1, 0)
    mainTitle.Font = Enum.Font.GothamBold
    mainTitle.Text = self.Title
    mainTitle.TextColor3 = Theme.TextPrimary
    mainTitle.TextSize = 13
    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
    mainTitle.ZIndex = 5
    mainTitle.Parent = titleGroup

    local versionTag = Instance.new("TextLabel")
    versionTag.BackgroundColor3 = Theme.Accent
    versionTag.Size = UDim2.new(0, 32, 0, 16)
    versionTag.Position = UDim2.new(0, 72, 0.5, -8)
    versionTag.Font = Enum.Font.GothamBold
    versionTag.Text = self.Subtitle
    versionTag.TextColor3 = Theme.TextPrimary
    versionTag.TextSize = 9
    versionTag.ZIndex = 6
    versionTag.Parent = titleGroup

    local vtCorner = Instance.new("UICorner")
    vtCorner.CornerRadius = UDim.new(0, 4)
    vtCorner.Parent = versionTag

    -- Mock Search Box from target style
    local searchBar = Instance.new("Frame")
    searchBar.BackgroundColor3 = Color3.fromRGB(24, 26, 42)
    searchBar.BackgroundTransparency = 0.4
    searchBar.Size = UDim2.new(0, 200, 0, 26)
    searchBar.Position = UDim2.new(0.5, -100, 0.5, -13)
    searchBar.ZIndex = 5
    searchBar.Parent = header

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 6)
    sbCorner.Parent = searchBar

    local sbStroke = Instance.new("UIStroke")
    sbStroke.Color = Color3.fromRGB(255, 255, 255)
    sbStroke.Transparency = 0.93
    sbStroke.Parent = searchBar

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Size = UDim2.new(0, 12, 0, 12)
    searchIcon.Position = UDim2.new(0, 10, 0.5, -6)
    searchIcon.Image = "rbxassetid://10747384394"
    searchIcon.ImageColor3 = Theme.TextMuted
    searchIcon.ZIndex = 6
    searchIcon.Parent = searchBar

    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Size = UDim2.new(1, -32, 1, 0)
    searchBox.Position = UDim2.new(0, 26, 0, 0)
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Search components..."
    searchBox.PlaceholderColor3 = Theme.TextMuted
    searchBox.Text = ""
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 6
    searchBox.Parent = searchBar

    local controls = Instance.new("Frame")
    controls.BackgroundTransparency = 1
    controls.Size = UDim2.new(0, 70, 1, 0)
    controls.Position = UDim2.new(1, -80, 0, 0)
    controls.ZIndex = 5
    controls.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.BackgroundTransparency = 0.1
    closeBtn.Size = UDim2.new(0, 11, 0, 11)
    closeBtn.Position = UDim2.new(1, -16, 0.5, -5)
    closeBtn.Text = ""
    closeBtn.ZIndex = 6
    closeBtn.Parent = controls

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    local minBtn = Instance.new("TextButton")
    minBtn.BackgroundColor3 = Theme.Warning
    minBtn.BackgroundTransparency = 0.1
    minBtn.Size = UDim2.new(0, 11, 0, 11)
    minBtn.Position = UDim2.new(1, -34, 0.5, -5)
    minBtn.Text = ""
    minBtn.ZIndex = 6
    minBtn.Parent = controls

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minBtn

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
    workspaceFrame.Size = UDim2.new(1, 0, 1, -48)
    workspaceFrame.Position = UDim2.new(0, 0, 0, 48)
    workspaceFrame.ZIndex = 4
    workspaceFrame.Parent = canvas

    local sidebar = Instance.new("Frame")
    sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebar.BackgroundTransparency = 0.99
    sidebar.BorderSizePixel = 0
    sidebar.Size = UDim2.new(0, self.SidebarWidth, 1, 0)
    sidebar.ZIndex = 4
    sidebar.Parent = workspaceFrame

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebarBorder.BackgroundTransparency = 0.92
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.ZIndex = 5
    sidebarBorder.Parent = sidebar

    local tabScroller = Instance.new("ScrollingFrame")
    tabScroller.BackgroundTransparency = 1
    tabScroller.BorderSizePixel = 0
    tabScroller.Size = UDim2.new(1, -1, 1, -95) -- Room for pro upgrade card
    tabScroller.ScrollBarThickness = 0
    tabScroller.ZIndex = 5
    tabScroller.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 4)
    tabListLayout.Parent = tabScroller

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.PaddingRight = UDim.new(0, 8)
    tabPad.PaddingTop = UDim.new(0, 8)
    tabPad.Parent = tabScroller

    -- Left sidebar upgrade block
    local proCard = Instance.new("Frame")
    proCard.Name = "ProCard"
    proCard.BackgroundColor3 = Color3.fromRGB(20, 22, 38)
    proCard.BackgroundTransparency = 0.4
    proCard.Size = UDim2.new(1, -16, 0, 75)
    proCard.Position = UDim2.new(0, 8, 1, -85)
    proCard.ZIndex = 5
    proCard.Parent = sidebar

    local pcCorner = Instance.new("UICorner")
    pcCorner.CornerRadius = UDim.new(0, 8)
    pcCorner.Parent = proCard

    local pcStroke = Instance.new("UIStroke")
    pcStroke.Color = Theme.Accent
    pcStroke.Transparency = 0.7
    pcStroke.Parent = proCard

    local pcTitle = Instance.new("TextLabel")
    pcTitle.BackgroundTransparency = 1
    pcTitle.Size = UDim2.new(1, -16, 0, 18)
    pcTitle.Position = UDim2.new(0, 8, 0, 6)
    pcTitle.Font = Enum.Font.GothamBold
    pcTitle.Text = "👑 UI Library Pro"
    pcTitle.TextColor3 = Theme.TextPrimary
    pcTitle.TextSize = 11
    pcTitle.TextXAlignment = Enum.TextXAlignment.Left
    pcTitle.ZIndex = 6
    pcTitle.Parent = proCard

    local pcDesc = Instance.new("TextLabel")
    pcDesc.BackgroundTransparency = 1
    pcDesc.Size = UDim2.new(1, -16, 0, 12)
    pcDesc.Position = UDim2.new(0, 8, 0, 22)
    pcDesc.Font = Enum.Font.Gotham
    pcDesc.Text = "Unlock premium assets"
    pcDesc.TextColor3 = Theme.TextMuted
    pcDesc.TextSize = 9
    pcDesc.TextXAlignment = Enum.TextXAlignment.Left
    pcDesc.ZIndex = 6
    pcDesc.Parent = proCard

    local pcBtn = Instance.new("TextButton")
    pcBtn.BackgroundColor3 = Theme.Accent
    pcBtn.Size = UDim2.new(1, -16, 0, 22)
    pcBtn.Position = UDim2.new(0, 8, 1, -28)
    pcBtn.Font = Enum.Font.GothamBold
    pcBtn.Text = "Upgrade Now"
    pcBtn.TextColor3 = Theme.TextPrimary
    pcBtn.TextSize = 10
    pcBtn.ZIndex = 6
    pcBtn.Parent = proCard

    local pcbCorner = Instance.new("UICorner")
    pcbCorner.CornerRadius = UDim.new(0, 5)
    pcbCorner.Parent = pcBtn

    local pcbGrad = Instance.new("UIGradient")
    pcbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentGlow)
    })
    pcbGrad.Parent = pcBtn

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, self.SidebarWidth, 0, 0)
    contentArea.ZIndex = 4
    contentArea.ClipsDescendants = true
    contentArea.Parent = workspaceFrame
    self._contentArea = contentArea

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
        local nWidth = math.clamp(rStartWinSize.X.Offset + delta.X, 480, 900)
        local nHeight = math.clamp(rStartWinSize.Y.Offset + delta.Y, 320, 650)
        
        winFrame.Size = UDim2.new(0, nWidth, 0, nHeight)
        contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    end)

    local sStartMouse, sStartWidth
    SetupUnifiedDrag(sidebarResizeHandle, function(mousePos)
        sStartMouse = mousePos
        sStartWidth = sidebar.Size.X.Offset
    end, function(mousePos)
        local delta = mousePos - sStartMouse
        local nWidth = math.clamp(sStartWidth + delta.X, 120, 220)
        
        self.SidebarWidth = nWidth
        sidebar.Size = UDim2.new(0, nWidth, 1, 0)
        contentArea.Size = UDim2.new(1, -nWidth, 1, 0)
        contentArea.Position = UDim2.new(0, nWidth, 0, 0)
        proCard.Size = UDim2.new(1, -16, 0, 75)
    end)

    local originalSize, originalPos

    local function ToggleMinimize()
        self._minimized = not self._minimized
        if self._minimized then
            originalSize = winFrame.Size
            originalPos = winFrame.Position

            SmoothTween(canvas, { GroupTransparency = 1 }, 0.12)
            SmoothTween(shadow, { ImageTransparency = 1 }, 0.12)
            SmoothTween(lightingBlur, { Size = 0 }, 0.15)
            task.delay(0.12, function()
                canvas.Visible = false
            end)

            SmoothTween(winFrame, {
                Size = UDim2.new(0, 180, 0, 36),
                Position = UDim2.new(0.5, -90, 0, 15),
                BackgroundTransparency = 0.08
            }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            SmoothTween(winCorner, { CornerRadius = UDim.new(1, 0) }, 0.2)
            SmoothTween(sheenCorner, { CornerRadius = UDim.new(1, 0) }, 0.2)
            SmoothTween(uiScale, { Scale = 0.96 }, 0.15)

            task.delay(0.15, function()
                islandFrame.Size = UDim2.new(0, 180, 0, 36)
                islandFrame.Position = UDim2.new(0.5, -90, 0, 15)
                islandFrame.Visible = true
            end)
        else
            islandFrame.Visible = false
            canvas.Visible = true

            SmoothTween(winFrame, {
                Size = originalSize,
                Position = originalPos,
                BackgroundTransparency = 1 - Theme.GlassOpacity
            }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            SmoothTween(winCorner, { CornerRadius = UDim.new(0, 14) }, 0.25)
            SmoothTween(sheenCorner, { CornerRadius = UDim.new(0, 14) }, 0.25)
            SmoothTween(uiScale, { Scale = 1.0 }, 0.15)

            SmoothTween(canvas, { GroupTransparency = 0 }, 0.15)
            SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.15)
            SmoothTween(lightingBlur, { Size = 16 }, 0.2)
        end
    end

    minBtn.MouseButton1Click:Connect(ToggleMinimize)
    islandFrame.MouseButton1Click:Connect(ToggleMinimize)

    closeBtn.MouseButton1Click:Connect(function()
        SmoothTween(winFrame, { 
            Size = UDim2.new(0, self.Width, 0, 0), 
            Position = UDim2.new(0.5, -self.Width/2, 0.5, 0),
            BackgroundTransparency = 1 
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        SmoothTween(uiScale, { Scale = 0.95 }, 0.18)
        SmoothTween(canvas, { GroupTransparency = 1 }, 0.12)
        SmoothTween(shadow, { ImageTransparency = 1 }, 0.12)
        SmoothTween(lightingBlur, { Size = 0 }, 0.2)

        task.delay(0.25, function() 
            gui:Destroy() 
            if lightingBlur then lightingBlur:Destroy() end
        end)
    end)

    canvas.GroupTransparency = 1
    shadow.ImageTransparency = 1

    SmoothTween(winFrame, { BackgroundTransparency = 1 - Theme.GlassOpacity }, 0.15)
    SmoothTween(uiScale, { Scale = 1.0 }, 0.15)
    SmoothTween(canvas, { GroupTransparency = 0 }, 0.12)
    SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.12)

    self._tabScroller = tabScroller
    return self
end

function Window:AddTab(name, iconId)
    local tabData = { Name = name, Elements = {} }

    local tabBtn = Instance.new("TextButton")
    tabBtn.BackgroundColor3 = Theme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 30)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Text = ""
    tabBtn.ZIndex = 6
    tabBtn.Parent = self._tabScroller

    local tabBtnCorner = Instance.new("UICorner")
    tabBtnCorner.CornerRadius = UDim.new(0, 6)
    tabBtnCorner.Parent = tabBtn

    local offset = 8
    if iconId then
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 14, 0, 14)
        icon.Position = UDim2.new(0, 10, 0.5, -7)
        icon.Image = iconId
        icon.ImageColor3 = Theme.TextMuted
        icon.ZIndex = 7
        icon.Parent = tabBtn
        tabData._icon = icon
        offset = 30
    end

    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundTransparency = 1
    tabLabel.Size = UDim2.new(1, -offset, 1, 0)
    tabLabel.Position = UDim2.new(0, offset, 0, 0)
    tabLabel.Font = Enum.Font.GothamSemibold
    tabLabel.Text = name
    tabLabel.TextColor3 = Theme.TextMuted
    tabLabel.TextSize = 11
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.ZIndex = 7
    tabLabel.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Theme.Accent
    page.ScrollBarImageTransparency = 0.6
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 5
    page.Parent = self._contentArea

    local pageList = Instance.new("UIListLayout")
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Padding = UDim.new(0, 6)
    pageList.Parent = page

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft = UDim.new(0, 12)
    pagePad.PaddingRight = UDim.new(0, 12)
    pagePad.PaddingTop = UDim.new(0, 12)
    pagePad.PaddingBottom = UDim.new(0, 12)
    pagePad.Parent = page

    tabData._btn = tabBtn
    tabData._label = tabLabel
    tabData._page = page

    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabData then
            SmoothTween(tabBtn, { BackgroundTransparency = 0.95 }, 0.1)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextSecondary }, 0.1)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextSecondary }, 0.1) end
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then
            SmoothTween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextMuted }, 0.1)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextMuted }, 0.1) end
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
    Tab._page = page
    Tab._order = 0

    function Tab:AddSection(text)
        local section = Instance.new("Frame")
        section.BackgroundTransparency = 1
        section.Size = UDim2.new(1, 0, 0, 24)
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

    function Tab:AddButton(config)
        config = config or {}
        local btn, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 36),
            Radius = UDim.new(0, 8),
            ZIndex = 5
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
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = btn

        local click = Instance.new("TextButton")
        click.BackgroundTransparency = 1
        click.Size = UDim2.new(1, 0, 1, 0)
        click.Text = ""
        click.ZIndex = 7
        click.Parent = btn

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.GlassSurface),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 33, 50))
        })
        grad.Parent = btn

        click.MouseEnter:Connect(function()
            SmoothTween(btn, { BackgroundTransparency = 0.8 }, 0.1)
        end)
        click.MouseLeave:Connect(function()
            SmoothTween(btn, { BackgroundTransparency = 1 - Theme.GlassOpacity }, 0.1)
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

    function Tab:AddToggle(config)
        config = config or {}
        local state = config.Default or false

        local row, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 36),
            Radius = UDim.new(0, 8),
            ZIndex = 5
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
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = row

        local track = Instance.new("Frame")
        track.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 60, 75)
        track.BorderSizePixel = 0
        track.Size = UDim2.new(0, 32, 0, 16)
        track.Position = UDim2.new(1, -46, 0.5, -8)
        track.ZIndex = 6
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
        track.Parent = row

        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Size = UDim2.new(0, 12, 0, 12)
        thumb.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
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
            SmoothTween(track, {
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 60, 75)
            }, 0.15)
            SmoothTween(thumb, {
                Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }, 0.15)
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
            Get = function() return state end
        }
    end

    function Tab:AddSlider(config)
        config = config or {}
        local min = config.Min or 0
        local max = config.Max or 100
        local value = config.Value or min
        local suffix = config.Suffix or ""

        local container, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 48),
            Radius = UDim.new(0, 8),
            ZIndex = 5
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -80, 0, 20)
        label.Position = UDim2.new(0, 14, 0, 4)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Slider"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local valLabel = Instance.new("TextLabel")
        valLabel.BackgroundTransparency = 1
        valLabel.Size = UDim2.new(0, 70, 0, 20)
        valLabel.Position = UDim2.new(1, -84, 0, 4)
        valLabel.Font = Enum.Font.GothamBold
        valLabel.Text = value .. suffix
        valLabel.TextColor3 = Theme.Accent
        valLabel.TextSize = 11
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.ZIndex = 6
        valLabel.Parent = container

        local track = Instance.new("Frame")
        track.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
        track.Size = UDim2.new(1, -28, 0, 4)
        track.Position = UDim2.new(0, 14, 1, -14)
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

        local thumb = Instance.new("Frame")
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.Size = UDim2.new(0, 10, 0, 10)
        thumb.Position = UDim2.new((value - min) / (max - min), -5, 0.5, -5)
        thumb.ZIndex = 8
        thumb.Parent = track

        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb

        local function updateSlider(inputX)
            local ratio = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * ratio)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            thumb.Position = UDim2.new(ratio, -5, 0.5, -5)
            valLabel.Text = value .. suffix
            if config.Callback then pcall(config.Callback, value) end
        end

        SetupUnifiedDrag(track, function(mousePos)
            updateSlider(mousePos.X)
        end, function(mousePos)
            updateSlider(mousePos.X)
        end)

        SetupUnifiedDrag(thumb, function(mousePos)
            updateSlider(mousePos.X)
        end, function(mousePos)
            updateSlider(mousePos.X)
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
                if config.Callback then pcall(config.Callback, val) end
            end,
            Get = function() return value end
        }
    end

    function Tab:AddDropdown(config)
        config = config or {}
        local options = config.Options or {}
        local selected = config.Default or (options[1] or "Select...")
        local isOpen = false

        local container, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 36),
            Radius = UDim.new(0, 8),
            ZIndex = 5
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0.5, 0, 0, 36)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Dropdown"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local trigger = Instance.new("TextButton")
        trigger.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
        trigger.BorderSizePixel = 0
        trigger.Size = UDim2.new(0.45, 0, 0, 24)
        trigger.Position = UDim2.new(0.55, -14, 0, 6)
        trigger.Font = Enum.Font.GothamSemibold
        trigger.Text = selected .. "  ▾"
        trigger.TextColor3 = Theme.TextSecondary
        trigger.TextSize = 11
        trigger.ZIndex = 6
        trigger.Parent = container

        local trigCorner = Instance.new("UICorner")
        trigCorner.CornerRadius = UDim.new(0, 6)
        trigCorner.Parent = trigger

        local listHolder = Instance.new("Frame")
        listHolder.BackgroundTransparency = 1
        listHolder.Position = UDim2.new(0, 0, 0, 36)
        listHolder.Size = UDim2.new(1, 0, 1, -36)
        listHolder.ClipsDescendants = true
        listHolder.ZIndex = 6
        listHolder.Parent = container

        local holderLayout = Instance.new("UIListLayout")
        holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
        holderLayout.Parent = listHolder

        local function rebuildList()
            for _, c in ipairs(listHolder:GetChildren()) do
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
                optBtn.ZIndex = 7
                optBtn.Parent = listHolder

                optBtn.MouseButton1Click:Connect(function()
                    selected = value
                    trigger.Text = value .. "  ▾"
                    isOpen = false
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.15)
                    rebuildList()
                    if config.Callback then pcall(config.Callback, value) end
                end)
            end
        end

        trigger.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                rebuildList()
                local targetHeight = 36 + (#options * 28)
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2, Enum.EasingStyle.Quint)
            else
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.15)
            end
        end)

        container.Parent = page
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

    function Tab:AddInput(config)
        config = config or {}
        local container, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 48),
            Radius = UDim.new(0, 8),
            ZIndex = 5
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -14, 0, 16)
        label.Position = UDim2.new(0, 14, 0, 4)
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
        box.Size = UDim2.new(1, -28, 0, 20)
        box.Position = UDim2.new(0, 14, 1, -24)
        box.Font = Enum.Font.Gotham
        box.PlaceholderText = config.Placeholder or "Write here..."
        box.PlaceholderColor3 = Theme.TextMuted
        box.Text = config.Default or ""
        box.TextColor3 = Theme.TextPrimary
        box.TextSize = 11
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ZIndex = 6
        box.Parent = container

        local boxPad = Instance.new("UIPadding")
        boxPad.PaddingLeft = UDim.new(0, 6)
        boxPad.Parent = box

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 5)
        boxCorner.Parent = box

        box.FocusLost:Connect(function(entered)
            if config.Callback then pcall(config.Callback, box.Text, entered) end
        end)

        container.Parent = page
        return {
            Get = function() return box.Text end,
            Set = function(_, txt) box.Text = txt end
        }
    end

    function Tab:AddKeybind(config)
        config = config or {}
        local key = config.Default or Enum.KeyCode.Unknown
        local listening = false

        local row, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 36),
            Radius = UDim.new(0, 8),
            ZIndex = 5
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
        label.TextSize = 11
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
            Get = function() return key end
        }
    end

    function Tab:AddColorPicker(config)
        config = config or {}
        local color = config.Default or Color3.fromRGB(120, 180, 255)
        local isOpen = false

        local container, _ = BuildGlassFrame({
            Size = UDim2.new(1, 0, 0, 36),
            Radius = UDim.new(0, 8),
            ZIndex = 5
        })
        container.LayoutOrder = Tab._order
        Tab._order += 1

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -70, 0, 36)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.Font = Enum.Font.GothamSemibold
        label.Text = config.Text or "Color Picker"
        label.TextColor3 = Theme.TextPrimary
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 6
        label.Parent = container

        local swatch = Instance.new("TextButton")
        swatch.BackgroundColor3 = color
        swatch.BorderSizePixel = 0
        swatch.Size = UDim2.new(0, 32, 0, 20)
        swatch.Position = UDim2.new(1, -46, 0, 8)
        swatch.Text = ""
        swatch.ZIndex = 6
        swatch.Parent = container

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(0, 5)
        swatchCorner.Parent = swatch

        local tray = Instance.new("Frame")
        tray.BackgroundTransparency = 1
        tray.Position = UDim2.new(0, 0, 0, 36)
        tray.Size = UDim2.new(1, 0, 0, 0)
        tray.ClipsDescendants = true
        tray.ZIndex = 6
        tray.Parent = container

        local svPicker = Instance.new("Frame")
        svPicker.Size = UDim2.new(0, 110, 0, 110)
        svPicker.Position = UDim2.new(0, 14, 0, 10)
        svPicker.ZIndex = 7
        svPicker.Parent = tray

        local svCorner = Instance.new("UICorner")
        svCorner.CornerRadius = UDim.new(0, 6)
        svCorner.Parent = svPicker

        local whiteGradFrame = Instance.new("Frame")
        whiteGradFrame.Size = UDim2.new(1, 0, 1, 0)
        whiteGradFrame.BackgroundTransparency = 0
        whiteGradFrame.ZIndex = 8
        whiteGradFrame.Parent = svPicker

        local wgCorner = Instance.new("UICorner")
        wgCorner.CornerRadius = UDim.new(0, 6)
        wgCorner.Parent = whiteGradFrame

        local whiteGrad = Instance.new("UIGradient")
        whiteGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
        whiteGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        whiteGrad.Parent = whiteGradFrame

        local blackGradFrame = Instance.new("Frame")
        blackGradFrame.Size = UDim2.new(1, 0, 1, 0)
        blackGradFrame.BackgroundTransparency = 0
        blackGradFrame.ZIndex = 9
        blackGradFrame.Parent = svPicker

        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 6)
        bgCorner.Parent = blackGradFrame

        local blackGrad = Instance.new("UIGradient")
        blackGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
        })
        blackGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
        blackGrad.Rotation = 90
        blackGrad.Parent = blackGradFrame

        local cursor = Instance.new("Frame")
        cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        cursor.Size = UDim2.new(0, 8, 0, 8)
        cursor.ZIndex = 10
        cursor.Parent = svPicker

        local cursorCorner = Instance.new("UICorner")
        cursorCorner.CornerRadius = UDim.new(1, 0)
        cursorCorner.Parent = cursor

        local cursorStroke = Instance.new("UIStroke")
        cursorStroke.Color = Color3.fromRGB(0, 0, 0)
        cursorStroke.Thickness = 1
        cursorStroke.Parent = cursor

        local hueSlider = Instance.new("Frame")
        hueSlider.Size = UDim2.new(0, 16, 0, 110)
        hueSlider.Position = UDim2.new(0, 134, 0, 10)
        hueSlider.ZIndex = 7
        hueSlider.Parent = tray

        local hueCorner = Instance.new("UICorner")
        hueCorner.CornerRadius = UDim.new(1, 0)
        hueCorner.Parent = hueSlider

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
        hueCursor.ZIndex = 8
        hueCursor.Parent = hueSlider

        local hueCursorStroke = Instance.new("UIStroke")
        hueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
        hueCursorStroke.Thickness = 1
        hueCursorStroke.Parent = hueCursor

        local value_H, value_S, value_V = color:ToHSV()

        local function updatePickers()
            svPicker.BackgroundColor3 = Color3.fromHSV(value_H, 1, 1)
            color = Color3.fromHSV(value_H, value_S, value_V)
            swatch.BackgroundColor3 = color
            if config.Callback then pcall(config.Callback, color) end
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
                
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 166) }, 0.20, Enum.EasingStyle.Quint)
                SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 130) }, 0.20, Enum.EasingStyle.Quint)
            else
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.15)
                SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            end
        end)

        container.Parent = page
        return {
            Get = function() return color end,
            Set = function(_, col)
                color = col
                swatch.BackgroundColor3 = col
                value_H, value_S, value_V = col:ToHSV()
                svPicker.BackgroundColor3 = Color3.fromHSV(value_H, 1, 1)
                cursor.Position = UDim2.new(value_S, -4, 1 - value_V, -4)
                hueCursor.Position = UDim2.new(0, -2, value_H, -2)
                if config.Callback then pcall(config.Callback, col) end
            end
        }
    end

    return Tab
end

function Window:_SwitchTab(tabData)
    if self.ActiveTab then
        self.ActiveTab._page.Visible = false
        SmoothTween(self.ActiveTab._btn, { BackgroundTransparency = 1 }, 0.15)
        SmoothTween(self.ActiveTab._label, { TextColor3 = Theme.TextMuted }, 0.15)
        if self.ActiveTab._icon then SmoothTween(self.ActiveTab._icon, { ImageColor3 = Theme.TextMuted }, 0.15) end
    end
    self.ActiveTab = tabData
    tabData._page.Visible = true
    SmoothTween(tabData._btn, { BackgroundTransparency = 0.88 }, 0.15)
    SmoothTween(tabData._label, { TextColor3 = Theme.TextPrimary }, 0.15)
    if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextPrimary }, 0.15) end
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
        notifyContainer.Size = UDim2.new(0, 300, 1, 0)
        notifyContainer.Position = UDim2.new(0.5, -150, 0, 0)
        notifyContainer.ZIndex = 150
        notifyContainer.Parent = gui

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.VerticalAlignment = Enum.VerticalAlignment.Top
        list.Padding = UDim.new(0, 8)
        list.Parent = notifyContainer

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 20)
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
    card.BackgroundTransparency = 0.08
    card.Size = UDim2.new(1, 0, 0, 48)
    card.ClipsDescendants = true
    card.ZIndex = 151
    card.Parent = notifyContainer

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(1, 0)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Theme.GlassBorder
    cardStroke.Transparency = 0.8
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local icon = Instance.new("Frame")
    icon.BackgroundColor3 = statusColor
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 12, 0.5, -12)
    icon.ZIndex = 152
    icon.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local iconLabel = Instance.new("TextLabel")
    iconLabel.BackgroundTransparency = 1
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = "!"
    iconLabel.TextColor3 = Color3.fromRGB(15, 15, 20)
    iconLabel.TextSize = 12
    iconLabel.ZIndex = 153
    iconLabel.Parent = icon

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -94, 0, 14)
    titleLabel.Position = UDim2.new(0, 44, 0, 10)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 152
    titleLabel.Parent = card

    local msgLabel = Instance.new("TextLabel")
    msgLabel.BackgroundTransparency = 1
    msgLabel.Size = UDim2.new(1, -94, 0, 14)
    msgLabel.Position = UDim2.new(0, 44, 0, 24)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.TextSecondary
    msgLabel.TextSize = 10
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.ZIndex = 152
    msgLabel.Parent = card

    local timeLabel = Instance.new("TextLabel")
    timeLabel.BackgroundTransparency = 1
    timeLabel.Size = UDim2.new(0, 40, 0, 14)
    timeLabel.Position = UDim2.new(1, -52, 0, 10)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Text = "now"
    timeLabel.TextColor3 = Theme.TextMuted
    timeLabel.TextSize = 10
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.ZIndex = 152
    timeLabel.Parent = card

    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundTransparency = 1
    cardStroke.Transparency = 1
    icon.BackgroundTransparency = 1
    iconLabel.TextTransparency = 1
    titleLabel.TextTransparency = 1
    msgLabel.TextTransparency = 1
    timeLabel.TextTransparency = 1

    SmoothTween(card, { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 0.08 }, 0.25, Enum.EasingStyle.Back)
    SmoothTween(cardStroke, { Transparency = 0.8 }, 0.25)
    SmoothTween(icon, { BackgroundTransparency = 0 }, 0.25)
    SmoothTween(iconLabel, { TextTransparency = 0 }, 0.25)
    SmoothTween(titleLabel, { TextTransparency = 0 }, 0.25)
    SmoothTween(msgLabel, { TextTransparency = 0 }, 0.25)
    SmoothTween(timeLabel, { TextTransparency = 0 }, 0.25)

    task.delay(duration, function()
        SmoothTween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.18)
        SmoothTween(cardStroke, { Transparency = 1 }, 0.18)
        SmoothTween(icon, { BackgroundTransparency = 1 }, 0.18)
        SmoothTween(iconLabel, { TextTransparency = 1 }, 0.18)
        SmoothTween(titleLabel, { TextTransparency = 1 }, 0.18)
        SmoothTween(msgLabel, { TextTransparency = 1 }, 0.18)
        SmoothTween(timeLabel, { TextTransparency = 1 }, 0.18)
        task.delay(0.2, function() card:Destroy() end)
    end)
end

function LiquidGlass:SetAccent(color)
    Theme.Accent = color
    Theme.AccentGlow = color
end

return LiquidGlass
