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

-- ========== AUTO UFO (DETECT UI) ==========
local autoUfoEnabled = true
local WAIT_TIME = 3
local isProcessing = false
local lastProcessedText = nil

-- ========== DATA NAMA ZONE (1-40) ==========
local zoneList = {
    { num = 1, name = "Grasslands", patterns = {"grasslands", "grass"} },
    { num = 2, name = "Desert", patterns = {"desert"} },
    { num = 3, name = "Polar", patterns = {"polar", "snow", "ice"} },
    { num = 4, name = "Volcano", patterns = {"volcano", "lava"} },
    { num = 5, name = "Islands", patterns = {"islands", "island"} },
    { num = 6, name = "Cave", patterns = {"cave"} },
    { num = 7, name = "Heaven", patterns = {"heaven", "cloud"} },
    { num = 8, name = "Jungle", patterns = {"jungle"} },
    { num = 9, name = "Canyon", patterns = {"canyon"} },
    { num = 10, name = "Mushroom Forest", patterns = {"mushroom forest", "mushroom"} },
    { num = 11, name = "Moon", patterns = {"moon"} },
    { num = 12, name = "Redwood Forest", patterns = {"redwood"} },
    { num = 13, name = "Meteor", patterns = {"meteor"} },
    { num = 14, name = "Candyland", patterns = {"candyland", "candy"} },
    { num = 15, name = "Cherry Grove", patterns = {"cherry"} },
    { num = 16, name = "Crystal Cavern", patterns = {"crystal cavern", "crystal"} },
    { num = 17, name = "Pumpkin Patch", patterns = {"pumpkin"} },
    { num = 18, name = "Atlantis", patterns = {"atlantis"} },
    { num = 19, name = "River", patterns = {"river"} },
    { num = 20, name = "Pyramids", patterns = {"pyramids", "pyramid"} },
    { num = 21, name = "Graveyard", patterns = {"graveyard"} },
    { num = 22, name = "Hot Springs", patterns = {"hot springs", "springs"} },
    { num = 23, name = "Tribe", patterns = {"tribe"} },
    { num = 24, name = "Toxic Wasteland", patterns = {"toxic", "wasteland"} },
    { num = 25, name = "Steampunk", patterns = {"steampunk"} },
    { num = 26, name = "Winter Wonderland", patterns = {"winter"} },
    { num = 27, name = "Farm", patterns = {"farm"} },
    { num = 28, name = "Jungle Temple", patterns = {"jungle temple", "temple"} },
    { num = 29, name = "Underworld", patterns = {"underworld"} },
    { num = 30, name = "Swamp", patterns = {"swamp"} },
    { num = 31, name = "Mushroom Village", patterns = {"mushroom village", "village"} },
    { num = 32, name = "The Void", patterns = {"void"} },
    { num = 33, name = "Honeycomb", patterns = {"honeycomb", "honey"} },
    { num = 34, name = "Glow Mine", patterns = {"glow mine", "mine"} },
    { num = 35, name = "Alien Planet", patterns = {"alien"} },
    { num = 36, name = "Spooky House", patterns = {"spooky"} },
    { num = 37, name = "Skull Island", patterns = {"skull"} },
    { num = 38, name = "Slime Inc.", patterns = {"slime inc"} },
    { num = 39, name = "Ancient Portal", patterns = {"ancient portal", "portal"} },
    { num = 40, name = "Racetrack", patterns = {"racetrack", "race"} }
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
        task.wait(0.1)
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
                    task.wait(0.05)
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
        task.wait(0.1)
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
                task.wait(0.1)
            end
        end
    end
end

local function Rebirth()
    if not RebirthSvc then return end
    pcall(function() RebirthSvc:InvokeServer("requestRebirth") end)
end

-- ========== FUNGSI GET BEST OPEN ZONE (COLIN) ==========
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

-- ========== TELEPORT KE PLAYERSPAWN ZONE ==========
local function TeleportToPlayerSpawn(zoneNumber)
    if zoneNumber > 40 then return false end
    
    local targetPart = workspace:FindFirstChild("Zones") 
        and workspace.Zones:FindFirstChild(tostring(zoneNumber)) 
        and workspace.Zones[tostring(zoneNumber)]:FindFirstChild("POI") 
        and workspace.Zones[tostring(zoneNumber)].POI:FindFirstChild("PlayerSpawn")
    
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

-- ========== AUTO BUY ZONE (MAX 40) ==========
local function BuyZoneAndTeleport()
    if not ZonesSvc then return end
    
    local colinSebelum = GetBestOpenZone()
    
    if colinSebelum >= 40 then
        print("🏆 SUDAH DI ZONE MAKSIMAL 40!")
        return
    end
    
    local targetZone = colinSebelum + 1
    if targetZone > 40 then return end
    
    print("🛒 Membeli Zone " .. targetZone .. "...")
    local Success = pcall(function()
        ZonesSvc:InvokeServer("requestPurchaseZone")
    end)
    
    if Success then
        print("✅ Berhasil membeli Zone " .. targetZone)
        print("⏳ Tunggu 3 detik...")
        task.wait(3)
        
        local bestZone = GetBestOpenZone()
        if bestZone > 0 and bestZone <= 40 then
            print("📍 Teleport ke Best Zone: " .. bestZone)
            TeleportToPlayerSpawn(bestZone)
        end
    end
end

-- ========== FUNGSI BACA UI ==========
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

-- ========== DETECT ZONE DARI TEKS ==========
local function detectZoneFromText(text)
    if not text then return nil, nil end
    local lowerText = string.lower(text)
    
    for _, zone in pairs(zoneList) do
        for _, pattern in pairs(zone.patterns) do
            if string.find(lowerText, pattern) then
                return zone.num, zone.name
            end
        end
    end
    return nil, nil
end

-- ========== CEK APAKAH TEKS TIMER ==========
local function isTimerText(text)
    if not text then return false end
    return string.match(text, "^%d+[:.]%d+$") ~= nil
end

-- ========== FUNGSI TELEPORT KE ZONE ==========
local function teleportToZone(zoneNum, zoneName)
    local targetPart = workspace:FindFirstChild("Zones") 
        and workspace.Zones:FindFirstChild(tostring(zoneNum)) 
        and workspace.Zones[tostring(zoneNum)]:FindFirstChild("POI") 
        and workspace.Zones[tostring(zoneNum)].POI:FindFirstChild("PlayerSpawn")
    
    if not targetPart then
        targetPart = workspace:FindFirstChild("Zones") and workspace.Zones:FindFirstChild(tostring(zoneNum))
    end
    
    if not targetPart or not targetPart:IsA("BasePart") then
        print("❌ Zone " .. zoneNum .. " tidak ditemukan")
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = char.HumanoidRootPart
    hrp.CFrame = CFrame.new(targetPart.Position.X, targetPart.Position.Y + 3, targetPart.Position.Z)
    print("✅ Teleport ke " .. (zoneName or "Zone " .. zoneNum))
    return true
end

-- ========== FUNGSI GET TIMER DARI UI ==========
local function getTimerFromUI()
    local ufoUI = LocalPlayer.PlayerGui:FindFirstChild("Root") 
        and LocalPlayer.PlayerGui.Root:FindFirstChild("UfoStatusRoot")
    
    if not ufoUI then
        ufoUI = LocalPlayer.PlayerGui:FindFirstChild("UfoStatusRoot")
    end
    
    if not ufoUI then
        return nil
    end
    
    local function findTimer(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                if string.match(text, "^%d+[:.]%d+$") then
                    return text
                end
            end
            local found = findTimer(child)
            if found then return found end
        end
        return nil
    end
    
    return findTimer(ufoUI)
end

-- ========== PROSES PERUBAHAN TEKS ==========
local function processTextChange(currentText)
    if isProcessing then return end
    if currentText == lastProcessedText then return end
    
    isProcessing = true
    
    print("═══════════════════════════════════════════")
    print("📝 Teks berubah: \"" .. currentText .. "\"")
    
    local zoneNum, zoneName = detectZoneFromText(currentText)
    
    if zoneNum then
        print("🎯 Nama zone terdeteksi: " .. zoneName)
        print("⚡ Langsung teleport ke " .. zoneName)
        teleportToZone(zoneNum, zoneName)
        lastProcessedText = currentText
        
    elseif isTimerText(currentText) then
        print("❌ Zone tidak terdeteksi (timer)")
        print("⏳ Tunggu " .. WAIT_TIME .. " detik...")
        
        for i = WAIT_TIME, 1, -1 do
            if not autoUfoEnabled then break end
            print("   ⌛ " .. i .. " detik lagi...")
            task.wait(1)
        end
        
        if autoUfoEnabled then
            local bestZone = GetBestOpenZone()
            local targetZone = bestZone + 1
            
            if targetZone <= 40 then
                print("📍 Teleport ke Best Zone: " .. targetZone)
                teleportToZone(targetZone, "Best Zone")
                lastProcessedText = currentText
            else
                print("🏆 Sudah di zone maksimal 40!")
            end
        end
    else
        print("❌ Teks tidak dikenali")
        lastProcessedText = currentText
    end
    
    print("✅ Selesai, menunggu perubahan teks berikutnya...")
    print("═══════════════════════════════════════════")
    
    isProcessing = false
end

-- ========== LOOP UTAMA AUTO UFO ==========
task.spawn(function()
    while true do
        if autoUfoEnabled then
            local currentText = getUIText()
            if currentText and currentText ~= lastProcessedText and not isProcessing then
                processTextChange(currentText)
            end
        end
        task.wait(0.5)
    end
end)

-- ========== EXISTING LOOPS ==========
task.spawn(function()
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
                            task.wait(GunDelay)
                        end
                    end
                end
            end
        end
        task.wait(GunDelay)
    end
end)

task.spawn(function()
    while true do
        if AutoRollMode > 0 then Roll() end
        task.wait(RollDelay)
    end
end)

task.spawn(function() while true do if AutoIndex then ClaimIndex() end task.wait(5) end end)
task.spawn(function() while true do if AutoFarmLoot then PullLoot() end task.wait(0.5) end end)
task.spawn(function() while true do if AutoFarmFruit then AutoCollectFruit() end task.wait(0.5) end end)
task.spawn(function() while true do if AutoUpgrade then Upgrade() end task.wait(1) end end)
task.spawn(function() while true do if AutoRebirth then Rebirth() end task.wait(5) end end)
task.spawn(function() while true do if AutoBuyZone then BuyZoneAndTeleport() end task.wait(30) end end)

task.spawn(function() while true do if AutoLuck then UseBoost("luck") end task.wait(1) end end)
task.spawn(function() while true do if AutoUltraLuck then UseBoost("ultraLuck") end task.wait(1) end end)
task.spawn(function() while true do if AutoCurrency then UseBoost("currency") end task.wait(1) end end)
task.spawn(function() while true do if AutoRollSpeed then UseBoost("rollSpeed") end task.wait(1) end end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0))
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0))
end)

local function DeleteAutoRejoin()
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
end
DeleteAutoRejoin()
task.spawn(function() while true do task.wait(10) DeleteAutoRejoin() end end)

-- ========== GUI ==========
local GUI = Instance.new("ScreenGui")
GUI.Name = "ZAIXPLOIT"
GUI.ResetOnSpawn = false
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 520)
Main.Position = UDim2.new(0.5, -160, 0.5, -260)
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
local TotalHeight = Main.Size.Y.Offset - 16

for i = 1, math.floor(TotalHeight / StripHeight) do
    local Strip = Instance.new("Frame")
    Strip.Size = UDim2.new(1, 0, 0, StripHeight)
    Strip.BackgroundColor3 = NeonColors[1]
    Strip.BorderSizePixel = 0
    Strip.Parent = SideLamp
    table.insert(Strips, Strip)
end

local Offset = 0
task.spawn(function()
    while true do
        Offset = Offset + 1
        for i, Strip in ipairs(Strips) do
            local ColorIndex = (i + Offset) % #NeonColors + 1
            if ColorIndex == 0 then ColorIndex = 1 end
            Strip.BackgroundColor3 = NeonColors[ColorIndex]
        end
        task.wait(0.08)
    end
end)

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

task.spawn(function()
    while true do
        for i = 0.3, 1, 0.1 do Indicator.BackgroundTransparency = i task.wait(0.05) end
        for i = 1, 0.3, -0.1 do Indicator.BackgroundTransparency = i task.wait(0.05) end
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

-- ========== UFO TIMER ==========
local TimerFrame = Instance.new("Frame")
TimerFrame.Size = UDim2.new(1, 0, 0, 50)
TimerFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
TimerFrame.BackgroundTransparency = 0.2
TimerFrame.BorderSizePixel = 0
TimerFrame.Parent = Scroll
local TimerCorner = Instance.new("UICorner")
TimerCorner.CornerRadius = UDim.new(0, 5)
TimerCorner.Parent = TimerFrame

local TimerIcon = Instance.new("TextLabel")
TimerIcon.Size = UDim2.new(0, 35, 1, 0)
TimerIcon.Position = UDim2.new(0, 5, 0, 0)
TimerIcon.BackgroundTransparency = 1
TimerIcon.Text = "⏱️"
TimerIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
TimerIcon.TextSize = 20
TimerIcon.Parent = TimerFrame

local TimerTitle = Instance.new("TextLabel")
TimerTitle.Size = UDim2.new(1, -45, 0, 18)
TimerTitle.Position = UDim2.new(0, 45, 0, 4)
TimerTitle.BackgroundTransparency = 1
TimerTitle.Text = "UFO TIMER"
TimerTitle.TextColor3 = Color3.fromRGB(200, 200, 230)
TimerTitle.Font = Enum.Font.FredokaOne
TimerTitle.TextSize = 10
TimerTitle.TextXAlignment = Enum.TextXAlignment.Left
TimerTitle.Parent = TimerFrame

local TimerValue = Instance.new("TextLabel")
TimerValue.Size = UDim2.new(1, -45, 0, 24)
TimerValue.Position = UDim2.new(0, 45, 0, 22)
TimerValue.BackgroundTransparency = 1
TimerValue.Text = "--:--"
TimerValue.TextColor3 = Color3.fromRGB(100, 255, 100)
TimerValue.Font = Enum.Font.FredokaOne
TimerValue.TextSize = 18
TimerValue.TextXAlignment = Enum.TextXAlignment.Left
TimerValue.Parent = TimerFrame

-- Update timer display
task.spawn(function()
    while true do
        local timer = getTimerFromUI()
        if timer then
            TimerValue.Text = timer
            TimerValue.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            TimerValue.Text = "--:--"
            TimerValue.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(0.5)
    end
end)

-- ========== AUTO UFO CARD ==========
local AutoUfoFrame = Instance.new("Frame")
AutoUfoFrame.Size = UDim2.new(1, 0, 0, 100)
AutoUfoFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
AutoUfoFrame.BackgroundTransparency = 0.2
AutoUfoFrame.BorderSizePixel = 0
AutoUfoFrame.Parent = Scroll
local AutoUfoCorner = Instance.new("UICorner")
AutoUfoCorner.CornerRadius = UDim.new(0, 5)
AutoUfoCorner.Parent = AutoUfoFrame

local AutoUfoIcon = Instance.new("TextLabel")
AutoUfoIcon.Size = UDim2.new(0, 35, 1, 0)
AutoUfoIcon.Position = UDim2.new(0, 5, 0, 0)
AutoUfoIcon.BackgroundTransparency = 1
AutoUfoIcon.Text = "🛸"
AutoUfoIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
AutoUfoIcon.TextSize = 20
AutoUfoIcon.Parent = AutoUfoFrame

local AutoUfoTitle = Instance.new("TextLabel")
AutoUfoTitle.Size = UDim2.new(1, -80, 0, 18)
AutoUfoTitle.Position = UDim2.new(0, 45, 0, 4)
AutoUfoTitle.BackgroundTransparency = 1
AutoUfoTitle.Text = "AUTO UFO"
AutoUfoTitle.TextColor3 = Color3.fromRGB(200, 200, 230)
AutoUfoTitle.Font = Enum.Font.FredokaOne
AutoUfoTitle.TextSize = 11AutoUfoTitle.TextXAlignment = Enum.TextXAlignment.Left
AutoUfoTitle.Parent = AutoUfoFrame

local AutoUfoBtn = Instance.new("TextButton")
AutoUfoBtn.Size = UDim2.new(0, 50, 0, 22)
AutoUfoBtn.Position = UDim2.new(1, -58, 0, 2)
AutoUfoBtn.BackgroundColor3 = autoUfoEnabled and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(70, 70, 70)
AutoUfoBtn.Text = autoUfoEnabled and "ON" or "OFF"
AutoUfoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoUfoBtn.Font = Enum.Font.FredokaOne
AutoUfoBtn.TextSize = 10
AutoUfoBtn.BorderSizePixel = 0
AutoUfoBtn.Parent = AutoUfoFrame
local AutoUfoBtnCorner = Instance.new("UICorner")
AutoUfoBtnCorner.CornerRadius = UDim.new(0, 5)
AutoUfoBtnCorner.Parent = AutoUfoBtn

local lastTextLabel = Instance.new("TextLabel")
lastTextLabel.Size = UDim2.new(1, -45, 0, 18)
lastTextLabel.Position = UDim2.new(0, 45, 0, 28)
lastTextLabel.BackgroundTransparency = 1
lastTextLabel.Text = "📝 Teks terakhir: --"
lastTextLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
lastTextLabel.Font = Enum.Font.Gotham
lastTextLabel.TextSize = 10
lastTextLabel.TextXAlignment = Enum.TextXAlignment.Left
lastTextLabel.Parent = AutoUfoFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -45, 0, 18)
statusLabel.Position = UDim2.new(0, 45, 0, 48)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🎯 Status: --"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = AutoUfoFrame

local actionLabel = Instance.new("TextLabel")
actionLabel.Size = UDim2.new(1, -45, 0, 18)
actionLabel.Position = UDim2.new(0, 45, 0, 68)
actionLabel.BackgroundTransparency = 1
actionLabel.Text = "⚡ Aksi: --"
actionLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
actionLabel.Font = Enum.Font.Gotham
actionLabel.TextSize = 10
actionLabel.TextXAlignment = Enum.TextXAlignment.Left
actionLabel.Parent = AutoUfoFrame

-- Toggle button function
AutoUfoBtn.MouseButton1Click:Connect(function()
    autoUfoEnabled = not autoUfoEnabled
    if autoUfoEnabled then
        AutoUfoBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        AutoUfoBtn.Text = "ON"
        print("🛸 Auto UFO: ON")
    else
        AutoUfoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        AutoUfoBtn.Text = "OFF"
        isProcessing = false
        print("🛸 Auto UFO: OFF")
    end
end)

-- Update UI status
task.spawn(function()
    while true do
        local currentText = getUIText()
        if currentText then
            lastTextLabel.Text = "📝 Teks terakhir: \"" .. currentText .. "\""
            local zoneNum, zoneName = detectZoneFromText(currentText)
            if zoneNum then
                statusLabel.Text = "🎯 Status: Zone terdeteksi! (" .. zoneName .. ")"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                if autoUfoEnabled and not isProcessing then
                    actionLabel.Text = "⚡ Aksi: Langsung teleport ke " .. zoneName
                    actionLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                end
            elseif isTimerText(currentText) then
                statusLabel.Text = "🎯 Status: Zone tidak terdeteksi (timer)"
                statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                if autoUfoEnabled and not isProcessing then
                    actionLabel.Text = "⚡ Aksi: Tunggu " .. WAIT_TIME .. " detik → Best Zone"
                    actionLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                end
            else
                statusLabel.Text = "🎯 Status: Teks tidak dikenali"
                statusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
                actionLabel.Text = "⚡ Aksi: --"
            end
        else
            lastTextLabel.Text = "📝 Teks terakhir: (UI tidak ditemukan)"
            statusLabel.Text = "🎯 Status: UI tidak ditemukan"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            actionLabel.Text = "⚡ Aksi: --"
        end
        task.wait(0.5)
    end
end)

-- ========== GUI COMPONENTS ==========
local function MakeModeToggle(Parent, Text, Emoji, GetMode, SetMode)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Parent = Parent
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = UDim.new(0, 5)
    FCorner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Emoji .. " " .. Text
    Label.TextColor3 = Color3.fromRGB(200, 200, 230)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 60, 0, 24)
    Btn.Position = UDim2.new(1, -68, 0.5, -12)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    Btn.Text = "NORMAL"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.FredokaOne
    Btn.TextSize = 10
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
    Frame.Size = UDim2.new(1, 0, 0, 28)
    Frame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    Frame.BackgroundTransparency = 0.2
    Frame.BorderSizePixel = 0
    Frame.Parent = Parent
    local FCorner = Instance.new("UICorner")
    FCorner.CornerRadius = UDim.new(0, 5)
    FCorner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = Emoji .. " " .. Text
    Label.TextColor3 = Color3.fromRGB(200, 200, 230)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 50, 0, 22)
    Btn.Position = UDim2.new(1, -58, 0.5, -11)
    Btn.BackgroundColor3 = GetState() and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(70, 70, 70)
    Btn.Text = GetState() and "ON" or "OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.FredokaOne
    Btn.TextSize = 10
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
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = Text
    Label.TextColor3 = Color3.fromRGB(0, 150, 255)
    Label.Font = Enum.Font.FredokaOne
    Label.TextSize = 11
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

-- ========== EXISTING GUI ELEMENTS ==========
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
Status.Size = UDim2.new(1, -20, 0, 16)
Status.BackgroundTransparency = 1
Status.Text = "● ANTI AFK ACTIVE"
Status.TextColor3 = Color3.fromRGB(100, 255, 100)
Status.Font = Enum.Font.FredokaOne
Status.TextSize = 10
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Scroll

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 320, 0, 35)
        Scroll.Visible = false
        SideLamp.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 320, 0, 520)
        Scroll.Visible = true
        SideLamp.Visible = true
        MinBtn.Text = "−"
    end
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | SLIME RNG + AUTO UFO")
print("═══════════════════════════════════════════")
print("✅ AUTO UFO (DETECT UI)")
print("   → Teks = Nama Zone: Langsung teleport")
print("   → Teks = Timer: Tunggu 3s → Best Zone")
print("✅ UFO TIMER - Menampilkan timer dari UI")
print("✅ AUTO BUY ZONE (MAX 40)")
print("✅ AUTO GUN | AUTO ROLL (OFF/NORMAL/FAST)")
print("✅ AUTO INDEX | AUTO FARM LOOT | AUTO FARM FRUIT")
print("✅ AUTO UPGRADE | AUTO REBIRTH")
print("✅ AUTO POTION (4 BOOSTS)")
print("🚀 SCRIPT SIAP DIGUNAKAN")
print("═══════════════════════════════════════════")