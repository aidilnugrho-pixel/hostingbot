local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local AutoTween = false
local isMinimized = false
local currentTab = "MAIN"

-- Config
local CONFIG = {
    TweenSpeed = 0.3,
    ScanDelay = 0.5
}

-- ========== DATA ZONE ==========
local zoneList = {
    {name = "Desert Biome", icon = "🏜️"},
    {name = "Forgotten Valley", icon = "🏔️"},
    {name = "Galactic Outpost", icon = "🚀"},
    {name = "Grassland", icon = "🌿"},
    {name = "Jungle Biome", icon = "🌴"},
    {name = "Shadow Dungeon", icon = "👻"},
    {name = "Shadow Realm", icon = "🌑"},
    {name = "Snow Biome", icon = "❄️"},
    {name = "Volcano Island", icon = "🌋"}
}

-- Zone yang memiliki RAID
local raidZones = {
    "Desert Biome",
    "Forgotten Valley",
    "Jungle Biome",
    "Shadow Dungeon",
    "Snow Biome",
    "Volcano Island"
}

-- ========== FUNGSI TELEPORT ==========
local function teleportToSpawn(zoneName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then return end
    local area = areas:FindFirstChild(zoneName)
    if not area then return end
    local spawns = area:FindFirstChild("SPAWNS")
    if not spawns then return end
    
    local targetPart = nil
    for _, part in pairs(spawns:GetChildren()) do
        if part:IsA("BasePart") then
            targetPart = part
            break
        end
    end
    if not targetPart then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(targetPart.Position)
    print("✅ Teleport ke " .. zoneName)
end

local function teleportToRaid(zoneName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then return end
    local area = areas:FindFirstChild(zoneName)
    if not area then return end
    local raidArea = area:FindFirstChild("BossRaidArea")
    if not raidArea then return end
    
    local targetPart = nil
    if raidArea:IsA("BasePart") then
        targetPart = raidArea
    else
        for _, part in pairs(raidArea:GetChildren()) do
            if part:IsA("BasePart") then
                targetPart = part
                break
            end
        end
    end
    if not targetPart then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(targetPart.Position)
    print("✅ Teleport ke " .. zoneName .. " [RAID]")
end

-- ========== FUNGSI AUTO TWEEN (HANYA TWEEN) ==========
local function tweenToModel(model)
    local char = LocalPlayer.Character
    if not char then return false end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return false end
    
    local targetPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return false end
    
    -- Tween ke posisi target (nempel)
    local targetPos = targetPart.Position + Vector3.new(2, 0, 2)
    local tween = TweenService:Create(rootPart, TweenInfo.new(CONFIG.TweenSpeed, Enum.EasingStyle.Quad), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

-- Loop Auto Tween (scan 0.5 detik, tween ke model di folder Mobs)
task.spawn(function()
    local currentIndex = 1
    local mobsList = {}
    
    while true do
        if AutoTween then
            local mobsFolder = workspace:FindFirstChild("Mobs")
            
            if mobsFolder then
                -- Update daftar mobs
                mobsList = {}
                for _, mob in pairs(mobsFolder:GetChildren()) do
                    if mob:IsA("Model") then
                        table.insert(mobsList, mob)
                    end
                end
                
                if #mobsList > 0 then
                    -- Reset index jika melebihi
                    if currentIndex > #mobsList then
                        currentIndex = 1
                    end
                    
                    local target = mobsList[currentIndex]
                    if target then
                        -- Update GUI
                        if guiElements then
                            guiElements.targetLabel.Text = "🎯 " .. target.Name .. " (" .. currentIndex .. "/" .. #mobsList .. ")"
                        end
                        
                        print("📍 Tween ke: " .. target.Name)
                        tweenToModel(target)
                        
                        -- Pindah ke mob berikutnya
                        currentIndex = currentIndex + 1
                        task.wait(0.5)
                    end
                else
                    if guiElements then
                        guiElements.targetLabel.Text = "🎯 Tidak ada mob"
                    end
                end
            end
        end
        
        task.wait(CONFIG.ScanDelay)
    end
end)

-- ========== ANTI AFK ==========
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0))
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0))
end)

-- ========== GUI ZAIXPLOIT ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZAIXPLOIT"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 400)
Main.Position = UDim2.new(0.5, -150, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 6, 15)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = screenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 150, 255)
Stroke.Transparency = 0.3
Stroke.Thickness = 1.5
Stroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 0, 16)
Title.Position = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "ZAIXPLOIT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.5, 0, 0, 12)
SubTitle.Position = UDim2.new(0, 12, 0, 23)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "MELEE RNG"
SubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
SubTitle.Font = Enum.Font.FredokaOne
SubTitle.TextSize = 8
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -56, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
MinBtn.BackgroundTransparency = 0.2
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseBtn

-- Tab Buttons
local TabMain = Instance.new("TextButton")
TabMain.Size = UDim2.new(0, 70, 0, 30)
TabMain.Position = UDim2.new(0, 10, 0, 55)
TabMain.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TabMain.Text = "MAIN"
TabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
TabMain.Font = Enum.Font.GothamBold
TabMain.TextSize = 11
TabMain.BorderSizePixel = 0
TabMain.Parent = Main

local TabMainCorner = Instance.new("UICorner")
TabMainCorner.CornerRadius = UDim.new(0, 6)
TabMainCorner.Parent = TabMain

local TabTeleport = Instance.new("TextButton")
TabTeleport.Size = UDim2.new(0, 80, 0, 30)
TabTeleport.Position = UDim2.new(0, 88, 0, 55)
TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabTeleport.Text = "TELEPORT"
TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
TabTeleport.Font = Enum.Font.GothamBold
TabTeleport.TextSize = 11
TabTeleport.BorderSizePixel = 0
TabTeleport.Parent = Main

local TabTeleportCorner = Instance.new("UICorner")
TabTeleportCorner.CornerRadius = UDim.new(0, 6)
TabTeleportCorner.Parent = TabTeleport

local TabRaid = Instance.new("TextButton")
TabRaid.Size = UDim2.new(0, 70, 0, 30)
TabRaid.Position = UDim2.new(0, 176, 0, 55)
TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabRaid.Text = "RAID"
TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
TabRaid.Font = Enum.Font.GothamBold
TabRaid.TextSize = 11
TabRaid.BorderSizePixel = 0
TabRaid.Parent = Main

local TabRaidCorner = Instance.new("UICorner")
TabRaidCorner.CornerRadius = UDim.new(0, 6)
TabRaidCorner.Parent = TabRaid

-- ========== CONTENT MAIN ==========
local ContentMain = Instance.new("Frame")
ContentMain.Size = UDim2.new(1, -20, 0, 260)
ContentMain.Position = UDim2.new(0, 10, 0, 95)
ContentMain.BackgroundTransparency = 1
ContentMain.Visible = true
ContentMain.Parent = Main

-- Auto Tween Card
local TweenFrame = Instance.new("Frame")
TweenFrame.Size = UDim2.new(1, 0, 0, 100)
TweenFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
TweenFrame.BackgroundTransparency = 0.2
TweenFrame.BorderSizePixel = 0
TweenFrame.Parent = ContentMain

local TweenCorner = Instance.new("UICorner")
TweenCorner.CornerRadius = UDim.new(0, 8)
TweenCorner.Parent = TweenFrame

local TweenIcon = Instance.new("TextLabel")
TweenIcon.Size = UDim2.new(0, 45, 1, 0)
TweenIcon.BackgroundTransparency = 1
TweenIcon.Text = "🏃"
TweenIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
TweenIcon.TextSize = 28
TweenIcon.Parent = TweenFrame

local TweenLabel = Instance.new("TextLabel")
TweenLabel.Size = UDim2.new(0.5, 0, 0, 20)
TweenLabel.Position = UDim2.new(0, 55, 0, 12)
TweenLabel.BackgroundTransparency = 1
TweenLabel.Text = "Auto Tween"
TweenLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
TweenLabel.Font = Enum.Font.FredokaOne
TweenLabel.TextSize = 14
TweenLabel.TextXAlignment = Enum.TextXAlignment.Left
TweenLabel.Parent = TweenFrame

local TweenDesc = Instance.new("TextLabel")
TweenDesc.Size = UDim2.new(0.5, 0, 0, 14)
TweenDesc.Position = UDim2.new(0, 55, 0, 32)
TweenDesc.BackgroundTransparency = 1
TweenDesc.Text = "Tween ke model di folder Mobs"
TweenDesc.TextColor3 = Color3.fromRGB(150, 150, 200)
TweenDesc.Font = Enum.Font.Gotham
TweenDesc.TextSize = 9
TweenDesc.TextXAlignment = Enum.TextXAlignment.Left
TweenDesc.Parent = TweenFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.5, 0, 0, 14)
targetLabel.Position = UDim2.new(0, 55, 0, 48)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "🎯 Target: -"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 10
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = TweenFrame

local TweenBtn = Instance.new("TextButton")
TweenBtn.Size = UDim2.new(0, 65, 0, 32)
TweenBtn.Position = UDim2.new(1, -75, 0.5, -16)
TweenBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
TweenBtn.Text = "OFF"
TweenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TweenBtn.Font = Enum.Font.GothamBold
TweenBtn.TextSize = 12
TweenBtn.BorderSizePixel = 0
TweenBtn.Parent = TweenFrame

local TweenBtnCorner = Instance.new("UICorner")
TweenBtnCorner.CornerRadius = UDim.new(0, 6)
TweenBtnCorner.Parent = TweenBtn

-- Info Card
local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(1, 0, 0, 80)
InfoFrame.Position = UDim2.new(0, 0, 0, 115)
InfoFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
InfoFrame.BackgroundTransparency = 0.2
InfoFrame.BorderSizePixel = 0
InfoFrame.Parent = ContentMain

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoFrame

local InfoIcon = Instance.new("TextLabel")
InfoIcon.Size = UDim2.new(0, 45, 1, 0)
InfoIcon.BackgroundTransparency = 1
InfoIcon.Text = "🛡️"
InfoIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
InfoIcon.TextSize = 24
InfoIcon.Parent = InfoFrame

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.7, 0, 0, 18)
InfoLabel.Position = UDim2.new(0, 55, 0, 8)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "ANTI AFK ACTIVE"
InfoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextSize = 11
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = InfoFrame

local InfoDesc = Instance.new("TextLabel")
InfoDesc.Size = UDim2.new(0.7, 0, 0, 14)
InfoDesc.Position = UDim2.new(0, 55, 0, 28)
InfoDesc.BackgroundTransparency = 1
InfoDesc.Text = "Scan semua model di folder Mobs"
InfoDesc.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoDesc.Font = Enum.Font.Gotham
InfoDesc.TextSize = 9
InfoDesc.TextXAlignment = Enum.TextXAlignment.Left
InfoDesc.Parent = InfoFrame

local InfoDesc2 = Instance.new("TextLabel")
InfoDesc2.Size = UDim2.new(0.7, 0, 0, 14)
InfoDesc2.Position = UDim2.new(0, 55, 0, 42)
InfoDesc2.BackgroundTransparency = 1
InfoDesc2.Text = "Tween nempel ke setiap model"
InfoDesc2.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoDesc2.Font = Enum.Font.Gotham
InfoDesc2.TextSize = 9
InfoDesc2.TextXAlignment = Enum.TextXAlignment.Left
InfoDesc2.Parent = InfoFrame

local InfoDesc3 = Instance.new("TextLabel")
InfoDesc3.Size = UDim2.new(0.7, 0, 0, 14)
InfoDesc3.Position = UDim2.new(0, 55, 0, 56)
InfoDesc3.BackgroundTransparency = 1
InfoDesc3.Text = "Scan interval: 0.5 detik"
InfoDesc3.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoDesc3.Font = Enum.Font.Gotham
InfoDesc3.TextSize = 9
InfoDesc3.TextXAlignment = Enum.TextXAlignment.Left
InfoDesc3.Parent = InfoFrame

-- ========== CONTENT TELEPORT ==========
local ContentTeleport = Instance.new("ScrollingFrame")
ContentTeleport.Size = UDim2.new(1, -20, 0, 260)
ContentTeleport.Position = UDim2.new(0, 10, 0, 95)
ContentTeleport.BackgroundTransparency = 1
ContentTeleport.ScrollBarThickness = 3
ContentTeleport.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
ContentTeleport.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentTeleport.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentTeleport.Visible = false
ContentTeleport.Parent = Main

local TeleportLayout = Instance.new("UIListLayout")
TeleportLayout.Padding = UDim.new(0, 6)
TeleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
TeleportLayout.Parent = ContentTeleport

for _, zone in ipairs(zoneList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    btn.BackgroundTransparency = 0.2
    btn.Text = zone.icon .. " " .. zone.name
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = ContentTeleport
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local tpLabel = Instance.new("TextLabel")
    tpLabel.Size = UDim2.new(0, 45, 1, 0)
    tpLabel.Position = UDim2.new(1, -52, 0, 0)
    tpLabel.BackgroundTransparency = 1
    tpLabel.Text = "📍 TP"
    tpLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
    tpLabel.Font = Enum.Font.GothamBold
    tpLabel.TextSize = 10
    tpLabel.TextXAlignment = Enum.TextXAlignment.Right
    tpLabel.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        teleportToSpawn(zone.name)
    end)
end

-- ========== CONTENT RAID ==========
local ContentRaid = Instance.new("ScrollingFrame")
ContentRaid.Size = UDim2.new(1, -20, 0, 260)
ContentRaid.Position = UDim2.new(0, 10, 0, 95)
ContentRaid.BackgroundTransparency = 1
ContentRaid.ScrollBarThickness = 3
ContentRaid.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
ContentRaid.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentRaid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentRaid.Visible = false
ContentRaid.Parent = Main

local RaidLayout = Instance.new("UIListLayout")
RaidLayout.Padding = UDim.new(0, 6)
RaidLayout.SortOrder = Enum.SortOrder.LayoutOrder
RaidLayout.Parent = ContentRaid

for _, zone in ipairs(zoneList) do
    local isRaidZone = false
    for _, rz in pairs(raidZones) do
        if rz == zone.name then
            isRaidZone = true
            break
        end
    end
    
    if isRaidZone then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
        btn.BackgroundTransparency = 0.2
        btn.Text = zone.icon .. " " .. zone.name
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.Font = Enum.Font.FredokaOne
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.Parent = ContentRaid
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        local tpLabel = Instance.new("TextLabel")
        tpLabel.Size = UDim2.new(0, 45, 1, 0)
        tpLabel.Position = UDim2.new(1, -52, 0, 0)
        tpLabel.BackgroundTransparency = 1
        tpLabel.Text = "⚔️ TP"
        tpLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        tpLabel.Font = Enum.Font.GothamBold
        tpLabel.TextSize = 10
        tpLabel.TextXAlignment = Enum.TextXAlignment.Right
        tpLabel.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            teleportToRaid(zone.name)
        end)
    end
end

local raidInfoFrame = Instance.new("Frame")
raidInfoFrame.Size = UDim2.new(1, 0, 0, 40)
raidInfoFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
raidInfoFrame.BackgroundTransparency = 0.2
raidInfoFrame.BorderSizePixel = 0
raidInfoFrame.Parent = ContentRaid

local raidInfoCorner = Instance.new("UICorner")
raidInfoCorner.CornerRadius = UDim.new(0, 6)
raidInfoCorner.Parent = raidInfoFrame

local raidInfoLabel = Instance.new("TextLabel")
raidInfoLabel.Size = UDim2.new(1, 0, 1, 0)
raidInfoLabel.BackgroundTransparency = 1
raidInfoLabel.Text = "⚔️ Teleport ke BossRaidArea"
raidInfoLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
raidInfoLabel.Font = Enum.Font.FredokaOne
raidInfoLabel.TextSize = 10
raidInfoLabel.Parent = raidInfoFrame

-- ========== GUI ELEMENTS ==========
guiElements = {
    targetLabel = targetLabel
}

-- Update target label setiap 0.5 detik
task.spawn(function()
    while true do
        if guiElements and guiElements.targetLabel and AutoTween then
            local mobsFolder = workspace:FindFirstChild("Mobs")
            if mobsFolder then
                local firstMob = nil
                for _, mob in pairs(mobsFolder:GetChildren()) do
                    if mob:IsA("Model") then
                        firstMob = mob
                        break
                    end
                end
                if firstMob then
                    guiElements.targetLabel.Text = "🎯 Target: " .. firstMob.Name
                else
                    guiElements.targetLabel.Text = "🎯 Target: -"
                end
            else
                guiElements.targetLabel.Text = "🎯 Target: -"
            end
        elseif guiElements and guiElements.targetLabel then
            guiElements.targetLabel.Text = "🎯 Target: -"
        end
        task.wait(0.5)
    end
end)

-- ========== TAB FUNCTIONS ==========
local function switchTab(tab)
    currentTab = tab
    if tab == "MAIN" then
        TabMain.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMain.Visible = true
        ContentTeleport.Visible = false
        ContentRaid.Visible = false
    elseif tab == "TELEPORT" then
        TabTeleport.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMain.Visible = false
        ContentTeleport.Visible = true
        ContentRaid.Visible = false
    else
        TabRaid.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabRaid.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMain.Visible = false
        ContentTeleport.Visible = false
        ContentRaid.Visible = true
    end
end

TabMain.MouseButton1Click:Connect(function() switchTab("MAIN") end)
TabTeleport.MouseButton1Click:Connect(function() switchTab("TELEPORT") end)
TabRaid.MouseButton1Click:Connect(function() switchTab("RAID") end)

-- ========== TOGGLE FUNCTION ==========
TweenBtn.MouseButton1Click:Connect(function()
    AutoTween = not AutoTween
    if AutoTween then
        TweenBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        TweenBtn.Text = "ON"
    else
        TweenBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        TweenBtn.Text = "OFF"
        if guiElements then
            guiElements.targetLabel.Text = "🎯 Target: -"
        end
    end
end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 300, 0, 50)
        TabMain.Visible = false
        TabTeleport.Visible = false
        TabRaid.Visible = false
        ContentMain.Visible = false
        ContentTeleport.Visible = false
        ContentRaid.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 300, 0, 400)
        TabMain.Visible = true
        TabTeleport.Visible = true
        TabRaid.Visible = true
        if currentTab == "MAIN" then
            ContentMain.Visible = true
        elseif currentTab == "TELEPORT" then
            ContentTeleport.Visible = true
        else
            ContentRaid.Visible = true
        end
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutoTween = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("✅ Auto Tween")
print("   → Scan semua model di folder Mobs")
print("   → Tween nempel ke setiap model")
print("   → Scan interval: 0.5 detik")
print("✅ TELEPORT → SPAWNS biasa")
print("✅ RAID → BossRaidArea")
print("✅ Anti AFK Active")
print("═══════════════════════════════════════════")