local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local ConvertSP = false
local isMinimized = false
local currentTab = "RAID"
local instanKillLoaded = false

-- Config
local CONFIG = {
    WaitTime = 60,
    IdleTime = 2,
    ConvertDelay = 0.03,
    ConvertAmount = 1
}

-- ========== ZONE RAID (Urutan baru) ==========
local raidZones = {
    {name = "Grassland", icon = "🌿", enabled = false, running = false},
    {name = "Desert Biome", icon = "🏜️", enabled = false, running = false},
    {name = "Jungle Biome", icon = "🌴", enabled = false, running = false},
    {name = "Snow Biome", icon = "❄️", enabled = false, running = false},
    {name = "Volcano Island", icon = "🌋", enabled = false, running = false},
    {name = "Shadow Dungeon", icon = "👻", enabled = false, running = false},
    {name = "Shadow Realm", icon = "🌑", enabled = false, running = false},
    {name = "Forgotten Valley", icon = "🏔️", enabled = false, running = false},
    {name = "Galactic Outpost", icon = "🚀", enabled = false, running = false}
}

-- ========== SEMUA ZONE UNTUK TELEPORT ==========
local allZones = {
    {name = "Grassland", icon = "🌿"},
    {name = "Desert Biome", icon = "🏜️"},
    {name = "Jungle Biome", icon = "🌴"},
    {name = "Snow Biome", icon = "❄️"},
    {name = "Volcano Island", icon = "🌋"},
    {name = "Shadow Dungeon", icon = "👻"},
    {name = "Shadow Realm", icon = "🌑"},
    {name = "Forgotten Valley", icon = "🏔️"},
    {name = "Galactic Outpost", icon = "🚀"}
}

-- ========== REMOTE ==========
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
                        local convertRemote = RemotesFolder:FindFirstChild("ConvertMana")
                        if convertRemote then
                            convertSPRemote = convertRemote:FindFirstChild("RemoteFunction") or convertRemote:FindFirstChild("RemoteEvent")
                        end
                    end
                end
            end
        end
    end
end)

if not convertSPRemote then
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes then
        convertSPRemote = Remotes:FindFirstChild("ConvertMana")
    end
end

-- ========== FUNGSI TELEPORT KE SPAWN ==========
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

-- ========== FUNGSI TELEPORT KE RAID ==========
local function teleportToRaid(zoneName)
    local areas = workspace:FindFirstChild("Areas")
    if not areas then return false end
    local area = areas:FindFirstChild(zoneName)
    if not area then return false end
    local raidArea = area:FindFirstChild("BossRaidArea")
    if not raidArea then return false end
    
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
    if not targetPart then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not rootPart then return false end
    
    rootPart.CFrame = CFrame.new(targetPart.Position)
    return true
end

-- ========== LOOP RAID (60s + idle 2s, tanpa kill) ==========
local function startRaidForZone(zone)
    if zone.running then return end
    zone.running = true
    
    task.spawn(function()
        while zone.enabled do
            -- Teleport ke raid zone
            teleportToRaid(zone.name)
            print("📍 Teleport ke " .. zone.name .. " [RAID]")
            
            -- Tunggu 60 detik
            for i = CONFIG.WaitTime, 1, -1 do
                if not zone.enabled then break end
                task.wait(1)
            end
            if not zone.enabled then break end
            
            -- Jeda 2 detik
            task.wait(CONFIG.IdleTime)
        end
        zone.running = false
    end)
end

-- ========== AUTO CONVERT SP ==========
task.spawn(function()
    while true do
        if ConvertSP and convertSPRemote then
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

-- ========== INSTAN KILL ==========
local function runInstanKill()
    local url = "https://raw.githubusercontent.com/lolwtfpro/booyah/refs/heads/main/untitledmeleerngkill.lua"
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and result then
        local func, err = loadstring(result)
        if func then
            pcall(func)
            print("💀 Instan Kill: RUNNING")
            if guiElements and guiElements.instanKillStatus then
                guiElements.instanKillStatus.Text = "✅"
            end
        end
    end
end

-- ========== ANTI AFK ==========
LocalPlayer.Idled:Connect(function()
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:Button2Down(Vector2.new(0, 0))
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0))
end)

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZAIXPLOIT"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 420)
Main.Position = UDim2.new(0.5, -140, 0.15, 0)
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
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 0, 14)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "ZAIXPLOIT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.5, 0, 0, 10)
SubTitle.Position = UDim2.new(0, 10, 0, 22)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "MELEE RNG"
SubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
SubTitle.Font = Enum.Font.FredokaOne
SubTitle.TextSize = 7
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -52, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
MinBtn.BackgroundTransparency = 0.2
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Tab Buttons
local TabRaid = Instance.new("TextButton")
TabRaid.Size = UDim2.new(0, 70, 0, 30)
TabRaid.Position = UDim2.new(0, 10, 0, 50)
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
TabTeleport.Size = UDim2.new(0, 85, 0, 30)
TabTeleport.Position = UDim2.new(0, 88, 0, 50)
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

local TabMenu = Instance.new("TextButton")
TabMenu.Size = UDim2.new(0, 65, 0, 30)
TabMenu.Position = UDim2.new(0, 181, 0, 50)
TabMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabMenu.Text = "📋 MENU"
TabMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
TabMenu.Font = Enum.Font.GothamBold
TabMenu.TextSize = 11
TabMenu.BorderSizePixel = 0
TabMenu.Parent = Main

local TabMenuCorner = Instance.new("UICorner")
TabMenuCorner.CornerRadius = UDim.new(0, 6)
TabMenuCorner.Parent = TabMenu

-- ========== CONTENT RAID ==========
local ContentRaid = Instance.new("ScrollingFrame")
ContentRaid.Size = UDim2.new(1, -20, 0, 310)
ContentRaid.Position = UDim2.new(0, 10, 0, 90)
ContentRaid.BackgroundTransparency = 1
ContentRaid.ScrollBarThickness = 3
ContentRaid.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentRaid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentRaid.Visible = true
ContentRaid.Parent = Main

local RaidLayout = Instance.new("UIListLayout")
RaidLayout.Padding = UDim.new(0, 5)
RaidLayout.SortOrder = Enum.SortOrder.LayoutOrder
RaidLayout.Parent = ContentRaid

-- Timer info
local timerInfo = Instance.new("TextLabel")
timerInfo.Size = UDim2.new(1, 0, 0, 25)
timerInfo.BackgroundTransparency = 1
timerInfo.Text = "⏱️ Timer: 60s | Idle: 2s"
timerInfo.TextColor3 = Color3.fromRGB(100, 200, 255)
timerInfo.Font = Enum.Font.Gotham
timerInfo.TextSize = 10
timerInfo.Parent = ContentRaid

-- Zone toggles
local zoneToggles = {}

for _, zone in ipairs(raidZones) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = ContentRaid
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = zone.icon .. " " .. zone.name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(1, -55, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 10
    toggle.BorderSizePixel = 0
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggle
    
    zoneToggles[zone.name] = toggle
    
    toggle.MouseButton1Click:Connect(function()
        zone.enabled = not zone.enabled
        if zone.enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            toggle.Text = "ON"
            startRaidForZone(zone)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            toggle.Text = "OFF"
        end
    end)
end

-- ========== CONTENT TELEPORT ==========
local ContentTeleport = Instance.new("ScrollingFrame")
ContentTeleport.Size = UDim2.new(1, -20, 0, 310)
ContentTeleport.Position = UDim2.new(0, 10, 0, 90)
ContentTeleport.BackgroundTransparency = 1
ContentTeleport.ScrollBarThickness = 3
ContentTeleport.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentTeleport.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentTeleport.Visible = false
ContentTeleport.Parent = Main

local TeleportLayout = Instance.new("UIListLayout")
TeleportLayout.Padding = UDim.new(0, 5)
TeleportLayout.SortOrder = Enum.SortOrder.LayoutOrder
TeleportLayout.Parent = ContentTeleport

for _, zone in ipairs(allZones) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = ContentTeleport
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = zone.icon .. " " .. zone.name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 55, 0, 24)
    tpBtn.Position = UDim2.new(1, -60, 0.5, -12)
    tpBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    tpBtn.Text = "📍 TP"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = frame
    
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 4)
    tpCorner.Parent = tpBtn
    
    tpBtn.MouseButton1Click:Connect(function()
        teleportToSpawn(zone.name)
    end)
end

-- ========== CONTENT MENU ==========
local ContentMenu = Instance.new("Frame")
ContentMenu.Size = UDim2.new(1, -20, 0, 310)
ContentMenu.Position = UDim2.new(0, 10, 0, 90)
ContentMenu.BackgroundTransparency = 1
ContentMenu.Visible = false
ContentMenu.Parent = Main

-- Instan Kill
local killFrame = Instance.new("Frame")
killFrame.Size = UDim2.new(1, 0, 0, 40)
killFrame.BackgroundTransparency = 1
killFrame.Parent = ContentMenu

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0.6, 0, 1, 0)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀 INSTAN KILL"
killLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
killLabel.Font = Enum.Font.FredokaOne
killLabel.TextSize = 12
killLabel.TextXAlignment = Enum.TextXAlignment.Left
killLabel.Parent = killFrame

local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(0, 55, 0, 28)
killBtn.Position = UDim2.new(1, -60, 0.5, -14)
killBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
killBtn.Text = "RUN"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 11
killBtn.BorderSizePixel = 0
killBtn.Parent = killFrame

local killBtnCorner = Instance.new("UICorner")
killBtnCorner.CornerRadius = UDim.new(0, 5)
killBtnCorner.Parent = killBtn

local killStatus = Instance.new("TextLabel")
killStatus.Size = UDim2.new(0, 30, 0, 14)
killStatus.Position = UDim2.new(1, -95, 0.5, -7)
killStatus.BackgroundTransparency = 1
killStatus.Text = ""
killStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
killStatus.Font = Enum.Font.Gotham
killStatus.TextSize = 8
killStatus.Parent = killFrame

-- Convert SP
local convertFrame = Instance.new("Frame")
convertFrame.Size = UDim2.new(1, 0, 0, 40)
convertFrame.Position = UDim2.new(0, 0, 0, 50)
convertFrame.BackgroundTransparency = 1
convertFrame.Parent = ContentMenu

local convertLabel = Instance.new("TextLabel")
convertLabel.Size = UDim2.new(0.6, 0, 1, 0)
convertLabel.BackgroundTransparency = 1
convertLabel.Text = "✨ CONVERT SP"
convertLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
convertLabel.Font = Enum.Font.FredokaOne
convertLabel.TextSize = 12
convertLabel.TextXAlignment = Enum.TextXAlignment.Left
convertLabel.Parent = convertFrame

local convertToggle = Instance.new("TextButton")
convertToggle.Size = UDim2.new(0, 55, 0, 28)
convertToggle.Position = UDim2.new(1, -60, 0.5, -14)
convertToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
convertToggle.Text = "OFF"
convertToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
convertToggle.Font = Enum.Font.GothamBold
convertToggle.TextSize = 11
convertToggle.BorderSizePixel = 0
convertToggle.Parent = convertFrame

local convertToggleCorner = Instance.new("UICorner")
convertToggleCorner.CornerRadius = UDim.new(0, 5)
convertToggleCorner.Parent = convertToggle

-- ========== GUI ELEMENTS ==========
guiElements = {
    instanKillStatus = killStatus
}

-- ========== FUNGSI ==========
killBtn.MouseButton1Click:Connect(function()
    if not instanKillLoaded then
        instanKillLoaded = true
        killStatus.Text = "⏳"
        task.spawn(function()
            runInstanKill()
            killStatus.Text = "✅"
            task.wait(2)
            killStatus.Text = ""
        end)
    end
end)

convertToggle.MouseButton1Click:Connect(function()
    ConvertSP = not ConvertSP
    if ConvertSP then
        convertToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        convertToggle.Text = "ON"
    else
        convertToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        convertToggle.Text = "OFF"
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
        TabMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = true
        ContentTeleport.Visible = false
        ContentMenu.Visible = false
    elseif tab == "TELEPORT" then
        TabTeleport.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = false
        ContentTeleport.Visible = true
        ContentMenu.Visible = false
    else
        TabMenu.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabMenu.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentRaid.Visible = false
        ContentTeleport.Visible = false
        ContentMenu.Visible = true
    end
end

TabRaid.MouseButton1Click:Connect(function() switchTab("RAID") end)
TabTeleport.MouseButton1Click:Connect(function() switchTab("TELEPORT") end)
TabMenu.MouseButton1Click:Connect(function() switchTab("MENU") end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 280, 0, 45)
        TabRaid.Visible = false
        TabTeleport.Visible = false
        TabMenu.Visible = false
        ContentRaid.Visible = false
        ContentTeleport.Visible = false
        ContentMenu.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 280, 0, 420)
        TabRaid.Visible = true
        TabTeleport.Visible = true
        TabMenu.Visible = true
        if currentTab == "RAID" then
            ContentRaid.Visible = true
        elseif currentTab == "TELEPORT" then
            ContentTeleport.Visible = true
        else
            ContentMenu.Visible = true
        end
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    for _, zone in pairs(raidZones) do
        zone.enabled = false
    end
    ConvertSP = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("⚔️ RAID - 9 Zone")
print("   Urutan: Grassland → Desert → Jungle → Snow → Volcano → Shadow Dungeon → Shadow Realm → Forgotten Valley → Galactic")
print("📍 TELEPORT - Ke SPAWNS")
print("📋 MENU - Instan Kill & Convert SP")
print("═══════════════════════════════════════════")