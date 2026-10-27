-- blockstrike.lua | FIMO HUB module | by Fimozikroot
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")
local VirtualUser=game:GetService("VirtualUser")

local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

local S={
	Aimbot=false, AimbotFOV=120, AimbotSmooth=0.25, AimbotKey=Enum.KeyCode.X,
	AimbotTeamCheck=true, AimbotWallCheck=true, AimbotPart="Head",
	Triggerbot=false, TriggerbotDelay=0.05,
	ESP=false, ESPName=true, ESPHealth=true, ESPDistance=true, ESPTeamColor=true,
	WorldESP=false, WorldESPColor=Color3.fromRGB(255,220,80),
	Speed=false, SpeedVal=80,
	Jump=false, JumpVal=200,
	Fly=false, FlySpeed=100,
	Noclip=false,
	Bhop=false,
	NoRecoil=false, NoSpread=false,
	Fullbright=false,
	AntiAFK=false
}

local Highlights={}
local WorldHighlights={}
local FlyBV,FlyBG
local OrigSpeed,OrigJump
local OrigAmbient,OrigBright,OrigOutdoor
local AimKeyDown=false
local TriggerCooldown=0
local isMobile=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function IsAlive(plr)
	if not plr or not plr.Character then return false end
	local h=plr.Character:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0
end

local function GetTeam(plr)
	return plr.Team
end

local function GetRoot(plr)
	if not plr.Character then return nil end
	return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function GetPart(plr,partName)
	if not plr.Character then return nil end
	local part=plr.Character:FindFirstChild(partName)
	if part and part:IsA("BasePart") then return part end
	return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function IsVisible(targetPart)
	if not S.AimbotWallCheck then return true end
	local origin=Camera.CFrame.Position
	local dir=(targetPart.Position-origin)
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={LocalPlayer.Character,targetPart.Parent,Camera}
	local result=Workspace:Raycast(origin,dir,params)
	return result==nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetTarget()
	local closest,dist=nil,S.AimbotFOV
	local center
	if isMobile then
		center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
	else
		center=Vector2.new(UserInputService:GetMouseLocation().X,UserInputService:GetMouseLocation().Y)
	end
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and IsAlive(plr) then
			if not(S.AimbotTeamCheck and GetTeam(plr)==GetTeam(LocalPlayer)) then
				local part=GetPart(plr,S.AimbotPart)
				if part and IsVisible(part) then
					local pos,onScreen=Camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
						if d<S.AimbotFOV and d<dist then
							dist=d
							closest=part
						end
					end
				end
			end
		end
	end
	return closest
end

local function CreateHighlight(plr)
	if Highlights[plr] then return end
	local h=Instance.new("Highlight")
	h.FillColor=S.ESPColor or Color3.fromRGB(255,60,60)
	h.OutlineColor=S.ESPColor or Color3.fromRGB(255,60,60)
	h.FillTransparency=0.5
	h.OutlineTransparency=0
	h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent=plr.Character

	local billboard=Instance.new("BillboardGui")
	billboard.Name="FimoESP"
	billboard.Size=UDim2.new(0,200,0,60)
	billboard.StudsOffset=Vector3.new(0,2.5,0)
	billboard.AlwaysOnTop=true
	billboard.Adornee=plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")

	local nameLabel=Instance.new("TextLabel",billboard)
	nameLabel.Name="Name"
	nameLabel.Size=UDim2.new(1,0,0,20)
	nameLabel.BackgroundTransparency=1
	nameLabel.TextColor3=Color3.fromRGB(255,60,60)
	nameLabel.TextStrokeTransparency=0.5
	nameLabel.Font=Enum.Font.GothamBold
	nameLabel.TextSize=14
	nameLabel.Text=plr.Name

	local healthLabel=Instance.new("TextLabel",billboard)
	healthLabel.Name="Health"
	healthLabel.Size=UDim2.new(1,0,0,16)
	healthLabel.Position=UDim2.new(0,0,0,20)
	healthLabel.BackgroundTransparency=1
	healthLabel.TextColor3=Color3.fromRGB(120,255,120)
	healthLabel.TextStrokeTransparency=0.5
	healthLabel.Font=Enum.Font.Gotham
	healthLabel.TextSize=12

	local distLabel=Instance.new("TextLabel",billboard)
	distLabel.Name="Distance"
	distLabel.Size=UDim2.new(1,0,0,16)
	distLabel.Position=UDim2.new(0,0,0,36)
	distLabel.BackgroundTransparency=1
	distLabel.TextColor3=Color3.fromRGB(200,200,200)
	distLabel.TextStrokeTransparency=0.5
	distLabel.Font=Enum.Font.Gotham
	distLabel.TextSize=12

	billboard.Parent=plr.Character
	Highlights[plr]={hl=h,bg=billboard}
end

local function RemoveHighlight(plr)
	if Highlights[plr] then
		if Highlights[plr].hl then Highlights[plr].hl:Destroy() end
		if Highlights[plr].bg then Highlights[plr].bg:Destroy() end
		Highlights[plr]=nil
	end
end

local function UpdateESP()
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and IsAlive(plr) then
			if S.ESP then
				CreateHighlight(plr)
				local data=Highlights[plr]
				if data then
					local color=Color3.fromRGB(255,60,60)
					if S.ESPTeamColor and plr.Team then color=plr.Team.TeamColor.Color end
					data.hl.FillColor=color
					data.hl.OutlineColor=color
					local head=plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
					if head then data.bg.Adornee=head end
					local root=GetRoot(plr)
					local hum=plr.Character:FindFirstChildOfClass("Humanoid")
					if data.bg:FindFirstChild("Name") then
						data.bg.Name.Text=plr.Name
						data.bg.Name.Visible=S.ESPName
						data.bg.Name.TextColor3=color
					end
					if data.bg:FindFirstChild("Health") and hum then
						data.bg.Health.Text=math.floor(hum.Health).." / "..math.floor(hum.MaxHealth)
						data.bg.Health.Visible=S.ESPHealth
					end
					if data.bg:FindFirstChild("Distance") and root then
						data.bg.Distance.Text=math.floor((root.Position-Camera.CFrame.Position).Magnitude).."m"
						data.bg.Distance.Visible=S.ESPDistance
					end
				end
			else
				RemoveHighlight(plr)
			end
		else
			RemoveHighlight(plr)
		end
	end
end

local function UpdateWorldESP()
	for obj,_ in pairs(WorldHighlights) do
		if not obj.Parent then
			if WorldHighlights[obj] then WorldHighlights[obj]:Destroy() end
			WorldHighlights[obj]=nil
		end
	end
	if not S.WorldESP then
		for obj,hl in pairs(WorldHighlights) do hl:Destroy() WorldHighlights[obj]=nil end
		return
	end
	local folders={"Drops","Weapons","Debris"}
	for _,folderName in ipairs(folders) do
		local folder=Workspace:FindFirstChild(folderName)
		if folder then
			for _,obj in ipairs(folder:GetChildren()) do
				if not WorldHighlights[obj] then
					local hl=Instance.new("Highlight")
					hl.FillColor=S.WorldESPColor
					hl.OutlineColor=S.WorldESPColor
					hl.FillTransparency=0.4
					hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
					hl.Adornee=obj
					hl.Parent=obj
					WorldHighlights[obj]=hl
				end
			end
		end
	end
end

local function UpdateAimbot()
	if not S.Aimbot then return end
	if not AimKeyDown then return end
	local target=GetTarget()
	if not target then return end
	local targetCFrame=CFrame.new(Camera.CFrame.Position,target.Position)
	Camera.CFrame=Camera.CFrame:Lerp(targetCFrame,S.AimbotSmooth)
end

local function UpdateTriggerbot()
	if not S.Triggerbot then return end
	if tick()-TriggerCooldown<S.TriggerbotDelay then return end
	local target=GetTarget()
	if not target then return end
	if IsVisible(target) then
		TriggerCooldown=tick()
		if mouse1click then
			mouse1click()
		else
			VirtualUser:Button1Down(Vector2.new(0,0),Camera.CFrame)
			task.wait(0.02)
			VirtualUser:Button1Up(Vector2.new(0,0),Camera.CFrame)
		end
	end
end

local function UpdateSpeedJump()
	local char=LocalPlayer.Character
	if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if not OrigSpeed then OrigSpeed=hum.WalkSpeed end
	if not OrigJump then OrigJump=hum.JumpPower end
	hum.WalkSpeed=S.Speed and S.SpeedVal or OrigSpeed
	hum.UseJumpPower=true
	hum.JumpPower=S.Jump and S.JumpVal or OrigJump
end

local function StartFly()
	local char=LocalPlayer.Character
	if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if FlyBV then FlyBV:Destroy() end
	if FlyBG then FlyBG:Destroy() end
	FlyBV=Instance.new("BodyVelocity",root)
	FlyBV.MaxForce=Vector3.new(9e9,9e9,9e9)
	FlyBV.Velocity=Vector3.zero
	FlyBG=Instance.new("BodyGyro",root)
	FlyBG.P=9e4
	FlyBG.MaxTorque=Vector3.new(9e9,9e9,9e9)
	FlyBG.CFrame=root.CFrame
end

local function StopFly()
	if FlyBV then FlyBV:Destroy() FlyBV=nil end
	if FlyBG then FlyBG:Destroy() FlyBG=nil end
end

local function UpdateFly()
	if not S.Fly then
		if FlyBV or FlyBG then StopFly() end
		return
	end
	if not FlyBV or not FlyBG then StartFly() end
	if not FlyBV or not FlyBG then return end
	local move=Vector3.zero
	local camCF=Camera.CFrame
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move=move+camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move=move-camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move=move-camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move=move+camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.new(0,1,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move=move-Vector3.new(0,1,0) end
	if move.Magnitude>0 then move=move.Unit*S.FlySpeed end
	FlyBV.Velocity=move
	FlyBG.CFrame=camCF
end

local function UpdateNoclip()
	if not S.Noclip then return end
	local char=LocalPlayer.Character
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide=false end
	end
end

local function UpdateBhop()
	if not S.Bhop then return end
	local char=LocalPlayer.Character
	if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial~=Enum.Material.Air then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local function UpdateNoRecoilSpread()
	if not S.NoRecoil and not S.NoSpread then return end
	local char=LocalPlayer.Character
	if not char then return end
	local containers={char}
	local backpack=LocalPlayer:FindFirstChild("Backpack")
	if backpack then table.insert(containers,backpack) end
	for _,container in ipairs(containers) do
		for _,obj in ipairs(container:GetDescendants()) do
			if obj:IsA("NumberValue") then
				local n=string.lower(obj.Name)
				if S.NoRecoil and (string.find(n,"recoil") or string.find(n,"kick")) then obj.Value=0 end
				if S.NoSpread and string.find(n,"spread") then obj.Value=0 end
			end
		end
	end
end

local function UpdateFullbright()
	if not OrigAmbient then
		OrigAmbient=Lighting.Ambient
		OrigBright=Lighting.Brightness
		OrigOutdoor=Lighting.OutdoorAmbient
	end
	if S.Fullbright then
		Lighting.Ambient=Color3.fromRGB(200,200,200)
		Lighting.Brightness=3
		Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
		Lighting.ClockTime=14
		Lighting.GlobalShadows=false
	else
		Lighting.Ambient=OrigAmbient
		Lighting.Brightness=OrigBright
		Lighting.OutdoorAmbient=OrigOutdoor
	end
end

RunService.RenderStepped:Connect(function()
	pcall(UpdateESP)
	pcall(UpdateWorldESP)
	pcall(UpdateAimbot)
	pcall(UpdateTriggerbot)
	pcall(UpdateSpeedJump)
	pcall(UpdateFly)
	pcall(UpdateNoclip)
	pcall(UpdateBhop)
	pcall(UpdateNoRecoilSpread)
	pcall(UpdateFullbright)
end)

UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode==S.AimbotKey then AimKeyDown=true end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode==S.AimbotKey then AimKeyDown=false end
end)

LocalPlayer.Idled:Connect(function()
	if S.AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0,0),Camera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0,0),Camera.CFrame)
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	StopFly()
	for plr in pairs(Highlights) do RemoveHighlight(plr) end
	Highlights={}
	OrigSpeed=nil
	OrigJump=nil
end)

local FimoBlockStrike={}
FimoBlockStrike.Settings=S
FimoBlockStrike.Unload=function()
	StopFly()
	for plr in pairs(Highlights) do RemoveHighlight(plr) end
	for obj,hl in pairs(WorldHighlights) do hl:Destroy() end
	WorldHighlights={}
	Highlights={}
	if OrigAmbient then
		Lighting.Ambient=OrigAmbient
		Lighting.Brightness=OrigBright
		Lighting.OutdoorAmbient=OrigOutdoor
	end
end
return FimoBlockStrike
