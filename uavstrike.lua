local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local S = {
    DroneESP = false, DroneAimlock = false, DroneAutoDestroy = false, DroneTP = false,
    DroneGodmode = false, DroneRange = 1000, DroneMaxRange = 500000,
    DroneFly = false, UnlockDrones = false, AntiDroneDamage = false,
}

local DR = {}
local DGM = nil
local JDR = nil
pcall(function()
    JDR = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Weapon"):WaitForChild("Jammer"):WaitForChild("JammedDrone")
end)
local DRN = workspace:FindFirstChild("Drones")

local function isDroneValid(d)
    if not d or not d.Parent then return false end
    local ls = d:FindFirstChild("LifeStatus")
    return ls ~= nil and ls.Value == true
end
local function addDrone(d)
    if DR[d] then return end
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(235,60,60)
    h.OutlineColor = Color3.fromRGB(235,60,60)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = d
    local l = Drawing.new("Line")
    l.Color = Color3.fromRGB(235,60,60)
    l.Visible = false
    local t = Drawing.new("Text")
    t.Color = Color3.fromRGB(235,60,60)
    t.Size = 14
    t.Center = true
    t.Outline = true
    t.Visible = false
    DR[d] = {H=h, L=l, T=t}
end
if DRN then
    for _, c in ipairs(DRN:GetChildren()) do addDrone(c) end
    DRN.ChildAdded:Connect(addDrone)
    DRN.ChildRemoved:Connect(function(d)
        if DR[d] then
            if DR[d].H then DR[d].H:Destroy() end
            if DR[d].L then DR[d].L:Remove() end
            if DR[d].T then DR[d].T:Remove() end
            DR[d] = nil
        end
    end)
end

local function getClosestDrone()
    if not DRN then return nil end
    local cl, ds = nil, math.huge
    local cp = Camera.CFrame.Position
    for _, d in ipairs(DRN:GetChildren()) do
        if isDroneValid(d) then
            local dp = d:GetPivot().Position
            local dist = (dp - cp).Magnitude
            if dist < ds then ds = dist; cl = d end
        end
    end
    return cl
end

local function autoDestroyDrone(d)
    if not d or not isDroneValid(d) or not LP.Character then return end
    local c = LP.Character
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local jb = LP.Backpack:FindFirstChild("Jammer")
    if jb then h:EquipTool(jb) end
    local aj = c:FindFirstChild("Jammer")
    if aj then
        local dp = d:GetPivot().Position
        pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, dp) end)
        local fe = aj:FindFirstChild("Events") and aj.Events:FindFirstChild("FanEvent")
        if fe then pcall(function() fe:FireServer(30) end) end
        if JDR then pcall(function() JDR:FireServer(d, Camera.CFrame) end) end
    end
end

local function startDroneGodmode()
    if DGM then DGM:Disconnect() end
    DGM = RunService.Heartbeat:Connect(function()
        if not S.DroneGodmode then return end
        local c = LP.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.Health = h.MaxHealth end
        if h and h.PlatformStand then h.PlatformStand = false end
    end)
end
local function stopDroneGodmode()
    if DGM then DGM:Disconnect(); DGM = nil end
end

local lastTP = 0
local flyDrone = nil
RunService.RenderStepped:Connect(function()
    if not DRN then return end
    if S.UnlockDrones then
        for _, d in ipairs(DRN:GetChildren()) do
            local ls = d:FindFirstChild("LifeStatus")
            if ls then ls.Value = true end
        end
    end
    if S.AntiDroneDamage then
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h.Health = h.MaxHealth end
    end
    if S.DroneFly then
        if not flyDrone or not flyDrone.Parent or not isDroneValid(flyDrone) then
            flyDrone = getClosestDrone()
        end
        if flyDrone then
            local dp = flyDrone:GetPivot().Position
            local c = LP.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local camDir = Camera.CFrame.LookVector
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camDir end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camDir end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                hrp.CFrame = CFrame.new(dp + (moveDir * 2)) + Vector3.new(0,3,0)
            end
        end
    end
    local vp = Camera.ViewportSize
    local sb = Vector2.new(vp.X/2, vp.Y)
    local cp = Camera.CFrame.Position
    for d, data in pairs(DR) do
        if S.DroneESP and isDroneValid(d) then
            local dp = d:GetPivot().Position
            local dist = math.floor((dp - cp).Magnitude)
            if dist <= S.DroneMaxRange then
                local sp, os = Camera:WorldToViewportPoint(dp)
                if os then
                    local col = (dist <= S.DroneRange) and Color3.fromRGB(60,235,100) or Color3.fromRGB(235,60,60)
                    data.H.Enabled = true
                    data.H.FillColor = col
                    data.L.Color = col
                    data.L.From = sb
                    data.L.To = Vector2.new(sp.X, sp.Y)
                    data.L.Visible = true
                    data.T.Color = col
                    data.T.Position = Vector2.new(sp.X, sp.Y-22)
                    data.T.Text = string.format("UAV %d st", dist)
                    data.T.Visible = true
                else
                    data.H.Enabled = false
                    data.L.Visible = false
                    data.T.Visible = false
                end
            else
                data.H.Enabled = false
                data.L.Visible = false
                data.T.Visible = false
            end
        else
            if data.H then data.H.Enabled = false end
            data.L.Visible = false
            data.T.Visible = false
        end
    end
    if S.DroneAimlock and not S.DroneTP and not S.DroneFly then
        local d = getClosestDrone()
        if d then
            pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, d:GetPivot().Position) end)
        end
    end
    if S.DroneAutoDestroy and not S.DroneTP and not S.DroneFly then
        local d = getClosestDrone()
        if d then
            local dp = d:GetPivot().Position
            if (dp - cp).Magnitude <= S.DroneRange then
                autoDestroyDrone(d)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if S.DroneTP then
        local now = tick()
        if now - lastTP > 0.2 then
            lastTP = now
            local d = getClosestDrone()
            if d then
                local c = LP.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dp = d:GetPivot().Position
                    hrp.CFrame = CFrame.new(dp + Vector3.new(0,500,0))
                    if S.DroneAutoDestroy then autoDestroyDrone(d) end
                end
            end
        end
    end
end)

-- ================= UI =================
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()
local Window = Luna:CreateWindow({
    Name = "FIMO HUB | UAV Strike",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = false,
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    KeySystem = false,
})
Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local DP = Window:CreateTab({ Name = "Drone ESP", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local Combat = Window:CreateTab({ Name = "Aimlock & Auto", Icon = "gavel", ImageSource = "Material", ShowTitle = true })
local Misc = Window:CreateTab({ Name = "Survival & TP", Icon = "settings", ImageSource = "Material", ShowTitle = true })
local FlyTab = Window:CreateTab({ Name = "Fly as Drone", Icon = "flight", ImageSource = "Material", ShowTitle = true })
local Client = Window:CreateTab({ Name = "Client", Icon = "settings", ImageSource = "Material", ShowTitle = true })

local sD = DP:CreateSection("Drone ESP")
sD:CreateToggle({Name = "Drone ESP", CurrentValue = S.DroneESP, Callback = function(v) S.DroneESP = v end})
sD:CreateSlider({Name = "Max Range", Range = {100,100000}, CurrentValue = S.DroneMaxRange, Callback = function(v) S.DroneMaxRange = v end})

local sA = Combat:CreateSection("Aimlock & Auto")
sA:CreateToggle({Name = "Camera Aimlock", CurrentValue = S.DroneAimlock, Callback = function(v) S.DroneAimlock = v end})
sA:CreateToggle({Name = "Auto-Destroy", CurrentValue = S.DroneAutoDestroy, Callback = function(v) S.DroneAutoDestroy = v end})
sA:CreateSlider({Name = "Action Range", Range = {100,5000}, CurrentValue = S.DroneRange, Callback = function(v) S.DroneRange = v end})

local sT = Misc:CreateSection("Survival & TP")
sT:CreateToggle({Name = "TP Loop Above", CurrentValue = S.DroneTP, Callback = function(v) S.DroneTP = v end})
sT:CreateToggle({Name = "Godmode", CurrentValue = S.DroneGodmode, Callback = function(v)
    S.DroneGodmode = v
    if v then startDroneGodmode() else stopDroneGodmode() end
end})

local sFly = FlyTab:CreateSection("Fly as Drone")
sFly:CreateToggle({Name = "Fly Mode (Ride Drone)", CurrentValue = S.DroneFly, Callback = function(v) S.DroneFly = v end})
sFly:CreateToggle({Name = "Unlock All Drones", CurrentValue = S.UnlockDrones, Callback = function(v) S.UnlockDrones = v end})
sFly:CreateToggle({Name = "Anti-Drone Damage (Heal)", CurrentValue = S.AntiDroneDamage, Callback = function(v) S.AntiDroneDamage = v end})

local sC = Client:CreateSection("Client")
sC:CreateButton({Name = "Unload", Callback = function() Luna:Destroy() end})
