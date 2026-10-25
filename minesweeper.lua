local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua", true))()

local Window = Luna:CreateWindow({
    Name = "FIMO HUB | Minesweeper",
    Subtitle = "by Fimozikroot | t.me/fimozikroot",
    LogoID = "100217590927128",
    LoadingEnabled = false,
    KeySystem = false,
})
Window:CreateHomeTab({ SupportedExecutors = {"Xeno","Wave","Delta","Solara"}, DiscordInvite = "fimozikroot", Icon = 1 })

local VisTab = Window:CreateTab({ Name = "Visuals & Bot", Icon = "visibility", ImageSource = "Material", ShowTitle = true })
local S = { ESP = false, AutoWalk = false }
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "FimoESP"
local grid, W, H, xToCol, zToRow = {}, 0, 0, {}, {}

local function initGrid()
    grid = {} xToCol = {} zToRow = {}
    local flag = workspace:FindFirstChild("Flag")
    local parts = flag and flag:FindFirstChild("Parts") and flag.Parts:GetChildren()
    if not parts then return end
    local xCoords, zCoords = {}, {}
    for _, p in ipairs(parts) do xCoords[math.floor(p.Position.X+0.5)] = true zCoords[math.floor(p.Position.Z+0.5)] = true end
    local sortedX, sortedZ = {}, {}
    for x in pairs(xCoords) do table.insert(sortedX, x) end table.sort(sortedX)
    for z in pairs(zCoords) do table.insert(sortedZ, z) end table.sort(sortedZ)
    for col, x in ipairs(sortedX) do xToCol[x] = col end
    for row, z in ipairs(sortedZ) do zToRow[z] = row end
    W = #sortedX H = #sortedZ
    for col = 1, W do grid[col] = {} for row = 1, H do grid[col][row] = { part = nil, isOpened = false, isFlagged = false, value = 0, col = col, row = row } end end
    for _, p in ipairs(parts) do
        local x = math.floor(p.Position.X+0.5) local z = math.floor(p.Position.Z+0.5)
        local col = xToCol[x] local row = zToRow[z]
        if col and row then grid[col][row].part = p end
    end
end

local function hasServerFlag(p) if not p then return false end for _, c in ipairs(p:GetChildren()) do if c:IsA("Model") then return true end end return false end

local function getFlags()
    for c = 1, W do
        for r = 1, H do
            local cell = grid[c][r]
            if cell.part then
                local isOpened = cell.part:FindFirstChild("NumberGui") ~= nil
                local isFlagged = hasServerFlag(cell.part)
                local value = 0
                if isOpened then local label = cell.part.NumberGui:FindFirstChild("TextLabel") value = tonumber(label and label.Text) or 0 end
                cell.isOpened = isOpened cell.isFlagged = isFlagged cell.value = value
            end
        end
    end
end

local function solve()
    local safe, bombs = {}, {}
    for c = 1, W do
        for r = 1, H do
            local cell = grid[c][r]
            if cell.isOpened and cell.value > 0 then
                local unopened = {} local flagged = 0
                for dc = -1, 1 do
                    for dr = -1, 1 do
                        if not (dc == 0 and dr == 0) then
                            local nc, nr = c + dc, r + dr
                            if nc >= 1 and nc <= W and nr >= 1 and nr <= H then
                                local n = grid[nc][nr]
                                if n.isFlagged then flagged = flagged + 1 elseif not n.isOpened then table.insert(unopened, n) end
                            end
                        end
                    end
                end
                if #unopened > 0 then
                    if cell.value == flagged + #unopened then for _, n in ipairs(unopened) do bombs[n.col.."_"..n.row] = n end
                    elseif cell.value == flagged then for _, n in ipairs(unopened) do safe[n.col.."_"..n.row] = n end end
                end
            end
        end
    end
    return safe, bombs
end

local function updateESP(safe, bombs)
    espFolder:ClearAllChildren()
    if not S.ESP and not S.AutoWalk then return end
    for k, v in pairs(safe) do 
        if v.part then 
            local b = Instance.new("SelectionBox") 
            b.Adornee = v.part 
            b.Color3 = Color3.new(0,1,0) 
            b.LineThickness = 0.1
            b.Parent = espFolder 
        end 
    end
    for k, v in pairs(bombs) do 
        if v.part then 
            local b = Instance.new("SelectionBox") 
            b.Adornee = v.part 
            b.Color3 = Color3.new(1,0,0) 
            b.LineThickness = 0.1
            b.Parent = espFolder 
        end 
    end
end

local function walkTo(part)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.WalkSpeed = 30
    local targetPos = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
    hum:MoveTo(targetPos)
    local startT = os.clock()
    while (root.Position - targetPos).Magnitude > 1.0 and S.AutoWalk do
        if os.clock() - startT > 2 then break end
        task.wait()
        hum:MoveTo(targetPos)
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if not S.ESP and not S.AutoWalk then espFolder:ClearAllChildren() continue end
        if not workspace:FindFirstChild("Flag") then continue end
        if W == 0 then initGrid() end
        if W == 0 then continue end
        
        getFlags()
        local safe, bombs = solve()
        updateESP(safe, bombs)
        
        if S.AutoWalk then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bestCell = nil
                local minDist = math.huge
                for k, v in pairs(safe) do
                    if v.part and not v.isOpened and not hasServerFlag(v.part) then
                        local d = (v.part.Position - root.Position).Magnitude
                        if d < minDist then minDist = d bestCell = v end
                    end
                end
                
                if not bestCell then
                    for c = 1, W do for r = 1, H do
                        local cell = grid[c][r]
                        if cell.part and not cell.isOpened and not cell.isFlagged then
                            local d = (cell.part.Position - root.Position).Magnitude
                            if d < minDist then minDist = d bestCell = cell end
                        end
                    end end
                end
                
                if bestCell and bestCell.part then
                    walkTo(bestCell.part)
                    task.wait(0.3)
                end
            end
        end
    end
end)

VisTab:CreateToggle({ Name = "ESP (Зеленый = Безопасно, Красный = Бомба)", CurrentValue = false, Callback = function(v) S.ESP = v end })
VisTab:CreateToggle({ Name = "Auto Walk (Бот ходит по безопасным)", CurrentValue = false, Callback = function(v) 
    S.AutoWalk = v 
    if v then Luna:Notification({Title="Bot",Content="Auto Walk ON",Icon="info",ImageSource="Material"}) end
end })
