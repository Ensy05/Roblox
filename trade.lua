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
local connections = {} -- store active event connections
local running, aborted = false, false
local gui

--// Create GUI
local function createTradeGui()
	if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TradeMenuGui") then
		print("[TradeGUI] Destroying old instance")
		LocalPlayer.PlayerGui.TradeMenuGui:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "TradeMenuGui"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	print("[TradeGUI] Created ScreenGui")

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
	title.Position = UDim2.new(0, 0, 0, 10)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = frame

	-- Dropdown
	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(0, 260, 0, 25)
	dropdown.Position = UDim2.new(0, 20, 0, 45)
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
	listFrame.Position = UDim2.new(0, 20, 0, 75)
	listFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	listFrame.ScrollBarThickness = 6
	listFrame.Visible = false
	listFrame.BorderSizePixel = 0
	listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	listFrame.ZIndex = 5 -- ensures scrollbar is drawn on top
	listFrame.Parent = frame
	
	local lfCorner = Instance.new("UICorner", listFrame)
	lfCorner.CornerRadius = UDim.new(0, 6)
	
	local lfLayout = Instance.new("UIListLayout", listFrame)
	lfLayout.Padding = UDim.new(0, 2)
	lfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
	lfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, lfLayout.AbsoluteContentSize.Y)
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("GuiObject") then
				child.ZIndex = 6 -- child buttons above even higher
			end
		end
	end)

	lfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, lfLayout.AbsoluteContentSize.Y)
	end)

	-- Duration box
	local durationBox = Instance.new("TextBox")
	durationBox.Size = UDim2.new(0, 140, 0, 25)
	durationBox.Position = UDim2.new(0, 80, 0, 85)
	durationBox.PlaceholderText = "Duration (s)"
	durationBox.Text = ""
	durationBox.Font = Enum.Font.Gotham
	durationBox.TextSize = 14
	durationBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	durationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	durationBox.Parent = frame

	-- Interval box
	local intervalBox = Instance.new("TextBox")
	intervalBox.Size = UDim2.new(0, 140, 0, 25)
	intervalBox.Position = UDim2.new(0, 80, 0, 130)
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
	startBtn.Position = UDim2.new(0, 25, 0, 170)
	startBtn.Text = "Start"
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 16
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
	startBtn.Parent = frame
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 35)
	cancelBtn.Position = UDim2.new(0, 155, 0, 170)
	cancelBtn.Text = "Cancel"
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 16
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
	cancelBtn.Parent = frame
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

	-- Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 20)
	statusLabel.Position = UDim2.new(0, 10, 0, 210)
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
		print("[PlayerList] Refreshing list...")
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
		end

		local others = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				others += 1
				print("[PlayerList] Found player:", plr.Name)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 25)
				btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				btn.Text = plr.Name
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Parent = listFrame
				btn.ZIndex = 6
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
				btn.MouseButton1Click:Connect(function()
					selectedPlayer = plr
					print("[PlayerList] Selected player:", plr.Name)
					dropdown.Text = "Selected: " .. plr.Name
					listFrame.Visible = false
				end)
			end
		end

		if others == 0 then
			print("[PlayerList] No other players found.")
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -4, 0, 25)
			label.Text = "(no other players)"
			label.Font = Enum.Font.Gotham
			label.TextSize = 14
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(200, 200, 200)
			label.Parent = listFrame
		end

		listFrame.CanvasSize = UDim2.new(0, 0, 0, lfLayout.AbsoluteContentSize.Y)
		print("[PlayerList] Refresh complete, total:", others)
	end

	-- Refresh player list
	task.defer(function()
		print("[TradeGUI] Initial list refresh...")
		refreshList()
		task.wait(1)
		print("[TradeGUI] Second list refresh after delay")
		refreshList()
	end)

	table.insert(connections, Players.PlayerAdded:Connect(function(plr)
		print("[PlayerList] Player joined:", plr.Name)
		refreshList()
	end))

	table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
		print("[PlayerList] Player left:", plr.Name)
		refreshList()
	end))

	-- Dropdown toggle
	dropdown.MouseButton1Click:Connect(function()
		print("[Dropdown] Clicked, refreshing and toggling visibility")
		refreshList()
		task.wait()
		listFrame.Visible = not listFrame.Visible
		print("[Dropdown] ListFrame.Visible =", listFrame.Visible)
	end)

	-- Click outside to close
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if listFrame.Visible and not listFrame:IsAncestorOf(input.Target) and input.Target ~= dropdown then
				listFrame.Visible = false
				print("[Dropdown] Click outside detected, hiding list")
			end
		end
	end)

	-- Start button
	startBtn.MouseButton1Click:Connect(function()
		if running then
			print("[TradeLoop] Already running, ignoring Start click")
			return
		end
		if not selectedPlayer then
			print("[TradeLoop] Tried to start with no player selected")
			statusLabel.Text = "⚠️ Select a player first!"
			return
		end

		-- Function loop to trade

		local totalTime = tonumber(durationBox.Text) or 60
		local interval = tonumber(intervalBox.Text) or 2
		local loops = math.floor(totalTime / interval)
		print(string.format("[TradeLoop] Starting for %d seconds (%d loops, %.1fs interval)", totalTime, loops, interval))

		running, aborted = true, false
		startBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		statusLabel.Text = string.format("🟢 Running (%d loops)", loops)

		-- Safe trade acceptance detector (non-blocking)

		task.spawn(function()
			for i = 1, loops do
				if aborted then break end
				if not selectedPlayer or selectedPlayer.Parent ~= Players then
					print("[TradeLoop] Player left or invalid, aborting.")
					statusLabel.Text = "⚠️ Player left or invalid!"
					break
				end
		
				local ok, err = pcall(function()
					RemoteEvent:FireServer("TradeRequest", selectedPlayer)
				end)
		
				if not ok then
					print("[TradeLoop] Trade error:", err)
					statusLabel.Text = "⚠️ Trade error: " .. tostring(err)
					break
				end
		
				statusLabel.Text = string.format("🟢 Loop %d/%d", i, loops)
				print(string.format("[TradeLoop] Loop %d/%d successful", i, loops))
				task.wait(interval)
			end
		
			if aborted then
				print("[TradeLoop] Aborted manually.")
				statusLabel.Text = "🔴 Aborted."
			else
				print("[TradeLoop] Finished all loops successfully.")
				statusLabel.Text = "✅ Done."
			end
		
			startBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
			running = false
		end)
	end)

	-- Cancel button
	cancelBtn.MouseButton1Click:Connect(function()
		if running then
			print("[TradeLoop] Cancel pressed.")
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
			print(gui.Enabled and "[Keybind] GUI shown" or "[Keybind] GUI hidden")
		end

	elseif input.KeyCode == Enum.KeyCode.BackSlash then
		if gui then
			print("[Keybind] ⚠️ Full shutdown initiated...")

			-- Stop active loops
			if running then
				aborted = true
				running = false
				print("[Shutdown] Trade loop stopped.")
			end

			-- Disconnect stored event connections
			for _, conn in ipairs(connections) do
				if typeof(conn) == "RBXScriptConnection" then
					conn:Disconnect()
				end
			end
			table.clear(connections)
			print("[Shutdown] PlayerAdded/PlayerRemoving connections cleared.")

			-- Disconnect RemoteEvent listeners
			pcall(function()
				if getconnections then
					for _, conn in ipairs(getconnections(RemoteEvent.OnClientEvent)) do
						conn:Disconnect()
					end
					print("[Shutdown] RemoteEvent connections disconnected.")
				end
			end)

			-- Cancel coroutines (safe in Delta)
			pcall(function()
				if getgc then
					for _, obj in ipairs(getgc(true)) do
						if type(obj) == "thread" then
							task.cancel(obj)
						end
					end
					print("[Shutdown] Stray coroutines canceled.")
				end
			end)

			-- Destroy GUI
			gui:Destroy()
			gui = nil
			print("[Shutdown] GUI destroyed, memory released.")
		end
	end
end)

