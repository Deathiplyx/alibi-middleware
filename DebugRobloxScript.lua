-- DEBUG VERSION - Alibi Interrogation System for Roblox
-- Place this in a LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- DEBUG: Print startup message
print("🔍 DEBUG: Interrogation script starting...")
print("🔍 DEBUG: Player name:", player.Name)
print("🔍 DEBUG: PlayerGui found:", playerGui ~= nil)

-- Configuration
local MIDDLEWARE_URL = "http://localhost:3000" -- Change this to your server URL
local INTERROGATION_TIME = 900 -- 15 minutes in seconds
local TYPING_SPEED = 0.03 -- Speed for text animation

-- DEBUG: Print configuration
print("🔍 DEBUG: Middleware URL:", MIDDLEWARE_URL)
print("🔍 DEBUG: Interrogation time:", INTERROGATION_TIME)

-- Game state
local gameState = {
    isInterrogationActive = false,
    timeRemaining = INTERROGATION_TIME,
    conversationHistory = {},
    currentScenario = nil,
    currentEvidence = {},
    difficulty = "Medium",
    playerRole = "Driver",
    detectiveSuspicion = 0, -- 0-100, tracks how suspicious the AI is
    isPlayerGuilty = false -- Set to true if player is actually guilty
}

-- DEBUG: Print initial game state
print("🔍 DEBUG: Initial game state:", HttpService:JSONEncode(gameState))

-- Available options for in-game selection
local availableDifficulties = {"Easy", "Medium", "Hard", "Expert"}
local availableRoles = {"Driver", "Lookout", "Hacker", "Muscle", "Inside Man", "Mastermind", "Tech Specialist", "Demolitions Expert"}

-- DEBUG: Print available options
print("🔍 DEBUG: Available difficulties:", table.concat(availableDifficulties, ", "))
print("🔍 DEBUG: Available roles:", table.concat(availableRoles, ", "))

-- Create settings UI
local function createSettingsUI()
    print("🔍 DEBUG: Creating settings UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SettingsUI"
    screenGui.Parent = playerGui
    
    print("🔍 DEBUG: SettingsUI created and parented to PlayerGui")
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
    mainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    print("🔍 DEBUG: Main frame created")
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "INTERROGATION SETTINGS"
    titleLabel.Parent = mainFrame
    
    print("🔍 DEBUG: Title label created")
    
    -- Difficulty selection
    local difficultyLabel = Instance.new("TextLabel")
    difficultyLabel.Name = "DifficultyLabel"
    difficultyLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    difficultyLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
    difficultyLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    difficultyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    difficultyLabel.TextScaled = true
    difficultyLabel.Font = Enum.Font.GothamBold
    difficultyLabel.Text = "DIFFICULTY:"
    difficultyLabel.Parent = mainFrame
    
    print("🔍 DEBUG: Difficulty label created")
    
    local difficultyButtons = {}
    for i, difficulty in ipairs(availableDifficulties) do
        local button = Instance.new("TextButton")
        button.Name = "Difficulty" .. difficulty
        button.Size = UDim2.new(0.15, 0, 0.08, 0)
        button.Position = UDim2.new(0.1 + (i-1) * 0.2, 0, 0.32, 0)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Text = difficulty
        button.Parent = mainFrame
        
        print("🔍 DEBUG: Created difficulty button:", difficulty)
        
        -- Highlight selected difficulty
        if difficulty == gameState.difficulty then
            button.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
            print("🔍 DEBUG: Highlighted current difficulty:", difficulty)
        end
        
        button.MouseButton1Click:Connect(function()
            print("🔍 DEBUG: Difficulty button clicked:", difficulty)
            -- Reset all buttons
            for _, btn in ipairs(difficultyButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            -- Highlight selected
            button.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
            gameState.difficulty = difficulty
            print("🔍 DEBUG: Difficulty changed to:", difficulty)
        end)
        
        table.insert(difficultyButtons, button)
    end
    
    -- Role selection
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    roleLabel.Position = UDim2.new(0.1, 0, 0.45, 0)
    roleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    roleLabel.TextScaled = true
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.Text = "YOUR ROLE:"
    roleLabel.Parent = mainFrame
    
    print("🔍 DEBUG: Role label created")
    
    local roleDropdown = Instance.new("TextButton")
    roleDropdown.Name = "RoleDropdown"
    roleDropdown.Size = UDim2.new(0.6, 0, 0.08, 0)
    roleDropdown.Position = UDim2.new(0.2, 0, 0.57, 0)
    roleDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    roleDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    roleDropdown.TextScaled = true
    roleDropdown.Font = Enum.Font.Gotham
    roleDropdown.Text = gameState.playerRole
    roleDropdown.Parent = mainFrame
    
    print("🔍 DEBUG: Role dropdown created with text:", gameState.playerRole)
    
    local currentRoleIndex = 1
    for i, role in ipairs(availableRoles) do
        if role == gameState.playerRole then
            currentRoleIndex = i
            break
        end
    end
    
    print("🔍 DEBUG: Current role index:", currentRoleIndex)
    
    roleDropdown.MouseButton1Click:Connect(function()
        print("🔍 DEBUG: Role dropdown clicked")
        currentRoleIndex = currentRoleIndex + 1
        if currentRoleIndex > #availableRoles then
            currentRoleIndex = 1
        end
        gameState.playerRole = availableRoles[currentRoleIndex]
        roleDropdown.Text = gameState.playerRole
        print("🔍 DEBUG: Role changed to:", gameState.playerRole)
    end)
    
    -- Start button
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0.6, 0, 0.1, 0)
    startButton.Position = UDim2.new(0.2, 0, 0.75, 0)
    startButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextScaled = true
    startButton.Font = Enum.Font.GothamBold
    startButton.Text = "START INTERROGATION"
    startButton.Parent = mainFrame
    
    print("🔍 DEBUG: Start button created")
    
    startButton.MouseButton1Click:Connect(function()
        print("🔍 DEBUG: Start button clicked!")
        screenGui:Destroy()
        print("🔍 DEBUG: Settings UI destroyed")
        startInterrogation()
    end)
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.Parent = mainFrame
    
    print("🔍 DEBUG: Close button created")
    
    closeButton.MouseButton1Click:Connect(function()
        print("🔍 DEBUG: Close button clicked")
        screenGui:Destroy()
        print("🔍 DEBUG: Settings UI destroyed by close button")
    end)
    
    print("🔍 DEBUG: Settings UI creation complete")
    return screenGui
end

-- Create UI (same as before, but with updated timer display)
local function createInterrogationUI()
    print("🔍 DEBUG: Creating interrogation UI...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InterrogationUI"
    screenGui.Parent = playerGui
    
    print("🔍 DEBUG: InterrogationUI created and parented to PlayerGui")
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.8, 0, 0.9, 0)
    mainFrame.Position = UDim2.new(0.1, 0, 0.05, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    print("🔍 DEBUG: Main frame created")
    
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
    
    print("🔍 DEBUG: Title label created")
    
    -- Timer
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(0.2, 0, 0.1, 0)
    timerLabel.Position = UDim2.new(0.8, 0, 0, 0)
    timerLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Text = "15:00"
    timerLabel.Parent = mainFrame
    
    print("🔍 DEBUG: Timer label created")
    
    -- Suspicion meter
    local suspicionLabel = Instance.new("TextLabel")
    suspicionLabel.Name = "SuspicionLabel"
    suspicionLabel.Size = UDim2.new(0.2, 0, 0.1, 0)
    suspicionLabel.Position = UDim2.new(0.6, 0, 0, 0)
    suspicionLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    suspicionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    suspicionLabel.TextScaled = true
    suspicionLabel.Font = Enum.Font.GothamBold
    suspicionLabel.Text = "SUSPICION: 0%"
    suspicionLabel.Parent = mainFrame
    
    print("🔍 DEBUG: Suspicion label created")
    
    -- Detective response area
    local detectiveFrame = Instance.new("Frame")
    detectiveFrame.Name = "DetectiveFrame"
    detectiveFrame.Size = UDim2.new(1, 0, 0.4, 0)
    detectiveFrame.Position = UDim2.new(0, 0, 0.1, 0)
    detectiveFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    detectiveFrame.BorderSizePixel = 0
    detectiveFrame.Parent = mainFrame
    
    print("🔍 DEBUG: Detective frame created")
    
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
    
    print("🔍 DEBUG: Detective label created")
    
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
    
    print("🔍 DEBUG: Detective text created")
    
    -- Player input area
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = "PlayerFrame"
    playerFrame.Size = UDim2.new(1, 0, 0.3, 0)
    playerFrame.Position = UDim2.new(0, 0, 0.5, 0)
    playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playerFrame.BorderSizePixel = 0
    playerFrame.Parent = mainFrame
    
    print("🔍 DEBUG: Player frame created")
    
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
    
    print("🔍 DEBUG: Player label created")
    
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
    
    print("🔍 DEBUG: Player input created")
    
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
    
    print("🔍 DEBUG: Send button created")
    
    -- Evidence panel
    local evidenceFrame = Instance.new("Frame")
    evidenceFrame.Name = "EvidenceFrame"
    evidenceFrame.Size = UDim2.new(1, 0, 0.15, 0)
    evidenceFrame.Position = UDim2.new(0, 0, 0.85, 0)
    evidenceFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    evidenceFrame.BorderSizePixel = 0
    evidenceFrame.Parent = mainFrame
    
    print("🔍 DEBUG: Evidence frame created")
    
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
    
    print("🔍 DEBUG: Evidence label created")
    
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
    
    print("🔍 DEBUG: Evidence text created")
    print("🔍 DEBUG: Interrogation UI creation complete")
    
    return screenGui
end

-- Animate text typing effect
local function animateText(textLabel, text)
    print("🔍 DEBUG: Starting text animation with text:", text)
    textLabel.Text = ""
    for i = 1, #text do
        textLabel.Text = string.sub(text, 1, i)
        wait(TYPING_SPEED)
    end
    print("🔍 DEBUG: Text animation complete")
end

-- Update timer display
local function updateTimer()
    local minutes = math.floor(gameState.timeRemaining / 60)
    local seconds = gameState.timeRemaining % 60
    local timerText = string.format("%d:%02d", minutes, seconds)
    
    local ui = playerGui:FindFirstChild("InterrogationUI")
    if ui then
        local timerLabel = ui.MainFrame.Timer
        timerLabel.Text = timerText
        
        -- Change color based on time remaining
        if gameState.timeRemaining <= 60 then
            timerLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
        elseif gameState.timeRemaining <= 300 then -- 5 minutes
            timerLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 50) -- Orange
        end
    end
end

-- Update suspicion meter
local function updateSuspicion()
    local ui = playerGui:FindFirstChild("InterrogationUI")
    if ui then
        local suspicionLabel = ui.MainFrame.SuspicionLabel
        suspicionLabel.Text = "SUSPICION: " .. gameState.detectiveSuspicion .. "%"
        
        -- Change color based on suspicion level
        if gameState.detectiveSuspicion >= 75 then
            suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
        elseif gameState.detectiveSuspicion >= 50 then
            suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 50) -- Orange
        elseif gameState.detectiveSuspicion >= 25 then
            suspicionLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 50) -- Yellow
        else
            suspicionLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Normal
        end
    end
end

-- Send request to middleware server
local function sendToMiddleware(playerResponse)
    print("🔍 DEBUG: Sending request to middleware...")
    print("🔍 DEBUG: Player response:", playerResponse)
    
    local requestData = {
        playerName = player.Name,
        role = gameState.playerRole,
        difficulty = gameState.difficulty,
        evidenceList = gameState.currentEvidence,
        playerResponse = playerResponse,
        conversationHistory = gameState.conversationHistory
    }
    
    print("🔍 DEBUG: Request data:", HttpService:JSONEncode(requestData))
    
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
    
    print("🔍 DEBUG: HTTP request success:", success)
    
    if success and response.Success then
        print("🔍 DEBUG: Response status:", response.StatusCode)
        print("🔍 DEBUG: Response body:", response.Body)
        local data = HttpService:JSONDecode(response.Body)
        print("🔍 DEBUG: Parsed response data:", HttpService:JSONEncode(data))
        return data
    else
        print("🔍 DEBUG: HTTP request failed!")
        print("🔍 DEBUG: Success:", success)
        print("🔍 DEBUG: Response:", response)
        if response then
            print("🔍 DEBUG: Status code:", response.StatusCode)
            print("🔍 DEBUG: Error message:", response.Body)
        end
        warn("Failed to get response from middleware:", response and response.StatusCode or "No response")
        return nil
    end
end

-- Start interrogation
local function startInterrogation()
    print("🔍 DEBUG: Starting interrogation...")
    print("🔍 DEBUG: Current game state:", HttpService:JSONEncode(gameState))
    
    gameState.isInterrogationActive = true
    gameState.timeRemaining = INTERROGATION_TIME
    gameState.conversationHistory = {}
    gameState.detectiveSuspicion = 0
    
    print("🔍 DEBUG: Game state updated for interrogation")
    
    -- Create UI
    local ui = createInterrogationUI()
    
    print("🔍 DEBUG: Getting first question from AI...")
    
    -- Get first question from AI
    local firstResponse = sendToMiddleware("")
    if firstResponse then
        print("🔍 DEBUG: Got first response from AI")
        gameState.currentScenario = firstResponse.scenario
        gameState.currentEvidence = firstResponse.evidence
        
        print("🔍 DEBUG: Scenario:", HttpService:JSONEncode(firstResponse.scenario))
        print("🔍 DEBUG: Evidence:", table.concat(firstResponse.evidence, ", "))
        
        -- Update evidence display
        local evidenceText = ui.MainFrame.EvidenceFrame.EvidenceText
        evidenceText.Text = table.concat(firstResponse.evidence, "\n")
        
        print("🔍 DEBUG: Evidence text updated")
        
        -- Animate detective's first question
        local detectiveText = ui.MainFrame.DetectiveFrame.DetectiveText
        animateText(detectiveText, firstResponse.response)
        
        -- Add to conversation history
        table.insert(gameState.conversationHistory, {
            role = "detective",
            content = firstResponse.response
        })
        
        print("🔍 DEBUG: Added first response to conversation history")
    else
        print("🔍 DEBUG: Failed to get first response from AI!")
    end
    
    -- Set up send button
    local sendButton = ui.MainFrame.PlayerFrame.SendButton
    local playerInput = ui.MainFrame.PlayerFrame.PlayerInput
    
    print("🔍 DEBUG: Setting up send button click handler...")
    
    sendButton.MouseButton1Click:Connect(function()
        print("🔍 DEBUG: Send button clicked!")
        local response = playerInput.Text
        print("🔍 DEBUG: Player response text:", response)
        
        if response and response ~= "" then
            print("🔍 DEBUG: Valid response, processing...")
            sendButton.Text = "SENDING..."
            sendButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            
            -- Add player response to history
            table.insert(gameState.conversationHistory, {
                role = "player",
                content = response
            })
            
            print("🔍 DEBUG: Added player response to history")
            
            -- Get AI response
            local aiResponse = sendToMiddleware(response)
            if aiResponse then
                print("🔍 DEBUG: Got AI response")
                
                -- Animate AI response
                local detectiveText = ui.MainFrame.DetectiveFrame.DetectiveText
                animateText(detectiveText, aiResponse.response)
                
                -- Add AI response to history
                table.insert(gameState.conversationHistory, {
                    role = "detective",
                    content = aiResponse.response
                })
                
                print("🔍 DEBUG: Added AI response to history")
                
                -- Check for evidence and suspicion indicators in AI response
                local evidenceKeywords = {"evidence", "proof", "caught", "lying", "contradiction", "guilty", "confess", "admit", "proven", "confirmed", "definitely", "clearly"}
                local strongEvidenceKeywords = {"definitive", "conclusive", "irrefutable", "undeniable", "caught red-handed", "beyond doubt", "proven guilty"}
                
                local suspicionGained = 0
                
                for _, keyword in ipairs(strongEvidenceKeywords) do
                    if string.find(string.lower(aiResponse.response), keyword) then
                        gameState.detectiveSuspicion = gameState.detectiveSuspicion + 25 -- Strong evidence
                        suspicionGained = suspicionGained + 25
                        print("🔍 DEBUG: Found strong evidence keyword:", keyword)
                        break
                    end
                end
                
                for _, keyword in ipairs(evidenceKeywords) do
                    if string.find(string.lower(aiResponse.response), keyword) then
                        gameState.detectiveSuspicion = gameState.detectiveSuspicion + 8 -- Regular evidence
                        suspicionGained = suspicionGained + 8
                        print("🔍 DEBUG: Found evidence keyword:", keyword)
                        break
                    end
                end
                
                print("🔍 DEBUG: Suspicion gained:", suspicionGained)
                print("🔍 DEBUG: Total suspicion:", gameState.detectiveSuspicion)
                
                updateSuspicion()
                
                -- Check if AI has enough evidence to prove guilt
                if gameState.detectiveSuspicion >= 75 then
                    print("🔍 DEBUG: Suspicion threshold reached! Player loses!")
                    endInterrogation(false) -- Player loses (caught)
                    return
                end
            else
                print("🔍 DEBUG: Failed to get AI response!")
            end
            
            -- Clear input and reset button
            playerInput.Text = ""
            sendButton.Text = "SEND"
            sendButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
            
            print("🔍 DEBUG: Reset input and button")
        else
            print("🔍 DEBUG: Invalid or empty response")
        end
    end)
    
    -- Set up enter key
    playerInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            print("🔍 DEBUG: Enter key pressed, firing send button")
            sendButton.MouseButton1Click:Fire()
        end
    end)
    
    print("🔍 DEBUG: Starting timer...")
    
    -- Start timer
    spawn(function()
        while gameState.isInterrogationActive and gameState.timeRemaining > 0 do
            wait(1)
            gameState.timeRemaining = gameState.timeRemaining - 1
            updateTimer()
            
            if gameState.timeRemaining <= 0 then
                print("🔍 DEBUG: Time ran out! Player wins!")
                endInterrogation(true) -- Player wins (survived interrogation)
                break
            end
        end
    end)
    
    print("🔍 DEBUG: Interrogation setup complete")
end

-- End interrogation
local function endInterrogation(playerWon)
    print("🔍 DEBUG: Ending interrogation, player won:", playerWon)
    gameState.isInterrogationActive = false
    
    local ui = playerGui:FindFirstChild("InterrogationUI")
    if ui then
        ui:Destroy()
        print("🔍 DEBUG: Interrogation UI destroyed")
    end
    
    -- Show result
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
    
    -- Color based on result
    if playerWon then
        resultFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Green
        resultLabel.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        resultFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
        resultLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    
    print("🔍 DEBUG: Result UI created")
    
    -- Auto-remove after 3 seconds
    wait(3)
    resultGui:Destroy()
    print("🔍 DEBUG: Result UI destroyed")
end

-- Add chat commands with extensive debugging
print("🔍 DEBUG: Setting up chat command handler...")

player.Chatted:Connect(function(message)
    print("🔍 DEBUG: Chat message received:", message)
    print("🔍 DEBUG: Message lower case:", string.lower(message))
    print("🔍 DEBUG: Is interrogation active:", gameState.isInterrogationActive)
    
    if string.lower(message) == "/interrogate" then
        print("🔍 DEBUG: /interrogate command detected!")
        if not gameState.isInterrogationActive then
            print("🔍 DEBUG: Interrogation not active, creating settings UI...")
            createSettingsUI()
        else
            print("🔍 DEBUG: Interrogation already active, ignoring command")
        end
    elseif string.lower(message) == "/settings" then
        print("🔍 DEBUG: /settings command detected!")
        if not gameState.isInterrogationActive then
            print("🔍 DEBUG: Creating settings UI...")
            createSettingsUI()
        else
            print("🔍 DEBUG: Interrogation active, ignoring settings command")
        end
    else
        print("🔍 DEBUG: Unknown command:", message)
    end
end)

print("🔍 DEBUG: Chat command handler set up")
print("🔍 DEBUG: Script initialization complete!")
print("🔍 DEBUG: Try typing /interrogate in chat to test") 