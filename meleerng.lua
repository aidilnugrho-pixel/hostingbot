local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local ConvertSP = false
local isMinimized = false

-- Config
local CONFIG = {
    TweenSpeed = 0.3,
    AttackSpeed = 0.1,
    WaitTime = 20,
    ConvertDelay = 0.03,
    ConvertAmount = 30
}

-- ========== ZONE RAID ==========
local raidZones = {
    {name = "Desert Biome", icon = "🏜️", enabled = false, running = false},
    {name = "Forgotten Valley", icon = "🏔️", enabled = false, running = false},
    {name = "Jungle Biome", icon = "🌴", enabled = false, running = false},
    {name = "Shadow Dungeon", icon = "👻", enabled = false, running = false},
    {name = "Snow Biome", icon = "❄️", enabled = false, running = false},
    {name = "Volcano Island", icon = "🌋", enabled = false, running = false}
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

-- ========== FUNGSI RAID ==========
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

-- ========== LOOP RAID UNTUK SATU ZONE ==========
local function startRaidForZone(zone)
    if zone.running then return end
    zone.running = true
    
    task.spawn(function()
        while zone.enabled do
            -- Teleport ke zone
            teleportToRaid(zone.name)
            
            -- Tunggu 20 detik
            for i = CONFIG.WaitTime, 1, -1 do
                if not zone.enabled then break end
                task.wait(1)
            end
            if not zone.enabled then break end
            
            -- Scan dan serang HP terbanyak
            while zone.enabled and hasAliveMobs() do
                local target, targetHp = getMobWithMostHp()
                if target then
                    local mobId = getMobId(target)
                    tweenToModel(target)
                    while zone.enabled and target and target.Parent and isAlive(target) do
                        hitMob(mobId)
                        task.wait(CONFIG.AttackSpeed)
                    end
                end
                task.wait(0.5)
            end
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
Main.Size = UDim2.new(0, 260, 0, 260)
Main.Position = UDim2.new(0.5, -130, 0.2, 0)
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
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.5, 0, 0, 14)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "ZAIXPLOIT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0.5, 0, 0, 10)
SubTitle.Position = UDim2.new(0, 10, 0, 20)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "MELEE RNG"
SubTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
SubTitle.Font = Enum.Font.FredokaOne
SubTitle.TextSize = 7
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Position = UDim2.new(1, -48, 0, 7)
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
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 7)
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

-- Content
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -45)
Content.Position = UDim2.new(0, 8, 0, 40)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

-- ========== MEMBUAT TOGGLE ZONE ==========
local zoneToggles = {}
local zoneStatusLabels = {}

for _, zone in ipairs(raidZones) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    frame.Parent = Content
    
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
    toggle.Size = UDim2.new(0, 50, 0, 22)
    toggle.Position = UDim2.new(1, -55, 0.5, -11)
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
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 30, 0, 14)
    statusLabel.Position = UDim2.new(1, -88, 0.5, -7)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 8
    statusLabel.Parent = frame
    
    zoneToggles[zone.name] = toggle
    zoneStatusLabels[zone.name] = statusLabel
    
    toggle.MouseButton1Click:Connect(function()
        zone.enabled = not zone.enabled
        if zone.enabled then
            toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            toggle.Text = "ON"
            statusLabel.Text = "▶"
            startRaidForZone(zone)
        else
            toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            toggle.Text = "OFF"
            statusLabel.Text = ""
        end
    end)
end

-- Spacer
local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 10)
spacer.BackgroundTransparency = 1
spacer.Parent = Content

-- ========== INSTAN KILL ==========
local killFrame = Instance.new("Frame")
killFrame.Size = UDim2.new(1, 0, 0, 28)
killFrame.BackgroundTransparency = 1
killFrame.Parent = Content

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0.6, 0, 1, 0)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀 INSTAN KILL"
killLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
killLabel.Font = Enum.Font.FredokaOne
killLabel.TextSize = 11
killLabel.TextXAlignment = Enum.TextXAlignment.Left
killLabel.Parent = killFrame

local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(0, 50, 0, 22)
killBtn.Position = UDim2.new(1, -55, 0.5, -11)
killBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
killBtn.Text = "RUN"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 10
killBtn.BorderSizePixel = 0
killBtn.Parent = killFrame

local killBtnCorner = Instance.new("UICorner")
killBtnCorner.CornerRadius = UDim.new(0, 4)
killBtnCorner.Parent = killBtn

local killStatus = Instance.new("TextLabel")
killStatus.Size = UDim2.new(0, 30, 0, 14)
killStatus.Position = UDim2.new(1, -88, 0.5, -7)
killStatus.BackgroundTransparency = 1
killStatus.Text = ""
killStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
killStatus.Font = Enum.Font.Gotham
killStatus.TextSize = 8
killStatus.Parent = killFrame

-- ========== CONVERT SP ==========
local convertFrame = Instance.new("Frame")
convertFrame.Size = UDim2.new(1, 0, 0, 28)
convertFrame.BackgroundTransparency = 1
convertFrame.Parent = Content

local convertLabel = Instance.new("TextLabel")
convertLabel.Size = UDim2.new(0.6, 0, 1, 0)
convertLabel.BackgroundTransparency = 1
convertLabel.Text = "✨ CONVERT SP"
convertLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
convertLabel.Font = Enum.Font.FredokaOne
convertLabel.TextSize = 11
convertLabel.TextXAlignment = Enum.TextXAlignment.Left
convertLabel.Parent = convertFrame

local convertToggle = Instance.new("TextButton")
convertToggle.Size = UDim2.new(0, 50, 0, 22)
convertToggle.Position = UDim2.new(1, -55, 0.5, -11)
convertToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
convertToggle.Text = "OFF"
convertToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
convertToggle.Font = Enum.Font.GothamBold
convertToggle.TextSize = 10
convertToggle.BorderSizePixel = 0
convertToggle.Parent = convertFrame

local convertToggleCorner = Instance.new("UICorner")
convertToggleCorner.CornerRadius = UDim.new(0, 4)
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

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 260, 0, 40)
        Content.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 260, 0, 260)
        Content.Visible = true
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
print("✅ AUTO RAID (Toggle per zone)")
print("   → Teleport ke BossRaidArea")
print("   → Tunggu 20 detik")
print("   → Scan HP terbanyak → Kill")
print("   → Loop terus ke zone yang sama")
print("✅ INSTAN KILL (Tombol RUN)")
print("✅ CONVERT SP (Toggle ON/OFF)")
print("═══════════════════════════════════════════")