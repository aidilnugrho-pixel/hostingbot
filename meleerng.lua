local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local AutoMobs = false
local AutoConvertSP = false
local isMinimized = false
local currentTab = "MAIN"

-- Config
local CONFIG = {
    TweenSpeed = 0.3,
    AttackSpeed = 0.1,
    ConvertAmount = 30,
    ConvertDelay = 0.03
}

-- ========== DATA ZONE ==========
local zoneList = {
    {name = "Desert Biome", icon = "🏜️", hasRaid = true},
    {name = "Forgotten Valley", icon = "🏔️", hasRaid = true},
    {name = "Galactic Outpost", icon = "🚀", hasRaid = false},
    {name = "Grassland", icon = "🌿", hasRaid = false},
    {name = "Jungle Biome", icon = "🌴", hasRaid = true},
    {name = "Shadow Dungeon", icon = "👻", hasRaid = true},
    {name = "Shadow Realm", icon = "🌑", hasRaid = false},
    {name = "Snow Biome", icon = "❄️", hasRaid = true},
    {name = "Volcano Island", icon = "🌋", hasRaid = true}
}

-- ========== REMOTE ==========
local hitMobRemote = nil
local convertSPRemote = nil

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
                        convertSPRemote = getRemote("ConvertMana")
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
        convertSPRemote = Remotes:FindFirstChild("ConvertMana")
    end
end

-- ========== FUNGSI TELEPORT KE ZONE (RAID ATAU SPAWN) ==========
local function teleportToZone(zoneName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then
        print("❌ Folder Areas tidak ditemukan!")
        return
    end
    
    local area = areas:FindFirstChild(zoneName)
    if not area then
        print("❌ Zone " .. zoneName .. " tidak ditemukan!")
        return
    end
    
    -- Cari data zone
    local zoneData = nil
    for _, z in pairs(zoneList) do
        if z.name == zoneName then
            zoneData = z
            break
        end
    end
    
    local targetPart = nil
    local teleportType = ""
    
    -- Jika ada raid, teleport ke BossRaidArea
    if zoneData and zoneData.hasRaid then
        local raidArea = area:FindFirstChild("BossRaidArea")
        if raidArea and raidArea:IsA("BasePart") then
            targetPart = raidArea
            teleportType = "Raid"
        elseif raidArea then
            -- Cari part di dalam BossRaidArea
            for _, part in pairs(raidArea:GetChildren()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    teleportType = "Raid"
                    break
                end
            end
        end
    end
    
    -- Jika tidak ada raid atau raid tidak ditemukan, teleport ke SPAWNS
    if not targetPart then
        local spawns = area:FindFirstChild("SPAWNS")
        if spawns then
            for _, part in pairs(spawns:GetChildren()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    teleportType = "Spawn"
                    break
                end
            end
        end
    end
    
    if not targetPart then
        print("❌ Tidak ada target teleport di " .. zoneName)
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return end
    
    rootPart.CFrame = CFrame.new(targetPart.Position)
    print("✅ Teleport ke " .. zoneName .. " [" .. teleportType .. "]")
end

-- ========== FUNGSI AUTO MOBS ==========
local function getMobId(mob)
    local attrs = mob:GetAttributes()
    if attrs.ID then return attrs.ID end
    if attrs.Id then return attrs.Id end
    return nil
end

local function tweenToModel(model)
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return end
    local targetPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return end
    local targetPos = targetPart.Position + Vector3.new(2, 0, 2)
    local tween = TweenService:Create(rootPart, TweenInfo.new(CONFIG.TweenSpeed, Enum.EasingStyle.Quad), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
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
    local humanoid = model and model:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Loop Auto Mobs
task.spawn(function()
    while true do
        if AutoMobs then
            local mobsFolder = workspace:FindFirstChild("Mobs")
            if mobsFolder then
                for _, mob in pairs(mobsFolder:GetChildren()) do
                    if not AutoMobs then break end
                    if mob:IsA("Model") then
                        local mobId = getMobId(mob)
                        if mobId and isAlive(mob) then
                            tweenToModel(mob)
                            while AutoMobs and isAlive(mob) do
                                hitMob(mobId)
                                task.wait(CONFIG.AttackSpeed)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ========== AUTO CONVERT SP ==========
task.spawn(function()
    while true do
        if AutoConvertSP and convertSPRemote then
            pcall(function()
                if convertSPRemote.ClassName == "RemoteFunction" then
                    convertSPRemote:InvokeServer(CONFIG.ConvertAmount)
                else
                    convertSPRemote:FireServer(CONFIG.ConvertAmount)
                end
            end)
        end
        task.wait(CONFIG.ConvertDelay)
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
Main.Size = UDim2.new(0, 300, 0, 420)
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
TabMain.Size = UDim2.new(0, 90, 0, 30)
TabMain.Position = UDim2.new(0, 12, 0, 55)
TabMain.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TabMain.Text = "MAIN"
TabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
TabMain.Font = Enum.Font.GothamBold
TabMain.TextSize = 12
TabMain.BorderSizePixel = 0
TabMain.Parent = Main

local TabMainCorner = Instance.new("UICorner")
TabMainCorner.CornerRadius = UDim.new(0, 6)
TabMainCorner.Parent = TabMain

local TabTeleport = Instance.new("TextButton")
TabTeleport.Size = UDim2.new(0, 90, 0, 30)
TabTeleport.Position = UDim2.new(0, 110, 0, 55)
TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabTeleport.Text = "TELEPORT"
TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
TabTeleport.Font = Enum.Font.GothamBold
TabTeleport.TextSize = 12
TabTeleport.BorderSizePixel = 0
TabTeleport.Parent = Main

local TabTeleportCorner = Instance.new("UICorner")
TabTeleportCorner.CornerRadius = UDim.new(0, 6)
TabTeleportCorner.Parent = TabTeleport

-- ========== CONTENT MAIN ==========
local ContentMain = Instance.new("Frame")
ContentMain.Size = UDim2.new(1, -20, 0, 280)
ContentMain.Position = UDim2.new(0, 10, 0, 95)
ContentMain.BackgroundTransparency = 1
ContentMain.Visible = true
ContentMain.Parent = Main

-- Auto Mobs
local MobsFrame = Instance.new("Frame")
MobsFrame.Size = UDim2.new(1, 0, 0, 50)
MobsFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
MobsFrame.BackgroundTransparency = 0.2
MobsFrame.BorderSizePixel = 0
MobsFrame.Parent = ContentMain

local MobsCorner = Instance.new("UICorner")
MobsCorner.CornerRadius = UDim.new(0, 8)
MobsCorner.Parent = MobsFrame

local MobsIcon = Instance.new("TextLabel")
MobsIcon.Size = UDim2.new(0, 40, 1, 0)
MobsIcon.BackgroundTransparency = 1
MobsIcon.Text = "👾"
MobsIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
MobsIcon.TextSize = 26
MobsIcon.Parent = MobsFrame

local MobsLabel = Instance.new("TextLabel")
MobsLabel.Size = UDim2.new(0.5, 0, 0, 20)
MobsLabel.Position = UDim2.new(0, 50, 0, 15)
MobsLabel.BackgroundTransparency = 1
MobsLabel.Text = "Auto Mobs"
MobsLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
MobsLabel.Font = Enum.Font.FredokaOne
MobsLabel.TextSize = 13
MobsLabel.TextXAlignment = Enum.TextXAlignment.Left
MobsLabel.Parent = MobsFrame

local MobsBtn = Instance.new("TextButton")
MobsBtn.Size = UDim2.new(0, 65, 0, 32)
MobsBtn.Position = UDim2.new(1, -75, 0.5, -16)
MobsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MobsBtn.Text = "OFF"
MobsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MobsBtn.Font = Enum.Font.GothamBold
MobsBtn.TextSize = 12
MobsBtn.BorderSizePixel = 0
MobsBtn.Parent = MobsFrame

local MobsBtnCorner = Instance.new("UICorner")
MobsBtnCorner.CornerRadius = UDim.new(0, 6)
MobsBtnCorner.Parent = MobsBtn

-- Auto Convert SP
local ConvertFrame = Instance.new("Frame")
ConvertFrame.Size = UDim2.new(1, 0, 0, 50)
ConvertFrame.Position = UDim2.new(0, 0, 0, 60)
ConvertFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
ConvertFrame.BackgroundTransparency = 0.2
ConvertFrame.BorderSizePixel = 0
ConvertFrame.Parent = ContentMain

local ConvertCorner = Instance.new("UICorner")
ConvertCorner.CornerRadius = UDim.new(0, 8)
ConvertCorner.Parent = ConvertFrame

local ConvertIcon = Instance.new("TextLabel")
ConvertIcon.Size = UDim2.new(0, 40, 1, 0)
ConvertIcon.BackgroundTransparency = 1
ConvertIcon.Text = "✨"
ConvertIcon.TextColor3 = Color3.fromRGB(100, 255, 200)
ConvertIcon.TextSize = 26
ConvertIcon.Parent = ConvertFrame

local ConvertLabel = Instance.new("TextLabel")
ConvertLabel.Size = UDim2.new(0.5, 0, 0, 20)
ConvertLabel.Position = UDim2.new(0, 50, 0, 15)
ConvertLabel.BackgroundTransparency = 1
ConvertLabel.Text = "Auto Convert SP"
ConvertLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
ConvertLabel.Font = Enum.Font.FredokaOne
ConvertLabel.TextSize = 13
ConvertLabel.TextXAlignment = Enum.TextXAlignment.Left
ConvertLabel.Parent = ConvertFrame

local ConvertBtn = Instance.new("TextButton")
ConvertBtn.Size = UDim2.new(0, 65, 0, 32)
ConvertBtn.Position = UDim2.new(1, -75, 0.5, -16)
ConvertBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ConvertBtn.Text = "OFF"
ConvertBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ConvertBtn.Font = Enum.Font.GothamBold
ConvertBtn.TextSize = 12
ConvertBtn.BorderSizePixel = 0
ConvertBtn.Parent = ConvertFrame

local ConvertBtnCorner = Instance.new("UICorner")
ConvertBtnCorner.CornerRadius = UDim.new(0, 6)
ConvertBtnCorner.Parent = ConvertBtn

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, -25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● ANTI AFK ACTIVE"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatusLabel.Font = Enum.Font.FredokaOne
StatusLabel.TextSize = 9
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = ContentMain

-- ========== CONTENT TELEPORT ==========
local ContentTeleport = Instance.new("ScrollingFrame")
ContentTeleport.Size = UDim2.new(1, -20, 0, 280)
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

-- Buat tombol teleport untuk setiap zone
local zoneButtons = {}
for _, zone in ipairs(zoneList) do
    local raidIcon = zone.hasRaid and "⚔️" or "📍"
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
    btn.BackgroundTransparency = 0.2
    btn.Text = zone.icon .. " " .. zone.name .. " " .. raidIcon
    btn.TextColor3 = Color3.fromRGB(220, 220, 240)
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = ContentTeleport
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    -- TP Label di kanan
    local tpLabel = Instance.new("TextLabel")
    tpLabel.Size = UDim2.new(0, 40, 1, 0)
    tpLabel.Position = UDim2.new(1, -48, 0, 0)
    tpLabel.BackgroundTransparency = 1
    tpLabel.Text = "▶ TP"
    tpLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
    tpLabel.Font = Enum.Font.GothamBold
    tpLabel.TextSize = 10
    tpLabel.TextXAlignment = Enum.TextXAlignment.Right
    tpLabel.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        teleportToZone(zone.name)
    end)
    
    table.insert(zoneButtons, btn)
end

-- Info Raid
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0, 35)
infoFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
infoFrame.BackgroundTransparency = 0.2
infoFrame.BorderSizePixel = 0
infoFrame.Parent = ContentTeleport

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = infoFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 1, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "⚔️ = Ada Raid  |  📍 = Spawn Biasa"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
infoLabel.Font = Enum.Font.FredokaOne
infoLabel.TextSize = 9
infoLabel.Parent = infoFrame

-- ========== TAB FUNCTIONS ==========
local function switchTab(tab)
    currentTab = tab
    if tab == "MAIN" then
        TabMain.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMain.Visible = true
        ContentTeleport.Visible = false
    else
        TabTeleport.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabMain.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMain.Visible = false
        ContentTeleport.Visible = true
    end
end

TabMain.MouseButton1Click:Connect(function() switchTab("MAIN") end)
TabTeleport.MouseButton1Click:Connect(function() switchTab("TELEPORT") end)

-- ========== TOGGLE FUNCTIONS ==========
MobsBtn.MouseButton1Click:Connect(function()
    AutoMobs = not AutoMobs
    if AutoMobs then
        MobsBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        MobsBtn.Text = "ON"
    else
        MobsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        MobsBtn.Text = "OFF"
    end
end)

ConvertBtn.MouseButton1Click:Connect(function()
    AutoConvertSP = not AutoConvertSP
    if AutoConvertSP then
        ConvertBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ConvertBtn.Text = "ON"
    else
        ConvertBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        ConvertBtn.Text = "OFF"
    end
end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 300, 0, 50)
        TabMain.Visible = false
        TabTeleport.Visible = false
        ContentMain.Visible = false
        ContentTeleport.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 300, 0, 420)
        TabMain.Visible = true
        TabTeleport.Visible = true
        if currentTab == "MAIN" then
            ContentMain.Visible = true
        else
            ContentTeleport.Visible = true
        end
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutoMobs = false
    AutoConvertSP = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("✅ Auto Mobs (Tween + Kill)")
print("✅ Auto Convert SP (Loop 0.03 detik)")
print("✅ Teleport System:")
for _, zone in pairs(zoneList) do
    print("   → " .. zone.name .. (zone.hasRaid and " [RAID]" or " [SPAWN]"))
end
print("✅ Anti AFK Active")
print("═══════════════════════════════════════════")