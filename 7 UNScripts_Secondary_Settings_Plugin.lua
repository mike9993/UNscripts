-- ============================================================
--  UNScripts Secondary Settings Plugin  (Script 2)
--  Injects dedicated Settings overlay into the Secondary Host UI.
--  Restores Shortcuts, Themes, Scripts sub-tabs.
--  Uses its own config file to avoid conflicts with Script 1.
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")
local TextService      = game:GetService("TextService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer

local rgb  = Color3.fromRGB
local ud2  = UDim2.new
local ud   = UDim.new
local bold = Enum.Font.GothamBold
local reg  = Enum.Font.Gotham
local semi = Enum.Font.GothamSemibold

if not _G.sectionToggles_Secondary then _G.sectionToggles_Secondary = setmetatable({}, {__mode = "k"}) end
if not _G.passiveScrollFrames_Secondary then _G.passiveScrollFrames_Secondary = {} end

local function makePassiveScrollable(sf)
    sf.Active = false
    table.insert(_G.passiveScrollFrames_Secondary, sf)
    sf.Destroying:Connect(function()
        for i, v in ipairs(_G.passiveScrollFrames_Secondary) do
            if v == sf then table.remove(_G.passiveScrollFrames_Secondary, i); break end
        end
    end)
end

local C = {
    bg         = rgb(25, 25, 25),
    surface    = rgb(32, 32, 32),
    part_bg    = rgb(45, 45, 45),
    surfaceAlt = rgb(40, 40, 40),
    border     = rgb(45, 45, 52),
    accent     = rgb(50, 120, 255),
    textPri    = rgb(218, 218, 222),
    textSec    = rgb(115, 115, 128),
    dot_red    = rgb(220, 80,  70),
    dot_yel    = rgb(255, 215, 0),
    dot_grn    = rgb(60,  180, 90),
    toggle_off = rgb(55,  55,  62),
    toggle_on  = rgb(50,  120, 255),
    knob       = rgb(245, 245, 248),
    white      = rgb(255, 255, 255),
    tab_stroke = rgb(59, 59, 59),
}

local LC = {
    bg         = rgb(240, 240, 240),
    surface    = rgb(225, 225, 225),
    part_bg    = rgb(215, 215, 215),
    surfaceAlt = rgb(200, 200, 200),
    border     = rgb(180, 180, 180),
    textPri    = rgb(30, 30, 30),
    textSec    = rgb(90, 90, 90),
    toggle_off = rgb(170, 170, 170),
    knob       = rgb(255, 255, 255),
    white      = rgb(20, 20, 20),
    tab_stroke = rgb(170, 170, 170),
    accent     = C.accent,
    dot_red    = C.dot_red,
    dot_yel    = C.dot_yel,
    dot_grn    = C.dot_grn,
    toggle_on  = C.toggle_on,
}

local CFG_FOLDER = "UNScripts"
local CFG_EXT    = ".cfg"
local PLG_FILE   = "settings_plugin_secondary"

local function cfgSafely(fn, ...)
    if fn then
        local ok, res = pcall(fn, ...)
        return ok and res or nil
    end
end

local function getCfg()
    local path = CFG_FOLDER.."/"..PLG_FILE..CFG_EXT
    if cfgSafely(isfile, path) then
        local content = cfgSafely(readfile, path)
        if content then
            local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
            if ok and type(data) == "table" then return data end
        end
    end
    return {}
end

local function saveCfg(data)
    if isfolder and not cfgSafely(isfolder, CFG_FOLDER) then
        cfgSafely(makefolder, CFG_FOLDER)
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        cfgSafely(writefile, CFG_FOLDER.."/"..PLG_FILE..CFG_EXT, encoded)
    end
end

local cfg              = getCfg()
local cfgTransparency  = cfg.transparency or 0
local cfgLightMode     = cfg.lightMode or false
local cfgKeybind1      = cfg.keybind1 or "LeftControl"
local cfgKeybind2      = cfg.keybind2 or "Z"
local cfgPillAnchor    = cfg.pillAnchor or "TopCenter"
local cfgPillVertical  = cfg.pillVertical or false
local cfgPillPlacements = cfg.pillPlacements or {}
local cfgCollapsePos   = cfg.collapsePos or "Right"
local cfgSaveInventory = cfg.saveInventory or false


local function keycodeFromName(name)
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    return (ok and kc) or Enum.KeyCode.Unknown
end

local activeKeybind = {
    keycodeFromName(cfgKeybind1),
    keycodeFromName(cfgKeybind2),
}

local function saveSettings()
    cfg.transparency   = cfgTransparency
    cfg.lightMode      = cfgLightMode
    cfg.keybind1       = activeKeybind[1].Name
    cfg.keybind2       = activeKeybind[2].Name
    cfg.pillAnchor     = cfgPillAnchor
    cfg.pillVertical   = cfgPillVertical
    cfg.pillPlacements = cfgPillPlacements
    cfg.collapsePos     = cfgCollapsePos
    cfg.saveInventory   = cfgSaveInventory

    saveCfg(cfg)
end

local Gui, Main, MainPage, HeaderBar, PillUI, CloseOverlay

local function findUI()
    Gui = game:GetService("CoreGui"):FindFirstChild("UNScripts_Secondary_UI")
    if not Gui then Gui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("UNScripts_Secondary_UI") end
    if not Gui then return false end

    for _, c in ipairs(Gui:GetChildren()) do if c:IsA("Frame") then Main = c; break end end
    if not Main then return false end

    for _, c in ipairs(Main:GetChildren()) do
        if c:IsA("Frame") then
            if c.Size.Y.Offset == 42 and c.Position.Y.Offset == 0 then HeaderBar = c
            elseif c.Position.Y.Offset == 42 and c.Size.Y.Offset < 0 then MainPage = c
            elseif c.ZIndex == 100 and c.Active == true then CloseOverlay = c end
        end
    end

    for _, c in ipairs(Gui:GetChildren()) do
        if c:IsA("TextButton") and (c.Text == "UNScripts Secondary" or c.Text == "UNS" or c.Text == "U\nN\nS") then
            PillUI = c
            break
        end
    end
    return Main ~= nil and HeaderBar ~= nil and MainPage ~= nil
end

-- ==========================================
-- Theme registry logic for Script 2's components
-- ==========================================
local themeRegistry = {}

local function updateThemeTag(obj, prop, newKey)
    for _, record in ipairs(themeRegistry) do
        if record.obj == obj then
            record.tags[prop] = newKey
            break
        end
    end
end

local function Make(className, props)
    local inst = Instance.new(className)
    local tags = {}
    for k, v in pairs(props) do
        inst[k] = v
        if typeof(v) == "Color3" then
            for cKey, cVal in pairs(C) do
                if v == cVal then
                    tags[k] = cKey
                    break
                end
            end
        end
    end
    if next(tags) then
        table.insert(themeRegistry, {obj = inst, tags = tags})
    end
    return inst
end

local toggleSpring  = TweenInfo.new(0.18, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)
local toggleColorTI = TweenInfo.new(0.20, Enum.EasingStyle.Linear)

local function makeToggle(parent, yPos, callback, initOn)
    local track = Make("Frame", {
        Size = ud2(0,38,0,20),
        Position = ud2(1,-48,0,yPos),
        BackgroundColor3 = initOn and C.toggle_on or C.toggle_off,
        BorderSizePixel = 0, Parent = parent
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
    Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.82, Parent = track})

    local knob = Make("Frame", {
        Size = ud2(0,16,0,16),
        Position = initOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8),
        BackgroundColor3 = C.knob,
        BorderSizePixel = 0, Parent = track
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
    Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.72, Parent = knob})

    local isOn = initOn == true
    local hitbox = Make("TextButton", { Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = track })

    local function setOn(state, silent)
        isOn = state
        local targetColorKey = isOn and "toggle_on" or "toggle_off"
        updateThemeTag(track, "BackgroundColor3", targetColorKey)
        
        local p = cfgLightMode and LC or C
        TweenService:Create(track, toggleColorTI, {BackgroundColor3 = p[targetColorKey]}):Play()
        TweenService:Create(knob, toggleSpring, {Position = isOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8)}):Play()
        if callback and not silent then callback(isOn) end
    end

    hitbox.MouseButton1Click:Connect(function() setOn(not isOn, false) end)
    return {Track = track, Knob = knob, IsOn = function() return isOn end, SetOn = setOn}
end

local function applyTheme()
    local p = cfgLightMode and LC or C
    -- Update local Settings GUI created by this script
    for _, record in ipairs(themeRegistry) do
        if record.obj and record.obj.Parent then
            for prop, cKey in pairs(record.tags) do
                if p[cKey] then
                    pcall(function() record.obj[prop] = p[cKey] end)
                end
            end
        end
    end
    -- Trigger Master UI Theme Application
    if _G.UNScripts_Secondary and _G.UNScripts_Secondary.ApplyTheme then
        _G.UNScripts_Secondary.ApplyTheme(cfgLightMode)
    end
end

local function applyTransparency(t)
    cfgTransparency = math.clamp(t, 0, 0.85)
    if Main then Main.BackgroundTransparency = cfgTransparency end
    if PillUI then PillUI.BackgroundTransparency = cfgTransparency end
    if CloseOverlay then CloseOverlay.BackgroundTransparency = cfgTransparency end
end

local function syncTransparencyToMain()
    pcall(function()
        local g = game:GetService("CoreGui"):FindFirstChild("UNScriptsInterface") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UNScriptsInterface"))
        if g then
            for _, c in ipairs(g:GetChildren()) do
                if c:IsA("Frame") then c.BackgroundTransparency = cfgTransparency
                    for _, s in ipairs(c:GetChildren()) do
                        if s:IsA("Frame") and s.ZIndex == 100 then s.BackgroundTransparency = cfgTransparency; break end
                    end; break
                end
            end
            for _, c in ipairs(g:GetChildren()) do
                if c:IsA("TextButton") and (c.Text == "UNScripts" or c.Text == "U\nN\nS") then c.BackgroundTransparency = cfgTransparency; break end
            end
        end
    end)
end

local PART_H      = 32
local SECTION_H   = 38
local sectionTween = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local tabTween    = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function makeSetScroll(parent, visible)
    local s = Make("ScrollingFrame", {
        Size = ud2(1,-24,1,-78),   Position = ud2(0,12,0,78),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
        CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = visible, Parent = parent,
    })
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = s})
    return s
end

local function makeSetSection(parent, title, contentH, startOpen)
    local wrapper = Make("Frame", {Size = ud2(1,-16,0,SECTION_H), BackgroundTransparency = 1, ClipsDescendants = true, Parent = parent})
    local header = Make("Frame", {Size = ud2(1,-2,0,SECTION_H - 2), Position = ud2(0,1,0,1),
        BackgroundColor3 = C.surface, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wrapper})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = header})
    Make("UIStroke", {Color = C.white, Thickness = 1, Transparency = 0.85, Parent = header})
    local arrow = Make("TextLabel", {Size = ud2(0,28,1,0), Position = ud2(0,10,0,0),
        BackgroundTransparency = 1, Text = startOpen and "-" or "+",
        TextColor3 = C.textSec, TextSize = 18, Font = bold, Parent = header})
    local titleLbl = Make("TextLabel", {Size = ud2(1,-50,1,0), Position = ud2(0,32,0,0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = C.textPri, TextSize = 12, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header})
    titleLbl:SetAttribute("SearchName", title)
    local totalH = SECTION_H + 4 + contentH
    if startOpen then wrapper.Size = ud2(1,-16,0,totalH) end
    local isOpen = startOpen == true
    local function setOpen(state)
        isOpen = state
        arrow.Text = isOpen and "-" or "+"
        TweenService:Create(wrapper, sectionTween, {Size = ud2(1,-16,0, isOpen and totalH or SECTION_H)}):Play()
    end
    _G.sectionToggles_Secondary[wrapper] = setOpen
    local hBtn = Make("TextButton", {Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = header})
    hBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
    local content = Make("Frame", {Size = ud2(1,0,0,contentH), Position = ud2(0,0,0,SECTION_H+4),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = wrapper})
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = content})
    
    local obj = {}
    function obj.UpdateHeight(newContentH)
        contentH = newContentH
        totalH = SECTION_H + 4 + contentH
        content.Size = ud2(1,0,0,contentH)
        if isOpen then
            TweenService:Create(wrapper, sectionTween, {Size = ud2(1,-16,0, totalH)}):Play()
        end
    end
    
    return wrapper, content, obj
end

local function makeSetDropdown(parent, sectionObj, label, options, defaultVal, callback)
    local isOpen = false
    local val = defaultVal or options[1]
    
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = parent,
    })
    pill:SetAttribute("SearchName", label)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})

    Make("TextLabel", {
        Size = ud2(0,120,0,PART_H), Position = ud2(0,14,0,0),
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
        Visible = false, Parent = parent,
    })
    Make("UICorner", {CornerRadius = ud(0,8), Parent = dropFrame})
    Make("UIStroke", {Color = C.border, Thickness = 1, Parent = dropFrame})
    Make("UIPadding", {
        PaddingTop = ud(0,4), PaddingBottom = ud(0,4),
        PaddingLeft = ud(0,14), PaddingRight = ud(0,14),
        Parent = dropFrame
    })
    local listLayout = Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,2), Parent = dropFrame
    })

    local function updateSize()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        if isOpen then
            dropFrame.Size = ud2(1,-16,0,contentHeight + 8)
        end

        if sectionObj then
            local pad = parent:FindFirstChildOfClass("UIListLayout") and parent:FindFirstChildOfClass("UIListLayout").Padding.Offset or 5
            local totalH = 0
            local count = 0
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("GuiObject") and (child.Visible or child == dropFrame) then
                    local active = (child ~= dropFrame) or isOpen
                    if active then
                        local sy = child.Size.Y.Offset
                        if sy > 0 then totalH = totalH + sy; count = count + 1 end
                    end
                end
            end
            if count > 1 then totalH = totalH + pad * (count - 1) end
            sectionObj.UpdateHeight(totalH)
        end

        if isOpen then
            dropFrame.Visible = true
        else
            dropFrame.Visible = false
            dropFrame.Size = ud2(1,-16,0,0)
        end
    end

    for i, opt in ipairs(options) do
        local oBtn = Make("TextButton", {
            Size = ud2(1,0,0,22), BackgroundColor3 = C.surface, BackgroundTransparency = 0.2,
            Text = tostring(opt), TextColor3 = C.textSec, TextSize = 10, Font = reg,
            Parent = dropFrame, LayoutOrder = i
        })
        Make("UICorner", {CornerRadius = ud(0,4), Parent = oBtn})
        oBtn.MouseButton1Click:Connect(function()
            val = opt
            valDisplay.Text = tostring(val) .. " ▼"
            isOpen = false
            updateSize()
            if callback then callback(val) end
        end)
    end

    valDisplay.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        valDisplay.Text = tostring(val) .. (isOpen and " ▲" or " ▼")
        updateSize()
    end)
    
    return pill
end

local function injectSettings()
    if not findUI() then
        task.wait(1)
        if not findUI() then
            warn("[UNScripts Secondary Plugin] Base UI not found")
            return
        end
    end

    -- ════════════════════════════ NOTIFICATION SYSTEM ════════════════════════════
    -- Base dimensions (Medium, s=1.0): container width 340, notification corner radius 8, padding 6
    -- Small  (s=0.85): width 289, text/dots/spacing at 85%
    -- Large  (s=1.15): width 391, text/dots/spacing at 115%
    local SIZE_WIDTHS = {Small = 289, Medium = 340, Large = 391}
    local SIZE_SCALES = {Small = 0.85, Medium = 1, Large = 1.15}
    local basePad = 6
    local baseCorner = 8
    local notifWidth = SIZE_WIDTHS[cfg.notifSize or "Medium"] or 340
    local notifContainer = Make("Frame", {
        Size = ud2(0,notifWidth,1,-20),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 200, Parent = Gui,
    })
    local initS = SIZE_SCALES[cfg.notifSize or "Medium"] or 1
    local notifList = Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0, math.max(math.floor(basePad * initS), 4)), Parent = notifContainer,
    })

    local notifCfg = {enabled = true, corner = cfg.notifCorner or "BottomRight", size = cfg.notifSize or "Medium"}

    local CORNERS = {
        TopLeft     = {pos = ud2(0,10,0,10),     anc = Vector2.new(0,0),  dir = -1, vert = Enum.VerticalAlignment.Top},
        TopRight    = {pos = ud2(1,-10,0,10),    anc = Vector2.new(1,0),  dir = 1,  vert = Enum.VerticalAlignment.Top},
        BottomLeft  = {pos = ud2(0,10,1,-10),    anc = Vector2.new(0,1),  dir = -1, vert = Enum.VerticalAlignment.Bottom},
        BottomRight = {pos = ud2(1,-10,1,-10),   anc = Vector2.new(1,1),  dir = 1,  vert = Enum.VerticalAlignment.Bottom},
    }

    local function applyNotifCorner(corner)
        notifCfg.corner = corner
        local d = CORNERS[corner]
        if d then
            notifContainer.AnchorPoint = d.anc
            notifList.VerticalAlignment = d.vert
            TweenService:Create(notifContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = d.pos,
            }):Play()
        end
        cfg.notifCorner = corner
        saveSettings()
    end

    local NID = 0

    local function notify(title, text, duration)
        duration = duration or 5
        if not notifCfg.enabled then return end
        NID = NID + 1
        local p = cfgLightMode and LC or C
        local s = SIZE_SCALES[notifCfg.size] or 1

        local cr = math.max(math.floor(baseCorner * s), 4)
        local st = math.max(math.floor(1 * s), 1)

        -- Wrapper: sized by UIListLayout, clips the sliding content
        local wrapper = Make("Frame", {
            Size = ud2(1,0,0,72), BackgroundTransparency = 1,
            BorderSizePixel = 0, ClipsDescendants = true,
            Parent = notifContainer, LayoutOrder = -NID,
        })

        -- Slide layer: slides inside the wrapper without layout interference
        local frame = Make("ImageButton", {
            Size = ud2(1,0,1,0), BackgroundColor3 = p.surface,
            BorderSizePixel = 0, ClipsDescendants = true,
            ImageTransparency = 1, AutoButtonColor = false,
            Parent = wrapper,
        })
        Make("UICorner", {CornerRadius = ud(0,cr), Parent = frame})
        Make("UIStroke", {Color = C.border, Thickness = st, Transparency = 0.4, Parent = frame})

        local ds = math.floor(14 * s)
        local redDot = Make("TextButton", {
            Size = ud2(0,ds,0,ds), Position = ud2(0,math.floor(10*s),0,math.floor(10*s)),
            BackgroundColor3 = C.dot_red, BorderSizePixel = 0, Text = "", ZIndex = 2, Parent = frame,
        })
        Make("UICorner", {CornerRadius = ud(1,0), Parent = redDot})

        local titleLbl = Make("TextLabel", {
            Size = ud2(1,-(ds+26),0,math.floor(18*s)), Position = ud2(0,ds+26,0,math.floor(10*s)),
            BackgroundTransparency = 1, Text = title,
            TextColor3 = p.textPri, TextSize = math.floor(15 * s), Font = bold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = frame,
        })

        local bodyFontSize = math.floor(13 * s)
        local txtSize = TextService:GetTextSize(text, bodyFontSize, Enum.Font.Gotham, Vector2.new(300,1000))
        local bodyH = math.min(txtSize.Y + math.floor(6*s), math.floor(50*s))
        local bodyLbl = Make("TextLabel", {
            Size = ud2(1,-math.floor(20*s),0,bodyH), Position = ud2(0,math.floor(10*s),0,math.floor(36*s)),
            BackgroundTransparency = 1, Text = text,
            TextColor3 = p.textSec, TextSize = bodyFontSize, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true, ZIndex = 2, Parent = frame,
        })
        local totalH = math.floor(36*s) + bodyH + math.floor(10*s) + math.floor(4*s)
        wrapper.Size = ud2(1,0,0,totalH)

        local barH = math.max(math.floor(4 * s), 2)
        local barTrack = Make("Frame", {
            Size = ud2(1,0,0,barH), Position = ud2(0,0,1,-barH),
            BackgroundColor3 = p.toggle_off, BackgroundTransparency = 0.5,
            BorderSizePixel = 0, ZIndex = 2, Parent = frame,
        })
        local barFill = Make("Frame", {
            Size = ud2(1,0,1,0), BackgroundColor3 = p.accent,
            BorderSizePixel = 0, Parent = barTrack,
        })
        Make("UICorner", {CornerRadius = ud(1,0), Parent = barFill})

        -- Slide in: wrapper stays in layout, frame slides within wrapper
        local dir = CORNERS[notifCfg.corner] and CORNERS[notifCfg.corner].dir or -1
        frame.Position = ud2(0, dir * 360, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = ud2(0,0,0,0),
        }):Play()

        -- Progress bar tween
        local progTween = TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = ud2(0,0,1,0),
        })
        progTween:Play()

        local state = "idle"

        local function destroyNotif()
            if state == "destroying" then return end
            state = "destroying"
            if not wrapper.Parent then return end
            progTween:Cancel()
            task.spawn(function()
                local so = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    Position = ud2(0, dir * 360, 0, 0),
                    BackgroundTransparency = 1,
                })
                so:Play()
                so.Completed:Wait()
                wrapper:Destroy()
            end)
        end

        task.spawn(function()
            progTween.Completed:Wait()
            if state == "idle" then destroyNotif() end
        end)

        local function pauseNotif()
            if state ~= "idle" then return end
            state = "paused"
            progTween:Cancel()
            barTrack.Visible = false
            barFill.Visible = false
        end

        redDot.MouseButton1Click:Connect(function()
            destroyNotif()
        end)

        frame.MouseButton1Click:Connect(function()
            pauseNotif()
        end)
    end

    local function applyNotifSize(size)
        notifCfg.size = size
        cfg.notifSize = size
        local s = SIZE_SCALES[size] or 1
        local newW = SIZE_WIDTHS[size] or 340
        notifList.Padding = ud(0, math.max(math.floor(basePad * s), 4))
        TweenService:Create(notifContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = ud2(0,newW,1,-20),
        }):Play()
        saveSettings()
    end

    applyNotifCorner(notifCfg.corner)
    _G.UNScripts_Secondary.Notify = notify
    _G.UNScripts_Secondary.SetNotifCorner = applyNotifCorner

    local ToggleBtn = Make("TextButton", {
        Size = ud2(0,28,0,28), Position = ud2(1,-36,0,7),
        BackgroundTransparency = 1, Text = "⚙",
        TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
    })

    -- ════════════════════════════ SEARCH ════════════════════════════
    local searchBtn = Make("TextButton", {
        Size = ud2(0,28,0,28), Position = ud2(1,-72,0,7),
        BackgroundTransparency = 1, Text = "🔍",
        TextColor3 = C.textSec, TextSize = 14, Font = bold, Parent = HeaderBar,
    })

    local searchOpen = false
    local searchOverlayRef = nil

    local function closeSearch()
        if searchOverlayRef and searchOverlayRef.Parent then
            searchOverlayRef:Destroy()
        end
        searchOverlayRef = nil
        searchOpen = false
    end

    local function openSearch()
        if searchOpen then return end
        searchOpen = true

        local overlay = Make("Frame", {
            Size = ud2(1,0,1,0), Position = ud2(0,0,0,0),
            BackgroundColor3 = C.bg, BorderSizePixel = 0,
            ZIndex = 200, Parent = Main,
        })
        Make("UICorner", {CornerRadius = ud(0,16), Parent = overlay})
        searchOverlayRef = overlay

        local box = Make("TextBox", {
            Size = ud2(1,-72,0,36), Position = ud2(0,28,0,16),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, Text = "", PlaceholderText = "Search players...",
            ClearTextOnFocus = false, TextColor3 = C.textPri,
            PlaceholderColor3 = C.textSec, TextSize = 14, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201, Parent = overlay,
        })
        Make("UICorner", {CornerRadius = ud(0,8), Parent = box})
        Make("UIPadding", {PaddingLeft = ud(0,12), Parent = box})

        local closeBtn = Make("TextButton", {
            Size = ud2(0,28,0,28), Position = ud2(1,-40,0,20),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.2,
            Text = "X", TextColor3 = C.textSec, TextSize = 14, Font = bold,
            ZIndex = 201, Parent = overlay,
        })
        Make("UICorner", {CornerRadius = ud(0,6), Parent = closeBtn})
        closeBtn.MouseButton1Click:Connect(closeSearch)

        local resultsScroll = Make("ScrollingFrame", {
            Size = ud2(1,-24,1,-80), Position = ud2(0,12,0,80),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
            CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 201, Parent = overlay,
        })
        Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,4), Parent = resultsScroll})
        Make("UIPadding", {PaddingLeft = ud(0,8), PaddingRight = ud(0,8), Parent = resultsScroll})

        local function renderResults(query)
            for _, c in ipairs(resultsScroll:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local q = query:lower()
            local order = 0
            for _, plr in pairs(Players:GetPlayers()) do
                local name = plr.Name
                local displayName = plr.DisplayName
                if q == "" or name:lower():find(q, 1, true) or displayName:lower():find(q, 1, true) then
                    order = order + 1
                    local row = Make("Frame", {
                        Size = ud2(1,0,0,44), BackgroundColor3 = C.part_bg,
                        BackgroundTransparency = 0.2, BorderSizePixel = 0,
                        ZIndex = 202, Parent = resultsScroll, LayoutOrder = order,
                    })
                    Make("UICorner", {CornerRadius = ud(0,6), Parent = row})

                    Make("ImageLabel", {
                        Size = ud2(0,32,0,32), Position = ud2(0,6,0,6),
                        BackgroundTransparency = 1,
                        Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48",
                        ZIndex = 203, Parent = row,
                    })

                    Make("TextLabel", {
                        Size = ud2(1,-52,0,20), Position = ud2(0,44,0,4),
                        BackgroundTransparency = 1, Text = displayName ~= name and (displayName .. " (" .. name .. ")") or name,
                        TextColor3 = C.textPri, TextSize = 12, Font = semi,
                        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203, Parent = row,
                    })

                    local statusText = plr == LocalPlayer and "(You)" or ""
                    if plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp or not hrp.Parent then statusText = "(Dead)" end
                    else
                        statusText = "(Dead)"
                    end
                    Make("TextLabel", {
                        Size = ud2(1,-52,0,16), Position = ud2(0,44,0,24),
                        BackgroundTransparency = 1, Text = statusText,
                        TextColor3 = C.textSec, TextSize = 10, Font = reg,
                        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 203, Parent = row,
                    })

                    local hit = Make("TextButton", {
                        Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
                        ZIndex = 203, Parent = row,
                    })
                    hit.MouseButton1Click:Connect(function()
                        closeSearch()
                        if plr ~= LocalPlayer then
                            _G.UNFling_SelectPlayer(plr.Name)
                        end
                    end)
                end
            end
            if order == 0 and q ~= "" then
                Make("TextLabel", {
                    Size = ud2(1,0,0,36), BackgroundTransparency = 1,
                    Text = "No players found", TextColor3 = C.textSec,
                    TextSize = 11, Font = reg, ZIndex = 202, Parent = resultsScroll,
                })
            end
        end

        box:GetPropertyChangedSignal("Text"):Connect(function()
            renderResults(box.Text)
        end)

        renderResults("")
        box:CaptureFocus()
    end

    searchBtn.MouseButton1Click:Connect(function()
        if searchOpen then closeSearch() else openSearch() end
    end)

    local SetPage = Make("Frame", {
        Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
        BackgroundTransparency = 1, ClipsDescendants = true,
        Visible = false, Parent = Main,
    })
    Make("TextLabel", {Size = ud2(1,0,0,42), BackgroundTransparency = 1,
        Text = "Settings", TextColor3 = C.textPri, TextSize = 16, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Center, Parent = SetPage})

    local TabBar = Make("Frame", {Size = ud2(1,-24,0,30), Position = ud2(0,12,0,42),
        BackgroundTransparency = 1, Parent = SetPage})
    Make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = ud(0,6), Parent = TabBar})

    local function mkSTab(name, w)
        local btn = Make("TextButton", {Size = ud2(0,w or 75,0,26),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0,
            Text = name, TextColor3 = C.textSec, TextSize = 10, Font = bold, Parent = TabBar})
        Make("UICorner", {CornerRadius = ud(1,0), Parent = btn})
        Make("UIStroke", {Color = C.tab_stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn})
        local pill = Make("Frame", {Size = ud2(0,0,0,2), Position = ud2(0.5,0,1,-2),
            AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.accent,
            BorderSizePixel = 0, Parent = btn})
        Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
        return {Button = btn, Pill = pill}
    end

    local sTab = {
        Shortcuts = mkSTab("Shortcuts"),
        Themes    = mkSTab("Themes"),
        System    = mkSTab("System", 80),
    }

    local ScrollShortcuts = makeSetScroll(SetPage, true)
    local ScrollThemes    = makeSetScroll(SetPage, false)
    local ScrollSystem    = makeSetScroll(SetPage, false)

    local activeSetTab = ""
    local function switchSetTab(name)
        if activeSetTab == name then return end
        activeSetTab = name
        ScrollShortcuts.Visible = (name == "Shortcuts")
        ScrollThemes.Visible    = (name == "Themes")
        ScrollSystem.Visible    = (name == "System")
        for k, t in pairs(sTab) do
            local a = (k == name)
            local tKey = a and "textPri" or "textSec"
            updateThemeTag(t.Button, "TextColor3", tKey)
            
            local p = cfgLightMode and LC or C
            TweenService:Create(t.Pill, tabTween, {Size = a and ud2(0,40,0,2) or ud2(0,0,0,2)}):Play()
            TweenService:Create(t.Button, tabTween, {TextColor3 = p[tKey], BackgroundTransparency = a and 0 or 0.15}):Play()
        end
    end
    sTab.Shortcuts.Button.MouseButton1Click:Connect(function() switchSetTab("Shortcuts") end)
    sTab.Themes.Button.MouseButton1Click:Connect(function()    switchSetTab("Themes") end)
    sTab.System.Button.MouseButton1Click:Connect(function()    switchSetTab("System") end)
    switchSetTab("Shortcuts")

    -- ════════════════════════════ SHORTCUTS ════════════════════════════
    local _, scSec, scObj = makeSetSection(ScrollShortcuts, "Close and open UI", PART_H + 5, true)
    _G.UNS_Secondary_ShortcutsSection = scSec
    _G.UNS_Secondary_ShortcutsSectionObj = scObj
    local scPill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = scSec})
    scPill:SetAttribute("SearchName", "Toggle UI Keybind")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = scPill})
    Make("TextLabel", {Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = "Toggle UI Keybind",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = scPill})

    local listeningKey = false
    local tempKeys     = {}
    local KeybindBtn = Make("TextButton", {Size = ud2(0,130,0,22), Position = ud2(1,-140,0,5),
        BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
        Text = "[ " .. activeKeybind[1].Name .. " + " .. activeKeybind[2].Name .. " ]",
        TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = scPill})
    Make("UICorner", {CornerRadius = ud(0,4), Parent = KeybindBtn})
    Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = KeybindBtn})
    KeybindBtn.MouseButton1Click:Connect(function()
        if not listeningKey then
            listeningKey = true; tempKeys = {}
            KeybindBtn.Text = "[ Press 1st Key ]"
            updateThemeTag(KeybindBtn, "TextColor3", "dot_yel")
            local p = cfgLightMode and LC or C
            KeybindBtn.TextColor3 = p["dot_yel"]
        end
    end)

    -- Dynamic shortcut pill injection API
    local shortcutPillCount = 0
    local shortcutBaseH = PART_H + 5
    function _G.UNS_Secondary_AddShortcutPill(label, defaultKeyName, onKeyChanged)
        shortcutPillCount = shortcutPillCount + 1
        local newH = shortcutBaseH + shortcutPillCount * (PART_H + 5)
        scObj.UpdateHeight(newH)

        local pill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
            BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = scSec})
        pill:SetAttribute("SearchName", label)
        Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
        Make("TextLabel", {Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
            BackgroundTransparency = 1, Text = label,
            TextColor3 = C.textPri, TextSize = 11, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = pill})

        local currentKeyName = defaultKeyName or "G"
        local listening = false
        local keyBtn = Make("TextButton", {Size = ud2(0,80,0,22), Position = ud2(1,-90,0,5),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
            Text = "[ " .. currentKeyName .. " ]",
            TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = pill})
        Make("UICorner", {CornerRadius = ud(0,4), Parent = keyBtn})
        Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = keyBtn})

        keyBtn.MouseButton1Click:Connect(function()
            if not listening then
                listening = true
                keyBtn.Text = "[ Press Key ]"
                local p = cfgLightMode and LC or C
                keyBtn.TextColor3 = p["dot_yel"]
            end
        end)

        local listenConn = UserInputService.InputBegan:Connect(function(input, proc)
            if not listening then return end
            if proc then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKeyName = input.KeyCode.Name
                listening = false
                local p = cfgLightMode and LC or C
                keyBtn.TextColor3 = p["textPri"]
                keyBtn.Text = "[ " .. currentKeyName .. " ]"
                if onKeyChanged then onKeyChanged(input.KeyCode) end
            end
        end)

        return {
            GetKeyName = function() return currentKeyName end,
            SetKey = function(keyCode)
                currentKeyName = keyCode.Name
                keyBtn.Text = "[ " .. currentKeyName .. " ]"
            end,
            Destroy = function()
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                pill:Destroy()
                shortcutPillCount = math.max(0, shortcutPillCount - 1)
                scObj.UpdateHeight(shortcutBaseH + shortcutPillCount * (PART_H + 5))
            end,
        }
    end

    -- ════════════════════════════ SCRIPTS (Shortcuts) ════════════════════════════
    local _, scrSec, scrObj = makeSetSection(ScrollShortcuts, "Scripts", 0, true)
    local scriptKeybindList = {}
    local scriptPillCount = 0
    local scriptBaseH = PART_H + 5

    function _G.UNS_Secondary_AddScriptShortcut(name, toggleFn)
        scriptPillCount = scriptPillCount + 1
        local newH = scriptBaseH + scriptPillCount * (PART_H + 5)
        scrObj.UpdateHeight(newH)

        if not cfg.scriptKeybinds then cfg.scriptKeybinds = {} end
        if not cfg.scriptKeybinds[name] then
            cfg.scriptKeybinds[name] = {mode = 1, key1 = nil, key2 = nil}
        end
        local kbCfg = cfg.scriptKeybinds[name]

        local entry = {name = name, mode = kbCfg.mode or 1, key1 = kbCfg.key1, key2 = kbCfg.key2, toggleFn = toggleFn}
        table.insert(scriptKeybindList, entry)

        local pill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
            BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = scrSec})
        pill:SetAttribute("SearchName", name)
        Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
        Make("TextLabel", {Size = ud2(0,100,1,0), Position = ud2(0,14,0,0),
            BackgroundTransparency = 1, Text = name,
            TextColor3 = C.textPri, TextSize = 11, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = pill})

        local modeBtn = Make("TextButton", {Size = ud2(0,34,0,22), Position = ud2(1,-170,0,5),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
            Text = entry.mode == 1 and "1K" or "2K",
            TextColor3 = C.textPri, TextSize = 10, Font = bold, Parent = pill})
        Make("UICorner", {CornerRadius = ud(0,4), Parent = modeBtn})
        Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = modeBtn})

        local function getKeyText()
            if not entry.key1 then return "[ - ]" end
            if entry.mode == 1 then return "[ " .. entry.key1 .. " ]" end
            return "[ " .. entry.key1 .. " + " .. (entry.key2 or "?") .. " ]"
        end

        local listening = false
        local tempKeys = {}
        local keyBtn = Make("TextButton", {Size = ud2(0,105,0,22), Position = ud2(1,-130,0,5),
            BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
            Text = getKeyText(), TextColor3 = C.textPri, TextSize = 10, Font = bold, Parent = pill})
        Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = keyBtn})

        local clearBtn = Make("TextButton", {Size = ud2(0,22,0,22), Position = ud2(1,-26,0,5),
            BackgroundColor3 = rgb(200,50,50), BackgroundTransparency = 0.2,
            Text = "X", TextColor3 = C.white, TextSize = 10, Font = bold, Parent = pill})
        Make("UICorner", {CornerRadius = ud(0,4), Parent = clearBtn})

        local function updateCfg()
            kbCfg.mode = entry.mode; kbCfg.key1 = entry.key1; kbCfg.key2 = entry.key2
            saveSettings()
        end

        local function updateKeyDisplay()
            keyBtn.Text = getKeyText()
            local p = cfgLightMode and LC or C
            keyBtn.TextColor3 = p["textPri"]
        end

        modeBtn.MouseButton1Click:Connect(function()
            if listening then listening = false; tempKeys = {}; updateKeyDisplay() end
            entry.mode = entry.mode == 1 and 2 or 1
            modeBtn.Text = entry.mode == 1 and "1K" or "2K"
            if entry.mode == 1 then entry.key2 = nil end
            updateKeyDisplay(); updateCfg()
        end)

        keyBtn.MouseButton1Click:Connect(function()
            if not listening then
                listening = true; tempKeys = {}
                keyBtn.Text = entry.mode == 1 and "[ Press Key ]" or "[ Press 1st Key ]"
                local p = cfgLightMode and LC or C
                keyBtn.TextColor3 = p["dot_yel"]
            end
        end)

        clearBtn.MouseButton1Click:Connect(function()
            if listening then listening = false; tempKeys = {} end
            entry.key1 = nil; entry.key2 = nil
            updateKeyDisplay(); updateCfg()
        end)

        local listenConn = UserInputService.InputBegan:Connect(function(input, proc)
            if not listening then return end
            if proc then return end
            if listeningKey then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Unknown then return end

            if entry.mode == 1 then
                entry.key1 = input.KeyCode.Name; listening = false
                updateKeyDisplay(); updateCfg()
            else
                table.insert(tempKeys, input.KeyCode)
                if #tempKeys == 1 then
                    keyBtn.Text = "[ " .. tempKeys[1].Name .. " + ? ]"
                elseif #tempKeys == 2 then
                    entry.key1 = tempKeys[1].Name; entry.key2 = tempKeys[2].Name
                    listening = false; updateKeyDisplay(); updateCfg()
                end
            end
        end)

        return {
            GetKeys = function() return entry.key1, entry.key2 end,
            GetMode = function() return entry.mode end,
            Destroy = function()
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                pill:Destroy()
                scriptPillCount = math.max(0, scriptPillCount - 1)
                scrObj.UpdateHeight(scriptBaseH + scriptPillCount * (PART_H + 5))
                for i, v in ipairs(scriptKeybindList) do if v == entry then table.remove(scriptKeybindList, i); break end end
            end,
        }
    end

    -- ════════════════════════════ THEMES ════════════════════════════
    local _, appSec = makeSetSection(ScrollThemes, "Appearance", PART_H + 5 + 45, true)
    local modePill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 0, Parent = appSec})
    modePill:SetAttribute("SearchName", "Light Mode")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = modePill})
    Make("TextLabel", {Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = "Light Mode",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = modePill})
    local lightModeToggle = makeToggle(modePill, (PART_H-18)/2, function(on)
        cfgLightMode = on; _G.UNS_LightMode = on; applyTheme(); saveSettings()
        if _G.UNScripts and _G.UNScripts.onLightModeChange then _G.UNScripts.onLightModeChange(on) end
        local mainPath = CFG_FOLDER.."/".."settings_plugin"..CFG_EXT
        local mainCfg = cfgSafely(readfile, mainPath) and cfgSafely(function() return HttpService:JSONDecode(cfgSafely(readfile, mainPath)) end) or {}
        if type(mainCfg) ~= "table" then mainCfg = {} end
        mainCfg.lightMode = on
        cfgSafely(writefile, mainPath, HttpService:JSONEncode(mainCfg))
    end, cfgLightMode)
    _G.UNScripts_Secondary.onLightModeChange = function(on)
        cfgLightMode = on; _G.UNS_LightMode = on; applyTheme()
        if lightModeToggle then lightModeToggle.SetOn(on, true) end
    end

    local slPill = Make("Frame", {Size = ud2(1,-8,0,45), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 1, Parent = appSec})
    slPill:SetAttribute("SearchName", "Transparency")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = slPill})
    Make("TextLabel", {Size = ud2(0,120,0,20), Position = ud2(0,14,0,6),
        BackgroundTransparency = 1, Text = "Transparency",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = slPill})
    local slVal = Make("TextLabel", {Size = ud2(0,36,0,20), Position = ud2(1,-50,0,6),
        BackgroundTransparency = 1, Text = math.floor(cfgTransparency/0.85*100+0.5).."%",
        TextColor3 = C.textSec, TextSize = 10, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = slPill})
    local slTrack = Make("Frame", {Size = ud2(1,-28,0,6), Position = ud2(0,14,0,32),
        BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Parent = slPill})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = slTrack})
    local initF = cfgTransparency / 0.85
    local slFill = Make("Frame", {Size = ud2(initF,0,1,0), BackgroundColor3 = C.accent,
        BackgroundTransparency = 0, BorderSizePixel = 0, Parent = slTrack})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = slFill})
    local slKnob = Make("TextButton", {Size = ud2(0,14,0,14), Position = ud2(initF,-7,0,-4),
        BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "", Parent = slTrack})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = slKnob})
    Make("UIStroke", {Color = rgb(80,80,80), Thickness = 1, Transparency = 0.3, Parent = slKnob})
    local slDrag = false
    local function updSl(x)
        local f = math.clamp((x - slTrack.AbsolutePosition.X) / slTrack.AbsoluteSize.X, 0, 1)
        TweenService:Create(slFill, TweenInfo.new(0.08), {Size = ud2(f,0,1,0)}):Play()
        slKnob.Position = ud2(f,-7,0,-4); slVal.Text = math.floor(f*100+0.5).."%"
        applyTransparency(f * 0.85); syncTransparencyToMain()
    end
    slKnob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slDrag = true end
    end)
    Make("TextButton", {Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
        BackgroundTransparency = 1, Text = "", ZIndex = slKnob.ZIndex - 1, Parent = slTrack
    }).InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then slDrag = true; updSl(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and slDrag then slDrag = false; saveSettings() end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if slDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then updSl(i.Position.X) end
    end)
    
    local _, splSec, splObj = makeSetSection(ScrollThemes, "Scripts Page Layout", PART_H, true)
    
    makeSetDropdown(splSec, splObj, "Collapse Button", {"Right", "Left"}, cfgCollapsePos, function(val)
        cfgCollapsePos = val
        saveSettings()
        if _G.UNScripts_Secondary and _G.UNScripts_Secondary.SetCollapsePosition then
            _G.UNScripts_Secondary.SetCollapsePosition(val)
        end
    end)

    local PA = {TopCenter = {x=0.5, y=0.02}, BottomCenter = {x=0.5, y=0.97}}
    local PA_KEYS = {"TopCenter","BottomCenter"}; local PA_LBLS = {"Top Middle","Bottom Middle"}
    if not PA[cfgPillAnchor] then cfgPillAnchor = "TopCenter" end
    local PILL_H = ud2(0,110,0,34); local PILL_V = ud2(0,34,0,90)
    local function applyAnchor(k)
        cfgPillAnchor = k
        local a = PA[k]
        if a and PillUI then
            PillUI.AnchorPoint = Vector2.new(0.5, a.y < 0.5 and 0 or 1)
            TweenService:Create(PillUI, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromScale(a.x, a.y)}):Play()
        end
        saveSettings()
    end
    local function applyPlace(p)
        if not PillUI then return end
        PillUI.AnchorPoint = Vector2.new(p.ax, p.ay)
        TweenService:Create(PillUI, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(p.px, p.pxo, p.py, p.pyo)}):Play()
    end
    local MAX_PL = 4
    local pH = 18 + 5 + 26 + 5 + 1 + 5 + PART_H + 5 + 1 + 5 + 18 + 5 + 30 + 5 + MAX_PL * (26 + 5)
    local _, pSec = makeSetSection(ScrollThemes, "Pill Placement", pH, true)

    local snapLbl = Make("Frame", {Size = ud2(1,-8,0,18), BackgroundTransparency = 1, LayoutOrder = 0, Parent = pSec})
    Make("TextLabel", {Size = ud2(0,90,1,0), BackgroundTransparency = 1, Text = "Snap Position",
        TextColor3 = C.textSec, TextSize = 10, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = snapLbl})

    local snapRow = Make("Frame", {Size = ud2(1,-8,0,26), BackgroundTransparency = 1, LayoutOrder = 1, Parent = pSec})
    Make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = ud(0,8), Parent = snapRow})
    for i, k in ipairs(PA_KEYS) do
        local b = Make("TextButton", {Size = ud2(0,120,0,26), Text = PA_LBLS[i],
            TextColor3 = C.textPri, TextSize = 10, Font = bold,
            BackgroundColor3 = (cfgPillAnchor == k) and C.accent or C.surfaceAlt,
            BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = snapRow})
        Make("UICorner", {CornerRadius = ud(0,6), Parent = b})
        b.MouseButton1Click:Connect(function()
            applyAnchor(k)
            for _, c in ipairs(snapRow:GetChildren()) do
                if c:IsA("TextButton") then
                    local isActive = (c == b)
                    local tKey = isActive and "accent" or "surfaceAlt"
                    updateThemeTag(c, "BackgroundColor3", tKey)
                    
                    local p = cfgLightMode and LC or C
                    TweenService:Create(c, TweenInfo.new(0.15), {BackgroundColor3 = p[tKey]}):Play()
                end
            end
        end)
    end

    Make("Frame", {Size = ud2(1,-8,0,1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = 2, Parent = pSec})

    local orientRow = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 3, Parent = pSec})
    orientRow:SetAttribute("SearchName", "Vertical Layout")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = orientRow})
    Make("TextLabel", {Size = ud2(0,140,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = "Vertical Layout",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = orientRow})
    makeToggle(orientRow, (PART_H-18)/2, function(on)
        cfgPillVertical = on
        if _G.UNScripts_Secondary then _G.UNScripts_Secondary.PillVertical = on end
        if PillUI and PillUI.Visible then
            if on then PillUI.Size = PILL_V; PillUI.Text = "U\nN\nS"
            else PillUI.Size = PILL_H; PillUI.Text = "UNScripts Secondary" end
        end
        saveSettings()
    end, cfgPillVertical)

    Make("Frame", {Size = ud2(1,-8,0,1), BackgroundColor3 = C.border,
        BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = 4, Parent = pSec})

    local cpLbl = Make("Frame", {Size = ud2(1,-8,0,18), BackgroundTransparency = 1, LayoutOrder = 5, Parent = pSec})
    Make("TextLabel", {Size = ud2(0,130,1,0), BackgroundTransparency = 1,
        Text = "Custom Placements", TextColor3 = C.textSec, TextSize = 10, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = cpLbl})

    local svRow = Make("Frame", {Size = ud2(1,-8,0,30), BackgroundTransparency = 1, LayoutOrder = 6, Parent = pSec})
    local pBox = Make("TextBox", {Size = ud2(1,-92,0,26), Position = ud2(0,0,0,2),
        BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        Text = "", PlaceholderText = "Placement name...", ClearTextOnFocus = false,
        TextColor3 = C.textPri, PlaceholderColor3 = C.textSec, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = svRow})
    Make("UICorner", {CornerRadius = ud(0,6), Parent = pBox})
    Make("UIPadding", {PaddingLeft = ud(0,10), PaddingRight = ud(0,6), Parent = pBox})
    local svBtn = Make("TextButton", {Size = ud2(0,84,0,26), Position = ud2(1,-84,0,2),
        BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, BorderSizePixel = 0,
        Text = "Save", TextColor3 = C.white, TextSize = 11, Font = bold, Parent = svRow})
    Make("UICorner", {CornerRadius = ud(0,6), Parent = svBtn})

    local plCon = Make("Frame", {Size = ud2(1,-8,0,0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 7, Parent = pSec})
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = plCon})
    local function refSlots()
        for _, c in ipairs(plCon:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for idx, d in ipairs(cfgPillPlacements) do
            local r = Make("Frame", {Size = ud2(1,0,0,26), BackgroundColor3 = C.part_bg,
                BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = idx, Parent = plCon})
            Make("UICorner", {CornerRadius = ud(1,0), Parent = r})
            Make("TextLabel", {Size = ud2(1,-70,1,0), Position = ud2(0,12,0,0),
                BackgroundTransparency = 1, Text = d.name, TextColor3 = C.textPri,
                TextSize = 10, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = r})
            local ld = Make("TextButton", {Size = ud2(0,44,0,18), Position = ud2(1,-64,0,4),
                BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
                Text = "Load", TextColor3 = C.white, TextSize = 9, Font = bold, Parent = r})
            Make("UICorner", {CornerRadius = ud(1,0), Parent = ld})
            local dl = Make("TextButton", {Size = ud2(0,18,0,18), Position = ud2(1,-18,0,4),
                BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.3,
                Text = "×", TextColor3 = C.white, TextSize = 11, Font = bold, Parent = r})
            Make("UICorner", {CornerRadius = ud(1,0), Parent = dl})
            ld.MouseButton1Click:Connect(function() applyPlace(d) end)
            dl.MouseButton1Click:Connect(function()
                table.remove(cfgPillPlacements, idx); saveSettings(); refSlots()
            end)
        end
    end
    svBtn.MouseButton1Click:Connect(function()
        if #cfgPillPlacements >= MAX_PL then svBtn.Text = "Full!"; task.delay(1, function() if svBtn and svBtn.Parent then svBtn.Text = "Save" end end); return end
        local nm = pBox.Text; if nm == "" then nm = "Placement " .. (#cfgPillPlacements + 1) end
        if PillUI then table.insert(cfgPillPlacements, {
            name = nm, ax = PillUI.AnchorPoint.X, ay = PillUI.AnchorPoint.Y,
            px = PillUI.Position.X.Scale, pxo = PillUI.Position.X.Offset,
            py = PillUI.Position.Y.Scale, pyo = PillUI.Position.Y.Offset,
        }) end
        pBox.Text = ""; saveSettings(); refSlots()
    end)
    refSlots()
    applyAnchor(cfgPillAnchor)
    if _G.UNScripts_Secondary then
        _G.UNScripts_Secondary.PillVertical = cfgPillVertical
        _G.UNScripts_Secondary.SaveInventory = cfgSaveInventory
    end
    if PillUI and PillUI.Visible then
        if cfgPillVertical then PillUI.Size = PILL_V; PillUI.Text = "U\nN\nS"
        else PillUI.Size = PILL_H; PillUI.Text = "UNScripts Secondary" end
    end

    -- ════════════════════════════ SYSTEM ════════════════════════════
    local _, rsSec = makeSetSection(ScrollSystem, "System Actions", PART_H * 3 + 10, true)

    local frBtn = Make("TextButton", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.dot_red,
        BackgroundTransparency = 0.1, Text = "Factory Reset",
        TextColor3 = C.white, TextSize = 11, Font = bold, LayoutOrder = 2, Parent = rsSec})
    frBtn:SetAttribute("SearchName", "Factory Reset")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = frBtn})

    local ResetOverlay = Make("Frame", {Size = ud2(1,0,1,0), Position = ud2(0,0,0,0),
        BackgroundColor3 = C.bg, BackgroundTransparency = 0, BorderSizePixel = 0,
        ZIndex = 100, Active = true, Visible = false, Parent = Main})
    Make("UICorner", {CornerRadius = ud(0,16), Parent = ResetOverlay})
    local rCon = Make("Frame", {Size = ud2(0,300,0,240), Position = ud2(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Parent = ResetOverlay})
    Make("TextLabel", {Size = ud2(0,44,0,44), Position = ud2(0.5,-22,0,0),
        BackgroundTransparency = 1, Text = "⚠", TextColor3 = C.dot_red, TextSize = 32, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Center, Parent = rCon})
    Make("TextLabel", {Size = ud2(1,0,0,24), Position = ud2(0,0,0,50),
        BackgroundTransparency = 1, Text = "Factory Reset?", TextColor3 = C.dot_red,
        TextSize = 15, Font = bold, TextXAlignment = Enum.TextXAlignment.Center, Parent = rCon})
    Make("TextLabel", {Size = ud2(1,0,0,54), Position = ud2(0,0,0,80),
        BackgroundTransparency = 1,
        Text = "This will permanently wipe all saved settings.\nThe UI will also be destroyed.\nThis action cannot be undone.",
        TextColor3 = C.textSec, TextSize = 11, Font = reg,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = rCon})
    Make("Frame", {Size = ud2(0,200,0,1), Position = ud2(0.5,-100,0,166),
        BackgroundColor3 = C.border, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = rCon})
    local rYes = Make("TextButton", {Size = ud2(0,120,0,34), Position = ud2(0.5,-128,0,182),
        BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.1,
        Text = "Wipe Data", TextColor3 = C.white, TextSize = 12, Font = bold, Parent = rCon})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = rYes})
    local rNo = Make("TextButton", {Size = ud2(0,120,0,34), Position = ud2(0.5,8,0,182),
        BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
        Text = "Cancel", TextColor3 = C.textPri, TextSize = 12, Font = bold, Parent = rCon})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = rNo})
    local function doReset()
        ResetOverlay.Visible = false
        local p = CFG_FOLDER.."/"..PLG_FILE..CFG_EXT; if cfgSafely(isfile, p) then cfgSafely(delfile, p) end
        local s = CFG_FOLDER.."/settings_secondary.cfg"; if cfgSafely(isfile, s) then cfgSafely(delfile, s) end
        if Gui and Gui.Parent then Gui:Destroy() end
    end
    
    frBtn.MouseButton1Click:Connect(function() ResetOverlay.Visible = true end)
    rYes.MouseButton1Click:Connect(doReset)
    rNo.MouseButton1Click:Connect(function() ResetOverlay.Visible = false end)

    local svPill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 1, Parent = rsSec})
    svPill:SetAttribute("SearchName", "Save Inventory")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = svPill})
    Make("TextLabel", {Size = ud2(0,140,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = "Save Inventory",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = svPill})
    makeToggle(svPill, (PART_H-18)/2, function(on)
        cfgSaveInventory = on
        if _G.UNScripts_Secondary then _G.UNScripts_Secondary.SaveInventory = on end
        saveSettings()
    end, cfgSaveInventory)

    -- ════════════════════════════ NOTIFICATIONS ════════════════════════════
    local _, notifSec, notifObj = makeSetSection(ScrollSystem, "Notifications", PART_H * 4 + 15, true)

    local notifPill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = notifSec})
    notifPill:SetAttribute("SearchName", "Notifications")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = notifPill})
    Make("TextLabel", {Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
        BackgroundTransparency = 1, Text = "Notifications",
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = notifPill})

    makeToggle(notifPill, (PART_H-18)/2, function(on)
        notifCfg.enabled = on
    end, notifCfg.enabled)

    makeSetDropdown(notifSec, notifObj, "Corner", {"TopLeft","TopRight","BottomLeft","BottomRight"}, notifCfg.corner, function(val)
        applyNotifCorner(val)
    end)

    makeSetDropdown(notifSec, notifObj, "Size", {"Small","Medium","Large"}, notifCfg.size or "Medium", function(val)
        applyNotifSize(val)
    end)

    local testBtn = Make("TextButton", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.accent,
        BackgroundTransparency = 0.1, Text = "Run Test",
        TextColor3 = C.white, TextSize = 11, Font = bold, Parent = notifSec,
    })
    testBtn:SetAttribute("SearchName", "Run Test")
    Make("UICorner", {CornerRadius = ud(1,0), Parent = testBtn})
    testBtn.MouseButton1Click:Connect(function()
        notify("", "This is a test notification!\nYou can change the corner in the dropdown above.", 5)
    end)

    ToggleBtn.MouseButton1Click:Connect(function()
        local inS = not SetPage.Visible
        ToggleBtn.Text = inS and "📄" or "⚙"
        if inS then
            for _, c in ipairs(Main:GetChildren()) do
                if c:IsA("Frame") and c ~= MainPage and c ~= SetPage and c.Visible and c.Size == ud2(1,0,1,-42) and c.Position == ud2(0,0,0,42) then
                    c.Visible = false
                end
            end
        end
        MainPage.Visible = not inS
        SetPage.Visible = inS
        if not inS and searchOpen then closeSearch() end
    end)

    -- ════════════════════════════ KEYBIND LISTENER ════════════════════════════
    UserInputService.InputBegan:Connect(function(input, proc)
        if not Gui or not Gui.Parent then return end
        if proc then return end
        if CloseOverlay and CloseOverlay.Visible then return end
        if ResetOverlay.Visible then return end
        if searchOpen and input.KeyCode == Enum.KeyCode.Escape then closeSearch(); return end

        if listeningKey and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                table.insert(tempKeys, input.KeyCode)
                if #tempKeys == 1 then
                    KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + ? ]"
                elseif #tempKeys == 2 then
                    activeKeybind = {tempKeys[1], tempKeys[2]}
                    listeningKey = false
                    updateThemeTag(KeybindBtn, "TextColor3", "textPri")
                    local p = cfgLightMode and LC or C
                    KeybindBtn.TextColor3 = p["textPri"]
                    KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + " .. tempKeys[2].Name .. " ]"
                    saveSettings()
                end
            end
            return
        end

        if not listeningKey and input.UserInputType == Enum.UserInputType.Keyboard then
            if #activeKeybind == 2 then
                if (input.KeyCode == activeKeybind[2] and UserInputService:IsKeyDown(activeKeybind[1]))
                or (input.KeyCode == activeKeybind[1] and UserInputService:IsKeyDown(activeKeybind[2])) then
                    if _G.UNScripts_Secondary and _G.UNScripts_Secondary.ToggleUI then
                        _G.UNScripts_Secondary.ToggleUI()
                    end
                end
            end
            -- Check script keybinds
            for _, scr in ipairs(scriptKeybindList) do
                if scr.key1 then
                    local kc1 = keycodeFromName(scr.key1)
                    if scr.mode == 1 then
                        if input.KeyCode == kc1 then scr.toggleFn() end
                    elseif scr.mode == 2 and scr.key2 then
                        local kc2 = keycodeFromName(scr.key2)
                        if (input.KeyCode == kc1 and UserInputService:IsKeyDown(kc2))
                        or (input.KeyCode == kc2 and UserInputService:IsKeyDown(kc1)) then
                            scr.toggleFn()
                        end
                    end
                end
            end
        end
    end)
    
    if _G.UNScripts_Secondary and _G.UNScripts_Secondary.SetCollapsePosition then
        _G.UNScripts_Secondary.SetCollapsePosition(cfgCollapsePos)
    end

    applyTheme()
    applyTransparency(cfgTransparency)
    print("[UNScripts Secondary Plugin] Settings overlay injected successfully")
end

local ok, err = pcall(injectSettings)
if not ok then
    warn("[UNScripts Secondary Plugin] Failed:", err)
end