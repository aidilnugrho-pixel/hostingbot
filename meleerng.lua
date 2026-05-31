local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local AutoRaid = false
local isMinimized = false
local currentTab = "RAID"
local selectedZone = "Desert Biome"
local killCount = 0
local isWaiting = false
local currentTarget = nil

-- Config
local CONFIG = {
    TweenSpeed = 0.3,
    AttackSpeed = 0.1,
    WaitTime = 16, -- 16 detik tunggu setiap kali masuk raid
    ScanDelay = 0.5
}

-- ========== DATA ZONE RAID ==========
local raidZones = {
    {name = "Desert Biome", icon = "🏜️"},
    {name = "Forgotten Valley", icon = "🏔️"},
    {name = "Jungle Biome", icon = "🌴"},
    {name = "Shadow Dungeon", icon = "👻"},
    {name = "Snow Biome", icon = "❄️"},
    {name = "Volcano Island", icon = "🌋"}
}

-- ========== REMOTE ==========
local hitMobRemote = nil

pcall(function()
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if Packages then
        local Index = Packages:FindFirstChild("_Index")
        if Index then
            local Net = Index:FindFirstChild("leifstout_networker@0.3.1")
            if Net then
                local NW = Net:FindFirstChild("networker")
                if NW then
                    local RemotesFolder = NW:FindFirstChild("_remotes")
                    if RemotesFolder then
                        local function getRemote(name)
                            local remote = RemotesFolder:FindFirstChild(name)
                            if remote then
                                return remote:FindFirstChild("RemoteFunction") or remote:FindFirstChild("RemoteEvent")
                            end
                            return nil
                        end
                        hitMobRemote = getRemote("HitMob")
                    end
                end
            end
        end
    end
end)

if not hitMobRemote then
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes then
        hitMobRemote = Remotes:FindFirstChild("HitMob")
    end
end

-- ========== FUNGSI TELEPORT KE RAID ==========
local function teleportToRaid(zoneName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then
        print("❌ Folder Areas tidak ditemukan!")
        return false
    end
    
    local area = areas:FindFirstChild(zoneName)
    if not area then
        print("❌ Zone " .. zoneName .. " tidak ditemukan!")
        return false
    end
    
    local raidArea = area:FindFirstChild("BossRaidArea")
    if not raidArea then
        print("❌ BossRaidArea tidak ditemukan di " .. zoneName)
        return false
    end
    
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
    
    if not targetPart then
        print("❌ Tidak ada target part di BossRaidArea")
        return false
    end
    
    local char = LocalPlayer.Character
    if not char then return false end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return false end
    
    rootPart.CFrame = CFrame.new(targetPart.Position)
    print("✅ Teleport ke " .. zoneName .. " [RAID]")
    return true
end

-- ========== FUNGSI AUTO MOBS (HP TERBANYAK) ==========
local function getMobId(mob)
    local attrs = mob:GetAttributes()
    if attrs.ID then return attrs.ID end
    if attrs.Id then return attrs.Id end
    return nil
end

local function getMobHp(mob)
    local humanoid = mob:FindFirstChild("Humanoid")
    if humanoid then
        return humanoid.Health
    end
    local attrs = mob:GetAttributes()
    if attrs.Health then
        return attrs.Health
    end
    return 0
end

local function tweenToModel(model)
    local char = LocalPlayer.Character
    if not char then return false end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return false end
    local targetPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return false end
    local targetPos = targetPart.Position + Vector3.new(2, 0, 2)
    local tween = TweenService:Create(rootPart, TweenInfo.new(CONFIG.TweenSpeed, Enum.EasingStyle.Quad), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

local function hitMob(mobId)
    if not mobId or not hitMobRemote then return end
    pcall(function()
        if hitMobRemote.ClassName == "RemoteEvent" then
            hitMobRemote:FireServer(mobId)
        else
            hitMobRemote:FireServer(unpack({{{mobId, 0, nil}}}))
        end
    end)
end

local function isAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChild("Humanoid")
    if humanoid then
        return humanoid.Health > 0
    end
    return true
end

-- Cek apakah masih ada mob hidup
local function hasAliveMobs()
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if not mobsFolder then return false end
    
    for _, mob in pairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobId = getMobId(mob)
            if mobId and isAlive(mob) then
                return true
            end
        end
    end
    return false
end

-- Cari mob dengan HP terbanyak
local function getMobWithMostHp()
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if not mobsFolder then return nil end
    
    local bestMob = nil
    local bestHp = 0
    
    for _, mob in pairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobId = getMobId(mob)
            if mobId and isAlive(mob) then
                local hp = getMobHp(mob)
                if hp > bestHp then
                    bestHp = hp
                    bestMob = mob
                end
            end
        end
    end
    
    return bestMob, bestHp
end

-- ========== LOOP AUTO RAID ==========
task.spawn(function()
    while true do
        if AutoRaid then
            -- Step 1: Teleport ke zone raid yang dipilih
            if guiElements then
                guiElements.statusLabel.Text = "📡 Teleporting to " .. selectedZone .. "..."
            end
            print("📍 Teleport ke raid: " .. selectedZone)
            teleportToRaid(selectedZone)
            
            -- Step 2: Tunggu 16 detik
            if guiElements then
                guiElements.statusLabel.Text = "⏳ Waiting " .. CONFIG.WaitTime .. "s before raid..."
            end
            print("⏳ Tunggu " .. CONFIG.WaitTime .. " detik sebelum raid...")
            
            for i = CONFIG.WaitTime, 1, -1 do
                if not AutoRaid then break end
                if guiElements then
                    guiElements.timerLabel.Text = "⏱️ Timer: " .. i .. "s"
                end
                task.wait(1)
            end
            
            if not AutoRaid then break end
            
            -- Step 3: Scan dan serang mob dengan HP terbanyak
            while AutoRaid and hasAliveMobs() do
                local target, targetHp = getMobWithMostHp()
                
                if target then
                    local mobId = getMobId(target)
                    local mobName = target.Name
                    
                    if guiElements then
                        guiElements.statusLabel.Text = "⚔️ Fighting: " .. mobName
                        guiElements.targetLabel.Text = "🎯 Target: " .. mobName .. " (HP: " .. targetHp .. ")"
                    end
                    
                    print("🎯 Target HP terbanyak: " .. mobName .. " (HP: " .. targetHp .. ")")
                    
                    -- Tween ke target
                    tweenToModel(target)
                    
                    -- Serang sampai mati
                    while AutoRaid and target and target.Parent and isAlive(target) do
                        hitMob(mobId)
                        killCount = killCount + 1
                        
                        if guiElements then
                            guiElements.killLabel.Text = "💀 Kill: " .. killCount
                            -- Update HP target
                            local currentHp = getMobHp(target)
                            guiElements.targetLabel.Text = "🎯 Target: " .. mobName .. " (HP: " .. currentHp .. ")"
                        end
                        
                        task.wait(CONFIG.AttackSpeed)
                    end
                    
                    if AutoRaid then
                        print("✅ " .. mobName .. " mati!")
                    end
                end
                
                task.wait(CONFIG.ScanDelay)
            end
            
            -- Step 4: Semua mob mati, loop ulang ke step 1
            if AutoRaid then
                if guiElements then
                    guiElements.statusLabel.Text = "🔄 All mobs dead, restarting raid..."
                end
                print("🔄 Semua mob mati, ulang raid...")
                task.wait(2)
            end
        end
        
        task.wait(0.5)
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
Main.Size = UDim2.new(0, 320, 0, 480)
Main.Position = UDim2.new(0.5, -160, 0.15, 0)
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
local TabRaid = Instance.new("TextButton")
TabRaid.Size = UDim2.new(0, 80, 0, 30)
TabRaid.Position = UDim2.new(0, 10, 0, 55)
TabRaid.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TabRaid.Text = "⚔️ RAID"
TabRaid.TextColor3 = Color3.fromRGB(255, 255, 255)
TabRaid.Font = Enum.Font.GothamBold
TabRaid.TextSize = 11
TabRaid.BorderSizePixel = 0
TabRaid.Parent = Main

local TabRaidCorner = Instance.new("UICorner")
TabRaidCorner.CornerRadius = UDim.new(0, 6)
TabRaidCorner.Parent = TabRaid

local TabTeleport = Instance.new("TextButton")
TabTeleport.Size = UDim2.new(0, 90, 0, 30)
TabTeleport.Position = UDim2.new(0, 98, 0, 55)
TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabTeleport.Text = "📍 TELEPORT"
TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
TabTeleport.Font = Enum.Font.GothamBold
TabTeleport.TextSize = 11
TabTeleport.BorderSizePixel = 0
TabTeleport.Parent = Main

local TabTeleportCorner = Instance.new("UICorner")
TabTeleportCorner.CornerRadius = UDim.new(0, 6)
TabTeleportCorner.Parent = TabTeleport

local TabMain = Instance.new("TextButton")
TabMain.Size = UDim2.new(0, 70, 0, 30)
TabMain.Position = UDim2.new(0, 196, 0, 55)
TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabMain.Text = "MAIN"
TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
TabMain.Font = Enum.Font.GothamBold
TabMain.TextSize = 11
TabMain.BorderSizePixel = 0
TabMain.Parent = Main

local TabMainCorner = Instance.new("UICorner")
TabMainCorner.CornerRadius = UDim.new(0, 6)
TabMainCorner.Parent = TabMain

-- ========== CONTENT RAID ==========
local ContentRaid = Instance.new("Frame")
ContentRaid.Size = UDim2.new(1, -20, 0, 340)
ContentRaid.Position = UDim2.new(0, 10, 0, 95)
ContentRaid.BackgroundTransparency = 1
ContentRaid.Visible = true
ContentRaid.Parent = Main

-- Zone Selector Card
local ZoneFrame = Instance.new("Frame")
ZoneFrame.Size = UDim2.new(1, 0, 0, 50)
ZoneFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
ZoneFrame.BackgroundTransparency = 0.2
ZoneFrame.BorderSizePixel = 0
ZoneFrame.Parent = ContentRaid

local ZoneCorner = Instance.new("UICorner")
ZoneCorner.CornerRadius = UDim.new(0, 8)
ZoneCorner.Parent = ZoneFrame

local ZoneIcon = Instance.new("TextLabel")
ZoneIcon.Size = UDim2.new(0, 45, 1, 0)
ZoneIcon.BackgroundTransparency = 1
ZoneIcon.Text = "🗺️"
ZoneIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
ZoneIcon.TextSize = 24
ZoneIcon.Parent = ZoneFrame

local ZoneLabel = Instance.new("TextLabel")
ZoneLabel.Size = UDim2.new(0.4, 0, 0, 20)
ZoneLabel.Position = UDim2.new(0, 55, 0, 15)
ZoneLabel.BackgroundTransparency = 1
ZoneLabel.Text = "Raid Zone:"
ZoneLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
ZoneLabel.Font = Enum.Font.FredokaOne
ZoneLabel.TextSize = 12
ZoneLabel.TextXAlignment = Enum.TextXAlignment.Left
ZoneLabel.Parent = ZoneFrame

local ZoneDropdown = Instance.new("TextButton")
ZoneDropdown.Size = UDim2.new(0, 140, 0, 32)
ZoneDropdown.Position = UDim2.new(0.4, 0, 0.5, -16)
ZoneDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
ZoneDropdown.Text = "🏜️ Desert Biome"
ZoneDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
ZoneDropdown.Font = Enum.Font.Gotham
ZoneDropdown.TextSize = 11
ZoneDropdown.BorderSizePixel = 0
ZoneDropdown.Parent = ZoneFrame

local ZoneDropdownCorner = Instance.new("UICorner")
ZoneDropdownCorner.CornerRadius = UDim.new(0, 6)
ZoneDropdownCorner.Parent = ZoneDropdown

-- Dropdown menu (sederhana)
local dropdownOpen = false
local dropdownFrame = nil

local function closeDropdown()
    if dropdownFrame then
        dropdownFrame:Destroy()
        dropdownFrame = nil
    end
    dropdownOpen = false
end

local function openDropdown()
    closeDropdown()
    dropdownOpen = true
    
    dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 140, 0, 180)
    dropdownFrame.Position = UDim2.new(0.4, 0, 0.5, 18)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    dropdownFrame.BackgroundTransparency = 0.1
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = ZoneFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdownFrame
    
    local dropdownStroke = Instance.new("UIStroke")
    dropdownStroke.Color = Color3.fromRGB(0, 150, 255)
    dropdownStroke.Thickness = 1
    dropdownStroke.Parent = dropdownFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = dropdownFrame
    
    for _, zone in pairs(raidZones) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        btn.Text = zone.icon .. " " .. zone.name
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.Parent = dropdownFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            selectedZone = zone.name
            ZoneDropdown.Text = zone.icon .. " " .. zone.name
            closeDropdown()
        end)
    end
    
    -- Klik diluar untuk tutup
    local function onMouseClick()
        closeDropdown()
    end
    task.wait(0.1)
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeDropdown()
        end
    end)
end

ZoneDropdown.MouseButton1Click:Connect(function()
    if dropdownOpen then
        closeDropdown()
    else
        openDropdown()
    end
end)

-- Auto Raid Card
local RaidCard = Instance.new("Frame")
RaidCard.Size = UDim2.new(1, 0, 0, 220)
RaidCard.Position = UDim2.new(0, 0, 0, 60)
RaidCard.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
RaidCard.BackgroundTransparency = 0.2
RaidCard.BorderSizePixel = 0
RaidCard.Parent = ContentRaid

local RaidCorner = Instance.new("UICorner")
RaidCorner.CornerRadius = UDim.new(0, 8)
RaidCorner.Parent = RaidCard

local RaidIcon = Instance.new("TextLabel")
RaidIcon.Size = UDim2.new(0, 50, 1, 0)
RaidIcon.BackgroundTransparency = 1
RaidIcon.Text = "⚔️"
RaidIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
RaidIcon.TextSize = 32
RaidIcon.Parent = RaidCard

local RaidLabel = Instance.new("TextLabel")
RaidLabel.Size = UDim2.new(0.5, 0, 0, 20)
RaidLabel.Position = UDim2.new(0, 60, 0, 12)
RaidLabel.BackgroundTransparency = 1
RaidLabel.Text = "AUTO RAID"
RaidLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
RaidLabel.Font = Enum.Font.FredokaOne
RaidLabel.TextSize = 14
RaidLabel.TextXAlignment = Enum.TextXAlignment.Left
RaidLabel.Parent = RaidCard

local RaidBtn = Instance.new("TextButton")
RaidBtn.Size = UDim2.new(0, 70, 0, 34)
RaidBtn.Position = UDim2.new(1, -80, 0, 10)
RaidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RaidBtn.Text = "START"
RaidBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RaidBtn.Font = Enum.Font.GothamBold
RaidBtn.TextSize = 12
RaidBtn.BorderSizePixel = 0
RaidBtn.Parent = RaidCard

local RaidBtnCorner = Instance.new("UICorner")
RaidBtnCorner.CornerRadius = UDim.new(0, 6)
RaidBtnCorner.Parent = RaidBtn

-- Status Card
local StatusCard = Instance.new("Frame")
StatusCard.Size = UDim2.new(1, 0, 0, 130)
StatusCard.Position = UDim2.new(0, 0, 0, 55)
StatusCard.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
StatusCard.BackgroundTransparency = 0.3
StatusCard.BorderSizePixel = 0
StatusCard.Parent = RaidCard

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 0, 8)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "📡 Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = StatusCard

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, -10, 0, 25)
timerLabel.Position = UDim2.new(0, 5, 0, 35)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱️ Timer: --"
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextSize = 11
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = StatusCard

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -10, 0, 25)
targetLabel.Position = UDim2.new(0, 5, 0, 62)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "🎯 Target: --"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = StatusCard

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(1, -10, 0, 25)
killLabel.Position = UDim2.new(0, 5, 0, 89)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀 Kill: 0"
killLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
killLabel.Font = Enum.Font.GothamBold
killLabel.TextSize = 12
killLabel.TextXAlignment = Enum.TextXAlignment.Left
killLabel.Parent = StatusCard

-- Anti AFK Card
local AntiAfkCard = Instance.new("Frame")
AntiAfkCard.Size = UDim2.new(1, 0, 0, 40)
AntiAfkCard.Position = UDim2.new(0, 0, 0, 290)
AntiAfkCard.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
AntiAfkCard.BackgroundTransparency = 0.2
AntiAfkCard.BorderSizePixel = 0
AntiAfkCard.Parent = ContentRaid

local AntiAfkCorner = Instance.new("UICorner")
AntiAfkCorner.CornerRadius = UDim.new(0, 8)
AntiAfkCorner.Parent = AntiAfkCard

local AntiAfkIcon = Instance.new("TextLabel")
AntiAfkIcon.Size = UDim2.new(0, 40, 1, 0)
AntiAfkIcon.BackgroundTransparency = 1
AntiAfkIcon.Text = "🛡️"
AntiAfkIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
AntiAfkIcon.TextSize = 20
AntiAfkIcon.Parent = AntiAfkCard

local AntiAfkLabel = Instance.new("TextLabel")
AntiAfkLabel.Size = UDim2.new(1, -50, 1, 0)
AntiAfkLabel.Position = UDim2.new(0, 50, 0, 0)
AntiAfkLabel.BackgroundTransparency = 1
AntiAfkLabel.Text = "ANTI AFK ACTIVE"
AntiAfkLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
AntiAfkLabel.Font = Enum.Font.GothamBold
AntiAfkLabel.TextSize = 10
AntiAfkLabel.TextXAlignment = Enum.TextXAlignment.Left
AntiAfkLabel.Parent = AntiAfkCard

-- ========== CONTENT TELEPORT ==========
local ContentTeleport = Instance.new("ScrollingFrame")
ContentTeleport.Size = UDim2.new(1, -20, 0, 340)
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

-- Semua zone (termasuk yang tidak ada raid)
local allZones = {
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

for _, zone in pairs(allZones) do
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
        -- Teleport biasa ke SPAWNS
        local areas = workspace:FindFirstChild("Areas")
        if areas then
            local area = areas:FindFirstChild(zone.name)
            if area then
                local spawns = area:FindFirstChild("SPAWNS")
                if spawns then
                    for _, part in pairs(spawns:GetChildren()) do
                        if part:IsA("BasePart") then
                            local char = LocalPlayer.Character
                            if char then
                                local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                                if rootPart then
                                    rootPart.CFrame = CFrame.new(part.Position)
                                    print("✅ Teleport ke " .. zone.name)
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- ========== CONTENT MAIN ==========
local ContentMain = Instance.new("Frame")
ContentMain.Size = UDim2.new(1, -20, 0, 340)
ContentMain.Position = UDim2.new(0, 10, 0, 95)
ContentMain.BackgroundTransparency = 1
ContentMain.Visible = false
ContentMain.Parent = Main

-- Auto Tween Card (opsional)
local TweenCard = Instance.new("Frame")
TweenCard.Size = UDim2.new(1, 0, 0, 80)
TweenCard.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
TweenCard.BackgroundTransparency = 0.2
TweenCard.BorderSizePixel = 0
TweenCard.Parent = ContentMain

local TweenCorner = Instance.new("UICorner")
TweenCorner.CornerRadius = UDim.new(0, 8)
TweenCorner.Parent = TweenCard

local TweenIcon = Instance.new("TextLabel")
TweenIcon.Size = UDim2.new(0, 45, 1, 0)
TweenIcon.BackgroundTransparency = 1
TweenIcon.Text = "🏃"
TweenIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
TweenIcon.TextSize = 28
TweenIcon.Parent = TweenCard

local TweenLabel = Instance.new("TextLabel")
TweenLabel.Size = UDim2.new(0.5, 0, 0, 20)
TweenLabel.Position = UDim2.new(0, 55, 0, 12)
TweenLabel.BackgroundTransparency = 1
TweenLabel.Text = "Auto Tween"
TweenLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
TweenLabel.Font = Enum.Font.FredokaOne
TweenLabel.TextSize = 13
TweenLabel.TextXAlignment = Enum.TextXAlignment.Left
TweenLabel.Parent = TweenCard

local TweenBtn = Instance.new("TextButton")
TweenBtn.Size = UDim2.new(0, 65, 0, 32)
TweenBtn.Position = UDim2.new(1, -75, 0.5, -16)
TweenBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
TweenBtn.Text = "OFF"
TweenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TweenBtn.Font = Enum.Font.GothamBold
TweenBtn.TextSize = 12
TweenBtn.BorderSizePixel = 0
TweenBtn.Parent = TweenCard

local TweenBtnCorner = Instance.new("UICorner")
TweenBtnCorner.CornerRadius = UDim.new(0, 6)
TweenBtnCorner.Parent = TweenBtn

-- Info
local InfoCard = Instance.new("Frame")
InfoCard.Size = UDim2.new(1, 0, 0, 80)
InfoCard.Position = UDim2.new(0, 0, 0, 95)
InfoCard.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
InfoCard.BackgroundTransparency = 0.2
InfoCard.BorderSizePixel = 0
InfoCard.Parent = ContentMain

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoCard

local InfoIcon = Instance.new("TextLabel")
InfoIcon.Size = UDim2.new(0, 45, 1, 0)
InfoIcon.BackgroundTransparency = 1
InfoIcon.Text = "ℹ️"
InfoIcon.TextColor3 = Color3.fromRGB(0, 150, 255)
InfoIcon.TextSize = 24
InfoIcon.Parent = InfoCard

local InfoLabel1 = Instance.new("TextLabel")
InfoLabel1.Size = UDim2.new(0.7, 0, 0, 16)
InfoLabel1.Position = UDim2.new(0, 55, 0, 8)
InfoLabel1.BackgroundTransparency = 1
InfoLabel1.Text = "Gunakan tab RAID untuk Auto Raid"
InfoLabel1.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoLabel1.Font = Enum.Font.Gotham
InfoLabel1.TextSize = 10
InfoLabel1.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel1.Parent = InfoCard

local InfoLabel2 = Instance.new("TextLabel")
InfoLabel2.Size = UDim2.new(0.7, 0, 0, 16)
InfoLabel2.Position = UDim2.new(0, 55, 0, 26)
InfoLabel2.BackgroundTransparency = 1
InfoLabel2.Text = "Pilih zone, START, tunggu 16 detik"
InfoLabel2.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoLabel2.Font = Enum.Font.Gotham
InfoLabel2.TextSize = 10
InfoLabel2.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel2.Parent = InfoCard

local InfoLabel3 = Instance.new("TextLabel")
InfoLabel3.Size = UDim2.new(0.7, 0, 0, 16)
InfoLabel3.Position = UDim2.new(0, 55, 0, 44)
InfoLabel3.BackgroundTransparency = 1
InfoLabel3.Text = "Scan HP terbanyak → Tween → Kill"
InfoLabel3.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoLabel3.Font = Enum.Font.Gotham
InfoLabel3.TextSize = 10
InfoLabel3.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel3.Parent = InfoCard

-- ========== GUI ELEMENTS ==========
guiElements = {
    statusLabel = statusLabel,
    timerLabel = timerLabel,
    targetLabel = targetLabel,
    killLabel = killLabel
}

-- Update kill counter display
task.spawn(function()
    while true do
        if guiElements and guiElements.killLabel then
            guiElements.killLabel.Text = "💀 Kill: " .. killCount
        end
        task.wait(0.3)
    end
end)

-- ========== TAB FUNCTIONS ==========
local function switchTab(tab)
    currentTab = tab
    if tab == "RAID" then
        TabRaid.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabRaid.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = true
        ContentTeleport.Visible = false
        ContentMain.Visible = false
    elseif tab == "TELEPORT" then
        TabTeleport.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = false
        ContentTeleport.Visible = true
        ContentMain.Visible = false
    else
        TabMain.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = false
        ContentTeleport.Visible = false
        ContentMain.Visible = true
    end
end

TabRaid.MouseButton1Click:Connect(function() switchTab("RAID") end)
TabTeleport.MouseButton1Click:Connect(function() switchTab("TELEPORT") end)
TabMain.MouseButton1Click:Connect(function() switchTab("MAIN") end)

-- ========== AUTO RAID TOGGLE ==========
RaidBtn.MouseButton1Click:Connect(function()
    AutoRaid = not AutoRaid
    if AutoRaid then
        RaidBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        RaidBtn.Text = "ON"
        killCount = 0
        if guiElements then
            guiElements.killLabel.Text = "💀 Kill: 0"
            guiElements.statusLabel.Text = "📡 Starting raid..."
        end
        print("🟢 Auto RAID: ON | Zone: " .. selectedZone)
    else
        RaidBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        RaidBtn.Text = "START"
        if guiElements then
            guiElements.statusLabel.Text = "📡 Status: Stopped"
            guiElements.timerLabel.Text = "⏱️ Timer: --"
            guiElements.targetLabel.Text = "🎯 Target: --"
        end
        print("🔴 Auto RAID: OFF")
    end
end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 320, 0, 50)
        TabRaid.Visible = false
        TabTeleport.Visible = false
        TabMain.Visible = false
        ContentRaid.Visible = false
        ContentTeleport.Visible = false
        ContentMain.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 320, 0, 480)
        TabRaid.Visible = true
        TabTeleport.Visible = true
        TabMain.Visible = true
        if currentTab == "RAID" then
            ContentRaid.Visible = true
        elseif currentTab == "TELEPORT" then
            ContentTeleport.Visible = true
        else
            ContentMain.Visible = true
        end
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutoRaid = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("⚔️ AUTO RAID")
print("   → Pilih zone raid (Desert, Forgotten, Jungle, dll)")
print("   → Teleport ke BossRaidArea")
print("   → Tunggu 16 detik")
print("   → Scan Mobs, cari HP terbanyak")
print("   → Tween + Kill sampai mati")
print("   → Jika semua mob mati, ulang dari awal")
print("📍 TELEPORT → SPAWNS biasa")
print("✅ Anti AFK Active")
print("═══════════════════════════════════════════")