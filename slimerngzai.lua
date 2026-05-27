-- ========== SERVICES ==========
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local virtualUser = game:GetService("VirtualUser")

-- ========== VARIABLE UTAMA ==========
local isMinimized = false

-- ========== FITUR TOGGLE STATE ==========
local autoGunActive = true
local autoRollActive = true
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
local maxZoneReached = false

-- ========== GET REMOTE ==========
local function getRemote(serviceName)
    local success, remote = pcall(function()
        return replicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild(serviceName):WaitForChild("RemoteFunction")
    end)
    if success then return remote end
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

-- ========== AUTO GUN ==========
local function attackSlime(slimeId)
    if not slimeGunRemote then return end
    pcall(function() slimeGunRemote:InvokeServer("tryFireSlimeGun", slimeId) end)
end

local function findGameplayFolder()
    for _, child in ipairs(workspace:GetChildren()) do
        if string.match(child.Name, "^Gameplay%d+$") then return child end
    end
    return nil
end

task.spawn(function()
    while true do
        if autoGunActive then
            local gameplay = findGameplayFolder()
            if gameplay then
                local enemiesFolder = gameplay:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                        local slimeId = tonumber(enemy.Name)
                        if slimeId then
                            attackSlime(slimeId)
                            task.wait(0.033)
                        end
                    end
                end
            end
        end
        task.wait(0.033)
    end
end)

-- ========== AUTO ROLL ==========
local function roll()
    if not rollRemote then return end
    pcall(function() rollRemote:InvokeServer("requestRoll") end)
end

task.spawn(function()
    while true do
        if autoRollActive then
            roll()
        end
        task.wait(0.033)
    end
end)

-- ========== AUTO INDEX ==========
local function claimIndex()
    if not indexRemote then return end
    for _, kind in ipairs({"basic","big","huge","shiny","inverted"}) do
        pcall(function() indexRemote:InvokeServer("requestClaimReward", kind) end)
        task.wait(0.1)
    end
end

task.spawn(function()
    while true do
        if autoIndexActive then
            claimIndex()
        end
        task.wait(5)
    end
end)

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
                    pcall(function() dropChild.CFrame = CFrame.new(hrp.Position) end)
                    task.wait(0.05)
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if autoFarmLootActive then
            pullLootToPlayer()
        end
        task.wait(0.5)
    end
end)

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
    if not id and #fruit.Name == 36 then id = fruit.Name end
    if not id and fruit:FindFirstChild("Value") then id = fruit.Value.Value end
    return id
end

local function claimFruit(fruitId)
    if not lootRemote then return end
    pcall(function() lootRemote:InvokeServer("requestCollect", fruitId) end)
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

task.spawn(function()
    while true do
        if autoFarmFruitActive then
            autoCollectFruit()
        end
        task.wait(0.5)
    end
end)

-- ========== AUTO UPGRADE ==========
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
                                    pcall(function() upgradeRemote:InvokeServer("requestUnlock", upgradeName) end)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if autoUpgradeActive then
            upgrade()
        end
        task.wait(1)
    end
end)

-- ========== AUTO REBIRTH ==========
local function rebirth()
    if not rebirthRemote then return end
    pcall(function() rebirthRemote:InvokeServer("requestRebirth") end)
end

task.spawn(function()
    while true do
        if autoRebirthActive then
            rebirth()
        end
        task.wait(5)
    end
end)

-- ========== AUTO BUY ZONE ==========
local function getBestOpenZone()
    local bestZone = 0
    local zonesFolder = workspace:FindFirstChild("Zones")
    if zonesFolder then
        for _, zone in ipairs(zonesFolder:GetChildren()) do
            local zoneNum = tonumber(zone.Name) or 0
            local gate = zone:FindFirstChild("Gate")
            local blocker = gate and gate:FindFirstChild("ClientGateBlocker_"..zone.Name)
            if not blocker or (blocker and not blocker.CanCollide) then
                if zoneNum > bestZone then bestZone = zoneNum end
            end
        end
    end
    return bestZone
end

local function canBuyNextZone()
    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then return false end
    local currentZoneNum = getBestOpenZone()
    return zonesFolder:FindFirstChild(tostring(currentZoneNum + 1)) ~= nil
end

local function tryBuyZone()
    if not zonesRemote then return false end
    if maxZoneReached then return false end
    if not canBuyNextZone() then
        maxZoneReached = true
        autoBuyZoneActive = false
        return false
    end
    local success = pcall(function() zonesRemote:InvokeServer("requestPurchaseZone") end)
    if not success then
        maxZoneReached = true
        autoBuyZoneActive = false
        return false
    end
    return true
end

local function tryTeleportToBestZone()
    if not zonesRemote then return false end
    local bestZone = getBestOpenZone()
    if bestZone == 0 then
        autoBuyZoneActive = false
        return false
    end
    pcall(function() zonesRemote:InvokeServer("requestTeleportZone", bestZone) end)
    return true
end

task.spawn(function()
    while true do
        if autoBuyZoneActive then
            local bought = tryBuyZone()
            if bought then
                task.wait(1)
                tryTeleportToBestZone()
            end
        end
        task.wait(5)
    end
end)

task.spawn(function()
    while true do
        task.wait(120)
        if maxZoneReached and canBuyNextZone() then
            maxZoneReached = false
        end
    end
end)

-- ========== AUTO POTIONS ==========
local function useBoost(boostType)
    if not boostRemote then return end
    pcall(function() boostRemote:InvokeServer("requestUseBoost", boostType) end)
end

task.spawn(function() while true do if autoLuckActive then useBoost("luck") end task.wait(1) end end)
task.spawn(function() while true do if autoUltraLuckActive then useBoost("ultraLuck") end task.wait(1) end end)
task.spawn(function() while true do if autoCurrencyActive then useBoost("currency") end task.wait(1) end end)
task.spawn(function() while true do if autoRollSpeedActive then useBoost("rollSpeed") end task.wait(1) end end)

-- ========== ANTI AFK ==========
localPlayer.Idled:Connect(function()
    virtualUser:Button2Down(Vector2.new(0, 0))
    task.wait(1)
    virtualUser:Button2Up(Vector2.new(0, 0))
end)

-- ========== DELETE AUTOREJOIN ==========
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
                        if autoRejoin then autoRejoin:Destroy() end
                    end
                end
            end
        end
    end
end
deleteAutoRejoinService()
task.spawn(function() while true do task.wait(10) deleteAutoRejoinService() end end)

-- ========== CREATE GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZAIXPLOIT"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 460)
frame.Position = UDim2.new(0.5, -140, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Transparency = 0.4
stroke.Thickness = 1
stroke.Parent = frame

-- ========== SIDE LAMP PALING PANJANG (60 STRIP) ==========
local sideLamp = Instance.new("Frame")
sideLamp.Size = UDim2.new(0, 5, 1, 0)
sideLamp.Position = UDim2.new(0, -6, 0, 0)
sideLamp.BackgroundTransparency = 1
sideLamp.BorderSizePixel = 0
sideLamp.Parent = frame

local colorGradient = {
    Color3.fromRGB(0, 80, 255),
    Color3.fromRGB(0, 130, 255),
    Color3.fromRGB(0, 180, 255),
    Color3.fromRGB(100, 200, 255),
    Color3.fromRGB(255, 220, 0),
    Color3.fromRGB(255, 180, 0),
    Color3.fromRGB(40, 40, 55),
    Color3.fromRGB(20, 20, 35),
}

local strips = {}
for i = 1, 70 do
    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(1, 0, 0, 3)
    strip.BackgroundColor3 = colorGradient[(i % #colorGradient) + 1]
    strip.BorderSizePixel = 0
    strip.Parent = sideLamp
    table.insert(strips, strip)
end

local sideLayout = Instance.new("UIListLayout")
sideLayout.FillDirection = Enum.FillDirection.Vertical
sideLayout.Padding = UDim.new(0, 0)
sideLayout.Parent = sideLamp

local offset = 0
task.spawn(function()
    while true do
        for i, strip in ipairs(strips) do
            local colorIndex = (i + offset) % #colorGradient + 1
            strip.BackgroundColor3 = colorGradient[colorIndex]
        end
        offset = offset + 1
        task.wait(0.08)
    end
end)

-- ========== TITLE BAR ==========
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local indicatorLight = Instance.new("Frame")
indicatorLight.Size = UDim2.new(0, 8, 0, 8)
indicatorLight.Position = UDim2.new(0, 12, 0.5, -4)
indicatorLight.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
indicatorLight.BorderSizePixel = 0
indicatorLight.Parent = titleBar
local lightCorner = Instance.new("UICorner")
lightCorner.CornerRadius = UDim.new(1, 0)
lightCorner.Parent = indicatorLight

task.spawn(function()
    while true do
        for i = 0.3, 1, 0.1 do indicatorLight.BackgroundTransparency = i task.wait(0.05) end
        for i = 1, 0.3, -0.1 do indicatorLight.BackgroundTransparency = i task.wait(0.05) end
    end
end)

-- Baris 1 Kiri
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.5, 0, 0, 18)
titleText.Position = UDim2.new(0, 28, 0, 6)
titleText.BackgroundTransparency = 1
titleText.Text = "ZAIXPLOIT"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.FredokaOne
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Baris 1 Kanan
local nickText = Instance.new("TextLabel")
nickText.Size = UDim2.new(0.5, -50, 0, 18)
nickText.Position = UDim2.new(0.5, 0, 0, 6)
nickText.BackgroundTransparency = 1
nickText.Text = localPlayer.DisplayName
nickText.TextColor3 = Color3.fromRGB(200, 200, 255)
nickText.Font = Enum.Font.FredokaOne
nickText.TextSize = 12
nickText.TextXAlignment = Enum.TextXAlignment.Right
nickText.Parent = titleBar

-- Baris 2 Kiri
local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(0.5, 0, 0, 12)
subTitleText.Position = UDim2.new(0, 28, 0, 26)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "SLIME RNG"
subTitleText.TextColor3 = Color3.fromRGB(0, 200, 255)
subTitleText.Font = Enum.Font.FredokaOne
subTitleText.TextSize = 10
subTitleText.TextXAlignment = Enum.TextXAlignment.Left
subTitleText.Parent = titleBar

-- Baris 2 Kanan
local userText = Instance.new("TextLabel")
userText.Size = UDim2.new(0.5, -50, 0, 12)
userText.Position = UDim2.new(0.5, 0, 0, 26)
userText.BackgroundTransparency = 1
userText.Text = localPlayer.Name
userText.TextColor3 = Color3.fromRGB(150, 150, 200)
userText.Font = Enum.Font.FredokaOne
userText.TextSize = 9
userText.TextXAlignment = Enum.TextXAlignment.Right
userText.Parent = titleBar

-- MINIMIZE BUTTON
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -30, 0, 19)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
minBtn.BackgroundTransparency = 0.3
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

-- ========== SCROLLING FRAME ==========
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, 0, 1, -60)
contentScroll.Position = UDim2.new(0, 0, 0, 60)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = frame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 6)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentScroll

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = contentScroll

-- ========== FUNGSI GARIS ==========
local function addSeparator(parent)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    line.BackgroundTransparency = 0.6
    line.BorderSizePixel = 0
    line.Parent = parent
    return line
end

-- ========== FUNGSI TOGGLE ==========
local function createToggle(parent, text, emoji, getState, setState)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(22, 20, 38)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = emoji .. " " .. text
    label.TextColor3 = Color3.fromRGB(210, 210, 240)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 26)
    btn.Position = UDim2.new(1, -62, 0.5, -13)
    btn.BackgroundColor3 = getState() and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(45, 40, 65)
    btn.Text = getState() and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        local newState = not getState()
        setState(newState)
        if newState then
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 40, 65)
            btn.Text = "OFF"
        end
    end)
    
    return frame
end

-- ========== MEMBUAT UI ==========
createToggle(contentScroll, "Auto Gun", "🔫", function() return autoGunActive end, function(v) autoGunActive = v end)
addSeparator(contentScroll)

createToggle(contentScroll, "Auto Roll", "🎲", function() return autoRollActive end, function(v) autoRollActive = v end)
addSeparator(contentScroll)

local utilTitle = Instance.new("TextLabel")
utilTitle.Size = UDim2.new(1, 0, 0, 24)
utilTitle.BackgroundTransparency = 1
utilTitle.Text = "📦 AUTO UTILITY"
utilTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
utilTitle.Font = Enum.Font.FredokaOne
utilTitle.TextSize = 11
utilTitle.TextXAlignment = Enum.TextXAlignment.Left
utilTitle.Parent = contentScroll

createToggle(contentScroll, "Auto Index", "📊", function() return autoIndexActive end, function(v) autoIndexActive = v end)
createToggle(contentScroll, "Auto Farm Loot", "💰", function() return autoFarmLootActive end, function(v) autoFarmLootActive = v end)
createToggle(contentScroll, "Auto Farm Fruit", "🍎", function() return autoFarmFruitActive end, function(v) autoFarmFruitActive = v end)
createToggle(contentScroll, "Auto Rebirth", "🔄", function() return autoRebirthActive end, function(v) autoRebirthActive = v end)
createToggle(contentScroll, "Auto Buy + Best Zone", "🏪", function() return autoBuyZoneActive end, function(v) autoBuyZoneActive = v end)
addSeparator(contentScroll)

local potTitle = Instance.new("TextLabel")
potTitle.Size = UDim2.new(1, 0, 0, 24)
potTitle.BackgroundTransparency = 1
potTitle.Text = "🧪 AUTO POTION"
potTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
potTitle.Font = Enum.Font.FredokaOne
potTitle.TextSize = 11
potTitle.TextXAlignment = Enum.TextXAlignment.Left
potTitle.Parent = contentScroll

createToggle(contentScroll, "Luck Potion", "🍀", function() return autoLuckActive end, function(v) autoLuckActive = v end)
createToggle(contentScroll, "Ultra Luck Potion", "⭐", function() return autoUltraLuckActive end, function(v) autoUltraLuckActive = v end)
createToggle(contentScroll, "Currency Potion", "💵", function() return autoCurrencyActive end, function(v) autoCurrencyActive = v end)
createToggle(contentScroll, "Roll Speed Potion", "⚡", function() return autoRollSpeedActive end, function(v) autoRollSpeedActive = v end)
addSeparator(contentScroll)

local zoneStatus = Instance.new("TextLabel")
zoneStatus.Size = UDim2.new(1, 0, 0, 18)
zoneStatus.BackgroundTransparency = 1
zoneStatus.Text = "🏪 Zone: Ready"
zoneStatus.TextColor3 = Color3.fromRGB(150, 150, 200)
zoneStatus.Font = Enum.Font.FredokaOne
zoneStatus.TextSize = 9
zoneStatus.TextXAlignment = Enum.TextXAlignment.Left
zoneStatus.Parent = contentScroll

task.spawn(function()
    while true do
        if autoBuyZoneActive then
            if maxZoneReached then
                zoneStatus.Text = "🏪 Zone: MAX REACHED (stopped)"
                zoneStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                zoneStatus.Text = "🏪 Zone: Active"
                zoneStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        else
            zoneStatus.Text = "🏪 Zone: Disabled"
            zoneStatus.TextColor3 = Color3.fromRGB(150, 150, 200)
        end
        task.wait(1)
    end
end)

-- ========== MINIMIZE ==========
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        frame.Size = UDim2.new(0, 280, 0, 60)
        contentScroll.Visible = false
        sideLamp.Visible = false
        minBtn.Text = "+"
    else
        frame.Size = UDim2.new(0, 280, 0, 460)
        contentScroll.Visible = true
        sideLamp.Visible = true
        minBtn.Text = "−"
    end
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | SLIME RNG - FINAL")
print("═══════════════════════════════════════════")
print("✅ SIDE LAMP 70 STRIP (PALING PANJANG)")
print("✅ BACKGROUND PEAKET (GAK TEMBUS)")
print("✅ GUI UKURAN 280x460 (GAK KEGEDEAN)")
print("✅ SEMUA FITUR LENGKAP")
print("🚀 SCRIPT SIAP DIGUNAKAN")
print("═══════════════════════════════════════════")