--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Remote
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
	:WaitForChild("Framework")
	:WaitForChild("Network")
	:WaitForChild("Remote")
	:WaitForChild("RemoteEvent")

--// State
local tradeStarted = false
local aborted = false
local running = false
local gui -- forward declare for keybinds

--// Helper: Create main UI
local function createTradeGui()
	-- Prevent duplicates
	if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TradeMenuGui") then
		LocalPlayer.PlayerGui.TradeMenuGui:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "TradeMenuGui"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	-- Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 255)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 255, 180)
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Auto Trade"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = frame

	-- Player label
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Text = "Select:"
	playerLabel.Font = Enum.Font.Gotham
	playerLabel.TextSize = 14
	playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerLabel.BackgroundTransparency = 1
	playerLabel.Position = UDim2.new(0, 15, 0, 40)
	playerLabel.Size = UDim2.new(0, 120, 0, 20)
	playerLabel.Parent = frame

	-- Dropdown
	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(0, 260, 0, 25)
	dropdown.Position = UDim2.new(0, 20, 0, 65)
	dropdown.Text = "Click to Select"
	dropdown.Font = Enum.Font.Gotham
	dropdown.TextSize = 14
	dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropdown.Parent = frame

	local ddCorner = Instance.new("UICorner")
	ddCorner.CornerRadius = UDim.new(0, 6)
	ddCorner.Parent = dropdown

	-- Scrollable player list
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(0, 260, 0, 100)
	listFrame.Position = UDim2.new(0, 20, 0, 90)
	listFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	listFrame.Visible = false
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	listFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.BorderSizePixel = 0
	listFrame.Parent = frame

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = listFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = listFrame
	listLayout.Padding = UDim.new(0, 2)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Duration / interval
	local durLabel = Instance.new("TextLabel")
	durLabel.Text = "Duration (s):"
	durLabel.Font = Enum.Font.Gotham
	durLabel.TextSize = 14
	durLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	durLabel.BackgroundTransparency = 1
	durLabel.Position = UDim2.new(0, 15, 0, 200)
	durLabel.Parent = frame

	local durationBox = Instance.new("TextBox")
	durationBox.Size = UDim2.new(0, 100, 0, 25)
	durationBox.Position = UDim2.new(0, 120, 0, 200)
	durationBox.PlaceholderText = "60"
	durationBox.Text = ""
	durationBox.Font = Enum.Font.Gotham
	durationBox.TextSize = 14
	durationBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	durationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	durationBox.Parent = frame

	local intLabel = Instance.new("TextLabel")
	intLabel.Text = "Interval (s):"
	intLabel.Font = Enum.Font.Gotham
	intLabel.TextSize = 14
	intLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	intLabel.BackgroundTransparency = 1
	intLabel.Position = UDim2.new(0, 15, 0, 135)
	intLabel.Parent = frame

	local intervalBox = Instance.new("TextBox")
	intervalBox.Size = UDim2.new(0, 100, 0, 25)
	intervalBox.Position = UDim2.new(0, 120, 0, 135)
	intervalBox.PlaceholderText = "2"
	intervalBox.Text = ""
	intervalBox.Font = Enum.Font.Gotham
	intervalBox.TextSize = 14
	intervalBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	intervalBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	intervalBox.Parent = frame

	-- Buttons
	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0, 120, 0, 35)
	startBtn.Position = UDim2.new(0, 25, 0, 175)
	startBtn.Text = "Start"
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 16
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
	startBtn.Parent = frame

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 35)
	cancelBtn.Position = UDim2.new(0, 155, 0, 175)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 16
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
	cancelBtn.Parent = frame

	local uiCorner1 = Instance.new("UICorner")
	uiCorner1.CornerRadius = UDim.new(0, 8)
	uiCorner1.Parent = startBtn
	local uiCorner2 = Instance.new("UICorner")
	uiCorner2.CornerRadius = UDim.new(0, 8)
	uiCorner2.Parent = cancelBtn

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 20)
	statusLabel.Position = UDim2.new(0, 10, 0, 220)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 14
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Ready."
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Parent = frame

	-- State
	local selectedPlayer = nil

	-- Populate player list
	local function refreshList()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 25)
				btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				btn.Text = plr.Name
				btn.Font = Enum.Font.Gotham
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Parent = listFrame

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 4)
				btnCorner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					selectedPlayer = plr
					dropdown.Text = "Selected: " .. plr.Name
					listFrame.Visible = false
				end)
			end
		end
	end

	refreshList()
	Players.PlayerAdded:Connect(refreshList)
	Players.PlayerRemoving:Connect(refreshList)

	-- Dropdown toggle
	dropdown.MouseButton1Click:Connect(function()
		listFrame.Visible = not listFrame.Visible
	end)

	-- Close dropdown when clicking elsewhere
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if listFrame.Visible and not listFrame:IsAncestorOf(input.Target) and input.Target ~= dropdown then
				listFrame.Visible = false
			end
		end
	end)

	-- Start
	startBtn.MouseButton1Click:Connect(function()
		if running then return end
		if not selectedPlayer then
			statusLabel.Text = "⚠️ Select a player first!"
			return
		end

		local totalTime = tonumber(durationBox.Text) or 60
		local interval = tonumber(intervalBox.Text) or 2
		local loops = math.floor(totalTime / interval)

		running = true
		aborted = false
		tradeStarted = false

		startBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		statusLabel.Text = string.format("🟢 Running (%ds / %.1fs interval)", totalTime, interval)

		task.spawn(function()
			for i = 1, loops do
				if aborted then break end
				RemoteEvent:FireServer("TradeRequest", selectedPlayer)
				statusLabel.Text = string.format("🟢 Running (%d/%d)", i, loops)
				for _ = 1, math.floor(interval * 10) do
					if aborted then break end
					task.wait(0.1)
				end
			end

			if aborted then
				statusLabel.Text = "🔴 Aborted."
			else
				statusLabel.Text = "✅ Done."
			end
			startBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
			running = false
		end)
	end)

	-- Cancel
	cancelBtn.MouseButton1Click:Connect(function()
		if running then
			aborted = true
			statusLabel.Text = "🔴 Cancelling..."
			cancelBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
			task.wait(0.3)
			cancelBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
		end
	end)
end

createTradeGui()

--// Keybinds
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if gui then
			gui.Enabled = not gui.Enabled
			print(gui.Enabled and "[UI] Shown." or "[UI] Hidden.")
		end
	elseif input.KeyCode == Enum.KeyCode.Delete then
		if gui then
			gui:Destroy()
			gui = nil
			print("[UI] Destroyed.")
		end
	end
end)
