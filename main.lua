local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
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
        Key = {"fimozikroot"},
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" }
    }
})

Window.Bind = Enum.KeyCode.K
Window:CreateHomeTab({ SupportedExecutors = {"Xeno","Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local SelectTab = Window:CreateTab({ Name = "Select Game", Icon = "games", ImageSource = "Material", ShowTitle = true })
local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

local function LoadMode(mode)
    local url = BASE .. mode .. ".lua"
    Luna:Notification({Title = "Loading", Content = "Загрузка " .. mode .. "...", Icon = "download", ImageSource = "Material"})
    local ok, err = pcall(function()
        local source = game:HttpGet(url)
        local func, loadErr = loadstring(source)
        if not func then error("Ошибка синтаксиса: " .. tostring(loadErr)) end
        func()
    end)
    if not ok then
        Luna:Notification({Title = "Error", Content = "Failed to load " .. mode .. ": " .. tostring(err), Icon = "error", ImageSource = "Material", Duration = 10})
        warn("FIMO HUB Error: " .. tostring(err))
    end
end

SelectTab:CreateButton({ Name = "Universal", Description = "Works in all games", Callback = function() LoadMode("universal") end })
SelectTab:CreateButton({ Name = "Block Strike", Description = "ESP + Aimbot + Bhop", Callback = function() LoadMode("blockstrike") end })
SelectTab:CreateButton({ Name = "Rust Lite", Description = "Drops + Sleepers + Guards", Callback = function() LoadMode("rustlite") end })
SelectTab:CreateButton({ Name = "UAV Strike", Description = "Drone ESP + Aimlock", Callback = function() LoadMode("uavstrike") end })
SelectTab:CreateButton({ Name = "Minesweeper", Description = "Auto Solver & ESP", Callback = function() LoadMode("minesweeper") end })

-- Мобильная кнопка
local function getLunaGUI()
    local parent = (gethui and gethui()) or CoreGui
    for _, obj in ipairs(parent:GetChildren()) do if obj.Name == "Luna UI" then return obj end end
    for _, obj in ipairs(CoreGui:GetChildren()) do if obj.Name == "Luna UI" then return obj end end
    return nil
end

local function toggleMenu()
    local gui = getLunaGUI()
    if not gui then return end
    local smart = gui:FindFirstChild("SmartWindow")
    if smart then 
        smart.Visible = not smart.Visible 
        Window.State = smart.Visible
    end
end

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    local parent = (gethui and gethui()) or CoreGui
    local btn = Instance.new("TextButton")
    btn.Name = "FimoMobileBtn"
    btn.Parent = parent
    btn.Size = UDim2.new(0, 70, 0, 70)
    btn.Position = UDim2.new(0, 20, 0.5, -35)
    btn.BackgroundColor3 = Color3.fromRGB(139,149,246)
    btn.Text = "FIMO"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.ZIndex = 999999
    btn.AutoButtonColor = false
    
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 14)
    
    btn.MouseButton1Click:Connect(toggleMenu)
end
