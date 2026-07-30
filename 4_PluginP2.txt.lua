-- ============================================================
--  UNScripts Combined Plugin P2 — Dropdown UI Edition
--  Features organized under collapsible sections:
--    - Aim Assist
--    - Visual
--    - Server
--    - Character
--    - Fling Script (page with Input & Fling, Defense, Utility dropdowns)
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

pcall(function() if type(_G.UNS_CombinedCleanupP2) == "function" then _G.UNS_CombinedCleanupP2() end end)

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
local bangConn = nil
local bangAnimTrack = nil
local bangEnabled = false
local headSitConn = nil
local jerkToolRef = nil
_G.jerkEnabled = false

-- Server
local antiAFKEnabled_IY = false
local antiAFKConn_IY = nil
local antiLagEnabled = false
local origDescendantSettings = {}
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
    _G.jerkEnabled = state
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
_G.toggleJerk = toggleJerk

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
                if v:IsA("BasePart") then
                    origDescendantSettings[v] = { CastShadow = v.CastShadow, Material = v.Material, Reflectance = v.Reflectance }
                    v.CastShadow = false; v.Material = Enum.Material.Plastic; v.Reflectance = 0
                elseif v:IsA("Decal") then
                    origDescendantSettings[v] = { Transparency = v.Transparency, Texture = v.Texture }
                    v.Transparency = 1; v.Texture = ""
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    origDescendantSettings[v] = { Lifetime = v.Lifetime }
                    v.Lifetime = NumberRange.new(0)
                end
            end)
        end
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") then
                origDescendantSettings[v] = { Enabled = v.Enabled }
                v.Enabled = false
            end
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
        for v, saved in pairs(origDescendantSettings) do
            pcall(function()
                if v:IsA("BasePart") then
                    v.CastShadow = saved.CastShadow; v.Material = saved.Material; v.Reflectance = saved.Reflectance
                elseif v:IsA("Decal") then
                    v.Transparency = saved.Transparency; v.Texture = saved.Texture
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = saved.Lifetime
                elseif v:IsA("PostEffect") then
                    v.Enabled = saved.Enabled
                end
            end)
        end
        origDescendantSettings = {}
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
--  Fling Script Feature Implementations
--  (Synced with FlingScriptUN.3 reference)
-- ============================================================

local touchFlingEnabled = false
local antiFlingEnabled = false; local antiFlingConnections = {}
local antiKillPartsEnabled = false; local antiKillPartsLoop = nil
local strengthEnabled = false; local strengthConns = {}; local origPhysProps = {}
local spActive = false; local spSavedPos = nil; local spCharConn = nil; local spDeathConn = nil
local antiSlapEnabled = false
local xenoAntiFlingEnabled = false; local xenoAntiFlingConn = nil
local infinitePosEnabled = false; local infPosSaved = nil; local infPosConn = nil; local infPosCharConn = nil
local afdEnabled = false; local afdConns = {}
local antiSitEnabled = false; local antiSitCharConn = nil
local antiRagdollEnabled = false; local antiRagdollDisconn = nil

local function setupTouchFling(state)
    touchFlingEnabled = state
    if not state then return end
    task.spawn(function()
        while touchFlingEnabled do
            RunService.Heartbeat:Wait()
            local hrp = root()
            if hrp then
                local vel = hrp.Velocity
                hrp.Velocity = vel * 1e35 + Vector3.new(0, 1e35, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, 0.1, 0)
            end
        end
    end)
end

local function setModelCanCollide(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = bval end
    end
end

local function setupAntiFling(state)
    antiFlingEnabled = state
    for _, conn in ipairs(antiFlingConnections) do conn:Disconnect() end
    antiFlingConnections = {}
    if not state then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then setModelCanCollide(p.Character, true) end
        end
        return
    end
    local function monitor(p)
        table.insert(antiFlingConnections, RunService.Stepped:Connect(function()
            if antiFlingEnabled and p.Character then setModelCanCollide(p.Character, false) end
        end))
    end
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then monitor(p) end end
    table.insert(antiFlingConnections, Players.PlayerAdded:Connect(function(plr)
        table.insert(antiFlingConnections, RunService.Stepped:Connect(function()
            if antiFlingEnabled and plr.Character then setModelCanCollide(plr.Character, false) end
        end))
    end))
end

local function setupAntiKillParts(state)
    antiKillPartsEnabled = state
    if antiKillPartsLoop then antiKillPartsLoop:Disconnect(); antiKillPartsLoop = nil end
    if not state then return end
    antiKillPartsLoop = RunService.Heartbeat:Connect(function()
        if not antiKillPartsEnabled then return end
        local hrp = root()
        if hrp then
            for _, part in ipairs(workspace:GetPartBoundsInRadius(hrp.Position, 10)) do
                part.CanTouch = false
            end
        end
    end)
end

local function cleanupStrength()
    for _, conn in ipairs(strengthConns) do conn:Disconnect() end; strengthConns = {}
    for part, props in pairs(origPhysProps) do
        if part:IsA("BasePart") and part.Parent then part.CustomPhysicalProperties = props end
    end; origPhysProps = {}
end

local function setupStrength(state)
    strengthEnabled = state
    cleanupStrength()
    if not state then return end
    local c = chr()
    if not c then return end
    for _, part in pairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            origPhysProps[part] = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5)
            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            table.insert(strengthConns, part:GetPropertyChangedSignal("CustomPhysicalProperties"):Connect(function()
                if strengthEnabled and (not part.CustomPhysicalProperties or part.CustomPhysicalProperties.Density < 100) then
                    part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                end
            end))
        end
    end
end

local function spSetupConns()
    if spCharConn then spCharConn:Disconnect(); spCharConn = nil end
    if spDeathConn then spDeathConn:Disconnect(); spDeathConn = nil end
    if not spActive then return end
    spCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if not spActive then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 1)
        if hrp and spSavedPos then task.wait(0.01); hrp.CFrame = spSavedPos end
    end)
    spDeathConn = RunService.Stepped:Connect(function()
        local c = chr(); if not c then return end
        local h = hum(); local hrp = root()
        if spActive and h and h.Health <= 0 and hrp then spSavedPos = hrp.CFrame end
    end)
end

local function setupSpawnpoint(state)
    spActive = state
    if state then
        local hrp = root(); if hrp then spSavedPos = hrp.CFrame end
        spSetupConns()
    else
        spSavedPos = nil
        if spCharConn then spCharConn:Disconnect(); spCharConn = nil end
        if spDeathConn then spDeathConn:Disconnect(); spDeathConn = nil end
    end
end

local function dobv(v, char)
    if not antiSlapEnabled then return end
    local undo = false
    if v:IsA("BodyAngularVelocity") then undo = true; v:Destroy()
    elseif v:IsA("BodyGyro") and v.MaxTorque ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.D ~= 500 and v.D ~= 50 and v.P ~= 90000 then undo = true; v:Destroy()
    elseif v:IsA("BodyVelocity") and v.MaxForce ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.Velocity ~= Vector3.new(0,0,0) then undo = true; v:Destroy()
    elseif v:IsA("BasePart") then v.ChildAdded:Connect(function(v2) dobv(v2, char) end)
    end
    if undo and char and char:FindFirstChild("Humanoid") then char.Humanoid.Sit = false; char.Humanoid.PlatformStand = false end
end

local function dc(char)
    if not antiSlapEnabled then return end
    for _, v in pairs(char:GetChildren()) do
        dobv(v, char)
        for _, v2 in pairs(v:GetChildren()) do dobv(v2, char) end
    end
    char.ChildAdded:Connect(function(v) dobv(v, char) end)
end

local function setupAntiSlap(state)
    antiSlapEnabled = state
    local c = chr()
    if c and state then dc(c) end
end

LocalPlayer.CharacterAdded:Connect(function(c)
    if antiSlapEnabled then dc(c) end
end)

local function setupXenoAntiFling(state)
    xenoAntiFlingEnabled = state
    if xenoAntiFlingConn then xenoAntiFlingConn:Disconnect(); xenoAntiFlingConn = nil end
    if not state then return end
    xenoAntiFlingConn = RunService.Stepped:Connect(function()
        pcall(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, v in pairs(p.Character:GetChildren()) do
                        pcall(function()
                            if v:IsA("BasePart") then
                                v.CanCollide = false; v.Velocity = Vector3.zero; v.RotVelocity = Vector3.zero
                                v.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0); v.Massless = true
                            elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
                                v.Handle.CanCollide = false; v.Handle.Velocity = Vector3.zero; v.Handle.RotVelocity = Vector3.zero
                                v.Handle.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0); v.Handle.Massless = true
                            end
                        end)
                    end
                end
            end
        end)
    end)
end

local function setupInfinitePosition(state)
    infinitePosEnabled = state
    if infPosConn then infPosConn:Disconnect(); infPosConn = nil end
    if infPosCharConn then infPosCharConn:Disconnect(); infPosCharConn = nil end
    if not state then infPosSaved = nil; return end
    local hrp = root(); if hrp then infPosSaved = hrp.CFrame end
    infPosConn = RunService.Heartbeat:Connect(function()
        if not infinitePosEnabled or not infPosSaved then return end
        local c = chr()
        if c then
            local r = root()
            if r and (r.Position - infPosSaved.Position).Magnitude > 0.1 then
                r.CFrame = infPosSaved; r.Velocity = Vector3.zero; r.RotVelocity = Vector3.zero
            end
        end
    end)
    infPosCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if not infinitePosEnabled then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 1)
        if hrp and infPosSaved then task.wait(0.0001); hrp.CFrame = infPosSaved end
    end)
end

local function setupAntiFallDamage(state)
    afdEnabled = state
    for _, conn in ipairs(afdConns) do conn:Disconnect() end; afdConns = {}
    if not state then return end
    local function setup(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 1)
        if not hrp then return end
        local conn = RunService.Heartbeat:Connect(function()
            if not hrp.Parent then conn:Disconnect(); return end
            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.zero
            RunService.RenderStepped:Wait()
            hrp.AssemblyLinearVelocity = vel
        end)
        table.insert(afdConns, conn)
    end
    if chr() then setup(chr()) end
    table.insert(afdConns, LocalPlayer.CharacterAdded:Connect(setup))
end

local function setupAntiSit(state)
    antiSitEnabled = state
    local h = hum()
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.Seated, not state)
        if state then h.Sit = false end
    end
    if antiSitCharConn then antiSitCharConn:Disconnect(); antiSitCharConn = nil end
    if state then
        antiSitCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
            if not antiSitEnabled then return end
            local h2 = char:WaitForChildOfClass("Humanoid")
            h2:SetStateEnabled(Enum.HumanoidStateType.Seated, false); h2.Sit = false
        end)
    end
end

local function setupAntiRagdoll(state)
    antiRagdollEnabled = state
    if antiRagdollDisconn then antiRagdollDisconn(); antiRagdollDisconn = nil end
    if not state then return end
    local function setup(char)
        local h = char:WaitForChild("Humanoid")
        h.PlatformStand = false
        local conns = {}
        table.insert(conns, h.StateChanged:Connect(function(_, s)
            if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end))
        table.insert(conns, h:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if h.PlatformStand then h.PlatformStand = false end
        end))
        antiRagdollDisconn = function() for _, c in ipairs(conns) do c:Disconnect() end end
    end
    if chr() then setup(chr()) end
    LocalPlayer.CharacterAdded:Connect(function()
        if antiRagdollEnabled then setup(LocalPlayer.Character) end
    end)
end

-- ============================================================
--  Invisibility Feature Implementation
--  (Synced with advanced_invis.lua reference)
-- ============================================================

local invisActive = false
local invisParts = {}
local invisConn = nil
local invisCharConn = nil
local invisToolConn = nil

local function setupInvisParts()
    invisParts = {}
    local c = chr()
    if c then
        for _, v in pairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then table.insert(invisParts, v) end
        end
        if invisToolConn then invisToolConn:Disconnect() end
        invisToolConn = c.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisParts, v)
                if invisActive then v.Transparency = 0.5 end
            end
        end)
    end
end

local function setInvisPartsTransparency(state)
    if state then
        for _, v in pairs(invisParts) do
            if v.Parent then v.Transparency = 0.5 end
        end
    else
        for _, v in pairs(invisParts) do
            if v.Parent then v.Transparency = 0 end
        end
        local c = chr()
        if c then
            for _, v in pairs(c:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then
                    v.Transparency = 0
                end
            end
        end
    end
end

local function startInvisLoop()
    if invisConn then invisConn:Disconnect() end
    invisConn = RunService.Heartbeat:Connect(function()
        if not invisActive then return end
        local c = chr()
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not h or h.Health <= 0 then return end
        local savedCF = hrp.CFrame
        local savedOffset = h.CameraOffset
        local below = savedCF * CFrame.new(0, -200000, 0)
        local camOffset = below:ToObjectSpace(CFrame.new(savedCF.Position)).Position
        hrp.CFrame = below
        h.CameraOffset = camOffset
        RunService.RenderStepped:Wait()
        if hrp and h and hrp.Parent and h.Health > 0 then
            hrp.CFrame = savedCF
            h.CameraOffset = savedOffset
        end
    end)
end

local function stopInvisLoop()
    if invisConn then invisConn:Disconnect(); invisConn = nil end
end

local autoReEnableInvis = false

invisCharConn = LocalPlayer.CharacterAdded:Connect(function()
    autoReEnableInvis = invisActive
    invisActive = false
    stopInvisLoop()
    task.wait(0.5)
    setupInvisParts()
    if autoReEnableInvis then
        invisActive = true
        startInvisLoop()
        setInvisPartsTransparency(true)
    end
end)

-- ============================================================
--  Build UI — Collapsible Sections
-- ============================================================

local tab = _G.UNScripts:CreateTab("Extras")

-- Aim Assist
local aa = tab:CreateSection("Aim Assist")
aa:CreateToggle("Aim Assist", function(state) aimAssistEnabled = state end)
aa:CreateToggle("Wall Check", function(state) wallCheckEnabled = state end)
aa:CreateSlider("Aim Smoothness", 1, 100, 15, function(v) aimSmoothness = v / 100 end)

-- Visual
local vis = tab:CreateSection("Visual")
vis:CreateToggle("Anti Lag", toggleAntiLag)
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
srv:CreateToggle("Anti-Afk", toggleAntiAFK_IY)
srv:CreateButton("Respawn", function()
    pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
end)

-- Character
local char = tab:CreateSection("Fun Stuff")
char:CreateToggle("Bang", toggleBang)
char:CreateToggle("Jerk", toggleJerk)
char:CreateToggle("Headsit", function(s)
    local plrs = getAllPlayers()
    toggleHeadsit(plrs, s)
end)

-- Fling Script
local flingSec = tab:CreateSection("Fling Script")
flingSec:CreatePageButton("Fling Script", "Fling Script", function(api)

    -- Input & Fling
    local inputFling = api:CreateSection("Input & Fling")
    inputFling:CreateToggle("Touch Fling", function(state)
        setupTouchFling(state)
    end)
    inputFling:CreateToggle("Anti Fling", function(state)
        setupAntiFling(state)
    end)
    inputFling:CreateToggle("Anti Kill Parts", function(state)
        setupAntiKillParts(state)
    end)

    -- Defense
    local defense = api:CreateSection("Defense")
    defense:CreateToggle("Strength", function(state)
        setupStrength(state)
    end)
    defense:CreateToggle("Spawnpoint", function(state)
        setupSpawnpoint(state)
    end)
    defense:CreateToggle("Anti Slap", function(state)
        setupAntiSlap(state)
    end)
    defense:CreateToggle("Xeno AntiFling", function(state)
        setupXenoAntiFling(state)
    end)
    defense:CreateToggle("Infinite Position", function(state)
        setupInfinitePosition(state)
    end)
    defense:CreateToggle("Anti Fall Damage", function(state)
        setupAntiFallDamage(state)
    end)

    -- Utility
    local utility = api:CreateSection("Utility")
    utility:CreateToggle("Anti Sit", function(state)
        setupAntiSit(state)
    end)
    utility:CreateToggle("Anti Ragdoll", function(state)
        setupAntiRagdoll(state)
    end)
end)

-- Invisibility
local invisSec = tab:CreateSection("Invisibility")
invisSec:CreateToggle("Invisible", function(state)
    invisActive = state
    if state then
        setupInvisParts()
        startInvisLoop()
        setInvisPartsTransparency(true)
    else
        stopInvisLoop()
        setInvisPartsTransparency(false)
        autoReEnableInvis = false
    end
end)

-- ============================================================
--  Keybind Registrations
-- ============================================================
if _G.UNS_AddScriptShortcut then
    _G.UNS_AddScriptShortcut("Aim Assist", function()
        local new = not aimAssistEnabled; aimAssistEnabled = new
        if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel("Aim Assist", new) end
    end)
    _G.UNS_AddScriptShortcut("Invisible", function()
        local new = not invisActive
        invisActive = new
        if new then
            setupInvisParts()
            startInvisLoop()
            setInvisPartsTransparency(true)
        else
            stopInvisLoop()
            setInvisPartsTransparency(false)
        end
        if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel("Invisible", new) end
    end)
end

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
    toggleBang(false); toggleJerk(false)
    toggleHeadsit({}, false)

    toggleAntiAFK_IY(false)
    if antiLagEnabled then toggleAntiLag(false) end

    touchFlingEnabled = false
    setupAntiFling(false)
    if antiKillPartsLoop then antiKillPartsLoop:Disconnect(); antiKillPartsLoop = nil end
    setupStrength(false)
    setupSpawnpoint(false)
    setupAntiSlap(false)
    setupXenoAntiFling(false)
    if infPosConn then infPosConn:Disconnect(); infPosConn = nil end
    if infPosCharConn then infPosCharConn:Disconnect(); infPosCharConn = nil end
    setupAntiFallDamage(false)
    setupAntiSit(false)
    if antiRagdollDisconn then antiRagdollDisconn(); antiRagdollDisconn = nil end
    local h = hum()
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        h.BreakJointsOnDeath = true
    end

    pcall(function()
        local sg = StarterGui:FindFirstChild("UNS_4K_Shader")
        if sg then sg:Destroy() end
    end)
end
_G.UNS_CombinedCleanupP2 = combinedCleanupP2
table.insert(_G.UNS_CleanupList, combinedCleanupP2)

print("[Combined Plugin P2] Features organized under dropdown sections + Fling Script page")
