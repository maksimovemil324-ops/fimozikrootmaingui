-- universal.lua | FIMO HUB module | Silent Aim + Rage + Fixes
-- by Fimozikroot | t.me/fimozikroot
-- Standalone or shared-window: reuses getgenv().FimoLuna / getgenv().FimoWindow when present.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local BASE = "https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/"

-- ============ EXECUTOR SHIMS (safe on every executor) ============
local G = (getgenv and getgenv()) or _G
local cloneref = cloneref or function(o) return o end
local newcclosure = newcclosure or function(f) return f end
local getrawmetatable = getrawmetatable or (debug and debug.getmetatable)
local setreadonly = setreadonly or (make_writeable and function(t, v) if v then make_writeable(t) end return t end)
local getnamecallmethod = getnamecallmethod or function() return "" end
local hookmetamethod = hookmetamethod
local mouse1click = mouse1click
local Drawing = Drawing or G.Drawing
local gethui = gethui
local CoreGui = game:GetService("CoreGui")

local function httpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(body) == "string" and #body > 100 then return body end
    if syn and syn.request then
        local o, r = pcall(function() return syn.request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 100 then return r end
    elseif http and http.request then
        local o, r = pcall(function() return http.request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 100 then return r end
    elseif request then
        local o, r = pcall(function() return request({ Url = url, Method = "GET" }).Body end)
        if o and type(r) == "string" and #r > 100 then return r end
    end
    return nil
end

local function getLuna()
    if G.FimoLuna then return G.FimoLuna end
    local src = httpGet(BASE .. "source.lua")
    if not src then error("[FIMO] source.lua download failed") end
    local fn = loadstring(src)
    if not fn then error("[FIMO] source.lua compile failed (executor size limit?)") end
    local Luna = fn()
    G.FimoLuna = Luna
    return Luna
end

-- old instance cleanup on reload
if G.FimoUniversal and G.FimoUniversal.Unload then
    pcall(G.FimoUniversal.Unload)
end

local Luna = getLuna()
local Window = G.FimoWindow
if not Window then
    Window = Luna:CreateWindow({
        Name = "FIMO HUB | Universal",
        Subtitle = "by Fimozikroot | t.me/fimozikroot",
        LogoID = "100217590927128",
        LoadingEnabled = false,
        ConfigSettings = { RootFolder = nil, ConfigFolder = "FimoHub" },
    })
    G.FimoWindow = Window
end

local S = {
    -- combat
    SilentAim = false, SilentFOV = 200, SilentAlways = false, SilentKey = Enum.KeyCode.X,
    Aimbot = false, AimbotFOV = 150, AimbotSmooth = 0.25, AimbotAlways = false, AimbotKey = Enum.KeyCode.X,
    Triggerbot = false, TriggerFOV = 14, TriggerDelay = 0.06,
    TeamCheck = true, WallCheck = true, Wallbang = false,
    TargetPart = "Head", Priority = "FOV", Prediction = false, PredictionTime = 0.12,
    -- rage
    Spinbot = false, SpinSpeed = 25, AntiAim = false, Desync = false,
    Hitbox = false, HitboxSize = 6, AutoFire = false, AutoFireDelay = 0.12,
    -- visuals
    ESP = false, ESPName = true, ESPHealth = true, ESPDistance = true, ESPBox = true,
    Tracers = false, FOVCircle = true,
    -- movement
    Speed = false, SpeedVal = 40, Jump = false, JumpVal = 120, InfJump = false,
    Noclip = false, Fly = false, FlySpeed = 100, Bhop = false,
    -- misc
    FullBright = false, AntiAFK = true, NoFog = false,
}

-- ============ HELPERS ============
local function getCam()
    return workspace.CurrentCamera
end

local function getChar()
    return LP.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = getChar()
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
end

local function isTeammate(plr)
    if not S.TeamCheck then return false end
    if not plr.Team or not LP.Team then return false end
    return plr.Team == LP.Team
end

local function alive(plr)
    local c = plr and plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local function aimPart(plr)
    local c = plr.Character
    if not c then return nil end
    if S.TargetPart == "Head" then
        return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
    elseif S.TargetPart == "Torso" then
        return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") or c:FindFirstChild("HumanoidRootPart")
    end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
end

local function partVisible(part, char)
    if S.Wallbang or not S.WallCheck then return true end
    local cam = getCam()
    if not cam then return true end
    local ok, res = pcall(function()
        return cam:GetPartsObscuringTarget({ part.Position }, { getChar(), char, cam })
    end)
    if ok and res and #res > 0 then return false end
    return true
end

local function screenCenter()
    local cam = getCam()
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

local function mouseCenter()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return screenCenter()
    end
    local p = UserInputService:GetMouseLocation()
    return Vector2.new(p.X, p.Y)
end

local Target = nil

local function predictedPos(part)
    local pos = part.Position
    if S.Prediction and part.AssemblyLinearVelocity then
        pos = pos + part.AssemblyLinearVelocity * S.PredictionTime
    end
    return pos
end

local function findTarget(fov, useMouse)
    local cam = getCam()
    if not cam then return nil end
    local center = useMouse and mouseCenter() or screenCenter()
    local best, bestScore = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and not isTeammate(plr) then
            local part = aimPart(plr)
            if part then
                local pos = predictedPos(part)
                local sp, onScreen = cam:WorldToViewportPoint(pos)
                if onScreen then
                    local dist2d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if dist2d <= fov and partVisible(part, plr.Character) then
                        local score = dist2d
                        if S.Priority == "Distance" then
                            score = (cam.CFrame.Position - pos).Magnitude
                        elseif S.Priority == "Health" then
                            local h = plr.Character:FindFirstChildOfClass("Humanoid")
                            score = h and h.Health or 100
                        end
                        if score < bestScore then
                            bestScore = score
                            best = { part = part, plr = plr, pos = pos }
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============ INPUT STATE ============
local silentDown, aimDown = false, false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == S.SilentKey then silentDown = true end
    if input.KeyCode == S.AimbotKey then aimDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == S.SilentKey then silentDown = false end
    if input.KeyCode == S.AimbotKey then aimDown = false end
end)

local function silentActive()
    return S.SilentAim and (S.SilentAlways or silentDown) and Target ~= nil
end

local function aimPos()
    if not Target or not Target.part or not Target.part.Parent then return nil end
    return predictedPos(Target.part)
end

-- ============ SILENT AIM HOOKS ============
local hooked = false
local function installHooks()
    if hooked or not hookmetamethod then return end
    hooked = true

    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if m == "ScreenPointToRay" or m == "ViewportPointToRay" then
                if silentActive() then
                    local p = aimPos()
                    local cam = getCam()
                    if p and cam then
                        local origin = cam.CFrame.Position
                        return Ray.new(origin, (p - origin).Unit * 5000)
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end)

    pcall(function()
        if not getrawmetatable then return end
        local mouse = LP:GetMouse()
        local mmt = getrawmetatable(mouse)
        if not mmt or not mmt.__index then return end
        local oldIndex = mmt.__index
        if setreadonly then setreadonly(mmt, false) end
        mmt.__index = newcclosure(function(t, k)
            if rawequal(t, mouse) and silentActive() then
                local p = aimPos()
                local cam = getCam()
                if p and cam then
                    if k == "Hit" then return p end
                    if k == "Target" then return Target.part end
                    if k == "Origin" then return cam.CFrame.Position end
                    if k == "UnitRay" then
                        local cf = CFrame.lookAt(cam.CFrame.Position, p)
                        return Ray.new(cf.Position, cf.LookVector * 5000)
                    end
                end
            end
            return oldIndex(t, k)
        end)
        if setreadonly then setreadonly(mmt, true) end
    end)
end
installHooks()

-- ============ CLICK ============
local lastClick = 0
local function click()
    if os.clock() - lastClick < S.AutoFireDelay then return end
    lastClick = os.clock()
    if mouse1click then
        local ok = pcall(mouse1click)
        if ok then return end
    end
    local cam = getCam()
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0), cam.CFrame)
        task.wait(0.03)
        VirtualUser:Button1Up(Vector2.new(0, 0), cam.CFrame)
    end)
end

-- ============ MOVEMENT FIXES ============
-- BUGFIX: old version forced WalkSpeed/JumpPower every frame -> broke custom movement games.
local cachedHum, cachedSpeed, cachedJump = nil, nil, nil
local function syncMovement()
    local hum = getHum()
    if not hum then return end
    if hum ~= cachedHum then
        cachedHum, cachedSpeed, cachedJump = hum, hum.WalkSpeed, hum.JumpPower
    end
    if S.Speed then hum.WalkSpeed = S.SpeedVal end
    if S.Jump then
        hum.UseJumpPower = true
        hum.JumpPower = S.JumpVal
    end
end
local function restoreMovement()
    local hum = getHum()
    if not hum then return end
    if cachedSpeed then hum.WalkSpeed = cachedSpeed end
    if cachedJump then hum.UseJumpPower = true; hum.JumpPower = cachedJump end
    cachedHum, cachedSpeed, cachedJump = nil, nil, nil
end

UserInputService.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local hum = getHum()
    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

-- noclip
RunService.Stepped:Connect(function()
    if not S.Noclip then return end
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

-- fly
local flyG, flyV
local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    flyG = Instance.new("BodyGyro")
    flyG.P = 9e4; flyG.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyG.CFrame = hrp.CFrame
    flyG.Parent = hrp
    flyV = Instance.new("BodyVelocity")
    flyV.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyV.Velocity = Vector3.zero
    flyV.Parent = hrp
end
local function stopFly()
    if flyG then flyG:Destroy(); flyG = nil end
    if flyV then flyV:Destroy(); flyV = nil end
end

-- ============ BUNNYHOP ============
local function doBhop()
    if not S.Bhop then return end
    local hum = getHum()
    if hum and hum.MoveDirection.Magnitude > 0.1 then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end

-- ============ HITBOX / SPINBOT ============
local hitboxOrig = {}
local function clearHitbox()
    for part, size in pairs(hitboxOrig) do
        if part and part.Parent then pcall(function() part.Size = size end) end
    end
    hitboxOrig = {}
end

local function applyHitbox()
    if not S.Hitbox then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and not isTeammate(plr) then
            local part = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                if not hitboxOrig[part] then hitboxOrig[part] = part.Size end
                local sz = S.HitboxSize
                local ns = Vector3.new(sz, sz, sz)
                if part.Size ~= ns then pcall(function() part.Size = ns end) end
            end
        end
    end
end

-- ============ ESP (Drawing fallback -> Highlight) ============
local espDraw = {}
local espHighlight = {}

local function clearESP()
    for _, d in pairs(espDraw) do
        pcall(function() d:Remove() end)
    end
    espDraw = {}
    for _, h in pairs(espHighlight) do
        if h and h.Parent then pcall(function() h:Destroy() end) end
    end
    espHighlight = {}
end

local function newDrawing(class)
    if not Drawing then return nil end
    local ok, obj = pcall(function() return Drawing.new(class) end)
    if ok then return obj end
    return nil
end

local function updateESP()
    for plr, set in pairs(espDraw) do
        if not (plr.Parent and plr.Character and alive(plr)) then
            for _, d in pairs(set) do pcall(function() d:Remove() end) end
            espDraw[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and alive(plr) and not isTeammate(plr) then
            local cam = getCam()
            local char = plr.Character
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            local root = char:FindFirstChild("HumanoidRootPart") or head
            if cam and head and root then
                local set = espDraw[plr]
                if not set then
                    set = {
                        name = newDrawing("Text"),
                        dist = newDrawing("Text"),
                        box = newDrawing("Square"),
                        tracer = newDrawing("Line"),
                    }
                    espDraw[plr] = set
                    if not Drawing then
                        local h = Instance.new("Highlight")
                        h.Name = "FimoESP"
                        h.FillColor = Color3.fromRGB(139, 149, 246)
                        h.OutlineColor = Color3.new(1, 1, 1)
                        h.FillTransparency = 0.45
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.Parent = char
                        espHighlight[plr] = h
                    end
                end

                local top = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                local bottom = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
                local onScreen = top.Z > 0
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.55
                local dist = (cam.CFrame.Position - root.Position).Magnitude
                local hum = char:FindFirstChildOfClass("Humanoid")

                if set.name then
                    set.name.Visible = onScreen and S.ESPName
                    set.name.Text = plr.Name
                    set.name.Size = 14
                    set.name.Center = true
                    set.name.Outline = true
                    set.name.Color = Color3.fromRGB(255, 255, 255)
                    set.name.Position = Vector2.new(top.X, top.Y - 16)
                end
                if set.dist then
                    set.dist.Visible = onScreen and S.ESPDistance
                    set.dist.Text = string.format("%d m", math.floor(dist))
                    set.dist.Size = 12
                    set.dist.Center = true
                    set.dist.Outline = true
                    set.dist.Color = Color3.fromRGB(200, 200, 210)
                    set.dist.Position = Vector2.new(top.X, top.Y + 2)
                end
                if set.box then
                    set.box.Visible = onScreen and S.ESPBox
                    set.box.Thickness = 1
                    set.box.Color = Color3.fromRGB(139, 149, 246)
                    set.box.Size = Vector2.new(width, height)
                    set.box.Position = Vector2.new(top.X - width / 2, top.Y)
                end
                if set.tracer then
                    set.tracer.Visible = onScreen and S.Tracers
                    set.tracer.Thickness = 1
                    set.tracer.Color = Color3.fromRGB(139, 149, 246)
                    set.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    set.tracer.To = Vector2.new(top.X, top.Y + height / 2)
                end
                if hum and set.name and S.ESPHealth then
                    set.name.Text = string.format("%s [%d]", plr.Name, math.floor(hum.Health))
                end
            end
        end
    end
end

-- ============ FOV CIRCLE ============
local fovCircle = newDrawing("Circle")
if fovCircle then
    fovCircle.Thickness = 1
    fovCircle.Filled = false
    fovCircle.NumSides = 60
    fovCircle.Color = Color3.fromRGB(139, 149, 246)
    fovCircle.Visible = false
end

-- ============ MAIN LOOP ============
local spinAngle = 0
local desyncFlip = false

RunService.RenderStepped:Connect(function(dt)
    local cam = getCam()
    if not cam then return end

    -- movement
    syncMovement()
    if S.Bhop then doBhop() end

    -- fly
    if S.Fly then
        if not flyG or not flyV then startFly() end
        if flyG and flyV then
            flyG.CFrame = cam.CFrame
            local d = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
            if d.Magnitude > 0 then d = d.Unit * S.FlySpeed end
            flyV.Velocity = d
        end
    elseif flyG or flyV then
        stopFly()
    end

    -- fullbright / fog
    if S.FullBright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    end
    if S.NoFog then Lighting.FogEnd = 100000 end

    -- targeting
    if S.SilentAim or S.Aimbot or S.AutoFire or S.Triggerbot then
        local fov = math.max(S.SilentFOV, S.AimbotFOV)
        Target = findTarget(fov, S.Aimbot)
    else
        Target = nil
    end

    -- silent aim needs nothing visible; aimbot rotates camera
    if S.Aimbot and Target and (S.AimbotAlways or aimDown) then
        local p = predictedPos(Target.part)
        local cp = cam.CFrame.Position
        local wanted = CFrame.lookAt(cp, p)
        if S.AimbotSmooth >= 1 then
            cam.CFrame = wanted
        else
            cam.CFrame = cam.CFrame:Lerp(wanted, math.clamp(S.AimbotSmooth, 0.01, 0.99))
        end
    end

    -- spinbot / antiaim / desync
    local hrp = getHRP()
    if hrp then
        if S.Spinbot then
            spinAngle = (spinAngle + dt * S.SpinSpeed * 20) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        elseif S.AntiAim then
            spinAngle = (spinAngle + dt * 720) % 360
            local jitter = math.sin(os.clock() * 12) * 45
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle + jitter), 0)
        end
        if S.Desync then
            desyncFlip = not desyncFlip
            local off = desyncFlip and Vector3.new(0, 0.4, 0) or Vector3.new(0, -0.4, 0)
            hrp.CFrame = hrp.CFrame + off
        end
    end

    -- autofire / triggerbot
    if (S.AutoFire and Target) or (S.Triggerbot and Target) then
        local p = Target.pos
        local sp = cam:WorldToViewportPoint(p)
        local center = mouseCenter()
        local px = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        local limit = S.AutoFire and 9999 or S.TriggerFOV
        if px <= limit then click() end
    end

    -- esp
    if S.ESP then updateESP() elseif next(espDraw) or next(espHighlight) then clearESP() end

    -- hitbox
    if S.Hitbox then applyHitbox() elseif next(hitboxOrig) then clearHitbox() end

    -- fov circle
    if fovCircle then
        local show = S.FOVCircle and (S.SilentAim or S.Aimbot)
        fovCircle.Visible = show
        if show then
            fovCircle.Radius = (S.SilentAim and S.SilentFOV or S.AimbotFOV) / 2
            fovCircle.Position = mouseCenter()
        end
    end
end)

-- ============ ANTI-AFK ============
LP.Idled:Connect(function()
    if not S.AntiAFK then return end
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- ============ UI ============
local Combat = Window:CreateTab({ Name = "Silent", Icon = "crosshair", ImageSource = "Material", ShowTitle = true })
local Rage = Window:CreateTab({ Name = "Rage", Icon = "local_fire_department", ImageSource = "Material", ShowTitle = true })
local Visuals = Window:CreateTab({ Name = "Visuals U", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local Movement = Window:CreateTab({ Name = "Move U", Icon = "run_circle", ImageSource = "Material", ShowTitle = true })
local Client = Window:CreateTab({ Name = "Misc U", Icon = "settings", ImageSource = "Material", ShowTitle = true })

local secAim = Combat:CreateSection("Silent Aim")
secAim:CreateToggle({ Name = "Silent Aim", CurrentValue = S.SilentAim, Callback = function(v) S.SilentAim = v end })
secAim:CreateToggle({ Name = "Always On", CurrentValue = S.SilentAlways, Callback = function(v) S.SilentAlways = v end })
secAim:CreateSlider({ Name = "FOV", Range = { 10, 800 }, CurrentValue = S.SilentFOV, Callback = function(v) S.SilentFOV = v end })
secAim:CreateDropdown({ Name = "Target Part", Options = { "Head", "Torso", "Root" }, CurrentOption = { "Head" }, Callback = function(opt) S.TargetPart = type(opt) == "table" and opt[1] or opt end })
secAim:CreateDropdown({ Name = "Priority", Options = { "FOV", "Distance", "Health" }, CurrentOption = { "FOV" }, Callback = function(opt) S.Priority = type(opt) == "table" and opt[1] or opt end })
secAim:CreateToggle({ Name = "Team Check", CurrentValue = S.TeamCheck, Callback = function(v) S.TeamCheck = v end })
secAim:CreateToggle({ Name = "Wall Check", CurrentValue = S.WallCheck, Callback = function(v) S.WallCheck = v end })
secAim:CreateToggle({ Name = "Wallbang", CurrentValue = S.Wallbang, Callback = function(v) S.Wallbang = v end })
secAim:CreateToggle({ Name = "Prediction", CurrentValue = S.Prediction, Callback = function(v) S.Prediction = v end })
secAim:CreateSlider({ Name = "Prediction ms", Range = { 0, 300 }, CurrentValue = 120, Callback = function(v) S.PredictionTime = v / 1000 end })

local secVis = Combat:CreateSection("Aimbot")
secVis:CreateToggle({ Name = "Aimbot", CurrentValue = S.Aimbot, Callback = function(v) S.Aimbot = v end })
secVis:CreateToggle({ Name = "Always On", CurrentValue = S.AimbotAlways, Callback = function(v) S.AimbotAlways = v end })
secVis:CreateSlider({ Name = "FOV", Range = { 10, 600 }, CurrentValue = S.AimbotFOV, Callback = function(v) S.AimbotFOV = v end })
secVis:CreateSlider({ Name = "Smooth", Range = { 1, 100 }, CurrentValue = 25, Callback = function(v) S.AimbotSmooth = v / 100 end })

local secTrig = Combat:CreateSection("Triggerbot")
secTrig:CreateToggle({ Name = "Triggerbot", CurrentValue = S.Triggerbot, Callback = function(v) S.Triggerbot = v end })
secTrig:CreateSlider({ Name = "Trigger FOV", Range = { 2, 200 }, CurrentValue = S.TriggerFOV, Callback = function(v) S.TriggerFOV = v end })

local secRage = Rage:CreateSection("Rage")
secRage:CreateToggle({ Name = "Auto Fire", CurrentValue = S.AutoFire, Callback = function(v) S.AutoFire = v end })
secRage:CreateSlider({ Name = "Fire Delay ms", Range = { 10, 500 }, CurrentValue = 120, Callback = function(v) S.AutoFireDelay = v / 1000 end })
secRage:CreateToggle({ Name = "Spinbot", CurrentValue = S.Spinbot, Callback = function(v) S.Spinbot = v end })
secRage:CreateSlider({ Name = "Spin Speed", Range = { 1, 100 }, CurrentValue = S.SpinSpeed, Callback = function(v) S.SpinSpeed = v end })
secRage:CreateToggle({ Name = "Anti-Aim Jitter", CurrentValue = S.AntiAim, Callback = function(v) S.AntiAim = v end })
secRage:CreateToggle({ Name = "Desync", CurrentValue = S.Desync, Callback = function(v) S.Desync = v end })
secRage:CreateToggle({ Name = "Hitbox Expander", CurrentValue = S.Hitbox, Callback = function(v) S.Hitbox = v; if not v then clearHitbox() end end })
secRage:CreateSlider({ Name = "Hitbox Size", Range = { 2, 20 }, CurrentValue = S.HitboxSize, Callback = function(v) S.HitboxSize = v end })

local secEsp = Visuals:CreateSection("ESP")
secEsp:CreateToggle({ Name = "ESP", CurrentValue = S.ESP, Callback = function(v) S.ESP = v; if not v then clearESP() end end })
secEsp:CreateToggle({ Name = "Name", CurrentValue = S.ESPName, Callback = function(v) S.ESPName = v end })
secEsp:CreateToggle({ Name = "Health", CurrentValue = S.ESPHealth, Callback = function(v) S.ESPHealth = v end })
secEsp:CreateToggle({ Name = "Distance", CurrentValue = S.ESPDistance, Callback = function(v) S.ESPDistance = v end })
secEsp:CreateToggle({ Name = "Box", CurrentValue = S.ESPBox, Callback = function(v) S.ESPBox = v end })
secEsp:CreateToggle({ Name = "Tracers", CurrentValue = S.Tracers, Callback = function(v) S.Tracers = v end })
secEsp:CreateToggle({ Name = "FOV Circle", CurrentValue = S.FOVCircle, Callback = function(v) S.FOVCircle = v end })

local secMiscVis = Visuals:CreateSection("World")
secMiscVis:CreateToggle({ Name = "Full Bright", CurrentValue = S.FullBright, Callback = function(v) S.FullBright = v end })
secMiscVis:CreateToggle({ Name = "No Fog", CurrentValue = S.NoFog, Callback = function(v) S.NoFog = v end })

local secMove = Movement:CreateSection("Movement")
secMove:CreateToggle({ Name = "Speed", CurrentValue = S.Speed, Callback = function(v) S.Speed = v; if not v then restoreMovement() end end })
secMove:CreateSlider({ Name = "Speed Value", Range = { 16, 500 }, CurrentValue = S.SpeedVal, Callback = function(v) S.SpeedVal = v end })
secMove:CreateToggle({ Name = "Jump Power", CurrentValue = S.Jump, Callback = function(v) S.Jump = v; if not v then restoreMovement() end end })
secMove:CreateSlider({ Name = "Jump Value", Range = { 50, 800 }, CurrentValue = S.JumpVal, Callback = function(v) S.JumpVal = v end })
secMove:CreateToggle({ Name = "Infinite Jump", CurrentValue = S.InfJump, Callback = function(v) S.InfJump = v end })
secMove:CreateToggle({ Name = "Bunnyhop", CurrentValue = S.Bhop, Callback = function(v) S.Bhop = v end })
secMove:CreateToggle({ Name = "Noclip", CurrentValue = S.Noclip, Callback = function(v) S.Noclip = v end })
secMove:CreateToggle({ Name = "Fly", CurrentValue = S.Fly, Callback = function(v) S.Fly = v; if v then startFly() else stopFly() end end })
secMove:CreateSlider({ Name = "Fly Speed", Range = { 10, 500 }, CurrentValue = S.FlySpeed, Callback = function(v) S.FlySpeed = v end })

local secClient = Client:CreateSection("Client")
secClient:CreateToggle({ Name = "Anti-AFK", CurrentValue = S.AntiAFK, Callback = function(v) S.AntiAFK = v end })
secClient:CreateButton({ Name = "Reset Hitbox", Callback = function() clearHitbox() end })
secClient:CreateButton({ Name = "Unload", Callback = function() if G.FimoUniversal and G.FimoUniversal.Unload then G.FimoUniversal.Unload() end end })

-- ============ UNLOAD ============
local function unload()
    S.SilentAim, S.Aimbot, S.AutoFire, S.Triggerbot = false, false, false, false
    S.ESP, S.Hitbox, S.Spinbot, S.AntiAim, S.Desync = false, false, false, false, false
    clearESP()
    clearHitbox()
    stopFly()
    restoreMovement()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    G.FimoUniversal = nil
end

G.FimoUniversal = { Settings = S, Unload = unload }

return { Settings = S }
