-- VEXES HUB PART 2
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local TeleportService      = game:GetService("TeleportService")
local VirtualUser          = game:GetService("VirtualUser")
local Lighting             = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService          = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse  = player:GetMouse()
local camera = workspace.CurrentCamera

local toggles        = VH_toggles
local getHRP         = VH_getHRP
local getHum         = VH_getHum
local GetPlayer      = VH_GetPlayer
local getTeamColor   = VH_getTeamColor
local onSameTeam     = VH_onSameTeam
local espObjects     = VH_espObjects
local AimbotSettings = VH_AimbotSettings
local FOV_COLORS     = VH_FOV_COLORS
local origLight      = VH_origLight
local TabMain        = VH_TabMain
local TabMain2       = VH_TabMain2
local TabCombat      = VH_TabCombat
local TabTarget      = VH_TabTarget
local TabAimbot      = VH_TabAimbot
local TabESP         = VH_TabESP
local TabVisuals     = VH_TabVisuals
local TabPos         = VH_TabPos
local TabItems       = VH_TabItems
local TabUtil        = VH_TabUtil
local TabSettings    = VH_TabSettings

local v2Speed       = 16
local v2JumpPow     = 50
local v2BypassJump  = 80
local v2SpeedConn   = nil
local v2NoclipConn  = nil
local v2InfJump     = false
local v2Spinbot     = false
local v2Godmode     = false
local v2Noclip      = false
local v2FlingActive = false
local v2FlingAngle  = 0
local v2SpinAngle   = 0

local function v2StartSpeed()
	if v2SpeedConn then v2SpeedConn:Disconnect() end
	v2SpeedConn = RunService.Heartbeat:Connect(function()
		local char=player.Character; if not char then return end
		local hrp=getHRP(char); local hum=getHum(char); if not hrp or not hum then return end
		if hum.MoveDirection.Magnitude>0 then
			hrp.Velocity=Vector3.new(hum.MoveDirection.X*v2Speed,hrp.Velocity.Y,hum.MoveDirection.Z*v2Speed)
		end
	end)
end
local function v2StopSpeed()
	if v2SpeedConn then v2SpeedConn:Disconnect(); v2SpeedConn=nil end
end

local v2NoclipOriginals = {}
local function v2StartNoclip()
	if v2NoclipConn then v2NoclipConn:Disconnect() end
	v2NoclipConn = RunService.Stepped:Connect(function()
		if not player.Character then return end
		if v2Noclip then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					if v2NoclipOriginals[v] == nil then v2NoclipOriginals[v] = v.CanCollide end
					v.CanCollide = false
				end
			end
		else
			for v,orig in pairs(v2NoclipOriginals) do
				if v and v.Parent then v.CanCollide = orig end
			end
			v2NoclipOriginals = {}
		end
	end)
end

RunService.Heartbeat:Connect(function()
	local char=player.Character; if not char then return end
	local hrp=getHRP(char); local hum=getHum(char); if not hrp or not hum then return end
	if v2Godmode then for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=false end end end
	if v2Spinbot and not v2FlingActive then
		v2SpinAngle=(v2SpinAngle+4)%360
		hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(v2SpinAngle),0)
	end
	if v2FlingActive then
		v2FlingAngle=(v2FlingAngle+60)%360
		local bg=hrp:FindFirstChild("v2FlingBG")
		if not bg then bg=Instance.new("BodyGyro",hrp); bg.Name="v2FlingBG"; bg.MaxTorque=Vector3.new(0,1e9,0); bg.P=1e9; bg.D=0 end
		bg.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(v2FlingAngle),0)
		hrp.RotVelocity=Vector3.new(0,9999,0)
		for _,p in pairs(Players:GetPlayers()) do
			if p~=player and p.Character then
				local ph=getHRP(p.Character)
				if ph and (ph.Position-hrp.Position).Magnitude<6 then
					local bv=ph:FindFirstChild("v2FlingBV") or Instance.new("BodyVelocity",ph)
					bv.Name="v2FlingBV"; bv.MaxForce=Vector3.new(1e9,1e9,1e9)
					bv.Velocity=Vector3.new(math.random(-300,300),800+math.random(0,400),math.random(-300,300))
					game:GetService("Debris"):AddItem(bv,0.15)
				end
			end
		end
	else
		local bg=hrp:FindFirstChild("v2FlingBG"); if bg then bg:Destroy() end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if v2InfJump then local h=getHum(player.Character) if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

TabMain:Slider({Title="Walkspeed",Value={Min=16,Max=500,Default=16},Callback=function(V) getgenv().VH_customSpeed=V end})
TabMain:Toggle({Title="Enable Walkspeed",Value=false,Callback=function(V) toggles.speed=V end})
TabMain:Slider({Title="Jump Power",Value={Min=50,Max=500,Default=50},Callback=function(V) getgenv().VH_customJump=V end})
TabMain:Toggle({Title="Enable Jump Power",Value=false,Callback=function(V)
	toggles.jumpHigh=V
	if not V then local h=getHum(player.Character) if h then h.JumpPower=50 end end
end})
TabMain:Slider({Title="Bypass Jump Height",Value={Min=50,Max=1000,Default=80},Callback=function(V) getgenv().VH_bypassJump=V end})
TabMain:Toggle({Title="Enable Bypass Jump",Value=false,Callback=function(V)
	toggles.bypassJump=V
	if VH_bypassJumpConn then VH_bypassJumpConn:Disconnect(); getgenv().VH_bypassJumpConn=nil end
	if V then getgenv().VH_bypassJumpConn = UserInputService.JumpRequest:Connect(VH_doBypassJump) end
end})
TabMain:Toggle({Title="Infinite Jump",Value=false,Callback=function(V) toggles.infjump=V end})
TabMain:Toggle({Title="Noclip",Value=false,Callback=function(V) toggles.noclip=V end})
TabMain:Toggle({Title="Spinbot",Value=false,Callback=function(V) toggles.spinbot=V end})
TabMain:Toggle({Title="God Mode",Value=false,Callback=function(V) toggles.untouchable=V end})
TabMain:Toggle({Title="FPS Booster",Value=false,Callback=function(V)
	toggles.fpsBoost=V
	if V then
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then VH_fpsStoredMaterials[v]=v.Material; v.Material=Enum.Material.SmoothPlastic end
		end
	else
		for p,m in pairs(VH_fpsStoredMaterials) do if p and p.Parent then p.Material=m end end
		getgenv().VH_fpsStoredMaterials={}
	end
end})
TabMain:Toggle({Title="Instant Respawn",Value=false,Callback=function(V) toggles.instantRespawn=V end})
TabMain:Toggle({Title="Fling",Value=false,Callback=function(V)
	toggles.fling=V
	if not V then
		local hrp=getHRP(player.Character)
		if hrp then local fg=hrp:FindFirstChild("FlingBG") if fg then fg:Destroy() end end
	end
end})
TabMain:Button({Title="Open Fly GUI",Callback=function()
	getgenv().VH_flyGuiOpen = not VH_flyGuiOpen
	VH_FlyScreenGui.Enabled = VH_flyGuiOpen
end})

TabMain2:Input({Title="Set Walkspeed",Placeholder="16",Callback=function(V) local n=tonumber(V) if n then v2Speed=math.clamp(n,1,9999) end end})
TabMain2:Toggle({Title="Enable Walkspeed",Value=false,Callback=function(V) if V then v2StartSpeed() else v2StopSpeed() end end})
TabMain2:Input({Title="Set Jump Power",Placeholder="50",Callback=function(V) local n=tonumber(V) if n then v2JumpPow=math.clamp(n,1,9999) end end})
TabMain2:Toggle({Title="Enable Jump Power",Value=false,Callback=function(V)
	RunService.Heartbeat:Connect(function()
		if not V then return end
		local h=getHum(player.Character); if h then h.JumpPower=v2JumpPow end
	end)
end})
TabMain2:Input({Title="Set Bypass Jump",Placeholder="80",Callback=function(V) local n=tonumber(V) if n then v2BypassJump=math.clamp(n,1,9999) end end})
TabMain2:Toggle({Title="Enable Bypass Jump",Value=false,Callback=function(V)
	if V then
		UserInputService.JumpRequest:Connect(function()
			local char=player.Character; if not char then return end
			local hrp=getHRP(char); local hum=getHum(char); if not hrp or not hum then return end
			local rp=RaycastParams.new(); rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Exclude
			if not workspace:Raycast(hrp.Position,Vector3.new(0,-3.2,0),rp) then return end
			local att=Instance.new("Attachment",hrp)
			local lv=Instance.new("LinearVelocity",hrp)
			lv.Attachment0=att; lv.MaxForce=math.huge
			lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
			lv.VectorVelocity=Vector3.new(hrp.Velocity.X,v2BypassJump*0.5,hrp.Velocity.Z)
			hum.PlatformStand=false
			task.delay(0.07,function()
				if lv and lv.Parent then lv:Destroy() end
				if att and att.Parent then att:Destroy() end
			end)
		end)
	end
end})
TabMain2:Toggle({Title="Infinite Jump",Value=false,Callback=function(V) v2InfJump=V end})
TabMain2:Toggle({Title="Noclip",Value=false,Callback=function(V) v2Noclip=V; if V then v2StartNoclip() end end})
TabMain2:Toggle({Title="Spinbot",Value=false,Callback=function(V) v2Spinbot=V end})
TabMain2:Toggle({Title="God Mode",Value=false,Callback=function(V) v2Godmode=V end})
TabMain2:Toggle({Title="Fling",Value=false,Callback=function(V) v2FlingActive=V end})
TabMain2:Toggle({Title="Instant Respawn",Value=false,Callback=function(V)
	if V then
		local char=player.Character
		if char then
			local h=char:FindFirstChild("Humanoid")
			if h then h.Died:Connect(function() task.wait(0.05); player:LoadCharacter() end) end
		end
	end
end})
TabMain2:Toggle({Title="FPS Booster",Value=false,Callback=function(V)
	if V then
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then VH_fpsStoredMaterials[v]=v.Material; v.Material=Enum.Material.SmoothPlastic end
		end
	else
		for p,m in pairs(VH_fpsStoredMaterials) do if p and p.Parent then p.Material=m end end
		getgenv().VH_fpsStoredMaterials={}
	end
end})

TabCombat:Toggle({Title="Hitbox Expander",Value=false,Callback=function(V) toggles.hitbox=V end})
TabCombat:Slider({Title="Hitbox Size",Value={Min=2,Max=100,Default=15},Callback=function(V) getgenv().VH_hitboxSize=V end})
TabCombat:Toggle({Title="Freeze All",Value=false,Callback=function(V) toggles.frozeAll=V end})
TabCombat:Toggle({Title="Freeze Aura (35 studs)",Value=false,Callback=function(V) toggles.freezeAura=V end})
TabCombat:Toggle({Title="Bring All",Value=false,Callback=function(V) toggles.bringAll=V end})
TabCombat:Toggle({Title="Bring Nearby (70 studs)",Value=false,Callback=function(V) toggles.bringNearby=V end})

TabTarget:Input({Title="Player Name",Placeholder="Enter username...",Callback=function(T) getgenv().VH_targetPlayerName=T end})
TabTarget:Toggle({Title="Spectate",Value=false,Callback=function(V)
	toggles.spectate=V
	if V then task.spawn(function()
		while toggles.spectate do
			local t=GetPlayer(VH_targetPlayerName)
			if t and t.Character and getHum(t.Character) then workspace.CurrentCamera.CameraSubject=t.Character.Humanoid
			elseif player.Character then workspace.CurrentCamera.CameraSubject=player.Character:FindFirstChild("Humanoid") end
			task.wait(0.1)
		end
	end) elseif player.Character then workspace.CurrentCamera.CameraSubject=player.Character:FindFirstChild("Humanoid") end
end})
TabTarget:Toggle({Title="Bring Target",Value=false,Callback=function(V)
	toggles.bringTarget=V
	if V then
		local t=GetPlayer(VH_targetPlayerName)
		if t and t.Character and getHRP(t.Character) then
			getgenv().VH_persistentTarget=t; getgenv().VH_targetOrigPos=getHRP(t.Character).CFrame
		end
	else
		if VH_persistentTarget and VH_persistentTarget.Character and getHRP(VH_persistentTarget.Character) and VH_targetOrigPos then
			getHRP(VH_persistentTarget.Character).CFrame=VH_targetOrigPos
		end
		getgenv().VH_persistentTarget=nil; getgenv().VH_targetOrigPos=nil
	end
end})
TabTarget:Toggle({Title="Freeze Target",Value=false,Callback=function(V)
	toggles.freezeTarget=V
	local t=GetPlayer(VH_targetPlayerName)
	if t and t.Character and getHRP(t.Character) then getHRP(t.Character).Anchored=V end
end})
TabTarget:Toggle({Title="Loop Teleport to Target",Value=false,Callback=function(V)
	toggles.loopTP=V
	if V then task.spawn(function()
		while toggles.loopTP do
			local t=GetPlayer(VH_targetPlayerName); local hrp=getHRP(player.Character)
			if t and t.Character and getHRP(t.Character) and hrp then hrp.CFrame=getHRP(t.Character).CFrame*CFrame.new(0,0,3) end
			task.wait(0.1)
		end
	end) end
end})
TabTarget:Button({Title="Fling Target",Callback=function()
	local t=GetPlayer(VH_targetPlayerName); if not t or not t.Character then return end
	local myHRP=getHRP(player.Character); if not myHRP then return end
	local origCF=myHRP.CFrame
	task.spawn(function()
		local myHum=getHum(player.Character)
		if myHum then myHum.PlatformStand=true end
		local ang=0
		local bg=Instance.new("BodyGyro",myHRP)
		bg.MaxTorque=Vector3.new(0,1e9,0); bg.P=1e9; bg.D=0
		local spinConn=RunService.Heartbeat:Connect(function()
			ang=(ang+30)%360
			bg.CFrame=CFrame.new(myHRP.Position)*CFrame.Angles(0,math.rad(ang),0)
			myHRP.RotVelocity=Vector3.new(0,500,0)
		end)
		task.wait(0.5)
		spinConn:Disconnect(); bg:Destroy()
		local tHRP=getHRP(t.Character)
		if tHRP then
			myHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,-1)
			local bv=Instance.new("BodyVelocity",tHRP)
			bv.MaxForce=Vector3.new(1e9,1e9,1e9)
			bv.Velocity=Vector3.new(math.random(-200,200),1200,math.random(-200,200))
			game:GetService("Debris"):AddItem(bv,0.1)
		end
		task.wait(0.2)
		myHRP.CFrame=origCF
		if myHum then myHum.PlatformStand=false end
	end)
end})

TabAimbot:Toggle({Title="Enable Aimbot",Value=false,Callback=function(V)
	toggles.aimbot=V; if not V then AimbotSettings.CurrentTarget=nil end
end})
TabAimbot:Toggle({Title="Enable FOV Circle",Value=false,Callback=function(V) toggles.fovCircle=V end})
TabAimbot:Input({Title="FOV Size",Placeholder="150",Callback=function(V)
	local n=tonumber(V); if n then AimbotSettings.FOVSize=math.clamp(n,10,800) end
end})
TabAimbot:Dropdown({Title="FOV Color",Values={"White","Red","Orange","Yellow","Lime","Cyan","Blue","Purple","Pink","Hot Pink","Rainbow"},Value="White",Callback=function(V)
	getgenv().VH_fovColorMode=V
	if V~="Rainbow" then local c=FOV_COLORS[V]; if c then AimbotSettings.FOVColor=c end end
end})
TabAimbot:Toggle({Title="Wall Check",Value=false,Callback=function(V) toggles.wallCheck=V end})
TabAimbot:Toggle({Title="Team Check",Value=false,Callback=function(V) toggles.teamCheck=V; AimbotSettings.CurrentTarget=nil end})
TabAimbot:Toggle({Title="Dead Check",Value=false,Callback=function(V) toggles.deadCheck=V end})
TabAimbot:Slider({Title="Aim Smoothing",Value={Min=1,Max=100,Default=100},Callback=function(V) AimbotSettings.Smoothing=V/100 end})

local function removeESP(p)
	if not espObjects[p] then return end
	pcall(function()
		if espObjects[p].hl and espObjects[p].hl.Parent then espObjects[p].hl:Destroy() end
		if espObjects[p].bb and espObjects[p].bb.Parent then espObjects[p].bb:Destroy() end
	end)
	espObjects[p]=nil
end

local function buildESP(p)
	if p==player then return end
	if toggles.espTeamCheck and onSameTeam(p) then return end
	removeESP(p)
	if not p.Character then return end
	local hrp=getHRP(p.Character); if not hrp then return end
	local col=getTeamColor(p); local d={}
	local hl=Instance.new("Highlight"); hl.Name="BESP"
	hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=0.5; hl.OutlineTransparency=0
	hl.Adornee=p.Character; hl.Enabled=toggles.espEnabled; hl.Parent=p.Character; d.hl=hl
	local bb=Instance.new("BillboardGui"); bb.Name="BESP_BB"
	bb.Size=UDim2.new(0,120,0,60); bb.StudsOffset=Vector3.new(0,3.5,0)
	bb.AlwaysOnTop=true; bb.Adornee=hrp; bb.Enabled=toggles.espEnabled; bb.Parent=hrp
	local nL=Instance.new("TextLabel",bb); nL.Size=UDim2.new(1,0,0,18)
	nL.BackgroundTransparency=1; nL.Text=p.DisplayName; nL.TextColor3=col
	nL.TextScaled=true; nL.Font=Enum.Font.GothamBold; nL.TextStrokeTransparency=0.5; nL.Visible=toggles.espNames; d.nL=nL
	local dL=Instance.new("TextLabel",bb); dL.Size=UDim2.new(1,0,0,18); dL.Position=UDim2.new(0,0,0,20)
	dL.BackgroundTransparency=1; dL.Text="0m"; dL.TextColor3=Color3.fromRGB(200,200,200)
	dL.TextScaled=true; dL.Font=Enum.Font.GothamBold; dL.TextStrokeTransparency=0.5; dL.Visible=toggles.espDistance; d.dL=dL
	local hbBG=Instance.new("Frame",bb); hbBG.Size=UDim2.new(1,0,0,6); hbBG.Position=UDim2.new(0,0,0,36)
	hbBG.BackgroundColor3=Color3.fromRGB(40,40,40); hbBG.BorderSizePixel=0; hbBG.Visible=toggles.espHealthbar
	Instance.new("UICorner",hbBG).CornerRadius=UDim.new(0,3); d.hbBG=hbBG
	local hbF=Instance.new("Frame",hbBG); hbF.Size=UDim2.new(1,0,1,0)
	hbF.BackgroundColor3=Color3.fromRGB(80,220,80); hbF.BorderSizePixel=0
	Instance.new("UICorner",hbF).CornerRadius=UDim.new(0,3); d.hbF=hbF
	d.bb=bb; espObjects[p]=d
end

TabESP:Toggle({Title="ESP On/Off",Value=false,Callback=function(V)
	toggles.espEnabled=V
	if V then for _,p in pairs(Players:GetPlayers()) do if p~=player then task.spawn(buildESP,p) end end
	else for p,_ in pairs(espObjects) do removeESP(p) end end
end})
TabESP:Toggle({Title="Name ESP",Value=false,Callback=function(V) toggles.espNames=V end})
TabESP:Toggle({Title="Distance ESP",Value=false,Callback=function(V) toggles.espDistance=V end})
TabESP:Toggle({Title="Healthbar ESP",Value=false,Callback=function(V) toggles.espHealthbar=V end})
TabESP:Toggle({Title="Team Check",Value=false,Callback=function(V)
	toggles.espTeamCheck=V
	if V then for p,_ in pairs(espObjects) do if onSameTeam(p) then removeESP(p) end end end
end})

TabVisuals:Toggle({Title="Xray Vision",Value=false,Callback=function(V)
	toggles.xray=V
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			if V then if not VH_xrayParts[v] then VH_xrayParts[v]=v.Transparency end; v.Transparency=0.6
			else if VH_xrayParts[v]~=nil then v.Transparency=VH_xrayParts[v]; VH_xrayParts[v]=nil end end
		end
	end
end})
TabVisuals:Toggle({Title="Fullbright",Value=false,Callback=function(V)
	if V then Lighting.Brightness=2;Lighting.ClockTime=12;Lighting.GlobalShadows=false;Lighting.Ambient=Color3.new(1,1,1)
	else Lighting.Brightness=origLight.Brightness;Lighting.ClockTime=origLight.ClockTime;Lighting.GlobalShadows=origLight.GlobalShadows;Lighting.Ambient=origLight.Ambient end
end})
TabVisuals:Toggle({Title="Night Mode",Value=false,Callback=function(V)
	if V then Lighting.ClockTime=0;Lighting.Brightness=0.2
	else Lighting.ClockTime=origLight.ClockTime;Lighting.Brightness=origLight.Brightness end
end})
TabVisuals:Toggle({Title="No Fog",Value=false,Callback=function(V) Lighting.FogEnd=V and 1e6 or origLight.FogEnd end})

TabPos:Input({Title="Position Name",Placeholder="Enter name...",Callback=function(V) getgenv().VH_posNameInput=V end})
TabPos:Button({Title="Save Current Position",Callback=function()
	local hrp=getHRP(player.Character); if not hrp then return end
	local name=VH_posNameInput~="" and VH_posNameInput or ("Position "..tostring(#VH_savedPositions+1))
	local cf=hrp.CFrame; table.insert(VH_savedPositions,{name=name,cf=cf})
	TabPos:Button({Title="TP: "..name,Callback=function()
		local h2=getHRP(player.Character); if h2 then h2.CFrame=cf end
	end})
	getgenv().VH_posNameInput=""
end})

TabItems:Toggle({Title="TP Tool",Value=false,Callback=function(V)
	toggles.tptool=V
	if V then
		getgenv().VH_tpTool=Instance.new("Tool"); VH_tpTool.Name="TP Tool"; VH_tpTool.RequiresHandle=false; VH_tpTool.Parent=player.Backpack
		VH_tpTool.Activated:Connect(function() local hrp=getHRP(player.Character) if hrp then hrp.CFrame=mouse.Hit*CFrame.new(0,3,0) end end)
	else if VH_tpTool then VH_tpTool:Destroy(); getgenv().VH_tpTool=nil end end
end})
TabItems:Toggle({Title="Glide Tool",Value=false,Callback=function(V)
	toggles.glidetool=V
	if V then
		if not VH_glideTool then getgenv().VH_glideTool=VH_createGlideTool() end
		VH_glideTool.Parent=player.Backpack
	else
		if VH_glideTool then VH_glideTool:Destroy(); getgenv().VH_glideTool=nil end
	end
end})

TabUtil:Toggle({Title="Hide in Baseplate",Value=false,Callback=function(V)
	toggles.hide=V; local hrp=getHRP(player.Character); if not hrp then return end
	if V then
		getgenv().VH_preCloudPos=hrp.CFrame
		if VH_roomFolder then VH_roomFolder:Destroy(); getgenv().VH_roomFolder=nil end
		getgenv().VH_roomFolder=Instance.new("Folder",workspace); VH_roomFolder.Name="BoloverRoom"
		local cf=CFrame.new(math.random(-9e4,9e4),4e4,math.random(-9e4,9e4))
		local p=Instance.new("Part",VH_roomFolder); p.Size=Vector3.new(80,1,80); p.CFrame=cf
		p.Anchored=true; p.Color=Color3.new(1,1,1); p.Material=Enum.Material.SmoothPlastic
		hrp.CFrame=cf*CFrame.new(0,5,0)
	else
		if VH_roomFolder then VH_roomFolder:Destroy(); getgenv().VH_roomFolder=nil end
		if VH_preCloudPos then hrp.CFrame=VH_preCloudPos end
	end
end})
TabUtil:Toggle({Title="Auto Hide When Low",Value=false,Callback=function(V) toggles.autoHide=V end})
TabUtil:Toggle({Title="Instant Interact",Value=false,Callback=function(V) toggles.instantInteract=V end})

TabSettings:Toggle({Title="Anti AFK",Value=false,Callback=function(V) toggles.antiAfk=V end})
TabSettings:Toggle({Title="Anti Fling",Value=false,Callback=function(V) toggles.antifling=V end})
TabSettings:Toggle({Title="Anti Sit",Value=false,Callback=function(V) toggles.antisit=V end})
TabSettings:Toggle({Title="Anti Stun",Value=false,Callback=function(V) toggles.antistun=V end})
TabSettings:Button({Title="Smallest Server",Callback=function()
	local ok,res=pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
	if not ok then return end
	for _,v in pairs(res.data) do if v.playing<v.maxPlayers and v.id~=game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId,v.id); break end end
end})
TabSettings:Button({Title="Biggest Server",Callback=function()
	local ok,res=pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")) end)
	if not ok then return end
	for _,v in pairs(res.data) do if v.playing<v.maxPlayers and v.id~=game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId,v.id); break end end
end})
TabSettings:Button({Title="Rejoin",Callback=function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId) end})

RunService.Heartbeat:Connect(function()
	if not toggles.espEnabled then return end
	local myHRP=getHRP(player.Character)
	for _,p in pairs(Players:GetPlayers()) do
		if p==player then continue end
		if toggles.espTeamCheck and onSameTeam(p) then if espObjects[p] then removeESP(p) end; continue end
		if not p.Character then continue end
		local hrp=getHRP(p.Character); if not hrp then continue end
		if not espObjects[p] or not espObjects[p].hl or not espObjects[p].hl.Parent then buildESP(p); continue end
		local d=espObjects[p]; local col=getTeamColor(p)
		if d.hl then d.hl.FillColor=col; d.hl.OutlineColor=col; d.hl.Enabled=true end
		if d.nL then d.nL.TextColor3=col; d.nL.Text=p.DisplayName; d.nL.Visible=toggles.espNames end
		if d.dL then d.dL.Visible=toggles.espDistance
			if toggles.espDistance and myHRP then d.dL.Text=math.floor((hrp.Position-myHRP.Position).Magnitude).."m" end end
		if d.hbBG then d.hbBG.Visible=toggles.espHealthbar end
		if d.hbF then
			local h=getHum(p.Character)
			if h and toggles.espHealthbar then
				local pct=h.Health/math.max(h.MaxHealth,1)
				d.hbF.Size=UDim2.new(math.clamp(pct,0,1),0,1,0)
				d.hbF.BackgroundColor3=Color3.fromRGB((1-pct)*220,pct*220,40)
			end
		end
		if d.bb then d.bb.Enabled=toggles.espNames or toggles.espDistance or toggles.espHealthbar end
	end
end)

local function hookESP(p)
	if p==player then return end
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart",10); task.wait(0.3)
		if toggles.espEnabled then buildESP(p) end
	end)
end
Players.PlayerAdded:Connect(hookESP)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
for _,p in pairs(Players:GetPlayers()) do hookESP(p) end

local aimSG = Instance.new("ScreenGui")
aimSG.Name = "BoloverAim"; aimSG.ResetOnSpawn = false
aimSG.IgnoreGuiInset = true; aimSG.DisplayOrder = 997
pcall(function() aimSG.Parent = game:GetService("CoreGui") end)
if not aimSG.Parent then aimSG.Parent = player.PlayerGui end

local fovF = Instance.new("Frame", aimSG)
fovF.AnchorPoint = Vector2.new(0.5, 0.5)
fovF.BackgroundTransparency = 1
fovF.BorderSizePixel = 0
fovF.Visible = false
local fovCorner = Instance.new("UICorner", fovF)
fovCorner.CornerRadius = UDim.new(1, 0)
local fovSt = Instance.new("UIStroke", fovF)
fovSt.Thickness = 1.5
fovSt.Color = Color3.fromRGB(255,255,255)

local function aimValid(p)
	if not p or not p.Character then return false end
	local h=getHum(p.Character)
	if toggles.deadCheck and h and h.Health<=0 then return false end
	if toggles.teamCheck and onSameTeam(p) then return false end
	if toggles.wallCheck then
		local hrp=getHRP(p.Character); if hrp then
			local rp=RaycastParams.new(); rp.FilterDescendantsInstances={player.Character}; rp.FilterType=Enum.RaycastFilterType.Exclude
			local res=workspace:Raycast(camera.CFrame.Position,hrp.Position-camera.CFrame.Position,rp)
			if res and not res.Instance:IsDescendantOf(p.Character) then return false end
		end
	end
	return true
end

local function getAimTarget()
	local best,bestD=nil,AimbotSettings.FOVSize
	local ctr=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
	for _,p in pairs(Players:GetPlayers()) do
		if p~=player and aimValid(p) then
			local hrp=getHRP(p.Character); if hrp then
				local sp,os=camera:WorldToViewportPoint(hrp.Position)
				if os then local d=(Vector2.new(sp.X,sp.Y)-ctr).Magnitude; if d<bestD then bestD=d; best=p end end
			end
		end
	end
	return best
end

RunService.RenderStepped:Connect(function(dt)
	getgenv().VH_fovAnimTime = VH_fovAnimTime + dt
	local t = VH_fovAnimTime
	local ctr = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
	fovF.Size = UDim2.new(0, AimbotSettings.FOVSize*2, 0, AimbotSettings.FOVSize*2)
	fovF.Position = UDim2.new(0, ctr.X, 0, ctr.Y)
	fovF.Visible = toggles.fovCircle
	local mode = VH_fovColorMode
	if mode=="Rainbow" then
		getgenv().VH_rainbowHue=(VH_rainbowHue+0.005)%1; fovSt.Color=Color3.fromHSV(VH_rainbowHue,1,1); fovSt.Thickness=1.5
	elseif mode=="Red" then
		local pulse=(math.sin(t*6)+1)/2; fovSt.Color=Color3.fromRGB(120+pulse*135,0,0); fovSt.Thickness=1.5+pulse*1.5
	elseif mode=="Orange" then
		local pulse=(math.sin(t*4)+1)/2; fovSt.Color=Color3.fromRGB(255,math.floor(80+pulse*85),0); fovSt.Thickness=1.5
	elseif mode=="Yellow" then
		local f=(math.sin(t*20)+1)/2; fovSt.Color=Color3.fromRGB(255,200+math.floor(f*55),0); fovSt.Thickness=1+f
	elseif mode=="Lime" then
		fovSt.Color=Color3.fromHSV(0.33+math.sin(t*2)*0.05,1,1); fovSt.Thickness=1.5
	elseif mode=="Cyan" then
		local w=(math.sin(t*5)+1)/2; fovSt.Color=Color3.fromRGB(0,220,255); fovSt.Thickness=1+w*2
	elseif mode=="Blue" then
		fovSt.Color=Color3.fromHSV(0.62+math.sin(t*1.5)*0.05,1,1); fovSt.Thickness=1.5
	elseif mode=="Purple" then
		fovSt.Color=Color3.fromHSV(0.77+math.sin(t*3)*0.04,1,1); fovSt.Thickness=1.5
	elseif mode=="Pink" then
		fovSt.Color=Color3.fromHSV(0.88+math.sin(t*3.5)*0.03,0.6,1); fovSt.Thickness=1.5
	elseif mode=="Hot Pink" then
		local pulse=(math.sin(t*10)+1)/2; fovSt.Color=Color3.fromRGB(255,20,147); fovSt.Thickness=1+pulse*3
	elseif mode=="White" then
		local glow=(math.sin(t*2)+1)/2; fovSt.Color=Color3.fromRGB(255,255,255); fovSt.Thickness=1+glow*1.5
	end
	if not toggles.aimbot then AimbotSettings.CurrentTarget=nil; return end
	if AimbotSettings.CurrentTarget then
		local hrp=getHRP(AimbotSettings.CurrentTarget.Character)
		if not hrp or not aimValid(AimbotSettings.CurrentTarget) then AimbotSettings.CurrentTarget=nil end
	end
	if not AimbotSettings.CurrentTarget then AimbotSettings.CurrentTarget=getAimTarget() end
	if AimbotSettings.CurrentTarget then
		local hrp=getHRP(AimbotSettings.CurrentTarget.Character); if hrp then
			local sp,os=camera:WorldToViewportPoint(hrp.Position)
			if not os or (Vector2.new(sp.X,sp.Y)-ctr).Magnitude>AimbotSettings.FOVSize*1.5 then AimbotSettings.CurrentTarget=nil; return end
			camera.CFrame=camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position,hrp.Position),math.clamp(AimbotSettings.Smoothing,0.01,1))
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	if VH_LocalFlying then getgenv().VH_LocalFlying=false; VH_startFly() end
	if toggles.bypassJump then
		if VH_bypassJumpConn then VH_bypassJumpConn:Disconnect() end
		getgenv().VH_bypassJumpConn = UserInputService.JumpRequest:Connect(VH_doBypassJump)
	end
	if toggles.instantRespawn then
		local h=char:WaitForChild("Humanoid",5)
		if h then h.Died:Connect(function() task.wait(0.05); player:LoadCharacter() end) end
	end
	if toggles.espEnabled then
		task.wait(0.5)
		for _,p in pairs(Players:GetPlayers()) do if p~=player then buildESP(p) end end
	end
end)

RunService.Heartbeat:Connect(function()
	local char=player.Character; if not char then return end
	local hrp,hum=getHRP(char),getHum(char); if not hrp or not hum then return end
	if toggles.speed and hum.MoveDirection.Magnitude>0 then
		hrp.Velocity=Vector3.new(hum.MoveDirection.X*VH_customSpeed,hrp.Velocity.Y,hum.MoveDirection.Z*VH_customSpeed)
	end
	if toggles.jumpHigh then hum.JumpPower=VH_customJump end
	if toggles.spinbot and not toggles.fling then
		getgenv().VH_spinAngle=(VH_spinAngle+4)%360; hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(VH_spinAngle),0)
	end
	if toggles.fling then
		getgenv().VH_flingAngle=(VH_flingAngle+60)%360
		local flingBG=hrp:FindFirstChild("FlingBG")
		if not flingBG then flingBG=Instance.new("BodyGyro",hrp); flingBG.Name="FlingBG"; flingBG.MaxTorque=Vector3.new(0,1e9,0); flingBG.P=1e9; flingBG.D=0 end
		flingBG.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(VH_flingAngle),0)
		hrp.RotVelocity=Vector3.new(0,9999,0)
		for _,p in pairs(Players:GetPlayers()) do
			if p~=player and p.Character then
				local ph=getHRP(p.Character)
				if ph and (ph.Position-hrp.Position).Magnitude<6 then
					local bv=ph:FindFirstChild("FlingBV") or Instance.new("BodyVelocity",ph)
					bv.Name="FlingBV"; bv.MaxForce=Vector3.new(1e9,1e9,1e9)
					bv.Velocity=Vector3.new(math.random(-300,300),800+math.random(0,400),math.random(-300,300))
					game:GetService("Debris"):AddItem(bv,0.15)
				end
			end
		end
	else
		local fg=hrp:FindFirstChild("FlingBG"); if fg then fg:Destroy() end
	end
	if toggles.antisit then hum.Sit=false end
	if toggles.antistun then hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end
	if not toggles.fling and toggles.antifling then hrp.RotVelocity=Vector3.new(0,0,0) end
	if toggles.untouchable then
		for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=false end end
	else
		for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanTouch=true end end
	end
	if toggles.bringTarget and VH_persistentTarget and VH_persistentTarget.Character then
		local th=getHRP(VH_persistentTarget.Character); if th then th.CFrame=hrp.CFrame*CFrame.new(0,0,-3) end
	end
	if toggles.autoHide then
		local hp=(hum.Health/math.max(hum.MaxHealth,1))*100
		if hp<30 and not toggles.hide then
			getgenv().VH_autoHideReturnPos=hrp.CFrame
			if VH_roomFolder then VH_roomFolder:Destroy(); getgenv().VH_roomFolder=nil end
			getgenv().VH_roomFolder=Instance.new("Folder",workspace); VH_roomFolder.Name="BoloverRoom"
			local cf=CFrame.new(math.random(-9e4,9e4),4e4,math.random(-9e4,9e4))
			hrp.CFrame=cf*CFrame.new(0,5,0); toggles.hide=true
		elseif hp>=50 and toggles.hide and VH_autoHideReturnPos then
			hrp.CFrame=VH_autoHideReturnPos; getgenv().VH_autoHideReturnPos=nil; toggles.hide=false
			if VH_roomFolder then VH_roomFolder:Destroy(); getgenv().VH_roomFolder=nil end
		end
	end
	for _,p in pairs(Players:GetPlayers()) do
		if p~=player and p.Character then
			local ph=getHRP(p.Character); if not ph then continue end
			local dist=(ph.Position-hrp.Position).Magnitude
			local doBring=toggles.bringAll or (toggles.bringNearby and dist<70)
			local doFreeze=toggles.frozeAll or (toggles.freezeAura and dist<35)
			if doBring or doFreeze then
				if not VH_playerPositions[p.UserId] then VH_playerPositions[p.UserId]=ph.CFrame end
				ph.Anchored=true; if doBring then ph.CFrame=hrp.CFrame*CFrame.new(0,0,-5) end
			else
				if VH_playerPositions[p.UserId] then ph.Anchored=false; ph.CFrame=VH_playerPositions[p.UserId]; VH_playerPositions[p.UserId]=nil end
			end
			if toggles.hitbox then ph.Size=Vector3.new(VH_hitboxSize,VH_hitboxSize,VH_hitboxSize); ph.Transparency=0.6
			else ph.Size=Vector3.new(2,2,1); ph.Transparency=0 end
		end
	end
end)

local noclipOriginals = {}
RunService.Stepped:Connect(function()
	if not player.Character then return end
	if toggles.noclip then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				if noclipOriginals[v] == nil then noclipOriginals[v] = v.CanCollide end
				v.CanCollide = false
			end
		end
	else
		for v,orig in pairs(noclipOriginals) do
			if v and v.Parent then v.CanCollide = orig end
		end
		noclipOriginals = {}
	end
end)

player.Idled:Connect(function()
	if toggles.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

UserInputService.JumpRequest:Connect(function()
	if toggles.infjump then local h=getHum(player.Character) if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	if toggles.instantInteract then pcall(function() fireproximityprompt(prompt) end) end
end)

local WindUI = getgenv().WindUI or loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:Notify({
	Title = "Vexes Hub",
	Content = "Loaded! @khezn21 on TikTok",
	Duration = 4,
})