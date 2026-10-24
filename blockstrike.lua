local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local S = {
    Aimbot = false, FOV = 200, AIM_KEY = Enum.KeyCode.X, AimbotSmooth = 0.25, WallCheck = true,
    ESP = false,
    Bhop = false, BhopMode = "Hold Space", BhopSpeedBoost = 0, BhopDelay = 0,
    NoRecoil = false, NoSpread = false,
    HeadSize = false, HeadSizeValue = 3, HeadTeamCheck = true,
}

-- ================= ESP =================
local EH = {}
local function clearESP()
    for m, d in pairs(EH) do
        if d.hl and d.hl.Parent then d.hl:Destroy() end
    end
    EH = {}
end
local function updateESP()
    local v = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                v[p.Character] = true
                local hl = p.Character:FindFirstChild("FimoHH")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "FimoHH"
                    hl.Parent = p.Character
                end
                hl.Enabled = true
                hl.FillColor = Color3.fromRGB(139,149,246)
                hl.OutlineColor = Color3.new(1,1,1)
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0.1
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                EH[p.Character] = {hl=hl}
            end
        end
    end
    for c, d in pairs(EH) do
        if not v[c] then
            if d.hl and d.hl.Parent then d.hl:Destroy() end
            EH[c] = nil
        end
    end
end
RunService.RenderStepped:Connect(function()
    if S.ESP then updateESP() else if next(EH) then clearESP() end end
end)

-- ================= AIMBOT =================
local AT = nil
local LTS = 0
local function getMousePos()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    return UserInputService:GetMouseLocation()
end
local function findTarget()
    local cl, sh = nil, math.huge
    local mp = getMousePos()
    local fs = {}
    for _, n in ipairs({"Characters","Players","Entities","Mobs","Enemies","NPCs"}) do
        local f = workspace:FindFirstChild(n)
        if f then table.insert(fs, f) end
    end
    local function ck(ob)
        if not ob:IsA("Model") then return end
        if Players:GetPlayerFromCharacter(ob) == LP then return end
        if ob.Name == LP.Name then return end
        if LP.Character and (ob == LP.Character or ob:IsDescendantOf(LP.Character)) then return end
        local h = ob:FindFirstChildOfClass("Humanoid")
        if h and h.Health <= 0 then return end
        local t = ob:FindFirstChild("Head") or ob:FindFirstChild("HumanoidRootPart") or ob:FindFirstChild("UpperTorso") or ob:FindFirstChild("Torso")
        if not t then return end
        local ok = true
        if S.WallCheck then
            local r = Camera:GetPartsObscuringTarget({t.Position}, {LP.Character, ob, Camera})
            if #r > 0 then ok = false end
        end
        if ok then
            local sp, os = Camera:WorldToViewportPoint(t.Position)
            if os then
                local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                if d <= S.FOV and d < sh then sh = d; cl = t end
            end
        end
    end
    for _, f in ipairs(fs) do
        for _, ob in pairs(f:GetChildren()) do ck(ob) end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then ck(p.Character) end
    end
    return cl
end
RunService.RenderStepped:Connect(function()
    if not S.Aimbot then AT = nil; return end
    local n = tick()
    if n - LTS < 0.03 then return end
    LTS = n
    AT = findTarget()
end)
local AimDown = false
UserInputService.InputBegan:Connect(function(i, gp) if gp then return end if i.KeyCode == S.AIM_KEY then AimDown = true end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == S.AIM_KEY then AimDown = false end end)
RunService:BindToRenderStep("FimoAimBS", Enum.RenderPriority.Camera.Value + 1, function()
    if not S.Aimbot or not AimDown or not AT or not AT.Parent then return end
    local cp = Camera.CFrame.Position
    local gc = CFrame.new(cp, AT.Position)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        local nc = Camera.CFrame:Lerp(gc, S.AimbotSmooth or 0.25)
        Camera.CFrame = CFrame.new(cp, cp + nc.LookVector)
    else
        Camera.CFrame = gc
    end
end)

-- ================= BHOP =================
local BLJ = 0
local function doBhop()
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if h.FloorMaterial == Enum.Material.Air then return end
    local st = h:GetState()
    if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Climbing or st == Enum.HumanoidStateType.Swimming then return end
    local n = tick()
    if n - BLJ < (S.BhopDelay or 0)/1000 + 0.01 then return end
    BLJ = n
    pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
    pcall(function() h.Jump = true end)
    pcall(function()
        local jp = h.UseJumpPower and h.JumpPower or 50
        if jp <= 0 then jp = 50 end
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(v.X, jp, v.Z)
    end)
end
RunService.Heartbeat:Connect(function()
    if not S.Bhop then return end
    if S.BhopMode == "Hold Space" then
        if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
    end
    doBhop()
    if S.BhopSpeedBoost > 0 then
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.FloorMaterial == Enum.Material.Air then
                local md = h.MoveDirection
                if md.Magnitude > 0.05 then
                    local b = (S.BhopSpeedBoost/100)*15
                    local v = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X + md.X*b*0.1, v.Y, v.Z + md.Z*b*0.1)
                end
            end
        end
    end
end)

-- ================= NO RECOIL / SPREAD =================
local RT = {}
local LRS = 0
local function scanRecoil()
    RT = {}
    local c = LP.Character
    if not c then return end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                for _, d in pairs(t:GetDescendants()) do
                    if d:IsA("NumberValue") and (d.Name:lower():find("recoil") or d.Name:lower():find("spread")) then
                        table.insert(RT, d)
                    end
                end
            end
        end
    end
    for _, d in pairs(c:GetDescendants()) do
        if d:IsA("NumberValue") and (d.Name:lower():find("recoil") or d.Name:lower():find("spread")) then
            table.insert(RT, d)
        end
    end
end
RunService.RenderStepped:Connect(function()
    if not (S.NoRecoil or S.NoSpread) then return end
    local n = tick()
    if n - LRS > 2 then
        LRS = n
        scanRecoil()
    end
    for _, o in ipairs(RT) do
        if o and o.Parent then
            local nm = o.Name:lower()
            if S.NoRecoil and nm:find("recoil") then o.Value = 0 end
            if S.NoSpread and nm:find("spread") then o.Value = 0 end
        end
    end
end)

-- ================= HEAD SIZE =================
local HC = {}
local function teamCheck(o)
    if not S.HeadTeamCheck then return false end
    local pl = Players:GetPlayerFromCharacter(o)
    if not pl then return false end
    if LP.Team and pl.Team and LP.Team == pl.Team then return true end
    local mt = LP:GetAttribute("Team")
    local tt = pl:GetAttribute("Team")
    if mt and tt and mt == tt then return true end
    return false
end
local function setHead(p, s)
    if not p or not p.Parent then return end
    if not HC[p] then HC[p] = {OS=p.Size, OT=p.Transparency, OC=p.CanCollide, OM=p.Massless} end
    p.Size = Vector3.new(s,s,s)
    p.Transparency = 0.75
    p.CanCollide = false
    p.Massless = true
end
local function resetHead(p)
    if not p then return end
    local c = HC[p]
    if not c then return end
    if p.Parent then
        pcall(function()
            p.Size = c.OS; p.Transparency = c.OT; p.CanCollide = c.OC; p.Massless = c.OM
        end)
    end
    HC[p] = nil
end
RunService.RenderStepped:Connect(function()
    if not S.HeadSize then
        for p in pairs(HC) do resetHead(p) end
        return
    end
    local s = math.clamp(S.HeadSizeValue or 3, 1, 5)
    local fs = {}
    for _, n in ipairs({"Characters","Players","Entities","Mobs","Enemies","NPCs"}) do
        local f = workspace:FindFirstChild(n)
        if f then table.insert(fs, f) end
    end
    local v = {}
    for _, f in ipairs(fs) do
        for _, o in pairs(f:GetChildren()) do
            if o:IsA("Model") then
                local iu = false
                if Players:GetPlayerFromCharacter(o) == LP then iu = true end
                if o.Name == LP.Name then iu = true end
                if LP.Character and (o == LP.Character or o:IsDescendantOf(LP.Character)) then iu = true end
                if teamCheck(o) then iu = true end
                if not iu then
                    local h = o:FindFirstChildOfClass("Humanoid")
                    if not h or h.Health > 0 then
                        local hd = o:FindFirstChild("Head")
                        if hd and hd:IsA("BasePart") then
                            setHead(hd, s)
                            v[hd] = true
                        end
                    end
                end
            end
        end
    end
    for p in pairs(HC) do
        if not v[p] then resetHead(p) end
    end
end)

-- ================= FOV CIRCLE =================
local FC = Drawing.new("Circle")
FC.Thickness = 2; FC.Filled = false; FC.Visible = false; FC.Color = Color3.fromRGB(139,149,246)
RunService.RenderStepped:Connect(function()
    if S.Aimbot then
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

-- ================= UI (Fimo Hub) =================
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()
local Window = Luna:CreateWindow({
    Name = "FIMO HUB | Block Strike",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = false,
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    KeySystem = false,
})
Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local Combat = Window:CreateTab({ Name = "Combat", Icon = "gavel", ImageSource = "Material", ShowTitle = true })
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local Client = Window:CreateTab({ Name = "Client", Icon = "settings", ImageSource = "Material", ShowTitle = true })

local sA = Combat:CreateSection("Aimbot")
sA:CreateToggle({Name = "Aimbot", CurrentValue = S.Aimbot, Callback = function(v) S.Aimbot = v end})
sA:CreateToggle({Name = "Wall Check", CurrentValue = S.WallCheck, Callback = function(v) S.WallCheck = v end})
sA:CreateSlider({Name = "FOV", Range = {40,600}, CurrentValue = S.FOV, Callback = function(v) S.FOV = v end})
sA:CreateSlider({Name = "Smooth", Range = {1,10}, CurrentValue = 5, Callback = function(v) S.AimbotSmooth = v/10 end})

local sH = Combat:CreateSection("Hitbox")
sH:CreateToggle({Name = "Head Size", CurrentValue = S.HeadSize, Callback = function(v) S.HeadSize = v end})
sH:CreateSlider({Name = "Size", Range = {1,5}, CurrentValue = S.HeadSizeValue, Callback = function(v) S.HeadSizeValue = v end})
sH:CreateToggle({Name = "Team Check", CurrentValue = S.HeadTeamCheck, Callback = function(v) S.HeadTeamCheck = v end})

local sW = Combat:CreateSection("Weapon Mods")
sW:CreateToggle({Name = "No Recoil", CurrentValue = S.NoRecoil, Callback = function(v) S.NoRecoil = v end})
sW:CreateToggle({Name = "No Spread", CurrentValue = S.NoSpread, Callback = function(v) S.NoSpread = v end})

local sE = Visuals:CreateSection("ESP")
sE:CreateToggle({Name = "ESP (Highlight)", CurrentValue = S.ESP, Callback = function(v) S.ESP = v; if not v then clearESP() end end})

local sB = Visuals:CreateSection("Bunny Hop")
sB:CreateToggle({Name = "Bunny Hop", CurrentValue = S.Bhop, Callback = function(v) S.Bhop = v end})
sB:CreateDropdown({Name = "Mode", Options = {"Hold Space","Always"}, CurrentOption = S.BhopMode, Callback = function(v) S.BhopMode = v end})
sB:CreateSlider({Name = "Boost %", Range = {0,100}, CurrentValue = S.BhopSpeedBoost, Callback = function(v) S.BhopSpeedBoost = v end})

local sC = Client:CreateSection("Client")
sC:CreateButton({Name = "Unload", Callback = function() Luna:Destroy() end})
