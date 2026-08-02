local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Theme = {
    GlassBackground = Color3.fromRGB(10, 11, 16),
    GlassSurface = Color3.fromRGB(18, 20, 29),
    GlassBorder = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(120, 180, 255),
    AccentGlow = Color3.fromRGB(80, 140, 255),
    AccentDark = Color3.fromRGB(40, 100, 220),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(185, 195, 215),
    TextMuted = Color3.fromRGB(115, 125, 145),
    Success = Color3.fromRGB(100, 225, 160),
    Warning = Color3.fromRGB(255, 195, 85),
    Danger = Color3.fromRGB(255, 95, 105),
    GlassOpacity = 0.22,
    BorderOpacity = 0.22,
    ShadowOpacity = 0.60,
    TweenSpeed = 0.28,
    TweenStyle = Enum.EasingStyle.Quint,
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
    corner.CornerRadius = props.Radius or UDim.new(0, 12)
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
        ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 130, 130))
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

    self.Title = config.Title or "Liquid Glass Hub"
    self.Subtitle = config.Subtitle or "Mobile Ready"
    self.Width = config.Width or 580
    self.Height = config.Height or 400
    self.SidebarWidth = 150
    self.Tabs = {}
    self.ActiveTab = nil
    self._minimized = false

    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlassV3"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    local winFrame, winStroke, winCorner = BuildGlassFrame({
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        Radius = UDim.new(0, 14),
        ClipsDescendants = false,
        ZIndex = 2
    })
    winFrame.Parent = gui
    self._winFrame = winFrame

    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 16))
    })
    mainGradient.Rotation = 135
    mainGradient.Parent = winFrame

    -- Anchored shadow directly parented to the main frame to prevent resizing desync
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "AnchoredShadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 38, 1, 38)
    shadow.Position = UDim2.new(0, -19, 0, -19)
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 1 - Theme.ShadowOpacity
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(47, 47, 450, 450)
    shadow.ZIndex = winFrame.ZIndex - 1
    shadow.Parent = winFrame
    self._shadow = shadow

    -- Glass specular gloss overlay
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
    islandFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
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

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 0.97
    header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 44)
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
    titleGroup.Size = UDim2.new(0.6, 0, 1, 0)
    titleGroup.Position = UDim2.new(0, 16, 0, 0)
    titleGroup.ZIndex = 5
    titleGroup.Parent = header

    local mainTitle = Instance.new("TextLabel")
    mainTitle.BackgroundTransparency = 1
    mainTitle.Size = UDim2.new(1, 0, 0.55, 0)
    mainTitle.Position = UDim2.new(0, 0, 0.1, 0)
    mainTitle.Font = Enum.Font.GothamBold
    mainTitle.Text = self.Title
    mainTitle.TextColor3 = Theme.TextPrimary
    mainTitle.TextSize = 14
    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
    mainTitle.ZIndex = 5
    mainTitle.Parent = titleGroup

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
    subTitle.Parent = titleGroup

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
    workspaceFrame.Size = UDim2.new(1, 0, 1, -44)
    workspaceFrame.Position = UDim2.new(0, 0, 0, 44)
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
    sidebarBorder.BackgroundTransparency = 0.91
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
    tabListLayout.Padding = UDim.new(0, 4)
    tabListLayout.Parent = tabScroller

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 8)
    tabPad.PaddingRight = UDim.new(0, 8)
    tabPad.PaddingTop = UDim.new(0, 8)
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
        local nWidth = math.clamp(rStartWinSize.X.Offset + delta.X, 450, 900)
        local nHeight = math.clamp(rStartWinSize.Y.Offset + delta.Y, 300, 650)
        
        winFrame.Size = UDim2.new(0, nWidth, 0, nHeight)
        contentArea.Size = UDim2.new(1, -self.SidebarWidth, 1, 0)
    end)

    local sStartMouse, sStartWidth
    SetupUnifiedDrag(sidebarResizeHandle, function(mousePos)
        sStartMouse = mousePos
        sStartWidth = sidebar.Size.X.Offset
    end, function(mousePos)
        local delta = mousePos - sStartMouse
        local nWidth = math.clamp(sStartWidth + delta.X, 100, 200)
        
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

            SmoothTween(canvas, { GroupTransparency = 1 }, 0.15)
            SmoothTween(shadow, { ImageTransparency = 1 }, 0.15)
            task.delay(0.15, function()
                canvas.Visible = false
            end)

            SmoothTween(winFrame, {
                Size = UDim2.new(0, 180, 0, 36),
                Position = UDim2.new(0.5, -90, 0, 15),
                BackgroundTransparency = 0.08
            }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            SmoothTween(winCorner, { CornerRadius = UDim.new(1, 0) }, 0.35)
            SmoothTween(sheenCorner, { CornerRadius = UDim.new(1, 0) }, 0.35)

            task.delay(0.2, function()
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
            }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            SmoothTween(winCorner, { CornerRadius = UDim.new(0, 14) }, 0.35)
            SmoothTween(sheenCorner, { CornerRadius = UDim.new(0, 14) }, 0.35)

            SmoothTween(canvas, { GroupTransparency = 0 }, 0.3)
            SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.3)
        end
    end

    minBtn.MouseButton1Click:Connect(ToggleMinimize)
    islandFrame.MouseButton1Click:Connect(ToggleMinimize)

    closeBtn.MouseButton1Click:Connect(function()
        SmoothTween(winFrame, { Size = UDim2.new(0, self.Width, 0, 0), BackgroundTransparency = 1 }, 0.25)
        task.delay(0.3, function() gui:Destroy() end)
    end)

    winFrame.Size = UDim2.new(0, self.Width, 0, 0)
    winFrame.BackgroundTransparency = 1
    canvas.GroupTransparency = 1
    shadow.ImageTransparency = 1

    SmoothTween(winFrame, {
        Size = UDim2.new(0, self.Width, 0, self.Height),
        BackgroundTransparency = 1 - Theme.GlassOpacity
    }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    SmoothTween(canvas, { GroupTransparency = 0 }, 0.45)
    SmoothTween(shadow, { ImageTransparency = 1 - Theme.ShadowOpacity }, 0.45)

    self._tabScroller = tabScroller
    return self
end

function Window:AddTab(name, iconId)
    local tabData = { Name = name, Elements = {} }

    local tabBtn = Instance.new("TextButton")
    tabBtn.BackgroundColor3 = Theme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.BorderSizePixel = 0
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
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
    tabLabel.TextSize = 12
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.ZIndex = 7
    tabLabel.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
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
            SmoothTween(tabBtn, { BackgroundTransparency = 0.95 }, 0.15)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextSecondary }, 0.15)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextSecondary }, 0.15) end
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then
            SmoothTween(tabBtn, { BackgroundTransparency = 1 }, 0.15)
            SmoothTween(tabLabel, { TextColor3 = Theme.TextMuted }, 0.15)
            if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextMuted }, 0.15) end
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
            SmoothTween(btn, { BackgroundTransparency = 0.85 }, 0.15)
        end)
        click.MouseLeave:Connect(function()
            SmoothTween(btn, { BackgroundTransparency = 1 - Theme.GlassOpacity }, 0.15)
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
        label.TextSize = 12
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
            }, 0.2)
            SmoothTween(thumb, {
                Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }, 0.2)
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
        label.TextSize = 12
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
        valLabel.TextSize = 12
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
        label.TextSize = 12
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
                    SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.2)
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
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.25, Enum.EasingStyle.Quint)
            else
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.2)
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
        box.TextSize = 12
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
        label.TextSize = 12
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

        -- Procedural Paint UI setup (HSV gradients generated strictly in Lua)
        local hueSlider = Instance.new("Frame")
        hueSlider.Size = UDim2.new(1, -28, 0, 14)
        hueSlider.Position = UDim2.new(0, 14, 0, 10)
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
        hueGrad.Parent = hueSlider

        local hueNode = Instance.new("Frame")
        hueNode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hueNode.Size = UDim2.new(0, 6, 0, 18)
        hueNode.Position = UDim2.new(0.5, -3, 0.5, -9)
        hueNode.ZIndex = 8
        hueNode.Parent = hueSlider

        local hueNodeCorner = Instance.new("UICorner")
        hueNodeCorner.CornerRadius = UDim.new(1, 0)
        hueNodeCorner.Parent = hueNode

        local satSlider = Instance.new("Frame")
        satSlider.Size = UDim2.new(1, -28, 0, 14)
        satSlider.Position = UDim2.new(0, 14, 0, 36)
        satSlider.ZIndex = 7
        satSlider.Parent = tray

        local satCorner = Instance.new("UICorner")
        satCorner.CornerRadius = UDim.new(1, 0)
        satCorner.Parent = satSlider

        local satGrad = Instance.new("UIGradient")
        satGrad.Parent = satSlider

        local satNode = Instance.new("Frame")
        satNode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        satNode.Size = UDim2.new(0, 6, 0, 18)
        satNode.Position = UDim2.new(0.5, -3, 0.5, -9)
        satNode.ZIndex = 8
        satNode.Parent = satSlider

        local satNodeCorner = Instance.new("UICorner")
        satNodeCorner.CornerRadius = UDim.new(1, 0)
        satNodeCorner.Parent = satNode

        local valSlider = Instance.new("Frame")
        valSlider.Size = UDim2.new(1, -28, 0, 14)
        valSlider.Position = UDim2.new(0, 14, 0, 62)
        valSlider.ZIndex = 7
        valSlider.Parent = tray

        local valCorner = Instance.new("UICorner")
        valCorner.CornerRadius = UDim.new(1, 0)
        valCorner.Parent = valSlider

        local valGrad = Instance.new("UIGradient")
        valGrad.Parent = valSlider

        local valNode = Instance.new("Frame")
        valNode.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        valNode.Size = UDim2.new(0, 6, 0, 18)
        valNode.Position = UDim2.new(0.5, -3, 0.5, -9)
        valNode.ZIndex = 8
        valNode.Parent = valSlider

        local valNodeCorner = Instance.new("UICorner")
        valNodeCorner.CornerRadius = UDim.new(1, 0)
        valNodeCorner.Parent = valNode

        local currentH, currentS, currentV = color:ToHSV()

        local function updateGradients()
            satGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(currentH, 1, 1))
            })
            valGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(currentH, currentS, 1))
            })
        end

        local function updateColor()
            color = Color3.fromHSV(currentH, currentS, currentV)
            swatch.BackgroundColor3 = color
            updateGradients()
            if config.Callback then pcall(config.Callback, color) end
        end

        local function dragHue(inputX)
            local ratio = math.clamp((inputX - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
            hueNode.Position = UDim2.new(ratio, -3, 0.5, -9)
            currentH = ratio
            updateColor()
        end

        local function dragSat(inputX)
            local ratio = math.clamp((inputX - satSlider.AbsolutePosition.X) / satSlider.AbsoluteSize.X, 0, 1)
            satNode.Position = UDim2.new(ratio, -3, 0.5, -9)
            currentS = ratio
            updateColor()
        end

        local function dragVal(inputX)
            local ratio = math.clamp((inputX - valSlider.AbsolutePosition.X) / valSlider.AbsoluteSize.X, 0, 1)
            valNode.Position = UDim2.new(ratio, -3, 0.5, -9)
            currentV = ratio
            updateColor()
        end

        SetupUnifiedDrag(hueSlider, function(pos) dragHue(pos.X) end, function(pos) dragHue(pos.X) end)
        SetupUnifiedDrag(hueNode, function(pos) dragHue(pos.X) end, function(pos) dragHue(pos.X) end)

        SetupUnifiedDrag(satSlider, function(pos) dragSat(pos.X) end, function(pos) dragSat(pos.X) end)
        SetupUnifiedDrag(satNode, function(pos) dragSat(pos.X) end, function(pos) dragSat(pos.X) end)

        SetupUnifiedDrag(valSlider, function(pos) dragVal(pos.X) end, function(pos) dragVal(pos.X) end)
        SetupUnifiedDrag(valNode, function(pos) dragVal(pos.X) end, function(pos) dragVal(pos.X) end)

        swatch.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                currentH, currentS, currentV = color:ToHSV()
                hueNode.Position = UDim2.new(currentH, -3, 0.5, -9)
                satNode.Position = UDim2.new(currentS, -3, 0.5, -9)
                valNode.Position = UDim2.new(currentV, -3, 0.5, -9)
                updateGradients()
                
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 130) }, 0.25, Enum.EasingStyle.Quint)
                SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 94) }, 0.25, Enum.EasingStyle.Quint)
            else
                SmoothTween(container, { Size = UDim2.new(1, 0, 0, 36) }, 0.2)
                SmoothTween(tray, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
            end
        end)

        container.Parent = page
        return {
            Get = function() return color end,
            Set = function(_, col)
                color = col
                swatch.BackgroundColor3 = col
                currentH, currentS, currentV = col:ToHSV()
                hueNode.Position = UDim2.new(currentH, -3, 0.5, -9)
                satNode.Position = UDim2.new(currentS, -3, 0.5, -9)
                valNode.Position = UDim2.new(currentV, -3, 0.5, -9)
                updateGradients()
                if config.Callback then pcall(config.Callback, col) end
            end
        }
    end

    return Tab
end

function Window:_SwitchTab(tabData)
    if self.ActiveTab then
        self.ActiveTab._page.Visible = false
        SmoothTween(self.ActiveTab._btn, { BackgroundTransparency = 1 }, 0.2)
        SmoothTween(self.ActiveTab._label, { TextColor3 = Theme.TextMuted }, 0.2)
        if self.ActiveTab._icon then SmoothTween(self.ActiveTab._icon, { ImageColor3 = Theme.TextMuted }, 0.2) end
    end
    self.ActiveTab = tabData
    tabData._page.Visible = true
    SmoothTween(tabData._btn, { BackgroundTransparency = 0.88 }, 0.2)
    SmoothTween(tabData._label, { TextColor3 = Theme.TextPrimary }, 0.2)
    if tabData._icon then SmoothTween(tabData._icon, { ImageColor3 = Theme.TextPrimary }, 0.2) end
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

    -- Notification badge icon
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

    SmoothTween(card, { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 0.08 }, 0.4, Enum.EasingStyle.Back)
    SmoothTween(cardStroke, { Transparency = 0.8 }, 0.4)
    SmoothTween(icon, { BackgroundTransparency = 0 }, 0.4)
    SmoothTween(iconLabel, { TextTransparency = 0 }, 0.4)
    SmoothTween(titleLabel, { TextTransparency = 0 }, 0.4)
    SmoothTween(msgLabel, { TextTransparency = 0 }, 0.4)
    SmoothTween(timeLabel, { TextTransparency = 0 }, 0.4)

    task.delay(duration, function()
        SmoothTween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.3)
        SmoothTween(cardStroke, { Transparency = 1 }, 0.3)
        SmoothTween(icon, { BackgroundTransparency = 1 }, 0.3)
        SmoothTween(iconLabel, { TextTransparency = 1 }, 0.3)
        SmoothTween(titleLabel, { TextTransparency = 1 }, 0.3)
        SmoothTween(msgLabel, { TextTransparency = 1 }, 0.3)
        SmoothTween(timeLabel, { TextTransparency = 1 }, 0.3)
        task.delay(0.3, function() card:Destroy() end)
    end)
end

function LiquidGlass:SetAccent(color)
    Theme.Accent = color
    Theme.AccentGlow = color
end

return LiquidGlass
