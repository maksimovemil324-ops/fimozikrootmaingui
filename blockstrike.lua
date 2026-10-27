-- blockstrike.lua | FIMO HUB module | by Fimozikroot
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local S = {
    Aimbot = false, AimbotFOV = 120, AimbotSmooth = 0.25, AimbotKey = Enum.KeyCode.X,
    AimbotTeamCheck = true, AimbotWallCheck = true, AimbotPart = "Head",
    Triggerbot = false, TriggerbotDelay = 0.05,
    ESP = false, ESPName = true, ESPHealth = true, ESPDistance = true, ESPTeamColor = true,
    WorldESP = false, WorldESPColor = Color3.fromRGB(255, 220, 80),
    Speed = false, SpeedVal = 80, Jump = false, JumpVal = 200,
    Fly = false, FlySpeed = 100, Noclip = false, Bhop = false,
    NoRecoil = false, NoSpread = false, Fullbright = false, AntiAFK = false
}

local Highlights = {}
local WorldHighlights = {}
local FlyBV, FlyBG
local OrigSpeed, OrigJump, OrigAmbient, OrigBright, OrigOutdoor
local AimKeyDown = false
local TriggerCooldown = 0
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Безопасная проверка на жизнь
local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function GetTarget()
    local closest, dist = nil, S.AimbotFOV
    local center = isMobile and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) or Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            if not (S.AimbotTeamCheck and plr.Team == LocalPlayer.Team) then
                local part = plr.Character:FindFirstChild(S.AimbotPart) or plr.Character:FindFirstChild("HumanoidRootPart")
                if part and part:IsA("BasePart") then
                    -- Проверка на видимость (безопасная)
                    local visible = true
                    if S.AimbotWallCheck then
                        local ray = Ray.new(Camera.CFrame.Position, part.Position - Camera.CFrame.Position)
                        local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, part.Parent})
                        visible = (hit == nil or hit:IsDescendantOf(part.Parent))
                    end
                    
                    if visible then
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
    end
    return closest
end

-- 1. ESP
local function UpdateESP()
    if not S.ESP then
        for plr, data in pairs(Highlights) do
            if data.hl then data.hl:Destroy() end
            if data.bg then data.bg:Destroy() end
            Highlights[plr] = nil
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) and plr.Character then
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
            local color = (S.ESPTeamColor and plr.Team) and plr.Team.TeamColor.Color or Color3.fromRGB(255, 60, 60)
            data.hl.FillColor = color
            data.hl.OutlineColor = color
            
            local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if head then data.bg.Adornee = head end
            
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
        end
    end
end

-- 2. Aimbot
local function UpdateAimbot()
    if not S.Aimbot or not AimKeyDown then return end
    local target = GetTarget()
    if target then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), S.AimbotSmooth)
    end
end

-- 3. Movement
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

    if S.Bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- 4. Fly
local function UpdateFly()
    if not S.Fly then
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not FlyBV then
        FlyBV = Instance.new("BodyVelocity", root)
        FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        FlyBV.Velocity = Vector3.zero
    end
    if not FlyBG then
        FlyBG = Instance.new("BodyGyro", root)
        FlyBG.P = 9e4
        FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    end
    
    local move = Vector3.zero
    local cam = Camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
    
    if move.Magnitude > 0 then move = move.Unit * S.FlySpeed end
    FlyBV.Velocity = move
    FlyBG.CFrame = cam
end

-- 5. Misc
local function UpdateMisc()
    if S.NoRecoil or S.NoSpread then
        local char = LocalPlayer.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("NumberValue") then
                    local n = string.lower(obj.Name)
                    if S.NoRecoil and (string.find(n, "recoil") or string.find(n, "kick")) then obj.Value = 0 end
                    if S.NoSpread and string.find(n, "spread") then obj.Value = 0 end
                end
            end
        end
    end

    if not OrigAmbient then OrigAmbient = Lighting.Ambient OrigBright = Lighting.Brightness end
    if S.Fullbright then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = OrigAmbient
        Lighting.Brightness = OrigBright
    end
end

-- Запуск в защищенном потоке (чтобы скрипт не крашился)
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        pcall(UpdateESP)
        pcall(UpdateAimbot)
        pcall(UpdateMovement)
        pcall(UpdateFly)
        pcall(UpdateMisc)
    end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == S.AimbotKey then AimKeyDown = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == S.AimbotKey then AimKeyDown = false end
end)

-- Anti-AFK (через VirtualUser, если он есть)
local vUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            vUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(1)
            vUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end)
    end
end)

return { Settings = S }
