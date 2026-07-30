-- ============================================================
--  UNScripts UI  |  Executor: Velocity
--  HOST UI SHELL — Settings page removed.
--  Core window/pill framework + Global Modular API (_G.UNScripts)
--  remain fully intact for external plugin scripts.
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local uiParent
do
    local ok = pcall(function() game:GetService("CoreGui"):IsA("DataModel") end)
    uiParent = ok and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
end

if not _G.sectionToggles then _G.sectionToggles = setmetatable({}, {__mode = "k"}) end

if not _G.passiveScrollFrames then _G.passiveScrollFrames = {} end
local function makePassiveScrollable(sf)
    sf.Active = false
    table.insert(_G.passiveScrollFrames, sf)
    sf.Destroying:Connect(function()
        for i, v in ipairs(_G.passiveScrollFrames) do
            if v == sf then table.remove(_G.passiveScrollFrames, i); break end
        end
    end)
end
local scrollConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local m = UserInputService:GetMouseLocation()
        for _, sf in ipairs(_G.passiveScrollFrames) do
            if sf.Visible then
                local ap, as = sf.AbsolutePosition, sf.AbsoluteSize
                if m.X >= ap.X and m.X <= ap.X + as.X and m.Y >= ap.Y and m.Y <= ap.Y + as.Y then
                    local amt = -input.Position.Z * 36
                    local n = sf.CanvasPosition.Y + amt
                    local mx = math.max(0, sf.CanvasSize.Y.Offset - as.Y)
                    sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, math.clamp(n, 0, mx))
                end
            end
        end
    end
end)

local rgb  = Color3.fromRGB
local ud2  = UDim2.new
local ud   = UDim.new
local bold = Enum.Font.GothamBold
local reg  = Enum.Font.Gotham
local semi = Enum.Font.GothamSemibold

local C = {
    bg         = rgb(25, 25, 25),
    surface    = rgb(35, 35, 35),
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

local CFG_FOLDER = "UNScripts"
local CFG_FILE   = "settings"
local CFG_EXT    = ".cfg"

local function cfgSafely(fn, ...)
    if fn then
        local ok, res = pcall(fn, ...)
        if not ok then return nil end
        return res
    end
end

local function ensureCfgFolder()
    if isfolder and not cfgSafely(isfolder, CFG_FOLDER) then
        cfgSafely(makefolder, CFG_FOLDER)
    end
end

local function saveConfig(data)
    ensureCfgFolder()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        cfgSafely(writefile, CFG_FOLDER.."/"..CFG_FILE..CFG_EXT, encoded)
    end
end

local function loadConfig()
    local path = CFG_FOLDER.."/"..CFG_FILE..CFG_EXT
    if not cfgSafely(isfile, path) then return nil end
    local content = cfgSafely(readfile, path)
    if not content then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    return ok and data or nil
end

local savedCfg = loadConfig() or {}

local cfgIsExpanded      = savedCfg.isExpanded or false
local cfgFavorites       = savedCfg.favorites or {}
local cfgSliderFavs      = savedCfg.sliderFavs or {}
local cfgPageData        = savedCfg.pageData or {}
local cfgAutoExec        = savedCfg.autoExec or {}
local cfgLightMode       = savedCfg.lightMode or false

local isExpanded         = cfgIsExpanded
_G.autoExecFeatures = cfgAutoExec
_G.UNS_LightMode = cfgLightMode

local function triggerAutoSave()
    local cleanPageData = {}
    for uid, meta in pairs(cfgPageData) do
        if cfgFavorites[uid] then cleanPageData[uid] = meta end
    end
    saveConfig({
        isExpanded    = isExpanded,
        favorites     = cfgFavorites,
        sliderFavs    = cfgSliderFavs,
        pageData      = cleanPageData,
        autoExec      = _G.autoExecFeatures,
        lightMode     = cfgLightMode,
    })
end

-- Theme Registry to update colors dynamically
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

if type(_G.UNS_HostCleanup) == "function" then _G.UNS_HostCleanup() end
_G.UNS_HostCleanup = function()
    if scrollConn then scrollConn:Disconnect(); scrollConn = nil end
    if closeOverlayConn then closeOverlayConn:Disconnect(); closeOverlayConn = nil end
    if _G.UNS_CleanupList then
        for _, fn in ipairs(_G.UNS_CleanupList) do
            pcall(fn)
        end
        _G.UNS_CleanupList = {}
    end
    pcall(function()
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        Lighting.FogEnd = 500
        Lighting.FogStart = 0
        Lighting.GlobalShadows = true
        Lighting.ClockTime = 14
        Lighting.GeographicLatitude = 45
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v:Destroy()
            end
        end
    end)
    -- Only destroy the main interface, not all plugins' GUIs
    pcall(function()
        local mainGui = uiParent:FindFirstChild("UNScriptsInterface")
        if mainGui then mainGui:Destroy() end
    end)
    _G.passiveScrollFrames = {}
    _G.sectionToggles = setmetatable({}, {__mode = "k"})
    _G.UNScripts = {}
end
if not _G.UNS_CleanupList then _G.UNS_CleanupList = {} end

local existingGui = uiParent:FindFirstChild("UNScriptsInterface")
if existingGui then existingGui:Destroy() end

local Gui = Make("ScreenGui", {
    Name           = "UNScriptsInterface",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent         = uiParent,
})

local NORMAL_W, NORMAL_H = 360, 480

local Main = Make("Frame", {
    Size                   = ud2(0, NORMAL_W, 0, NORMAL_H),
    Position               = ud2(0.5, 0, 0.5, 0),
    AnchorPoint            = Vector2.new(0.5, 0.5),
    BackgroundColor3       = C.bg,
    BackgroundTransparency = 0,
    BorderSizePixel        = 0,
    ClipsDescendants       = true,
    Parent                 = Gui,
})
Make("UICorner", {CornerRadius = ud(0, 16), Parent = Main})
Make("UIStroke",  {Color = C.white, Thickness = 1, Transparency = 0.7, Parent = Main})

local MainScale = Make("UIScale", {Scale = isExpanded and 1.4 or 1, Parent = Main})

local BorderFrame = Make("Frame", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 99, Parent = Main,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = BorderFrame})
Make("UIStroke",  {Color = C.white, Thickness = 1, Transparency = 0.85, Parent = BorderFrame})

local HeaderBar = Make("Frame", {
    Size = ud2(1,0,0,42), BackgroundTransparency = 1,
    BorderSizePixel = 0, Active = true, Parent = Main,
})

local function makeDot(xPos, color, parent)
    local dot = Make("TextButton", {
        Size = ud2(0,13,0,13), Position = ud2(0,xPos,0,15),
        Text = "", BackgroundColor3 = color,
        BorderSizePixel = 0, Parent = parent or HeaderBar,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = dot})
    return dot
end
local CloseBtn = makeDot(14, C.dot_red)
local MinBtn   = makeDot(32, C.dot_yel)
local MaxBtn   = makeDot(50, C.dot_grn)

local TitleLabel = Make("TextLabel", {
    Size = ud2(0,100,0,42), Position = ud2(0.5,-50,0,0),
    BackgroundTransparency = 1, Text = '<font color="rgb(50,120,255)">UN</font>Scripts',
    TextColor3 = C.textPri, TextSize = 13, Font = bold, RichText = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = HeaderBar,
})

local function makeHeaderIcon(xOffset, icon)
    return Make("TextButton", {
        Size = ud2(0,28,0,28), Position = ud2(1,xOffset,0,7),
        BackgroundTransparency = 1, Text = icon,
        TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
    })
end

local PillUI = Make("TextButton", {
    Size = ud2(0,110,0,34), Position = ud2(0.5,0,0,12),
    AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.bg,
    BackgroundTransparency = 0, Text = '<font color="rgb(50,120,255)">UN</font>Scripts',
    TextColor3 = C.textPri, Font = bold, TextSize = 12, RichText = true,
    Active = true, Visible = false, Parent = Gui,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PillUI})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = PillUI})
local PillScale = Make("UIScale", {Scale = 1, Parent = PillUI})

local MainPage = Make("Frame", {
    Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
})

local partState       = {}
local toggleCallbacks = {} 

local originalToggles = {}
_G.UNS_OriginalToggles = originalToggles
local proxyToggles    = {}

-- ==========================================
-- Close Confirmation Overlay
-- ==========================================

local CloseOverlay = Make("Frame", {
    Size                   = ud2(1,0,1,0),
    Position               = ud2(0,0,0,0),
    BackgroundColor3       = C.bg,
    BackgroundTransparency = 0,
    BorderSizePixel        = 0,
    ZIndex                 = 100,
    Active                 = true,
    Visible                = false,
    Parent                 = Main,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = CloseOverlay})

local CloseContainer = Make("Frame", {
    Size = ud2(0, 300, 0, 240), Position = ud2(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
    Parent = CloseOverlay,
})

Make("TextLabel", {
    Size = ud2(0,44,0,44), Position = ud2(0.5,-22,0,0),
    BackgroundTransparency = 1, Text = "⚠",
    TextColor3 = C.dot_yel, TextSize = 32, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = CloseContainer,
})
Make("TextLabel", {
    Size = ud2(1,0,0,24), Position = ud2(0,0,0,50),
    BackgroundTransparency = 1, Text = "Close UNScripts?",
    TextColor3 = C.white, TextSize = 15, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = CloseContainer,
})
Make("TextLabel", {
    Size = ud2(1,0,0,54), Position = ud2(0,0,0,80),
    BackgroundTransparency = 1,
    Text = "This will destroy the interface.\nYour saved settings will remain intact.\nYou will need to re-execute to open it again.",
    TextColor3 = C.textSec, TextSize = 11, Font = reg,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = CloseContainer,
})
Make("TextLabel", {
    Size = ud2(1,0,0,16), Position = ud2(0,0,0,140),
    BackgroundTransparency = 1, Text = "[ Enter ] = Yes      [ Backspace ] = No",
    TextColor3 = C.textSec, TextSize = 10, Font = reg,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = CloseContainer,
})
Make("Frame", {
    Size = ud2(0,200,0,1), Position = ud2(0.5,-100,0,166),
    BackgroundColor3 = C.border, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, Parent = CloseContainer,
})
local CloseYesBtn = Make("TextButton", {
    Size = ud2(0,120,0,34), Position = ud2(0.5,-128,0,182),
    BackgroundColor3 = C.dot_yel, BackgroundTransparency = 0.1,
    Text = "Yes, Close", TextColor3 = C.bg,
    TextSize = 12, Font = bold, Parent = CloseContainer,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = CloseYesBtn})
local CloseNoBtn = Make("TextButton", {
    Size = ud2(0,120,0,34), Position = ud2(0.5,8,0,182),
    BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
    Text = "Cancel", TextColor3 = C.textPri,
    TextSize = 12, Font = bold, Parent = CloseContainer,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = CloseNoBtn})

local function runClose()
	CloseOverlay.Visible = false
	if Gui and Gui.Parent then Gui:Destroy() end
end

CloseYesBtn.MouseButton1Click:Connect(runClose)
CloseNoBtn.MouseButton1Click:Connect(function() CloseOverlay.Visible = false end)

local closeOverlayConn = UserInputService.InputBegan:Connect(function(input, processed)
    if CloseOverlay.Visible then
        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            runClose()
        elseif input.KeyCode == Enum.KeyCode.Backspace then
            CloseOverlay.Visible = false
        end
    end
end)


local activeTab   = ""
local tabs        = {}
local tabContainers = {}
local tabSections = {Home = {}, Scripts = {}}
local tabTween    = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local sectionTween= TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local TabBar = Make("Frame", {
    Size = ud2(1,-24,0,30), Position = ud2(0,12,0,8),
    BackgroundTransparency = 1, Parent = MainPage,
})

local TabsRow = Make("Frame", {
    Size = ud2(1,-32,1,0), Position = ud2(0,0,0,0),
    BackgroundTransparency = 1, Parent = TabBar,
})
Make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = ud(0,6), Parent = TabsRow,
})

local function makeTab(name)
    local btn = Make("TextButton", {
        Size = ud2(0,64,0,26), BackgroundColor3 = C.surfaceAlt,
        BackgroundTransparency = 0, Text = name,
        TextColor3 = C.textSec, TextSize = 12, Font = bold, RichText = true, Parent = TabsRow,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = btn})
    local pill = Make("Frame", {
        Size = ud2(0,0,0,2), Position = ud2(0.5,0,1,-2),
        AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.accent,
        BorderSizePixel = 0, Parent = btn,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("UIStroke", {Color = C.tab_stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn})
    return {Button = btn, Pill = pill, Name = name}
end

local CollapseAllBtn = Make("TextButton", {
    Size = ud2(0,26,0,26), Position = ud2(1,-30,0.5,-13),
    BackgroundColor3 = C.surfaceAlt,
    BackgroundTransparency = 0.3, Text = "^", TextColor3 = C.textSec,
    TextSize = 14, Font = bold, Visible = false, Parent = TabBar,
})
Make("UICorner", {CornerRadius = ud(0,6), Parent = CollapseAllBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = CollapseAllBtn})

local TabContent = Make("Frame", {
    Size = ud2(1,-24,1,-44), Position = ud2(0,12,0,44),
    BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainPage,
})
local SectionScroll = Make("ScrollingFrame", {
    Size = ud2(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = TabContent,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,0), Parent = SectionScroll})

_G.UNS_PageScroll = nil

-- SMOOTH TOGGLE
local rebuildFavorites, rebuildActive, rebuildAutoExec
local openCtxMenu, closeCtxMenu
local toggleTween    = TweenInfo.new(0.22, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
local toggleSpring   = TweenInfo.new(0.18, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)
local toggleColorTI  = TweenInfo.new(0.20, Enum.EasingStyle.Linear)
local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function makeToggle(parent, yPos, callback, initOn, uid)
    local track = Make("Frame", {
        Size = ud2(0,38,0,20),
        Position = ud2(1,-48,0,yPos),
        BackgroundColor3 = initOn and C.toggle_on or C.toggle_off,
        BorderSizePixel = 0,
        Parent = parent
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
    Make("UIStroke",  {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.82, Parent = track})

    local knob = Make("Frame", {
        Size = ud2(0,16,0,16),
        Position = initOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8),
        BackgroundColor3 = C.knob,
        BorderSizePixel = 0,
        Parent = track
    })
    Make("UICorner",  {CornerRadius = ud(1,0), Parent = knob})
    Make("UIStroke",  {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.72, Parent = knob})

    local isOn = initOn == true
    local hitbox = Make("TextButton", {
        Size = ud2(1,0,1,0), BackgroundTransparency = 1,
        Text = "", ZIndex = knob.ZIndex + 1, Parent = track,
    })

    local dimOver = Make("Frame", {
        Size = ud2(1,0,1,0), BackgroundColor3 = rgb(0,0,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 10, Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = dimOver})

    hitbox.MouseEnter:Connect(function()
        TweenService:Create(dimOver, hoverTweenInfo, {BackgroundTransparency = 0.72}):Play()
    end)
    hitbox.MouseLeave:Connect(function()
        TweenService:Create(dimOver, hoverTweenInfo, {BackgroundTransparency = 1}):Play()
    end)

    local function setOn(state, silent)
        isOn  = state
        local targetColorKey = isOn and "toggle_on" or "toggle_off"
        updateThemeTag(track, "BackgroundColor3", targetColorKey)

        TweenService:Create(track, toggleColorTI, {
            BackgroundColor3 = C[targetColorKey]
        }):Play()
        TweenService:Create(knob, toggleSpring, {
            Position = isOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8)
        }):Play()
        if callback and not silent then callback(isOn) end
    end

    hitbox.MouseButton1Click:Connect(function() setOn(not isOn, false) end)
    return {Track = track, Knob = knob, IsOn = function() return isOn end, SetOn = setOn}
end

local PART_H = 32
local SECTION_H = 38
local SLIDER_H = 48
local LABEL_H = 22

local sliderFavObj = {}
local sliderParams = {}
local buttonParams = {}
local dropdownParams = {}
local pageButtonParams = {}

local function makeSlider(parent, label, minV, maxV, defaultV, callback, uid, isProxy, layoutOrder)
    local savedVal = uid and cfgSliderFavs[uid]
    local val = savedVal or defaultV or minV
    if not isProxy and uid then
        sliderParams[uid] = { label = label, minV = minV, maxV = maxV, defaultV = defaultV, callback = callback }
    end
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,SLIDER_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0, Parent = parent,
        Active = true,
    })
    pill:SetAttribute("SearchName", label)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})

    Make("TextLabel", {
        Size = ud2(0,110,0,20), Position = ud2(0,30,0,6),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })

    local valInput = Make("TextBox", {
        Size = ud2(0,42,0,20), Position = ud2(1,-56,0,6),
        BackgroundTransparency = 1, Text = tostring(val),
        TextColor3 = C.textSec, TextSize = 10, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = pill,
        ClearTextOnFocus = false,
    })

    local track = Make("Frame", {
        Size = ud2(1,-28,0,6), Position = ud2(0,14,0,32),
        BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = track})

    local frac = math.max((val - minV) / (maxV - minV), 0.01)
    local fill = Make("Frame", {
        Size = ud2(frac, 0, 1, 0), BackgroundColor3 = C.accent,
        BackgroundTransparency = 0, BorderSizePixel = 0, Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = fill})

    local knob = Make("TextButton", {
        Size = ud2(0,14,0,14), Position = ud2(frac, -7, 0, -4),
        BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "", Parent = track,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
    Make("UIStroke", {Color = rgb(80,80,80), Thickness = 1, Transparency = 0.3, Parent = knob})

    local dragging = false

    local function setVal(v)
        v = math.clamp(v, minV, maxV)
        val = v
        valInput.Text = tostring(v)
        local p = (v - minV) / (maxV - minV)
        TweenService:Create(fill, TweenInfo.new(0.1), {Size = ud2(p, 0, 1, 0)}):Play()
        knob.Position = ud2(p, -7, 0, -4)
        if uid then
            cfgSliderFavs[uid] = val
            if cfgPageData[uid] then cfgPageData[uid].val = val end
        end
        if callback then callback(val) end
    end
    if not isProxy and uid then
        sliderParams[uid].setVal = setVal
    end

    valInput.FocusLost:Connect(function()
        local num = tonumber(valInput.Text)
        if num then
            setVal(num)
        else
            valInput.Text = tostring(val)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)

    local hitbox = Make("TextButton", {
        Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
        BackgroundTransparency = 1, Text = "", ZIndex = knob.ZIndex - 1, Parent = track,
    })
    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setVal(math.floor(minV + (maxV - minV) * rel + 0.5))
        end
    end)

    local ec = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if rebuildFavorites then rebuildFavorites() end
        end
    end)
    local rc = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setVal(math.floor(minV + (maxV - minV) * rel + 0.5))
        end
    end)
    pill.Destroying:Connect(function() ec:Disconnect(); rc:Disconnect() end)

    if uid then
        if isProxy then
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,2),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = C.dot_yel, TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = false
                if sliderFavObj[uid] and sliderFavObj[uid].star then
                    updateThemeTag(sliderFavObj[uid].star, "TextColor3", "textSec")
                    sliderFavObj[uid].star.TextColor3 = C.textSec
                end
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        else
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,2),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                if cfgFavorites[uid] then
                    cfgSliderFavs[uid] = val
                end
                if sliderFavObj[uid] and sliderFavObj[uid].star and sliderFavObj[uid].star ~= star then
                    updateThemeTag(sliderFavObj[uid].star, "TextColor3", colorKey)
                    sliderFavObj[uid].star.TextColor3 = C[colorKey]
                end
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
            sliderFavObj[uid] = { name = label, star = star, pill = pill, getVal = function() return val end }
        end
    end

        if uid and not isProxy then
            pill.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    openCtxMenu({
                        type = "slider",
                        uid = uid,
                        label = label,
                    }, Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
        end

    return pill
end

local function makeButton(parent, label, callback, uid, isProxy, layoutOrder)
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0, Parent = parent,
        Active = true,
    })
    pill:SetAttribute("SearchName", label)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = pill})

    local lbl = Make("TextLabel", {
        Size = ud2(0,120,1,0), Position = ud2(0,30,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = semi,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })

    local btn = Make("TextButton", {
        Size = ud2(0,70,0,22), Position = ud2(1,-80,0.5,-11),
        BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
        Text = "Run", TextColor3 = C.white,
        TextSize = 10, Font = bold, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(0,4), Parent = btn})
    local btnDim = Make("Frame", {
        Size = ud2(1,0,1,0), BackgroundColor3 = rgb(0,0,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 10, Parent = btn,
    })
    Make("UICorner", {CornerRadius = ud(0,4), Parent = btnDim})
    btn.MouseEnter:Connect(function()
        TweenService:Create(btnDim, hoverTweenInfo, {BackgroundTransparency = 0.72}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btnDim, hoverTweenInfo, {BackgroundTransparency = 1}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
        if _G.UNS_RecentAdd then _G.UNS_RecentAdd(label, true, "button", callback) end
        btn.Text = "Done!"
        task.delay(0.8, function() btn.Text = "Run" end)
    end)
    if uid then
        pill.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                openCtxMenu({
                    type = "button",
                    uid = uid,
                    callback = callback,
                }, Vector2.new(input.Position.X, input.Position.Y))
            end
        end)
    end

    if uid then
        if isProxy then
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = C.dot_yel, TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = false
                if buttonParams[uid] and buttonParams[uid].star then
                    updateThemeTag(buttonParams[uid].star, "TextColor3", "textSec")
                    buttonParams[uid].star.TextColor3 = C.textSec
                end
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        else
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            buttonParams[uid] = { name = label, callback = callback, star = star }
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        end
    end
    return pill
end

-- PAGE NAVIGATION
local PageOverlay = Make("Frame", {
    Size = ud2(1,0,1,0), BackgroundColor3 = C.bg,
    BackgroundTransparency = 0, BorderSizePixel = 0,
    Visible = false, Active = true, ClipsDescendants = true, Parent = MainPage,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = PageOverlay})
local PageTopBar = Make("Frame", {
    Size = ud2(1,0,0,44), BackgroundTransparency = 1,
    Parent = PageOverlay,
})
local PageBackBtn = Make("TextButton", {
    Size = ud2(0,56,0,24), Position = ud2(0,10,0,8),
    BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
    Text = "< BACK", TextColor3 = C.white, TextSize = 10, Font = bold, Parent = PageTopBar,
})
Make("UICorner", {CornerRadius = ud(0,8), Parent = PageBackBtn})
local PageTitle = Make("TextLabel", {
    Size = ud2(1,-100,1,0), Position = ud2(0,50,0,0),
    BackgroundTransparency = 1, Text = "",
    TextColor3 = C.textPri, TextSize = 15, Font = bold,
    TextXAlignment = Enum.TextXAlignment.Center, Parent = PageTopBar,
})
Make("Frame", {
    Size = ud2(1,-24,0,1), Position = ud2(0,12,0,44),
    BackgroundColor3 = C.border, BackgroundTransparency = 0.4,
    BorderSizePixel = 0, Parent = PageOverlay,
})
local PageScroll = Make("ScrollingFrame", {
    Size = ud2(1,-24,1,-56), Position = ud2(0,12,0,48),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
    CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Active = true, Parent = PageOverlay,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = PageScroll})

local makeLabel, makeDropdown
local pageApiCounter = 0

local function createPageAPI(pageTag)
    pageApiCounter = pageApiCounter + 1
    local tag = pageTag or ("auto_"..pageApiCounter)
    local api = {}
    local pc = 0
    function api:CreateToggle(label, callback, initOn)
        pc = pc + 1
        local uid = "SP_Tgl_"..tag.."_"..pc
        toggleCallbacks[uid] = callback
        if initOn ~= nil then partState[uid] = initOn end
        local pill = Make("Frame", {
            Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
            BackgroundTransparency = 0.3, BorderSizePixel = 0,
            LayoutOrder = pc, Parent = PageScroll,
        })
        pill:SetAttribute("SearchName", label)
        Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
        Make("TextLabel", {
            Size = ud2(1,-80,1,0), Position = ud2(0,30,0,0),
            BackgroundTransparency = 1, Text = label,
            TextColor3 = C.textPri, TextSize = 11, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
        })
        local toggle = makeToggle(pill, (PART_H-18)/2, function(state)
            partState[uid] = state
            if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(state, true) end
            if toggleCallbacks[uid] then toggleCallbacks[uid](state) end
            if _G.UNS_RecentAdd then _G.UNS_RecentAdd(label, state) end
            if rebuildActive then rebuildActive() end
        end, partState[uid] or false, uid)
        pill.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                openCtxMenu({
                    type = "toggle",
                    uid = uid,
                    setOn = function(s) toggle.SetOn(s, false) end,
                    isOn = function() return toggle.IsOn() end,
                }, Vector2.new(input.Position.X, input.Position.Y))
            end
        end)
        local star = Make("TextButton", {
            Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
            BackgroundTransparency = 1, Text = "★",
            TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
            TextSize = 18, Font = bold, Parent = pill,
        })
        star.MouseButton1Click:Connect(function()
            cfgFavorites[uid] = not cfgFavorites[uid]
            local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
            updateThemeTag(star, "TextColor3", colorKey)
            star.TextColor3 = C[colorKey]
            if proxyToggles[uid] then
                updateThemeTag(proxyToggles[uid].star, "TextColor3", colorKey)
                proxyToggles[uid].star.TextColor3 = C[colorKey]
            end
            triggerAutoSave()
            rebuildFavorites()
        end)
        originalToggles[uid] = { toggle = toggle, star = star, name = label, pill = pill }
        cfgPageData[uid] = { type = "toggle", label = label, page = tag }
        triggerAutoSave()
    end
    function api:CreateButton(label, callback)
        pc = pc + 1
        local uid = "SP_Btn_"..tag.."_"..pc
        makeButton(PageScroll, label, callback, uid, false, pc)
        cfgPageData[uid] = { type = "button", label = label, page = tag }
        triggerAutoSave()
    end
    function api:CreateSlider(label, min, max, default, callback)
        pc = pc + 1
        local uid = "SP_Sld_"..tag.."_"..pc
        local saved = cfgPageData[uid] and cfgPageData[uid].val
        makeSlider(PageScroll, label, min, max, saved or default or ((min+max)/2), callback, uid, false, pc)
        cfgPageData[uid] = { type = "slider", label = label, page = tag, min = min, max = max, default = default or ((min+max)/2), val = saved }
        triggerAutoSave()
    end
    function api:CreateDropdown(label, options, default, callback)
        pc = pc + 1
        local uid = "SP_Drp_"..tag.."_"..pc
        local saved = cfgPageData[uid] and cfgPageData[uid].val
        cfgPageData[uid] = { type = "dropdown", label = label, page = tag, options = options, default = default }
        cfgPageData[uid].val = saved
        makeDropdown(PageScroll, label, options, saved or default, callback, uid, false, pc, nil)
        triggerAutoSave()
    end
    function api:CreateLabel(text)
        pc = pc + 1
        makeLabel(PageScroll, text, nil, pc)
    end
    function api:CreateSection(sectionName)
        pc = pc + 1
        local secPC = 0
        local sectionTween = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local isOpen = false

        local wrapper = Make("Frame", {
            Size = ud2(1,-16,0,38), BackgroundTransparency = 1,
            ClipsDescendants = true, LayoutOrder = pc, Parent = PageScroll,
        })
        local header = Make("Frame", {
            Size = ud2(1,-2,0,36), Position = ud2(0,1,0,1),
            BackgroundColor3 = C.surface,
            BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wrapper,
        })
        Make("UICorner", {CornerRadius = ud(1,0), Parent = header})
        Make("UIStroke", {Color = C.white, Thickness = 1, Transparency = 0.85, Parent = header})
        local arrow = Make("TextLabel", {
            Size = ud2(0,28,1,0), Position = ud2(0,10,0,0),
            BackgroundTransparency = 1, Text = "+",
            TextColor3 = C.textSec, TextSize = 18, Font = bold, Parent = header,
        })
        local titleLbl = Make("TextLabel", {
            Size = ud2(1,-50,1,0), Position = ud2(0,32,0,0),
            BackgroundTransparency = 1, Text = sectionName,
            TextColor3 = C.textPri, TextSize = 12, Font = bold,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
        })
        local hBtn = Make("TextButton", {
            Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = header,
        })
        local content = Make("Frame", {
            Size = ud2(1,0,0,0), Position = ud2(0,0,0,42),
            BackgroundTransparency = 1, Parent = wrapper,
        })
        local layout = Make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = content,
        })

        local secApi = {}

        local function updateSize()
            local h = 0
            local pad = layout.Padding.Offset
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    local sy = child.Size.Y.Offset
                    if sy > 0 then h = h + sy + pad end
                end
            end
            if h > 0 then h = h - pad end
            content.Size = ud2(1,0,0,h)
            local totalH = 42 + h
            if isOpen then
                TweenService:Create(wrapper, sectionTween, {
                    Size = ud2(1,-16,0,totalH)
                }):Play()
            end
        end

        function secApi:CreateToggle(label, callback, initOn)
            secPC = secPC + 1
            local uid = "DP_Tgl_"..tag.."_"..pc.."_"..secPC
            toggleCallbacks[uid] = callback
            if initOn ~= nil then partState[uid] = initOn end
            local pill = Make("Frame", {
                Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
                BackgroundTransparency = 0.3, BorderSizePixel = 0,
                LayoutOrder = secPC, Parent = content,
            })
            Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
            Make("TextLabel", {
                Size = ud2(1,-80,1,0), Position = ud2(0,30,0,0),
                BackgroundTransparency = 1, Text = label,
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
            })
            local toggle = makeToggle(pill, (PART_H-18)/2, function(state)
                partState[uid] = state
                if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(state, true) end
                if toggleCallbacks[uid] then toggleCallbacks[uid](state) end
                if _G.UNS_RecentAdd then _G.UNS_RecentAdd(label, state) end
                if rebuildActive then rebuildActive() end
            end, partState[uid] or false, uid)
            pill.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    openCtxMenu({
                        type = "toggle",
                        uid = uid,
                        setOn = function(s) toggle.SetOn(s, false) end,
                        isOn = function() return toggle.IsOn() end,
                    }, Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                rebuildFavorites()
            end)
            originalToggles[uid] = { toggle = toggle, name = label, pill = pill, star = star }
            cfgPageData[uid] = { type = "toggle", label = label, page = tag }
            triggerAutoSave()
            updateSize()
        end

        function secApi:CreateButton(label, callback)
            secPC = secPC + 1
            local uid = "DP_Btn_"..tag.."_"..pc.."_"..secPC
            local pill = Make("Frame", {
                Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
                BackgroundTransparency = 0.1, BorderSizePixel = 0,
                LayoutOrder = secPC, Parent = content,
            })
            pill:SetAttribute("SearchName", label)
            Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
            Make("TextLabel", {
                Size = ud2(0,120,1,0), Position = ud2(0,30,0,0),
                BackgroundTransparency = 1, Text = label,
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
            })
            local btn = Make("TextButton", {
                Size = ud2(0,70,0,22), Position = ud2(1,-80,0.5,-11),
                BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
                Text = "Run", TextColor3 = C.white,
                TextSize = 10, Font = bold, Parent = pill,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = btn})
            local btnDim = Make("Frame", {
                Size = ud2(1,0,1,0), BackgroundColor3 = rgb(0,0,0),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                ZIndex = 10, Parent = btn,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = btnDim})
            btn.MouseEnter:Connect(function()
                TweenService:Create(btnDim, hoverTweenInfo, {BackgroundTransparency = 0.72}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btnDim, hoverTweenInfo, {BackgroundTransparency = 1}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
                btn.Text = "Done!"
                task.delay(0.8, function() btn.Text = "Run" end)
            end)
            pill.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    openCtxMenu({
                        type = "button",
                        uid = uid,
                        callback = callback,
                    }, Vector2.new(input.Position.X, input.Position.Y))
                end
            end)
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
            cfgPageData[uid] = { type = "button", label = label, page = tag }
            triggerAutoSave()
            updateSize()
        end

        function secApi:CreateSlider(label, min, max, default, callback)
            secPC = secPC + 1
            local uid = "DP_Sld_"..tag.."_"..pc.."_"..secPC
            local savedVal = cfgSliderFavs[uid]
            local val = savedVal or default or min
            if savedVal and callback and savedVal ~= default then callback(savedVal) end
            local pill = Make("Frame", {
                Size = ud2(1,-8,0,SLIDER_H), BackgroundColor3 = C.part_bg,
                BackgroundTransparency = 0.3, BorderSizePixel = 0,
                LayoutOrder = secPC, Parent = content,
            })
            pill:SetAttribute("SearchName", label)
            Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
            Make("TextLabel", {
                Size = ud2(0,120,0,20), Position = ud2(0,30,0,6),
                BackgroundTransparency = 1, Text = label,
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
            })
            local valLbl = Make("TextLabel", {
                Size = ud2(0,36,0,20), Position = ud2(1,-50,0,6),
                BackgroundTransparency = 1, Text = tostring(val),
                TextColor3 = C.textSec, TextSize = 10, Font = bold,
                TextXAlignment = Enum.TextXAlignment.Right, Parent = pill,
            })
            local track = Make("Frame", {
                Size = ud2(1,-28,0,6), Position = ud2(0,14,0,32),
                BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Parent = pill,
            })
            Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
            local range = max - min
            local effectiveMax = max
            local effectiveMin = min
            local initF = math.max(range > 0 and (val - min) / range or 0, 0.01)
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
            local function updSlider(x)
                local f = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local effRange = effectiveMax - effectiveMin
                local newVal = math.floor(effectiveMin + f * effRange + 0.5)
                fill.Size = ud2(f,0,1,0)
                knob.Position = ud2(f,-7,0,-4)
                valLbl.Text = tostring(newVal)
                val = newVal
                cfgSliderFavs[uid] = val
                if callback then callback(newVal) end
            end
            local function setSliderVal(v, displayMax, displayMin)
                if displayMax then effectiveMax = displayMax end
                if displayMin then effectiveMin = displayMin end
                local effectiveRange = effectiveMax - effectiveMin
                v = math.clamp(v, effectiveMin, effectiveMax)
                local f = effectiveRange > 0 and (v - effectiveMin) / effectiveRange or 0
                TweenService:Create(fill, TweenInfo.new(0.1), {Size = ud2(f,0,1,0)}):Play()
                knob.Position = ud2(f,-7,0,-4)
                valLbl.Text = tostring(v)
                val = v
                cfgSliderFavs[uid] = val
            end
            if not _G.UNS_SliderSetVal then _G.UNS_SliderSetVal = {} end
            _G.UNS_SliderSetVal[label] = setSliderVal
            knob.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
            end)
            local trackClick = Make("TextButton", {
                Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7),
                BackgroundTransparency = 1, Text = "", ZIndex = knob.ZIndex - 1, Parent = track,
            })
            trackClick.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; updSlider(i.Position.X)
                end
            end)
            local connEnd = UserInputService.InputEnded:Connect(function(i)
                if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and dragging then
                    dragging = false
                    cfgSliderFavs[uid] = val
                    triggerAutoSave()
                    if rebuildFavorites then rebuildFavorites() end
                end
            end)
            local connMove = UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    updSlider(i.Position.X)
                end
            end)
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,2),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
            sliderFavObj[uid] = { name = label, getVal = function() return val end, star = star }
            cfgPageData[uid] = { type = "slider", label = label, page = tag, min = min, max = max, default = default or ((min+max)/2) }
            triggerAutoSave()
            updateSize()
        end

        function secApi:CreateDropdown(label, options, default, callback)
            secPC = secPC + 1
            local uid = "DP_Drp_"..tag.."_"..pc.."_"..secPC
            local saved = cfgPageData[uid] and cfgPageData[uid].val
            local isOpen = false
            local val = saved or default or options[1]
            local pill = Make("Frame", {
                Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
                BackgroundTransparency = 0.1, BorderSizePixel = 0,
                LayoutOrder = secPC, Parent = content,
            })
            pill:SetAttribute("SearchName", label)
            Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
            Make("TextLabel", {
                Size = ud2(0,120,0,PART_H), Position = ud2(0,30,0,0),
                BackgroundTransparency = 1, Text = label,
                TextColor3 = C.textPri, TextSize = 11, Font = semi,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
            })
            local valDisplay = Make("TextButton", {
                Size = ud2(0,90,0,22), Position = ud2(1,-100,0,5),
                BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
                Text = tostring(val) .. " ▼", TextColor3 = C.white,
                TextSize = 10, Font = bold, Parent = pill,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = valDisplay})
            local dropFrame = Make("Frame", {
                Size = ud2(1,0,0,0), BackgroundColor3 = C.surface,
                BackgroundTransparency = 0, BorderSizePixel = 0,
                Visible = false, LayoutOrder = secPC + 1, Parent = content,
            })
            Make("UICorner", {CornerRadius = ud(0,8), Parent = dropFrame})
            Make("UIStroke", {Color = C.border, Thickness = 1, Parent = dropFrame})
            local dropPad = Make("UIPadding", {
                PaddingTop = ud(0,4), PaddingBottom = ud(0,4),
                PaddingLeft = ud(0,14), PaddingRight = ud(0,14), Parent = dropFrame,
            })
            local dropLayout = Make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,2), Parent = dropFrame,
            })
            for i, opt in ipairs(options) do
                local oBtn = Make("TextButton", {
                    Size = ud2(1,0,0,22), BackgroundColor3 = C.surface, BackgroundTransparency = 0,
                    Text = tostring(opt), TextColor3 = C.textSec, TextSize = 10, Font = reg,
                    Parent = dropFrame, LayoutOrder = i,
                })
                Make("UICorner", {CornerRadius = ud(0,4), Parent = oBtn})
                oBtn.MouseButton1Click:Connect(function()
                    val = opt
                    valDisplay.Text = tostring(val) .. " ▶"
                    isOpen = false
                    dropFrame.Visible = false
                    dropFrame.Size = ud2(1,0,0,0)
                    cfgPageData[uid] = cfgPageData[uid] or {}
                    cfgPageData[uid].val = val
                    if callback then callback(val) end
                    if rebuildFavorites then rebuildFavorites() end
                end)
            end
            dropdownParams[uid] = { name = label, options = options, default = default, callback = callback }
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
            valDisplay.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                valDisplay.Text = tostring(val) .. (isOpen and " ▼" or " ▶")
                if isOpen then
                    local ch = dropLayout.AbsoluteContentSize.Y
                    dropFrame.Size = ud2(1,0,0,ch + 8)
                    dropFrame.Visible = true
                else
                    TweenService:Create(dropFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                        Size = ud2(1,0,0,0)
                    }):Play()
                    task.delay(0.12, function()
                        if not isOpen then dropFrame.Visible = false end
                        updateSize()
                    end)
                end
                updateSize()
            end)
            cfgPageData[uid] = { type = "dropdown", label = label, page = tag, options = options, default = default, val = val }
            triggerAutoSave()
            updateSize()
        end

        function secApi:CreateLabel(text)
            secPC = secPC + 1
            makeLabel(content, text, nil, secPC)
            updateSize()
        end

        hBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            arrow.Text = isOpen and "-" or "+"
            if isOpen then updateSize() end
            local h = 0
            local pad = layout.Padding.Offset
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    local sy = child.Size.Y.Offset
                    if sy > 0 then h = h + sy + pad end
                end
            end
            if h > 0 then h = h - pad end
            local targetH = isOpen and (42 + h) or 38
            TweenService:Create(wrapper, sectionTween, {
                Size = ud2(1,-16,0,targetH)
            }):Play()
        end)

        return secApi
    end
    return api
end

local function showPage(title, setupFn, pageTag)
    PageTitle.Text = title
    for _, child in ipairs(PageScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    TabBar.Visible = false
    TabContent.Visible = false
    _G.UNS_PageScroll = PageScroll

    local ok, err = pcall(setupFn, createPageAPI(pageTag))
    if not ok then
        warn("[UNScripts] Page setup error:", err)
    end

    PageOverlay.Visible = true
    PageOverlay.ZIndex = 50
    PageTopBar.ZIndex = 51
    PageBackBtn.ZIndex = 52
end

local function hidePage()
    PageOverlay.Visible = false
    TabBar.Visible = true
    TabContent.Visible = true
end

PageBackBtn.MouseButton1Click:Connect(hidePage)

local function makePageButton(parent, label, pageTitle, setupFn, layoutOrder, uid, isProxy)
    local pill = Make("Frame", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0, Parent = parent,
        Active = true,
    })
    pill:SetAttribute("SearchName", label)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = pill})

    local lbl = Make("TextLabel", {
        Size = ud2(0,120,1,0), Position = ud2(0,30,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = semi,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })

    local openBtn = Make("TextButton", {
        Size = ud2(0,70,0,22), Position = ud2(1,-80,0.5,-11),
        BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
        Text = "Open", TextColor3 = C.white,
        TextSize = 10, Font = bold, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(0,4), Parent = openBtn})
    openBtn.MouseButton1Click:Connect(function()
        showPage(pageTitle or label, setupFn, uid or ("page_"..tostring(layoutOrder)))
        if _G.UNS_RecentAdd then _G.UNS_RecentAdd(label, true, "page", {pageTitle = pageTitle or label, setupFn = setupFn, uid = uid}) end
    end)

    if uid then
        pill.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                openCtxMenu({
                    type = "button",
                    uid = uid,
                    label = label,
                }, Vector2.new(input.Position.X, input.Position.Y))
            end
        end)
    end

    if uid then
        if isProxy then
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = C.dot_yel, TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = false
                if pageButtonParams[uid] and pageButtonParams[uid].star then
                    updateThemeTag(pageButtonParams[uid].star, "TextColor3", "textSec")
                    pageButtonParams[uid].star.TextColor3 = C.textSec
                end
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        else
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            pageButtonParams[uid] = { name = label, pageTitle = pageTitle or label, setupFn = setupFn, btnUid = uid, star = star }
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        end
    end

    return pill
end

makeDropdown = function(parent, label, options, defaultVal, callback, uid, isProxy, layoutOrder, parentSectionObj)
    local savedVal = uid and cfgPageData[uid] and cfgPageData[uid].val
    local isOpen = false
    local val = savedVal or defaultVal or options[1]

    local pill = Make("Frame", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        LayoutOrder = layoutOrder or 0, Parent = parent,
    })
    pill:SetAttribute("SearchName", label)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})

    local lbl = Make("TextLabel", {
        Size = ud2(0,120,0,PART_H), Position = ud2(0,30,0,0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.textPri, TextSize = 11, Font = semi,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
    })

    local valDisplay = Make("TextButton", {
        Size = ud2(0,90,0,22), Position = ud2(1,-100,0,5),
        BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
        Text = tostring(val) .. " ▼", TextColor3 = C.white,
        TextSize = 10, Font = bold, Parent = pill,
    })
    Make("UICorner", {CornerRadius = ud(0,4), Parent = valDisplay})

    local dropFrame = Make("Frame", {
        Size = ud2(1,-16,0,0), BackgroundColor3 = C.surface,
        BackgroundTransparency = 0, BorderSizePixel = 0,
        Visible = false, LayoutOrder = (layoutOrder or 0) + 1, Parent = parent,
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

    local function saveVal(v)
        cfgPageData[uid] = cfgPageData[uid] or {}
        cfgPageData[uid].val = v
    end

    local function updateSize()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        if isOpen then
            dropFrame.Visible = true
            TweenService:Create(dropFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = ud2(1,-16,0,contentHeight + 8)
            }):Play()
        else
            TweenService:Create(dropFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = ud2(1,-16,0,0)
            }):Play()
            task.delay(0.12, function()
                if not isOpen then dropFrame.Visible = false end
            end)
        end

        if parentSectionObj then
            local ph = parentSectionObj.Content
            local layout = ph:FindFirstChildOfClass("UIListLayout")
            local pad = (layout and layout.Padding.Offset) or 5
            local dropH = isOpen and (listLayout.AbsoluteContentSize.Y + 8) or 0
            local total = 0
            local count = 0
            for _, ch in ipairs(ph:GetChildren()) do
                if ch:IsA("GuiObject") and (ch.Visible or ch == dropFrame) then
                    local active = (ch ~= dropFrame) or isOpen
                    if active then
                        local sy = (ch == dropFrame) and dropH or ch.Size.Y.Offset
                        if sy > 0 then total = total + sy; count = count + 1 end
                    end
                end
            end
            if count > 1 then total = total + pad * (count - 1) end
            ph.Size = ud2(1,0,0,total)
            if parentSectionObj.IsOpen() then
                parentSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + total)
            end

            local delayTime = isOpen and 0.25 or 0.17
            task.delay(delayTime, function()
                parentSectionObj.resizeToContent()
                if parentSectionObj.IsOpen() then
                    local ch = parentSectionObj.Content.Size.Y.Offset
                    parentSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + ch)
                end
            end)
        end
    end

    for i, opt in ipairs(options) do
        local oBtn = Make("TextButton", {
            Size = ud2(1,0,0,22), BackgroundColor3 = C.surface, BackgroundTransparency = 0,
            Text = tostring(opt), TextColor3 = C.textSec, TextSize = 10, Font = reg,
            Parent = dropFrame, LayoutOrder = i
        })
        Make("UICorner", {CornerRadius = ud(0,4), Parent = oBtn})
        oBtn.MouseButton1Click:Connect(function()
            val = opt
            isOpen = false
            valDisplay.Text = tostring(val) .. " ▶"
            updateSize()
            saveVal(val)
            if callback then callback(val) end
            if rebuildFavorites then rebuildFavorites() end
        end)
    end

    if uid then
        if isProxy then
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = C.dot_yel, TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = false
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        else
            dropdownParams[uid] = { name = label, options = options, default = defaultVal, callback = callback }
            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = pill,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                if rebuildFavorites then rebuildFavorites() end
            end)
        end
    end

    valDisplay.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        valDisplay.Text = tostring(val) .. (isOpen and " ▼" or " ▶")
        updateSize()
    end)

    return pill
end

makeLabel = function(parent, text, uid, layoutOrder)
    local lbl = Make("TextLabel", {
        Size = ud2(1,-8,0,LABEL_H), BackgroundTransparency = 1,
        Text = " -- " .. text .. " --", TextColor3 = C.textSec,
        TextSize = 10, Font = bold, LayoutOrder = layoutOrder,
        TextXAlignment = Enum.TextXAlignment.Center, Parent = parent,
    })
    lbl:SetAttribute("SearchName", text)
    return lbl
end

local favSectionObj   = nil
local activeSectionObj = nil
local recentsSectionObj = nil
local autoExecSectionObj = nil
local recentList = {}
local MAX_RECENTS = 8

local function createTogglePart(parent, pName, uid, layoutOrder, isProxy)
    local partPill = Make("Frame", {
        Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
        BackgroundTransparency = 0.3, BorderSizePixel = 0,
        LayoutOrder = layoutOrder, Parent = parent,
        Active = true,
    })
    partPill:SetAttribute("SearchName", pName)
    Make("UICorner", {CornerRadius = ud(1,0), Parent = partPill})
    Make("TextLabel", {
        Size = ud2(1,-80,1,0), Position = ud2(0,30,0,0),
        BackgroundTransparency = 1, Text = pName,
        TextColor3 = C.textPri, TextSize = 11, Font = reg,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = partPill,
    })

    local toggle
    toggle = makeToggle(partPill, (PART_H-18)/2, function(state)
        partState[uid] = state
        if isProxy then
            if originalToggles[uid] then originalToggles[uid].toggle.SetOn(state, true) end
        else
            if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(state, true) end
        end
        if toggleCallbacks[uid] then toggleCallbacks[uid](state) end
        if _G.UNS_RecentAdd then _G.UNS_RecentAdd(pName, state) end
        if rebuildActive then rebuildActive() end
    end, partState[uid] or false, uid)

    partPill.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            openCtxMenu({
                type = "toggle",
                uid = uid,
                setOn = function(s) toggle.SetOn(s, false) end,
                isOn = function() return toggle.IsOn() end,
            }, Vector2.new(input.Position.X, input.Position.Y))
        end
    end)

    local star = Make("TextButton", {
        Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
        BackgroundTransparency = 1, Text = "★",
        TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
        TextSize = 18, Font = bold, Parent = partPill,
    })

    star.MouseButton1Click:Connect(function()
        cfgFavorites[uid] = not cfgFavorites[uid]
        local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
        updateThemeTag(star, "TextColor3", colorKey)
        star.TextColor3 = C[colorKey]
        
        if isProxy then
            if originalToggles[uid] then 
                updateThemeTag(originalToggles[uid].star, "TextColor3", colorKey)
                originalToggles[uid].star.TextColor3 = C[colorKey] 
            end
        else
            if proxyToggles[uid] then 
                updateThemeTag(proxyToggles[uid].star, "TextColor3", colorKey)
                proxyToggles[uid].star.TextColor3 = C[colorKey] 
            end
        end
        triggerAutoSave()
        rebuildFavorites()
    end)

    if isProxy then
        proxyToggles[uid] = { toggle = toggle, star = star, pill = partPill }
    else
        originalToggles[uid] = { toggle = toggle, star = star, name = pName, pill = partPill }
    end
    return partPill
end

rebuildFavorites = function()
    if not favSectionObj then return end
    for _, child in ipairs(favSectionObj.Content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    proxyToggles = {}

    local count = 0
    local favList = {}
    for uid, isFav in pairs(cfgFavorites) do
        if isFav == true and uid ~= "" then
            local hasSource = originalToggles[uid] or buttonParams[uid] or sliderFavObj[uid] or sliderParams[uid] or cfgPageData[uid] or dropdownParams[uid] or pageButtonParams[uid]
            if hasSource then table.insert(favList, uid) end
        end
    end
    table.sort(favList)

    for i, uid in ipairs(favList) do
        local rendered = false
        if originalToggles[uid] then
            createTogglePart(favSectionObj.Content, originalToggles[uid].name, uid, i, true)
            count = count + 1
            rendered = true
        end
        if not rendered and buttonParams[uid] then
            local bData = buttonParams[uid]
            makeButton(favSectionObj.Content, bData.name, bData.callback, uid, true, i)
            count = count + 1
            rendered = true
        end
        if not rendered then
            local params = sliderParams[uid]
            if params then
                makeSlider(favSectionObj.Content, params.label, params.minV, params.maxV, cfgSliderFavs[uid] or params.defaultV, function(v)
                    local p = sliderParams[uid]
                    if p and p.setVal then p.setVal(v) end
                    if params.callback then params.callback(v) end
                end, uid, true, i)
                count = count + 1
                rendered = true
            end
        end
        if not rendered then
            local pd = cfgPageData[uid]
            if pd then
                if pd.type == "toggle" then
                    createTogglePart(favSectionObj.Content, pd.label, uid, i, true)
                    count = count + 1; rendered = true
                elseif pd.type == "button" then
                    makeButton(favSectionObj.Content, pd.label, function() end, uid, true, i)
                    count = count + 1; rendered = true
                elseif pd.type == "slider" then
                    makeSlider(favSectionObj.Content, pd.label, pd.min or 0, pd.max or 100, pd.val or pd.default or 50, function(v)
                        local p = sliderParams[uid]
                        if p and p.setVal then p.setVal(v) end
                    end, uid, true, i)
                    count = count + 1; rendered = true
                elseif pd.type == "dropdown" then
                    local ddCallback = dropdownParams[uid] and dropdownParams[uid].callback
                    makeDropdown(favSectionObj.Content, pd.label, pd.options or {}, pd.val or pd.default, function(v)
                        if ddCallback then ddCallback(v) end
                    end, uid, true, i, favSectionObj)
                    count = count + 1; rendered = true
                end
            end
        end
        if not rendered and dropdownParams[uid] then
            local dd = dropdownParams[uid]
            makeDropdown(favSectionObj.Content, dd.name, dd.options, dd.default, function(v)
                if dd.callback then dd.callback(v) end
            end, uid, true, i, favSectionObj)
            count = count + 1; rendered = true
        end
        if not rendered and pageButtonParams[uid] then
            local pb = pageButtonParams[uid]
            makePageButton(favSectionObj.Content, pb.name, pb.pageTitle, pb.setupFn, i, uid, true)
            count = count + 1; rendered = true
        end
        if not rendered and sliderFavObj[uid] then
            local sData = sliderFavObj[uid]
            local item = Make("Frame", {
                Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
                BackgroundTransparency = 0.3, BorderSizePixel = 0,
                LayoutOrder = i, Parent = favSectionObj.Content,
            })
            item:SetAttribute("SearchName", sData.name)
            Make("UICorner", {CornerRadius = ud(1,0), Parent = item})
            Make("TextLabel", {
                Size = ud2(1,-80,1,0), Position = ud2(0,30,0,0),
                BackgroundTransparency = 1, Text = sData.name .. " (" .. tostring(sData.getVal()) .. ")",
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
            })
            local star = Make("TextButton", {
                Size = ud2(0,24,0,24), Position = ud2(1,-34,0,4),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = C.dot_yel, TextSize = 18, Font = bold, Parent = item,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = false
                if sliderFavObj[uid] and sliderFavObj[uid].star then
                    updateThemeTag(sliderFavObj[uid].star, "TextColor3", "textSec")
                    sliderFavObj[uid].star.TextColor3 = C.textSec
                end
                triggerAutoSave()
                rebuildFavorites()
            end)
            count = count + 1
            rendered = true
        end
    end

    local emptyLabel = favSectionObj.Content:FindFirstChild("FavEmptyLabel")
    if count == 0 then
        if not emptyLabel then
            Make("TextLabel", {
                Name = "FavEmptyLabel",
                Size = ud2(1,-8,0,28), BackgroundTransparency = 1,
                Text = "No favorites", TextColor3 = C.textSec,
                TextSize = 11, Font = reg, LayoutOrder = 0, Parent = favSectionObj.Content,
            })
        end
    else
        if emptyLabel then emptyLabel:Destroy() end
    end

    for uid, pb in pairs(pageButtonParams) do
        if pb.star then
            local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
            updateThemeTag(pb.star, "TextColor3", colorKey)
            pb.star.TextColor3 = C[colorKey]
        end
    end

    favSectionObj.resizeToContent()
    if favSectionObj.IsOpen() then
        favSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + favSectionObj.Content.Size.Y.Offset)
    end

    task.delay(0.15, function()
        if favSectionObj then
            if favSectionObj.IsOpen() then
                favSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + favSectionObj.Content.Size.Y.Offset)
            end
        end
    end)
end

rebuildActive = function()
    if not activeSectionObj then return end
    for _, child in ipairs(activeSectionObj.Content:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local count = 0
    local activeList = {}
    for uid, isOn in pairs(partState) do
        if isOn and (originalToggles[uid] or sliderFavObj[uid] or proxyToggles[uid]) then table.insert(activeList, uid) end
    end
    table.sort(activeList)

    for i, uid in ipairs(activeList) do
        local data = originalToggles[uid] or sliderFavObj[uid] or proxyToggles[uid]
        local item = Make("Frame", {
            Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
            BackgroundTransparency = 0.3, BorderSizePixel = 0,
            LayoutOrder = i, Parent = activeSectionObj.Content,
        })
        item:SetAttribute("SearchName", data.name)
        Make("UICorner", {CornerRadius = ud(1,0), Parent = item})
        Make("Frame", {
            Size = ud2(0,8,0,8), Position = ud2(0,14,0,12),
            BackgroundColor3 = C.dot_grn, BorderSizePixel = 0, Parent = item,
        })
        Make("UICorner", {CornerRadius = ud(1,0), Parent = item:FindFirstChildOfClass("Frame")})
        Make("TextLabel", {
            Size = ud2(1,-100,1,0), Position = ud2(0,30,0,0),
            BackgroundTransparency = 1, Text = data.name or "Unknown",
            TextColor3 = C.textPri, TextSize = 11, Font = reg,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
        })

        local disableBtn = Make("TextButton", {
            Size = ud2(0,52,0,20), Position = ud2(1,-66,0,6),
            BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.15,
            Text = "Disable", TextColor3 = C.white,
            TextSize = 10, Font = bold, Parent = item,
        })
        Make("UICorner", {CornerRadius = ud(0,4), Parent = disableBtn})

        disableBtn.MouseButton1Click:Connect(function()
            partState[uid] = false
            if data.toggle then data.toggle.SetOn(false, false) end
            if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(false, false) end
            rebuildActive()
        end)
        count = count + 1
    end

    local emptyLabel = activeSectionObj.Content:FindFirstChild("ActiveEmptyLabel")
    if count == 0 then
        if not emptyLabel then
            Make("TextLabel", {
                Name = "ActiveEmptyLabel",
                Size = ud2(1,-8,0,28), BackgroundTransparency = 1,
                Text = "No active features", TextColor3 = C.textSec,
                TextSize = 11, Font = reg, LayoutOrder = 0, Parent = activeSectionObj.Content,
            })
        end
    else
        if emptyLabel then emptyLabel:Destroy() end
    end

    local wasOpen = activeSectionObj.IsOpen()
    activeSectionObj.resizeToContent()
    if wasOpen then
        if count > 0 then
            TweenService:Create(activeSectionObj.Wrapper, sectionTween, { Size = ud2(1,-16,0, SECTION_H + 4 + activeSectionObj.Content.Size.Y.Offset) }):Play()
            task.delay(0.15, function()
                if activeSectionObj and activeSectionObj.IsOpen() then
                    activeSectionObj.resizeToContent()
                    activeSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + activeSectionObj.Content.Size.Y.Offset)
                end
            end)
        else
            activeSectionObj.SetOpen(false)
        end
    else
        activeSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H)
    end
end

rebuildAutoExec = function()
    if not autoExecSectionObj then return end
    for _, child in ipairs(autoExecSectionObj.Content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end

    local uids = {}
    for uid, _ in pairs(_G.autoExecFeatures) do
        table.insert(uids, uid)
    end
    table.sort(uids)

    if #uids == 0 then
        Make("TextLabel", {
            Size = ud2(1,0,0,28), BackgroundTransparency = 1,
            Text = "No auto-execute features", TextColor3 = C.textSec,
            TextSize = 11, Font = reg, LayoutOrder = 0, Parent = autoExecSectionObj.Content,
        })
    else
        for i, uid in ipairs(uids) do
            local label = nil
            local meta = _G.autoExecFeatures[uid]
            if originalToggles[uid] then
                label = originalToggles[uid].name
            elseif buttonParams[uid] then
                label = buttonParams[uid].name
            elseif cfgPageData[uid] then
                label = cfgPageData[uid].label
            end
            if not label then label = uid end

            local item = Make("Frame", {
                Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
                BackgroundTransparency = 0.3, BorderSizePixel = 0,
                LayoutOrder = i, Parent = autoExecSectionObj.Content,
            })
            item:SetAttribute("SearchName", label)
            Make("UICorner", {CornerRadius = ud(1,0), Parent = item})
            Make("TextLabel", {
                Size = ud2(1,-130,1,0), Position = ud2(0,30,0,0),
                BackgroundTransparency = 1, Text = label,
                TextColor3 = C.textPri, TextSize = 11, Font = reg,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
            })

            local star = Make("TextButton", {
                Size = ud2(0,22,0,22), Position = ud2(0,6,0,5),
                BackgroundTransparency = 1, Text = "★",
                TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
                TextSize = 18, Font = bold, Parent = item,
            })
            star.MouseButton1Click:Connect(function()
                cfgFavorites[uid] = not cfgFavorites[uid]
                local colorKey = cfgFavorites[uid] and "dot_yel" or "textSec"
                updateThemeTag(star, "TextColor3", colorKey)
                star.TextColor3 = C[colorKey]
                triggerAutoSave()
                rebuildFavorites()
            end)

            local disBtn = Make("TextButton", {
                Size = ud2(0,52,0,20), Position = ud2(1,-66,0,6),
                BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.15,
                Text = "Disable", TextColor3 = C.white,
                TextSize = 10, Font = bold, Parent = item,
            })
            Make("UICorner", {CornerRadius = ud(0,4), Parent = disBtn})
            disBtn.MouseButton1Click:Connect(function()
                _G.autoExecFeatures[uid] = nil
                triggerAutoSave()
                rebuildAutoExec()
            end)
        end
    end

    autoExecSectionObj.resizeToContent()
    if autoExecSectionObj.IsOpen() then
        autoExecSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + autoExecSectionObj.Content.Size.Y.Offset)
    end
end

-- ════════════════════════════ RECENTS ════════════════════════════
local function createRecentPill(parent, entry, order)
    local label, entryType, data = entry.label, entry.type, entry.data
    local pill = Make("Frame", {Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = order, Parent = parent})
    Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
    Make("TextLabel", {Size = ud2(1,-80,1,0), Position = ud2(0,30,0,0), BackgroundTransparency = 1, Text = label, TextColor3 = C.textPri, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = pill})
    if entryType == "toggle" then
        local initState = data or false
        local track = Make("Frame", {Size = ud2(0,38,0,20), Position = ud2(1,-48,0,6), BackgroundColor3 = initState and C.toggle_on or C.toggle_off, BorderSizePixel = 0, Parent = pill})
        Make("UICorner", {CornerRadius = ud(1,0), Parent = track})
        local knob = Make("Frame", {Size = ud2(0,16,0,16), Position = initState and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8), BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = track})
        Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
        local hitbox = Make("TextButton", {Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = knob.ZIndex + 1, Parent = track})
        local isOn = initState
        hitbox.MouseButton1Click:Connect(function()
            isOn = not isOn
            local targetColorKey = isOn and "toggle_on" or "toggle_off"
            updateThemeTag(track, "BackgroundColor3", targetColorKey)
            track.BackgroundColor3 = C[targetColorKey]
            knob.Position = isOn and ud2(1,-18,0.5,-8) or ud2(0,2,0.5,-8)
            if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel(label, isOn) end
        end)
    elseif entryType == "button" then
        local runBtn = Make("TextButton", {Size = ud2(0,52,0,20), Position = ud2(1,-62,0,6), BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, Text = "Run", TextColor3 = C.white, TextSize = 10, Font = bold, Parent = pill})
        Make("UICorner", {CornerRadius = ud(0,4), Parent = runBtn})
        runBtn.MouseButton1Click:Connect(function()
            if data then data() end
            runBtn.Text = "Done!"
            task.delay(0.8, function() runBtn.Text = "Run" end)
        end)
    elseif entryType == "page" then
        local openBtn = Make("TextButton", {Size = ud2(0,52,0,20), Position = ud2(1,-62,0,6), BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, Text = "Open", TextColor3 = C.white, TextSize = 10, Font = bold, Parent = pill})
        Make("UICorner", {CornerRadius = ud(0,4), Parent = openBtn})
        openBtn.MouseButton1Click:Connect(function()
            if data then showPage(data.pageTitle, data.setupFn, data.uid) end
        end)
    end
end

local function rebuildRecentsPills()
    if not recentsSectionObj then return end
    for _, child in ipairs(recentsSectionObj.Content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    if #recentList == 0 then
        local emptyLabel = Make("TextLabel", {Size = ud2(1,0,0,32), BackgroundTransparency = 1, Text = "No recent features used", TextColor3 = C.textSec, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Center, Parent = recentsSectionObj.Content})
    else
    for i, entry in ipairs(recentList) do
        if entry.type == "toggle" then
            local state = _G.UNScripts.GetToggleState and _G.UNScripts.GetToggleState(entry.label) or false
            createRecentPill(recentsSectionObj.Content, {label = entry.label, type = "toggle", data = state}, i)
        else
            createRecentPill(recentsSectionObj.Content, entry, i)
        end
    end
    end
    recentsSectionObj.resizeToContent()
    if recentsSectionObj.IsOpen() then
        local totalH = SECTION_H + 4 + recentsSectionObj.Content.Size.Y.Offset
        recentsSectionObj.Wrapper.Size = UDim2.new(1, -16, 0, totalH)
    end
end

function _G.UNS_RecentAdd(label, state, kind, data)
    local entryType = kind or "toggle"
    for i, entry in ipairs(recentList) do
        if entry.label == label then table.remove(recentList, i); break end
    end
    table.insert(recentList, 1, {label = label, type = entryType, data = data})
    while #recentList > MAX_RECENTS do table.remove(recentList) end
    task.spawn(rebuildRecentsPills)
end

local function updateCollapseAllVisibility()
    if not activeTab then CollapseAllBtn.Visible = false; return end
    local n = 0
    for _, sec in ipairs(tabSections[activeTab]) do
        if sec.IsOpen() then n = n + 1 end
    end
    CollapseAllBtn.Visible = (n > 1)
end

local function makeSection(sectionName, parentContainer, tabKey, isFavSection, isActiveSection)
    local wrapper = Make("Frame", {
        Size = ud2(1,-16,0,SECTION_H), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = parentContainer,
    })
    local header = Make("Frame", {
        Size = ud2(1,-2,0,SECTION_H - 2), Position = ud2(0,1,0,1),
        BackgroundColor3 = C.surface,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wrapper,
    })
    Make("UICorner", {CornerRadius = ud(1,0), Parent = header})
    Make("UIStroke", {Color = C.white, Thickness = 1, Transparency = 0.85, Parent = header})
    local arrow = Make("TextLabel", {
        Size = ud2(0,28,1,0), Position = ud2(0,10,0,0),
        BackgroundTransparency = 1, Text = "+", TextColor3 = C.textSec,
        TextSize = 18, Font = bold, Parent = header,
    })
    local titleLbl = Make("TextLabel", {
        Size = ud2(1,-50,1,0), Position = ud2(0,32,0,0),
        BackgroundTransparency = 1, Text = sectionName,
        TextColor3 = C.textPri, TextSize = 12, Font = bold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })
    titleLbl:SetAttribute("SearchName", sectionName)

    local content = Make("Frame", {
        Size = ud2(1,0,0,0), Position = ud2(0,0,0,SECTION_H+4),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = wrapper,
    })
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = content})

    local isOpen = false
    local obj = {
        Wrapper = wrapper, Content = content, TitleLabel = titleLbl,
        IsOpen = function() return isOpen end, Name = sectionName,
        resizeToContent = function()
            local layout = content:FindFirstChildOfClass("UIListLayout")
            local h = layout and layout.AbsoluteContentSize.Y or 0
            if h <= 0 then
                h = 0
                local pad = (layout and layout.Padding.Offset) or 5
                for _, child in ipairs(content:GetChildren()) do
                    if child:IsA("GuiObject") and child.Visible then
                        local sy = child.Size.Y.Offset
                        if sy <= 0 then
                            if child:IsA("Frame") then sy = PART_H
                            elseif child:IsA("TextLabel") then sy = LABEL_H
                            else sy = 32 end
                        end
                        h = h + sy + pad
                    end
                end
            end
            content.Size = ud2(1,0,0, h)
        end,
    }

    if isActiveSection then activeSectionObj = obj
    elseif isFavSection then favSectionObj = obj
    elseif tabKey and tabSections[tabKey] then obj.resizeToContent() end

    local function setOpen(state)
        isOpen = state
        arrow.Text = isOpen and "-" or "+"
        if isOpen then obj.resizeToContent() end
        local totalH = SECTION_H + 4 + content.Size.Y.Offset
        if isOpen then
            wrapper.Size = ud2(1,-16,0,totalH)
        else
            TweenService:Create(wrapper, sectionTween, {Size = ud2(1,-16,0,SECTION_H)}):Play()
        end
        if isOpen then
            task.delay(0.15, function()
                obj.resizeToContent()
                wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + content.Size.Y.Offset)
            end)
        end
        updateCollapseAllVisibility()
    end
    obj.SetOpen = setOpen
    _G.sectionToggles[wrapper] = setOpen

    local hBtn = Make("TextButton", { Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = header })
    hBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)

    if tabKey and tabSections[tabKey] then table.insert(tabSections[tabKey], obj) end
    return obj
end

local function buildTabContainer(visible)
    local c = Make("Frame", {
        Size = ud2(1,0,0,0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = visible, Parent = SectionScroll,
    })
    Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = c})
    return c
end

tabs.Home   = makeTab("Home")
tabs.Home.Button.Text = '<font color="rgb(50,120,255)">Home</font>'
tabContainers["Home"]    = buildTabContainer(true)
tabContainers["Scripts"] = buildTabContainer(false)

makeSection("Active",    tabContainers["Home"], "Home", false, true)
recentsSectionObj = makeSection("Recents", tabContainers["Home"], "Home", false, false)
makeSection("Favorites", tabContainers["Home"], "Home", true,  false)
autoExecSectionObj = makeSection("Auto Executes", tabContainers["Home"], "Home", false, false)

Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = tabContainers["Home"]})
Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = tabContainers["Scripts"]})

rebuildRecentsPills()
rebuildFavorites()
rebuildActive()
rebuildAutoExec()

CollapseAllBtn.MouseButton1Click:Connect(function()
    if not activeTab then return end
    for _, sec in ipairs(tabSections[activeTab]) do
        if sec.IsOpen() then sec.SetOpen(false) end
    end
end)

local switchTab
local function makeDraggableReal(object, handle)
    local dragging = false
    local relative = Vector2.zero
    local insetOff = Vector2.zero
    local sg = object:FindFirstAncestorWhichIsA("ScreenGui")
    if sg and sg.IgnoreGuiInset then
        local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
        if ok then insetOff = insetOff + inset end
    end
    handle.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            relative = Vector2.new(object.AbsolutePosition.X, object.AbsolutePosition.Y)
            + Vector2.new(object.AbsoluteSize.X * object.AnchorPoint.X, object.AbsoluteSize.Y * object.AnchorPoint.Y)
            - UserInputService:GetMouseLocation()
        end
    end)
    local ec = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    local rc = RunService.RenderStepped:Connect(function()
        if dragging then
            local pos = UserInputService:GetMouseLocation() + relative + insetOff
            object.Position = UDim2.fromOffset(pos.X, pos.Y)
        end
    end)
    object.Destroying:Connect(function() ec:Disconnect(); rc:Disconnect() end)
end

makeDraggableReal(Main, Main)
makeDraggableReal(PillUI, PillUI)
local tweenInfo   = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pillUsed    = false
local lastMainPos = Main.Position
local isAnimating = false

CloseBtn.MouseButton1Click:Connect(function() CloseOverlay.Visible = true end)

local PILL_H_SIZE = ud2(0,110,0,34)
local PILL_V_SIZE = ud2(0,34,0,90)

-- API GLOBAL CREATION (Includes Animation Exposing)
_G.UNScripts = {}
_G.UNScripts.PillVertical = false
_G.UNScripts.onLightModeChange = function(isLight)
    _G.UNS_LightMode = isLight
    if _G.UNScripts and _G.UNScripts.ApplyTheme then
        _G.UNScripts.ApplyTheme(isLight)
    end
end

local function shrinkToPill()
    if not Main.Visible or isAnimating then return end
    isAnimating = true
    lastMainPos = Main.Position
    local targetPillSize = _G.UNScripts.PillVertical and PILL_V_SIZE or PILL_H_SIZE
    PillUI.Text = _G.UNScripts.PillVertical and '<font color="rgb(50,120,255)">U</font>\n<font color="rgb(50,120,255)">N</font>\nS' or '<font color="rgb(50,120,255)">UN</font>Scripts'

    if _G.UNScripts.PillVertical then
        PillUI.Size = ud2(0,34,0,0)
    else
        PillUI.Size = ud2(0,0,0,34)
    end

    PillUI.Visible  = true
    PillScale.Scale = 0
    TweenService:Create(PillUI,    tweenInfo, {Size = targetPillSize}):Play()
    TweenService:Create(PillScale, tweenInfo, {Scale = 1}):Play()
    TweenService:Create(MainScale, tweenInfo, {Scale = 0}):Play()
    TweenService:Create(Main, tweenInfo, {
        Position = ud2(PillUI.Position.X.Scale, PillUI.Position.X.Offset,
        PillUI.Position.Y.Scale, PillUI.Position.Y.Offset + 17)
    }):Play()
    task.delay(0.32, function()
        if Main and Main.Parent then Main.Visible = false end
        isAnimating = false
    end)
end

local function expandFromPill()
    if not PillUI.Visible or isAnimating then return end
    isAnimating   = true
    Main.Position = lastMainPos
    Main.Visible  = true
    TweenService:Create(PillScale, tweenInfo, {Scale = 0}):Play()
    TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.4 or 1}):Play()
    task.delay(0.32, function()
        if PillUI and PillUI.Parent then PillUI.Visible = false; PillScale.Scale = 1 end
        isAnimating = false
        if activeSectionObj and activeSectionObj.IsOpen() then
            activeSectionObj.resizeToContent()
            local h = activeSectionObj.Content.Size.Y.Offset
            if h > 0 then
                activeSectionObj.Wrapper.Size = ud2(1,-16,0, SECTION_H + 4 + h)
            end
        end
    end)
end

MinBtn.MouseButton1Click:Connect(shrinkToPill)

MaxBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.4 or 1}):Play()
    triggerAutoSave()
end)

local pillDragStart = nil
PillUI.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        pillDragStart = input.Position
    end
end)
PillUI.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and pillDragStart then
        if (input.Position - pillDragStart).Magnitude < 6 then expandFromPill() end
        pillDragStart = nil
    end
end)

function switchTab(tabName)
    if activeTab == tabName then return end
    activeTab = tabName
    for key, tab in pairs(tabs) do
        local active = (key == tabName)
        local targetTextKey = active and "textPri" or "textSec"
        updateThemeTag(tab.Button, "TextColor3", targetTextKey)

        TweenService:Create(tab.Pill, tabTween, { Size = active and ud2(0,40,0,2) or ud2(0,0,0,2) }):Play()
        TweenService:Create(tab.Button, tabTween, { TextColor3 = C[targetTextKey], BackgroundTransparency = active and 0.2 or 0.5 }):Play()
    end
    for key, container in pairs(tabContainers) do
        container.Visible = (key == tabName)
    end
    updateCollapseAllVisibility()
end
_G.UNScripts.switchTab = switchTab
_G.UNScripts.tabContainers = tabContainers
_G.UNScripts.tabSections = tabSections

function _G.UNScripts:NavigateTo(tabName, sectionName)
    switchTab(tabName)
    task.wait(0.05)
    local sections = tabSections[tabName]
    if not sections then return end

    for _, otherSec in ipairs(sections) do
        if otherSec.Name ~= sectionName and otherSec.IsOpen() then
            otherSec:SetOpen(false)
        end
    end

    for _, sec in ipairs(sections) do
        if sec.Name == sectionName then
            if not sec.IsOpen() then sec:SetOpen(true) end
            task.wait(0.2)
            if sec.Wrapper and sec.Wrapper.Parent then
                local scroll = sec.Wrapper
                while scroll and not scroll:IsA("ScrollingFrame") do
                    scroll = scroll.Parent
                end
                if scroll then
                    task.wait()
                    local viewH = scroll.AbsoluteSize.Y
                    local centerOff = viewH / 2 - sec.Wrapper.AbsoluteSize.Y / 2
                    local curOff = sec.Wrapper.AbsolutePosition.Y - scroll.AbsolutePosition.Y
                    local newPos = scroll.CanvasPosition.Y + curOff - centerOff
                    scroll.CanvasPosition = Vector2.new(0, math.max(0, newPos))
                end
                local header = sec.Wrapper:FindFirstChildOfClass("Frame")
                if header then
                    local oc, ot = header.BackgroundColor3, header.BackgroundTransparency
                    header.BackgroundColor3 = C.accent
                    header.BackgroundTransparency = 0.1
                    task.wait(0.7)
                    if header and header.Parent then
                        TweenService:Create(header, TweenInfo.new(0.5), {BackgroundColor3 = oc, BackgroundTransparency = ot}):Play()
                    end
                end
            end
            break
        end
    end
end

tabs.Home.Button.MouseButton1Click:Connect(function() switchTab("Home") end)
switchTab("Home")

-- ============================================================
-- GLOBAL REGISTRY / API FOR EXTERNAL SCRIPTS 
-- ============================================================
local apiCounter = 9000

local rebuildQueued = false
local function queueRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        if rebuildFavorites then rebuildFavorites() end
        if rebuildActive then rebuildActive() end
        rebuildQueued = false
    end)
end

_G.UNScripts.ToggleUI = function()
    if Main.Visible then shrinkToPill() elseif PillUI.Visible then expandFromPill() end
end

_G.UNScripts.SetCollapsePosition = function(pos)
    if CollapseAllBtn then
        CollapseAllBtn.Position = (pos == "Left") and ud2(0,4,0.5,-13) or ud2(1,-30,0.5,-13)
    end
end

_G.UNScripts.SetToggleByLabel = function(label, state)
    for _, data in pairs(originalToggles) do
        if data.name == label and data.toggle and data.toggle.SetOn then
            data.toggle.SetOn(state, false)
            return true
        end
    end
    for _, data in pairs(proxyToggles) do
        if data.name == label and data.toggle and data.toggle.SetOn then
            data.toggle.SetOn(state, false)
            return true
        end
    end
    return false
end

_G.UNScripts.GetToggleState = function(label)
    for _, data in pairs(originalToggles) do
        if data.name == label and data.toggle and data.toggle.IsOn then
            return data.toggle.IsOn()
        end
    end
    for _, data in pairs(proxyToggles) do
        if data.name == label and data.toggle and data.toggle.IsOn then
            return data.toggle.IsOn()
        end
    end
    return nil
end

_G.UNScripts.ApplyTheme = function(isLight)
    if isLight then
        C.bg         = rgb(240, 240, 240)
        C.surface    = rgb(222, 222, 222)
        C.part_bg    = rgb(215, 215, 215)
        C.surfaceAlt = rgb(200, 200, 200)
        C.border     = rgb(180, 180, 180)
        C.textPri    = rgb(30, 30, 30)
        C.textSec    = rgb(90, 90, 90)
        C.toggle_off = rgb(170, 170, 170)
        C.knob       = rgb(255, 255, 255)
        C.white      = rgb(20, 20, 20)
        C.tab_stroke = rgb(170, 170, 170)
    else
        C.bg         = rgb(25, 25, 25)
        C.surface    = rgb(35, 35, 35)
        C.part_bg    = rgb(45, 45, 45)
        C.surfaceAlt = rgb(40, 40, 40)
        C.border     = rgb(45, 45, 52)
        C.textPri    = rgb(218, 218, 222)
        C.textSec    = rgb(115, 115, 128)
        C.toggle_off = rgb(55,  55,  62)
        C.knob       = rgb(245, 245, 248)
        C.white      = rgb(255, 255, 255)
        C.tab_stroke = rgb(59, 59, 59)
    end

    for _, record in ipairs(themeRegistry) do
        if record.obj and record.obj.Parent then
            for prop, cKey in pairs(record.tags) do
                if C[cKey] then
                    pcall(function() record.obj[prop] = C[cKey] end)
                end
            end
        end
    end

    -- Directly update tab buttons (belt-and-suspenders for Make tracking)
    for _, t in pairs(tabs) do
        if t.Button and t.Button.Parent then
            t.Button.BackgroundColor3 = C.surfaceAlt
            t.Button.TextColor3 = C.textSec
            for _, child in ipairs(t.Button:GetChildren()) do
                if child:IsA("UIStroke") then
                    child.Color = C.tab_stroke
                end
            end
        end
    end
end

function _G.UNScripts:CreateTab(tabName)
    if not tabs[tabName] then
        tabs[tabName] = makeTab(tabName)
        tabContainers[tabName] = buildTabContainer(false)
        tabSections[tabName] = {}
        tabs[tabName].Button.MouseButton1Click:Connect(function() switchTab(tabName) end)
        Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = tabContainers[tabName]})
    end
    
    local TabAPI = {}
    function TabAPI:CreateSection(sectionName)
        local sectionObj = makeSection(sectionName, tabContainers[tabName], tabName, false, false)
        local SectionAPI = {}
        
        function SectionAPI:CreateToggle(label, callback, initOn)
            apiCounter = apiCounter + 1
            local uid = "API_Tgl_"..apiCounter
            toggleCallbacks[uid] = callback
            if initOn ~= nil then partState[uid] = initOn end
            createTogglePart(sectionObj.Content, label, uid, apiCounter, false)
            sectionObj.resizeToContent()
            queueRebuild()
        end
        function SectionAPI:CreateButton(label, callback)
            apiCounter = apiCounter + 1
            makeButton(sectionObj.Content, label, callback, "API_Btn_"..apiCounter, false, apiCounter)
            sectionObj.resizeToContent()
            queueRebuild()
        end
        function SectionAPI:CreateSlider(label, min, max, default, callback)
            apiCounter = apiCounter + 1
            makeSlider(sectionObj.Content, label, min, max, default, callback, "API_Sld_"..apiCounter, false, apiCounter)
            sectionObj.resizeToContent()
            queueRebuild()
        end
        function SectionAPI:CreateDropdown(label, options, default, callback)
            apiCounter = apiCounter + 1
            makeDropdown(sectionObj.Content, label, options, default, callback, "API_Drp_"..apiCounter, false, apiCounter, sectionObj)
            sectionObj.resizeToContent()
        end
        function SectionAPI:CreateLabel(text)
            apiCounter = apiCounter + 1
            makeLabel(sectionObj.Content, text, "API_Lbl_"..apiCounter, apiCounter)
            sectionObj.resizeToContent()
        end
        function SectionAPI:CreatePageButton(label, pageTitle, setupFn)
            apiCounter = apiCounter + 1
            local uid = "PBtn_"..apiCounter
            makePageButton(sectionObj.Content, label, pageTitle or label, setupFn, apiCounter, uid, false)
            sectionObj.resizeToContent()
            queueRebuild()
        end
        function SectionAPI:CreateShortcutButton(label, targetTab, targetSection)
            apiCounter = apiCounter + 1
            makeButton(sectionObj.Content, label, function()
                _G.UNScripts:NavigateTo(targetTab, targetSection)
            end, "API_Shortcut_"..apiCounter, false, apiCounter)
            sectionObj.resizeToContent()
            queueRebuild()
        end
        return SectionAPI
    end
    return TabAPI
end

function _G.UNScripts:CreateSection(sectionName)
    local sectionObj = makeSection(sectionName, tabContainers["Scripts"], "Scripts", false, false)
    local SectionAPI = {}
    
    function SectionAPI:CreateToggle(label, callback, initOn)
        apiCounter = apiCounter + 1
        local uid = "API_Tgl_"..apiCounter
        toggleCallbacks[uid] = callback
        if initOn ~= nil then partState[uid] = initOn end
        createTogglePart(sectionObj.Content, label, uid, apiCounter, false)
        sectionObj.resizeToContent()
        queueRebuild()
    end
    function SectionAPI:CreateButton(label, callback)
        apiCounter = apiCounter + 1
        makeButton(sectionObj.Content, label, callback, "API_Btn_"..apiCounter, false, apiCounter)
        sectionObj.resizeToContent()
        queueRebuild()
    end
    function SectionAPI:CreateSlider(label, min, max, default, callback)
        apiCounter = apiCounter + 1
        makeSlider(sectionObj.Content, label, min, max, default, callback, "API_Sld_"..apiCounter, false, apiCounter)
        sectionObj.resizeToContent()
        queueRebuild()
    end
    function SectionAPI:CreateDropdown(label, options, default, callback)
        apiCounter = apiCounter + 1
        makeDropdown(sectionObj.Content, label, options, default, callback, "API_Drp_"..apiCounter, false, apiCounter, sectionObj)
        sectionObj.resizeToContent()
    end
    function SectionAPI:CreateLabel(text)
        apiCounter = apiCounter + 1
        makeLabel(sectionObj.Content, text, "API_Lbl_"..apiCounter, apiCounter)
        sectionObj.resizeToContent()
    end
    function SectionAPI:CreatePageButton(label, pageTitle, setupFn)
        apiCounter = apiCounter + 1
        local uid = "PBtn_"..apiCounter
        makePageButton(sectionObj.Content, label, pageTitle or label, setupFn, apiCounter, uid, false)
        sectionObj.resizeToContent()
        queueRebuild()
    end
    function SectionAPI:CreateShortcutButton(label, targetTab, targetSection)
        apiCounter = apiCounter + 1
        makeButton(sectionObj.Content, label, function()
            _G.UNScripts:NavigateTo(targetTab, targetSection)
        end, "API_Shortcut_"..apiCounter, false, apiCounter)
        sectionObj.resizeToContent()
        queueRebuild()
    end
    return SectionAPI
end

-- ════════════════════════════ CONTEXT MENU ════════════════════════════
local menuFrame = nil
local menuConnections = {}

closeCtxMenu = function()
    if menuFrame then
        local scale = menuFrame:FindFirstChild("UIScale")
        if scale then
            TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
            TweenService:Create(menuFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            task.delay(0.18, function()
                if menuFrame then menuFrame:Destroy() end
            end)
        else
            menuFrame:Destroy()
        end
        menuFrame = nil
    end
    for _, conn in ipairs(menuConnections) do
        conn:Disconnect()
    end
    menuConnections = {}
end

    openCtxMenu = function(ctxData, inputPos)
        closeCtxMenu()
        local pos = inputPos or UserInputService:GetMouseLocation()
        local menu = Make("Frame", {
            Size = ud2(0,135,0,0), Position = ud2(0, pos.X, 0, pos.Y),
            BackgroundColor3 = C.surface,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ZIndex = 200, Active = true, Parent = Gui,
            AutomaticSize = Enum.AutomaticSize.Y,
        })
    Make("UICorner", {CornerRadius = ud(0,8), Parent = menu})
    Make("UIStroke", {Color = C.border, Thickness = 1, Parent = menu})
    local layout = Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,3), Parent = menu,
    })
    Make("UIPadding", {
        PaddingTop = ud(0,6), PaddingBottom = ud(0,6),
        PaddingLeft = ud(0,8), PaddingRight = ud(0,8), Parent = menu,
    })

    menuFrame = menu

    local menuScale = Make("UIScale", {Scale = 0, Parent = menu})
    TweenService:Create(menuScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TweenService:Create(menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()

    local function addItem(text, onClick)
        local btn = Make("TextButton", {
            Size = ud2(1,0,0,30), BackgroundColor3 = C.surface,
            BackgroundTransparency = 0, Text = text,
            TextColor3 = C.textPri, TextSize = 13, Font = semi,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = menu,
        })
        Make("UICorner", {CornerRadius = ud(0,4), Parent = btn})
        btn.MouseButton1Click:Connect(function()
            onClick()
            closeCtxMenu()
        end)
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = C.surfaceAlt
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = C.surface
        end)
    end

    local uid = ctxData.uid

    if ctxData.type == "toggle" then
        addItem("Toggle " .. (ctxData.isOn() and "Off" or "On"), function()
            ctxData.setOn(not ctxData.isOn())
        end)
    elseif ctxData.type == "button" then
        addItem("Execute", function()
            if ctxData.callback then ctxData.callback() end
        end)
    elseif ctxData.type == "slider" then
        addItem("Favorite", function()
            cfgFavorites[uid] = not cfgFavorites[uid]
            local ck = cfgFavorites[uid] and "dot_yel" or "textSec"
            if sliderFavObj[uid] and sliderFavObj[uid].star then
                updateThemeTag(sliderFavObj[uid].star, "TextColor3", ck)
                sliderFavObj[uid].star.TextColor3 = C[ck]
            end
            triggerAutoSave()
            if rebuildFavorites then rebuildFavorites() end
        end)
    elseif ctxData.type == "page" then
        addItem("Favorite", function()
            cfgFavorites[uid] = not cfgFavorites[uid]
            local ck = cfgFavorites[uid] and "dot_yel" or "textSec"
            if pageButtonParams[uid] and pageButtonParams[uid].star then
                updateThemeTag(pageButtonParams[uid].star, "TextColor3", ck)
                pageButtonParams[uid].star.TextColor3 = C[ck]
            end
            triggerAutoSave()
            if rebuildFavorites then rebuildFavorites() end
        end)
    end

    addItem(cfgFavorites[uid] and "☆ Unfavorite" or "★ Favorite", function()
        cfgFavorites[uid] = not cfgFavorites[uid]
        local ck = cfgFavorites[uid] and "dot_yel" or "textSec"
        if originalToggles[uid] and originalToggles[uid].star then
            updateThemeTag(originalToggles[uid].star, "TextColor3", ck)
            originalToggles[uid].star.TextColor3 = C[ck]
        end
        if buttonParams[uid] and buttonParams[uid].star then
            updateThemeTag(buttonParams[uid].star, "TextColor3", ck)
            buttonParams[uid].star.TextColor3 = C[ck]
        end
        if sliderFavObj[uid] and sliderFavObj[uid].star then
            updateThemeTag(sliderFavObj[uid].star, "TextColor3", ck)
            sliderFavObj[uid].star.TextColor3 = C[ck]
        end
        triggerAutoSave()
        rebuildFavorites()
    end)

    local isAuto = _G.autoExecFeatures[uid] ~= nil
    addItem(isAuto and "Disable Auto Execute" or "Auto Execute", function()
        if isAuto then
            _G.autoExecFeatures[uid] = nil
        else
            _G.autoExecFeatures[uid] = { type = ctxData.type }
        end
        triggerAutoSave()
        rebuildAutoExec()
    end)

    local closeConn
    closeConn = UserInputService.InputBegan:Connect(function(input, g)
        if g then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            closeCtxMenu()
        end
    end)
    table.insert(menuConnections, closeConn)
end

makePillInteractive = function(pill, ctxData)
    local pressTimer = nil
    pill.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            openCtxMenu(ctxData, Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    pill.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            pressTimer = task.delay(0.5, function()
                openCtxMenu(ctxData)
            end)
        end
    end)
    pill.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Touch and pressTimer then
            task.cancel(pressTimer)
            pressTimer = nil
        end
    end)
end

-- ════════════════════════════ AUTO-EXECUTE STARTUP ════════════════════════════
task.spawn(function()
    task.wait(3)
    local seen = {}
    local maxRetries = 10
    for attempt = 1, maxRetries do
        local anyPending = false
        for uid, meta in pairs(_G.autoExecFeatures) do
            if not seen[uid] then
                local found = false
                local itemType = meta and meta.type
                if itemType == "toggle" then
                    if originalToggles[uid] then
                        originalToggles[uid].toggle.SetOn(true, false)
                        if toggleCallbacks[uid] then pcall(toggleCallbacks[uid], true) end
                        if rebuildActive then rebuildActive() end
                        seen[uid] = true
                        found = true
                    end
                elseif itemType == "button" then
                    if buttonParams[uid] then
                        pcall(buttonParams[uid].callback)
                        found = true
                    end
                    seen[uid] = true
                end
                if not found then anyPending = true end
            end
        end
        if not anyPending then break end
        task.wait(1)
    end
end)

-- Auto-apply theme from saved config
if cfgLightMode then
    _G.UNScripts.ApplyTheme(true)
end

Gui.Destroying:Connect(function()
    if _G.UNS_HostCleanup then _G.UNS_HostCleanup() end
end)

print("[UNScripts] Global Base UI Loaded Successfully")