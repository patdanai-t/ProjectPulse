--[[
    ██████╗ ██╗   ██╗██╗     ███████╗███████╗██╗  ██╗
    ██╔══██╗██║   ██║██║     ██╔════╝██╔════╝╚██╗██╔╝
    ██████╔╝██║   ██║██║     ███████╗█████╗   ╚███╔╝
    ██╔═══╝ ██║   ██║██║     ╚════██║██╔══╝   ██╔██╗
    ██║     ╚██████╔╝███████╗███████║███████╗██╔╝ ██╗
    ╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
    
    PulseX UI Library v3.0.0
    Dark Red Professional Theme
    
    Usage:
        local PulseX = loadstring(game:HttpGet("..."))()
        local Window = PulseX:CreateWindow({ Title = "My Hub", Subtitle = "v1.0" })
        local Tab = Window:AddTab("Main")
        Tab:AddButton({ Title = "Click Me", Callback = function() print("clicked") end })
]]

local PulseX = {}
PulseX.__index = PulseX

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local COLORS = {
    Void       = Color3.fromRGB(2,  2,  10),
    Deep       = Color3.fromRGB(6,  6,  15),
    Surface    = Color3.fromRGB(12, 12, 26),
    Panel      = Color3.fromRGB(17, 17, 37),
    Card       = Color3.fromRGB(22, 22, 48),
    Raised     = Color3.fromRGB(28, 28, 56),
    Red1       = Color3.fromRGB(255, 10, 42),
    Red2       = Color3.fromRGB(200, 0,  30),
    Red3       = Color3.fromRGB(140, 0,  21),
    Red4       = Color3.fromRGB(64,  0,  10),
    RedGlow    = Color3.fromRGB(255, 10, 42),
    Green      = Color3.fromRGB(0,  221, 136),
    Blue       = Color3.fromRGB(68, 136, 255),
    Teal       = Color3.fromRGB(0,  229, 204),
    Gold       = Color3.fromRGB(255, 204, 68),
    Text1      = Color3.fromRGB(242, 242, 255),
    Text2      = Color3.fromRGB(136, 136, 170),
    Text3      = Color3.fromRGB(68,  68, 106),
    Border     = Color3.fromRGB(255, 10,  42),
    BorderSub  = Color3.fromRGB(50,  50,  80),
    White      = Color3.fromRGB(255, 255, 255),
}

local FONT       = Enum.Font.GothamBold
local FONT_REG   = Enum.Font.Gotham
local FONT_SEMI  = Enum.Font.GothamSemibold

local function Tween(obj, props, t, style, dir)
    local ti = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, ti, props):Play()
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function Corner(r)
    return New("UICorner", { CornerRadius = UDim.new(0, r or 6) })
end

local function Stroke(color, thickness, trans)
    return New("UIStroke", {
        Color       = color or COLORS.Border,
        Thickness   = thickness or 1,
        Transparency = trans or 0.6,
    })
end

local function Padding(t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft   = UDim.new(0, l or 10),
        PaddingRight  = UDim.new(0, r or 10),
    })
end

local function ListLayout(dir, pad, align)
    return New("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, pad or 6),
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
    })
end


function PulseX:CreateWindow(config)
    config = config or {}
    local Title    = config.Title    or "PulseX"
    local Subtitle = config.Subtitle or "v3.0.0"
    local Size     = config.Size     or UDim2.new(0, 620, 0, 440)

    local ScreenGui = New("ScreenGui", {
        Name            = "PulseX_" .. Title,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local LoadFrame = New("Frame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = COLORS.Void,
        BorderSizePixel = 0,
        ZIndex          = 100,
        Parent          = ScreenGui,
    })

    local LoadLogo = New("TextLabel", {
        Size             = UDim2.new(0, 300, 0, 50),
        Position         = UDim2.new(0.5, -150, 0.5, -80),
        BackgroundTransparency = 1,
        Text             = "PULSE" .. "X",
        TextColor3       = COLORS.Text1,
        Font             = FONT,
        TextSize         = 38,
        LetterSpacing    = 8,
        Parent           = LoadFrame,
    })

    local LoadSub = New("TextLabel", {
        Size             = UDim2.new(0, 300, 0, 20),
        Position         = UDim2.new(0.5, -150, 0.5, -30),
        BackgroundTransparency = 1,
        Text             = "PROFESSIONAL UI LIBRARY",
        TextColor3       = COLORS.Red1,
        Font             = FONT_REG,
        TextSize         = 10,
        LetterSpacing    = 4,
        Parent           = LoadFrame,
    })

    local TrackBg = New("Frame", {
        Size             = UDim2.new(0, 280, 0, 2),
        Position         = UDim2.new(0.5, -140, 0.5, 30),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel  = 0,
        Parent           = LoadFrame,
    }, { Corner(2) })

    local TrackFill = New("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.Red1,
        BorderSizePixel  = 0,
        Parent           = TrackBg,
    }, { Corner(2) })

    local PctLabel = New("TextLabel", {
        Size             = UDim2.new(0, 280, 0, 20),
        Position         = UDim2.new(0.5, -140, 0.5, 40),
        BackgroundTransparency = 1,
        Text             = "0%",
        TextColor3       = COLORS.Red1,
        Font             = FONT,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = LoadFrame,
    })

    local MsgLabel = New("TextLabel", {
        Size             = UDim2.new(0, 280, 0, 20),
        Position         = UDim2.new(0.5, -140, 0.5, 40),
        BackgroundTransparency = 1,
        Text             = "BOOT SEQUENCE",
        TextColor3       = COLORS.Text3,
        Font             = FONT_REG,
        TextSize         = 10,
        LetterSpacing    = 2,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = LoadFrame,
    })

    local loadMsgs = {"BOOT SEQUENCE","LOADING ASSETS","INIT COMPONENTS","APPLYING THEME","STARTING ENGINE","SYSTEM READY"}
    local pct = 0
    local loadConn
    loadConn = RunService.Heartbeat:Connect(function()
        pct = math.min(pct + math.random(3, 8), 100)
        local w = pct / 100
        Tween(TrackFill, { Size = UDim2.new(w, 0, 1, 0) }, 0.1)
        PctLabel.Text = math.floor(pct) .. "%"
        MsgLabel.Text = loadMsgs[math.min(math.floor(pct / 20) + 1, #loadMsgs)]
        if pct >= 100 then
            loadConn:Disconnect()
            task.wait(0.5)
            Tween(LoadFrame, { BackgroundTransparency = 1 }, 0.6, Enum.EasingStyle.Quart)
            task.wait(0.65)
            LoadFrame:Destroy()
        end
    end)

    local MainFrame = New("Frame", {
        Name             = "MainFrame",
        Size             = Size,
        Position         = UDim2.new(0.5, -310, 0.5, -220),
        BackgroundColor3 = COLORS.Void,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = ScreenGui,
    }, {
        Corner(8),
        Stroke(COLORS.Red3, 1, 0.4),
    })

    local TopBar = New("Frame", {
        Name             = "TopBar",
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = COLORS.Deep,
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        New("Frame", {
            Size             = UDim2.new(1, 0, 0, 8),
            Position         = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = COLORS.Deep,
            BorderSizePixel  = 0,
        }),
    })

    local TopAccent = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = COLORS.Red3,
        BorderSizePixel  = 0,
        Parent           = TopBar,
    })

    New("TextLabel", {
        Size             = UDim2.new(0, 200, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = "PULSE" .. "X  ·  " .. Title,
        TextColor3       = COLORS.Text1,
        Font             = FONT,
        TextSize         = 13,
        LetterSpacing    = 3,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = TopBar,
    })

    New("TextLabel", {
        Size             = UDim2.new(0, 200, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = Subtitle,
        TextColor3       = COLORS.Red1,
        Font             = FONT_REG,
        TextSize         = 10,
        LetterSpacing    = 2,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = TopBar,
    }):SetAttribute("offset", true)

    local SubLabel = New("TextLabel", {
        Size             = UDim2.new(1, -14, 1, 0),
        BackgroundTransparency = 1,
        Text             = Subtitle,
        TextColor3       = COLORS.Text3,
        Font             = FONT_REG,
        TextSize         = 10,
        LetterSpacing    = 2,
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = TopBar,
    })

    local CloseBtn = New("TextButton", {
        Size             = UDim2.new(0, 28, 0, 28),
        Position         = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = COLORS.Surface,
        Text             = "✕",
        TextColor3       = COLORS.Text3,
        Font             = FONT,
        TextSize         = 12,
        BorderSizePixel  = 0,
        Parent           = TopBar,
    }, {
        Corner(4),
        Stroke(COLORS.BorderSub, 1, 0.7),
    })

    local MinBtn = New("TextButton", {
        Size             = UDim2.new(0, 28, 0, 28),
        Position         = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = COLORS.Surface,
        Text             = "—",
        TextColor3       = COLORS.Text3,
        Font             = FONT,
        TextSize         = 12,
        BorderSizePixel  = 0,
        Parent           = TopBar,
    }, {
        Corner(4),
        Stroke(COLORS.BorderSub, 1, 0.7),
    })

    local minimized = false
    local normalSize = Size

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.new(0, Size.X.Offset, 0, 46) }, 0.3, Enum.EasingStyle.Quart)
        else
            Tween(MainFrame, { Size = normalSize }, 0.3, Enum.EasingStyle.Quart)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.31)
        ScreenGui:Destroy()
    end)

    for _, btn in ipairs({ CloseBtn, MinBtn }) do
        btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundColor3 = COLORS.Red4 }, 0.15)
            Tween(btn, { TextColor3 = COLORS.Red1 }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundColor3 = COLORS.Surface }, 0.15)
            Tween(btn, { TextColor3 = COLORS.Text3 }, 0.15)
        end)
    end

    MakeDraggable(MainFrame, TopBar)

    local Sidebar = New("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 148, 1, -46),
        Position         = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = COLORS.Deep,
        BorderSizePixel  = 0,
        Parent           = MainFrame,
    }, {
        New("Frame", {
            Size             = UDim2.new(0, 1, 1, 0),
            Position         = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = COLORS.Red3,
            BorderSizePixel  = 0,
        }),
    })

    local TabList = New("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -40),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = COLORS.Red3,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = Sidebar,
    }, {
        ListLayout(Enum.FillDirection.Vertical, 2),
        Padding(8, 0, 0, 0),
    })

    local SideFooter = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 38),
        Position         = UDim2.new(0, 0, 1, -38),
        BackgroundColor3 = COLORS.Void,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    }, {
        New("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = COLORS.BorderSub,
        }),
        New("TextLabel", {
            Size             = UDim2.new(1, -14, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text             = "● SYSTEM ONLINE",
            TextColor3       = COLORS.Green,
            Font             = FONT_REG,
            TextSize         = 9,
            LetterSpacing    = 1,
            TextXAlignment   = Enum.TextXAlignment.Left,
        }),
    })

    local ContentArea = New("ScrollingFrame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -148, 1, -46),
        Position         = UDim2.new(0, 148, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = COLORS.Red3,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = MainFrame,
    }, {
        Padding(12, 12, 14, 14),
        ListLayout(Enum.FillDirection.Vertical, 8),
    })

    local Window = { _tabs = {}, _activeTab = nil, _gui = ScreenGui, _content = ContentArea }

    function Window:AddTab(name, icon)
        local tabData = { _elements = {}, _frame = nil }

        local indicator = New("Frame", {
            Size             = UDim2.new(0, 2, 0, 0),
            Position         = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = COLORS.Red1,
            BorderSizePixel  = 0,
        }, { Corner(2) })

        local TabBtn = New("TextButton", {
            Size             = UDim2.new(1, -8, 0, 34),
            Position         = UDim2.new(0, 4, 0, 0),
            BackgroundColor3 = COLORS.Deep,
            BackgroundTransparency = 1,
            Text             = "",
            BorderSizePixel  = 0,
            Parent           = TabList,
        }, {
            Corner(5),
            indicator,
            New("TextLabel", {
                Size             = UDim2.new(1, -12, 1, 0),
                Position         = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text             = name,
                TextColor3       = COLORS.Text2,
                Font             = FONT_SEMI,
                TextSize         = 12,
                LetterSpacing    = 1,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }),
        })

        local TabFrame = New("Frame", {
            Name             = "Tab_" .. name,
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible          = false,
            BorderSizePixel  = 0,
            Parent           = ContentArea,
        }, {
            ListLayout(Enum.FillDirection.Vertical, 8),
        })

        tabData._frame = TabFrame
        tabData._btn   = TabBtn
        tabData._ind   = indicator

        local function activate()
            for _, t in ipairs(self._tabs) do
                t._frame.Visible = false
                Tween(t._btn, { BackgroundTransparency = 1 }, 0.15)
                Tween(t._btn:FindFirstChildOfClass("TextLabel"), { TextColor3 = COLORS.Text2 }, 0.15)
                Tween(t._ind, { Size = UDim2.new(0, 2, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
                Tween(t._ind, { BackgroundTransparency = 0 }, 0.15)
            end
            TabFrame.Visible = true
            Tween(TabBtn, { BackgroundTransparency = 0.93 }, 0.15)
            local lbl = TabBtn:FindFirstChildOfClass("TextLabel")
            if lbl then Tween(lbl, { TextColor3 = COLORS.Text1 }, 0.15) end
            Tween(indicator, { Size = UDim2.new(0, 2, 0.6, 0) }, 0.25, Enum.EasingStyle.Quart)
            self._activeTab = tabData
        end

        TabBtn.MouseButton1Click:Connect(activate)
        TabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn, { BackgroundTransparency = 0.97 }, 0.15)
                local lbl = TabBtn:FindFirstChildOfClass("TextLabel")
                if lbl then Tween(lbl, { TextColor3 = COLORS.Text1 }, 0.15) end
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn, { BackgroundTransparency = 1 }, 0.15)
                local lbl = TabBtn:FindFirstChildOfClass("TextLabel")
                if lbl then Tween(lbl, { TextColor3 = COLORS.Text2 }, 0.15) end
            end
        end)

        table.insert(self._tabs, tabData)
        if #self._tabs == 1 then activate() end

        local Tab = {}

        function Tab:AddSection(title)
            local sec = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                ListLayout(Enum.FillDirection.Vertical, 6),
            })

            local header = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                Parent           = sec,
            })
            New("TextLabel", {
                Size             = UDim2.new(0, 0, 1, 0),
                AutomaticSize    = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text             = string.upper(title),
                TextColor3       = COLORS.Red1,
                Font             = FONT,
                TextSize         = 9,
                LetterSpacing    = 4,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = header,
            })
            New("Frame", {
                Size             = UDim2.new(1, -80, 0, 1),
                Position         = UDim2.new(0, 80, 0.5, 0),
                BackgroundColor3 = COLORS.BorderSub,
                BorderSizePixel  = 0,
                Parent           = header,
            })

            return sec
        end

        function Tab:AddButton(cfg)
            cfg = cfg or {}
            local lbl = cfg.Title or "Button"
            local desc = cfg.Description or ""
            local cb   = cfg.Callback or function() end

            local btn = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, desc ~= "" and 52 or 38),
                BackgroundColor3 = COLORS.Card,
                Text             = "",
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(COLORS.BorderSub, 1, 0.7),
            })

            New("TextLabel", {
                Size             = UDim2.new(1, -50, 0, 20),
                Position         = UDim2.new(0, 14, 0, desc ~= "" and 8 or 9),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = COLORS.Text1,
                Font             = FONT_SEMI,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = btn,
            })

            if desc ~= "" then
                New("TextLabel", {
                    Size             = UDim2.new(1, -50, 0, 16),
                    Position         = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text             = desc,
                    TextColor3       = COLORS.Text3,
                    Font             = FONT_REG,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = btn,
                })
            end

            local arrow = New("TextLabel", {
                Size             = UDim2.new(0, 30, 1, 0),
                Position         = UDim2.new(1, -36, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▶",
                TextColor3       = COLORS.Red1,
                Font             = FONT,
                TextSize         = 10,
                Parent           = btn,
            })

            btn.MouseEnter:Connect(function()
                Tween(btn, { BackgroundColor3 = COLORS.Raised }, 0.15)
                Tween(btn:FindFirstChildOfClass("UIStroke"), { Transparency = 0.4 }, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, { BackgroundColor3 = COLORS.Card }, 0.15)
                Tween(btn:FindFirstChildOfClass("UIStroke"), { Transparency = 0.7 }, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, { BackgroundColor3 = COLORS.Red4 }, 0.1)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, { BackgroundColor3 = COLORS.Raised }, 0.1)
                task.spawn(cb)
            end)

            return btn
        end

        function Tab:AddToggle(cfg)
            cfg = cfg or {}
            local lbl  = cfg.Title or "Toggle"
            local desc = cfg.Description or ""
            local def  = cfg.Default or false
            local cb   = cfg.Callback or function() end

            local state = def
            local row = New("Frame", {
                Size             = UDim2.new(1, 0, 0, desc ~= "" and 52 or 38),
                BackgroundColor3 = COLORS.Card,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(COLORS.BorderSub, 1, 0.7),
            })

            New("TextLabel", {
                Size             = UDim2.new(1, -70, 0, 20),
                Position         = UDim2.new(0, 14, 0, desc ~= "" and 8 or 9),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = COLORS.Text1,
                Font             = FONT_SEMI,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = row,
            })
            if desc ~= "" then
                New("TextLabel", {
                    Size             = UDim2.new(1, -70, 0, 16),
                    Position         = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text             = desc,
                    TextColor3       = COLORS.Text3,
                    Font             = FONT_REG,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
            end

            local track = New("Frame", {
                Size             = UDim2.new(0, 40, 0, 22),
                Position         = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = state and COLORS.Red2 or COLORS.Surface,
                BorderSizePixel  = 0,
                Parent           = row,
            }, {
                Corner(11),
                Stroke(state and COLORS.Red2 or COLORS.BorderSub, 1, state and 0.6 or 0.5),
            })

            local knob = New("Frame", {
                Size             = UDim2.new(0, 16, 0, 16),
                Position         = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = state and COLORS.White or COLORS.Text3,
                BorderSizePixel  = 0,
                Parent           = track,
            }, { Corner(9) })

            local clickBtn = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                BorderSizePixel  = 0,
                Parent           = row,
            })

            local function setToggle(val)
                state = val
                Tween(track, { BackgroundColor3 = state and COLORS.Red2 or COLORS.Surface }, 0.2)
                Tween(knob,  { Position = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.2, Enum.EasingStyle.Quart)
                Tween(knob,  { BackgroundColor3 = state and COLORS.White or COLORS.Text3 }, 0.2)
                local stroke = track:FindFirstChildOfClass("UIStroke")
                if stroke then
                    Tween(stroke, { Color = state and COLORS.Red2 or COLORS.BorderSub }, 0.2)
                    Tween(stroke, { Transparency = state and 0.6 or 0.5 }, 0.2)
                end
                task.spawn(cb, state)
            end

            clickBtn.MouseButton1Click:Connect(function() setToggle(not state) end)
            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = COLORS.Raised }, 0.15) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = COLORS.Card  }, 0.15) end)

            return { Set = setToggle, Get = function() return state end }
        end

        function Tab:AddSlider(cfg)
            cfg = cfg or {}
            local lbl = cfg.Title or "Slider"
            local desc = cfg.Description or ""
            local min  = cfg.Min or 0
            local max  = cfg.Max or 100
            local def  = cfg.Default or min
            local suf  = cfg.Suffix or ""
            local cb   = cfg.Callback or function() end

            local value = math.clamp(def, min, max)
            local dragging = false

            local container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, desc ~= "" and 68 or 56),
                BackgroundColor3 = COLORS.Card,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(COLORS.BorderSub, 1, 0.7),
            })

            local titleLbl = New("TextLabel", {
                Size             = UDim2.new(1, -80, 0, 18),
                Position         = UDim2.new(0, 14, 0, 10),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = COLORS.Text1,
                Font             = FONT_SEMI,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = container,
            })

            local valLbl = New("TextLabel", {
                Size             = UDim2.new(0, 70, 0, 18),
                Position         = UDim2.new(1, -80, 0, 10),
                BackgroundTransparency = 1,
                Text             = tostring(value) .. suf,
                TextColor3       = COLORS.Red1,
                Font             = FONT,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Parent           = container,
            })

            if desc ~= "" then
                New("TextLabel", {
                    Size             = UDim2.new(1, -28, 0, 14),
                    Position         = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text             = desc,
                    TextColor3       = COLORS.Text3,
                    Font             = FONT_REG,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = container,
                })
            end

            local trackY  = desc ~= "" and 50 or 38
            local trackBg = New("Frame", {
                Size             = UDim2.new(1, -28, 0, 3),
                Position         = UDim2.new(0, 14, 0, trackY),
                BackgroundColor3 = COLORS.Surface,
                BorderSizePixel  = 0,
                Parent           = container,
            }, {
                Corner(2),
                Stroke(COLORS.BorderSub, 1, 0.8),
            })

            local pct0 = (value - min) / (max - min)
            local fill = New("Frame", {
                Size             = UDim2.new(pct0, 0, 1, 0),
                BackgroundColor3 = COLORS.Red2,
                BorderSizePixel  = 0,
                Parent           = trackBg,
            }, { Corner(2) })

            local nub = New("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = UDim2.new(pct0, -6, 0.5, -6),
                BackgroundColor3 = COLORS.Red1,
                BorderSizePixel  = 0,
                Parent           = trackBg,
            }, {
                Corner(6),
                Stroke(COLORS.Red3, 1, 0.4),
            })

            local function updateSlider(inputX)
                local abs = trackBg.AbsolutePosition
                local sz  = trackBg.AbsoluteSize
                local rel = math.clamp((inputX - abs.X) / sz.X, 0, 1)
                value = math.floor(min + rel * (max - min) + 0.5)
                local p = (value - min) / (max - min)
                Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.05)
                Tween(nub,  { Position = UDim2.new(p, -6, 0.5, -6) }, 0.05)
                valLbl.Text = tostring(value) .. suf
                task.spawn(cb, value)
            end

            local clickArea = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = trackBg,
            })
            clickArea.MouseButton1Down:Connect(function()
                dragging = true
                updateSlider(Mouse.X)
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(Mouse.X)
                end
            end)
            container.MouseEnter:Connect(function() Tween(container, { BackgroundColor3 = COLORS.Raised }, 0.15) end)
            container.MouseLeave:Connect(function() Tween(container, { BackgroundColor3 = COLORS.Card  }, 0.15) end)

            return {
                Set = function(v)
                    value = math.clamp(v, min, max)
                    local p = (value - min) / (max - min)
                    Tween(fill, { Size = UDim2.new(p, 0, 1, 0) }, 0.2)
                    Tween(nub,  { Position = UDim2.new(p, -6, 0.5, -6) }, 0.2)
                    valLbl.Text = tostring(value) .. suf
                end,
                Get = function() return value end,
            }
        end

        function Tab:AddDropdown(cfg)
            cfg = cfg or {}
            local lbl     = cfg.Title or "Dropdown"
            local opts    = cfg.Options or {}
            local def     = cfg.Default or opts[1] or ""
            local cb      = cfg.Callback or function() end
            local selected = def
            local open     = false

            local container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = COLORS.Card,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
                ZIndex           = 2,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(COLORS.BorderSub, 1, 0.7),
            })

            New("TextLabel", {
                Size             = UDim2.new(0.55, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = COLORS.Text1,
                Font             = FONT_SEMI,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = container,
            })

            local selLabel = New("TextLabel", {
                Size             = UDim2.new(0.35, 0, 1, 0),
                Position         = UDim2.new(0.55, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = selected,
                TextColor3       = COLORS.Red1,
                Font             = FONT_SEMI,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Parent           = container,
            })

            New("TextLabel", {
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -22, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = COLORS.Text3,
                Font             = FONT,
                TextSize         = 12,
                Parent           = container,
            })

            local dropList = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 10,
                Visible          = false,
                Parent           = container,
            }, {
                Corner(6),
                Stroke(COLORS.Red3, 1, 0.5),
                ListLayout(Enum.FillDirection.Vertical, 2),
                Padding(4, 4, 4, 4),
            })

            for _, opt in ipairs(opts) do
                local optBtn = New("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = COLORS.Panel,
                    Text             = opt,
                    TextColor3       = COLORS.Text2,
                    Font             = FONT_REG,
                    TextSize         = 12,
                    BorderSizePixel  = 0,
                    ZIndex           = 11,
                    Parent           = dropList,
                }, { Corner(4) })
                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, { BackgroundColor3 = COLORS.Red4 }, 0.1)
                    Tween(optBtn, { TextColor3 = COLORS.Text1 }, 0.1)
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, { BackgroundColor3 = COLORS.Panel }, 0.1)
                    Tween(optBtn, { TextColor3 = COLORS.Text2 }, 0.1)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    selLabel.Text = selected
                    open = false
                    Tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
                    task.wait(0.21)
                    dropList.Visible = false
                    task.spawn(cb, selected)
                end)
            end

            local totalH = #opts * 30 + 8

            local clickBtn = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = container,
            })
            clickBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    dropList.Visible = true
                    Tween(dropList, { Size = UDim2.new(1, 0, 0, totalH) }, 0.25, Enum.EasingStyle.Quart)
                else
                    Tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
                    task.wait(0.21)
                    dropList.Visible = false
                end
            end)

            return {
                Set = function(v) selected = v; selLabel.Text = v end,
                Get = function() return selected end,
                Refresh = function(newOpts)
                    for _, c in ipairs(dropList:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    opts = newOpts
                end,
            }
        end

        function Tab:AddTextbox(cfg)
            cfg = cfg or {}
            local lbl  = cfg.Title or "Input"
            local ph   = cfg.Placeholder or "Type here..."
            local def  = cfg.Default or ""
            local cb   = cfg.Callback or function() end
            local nums = cfg.NumbersOnly or false

            local container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = COLORS.Card,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(COLORS.BorderSub, 1, 0.7),
            })

            New("TextLabel", {
                Size             = UDim2.new(1, -14, 0, 18),
                Position         = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Text             = lbl,
                TextColor3       = COLORS.Text1,
                Font             = FONT_SEMI,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = container,
            })

            local box = New("TextBox", {
                Size             = UDim2.new(1, -28, 0, 22),
                Position         = UDim2.new(0, 14, 0, 28),
                BackgroundColor3 = COLORS.Surface,
                Text             = def,
                PlaceholderText  = ph,
                PlaceholderColor3 = COLORS.Text3,
                TextColor3       = COLORS.Text1,
                Font             = FONT_REG,
                TextSize         = 12,
                BorderSizePixel  = 0,
                ClearTextOnFocus = false,
                Parent           = container,
            }, {
                Corner(4),
                Stroke(COLORS.BorderSub, 1, 0.6),
                Padding(0, 0, 8, 8),
            })

            box.Focused:Connect(function()
                Tween(box:FindFirstChildOfClass("UIStroke"), { Color = COLORS.Red1, Transparency = 0.4 }, 0.15)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(box:FindFirstChildOfClass("UIStroke"), { Color = COLORS.BorderSub, Transparency = 0.6 }, 0.15)
                if enter then task.spawn(cb, box.Text) end
            end)
            container.MouseEnter:Connect(function() Tween(container, { BackgroundColor3 = COLORS.Raised }, 0.15) end)
            container.MouseLeave:Connect(function() Tween(container, { BackgroundColor3 = COLORS.Card  }, 0.15) end)

            return {
                Get = function() return box.Text end,
                Set = function(v) box.Text = v end,
            }
        end

        function Tab:AddLabel(text, color)
            local lbl = New("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text             = text or "",
                TextColor3       = color or COLORS.Text2,
                Font             = FONT_REG,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
                Parent           = TabFrame,
            })
            return { Set = function(t) lbl.Text = t end, SetColor = function(c) lbl.TextColor3 = c end }
        end

        function Tab:AddDivider()
            New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = COLORS.BorderSub,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            })
        end

        function Tab:AddNotification(cfg)
            cfg = cfg or {}
            local title = cfg.Title or "Notice"
            local msg   = cfg.Message or ""
            local ntype = cfg.Type or "info"

            local cols = {
                error   = { bg = Color3.fromRGB(40, 5, 12),  border = COLORS.Red1,   text = COLORS.Red1   },
                success = { bg = Color3.fromRGB(5,  36, 22), border = COLORS.Green,  text = COLORS.Green  },
                info    = { bg = Color3.fromRGB(8,  18, 42), border = COLORS.Blue,   text = COLORS.Blue   },
                warn    = { bg = Color3.fromRGB(36, 28, 5),  border = COLORS.Gold,   text = COLORS.Gold   },
            }
            local c = cols[ntype] or cols.info

            local notif = New("Frame", {
                Size             = UDim2.new(1, 0, 0, msg ~= "" and 52 or 34),
                BackgroundColor3 = c.bg,
                BorderSizePixel  = 0,
                Parent           = TabFrame,
            }, {
                Corner(6),
                Stroke(c.border, 1, 0.5),
            })

            New("TextLabel", {
                Size             = UDim2.new(1, -28, 0, 18),
                Position         = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Text             = title,
                TextColor3       = c.text,
                Font             = FONT_SEMI,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = notif,
            })

            if msg ~= "" then
                New("TextLabel", {
                    Size             = UDim2.new(1, -28, 0, 16),
                    Position         = UDim2.new(0, 14, 0, 28),
                    BackgroundTransparency = 1,
                    Text             = msg,
                    TextColor3       = COLORS.Text2,
                    Font             = FONT_REG,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = notif,
                })
            end

            return notif
        end

        return Tab
    end

    function Window:Notify(cfg)
        cfg = cfg or {}
        local title    = cfg.Title    or "PulseX"
        local content  = cfg.Content  or ""
        local duration = cfg.Duration or 4
        local ntype    = cfg.Type     or "info"

        local cols = {
            error   = { border = COLORS.Red1,  accent = COLORS.Red1   },
            success = { border = COLORS.Green,  accent = COLORS.Green  },
            info    = { border = COLORS.Blue,   accent = COLORS.Blue   },
            warn    = { border = COLORS.Gold,   accent = COLORS.Gold   },
        }
        local c = cols[ntype] or cols.info

        local nframe = New("Frame", {
            Size             = UDim2.new(0, 280, 0, 70),
            Position         = UDim2.new(1, -290, 1, 80),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel  = 0,
            Parent           = ScreenGui,
        }, {
            Corner(8),
            Stroke(c.border, 1, 0.4),
            New("Frame", {
                Size             = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = c.accent,
                BorderSizePixel  = 0,
            }, { Corner(2) }),
            New("TextLabel", {
                Size             = UDim2.new(1, -22, 0, 22),
                Position         = UDim2.new(0, 14, 0, 10),
                BackgroundTransparency = 1,
                Text             = title,
                TextColor3       = c.accent,
                Font             = FONT_SEMI,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }),
            New("TextLabel", {
                Size             = UDim2.new(1, -22, 0, 28),
                Position         = UDim2.new(0, 14, 0, 32),
                BackgroundTransparency = 1,
                Text             = content,
                TextColor3       = COLORS.Text2,
                Font             = FONT_REG,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
            }),
        })

        Tween(nframe, { Position = UDim2.new(1, -290, 1, -80) }, 0.4, Enum.EasingStyle.Quart)
        task.delay(duration, function()
            Tween(nframe, { Position = UDim2.new(1, 10, 1, -80) }, 0.4, Enum.EasingStyle.Quart)
            task.wait(0.45)
            nframe:Destroy()
        end)
    end

    return Window
end

return PulseX
