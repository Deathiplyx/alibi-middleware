-- Auto-Start Interrogation System for Roblox
-- Place this in a LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local MIDDLEWARE_URL = "http://192.168.254.3:3000"
local INTERROGATION_TIME = 900 -- 15 minutes
local RESPONSE_TIME_LIMIT = 60 -- 1 minute to respond
local TYPING_SPEED = 0.03

-- Game state
local gameState = {
    isInterrogationActive = false,
    timeRemaining = INTERROGATION_TIME,
    responseTimeRemaining = RESPONSE_TIME_LIMIT,
    conversationHistory = {},
    currentScenario = nil,
    currentEvidence = {},
    difficulty = "Medium",
    playerRole = "Driver",
    detectiveSuspicion = 0,
    isPlayerGuilty = false,
    isWaitingForResponse = false,
    isAITyping = false
}

-- Available options
local availableDifficulties = {"Easy", "Medium", "Hard", "Expert"}
local availableRoles = {"Driver", "Lookout", "Hacker", "Muscle", "Inside Man", "Mastermind", "Tech Specialist", "Demolitions Expert"}

-- Forward declare functions
local startInterrogation
local endInterrogation
local createInterrogationUI
local createMainMenu
local animateText
local updateTimer
local updateResponseTimer
local updateSuspicion
local sendToMiddleware

-- Define endInterrogation function first
endInterrogation = function(playerWon)
	gameState.isInterrogationActive = false

	local ui = playerGui:FindFirstChild("InterrogationUI")
	if ui then
		ui:Destroy()
	end

	local resultGui = Instance.new("ScreenGui")
	resultGui.Name = "ResultUI"
	resultGui.Parent = playerGui

	local resultFrame = Instance.new("Frame")
	resultFrame.Size = UDim2.new(0.5, 0, 0.3, 0)
	resultFrame.Position = UDim2.new(0.25, 0, 0.35, 0)
	resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	resultFrame.BorderSizePixel = 0
	resultFrame.Parent = resultGui

	local resultLabel = Instance.new("TextLabel")
	resultLabel.Size = UDim2.new(1, 0, 1, 0)
	resultLabel.Position = UDim2.new(0, 0, 0, 0)
	resultLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	resultLabel.TextScaled = true
	resultLabel.Font = Enum.Font.GothamBold
	resultLabel.Text = playerWon and "INTERROGATION SURVIVED!" or "CAUGHT LYING!"
	resultLabel.Parent = resultFrame

	if playerWon then
		resultFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		resultLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	else
		resultFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		resultLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end

	wait(3)
	resultGui:Destroy()
end

-- Define helper functions
animateText = function(textLabel, text)
	textLabel.Text = ""
	for i = 1, #text do
		textLabel.Text = string.sub(text, 1, i)
		wait(TYPING_SPEED)
	end
end

updateTimer = function()
	local minutes = math.floor(gameState.timeRemaining / 60)
	local seconds = gameState.timeRemaining % 60
	local timerText = string.format("%d:%02d", minutes, seconds)
	
	local ui = playerGui:FindFirstChild("InterrogationUI")
	if ui then
		local timerLabel = ui.MainFrame.Timer
		timerLabel.Text = timerText
		
		if gameState.timeRemaining <= 60 then
			timerLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		elseif gameState.timeRemaining <= 300 then
			timerLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
		end
	end
end

updateResponseTimer = function()
	local ui = playerGui:FindFirstChild("InterrogationUI")
	if ui then
		local responseTimerLabel = ui.MainFrame.ResponseTimer
		if responseTimerLabel then
			responseTimerLabel.Text = string.format("RESPOND: %d", gameState.responseTimeRemaining)
			
			if gameState.responseTimeRemaining <= 10 then
				responseTimerLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			elseif gameState.responseTimeRemaining <= 30 then
				responseTimerLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
			else
				responseTimerLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
			end
		end
	end
end

updateSuspicion = function()
	local ui = playerGui:FindFirstChild("InterrogationUI")
	if ui then
		local suspicionLabel = ui.MainFrame.SuspicionLabel
		suspicionLabel.Text = "SUSPICION: " .. gameState.detectiveSuspicion .. "%"
		
		if gameState.detectiveSuspicion >= 75 then
			suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		elseif gameState.detectiveSuspicion >= 50 then
			suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
		elseif gameState.detectiveSuspicion >= 25 then
			suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
		else
			suspicionLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end
	end
end

sendToMiddleware = function(playerResponse)
	local requestData = {
		playerName = player.Name,
		role = gameState.playerRole,
		difficulty = gameState.difficulty,
		evidenceList = gameState.currentEvidence,
		playerResponse = playerResponse,
		conversationHistory = gameState.conversationHistory
	}
	
	print("Sending request to middleware:", MIDDLEWARE_URL .. "/interrogate")
	print("Request data:", HttpService:JSONEncode(requestData))
	
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = MIDDLEWARE_URL .. "/interrogate",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = HttpService:JSONEncode(requestData)
		})
	end)
	
	if success then
		print("Request successful, status:", response.StatusCode)
		if response.Success then
			local data = HttpService:JSONDecode(response.Body)
			print("Response data received:", HttpService:JSONEncode(data))
			return data
		else
			print("HTTP request failed:", response.StatusCode, response.StatusMessage)
			warn("Failed to get response from middleware: HTTP", response.StatusCode)
			return nil
		end
	else
		print("Request failed with error:", response)
		warn("Failed to get response from middleware:", response)
		return nil
	end
end

-- Define startInterrogation function
startInterrogation = function()
	gameState.isInterrogationActive = true
	gameState.timeRemaining = INTERROGATION_TIME
	gameState.responseTimeRemaining = RESPONSE_TIME_LIMIT
	gameState.conversationHistory = {}
	gameState.detectiveSuspicion = 0
	gameState.isWaitingForResponse = false
	gameState.isAITyping = false

	local ui = createInterrogationUI()

	print("Starting interrogation...")
	local firstResponse = sendToMiddleware("")
	if firstResponse then
		print("First response received successfully")
		gameState.currentScenario = firstResponse.scenario
		gameState.currentEvidence = firstResponse.evidence

		local evidenceText = ui.MainFrame.EvidenceFrame.EvidenceText
		evidenceText.Text = table.concat(firstResponse.evidence, "\n")

		local detectiveText = ui.MainFrame.DetectiveFrame.DetectiveText
		gameState.isAITyping = true
		animateText(detectiveText, firstResponse.response)
		gameState.isAITyping = false
		gameState.isWaitingForResponse = true
		gameState.responseTimeRemaining = RESPONSE_TIME_LIMIT

		table.insert(gameState.conversationHistory, {
			role = "detective",
			content = firstResponse.response
		})
	else
		print("Failed to get first response from middleware")
		-- Show error message
		local detectiveText = ui.MainFrame.DetectiveFrame.DetectiveText
		detectiveText.Text = "ERROR: Could not connect to interrogation system. Please check your connection and try again."
	end

	local sendButton = ui.MainFrame.PlayerFrame.SendButton
	local playerInput = ui.MainFrame.PlayerFrame.PlayerInput

	sendButton.MouseButton1Click:Connect(function()
		local response = playerInput.Text
		if response and response ~= "" and gameState.isWaitingForResponse then
			gameState.isWaitingForResponse = false
			sendButton.Text = "SENDING..."
			sendButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

			table.insert(gameState.conversationHistory, {
				role = "player",
				content = response
			})

			print("Sending player response:", response)
			local aiResponse = sendToMiddleware(response)
			if aiResponse then
				print("AI response received")
				local detectiveText = ui.MainFrame.DetectiveFrame.DetectiveText
				gameState.isAITyping = true
				animateText(detectiveText, aiResponse.response)
				gameState.isAITyping = false
				gameState.isWaitingForResponse = true
				gameState.responseTimeRemaining = RESPONSE_TIME_LIMIT

				table.insert(gameState.conversationHistory, {
					role = "detective",
					content = aiResponse.response
				})

				local evidenceKeywords = {"evidence", "proof", "caught", "lying", "contradiction", "guilty", "confess", "admit", "proven", "confirmed", "definitely", "clearly"}
				local strongEvidenceKeywords = {"definitive", "conclusive", "irrefutable", "undeniable", "caught red-handed", "beyond doubt", "proven guilty"}

				for _, keyword in ipairs(strongEvidenceKeywords) do
					if string.find(string.lower(aiResponse.response), keyword) then
						gameState.detectiveSuspicion = gameState.detectiveSuspicion + 25
						break
					end
				end

				for _, keyword in ipairs(evidenceKeywords) do
					if string.find(string.lower(aiResponse.response), keyword) then
						gameState.detectiveSuspicion = gameState.detectiveSuspicion + 8
						break
					end
				end

				updateSuspicion()

				if gameState.detectiveSuspicion >= 75 then
					endInterrogation(false)
					return
				end
			else
				print("Failed to get AI response")
				gameState.isWaitingForResponse = true
				gameState.responseTimeRemaining = RESPONSE_TIME_LIMIT
			end

			playerInput.Text = ""
			sendButton.Text = "SEND"
			sendButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
		end
	end)

	playerInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			sendButton.MouseButton1Click:Fire()
		end
	end)

	spawn(function()
		while gameState.isInterrogationActive and gameState.timeRemaining > 0 do
			wait(1)
			
			-- Only count down main timer when AI is not typing and player is not responding
			if not gameState.isAITyping and not gameState.isWaitingForResponse then
				gameState.timeRemaining = gameState.timeRemaining - 1
				updateTimer()
			end
			
			-- Count down response timer when waiting for player response
			if gameState.isWaitingForResponse then
				gameState.responseTimeRemaining = gameState.responseTimeRemaining - 1
				updateResponseTimer()
				
				if gameState.responseTimeRemaining <= 0 then
					print("Player took too long to respond - losing")
					endInterrogation(false)
					break
				end
			end

			if gameState.timeRemaining <= 0 then
				endInterrogation(true)
				break
			end
		end
	end)
end

-- Define UI creation functions
createInterrogationUI = function()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InterrogationUI"
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.8, 0, 0.9, 0)
	mainFrame.Position = UDim2.new(0.1, 0, 0.05, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "INTERROGATION ROOM"
	titleLabel.Parent = mainFrame
	
	-- Timer
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(0.15, 0, 0.1, 0)
	timerLabel.Position = UDim2.new(0.45, 0, 0, 0)
	timerLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextScaled = true
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Text = "15:00"
	timerLabel.Parent = mainFrame
	
	-- Suspicion meter
	local suspicionLabel = Instance.new("TextLabel")
	suspicionLabel.Name = "SuspicionLabel"
	suspicionLabel.Size = UDim2.new(0.15, 0, 0.1, 0)
	suspicionLabel.Position = UDim2.new(0.6, 0, 0, 0)
	suspicionLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	suspicionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	suspicionLabel.TextScaled = true
	suspicionLabel.Font = Enum.Font.GothamBold
	suspicionLabel.Text = "SUSPICION: 0%"
	suspicionLabel.Parent = mainFrame
	
	-- Response timer
	local responseTimerLabel = Instance.new("TextLabel")
	responseTimerLabel.Name = "ResponseTimer"
	responseTimerLabel.Size = UDim2.new(0.15, 0, 0.1, 0)
	responseTimerLabel.Position = UDim2.new(0.8, 0, 0, 0)
	responseTimerLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
	responseTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	responseTimerLabel.TextScaled = true
	responseTimerLabel.Font = Enum.Font.GothamBold
	responseTimerLabel.Text = "RESPOND: 60"
	responseTimerLabel.Parent = mainFrame
	
	-- Detective response area
	local detectiveFrame = Instance.new("Frame")
	detectiveFrame.Name = "DetectiveFrame"
	detectiveFrame.Size = UDim2.new(1, 0, 0.4, 0)
	detectiveFrame.Position = UDim2.new(0, 0, 0.1, 0)
	detectiveFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	detectiveFrame.BorderSizePixel = 0
	detectiveFrame.Parent = mainFrame
	
	local detectiveLabel = Instance.new("TextLabel")
	detectiveLabel.Name = "DetectiveLabel"
	detectiveLabel.Size = UDim2.new(0.1, 0, 0.1, 0)
	detectiveLabel.Position = UDim2.new(0, 10, 0, 10)
	detectiveLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	detectiveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	detectiveLabel.TextScaled = true
	detectiveLabel.Font = Enum.Font.GothamBold
	detectiveLabel.Text = "DETECTIVE"
	detectiveLabel.Parent = detectiveFrame
	
	local detectiveText = Instance.new("TextLabel")
	detectiveText.Name = "DetectiveText"
	detectiveText.Size = UDim2.new(0.95, -20, 0.8, -20)
	detectiveText.Position = UDim2.new(0, 10, 0.15, 0)
	detectiveText.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	detectiveText.TextColor3 = Color3.fromRGB(255, 255, 255)
	detectiveText.TextScaled = true
	detectiveText.Font = Enum.Font.Gotham
	detectiveText.Text = "Detective Holloway is preparing to question you..."
	detectiveText.TextWrapped = true
	detectiveText.Parent = detectiveFrame
	
	-- Player input area
	local playerFrame = Instance.new("Frame")
	playerFrame.Name = "PlayerFrame"
	playerFrame.Size = UDim2.new(1, 0, 0.3, 0)
	playerFrame.Position = UDim2.new(0, 0, 0.5, 0)
	playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	playerFrame.BorderSizePixel = 0
	playerFrame.Parent = mainFrame
	
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Name = "PlayerLabel"
	playerLabel.Size = UDim2.new(0.1, 0, 0.1, 0)
	playerLabel.Position = UDim2.new(0, 10, 0, 10)
	playerLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
	playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerLabel.TextScaled = true
	playerLabel.Font = Enum.Font.GothamBold
	playerLabel.Text = "YOU"
	playerLabel.Parent = playerFrame
	
	local playerInput = Instance.new("TextBox")
	playerInput.Name = "PlayerInput"
	playerInput.Size = UDim2.new(0.7, -20, 0.6, -20)
	playerInput.Position = UDim2.new(0, 10, 0.15, 0)
	playerInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	playerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerInput.TextScaled = true
	playerInput.Font = Enum.Font.Gotham
	playerInput.PlaceholderText = "Type your response here..."
	playerInput.Text = ""
	playerInput.Parent = playerFrame
	
	local sendButton = Instance.new("TextButton")
	sendButton.Name = "SendButton"
	sendButton.Size = UDim2.new(0.25, -10, 0.6, -20)
	sendButton.Position = UDim2.new(0.75, 0, 0.15, 0)
	sendButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
	sendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	sendButton.TextScaled = true
	sendButton.Font = Enum.Font.GothamBold
	sendButton.Text = "SEND"
	sendButton.Parent = playerFrame
	
	-- Evidence panel
	local evidenceFrame = Instance.new("Frame")
	evidenceFrame.Name = "EvidenceFrame"
	evidenceFrame.Size = UDim2.new(1, 0, 0.15, 0)
	evidenceFrame.Position = UDim2.new(0, 0, 0.85, 0)
	evidenceFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	evidenceFrame.BorderSizePixel = 0
	evidenceFrame.Parent = mainFrame
	
	local evidenceLabel = Instance.new("TextLabel")
	evidenceLabel.Name = "EvidenceLabel"
	evidenceLabel.Size = UDim2.new(0.2, 0, 1, 0)
	evidenceLabel.Position = UDim2.new(0, 0, 0, 0)
	evidenceLabel.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	evidenceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	evidenceLabel.TextScaled = true
	evidenceLabel.Font = Enum.Font.GothamBold
	evidenceLabel.Text = "EVIDENCE"
	evidenceLabel.Parent = evidenceFrame
	
	local evidenceText = Instance.new("TextLabel")
	evidenceText.Name = "EvidenceText"
	evidenceText.Size = UDim2.new(0.8, -10, 1, -10)
	evidenceText.Position = UDim2.new(0.2, 0, 0, 0)
	evidenceText.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	evidenceText.TextColor3 = Color3.fromRGB(255, 255, 255)
	evidenceText.TextScaled = true
	evidenceText.Font = Enum.Font.Gotham
	evidenceText.Text = "Evidence will appear here..."
	evidenceText.TextWrapped = true
	evidenceText.Parent = evidenceFrame
	
	return screenGui
end

-- Create main menu
createMainMenu = function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenuUI"
    screenGui.Parent = playerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.Parent = screenGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
    mainFrame.Position = UDim2.new(0.25, 0, 0.15, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "ALIBI INTERROGATION"
    titleLabel.Parent = mainFrame
    
    -- Difficulty section
    local difficultyLabel = Instance.new("TextLabel")
    difficultyLabel.Name = "DifficultyLabel"
    difficultyLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
    difficultyLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
    difficultyLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    difficultyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    difficultyLabel.TextScaled = true
    difficultyLabel.Font = Enum.Font.GothamBold
    difficultyLabel.Text = "DIFFICULTY:"
    difficultyLabel.Parent = mainFrame
    
    local difficultyButtons = {}
    for i, difficulty in ipairs(availableDifficulties) do
        local button = Instance.new("TextButton")
        button.Name = "Difficulty" .. difficulty
        button.Size = UDim2.new(0.15, 0, 0.06, 0)
        button.Position = UDim2.new(0.1 + (i-1) * 0.2, 0, 0.3, 0)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Text = difficulty
        button.Parent = mainFrame
        
        if difficulty == gameState.difficulty then
            button.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        end
        
        button.MouseButton1Click:Connect(function()
            for _, btn in ipairs(difficultyButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            button.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
            gameState.difficulty = difficulty
        end)
        
        table.insert(difficultyButtons, button)
    end
    
    -- Role section
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(0.8, 0, 0.08, 0)
    roleLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
    roleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    roleLabel.TextScaled = true
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.Text = "YOUR ROLE:"
    roleLabel.Parent = mainFrame
    
    local roleDropdown = Instance.new("TextButton")
    roleDropdown.Name = "RoleDropdown"
    roleDropdown.Size = UDim2.new(0.6, 0, 0.06, 0)
    roleDropdown.Position = UDim2.new(0.2, 0, 0.5, 0)
    roleDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    roleDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    roleDropdown.TextScaled = true
    roleDropdown.Font = Enum.Font.Gotham
    roleDropdown.Text = gameState.playerRole
    roleDropdown.Parent = mainFrame
    
    local currentRoleIndex = 1
    for i, role in ipairs(availableRoles) do
        if role == gameState.playerRole then
            currentRoleIndex = i
            break
        end
    end
    
    roleDropdown.MouseButton1Click:Connect(function()
        currentRoleIndex = currentRoleIndex + 1
        if currentRoleIndex > #availableRoles then
            currentRoleIndex = 1
        end
        gameState.playerRole = availableRoles[currentRoleIndex]
        roleDropdown.Text = gameState.playerRole
    end)
    
    -- Start button
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0.6, 0, 0.1, 0)
    startButton.Position = UDim2.new(0.2, 0, 0.7, 0)
    startButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextScaled = true
    startButton.Font = Enum.Font.GothamBold
    startButton.Text = "START INTERROGATION"
    startButton.Parent = mainFrame
    
    startButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        startInterrogation()
    end)
    
    -- Auto-start button
    local autoStartButton = Instance.new("TextButton")
    autoStartButton.Name = "AutoStartButton"
    autoStartButton.Size = UDim2.new(0.6, 0, 0.08, 0)
    autoStartButton.Position = UDim2.new(0.2, 0, 0.85, 0)
    autoStartButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
    autoStartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoStartButton.TextScaled = true
    autoStartButton.Font = Enum.Font.GothamBold
    autoStartButton.Text = "AUTO-START (SKIP MENU)"
    autoStartButton.Parent = mainFrame
    
    autoStartButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        startInterrogation()
    end)
    
    return screenGui
end









-- Test middleware connection
local function testMiddlewareConnection()
	print("Testing middleware connection...")
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = MIDDLEWARE_URL .. "/health",
			Method = "GET"
		})
	end)
	
	if success and response.Success then
		print("✅ Middleware connection successful!")
		return true
	else
		print("❌ Middleware connection failed:", response and response.StatusCode or "No response")
		warn("Middleware connection failed. Make sure the server is running on", MIDDLEWARE_URL)
		return false
	end
end

-- Auto-start after a short delay
wait(2) -- Wait 2 seconds for everything to load

-- Test connection first
if testMiddlewareConnection() then
	createMainMenu()
else
	-- Show error message
	local errorGui = Instance.new("ScreenGui")
	errorGui.Name = "ConnectionErrorUI"
	errorGui.Parent = playerGui
	
	local errorFrame = Instance.new("Frame")
	errorFrame.Size = UDim2.new(0.5, 0, 0.3, 0)
	errorFrame.Position = UDim2.new(0.25, 0, 0.35, 0)
	errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	errorFrame.BorderSizePixel = 0
	errorFrame.Parent = errorGui
	
	local errorLabel = Instance.new("TextLabel")
	errorLabel.Size = UDim2.new(1, 0, 1, 0)
	errorLabel.Position = UDim2.new(0, 0, 0, 0)
	errorLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	errorLabel.TextScaled = true
	errorLabel.Font = Enum.Font.GothamBold
	errorLabel.Text = "CONNECTION ERROR\n\nCould not connect to interrogation server.\nMake sure the middleware is running on:\n" .. MIDDLEWARE_URL .. "\n\nCheck the console for details."
	errorLabel.TextWrapped = true
	errorLabel.Parent = errorFrame
	
	wait(5)
	errorGui:Destroy()
	createMainMenu() -- Still show menu in case user wants to retry
end

-- Also add chat commands as backup
player.Chatted:Connect(function(message)
	if string.lower(message) == "/interrogate" or string.lower(message) == "/menu" then
		if not gameState.isInterrogationActive then
			createMainMenu()
		end
	end
end) 