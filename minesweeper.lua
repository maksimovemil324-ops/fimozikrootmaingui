local Players=game:GetService("Players")local ReplicatedStorage=game:GetService("ReplicatedStorage")local UserInputService=game:GetService("UserInputService")local RunService=game:GetService("RunService")local TweenService=game:GetService("TweenService")local CoreGui=game:GetService("CoreGui")local player=Players.LocalPlayer
local autoFlagActive,autoWalkActive,espActive=false,false,false
local customWalkSpeed,customJumpPower,infiniteJump,flying,flySpeed=25,50,false,false,50
local flyGyro,flyVelocity
local espSafeColor,espBombColor=Color3.fromRGB(0,0,255),Color3.fromRGB(255,0,0)
local espUncertainLow,espUncertainMed,espUncertainHigh=Color3.fromRGB(255,215,0),Color3.fromRGB(255,165,0),Color3.fromRGB(220,20,60)
local grid,W,H,xToCol,zToRow,localFlags,deducedBombs={},0,0,{},{},{},{}
local AutoWalkToggle,AutoFlagToggle,EspToggle,FlyToggle
local espFolder=workspace:FindFirstChild("BotESPFolder")or Instance.new("Folder",workspace)
espFolder.Name="BotESPFolder"
local function notify(t,x)pcall(function()game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=x,Duration=3})end)end
local function hasServerFlag(p)if not p then return false end for _,c in ipairs(p:GetChildren())do if c:IsA("Model")then return true end end return false end
local function checkFlagged(p)return localFlags[p]==true or deducedBombs[p]==true end
local function checkBlocked(p)return localFlags[p]==true or deducedBombs[p]==true or hasServerFlag(p)end
local function clearESP()espFolder:ClearAllChildren()end
local function updateESP(safeTiles,deducedBombs,borderProbabilities)clearESP()if not espActive then return end for part in pairs(deducedBombs)do if part and part.Parent then local box=Instance.new("SelectionBox")box.Adornee=part box.Color3=espBombColor box.LineThickness=0.06 box.SurfaceColor3=espBombColor box.SurfaceTransparency=0.45 box.Parent=espFolder end end for _,cell in pairs(safeTiles)do if cell.part and cell.part.Parent then local box=Instance.new("SelectionBox")box.Adornee=cell.part box.Color3=espSafeColor box.LineThickness=0.06 box.SurfaceColor3=espSafeColor box.SurfaceTransparency=0.45 box.Parent=espFolder end end for part,P in pairs(borderProbabilities)do if part and part.Parent then local color=espUncertainMed if P<0.35 then color=espUncertainLow elseif P>0.65 then color=espUncertainHigh end local box=Instance.new("SelectionBox")box.Adornee=part box.Color3=color box.LineThickness=0.05 box.SurfaceColor3=color box.SurfaceTransparency=0.6 box.Parent=espFolder local bb=Instance.new("BillboardGui")bb.Size=UDim2.new(0,100,0,40)bb.AlwaysOnTop=true bb.Adornee=part bb.StudsOffset=Vector3.new(0,3,0)local label=Instance.new("TextLabel")label.Size=UDim2.new(1,0,1,0)label.BackgroundTransparency=1 label.TextSize=26 label.TextColor3=color label.Font=Enum.Font.GothamBold label.TextStrokeTransparency=0 label.TextStrokeColor3=Color3.fromRGB(0,0,0)label.Text=string.format("%.0f%%",P*100)label.Parent=bb bb.Parent=espFolder end end end
local function initGrid()grid={}xToCol={}zToRow={}localFlags={}deducedBombs={}clearESP()local flag=workspace:FindFirstChild("Flag")local parts=flag and flag:FindFirstChild("Parts")and flag.Parts:GetChildren()if not parts then return end local xCoords,zCoords={},{}for _,p in ipairs(parts)do xCoords[math.floor(p.Position.X+0.5)]=true zCoords[math.floor(p.Position.Z+0.5)]=true end local sortedX,sortedZ={},{}for x in pairs(xCoords)do table.insert(sortedX,x)end table.sort(sortedX)for z in pairs(zCoords)do table.insert(sortedZ,z)end table.sort(sortedZ)for col,x in ipairs(sortedX)do xToCol[x]=col end for row,z in ipairs(sortedZ)do zToRow[z]=row end W=#sortedX H=#sortedZ for col=1,W do grid[col]={}for row=1,H do grid[col][row]={part=nil,isOpened=false,isFlagged=false,isBlocked=false,value=0,col=col,row=row}end end for _,p in ipairs(parts)do local x=math.floor(p.Position.X+0.5)local z=math.floor(p.Position.Z+0.5)local col=xToCol[x]local row=zToRow[z]if col and row then grid[col][row].part=p end end for col=1,W do for row=1,H do local cell=grid[col][row]if cell.part and hasServerFlag(cell.part)then deducedBombs[cell.part]=true cell.isFlagged=true cell.isBlocked=true end end end print("Grid mapped: "..W.."x"..H)end
local function checkGridValid()if W==0 or H==0 then return false end for col=1,W do for row=1,H do local cell=grid[col][row]if not cell.part or not cell.part:IsDescendantOf(workspace)then return false end end end return true end
local function scanBoard()local state={}for col=1,W do state[col]={}for row=1,H do local cell=grid[col][row]local isOpened,value,isFlagged,isBlocked=false,0,false,false if cell.part then isOpened=cell.part:FindFirstChild("NumberGui")~=nil if isOpened then local label=cell.part.NumberGui:FindFirstChild("TextLabel")local text=label and label.Text or ""value=tonumber(text)or 0 end isFlagged=checkFlagged(cell.part)isBlocked=checkBlocked(cell.part)end state[col][row]={isOpened=isOpened,value=value,isFlagged=isFlagged,isBlocked=isBlocked}end end return state end
local function getCurrentPlayerGrid()local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart")if not root then return nil,nil end local nearestCol,nearestRow=nil,nil local minDist=math.huge for col=1,W do for row=1,H do local cell=grid[col][row]if cell.part then local dist=(cell.part.Position-root.Position).Magnitude if dist<minDist then minDist=dist nearestCol=col nearestRow=row end end end end return nearestCol,nearestRow end
local function findPath(startCol,startRow,targetCol,targetRow)local queue={{startCol,startRow,{}}}local visited={}visited[startCol.."_"..startRow]=true while #queue>0 do local curr=table.remove(queue,1)local c,r,path=curr[1],curr[2],curr[3]if c==targetCol and r==targetRow then return path end local dirs={{1,0},{-1,0},{0,1},{0,-1}}for _,dir in ipairs(dirs)do local nc=c+dir[1]local nr=r+dir[2]local key=nc.."_"..nr if nc>=1 and nc<=W and nr>=1 and nr<=H and not visited[key]then local neighbor=grid[nc][nr]local isFlaggedOnServer=hasServerFlag(neighbor.part)if neighbor.isOpened or isFlaggedOnServer or(nc==targetCol and nr==targetRow)then visited[key]=true local newPath={}for _,p in ipairs(path)do table.insert(newPath,p)end table.insert(newPath,neighbor.part)table.insert(queue,{nc,nr,newPath})end end end end return nil end
local function getConnectedComponent(startCol,startRow)local queue={{startCol,startRow}}local visited={}visited[startCol.."_"..startRow]=true local component={}while #queue>0 do local curr=table.remove(queue,1)local c,r=curr[1],curr[2]table.insert(component,grid[c][r])local dirs={{1,0},{-1,0},{0,1},{0,-1}}for _,dir in ipairs(dirs)do local nc=c+dir[1]local nr=r+dir[2]local key=nc.."_"..nr if nc>=1 and nc<=W and nr>=1 and nr<=H and not visited[key]then local neighbor=grid[nc][nr]local isFlaggedOnServer=hasServerFlag(neighbor.part)if neighbor.isOpened or isFlaggedOnServer then visited[key]=true table.insert(queue,{nc,nr})end end end end return component end
local function getLocalGuessCandidates(pCol,pRow)local component=getConnectedComponent(pCol,pRow)local candidates={}local seen={}for _,cell in ipairs(component)do local dirs={{1,0},{-1,0},{0,1},{0,-1},{1,1},{-1,1},{1,-1},{-1,-1}}for _,dir in ipairs(dirs)do local nc=cell.col+dir[1]local nr=cell.row+dir[2]if nc>=1 and nc<=W and nr>=1 and nr<=H then local neighbor=grid[nc][nr]if not neighbor.isOpened and not neighbor.isBlocked then local key=nc.."_"..nr if not seen[key]then seen[key]=true table.insert(candidates,neighbor)end end end end end return candidates end local function solveEquations(safeTiles,deducedBombs,borderProbabilities)
local clues={}
local borderMap={}
local borderList={}
for col=1,W do
for row=1,H do
local cell=grid[col][row]
if cell.isOpened and cell.value>0 then
local unopened={}
local flaggedCount=0
for dc=-1,1 do
for dr=-1,1 do
if not(dc==0 and dr==0)then
local nc=col+dc
local nr=row+dr
if nc>=1 and nc<=W and nr>=1 and nr<=H then
local nCell=grid[nc][nr]
if nCell.isFlagged then
flaggedCount=flaggedCount+1
elseif not nCell.isOpened then
table.insert(unopened,nCell)
end
end
end
end
end
if #unopened>0 then
table.insert(clues,{cell=cell,unopened=unopened,target=cell.value-flaggedCount})
for _,nCell in ipairs(unopened)do
if not borderMap[nCell]then
borderMap[nCell]=true
table.insert(borderList,nCell)
end
end
end
end
end
end
if #borderList==0 then return end
local components={}
local visitedClues={}
local visitedVars={}
for _,clue in ipairs(clues)do
if not visitedClues[clue]then
local compClues={}
local compVars={}
local queue={clue}
visitedClues[clue]=true
while #queue>0 do
local currClue=table.remove(queue,1)
table.insert(compClues,currClue)
for _,nCell in ipairs(currClue.unopened)do
if not visitedVars[nCell]then
visitedVars[nCell]=true
table.insert(compVars,nCell)
for _,otherClue in ipairs(clues)do
if not visitedClues[otherClue]then
local contains=false
for _,c in ipairs(otherClue.unopened)do
if c==nCell then contains=true break end
end
if contains then
visitedClues[otherClue]=true
table.insert(queue,otherClue)
end
end
end
end
end
end
table.insert(components,{clues=compClues,vars=compVars})
end
end
for _,comp in ipairs(components)do
local vars=comp.vars
local compClues=comp.clues
if #vars<=20 then
local solutions={}
local currentAssignment={}
local function backtrack(varIndex)
if varIndex>#vars then
for _,clue in ipairs(compClues)do
local sum=0
for _,nCell in ipairs(clue.unopened)do
sum=sum+(currentAssignment[nCell]or 0)
end
if sum~=clue.target then return end
end
local sol={}
for k,v in pairs(currentAssignment)do
sol[k]=v
end
table.insert(solutions,sol)
return
end
local currentVar=vars[varIndex]
for _,clue in ipairs(compClues)do
local sum=0
local unassigned=0
for _,nCell in ipairs(clue.unopened)do
local assign=currentAssignment[nCell]
if assign then
sum=sum+assign
else
unassigned=unassigned+1
end
end
if sum>clue.target or sum+unassigned<clue.target then
return
end
end
currentAssignment[currentVar]=0
backtrack(varIndex+1)
currentAssignment[currentVar]=1
backtrack(varIndex+1)
currentAssignment[currentVar]=nil
end
backtrack(1)
if #solutions>0 then
for _,var in ipairs(vars)do
local bombCount=0
for _,sol in ipairs(solutions)do
if sol[var]==1 then
bombCount=bombCount+1
end
end
local P=bombCount/#solutions
if P==0 then
safeTiles[var.col.."_"..var.row]=var
elseif P==1 then
deducedBombs[var.part]=true
else
borderProbabilities[var.part]=P
end
end
end
end
end
end
local function updateDeductions()
local state1=scanBoard()
task.wait(0.05)
local state2=scanBoard()
local stable=true
for col=1,W do
for row=1,H do
local c1=state1[col][row]
local c2=state2[col][row]
if c1.isOpened~=c2.isOpened or c1.value~=c2.value or c1.isFlagged~=c2.isFlagged or c1.isBlocked~=c2.isBlocked then
stable=false
break
end
end
if not stable then break end
end
if not stable then
return false
end
for col=1,W do
for row=1,H do
local cell=grid[col][row]
local st=state1[col][row]
cell.isOpened=st.isOpened
cell.value=st.value
cell.isFlagged=st.isFlagged
cell.isBlocked=st.isBlocked
end
end
local safeTiles={}
local borderProbabilities={}
local deducedNewBomb=false
local totalUnopened={}
local totalFlagged=0
for col=1,W do
for row=1,H do
local cell=grid[col][row]
if cell.part then
if cell.isFlagged then
totalFlagged=totalFlagged+1
elseif not cell.isOpened then
table.insert(totalUnopened,cell)
end
end
end
end
local minesVal=ReplicatedStorage:FindFirstChild("Info")and ReplicatedStorage.Info:FindFirstChild("Mines")and ReplicatedStorage.Info.Mines.Value or 0
local remainingMines=minesVal-totalFlagged
if #totalUnopened>0 then
if #totalUnopened==remainingMines then
for _,cell in ipairs(totalUnopened)do
if not deducedBombs[cell.part]then
print("Global Constraint: Deduced bomb at ("..cell.col..", "..cell.row..")")
deducedBombs[cell.part]=true
cell.isFlagged=true
cell.isBlocked=true
deducedNewBomb=true
end
end
elseif remainingMines==0 then
for _,cell in ipairs(totalUnopened)do
safeTiles[cell.col.."_"..cell.row]=cell
end
end
end
if not deducedNewBomb then
solveEquations(safeTiles,deducedBombs,borderProbabilities)
for col=1,W do
for row=1,H do
local cell=grid[col][row]
if cell.isOpened and cell.value>0 then
local neighbors={}
local flaggedNeighbors=0
local unopenedNeighbors={}
for dc=-1,1 do
for dr=-1,1 do
if not(dc==0 and dr==0)then
local nc=col+dc
local nr=row+dr
if nc>=1 and nc<=W and nr>=1 and nr<=H then
local nCell=grid[nc][nr]
table.insert(neighbors,nCell)
if nCell.isFlagged then
flaggedNeighbors=flaggedNeighbors+1
elseif not nCell.isOpened then
table.insert(unopenedNeighbors,nCell)
end
end
end
end
end
if cell.value-flaggedNeighbors==#unopenedNeighbors and #unopenedNeighbors>0 then
for _,nCell in ipairs(unopenedNeighbors)do
if not deducedBombs[nCell.part]then
print("Deduced bomb at ("..nCell.col..", "..nCell.row..")")
deducedBombs[nCell.part]=true
nCell.isFlagged=true
nCell.isBlocked=true
deducedNewBomb=true
end
end
end
if cell.value==flaggedNeighbors and #unopenedNeighbors>0 then
for _,nCell in ipairs(unopenedNeighbors)do
if not nCell.isFlagged and not nCell.isOpened then
safeTiles[nCell.col.."_"..nCell.row]=nCell
end
end
end
end
end
end
end
if espActive then
updateESP(safeTiles,deducedBombs,borderProbabilities)
end
return true,safeTiles,borderProbabilities,deducedNewBomb
end
local function walkTo(part)
local char=player.Character
local root=char and char:FindFirstChild("HumanoidRootPart")
local hum=char and char:FindFirstChildOfClass("Humanoid")
if not root or not hum then return end
hum.WalkSpeed=customWalkSpeed
local targetPos=Vector3.new(part.Position.X,root.Position.Y,part.Position.Z)
hum:MoveTo(targetPos)
local startT=os.clock()
while(root.Position-targetPos).Magnitude>1.5 and autoWalkActive do
if os.clock()-startT>2 then
break
end
task.wait()
hum:MoveTo(targetPos)
end
end
local function walkPath(path)
for _,part in ipairs(path)do
if not autoWalkActive then break end
walkTo(part)
end
end
local function flag(part)
-- Симуляция клика мышкой/пальцем для установки флага
local camera = workspace.CurrentCamera
local viewportPoint = camera:WorldToViewportPoint(part.Position)
if viewportPoint.Z > 0 then
local m = player:GetMouse()
m.Target = part
m.Hit = part
-- На телефоне тоже сработает, так как мы меняем Target
end
localFlags[part] = true
deducedBombs[part] = true
end
local function waitForFlags()
if not autoFlagActive then return end
local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if not root then return end
local startTime=os.clock()
while os.clock()-startTime<0.5 do
local allFlagged=true
for part in pairs(deducedBombs)do
if part and part.Parent then
local dist=(part.Position-root.Position).Magnitude
if dist<100 then
if not hasServerFlag(part)then
allFlagged=false
flag(part)
end
end
end
end
if allFlagged then break end
task.wait(0.05)
end
end
local function botLoop()
while autoWalkActive or autoFlagActive do
local gameRunningVal=ReplicatedStorage:FindFirstChild("Info")and ReplicatedStorage.Info:FindFirstChild("GameRunning")and ReplicatedStorage.Info.GameRunning.Value
if not gameRunningVal then
task.wait(1)
continue
end
if not checkGridValid()then
initGrid()
end
local success,safeTiles,borderProbabilities,deducedNewBomb=updateDeductions()
if not success then
task.wait(0.05)
continue
end
local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if not root then task.wait(0.5) continue end

-- 1. СНАЧАЛА СТАВИМ ФЛАГИ (если включено)
if autoFlagActive then
local bombToFlag = nil
local minBombDist = math.huge
for part in pairs(deducedBombs) do
if part and part.Parent and not hasServerFlag(part) then
local d = (part.Position - root.Position).Magnitude
if d < 100 and d < minBombDist then
minBombDist = d
bombToFlag = part
end
end
end
if bombToFlag then
-- Идем к бомбе, чтобы поставить флаг (игра требует близкого расстояния)
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum.WalkSpeed = customWalkSpeed
hum:MoveTo(Vector3.new(bombToFlag.Position.X, root.Position.Y, bombToFlag.Position.Z))
local t = os.clock()
while (root.Position - Vector3.new(bombToFlag.Position.X, root.Position.Y, bombToFlag.Position.Z)).Magnitude > 1.5 and os.clock() - t < 2 do
task.wait()
hum:MoveTo(Vector3.new(bombToFlag.Position.X, root.Position.Y, bombToFlag.Position.Z))
end
task.wait(0.1)
flag(bombToFlag)
task.wait(0.2)
end
continue -- После флага начинаем цикл заново
end
end

-- 2. ЕСЛИ ФЛАГИ НЕ НУЖНЫ, ИДЕМ ОТКРЫВАТЬ СИНИЕ (безопасные)
if autoWalkActive then
local pCol,pRow=getCurrentPlayerGrid()
if not pCol or not pRow then task.wait(0.5) continue end
local openedCount=0
for col=1,W do for row=1,H do if grid[col][row].isOpened then openedCount=openedCount+1 end end end

if openedCount==0 then
local midCol=math.floor(W/2)+1
local midRow=math.floor(H/2)+1
notify("FIMO HUB","Starting game...")
local targetPart=grid[midCol][midRow].part
if targetPart then
walkTo(targetPart)
task.wait(0.5)
end
continue
end

local targetCell=nil
local bestPath=nil
local minPathLen=math.huge
for _,cell in pairs(safeTiles)do
local path=findPath(pCol,pRow,cell.col,cell.row)
if path and #path<minPathLen then
minPathLen=#path
targetCell=cell
bestPath=path
end
end

if bestPath and targetCell then
print("Walking to safe tile: ("..targetCell.col..", "..targetCell.row..")")
walkPath(bestPath)
local startWait=os.clock()
while not targetCell.part:FindFirstChild("NumberGui")and os.clock()-startWait<1.5 and autoWalkActive do
task.wait(0.05)
end
else
-- Если безопасных нет, ищем по вероятностям или рандомно
local bestGuessCell=nil
local minProb=math.huge
for part,P in pairs(borderProbabilities)do
local x=math.floor(part.Position.X+0.5)
local z=math.floor(part.Position.Z+0.5)
local col=xToCol[x]
local row=zToRow[z]
if col and row then
local cell=grid[col][row]
if P<minProb then
minProb=P
bestGuessCell=cell
end
end
end
if bestGuessCell then
local path=findPath(pCol,pRow,bestGuessCell.col,bestGuessCell.row)
if path then walkPath(path) else walkTo(bestGuessCell.part) end
local startWait=os.clock()
while not bestGuessCell.part:FindFirstChild("NumberGui")and os.clock()-startWait<1.5 and autoWalkActive do
task.wait(0.05)
end
else
local candidates=getLocalGuessCandidates(pCol,pRow)
if #candidates>0 then
local guessCell=candidates[math.random(1,#candidates)]
local path=findPath(pCol,pRow,guessCell.col,guessCell.row)
if path then walkPath(path) else walkTo(guessCell.part) end
local startWait=os.clock()
while not guessCell.part:FindFirstChild("NumberGui")and os.clock()-startWait<1.5 and autoWalkActive do
task.wait(0.05)
end
else
notify("FIMO HUB","No candidates found!")
autoWalkActive=false
if AutoWalkToggle then AutoWalkToggle:UpdateState(false) end
end
end
end
end
task.wait(0.05)
end
end

local function espLoop()
while espActive do
if not autoWalkActive and not autoFlagActive then
local gameRunningVal=ReplicatedStorage:FindFirstChild("Info")and ReplicatedStorage.Info:FindFirstChild("GameRunning")and ReplicatedStorage.Info.GameRunning.Value
if not gameRunningVal then
localFlags={}
deducedBombs={}
clearESP()
while not(ReplicatedStorage:FindFirstChild("Info")and ReplicatedStorage.Info:FindFirstChild("GameRunning")and ReplicatedStorage.Info.GameRunning.Value)and espActive and not autoWalkActive and not autoFlagActive do
task.wait(1)
end
if espActive and not autoWalkActive and not autoFlagActive then
task.wait(2)
initGrid()
end
continue
end
if not checkGridValid()then
initGrid()
end
updateDeductions()
end
task.wait(0.2)
end
end
local function startFlying()
local char=player.Character
local root=char and char:FindFirstChild("HumanoidRootPart")
local hum=char and char:FindFirstChildOfClass("Humanoid")
if not root or not hum then return end
if flyGyro then flyGyro:Destroy()end
if flyVelocity then flyVelocity:Destroy()end
flyGyro=Instance.new("BodyGyro")
flyGyro.P=9e4
flyGyro.maxTorque=Vector3.new(9e9,9e9,9e9)
flyGyro.cframe=root.CFrame
flyGyro.Parent=root
flyVelocity=Instance.new("BodyVelocity")
flyVelocity.velocity=Vector3.new(0,0.1,0)
flyVelocity.maxForce=Vector3.new(9e9,9e9,9e9)
flyVelocity.Parent=root
hum.PlatformStand=true
task.spawn(function()
while flying and player.Character and root and hum do
local camera=workspace.CurrentCamera
local moveDir=Vector3.new(0,0,0)
if UserInputService:IsKeyDown(Enum.KeyCode.W)then
moveDir=moveDir+camera.CFrame.LookVector
end
if UserInputService:IsKeyDown(Enum.KeyCode.S)then
moveDir=moveDir-camera.CFrame.LookVector
end
if UserInputService:IsKeyDown(Enum.KeyCode.A)then
moveDir=moveDir-camera.CFrame.RightVector
end
if UserInputService:IsKeyDown(Enum.KeyCode.D)then
moveDir=moveDir+camera.CFrame.RightVector
end
if UserInputService:IsKeyDown(Enum.KeyCode.Space)then
moveDir=moveDir+Vector3.new(0,1,0)
end
if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)then
moveDir=moveDir-Vector3.new(0,1,0)
end
flyVelocity.velocity=moveDir.Magnitude>0 and(moveDir.Unit*flySpeed)or Vector3.new(0,0,0)
flyGyro.cframe=camera.CFrame
task.wait()
end
if flyGyro then flyGyro:Destroy()flyGyro=nil end
if flyVelocity then flyVelocity:Destroy()flyVelocity=nil end
if hum then hum.PlatformStand=false end
end)
end
local function stopFlying()
if flyGyro then flyGyro:Destroy()flyGyro=nil end
if flyVelocity then flyVelocity:Destroy()flyVelocity=nil end
local char=player.Character
local hum=char and char:FindFirstChildOfClass("Humanoid")
if hum then hum.PlatformStand=false end
end
local function toggleFly(val)
flying=val
if flying then
startFlying()
notify("Fly Mode","Flying ON")
else
stopFlying()
notify("Fly Mode","Flying OFF")
end
end
UserInputService.JumpRequest:Connect(function()
if infiniteJump then
local char=player.Character
local hum=char and char:FindFirstChildOfClass("Humanoid")
if hum then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
end)
local function onCharacterAdded(char)
local hum=char:WaitForChild("Humanoid",5)
if hum then
hum.UseJumpPower=true
hum.WalkSpeed=customWalkSpeed
hum.JumpPower=customJumpPower
end
if flying then
task.spawn(startFlying)
end
end
if player.Character then
task.spawn(onCharacterAdded,player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
local Luna=loadstring(game:HttpGet("https://raw.githubusercontent.com/maksimovemil324-ops/fimozikrootmaingui/refs/heads/main/source.lua",true))()
local Window=Luna:CreateWindow({
Name="FIMO HUB | Minesweeper",
Subtitle="by Fimozikroot | t.me/fimozikroot",
LogoID="100217590927128",
LoadingEnabled=true,
LoadingTitle="Minesweeper Solver",
LoadingSubtitle="by Fimozikroot",
ConfigSettings={RootFolder=nil,ConfigFolder="FimoHub"},
KeySystem=true,
KeySettings={
Title="FIMO HUB Key",
Subtitle="Verification",
Note="Key is: fimozikroot",
SaveInRoot=false,
SaveKey=true,
Key={"fimozikroot"},
SecondAction={Enabled=false,Type="Link",Parameter=""}
}
})
Window:CreateHomeTab({
SupportedExecutors={"Wave","Delta","Codex","Hydrogen","Solara","Macsploit","Real"},
DiscordInvite="fimozikroot",
Icon=1
})
local BotTab=Window:CreateTab({Name="Auto Bot",Icon="android",ImageSource="Material",ShowTitle=true})
local function setAutoWalk(val)
autoWalkActive=val
if autoWalkActive then
initGrid()
notify("Auto Walk","Auto Walk toggled ON")
task.spawn(botLoop)
else
notify("Auto Walk","Auto Walk toggled OFF")
end
end
local function setAutoFlag(val)
autoFlagActive=val
if autoFlagActive then
initGrid()
notify("Auto Flag","Auto Flag toggled ON")
task.spawn(botLoop)
else
notify("Auto Flag","Auto Flag toggled OFF")
end
end
AutoWalkToggle=BotTab:CreateToggle({Name="Auto Walk",Description="Auto walks and steps/clicks safe or optimal guess tiles.",CurrentValue=false,Callback=setAutoWalk},"AutoWalk")
BotTab:CreateBind({Name="Auto Walk Keybind",Description="Key to toggle Auto Walk",CurrentBind="L",HoldToInteract=false,Callback=function()local newVal=not AutoWalkToggle.CurrentValue AutoWalkToggle:UpdateState(newVal)setAutoWalk(newVal)end},"AutoWalkBind")
AutoFlagToggle=BotTab:CreateToggle({Name="Auto Flag",Description="Automatically places flags on deduced bombs.",CurrentValue=false,Callback=setAutoFlag},"AutoFlag")
BotTab:CreateBind({Name="Auto Flag Keybind",Description="Key to toggle Auto Flag",CurrentBind="NONE",HoldToInteract=false,Callback=function()local newVal=not AutoFlagToggle.CurrentValue AutoFlagToggle:UpdateState(newVal)setAutoFlag(newVal)end},"AutoFlagBind")
local EspTab=Window:CreateTab({Name="ESP",Icon="visibility",ImageSource="Material",ShowTitle=true})
local function setEspActive(val)
espActive=val
if espActive then
initGrid()
task.spawn(espLoop)
else
clearESP()
end
end
EspToggle=EspTab:CreateToggle({Name="ESP Active",Description="Draw outlines on safe, bomb, and uncertain cells.",CurrentValue=false,Callback=setEspActive},"ESPActive")
EspTab:CreateBind({Name="ESP Keybind",Description="Key to toggle ESP",CurrentBind="K",HoldToInteract=false,Callback=function()local newVal=not EspToggle.CurrentValue EspToggle:UpdateState(newVal)setEspActive(newVal)end},"ESPBind")
EspTab:CreateSection("ESP Colors")
EspTab:CreateColorPicker({Name="Safe Tile Color",Color=espSafeColor,Flag="ColorSafe",Callback=function(color)espSafeColor=color end},"ColorSafe")
EspTab:CreateColorPicker({Name="Bomb Tile Color",Color=espBombColor,Flag="ColorBomb",Callback=function(color)espBombColor=color end},"ColorBomb")
EspTab:CreateColorPicker({Name="Uncertain Low Risk Color (Yellow)",Color=espUncertainLow,Flag="ColorLow",Callback=function(color)espUncertainLow=color end},"ColorLow")
EspTab:CreateColorPicker({Name="Uncertain Medium Risk Color (Orange)",Color=espUncertainMed,Flag="ColorMed",Callback=function(color)espUncertainMed=color end},"ColorMed")
EspTab:CreateColorPicker({Name="Uncertain High Risk Color (Crimson)",Color=espUncertainHigh,Flag="ColorHigh",Callback=function(color)espUncertainHigh=color end},"ColorHigh")
local MoveTab=Window:CreateTab({Name="Movement",Icon="directions_run",ImageSource="Material",ShowTitle=true})
MoveTab:CreateSlider({Name="Walk Speed",Range={16,150},Increment=1,CurrentValue=customWalkSpeed,Callback=function(val)customWalkSpeed=val local char=player.Character local hum=char and char:FindFirstChildOfClass("Humanoid")if hum then hum.WalkSpeed=customWalkSpeed end end},"WalkSpeedSlider")
MoveTab:CreateSlider({Name="Jump Power",Range={50,300},Increment=5,CurrentValue=customJumpPower,Callback=function(val)customJumpPower=val local char=player.Character local hum=char and char:FindFirstChildOfClass("Humanoid")if hum then hum.UseJumpPower=true hum.JumpPower=customJumpPower end end},"JumpPowerSlider")
MoveTab:CreateToggle({Name="Infinite Jump",Description="Lets you jump in mid-air indefinitely.",CurrentValue=false,Callback=function(val)infiniteJump=val end},"InfiniteJumpToggle")
MoveTab:CreateSection("Fly Controls")
FlyToggle=MoveTab:CreateToggle({Name="Fly Mode",Description="WASD to move, Space to go up, LeftShift to go down.",CurrentValue=false,Callback=toggleFly},"FlyToggle")
MoveTab:CreateBind({Name="Fly Keybind",Description="Key to toggle Fly",CurrentBind="F",HoldToInteract=false,Callback=function()local newVal=not FlyToggle.CurrentValue FlyToggle:UpdateState(newVal)toggleFly(newVal)end},"FlyBind")
MoveTab:CreateSlider({Name="Fly Speed",Range={10,150},Increment=5,CurrentValue=flySpeed,Callback=function(val)flySpeed=val end},"FlySpeedSlider")
local ThemeTab=Window:CreateTab({Name="Theme Tab",Icon="palette",ImageSource="Material",ShowTitle=true})
ThemeTab:BuildThemeSection()
local ConfigTab=Window:CreateTab({Name="Config Tab",Icon="settings",ImageSource="Material",ShowTitle=true})
ConfigTab:BuildConfigSection()
print("FIMO HUB Minesweeper loaded")
notify("FIMO HUB","Support t.me/fimozikroot")
