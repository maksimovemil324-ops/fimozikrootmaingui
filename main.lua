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

local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

local function LoadMode(mode)
    local url = BASE .. mode .. ".lua"
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        Luna:Notification({Title = "Error", Content = "Failed to load " .. mode, Icon = "error", ImageSource = "Material"})
    end
end

-- ============ ВКЛАДКА SELECT GAME ============
local SelectTab = Window:CreateTab({ Name = "Select Game", Icon = "games", ImageSource = "Material", ShowTitle = true })

SelectTab:CreateButton({ Name = "Universal", Description = "Works in all games", Callback = function() LoadMode("universal") end })
SelectTab:CreateButton({ Name = "Block Strike", Description = "ESP + Aimbot + Bhop", Callback = function() LoadMode("blockstrike") end })
SelectTab:CreateButton({ Name = "The Lost Front", Description = "ESP + Aimbot + Godmode", Callback = function() LoadMode("thelostfront") end })
SelectTab:CreateButton({ Name = "Rust Lite", Description = "Drops + Sleepers + Guards", Callback = function() LoadMode("rustlite") end })
SelectTab:CreateButton({ Name = "UAV Strike", Description = "Drone ESP + Aimlock", Callback = function() LoadMode("uavstrike") end })
SelectTab:CreateButton({ Name = "Minesweeper", Description = "Auto Solver & ESP", Callback = function() LoadMode("minesweeper") end })

-- ============ ВКЛАДКА BLOCK STRIKE ============
local BSTab = Window:CreateTab({ Name = "Block Strike", Icon = "crosshair", ImageSource = "Material", ShowTitle = true })
local BS = nil

local function LoadBS()
    if BS then return BS end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(BASE .. "blockstrike.lua"))()
    end)
    if ok and result then
        BS = result
        Luna:Notification({Title = "Block Strike", Content = "Loaded", Icon = "check_circle", ImageSource = "Material"})
    else
        Luna:Notification({Title = "Error", Content = "Failed to load Block Strike", Icon = "error", ImageSource = "Material"})
    end
    return BS
end

local function SetBS(key, val)
    local bs = LoadBS()
    if bs and bs.Settings then bs.Settings[key] = val end
end

local SecBSAim = BSTab:CreateSection("Aimbot")
SecBSAim:CreateToggle({Name="Aimbot", CurrentValue=false, Callback=function(v) SetBS("Aimbot", v) end})
SecBSAim:CreateSlider({Name="FOV", Range={40,600}, CurrentValue=120, Callback=function(v) SetBS("AimbotFOV", v) end})
SecBSAim:CreateSlider({Name="Smooth", Range={1,100}, CurrentValue=25, Callback=function(v) SetBS("AimbotSmooth", v/100) end})
SecBSAim:CreateToggle({Name="Team Check", CurrentValue=true, Callback=function(v) SetBS("AimbotTeamCheck", v) end})
SecBSAim:CreateToggle({Name="Wall Check", CurrentValue=true, Callback=function(v) SetBS("AimbotWallCheck", v) end})
SecBSAim:CreateDropdown({Name="Hit Part", Options={"Head","UpperTorso","HumanoidRootPart"}, CurrentOption={"Head"}, Callback=function(o) SetBS("AimbotPart", o[1]) end})

local SecBSEsp = BSTab:CreateSection("ESP")
SecBSEsp:CreateToggle({Name="ESP", CurrentValue=false, Callback=function(v) SetBS("ESP", v) end})
SecBSEsp:CreateToggle({Name="Name", CurrentValue=true, Callback=function(v) SetBS("ESPName", v) end})
SecBSEsp:CreateToggle({Name="Health", CurrentValue=true, Callback=function(v) SetBS("ESPHealth", v) end})
SecBSEsp:CreateToggle({Name="Distance", CurrentValue=true, Callback=function(v) SetBS("ESPDistance", v) end})
SecBSEsp:CreateToggle({Name="Team Color", CurrentValue=true, Callback=function(v) SetBS("ESPTeamColor", v) end})

local SecBSMove = BSTab:CreateSection("Movement")
SecBSMove:CreateToggle({Name="Speed", CurrentValue=false, Callback=function(v) SetBS("Speed", v) end})
SecBSMove:CreateSlider({Name="Speed Value", Range={16,500}, CurrentValue=80, Callback=function(v) SetBS("SpeedVal", v) end})
SecBSMove:CreateToggle({Name="Jump", CurrentValue=false, Callback=function(v) SetBS("Jump", v) end})
SecBSMove:CreateSlider({Name="Jump Value", Range={50,800}, CurrentValue=200, Callback=function(v) SetBS("JumpVal", v) end})
SecBSMove:CreateToggle({Name="Fly", CurrentValue=false, Callback=function(v) SetBS("Fly", v) end})
SecBSMove:CreateSlider({Name="Fly Speed", Range={10,500}, CurrentValue=100, Callback=function(v) SetBS("FlySpeed", v) end})
SecBSMove:CreateToggle({Name="Noclip", CurrentValue=false, Callback=function(v) SetBS("Noclip", v) end})
SecBSMove:CreateToggle({Name="Bhop", CurrentValue=false, Callback=function(v) SetBS("Bhop", v) end})

local SecBSMisc = BSTab:CreateSection("Misc")
SecBSMisc:CreateToggle({Name="No Recoil", CurrentValue=false, Callback=function(v) SetBS("NoRecoil", v) end})
SecBSMisc:CreateToggle({Name="No Spread", CurrentValue=false, Callback=function(v) SetBS("NoSpread", v) end})
SecBSMisc:CreateToggle({Name="Fullbright", CurrentValue=false, Callback=function(v) SetBS("Fullbright", v) end})
SecBSMisc:CreateToggle({Name="Anti-AFK", CurrentValue=false, Callback=function(v) SetBS("AntiAFK", v) end})

-- ============ ВКЛАДКА THE LOST FRONT ============
local TLFTab = Window:CreateTab({ Name = "The Lost Front", Icon = "shield", ImageSource = "Material", ShowTitle = true })
local TLF = nil

local function LoadTLF()
    if TLF then return TLF end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(BASE .. "thelostfront.lua"))()
    end)
    if ok and result then
        TLF = result
        Luna:Notification({Title = "The Lost Front", Content = "Loaded", Icon = "check_circle", ImageSource = "Material"})
    else
        Luna:Notification({Title = "Error", Content = "Failed to load The Lost Front", Icon = "error", ImageSource = "Material"})
    end
    return TLF
end

local function SetTLF(key, val)
    local mod = LoadTLF()
    if mod and mod.Settings then mod.Settings[key] = val end
end

local SecTLFCombat = TLFTab:CreateSection("Combat")
SecTLFCombat:CreateToggle({Name="Aimbot", CurrentValue=false, Callback=function(v) SetTLF("Aimbot", v) end})
SecTLFCombat:CreateSlider({Name="FOV", Range={40,600}, CurrentValue=120, Callback=function(v) SetTLF("AimbotFOV", v) end})
SecTLFCombat:CreateToggle({Name="Godmode", CurrentValue=false, Callback=function(v) SetTLF("Godmode", v) end})

local SecTLFVisuals = TLFTab:CreateSection("Visuals")
SecTLFVisuals:CreateToggle({Name="ESP", CurrentValue=false, Callback=function(v) SetTLF("ESP", v) end})
SecTLFVisuals:CreateToggle({Name="No Fog / Sky", CurrentValue=false, Callback=function(v) SetTLF("NoFog", v) end})
SecTLFVisuals:CreateToggle({Name="No Leaves", CurrentValue=false, Callback=function(v) SetTLF("NoLeaves", v) end})
SecTLFVisuals:CreateToggle({Name="FPS Booster", CurrentValue=false, Callback=function(v) SetTLF("FPSBooster", v) end})

local SecTLFMove = TLFTab:CreateSection("Movement")
SecTLFMove:CreateToggle({Name="Speed", CurrentValue=false, Callback=function(v) SetTLF("Speed", v) end})
SecTLFMove:CreateSlider({Name="Speed Value", Range={16,500}, CurrentValue=80, Callback=function(v) SetTLF("SpeedVal", v) end})
SecTLFMove:CreateToggle({Name="Noclip", CurrentValue=false, Callback=function(v) SetTLF("Noclip", v) end})

-- ============ МОБИЛЬНАЯ КНОПКА FIMO ============
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
        if Window.State then
            hideMenu()
        else
            showMenu()
        end
    end)
end
