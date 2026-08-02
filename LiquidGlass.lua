--[[
╔══════════════════════════════════════════════════════════════╗
║          LIQUID GLASS UI LIBRARY v2.0 — ULTRA EDITION       ║
║          JAROT404 × KVNXY Team                               ║
║          Layout: Landscape · Sidebar · Resizable · Smooth   ║
╚══════════════════════════════════════════════════════════════╝

  LAYOUT:
    ┌─────────────────────────────────────────────────┐
    │  HEADER  (Title · Subtitle · macOS dots · Drag) │
    ├──────────┬──────────────────────────────────────┤
    │          │                                      │
    │ SIDEBAR  │         CONTENT AREA                 │
    │ (tabs)   │  (ScrollingFrame per tab)            │
    │          │                                      │
    │ resize ← │                          resize ↔ ↕ │
    └──────────┴──────────────────────────────────────┘

  FEATURES:
    · Resize width  — drag LEFT edge of window
    · Resize height — drag BOTTOM edge
    · Resize W+H    — drag BOTTOM-RIGHT corner
    · Sidebar width — drag divider between sidebar & content
    · Draggable     — drag header
    · Minimize / Close (macOS dots)
    · Full HSV Color Picker
    · Toggle · Slider · Dropdown · Input · Keybind · Label · Section · Button
    · Notification system (top-right, stacked, progress bar, 4 types)
    · All animations: Quint easing, ripple, spring back, glow pulse

  USAGE:
    local LG = loadstring(game:HttpGet("URL"))()
    local Win = LG:CreateWindow({ Title="My Hub", Width=620, Height=440 })
    local Tab = Win:AddTab("Main", "⚔")
    Tab:AddToggle({ Text="Auto Farm", Callback=function(v) end })
]]

-- ════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UIS              = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LP   = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════
local T = {
    -- Backgrounds
    BG          = Color3.fromRGB(10, 11, 18),
    BG2         = Color3.fromRGB(16, 18, 28),
    BG3         = Color3.fromRGB(22, 25, 38),
    Sidebar     = Color3.fromRGB(13, 14, 22),

    -- Glass
    GlassFill   = Color3.fromRGB(255, 255, 255),
    GlassTr     = 0.93,   -- higher = more transparent
    Border      = Color3.fromRGB(255, 255, 255),
    BorderTr    = 0.82,

    -- Accent
    Accent      = Color3.fromRGB(110, 175, 255),
    AccentDim   = Color3.fromRGB(60, 110, 210),

    -- Text
    TxtHi       = Color3.fromRGB(240, 243, 255),
    TxtMid      = Color3.fromRGB(160, 170, 200),
    TxtLow      = Color3.fromRGB(80, 90, 120),

    -- States
    Ok          = Color3.fromRGB(90, 215, 150),
    Warn        = Color3.fromRGB(255, 185, 60),
    Err         = Color3.fromRGB(255, 80, 90),
    Info        = Color3.fromRGB(110, 175, 255),

    -- Animation
    Spd         = 0.20,
    SpdFast     = 0.12,
    SpdSlow     = 0.35,
    Es          = Enum.EasingStyle.Quint,
    Ed          = Enum.EasingDirection.Out,
}

-- ════════════════════════════════════════════
--  UTILITIES
-- ════════════════════════════════════════════
local U = {}

function U.Tw(obj, props, dur, es, ed)
    local ti = TweenInfo.new(dur or T.Spd, es or T.Es, ed or T.Ed)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play(); return tw
end

function U.Spring(obj, props)
    U.Tw(obj, props, T.Spd, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function U.Corner(parent, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = rad or UDim.new(0, 10)
    c.Parent = parent
    return c
end

function U.Stroke(parent, col, tr, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border
    s.Transparency = tr or T.BorderTr
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function U.Padding(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end

function U.List(parent, dir, pad, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection      = dir or Enum.FillDirection.Vertical
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Padding            = UDim.new(0, pad or 0)
    if ha then l.HorizontalAlignment = ha end
    if va then l.VerticalAlignment   = va end
    l.Parent = parent
    return l
end

function U.Label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font     = props.Font  or Enum.Font.GothamSemibold
    l.Text     = props.Text  or ""
    l.TextColor3 = props.Color or T.TxtHi
    l.TextSize = props.Size  or 13
    l.TextXAlignment = props.Align or Enum.TextXAlignment.Left
    l.TextYAlignment = props.VAlign or Enum.TextYAlignment.Center
    l.Size     = props.Sz    or UDim2.new(1, 0, 1, 0)
    l.Position = props.Pos   or UDim2.new(0, 0, 0, 0)
    l.ZIndex   = props.Z     or 1
    l.RichText = props.Rich  or false
    l.TextTruncate = props.Trunc or Enum.TextTruncate.AtEnd
    l.Parent   = parent
    return l
end

function U.Frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3  = props.Color or T.GlassFill
    f.BackgroundTransparency = props.Tr or 1
    f.BorderSizePixel   = 0
    f.Size              = props.Sz  or UDim2.new(1, 0, 1, 0)
    f.Position          = props.Pos or UDim2.new(0, 0, 0, 0)
    f.ZIndex            = props.Z   or 1
    f.ClipsDescendants  = props.Clip or false
    if props.AnchorPoint then f.AnchorPoint = props.AnchorPoint end
    f.Parent            = parent
    if props.Radius then U.Corner(f, UDim.new(0, props.Radius)) end
    if props.Stroke then U.Stroke(f) end
    return f
end

function U.Btn(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundColor3  = props.Color or T.GlassFill
    b.BackgroundTransparency = props.Tr or 1
    b.BorderSizePixel   = 0
    b.Size              = props.Sz  or UDim2.new(1, 0, 1, 0)
    b.Position          = props.Pos or UDim2.new(0, 0, 0, 0)
    b.ZIndex            = props.Z   or 1
    b.Font              = props.Font or Enum.Font.GothamSemibold
    b.Text              = props.Text or ""
    b.TextColor3        = props.TCol or T.TxtHi
    b.TextSize          = props.TSize or 13
    b.TextXAlignment    = props.Align or Enum.TextXAlignment.Center
    b.ClipsDescendants  = props.Clip or false
    b.AutoButtonColor   = false
    if props.AnchorPoint then b.AnchorPoint = props.AnchorPoint end
    b.Parent            = parent
    if props.Radius then U.Corner(b, UDim.new(0, props.Radius)) end
    return b
end

function U.Ripple(parent, x, y)
    local rip = U.Frame(parent, {
        Color = Color3.fromRGB(255,255,255),
        Tr    = 0.72,
        Sz    = UDim2.fromOffset(0, 0),
        Pos   = UDim2.fromOffset(x - parent.AbsolutePosition.X, y - parent.AbsolutePosition.Y),
        Z     = parent.ZIndex + 20,
    })
    rip.AnchorPoint = Vector2.new(0.5, 0.5)
    U.Corner(rip, UDim.new(1, 0))
    local sz = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    U.Tw(rip, { Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1 }, 0.55,
        Enum.EasingStyle.Quart)
    task.delay(0.55, function() rip:Destroy() end)
end

-- HSV Color helpers
function U.HSV2RGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t2 = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r,g,b = v,t2,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,t2
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = t2,p,v
    elseif i == 5 then r,g,b = v,p,q end
    return Color3.new(r, g, b)
end

function U.RGB2HSV(c)
    local r, g, b = c.R, c.G, c.B
    local max = math.max(r,g,b)
    local min2 = math.min(r,g,b)
    local d = max - min2
    local h, s, v = 0, 0, max
    if max ~= 0 then s = d / max end
    if d ~= 0 then
        if max == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, v
end

-- Drag helper (returns cleanup fn)
function U.Drag(handle, onMove, onEnd)
    local conn1, conn2
    conn1 = handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local startX, startY = inp.Position.X, inp.Position.Y
        conn2 = UIS.InputChanged:Connect(function(inp2)
            if inp2.UserInputType == Enum.UserInputType.MouseMovement then
                onMove(inp2.Position.X - startX, inp2.Position.Y - startY,
                       inp2.Position.X, inp2.Position.Y)
                startX, startY = inp2.Position.X, inp2.Position.Y
            end
        end)
        UIS.InputEnded:Connect(function(inp2)
            if inp2.UserInputType == Enum.UserInputType.MouseButton1 then
                if conn2 then conn2:Disconnect(); conn2 = nil end
                if onEnd then onEnd() end
            end
        end)
    end)
    return function() conn1:Disconnect(); if conn2 then conn2:Disconnect() end end
end

-- ════════════════════════════════════════════
--  GLASS FRAME FACTORY
-- ════════════════════════════════════════════
local function Glass(parent, sz, pos, rad, z, clip)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = T.GlassFill
    f.BackgroundTransparency = T.GlassTr
    f.BorderSizePixel = 0
    f.Size = sz or UDim2.new(1,0,1,0)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.ZIndex = z or 2
    f.ClipsDescendants = clip or false
    f.Parent = parent
    U.Corner(f, UDim.new(0, rad or 10))
    U.Stroke(f)
    return f
end

-- ════════════════════════════════════════════
--  NOTIFICATION SYSTEM  (module-level)
-- ════════════════════════════════════════════
local _notifGui, _notifHolder

local function EnsureNotifGui()
    if _notifGui and _notifGui.Parent then return end
    _notifGui = Instance.new("ScreenGui")
    _notifGui.Name = "LG_Notif"
    _notifGui.ResetOnSpawn = false
    _notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _notifGui.IgnoreGuiInset = true
    pcall(function() _notifGui.Parent = CoreGui end)
    if not _notifGui.Parent then _notifGui.Parent = LP:WaitForChild("PlayerGui") end

    _notifHolder = U.Frame(_notifGui, {
        Sz = UDim2.new(0, 310, 1, -20),
        Pos = UDim2.new(1, -320, 0, 0),
        Z  = 200,
    })
    U.List(_notifHolder, nil, 8, nil, Enum.VerticalAlignment.Bottom)
    U.Padding(_notifHolder, 0, 0, 16, 0)
end

local function Notify(cfg)
    EnsureNotifGui()
    cfg = cfg or {}
    local typeColors = { info=T.Info, success=T.Ok, warning=T.Warn, danger=T.Err }
    local ac = typeColors[cfg.Type or "info"] or T.Info
    local dur = cfg.Duration or 4

    -- Card
    local card = Glass(_notifHolder, UDim2.new(1, 0, 0, 78), nil, 14, 201)
    card.BackgroundTransparency = 0.04
    card.ClipsDescendants = true

    -- Gradient
    local gr = Instance.new("UIGradient")
    gr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.BG3),
        ColorSequenceKeypoint.new(1, T.BG),
    })
    gr.Rotation = 120
    gr.Parent = card

    -- Left accent bar
    local bar = U.Frame(card, { Color=ac, Tr=0, Sz=UDim2.new(0,3,1,0), Z=202 })
    U.Corner(bar, UDim.new(1, 0))

    -- Icon area
    local iconTypes = { info="ℹ", success="✓", warning="⚠", danger="✕" }
    local icon = U.Label(card, {
        Text  = iconTypes[cfg.Type or "info"] or "ℹ",
        Color = ac,
        Font  = Enum.Font.GothamBold,
        Size  = 18,
        Sz    = UDim2.new(0, 32, 0, 32),
        Pos   = UDim2.new(0, 14, 0, 10),
        Z     = 202,
        Align = Enum.TextXAlignment.Center,
    })

    -- Title
    U.Label(card, {
        Text  = cfg.Title or "Notification",
        Color = ac,
        Font  = Enum.Font.GothamBold,
        Size  = 13,
        Sz    = UDim2.new(1, -60, 0, 20),
        Pos   = UDim2.new(0, 50, 0, 10),
        Z     = 202,
    })

    -- Message
    U.Label(card, {
        Text   = cfg.Message or "",
        Color  = T.TxtMid,
        Font   = Enum.Font.Gotham,
        Size   = 11,
        Sz     = UDim2.new(1, -60, 0, 34),
        Pos    = UDim2.new(0, 50, 0, 30),
        Z      = 202,
        VAlign = Enum.TextYAlignment.Top,
        Rich   = false,
    }).TextWrapped = true

    -- Progress bar
    local prog = U.Frame(card, {
        Color = ac, Tr = 0.45,
        Sz  = UDim2.new(1, 0, 0, 3),
        Pos = UDim2.new(0, 0, 1, -3),
        Z   = 202,
    })

    -- Entrance
    card.Position = UDim2.new(1, 20, 0, 0)
    U.Spring(card, { Position = UDim2.new(0, 0, 0, 0) })
    U.Tw(prog, { Size = UDim2.new(0, 0, 0, 3) }, dur, Enum.EasingStyle.Linear)

    task.delay(dur, function()
        U.Tw(card, { Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1 }, T.SpdSlow)
        task.delay(T.SpdSlow + 0.05, function() card:Destroy() end)
    end)
end

-- ════════════════════════════════════════════
--  LIBRARY TABLE
-- ════════════════════════════════════════════
local LG = {}
LG.__index = LG
LG.Notify = Notify
LG.Theme = T

function LG:SetAccent(col)
    T.Accent = col; T.Info = col
end

-- ════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════
local Window = {}
Window.__index = Window

function LG:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, Window)
    self.Title    = cfg.Title    or "Liquid Glass"
    self.Subtitle = cfg.Subtitle or "JAROT404 × KVNXY"
    self.W        = cfg.Width    or 640
    self.H        = cfg.Height   or 450
    self.SideW    = cfg.SidebarWidth or 160
    self.MinW     = cfg.MinWidth or 440
    self.MinH     = cfg.MinHeight or 300
    self.MaxW     = cfg.MaxWidth or 900
    self.MaxH     = cfg.MaxHeight or 700
    self.Tabs     = {}
    self.ActiveTab = nil

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "LiquidGlass2"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
    self._gui = gui

    -- Shadow layer
    local shadow = U.Frame(gui, {
        Color = Color3.fromRGB(0,0,0),
        Tr    = 0.35,
        Sz    = UDim2.fromOffset(self.W + 50, self.H + 50),
        Pos   = UDim2.new(0.5, -(self.W+50)/2, 0.5, -(self.H+50)/2),
        Z     = 1, Radius = 22,
    })
    self._shadow = shadow

    -- Main window frame
    local win = U.Frame(gui, {
        Color = T.BG,
        Tr    = 0.0,
        Sz    = UDim2.fromOffset(self.W, self.H),
        Pos   = UDim2.new(0.5, -self.W/2, 0.5, -self.H/2),
        Z     = 2, Radius = 16, Clip = true,
    })
    U.Stroke(win, T.Border, 0.80, 1)
    self._win = win

    -- BG gradient
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22,26,42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,11,18)),
    })
    grad.Rotation = 130
    grad.Parent = win

    -- ── HEADER ──
    local HEADER_H = 46
    local header = U.Frame(win, {
        Color = Color3.fromRGB(255,255,255), Tr = 0.95,
        Sz    = UDim2.new(1,0,0,HEADER_H),
        Z     = 10, Clip = true,
    })

    -- Header gradient
    local hGrad = Instance.new("UIGradient")
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,35,55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15,17,28)),
    })
    hGrad.Rotation = 90
    hGrad.Parent = header

    -- Top shimmer line
    local shimmer = U.Frame(header, {
        Color=Color3.fromRGB(255,255,255), Tr=0.55,
        Sz=UDim2.new(0.65,0,0,1), Pos=UDim2.new(0.175,0,0,0), Z=11,
    })

    -- Header bottom border
    U.Frame(header, {
        Color=T.Border, Tr=0.80,
        Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,1,-1), Z=11,
    })

    -- macOS traffic lights
    local dotData = {
        { col=Color3.fromRGB(255,95,87),  hov=Color3.fromRGB(255,65,57),  sym="×" },
        { col=Color3.fromRGB(255,189,46), hov=Color3.fromRGB(255,165,20), sym="−" },
        { col=Color3.fromRGB(39,201,63),  hov=Color3.fromRGB(20,180,40),  sym="+" },
    }
    local dots = {}
    for i, d in ipairs(dotData) do
        local dot = U.Btn(header, {
            Color = d.col, Tr = 0,
            Sz = UDim2.fromOffset(14,14),
            Pos = UDim2.new(0, 12 + (i-1)*20, 0.5, -7),
            Z = 12, Radius = 7,
            Text = "", TCol = Color3.new(0,0,0), TSize = 10,
            Font = Enum.Font.GothamBold,
        })
        dot.MouseEnter:Connect(function()
            dot.Text = d.sym
            U.Tw(dot, { BackgroundColor3 = d.hov }, T.SpdFast)
        end)
        dot.MouseLeave:Connect(function()
            dot.Text = ""
            U.Tw(dot, { BackgroundColor3 = d.col }, T.SpdFast)
        end)
        dots[i] = dot
    end

    -- Accent pulse dot before title
    local pulseDot = U.Frame(header, {
        Color = T.Accent, Tr = 0,
        Sz = UDim2.fromOffset(6,6),
        Pos = UDim2.new(0, 74, 0.5, -3),
        Z = 11, Radius = 6,
    })
    -- Pulse animation
    task.spawn(function()
        while pulseDot.Parent do
            U.Tw(pulseDot, { BackgroundTransparency = 0.4 }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
            U.Tw(pulseDot, { BackgroundTransparency = 0 }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
        end
    end)

    -- Title
    U.Label(header, {
        Text  = self.Title,
        Font  = Enum.Font.GothamBold,
        Color = T.TxtHi,
        Size  = 14,
        Sz    = UDim2.new(0, 200, 1, 0),
        Pos   = UDim2.new(0, 84, 0, 0),
        Z     = 12,
    })

    -- Subtitle (right)
    local subL = U.Label(header, {
        Text  = self.Subtitle,
        Font  = Enum.Font.Gotham,
        Color = T.TxtLow,
        Size  = 11,
        Sz    = UDim2.new(1, -90, 1, 0),
        Pos   = UDim2.new(0, 0, 0, 0),
        Z     = 12,
        Align = Enum.TextXAlignment.Right,
    })
    U.Padding(subL, 0, 12, 0, 0)

    -- Drag via header
    U.Drag(header,
        function(dx, dy)
            win.Position = UDim2.new(
                win.Position.X.Scale,
                win.Position.X.Offset + dx,
                win.Position.Y.Scale,
                win.Position.Y.Offset + dy
            )
            shadow.Position = UDim2.new(
                win.Position.X.Scale,
                win.Position.X.Offset - 25,
                win.Position.Y.Scale,
                win.Position.Y.Offset - 25
            )
        end
    )

    -- macOS dot actions
    self._minimized = false
    dots[1].MouseButton1Click:Connect(function()  -- Close
        U.Tw(win, { Size=UDim2.fromOffset(self.W, 0), BackgroundTransparency=1 }, 0.25)
        U.Tw(shadow, { BackgroundTransparency=1 }, 0.25)
        task.delay(0.28, function() gui:Destroy() end)
    end)
    dots[2].MouseButton1Click:Connect(function()  -- Minimize
        self._minimized = not self._minimized
        if self._minimized then
            U.Tw(win, { Size=UDim2.fromOffset(self.W, HEADER_H) }, T.SpdSlow, Enum.EasingStyle.Quint)
        else
            U.Tw(win, { Size=UDim2.fromOffset(self.W, self.H) }, T.SpdSlow, Enum.EasingStyle.Back)
        end
    end)

    self._header = header
    self._headerH = HEADER_H

    -- ── BODY (below header) ──
    local body = U.Frame(win, {
        Sz  = UDim2.new(1, 0, 1, -HEADER_H),
        Pos = UDim2.new(0, 0, 0, HEADER_H),
        Z   = 3, Clip = true,
    })
    self._body = body

    -- ── SIDEBAR ──
    local sidebar = U.Frame(body, {
        Color = T.Sidebar, Tr = 0.0,
        Sz  = UDim2.new(0, self.SideW, 1, 0),
        Z   = 4, Clip = true,
    })

    -- Sidebar gradient
    local sgr = Instance.new("UIGradient")
    sgr.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15,17,26)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,12,20)),
    })
    sgr.Rotation = 180
    sgr.Parent = sidebar

    -- Sidebar right border
    U.Frame(sidebar, {
        Color=T.Border, Tr=0.84,
        Sz=UDim2.new(0,1,1,0), Pos=UDim2.new(1,-1,0,0), Z=5,
    })

    -- Sidebar header mini-logo area
    local sideHead = U.Frame(sidebar, {
        Sz=UDim2.new(1,0,0,44), Z=5,
        Color=Color3.fromRGB(255,255,255), Tr=0.96,
    })
    U.Frame(sideHead, {
        Color=T.Border, Tr=0.84,
        Sz=UDim2.new(0.75,0,0,1), Pos=UDim2.new(0.125,0,1,-1), Z=6,
    })
    U.Label(sideHead, {
        Text  = "MENU",
        Font  = Enum.Font.GothamBold,
        Color = T.TxtLow,
        Size  = 9,
        Sz    = UDim2.new(1,0,1,0),
        Z     = 6,
        Align = Enum.TextXAlignment.Center,
    })

    -- Sidebar tab list
    local sideList = U.Frame(sidebar, {
        Sz  = UDim2.new(1, 0, 1, -44),
        Pos = UDim2.new(0, 0, 0, 44),
        Z   = 5, Clip = false,
    })
    U.List(sideList, nil, 4)
    U.Padding(sideList, 8, 6, 8, 6)
    self._sideList = sideList
    self._sidebar  = sidebar

    -- ── SIDEBAR RESIZE (drag right edge of sidebar) ──
    local sideResizer = U.Frame(sidebar, {
        Color = T.Accent, Tr = 1,
        Sz  = UDim2.new(0, 6, 1, 0),
        Pos = UDim2.new(1, -3, 0, 0),
        Z   = 20,
    })
    sideResizer.Active = true
    U.Drag(sideResizer, function(dx)
        local newSW = math.clamp(sidebar.AbsoluteSize.X + dx, 100, 260)
        sidebar.Size = UDim2.new(0, newSW, 1, 0)
        self._contentArea.Position = UDim2.new(0, newSW, 0, 0)
        self._contentArea.Size     = UDim2.new(1, -newSW, 1, 0)
        self.SideW = newSW
    end)
    sideResizer.MouseEnter:Connect(function()
        U.Tw(sideResizer, { BackgroundTransparency = 0.5 }, T.SpdFast)
        Mouse.Icon = "rbxasset://SystemCursors/SplitEW"
    end)
    sideResizer.MouseLeave:Connect(function()
        U.Tw(sideResizer, { BackgroundTransparency = 1 }, T.SpdFast)
        Mouse.Icon = ""
    end)

    -- ── CONTENT AREA ──
    local contentArea = U.Frame(body, {
        Sz  = UDim2.new(1, -self.SideW, 1, 0),
        Pos = UDim2.new(0, self.SideW, 0, 0),
        Z   = 4, Clip = true,
    })
    self._contentArea = contentArea

    -- ── RESIZE HANDLES ──
    -- Bottom edge (height)
    local resizeB = U.Frame(win, {
        Color=T.Accent, Tr=1,
        Sz=UDim2.new(1,-30,0,8), Pos=UDim2.new(0,0,1,-8), Z=30,
    })
    resizeB.Active = true
    U.Drag(resizeB, function(_, dy)
        local newH = math.clamp(self.H + dy, self.MinH, self.MaxH)
        self.H = newH
        win.Size = UDim2.fromOffset(self.W, newH)
        shadow.Size = UDim2.fromOffset(self.W+50, newH+50)
    end)
    resizeB.MouseEnter:Connect(function()
        U.Tw(resizeB, { BackgroundTransparency = 0.4 }, T.SpdFast)
        Mouse.Icon = "rbxasset://SystemCursors/SplitNS"
    end)
    resizeB.MouseLeave:Connect(function()
        U.Tw(resizeB, { BackgroundTransparency = 1 }, T.SpdFast)
        Mouse.Icon = ""
    end)

    -- Left edge (width)
    local resizeL = U.Frame(win, {
        Color=T.Accent, Tr=1,
        Sz=UDim2.new(0,8,1,-30), Pos=UDim2.new(0,-4,0,0), Z=30,
    })
    resizeL.Active = true
    U.Drag(resizeL, function(dx)
        local delta = -dx
        local newW = math.clamp(self.W + delta, self.MinW, self.MaxW)
        local diff = newW - self.W
        self.W = newW
        win.Size = UDim2.fromOffset(newW, self.H)
        win.Position = UDim2.new(
            win.Position.X.Scale,
            win.Position.X.Offset - diff,
            win.Position.Y.Scale,
            win.Position.Y.Offset
        )
        shadow.Size = UDim2.fromOffset(newW+50, self.H+50)
    end)
    resizeL.MouseEnter:Connect(function()
        U.Tw(resizeL, { BackgroundTransparency = 0.4 }, T.SpdFast)
        Mouse.Icon = "rbxasset://SystemCursors/SplitEW"
    end)
    resizeL.MouseLeave:Connect(function()
        U.Tw(resizeL, { BackgroundTransparency = 1 }, T.SpdFast)
        Mouse.Icon = ""
    end)

    -- Bottom-right corner (W + H)
    local resizeBR = U.Frame(win, {
        Color=T.Accent, Tr=0.6,
        Sz=UDim2.fromOffset(18,18), Pos=UDim2.new(1,-18,1,-18), Z=31, Radius=4,
    })
    -- Corner grip dots
    for i = 1,3 do
        for j = 1,3 do
            if i+j > 3 then
                U.Frame(resizeBR, {
                    Color=Color3.fromRGB(255,255,255), Tr=0.5,
                    Sz=UDim2.fromOffset(2,2),
                    Pos=UDim2.fromOffset(3+(j-1)*5, 3+(i-1)*5),
                    Z=32, Radius=1,
                })
            end
        end
    end
    resizeBR.Active = true
    U.Drag(resizeBR, function(dx, dy)
        self.W = math.clamp(self.W + dx, self.MinW, self.MaxW)
        self.H = math.clamp(self.H + dy, self.MinH, self.MaxH)
        win.Size = UDim2.fromOffset(self.W, self.H)
        shadow.Size = UDim2.fromOffset(self.W+50, self.H+50)
        resizeBR.Position = UDim2.new(1,-18,1,-18)
    end)
    resizeBR.MouseEnter:Connect(function()
        U.Tw(resizeBR, { BackgroundTransparency=0.2 }, T.SpdFast)
        Mouse.Icon = "rbxasset://SystemCursors/SizeNWSE"
    end)
    resizeBR.MouseLeave:Connect(function()
        U.Tw(resizeBR, { BackgroundTransparency=0.6 }, T.SpdFast)
        Mouse.Icon = ""
    end)

    -- Entrance animation
    win.Size = UDim2.fromOffset(self.W, 0)
    win.BackgroundTransparency = 1
    U.Tw(win, { Size=UDim2.fromOffset(self.W, self.H), BackgroundTransparency=0 },
        T.SpdSlow, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return self
end

-- ════════════════════════════════════════════
--  ADD TAB
-- ════════════════════════════════════════════
function Window:AddTab(name, icon)
    local td = { Name=name }

    -- ── Sidebar button ──
    local sbtn = U.Btn(self._sideList, {
        Color  = T.Accent, Tr = 1,
        Sz     = UDim2.new(1, 0, 0, 38),
        Z      = 6,
        Radius = 8,
        Align  = Enum.TextXAlignment.Left,
    })
    sbtn.ClipsDescendants = true

    -- Active left bar
    local activeLine = U.Frame(sbtn, {
        Color = T.Accent, Tr = 1,
        Sz = UDim2.new(0, 3, 0.6, 0),
        Pos = UDim2.new(0, 0, 0.2, 0),
        Z = 7, Radius = 3,
    })

    -- Icon
    local iconL = U.Label(sbtn, {
        Text  = icon or "◈",
        Color = T.TxtLow,
        Font  = Enum.Font.GothamBold,
        Size  = 15,
        Sz    = UDim2.new(0, 32, 1, 0),
        Pos   = UDim2.new(0, 8, 0, 0),
        Z     = 7,
        Align = Enum.TextXAlignment.Center,
    })

    -- Name
    local nameL = U.Label(sbtn, {
        Text  = name,
        Color = T.TxtLow,
        Font  = Enum.Font.GothamSemibold,
        Size  = 12,
        Sz    = UDim2.new(1, -42, 1, 0),
        Pos   = UDim2.new(0, 38, 0, 0),
        Z     = 7,
        Trunc = Enum.TextTruncate.AtEnd,
    })

    -- ── Content page ──
    local page = Instance.new("ScrollingFrame")
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = T.Accent
    page.ScrollBarImageTransparency = 0.45
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 5
    page.Parent = self._contentArea
    U.List(page, nil, 8)
    U.Padding(page, 12, 12, 16, 12)

    td._sbtn = sbtn; td._page = page
    td._activeLine = activeLine
    td._iconL = iconL; td._nameL = nameL

    -- Hover
    sbtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= td then
            U.Tw(sbtn, { BackgroundTransparency=0.88 }, T.SpdFast)
            U.Tw(iconL, { TextColor3=T.TxtMid }, T.SpdFast)
            U.Tw(nameL, { TextColor3=T.TxtMid }, T.SpdFast)
        end
    end)
    sbtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= td then
            U.Tw(sbtn, { BackgroundTransparency=1 }, T.SpdFast)
            U.Tw(iconL, { TextColor3=T.TxtLow }, T.SpdFast)
            U.Tw(nameL, { TextColor3=T.TxtLow }, T.SpdFast)
        end
    end)
    sbtn.MouseButton1Down:Connect(function()
        U.Ripple(sbtn, Mouse.X, Mouse.Y)
    end)
    sbtn.MouseButton1Click:Connect(function()
        self:_Switch(td)
    end)

    table.insert(self.Tabs, td)
    if #self.Tabs == 1 then self:_Switch(td) end

    -- ── Element builder ──
    local Tab = {}
    Tab._page  = page
    Tab._order = 0

    local function NextOrder()
        Tab._order += 1
        return Tab._order
    end

    -- ─────────────────── SECTION ───────────────────
    function Tab:AddSection(text)
        local sec = U.Frame(page, {
            Sz=UDim2.new(1,0,0,28), Z=6,
        })
        sec.LayoutOrder = NextOrder()

        -- line
        U.Frame(sec, {
            Color=T.TxtLow, Tr=0.5,
            Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0.5,0), Z=6,
        })
        -- label bg
        local lbg = U.Frame(sec, {
            Color=T.BG, Tr=0,
            Sz=UDim2.new(0,0,1,0),
            Pos=UDim2.new(0,0,0,0), Z=7,
        })
        lbg.AutomaticSize = Enum.AutomaticSize.X
        U.Padding(lbg, 0, 8, 0, 0)
        U.Label(lbg, {
            Text  = text:upper(),
            Color = T.Accent,
            Font  = Enum.Font.GothamBold,
            Size  = 9,
            Sz    = UDim2.new(0,0,1,0),
            Z     = 8,
        }).AutomaticSize = Enum.AutomaticSize.X
    end

    -- ─────────────────── BUTTON ───────────────────
    function Tab:AddButton(cfg)
        cfg = cfg or {}
        local row = Glass(page, UDim2.new(1,0,0,42), nil, 10, 6, true)
        row.LayoutOrder = NextOrder()

        local iconLbl = U.Label(row, {
            Text  = cfg.Icon or "▶",
            Color = T.Accent,
            Font  = Enum.Font.GothamBold,
            Size  = 14,
            Sz    = UDim2.new(0,36,1,0),
            Pos   = UDim2.new(0,4,0,0),
            Z     = 7,
            Align = Enum.TextXAlignment.Center,
        })
        U.Label(row, {
            Text  = cfg.Text or "Button",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(1,-52,1,0),
            Pos   = UDim2.new(0,40,0,0),
            Z     = 7,
        })

        local click = U.Btn(row, { Sz=UDim2.new(1,0,1,0), Z=8 })
        click.MouseEnter:Connect(function()
            U.Tw(row, { BackgroundTransparency=T.GlassTr-0.06 }, T.SpdFast)
        end)
        click.MouseLeave:Connect(function()
            U.Tw(row, { BackgroundTransparency=T.GlassTr }, T.SpdFast)
        end)
        click.MouseButton1Down:Connect(function()
            U.Tw(row, { BackgroundTransparency=T.GlassTr-0.1 }, 0.07)
            U.Ripple(row, Mouse.X, Mouse.Y)
        end)
        click.MouseButton1Up:Connect(function()
            U.Tw(row, { BackgroundTransparency=T.GlassTr-0.06 }, T.SpdFast)
        end)
        click.MouseButton1Click:Connect(function()
            if cfg.Callback then pcall(cfg.Callback) end
        end)
        row.Parent = page
        return { Frame = row }
    end

    -- ─────────────────── TOGGLE ───────────────────
    function Tab:AddToggle(cfg)
        cfg = cfg or {}
        local state = cfg.Default or false

        local row = Glass(page, UDim2.new(1,0,0,cfg.Description and 52 or 42), nil, 10, 6)
        row.LayoutOrder = NextOrder()

        U.Label(row, {
            Text  = cfg.Text or "Toggle",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(1,-66,0,22),
            Pos   = UDim2.new(0,14,0, cfg.Description and 6 or 0),
            Z     = 7,
        })
        if cfg.Description then
            U.Label(row, {
                Text  = cfg.Description,
                Color = T.TxtLow,
                Font  = Enum.Font.Gotham,
                Size  = 10,
                Sz    = UDim2.new(1,-66,0,16),
                Pos   = UDim2.new(0,14,0,26),
                Z     = 7,
            })
        end

        -- Track
        local track = U.Frame(row, {
            Color = state and T.Accent or Color3.fromRGB(45,50,70),
            Tr    = 0,
            Sz    = UDim2.fromOffset(44,24),
            Pos   = UDim2.new(1,-58,0.5,-12),
            Z     = 7, Radius = 12,
        })
        -- Track stroke
        U.Stroke(track, T.Border, 0.70, 1)

        -- Thumb
        local thumb = U.Frame(track, {
            Color = Color3.fromRGB(255,255,255),
            Tr    = 0,
            Sz    = UDim2.fromOffset(18,18),
            Pos   = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            Z     = 8, Radius = 9,
        })

        -- Thumb inner glow
        local thumbGlow = U.Frame(thumb, {
            Color = state and T.Accent or Color3.fromRGB(180,185,210),
            Tr    = 0.65,
            Sz    = UDim2.fromOffset(8,8),
            Pos   = UDim2.new(0.5,-4,0.5,-4),
            Z     = 9, Radius = 4,
        })

        local click = U.Btn(row, { Sz=UDim2.new(1,0,1,0), Z=9 })
        click.MouseButton1Click:Connect(function()
            state = not state
            U.Tw(track, { BackgroundColor3 = state and T.Accent or Color3.fromRGB(45,50,70) }, T.Spd)
            U.Tw(thumb, { Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9) },
                T.Spd, Enum.EasingStyle.Back)
            U.Tw(thumbGlow, { BackgroundColor3 = state and T.Accent or Color3.fromRGB(180,185,210) }, T.Spd)
            if cfg.Callback then pcall(cfg.Callback, state) end
        end)
        row.Parent = page

        return {
            Set = function(_, v)
                state = v
                U.Tw(track, { BackgroundColor3 = v and T.Accent or Color3.fromRGB(45,50,70) }, T.Spd)
                U.Tw(thumb, { Position = v and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9) },
                    T.Spd, Enum.EasingStyle.Back)
                U.Tw(thumbGlow, { BackgroundColor3 = v and T.Accent or Color3.fromRGB(180,185,210) }, T.Spd)
                if cfg.Callback then pcall(cfg.Callback, v) end
            end,
            Get = function() return state end,
        }
    end

    -- ─────────────────── SLIDER ───────────────────
    function Tab:AddSlider(cfg)
        cfg = cfg or {}
        local mn  = cfg.Min    or 0
        local mx  = cfg.Max    or 100
        local val = cfg.Value  or mn
        local suf = cfg.Suffix or ""
        local dec = cfg.Decimals or 0

        local row = Glass(page, UDim2.new(1,0,0,62), nil, 10, 6)
        row.LayoutOrder = NextOrder()

        U.Label(row, {
            Text  = cfg.Text or "Slider",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(1,-80,0,22),
            Pos   = UDim2.new(0,14,0,8),
            Z     = 7,
        })
        local valL = U.Label(row, {
            Text  = string.format("%."..dec.."f%s", val, suf),
            Color = T.Accent,
            Font  = Enum.Font.GothamBold,
            Size  = 13,
            Sz    = UDim2.new(0,74,0,22),
            Pos   = UDim2.new(1,-88,0,8),
            Z     = 7,
            Align = Enum.TextXAlignment.Right,
        })

        -- Track
        local track = U.Frame(row, {
            Color = Color3.fromRGB(35,40,60),
            Tr    = 0,
            Sz    = UDim2.new(1,-28,0,5),
            Pos   = UDim2.new(0,14,1,-18),
            Z     = 7, Radius = 3,
        })

        -- Fill
        local initRel = (val-mn)/(mx-mn)
        local fill = U.Frame(track, {
            Color = T.Accent, Tr=0,
            Sz    = UDim2.new(initRel,0,1,0),
            Z     = 8, Radius = 3,
        })

        -- Thumb
        local thumb = U.Frame(track, {
            Color = Color3.fromRGB(230,235,255), Tr=0,
            Sz    = UDim2.fromOffset(16,16),
            Pos   = UDim2.new(initRel,-8,0.5,-8),
            Z     = 9, Radius = 8,
        })
        U.Stroke(thumb, T.Accent, 0.25, 2)

        local dragging = false
        local function upd(ax)
            local rel = math.clamp((ax - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            val = mn + (mx-mn)*rel
            if dec == 0 then val = math.floor(val) end
            fill.Size  = UDim2.new(rel,0,1,0)
            thumb.Position = UDim2.new(rel,-8,0.5,-8)
            valL.Text  = string.format("%."..dec.."f%s", val, suf)
            if cfg.Callback then pcall(cfg.Callback, val) end
        end

        thumb.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                U.Tw(thumb, {Size=UDim2.fromOffset(20,20), Position=UDim2.new(thumb.Position.X.Scale,-10,0.5,-10)}, 0.1, Enum.EasingStyle.Back)
            end
        end)
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                upd(inp.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                upd(inp.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                dragging = false
                U.Tw(thumb, {Size=UDim2.fromOffset(16,16)}, 0.1, Enum.EasingStyle.Back)
            end
        end)

        row.Parent = page
        return {
            Get = function() return val end,
            Set = function(_, v)
                v = math.clamp(v, mn, mx)
                val = v
                local rel = (v-mn)/(mx-mn)
                fill.Size = UDim2.new(rel,0,1,0)
                thumb.Position = UDim2.new(rel,-8,0.5,-8)
                valL.Text = string.format("%."..dec.."f%s", val, suf)
            end,
        }
    end

    -- ─────────────────── DROPDOWN ───────────────────
    function Tab:AddDropdown(cfg)
        cfg = cfg or {}
        local opts = cfg.Options or {}
        local sel  = cfg.Default or opts[1] or "Select..."
        local open = false

        local row = Glass(page, UDim2.new(1,0,0,42), nil, 10, 6)
        row.LayoutOrder = NextOrder()
        row.ClipsDescendants = false

        U.Label(row, {
            Text  = cfg.Text or "Dropdown",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(0.48,0,1,0),
            Pos   = UDim2.new(0,14,0,0),
            Z     = 7,
        })

        local selBtn = U.Btn(row, {
            Color  = Color3.fromRGB(30,35,55), Tr=0,
            Sz     = UDim2.new(0.52,-20,0,28),
            Pos    = UDim2.new(0.48,6,0.5,-14),
            Z      = 7, Radius = 7,
            Text   = sel .. "  ▾",
            TCol   = T.TxtMid,
            TSize  = 11,
            Font   = Enum.Font.GothamSemibold,
        })

        -- Panel
        local panel = Glass(row,
            UDim2.new(0.52,-20,0,0),
            UDim2.new(0.48,6,1,5),
            8, 25)
        panel.Visible = false
        panel.ClipsDescendants = true
        panel.BackgroundTransparency = 0.03

        local panelScroll = Instance.new("ScrollingFrame")
        panelScroll.BackgroundTransparency = 1
        panelScroll.BorderSizePixel = 0
        panelScroll.Size = UDim2.new(1,0,1,0)
        panelScroll.ScrollBarThickness = 2
        panelScroll.ScrollBarImageColor3 = T.Accent
        panelScroll.CanvasSize = UDim2.new(0,0,0,0)
        panelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        panelScroll.ZIndex = 26
        panelScroll.Parent = panel
        U.List(panelScroll, nil, 2)
        U.Padding(panelScroll, 4,4,4,4)

        local function rebuild()
            for _, c in pairs(panelScroll:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for i, opt in ipairs(opts) do
                local ob = U.Btn(panelScroll, {
                    Color = opt==sel and T.Accent or Color3.fromRGB(255,255,255),
                    Tr    = opt==sel and 0.80 or 1,
                    Sz    = UDim2.new(1,0,0,28),
                    Z     = 27, Radius = 5,
                    Text  = opt,
                    TCol  = opt==sel and T.Accent or T.TxtMid,
                    TSize = 11, Font = Enum.Font.Gotham,
                })
                ob.LayoutOrder = i
                ob.MouseEnter:Connect(function()
                    if opt ~= sel then U.Tw(ob, { BackgroundTransparency=0.90 }, T.SpdFast) end
                end)
                ob.MouseLeave:Connect(function()
                    if opt ~= sel then U.Tw(ob, { BackgroundTransparency=1 }, T.SpdFast) end
                end)
                ob.MouseButton1Click:Connect(function()
                    sel = opt
                    selBtn.Text = opt .. "  ▾"
                    open = false
                    U.Tw(panel, { Size=UDim2.new(0.52,-20,0,0) }, T.Spd)
                    task.delay(T.Spd+0.02, function() panel.Visible=false end)
                    rebuild()
                    if cfg.Callback then pcall(cfg.Callback, sel) end
                end)
            end
            panelScroll.CanvasSize = UDim2.new(0,0,0,#opts*30+8)
        end
        rebuild()

        selBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                panel.Visible = true
                panel.Size = UDim2.new(0.52,-20,0,0)
                local targetH = math.min(#opts*30+12, 180)
                U.Tw(panel, { Size=UDim2.new(0.52,-20,0,targetH) }, T.Spd, Enum.EasingStyle.Back)
            else
                U.Tw(panel, { Size=UDim2.new(0.52,-20,0,0) }, T.Spd)
                task.delay(T.Spd+0.02, function() panel.Visible=false end)
            end
        end)

        row.Parent = page
        return {
            Get = function() return sel end,
            Set = function(_, v) sel=v; selBtn.Text=v.."  ▾"; rebuild() end,
            Refresh = function(_, newOpts) opts=newOpts; rebuild() end,
        }
    end

    -- ─────────────────── INPUT ───────────────────
    function Tab:AddInput(cfg)
        cfg = cfg or {}
        local row = Glass(page, UDim2.new(1,0,0,62), nil, 10, 6)
        row.LayoutOrder = NextOrder()

        U.Label(row, {
            Text  = cfg.Text or "Input",
            Color = T.TxtMid,
            Font  = Enum.Font.GothamSemibold,
            Size  = 10,
            Sz    = UDim2.new(1,-14,0,18),
            Pos   = UDim2.new(0,14,0,7),
            Z     = 7,
        })

        local boxBg = U.Frame(row, {
            Color = Color3.fromRGB(20,23,38), Tr=0,
            Sz    = UDim2.new(1,-28,0,28),
            Pos   = UDim2.new(0,14,1,-34),
            Z     = 7, Radius = 7,
        })
        local boxStroke = U.Stroke(boxBg, T.Accent, 1, 1.5)

        local box = Instance.new("TextBox")
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Size = UDim2.new(1,0,1,0)
        box.Font = Enum.Font.Gotham
        box.PlaceholderText = cfg.Placeholder or "Type..."
        box.PlaceholderColor3 = T.TxtLow
        box.Text = cfg.Default or ""
        box.TextColor3 = T.TxtHi
        box.TextSize = 12
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = cfg.ClearOnFocus or false
        box.ZIndex = 8
        box.Parent = boxBg
        U.Padding(box, 0, 8, 0, 10)

        box.Focused:Connect(function()
            U.Tw(boxStroke, { Transparency=0.25 }, T.SpdFast)
            U.Tw(boxBg, { BackgroundColor3=Color3.fromRGB(26,30,50) }, T.SpdFast)
        end)
        box.FocusLost:Connect(function(enter)
            U.Tw(boxStroke, { Transparency=1 }, T.SpdFast)
            U.Tw(boxBg, { BackgroundColor3=Color3.fromRGB(20,23,38) }, T.SpdFast)
            if cfg.Callback then pcall(cfg.Callback, box.Text, enter) end
        end)

        row.Parent = page
        return { Get=function() return box.Text end, Set=function(_,v) box.Text=v end }
    end

    -- ─────────────────── KEYBIND ───────────────────
    function Tab:AddKeybind(cfg)
        cfg = cfg or {}
        local key = cfg.Default or Enum.KeyCode.Unknown
        local listening = false

        local row = Glass(page, UDim2.new(1,0,0,42), nil, 10, 6)
        row.LayoutOrder = NextOrder()

        U.Label(row, {
            Text  = cfg.Text or "Keybind",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(1,-110,1,0),
            Pos   = UDim2.new(0,14,0,0),
            Z     = 7,
        })

        local kbtn = U.Btn(row, {
            Color  = Color3.fromRGB(28,33,52), Tr=0,
            Sz     = UDim2.fromOffset(84,26),
            Pos    = UDim2.new(1,-98,0.5,-13),
            Z      = 7, Radius = 6,
            Text   = key==Enum.KeyCode.Unknown and "NONE" or key.Name,
            TCol   = T.Accent,
            TSize  = 11,
            Font   = Enum.Font.GothamBold,
        })

        kbtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            kbtn.Text = "● · ·"
            U.Tw(kbtn, { TextColor3=T.Warn }, T.SpdFast)
        end)

        UIS.InputBegan:Connect(function(inp, gp)
            if listening and not gp and inp.UserInputType==Enum.UserInputType.Keyboard then
                key = inp.KeyCode
                listening = false
                kbtn.Text = key.Name
                U.Tw(kbtn, { TextColor3=T.Accent }, T.SpdFast)
                if cfg.Callback then pcall(cfg.Callback, key) end
            elseif not listening and not gp and inp.KeyCode==key and cfg.OnPress then
                pcall(cfg.OnPress)
            end
        end)

        row.Parent = page
        return { Get=function() return key end }
    end

    -- ─────────────────── LABEL ───────────────────
    function Tab:AddLabel(cfg)
        cfg = cfg or {}
        local row = U.Frame(page, { Sz=UDim2.new(1,0,0,26), Z=6 })
        row.LayoutOrder = NextOrder()
        U.Padding(row, 0, 0, 0, 14)

        local lbl = U.Label(row, {
            Text  = cfg.Text  or "",
            Color = cfg.Color or T.TxtLow,
            Font  = cfg.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
            Size  = cfg.Size  or 12,
            Sz    = UDim2.new(1,0,1,0),
            Z     = 7, Rich = true,
        })
        row.Parent = page
        return { Set=function(_,v) lbl.Text=v end, Get=function() return lbl.Text end }
    end

    -- ─────────────────── COLOR PICKER (HSV Full) ───────────────────
    function Tab:AddColorPicker(cfg)
        cfg = cfg or {}
        local color = cfg.Default or Color3.fromRGB(110,175,255)
        local h, s, v = U.RGB2HSV(color)

        local row = Glass(page, UDim2.new(1,0,0,42), nil, 10, 6)
        row.LayoutOrder = NextOrder()
        row.ClipsDescendants = false

        U.Label(row, {
            Text  = cfg.Text or "Color",
            Color = T.TxtHi,
            Font  = Enum.Font.GothamSemibold,
            Size  = 13,
            Sz    = UDim2.new(1,-70,1,0),
            Pos   = UDim2.new(0,14,0,0),
            Z     = 7,
        })

        -- Swatch button
        local swatch = U.Btn(row, {
            Color  = color, Tr=0,
            Sz     = UDim2.fromOffset(40,24),
            Pos    = UDim2.new(1,-54,0.5,-12),
            Z      = 7, Radius = 6,
        })
        U.Stroke(swatch, Color3.fromRGB(255,255,255), 0.65, 1)

        -- Hex label on swatch
        local hexL = U.Label(swatch, {
            Text  = "",
            Color = Color3.fromRGB(255,255,255),
            Font  = Enum.Font.GothamBold,
            Size  = 7,
            Sz    = UDim2.new(1,0,1,0),
            Z     = 8,
            Align = Enum.TextXAlignment.Center,
        })

        -- Picker panel
        local pickerOpen = false
        local panel = Glass(row, UDim2.new(1,0,0,0), UDim2.new(0,0,1,5), 12, 20)
        panel.Visible = false
        panel.ClipsDescendants = true
        panel.BackgroundTransparency = 0.03

        -- ── Hue gradient bar
        local hueBar = U.Frame(panel, {
            Sz = UDim2.new(1,-28,0,14),
            Pos = UDim2.new(0,14,0,12),
            Z  = 21, Radius = 7, Tr = 1,
        })
        -- Paint hue gradient using ImageLabel trick (UIGradient works!)
        local hueGrad = Instance.new("UIGradient")
        hueGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,     Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1/6,   Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(2/6,   Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(3/6,   Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(4/6,   Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(5/6,   Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,     Color3.fromRGB(255,0,0)),
        })
        hueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
        hueBar.BackgroundTransparency = 0
        hueGrad.Parent = hueBar

        -- Hue thumb
        local hueThumb = U.Frame(hueBar, {
            Color = Color3.fromRGB(255,255,255), Tr=0,
            Sz = UDim2.fromOffset(6,18),
            Pos = UDim2.new(h,-3,0.5,-9),
            Z  = 22, Radius = 3,
        })
        U.Stroke(hueThumb, Color3.fromRGB(0,0,0), 0.5, 1.5)

        -- ── SV square (saturation/value 2D)
        local svSq = U.Frame(panel, {
            Sz  = UDim2.new(1,-28,0,110),
            Pos = UDim2.new(0,14,0,34),
            Z   = 21, Radius = 6,
        })
        svSq.BackgroundColor3 = U.HSV2RGB(h, 1, 1)

        -- White gradient (left = white)
        local svGradW = Instance.new("UIGradient")
        svGradW.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
        })
        svGradW.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        svGradW.Parent = svSq

        -- Black gradient overlay (bottom = black)
        local svBlack = U.Frame(svSq, {
            Sz=UDim2.new(1,0,1,0), Z=22, Radius=6,
        })
        local svGradB = Instance.new("UIGradient")
        svGradB.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
        })
        svGradB.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        svGradB.Rotation = 90
        svGradB.Parent = svBlack

        -- SV crosshair
        local svCross = U.Frame(svSq, {
            Color = Color3.fromRGB(255,255,255), Tr=0,
            Sz = UDim2.fromOffset(12,12),
            Pos = UDim2.new(s,-6,1-v,-6),
            Z  = 23, Radius = 6,
        })
        U.Stroke(svCross, Color3.fromRGB(0,0,0), 0.4, 1.5)

        -- ── Alpha bar
        local alphaBar = U.Frame(panel, {
            Sz  = UDim2.new(1,-28,0,14),
            Pos = UDim2.new(0,14,0,152),
            Z   = 21, Radius = 7,
        })
        -- Checkerboard-ish bg
        alphaBar.BackgroundColor3 = Color3.fromRGB(180,180,180)
        local alphaGrad2 = Instance.new("UIGradient")
        alphaGrad2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, color),
        })
        alphaGrad2.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(1,0),
        })
        alphaGrad2.Parent = alphaBar

        local alpha = 1
        local alphaThumb = U.Frame(alphaBar, {
            Color = Color3.fromRGB(255,255,255), Tr=0,
            Sz = UDim2.fromOffset(6,18), Pos = UDim2.new(alpha,-3,0.5,-9),
            Z=22, Radius=3,
        })
        U.Stroke(alphaThumb, Color3.fromRGB(0,0,0), 0.5, 1.5)

        -- ── Hex input
        local hexBox = Instance.new("TextBox")
        hexBox.BackgroundColor3 = Color3.fromRGB(20,24,40)
        hexBox.BackgroundTransparency = 0
        hexBox.BorderSizePixel = 0
        hexBox.Size = UDim2.new(1,-28,0,22)
        hexBox.Position = UDim2.new(0,14,0,174)
        hexBox.Font = Enum.Font.GothamBold
        hexBox.Text = string.format("#%02X%02X%02X", math.round(color.R*255), math.round(color.G*255), math.round(color.B*255))
        hexBox.TextColor3 = T.Accent
        hexBox.TextSize = 11
        hexBox.ZIndex = 21
        hexBox.ClearTextOnFocus = false
        U.Corner(hexBox, UDim.new(0,5))
        U.Padding(hexBox, 0, 0, 0, 8)
        hexBox.Parent = panel

        -- ── Preview swatch in panel
        local prevSwatch = U.Frame(panel, {
            Sz = UDim2.new(1,-28,0,22),
            Pos = UDim2.new(0,14,0,202),
            Z=21, Radius=5, Color=color, Tr=0,
        })

        -- Update function
        local function updateColor()
            color = U.HSV2RGB(h, s, v)
            swatch.BackgroundColor3 = color
            prevSwatch.BackgroundColor3 = color
            svSq.BackgroundColor3 = U.HSV2RGB(h, 1, 1)
            alphaGrad2.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, color),
                ColorSequenceKeypoint.new(1, color),
            })
            hexBox.Text = string.format("#%02X%02X%02X",
                math.round(color.R*255), math.round(color.G*255), math.round(color.B*255))
            svCross.Position = UDim2.new(s,-6,1-v,-6)
            hueThumb.Position = UDim2.new(h,-3,0.5,-9)
            if cfg.Callback then pcall(cfg.Callback, color, alpha) end
        end

        -- Hue drag
        U.Drag(hueBar, function(dx)
            local rel = math.clamp((Mouse.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
            h = rel
            updateColor()
        end)
        hueBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local rel = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
                h=rel; updateColor()
            end
        end)

        -- SV drag
        local svDragging = false
        svSq.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true
                local function doSV(i2)
                    s = math.clamp((i2.Position.X - svSq.AbsolutePosition.X)/svSq.AbsoluteSize.X,0,1)
                    v = 1 - math.clamp((i2.Position.Y - svSq.AbsolutePosition.Y)/svSq.AbsoluteSize.Y,0,1)
                    updateColor()
                end
                doSV(inp)
                UIS.InputChanged:Connect(function(i2)
                    if svDragging and i2.UserInputType==Enum.UserInputType.MouseMovement then doSV(i2) end
                end)
                UIS.InputEnded:Connect(function(i2)
                    if i2.UserInputType==Enum.UserInputType.MouseButton1 then svDragging=false end
                end)
            end
        end)

        -- Alpha drag
        U.Drag(alphaBar, function(dx)
            local rel = math.clamp((Mouse.X - alphaBar.AbsolutePosition.X)/alphaBar.AbsoluteSize.X,0,1)
            alpha = rel
            alphaThumb.Position = UDim2.new(rel,-3,0.5,-9)
        end)
        alphaBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local rel = math.clamp((inp.Position.X-alphaBar.AbsolutePosition.X)/alphaBar.AbsoluteSize.X,0,1)
                alpha=rel; alphaThumb.Position=UDim2.new(rel,-3,0.5,-9)
            end
        end)

        -- Hex input
        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#","")
            if #hex == 6 then
                local r = tonumber(hex:sub(1,2),16)/255
                local g = tonumber(hex:sub(3,4),16)/255
                local b = tonumber(hex:sub(5,6),16)/255
                if r and g and b then
                    color = Color3.new(r,g,b)
                    h,s,v = U.RGB2HSV(color)
                    updateColor()
                end
            end
        end)

        swatch.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                panel.Visible = true
                U.Tw(panel, { Size=UDim2.new(1,0,0,232) }, T.Spd, Enum.EasingStyle.Back)
            else
                U.Tw(panel, { Size=UDim2.new(1,0,0,0) }, T.Spd)
                task.delay(T.Spd+0.02, function() panel.Visible=false end)
            end
        end)

        row.Parent = page
        updateColor()

        return {
            Get    = function() return color end,
            GetAlpha = function() return alpha end,
            Set    = function(_, c)
                color = c
                h,s,v = U.RGB2HSV(c)
                updateColor()
            end,
        }
    end

    -- ─────────────────── PARAGRAPH ───────────────────
    function Tab:AddParagraph(cfg)
        cfg = cfg or {}
        local row = Glass(page, UDim2.new(1,0,0,0), nil, 10, 6)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.LayoutOrder = NextOrder()

        local inner = U.Frame(row, { Sz=UDim2.new(1,0,0,0), Z=7 })
        inner.AutomaticSize = Enum.AutomaticSize.Y
        U.Padding(inner, 10, 12, 10, 12)
        U.List(inner, nil, 4)

        if cfg.Title then
            U.Label(inner, {
                Text=cfg.Title, Color=T.TxtHi,
                Font=Enum.Font.GothamBold, Size=13, Z=7,
                Sz=UDim2.new(1,0,0,18),
            })
        end
        local bodyL = U.Label(inner, {
            Text=cfg.Text or "", Color=T.TxtMid,
            Font=Enum.Font.Gotham, Size=11, Z=7,
            Sz=UDim2.new(1,0,0,0),
        })
        bodyL.TextWrapped = true
        bodyL.AutomaticSize = Enum.AutomaticSize.Y

        row.Parent = page
        return { Set=function(_,v) bodyL.Text=v end }
    end

    -- ─────────────────── DIVIDER ───────────────────
    function Tab:AddDivider()
        local row = U.Frame(page, { Sz=UDim2.new(1,0,0,16), Z=6 })
        row.LayoutOrder = NextOrder()
        U.Frame(row, { Color=T.TxtLow, Tr=0.7, Sz=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0.5,0), Z=7 })
        row.Parent = page
    end

    -- Expose notify through tab too
    function Tab:Notify(cfg2) Notify(cfg2) end

    return Tab
end

-- ════════════════════════════════════════════
--  INTERNAL: SWITCH TAB
-- ════════════════════════════════════════════
function Window:_Switch(td)
    if self.ActiveTab then
        self.ActiveTab._page.Visible = false
        U.Tw(self.ActiveTab._sbtn, { BackgroundTransparency=1 }, T.Spd)
        U.Tw(self.ActiveTab._activeLine, { BackgroundTransparency=1 }, T.Spd)
        U.Tw(self.ActiveTab._iconL, { TextColor3=T.TxtLow }, T.Spd)
        U.Tw(self.ActiveTab._nameL, { TextColor3=T.TxtLow }, T.Spd)
    end
    self.ActiveTab = td
    td._page.Visible = true
    U.Tw(td._sbtn, { BackgroundTransparency=0.88 }, T.Spd)
    U.Tw(td._activeLine, { BackgroundTransparency=0 }, T.Spd)
    U.Tw(td._iconL, { TextColor3=T.Accent }, T.Spd)
    U.Tw(td._nameL, { TextColor3=T.TxtHi }, T.Spd)
    -- Slide-in page
    td._page.Position = UDim2.new(0.08, 0, 0, 0)
    td._page.BackgroundTransparency = 1
    U.Tw(td._page, { Position=UDim2.new(0,0,0,0) }, T.SpdSlow, Enum.EasingStyle.Quint)
end

-- ════════════════════════════════════════════
--  PUBLIC
-- ════════════════════════════════════════════
function LG:CreateWindow(cfg) return Window.new(LG, cfg) end
Window.new = function(lg_self, cfg) return LG.CreateWindow(LG, cfg) end

return LG
