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

Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

-- Замена кнопки Discord на Telegram
task.spawn(function()
    task.wait(1.5)
    local mainUI
    pcall(function() mainUI = game:GetService("CoreGui"):FindFirstChild("Luna UI") end)
    if not mainUI then pcall(function() mainUI = gethui():FindFirstChild("Luna UI") end) end
    if mainUI and mainUI:FindFirstChild("SmartWindow") then
        local home = mainUI.SmartWindow:FindFirstChild("Elements")
        if home and home:FindFirstChild("Home") then
            local dash = home.Home:FindFirstChild("detailsholder")
            if dash and dash:FindFirstChild("dashboard") then
                local discordBtn = dash.dashboard:FindFirstChild("Discord")
                if discordBtn then
                    pcall(function()
                        discordBtn.Title.Text = "Telegram"
                        discordBtn.Subtitle.Text = "t.me/fimozikroot"
                        for _, c in pairs(getconnections(discordBtn.Interact.MouseButton1Click)) do c:Disconnect() end
                        discordBtn.Interact.MouseButton1Click:Connect(function()
                            setclipboard("https://t.me/fimozikroot")
                            Luna:Notification({Title="Telegram", Content="Ссылка скопирована: t.me/fimozikroot", Icon="copy", ImageSource="Material"})
                        end)
                    end)
                end
            end
        end
    end
end)

local SelectTab = Window:CreateTab({ Name = "Select Game", Icon = "games", ImageSource = "Material", ShowTitle = true })

local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

local function LoadMode(mode)
    local url = BASE .. mode .. ".lua"
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        Luna:Notification({Title = "Error", Content = "Failed to load " .. mode .. ": " .. tostring(err), Icon = "error", ImageSource = "Material"})
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
    for _, obj in ipairs(parent:GetChildren()) do
        if obj.Name == "Luna UI" then return obj, parent end
    end
    for _, obj in ipairs(CoreGui:GetChildren()) do
        if obj.Name == "Luna UI" then return obj, CoreGui end
    end
    return nil, parent
end

local function showMenu()
    local gui = getLunaGUI()
    if not gui then return end
    local smart = gui:FindFirstChild("SmartWindow")
    if not smart then return end
    smart.Visible = true
    smart.Size = UDim2.fromOffset(675, 424)
    smart.BackgroundTransparency = 0.2
    local els = smart:FindFirstChild("Elements")
    if els then
        els.Visible = true
        els.BackgroundTransparency = 0.08
    end
    local nav = smart:FindFirstChild("Navigation")
    if nav then nav.Visible = true end
    Window.State = true
end

local function hideMenu()
    local gui = getLunaGUI()
    if not gui then return end
    local smart = gui:FindFirstChild("SmartWindow")
    if smart then smart.Visible = false end
    Window.State = false
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

    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.new(1,1,1)
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
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if Window.State then hideMenu() else showMenu() end
    end)
end
