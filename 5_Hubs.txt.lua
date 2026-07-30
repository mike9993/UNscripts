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
un:CreateButton("UNScripts Fling", function()
    local urls = {
        "https://raw.githubusercontent.com/mike9993/UNscripts/refs/heads/main/6%20UNScripts_Secondary_UI.lua",
        "https://raw.githubusercontent.com/mike9993/UNscripts/refs/heads/main/7%20UNScripts_Secondary_Settings_Plugin.lua",
        "https://raw.githubusercontent.com/mike9993/UNscripts/refs/heads/main/8%20FlingPlugin.lua",
    }
    local names = {"Secondary Host", "Secondary Settings", "Fling Plugin"}
    for i, url in ipairs(urls) do
        local ok, result = pcall(function()
            local code = game:HttpGet(url, true)
            if code and #code >= 10 then
                local fn, err = loadstring(code)
                if fn then
                    local s, e2 = pcall(fn)
                    if not s then warn("UNFling: " .. names[i] .. " error: " .. tostring(e2)) end
                else
                    warn("UNFling: " .. names[i] .. " compile error: " .. tostring(err))
                end
            else
                warn("UNFling: " .. names[i] .. " empty response")
            end
        end)
        if not ok then warn("UNFling: " .. names[i] .. " fetch failed: " .. tostring(result)) end
        if i == 1 then
            for _ = 1, 100 do
                if _G.UNScripts_Secondary and _G.UNScripts_Secondary.MainPage then break end
                task.wait(0.5)
            end
        end
    end
end)


print("[UNScripts] Hubs Plugin loaded")
