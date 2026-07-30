-- ============================================================
--  UNScripts Combined Plugin P2 — Dropdown UI Edition
--  Features organized under collapsible sections:
--    - Aim Assist
--    - Visual
--    - Server
--    - Character
--  Run AFTER UNScripts_Host_UI loads.
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")
local MaterialService  = game:GetService("MaterialService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local PlaceId     = game.PlaceId
local JobId       = game.JobId

local function waitForHost()
    for _ = 1, 100 do
        if _G.UNScripts and type(_G.UNScripts.CreateTab) == "function" then return true end
        task.wait(0.5)
    end
    return false
end

if not waitForHost() then
    warn("[Combined Plugin P2] Host UI not found")
    return
end

if type(_G.UNS_CombinedCleanupP2) == "function" then _G.UNS_CombinedCleanupP2() end

-- ============================================================
--  State Variables
-- ============================================================

-- Aim Assist
local aimAssistEnabled = false
local wallCheckEnabled = true
local aimSmoothness = 0.15
local isAiming = false
local aimAssistBegan = nil
local aimAssistEnded = nil
local aimAssistRender = nil

-- Visual — other
local origBrightness = Lighting.Brightness
local origAmbient = Lighting.Ambient
local origOutdoorAmb = Lighting.OutdoorAmbient
local fullBrightActive = false
local rainbowSkyEnabled_IY = false
local rainbowSkyConn = nil
local shadowsDisabled_IY = false
local fovSetting = 70
local lightObj = nil

-- Character
local antiFlingEnabled = false
local antiFlingConn = nil
local bangConn = nil
local bangAnimTrack = nil
local bangEnabled = false
local headSitConn = nil
local jerkToolRef = nil
local jerkEnabled = false

-- Server
local antiAFKEnabled_IY = false
local antiAFKConn_IY = nil
local antiLagEnabled = false
local origSettings = {}

-- ============================================================
--  Helper Functions
-- ============================================================

local function getRoot(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("LowerTorso"))
end

local function getHum(c)
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function chr()
    return LocalPlayer.Character
end

local function root()
    return getRoot(chr())
end

local function hum()
    return getHum(chr())
end

local function getAllPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    return list
end

local function r15(plr)
    local c = plr.Character
    if c then
        local h = c:FindFirstChildWhichIsA("Humanoid")
        if h and h.RigType == Enum.HumanoidRigType.R15 then return true end
    end
    return false
end

-- ============================================================
--  Visual Functions
-- ============================================================

local function toggleFullBright(state)
    if state then
        fullBrightActive = true
        Lighting.Brightness = 10
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        fullBrightActive = false
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
        Lighting.OutdoorAmbient = origOutdoorAmb
    end
end

local function toggleRainbowSky_IY(state)
    rainbowSkyEnabled_IY = state
    if rainbowSkyConn then rainbowSkyConn:Disconnect(); rainbowSkyConn = nil end
    if state then
        rainbowSkyConn = RunService.Heartbeat:Connect(function()
            local h = tick() % 10 * 36
            Lighting.Ambient = Color3.fromHSV(h/360, 0.5, 1)
            Lighting.OutdoorAmbient = Color3.fromHSV(h/360, 0.4, 0.9)
        end)
    else
        if not fullBrightActive then
            Lighting.Ambient = origAmbient
            Lighting.OutdoorAmbient = origOutdoorAmb
        end
    end
end

local function setFOV(v)
    fovSetting = v
    Camera.FieldOfView = v
end

local function setCameraFOV(v)
    pcall(function() Camera.FieldOfView = v end)
end

local function setMaxZoom(v)
    LocalPlayer.CameraMaxZoomDistance = v
end

local function setMinZoom(v)
    LocalPlayer.CameraMinZoomDistance = v
end

local function setCamDist(v)
    local max = LocalPlayer.CameraMaxZoomDistance
    local min = LocalPlayer.CameraMinZoomDistance
    if max < tonumber(v) then max = v end
    LocalPlayer.CameraMaxZoomDistance = v
    LocalPlayer.CameraMinZoomDistance = v
    task.wait()
    LocalPlayer.CameraMaxZoomDistance = max
    LocalPlayer.CameraMinZoomDistance = min
end

local function setBrightness(v)
    Lighting.Brightness = v
end

local function toggleShadows_IY(state)
    shadowsDisabled_IY = state
    Lighting.GlobalShadows = not state
end

local function toggleDisableDecals(state)
    task.spawn(function()
        task.wait(0.1)
        for _, o in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("Decal") or o:IsA("Texture") then o.Transparency = state and 1 or 0 end
            end)
        end
    end)
end

local function toggleLight(state)
    if not state then
        if lightObj then pcall(function() lightObj:Destroy() end); lightObj = nil end
        return
    end
    local r = root()
    if r then
        lightObj = Instance.new("PointLight")
        lightObj.Range = 30; lightObj.Brightness = 5; lightObj.Parent = r
    end
end

local function toggle2022Materials(state)
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(MaterialService, "Use2022Materials", state)
        elseif set_hidden_property then
            set_hidden_property(MaterialService, "Use2022Materials", state)
        end
    end)
end

local function fakeout()
    local c = chr()
    if not c then return end
    local clone = c:Clone()
    clone.Parent = workspace
    clone.Name = LocalPlayer.Name .. " (fake)"
    local h = clone:FindFirstChildWhichIsA("Humanoid")
    if h then
        h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        task.spawn(function()
            local r = getRoot(clone)
            if r then
                r.Velocity = Vector3.new(math.random(-50,50), 50, math.random(-50,50))
            end
            task.wait(5)
            clone:Destroy()
        end)
    end
end

local function setDay()
    Lighting.ClockTime = 14
end

local function setNight()
    Lighting.ClockTime = 0
end

local function apply4KShader()
    pcall(function()
        for i, v in pairs(Lighting:GetChildren()) do if v:IsA("PostEffect") or v:IsA("Sky") or v:IsA("Atmosphere") then v:Destroy() end end
        local Bloom = Instance.new("BloomEffect"); Bloom.Parent = Lighting
        local Blur = Instance.new("BlurEffect"); Blur.Parent = Lighting
        local ColorCor = Instance.new("ColorCorrectionEffect"); ColorCor.Parent = Lighting
        local SunRays = Instance.new("SunRaysEffect"); SunRays.Parent = Lighting
        local Sky = Instance.new("Sky"); Sky.Parent = Lighting
        local Atm = Instance.new("Atmosphere"); Atm.Parent = Lighting
        local Gui = Instance.new("ScreenGui"); Gui.Name = "UNS_4K_Shader"; Gui.Parent = StarterGui; Gui.IgnoreGuiInset = true
        local ShadowFrame = Instance.new("ImageLabel"); ShadowFrame.Parent = Gui
        ShadowFrame.AnchorPoint = Vector2.new(0.5,1); ShadowFrame.Position = UDim2.new(0.5,0,1,0)
        ShadowFrame.Size = UDim2.new(1,0,1.05,0); ShadowFrame.BackgroundTransparency = 1
        ShadowFrame.Image = "rbxassetid://4576475446"; ShadowFrame.ImageTransparency = 0.3; ShadowFrame.ZIndex = 10
        Bloom.Intensity = 0.3; Bloom.Size = 10; Bloom.Threshold = 0.8; Blur.Size = 5
        ColorCor.Brightness = 0.1; ColorCor.Contrast = 0.5; ColorCor.Saturation = -0.3; ColorCor.TintColor = Color3.fromRGB(255,235,203)
        SunRays.Intensity = 0.075; SunRays.Spread = 0.727
        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=151165214"; Sky.SkyboxDn = "http://www.roblox.com/asset/?id=151165197"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=151165224"; Sky.SkyboxLf = "http://www.roblox.com/asset/?id=151165191"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=151165206"; Sky.SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
        Lighting.Ambient = Color3.fromRGB(2,2,2); Lighting.Brightness = 2.25; Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0); Lighting.ClockTime = 17; Lighting.GeographicLatitude = 45
        Atm.Density = 0.364; Atm.Offset = 0.556; Atm.Color = Color3.fromRGB(199,175,166); Atm.Decay = Color3.fromRGB(44,39,33); Atm.Glare = 0.36; Atm.Haze = 1.72
    end)
end

local function destroyAllParticles()
    task.spawn(function()
        for _, o in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if o:IsA("ParticleEmitter") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then o:Destroy() end
            end)
        end
    end)
end

local function removeLightingFX()
    for _, o in ipairs(Lighting:GetChildren()) do pcall(function() if o:IsA("PostEffect") then o:Destroy() end end) end
end

-- ============================================================
--  Character Functions
-- ============================================================

local function toggleAntiFling(state)
    antiFlingEnabled = state
    if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
    if state then
        antiFlingConn = RunService.Stepped:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, v in pairs(player.Character:GetDescendants()) do
                        if v:IsA("BasePart") and not v:FindFirstAncestorOfClass("Accessory") then
                            v.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
end

local function toggleBang(state)
    bangEnabled = state
    if bangConn then bangConn:Disconnect(); bangConn = nil end
    if bangAnimTrack then bangAnimTrack:Stop(); bangAnimTrack = nil end
    if not state then return end
    local plrs = getAllPlayers()
    if #plrs == 0 then return end
    local p = plrs[1]
    local h = hum()
    if h then
        local anim = Instance.new("Animation")
        anim.AnimationId = not r15(LocalPlayer) and "rbxassetid://148840371" or "rbxassetid://5918726674"
        bangAnimTrack = h:LoadAnimation(anim)
        bangAnimTrack:Play(0.1, 1, 1)
        bangAnimTrack:AdjustSpeed(3)
        local diedConn = h.Died:Connect(function()
            bangAnimTrack:Stop()
            bangAnimTrack = nil
            if bangConn then bangConn:Disconnect(); bangConn = nil end
            diedConn:Disconnect()
        end)
        bangConn = RunService.Stepped:Connect(function()
            pcall(function()
                local pr = p.Character and getRoot(p.Character)
                local mr = root()
                if pr and mr then mr.CFrame = pr.CFrame * CFrame.new(0, 0, 1.1) end
            end)
        end)
    end
end

local function toggleJerk(state)
    jerkEnabled = state
    if jerkToolRef then jerkToolRef:Destroy(); jerkToolRef = nil end
    if not state then return end
    local h = hum()
    local bp = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if not h or not bp then return end
    local tool = Instance.new("Tool")
    tool.Name = "Jerk Off"
    tool.RequiresHandle = false
    tool.Parent = bp
    jerkToolRef = tool
    local jorking = false
    local track = nil
    local function stopTomfoolery()
        jorking = false
        if track then track:Stop(); track = nil end
    end
    tool.Equipped:Connect(function() jorking = true end)
    tool.Unequipped:Connect(stopTomfoolery)
    h.Died:Connect(stopTomfoolery)
    task.spawn(function()
        while tool and tool.Parent do
            if not jorking then task.wait(); continue end
            local isR15 = r15(LocalPlayer)
            if not track then
                local anim = Instance.new("Animation")
                anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                track = h:LoadAnimation(anim)
            end
            track:Play()
            track:AdjustSpeed(isR15 and 0.7 or 0.65)
            track.TimePosition = 0.6
            task.wait(0.1)
            while track and track.TimePosition < (not isR15 and 0.65 or 0.7) do task.wait(0.1) end
            if track then
                track:Stop()
                track = nil
            end
        end
    end)
end

local function toggleHeadsit(plrs, state)
    if headSitConn then headSitConn:Disconnect(); headSitConn = nil end
    if not state then return end
    local h = hum()
    if h then h.Sit = true end
    if plrs and #plrs > 0 then
        local p = plrs[1]
        headSitConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local pr = p.Character and getRoot(p.Character)
                local mr = root()
                if pr and mr and h and h.Sit == true then
                    mr.CFrame = pr.CFrame * CFrame.Angles(0, 0, 0) * CFrame.new(0, 1.6, 0.4)
                else
                    headSitConn:Disconnect(); headSitConn = nil
                end
            end)
        end)
    end
end

-- ============================================================
--  Server Functions
-- ============================================================

local function openExplorer()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end)
end

local function openRemoteSpy()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
    end)
end

local function toggleAntiAFK_IY(state)
    antiAFKEnabled_IY = state
    if antiAFKConn_IY then antiAFKConn_IY:Disconnect(); antiAFKConn_IY = nil end
    if state then
        antiAFKConn_IY = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
    end
end

local function rejoin()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end
end

local function serverHop()
    local ok, raw = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    end)
    if not ok then return end
    local data = HttpService:JSONDecode(raw)
    if data and data.data then
        local servers = {}
        for _, v in pairs(data.data) do
            if v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= JobId then
                table.insert(servers, v.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        end
    end
end

local function showPrompts()
    pcall(function()
        local ppa = CoreGui:FindFirstChild("PurchasePromptApp")
        if ppa then ppa.Enabled = true end
    end)
end

local function toggleAntiLag(state)
    antiLagEnabled = state
    if state then
        origSettings = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            QualityLevel = settings().Rendering.QualityLevel,
        }
        local terrain = workspace:FindFirstChildWhichIsA("Terrain")
        if terrain then
            origSettings.WaterWaveSize = terrain.WaterWaveSize
            origSettings.WaterWaveSpeed = terrain.WaterWaveSpeed
            origSettings.WaterReflectance = terrain.WaterReflectance
            origSettings.WaterTransparency = terrain.WaterTransparency
            terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0; terrain.WaterTransparency = 1
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        settings().Rendering.QualityLevel = 1
        for _, v in pairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then v.CastShadow = false; v.Material = Enum.Material.Plastic; v.Reflectance = 0
                elseif v:IsA("Decal") then v.Transparency = 1; v.Texture = ""
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Lifetime = NumberRange.new(0) end
            end)
        end
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
    else
        if origSettings.GlobalShadows ~= nil then Lighting.GlobalShadows = origSettings.GlobalShadows end
        if origSettings.FogEnd then Lighting.FogEnd = origSettings.FogEnd end
        if origSettings.FogStart then Lighting.FogStart = origSettings.FogStart end
        if origSettings.QualityLevel then settings().Rendering.QualityLevel = origSettings.QualityLevel end
        local terrain = workspace:FindFirstChildWhichIsA("Terrain")
        if terrain and origSettings.WaterWaveSize ~= nil then
            terrain.WaterWaveSize = origSettings.WaterWaveSize
            terrain.WaterWaveSpeed = origSettings.WaterWaveSpeed
            terrain.WaterReflectance = origSettings.WaterReflectance
            terrain.WaterTransparency = origSettings.WaterTransparency
        end
        origSettings = {}
    end
end

-- ============================================================
--  Core Loops
-- ============================================================

-- Aim Assist
aimAssistBegan = UserInputService.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end
end)
aimAssistEnded = UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end
end)
aimAssistRender = RunService.RenderStepped:Connect(function()
    if aimAssistEnabled and isAiming then
        local mousePos = UserInputService:GetMouseLocation()
        local closest = nil; local shortestDist = math.huge
        local rayParams = RaycastParams.new(); rayParams.FilterType = Enum.RaycastFilterType.Exclude; rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local head = p.Character.Head; local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                        if dist < shortestDist then
                            local isVisible = true
                            if wallCheckEnabled then
                                local origin = Camera.CFrame.Position; local dest = head.Position
                                local result = workspace:Raycast(origin, dest - origin, rayParams)
                                if result and result.Instance and not result.Instance:IsDescendantOf(p.Character) then isVisible = false end
                            end
                            if isVisible then shortestDist = dist; closest = head end
                        end
                    end
                end
            end
        end
        if closest then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Position), aimSmoothness) end
    end
end)

-- ============================================================
--  Build UI — 4 Collapsible Sections
-- ============================================================

local tab = _G.UNScripts:CreateTab("Scripts P2")

-- Aim Assist
local aa = tab:CreateSection("Aim Assist")
aa:CreateToggle("Aim Assist", function(state) aimAssistEnabled = state end)
aa:CreateToggle("Wall Check", function(state) wallCheckEnabled = state end)
aa:CreateSlider("Aim Smoothness", 1, 100, 15, function(v) aimSmoothness = v / 100 end)

-- Visual
local vis = tab:CreateSection("Visual")
vis:CreateToggle("Fullbright", toggleFullBright)
vis:CreateToggle("Rainbow Sky_IY", toggleRainbowSky_IY)
vis:CreateToggle("Disable Shadows_IY", toggleShadows_IY)
vis:CreateToggle("Disable Decals", toggleDisableDecals)
vis:CreateToggle("Light", toggleLight)
vis:CreateToggle("2022 Materials", toggle2022Materials)
vis:CreateSlider("FOV", 50, 120, 70, setFOV)
vis:CreateSlider("Camera FOV", 50, 120, 70, setCameraFOV)
vis:CreateSlider("Max Zoom", 0.5, 500, 200, setMaxZoom)
vis:CreateSlider("Min Zoom", 0.5, 500, 0.5, setMinZoom)
vis:CreateSlider("Cam Distance", 0, 500, 20, setCamDist)
vis:CreateSlider("Brightness", 0, 10, 1, setBrightness)
vis:CreateButton("Fakeout", fakeout)
vis:CreateButton("Day", setDay)
vis:CreateButton("Night", setNight)
vis:CreateButton("4K Shader", apply4KShader)
vis:CreateButton("Destroy All Particles", destroyAllParticles)
vis:CreateButton("Remove Lighting FX", removeLightingFX)
-- Server
local srv = tab:CreateSection("Server")
srv:CreateButton("Explorer / Dex", openExplorer)
srv:CreateButton("Remote Spy", openRemoteSpy)
srv:CreateButton("Rejoin", rejoin)
srv:CreateButton("Server Hop", serverHop)
srv:CreateButton("Show Prompts", showPrompts)
srv:CreateToggle("Anti Lag", toggleAntiLag)
srv:CreateToggle("Anti-Afk", toggleAntiAFK_IY)

-- Character
local char = tab:CreateSection("Character")
char:CreateToggle("Anti-Fling", toggleAntiFling)
char:CreateToggle("Bang", toggleBang)
char:CreateToggle("Jerk", toggleJerk)
char:CreateToggle("Headsit", function(s)
    local plrs = getAllPlayers()
    toggleHeadsit(plrs, s)
end)
char:CreateButton("Respawn", function()
    pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
end)

-- ============================================================
--  Cleanup
-- ============================================================
local combinedCleanupP2 = function()
    if aimAssistBegan then aimAssistBegan:Disconnect(); aimAssistBegan = nil end
    if aimAssistEnded then aimAssistEnded:Disconnect(); aimAssistEnded = nil end
    if aimAssistRender then aimAssistRender:Disconnect(); aimAssistRender = nil end

    if fullBrightActive then toggleFullBright(false) end
    if rainbowSkyEnabled_IY then toggleRainbowSky_IY(false) end
    if shadowsDisabled_IY then toggleShadows_IY(false) end
    if lightObj then toggleLight(false) end
    toggleAntiFling(false); toggleBang(false); toggleJerk(false)
    toggleHeadsit({}, false)

    if antiLagEnabled then toggleAntiLag(false) end
    toggleAntiAFK_IY(false)

    pcall(function()
        local sg = StarterGui:FindFirstChild("UNS_4K_Shader")
        if sg then sg:Destroy() end
    end)
end
_G.UNS_CombinedCleanupP2 = combinedCleanupP2
table.insert(_G.UNS_CleanupList, combinedCleanupP2)

print("[Combined Plugin P2] Features organized under 4 dropdown sections")
