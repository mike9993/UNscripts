-- ============================================================
--  Fling Plugin for UNScripts Host UI
--  Load AFTER 1 UNScripts_Secondary_UI.lua
--  Creates fling UI in MainPage + ModsPage overlay via ⚡ icon
-- ============================================================

-- Wait for host to be ready
repeat task.wait() until _G.UNScripts_Secondary and _G.UNScripts_Secondary.MainPage

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local rgb  = Color3.fromRGB
local ud2  = UDim2.new
local ud   = UDim.new
local bold = Enum.Font.GothamBold
local reg  = Enum.Font.Gotham

-- Access host UI elements and utilities
local host = _G.UNScripts_Secondary
local C = host.C

-- Clear the main page
for _, c in pairs(host.MainPage:GetChildren()) do c:Destroy() end
local Make = host.Make

-- ── Fling State ──
local SelectedTargets    = {}
local PlayerCheckboxes   = {}
local FlingActive        = false
local FlingMode          = nil
local SpectatingTarget   = nil
local GhostPart          = nil
local SavedCFrame        = nil
getgenv().OldPos         = nil
getgenv().FPDH           = workspace.FallenPartsDestroyHeight

local cfg = {
    ghost    = false,
    safe     = true,
    dir      = "RANDOM",
    power    = 1,
    autoSel  = false,
}

local flingColorOnce = rgb(50, 120, 255)
local flingColorLoop = rgb(0, 160, 80)
local flingColorStop = rgb(220, 80, 70)

-- ── Status ──
local StatusLabel = Make("TextLabel", {
    Size = ud2(1,-24,0,18), Position = ud2(0,12,0,6),
    BackgroundTransparency = 1, Text = "Select targets to fling",
    TextColor3 = Color3.fromRGB(115, 115, 128), Font = reg, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = host.MainPage,
})

-- ── Player List ──
local PlayerFrame = Make("Frame", {
    Size = ud2(1,-24,1,-144), Position = ud2(0,12,0,26),
    BackgroundColor3 = C.surface, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = host.MainPage,
})
Make("UICorner", {CornerRadius = ud(0,12), Parent = PlayerFrame})

local PlayerScroll = Make("ScrollingFrame", {
    Size = ud2(1,-8,1,-8), Position = ud2(0,4,0,4),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = PlayerFrame,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,3), Parent = PlayerScroll})

-- ── Helpers ──
local function countSelected()
    local n = 0; for _ in pairs(SelectedTargets) do n = n + 1 end; return n
end

local function updateStatus()
    local c = countSelected()
    if FlingActive then
        StatusLabel.Text = "Flinging " .. c .. " target(s)" .. (FlingMode=="once" and " (once)" or " (loop)")
        StatusLabel.TextColor3 = rgb(220, 80, 70)
    else
        StatusLabel.Text = c .. " target(s) selected"
        StatusLabel.TextColor3 = Color3.fromRGB(115, 115, 128)
    end
end

local function getPlrStatus(plr)
    local c = plr.Character
    if not c then return "dead" end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return "dead" end
    if c:FindFirstChildOfClass("ForceField") then return "forcefield" end
    if h.Sit then return "seated" end
    return "alive"
end

local function setSelection(plr, state)
    if not plr then return end
    if state then SelectedTargets[plr.Name] = plr else SelectedTargets[plr.Name] = nil end
    if PlayerCheckboxes[plr.Name] then PlayerCheckboxes[plr.Name].ck.Visible = state end
    if plr.Character then
        local hl = plr.Character:FindFirstChild("FlingTargetESP")
        if state then
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "FlingTargetESP"
                hl.FillColor = rgb(255,0,0)
                hl.OutlineColor = rgb(255,255,255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.2
                hl.Parent = plr.Character
            end
        else
            if hl then hl:Destroy() end
        end
    end
    updateStatus()
end

_G.UNFling_SelectPlayer = function(plrName)
    local plr = Players:FindFirstChild(plrName)
    if plr and plr ~= LocalPlayer then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then setSelection(p, false) end
        end
        setSelection(plr, true)
    end
end

local function refreshPlayers()
    for _, c in pairs(PlayerScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    PlayerCheckboxes = {}
    local list = Players:GetPlayers()
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)
    for _, plr in ipairs(list) do
        if plr ~= LocalPlayer then
            local entry = Make("Frame", {
                Size = ud2(1,-8,0,30), BackgroundColor3 = C.surfaceAlt,
                BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = PlayerScroll,
            })
            Make("UICorner", {CornerRadius = ud(0,6), Parent = entry})
            local cb = Make("Frame", {
                Size = ud2(0,18,0,18), Position = ud2(0,8,0,6),
                BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = entry,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = cb})
            Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = cb})
            local ck = Make("TextLabel", {
                Size = ud2(1,0,1,0), BackgroundTransparency = 1,
                Text = "✓", TextColor3 = rgb(60,180,90), TextSize = 13,
                Font = bold, Visible = SelectedTargets[plr.Name] ~= nil, Parent = cb,
            })
            local avatar = Make("ImageLabel", {
                Size = ud2(0,24,0,24), Position = ud2(0,29,0,3),
                BackgroundColor3 = C.bg, BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48",
                Parent = entry,
            })
            Make("UICorner", {CornerRadius = ud(0,6), Parent = avatar})
            Make("TextLabel", {
                Size = ud2(1,-80,1,0), Position = ud2(0,58,0,0),
                BackgroundTransparency = 1, Text = plr.Name,
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = entry,
            })
            local st = getPlrStatus(plr)
            local sc = st=="dead" and rgb(220,80,70) or st=="seated" and rgb(255,215,0) or st=="forcefield" and rgb(70,130,220) or rgb(60,180,90)
            local dot = Make("Frame", {
                Size = ud2(0,7,0,7), Position = ud2(1,-44,0,12),
                BackgroundColor3 = sc, BorderSizePixel = 0, Parent = entry,
            })
            Make("UICorner", {CornerRadius = ud(1,0), Parent = dot})
            local eye = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(1,-26,0,4),
                BackgroundTransparency = 1, Text = "👁",
                TextColor3 = C.textSec, TextSize = 11, Font = reg, Parent = entry,
            })
            eye.MouseButton1Click:Connect(function()
                if SpectatingTarget == plr then
                    SpectatingTarget = nil
                    local lc = LocalPlayer.Character; local lh = lc and lc:FindFirstChildOfClass("Humanoid")
                    if lh then workspace.CurrentCamera.CameraSubject = lh end
                    eye.TextColor3 = C.textSec
                else
                    SpectatingTarget = plr
                    local tc = plr.Character; local th = tc and tc:FindFirstChildOfClass("Humanoid")
                    if th then workspace.CurrentCamera.CameraSubject = th end
                    eye.TextColor3 = C.accent
                end
            end)
            local hit = Make("TextButton", {
                Size = ud2(1,-32,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = entry,
            })
            local lastClick = 0
            hit.MouseButton1Click:Connect(function()
                local t = tick()
                if t - lastClick < 0.25 then
                    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setSelection(p, false) end end
                    setSelection(plr, true); lastClick = 0
                else
                    setSelection(plr, SelectedTargets[plr.Name] == nil); lastClick = t
                end
            end)
            PlayerCheckboxes[plr.Name] = { entry=entry, ck=ck, dot=dot, eye=eye }
        end
    end
end

-- ── Buttons ──
local BtnFrame = Make("Frame", {
    Size = ud2(1,-24,0,112), Position = ud2(0,12,1,-112),
    BackgroundTransparency = 1, Parent = host.MainPage,
})

local SelAll = Make("TextButton", {
    Size = ud2(0.5,-3,0,28), Position = ud2(0,0,0,0),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "SELECT ALL", TextColor3 = C.textPri,
    Font = bold, TextSize = 10, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = SelAll})

local DeselAll = Make("TextButton", {
    Size = ud2(0.5,-3,0,28), Position = ud2(0.5,3,0,0),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "DESELECT ALL", TextColor3 = C.textPri,
    Font = bold, TextSize = 10, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = DeselAll})

local NearBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,28), Position = ud2(0,0,0,32),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "SELECT NEAREST", TextColor3 = C.textPri,
    Font = bold, TextSize = 10, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = NearBtn})

-- Auto Select
local AutoFrame = Make("Frame", {
    Size = ud2(0.5,-3,0,28), Position = ud2(0.5,3,0,32),
    BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = AutoFrame})
Make("TextLabel", {
    Size = ud2(1,-36,1,0), Position = ud2(0,10,0,0),
    BackgroundTransparency = 1, Text = "Auto Select",
    TextColor3 = C.textPri, TextSize = 10, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = AutoFrame,
})
local AutoTrack = Make("Frame", {
    Size = ud2(0,28,0,14), Position = ud2(1,-32,0,7),
    BackgroundColor3 = C.toggle_off, BorderSizePixel = 0, Parent = AutoFrame,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = AutoTrack})
local AutoKnob = Make("Frame", {
    Size = ud2(0,10,0,10), Position = ud2(0,2,0,2),
    BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = AutoTrack,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = AutoKnob})
local AutoHit = Make("TextButton", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = AutoTrack,
})

-- Fling buttons
local OnceBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,34), Position = ud2(0,0,0,70),
    BackgroundColor3 = flingColorOnce, BackgroundTransparency = 0.05,
    Text = "FLING ONCE", TextColor3 = rgb(255,255,255),
    Font = bold, TextSize = 12, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = OnceBtn})

local LoopBtn = Make("TextButton", {
    Size = ud2(0.5,-3,0,34), Position = ud2(0.5,3,0,70),
    BackgroundColor3 = flingColorLoop, BackgroundTransparency = 0.05,
    Text = "FLING LOOP", TextColor3 = rgb(255,255,255),
    Font = bold, TextSize = 12, Parent = BtnFrame,
})
Make("UICorner", {CornerRadius = ud(0,10), Parent = LoopBtn})

-- ── ModsPage Overlay ──
-- Accessed via ⚡ icon in host header; contains modifiers + settings
local ModsPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, Visible = false, ClipsDescendants = true,
    Parent = host.Main,
})

-- Back button
local BackBtn = Make("TextButton", {
    Size = ud2(0,56,0,24), Position = ud2(0,10,0,8),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "< BACK", TextColor3 = C.textPri,
    TextSize = 10, Font = bold, Parent = ModsPage,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = BackBtn})

-- Title
Make("TextLabel", {
    Size = ud2(1,0,0,24),
    BackgroundTransparency = 1, Text = "⚡ Modifiers",
    TextColor3 = C.textPri, TextSize = 13, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = ModsPage,
})

-- Scroll area for settings
local ModsScroll = Make("ScrollingFrame", {
    Size = ud2(1,-16,1,-48), Position = ud2(0,8,0,44),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = ModsPage,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,6), Parent = ModsScroll})

-- Populate ModsPage using settings-style component factories

local function mkTgl(label, getter, setter)
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,32), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("TextLabel", {
        Size = ud2(1,-80,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })
    local track = Make("Frame", {
        Size = ud2(0,38,0,20), Position = ud2(1,-48,0,6),
        BackgroundColor3 = getter() and C.toggle_on or C.toggle_off,
        BorderSizePixel = 0, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
    Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.82, Parent = track})
    local knob = Make("Frame", {
        Size = ud2(0,16,0,16), Position = getter() and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8),
        BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
    Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.72, Parent = knob})
    local isOn = getter()
    local hit = Make("TextButton", {
        Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = track,
    })
    hit.MouseButton1Click:Connect(function()
        isOn = not isOn; setter(isOn)
        TweenService:Create(knob, TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Position = isOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8)}):Play()
        TweenService:Create(track, TweenInfo.new(0.2,Enum.EasingStyle.Linear), {BackgroundColor3 = isOn and C.toggle_on or C.toggle_off}):Play()
    end)
end

local function mkDropdown(label, options, defaultVal, callback)
    local isOpen = false
    local val = defaultVal or options[1]
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,32), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("TextLabel", {
        Size = ud2(0,120,0,32), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })
    local valDisplay = Make("TextButton", {
        Size = ud2(0,90,0,22), Position = ud2(1,-100,0,5),
        BackgroundColor3 = C.surface, BackgroundTransparency = 0,
        Text = tostring(val) .. " ▼", TextColor3 = C.textPri,
        TextSize = 10, Font = bold, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(0,4), Parent = valDisplay})
    local dropFrame = Make("Frame", {
        Size = ud2(1,-16,0,0), Position = ud2(0,4,0,0), BackgroundColor3 = C.surface,
        BackgroundTransparency = 0, BorderSizePixel = 0,
        Visible = false, Parent = ModsScroll,
    })
    Make("UICorner", {CornerRadius = ud(0,8), Parent = dropFrame})
    Make("UIStroke", {Color = C.border, Thickness = 1, Parent = dropFrame})
    Make("UIPadding", {PaddingTop = ud(0,4), PaddingBottom = ud(0,4), PaddingLeft = ud(0,14), PaddingRight = ud(0,14), Parent = dropFrame})
    local list = Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,2), Parent = dropFrame})
    local function updateSize()
        if isOpen then
            local ch = list.AbsoluteContentSize.Y
            dropFrame.Size = ud2(1,-16,0,ch + 8)
            dropFrame.Visible = true
        else
            dropFrame.Visible = false
            dropFrame.Size = ud2(1,-16,0,0)
        end
    end
    for _, opt in ipairs(options) do
        local oBtn = Make("TextButton", {
            Size = ud2(1,0,0,22), BackgroundColor3 = C.surface, BackgroundTransparency = 0.2,
            Text = tostring(opt), TextColor3 = C.textSec, TextSize = 10, Font = reg,
            Parent = dropFrame,
        })
        Make("UICorner", {CornerRadius = ud(0,4), Parent = oBtn})
        oBtn.MouseButton1Click:Connect(function()
            val = opt; valDisplay.Text = tostring(val) .. " ▼"; isOpen = false; updateSize()
            if callback then callback(val) end
        end)
    end
    valDisplay.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        valDisplay.Text = tostring(val) .. (isOpen and " ▲" or " ▼")
        updateSize()
    end)
end

local function mkSlider(label, getter, setter, minV, maxV, suffix)
    suffix = suffix or "x"
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,45), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ModsScroll,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("TextLabel", {
        Size = ud2(0,120,0,20), Position = ud2(0,14,0,6),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })
    local valLabel = Make("TextLabel", {
        Size = ud2(0,36,0,20), Position = ud2(1,-50,0,6),
        BackgroundTransparency = 1, Text = getter() .. suffix,
        TextColor3 = C.textSec, TextSize = 10, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = pill,
    })
    local track = Make("Frame", {
        Size = ud2(1,-28,0,6), Position = ud2(0,14,0,32),
        BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
    local initF = (getter() - minV) / (maxV - minV)
    local fill = Make("Frame", {
        Size = ud2(initF,0,1,0), BackgroundColor3 = C.accent,
        BackgroundTransparency = 0, BorderSizePixel = 0, Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = fill})
    local knob = Make("TextButton", {
        Size = ud2(0,14,0,14), Position = ud2(initF,-7,0,-4),
        BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "", Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
    Make("UIStroke", {Color = rgb(80,80,80), Thickness = 1, Transparency = 0.3, Parent = knob})
    local dragging = false
    local function update(x)
        local f = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        TweenService:Create(fill, TweenInfo.new(0.08), {Size = ud2(f,0,1,0)}):Play()
        knob.Position = ud2(f,-7,0,-4)
        local v = math.floor(minV + f * (maxV - minV) + 0.5)
        valLabel.Text = v .. suffix; setter(v)
    end
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    Make("TextButton", {
        Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
        BackgroundTransparency = 1, Text = "", ZIndex = knob.ZIndex - 1, Parent = track,
    }).InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; update(i.Position.X) end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and dragging then dragging = false end
    end)
    local movConn = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i.Position.X) end
    end)
    pill.Destroying:Connect(function() endConn:Disconnect(); movConn:Disconnect() end)
end

mkTgl("Ghost / Invisible Fling", function() return cfg.ghost end, function(v) cfg.ghost = v end)
mkTgl("Safe-Return (Blink Back)", function() return cfg.safe end, function(v) cfg.safe = v end)
mkSlider("Velocity Multiplier", function() return cfg.power end, function(v) cfg.power = v end, 1, 10, "x")
mkDropdown("Fling Direction", {"RANDOM","UP","DOWN"}, cfg.dir, function(v) cfg.dir = v end)

-- Lightning icon in host header
local ModsBtn = host.makeHeaderIcon(-108, "⚡")
ModsBtn.MouseButton1Click:Connect(function()
    local showing = not ModsPage.Visible
    if showing then
        for _, c in ipairs(host.Main:GetChildren()) do
            if c:IsA("Frame") and c ~= host.MainPage and c ~= ModsPage and c.Visible and c.Size == ud2(1,0,1,-42) and c.Position == ud2(0,0,0,42) then
                c.Visible = false
            end
        end
    end
    ModsPage.Visible = showing
    host.MainPage.Visible = not showing
    ModsBtn.TextColor3 = showing and C.accent or C.textSec
end)

BackBtn.MouseButton1Click:Connect(function()
    ModsPage.Visible = false
    host.MainPage.Visible = true
    ModsBtn.TextColor3 = C.textSec
end)

-- ── Security ──
local function enableSec()
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
    if not c:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = c
    end
    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

local function disableSec()
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    h:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    local ff = c:FindFirstChildOfClass("ForceField"); if ff then ff:Destroy() end
end

local function mkGhost()
    if GhostPart then GhostPart:Destroy() end
    local c = LocalPlayer.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    SavedCFrame = r.CFrame
    GhostPart = Instance.new("Part")
    GhostPart.Size = Vector3.new(1,1,1); GhostPart.Anchored = true
    GhostPart.CanCollide = false; GhostPart.Transparency = 1
    GhostPart.Position = r.Position; GhostPart.Parent = workspace
end

local function killGhost()
    if GhostPart then GhostPart:Destroy(); GhostPart = nil end
end

-- ── Fling Core ──
local function skid(tPlr)
    local c = LocalPlayer.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = h and h.RootPart; local tc = tPlr.Character
    if not tc then return end
    local th = tc:FindFirstChildOfClass("Humanoid"); local tr = th and th.RootPart
    local tHead = tc:FindFirstChild("Head")
    local acc = tc:FindFirstChildOfClass("Accessory"); local handle = acc and acc:FindFirstChild("Handle")
    if not (c and h and r) then return end
    if r.Velocity.Magnitude < 50 then getgenv().OldPos = r.CFrame; SavedCFrame = r.CFrame end
    enableSec()
    if th and th.Sit then return end
    if cfg.ghost then mkGhost(); workspace.CurrentCamera.CameraSubject = h
    elseif tHead then workspace.CurrentCamera.CameraSubject = tHead
    elseif handle then workspace.CurrentCamera.CameraSubject = handle
    elseif th and tr then workspace.CurrentCamera.CameraSubject = th end
    if not tc:FindFirstChildWhichIsA("BasePart") then return end
    local pm = cfg.power; local isUp = cfg.dir == "UP"; local isDown = cfg.dir == "DOWN"
    local function fp(bp, pos, ang, velO)
        r.CFrame = CFrame.new(bp.Position) * pos * ang
        c:SetPrimaryPartCFrame(CFrame.new(bp.Position) * pos * ang)
        r.Velocity = velO or Vector3.new(9e7*pm,9e7*10*pm,9e7*pm)
        r.RotVelocity = Vector3.new(9e8*pm,9e8*pm,9e8*pm)
    end
    local function sfbp(bp)
        local t2 = 2; local t0 = tick(); local ang = 0
        if isUp then
            repeat if r and th then ang=ang+100; local sa=CFrame.Angles(math.rad(ang),0,0); local uv=Vector3.new(0,9e8*pm,0); fp(bp,CFrame.new(0,-0.5,0),sa,uv); task.wait(); fp(bp,CFrame.new(0,-2.5,0),sa,uv); task.wait() end until t0+t2<tick() or not FlingActive
        elseif isDown then
            repeat if r and th then ang=ang+100; local sa=CFrame.Angles(math.rad(ang),0,0); local dv=Vector3.new(0,-9e8*pm,0); fp(bp,CFrame.new(0,0.5,0),sa,dv); task.wait(); fp(bp,CFrame.new(0,2.5,0),sa,dv); task.wait() end until t0+t2<tick() or not FlingActive
        else
            repeat if r and th then
                if bp.Velocity.Magnitude < 50 then
                    ang=ang+100; local ra=math.random(-30,30); local sa=CFrame.Angles(math.rad(ang+ra),0,0)
                    local md=th.MoveDirection*bp.Velocity.Magnitude/1.25
                    fp(bp,CFrame.new(0,1.5,0)+md,sa); task.wait(); fp(bp,CFrame.new(0,-1.5,0)+md,sa); task.wait()
                    fp(bp,CFrame.new(0,1.5,0)+md,sa); task.wait(); fp(bp,CFrame.new(0,-1.5,0)+md,sa); task.wait()
                    fp(bp,CFrame.new(0,1.5,0)+th.MoveDirection,sa); task.wait()
                    fp(bp,CFrame.new(0,-1.5,0)+th.MoveDirection,sa); task.wait()
                else
                    local rf=math.random(-2,2)
                    fp(bp,CFrame.new(0,1.5,th.WalkSpeed+rf),CFrame.Angles(math.rad(90),0,0)); task.wait()
                    fp(bp,CFrame.new(0,-1.5,-th.WalkSpeed+rf),CFrame.Angles(0,0,0)); task.wait()
                    fp(bp,CFrame.new(0,1.5,th.WalkSpeed+rf),CFrame.Angles(math.rad(90),0,0)); task.wait()
                    fp(bp,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(90),0,0)); task.wait()
                    fp(bp,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0)); task.wait()
                    fp(bp,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(90),0,0)); task.wait()
                    fp(bp,CFrame.new(0,-1.5,0),CFrame.Angles(0,0,0)); task.wait()
                end end until t0+t2<tick() or not FlingActive end
    end
    workspace.FallenPartsDestroyHeight = 0/0
    local bv = Instance.new("BodyVelocity"); bv.Parent = r; bv.Velocity = Vector3.new(0,0,0); bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if tr then sfbp(tr) elseif tHead then sfbp(tHead) elseif handle then sfbp(handle) end
    bv:Destroy(); h:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    if cfg.ghost then killGhost() end
    workspace.CurrentCamera.CameraSubject = h; disableSec()
    if cfg.safe and SavedCFrame then
        r.CFrame = SavedCFrame; c:SetPrimaryPartCFrame(SavedCFrame)
        for _, p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.Velocity=Vector3.new(); p.RotVelocity=Vector3.new() end end
        h:ChangeState("GettingUp"); workspace.FallenPartsDestroyHeight = getgenv().FPDH; return
    end
    if getgenv().OldPos then
        repeat r.CFrame = getgenv().OldPos * CFrame.new(0,.5,0); c:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0,.5,0)); h:ChangeState("GettingUp")
            for _, p in pairs(c:GetChildren()) do if p:IsA("BasePart") then p.Velocity=Vector3.new(); p.RotVelocity=Vector3.new() end end
            task.wait() until (r.Position - getgenv().OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end
end

-- ── Controls ──
local function stopFling()
    if not FlingActive then return end; FlingActive = false; FlingMode = nil
    LoopBtn.Text = "FLING LOOP"; LoopBtn.BackgroundColor3 = flingColorLoop
    OnceBtn.Text = "FLING ONCE"; OnceBtn.BackgroundColor3 = flingColorOnce
    updateStatus()
end

local function startLoop()
    if FlingActive then return end
    if countSelected() == 0 then StatusLabel.Text="No targets selected!"; task.delay(1,function() StatusLabel.Text="Select targets to fling"; StatusLabel.TextColor3=C.textSec end); return end
    FlingActive = true; FlingMode = "loop"
    LoopBtn.Text = "STOP LOOP"; LoopBtn.BackgroundColor3 = flingColorStop
    OnceBtn.Text = "FLING ONCE"; OnceBtn.BackgroundColor3 = flingColorOnce
    updateStatus()
    task.spawn(function()
        while FlingActive do
            local vt = {}; for n,p in pairs(SelectedTargets) do if p and p.Parent then vt[n]=p else SelectedTargets[n]=nil; local ck=PlayerCheckboxes[n]; if ck then ck.ck.Visible=false end end end
            for _, p in pairs(vt) do if FlingActive then skid(p); task.wait(0.1) else break end end
            updateStatus(); task.wait(0.5)
        end
    end)
end

local function startOnce()
    if FlingActive then return end
    if countSelected() == 0 then StatusLabel.Text="No targets selected!"; task.delay(1,function() StatusLabel.Text="Select targets to fling"; StatusLabel.TextColor3=C.textSec end); return end
    FlingActive = true; FlingMode = "once"
    OnceBtn.Text = "FLINGING..."; OnceBtn.BackgroundColor3 = flingColorStop
    LoopBtn.Text = "FLING LOOP"; LoopBtn.BackgroundColor3 = flingColorLoop
    updateStatus()
    task.spawn(function()
        local vt = {}; for n,p in pairs(SelectedTargets) do if p and p.Parent then vt[n]=p else SelectedTargets[n]=nil; local ck=PlayerCheckboxes[n]; if ck then ck.ck.Visible=false end end end
        for _, p in pairs(vt) do if FlingActive then skid(p); task.wait(0.1) else break end end
        stopFling()
    end)
end

-- ── Connections ──
SelAll.MouseButton1Click:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setSelection(p, true) end end
end)
DeselAll.MouseButton1Click:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setSelection(p, false) end end
end)
NearBtn.MouseButton1Click:Connect(function()
    local lc = LocalPlayer.Character; local lr = lc and lc:FindFirstChild("HumanoidRootPart")
    if not lr then return end
    local near, sd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            if pr then local d = (pr.Position - lr.Position).Magnitude; if d < sd then sd = d; near = p end end
        end
    end
    if near then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setSelection(p, false) end end
        setSelection(near, true)
    end
end)
AutoHit.MouseButton1Click:Connect(function()
    cfg.autoSel = not cfg.autoSel
    TweenService:Create(AutoKnob, TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out), {Position = cfg.autoSel and ud2(0,16,0,2) or ud2(0,2,0,2)}):Play()
    TweenService:Create(AutoTrack, TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out), {BackgroundColor3 = cfg.autoSel and C.accent or C.toggle_off}):Play()
end)
LoopBtn.MouseButton1Click:Connect(function()
    if FlingMode == "loop" then stopFling() else startLoop() end
end)
OnceBtn.MouseButton1Click:Connect(function()
    if FlingMode == "once" then stopFling() else startOnce() end
end)

-- Player events
Players.PlayerAdded:Connect(function(p)
    if cfg.autoSel then task.wait(0.5); setSelection(p, true) end; refreshPlayers()
end)
Players.PlayerRemoving:Connect(function(p)
    if SelectedTargets[p.Name] then SelectedTargets[p.Name] = nil end; refreshPlayers(); updateStatus()
end)

-- Status loop
task.spawn(function()
    local gui = host.MainPage:FindFirstAncestorWhichIsA("ScreenGui")
    while gui and gui.Parent do
        for n, d in pairs(PlayerCheckboxes) do
            local p = Players:FindFirstChild(n)
            if p and d.dot then
                local s = getPlrStatus(p)
                d.dot.BackgroundColor3 = s=="dead" and rgb(220,80,70) or s=="seated" and rgb(255,215,0) or s=="forcefield" and rgb(70,130,220) or rgb(60,180,90)
            end
        end
        task.wait(1)
    end
end)

-- 3D target keybind (Middle mouse to select)
local lastMPress = 0; local lastMTarget = nil
UserInputService.InputBegan:Connect(function(input, proc)
    if not host.MainPage or not host.MainPage.Parent then return end
    if proc then return end
    if input.KeyCode == Enum.KeyCode.Middle then
        local mouse = LocalPlayer:GetMouse()
        local tp = mouse.Target
        if not tp then return end
        local char = tp:FindFirstAncestorOfClass("Model")
        local tPlr = Players:GetPlayerFromCharacter(char)
        if not tPlr or tPlr == LocalPlayer then return end
        local t = tick()
        if t - lastMPress < 0.3 and lastMTarget == tPlr then
            for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then setSelection(p, false) end end
            setSelection(tPlr, true); lastMPress = 0
        else
            setSelection(tPlr, SelectedTargets[tPlr.Name] == nil); lastMPress = t; lastMTarget = tPlr
        end
    end
end)

-- Initialize
refreshPlayers()
updateStatus()


