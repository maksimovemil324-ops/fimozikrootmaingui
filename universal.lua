local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Window = Luna:CreateWindow({
    Name = "FIMO HUB | Universal",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = false,
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
})

Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local Movement = Window:CreateTab({ Name = "Movement", Icon = "run_circle", ImageSource = "Material", ShowTitle = true })
local Combat = Window:CreateTab({ Name = "Combat", Icon = "gavel", ImageSource = "Material", ShowTitle = true })
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local Client = Window:CreateTab({ Name = "Client", Icon = "settings", ImageSource = "Material", ShowTitle = true })

local S = {
    Speed = false, SpeedVal = 80,
    Jump = false, JumpVal = 200,
    Noclip = false,
    Fly = false, FlySpeed = 100,
    InfJump = false,
    FullBright = false,
    AntiAFK = false,
    Aimbot = false, AimbotPOV = false, FOV = 200, AIM_KEY = Enum.KeyCode.X, AimbotSmooth = 0.25, WallCheck = true,
    ESP = false,
}

-- SPEED / JUMP
RunService.RenderStepped:Connect(function()
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if S.Speed then h.WalkSpeed = S.SpeedVal else h.WalkSpeed = 16 end
    if S.Jump then h.UseJumpPower = true; h.JumpPower = S.JumpVal else h.JumpPower = 50 end
end)

-- NOCLIP
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local c = LP.Character
    if not c then return end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- FLY
local FG, FV
local function startFly()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FG = Instance.new("BodyGyro", hrp)
    FG.P = 9e4; FG.MaxTorque = Vector3.new(9e9,9e9,9e9); FG.CFrame = hrp.CFrame
    FV = Instance.new("BodyVelocity", hrp)
    FV.MaxForce = Vector3.new(9e9,9e9,9e9); FV.Velocity = Vector3.zero
end
local function stopFly()
    if FG then FG:Destroy(); FG = nil end
    if FV then FV:Destroy(); FV = nil end
end
RunService.RenderStepped:Connect(function()
    if not S.Fly or not FG or not FV then return end
    local cm = workspace.CurrentCamera
    FG.CFrame = cm.CFrame
    local d = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cm.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cm.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cm.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cm.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
    if d.Magnitude > 0 then d = d.Unit * S.FlySpeed end
    FV.Velocity = d
end)

-- INF JUMP
UserInputService.JumpRequest:Connect(function()
    if S.InfJump and LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- FULL BRIGHT
local OB, OG = Lighting.Brightness, Lighting.GlobalShadows
RunService.RenderStepped:Connect(function()
    if S.FullBright then
        Lighting.Brightness = 10; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = OB; Lighting.GlobalShadows = OG
    end
end)

-- ANTI AFK
LP.Idled:Connect(function()
    if not S.AntiAFK then return end
    local V = game:GetService("VirtualUser")
    V:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    V:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ESP (Highlight)
local ESPH = {}
local function clearESP()
    for m, h in pairs(ESPH) do
        if h and h.Parent then h:Destroy() end
    end
    ESPH = {}
end
RunService.RenderStepped:Connect(function()
    if not S.ESP then
        if next(ESPH) then clearESP() end
        return
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("FimoESP")
            if not h then
                h = Instance.new("Highlight")
                h.Name = "FimoESP"
                h.Parent = p.Character
                h.FillColor = Color3.fromRGB(139,149,246)
                h.OutlineColor = Color3.new(1,1,1)
                h.FillTransparency = 0.4
                h.OutlineTransparency = 0.1
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                ESPH[p.Character] = h
            end
            h.Enabled = true
        end
    end
end)

-- AIMBOT
local AimTarget = nil
local function getMousePos()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    return UserInputService:GetMouseLocation()
end
local function findTarget()
    local cl, sh = nil, math.huge
    local mp = getMousePos()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local ok = true
                if S.WallCheck then
                    local r = Camera:GetPartsObscuringTarget({head.Position}, {LP.Character, p.Character, Camera})
                    if #r > 0 then ok = false end
                end
                if ok then
                    local sp, os = Camera:WorldToViewportPoint(head.Position)
                    if os then
                        local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                        if d <= S.FOV and d < sh then sh = d; cl = head end
                    end
                end
            end
        end
    end
    return cl
end
RunService.RenderStepped:Connect(function()
    if not S.Aimbot then AimTarget = nil; return end
    AimTarget = findTarget()
end)
local AimDown = false
UserInputService.InputBegan:Connect(function(i, gp) if gp then return end if i.KeyCode == S.AIM_KEY then AimDown = true end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == S.AIM_KEY then AimDown = false end end)
RunService:BindToRenderStep("FimoAim", Enum.RenderPriority.Camera.Value + 1, function()
    if not S.Aimbot or not AimDown or not AimTarget or not AimTarget.Parent then return end
    local cp = Camera.CFrame.Position
    local gc = CFrame.new(cp, AimTarget.Position)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        local nc = Camera.CFrame:Lerp(gc, S.AimbotSmooth)
        Camera.CFrame = CFrame.new(cp, cp + nc.LookVector)
    else
        Camera.CFrame = gc
    end
end)

-- FOV CIRCLE
local FC = Drawing.new("Circle")
FC.Thickness = 2; FC.Filled = false; FC.Visible = false; FC.Color = Color3.fromRGB(139,149,246)
RunService.RenderStepped:Connect(function()
    if S.Aimbot or S.AimbotPOV then
        FC.Visible = true
        FC.Radius = S.FOV
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            FC.Position = Camera.ViewportSize / 2
        else
            FC.Position = UserInputService:GetMouseLocation()
        end
    else
        FC.Visible = false
    end
end)

-- UI
local sM = Movement:CreateSection("Speed")
sM:CreateToggle({Name = "Speed", CurrentValue = S.Speed, Callback = function(v) S.Speed = v end})
sM:CreateSlider({Name = "Speed Value", Range = {16,500}, CurrentValue = S.SpeedVal, Callback = function(v) S.SpeedVal = v end})

local sJ = Movement:CreateSection("Jump")
sJ:CreateToggle({Name = "Jump Power", CurrentValue = S.Jump, Callback = function(v) S.Jump = v end})
sJ:CreateSlider({Name = "Jump Value", Range = {50,800}, CurrentValue = S.JumpVal, Callback = function(v) S.JumpVal = v end})

local sF = Movement:CreateSection("Fly")
sF:CreateToggle({Name = "Fly", CurrentValue = S.Fly, Callback = function(v) S.Fly = v; if v then startFly() else stopFly() end end})
sF:CreateSlider({Name = "Fly Speed", Range = {10,500}, CurrentValue = S.FlySpeed, Callback = function(v) S.FlySpeed = v end})

local sN = Movement:CreateSection("Misc")
sN:CreateToggle({Name = "Noclip", CurrentValue = S.Noclip, Callback = function(v) S.Noclip = v end})
sN:CreateToggle({Name = "Infinite Jump", CurrentValue = S.InfJump, Callback = function(v) S.InfJump = v end})
sN:CreateToggle({Name = "Full Bright", CurrentValue = S.FullBright, Callback = function(v) S.FullBright = v end})
sN:CreateToggle({Name = "Anti-AFK", CurrentValue = S.AntiAFK, Callback = function(v) S.AntiAFK = v end})

local sA = Combat:CreateSection("Aimbot")
sA:CreateToggle({Name = "Aimbot", CurrentValue = S.Aimbot, Callback = function(v) S.Aimbot = v end})
sA:CreateToggle({Name = "Wall Check", CurrentValue = S.WallCheck, Callback = function(v) S.WallCheck = v end})
sA:CreateToggle({Name = "Aimbot POV", CurrentValue = S.AimbotPOV, Callback = function(v) S.AimbotPOV = v end})
sA:CreateSlider({Name = "FOV", Range = {40,600}, CurrentValue = S.FOV, Callback = function(v) S.FOV = v end})
sA:CreateSlider({Name = "Smooth", Range = {1,10}, CurrentValue = 5, Callback = function(v) S.AimbotSmooth = v/10 end})

local sE = Visuals:CreateSection("ESP")
sE:CreateToggle({Name = "ESP (Highlight)", CurrentValue = S.ESP, Callback = function(v) S.ESP = v; if not v then clearESP() end end})

local sC = Client:CreateSection("Client")
sC:CreateButton({Name = "Unload", Callback = function() Luna:Destroy() end})
