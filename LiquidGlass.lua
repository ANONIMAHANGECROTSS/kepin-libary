-- ================================================================
--  LiquidGlass UI Library v2.0
--  JAROT404 × KVNXY Team
--  Premium Roblox GUI Framework — Liquid Glass Design Language
-- ================================================================

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

-- ── SERVICES ────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

-- ── CONSTANTS ───────────────────────────────────────────────────
local TWEEN_FAST     = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_MED      = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SLOW     = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SPRING   = TweenInfo.new(0.5,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out, 0, false, 0)

-- ── THEME ───────────────────────────────────────────────────────
local Theme = {
    -- Base surfaces
    BG_DEEP      = Color3.fromRGB(6,   6,   10),
    BG_BASE      = Color3.fromRGB(10,  10,  16),
    BG_PANEL     = Color3.fromRGB(14,  14,  22),
    BG_CARD      = Color3.fromRGB(18,  18,  28),
    BG_ELEVATED  = Color3.fromRGB(24,  24,  36),
    BG_HOVER     = Color3.fromRGB(30,  30,  46),

    -- Glass layers
    GLASS_1      = Color3.fromRGB(255, 255, 255),  -- alpha: 0.03
    GLASS_2      = Color3.fromRGB(255, 255, 255),  -- alpha: 0.06
    GLASS_BORDER = Color3.fromRGB(255, 255, 255),  -- alpha: 0.08

    -- Accent (default blue-violet, overridable via SetAccent)
    ACCENT       = Color3.fromRGB(99,  102, 241),
    ACCENT_GLOW  = Color3.fromRGB(139, 92,  246),
    ACCENT_SOFT  = Color3.fromRGB(30,  27,  75),

    -- Semantic colors
    SUCCESS      = Color3.fromRGB(34,  197, 94),
    WARNING      = Color3.fromRGB(251, 191, 36),
    ERROR        = Color3.fromRGB(239, 68,  68),
    INFO         = Color3.fromRGB(99,  102, 241),

    -- Text hierarchy
    TEXT_PRIMARY   = Color3.fromRGB(240, 240, 255),
    TEXT_SECONDARY = Color3.fromRGB(148, 148, 180),
    TEXT_MUTED     = Color3.fromRGB(80,  80,  110),
    TEXT_ACCENT    = Color3.fromRGB(139, 139, 255),

    -- Stroke & separator
    STROKE       = Color3.fromRGB(40,  40,  60),
    STROKE_LIGHT = Color3.fromRGB(60,  60,  90),
    SEPARATOR    = Color3.fromRGB(255, 255, 255),  -- alpha: 0.05

    -- Font
    FONT_UI      = Enum.Font.GothamBold,
    FONT_BODY    = Enum.Font.Gotham,
    FONT_MONO    = Enum.Font.Code,
}

LiquidGlass.Theme = Theme

-- ── INTERNAL HELPERS ────────────────────────────────────────────

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

local function Tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function MakeShadow(parent, radius, transparency)
    -- Simulated drop shadow via nested frames
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 6),
        Size = UDim2.new(1, radius * 2, 1, radius * 2),
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = parent.ZIndex - 1,
        Parent = parent.Parent
    })
    return shadow
end

local function RippleEffect(button, x, y)
    local ripple = Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = false,
        ZIndex = button.ZIndex + 10,
        Parent = button
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ripple})

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    Tween(ripple, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    game:GetService("Debris"):AddItem(ripple, 0.6)
end

local function GlowPulse(frame, color, peakAlpha)
    -- Subtle breathing glow on accent frames
    local function pulse()
        Tween(frame, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = color, ImageTransparency = peakAlpha + 0.15}):wait()
        Tween(frame, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageColor3 = color, ImageTransparency = peakAlpha}):wait()
        pulse()
    end
    coroutine.wrap(pulse)()
end

-- ── NOTIFICATION SYSTEM ─────────────────────────────────────────

local NotifContainer = nil
local NotifQueue = {}

local function GetNotifContainer()
    if NotifContainer and NotifContainer.Parent then return NotifContainer end
    -- Try to use existing ScreenGui or create one
    local existing = CoreGui:FindFirstChild("LG_Notifications")
    if existing then NotifContainer = existing:FindFirstChild("Container") return NotifContainer end

    local screenGui = Create("ScreenGui", {
        Name = "LG_Notifications",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
        Parent = CoreGui
    })
    NotifContainer = Create("Frame", {
        Name = "Container",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 0, 52),
        Size = UDim2.new(0, 320, 1, -68),
        ClipsDescendants = false,
        Parent = screenGui
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = NotifContainer
    })
    return NotifContainer
end

local NOTIF_ICONS = {
    success = "rbxassetid://10734891048",
    warning = "rbxassetid://10734902866",
    error   = "rbxassetid://10734892742",
    info    = "rbxassetid://10734912354",
}
local NOTIF_COLORS = {
    success = Theme.SUCCESS,
    warning = Theme.WARNING,
    error   = Theme.ERROR,
    info    = Theme.INFO,
}

function LiquidGlass.Notify(opts)
    opts = opts or {}
    local title    = opts.Title    or "Notification"
    local message  = opts.Message  or ""
    local nType    = (opts.Type    or "info"):lower()
    local duration = opts.Duration or 4

    local container = GetNotifContainer()
    local accentColor = NOTIF_COLORS[nType] or Theme.INFO

    -- Card
    local card = Create("Frame", {
        Name = "Notif_" .. nType,
        BackgroundColor3 = Color3.fromRGB(18, 18, 28),
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 72),
        ClipsDescendants = true,
        Parent = container
    })
    Create("UICorner",  {CornerRadius = UDim.new(0, 14), Parent = card})
    Create("UIStroke",  {Color = accentColor, Transparency = 0.7, Thickness = 1, Parent = card})

    -- Accent left bar
    local leftBar = Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 10, 0, 8),
        Parent = card
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = leftBar})

    -- Icon
    local icon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Image = NOTIF_ICONS[nType] or NOTIF_ICONS.info,
        ImageColor3 = accentColor,
        Parent = card
    })

    -- Title
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 54, 0, 12),
        Size = UDim2.new(1, -64, 0, 20),
        Font = Theme.FONT_UI,
        Text = title,
        TextColor3 = Theme.TEXT_PRIMARY,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    -- Message
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 54, 0, 34),
        Size = UDim2.new(1, -64, 0, 28),
        Font = Theme.FONT_BODY,
        Text = message,
        TextColor3 = Theme.TEXT_SECONDARY,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = card
    })

    -- Progress bar
    local progressBG = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 30, 46),
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        Parent = card
    })
    local progressFill = Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = progressBG
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressBG})
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressFill})

    -- Slide-in from right
    card.Position = UDim2.new(1, 20, 0, 0)
    Tween(card, TWEEN_SPRING, {Position = UDim2.new(0, 0, 0, 0)})

    -- Progress drain
    Tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})

    -- Hover to pause / unpause
    local paused = false
    local elapsed = 0
    card.MouseEnter:Connect(function() paused = true end)
    card.MouseLeave:Connect(function() paused = false end)

    -- Auto dismiss
    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, TWEEN_MED, {Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1})
            task.delay(0.3, function() if card then card:Destroy() end end)
        end
    end)

    -- Click to dismiss
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(card, TWEEN_FAST, {Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1})
            task.delay(0.2, function() if card then card:Destroy() end end)
        end
    end)

    return card
end

-- ── WINDOW ──────────────────────────────────────────────────────

function LiquidGlass:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "LiquidGlass"
    local subtitle = opts.Subtitle or ""
    local winW     = opts.Width    or 640
    local winH     = opts.Height   or 480
    local minW     = opts.MinWidth or 400

    -- Root ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "LiquidGlass_" .. title:gsub("%s",""),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })

    -- Backdrop blur simulation (dark overlay + noise)
    local backdrop = Create("Frame", {
        Name = "Backdrop",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Visible = false,   -- only shown on dropdowns / modals
        Parent = screenGui
    })

    -- Main window frame
    local win = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.BG_BASE,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, winW, 0, winH),
        ClipsDescendants = false,
        ZIndex = 2,
        Parent = screenGui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 20), Parent = win})
    Create("UIStroke", {
        Color = Theme.GLASS_BORDER,
        Transparency = 0.82,
        Thickness = 1,
        Parent = win
    })

    -- Window open animation
    win.Size = UDim2.new(0, winW * 0.88, 0, winH * 0.88)
    win.BackgroundTransparency = 1
    Tween(win, TWEEN_SPRING, {Size = UDim2.new(0, winW, 0, winH), BackgroundTransparency = 0})

    -- Subtle top gradient (glass shimmer)
    local shimmer = Create("Frame", {
        Name = "Shimmer",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.94,
        Size = UDim2.new(1, 0, 0, 60),
        ZIndex = 3,
        Parent = win
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 20), Parent = shimmer})
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80,80,120))
        }),
        Rotation = 90,
        Parent = shimmer
    })

    -- ── TITLE BAR ──
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme.BG_PANEL,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 4,
        Parent = win
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 20), Parent = titleBar})
    -- Flatten bottom corners of titleBar
    Create("Frame", {
        BackgroundColor3 = Theme.BG_PANEL,
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        ZIndex = 3,
        Parent = titleBar
    })

    -- Logo / accent dot
    local logoDot = Create("Frame", {
        Name = "LogoDot",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.ACCENT,
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.new(0, 8, 0, 8),
        ZIndex = 5,
        Parent = titleBar
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = logoDot})

    -- Title text
    Create("TextLabel", {
        Name = "Title",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0.5, -7),
        Size = UDim2.new(0.5, 0, 0, 20),
        Font = Theme.FONT_UI,
        Text = title,
        TextColor3 = Theme.TEXT_PRIMARY,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = titleBar
    })

    -- Subtitle
    Create("TextLabel", {
        Name = "Subtitle",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0.5, 8),
        Size = UDim2.new(0.5, 0, 0, 14),
        Font = Theme.FONT_BODY,
        Text = subtitle,
        TextColor3 = Theme.TEXT_MUTED,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = titleBar
    })

    -- Close button
    local closeBtn = Create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(239, 68, 68),
        BackgroundTransparency = 0.3,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Text = "×",
        Font = Theme.FONT_UI,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        ZIndex = 5,
        Parent = titleBar
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = closeBtn})
    closeBtn.MouseButton1Click:Connect(function()
        Tween(win, TWEEN_MED, {Size = UDim2.new(0, winW * 0.88, 0, winH * 0.88), BackgroundTransparency = 1})
        task.delay(0.32, function() screenGui:Destroy() end)
    end)

    -- Minimize button
    local minBtn = Create("TextButton", {
        Name = "Minimize",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(251, 191, 36),
        BackgroundTransparency = 0.3,
        Position = UDim2.new(1, -40, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Text = "−",
        Font = Theme.FONT_UI,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        ZIndex = 5,
        Parent = titleBar
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = minBtn})

    local minimized = false
    local contentRef = nil  -- set later
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(win, TWEEN_MED, {Size = UDim2.new(0, winW, 0, 52)})
        else
            Tween(win, TWEEN_MED, {Size = UDim2.new(0, winW, 0, winH)})
        end
    end)

    -- ── DRAG ──
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── TAB BAR ──
    local tabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.BG_DEEP,
        BackgroundTransparency = 0,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 4,
        Parent = win
    })
    Create("Frame", {
        BackgroundColor3 = Theme.STROKE,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 5,
        Parent = tabBar
    })
    local tabList = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        ZIndex = 4,
        Parent = tabBar
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList
    })

    -- Tab indicator line (sliding underline)
    local tabIndicator = Create("Frame", {
        Name = "TabIndicator",
        BackgroundColor3 = Theme.ACCENT,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(0, 60, 0, 2),
        ZIndex = 6,
        Parent = tabBar
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = tabIndicator})

    -- ── CONTENT AREA ──
    local contentArea = Create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 96),
        Size = UDim2.new(1, 0, 1, -96),
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = win
    })
    contentRef = contentArea

    -- ── WINDOW OBJECT ──
    local WindowObj  = {}
    local Tabs       = {}
    local ActiveTab  = nil
    local TabButtons = {}

    function WindowObj:SetAccent(color)
        Theme.ACCENT = color
        tabIndicator.BackgroundColor3 = color
        logoDot.BackgroundColor3 = color
    end

    function WindowObj:AddTab(name, icon)
        local tabContent = Create("ScrollingFrame", {
            Name = "Tab_" .. name,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.ACCENT,
            ScrollBarImageTransparency = 0.5,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 3,
            Parent = contentArea
        })
        Create("UIPadding", {
            PaddingTop    = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 16),
            PaddingLeft   = UDim.new(0, 14),
            PaddingRight  = UDim.new(0, 14),
            Parent = tabContent
        })
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = tabContent
        })

        -- Tab button
        local tabBtn = Create("TextButton", {
            Name = "TabBtn_" .. name,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, -10),
            Text = "",
            ZIndex = 5,
            Parent = tabList
        })

        -- Tab button inner layout
        local btnInner = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5,
            Parent = tabBtn
        })
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = btnInner
        })
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = tabBtn
        })

        if icon and icon ~= "" then
            Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 16, 0, 16),
                Image = icon,
                ImageColor3 = Theme.TEXT_MUTED,
                ZIndex = 5,
                Parent = btnInner
            })
        end

        local btnLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            Font = Theme.FONT_UI,
            Text = name,
            TextColor3 = Theme.TEXT_MUTED,
            TextSize = 12,
            ZIndex = 5,
            Parent = btnInner
        })

        table.insert(Tabs, tabContent)
        table.insert(TabButtons, {btn = tabBtn, label = btnLabel, icon = btnInner:FindFirstChildOfClass("ImageLabel")})

        local function Activate()
            -- Hide all tabs
            for _, t in ipairs(Tabs) do
                Tween(t, TWEEN_FAST, {})
                t.Visible = false
            end
            -- Dim all tab buttons
            for _, tb in ipairs(TabButtons) do
                Tween(tb.label, TWEEN_FAST, {TextColor3 = Theme.TEXT_MUTED})
                if tb.icon then Tween(tb.icon, TWEEN_FAST, {ImageColor3 = Theme.TEXT_MUTED}) end
            end

            -- Show this tab
            tabContent.Visible = true

            -- Animate indicator
            local btnAbsX = tabBtn.AbsolutePosition.X - tabBar.AbsolutePosition.X
            local btnAbsW = tabBtn.AbsoluteSize.X
            Tween(tabIndicator, TWEEN_MED, {
                Position = UDim2.new(0, btnAbsX + 12, 1, -2),
                Size = UDim2.new(0, btnAbsW - 24, 0, 2)
            })

            -- Highlight active
            Tween(btnLabel, TWEEN_FAST, {TextColor3 = Theme.TEXT_PRIMARY})
            local activeIcon = btnInner:FindFirstChildOfClass("ImageLabel")
            if activeIcon then Tween(activeIcon, TWEEN_FAST, {ImageColor3 = Theme.ACCENT}) end

            ActiveTab = tabContent
        end

        tabBtn.MouseButton1Click:Connect(function()
            Activate()
        end)

        -- Activate first tab
        if #Tabs == 1 then
            task.defer(Activate)
        end

        -- ── TAB OBJECT ──
        local TabObj = {}

        function TabObj:AddGroup(groupTitle, groupIcon)
            local groupCard = Create("Frame", {
                Name = "Group_" .. groupTitle:gsub("%s",""),
                BackgroundColor3 = Theme.BG_CARD,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
                ZIndex = 4,
                Parent = tabContent
            })
            Create("UICorner",  {CornerRadius = UDim.new(0, 14), Parent = groupCard})
            Create("UIStroke",  {Color = Theme.STROKE, Transparency = 0.4, Thickness = 1, Parent = groupCard})
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 44),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft   = UDim.new(0, 12),
                PaddingRight  = UDim.new(0, 12),
                Parent = groupCard
            })
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = groupCard
            })

            -- Group header
            local header = Create("Frame", {
                Name = "Header",
                BackgroundColor3 = Theme.BG_ELEVATED,
                Size = UDim2.new(1, 0, 0, 36),
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 5,
                Parent = groupCard
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = header})
            -- Only round top two corners (clip bottom)
            Create("Frame", {
                BackgroundColor3 = Theme.BG_ELEVATED,
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 1, -14),
                ZIndex = 4,
                Parent = header
            })

            if groupIcon and groupIcon ~= "" then
                Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 12, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16),
                    Image = groupIcon,
                    ImageColor3 = Theme.ACCENT,
                    ZIndex = 6,
                    Parent = header
                })
            end

            local headerOffset = (groupIcon and groupIcon ~= "") and 36 or 14
            Create("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, headerOffset, 0.5, 0),
                Size = UDim2.new(1, -headerOffset - 10, 1, 0),
                Font = Theme.FONT_UI,
                Text = groupTitle,
                TextColor3 = Theme.TEXT_PRIMARY,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
                Parent = header
            })

            -- ── GROUP OBJECT ──
            local GroupObj = {}

            -- ── BUTTON ──
            function GroupObj:AddButton(opts)
                opts = opts or {}
                local btn = Create("TextButton", {
                    Name = "Btn_" .. (opts.Text or "Button"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 36),
                    Text = "",
                    AutoButtonColor = false,
                    ClipsDescendants = true,
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = btn})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(1, -28, 1, 0),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Button",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = btn
                })

                -- Arrow icon
                Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16),
                    Font = Theme.FONT_UI,
                    Text = "›",
                    TextColor3 = Theme.TEXT_MUTED,
                    TextSize = 18,
                    ZIndex = 7,
                    Parent = btn
                })

                btn.MouseEnter:Connect(function()
                    Tween(btn, TWEEN_FAST, {BackgroundColor3 = Theme.BG_HOVER})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, TWEEN_FAST, {BackgroundColor3 = Theme.BG_ELEVATED})
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(btn, TWEEN_FAST, {BackgroundColor3 = Theme.ACCENT_SOFT})
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn, TWEEN_FAST, {BackgroundColor3 = Theme.BG_HOVER})
                end)
                btn.MouseButton1Click:Connect(function(x, y)
                    RippleEffect(btn, Mouse.X, Mouse.Y)
                    if opts.Callback then
                        task.spawn(opts.Callback)
                    end
                end)

                return btn
            end

            -- ── TOGGLE ──
            function GroupObj:AddToggle(opts)
                opts = opts or {}
                local state = opts.Default or false

                local row = Create("Frame", {
                    Name = "Toggle_" .. (opts.Text or "Toggle"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 36),
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = row})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = row})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(1, -72, 1, 0),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Toggle",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = row
                })

                -- Toggle track
                local track = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = state and Theme.ACCENT or Color3.fromRGB(50, 50, 70),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.new(0, 40, 0, 22),
                    ZIndex = 7,
                    Parent = row
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = track})

                -- Toggle knob
                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = state and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
                    Size = UDim2.new(0, 16, 0, 16),
                    ZIndex = 8,
                    Parent = track
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

                local function SetState(newState, silent)
                    state = newState
                    Tween(track, TWEEN_MED, {BackgroundColor3 = state and Theme.ACCENT or Color3.fromRGB(50, 50, 70)})
                    Tween(knob, TWEEN_MED, {Position = state and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)})
                    if not silent and opts.Callback then
                        task.spawn(opts.Callback, state)
                    end
                end

                local clickArea = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    ZIndex = 9,
                    Parent = row
                })
                clickArea.MouseButton1Click:Connect(function()
                    SetState(not state)
                end)

                -- Return controller
                return {
                    SetState = SetState,
                    GetState = function() return state end
                }
            end

            -- ── SLIDER ──
            function GroupObj:AddSlider(opts)
                opts = opts or {}
                local minVal  = opts.Min    or 0
                local maxVal  = opts.Max    or 100
                local curVal  = opts.Value  or minVal
                local suffix  = opts.Suffix or ""

                local container = Create("Frame", {
                    Name = "Slider_" .. (opts.Text or "Slider"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 54),
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = container})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 8),
                    Size = UDim2.new(0.7, 0, 0, 16),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Slider",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = container
                })

                local valLabel = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -14, 0, 8),
                    Size = UDim2.new(0.3, 0, 0, 16),
                    Font = Theme.FONT_MONO,
                    Text = tostring(curVal) .. suffix,
                    TextColor3 = Theme.ACCENT,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 7,
                    Parent = container
                })

                -- Track
                local track = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(35, 35, 55),
                    Position = UDim2.new(0.5, 0, 0, 34),
                    Size = UDim2.new(1, -28, 0, 4),
                    ZIndex = 7,
                    Parent = container
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = track})

                local pct = (curVal - minVal) / (maxVal - minVal)

                local fill = Create("Frame", {
                    BackgroundColor3 = Theme.ACCENT,
                    Size = UDim2.new(pct, 0, 1, 0),
                    ZIndex = 8,
                    Parent = track
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})

                local thumb = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = UDim2.new(pct, 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    ZIndex = 9,
                    Parent = track
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = thumb})

                local draggingSlider = false

                local function UpdateSlider(inputX)
                    local relX  = math.clamp(inputX - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
                    local newPct = relX / track.AbsoluteSize.X
                    local newVal = math.floor(minVal + (maxVal - minVal) * newPct + 0.5)
                    newPct = (newVal - minVal) / (maxVal - minVal)

                    curVal = newVal
                    fill.Size  = UDim2.new(newPct, 0, 1, 0)
                    thumb.Position = UDim2.new(newPct, 0, 0.5, 0)
                    valLabel.Text = tostring(newVal) .. suffix

                    if opts.Callback then task.spawn(opts.Callback, newVal) end
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = true
                        UpdateSlider(input.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingSlider = false
                    end
                end)

                return {
                    SetValue = function(_, v)
                        curVal = math.clamp(v, minVal, maxVal)
                        local p = (curVal - minVal) / (maxVal - minVal)
                        fill.Size = UDim2.new(p, 0, 1, 0)
                        thumb.Position = UDim2.new(p, 0, 0.5, 0)
                        valLabel.Text = tostring(curVal) .. suffix
                    end
                }
            end

            -- ── INPUT ──
            function GroupObj:AddInput(opts)
                opts = opts or {}

                local container = Create("Frame", {
                    Name = "Input_" .. (opts.Text or "Input"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 54),
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = container})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 8),
                    Size = UDim2.new(1, -28, 0, 16),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Input",
                    TextColor3 = Theme.TEXT_SECONDARY,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = container
                })

                local inputBox = Create("TextBox", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 1, -8),
                    Size = UDim2.new(1, -28, 0, 20),
                    Font = Theme.FONT_UI,
                    PlaceholderText = opts.Placeholder or "Type here...",
                    PlaceholderColor3 = Theme.TEXT_MUTED,
                    Text = opts.Default or "",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    ClearTextOnFocus = false,
                    Parent = container
                })

                local stroke = Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})
                inputBox.Focused:Connect(function()
                    Tween(stroke, TWEEN_FAST, {Color = Theme.ACCENT, Transparency = 0.3})
                end)
                inputBox.FocusLost:Connect(function()
                    Tween(stroke, TWEEN_FAST, {Color = Theme.STROKE_LIGHT, Transparency = 0.7})
                    if opts.Callback then task.spawn(opts.Callback, inputBox.Text) end
                end)

                return inputBox
            end

            -- ── DROPDOWN ── (FULLY FIXED — no clipping, proper scroll, search)
            function GroupObj:AddDropdown(opts)
                opts = opts or {}
                local options  = opts.Options  or {}
                local selected = opts.Default  or (options[1] or "")
                local isOpen   = false

                local container = Create("Frame", {
                    Name = "Dropdown_" .. (opts.Text or "Dropdown"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 36),
                    ZIndex = 6,
                    ClipsDescendants = false,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = container})
                local ddStroke = Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})

                -- Display row
                local displayRow = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 36),
                    ZIndex = 7,
                    Parent = container
                })

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Dropdown",
                    TextColor3 = Theme.TEXT_SECONDARY,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = displayRow
                })

                local selectedLabel = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -30, 0.5, 0),
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Font = Theme.FONT_UI,
                    Text = selected,
                    TextColor3 = Theme.ACCENT,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 7,
                    Parent = displayRow
                })

                -- Chevron
                local chevron = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18),
                    Font = Theme.FONT_UI,
                    Text = "⌄",
                    TextColor3 = Theme.TEXT_MUTED,
                    TextSize = 14,
                    ZIndex = 7,
                    Parent = displayRow
                })

                -- ── PANEL (portal-style, parented to screenGui to avoid clipping) ──
                local MAX_VISIBLE  = 5
                local ITEM_H       = 32
                local SEARCH_H     = 34
                local PANEL_PADDING = 8
                local showSearch   = #options > 5
                local panelH       = SEARCH_H * (showSearch and 1 or 0) + math.min(#options, MAX_VISIBLE) * ITEM_H + PANEL_PADDING * 2

                local panel = Create("Frame", {
                    Name = "DropdownPanel",
                    BackgroundColor3 = Theme.BG_PANEL,
                    Size = UDim2.new(0, 0, 0, 0),  -- start collapsed
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 100,
                    Parent = screenGui  -- ← parented to screenGui, NOT groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = panel})
                Create("UIStroke", {Color = Theme.ACCENT, Transparency = 0.6, Thickness = 1, Parent = panel})

                -- Shadow behind panel
                Create("ImageLabel", {
                    Name = "PanelShadow",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0.5, 8),
                    Size = UDim2.new(1, 30, 1, 30),
                    Image = "rbxassetid://6014261993",
                    ImageColor3 = Color3.fromRGB(0, 0, 0),
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Slice,
                    SliceCenter = Rect.new(49, 49, 450, 450),
                    ZIndex = 99,
                    Parent = panel
                })

                -- Search bar (only if > 5 options)
                local searchBox = nil
                local filteredOptions = {}
                for _, v in ipairs(options) do table.insert(filteredOptions, v) end

                if showSearch then
                    local searchFrame = Create("Frame", {
                        BackgroundColor3 = Theme.BG_ELEVATED,
                        Position = UDim2.new(0, PANEL_PADDING, 0, PANEL_PADDING),
                        Size = UDim2.new(1, -PANEL_PADDING * 2, 0, SEARCH_H - 4),
                        ZIndex = 102,
                        Parent = panel
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = searchFrame})
                    Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.5, Thickness = 1, Parent = searchFrame})

                    -- Search icon
                    Create("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 8, 0.5, 0),
                        Size = UDim2.new(0, 16, 0, 16),
                        Font = Theme.FONT_UI,
                        Text = "⌕",
                        TextColor3 = Theme.TEXT_MUTED,
                        TextSize = 14,
                        ZIndex = 103,
                        Parent = searchFrame
                    })

                    searchBox = Create("TextBox", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 26, 0, 0),
                        Size = UDim2.new(1, -32, 1, 0),
                        Font = Theme.FONT_BODY,
                        PlaceholderText = "Search...",
                        PlaceholderColor3 = Theme.TEXT_MUTED,
                        Text = "",
                        TextColor3 = Theme.TEXT_PRIMARY,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = false,
                        ZIndex = 103,
                        Parent = searchFrame
                    })
                end

                -- Scrolling list
                local listScrollOffset = showSearch and (SEARCH_H + PANEL_PADDING) or PANEL_PADDING
                local listFrame = Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, listScrollOffset),
                    Size = UDim2.new(1, 0, 1, -listScrollOffset),
                    CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H),
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme.ACCENT,
                    ScrollBarImageTransparency = 0.4,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ZIndex = 101,
                    Parent = panel
                })
                Create("UIPadding", {
                    PaddingLeft = UDim.new(0, PANEL_PADDING),
                    PaddingRight = UDim.new(0, PANEL_PADDING),
                    Parent = listFrame
                })
                Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                    Parent = listFrame
                })

                local optionButtons = {}

                local function BuildList(filter)
                    -- Clear existing
                    for _, b in ipairs(optionButtons) do b:Destroy() end
                    optionButtons = {}

                    local shown = 0
                    for _, opt in ipairs(options) do
                        if filter == nil or filter == "" or opt:lower():find(filter:lower(), 1, true) then
                            local isSelected = (opt == selected)
                            local item = Create("TextButton", {
                                BackgroundColor3 = isSelected and Theme.ACCENT_SOFT or Color3.fromRGB(0,0,0),
                                BackgroundTransparency = isSelected and 0 or 1,
                                Size = UDim2.new(1, 0, 0, ITEM_H - 2),
                                Text = "",
                                AutoButtonColor = false,
                                ClipsDescendants = false,
                                ZIndex = 102,
                                Parent = listFrame
                            })
                            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = item})

                            Create("TextLabel", {
                                AnchorPoint = Vector2.new(0, 0.5),
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 10, 0.5, 0),
                                Size = UDim2.new(1, -30, 1, 0),
                                Font = isSelected and Theme.FONT_UI or Theme.FONT_BODY,
                                Text = opt,
                                TextColor3 = isSelected and Theme.ACCENT or Theme.TEXT_PRIMARY,
                                TextSize = 12,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 103,
                                Parent = item
                            })

                            if isSelected then
                                Create("TextLabel", {
                                    AnchorPoint = Vector2.new(1, 0.5),
                                    BackgroundTransparency = 1,
                                    Position = UDim2.new(1, -8, 0.5, 0),
                                    Size = UDim2.new(0, 14, 0, 14),
                                    Font = Theme.FONT_UI,
                                    Text = "✓",
                                    TextColor3 = Theme.ACCENT,
                                    TextSize = 11,
                                    ZIndex = 103,
                                    Parent = item
                                })
                            end

                            item.MouseEnter:Connect(function()
                                if opt ~= selected then
                                    Tween(item, TWEEN_FAST, {BackgroundTransparency = 0.7, BackgroundColor3 = Theme.BG_HOVER})
                                end
                            end)
                            item.MouseLeave:Connect(function()
                                if opt ~= selected then
                                    Tween(item, TWEEN_FAST, {BackgroundTransparency = 1})
                                end
                            end)
                            item.MouseButton1Click:Connect(function()
                                selected = opt
                                selectedLabel.Text = opt
                                if opts.Callback then task.spawn(opts.Callback, opt) end
                                -- Close
                                Tween(panel, TWEEN_MED, {Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, 0)})
                                Tween(chevron, TWEEN_MED, {Rotation = 0})
                                task.delay(0.3, function() panel.Visible = false end)
                                isOpen = false
                                -- Rebuild with new selection
                                task.defer(function() BuildList(searchBox and searchBox.Text or "") end)
                            end)

                            table.insert(optionButtons, item)
                            shown += 1
                        end
                    end
                    listFrame.CanvasSize = UDim2.new(0, 0, 0, shown * ITEM_H)
                end

                BuildList()

                if searchBox then
                    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        BuildList(searchBox.Text)
                    end)
                end

                -- Position panel relative to container on screen
                local function PositionPanel()
                    local absPos  = container.AbsolutePosition
                    local absSize = container.AbsoluteSize
                    local screenH = screenGui.AbsoluteSize.Y
                    local targetW = absSize.X

                    -- Determine if panel goes below or above
                    local spaceBelow = screenH - (absPos.Y + absSize.Y)
                    local spaceAbove = absPos.Y
                    local goAbove = spaceBelow < panelH and spaceAbove > spaceBelow

                    local panelY = goAbove and (absPos.Y - panelH - 4) or (absPos.Y + absSize.Y + 4)

                    panel.Position = UDim2.new(0, absPos.X, 0, panelY)
                    panel.Size     = UDim2.new(0, targetW, 0, 0) -- start at 0 height for animation
                end

                -- Toggle open/close
                local clickLayer = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    ZIndex = 8,
                    Parent = container
                })

                clickLayer.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        PositionPanel()
                        panel.Visible = true
                        if searchBox then searchBox.Text = "" BuildList() end
                        Tween(panel, TWEEN_MED, {Size = UDim2.new(0, container.AbsoluteSize.X, 0, panelH)})
                        Tween(chevron, TWEEN_MED, {Rotation = 180})
                        Tween(ddStroke, TWEEN_FAST, {Color = Theme.ACCENT, Transparency = 0.4})
                    else
                        Tween(panel, TWEEN_MED, {Size = UDim2.new(0, container.AbsoluteSize.X, 0, 0)})
                        Tween(chevron, TWEEN_MED, {Rotation = 0})
                        Tween(ddStroke, TWEEN_FAST, {Color = Theme.STROKE_LIGHT, Transparency = 0.7})
                        task.delay(0.3, function() panel.Visible = false end)
                    end
                end)

                -- Close when clicking elsewhere
                UserInputService.InputBegan:Connect(function(input)
                    if isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        local mx, my = input.Position.X, input.Position.Y
                        local px, py = panel.AbsolutePosition.X, panel.AbsolutePosition.Y
                        local pw, ph = panel.AbsoluteSize.X, panel.AbsoluteSize.Y
                        local cx, cy = container.AbsolutePosition.X, container.AbsolutePosition.Y
                        local cw, ch = container.AbsoluteSize.X, container.AbsoluteSize.Y

                        local inPanel     = mx >= px and mx <= px+pw and my >= py and my <= py+ph
                        local inContainer = mx >= cx and mx <= cx+cw and my >= cy and my <= cy+ch

                        if not inPanel and not inContainer then
                            isOpen = false
                            Tween(panel, TWEEN_MED, {Size = UDim2.new(0, cw, 0, 0)})
                            Tween(chevron, TWEEN_MED, {Rotation = 0})
                            Tween(ddStroke, TWEEN_FAST, {Color = Theme.STROKE_LIGHT, Transparency = 0.7})
                            task.delay(0.3, function() panel.Visible = false end)
                        end
                    end
                end)

                return {
                    GetSelected = function() return selected end,
                    SetSelected = function(_, v)
                        selected = v
                        selectedLabel.Text = v
                        BuildList()
                    end
                }
            end

            -- ── COLOR PICKER ──
            function GroupObj:AddColorPicker(opts)
                opts = opts or {}
                local curColor = opts.Default or Color3.fromRGB(255, 255, 255)

                local container = Create("Frame", {
                    Name = "ColorPicker_" .. (opts.Text or "Color"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 36),
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = container})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Color",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = container
                })

                local swatch = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = curColor,
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.new(0, 28, 0, 20),
                    ZIndex = 7,
                    Parent = container
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = swatch})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.3, Thickness = 1, Parent = swatch})

                -- Simple color picker popup (hue row)
                local isOpen = false
                local pickerPanel = Create("Frame", {
                    BackgroundColor3 = Theme.BG_PANEL,
                    Size = UDim2.new(0, 200, 0, 0),
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 100,
                    Parent = screenGui
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = pickerPanel})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.4, Thickness = 1, Parent = pickerPanel})

                -- Hue gradient bar
                local hueBar = Create("Frame", {
                    Position = UDim2.new(0, 10, 0, 10),
                    Size = UDim2.new(1, -20, 0, 20),
                    ZIndex = 101,
                    Parent = pickerPanel
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = hueBar})
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,   1, 1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,  1, 1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                        ColorSequenceKeypoint.new(1,   Color3.fromHSV(1,   1, 1)),
                    }),
                    Parent = hueBar
                })

                local hueCursor = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 6, 1, 4),
                    ZIndex = 102,
                    Parent = hueBar
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = hueCursor})

                local draggingHue = false
                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingHue and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relX = math.clamp(input.Position.X - hueBar.AbsolutePosition.X, 0, hueBar.AbsoluteSize.X)
                        local hue  = relX / hueBar.AbsoluteSize.X
                        hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
                        curColor = Color3.fromHSV(hue, 1, 1)
                        swatch.BackgroundColor3 = curColor
                        if opts.Callback then task.spawn(opts.Callback, curColor) end
                    end
                end)

                local clickBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    ZIndex = 8,
                    Parent = container
                })

                clickBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        local absPos  = container.AbsolutePosition
                        local absSize = container.AbsoluteSize
                        pickerPanel.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                        pickerPanel.Visible = true
                        Tween(pickerPanel, TWEEN_MED, {Size = UDim2.new(0, absSize.X, 0, 44)})
                    else
                        Tween(pickerPanel, TWEEN_MED, {Size = UDim2.new(0, container.AbsoluteSize.X, 0, 0)})
                        task.delay(0.3, function() pickerPanel.Visible = false end)
                    end
                end)

                return {
                    GetColor = function() return curColor end,
                    SetColor = function(_, c)
                        curColor = c
                        swatch.BackgroundColor3 = c
                    end
                }
            end

            -- ── KEYBIND ──
            function GroupObj:AddKeybind(opts)
                opts = opts or {}
                local curKey = opts.Default or Enum.KeyCode.Unknown
                local listening = false

                local container = Create("Frame", {
                    Name = "Keybind_" .. (opts.Text or "Keybind"):gsub("%s",""),
                    BackgroundColor3 = Theme.BG_ELEVATED,
                    Size = UDim2.new(1, 0, 0, 36),
                    ZIndex = 6,
                    Parent = groupCard
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = container})
                Create("UIStroke", {Color = Theme.STROKE_LIGHT, Transparency = 0.7, Thickness = 1, Parent = container})

                Create("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "Keybind",
                    TextColor3 = Theme.TEXT_PRIMARY,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                    Parent = container
                })

                local keyBadge = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.BG_DEEP,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 80, 0, 22),
                    Font = Theme.FONT_MONO,
                    Text = curKey.Name,
                    TextColor3 = Theme.ACCENT,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 7,
                    Parent = container
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keyBadge})
                Create("UIStroke", {Color = Theme.ACCENT, Transparency = 0.6, Thickness = 1, Parent = keyBadge})

                keyBadge.MouseButton1Click:Connect(function()
                    listening = true
                    keyBadge.Text = "..."
                    keyBadge.TextColor3 = Theme.WARNING
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        curKey = input.KeyCode
                        keyBadge.Text = curKey.Name
                        keyBadge.TextColor3 = Theme.ACCENT
                        listening = false
                        if opts.Callback then task.spawn(opts.Callback, curKey) end
                    end
                    if input.KeyCode == curKey and not listening then
                        if opts.OnPress then task.spawn(opts.OnPress) end
                    end
                end)

                return {
                    GetKey = function() return curKey end
                }
            end

            -- ── LABEL ──
            function GroupObj:AddLabel(opts)
                opts = opts or {}
                local lbl = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Font = Theme.FONT_BODY,
                    Text = opts.Text or "",
                    TextColor3 = opts.Color or Theme.TEXT_SECONDARY,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                    Parent = groupCard
                })
                return lbl
            end

            -- ── SEPARATOR ──
            function GroupObj:AddSeparator()
                Create("Frame", {
                    BackgroundColor3 = Theme.STROKE,
                    Size = UDim2.new(1, 0, 0, 1),
                    ZIndex = 6,
                    Parent = groupCard
                })
            end

            return GroupObj
        end

        return TabObj
    end

    -- Expose Notify on WindowObj too
    WindowObj.Notify = LiquidGlass.Notify

    function LiquidGlass:SetAccent(color)
        WindowObj:SetAccent(color)
    end

    return WindowObj
end

return LiquidGlass
