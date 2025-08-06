--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

--// Config
local Cookie = "" --// ROBLOSECURITY REQUIRED - Short for Roblox Cookie I promise this is safe it's fully open source
--// STREAMERS OR PLAYERS JOINS ARE NEEDED TO BE ON FOR IT TO WORK.

local gui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "StreamSniper"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 150)
frame.Position = UDim2.new(0.5, -140, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)

local bg = Instance.new("ImageLabel", frame)
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Position = UDim2.new(0, 0, 0, 0)
bg.Image = "rbxassetid://12655175600"
bg.ImageTransparency = 0.3
bg.BackgroundTransparency = 1

local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

--// UserInput Id, Join Buttons
local textBox = Instance.new("TextBox", frame)
textBox.PlaceholderText = "Enter UserID"
textBox.Size = UDim2.new(1, -20, 0, 30)
textBox.Position = UDim2.new(0, 10, 0, 15)
textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.BorderSizePixel = 0
textBox.ClearTextOnFocus = false
textBox.BackgroundTransparency = 0.2

local button = Instance.new("TextButton", frame)
button.Text = "Join"
button.Size = UDim2.new(1, -20, 0, 30)
button.Position = UDim2.new(0, 10, 0, 60)
button.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.BorderSizePixel = 0
button.BackgroundTransparency = 0.2

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 105)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.Text = "Waiting..."

local retrying = false
local retryLoop = nil

local function updateButton()
	if retrying then
		button.Text = "Stop"
		button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	else
		button.Text = "Join"
		button.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	end
end

button.MouseButton1Click:Connect(function()
	if retrying then
		retrying = false
		updateButton()
		statusLabel.Text = "Stopped."
	else
		local UserID = textBox.Text
		if not tonumber(UserID) then statusLabel.Text = "Invalid UserID" return end

		retrying = true
		updateButton()
		statusLabel.Text = "Checking..."

		retryLoop = coroutine.create(function()
			while retrying do
				local resp
				local success, decoded = pcall(function()
					resp = syn.request({
						Url = "https://presence.roblox.com/v1/presence/users";
						Method = "POST";
						Headers = {
							["Content-Type"] = "application/json";
							["User-Agent"] = "Mozilla/5.0";
							["Cookie"] = ".ROBLOSECURITY="..Cookie
						};
						Body = HttpService:JSONEncode({ userIds = { tonumber(UserID) } })
					})
				end)

				--// Debugging: If the request failed
				if not success then
					statusLabel.Text = "Error while checking presence."
					print("Error response:", resp)
					retrying = false
					updateButton()
					break
				end

				--// Debugging Log: Check full response
				print("Response Body:", resp.Body)

				if not decoded or not decoded.userPresences or not decoded.userPresences[1] then
					statusLabel.Text = "Invalid response"
					print("Invalid response:", resp.Body)
					retrying = false
					updateButton()
					break
				end

				local presence = decoded.userPresences[1]
				local userPresenceType = tostring(presence.userPresenceType)
				local placeId = tostring(presence.placeId)
				local gameId = tostring(presence.gameId)

				--// Debugging Log
				print("UserPresenceType:", userPresenceType, "PlaceId:", placeId, "GameId:", gameId)

				--// Logic for handling public/private servers
				if userPresenceType == "2" then
					if tonumber(placeId) and tonumber(placeId) ~= 0 then
						statusLabel.Text = "Joining..."
						--// Optimizing teleport initiation
						local success, err = pcall(function()
							TeleportService.TeleportInitFailed:Once(function(a1, a2, a3, a4, a5)
								warn(`Teleport failed:\n{a1}\n{a2}\n{a3}\n{a4}\n{a5}`)
							end)
							TeleportService:TeleportToPlaceInstance(placeId, gameId, Players.LocalPlayer)
						end)
						if success then
							retrying = false
							updateButton()
							break
						else
							statusLabel.Text = "Teleport failed"
							print("Teleport failed:", err)
							retrying = false
							updateButton()
							break
						end
					else
						statusLabel.Text = "User is in private server"
						retrying = false
						updateButton()
						break
					end
				elseif userPresenceType == "1" then
					statusLabel.Text = "User online but not in-game"
				elseif userPresenceType == "0" then
					statusLabel.Text = "User is offline"
					retrying = false
					updateButton()
					break
				else
					statusLabel.Text = "Failed to detect status"
					retrying = false
					updateButton()
					break
				end

				task.wait(0.1)
			end
		end)

		coroutine.resume(retryLoop)
	end
end)
