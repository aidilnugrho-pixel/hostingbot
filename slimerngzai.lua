local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

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

-- ========== AUTO UFO (DEFAULT ON) ==========
local AutoUfo = true          -- DEFAULT ON
local UFO_INTERVAL = 10       -- Teleport ke UFO setiap 10 detik
local alreadyInZone40 = false -- Flag untuk teleport Zone 40 hanya sekali

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

local function TeleportZone(ZoneNum)
    if not ZonesSvc then return end
    pcall(function() ZonesSvc:InvokeServer("requestTeleportZone", ZoneNum) end)
end

local function GetBestOpenZone()
    local Best = 0
    local Zones = workspace:FindFirstChild("Zones")
    if Zones then
        for _, Zone in ipairs(Zones:GetChildren()) do
            local Num = tonumber(Zone.Name) or 0
            if Num > 0 then
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

local function BuyZoneAndTeleport()
    if not ZonesSvc then return end
    
    local ZoneBefore = GetBestOpenZone()
    local TargetZone = ZoneBefore + 1
    
    local Success = pcall(function()
        ZonesSvc:InvokeServer("requestPurchaseZone")
    end)
    
    if Success then
        task.wait(1)
        
        local targetZoneFolder = workspace:FindFirstChild("Zones") and 
                                 workspace.Zones:FindFirstChild(tostring(TargetZone))
        
        if targetZoneFolder then
            local gate = targetZoneFolder:FindFirstChild("Gate")
            if gate and gate:FindFirstChild("DepthFade") then
                TeleportZone(TargetZone)
            else
                local BestZone = GetBestOpenZone()
                if BestZone > 0 then
                    TeleportZone(BestZone)
                end
            end
        else
            local BestZone = GetBestOpenZone()
            if BestZone > 0 then
                TeleportZone(BestZone)
            end
        end
    end
end

local function UseBoost(Type)
    if not BoostSvc then return end
    pcall(function() BoostSvc:InvokeServer("requestUseBoost", Type) end)
end

-- ========== AUTO UFO TELEPORT FUNCTIONS ==========
local function TeleportToUfo()
    if not AutoUfo then return false end
    
    local ufoRoot = workspace:FindFirstChild("UfoEvent") 
        and workspace.UfoEvent:FindFirstChild("UFO") 
        and workspace.UfoEvent.UFO:FindFirstChild("Root")
    
    if not ufoRoot or not ufoRoot:IsA("BasePart") then
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = char.HumanoidRootPart
    local ufoPos = ufoRoot.Position
    hrp.CFrame = CFrame.new(ufoPos.X, hrp.Position.Y, ufoPos.Z)
    
    print("🛸 Teleport ke UFO!")
    return true
end

local function TeleportToZone40()
    if not AutoUfo then return false end
    
    local targetPart = workspace:FindFirstChild("Zones") 
        and workspace.Zones:FindFirstChild("40") 
        and workspace.Zones["40"]:FindFirstChild("POI") 
        and workspace.Zones["40"].POI:FindFirstChild("PlayerSpawn")
    
    if not targetPart or not targetPart:IsA("BasePart") then
        print("❌ Zone 40 Spawn tidak ditemukan")
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = char.HumanoidRootPart
    local targetPos = targetPart.Position
    hrp.CFrame = CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
    
    print("📍 Teleport ke Zone 40 Spawn (SEKALI SAJA)")
    return true
end

-- ========== LOOP AUTO UFO ==========
task.spawn(function()
    while true do
        task.wait(UFO_INTERVAL)
        
        if not AutoUfo then 
            -- Reset flag kalau auto ufo dimatikan
            alreadyInZone40 = false
            print("🛸 Auto UFO: OFF")
            continue 
        end
        
        local ufoAda = TeleportToUfo()
        
        if ufoAda then
            -- UFO ada, reset flag zone40
            alreadyInZone40 = false
        else
            -- UFO tidak ada
            if not alreadyInZone40 then
                TeleportToZone40()
                alreadyInZone40 = true
                print("⏸️ UFO tidak ada, sudah di Zone 40. Menunggu UFO spawn...")
            end
        end
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
Main.Size = UDim2.new(0, 240, 0, 420)
Main.Position = UDim2.new(0.5, -120, 0.5, -210)
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
Corner.CornerRadius = UDim.new(0, 6)
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

-- ========== AUTO UFO TOGGLE (BESAR, WARNA BIRU, PALING ATAS) ==========
local UfoFrame = Instance.new("Frame")
UfoFrame.Size = UDim2.new(1, 0, 0, 38)
UfoFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
UfoFrame.BackgroundTransparency = 0.2
UfoFrame.BorderSizePixel = 0
UfoFrame.Parent = Scroll
local UfoCorner = Instance.new("UICorner")
UfoCorner.CornerRadius = UDim.new(0, 6)
UfoCorner.Parent = UfoFrame

local UfoLabel = Instance.new("TextLabel")
UfoLabel.Size = UDim2.new(1, -65, 1, 0)
UfoLabel.Position = UDim2.new(0, 10, 0, 0)
UfoLabel.BackgroundTransparency = 1
UfoLabel.Text = "🛸 Auto UFO (10s)"
UfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UfoLabel.Font = Enum.Font.FredokaOne
UfoLabel.TextSize = 12
UfoLabel.TextXAlignment = Enum.TextXAlignment.Left
UfoLabel.Parent = UfoFrame

local UfoBtn = Instance.new("TextButton")
UfoBtn.Size = UDim2.new(0, 60, 0, 28)
UfoBtn.Position = UDim2.new(1, -70, 0.5, -14)
UfoBtn.BackgroundColor3 = AutoUfo and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(70, 70, 70)
UfoBtn.Text = AutoUfo and "ON" or "OFF"
UfoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UfoBtn.Font = Enum.Font.FredokaOne
UfoBtn.TextSize = 12
UfoBtn.BorderSizePixel = 0
UfoBtn.Parent = UfoFrame
local UfoBtnCorner = Instance.new("UICorner")
UfoBtnCorner.CornerRadius = UDim.new(0, 6)
UfoBtnCorner.Parent = UfoBtn

UfoBtn.MouseButton1Click:Connect(function()
    AutoUfo = not AutoUfo
    if AutoUfo then
        UfoBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        UfoBtn.Text = "ON"
        alreadyInZone40 = false  -- Reset flag saat ON
        print("🛸 Auto UFO: ON")
    else
        UfoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        UfoBtn.Text = "OFF"
        print("🛸 Auto UFO: OFF")
    end
end)

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
        Main.Size = UDim2.new(0, 240, 0, 35)
        Scroll.Visible = false
        SideLamp.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 240, 0, 420)
        Scroll.Visible = true
        SideLamp.Visible = true
        MinBtn.Text = "−"
    end
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | SLIME RNG + AUTO UFO")
print("═══════════════════════════════════════════")
print("✅ AUTO UFO (ON by default) - Teleport 10s")
print("   → Ada UFO: Teleport ke UFO")
print("   → Tidak ada: Teleport ke Zone 40 (SEKALI)")
print("✅ AUTO GUN | AUTO ROLL (OFF/NORMAL/FAST)")
print("✅ AUTO INDEX | AUTO FARM LOOT | AUTO FARM FRUIT")
print("✅ AUTO UPGRADE | AUTO REBIRTH")
print("✅ AUTO BUY ZONE + TELEPORT")
print("✅ AUTO POTION (4 BOOSTS)")
print("🚀 SCRIPT SIAP DIGUNAKAN")
print("═══════════════════════════════════════════")