local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local AutoFarm = false
local ConvertSP = false
local AutoAscend = false
local isMinimized = false
local currentTab = "MENU"
local instanKillLoaded = false
local selectedFarmZone = "Grassland"

-- Config
local CONFIG = {
    WaitTime = 60,
    IdleTime = 2,
    ConvertDelay = 0.03,
    ConvertAmount = 30,
    AscendInterval = 60,
    TweenSpeed = 0.3,
    AttackSpeed = 0.1
}

-- ========== ZONE LIST ==========
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
local hitMobRemote = nil
local convertSPRemote = nil
local ascendRemote = nil

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
                        local hitRemote = RemotesFolder:FindFirstChild("HitMob")
                        if hitRemote then
                            hitMobRemote = hitRemote:FindFirstChild("RemoteEvent") or hitRemote:FindFirstChild("RemoteFunction")
                        end
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

if not hitMobRemote then
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if Remotes then
        hitMobRemote = Remotes:FindFirstChild("HitMob")
        convertSPRemote = Remotes:FindFirstChild("ConvertMana")
    end
end

ascendRemote = ReplicatedStorage:FindFirstChild("Remotes")
if ascendRemote then
    ascendRemote = ascendRemote:FindFirstChild("ConfirmAscend")
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
end

-- ========== FUNGSI AUTO FARM ==========
local function getMobId(mob)
    local attrs = mob:GetAttributes()
    if attrs.ID then return attrs.ID end
    if attrs.Id then return attrs.Id end
    return nil
end

local function getMobHp(mob)
    local humanoid = mob:FindFirstChild("Humanoid")
    if humanoid then return humanoid.Health end
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
    if humanoid then return humanoid.Health > 0 end
    return true
end

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

-- Loop Auto Farm (freeze di zone, kill terus)
local farmRunning = false
local function startAutoFarm()
    if farmRunning then return end
    farmRunning = true
    
    task.spawn(function()
        -- Teleport ke zone yang dipilih
        teleportToSpawn(selectedFarmZone)
        print("📍 Auto Farm di: " .. selectedFarmZone)
        
        while AutoFarm do
            if hasAliveMobs() then
                local target, targetHp = getMobWithMostHp()
                if target then
                    local mobId = getMobId(target)
                    tweenToModel(target)
                    while AutoFarm and target and target.Parent and isAlive(target) do
                        hitMob(mobId)
                        task.wait(CONFIG.AttackSpeed)
                    end
                end
            end
            task.wait(0.5)
        end
        farmRunning = false
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

-- ========== AUTO ASCEND ==========
task.spawn(function()
    while true do
        if AutoAscend and ascendRemote then
            pcall(function()
                if ascendRemote.ClassName == "RemoteFunction" then
                    ascendRemote:InvokeServer()
                else
                    ascendRemote:FireServer()
                end
            end)
        end
        task.wait(CONFIG.AscendInterval)
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
            if guiElements and guiElements.instanKillStatus then
                guiElements.instanKillStatus.Text = "✅"
            end
        end
    end
end

-- ========== ANTI AFK ==========
LocalPlayer.Idled:Connect(function()
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
Main.Size = UDim2.new(0, 300, 0, 350)
Main.Position = UDim2.new(0.5, -150, 0.2, 0)
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

-- Tab Buttons (MENU kiri, TELEPORT tengah, RAID kanan)
local TabMenu = Instance.new("TextButton")
TabMenu.Size = UDim2.new(0, 65, 0, 30)
TabMenu.Position = UDim2.new(0, 10, 0, 50)
TabMenu.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TabMenu.Text = "📋 MENU"
TabMenu.TextColor3 = Color3.fromRGB(255, 255, 255)
TabMenu.Font = Enum.Font.GothamBold
TabMenu.TextSize = 11
TabMenu.BorderSizePixel = 0
TabMenu.Parent = Main

local TabMenuCorner = Instance.new("UICorner")
TabMenuCorner.CornerRadius = UDim.new(0, 6)
TabMenuCorner.Parent = TabMenu

local TabTeleport = Instance.new("TextButton")
TabTeleport.Size = UDim2.new(0, 85, 0, 30)
TabTeleport.Position = UDim2.new(0, 83, 0, 50)
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

local TabRaid = Instance.new("TextButton")
TabRaid.Size = UDim2.new(0, 70, 0, 30)
TabRaid.Position = UDim2.new(0, 176, 0, 50)
TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
TabRaid.Text = "⚔️ RAID"
TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
TabRaid.Font = Enum.Font.GothamBold
TabRaid.TextSize = 11
TabRaid.BorderSizePixel = 0
TabRaid.Parent = Main

local TabRaidCorner = Instance.new("UICorner")
TabRaidCorner.CornerRadius = UDim.new(0, 6)
TabRaidCorner.Parent = TabRaid

-- ========== CONTENT MENU ==========
local ContentMenu = Instance.new("Frame")
ContentMenu.Size = UDim2.new(1, -20, 0, 240)
ContentMenu.Position = UDim2.new(0, 10, 0, 90)
ContentMenu.BackgroundTransparency = 1
ContentMenu.Visible = true
ContentMenu.Parent = Main

-- ========== AUTO FARM (Baris 1) ==========
local farmFrame = Instance.new("Frame")
farmFrame.Size = UDim2.new(1, 0, 0, 35)
farmFrame.BackgroundTransparency = 1
farmFrame.Parent = ContentMenu

local farmLabel = Instance.new("TextLabel")
farmLabel.Size = UDim2.new(0.25, 0, 1, 0)
farmLabel.BackgroundTransparency = 1
farmLabel.Text = "⚔️ AUTO FARM"
farmLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
farmLabel.Font = Enum.Font.FredokaOne
farmLabel.TextSize = 12
farmLabel.TextXAlignment = Enum.TextXAlignment.Left
farmLabel.Parent = farmFrame

-- Dropdown
local farmDropdown = Instance.new("TextButton")
farmDropdown.Size = UDim2.new(0, 120, 0, 28)
farmDropdown.Position = UDim2.new(0.28, 0, 0.5, -14)
farmDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
farmDropdown.Text = "🌿 Grassland"
farmDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
farmDropdown.Font = Enum.Font.Gotham
farmDropdown.TextSize = 10
farmDropdown.BorderSizePixel = 0
farmDropdown.Parent = farmFrame

local farmDropdownCorner = Instance.new("UICorner")
farmDropdownCorner.CornerRadius = UDim.new(0, 5)
farmDropdownCorner.Parent = farmDropdown

-- Toggle ON/OFF
local farmToggle = Instance.new("TextButton")
farmToggle.Size = UDim2.new(0, 50, 0, 26)
farmToggle.Position = UDim2.new(1, -55, 0.5, -13)
farmToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
farmToggle.Text = "OFF"
farmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
farmToggle.Font = Enum.Font.GothamBold
farmToggle.TextSize = 10
farmToggle.BorderSizePixel = 0
farmToggle.Parent = farmFrame

local farmToggleCorner = Instance.new("UICorner")
farmToggleCorner.CornerRadius = UDim.new(0, 5)
farmToggleCorner.Parent = farmToggle

-- Dropdown menu
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
    dropdownFrame.Size = UDim2.new(0, 120, 0, 180)
    dropdownFrame.Position = UDim2.new(0.28, 0, 0.5, 18)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    dropdownFrame.BackgroundTransparency = 0.1
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = farmFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
    dropdownCorner.Parent = dropdownFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = dropdownFrame
    
    for _, zone in pairs(allZones) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        btn.Text = zone.icon .. " " .. zone.name
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 9
        btn.BorderSizePixel = 0
        btn.Parent = dropdownFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            selectedFarmZone = zone.name
            farmDropdown.Text = zone.icon .. " " .. zone.name
            closeDropdown()
        end)
    end
end

farmDropdown.MouseButton1Click:Connect(function()
    if dropdownOpen then
        closeDropdown()
    else
        openDropdown()
    end
end)

-- Farm toggle function
farmToggle.MouseButton1Click:Connect(function()
    AutoFarm = not AutoFarm
    if AutoFarm then
        farmToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        farmToggle.Text = "ON"
        startAutoFarm()
    else
        farmToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        farmToggle.Text = "OFF"
    end
end)

-- ========== INSTAN KILL ==========
local killFrame = Instance.new("Frame")
killFrame.Size = UDim2.new(1, 0, 0, 35)
killFrame.Position = UDim2.new(0, 0, 0, 45)
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
killBtn.Size = UDim2.new(0, 55, 0, 26)
killBtn.Position = UDim2.new(1, -60, 0.5, -13)
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

-- ========== CONVERT SP ==========
local convertFrame = Instance.new("Frame")
convertFrame.Size = UDim2.new(1, 0, 0, 35)
convertFrame.Position = UDim2.new(0, 0, 0, 90)
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
convertToggle.Size = UDim2.new(0, 55, 0, 26)
convertToggle.Position = UDim2.new(1, -60, 0.5, -13)
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

-- ========== AUTO ASCEND ==========
local ascendFrame = Instance.new("Frame")
ascendFrame.Size = UDim2.new(1, 0, 0, 35)
ascendFrame.Position = UDim2.new(0, 0, 0, 135)
ascendFrame.BackgroundTransparency = 1
ascendFrame.Parent = ContentMenu

local ascendLabel = Instance.new("TextLabel")
ascendLabel.Size = UDim2.new(0.6, 0, 1, 0)
ascendLabel.BackgroundTransparency = 1
ascendLabel.Text = "⬆️ AUTO ASCEND"
ascendLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
ascendLabel.Font = Enum.Font.FredokaOne
ascendLabel.TextSize = 12
ascendLabel.TextXAlignment = Enum.TextXAlignment.Left
ascendLabel.Parent = ascendFrame

local ascendToggle = Instance.new("TextButton")
ascendToggle.Size = UDim2.new(0, 55, 0, 26)
ascendToggle.Position = UDim2.new(1, -60, 0.5, -13)
ascendToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ascendToggle.Text = "OFF"
ascendToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ascendToggle.Font = Enum.Font.GothamBold
ascendToggle.TextSize = 11
ascendToggle.BorderSizePixel = 0
ascendToggle.Parent = ascendFrame

local ascendToggleCorner = Instance.new("UICorner")
ascendToggleCorner.CornerRadius = UDim.new(0, 5)
ascendToggleCorner.Parent = ascendToggle

-- ========== CONTENT TELEPORT ==========
local ContentTeleport = Instance.new("ScrollingFrame")
ContentTeleport.Size = UDim2.new(1, -20, 0, 240)
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

for _, zone in pairs(allZones) do
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

-- ========== CONTENT RAID ==========
local ContentRaid = Instance.new("ScrollingFrame")
ContentRaid.Size = UDim2.new(1, -20, 0, 240)
ContentRaid.Position = UDim2.new(0, 10, 0, 90)
ContentRaid.BackgroundTransparency = 1
ContentRaid.ScrollBarThickness = 3
ContentRaid.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentRaid.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentRaid.Visible = false
ContentRaid.Parent = Main

local RaidLayout = Instance.new("UIListLayout")
RaidLayout.Padding = UDim.new(0, 5)
RaidLayout.SortOrder = Enum.SortOrder.LayoutOrder
RaidLayout.Parent = ContentRaid

-- Zone RAID (sama tapi tanpa teleport, hanya toggle)
local raidZoneList = {
    {name = "Grassland", icon = "🌿", enabled = false},
    {name = "Desert Biome", icon = "🏜️", enabled = false},
    {name = "Jungle Biome", icon = "🌴", enabled = false},
    {name = "Snow Biome", icon = "❄️", enabled = false},
    {name = "Volcano Island", icon = "🌋", enabled = false},
    {name = "Shadow Dungeon", icon = "👻", enabled = false},
    {name = "Shadow Realm", icon = "🌑", enabled = false},
    {name = "Forgotten Valley", icon = "🏔️", enabled = false},
    {name = "Galactic Outpost", icon = "🚀", enabled = false}
}

for _, zone in pairs(raidZoneList) do
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
    
    toggle.MouseButton1Click:Connect(function()
        zone.enabled = not zone.enabled
        if zone.enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            toggle.Text = "ON"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            toggle.Text = "OFF"
        end
    end)
end

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

ascendToggle.MouseButton1Click:Connect(function()
    AutoAscend = not AutoAscend
    if AutoAscend then
        ascendToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ascendToggle.Text = "ON"
    else
        ascendToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        ascendToggle.Text = "OFF"
    end
end)

-- ========== TAB FUNCTIONS ==========
local function switchTab(tab)
    currentTab = tab
    if tab == "MENU" then
        TabMenu.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabMenu.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMenu.Visible = true
        ContentTeleport.Visible = false
        ContentRaid.Visible = false
    elseif tab == "TELEPORT" then
        TabTeleport.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabRaid.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabRaid.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMenu.Visible = false
        ContentTeleport.Visible = true
        ContentRaid.Visible = false
    else
        TabRaid.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        TabRaid.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabTeleport.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        TabTeleport.TextColor3 = Color3.fromRGB(200, 200, 200)
        ContentMenu.Visible = false
        ContentTeleport.Visible = false
        ContentRaid.Visible = true
    end
end

TabMenu.MouseButton1Click:Connect(function() switchTab("MENU") end)
TabTeleport.MouseButton1Click:Connect(function() switchTab("TELEPORT") end)
TabRaid.MouseButton1Click:Connect(function() switchTab("RAID") end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 300, 0, 45)
        TabMenu.Visible = false
        TabTeleport.Visible = false
        TabRaid.Visible = false
        ContentMenu.Visible = false
        ContentTeleport.Visible = false
        ContentRaid.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 300, 0, 350)
        TabMenu.Visible = true
        TabTeleport.Visible = true
        TabRaid.Visible = true
        if currentTab == "MENU" then
            ContentMenu.Visible = true
        elseif currentTab == "TELEPORT" then
            ContentTeleport.Visible = true
        else
            ContentRaid.Visible = true
        end
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutoFarm = false
    ConvertSP = false
    AutoAscend = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("⚔️ AUTO FARM - Pilih map, freeze, auto kill")
print("💀 INSTAN KILL - Tombol RUN")
print("✨ CONVERT SP - Auto convert")
print("⬆️ AUTO ASCEND - Setiap 60 detik")
print("📍 TELEPORT - Ke SPAWNS")
print("⚔️ RAID - Teleport loop ke BossRaidArea")
print("═══════════════════════════════════════════")