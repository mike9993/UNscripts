local HttpService = game:GetService("HttpService")

local function loadScript(url)
    local ok, result = pcall(function()
        local code = game:HttpGet(url, true)
        local fn, err = loadstring(code)
        if fn then
            local s, e = pcall(fn)
            if not s then warn("UNScripts Hub: Script error:", e) end
        else
            warn("UNScripts Hub: Failed to compile:\n" .. (err or "unknown error"))
        end
    end)
    if not ok then
        warn("UNScripts Hub: Failed to fetch URL:\n" .. result)
    end
end

local hubTab = _G.UNScripts:CreateTab("Hubs")

-- Games / MM2
local mm2 = hubTab:CreateSection("MM2")
mm2:CreateButton("UNMM2", function() loadScript("https://raw.githubusercontent.com/mike9993/UNMM2/refs/heads/main/obfuscated_unmm2_v12.lua") end)

-- Games / MVSD
local mvsd = hubTab:CreateSection("MVSD")
mvsd:CreateButton("MVSD", function() loadScript("https://www.vaporscripts.xyz/VaporMvsd") end)

-- Script
local scripts = hubTab:CreateSection("Script")
scripts:CreateButton("AK", function() loadScript("https://absent.wtf/AKADMIN.lua") end)
scripts:CreateButton("Infinite Yield", function() loadScript("https://raw.githubusercontent.com/mike9993/Infinite-Yield-FE/refs/heads/main/Infinite%20Yield%20FE.lua") end)
scripts:CreateButton("Emotes / Animations", function() loadScript("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua") end)
scripts:CreateButton("mois7", function() loadScript("https://api.luarmor.net/files/v4/loaders/c146e7169df99db2afa5052b177dd747.lua") end)

-- UNScripts
local un = hubTab:CreateSection("UNScripts")
un:CreateButton("UNScripts Fling", function() loadScript("https://raw.githubusercontent.com/mike9993/UNscript-fling-/refs/heads/main/FlingScript%20V.4.lua") end)
un:CreateButton("UNTapFling", function() loadScript("https://raw.githubusercontent.com/mike9993/TapFling/refs/heads/main/FlingScriptUN.3.txt") end)
un:CreateButton("Advanced Walk Speed", function() loadScript("https://raw.githubusercontent.com/mike9993/Advance-walk-speed./refs/heads/main/AdvancedWalkSpeed%20v7.lua") end)
un:CreateButton("Advanced Invis", function() loadScript("https://raw.githubusercontent.com/mike9993/UN-Invis/refs/heads/main/advanced_invis.lua") end)

print("[UNScripts] Hubs Plugin loaded")
