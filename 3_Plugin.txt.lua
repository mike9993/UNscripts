-- ============================================================
--  UNScripts Combined Plugin — All Features in One Tab
--  Merged from Scripts (2) and IY (5) with _s / _IY suffixes
--  Run AFTER UNScripts_Host_UI loads.
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local function waitForHost()
    for _ = 1, 100 do
        if _G.UNScripts and type(_G.UNScripts.CreateTab) == "function" then return true end
        task.wait(0.5)
    end
    return false
end

if not waitForHost() then
    warn("[Combined Plugin] Host UI not found")
    return
end

-- Cleanup previous instance
if type(_G.UNS_CombinedCleanup) == "function" then _G.UNS_CombinedCleanup() end

-- ============================================================
--  State Variables
-- ============================================================

-- Script 2 (Scripts tab) state
local infJumpEnabled = false
local clickTPEnabled = false

local f3xEnabled = false
local tptoolActive = false

-- IY state
local noclipEnabled = false
local noclipConn = nil
local flyEnabled = false
local flyKeySpeed = 16
local vflyMultiplier = 50
local vflyFlag = false
local floatEnabled = false
local floatPart = nil
local floatConn = nil
local floatValue = -3.1

local ESP_Settings = {
    Enabled = false,
    TeamCheck = false,
    Highlight = true,
    ThroughWalls = true,
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    UseMaxDistance = false,
    MaxDistance = 1500,
    FillTransparency = 0.74,
    Color = Color3.fromRGB(255, 0, 0),
}
local ESP_ColorState = { H = 0, S = 1, V = 1 }

-- Walk Speed state
local wsCfg = {
    enabled = false, preToggleSpeed = 16, currentSpeed = 16, gameDefaultSpeed = 16,
    speedIncrement = 2, maxSpeedLimit = 100, extremeSpeed = false,
    instantStop = false, cframeBypass = false,
    minSpeed = 0,
}
local wsRun = true
local wsHoldingUp = false
local wsHoldingDown = false
local wsLastUpTime = 0
local wsLastDownTime = 0
local WS_HOLD_RATE = 0.12
local wsSliderUpdater = nil

local ESP_SAVE_FILE = "UNScripts/esp_settings.json"
local ESP_SAVE_VERSION = 2

local function saveESPSettings()
    local data = {
        _version = ESP_SAVE_VERSION,
        ShowName = ESP_Settings.ShowName,
        ShowHealth = ESP_Settings.ShowHealth,
        ShowDistance = ESP_Settings.ShowDistance,
        Highlight = ESP_Settings.Highlight,
        TeamCheck = ESP_Settings.TeamCheck,
        ThroughWalls = ESP_Settings.ThroughWalls,
        UseMaxDistance = ESP_Settings.UseMaxDistance,
        MaxDistance = ESP_Settings.MaxDistance,
        FillTransparency = ESP_Settings.FillTransparency,
        ColorR = ESP_Settings.Color.R,
        ColorG = ESP_Settings.Color.G,
        ColorB = ESP_Settings.Color.B,
        H = ESP_ColorState.H,
        S = ESP_ColorState.S,
        V = ESP_ColorState.V,
    }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        pcall(function()
            if isfolder and not isfolder("UNScripts") then makefolder("UNScripts") end
            writefile(ESP_SAVE_FILE, encoded)
        end)
    end
end

local function loadESPSettings()
    local ok, exists = pcall(isfile, ESP_SAVE_FILE)
    if not ok or not exists then return end
    local readOk, content = pcall(readfile, ESP_SAVE_FILE)
    if not readOk or content == "" then return end
    local success, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not success or type(data) ~= "table" then return end
    if data._version ~= ESP_SAVE_VERSION then return end
    ESP_Settings.ShowName = data.ShowName == true
    ESP_Settings.ShowHealth = data.ShowHealth == true
    ESP_Settings.ShowDistance = data.ShowDistance == true
    if data.Highlight ~= nil then ESP_Settings.Highlight = data.Highlight end
    if data.TeamCheck ~= nil then ESP_Settings.TeamCheck = data.TeamCheck end
    if data.ThroughWalls ~= nil then ESP_Settings.ThroughWalls = data.ThroughWalls end
    ESP_Settings.UseMaxDistance = data.UseMaxDistance == true
    if data.MaxDistance then ESP_Settings.MaxDistance = data.MaxDistance end
    if data.FillTransparency then ESP_Settings.FillTransparency = data.FillTransparency end
    if data.ColorR then ESP_Settings.Color = Color3.new(data.ColorR, data.ColorG, data.ColorB) end
    if data.H then ESP_ColorState.H = data.H end
    if data.S then ESP_ColorState.S = data.S end
    if data.V then ESP_ColorState.V = data.V end
end

loadESPSettings()

local espObjects = {}
local espLoopConn = nil
local espPlayerAddedConn = nil
local espCharAddedConns = {}
local espPlayerRemovingConn = nil

-- IY state (continued)




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
--  Script 2 Features (suffixed _s where conflicting)
-- ============================================================

-- Click Teleport
local clickTPConn = nil
local function toggleClickTeleport(state)
    clickTPEnabled = state
end



-- F3X
local function clearF3XTools()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name:find("F3X") or t.Name:find("f3x") or t.Name:find("F3x") or t.Name:find("BTool") or t.Name:find("Btool")) then t:Destroy() end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and (t.Name:find("F3X") or t.Name:find("f3x") or t.Name:find("F3x") or t.Name:find("BTool") or t.Name:find("Btool")) then t:Destroy() end
        end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local f3xGui = pg:FindFirstChild("Building Tools by F3X (UI)")
        if f3xGui then f3xGui:Destroy() end
    end
end

local function injectF3X()
    clearF3XTools()
    local ok, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/mike9993/F3X/refs/heads/main/f3xv.lua.txt")
    end)
    if ok and result then
        _G.BTCoreEnv = nil
        pcall(function() loadstring(result)() end)
        task.spawn(function()
            task.wait(1)
            local t = LocalPlayer.Backpack:FindFirstChild("F3X")
            local char = LocalPlayer.Character
            if t and t:IsA("Tool") and char then
                t.Parent = char
            end
        end)
    end
end

_G.toggleF3X = function(state)
    f3xEnabled = state
    if state then injectF3X() else clearF3XTools() end
end

local function clearTPTool()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChild("TPTool")
        if t then t:Destroy() end
    end
    local char = LocalPlayer.Character
    if char then
        local t = char:FindFirstChild("TPTool")
        if t then t:Destroy() end
    end
end

local function injectTPTool()
    clearTPTool()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local t = Instance.new("Tool")
        t.Name = "TPTool"
        t.RequiresHandle = false
        t.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                c.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
            end
        end)
        t.Parent = bp
    end
end

-- ============================================================
--  IY Features
-- ============================================================

-- NOCLIP
local function toggleNoclip(state)
    noclipEnabled = state
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipEnabled then return end
            local c = chr()
            if c then
                for _, child in pairs(c:GetDescendants()) do
                    if child:IsA("BasePart") then child.CanCollide = false end
                end
            end
        end)
    end
end

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

-- FLY
local flyControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
local flyLControl = {F=0,B=0,L=0,R=0}
local flyBV = nil
local flyBG = nil
local flyKeyDown = nil
local flyKeyUp = nil

local function stopFly()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown = nil end
    if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp = nil end
    flyControl = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local h = hum()
    if h then h.PlatformStand = false end
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
end

local function startFly()
    task.spawn(function()
        task.wait(0.1)
        local r = root()
        local h = hum()
        if not r or not h then flyEnabled = false; return end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9,9e9,9e9); flyBV.Parent = r
        flyBG = Instance.new("BodyGyro")
        flyBG.P = 9e4; flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBG.Parent = r
        h.PlatformStand = true
        flyKeyDown = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == Enum.KeyCode.W then flyControl.F = flyKeySpeed
            elseif inp.KeyCode == Enum.KeyCode.S then flyControl.B = -flyKeySpeed
            elseif inp.KeyCode == Enum.KeyCode.A then flyControl.L = -flyKeySpeed
            elseif inp.KeyCode == Enum.KeyCode.D then flyControl.R = flyKeySpeed
            elseif inp.KeyCode == Enum.KeyCode.E then flyControl.Q = flyKeySpeed*2
            elseif inp.KeyCode == Enum.KeyCode.Q then flyControl.E = -flyKeySpeed*2 end
        end)
        flyKeyUp = UserInputService.InputEnded:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == Enum.KeyCode.W then flyControl.F = 0
            elseif inp.KeyCode == Enum.KeyCode.S then flyControl.B = 0
            elseif inp.KeyCode == Enum.KeyCode.A then flyControl.L = 0
            elseif inp.KeyCode == Enum.KeyCode.D then flyControl.R = 0
            elseif inp.KeyCode == Enum.KeyCode.E then flyControl.Q = 0
            elseif inp.KeyCode == Enum.KeyCode.Q then flyControl.E = 0 end
        end)
        task.spawn(function()
            while flyEnabled and flyBV and flyBG do
                local camCF = Camera.CFrame
                if flyControl.L+flyControl.R ~= 0 or flyControl.F+flyControl.B ~= 0 or flyControl.Q+flyControl.E ~= 0 then
                    flyBV.Velocity = ((camCF.LookVector * (flyControl.F + flyControl.B)) + ((camCF * CFrame.new(flyControl.L+flyControl.R, (flyControl.F+flyControl.B+flyControl.Q+flyControl.E)*0.2, 0).p) - camCF.p)) * vflyMultiplier
                    flyLControl = {F=flyControl.F, B=flyControl.B, L=flyControl.L, R=flyControl.R}
                elseif flyControl.L+flyControl.R == 0 and flyControl.F+flyControl.B == 0 and flyControl.Q+flyControl.E == 0 then
                    flyBV.Velocity = Vector3.new(0,0,0)
                else
                    flyBV.Velocity = ((camCF.LookVector * (flyLControl.F+flyLControl.B)) + ((camCF * CFrame.new(flyLControl.L+flyLControl.R, (flyControl.F+flyControl.B+flyControl.Q+flyControl.E)*0.2, 0).p) - camCF.p)) * vflyMultiplier
                end
                flyBG.CFrame = camCF
                task.wait()
            end
            flyControl = {F=0,B=0,L=0,R=0,Q=0,E=0}; flyLControl = {F=0,B=0,L=0,R=0}
        end)
    end)
end

local function toggleFly(state)
    flyEnabled = state
    if state then startFly() else stopFly() end
end

local function toggleVfly(state)
    if state then
        if not flyEnabled then
            vflyFlag = true; toggleFly(true)
        else
            vflyFlag = true
        end
    else
        vflyFlag = false
        if flyEnabled then toggleFly(false) end
    end
end



-- FLOAT
local floatInputConn = nil
local function toggleFloat(state)
    floatEnabled = state
    if not state then
        if floatConn then floatConn:Disconnect(); floatConn = nil end
        if floatPart then pcall(function() floatPart:Destroy() end); floatPart = nil end
        return
    end
    local c = chr()
    if not c then return end
    floatPart = Instance.new("Part")
    floatPart.Transparency = 1; floatPart.Size = Vector3.new(2,0.2,1.5); floatPart.Anchored = true; floatPart.Name = "UNS_FloatPart"
    floatPart.Parent = c
    floatValue = -3.1
    floatConn = RunService.Heartbeat:Connect(function()
        if floatPart and root() then
            floatPart.CFrame = root().CFrame * CFrame.new(0, floatValue, 0)
        end
    end)
end

-- ESP
local HIGHLIGHT_NAME = "UNS_ESP_HL"
local TAG_NAME = "UNS_ESP_BB"
local TEXT_NAME = "UNS_ESP_TXT"

local function isTeammate(p)
    return ESP_Settings.TeamCheck
        and LocalPlayer.Team ~= nil
        and p.Team == LocalPlayer.Team
end

local function clearESP()
    for p, data in pairs(espObjects) do
        pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
        pcall(function() if data.BB then data.BB:Destroy() end end)
    end
    espObjects = {}
end

local function removeESPFromChar(character)
    if not character then return end
    local hl = character:FindFirstChild(HIGHLIGHT_NAME)
    if hl then hl:Destroy() end
    local tag = character:FindFirstChild(TAG_NAME)
    if tag then tag:Destroy() end
end

local function ensureESP(character, root)
    local hl = character:FindFirstChild(HIGHLIGHT_NAME)
    if hl and not hl:IsA("Highlight") then hl:Destroy(); hl = nil end
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = HIGHLIGHT_NAME
        hl.Parent = character
    end
    local tag = character:FindFirstChild(TAG_NAME)
    if tag and not tag:IsA("BillboardGui") then tag:Destroy(); tag = nil end
    if not tag then
        tag = Instance.new("BillboardGui")
        tag.Name = TAG_NAME
        tag.Size = UDim2.fromOffset(220, 64)
        tag.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
        tag.LightInfluence = 0
        tag.Parent = character
    end
    local label = tag:FindFirstChild(TEXT_NAME)
    if label and not label:IsA("TextLabel") then label:Destroy(); label = nil end
    if not label then
        label = Instance.new("TextLabel")
        label.Name = TEXT_NAME
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.25
        label.Parent = tag
    end
    hl.Adornee = character
    tag.Adornee = root
    return hl, tag, label
end

local function updatePlayerESP(p)
    if p == LocalPlayer then return end
    local character = p.Character
    if not character or isTeammate(p) then
        removeESPFromChar(character)
        if espObjects[p] then
            pcall(function() if espObjects[p].Highlight then espObjects[p].Highlight:Destroy() end end)
            pcall(function() if espObjects[p].BB then espObjects[p].BB:Destroy() end end)
            espObjects[p] = nil
        end
        return
    end
    if not ESP_Settings.Enabled then
        if espObjects[p] then
            pcall(function() if espObjects[p].Highlight then espObjects[p].Highlight:Destroy() end end)
            pcall(function() if espObjects[p].BB then espObjects[p].BB:Destroy() end end)
            espObjects[p] = nil
        end
        removeESPFromChar(character)
        return
    end
    local r = getRoot(character) or character:FindFirstChild("HumanoidRootPart")
    if not r then
        r = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("LowerTorso")
    end
    local localRoot = root()
    if not r or not localRoot then
        if espObjects[p] then
            espObjects[p] = nil
        end
        return
    end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        removeESPFromChar(character)
        if espObjects[p] then espObjects[p] = nil end
        return
    end
    local distance = (r.Position - localRoot.Position).Magnitude
    if ESP_Settings.UseMaxDistance and distance > ESP_Settings.MaxDistance then
        removeESPFromChar(character)
        if espObjects[p] then espObjects[p] = nil end
        return
    end
    local showLabels = ESP_Settings.ShowName or ESP_Settings.ShowHealth or ESP_Settings.ShowDistance
    if not ESP_Settings.Highlight and not showLabels then
        removeESPFromChar(character)
        if espObjects[p] then espObjects[p] = nil end
        return
    end
    local hl, tag, label = ensureESP(character, r)
    hl.Enabled = ESP_Settings.Highlight
    hl.FillColor = ESP_Settings.Color
    hl.OutlineColor = ESP_Settings.Color
    hl.FillTransparency = ESP_Settings.FillTransparency
    hl.OutlineTransparency = 0
    hl.DepthMode = ESP_Settings.ThroughWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
    tag.Enabled = showLabels
    tag.AlwaysOnTop = ESP_Settings.ThroughWalls
    label.TextColor3 = ESP_Settings.Color
    local lines = {}
    if ESP_Settings.ShowName then
        table.insert(lines, p.DisplayName ~= "" and p.DisplayName or p.Name)
    end
    if ESP_Settings.ShowHealth then
        table.insert(lines, string.format("%d / %d HP",
            math.floor(humanoid.Health + 0.5),
            math.floor(humanoid.MaxHealth + 0.5)))
    end
    if ESP_Settings.ShowDistance then
        table.insert(lines, string.format("%d studs", math.floor(distance + 0.5)))
    end
    label.Text = table.concat(lines, "\n")
    espObjects[p] = { Highlight = hl, BB = tag }
end

local function refreshAllESP()
    if not ESP_Settings.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        updatePlayerESP(p)
    end
end

local function setupESPCharAdded(p)
    if espCharAddedConns[p] then
        espCharAddedConns[p]:Disconnect()
        espCharAddedConns[p] = nil
    end
    espCharAddedConns[p] = p.CharacterAdded:Connect(function()
        task.spawn(function()
            if not ESP_Settings.Enabled then return end
            local char = p.Character
            if not char then return end
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if not hrp or not ESP_Settings.Enabled then return end
            if espObjects[p] then
                pcall(function() if espObjects[p].Highlight then espObjects[p].Highlight:Destroy() end end)
                pcall(function() if espObjects[p].BB then espObjects[p].BB:Destroy() end end)
                espObjects[p] = nil
            end
            task.wait(0.1)
            if ESP_Settings.Enabled then
                updatePlayerESP(p)
            end
        end)
    end)
end

local function startESPLoop()
    if espLoopConn then espLoopConn:Disconnect() end
    if espPlayerAddedConn then espPlayerAddedConn:Disconnect(); espPlayerAddedConn = nil end
    if espPlayerRemovingConn then espPlayerRemovingConn:Disconnect(); espPlayerRemovingConn = nil end
    for _, conn in pairs(espCharAddedConns) do
        pcall(function() conn:Disconnect() end)
    end
    espCharAddedConns = {}

    refreshAllESP()

    espPlayerAddedConn = Players.PlayerAdded:Connect(function(p)
        setupESPCharAdded(p)
        task.spawn(function()
            local char = p.Character or p.CharacterAdded:Wait()
            if not ESP_Settings.Enabled then return end
            task.wait(0.5)
            if ESP_Settings.Enabled then
                updatePlayerESP(p)
            end
        end)
    end)

    espPlayerRemovingConn = Players.PlayerRemoving:Connect(function(p)
        if espCharAddedConns[p] then
            espCharAddedConns[p]:Disconnect()
            espCharAddedConns[p] = nil
        end
        if espObjects[p] then
            espObjects[p] = nil
        end
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            setupESPCharAdded(p)
        end
    end

    espLoopConn = RunService.Heartbeat:Connect(function(dt)
        if not ESP_Settings.Enabled then return end
        pcall(refreshAllESP)
    end)
end

local function stopESPLoop()
    if espLoopConn then espLoopConn:Disconnect(); espLoopConn = nil end
    if espPlayerAddedConn then espPlayerAddedConn:Disconnect(); espPlayerAddedConn = nil end
    if espPlayerRemovingConn then espPlayerRemovingConn:Disconnect(); espPlayerRemovingConn = nil end
    for _, conn in pairs(espCharAddedConns) do
        pcall(function() conn:Disconnect() end)
    end
    espCharAddedConns = {}
    for _, p in ipairs(Players:GetPlayers()) do
        removeESPFromChar(p.Character)
    end
    clearESP()
end

-- ESP Settings Page
local function setupESPSettingsPage(page)
    local ot = _G.UNS_OriginalToggles
    if ot then
        for uid, data in pairs(ot) do
            local n = data.name
            if n == "Name ESP" or n == "Distance ESP" or n == "Health ESP" or n == "Highlight / Chams" or n == "Team Check" or n == "Through Walls" or n == "Use Max Distance" then
                ot[uid] = nil
            end
        end
    end

    local function trackedToggle(label, key)
        page:CreateToggle(label, function(s)
            ESP_Settings[key] = s
            if ESP_Settings.Enabled then refreshAllESP() end
            saveESPSettings()
        end, ESP_Settings[key])
    end

    trackedToggle("Name ESP", "ShowName")
    trackedToggle("Distance ESP", "ShowDistance")
    trackedToggle("Health ESP", "ShowHealth")
    trackedToggle("Highlight / Chams", "Highlight")
    trackedToggle("Team Check", "TeamCheck")
    trackedToggle("Through Walls", "ThroughWalls")

    page:CreateToggle("Use Max Distance", function(s)
        ESP_Settings.UseMaxDistance = s
        if ESP_Settings.Enabled then refreshAllESP() end
        saveESPSettings()
    end, ESP_Settings.UseMaxDistance)
    page:CreateSlider("Max Distance", 100, 5000, 1500, function(v)
        ESP_Settings.MaxDistance = v
        if ESP_Settings.Enabled then refreshAllESP() end
        saveESPSettings()
    end)
    page:CreateSlider("Fill Transparency", 0, 100, 74, function(v)
        ESP_Settings.FillTransparency = 1 - (v / 100)
        if ESP_Settings.Enabled then refreshAllESP() end
        saveESPSettings()
    end)

    page:CreateLabel("ESP Color")

    local S = 160
    local hueBarW = 18
    local previewS = 40
    local pad = 10
    local pickerH = S + pad * 2
    local parent = _G.UNS_PageScroll
    if not parent then return end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, pickerH + 30)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.LayoutOrder = 999
    container.Parent = parent

    local square = Instance.new("Frame")
    square.Size = UDim2.new(0, S, 0, S)
    square.Position = UDim2.new(0, pad, 0, pad + 4)
        square.BackgroundColor3 = Color3.fromHSV(ESP_ColorState.H / 360, 1, 1)
    square.BorderSizePixel = 0
    square.Parent = container
    local sqCorner = Instance.new("UICorner")
    sqCorner.CornerRadius = UDim.new(0, 4)
    sqCorner.Parent = square

    local satLayer = Instance.new("Frame")
    satLayer.Size = UDim2.new(1, 0, 1, 0)
    satLayer.BackgroundColor3 = Color3.new(1, 1, 1)
    satLayer.BorderSizePixel = 0
    satLayer.Parent = square
    local satGrad = Instance.new("UIGradient")
    satGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    satGrad.Rotation = 0
    satGrad.Parent = satLayer
    local sqCorner2 = Instance.new("UICorner")
    sqCorner2.CornerRadius = UDim.new(0, 4)
    sqCorner2.Parent = satLayer

    local valLayer = Instance.new("Frame")
    valLayer.Size = UDim2.new(1, 0, 1, 0)
    valLayer.BackgroundColor3 = Color3.new(0, 0, 0)
    valLayer.BorderSizePixel = 0
    valLayer.Parent = square
    local valGrad = Instance.new("UIGradient")
    valGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    valGrad.Rotation = 90
    valGrad.Parent = valLayer
    local sqCorner3 = Instance.new("UICorner")
    sqCorner3.CornerRadius = UDim.new(0, 4)
    sqCorner3.Parent = valLayer

    local sqCursor = Instance.new("Frame")
    sqCursor.Size = UDim2.new(0, 8, 0, 8)
    sqCursor.BackgroundTransparency = 1
    sqCursor.BorderSizePixel = 0
    sqCursor.ZIndex = 5
    sqCursor.Parent = square
    local sqCursorStroke = Instance.new("UIStroke")
    sqCursorStroke.Color = Color3.new(1, 1, 1)
    sqCursorStroke.Thickness = 2
    sqCursorStroke.Parent = sqCursor
    local sqCursorCorner = Instance.new("UICorner")
    sqCursorCorner.CornerRadius = UDim.new(1, 0)
    sqCursorCorner.Parent = sqCursor
    local function updateSqCursor()
        local sx = ESP_ColorState.S * S
        local sy = (1 - ESP_ColorState.V) * S
        sqCursor.Position = UDim2.new(0, sx - 4, 0, sy - 4)
    end
    updateSqCursor()

    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(0, hueBarW, 0, S)
    hueBar.Position = UDim2.new(0, pad + S + pad, 0, pad + 4)
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = container
    local hbCorner = Instance.new("UICorner")
    hbCorner.CornerRadius = UDim.new(0, 4)
    hbCorner.Parent = hueBar
    local hbGrad = Instance.new("UIGradient")
    hbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    hbGrad.Rotation = 90
    hbGrad.Parent = hueBar

    local hCursor = Instance.new("Frame")
    hCursor.Size = UDim2.new(1, 6, 0, 4)
    hCursor.Position = UDim2.new(0, -3, 0, -2)
    hCursor.BackgroundTransparency = 1
    hCursor.BorderSizePixel = 0
    hCursor.ZIndex = 5
    hCursor.Parent = hueBar
    local hCursorStroke = Instance.new("UIStroke")
    hCursorStroke.Color = Color3.new(1, 1, 1)
    hCursorStroke.Thickness = 2
    hCursorStroke.Parent = hCursor
    local hCursorCorner = Instance.new("UICorner")
    hCursorCorner.CornerRadius = UDim.new(1, 0)
    hCursorCorner.Parent = hCursor
    local function updateHCursor()
        local hy = (ESP_ColorState.H / 360) * S
        hCursor.Position = UDim2.new(0, -3, 0, hy - 2)
    end
    updateHCursor()

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, previewS, 0, previewS)
    preview.Position = UDim2.new(0, pad + S + pad + hueBarW + pad, 0, pad + 4)
    preview.BackgroundColor3 = ESP_Settings.Color
    preview.BorderSizePixel = 0
    preview.Parent = container
    local prevCorner = Instance.new("UICorner")
    prevCorner.CornerRadius = UDim.new(0, 6)
    prevCorner.Parent = preview

    local hexLabel = Instance.new("TextLabel")
    hexLabel.Size = UDim2.new(0, previewS, 0, 18)
    hexLabel.Position = UDim2.new(0, pad + S + pad + hueBarW + pad, 0, pad + 4 + previewS + 4)
    hexLabel.BackgroundTransparency = 1
    hexLabel.Text = "#FF0000"
    hexLabel.TextColor3 = Color3.fromRGB(218, 218, 222)
    hexLabel.TextSize = 11
    hexLabel.Font = Enum.Font.GothamBold
    hexLabel.TextXAlignment = Enum.TextXAlignment.Center
    hexLabel.Parent = container

    local function setESPColor()
        ESP_Settings.Color = Color3.fromHSV(ESP_ColorState.H / 360, ESP_ColorState.S, ESP_ColorState.V)
        preview.BackgroundColor3 = ESP_Settings.Color
        local r = math.floor(ESP_Settings.Color.R * 255 + 0.5)
        local g = math.floor(ESP_Settings.Color.G * 255 + 0.5)
        local b = math.floor(ESP_Settings.Color.B * 255 + 0.5)
        hexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
        if ESP_Settings.Enabled then refreshAllESP() end
    end

    local function sqInput(x, y)
        local absPos = square.AbsolutePosition
        local absSize = square.AbsoluteSize
        local lx = math.clamp((x - absPos.X) / absSize.X, 0, 1)
        local ly = math.clamp((y - absPos.Y) / absSize.Y, 0, 1)
        ESP_ColorState.S = lx
        ESP_ColorState.V = 1 - ly
        updateSqCursor()
        setESPColor()
    end

    local sqDrag = false
    local sqHit = Instance.new("TextButton")
    sqHit.Size = UDim2.new(1, 0, 1, 0)
    sqHit.BackgroundTransparency = 1
    sqHit.Text = ""
    sqHit.ZIndex = 10
    sqHit.Parent = square
    sqHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sqDrag = true
            sqInput(i.Position.X, i.Position.Y)
        end
    end)
    local sqMoveConn = UserInputService.InputChanged:Connect(function(i)
        if sqDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            sqInput(i.Position.X, i.Position.Y)
        end
    end)
    local sqEndConn = UserInputService.InputEnded:Connect(function(i)
        if sqDrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            sqDrag = false
            saveESPSettings()
        end
    end)
    container.Destroying:Connect(function()
        sqMoveConn:Disconnect()
        sqEndConn:Disconnect()
    end)

    local function hbInput(x, y)
        local absPos = hueBar.AbsolutePosition
        local absSize = hueBar.AbsoluteSize
        local ly = math.clamp((y - absPos.Y) / absSize.Y, 0, 1)
        ESP_ColorState.H = ly * 360
    square.BackgroundColor3 = Color3.fromHSV(ESP_ColorState.H / 360, 1, 1)
        updateHCursor()
        setESPColor()
    end

    local hbDrag = false
    local hbHit = Instance.new("TextButton")
    hbHit.Size = UDim2.new(1, 0, 1, 0)
    hbHit.BackgroundTransparency = 1
    hbHit.Text = ""
    hbHit.ZIndex = 10
    hbHit.Parent = hueBar
    hbHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hbDrag = true
            hbInput(i.Position.X, i.Position.Y)
        end
    end)
    local hbMoveConn = UserInputService.InputChanged:Connect(function(i)
        if hbDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            hbInput(i.Position.X, i.Position.Y)
        end
    end)
    local hbEndConn = UserInputService.InputEnded:Connect(function(i)
        if hbDrag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            hbDrag = false
            saveESPSettings()
        end
    end)
    container.Destroying:Connect(function()
        hbMoveConn:Disconnect()
        hbEndConn:Disconnect()
    end)
end

-- ============================================================
--  Core Loops
-- ============================================================

-- Infinite Jump
jumpRequestConn = UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        pcall(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

-- Click Teleport
clickTPConn = UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if clickTPEnabled and inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouseLoc = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        if result then
            pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 5, 0)) end)
        end
    end
end)


-- Float controls
floatInputConn = UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if floatEnabled and inp.KeyCode == Enum.KeyCode.Q then floatValue = floatValue - 0.5 end
    if floatEnabled and inp.KeyCode == Enum.KeyCode.E then floatValue = floatValue + 1.5 end
end)

-- ============================================================
--  Respawn Handlers (merged)
-- ============================================================
local function setupToolWatchers()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local function onToolRemoved(toolName, toggleLabel)
        task.wait(0.5)
        if not _G.UNScripts or _G.UNScripts.SaveInventory then return end
        local bp2 = LocalPlayer:FindFirstChild("Backpack")
        local char2 = LocalPlayer.Character
        local stillExists = (bp2 and bp2:FindFirstChild(toolName)) or (char2 and char2:FindFirstChild(toolName))
        if not stillExists and _G.UNScripts.GetToggleState and _G.UNScripts.GetToggleState(toggleLabel) then
            if _G.UNScripts.SetToggleByLabel then
                _G.UNScripts.SetToggleByLabel(toggleLabel, false)
            end
        end
    end
    if bp then
        bp.ChildRemoved:Connect(function(child)
            if child.Name == "F3X" or child.Name:find("F3X") or child.Name:find("f3x") then
                onToolRemoved("F3X", "F3X")
            end
            if child.Name == "TPTool" then
                onToolRemoved("TPTool", "TPTool")
            end
            if child.Name == "Jerk Off" then
                onToolRemoved("Jerk Off", "Jerk")
            end
        end)
    end
    if char then
        char.ChildRemoved:Connect(function(child)
            if child.Name == "F3X" or child.Name:find("F3X") or child.Name:find("f3x") then
                onToolRemoved("F3X", "F3X")
            end
            if child.Name == "TPTool" then
                onToolRemoved("TPTool", "TPTool")
            end
            if child.Name == "Jerk Off" then
                onToolRemoved("Jerk Off", "Jerk")
            end
        end)
    end
end

local function setupRespawnHandlers()
    if _G.UNS_RespawnConnection then _G.UNS_RespawnConnection:Disconnect(); _G.UNS_RespawnConnection = nil end
    _G.UNS_RespawnConnection = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        local bp = LocalPlayer:WaitForChild("Backpack")
        task.wait(0.5)
        setupToolWatchers()
        if _G.UNScripts and _G.UNScripts.SaveInventory then
            if f3xEnabled then injectF3X() end
            if tptoolActive then injectTPTool() end
            if _G.jerkEnabled and _G.toggleJerk then _G.toggleJerk(true) end
        else
            if _G.UNScripts and _G.UNScripts.GetToggleState and _G.UNScripts.GetToggleState("F3X") then
                _G.UNScripts.SetToggleByLabel("F3X", false)
            end
            if _G.UNScripts and _G.UNScripts.GetToggleState and _G.UNScripts.GetToggleState("TPTool") then
                _G.UNScripts.SetToggleByLabel("TPTool", false)
            end
            if _G.UNScripts and _G.UNScripts.GetToggleState and _G.UNScripts.GetToggleState("Jerk") then
                _G.UNScripts.SetToggleByLabel("Jerk", false)
            end
        end
    end)
end
setupToolWatchers()
setupRespawnHandlers()

-- ============================================================
--  Build UI — Single Tab with All Sections
-- ============================================================

local tab = _G.UNScripts:CreateTab("Main")
local tpWaypoints = {}
local tpPlayerConns = {}
local antiFlingEnabled = false
local antiFlingConn = nil

-- Movement
local mov = tab:CreateSection("Movement")
mov:CreateToggle("Noclip", toggleNoclip)
mov:CreateToggle("Float", toggleFloat)
mov:CreateToggle("Anti-Fling", toggleAntiFling)
mov:CreateSlider("WalkSpeed", 16, 500, 16, function(v)
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = v end)
end)
mov:CreateSlider("JumpPower", 50, 500, 50, function(v)
    pcall(function() local h = LocalPlayer.Character.Humanoid; h.UseJumpPower = true; h.JumpPower = v end)
end)
mov:CreateToggle("Vfly", toggleVfly)
mov:CreateSlider("Fly Speed", 1, 150, 50, function(v)
    vflyMultiplier = v
end)
mov:CreateButton("Infinite Jump", function()
    pcall(function()
        loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Infinite%20Jump.lua"))()
    end)
end)

-- Teleport
local tel = tab:CreateSection("Teleport")
tel:CreateToggle("TPTool", function(state)
    tptoolActive = state
    if state then injectTPTool() else clearTPTool() end
end)
tel:CreateToggle("Click Teleport", toggleClickTeleport)
tel:CreatePageButton("Teleport Menu", "Teleport", function(page)
    for _, conn in ipairs(tpPlayerConns) do
        pcall(function() conn:Disconnect() end)
    end
    tpPlayerConns = {}

    local C = {
        surfaceAlt = Color3.fromRGB(40, 40, 40),
        border = Color3.fromRGB(45, 45, 52),
        accent = Color3.fromRGB(50, 120, 255),
        textPri = Color3.fromRGB(218, 218, 222),
        textSec = Color3.fromRGB(115, 115, 128),
    }

    local function makePill(parent, text, lo)
        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(1, -8, 0, 32)
        pill.BackgroundColor3 = C.surfaceAlt
        pill.BackgroundTransparency = 0.1
        pill.BorderSizePixel = 0
        pill.LayoutOrder = lo
        pill.Parent = parent
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke")
        stroke.Color = C.border; stroke.Thickness = 1; stroke.Transparency = 0.4
        stroke.Parent = pill
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 120, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = text
        lbl.TextColor3 = C.textPri; lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = pill
        return pill
    end

    local function addBtn(pill, cb, txt)
        txt = txt or "TP"
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 70, 0, 22)
        btn.Position = UDim2.new(1, -80, 0.5, -11)
        btn.BackgroundColor3 = C.accent; btn.BackgroundTransparency = 0.1
        btn.Text = txt; btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 10; btn.Font = Enum.Font.GothamBold
        btn.Parent = pill
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(cb)
    end

    local lo = 0

    lo = lo + 1
    page:CreateLabel("Players")

    lo = lo + 1
    local pFrame = Instance.new("Frame")
    pFrame.Size = UDim2.new(1, -8, 0, 0)
    pFrame.BackgroundTransparency = 1; pFrame.BorderSizePixel = 0
    pFrame.LayoutOrder = lo; pFrame.Parent = _G.UNS_PageScroll
    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 5); pLayout.Parent = pFrame

    local function refreshPlayers()
        for _, c in ipairs(pFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local po = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                po = po + 1
                local pill = Instance.new("Frame")
                pill.Size = UDim2.new(1, -8, 0, 36)
                pill.BackgroundColor3 = C.surfaceAlt
                pill.BackgroundTransparency = 0.1
                pill.BorderSizePixel = 0
                pill.LayoutOrder = po
                pill.Parent = pFrame
                Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
                local stroke = Instance.new("UIStroke")
                stroke.Color = C.border; stroke.Thickness = 1; stroke.Transparency = 0.4
                stroke.Parent = pill
                local headshot = Instance.new("ImageLabel")
                headshot.Size = UDim2.new(0, 28, 0, 28)
                headshot.Position = UDim2.new(0, 6, 0.5, -14)
                headshot.BackgroundTransparency = 1
                headshot.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
                headshot.Parent = pill
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -170, 1, 0)
                lbl.Position = UDim2.new(0, 40, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = p.Name
                lbl.TextColor3 = C.textPri; lbl.TextSize = 11
                lbl.Font = Enum.Font.GothamSemibold
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = pill
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 70, 0, 22)
                btn.Position = UDim2.new(1, -80, 0.5, -11)
                btn.BackgroundColor3 = C.accent; btn.BackgroundTransparency = 0.1
                btn.Text = "TP"; btn.TextColor3 = Color3.new(1, 1, 1)
                btn.TextSize = 10; btn.Font = Enum.Font.GothamBold
                btn.Parent = pill
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                btn.MouseButton1Click:Connect(function()
                    pcall(function()
                        local mr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if mr and pr then mr.CFrame = pr.CFrame * CFrame.new(0, 0, 3) end
                    end)
                end)
            end
        end
        pFrame.Size = UDim2.new(1, -8, 0, po > 0 and (po * 41 - 5) or 0)
    end

    refreshPlayers()
    table.insert(tpPlayerConns, Players.PlayerAdded:Connect(refreshPlayers))
    table.insert(tpPlayerConns, Players.PlayerRemoving:Connect(refreshPlayers))

    lo = lo + 1
    page:CreateLabel("Checkpoints")

    lo = lo + 1
    local savePill = makePill(_G.UNS_PageScroll, "Save Checkpoint", lo)

    local function rebuildCpPills()
        local scroll = _G.UNS_PageScroll
        if not scroll then return end
        for _, c in ipairs(scroll:GetChildren()) do
            if c.Name == "UNS_CpPill" then c:Destroy() end
        end
        for i, wp in ipairs(tpWaypoints) do
            makeCpPill(i, wp, scroll)
        end
    end

    local function makeCpPill(index, wp, parent)
        local pill = Instance.new("Frame")
        pill.Name = "UNS_CpPill"
        pill.Size = UDim2.new(1, -8, 0, 32)
        pill.BackgroundColor3 = C.surfaceAlt
        pill.BackgroundTransparency = 0.1
        pill.BorderSizePixel = 0
        pill.LayoutOrder = 9000 + index
        pill.Parent = parent
        pill:SetAttribute("CpIdx", index)
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke")
        stroke.Color = C.border; stroke.Thickness = 1; stroke.Transparency = 0.4
        stroke.Parent = pill

        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(1, -170, 1, 0); nameBox.Position = UDim2.new(0, 14, 0, 0)
        nameBox.BackgroundTransparency = 1; nameBox.Text = wp.Name
        nameBox.TextColor3 = C.textPri; nameBox.TextSize = 11
        nameBox.Font = Enum.Font.GothamSemibold
        nameBox.TextXAlignment = Enum.TextXAlignment.Left
        nameBox.ClearTextOnFocus = false
        nameBox.Parent = pill
        nameBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local cpIdx = pill:GetAttribute("CpIdx")
                if cpIdx and tpWaypoints[cpIdx] then
                    tpWaypoints[cpIdx].Name = nameBox.Text
                end
            else
                nameBox.Text = wp.Name
            end
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 65, 0, 22)
        delBtn.Position = UDim2.new(1, -155, 0.5, -11)
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        delBtn.BackgroundTransparency = 0.1
        delBtn.Text = "Del"; delBtn.TextColor3 = Color3.new(1, 1, 1)
        delBtn.TextSize = 10; delBtn.Font = Enum.Font.GothamBold
        delBtn.Parent = pill
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
        delBtn.MouseButton1Click:Connect(function()
            local p = delBtn.Parent
            if not p then return end
            local idx = p:GetAttribute("CpIdx")
            if idx and idx >= 1 and idx <= #tpWaypoints then
                table.remove(tpWaypoints, idx)
                p:Destroy()
                local newIdx = 0
                for _, c in ipairs(_G.UNS_PageScroll:GetChildren()) do
                    if c.Name == "UNS_CpPill" then
                        newIdx = newIdx + 1
                        c.LayoutOrder = 9000 + newIdx
                        c:SetAttribute("CpIdx", newIdx)
                    end
                end
            end
        end)

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 65, 0, 22)
        tpBtn.Position = UDim2.new(1, -80, 0.5, -11)
        tpBtn.BackgroundColor3 = C.accent; tpBtn.BackgroundTransparency = 0.1
        tpBtn.Text = "TP"; tpBtn.TextColor3 = Color3.new(1, 1, 1)
        tpBtn.TextSize = 10; tpBtn.Font = Enum.Font.GothamBold
        tpBtn.Parent = pill
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
        tpBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then root.CFrame = wp.CFrame end
            end)
        end)

        return pill
    end

    addBtn(savePill, function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local name = "CP #" .. (#tpWaypoints + 1)
            table.insert(tpWaypoints, {Name = name, CFrame = root.CFrame})
            local scroll = _G.UNS_PageScroll
            if scroll then
                makeCpPill(#tpWaypoints, tpWaypoints[#tpWaypoints], scroll)
            end
        end
    end, "Save")

    rebuildCpPills()
end)

-- ESP
local esp = tab:CreateSection("ESP")
esp:CreateToggle("Master ESP", function(s)
    ESP_Settings.Enabled = s
    if s then startESPLoop() else stopESPLoop() end
end)
esp:CreatePageButton("Advanced ESP Settings", "ESP Settings", setupESPSettingsPage)

-- Misc
local misc = tab:CreateSection("Misc")
misc:CreateToggle("F3X", function(state)
    if _G.toggleF3X then _G.toggleF3X(state) end
end)

-- ============================================================
--  UNWalk Speed — Full Advanced Walk Speed V7 Integration
-- ============================================================
local function wsGetLimit()
    return wsCfg.extremeSpeed and 99999 or wsCfg.maxSpeedLimit
end

local function wsApplySpeed(speed)
    wsCfg.currentSpeed = math.clamp(speed, wsCfg.minSpeed, wsGetLimit())
    if wsSliderUpdater then pcall(wsSliderUpdater, wsCfg.currentSpeed, wsGetLimit(), wsCfg.minSpeed) end
    if not wsCfg.enabled or wsCfg.cframeBypass then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = wsCfg.currentSpeed end
end

local function wsCreateBV(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local e = hrp:FindFirstChild("AwsBodyVel")
    if e then e:Destroy() end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "AwsBodyVel"; bv.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bv.Velocity = Vector3.zero; bv.P = 10000; bv.Parent = hrp
    return bv
end

local function wsDestroyBV(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then local bv = hrp:FindFirstChild("AwsBodyVel"); if bv then bv:Destroy() end end
end

local wsHeartbeatConn, wsStopConn

local function wsStartCFrame()
    if wsHeartbeatConn then return end
    local char = LocalPlayer.Character; if not char then return end
    wsCreateBV(char)
    wsHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not wsCfg.cframeBypass or not wsCfg.enabled then return end
        local ch = LocalPlayer.Character; if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid"); if not hum then return end
        hum.WalkSpeed = wsCfg.gameDefaultSpeed
        local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local bv = hrp:FindFirstChild("AwsBodyVel")
        if not bv then bv = wsCreateBV(ch); if not bv then return end end
        local md = hum.MoveDirection
        bv.Velocity = md.Magnitude > 0.01 and Vector3.new(md.X, 0, md.Z).Unit * wsCfg.currentSpeed or Vector3.zero
    end)
end

local function wsStopCFrame()
    if wsHeartbeatConn then wsHeartbeatConn:Disconnect(); wsHeartbeatConn = nil end
    wsDestroyBV(LocalPlayer.Character)
end

local function wsStartStopLoop()
    if wsStopConn then return end
    wsStopConn = RunService.Heartbeat:Connect(function()
        if not wsCfg.enabled or not wsCfg.instantStop then return end
        local moving = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A)
            or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)
        if moving then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local v = hrp.Velocity
            if Vector3.new(v.X, 0, v.Z).Magnitude > 0.5 then hrp.Velocity = Vector3.new(0, v.Y, 0) end
        end
    end)
end

local function wsStopInstantStop()
    if wsStopConn then wsStopConn:Disconnect(); wsStopConn = nil end
end

-- Speed enforcement loop
task.spawn(function()
    while wsRun do
        task.wait(0.3)
        if not wsCfg.enabled or wsCfg.cframeBypass then continue end
        if wsCfg.currentSpeed < wsCfg.minSpeed then
            wsApplySpeed(wsCfg.minSpeed)
        end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= wsCfg.currentSpeed then hum.WalkSpeed = wsCfg.currentSpeed end
    end
end)

-- CFrame bypass state watcher
task.spawn(function()
    local lastBypass = false
    while wsRun do
        task.wait(0.1)
        local should = wsCfg.cframeBypass and wsCfg.enabled
        if should and not lastBypass then wsStartCFrame() end
        if not should and lastBypass then wsStopCFrame() end
        lastBypass = should
    end
end)

-- Instant stop state watcher
task.spawn(function()
    local lastStop = false
    while wsRun do
        task.wait(0.1)
        local should = wsCfg.instantStop and wsCfg.enabled
        if should and not lastStop then wsStartStopLoop() end
        if not should and lastStop then wsStopInstantStop() end
        lastStop = should
    end
end)

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    wsCfg.gameDefaultSpeed = hum.WalkSpeed
    hum.WalkSpeed = wsCfg.enabled and (wsCfg.cframeBypass and wsCfg.gameDefaultSpeed or wsCfg.currentSpeed) or wsCfg.gameDefaultSpeed
end)

-- Initial setup
task.spawn(function()
    task.wait(2)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then wsCfg.gameDefaultSpeed = hum.WalkSpeed end
    if wsCfg.enabled then wsApplySpeed(wsCfg.currentSpeed) end
end)

-- UNWalk Speed UI
local awsSec = tab:CreateSection("UNWalk Speed")
awsSec:CreatePageButton("UNWalk Speed", "UNWalk Speed", function(page)
    local mainSec = page:CreateSection("Main Toggle")
    mainSec:CreateToggle("Advanced Walk Speed", function(state)
        wsCfg.enabled = state
        if not state then
            wsCfg.preToggleSpeed = wsCfg.currentSpeed
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = wsCfg.gameDefaultSpeed end
        else
            wsCfg.currentSpeed = wsCfg.preToggleSpeed
            wsApplySpeed(wsCfg.currentSpeed)
        end
    end, wsCfg.enabled)

    local sc = page:CreateSection("Speed Control")
    sc:CreateSlider("Current Speed", 0, 500, wsCfg.currentSpeed, function(v)
        wsApplySpeed(v)
    end)
    if _G.UNS_SliderSetVal then
        wsSliderUpdater = _G.UNS_SliderSetVal["Current Speed"]
        if wsSliderUpdater then pcall(wsSliderUpdater, wsCfg.currentSpeed, wsGetLimit(), wsCfg.minSpeed) end
    end
    sc:CreateSlider("Speed Increment", 1, 50, wsCfg.speedIncrement, function(v)
        wsCfg.speedIncrement = v
    end)
    sc:CreateSlider("Speed Cap / Limit", 16, 500, wsCfg.maxSpeedLimit, function(v)
        wsCfg.maxSpeedLimit = v
        if not wsCfg.extremeSpeed and wsCfg.currentSpeed > v then
            wsApplySpeed(v)
        end
        if wsSliderUpdater then pcall(wsSliderUpdater, wsCfg.currentSpeed, wsGetLimit(), wsCfg.minSpeed) end
    end)
    sc:CreateSlider("Minimum Speed", 0, 50, wsCfg.minSpeed, function(v)
        wsCfg.minSpeed = v
    end)

    local fc = page:CreateSection("Features")
    fc:CreateToggle("Instant Stop", function(state)
        wsCfg.instantStop = state
    end, wsCfg.instantStop)
    fc:CreateToggle("EXTREME SPEED MODE", function(state)
        wsCfg.extremeSpeed = state; wsApplySpeed(wsCfg.currentSpeed)
    end, wsCfg.extremeSpeed)
    fc:CreateToggle("CFrame Walking (Bypass)", function(state)
        wsCfg.cframeBypass = state
        if not state then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = wsCfg.currentSpeed end
        end
    end, wsCfg.cframeBypass)

    local pc = page:CreateSection("Quick Presets")
    local presets = {{"Walk", 16}, {"Sprint", 32}, {"Mach 1", 100}, {"Mach 2", 200}, {"Mach 3", 500}, {"Mach 5", 1000}}
    for _, p in ipairs(presets) do
        pc:CreateButton(p[1] .. " (" .. p[2] .. ")", function() wsApplySpeed(p[2]) end)
    end
end)

-- Direct key listeners for speed control (works regardless of settings page)
local wsConnBegan = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not wsCfg.enabled then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Equals then
        wsApplySpeed(wsCfg.currentSpeed + wsCfg.speedIncrement)
        wsHoldingUp = true; wsLastUpTime = tick()
    elseif input.KeyCode == Enum.KeyCode.Minus then
        wsApplySpeed(wsCfg.currentSpeed - wsCfg.speedIncrement)
        wsHoldingDown = true; wsLastDownTime = tick()
    end
end)

-- Speed keybinds (bonus: register with settings page if available)
if _G.UNS_AddScriptShortcut then
    _G.UNS_AddScriptShortcut("Speed +", function()
        if wsCfg.enabled then
            wsApplySpeed(wsCfg.currentSpeed + wsCfg.speedIncrement)
            wsHoldingUp = true; wsLastUpTime = tick()
        end
    end, {mode = 1, key1 = "Equals"})
    _G.UNS_AddScriptShortcut("Speed -", function()
        if wsCfg.enabled then
            wsApplySpeed(wsCfg.currentSpeed - wsCfg.speedIncrement)
            wsHoldingDown = true; wsLastDownTime = tick()
        end
    end, {mode = 1, key1 = "Minus"})
    _G.UNS_AddScriptShortcut("Speed Reset", function()
        if wsCfg.enabled then wsApplySpeed(wsCfg.gameDefaultSpeed) end
    end)
end

-- Hold-to-repeat for speed keys
local function wsKeycodeFromName(n)
    local ok, kc = pcall(function() return Enum.KeyCode[n] end)
    return (ok and kc) or Enum.KeyCode.Unknown
end
local wsUpKeyCode = wsKeycodeFromName("Equals")
local wsDownKeyCode = wsKeycodeFromName("Minus")
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == wsUpKeyCode then wsHoldingUp = false end
    if input.KeyCode == wsDownKeyCode then wsHoldingDown = false end
end)
task.spawn(function()
    while task.wait(0.05) do
        if not wsRun then break end
        if wsCfg.enabled then
            local now = tick()
            if wsHoldingUp and (now - wsLastUpTime) >= WS_HOLD_RATE then
                wsApplySpeed(wsCfg.currentSpeed + wsCfg.speedIncrement)
                wsLastUpTime = now
            end
            if wsHoldingDown and (now - wsLastDownTime) >= WS_HOLD_RATE then
                wsApplySpeed(wsCfg.currentSpeed - wsCfg.speedIncrement)
                wsLastDownTime = now
            end
        end
    end
end)

-- ============================================================
--  Keybind Registrations
-- ============================================================
if _G.UNS_AddScriptShortcut then
    _G.UNS_AddScriptShortcut("Noclip", function()
        local new = not noclipEnabled; toggleNoclip(new)
        if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel("Noclip", new) end
    end)
    _G.UNS_AddScriptShortcut("Float", function()
        local new = not floatEnabled; toggleFloat(new)
        if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel("Float", new) end
    end)
    _G.UNS_AddScriptShortcut("Vfly", function()
        local new = not flyEnabled; toggleFly(new)
        if _G.UNScripts and _G.UNScripts.SetToggleByLabel then _G.UNScripts.SetToggleByLabel("Vfly", new) end
    end)
end

-- ============================================================
--  Cleanup
-- ============================================================
local combinedCleanup = function()
    if jumpRequestConn then jumpRequestConn:Disconnect(); jumpRequestConn = nil end
    if clickTPConn then clickTPConn:Disconnect(); clickTPConn = nil end

    if floatInputConn then floatInputConn:Disconnect(); floatInputConn = nil end
    toggleNoclip(false); toggleFly(false); toggleFloat(false); toggleAntiFling(false)
    stopESPLoop(); wsStopCFrame(); wsStopInstantStop()
    if wsConnBegan then wsConnBegan:Disconnect(); wsConnBegan = nil end
    clearF3XTools(); clearTPTool()
    infJumpEnabled = false; clickTPEnabled = false
    f3xEnabled = false; tptoolActive = false
    wsRun = false
end
_G.UNS_CombinedCleanup = combinedCleanup
table.insert(_G.UNS_CleanupList, combinedCleanup)

print("[Combined Plugin] All features merged into Scripts tab")
