local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local S = {
    RustDrops = false, RustSleepers = false, RustGuards = false, RustPlayers = false,
    BringPlayers = false, BringDrops = false, BringRange = 500, BringSpeed = 2,
    Aimbot = false, WallCheck = true, FOV = 200, AIM_KEY = Enum.KeyCode.X, AimbotSmooth = 0.25,
}

-- ================= ESP =================
local RH = {}
local function shouldHighlight(o)
    if not (o:IsA("Model") or o:IsA("BasePart")) then return false, nil end
    local df = workspace:FindFirstChild("Drops")
    if df and o:IsDescendantOf(df) then return S.RustDrops, Color3.fromRGB(255,220,80) end
    local sf = workspace:FindFirstChild("Sleepers")
    if sf and o:IsDescendantOf(sf) then return S.RustSleepers, Color3.fromRGB(255,80,80) end
    local gf = workspace:FindFirstChild("Guards")
    if gf and o:IsDescendantOf(gf) then return S.RustGuards, Color3.fromRGB(255,120,40) end
    if o:IsA("Model") then
        local h = o:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            local is = sf and o:IsDescendantOf(sf)
            local id = df and o:IsDescendantOf(df)
            local ig = gf and o:IsDescendantOf(gf)
            if not is and not id and not ig then return S.RustPlayers, Color3.fromRGB(80,220,255) end
        end
    end
    return false, nil
end
local function updateRustESP()
    if not (S.RustDrops or S.RustSleepers or S.RustGuards or S.RustPlayers) then
        for o, d in pairs(RH) do if d.hl and d.hl.Parent then d.hl:Destroy() end end
        RH = {}
        return
    end
    local v = {}
    local function proc(o)
        if not (o:IsA("Model") or o:IsA("BasePart")) then return end
        local en, cl = shouldHighlight(o)
        if not en or not cl then return end
        v[o] = true
        local hl = o:FindFirstChild("FimoRust")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "FimoRust"
            hl.Parent = o
        end
        hl.Enabled = true
        hl.FillColor = cl
        hl.OutlineColor = cl:Lerp(Color3.new(1,1,1),0.5)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        RH[o] = {hl=hl}
    end
    if S.RustDrops then
        local d = workspace:FindFirstChild("Drops")
        if d then for _, o in pairs(d:GetChildren()) do proc(o) end end
    end
    if S.RustSleepers then
        local s = workspace:FindFirstChild("Sleepers")
        if s then for _, o in pairs(s:GetChildren()) do proc(o) end end
    end
    if S.RustGuards then
        local g = workspace:FindFirstChild("Guards")
        if g then for _, o in pairs(g:GetChildren()) do proc(o) end end
    end
    if S.RustPlayers then
        for _, o in pairs(workspace:GetChildren()) do
            if o:IsA("Model") then
                local h = o:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 and o ~= LP.Character then
                    local sk = false
                    for _, fn in ipairs({"Drops","Sleepers","Guards"}) do
                        local f = workspace:FindFirstChild(fn)
                        if f and o:IsDescendantOf(f) then sk = true; break end
                    end
                    if not sk then proc(o) end
                end
            end
        end
    end
    for o, d in pairs(RH) do
        if not v[o] then
            if d.hl and d.hl.Parent then d.hl:Destroy() end
            RH[o] = nil
        end
    end
end
RunService.RenderStepped:Connect(updateRustESP)

-- ================= BRING =================
local BLT = 0
local function getMyPos()
    local c = LP.Character
    if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    return h and h.Position
end
local function bringPlayers(mp)
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character then
            local h = pl.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (mp - hrp.Position).Magnitude
                    if d > 3 and d < S.BringRange then
                        pcall(function() h:MoveTo(mp) end)
                    end
                end
            end
        end
    end
end
local function bringModel(m, mp)
    if not m or not m.Parent then return false end
    local pr = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
    if not pr then return false end
    local a = math.random() * math.pi * 2
    local of = Vector3.new(math.cos(a)*4, 2, math.sin(a)*4)
    pcall(function() m:PivotTo(CFrame.new(mp + of)) end)
    return true
end
local function bringDrops(mp)
    local f = workspace:FindFirstChild("Drops")
    if not f then return end
    for _, o in pairs(f:GetChildren()) do
        if o:IsA("Model") or o:IsA("BasePart") then
            local ps
            if o:IsA("Model") then
                local pr = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)
                ps = pr and pr.Position
            else
                ps = o.Position
            end
            if ps then
                local d = (mp - ps).Magnitude
                if d > 3 and d < S.BringRange then
                    if o:IsA("Model") then
                        bringModel(o, mp)
                    else
                        pcall(function()
                            o.CFrame = CFrame.new(mp + Vector3.new(math.random()*4-2,2,math.random()*4-2))
                            o.AssemblyLinearVelocity = Vector3.zero
                        end)
                    end
                end
            end
        end
    end
end
RunService.Heartbeat:Connect(function()
    if not (S.BringPlayers or S.BringDrops) then return end
    local n = tick()
    local iv = 1/math.max(S.BringSpeed or 2, 0.5)
    if n - BLT < iv then return end
    BLT = n
    local mp = getMyPos()
    if not mp then return end
    if S.BringPlayers then bringPlayers(mp) end
    if S.BringDrops then bringDrops(mp) end
end)

-- ================= AIMBOT =================
local AT, LTS = nil, 0
local function getMousePos()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
    return UserInputService:GetMouseLocation()
end
local function findTarget()
    local cl, sh = nil, math.huge
    local mp = getMousePos()
    local function ck(ob)
        if not ob:IsA("Model") then return end
        if ob == LP.Character then return end
        local h = ob:FindFirstChildOfClass("Humanoid")
        if h and h.Health <= 0 then return end
        local t = ob:FindFirstChild("Head") or ob:FindFirstChild("HumanoidRootPart")
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
    local g = workspace:FindFirstChild("Guards")
    if g then for _, ob in pairs(g:GetChildren()) do ck(ob) end end
    local s = workspace:FindFirstChild("Sleepers")
    if s then for _, ob in pairs(s:GetChildren()) do ck(ob) end end
    for _, ob in pairs(workspace:GetChildren()) do
        if ob:IsA("Model") and ob ~= LP.Character then ck(ob) end
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
RunService:BindToRenderStep("FimoAimRL", Enum.RenderPriority.Camera.Value + 1, function()
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

-- ================= UI =================
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()
local Window = Luna:CreateWindow({
    Name = "FIMO HUB | Rust Lite",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = false,
    ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    KeySystem = false,
})
Window:CreateHomeTab({ SupportedExecutors = {"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"}, DiscordInvite = "fimozikroot", Icon = 1 })

local Visuals = Window:CreateTab({ Name = "Rust ESP", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local BringTab = Window:CreateTab({ Name = "Bring", Icon = "open_with", ImageSource = "Material", ShowTitle = true })
local Combat = Window:CreateTab({ Name = "Combat", Icon = "gavel", ImageSource = "Material", ShowTitle = true })
local Client = Window:CreateTab({ Name = "Client", Icon = "settings", ImageSource = "Material", ShowTitle = true })

local sR = Visuals:CreateSection("Rust Lite ESP")
sR:CreateToggle({Name = "Drops", CurrentValue = S.RustDrops, Callback = function(v) S.RustDrops = v end})
sR:CreateToggle({Name = "Sleepers", CurrentValue = S.RustSleepers, Callback = function(v) S.RustSleepers = v end})
sR:CreateToggle({Name = "Guards", CurrentValue = S.RustGuards, Callback = function(v) S.RustGuards = v end})
sR:CreateToggle({Name = "Players", CurrentValue = S.RustPlayers, Callback = function(v) S.RustPlayers = v end})

local sB = BringTab:CreateSection("Bring")
sB:CreateToggle({Name = "Bring Players", CurrentValue = S.BringPlayers, Callback = function(v) S.BringPlayers = v end})
sB:CreateToggle({Name = "Bring Drops", CurrentValue = S.BringDrops, Callback = function(v) S.BringDrops = v end})
sB:CreateSlider({Name = "Range", Range = {50,5000}, CurrentValue = S.BringRange, Callback = function(v) S.BringRange = v end})
sB:CreateSlider({Name = "Speed (Hz)", Range = {1,10}, CurrentValue = S.BringSpeed, Callback = function(v) S.BringSpeed = v end})

local sA = Combat:CreateSection("Aimbot")
sA:CreateToggle({Name = "Aimbot", CurrentValue = S.Aimbot, Callback = function(v) S.Aimbot = v end})
sA:CreateToggle({Name = "Wall Check", CurrentValue = S.WallCheck, Callback = function(v) S.WallCheck = v end})
sA:CreateSlider({Name = "FOV", Range = {40,600}, CurrentValue = S.FOV, Callback = function(v) S.FOV = v end})

local sC = Client:CreateSection("Client")
sC:CreateButton({Name = "Unload", Callback = function() Luna:Destroy() end})
