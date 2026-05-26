-- ZAIXPLOIT | SANTET SLIME + AUTO ROLL 🎲
-- By ZAIXPLOIT

-- SERVICE
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- ========== VARIABLE UTAMA ==========
local isActive = true
local isMinimized = false
local currentTargetId = nil
local currentTargetHp = nil
local currentTargetMaxHp = nil
local loopSpeed = 0.1
local killCount = 0
local fps = 0
local lastTime = tick()
local frameCount = 0
local isWaiting = false

-- ========== FITUR ==========
local totalGoop = 0
local goopPerKill = 121000
local kps = 0
local lastKillCount = 0
local lastKpsTime = tick()
local sessionStartTime = tick()
local etaSeconds = 0

-- ========== AUTO ROLL BYPASS ==========
local autoRollActive = true
local autoRollCoroutine = nil
local autoRollDelay = 0.1

-- GET REMOTE GUN
local gunRemote = replicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("SlimeGunService"):WaitForChild("RemoteFunction")

-- GET REMOTE ROLL
local rollRemote = replicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction")

-- FUNCTION ATTACK GUN (GOOP sudah dihapus dari sini)
local function attackSlime(slimeId)
    local args = {"tryFireSlimeGun", slimeId}
    pcall(function()
        gunRemote:InvokeServer(unpack(args))
    end)
end

-- FIND GAMEPLAY FOLDER
local function findGameplayFolder()
    for _, child in ipairs(workspace:GetChildren()) do
        if string.match(child.Name, "^Gameplay%d+$") then
            return child
        end
    end
    return nil
end

-- GET SLIME COUNT
local function getSlimeCount()
    local gameplay = findGameplayFolder()
    if gameplay then
        local enemiesFolder = gameplay:FindFirstChild("Enemies")
        if enemiesFolder then
            local count = 0
            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                if tonumber(enemy.Name) then
                    count = count + 1
                end
            end
            return count
        end
    end
    return 0
end

-- GET ALL SLIME IDs
local function getAllSlimeIds()
    local ids = {}
    local gameplay = findGameplayFolder()
    if gameplay then
        local enemiesFolder = gameplay:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                local id = tonumber(enemy.Name)
                if id then
                    table.insert(ids, id)
                end
            end
        end
    end
    return ids
end

-- TRACK SLIME MATI + TAMBAH GOOP (FIXED)
local previousSlimeIds = {}
local function updateKillCount()
    local currentIds = getAllSlimeIds()
    local killedThisCycle = 0
    
    for i = 1, #previousSlimeIds do
        local id = previousSlimeIds[i]
        local found = false
        for j = 1, #currentIds do
            if currentIds[j] == id then
                found = true
                break
            end
        end
        if not found then
            killedThisCycle = killedThisCycle + 1
        end
    end
    
    if killedThisCycle > 0 then
        killCount = killCount + killedThisCycle
        totalGoop = totalGoop + (killedThisCycle * goopPerKill)
    end
    
    previousSlimeIds = currentIds
end

-- UPDATE KPS
local function updateKPS()
    local now = tick()
    if now - lastKpsTime >= 1 then
        kps = killCount - lastKillCount
        lastKillCount = killCount
        lastKpsTime = now
    end
end

-- FORMAT WAKTU SESSION
local function formatSessionTime()
    local elapsed = tick() - sessionStartTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    if minutes > 0 then
        return string.format("%dm %ds", minutes, seconds)
    else
        return string.format("%ds", seconds)
    end
end

-- FORMAT ANGKA
local function formatNumber(num)
    if not num then return "0" end
    if num >= 1000000000000 then return string.format("%.1fT", num/1000000000000)
    elseif num >= 1000000000 then return string.format("%.1fB", num/1000000000)
    elseif num >= 1000000 then return string.format("%.1fM", num/1000000)
    elseif num >= 1000 then return string.format("%.1fK", num/1000)
    else return tostring(math.floor(num))
    end
end

-- PARSE NUMBER
local function parseNumber(str)
    if not str then return nil end
    str = string.gsub(str, ",", "")
    local value, suffix = string.match(str, "([%d.]+)([KMBT])")
    if value and suffix then
        value = tonumber(value)
        if suffix == "K" then return value * 1000 end
        if suffix == "M" then return value * 1000000 end
        if suffix == "B" then return value * 1000000000 end
        if suffix == "T" then return value * 1000000000000 end
    end
    return tonumber(str)
end

-- GET SLIME HP
local function getSlimeHp(slimeId)
    local gameplay = findGameplayFolder()
    if not gameplay then return nil, nil end
    local enemiesFolder = gameplay:FindFirstChild("Enemies")
    if not enemiesFolder then return nil, nil end
    local enemy = enemiesFolder:FindFirstChild(tostring(slimeId))
    if not enemy then return nil, nil end
    local healthBar = enemy:FindFirstChild("HealthBarBillboardGui")
    if not healthBar then return nil, nil end
    local hpText = healthBar:FindFirstChild("Hp")
    if not hpText or not hpText:IsA("TextLabel") then return nil, nil end
    local text = hpText.Text
    local parts = {}
    for part in string.gmatch(text, "([^/]+)") do
        table.insert(parts, part)
    end
    if #parts >= 2 then
        return parseNumber(parts[1]), parseNumber(parts[2])
    end
    return nil, nil
end

-- CHECK SLIME EXISTS
local function slimeExists(slimeId)
    local gameplay = findGameplayFolder()
    if gameplay then
        local enemiesFolder = gameplay:FindFirstChild("Enemies")
        if enemiesFolder then
            return enemiesFolder:FindFirstChild(tostring(slimeId)) ~= nil
        end
    end
    return false
end

-- FPS COUNTER
runService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastTime >= 1 then
        fps = frameCount
        frameCount = 0
        lastTime = tick()
    end
end)

-- ========== CREATE GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZAIXPLOIT"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 245)
frame.Position = UDim2.new(0.5, -150, 0.75, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 200, 80)
stroke.Transparency = 0.3
stroke.Thickness = 1
stroke.Parent = frame

-- SIDE LAMP
local sideLamp = Instance.new("Frame")
sideLamp.Size = UDim2.new(0, 3, 1, -8)
sideLamp.Position = UDim2.new(0, -5, 0, 4)
sideLamp.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
sideLamp.BorderSizePixel = 0
sideLamp.Parent = frame
local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 3)
sideCorner.Parent = sideLamp

-- TITLE BAR
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
titleBar.BackgroundTransparency = 0.5
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- INDICATOR
local indicatorLight = Instance.new("Frame")
indicatorLight.Size = UDim2.new(0, 6, 0, 6)
indicatorLight.Position = UDim2.new(0, 10, 0, 12)
indicatorLight.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
indicatorLight.BorderSizePixel = 0
indicatorLight.Parent = titleBar
local lightCorner = Instance.new("UICorner")
lightCorner.CornerRadius = UDim.new(1, 0)
lightCorner.Parent = indicatorLight

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 0, 16)
titleText.Position = UDim2.new(0, 28, 0, 4)
titleText.BackgroundTransparency = 1
titleText.Text = "ZAIXPLOIT"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.FredokaOne
titleText.TextSize = 11
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(1, -70, 0, 12)
subTitleText.Position = UDim2.new(0, 28, 0, 17)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "SANTET SLIME"
subTitleText.TextColor3 = Color3.fromRGB(150, 150, 200)
subTitleText.Font = Enum.Font.FredokaOne
subTitleText.TextSize = 8
subTitleText.TextXAlignment = Enum.TextXAlignment.Left
subTitleText.Parent = titleBar

-- MINIMIZE BUTTON
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -25, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
minBtn.BackgroundTransparency = 0.3
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minBtn

-- AUTO ROLL TOGGLE BUTTON (ROLL)
local autoRollBtn = Instance.new("TextButton")
autoRollBtn.Size = UDim2.new(0, 45, 0, 22)
autoRollBtn.Position = UDim2.new(1, -135, 0, 4)
autoRollBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
autoRollBtn.BackgroundTransparency = 0
autoRollBtn.Text = "ROLL"
autoRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoRollBtn.Font = Enum.Font.FredokaOne
autoRollBtn.TextSize = 8
autoRollBtn.AutoButtonColor = false
autoRollBtn.Parent = titleBar
local autoRollCorner = Instance.new("UICorner")
autoRollCorner.CornerRadius = UDim.new(0, 5)
autoRollCorner.Parent = autoRollBtn

-- GUN TOGGLE BUTTON (GUN)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 45, 0, 22)
toggleBtn.Position = UDim2.new(1, -85, 0, 4)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
toggleBtn.BackgroundTransparency = 0
toggleBtn.Text = "GUN"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 8
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = titleBar
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 5)
toggleCorner.Parent = toggleBtn

-- CONTENT
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = frame

-- BARIS 1: STOP AT SLIME
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 100, 0, 16)
targetLabel.Position = UDim2.new(0, 10, 0, 8)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Stop at slime:"
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
targetLabel.Font = Enum.Font.FredokaOne
targetLabel.TextSize = 9
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = contentFrame

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(0, 50, 0, 26)
targetBox.Position = UDim2.new(0, 10, 0, 24)
targetBox.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
targetBox.BackgroundTransparency = 0
targetBox.Text = "1"
targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
targetBox.Font = Enum.Font.FredokaOne
targetBox.TextSize = 13
targetBox.TextXAlignment = Enum.TextXAlignment.Center
targetBox.Parent = contentFrame
local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 6)
targetCorner.Parent = targetBox

local targetInfo = Instance.new("TextLabel")
targetInfo.Size = UDim2.new(0, 40, 0, 26)
targetInfo.Position = UDim2.new(0, 68, 0, 24)
targetInfo.BackgroundTransparency = 1
targetInfo.Text = "/ 7"
targetInfo.TextColor3 = Color3.fromRGB(150, 150, 200)
targetInfo.Font = Enum.Font.FredokaOne
targetInfo.TextSize = 13
targetInfo.TextXAlignment = Enum.TextXAlignment.Left
targetInfo.Parent = contentFrame

-- ========== BARIS 2: FPS, SLIME, KILLS ==========
-- FPS CARD
local fpsCard = Instance.new("Frame")
fpsCard.Size = UDim2.new(0, 90, 0, 55)
fpsCard.Position = UDim2.new(0, 10, 0, 60)
fpsCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
fpsCard.BackgroundTransparency = 0.2
fpsCard.BorderSizePixel = 0
fpsCard.Parent = contentFrame
local fpsCardCorner = Instance.new("UICorner")
fpsCardCorner.CornerRadius = UDim.new(0, 6)
fpsCardCorner.Parent = fpsCard

local fpsName = Instance.new("TextLabel")
fpsName.Size = UDim2.new(1, 0, 0, 14)
fpsName.Position = UDim2.new(0, 0, 0, 4)
fpsName.BackgroundTransparency = 1
fpsName.Text = "FPS"
fpsName.TextColor3 = Color3.fromRGB(150, 150, 200)
fpsName.Font = Enum.Font.FredokaOne
fpsName.TextSize = 8
fpsName.TextXAlignment = Enum.TextXAlignment.Center
fpsName.Parent = fpsCard

local fpsValue = Instance.new("TextLabel")
fpsValue.Size = UDim2.new(1, 0, 0, 30)
fpsValue.Position = UDim2.new(0, 0, 0, 20)
fpsValue.BackgroundTransparency = 1
fpsValue.Text = "0"
fpsValue.TextColor3 = Color3.fromRGB(100, 255, 100)
fpsValue.Font = Enum.Font.FredokaOne
fpsValue.TextSize = 18
fpsValue.TextXAlignment = Enum.TextXAlignment.Center
fpsValue.Parent = fpsCard

-- SLIME CARD
local slimeCard = Instance.new("Frame")
slimeCard.Size = UDim2.new(0, 90, 0, 55)
slimeCard.Position = UDim2.new(0, 105, 0, 60)
slimeCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
slimeCard.BackgroundTransparency = 0.2
slimeCard.BorderSizePixel = 0
slimeCard.Parent = contentFrame
local slimeCardCorner = Instance.new("UICorner")
slimeCardCorner.CornerRadius = UDim.new(0, 6)
slimeCardCorner.Parent = slimeCard

local slimeName = Instance.new("TextLabel")
slimeName.Size = UDim2.new(1, 0, 0, 14)
slimeName.Position = UDim2.new(0, 0, 0, 4)
slimeName.BackgroundTransparency = 1
slimeName.Text = "SLIME"
slimeName.TextColor3 = Color3.fromRGB(150, 150, 200)
slimeName.Font = Enum.Font.FredokaOne
slimeName.TextSize = 8
slimeName.TextXAlignment = Enum.TextXAlignment.Center
slimeName.Parent = slimeCard

local slimeValue = Instance.new("TextLabel")
slimeValue.Size = UDim2.new(1, 0, 0, 30)
slimeValue.Position = UDim2.new(0, 0, 0, 20)
slimeValue.BackgroundTransparency = 1
slimeValue.Text = "0/7"
slimeValue.TextColor3 = Color3.fromRGB(100, 200, 255)
slimeValue.Font = Enum.Font.FredokaOne
slimeValue.TextSize = 15
slimeValue.TextXAlignment = Enum.TextXAlignment.Center
slimeValue.Parent = slimeCard

-- KILLS CARD
local killsCard = Instance.new("Frame")
killsCard.Size = UDim2.new(0, 90, 0, 55)
killsCard.Position = UDim2.new(0, 200, 0, 60)
killsCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
killsCard.BackgroundTransparency = 0.2
killsCard.BorderSizePixel = 0
killsCard.Parent = contentFrame
local killsCardCorner = Instance.new("UICorner")
killsCardCorner.CornerRadius = UDim.new(0, 6)
killsCardCorner.Parent = killsCard

local killsName = Instance.new("TextLabel")
killsName.Size = UDim2.new(1, 0, 0, 14)
killsName.Position = UDim2.new(0, 0, 0, 4)
killsName.BackgroundTransparency = 1
killsName.Text = "KILLS"
killsName.TextColor3 = Color3.fromRGB(150, 150, 200)
killsName.Font = Enum.Font.FredokaOne
killsName.TextSize = 8
killsName.TextXAlignment = Enum.TextXAlignment.Center
killsName.Parent = killsCard

local killsValue = Instance.new("TextLabel")
killsValue.Size = UDim2.new(1, 0, 0, 30)
killsValue.Position = UDim2.new(0, 0, 0, 20)
killsValue.BackgroundTransparency = 1
killsValue.Text = "0"
killsValue.TextColor3 = Color3.fromRGB(255, 100, 100)
killsValue.Font = Enum.Font.FredokaOne
killsValue.TextSize = 18
killsValue.TextXAlignment = Enum.TextXAlignment.Center
killsValue.Parent = killsCard

-- ========== BARIS 3: GOOP, KPS, SESSION ==========
-- GOOP CARD
local goopCard = Instance.new("Frame")
goopCard.Size = UDim2.new(0, 90, 0, 55)
goopCard.Position = UDim2.new(0, 10, 0, 122)
goopCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
goopCard.BackgroundTransparency = 0.2
goopCard.BorderSizePixel = 0
goopCard.Parent = contentFrame
local goopCardCorner = Instance.new("UICorner")
goopCardCorner.CornerRadius = UDim.new(0, 6)
goopCardCorner.Parent = goopCard

local goopName = Instance.new("TextLabel")
goopName.Size = UDim2.new(1, 0, 0, 14)
goopName.Position = UDim2.new(0, 0, 0, 4)
goopName.BackgroundTransparency = 1
goopName.Text = "GOOP"
goopName.TextColor3 = Color3.fromRGB(150, 150, 200)
goopName.Font = Enum.Font.FredokaOne
goopName.TextSize = 8
goopName.TextXAlignment = Enum.TextXAlignment.Center
goopName.Parent = goopCard

local goopValue = Instance.new("TextLabel")
goopValue.Size = UDim2.new(1, 0, 0, 30)
goopValue.Position = UDim2.new(0, 0, 0, 20)
goopValue.BackgroundTransparency = 1
goopValue.Text = "0"
goopValue.TextColor3 = Color3.fromRGB(100, 255, 100)
goopValue.Font = Enum.Font.FredokaOne
goopValue.TextSize = 13
goopValue.TextXAlignment = Enum.TextXAlignment.Center
goopValue.Parent = goopCard

-- KPS CARD
local kpsCard = Instance.new("Frame")
kpsCard.Size = UDim2.new(0, 90, 0, 55)
kpsCard.Position = UDim2.new(0, 105, 0, 122)
kpsCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
kpsCard.BackgroundTransparency = 0.2
kpsCard.BorderSizePixel = 0
kpsCard.Parent = contentFrame
local kpsCardCorner = Instance.new("UICorner")
kpsCardCorner.CornerRadius = UDim.new(0, 6)
kpsCardCorner.Parent = kpsCard

local kpsName = Instance.new("TextLabel")
kpsName.Size = UDim2.new(1, 0, 0, 14)
kpsName.Position = UDim2.new(0, 0, 0, 4)
kpsName.BackgroundTransparency = 1
kpsName.Text = "KPS"
kpsName.TextColor3 = Color3.fromRGB(150, 150, 200)
kpsName.Font = Enum.Font.FredokaOne
kpsName.TextSize = 8
kpsName.TextXAlignment = Enum.TextXAlignment.Center
kpsName.Parent = kpsCard

local kpsValue = Instance.new("TextLabel")
kpsValue.Size = UDim2.new(1, 0, 0, 30)
kpsValue.Position = UDim2.new(0, 0, 0, 20)
kpsValue.BackgroundTransparency = 1
kpsValue.Text = "0/s"
kpsValue.TextColor3 = Color3.fromRGB(100, 200, 255)
kpsValue.Font = Enum.Font.FredokaOne
kpsValue.TextSize = 15
kpsValue.TextXAlignment = Enum.TextXAlignment.Center
kpsValue.Parent = kpsCard

-- SESSION CARD
local sessionCard = Instance.new("Frame")
sessionCard.Size = UDim2.new(0, 90, 0, 55)
sessionCard.Position = UDim2.new(0, 200, 0, 122)
sessionCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
sessionCard.BackgroundTransparency = 0.2
sessionCard.BorderSizePixel = 0
sessionCard.Parent = contentFrame
local sessionCardCorner = Instance.new("UICorner")
sessionCardCorner.CornerRadius = UDim.new(0, 6)
sessionCardCorner.Parent = sessionCard

local sessionName = Instance.new("TextLabel")
sessionName.Size = UDim2.new(1, 0, 0, 14)
sessionName.Position = UDim2.new(0, 0, 0, 4)
sessionName.BackgroundTransparency = 1
sessionName.Text = "SESSION"
sessionName.TextColor3 = Color3.fromRGB(150, 150, 200)
sessionName.Font = Enum.Font.FredokaOne
sessionName.TextSize = 8
sessionName.TextXAlignment = Enum.TextXAlignment.Center
sessionName.Parent = sessionCard

local sessionValue = Instance.new("TextLabel")
sessionValue.Size = UDim2.new(1, 0, 0, 30)
sessionValue.Position = UDim2.new(0, 0, 0, 20)
sessionValue.BackgroundTransparency = 1
sessionValue.Text = "0s"
sessionValue.TextColor3 = Color3.fromRGB(180, 180, 255)
sessionValue.Font = Enum.Font.FredokaOne
sessionValue.TextSize = 13
sessionValue.TextXAlignment = Enum.TextXAlignment.Center
sessionValue.Parent = sessionCard

-- STATUS LABEL GUN
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 14)
statusLabel.Position = UDim2.new(0, 10, 0, 190)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🔫 GUN: ACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
statusLabel.Font = Enum.Font.FredokaOne
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

-- STATUS LABEL ROLL
local rollStatusLabel = Instance.new("TextLabel")
rollStatusLabel.Size = UDim2.new(1, -20, 0, 14)
rollStatusLabel.Position = UDim2.new(0, 10, 0, 208)
rollStatusLabel.BackgroundTransparency = 1
rollStatusLabel.Text = "🎲 ROLL: OFF"
rollStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
rollStatusLabel.Font = Enum.Font.FredokaOne
rollStatusLabel.TextSize = 9
rollStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
rollStatusLabel.Parent = contentFrame

-- MINIMIZE FUNCTION
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 300, 0, 30)
        contentFrame.Visible = false
        minBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 300, 0, 245)
        contentFrame.Visible = true
        minBtn.Text = "−"
    end
end)

-- GET TARGET
local function getTargetStop()
    local val = tonumber(targetBox.Text)
    if val and val >= 1 and val <= 7 then
        return val
    end
    return 1
end

-- UPDATE UI
local function updateUI()
    fpsValue.Text = fps
    killsValue.Text = formatNumber(killCount)
    goopValue.Text = formatNumber(totalGoop)
    kpsValue.Text = kps .. "/s"
    sessionValue.Text = formatSessionTime()
    
    local currentSlime = getSlimeCount()
    slimeValue.Text = currentSlime .. "/7"
    
    if currentSlime == 0 then
        slimeValue.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        slimeValue.TextColor3 = Color3.fromRGB(100, 200, 255)
    end
end

-- INIT TRACKER
local function initIdTracker()
    previousSlimeIds = getAllSlimeIds()
end

-- CARI TARGET
local function findBestTarget(enemiesFolder)
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local slimeId = tonumber(enemy.Name)
        if slimeId then
            return slimeId
        end
    end
    return nil
end

-- ========== AUTO ROLL FUNCTION ==========
local function startAutoRoll()
    if autoRollCoroutine then
        coroutine.close(autoRollCoroutine)
        autoRollCoroutine = nil
    end
    
    autoRollCoroutine = coroutine.create(function()
        while autoRollActive do
            pcall(function()
                rollRemote:InvokeServer("requestRoll")
            end)
            wait(autoRollDelay)
        end
    end)
    
    coroutine.resume(autoRollCoroutine)
end

local function stopAutoRoll()
    if autoRollCoroutine then
        coroutine.close(autoRollCoroutine)
        autoRollCoroutine = nil
    end
end

-- ========== GUN MONITORING FUNCTION ==========
local function startGunMonitoring()
    currentTargetId = nil
    initIdTracker()
    
    while isActive do
        local currentSlime = getSlimeCount()
        local target = getTargetStop()
        
        updateKillCount()
        updateKPS()
        
        local shouldAttack = false
        
        if target == 1 then
            shouldAttack = true
            if isWaiting then
                isWaiting = false
                statusLabel.Text = "🔫 GUN: INSTANT MODE"
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
            end
        else
            if currentSlime >= target then
                shouldAttack = true
                if isWaiting then
                    isWaiting = false
                    statusLabel.Text = "🔫 GUN: ATTACKING"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            elseif not isWaiting and currentSlime > 0 and currentSlime < target then
                shouldAttack = true
                statusLabel.Text = "🔫 GUN: ATTACKING"
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            elseif currentSlime == 0 then
                if not isWaiting then
                    isWaiting = true
                    currentTargetId = nil
                    currentTargetHp = nil
                    statusLabel.Text = "🔫 GUN: WAITING"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                end
                shouldAttack = false
            else
                shouldAttack = false
                if not isWaiting then
                    isWaiting = true
                    currentTargetId = nil
                    currentTargetHp = nil
                    statusLabel.Text = "🔫 GUN: WAITING"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                end
            end
        end
        
        if shouldAttack then
            local gameplay = findGameplayFolder()
            if gameplay then
                local enemiesFolder = gameplay:FindFirstChild("Enemies")
                if enemiesFolder then
                    if currentTargetId then
                        local hp, maxHp = getSlimeHp(currentTargetId)
                        if hp then
                            currentTargetHp = hp
                            currentTargetMaxHp = maxHp
                        end
                    end
                    
                    if currentTargetId == nil or not slimeExists(currentTargetId) then
                        currentTargetId = findBestTarget(enemiesFolder)
                        if currentTargetId then
                            local hp, maxHp = getSlimeHp(currentTargetId)
                            currentTargetHp = hp
                            currentTargetMaxHp = maxHp
                        end
                    end
                    
                    if currentTargetId then
                        attackSlime(currentTargetId)
                    end
                end
            end
        end
        
        updateUI()
        wait(loopSpeed)
    end
end

-- ========== TOGGLE GUN ==========
toggleBtn.MouseButton1Click:Connect(function()
    isActive = not isActive
    if isActive then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
        toggleBtn.Text = "GUN"
        statusLabel.Text = "🔫 GUN: ACTIVE"
        statusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
        tweenService:Create(sideLamp, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 255, 80)}):Play()
        tweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 255, 80)}):Play()
        tweenService:Create(indicatorLight, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 255, 80)}):Play()
        task.spawn(startGunMonitoring)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
        toggleBtn.Text = "GUN"
        statusLabel.Text = "🔫 GUN: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
        tweenService:Create(sideLamp, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
        tweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 50, 50)}):Play()
        tweenService:Create(indicatorLight, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
        currentTargetId = nil
        isWaiting = false
    end
end)

-- ========== TOGGLE AUTO ROLL ==========
autoRollBtn.MouseButton1Click:Connect(function()
    autoRollActive = not autoRollActive
    
    if autoRollActive then
        autoRollBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        autoRollBtn.Text = "ON"
        rollStatusLabel.Text = "🎲 ROLL: ON (0.1s bypass)"
        rollStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        startAutoRoll()
    else
        autoRollBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
        autoRollBtn.Text = "ROLL"
        rollStatusLabel.Text = "🎲 ROLL: OFF"
        rollStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
        stopAutoRoll()
    end
end)

-- ========== AUTO START ==========
initIdTracker()
task.spawn(startGunMonitoring)

-- AUTO START ROLL (LANGSUNG AKTIF)
task.spawn(function()
    wait(0.3)
    if autoRollActive then
        autoRollBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        autoRollBtn.Text = "ON"
        rollStatusLabel.Text = "🎲 ROLL: ON (0.1s bypass)"
        rollStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        startAutoRoll()
    end
end)

-- UPDATE LOOP UI
task.spawn(function()
    while true do
        updateUI()
        wait(0.2)
    end
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | SANTET SLIME + AUTO ROLL")
print("═══════════════════════════════════════════")
print("✅ GUN ON/OFF - Santet Slime")
print("✅ ROLL ON/OFF - Auto Roll Bypass 0.1s")
print("✅ GOOP per KILL (FIXED) - 121.000 per slime mati")
print("✅ FPS | SLIME | KILLS | GOOP | KPS | SESSION")
print("✅ Minimize | Draggable")
print("🚀 AUTO START GUN & ROLL - LANGSUNG JALAN")
print("═══════════════════════════════════════════")