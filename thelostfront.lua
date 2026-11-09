-- thelostfront.lua | FIMO HUB module
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local S = {
    -- ESP
    ESP = false, ESPTeam = false, ESPName = true, ESPHealth = true, ESPDistance = true,
    ESPColorEnemy = Color3.fromRGB(255, 0, 0), ESPColorTeam = Color3.fromRGB(0, 255, 0),
    -- Aimbot
    Aimbot = false, AimbotFOV = 120, AimbotSmooth = 0.25, AimbotKey = Enum.KeyCode.X,
    AimbotTeamCheck = true, AimbotPart = "Head",
    -- Movement
    Speed = false, SpeedVal = 80, Jump = false, JumpVal = 200,
    Noclip = false, Godmode = false, -- ТУТ ИСПРАВЛЕНО ПОД MAIN.LUA
    -- Visuals
    NoFog = false, NoLeaves = false, SkyBox = false, FPSBooster = false -- ТУТ ТОЖЕ
}

local Highlights = {}
local AimKeyDown = false
local OrigSpeed, OrigJump, OrigFogEnd, OrigFogStart, OrigFogColor, OrigAmbient, OrigBright
local HiddenLeaves = {}

local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsEnemy(plr)
    if plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team then
        return LocalPlayer.Team ~= plr.Team
    end
    return true
end

local function UpdateESP()
    for plr, data in pairs(Highlights) do
        if not IsAlive(plr) then
            if data.hl then data.hl:Destroy() end
            if data.bg then data.bg:Destroy() end
            Highlights[plr] = nil
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local enemy = IsEnemy(plr)
            local show = (S.ESP and enemy) or (S.ESPTeam and not enemy)
            
            if show then
                if not Highlights[plr] then
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                    
                    local bg = Instance.new("BillboardGui")
                    bg.Size = UDim2.new(0, 200, 0, 60)
                    bg.StudsOffset = Vector3.new(0, 2.5, 0)
                    bg.AlwaysOnTop = true
                    bg.Adornee = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                    
                    local nl = Instance.new("TextLabel", bg)
                    nl.Name = "Name"
                    nl.Size = UDim2.new(1, 0, 0, 20)
                    nl.BackgroundTransparency = 1
                    nl.Font = Enum.Font.GothamBold
                    nl.TextSize = 14
                    nl.TextStrokeTransparency = 0.5
                    
                    local hlbl = Instance.new("TextLabel", bg)
                    hlbl.Name = "Health"
                    hlbl.Size = UDim2.new(1, 0, 0, 16)
                    hlbl.Position = UDim2.new(0, 0, 0, 20)
                    hlbl.BackgroundTransparency = 1
                    hlbl.TextColor3 = Color3.fromRGB(120, 255, 120)
                    hlbl.Font = Enum.Font.Gotham
                    hlbl.TextSize = 12
                    hlbl.TextStrokeTransparency = 0.5
                    
                    local dl = Instance.new("TextLabel", bg)
                    dl.Name = "Distance"
                    dl.Size = UDim2.new(1, 0, 0, 16)
                    dl.Position = UDim2.new(0, 0, 0, 36)
                    dl.BackgroundTransparency = 1
                    dl.TextColor3 = Color3.fromRGB(200, 200, 200)
                    dl.Font = Enum.Font.Gotham
                    dl.TextSize = 12
                    dl.TextStrokeTransparency = 0.5
                    
                    bg.Parent = plr.Character
                    Highlights[plr] = {hl = hl, bg = bg}
                end

                local data = Highlights[plr]
                local color = enemy and S.ESPColorEnemy or S.ESPColorTeam
                data.hl.FillColor = color
                data.hl.OutlineColor = color

                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                
                data.bg.Name.Text = plr.Name
                data.bg.Name.TextColor3 = color
                data.bg.Name.Visible = S.ESPName
                
                if hum then
                    data.bg.Health.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    data.bg.Health.Visible = S.ESPHealth
                end
                if root then
                    data.bg.Distance.Text = math.floor((root.Position - Camera.CFrame.Position).Magnitude) .. "m"
                    data.bg.Distance.Visible = S.ESPDistance
                end
            else
                if Highlights[plr] then
                    if Highlights[plr].hl then Highlights[plr].hl:Destroy() end
                    if Highlights[plr].bg then Highlights[plr].bg:Destroy() end
                    Highlights[plr] = nil
                end
            end
        end
    end
end

local function GetTarget()
    local closest, dist = nil, S.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            if not (S.AimbotTeamCheck and not IsEnemy(plr)) then
                local part = plr.Character:FindFirstChild(S.AimbotPart) or plr.Character:FindFirstChild("HumanoidRootPart")
                if part and part:IsA("BasePart") then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d < S.AimbotFOV and d < dist then
                            dist = d
                            closest = part
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function UpdateAimbot()
    if not S.Aimbot or not AimKeyDown then return end
    local target = GetTarget()
    if target then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), S.AimbotSmooth)
    end
end

local function UpdateMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not OrigSpeed then OrigSpeed = hum.WalkSpeed end
    if not OrigJump then OrigJump = hum.JumpPower end

    hum.WalkSpeed = S.Speed and S.SpeedVal or OrigSpeed
    hum.UseJumpPower = true
    hum.JumpPower = S.Jump and S.JumpVal or OrigJump

    if S.Noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    if S.Godmode and hum.Health < hum.MaxHealth then
        hum.Health = hum.MaxHealth
    end
end

local function UpdateVisuals()
    if not OrigFogEnd then
        OrigFogEnd, OrigFogStart, OrigFogColor = Lighting.FogEnd, Lighting.FogStart, Lighting.FogColor
        OrigAmbient, OrigBright = Lighting.Ambient, Lighting.Brightness
    end
    
    if S.NoFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3
    else
        Lighting.FogEnd = OrigFogEnd
        Lighting.FogStart = OrigFogStart
        Lighting.FogColor = OrigFogColor
        Lighting.Ambient = OrigAmbient
        Lighting.Brightness = OrigBright
    end

    if S.NoLeaves then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("leaf") or obj.Name:lower():find("leaves")) then
                if not HiddenLeaves[obj] then
                    HiddenLeaves[obj] = obj.Transparency
                    obj.Transparency = 1
                end
            end
        end
    else
        for obj, tr in pairs(HiddenLeaves) do
            if obj and obj.Parent then obj.Transparency = tr end
        end
        HiddenLeaves = {}
    end
end

local function ApplyFPSBoost()
    if S.FPSBooster then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        Lighting.GlobalShadows = false
    end
end

RunService.RenderStepped:Connect(function()
    pcall(UpdateESP)
    pcall(UpdateAimbot)
    pcall(UpdateMovement)
    pcall(UpdateVisuals)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == S.AimbotKey then AimKeyDown = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == S.AimbotKey then AimKeyDown = false end
end)

LocalPlayer.CharacterAdded:Connect(function()
    OrigSpeed, OrigJump = nil, nil
    Highlights = {}
    HiddenLeaves = {}
    task.wait(2)
    ApplyFPSBoost()
end)

return { Settings = S }
