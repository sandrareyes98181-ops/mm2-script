local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local espEnabled = false
local autoShootEnabled = false
local hitboxEnabled = false
local hitboxSize = 5

local draggingGUI = false

local function isMurder(player)
	if not player.Character then return false end
	if player.Character:FindFirstChild("Knife") then return true end
	if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") then return true end
	return false
end

local function isSheriff(player)
	if not player.Character then return false end
	if player.Character:FindFirstChild("Gun") then return true end
	if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun") then return true end
	return false
end

local function createESP(player)
	if player == LocalPlayer or not player.Character then return end
	if player.Character:FindFirstChild("ESP") then return end
	
	local h = Instance.new("Highlight")
	h.Name = "ESP"
	h.FillTransparency = 0.5
	h.Parent = player.Character
end

local function updateESP(player)
	if not player.Character then return end
	
	if not espEnabled then
		local e = player.Character:FindFirstChild("ESP")
		if e then e:Destroy() end
		return
	end
	
	local e = player.Character:FindFirstChild("ESP")
	if not e then return end
	
	if isMurder(player) then
		e.FillColor = Color3.fromRGB(255,0,0)
	elseif isSheriff(player) then
		e.FillColor = Color3.fromRGB(0,0,255)
	else
		e.FillColor = Color3.fromRGB(0,255,0)
	end
end

local function applyHitbox(player)
	if player == LocalPlayer or not player.Character then return end
	
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	if hitboxEnabled then
		root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
		root.Transparency = 0.5
		root.CanCollide = false
	else
		root.Size = Vector3.new(2,2,1)
		root.Transparency = 1
	end
end

local function canSeeTarget(targetPlayer)
	local char = LocalPlayer.Character
	if not char then return false end
	
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	
	local targetChar = targetPlayer.Character
	if not targetChar then return false end
	
	local partsToCheck = {
		targetChar:FindFirstChild("Head"),
		targetChar:FindFirstChild("HumanoidRootPart"),
		targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
	}
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	
	for _, part in ipairs(partsToCheck) do
		if part then
			local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
			if onScreen then
				local direction = (part.Position - origin)
				local result = workspace:Raycast(origin, direction, rayParams)
				
				if result and result.Instance and result.Instance:IsDescendantOf(targetChar) then
					return true
				end
			end
		end
	end
	
	return false
end

local function setupGunConnection()
	local char = LocalPlayer.Character
	if not char then return end
	
	local gun = char:FindFirstChild("Gun")
	if not gun then return end
	
	if gun:FindFirstChild("AutoHook") then return end
	
	local tag = Instance.new("BoolValue")
	tag.Name = "AutoHook"
	tag.Parent = gun
	
	gun.Activated:Connect(function()
		if not autoShootEnabled then return end
		
		local target = nil
		
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and isMurder(player) then
				if player.Character and player.Character:FindFirstChild("Head") then
					if canSeeTarget(player) then
						target = player
						break
					end
				end
			end
		end
		
		if not target then return end
		
		local root = char:FindFirstChild("HumanoidRootPart")
		local attach = root and root:FindFirstChild("GunRaycastAttachment")
		local remote = gun:FindFirstChild("Shoot")
		
		if not (attach and remote) then return end
		
		local head = target.Character.Head
		local direction = (head.Position - attach.WorldPosition).Unit * 500
		
		remote:FireServer(
			attach.WorldCFrame,
			CFrame.new(attach.WorldPosition + direction)
		)
	end)
end

local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.ResetOnSpawn = false

local circle = Instance.new("TextButton", gui)
circle.Size = UDim2.fromOffset(50,50)
circle.Position = UDim2.fromScale(0.1,0.5)
circle.BackgroundColor3 = Color3.fromRGB(0,200,255)
circle.Text = "A"
circle.TextScaled = true
circle.TextColor3 = Color3.fromRGB(10,20,30)
circle.Font = Enum.Font.GothamBold
circle.Draggable = true
Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(220,260)
main.Position = UDim2.fromScale(0.7,0.3)
main.BackgroundColor3 = Color3.fromRGB(15,30,45)
main.Visible = false
main.Active = true

main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingGUI = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingGUI = false
	end
end)

RunService.RenderStepped:Connect(function()
	if draggingGUI then
		local mouse = UserInputService:GetMouseLocation()
		main.Position = UDim2.fromOffset(mouse.X - 100, mouse.Y - 20)
	end
	
	local char = LocalPlayer.Character
	if char then
		setupGunConnection()
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			createESP(player)
			updateESP(player)
			applyHitbox(player)
		end
	end
end)

circle.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)

local function makeLabel(y, text)
	local lbl = Instance.new("TextLabel", main)
	lbl.Position = UDim2.fromOffset(0,y)
	lbl.Size = UDim2.new(1,0,0,18)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255,120,120)
	return lbl
end

local function makeButton(y, text, callback)
	local btn = Instance.new("TextButton", main)
	btn.Position = UDim2.fromOffset(30,y)
	btn.Size = UDim2.fromOffset(160,25)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(0,200,255)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local espLabel = makeLabel(10,"ESP: OFF")
makeButton(30,"Toggle ESP",function()
	espEnabled = not espEnabled
	espLabel.Text = espEnabled and "ESP: ON" or "ESP: OFF"
	espLabel.TextColor3 = espEnabled and Color3.fromRGB(150,255,200) or Color3.fromRGB(255,120,120)
end)

local shootLabel = makeLabel(60,"Auto Shot: OFF")
makeButton(80,"Toggle Auto Shot",function()
	autoShootEnabled = not autoShootEnabled
	shootLabel.Text = autoShootEnabled and "Auto Shot: ON" or "Auto Shot: OFF"
	shootLabel.TextColor3 = autoShootEnabled and Color3.fromRGB(150,255,200) or Color3.fromRGB(255,120,120)
end)

local hitboxLabel = makeLabel(110,"Hitbox: OFF")
makeButton(130,"Toggle Hitbox",function()
	hitboxEnabled = not hitboxEnabled
	hitboxLabel.Text = hitboxEnabled and "Hitbox: ON" or "Hitbox: OFF"
	hitboxLabel.TextColor3 = hitboxEnabled and Color3.fromRGB(150,255,200) or Color3.fromRGB(255,120,120)
end)

local sizeBox = Instance.new("TextBox", main)
sizeBox.Position = UDim2.fromOffset(30,170)
sizeBox.Size = UDim2.fromOffset(160,30)
sizeBox.PlaceholderText = "Hitbox Size (2-20)"
sizeBox.BackgroundColor3 = Color3.fromRGB(30,60,80)
sizeBox.TextColor3 = Color3.fromRGB(140,230,255)

sizeBox.FocusLost:Connect(function()
	local num = tonumber(sizeBox.Text)
	if num and num >= 2 and num <= 20 then
		hitboxSize = num
	end
end)
