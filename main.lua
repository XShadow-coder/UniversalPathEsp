local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local highlights = {}
local connections = {}
local enabled = false
local currentContainer = nil

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "PathESP"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 360, 0, 150)
frame.Position = UDim2.new(0.5, -180, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(22,22,22)
frame.BorderSizePixel = 0
frame.Active = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(60,60,60)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Path ESP (Light Blue)"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

-- TextBox
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -20, 0, 40)
box.Position = UDim2.new(0, 10, 0, 45)
box.BackgroundColor3 = Color3.fromRGB(32,32,32)
box.PlaceholderText = 'workspace.Model.Folder'
box.Text = ""
box.ClearTextOnFocus = false
box.TextColor3 = Color3.new(1,1,1)
box.Font = Enum.Font.Gotham
box.TextSize = 15
box.BorderSizePixel = 0
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

-- Toggle Button
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(0.6, -5, 0, 35)
toggle.Position = UDim2.new(0, 10, 0, 95)
toggle.Text = "OFF"
toggle.BackgroundColor3 = Color3.fromRGB(120,40,40)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 15
toggle.BorderSizePixel = 0
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

-- Clean Button
local clean = Instance.new("TextButton", frame)
clean.Size = UDim2.new(0.4, -5, 0, 35)
clean.Position = UDim2.new(0.6, 5, 0, 95)
clean.Text = "CLEAN"
clean.BackgroundColor3 = Color3.fromRGB(80,80,80)
clean.TextColor3 = Color3.new(1,1,1)
clean.Font = Enum.Font.GothamBold
clean.TextSize = 15
clean.BorderSizePixel = 0
Instance.new("UICorner", clean).CornerRadius = UDim.new(0, 8)

-- Hide UI Button
local hideGui = Instance.new("TextButton", gui)
hideGui.Size = UDim2.new(0, 100, 0, 35)
hideGui.Position = UDim2.new(0, 10, 0, 10)
hideGui.Text = "Hide UI"
hideGui.BackgroundColor3 = Color3.fromRGB(35,35,35)
hideGui.TextColor3 = Color3.new(1,1,1)
hideGui.Font = Enum.Font.GothamBold
hideGui.TextSize = 14
hideGui.BorderSizePixel = 0
Instance.new("UICorner", hideGui).CornerRadius = UDim.new(0, 8)

--------------------------------------------------
-- DRAG (Mobile + PC)
--------------------------------------------------

local dragging = false
local dragStart
local startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------
-- ESP LOGIC
--------------------------------------------------

local function clearESP()
	for _, h in ipairs(highlights) do
		if h and h.Parent then
			h:Destroy()
		end
	end
	highlights = {}
end

local function disconnectAll()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	connections = {}
end

local function resolvePath(path)
	local success, result = pcall(function()
		return loadstring("return " .. path)()
	end)
	if success then return result end
	return nil
end

local function addESP(obj)
	if obj:IsA("BasePart") or obj:IsA("Model") then
		if not obj:FindFirstChild("ClientHighlight") then
			local h = Instance.new("Highlight")
			h.Name = "ClientHighlight"
			h.FillColor = Color3.fromRGB(0,255,255)
			h.FillTransparency = 0.25
			h.OutlineColor = Color3.fromRGB(0,200,255)
			h.OutlineTransparency = 0
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Parent = obj
			table.insert(highlights, h)
		end
	end
end

local function scan(container)
	for _, obj in ipairs(container:GetDescendants()) do
		addESP(obj)
	end
end

local function startListening(container)
	table.insert(connections,
		container.DescendantAdded:Connect(function(obj)
			addESP(obj)
		end)
	)
end

local function startESP(container)
	currentContainer = container
	scan(container)
	startListening(container)
end

local function fullCleanup()
	enabled = false
	toggle.Text = "OFF"
	toggle.BackgroundColor3 = Color3.fromRGB(120,40,40)
	clearESP()
	disconnectAll()
	currentContainer = nil
end

local function enableESP()
	fullCleanup()
	local container = resolvePath(box.Text)
	if not container then return end

	enabled = true
	toggle.Text = "ON"
	toggle.BackgroundColor3 = Color3.fromRGB(40,140,60)

	startESP(container)
end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

toggle.MouseButton1Click:Connect(function()
	if enabled then
		fullCleanup()
	else
		enableESP()
	end
end)

clean.MouseButton1Click:Connect(function()
	fullCleanup()
end)

hideGui.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)
