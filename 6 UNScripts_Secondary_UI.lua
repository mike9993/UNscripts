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
local scrollConn = UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local m = UserInputService:GetMouseLocation()
        for _, sf in ipairs(_G.passiveScrollFrames_Secondary) do
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
}

local CFG_FOLDER = "UNScripts"
local CFG_FILE   = "settings_secondary"
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

local isExpanded         = cfgIsExpanded

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

if type(_G.UNS_Secondary_HostCleanup) == "function" then _G.UNS_Secondary_HostCleanup() end
_G.UNS_Secondary_HostCleanup = function()
    if scrollConn then scrollConn:Disconnect(); scrollConn = nil end
    if closeOverlayConn then closeOverlayConn:Disconnect(); closeOverlayConn = nil end
    if _G.UNS_Secondary_CleanupList then
        for _, fn in ipairs(_G.UNS_Secondary_CleanupList) do
            pcall(fn)
        end
        _G.UNS_Secondary_CleanupList = {}
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
    pcall(function()
        for _, v in ipairs(CoreGui:GetChildren()) do
            if v.Name == "UNScripts_Secondary_UI" then
                v:Destroy()
            end
        end
        local sg = game:GetService("StarterGui")
        for _, v in ipairs(sg:GetChildren()) do
            if v.Name == "UNScripts_Secondary_UI" then
                v:Destroy()
            end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, v in ipairs(pg:GetChildren()) do
                if v.Name == "UNScripts_Secondary_UI" then
                    v:Destroy()
                end
            end
        end
    end)
    _G.passiveScrollFrames_Secondary = {}
    _G.sectionToggles_Secondary = setmetatable({}, {__mode = "k"})
    _G.UNScripts_Secondary = {}
end
if not _G.UNS_Secondary_CleanupList then _G.UNS_Secondary_CleanupList = {} end

local existingGui = uiParent:FindFirstChild("UNScripts_Secondary_UI")
if existingGui then existingGui:Destroy() end

local Gui = Make("ScreenGui", {
    Name           = "UNScripts_Secondary_UI",
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
    BackgroundTransparency = 1, Text = '<font color="rgb(50,120,255)">UN</font>Fling',
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
    BackgroundTransparency = 0, Text = '<font color="rgb(50,120,255)">UN</font>Fling',
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
_G.UNScripts_Secondary = {}
_G.UNScripts_Secondary.PillVertical = false

local function shrinkToPill()
    if not Main.Visible or isAnimating then return end
    isAnimating = true
    lastMainPos = Main.Position
    local targetPillSize = _G.UNScripts_Secondary.PillVertical and PILL_V_SIZE or PILL_H_SIZE
    PillUI.Text = _G.UNScripts_Secondary.PillVertical and "U\nN\nS" or "UNScripts"

    if _G.UNScripts_Secondary.PillVertical then
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

_G.UNScripts_Secondary.HeaderBar = HeaderBar
_G.UNScripts_Secondary.Main = Main
_G.UNScripts_Secondary.MainPage = MainPage
_G.UNScripts_Secondary.makeHeaderIcon = makeHeaderIcon
_G.UNScripts_Secondary.Make = Make
_G.UNScripts_Secondary.C = C

_G.UNScripts_Secondary.ToggleUI = function()
    if Main.Visible then shrinkToPill() elseif PillUI.Visible then expandFromPill() end
end

_G.UNScripts_Secondary.ApplyTheme = function(isLight)
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
end

-- Auto-detect theme from global or secondary settings config
if _G.UNS_LightMode ~= nil then
    _G.UNScripts_Secondary.ApplyTheme(_G.UNS_LightMode)
else
    local secCfgPath = CFG_FOLDER.."/".."settings_plugin_secondary"..CFG_EXT
    if cfgSafely(isfile, secCfgPath) then
        local c = cfgSafely(readfile, secCfgPath)
        if c then
            local ok, d = pcall(function() return HttpService:JSONDecode(c) end)
            if ok and type(d) == "table" and d.lightMode ~= nil then
                _G.UNS_LightMode = d.lightMode
                _G.UNScripts_Secondary.ApplyTheme(d.lightMode)
            end
        end
    end
end
_G.UNScripts_Secondary.onLightModeChange = function(isLight)
    _G.UNS_LightMode = isLight
    if _G.UNScripts_Secondary and _G.UNScripts_Secondary.ApplyTheme then
        _G.UNScripts_Secondary.ApplyTheme(isLight)
    end
end

Gui.Destroying:Connect(function()
    if _G.UNS_Secondary_HostCleanup then _G.UNS_Secondary_HostCleanup() end
end)

print("[UNFling] Global Base UI Loaded Successfully")