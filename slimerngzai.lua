-- ========== SERVICES ==========
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local virtualUser = game:GetService("VirtualUser")
local httpService = game:GetService("HttpService")

-- ========== VARIABLE UTAMA ==========
local isActive = true
local isMinimized = false
local loopSpeed = 0.033

-- ========== FITUR TOGGLE STATE ==========
local autoIndexActive = false
local autoFarmLootActive = false
local autoFarmFruitActive = false
local autoUpgradeActive = false
local autoRebirthActive = false
local autoBuyZoneActive = false

local autoLuckActive = false
local autoUltraLuckActive = false
local autoCurrencyActive = false
local autoRollSpeedActive = false

-- ========== GET REMOTE FUNCTION ==========
local function getRemote(serviceName)
    local success, remote = pcall(function()
        return replicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild(serviceName):WaitForChild("RemoteFunction")
    end)
    if success then
        return remote
    end
    return nil
end

local slimeGunRemote = getRemote("SlimeGunService")
local rollRemote = getRemote("RollService")
local indexRemote = getRemote("IndexService")
local boostRemote = getRemote("BoostService")
local rebirthRemote = getRemote("RebirthService")
local zonesRemote = getRemote("ZonesService")
local upgradeRemote = getRemote("UpgradeService")
local lootRemote = getRemote("LootService")

-- ========== FUNGSI UTAMA ==========
local function attackSlime(slimeId)
    if not slimeGunRemote then return end
    local success = pcall(function()
        slimeGunRemote:InvokeServer("tryFireSlimeGun", slimeId)
    end)
end

local function roll()
    if not rollRemote then return end
    pcall(function()
        rollRemote:InvokeServer("requestRoll")
    end)
end

local function claimIndex()
    if not indexRemote then return end
    for _, kind in ipairs({"basic","big","huge","shiny","inverted"}) do
        pcall(function()
            indexRemote:InvokeServer("requestClaimReward", kind)
        end)
        task.wait(0.1)
    end
end

local function useBoost(boostType)
    if not boostRemote then return end
    pcall(function()
        boostRemote:InvokeServer("requestUseBoost", boostType)
    end)
end

local function rebirth()
    if not rebirthRemote then return end
    pcall(function()
        rebirthRemote:InvokeServer("requestRebirth")
    end)
end

local function purchaseZone()
    if not zonesRemote then return end
    pcall(function()
        zonesRemote:InvokeServer("requestPurchaseZone")
    end)
end

local function teleportBestZone()
    if not zonesRemote then return end
    local best = 0
    local zonesFolder = workspace:FindFirstChild("Zones")
    if zonesFolder then
        for _, zone in ipairs(zonesFolder:GetChildren()) do
            local gate = zone:FindFirstChild("Gate")
            local blocker = gate and gate:FindFirstChild("ClientGateBlocker_"..zone.Name)
            if blocker and not blocker.CanCollide then
                local n = tonumber(blocker.Parent.Parent.Name) or 0
                if n > best then best = n end
            end
        end
    end
    pcall(function()
        zonesRemote:InvokeServer("requestTeleportZone", best + 1)
    end)
end

local function upgrade()
    if not upgradeRemote then return end
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if pg then
        local root = pg:FindFirstChild("Root")
        if root then
            local us = root:FindFirstChild("UpgradeScreen")
            if us then
                local uc = us:FindFirstChild("UpgradeContent")
                if uc then
                    local fr = uc:FindFirstChild("Frame")
                    if fr then
                        for _, tile in ipairs(fr:GetChildren()) do
                            if tile.Name ~= "UIAspectRatioConstraint" and tile.Name ~= "UpgradeHoverInfo" then
                                local upgradeName = tile.Name:match("^(%S+)Tile")
                                if upgradeName then
                                    pcall(function()
                                        upgradeRemote:InvokeServer("requestUnlock", upgradeName)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ========== AUTO FARM LOOT ==========
local function pullLootToPlayer()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local loot = workspace:FindFirstChild("Loot")
    if loot then
        for _, drop in ipairs(loot:GetChildren()) do
            for _, dropChild in ipairs(drop:GetChildren()) do
                if dropChild:IsA("BasePart") and dropChild.Name ~= "LootHighlight" then
                    pcall(function()
                        dropChild.CFrame = CFrame.new(hrp.Position)
                    end)
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ========== AUTO FARM FRUIT ==========
local function getAllFruits()
    local fruits = {}
    local locations = {
        workspace:FindFirstChild("DroppedFruits"),
        workspace:FindFirstChild("Fruits"),
        workspace:FindFirstChild("Loot"),
        workspace:FindFirstChild("Drops")
    }
    for _, loc in pairs(locations) do
        if loc then
            for _, child in pairs(loc:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    table.insert(fruits, child)
                end
            end
        end
    end
    return fruits
end

local function getFruitId(fruit)
    local id = fruit:GetAttribute("LootId") or fruit:GetAttribute("Id") or fruit:GetAttribute("UUID")
    if not id and #fruit.Name == 36 then
        id = fruit.Name
    end
    if not id and fruit:FindFirstChild("Value") then
        id = fruit.Value.Value
    end
    return id
end

local function claimFruit(fruitId)
    if not lootRemote then return end
    pcall(function()
        lootRemote:InvokeServer("requestCollect", fruitId)
    end)
end

local function autoCollectFruit()
    local fruits = getAllFruits()
    for _, fruit in pairs(fruits) do
        local id = getFruitId(fruit)
        if id then
            claimFruit(id)
        end
        task.wait(0.1)
    end
end

-- ========== FIND GAMEPLAY FOLDER UNTUK AUTO GUN ==========
local function findGameplayFolder()
    for _, child in ipairs(workspace:GetChildren()) do
        if string.match(child.Name, "^Gameplay%d+$") then
            return child
        end
    end
    return nil
end

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

local previousSlimeIds = {}

local function updateKillCount()
    local currentIds = getAllSlimeIds()
    for _, id in ipairs(previousSlimeIds) do
        local found = false
        for _, cid in ipairs(currentIds) do
            if cid == id then
                found = true
                break
            end
        end
        if not found then
            killCount = killCount + 1
            totalGoop = totalGoop + goopPerKill
        end
    end
    previousSlimeIds = currentIds
end

-- ========== ANTI AFK (BACKEND) ==========
localPlayer.Idled:Connect(function()
    virtualUser:Button2Down(Vector2.new(0, 0))
    task.wait(1)
    virtualUser:Button2Up(Vector2.new(0, 0))
end)

-- ========== DELETE AUTOREJOIN (BACKEND) ==========
local function deleteAutoRejoinService()
    local path = replicatedStorage:FindFirstChild("Packages")
    if path then
        local index = path:FindFirstChild("_Index")
        if index then
            local netFolder = index:FindFirstChild("leifstout_networker@0.3.1")
            if netFolder then
                local networker = netFolder:FindFirstChild("networker")
                if networker then
                    local remotes = networker:FindFirstChild("_remotes")
                    if remotes then
                        local autoRejoin = remotes:FindFirstChild("AutoRejoinService")
                        if autoRejoin then
                            autoRejoin:Destroy()
                        end
                    end
                end
            end
        end
    end
end
deleteAutoRejoinService()
task.spawn(function()
    while true do
        task.wait(10)
        deleteAutoRejoinService()
    end
end)

-- ========== AUTO GUN LOOP ==========
task.spawn(function()
    while isActive do
        local gameplay = findGameplayFolder()
        if gameplay then
            local enemiesFolder = gameplay:FindFirstChild("Enemies")
            if enemiesFolder then
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    local slimeId = tonumber(enemy.Name)
                    if slimeId then
                        attackSlime(slimeId)
                        task.wait(loopSpeed)
                    end
                end
            end
        end
        task.wait(loopSpeed)
    end
end)

-- ========== AUTO ROLL LOOP ==========
task.spawn(function()
    while true do
        roll()
        task.wait(0.033)
    end
end)

-- ========== AUTO INDEX LOOP ==========
task.spawn(function()
    while true do
        if autoIndexActive then
            claimIndex()
        end
        task.wait(5)
    end
end)

-- ========== AUTO FARM LOOT LOOP ==========
task.spawn(function()
    while true do
        if autoFarmLootActive then
            pullLootToPlayer()
        end
        task.wait(0.5)
    end
end)

-- ========== AUTO FARM FRUIT LOOP ==========
task.spawn(function()
    while true do
        if autoFarmFruitActive then
            autoCollectFruit()
        end
        task.wait(1)
    end
end)

-- ========== AUTO UPGRADE LOOP ==========
task.spawn(function()
    while true do
        if autoUpgradeActive then
            upgrade()
        end
        task.wait(2)
    end
end)

-- ========== AUTO REBIRTH LOOP ==========
task.spawn(function()
    while true do
        if autoRebirthActive then
            rebirth()
        end
        task.wait(5)
    end
end)

-- ========== AUTO BUY + BEST ZONE LOOP ==========
task.spawn(function()
    while true do
        if autoBuyZoneActive then
            purchaseZone()
            task.wait(1)
            teleportBestZone()
        end
        task.wait(5)
    end
end)

-- ========== AUTO POTION LOOPS ==========
task.spawn(function()
    while true do
        if autoLuckActive then useBoost("luck") end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if autoUltraLuckActive then useBoost("ultraLuck") end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if autoCurrencyActive then useBoost("currency") end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if autoRollSpeedActive then useBoost("rollSpeed") end
        task.wait(1)
    end
end)

-- ========== CREATE GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZAIXPLOIT"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 320)
frame.Position = UDim2.new(0.5, -140, 0.5, -160)
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

-- INDICATOR LIGHT
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
titleText.Size = UDim2.new(1, -50, 0, 16)
titleText.Position = UDim2.new(0, 28, 0, 7)
titleText.BackgroundTransparency = 1
titleText.Text = "ZAIXPLOIT"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.FredokaOne
titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

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

-- SCROLLING FRAME (GULIR)
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, 0, 1, -30)
contentScroll.Position = UDim2.new(0, 0, 0, 30)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 6
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 200, 80)
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = frame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentScroll

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = contentScroll

-- ========== FUNGSI BUAT TOGGLE ==========
local function createToggle(parent, text, emoji, getState, setState)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = emoji .. " " .. text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 24)
    btn.Position = UDim2.new(1, -58, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 200, 200)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        local newState = not getState()
        setState(newState)
        if newState then
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            btn.Text = "ON"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
            btn.Text = "OFF"
            btn.TextColor3 = Color3.fromRGB(255, 200, 200)
        end
    end)
    
    return frame
end

local function createStatus(parent, text, emoji)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local statCorner = Instance.new("UICorner")
    statCorner.CornerRadius = UDim.new(0, 6)
    statCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = emoji .. " " .. text
    label.TextColor3 = Color3.fromRGB(100, 255, 100)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame
    
    return frame
end

-- ========== MEMBUAT UI ==========
-- STATUS AUTO GUN & AUTO ROLL
createStatus(contentScroll, "AUTO GUN", "🔫")
createStatus(contentScroll, "AUTO ROLL", "🎲")

-- AUTO UTILITY SECTION
local utilitySection = Instance.new("Frame")
utilitySection.Size = UDim2.new(1, 0, 0, 28)
utilitySection.BackgroundTransparency = 1
utilitySection.Parent = contentScroll

local utilTitle = Instance.new("TextLabel")
utilTitle.Size = UDim2.new(1, 0, 1, 0)
utilTitle.BackgroundTransparency = 1
utilTitle.Text = "📦 AUTO UTILITY"
utilTitle.TextColor3 = Color3.fromRGB(80, 200, 255)
utilTitle.Font = Enum.Font.FredokaOne
utilTitle.TextSize = 11
utilTitle.TextXAlignment = Enum.TextXAlignment.Left
utilTitle.Parent = utilitySection

createToggle(contentScroll, "Auto Index", "📊", function() return autoIndexActive end, function(v) autoIndexActive = v end)
createToggle(contentScroll, "Auto Farm Loot", "💰", function() return autoFarmLootActive end, function(v) autoFarmLootActive = v end)
createToggle(contentScroll, "Auto Farm Fruit", "🍎", function() return autoFarmFruitActive end, function(v) autoFarmFruitActive = v end)
createToggle(contentScroll, "Auto Upgrade", "⬆️", function() return autoUpgradeActive end, function(v) autoUpgradeActive = v end)
createToggle(contentScroll, "Auto Rebirth", "🔄", function() return autoRebirthActive end, function(v) autoRebirthActive = v end)
createToggle(contentScroll, "Auto Buy + Best Zone", "🏪", function() return autoBuyZoneActive end, function(v) autoBuyZoneActive = v end)

-- AUTO POTION SECTION
local potionSection = Instance.new("Frame")
potionSection.Size = UDim2.new(1, 0, 0, 28)
potionSection.BackgroundTransparency = 1
potionSection.Parent = contentScroll

local potTitle = Instance.new("TextLabel")
potTitle.Size = UDim2.new(1, 0, 1, 0)
potTitle.BackgroundTransparency = 1
potTitle.Text = "🧪 AUTO POTION"
potTitle.TextColor3 = Color3.fromRGB(80, 200, 255)
potTitle.Font = Enum.Font.FredokaOne
potTitle.TextSize = 11
potTitle.TextXAlignment = Enum.TextXAlignment.Left
potTitle.Parent = potionSection

createToggle(contentScroll, "Luck Potion", "🍀", function() return autoLuckActive end, function(v) autoLuckActive = v end)
createToggle(contentScroll, "Ultra Luck Potion", "⭐", function() return autoUltraLuckActive end, function(v) autoUltraLuckActive = v end)
createToggle(contentScroll, "Currency Potion", "💵", function() return autoCurrencyActive end, function(v) autoCurrencyActive = v end)
createToggle(contentScroll, "Roll Speed Potion", "⚡", function() return autoRollSpeedActive end, function(v) autoRollSpeedActive = v end)

-- STATUS LABEL BAWAH
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "● 🔫 ACTIVE | 🎲 ROLLING"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.FredokaOne
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = contentScroll

-- MINIMIZE FUNCTION
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 280, 0, 30)
        contentScroll.Visible = false
        minBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 280, 0, 320)
        contentScroll.Visible = true
        minBtn.Text = "−"
    end
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | SLIME RNG - FINAL")
print("═══════════════════════════════════════════")
print("✅ AUTO GUN + AUTO ROLL LANGSUNG ON")
print("✅ 10 FITUR TOGGLE (UTILITY + POTION)")
print("✅ ANTI AFK + DELETE AUTOREJOIN (BACKEND)")
print("✅ UI DENGAN SISTEM GULIR (SCROLL)")
print("🚀 SCRIPT SIAP DIGUNAKAN")
print("═══════════════════════════════════════════")