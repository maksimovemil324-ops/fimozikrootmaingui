-- main.lua | FIMO HUB | by Fimozikroot | t.me/fimozikroot
-- Loader fixes: no duplicate window, real error output, module cache, key system fallback.

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local G = (getgenv and getgenv()) or _G
local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

-- ============ HTTP (fallback for executors where game:HttpGet dies) ============
local function httpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(body) == "string" and #body > 10 then return body end
    if syn and syn.request then
        local o, r = pcall(function() return syn.request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 10 then return r end
    elseif http and http.request then
        local o, r = pcall(function() return http.request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 10 then return r end
    elseif request then
        local o, r = pcall(function() return request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 10 then return r end
    end
    return nil
end

local function getLuna()
    if G.FimoLuna then return G.FimoLuna end
    local src = httpGet(BASE .. "source.lua")
    if not src then error("[FIMO] cannot download source.lua - http disabled?") end
    local fn, cerr = loadstring(src)
    if not fn then error("[FIMO] source.lua compile failed: " .. tostring(cerr)) end
    local Luna = fn()
    G.FimoLuna = Luna
    return Luna
end

local okLuna, Luna = pcall(getLuna)
if not okLuna then
    warn(tostring(Luna))
    return
end

-- ============ WINDOW (key system must not kill the menu) ============
local windowCfg = {
    Name = "FIMO HUB",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = true,
    LoadingTitle = "FIMO HUB",
    LoadingSubtitle = "by Fimozikroot",
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    KeySystem = true,
    KeySettings = {
        Title = "FIMO HUB Key",
        Subtitle = "Verification",
        Note = "Key is: fimozikroot",
        SaveInRoot = false,
        SaveKey = true,
        Key = { "fimozikroot" },
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" },
    },
}

local Window
local function tryWindow(cfg)
    local ok, res = pcall(function() return Luna:CreateWindow(cfg) end)
    if ok and res then return res end
    warn("[FIMO] CreateWindow failed: " .. tostring(res))
    return nil
end

if G.FimoWindow then
    Window = G.FimoWindow
else
    Window = tryWindow(windowCfg)
    if not Window then
        local noKey = {}
        for k, v in pairs(windowCfg) do noKey[k] = v end
        noKey.KeySystem = false
        noKey.LoadingEnabled = false
        Window = tryWindow(noKey)
    end
    G.FimoWindow = Window
end

if not Window then
    warn("[FIMO] UI unavailable in this executor")
    return
end

pcall(function() Window.Bind = Enum.KeyCode.K end)

local function notify(title, content)
    pcall(function()
        Luna:Notification({ Title = title, Content = content, Icon = "info", ImageSource = "Material" })
    end)
end

-- ============ MODULE LOADER (cached, real errors) ============
local Modules = {}
local Loading = {}

local function LoadMode(mode)
    if Modules[mode] then return Modules[mode] end
    if Loading[mode] then return nil end
    Loading[mode] = true

    local url = BASE .. mode .. ".lua"
    if not mode:match("^[%w_]+$") then Loading[mode] = nil; return nil end

    local src = httpGet(url)
    if not src then
        Loading[mode] = nil
        notify("Load error", mode .. ": download failed")
        warn("[FIMO] download failed: " .. url)
        return nil
    end

    local fn, cerr = loadstring(src)
    if not fn then
        Loading[mode] = nil
        notify("Load error", mode .. ": syntax " .. tostring(cerr))
        warn("[FIMO] compile failed " .. mode .. ": " .. tostring(cerr))
        return nil
    end

    local ok, res = pcall(fn)
    Loading[mode] = nil
    if not ok then
        notify("Load error", mode .. ": runtime error (see console)")
        warn("[FIMO] runtime error " .. mode .. ": " .. tostring(res))
        return nil
    end

    Modules[mode] = res or true
    return Modules[mode]
end

-- ============ SELECT GAME ============
local SelectTab = Window:CreateTab({ Name = "Select Game", Icon = "games", ImageSource = "Material", ShowTitle = true })
local SelectSection = SelectTab:CreateSection("All in one")
local GameList = {
    { Mode = "universal", Name = "Universal", Desc = "Silent Aim + Rage + ESP" },
    { Mode = "blockstrike", Name = "Block Strike", Desc = "ESP + Aimbot + Bhop" },
    { Mode = "thelostfront", Name = "The Lost Front", Desc = "ESP + Aimbot + Godmode" },
    { Mode = "rustlite", Name = "Rust Lite", Desc = "Drops + Sleepers + Guards" },
    { Mode = "uavstrike", Name = "UAV Strike", Desc = "Drone ESP + Aimlock" },
    { Mode = "minesweeper", Name = "Minesweeper", Desc = "Auto Solver & ESP" },
}
for _, g in ipairs(GameList) do
    SelectSection:CreateButton({
        Name = g.Name,
        Description = g.Desc,
        Callback = function() LoadMode(g.Mode) end,
    })
end

-- ============ BLOCK STRIKE TAB ============
local BSTab = Window:CreateTab({ Name = "Block Strike", Icon = "crosshair", ImageSource = "Material", ShowTitle = true })
local function SetModule(mode, key, val)
    local mod = Modules[mode] or LoadMode(mode)
    if mod and mod.Settings then mod.Settings[key] = val end
end

local SecBSAim = BSTab:CreateSection("Aimbot")
SecBSAim:CreateToggle({ Name = "Aimbot", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "Aimbot", v) end })
SecBSAim:CreateSlider({ Name = "FOV", Range = { 40, 600 }, CurrentValue = 120, Callback = function(v) SetModule("blockstrike", "AimbotFOV", v) end })
SecBSAim:CreateSlider({ Name = "Smooth", Range = { 1, 100 }, CurrentValue = 25, Callback = function(v) SetModule("blockstrike", "AimbotSmooth", v / 100) end })
SecBSAim:CreateToggle({ Name = "Team Check", CurrentValue = true, Callback = function(v) SetModule("blockstrike", "AimbotTeamCheck", v) end })
SecBSAim:CreateToggle({ Name = "Wall Check", CurrentValue = true, Callback = function(v) SetModule("blockstrike", "AimbotWallCheck", v) end })

local SecBSEsp = BSTab:CreateSection("ESP")
SecBSEsp:CreateToggle({ Name = "ESP", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "ESP", v) end })
SecBSEsp:CreateToggle({ Name = "Name", CurrentValue = true, Callback = function(v) SetModule("blockstrike", "ESPName", v) end })
SecBSEsp:CreateToggle({ Name = "Health", CurrentValue = true, Callback = function(v) SetModule("blockstrike", "ESPHealth", v) end })
SecBSEsp:CreateToggle({ Name = "Distance", CurrentValue = true, Callback = function(v) SetModule("blockstrike", "ESPDistance", v) end })

local SecBSMove = BSTab:CreateSection("Movement")
SecBSMove:CreateToggle({ Name = "Speed", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "Speed", v) end })
SecBSMove:CreateSlider({ Name = "Speed Value", Range = { 16, 500 }, CurrentValue = 80, Callback = function(v) SetModule("blockstrike", "SpeedVal", v) end })
SecBSMove:CreateToggle({ Name = "Jump", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "Jump", v) end })
SecBSMove:CreateSlider({ Name = "Jump Value", Range = { 50, 800 }, CurrentValue = 200, Callback = function(v) SetModule("blockstrike", "JumpVal", v) end })
SecBSMove:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "Noclip", v) end })

local SecBSMisc = BSTab:CreateSection("Misc")
SecBSMisc:CreateToggle({ Name = "No Recoil", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "NoRecoil", v) end })
SecBSMisc:CreateToggle({ Name = "Fullbright", CurrentValue = false, Callback = function(v) SetModule("blockstrike", "Fullbright", v) end })

-- ============ THE LOST FRONT TAB ============
local TLFTab = Window:CreateTab({ Name = "The Lost Front", Icon = "shield", ImageSource = "Material", ShowTitle = true })

local SecTLFCombat = TLFTab:CreateSection("Combat")
SecTLFCombat:CreateToggle({ Name = "Aimbot", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "Aimbot", v) end })
SecTLFCombat:CreateSlider({ Name = "FOV", Range = { 40, 600 }, CurrentValue = 120, Callback = function(v) SetModule("thelostfront", "AimbotFOV", v) end })
SecTLFCombat:CreateToggle({ Name = "Godmode", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "Godmode", v) end })

local SecTLFVisuals = TLFTab:CreateSection("Visuals")
SecTLFVisuals:CreateToggle({ Name = "ESP", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "ESP", v) end })
SecTLFVisuals:CreateToggle({ Name = "No Fog / Sky", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "NoFog", v) end })
SecTLFVisuals:CreateToggle({ Name = "No Leaves", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "NoLeaves", v) end })
SecTLFVisuals:CreateToggle({ Name = "FPS Booster", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "FPSBooster", v) end })

local SecTLFMove = TLFTab:CreateSection("Movement")
SecTLFMove:CreateToggle({ Name = "Speed", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "Speed", v) end })
SecTLFMove:CreateSlider({ Name = "Speed Value", Range = { 16, 500 }, CurrentValue = 80, Callback = function(v) SetModule("thelostfront", "SpeedVal", v) end })
SecTLFMove:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(v) SetModule("thelostfront", "Noclip", v) end })

local ClientTab = Window:CreateTab({ Name = "Client", Icon = "settings", ImageSource = "Material", ShowTitle = true })
local ClientSec = ClientTab:CreateSection("Hub")
ClientSec:CreateButton({
    Name = "Reload modules",
    Callback = function()
        Modules = {}
        notify("Client", "module cache cleared")
    end,
})
ClientSec:CreateButton({
    Name = "Reopen menu (mobile)",
    Callback = function()
        pcall(function() Window.State = true end)
        local parent = (gethui and gethui()) or CoreGui
        for _, obj in ipairs(parent:GetChildren()) do
            if obj.Name == "Luna UI" then
                local smart = obj:FindFirstChild("SmartWindow")
                if smart then
                    smart.Visible = true
                    pcall(function() Window.State = true end)
                end
            end
        end
    end,
})

-- ============ MOBILE FIMO BUTTON ============
local function getLunaGUI()
    local parent = (gethui and gethui()) or CoreGui
    for _, obj in ipairs(parent:GetChildren()) do
        if obj.Name == "Luna UI" then return obj end
    end
    for _, obj in ipairs(CoreGui:GetChildren()) do
        if obj.Name == "Luna UI" then return obj end
    end
    return nil
end

local function setMenu(state)
    local gui = getLunaGUI()
    if not gui then return end
    local smart = gui:FindFirstChild("SmartWindow")
    if not smart then return end
    smart.Visible = state
    pcall(function() Window.State = state end)
end

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    local parent = (gethui and gethui()) or CoreGui
    local btn = Instance.new("TextButton")
    btn.Name = "FimoMobileBtn"
    btn.Parent = parent
    btn.Size = UDim2.new(0, 70, 0, 70)
    btn.Position = UDim2.new(0, 20, 0.5, -35)
    btn.BackgroundColor3 = Color3.fromRGB(139, 149, 246)
    btn.Text = "FIMO"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.ZIndex = 999999
    btn.AutoButtonColor = false

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 14)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.new(1, 1, 1)
    s.Thickness = 2
    s.Transparency = 0.5

    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    btn.MouseButton1Click:Connect(function()
        local gui = getLunaGUI()
        local smart = gui and gui:FindFirstChild("SmartWindow")
        local visible = smart and smart.Visible
        setMenu(not visible)
    end)
end

notify("FIMO HUB", "loaded")
