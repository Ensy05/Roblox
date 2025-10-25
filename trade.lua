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
local running, aborted = false, false
local gui

--// Create GUI
local function createTradeGui()
	if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TradeMenuGui") then
		LocalPlayer.PlayerGui.TradeMenuGui:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "TradeMenuGui"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	-- Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 240)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	frame.Parent = gui

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 255, 180)

	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Auto Trade"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = frame

	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(0, 260, 0, 25)
	dropdown.Position = UDim2.new(0, 0, 0, 50)
	dropdown.Text = "Click to Select"
	dropdown.Font = Enum.Font.Gotham
	dropdown.TextSize = 14
	dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropdown.Parent = frame
	local ddCorner = Instance.new("UICorner", dropdown)
	ddCorner.CornerRadius = UDim.new(0, 6)

	-- Scrollable player list
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(0, 260, 0, 80)
	listFrame.Position = UDim2.new(0, 5, 0, 50)
	listFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	listFrame.ScrollBarThickness = 6
	listFrame.Visible = false
	listFrame.BorderSizePixel = 0
	listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	listFrame.Parent = frame
	local lfCorner = Instance.new("UICorner", listFrame)
	lfCorner.CornerRadius = UDim.new(0, 6)
	local lfLayout = Instance.new("UIListLayout", listFrame)
	lfLayout.Padding = UDim.new(0, 2)
	lfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local durationBox = Instance.new("TextBox")
	durationBox.Size = UDim2.new(0, 140, 0, 25)
	durationBox.Position = UDim2.new(0, 80, 0, 80)
	durationBox.PlaceholderText = "Duration (s)"
	durationBox.Text = ""
	durationBox.Font = Enum.Font.Gotham
	durationBox.TextSize = 14
	durationBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	durationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	durationBox.Parent = frame

	-- Interval field

	local intervalBox = Instance.new("TextBox")
	intervalBox.Size = UDim2.new(0, 140, 0, 25)
	intervalBox.Position = UDim2.new(0, 80, 0, 110)
	intervalBox.PlaceholderText = "Interval (s)"
	intervalBox.Text = ""
	intervalBox.Font = Enum.Font.Gotham
	intervalBox.TextSize = 14
	intervalBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	intervalBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	intervalBox.Parent = frame

	-- Buttons
	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0, 120, 0, 35)
	startBtn.Position = UDim2.new(0, 25, 0, 130)
	startBtn.Text = "Start"
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 16
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
	startBtn.Parent = frame
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 35)
	cancelBtn.Position = UDim2.new(0, 155, 0, 130)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 16
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
	cancelBtn.Parent = frame
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 20)
	statusLabel.Position = UDim2.new(0, 10, 0, 180)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 14
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Ready."
	statusLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Parent = frame

	-- Player list logic
	local selectedPlayer = nil
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

	dropdown.MouseButton1Click:Connect(function()
		listFrame.Visible = not listFrame.Visible
		listFrame.ZIndex = 10
	end)

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
		running, aborted = true, false
		startBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		statusLabel.Text = string.format("🟢 Running (%d loops)", loops)

		task.spawn(function()
			for i = 1, loops do
				if aborted then break end
				RemoteEvent:FireServer("TradeRequest", selectedPlayer)
				statusLabel.Text = string.format("🟢 Loop %d/%d", i, loops)
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

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if gui then
			gui.Enabled = not gui.Enabled
			print(gui.Enabled and "[UI] Shown." or "[UI] Hidden.")
		end
	elseif input.KeyCode == Enum.KeyCode.BackSlash then
		if gui then
			gui:Destroy()
			gui = nil
			print("[UI] Destroyed.")
		end
	end
end)



