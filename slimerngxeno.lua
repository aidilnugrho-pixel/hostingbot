-- ZAIXPLOIT - SLIME RNG (XENO COMPATIBLE)
-- Support: Auto UFO, Auto Gun, Auto Roll, Auto Index, Auto Loot, Auto Fruit, Auto Upgrade, Auto Rebirth, Auto Buy Zone, Auto Potion

local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local isMinimized = false

local AutoGunMode = 1
local AutoRollMode = 1
local GunDelay = 0.1
local RollDelay = 0.1

local AutoIndex = false
local AutoFarmLoot = false
local AutoFarmFruit = false
local AutoUpgrade = false
local AutoRebirth = false
local AutoBuyZone = false
local AutoLuck = false
local AutoUltraLuck = false
local AutoCurrency = false
local AutoRollSpeed = false

-- AUTO UFO
local autoUfoEnabled = true
local lastUIText = nil
local isProcessing = false

-- ZONE LIST (1-40)
local zoneList = {
    { num = 1, name = "Grasslands", patterns = {"grasslands"} },
    { num = 2, name = "Desert", patterns = {"desert"} },
    { num = 3, name = "Polar", patterns = {"polar"} },
    { num = 4, name = "Volcano", patterns = {"volcano"} },
    { num = 5, name = "Islands", patterns = {"islands"} },
    { num = 6, name = "Cave", patterns = {"cave"} },
    { num = 7, name = "Heaven", patterns = {"heaven"} },
    { num = 8, name = "Jungle", patterns = {"jungle"} },
    { num = 9, name = "Canyon", patterns = {"canyon"} },
    { num = 10, name = "Mushroom Forest", patterns = {"mushroom forest"} },
    { num = 11, name = "Moon", patterns = {"moon"} },
    { num = 12, name = "Redwood Forest", patterns = {"redwood forest"} },
    { num = 13, name = "Meteor", patterns = {"meteor"} },
    { num = 14, name = "Candyland", patterns = {"candyland"} },
    { num = 15, name = "Cherry Grove", patterns = {"cherry grove"} },
    { num = 16, name = "Crystal Cavern", patterns = {"crystal cavern"} },
    { num = 17, name = "Pumpkin Patch", patterns = {"pumpkin patch"} },
    { num = 18, name = "Atlantis", patterns = {"atlantis"} },
    { num = 19, name = "River", patterns = {"river"} },
    { num = 20, name = "Pyramids", patterns = {"pyramids"} },
    { num = 21, name = "Graveyard", patterns = {"graveyard"} },
    { num = 22, name = "Hot Springs", patterns = {"hot springs"} },
    { num = 23, name = "Tribe", patterns = {"tribe"} },
    { num = 24, name = "Toxic Wasteland", patterns = {"toxic wasteland"} },
    { num = 25, name = "Steampunk", patterns = {"steampunk"} },
    { num = 26, name = "Winter Wonderland", patterns = {"winter wonderland"} },
    { num = 27, name = "Farm", patterns = {"farm"} },
    { num = 28, name = "Jungle Temple", patterns = {"jungle temple"} },
    { num = 29, name = "Underworld", patterns = {"underworld"} },
    { num = 30, name = "Swamp", patterns = {"swamp"} },
    { num = 31, name = "Mushroom Village", patterns = {"mushroom village"} },
    { num = 32, name = "The Void", patterns = {"the void"} },
    { num = 33, name = "Honeycomb", patterns = {"honeycomb"} },
    { num = 34, name = "Glow Mine", patterns = {"glow mine"} },
    { num = 35, name = "Alien Planet", patterns = {"alien planet"} },
    { num = 36, name = "Spooky House", patterns = {"spooky house"} },
    { num = 37, name = "Skull Island", patterns = {"skull island"} },
    { num = 38, name = "Slime Inc.", patterns = {"slime inc"} },
    { num = 39, name = "Ancient Portal", patterns = {"ancient portal"} },
    { num = 40, name = "Racetrack", patterns = {"racetrack"} }
}

local function GetRemote(Name)
    local Success, Remote = pcall(function()
        return RepStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild(Name):WaitForChild("RemoteFunction")
    end)
    return Success and Remote or nil
end

local SlimeGun = GetRemote("SlimeGunService")
local RollSvc = GetRemote("RollService")
local IndexSvc = GetRemote("IndexService")
local BoostSvc = GetRemote("BoostService")
local RebirthSvc = GetRemote("RebirthService")
local ZonesSvc = GetRemote("ZonesService")
local UpgradeSvc = GetRemote("UpgradeService")
local LootSvc = GetRemote("LootService")

local function UseBoost(Type)
    if not BoostSvc then return end
    pcall(function() BoostSvc:InvokeServer("requestUseBoost", Type) end)
end

local function FindGameplay()
    for _, Child in ipairs(workspace:GetChildren()) do
        if string.match(Child.Name, "^Gameplay%d+$") then return Child end
    end
    return nil
end

local function AttackSlime(Id)
    if not SlimeGun then return end
    pcall(function() SlimeGun:InvokeServer("tryFireSlimeGun", Id) end)
end

local function Roll()
    if not RollSvc then return end
    pcall(function() RollSvc:InvokeServer("requestRoll") end)
end

local function ClaimIndex()
    if not IndexSvc then return end
    for _, Kind in ipairs({"basic","big","huge","shiny","inverted"}) do
        pcall(function() IndexSvc:InvokeServer("requestClaimReward", Kind) end)
        wait(0.1)
    end
end

local function PullLoot()
    local Char = LocalPlayer.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local LootFolder = workspace:FindFirstChild("Loot")
    if LootFolder then
        for _, Drop in ipairs(LootFolder:GetChildren()) do
            for _, Part in ipairs(Drop:GetChildren()) do
                if Part:IsA("BasePart") and Part.Name ~= "LootHighlight" then
                    pcall(function() Part.CFrame = CFrame.new(HRP.Position) end)
                    wait(0.05)
                end
            end
        end
    end
end

local function GetAllFruits()
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

local function GetFruitId(fruit)
    local id = fruit:GetAttribute("LootId") or fruit:GetAttribute("Id") or fruit:GetAttribute("UUID")
    if not id and #fruit.Name == 36 then id = fruit.Name end
    if not id and fruit:FindFirstChild("Value") then id = fruit.Value.Value end
    return id
end

local function ClaimFruit(fruitId)
    if not LootSvc then return end
    pcall(function() LootSvc:InvokeServer("requestCollect", fruitId) end)
end

local function AutoCollectFruit()
    local fruits = GetAllFruits()
    for _, fruit in pairs(fruits) do
        local id = GetFruitId(fruit)
        if id then
            ClaimFruit(id)
        end
        wait(0.1)
    end
end

local function Upgrade()
    if not UpgradeSvc then return end
    local PG = LocalPlayer:FindFirstChild("PlayerGui")
    if not PG then return end
    local Root = PG:FindFirstChild("Root")
    if not Root then return end
    local UpgradeScreen = Root:FindFirstChild("UpgradeScreen")
    if not UpgradeScreen then return end
    local UpgradeContent = UpgradeScreen:FindFirstChild("UpgradeContent")
    if not UpgradeContent then return end
    local Frame = UpgradeContent:FindFirstChild("Frame")
    if not Frame then return end
    for _, Tile in ipairs(Frame:GetChildren()) do
        if Tile.Name ~= "UIAspectRatioConstraint" and Tile.Name ~= "UpgradeHoverInfo" then
            local UpgradeName = Tile.Name:match("^(%S+)Tile")
            if UpgradeName then
                pcall(function() UpgradeSvc:InvokeServer("requestUnlock", UpgradeName) end)
                wait(0.1)
            end
        end
    end
end

local function Rebirth()
    if not RebirthSvc then return end
    pcall(function() RebirthSvc:InvokeServer("requestRebirth") end)
end

local function GetBestOpenZone()
    local Best = 0
    local Zones = workspace:FindFirstChild("Zones")
    if Zones then
        for _, Zone in ipairs(Zones:GetChildren()) do
            local Num = tonumber(Zone.Name) or 0
            if Num > 0 and Num <= 40 then
                local Gate = Zone:FindFirstChild("Gate")
                local Blocker = Gate and Gate:FindFirstChild("ClientGateBlocker_"..Num)
                if Blocker and not Blocker.CanCollide and Num > Best then
                    Best = Num
                end
            end
        end
    end
    return Best
end

local function TeleportToZone(zoneNum, zoneName)
    local targetPart = workspace:FindFirstChild("Zones") 
        and workspace.Zones:FindFirstChild(tostring(zoneNum)) 
        and workspace.Zones[tostring(zoneNum)]:FindFirstChild("POI") 
        and workspace.Zones[tostring(zoneNum)].POI:FindFirstChild("PlayerSpawn")
    
    if not targetPart then
        targetPart = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild(tostring(zoneNum))
    end
    
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = char.HumanoidRootPart
    hrp.CFrame = CFrame.new(targetPart.Position.X, targetPart.Position.Y + 3, targetPart.Position.Z)
    return true
end

local function BuyZoneAndTeleport()
    if not ZonesSvc then return end
    
    local colinSebelum = GetBestOpenZone()
    
    if colinSebelum >= 40 then
        return
    end
    
    local targetZone = colinSebelum + 1
    if targetZone > 40 then return end
    
    pcall(function()
        ZonesSvc:InvokeServer("requestPurchaseZone")
    end)
    
    wait(3)
    
    local bestZone = GetBestOpenZone()
    if bestZone > 0 and bestZone <= 40 then
        TeleportToZone(bestZone, "Best Zone " .. bestZone)
    end
end

local function getUIText()
    local ufoUI = LocalPlayer.PlayerGui:FindFirstChild("Root") 
        and LocalPlayer.PlayerGui.Root:FindFirstChild("UfoStatusRoot")
    
    if not ufoUI then
        ufoUI = LocalPlayer.PlayerGui:FindFirstChild("UfoStatusRoot")
    end
    
    if not ufoUI then
        return nil
    end
    
    local function findText(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.Text and child.Text ~= "" then
                    return child.Text
                end
            end
            local found = findText(child)
            if found then return found end
        end
        return nil
    end
    
    return findText(ufoUI)
end

local function detectZoneFromText(text)
    if not text then return nil, nil end
    local lowerText = string.lower(text)
    
    for _, zone in pairs(zoneList) do
        if lowerText == string.lower(zone.name) then
            return zone.num, zone.name
        end
    end
    
    for _, zone in pairs(zoneList) do
        for _, pattern in pairs(zone.patterns) do
            if string.find(lowerText, pattern) then
                return zone.num, zone.name
            end
        end
    end
    
    return nil, nil
end

local function isTargetTimer(text)
    if not text then return false end
    return text == "56.00" or text == "56:00"
end

local function processText(currentText)
    if isProcessing then return end
    if currentText == lastUIText then return end
    
    local zoneNum, zoneName = detectZoneFromText(currentText)
    
    if zoneNum then
        isProcessing = true
        TeleportToZone(zoneNum, zoneName)
        lastUIText = currentText
        isProcessing = false
    elseif isTargetTimer(currentText) then
        local colin = GetBestOpenZone()
        local targetZone = colin + 1
        if targetZone <= 40 then
            isProcessing = true
            TeleportToZone(targetZone, "Best Zone " .. targetZone)
            lastUIText = currentText
            isProcessing = false
        else
            lastUIText = currentText
        end
    else
        lastUIText = currentText
    end
end

-- LOOP AUTO UFO
spawn(function()
    while true do
        if autoUfoEnabled then
            local currentText = getUIText()
            if currentText then
                processText(currentText)
            end
        end
        wait(0.5)
    end
end)

-- LOOP AUTO GUN
spawn(function()
    while true do
        if AutoGunMode > 0 then
            local Gameplay = FindGameplay()
            if Gameplay then
                local Enemies = Gameplay:FindFirstChild("Enemies")
                if Enemies then
                    for _, Enemy in ipairs(Enemies:GetChildren()) do
                        local Id = tonumber(Enemy.Name)
                        if Id then
                            AttackSlime(Id)
                            wait(GunDelay)
                        end
                    end
                end
            end
        end
        wait(GunDelay)
    end
end)

-- LOOP AUTO ROLL
spawn(function()
    while true do
        if AutoRollMode > 0 then Roll() end
        wait(RollDelay)
    end
end)

-- LOOP LAINNYA
spawn(function() while true do if AutoIndex then ClaimIndex() end wait(5) end end)
spawn(function() while true do if AutoFarmLoot then PullLoot() end wait(0.5) end end)
spawn(function() while true do if AutoFarmFruit then AutoCollectFruit() end wait(0.5) end end)
spawn(function() while true do if AutoUpgrade then Upgrade() end wait(1) end end)
spawn(function() while true do if AutoRebirth then Rebirth() end wait(5) end end)
spawn(function() while true do if AutoBuyZone then BuyZoneAndTeleport() end wait(30) end end)
spawn(function() while true do if AutoLuck then UseBoost("luck") end wait(1) end end)
spawn(function() while true do if AutoUltraLuck then UseBoost("ultraLuck") end wait(1) end end)
spawn(function() while true do if AutoCurrency then UseBoost("currency") end wait(1) end end)
spawn(function() while true do if AutoRollSpeed then UseBoost("rollSpeed") end wait(1) end end)

-- ANTI AFK (XENO COMPATIBLE)
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0, 0))
        wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0))
    end)
end)

-- DELETE AUTO REJOIN
local function DeleteAutoRejoin()
    pcall(function()
        local Path = RepStorage:FindFirstChild("Packages")
        if Path then
            local Index = Path:FindFirstChild("_Index")
            if Index then
                local Net = Index:FindFirstChild("leifstout_networker@0.3.1")
                if Net then
                    local NW = Net:FindFirstChild("networker")
                    if NW then
                        local Remotes = NW:FindFirstChild("_remotes")
                        if Remotes then
                            local AR = Remotes:FindFirstChild("AutoRejoinService")
                            if AR then AR:Destroy() end
                        end
                    end
                end
            end
        end
    end)
end
DeleteAutoRejoin()
spawn(function() while true do wait(10) DeleteAutoRejoin() end end)

-- ========== GUI UNTUK XENO ==========
local GUI = Instance.new("ScreenGui")
GUI.Name = "ZAIXPLOIT"
GUI.ResetOnSpawn = false
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 360, 0, 240)
Main.Position = UDim2.new(0.5, -180, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 6, 15)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 20, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 80, 150)),
})
UIGradient.Rotation = 90
UIGradient.Parent = Main

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 150, 255)
Stroke.Transparency = 0.3
Stroke.Thickness = 1
Stroke.Parent = Main

-- SIDE LAMP
local SideLamp = Instance.new("Frame")
SideLamp.Size = UDim2.new(0, 4, 1, -8)
SideLamp.Position = UDim2.new(0, 2, 0, 4)
SideLamp.BackgroundTransparency = 1
SideLamp.BorderSizePixel = 0
SideLamp.ClipsDescendants = true
SideLamp.Parent = Main

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 2)
SideCorner.Parent = SideLamp

local SideLayout = Instance.new("UIListLayout")
SideLayout.FillDirection = Enum.FillDirection.Vertical
SideLayout.Padding = UDim.new(0, 0)
SideLayout.Parent = SideLamp

local NeonColors = {
    Color3.fromRGB(0, 50, 200),
    Color3.fromRGB(0, 100, 230),
    Color3.fromRGB(0, 150, 255),
    Color3.fromRGB(80, 180, 255),
    Color3.fromRGB(0, 150, 255),
    Color3.fromRGB(0, 100, 230),
    Color3.fromRGB(0, 50, 200),
}

local Strips = {}
local StripHeight = 8
local TotalHeight = 240 - 16

for i = 1, math.floor(TotalHeight / StripHeight) do
    local Strip = Instance.new("Frame")
    Strip.Size = UDim2.new(1, 0, 0, StripHeight)
    Strip.BackgroundColor3 = NeonColors[1]
    Strip.BorderSizePixel = 0
    Strip.Parent = SideLamp
    table.insert(Strips, Strip)
end

local Offset = 0
spawn(function()
    while true do
        Offset = Offset + 1
        for i, Strip in ipairs(Strips) do
            local ColorIndex = (i + Offset) % #NeonColors + 1
            Strip.BackgroundColor3 = NeonColors[ColorIndex]
        end
        wait(0.08)
    end
end)

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 6)
TitleCorner.Parent = TitleBar

local Indicator = Instance.new("Frame")
Indicator.Size = UDim2.new(0, 6, 0, 6)
Indicator.Position = UDim2.new(0, 10, 0, 14)
Indicator.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
Indicator.BorderSizePixel = 0
Indicator.Parent = TitleBar
local IndicatorCorner = Instance.new("UICorner")
IndicatorCorner.CornerRadius = UDim.new(1, 0)
IndicatorCorner.Parent = Indicator

spawn(function()
    while true do
        for i = 0.3, 1, 0.1 do Indicator.BackgroundTransparency = i wait(0.05) end
        for i = 1, 0.3, -0.1 do Indicator.BackgroundTransparency = i wait(0.05) end
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 0, 14)
Title.Position = UDim2.new(0, 22, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "ZAIXPLOIT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 10
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local NickLabel = Instance.new("TextLabel")
NickLabel.Size = UDim2.new(0.5, -40, 0, 14)
NickLabel.Position = UDim2.new(0.5, 0, 0, 5)
NickLabel.BackgroundTransparency = 1
NickLabel.Text = LocalPlayer.DisplayName
NickLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
NickLabel.Font = Enum.Font.FredokaOne
NickLabel.TextSize = 9
NickLabel.TextXAlignment = Enum.TextXAlignment.Right
NickLabel.Parent = TitleBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.5, 0, 0, 10)
SubTitle.Position = UDim2.new(0, 22, 0, 20)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "SLIME RNG"
SubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
SubTitle.Font = Enum.Font.FredokaOne
SubTitle.TextSize = 7
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TitleBar

local UserLabel = Instance.new("TextLabel")
UserLabel.Size = UDim2.new(0.5, -40, 0, 10)
UserLabel.Position = UDim2.new(0.5, 0, 0, 20)
UserLabel.BackgroundTransparency = 1
UserLabel.Text = LocalPlayer.Name
UserLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
UserLabel.Font = Enum.Font.FredokaOne
UserLabel.TextSize = 7
UserLabel.TextXAlignment = Enum.TextXAlignment.Right
UserLabel.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 18, 0, 18)
MinBtn.Position = UDim2.new(1, -22, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
MinBtn.BackgroundTransparency = 0.2
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
MinBtn.AutoButtonColor = true
MinBtn.Parent = TitleBar
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinBtn

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -35)
Scroll.Position = UDim2.new(0, 0, 0, 35)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 8)
Padding.PaddingRight = UDim.new(0, 8)
Padding.PaddingTop = UDim.new(0, 6)
Padding.PaddingBottom = UDim.new(0, 6)
Padding.Parent = Scroll

-- AUTO UFO CARD
local AutoUfoCard = Instance.new("Frame")
AutoUfoCard.Size = UDim2.new(1, 0, 0, 85)
AutoUfoCard.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
AutoUfoCard.BackgroundTransparency = 0.2
AutoUfoCard.BorderSizePixel = 0
AutoUfoCard.Parent = Scroll
local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 5)
CardCorner.Parent = AutoUfoCard

local UfoIcon = Instance.new("TextLabel")
UfoIcon.Size = UDim2.new(0, 35, 1, 0)
UfoIcon.Position = UDim2.new(0, 5, 0, 0)
UfoIcon.BackgroundTransparency = 1
UfoIcon.Text = "🛸"
UfoIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
UfoIcon.TextSize = 20
UfoIcon.Parent = AutoUfoCard

local UfoTitle = Instance.new("TextLabel")
UfoTitle.Size = UDim2.new(1, -80, 0, 16)
UfoTitle.Position = UDim2.new(0, 45, 0, 4)
UfoTitle.BackgroundTransparency = 1
UfoTitle.Text = "AUTO UFO"
UfoTitle.TextColor3 = Color3.fromRGB(200, 200, 230)
UfoTitle.Font = Enum.Font.FredokaOne
UfoTitle.TextSize = 10
UfoTitle.TextXAlignment = Enum.TextXAlignment.Left
UfoTitle.Parent = AutoUfoCard

local UfoToggleBtn = Instance.new("TextButton")
UfoToggleBtn.Size = UDim2.new(0, 45, 0, 20)
UfoToggleBtn.Position = UDim2.new(1, -53, 0, 2)
UfoToggleBtn.BackgroundColor3 = autoUfoEnabled and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(70, 70, 70)
UfoToggleBtn.Text = autoUfoEnabled and "ON" or "OFF"
UfoToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UfoToggleBtn.Font = Enum.Font.FredokaOne
UfoToggleBtn.TextSize = 9
UfoToggleBtn.BorderSizePixel = 0
UfoToggleBtn.Parent = AutoUfoCard
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = UfoToggleBtn

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -45, 0, 16)
textLabel.Position = UDim2.new(0, 45, 0, 24)
textLabel.BackgroundTransparency = 1
textLabel.Text = "📝 Teks: --"
textLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
textLabel.Font = Enum.Font.Gotham
textLabel.TextSize = 9
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.Parent = AutoUfoCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -45, 0, 16)
statusLabel.Position = UDim2.new(0, 45, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🗺️ Status: --"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = AutoUfoCard

local actionLabel = Instance.new("TextLabel")
actionLabel.Size = UDim2.new(1, -45, 0, 16)
actionLabel.Position = UDim2.new(0, 45, 0, 60)
actionLabel.BackgroundTransparency = 1
actionLabel.Text = "⚡ Aksi: --"
actionLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
actionLabel.Font = Enum.Font.Gotham
actionLabel.TextSize = 9
actionLabel.TextXAlignment = Enum.TextXAlignment.Left
actionLabel.Parent = AutoUfoCard

UfoToggleBtn.MouseButton1Click:Connect(function()
    autoUfoEnabled = not autoUfoEnabled
    if autoUfoEnabled then
        UfoToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        UfoToggleBtn.Text = "ON"
    else
        UfoToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        UfoToggleBtn.Text = "OFF"
    end
end)

spawn(function()
    while true do
        if GUI and GUI.Parent then
            local currentText = getUIText()
            if currentText then
                textLabel.Text = "📝 Teks: \"" .. currentText .. "\""
                textLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                local zoneNum, zoneName = detectZoneFromText(currentText)
                
                if zoneNum then
                    statusLabel.Text = "🗺️ Status: Zone (" .. zoneName .. ")"
                    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    if autoUfoEnabled and not isProcessing then
                        actionLabel.Text = "⚡ Aksi: Teleport ke " .. zoneName
                        actionLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                elseif isTargetTimer(currentText) then
                    local colin = GetBestOpenZone()
                    local targetZone = colin + 1
                    statusLabel.Text = "📍 Status: Timer 56.00!"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    if autoUfoEnabled and not isProcessing then
                        actionLabel.Text = "⚡ Aksi: Best Zone " .. targetZone
                        actionLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    end
                else
                    statusLabel.Text = "🗺️ Status: Diabaikan"
                    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                    actionLabel.Text = "⚡ Aksi: --"
                    actionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            else
                textLabel.Text = "📝 Teks: (UI tidak ditemukan)"
                textLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                statusLabel.Text = "🗺️ Status: UI tidak ditemukan"
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                actionLabel.Text = "⚡ Aksi: --"
            end
        end
        wait(0.5)
    end
end)

-- GUI COMPONENTS
local function MakeModeToggle(Parent, Text, Emoji, GetMode, SetMode)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 28)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Parent = Parent
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = UDim.new(0, 5)
    FCorner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -75, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Emoji .. " " .. Text
    Label.TextColor3 = Color3.fromRGB(200, 200, 230)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 55, 0, 22)
    Btn.Position = UDim2.new(1, -63, 0.5, -11)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    Btn.Text = "NORMAL"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.FredokaOne
    Btn.TextSize = 9
    Btn.BorderSizePixel = 0
    Btn.Parent = Frame
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = Btn
    
    local function UpdateButton()
        local Mode = GetMode()
        if Mode == 0 then
            Btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            Btn.Text = "OFF"
        elseif Mode == 1 then
            Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            Btn.Text = "NORMAL"
        elseif Mode == 2 then
            Btn.BackgroundColor3 = Color3.fromRGB(0, 80, 200)
            Btn.Text = "FAST"
        end
    end
    
    Btn.MouseButton1Click:Connect(function()
        local Mode = GetMode()
        if Mode == 0 then
            SetMode(1)
        elseif Mode == 1 then
            SetMode(2)
        elseif Mode == 2 then
            SetMode(0)
        end
        UpdateButton()
    end)
    
    UpdateButton()
    return Frame
end

local function MakeToggle(Parent, Text, Emoji, GetState, SetState)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 24)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Parent = Parent
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = UDim.new(0, 5)
    FCorner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Emoji .. " " .. Text
    Label.TextColor3 = Color3.fromRGB(200, 200, 230)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 45, 0, 20)
    Btn.Position = UDim2.new(1, -53, 0.5, -10)
    Btn.BackgroundColor3 = GetState() and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(70, 70, 70)
    Btn.Text = GetState() and "ON" or "OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.FredokaOne
    Btn.TextSize = 9
    Btn.BorderSizePixel = 0
    Btn.Parent = Frame
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = Btn
    
    Btn.MouseButton1Click:Connect(function()
        local New = not GetState()
        SetState(New)
        Btn.BackgroundColor3 = New and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(70, 70, 70)
        Btn.Text = New and "ON" or "OFF"
    end)
    
    return Frame
end

local function MakeTitle(Parent, Text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Color3.fromRGB(0, 150, 255)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Parent
    return Label
end

local function MakeSep(Parent)
    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    Line.BackgroundTransparency = 0.6
    Line.BorderSizePixel = 0
    Line.Parent = Parent
    return Line
end

-- BUILD GUI ELEMENTS
MakeModeToggle(Scroll, "Auto Gun", "🔫", function() return AutoGunMode end, function(v)
    AutoGunMode = v
    if v == 1 then GunDelay = 0.1
    elseif v == 2 then GunDelay = 0.01
    end
end)

MakeModeToggle(Scroll, "Auto Roll", "🎲", function() return AutoRollMode end, function(v)
    AutoRollMode = v
    if v == 1 then RollDelay = 0.1
    elseif v == 2 then RollDelay = 0.01
    end
end)

MakeSep(Scroll)
MakeTitle(Scroll, "📦 AUTO UTILITY")
MakeToggle(Scroll, "Auto Index", "📊", function() return AutoIndex end, function(v) AutoIndex = v end)
MakeToggle(Scroll, "Auto Farm Loot", "💰", function() return AutoFarmLoot end, function(v) AutoFarmLoot = v end)
MakeToggle(Scroll, "Auto Farm Fruit", "🍎", function() return AutoFarmFruit end, function(v) AutoFarmFruit = v end)
MakeToggle(Scroll, "Auto Upgrade", "⬆️", function() return AutoUpgrade end, function(v) AutoUpgrade = v end)
MakeToggle(Scroll, "Auto Rebirth", "🔄", function() return AutoRebirth end, function(v) AutoRebirth = v end)
MakeToggle(Scroll, "Auto Buy Zone", "🏪", function() return AutoBuyZone end, function(v) AutoBuyZone = v end)
MakeSep(Scroll)

MakeTitle(Scroll, "🧪 AUTO POTION")
MakeToggle(Scroll, "Luck Potion", "🍀", function() return AutoLuck end, function(v) AutoLuck = v end)
MakeToggle(Scroll, "Ultra Luck Potion", "⭐", function() return AutoUltraLuck end, function(v) AutoUltraLuck = v end)
MakeToggle(Scroll, "Currency Potion", "💵", function() return AutoCurrency end, function(v) AutoCurrency = v end)
MakeToggle(Scroll, "Roll Speed Potion", "⚡", function() return AutoRollSpeed end, function(v) AutoRollSpeed = v end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 14)
Status.BackgroundTransparency = 1
Status.Text = "● ANTI AFK ACTIVE"
Status.TextColor3 = Color3.fromRGB(100, 255, 100)
Status.Font = Enum.Font.FredokaOne
Status.TextSize = 9
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Scroll

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 360, 0, 35)
        Scroll.Visible = false
        SideLamp.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 360, 0, 240)
        Scroll.Visible = true
        SideLamp.Visible = true
        MinBtn.Text = "−"
    end
end)

print("✅ ZAIXPLOIT - SLIME RNG loaded (XENO Compatible)")