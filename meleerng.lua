local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

-- ========== FITUR ==========
local AutoRaid = false
local ConvertSP = false
local isMinimized = false
local selectedZone = "Desert Biome"
local killCount = 0
local instanKillLoaded = false

-- Config
local CONFIG = {
    TweenSpeed = 0.3,
    AttackSpeed = 0.1,
    WaitTime = 20,
    ConvertDelay = 0.03,
    ConvertAmount = 30
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

-- ========== FUNGSI AUTO RAID ==========
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

-- Loop Auto RAID
task.spawn(function()
    while true do
        if AutoRaid then
            -- Teleport
            teleportToRaid(selectedZone)
            
            -- Tunggu 20 detik
            for i = CONFIG.WaitTime, 1, -1 do
                if not AutoRaid then break end
                if guiElements and guiElements.timerLabel then
                    guiElements.timerLabel.Text = "⏱️ " .. i .. "s"
                end
                task.wait(1)
            end
            if not AutoRaid then break end
            
            -- Serang HP terbanyak
            while AutoRaid and hasAliveMobs() do
                local target, targetHp = getMobWithMostHp()
                if target then
                    local mobId = getMobId(target)
                    local mobName = target.Name
                    
                    if guiElements then
                        guiElements.targetLabel.Text = "🎯 " .. mobName .. " (" .. targetHp .. ")"
                    end
                    
                    tweenToModel(target)
                    
                    while AutoRaid and target and target.Parent and isAlive(target) do
                        hitMob(mobId)
                        killCount = killCount + 1
                        if guiElements then
                            guiElements.killLabel.Text = "💀 " .. killCount
                        end
                        task.wait(CONFIG.AttackSpeed)
                    end
                end
                task.wait(0.5)
            end
            
            if AutoRaid then
                task.wait(2)
            end
        end
        task.wait(0.5)
    end
end)

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

-- ========== INSTAN KILL (SEKALI JALAN) ==========
local function loadInstanKill()
    if instanKillLoaded then return end
    instanKillLoaded = true
    
    local url = "https://raw.githubusercontent.com/lolwtfpro/booyah/refs/heads/main/untitledmeleerngkill.lua"
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success and result then
        local func, err = loadstring(result)
        if func then
            pcall(func)
            if guiElements and guiElements.instanKillStatus then
                guiElements.instanKillStatus.Text = "✅ ACTIVE"
            end
            print("💀 Instan Kill: LOADED")
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
Main.Size = UDim2.new(0, 260, 0, 200)
Main.Position = UDim2.new(0.5, -130, 0.3, 0)
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
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -45)
Content.Position = UDim2.new(0, 8, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- ========== AUTO RAID TOGGLE ==========
local RaidFrame = Instance.new("Frame")
RaidFrame.Size = UDim2.new(1, 0, 0, 30)
RaidFrame.BackgroundTransparency = 1
RaidFrame.Parent = Content

local RaidLabel = Instance.new("TextLabel")
RaidLabel.Size = UDim2.new(0.6, 0, 1, 0)
RaidLabel.BackgroundTransparency = 1
RaidLabel.Text = "⚔️ AUTO RAID"
RaidLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
RaidLabel.Font = Enum.Font.FredokaOne
RaidLabel.TextSize = 12
RaidLabel.TextXAlignment = Enum.TextXAlignment.Left
RaidLabel.Parent = RaidFrame

local RaidToggle = Instance.new("TextButton")
RaidToggle.Size = UDim2.new(0, 50, 0, 24)
RaidToggle.Position = UDim2.new(1, -55, 0.5, -12)
RaidToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RaidToggle.Text = "OFF"
RaidToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
RaidToggle.Font = Enum.Font.GothamBold
RaidToggle.TextSize = 11
RaidToggle.BorderSizePixel = 0
RaidToggle.Parent = RaidFrame

local RaidToggleCorner = Instance.new("UICorner")
RaidToggleCorner.CornerRadius = UDim.new(0, 5)
RaidToggleCorner.Parent = RaidToggle

-- ========== DROPDOWN ZONE ==========
local ZoneFrame = Instance.new("Frame")
ZoneFrame.Size = UDim2.new(1, 0, 0, 30)
ZoneFrame.Position = UDim2.new(0, 0, 0, 35)
ZoneFrame.BackgroundTransparency = 1
ZoneFrame.Parent = Content

local ZoneLabel = Instance.new("TextLabel")
ZoneLabel.Size = UDim2.new(0.3, 0, 1, 0)
ZoneLabel.BackgroundTransparency = 1
ZoneLabel.Text = "📍"
ZoneLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
ZoneLabel.Font = Enum.Font.FredokaOne
ZoneLabel.TextSize = 12
ZoneLabel.TextXAlignment = Enum.TextXAlignment.Left
ZoneLabel.Parent = ZoneFrame

local ZoneDropdown = Instance.new("TextButton")
ZoneDropdown.Size = UDim2.new(0, 160, 0, 26)
ZoneDropdown.Position = UDim2.new(0.3, 0, 0.5, -13)
ZoneDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
ZoneDropdown.Text = "🏜️ Desert Biome"
ZoneDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
ZoneDropdown.Font = Enum.Font.Gotham
ZoneDropdown.TextSize = 10
ZoneDropdown.BorderSizePixel = 0
ZoneDropdown.Parent = ZoneFrame

local ZoneDropdownCorner = Instance.new("UICorner")
ZoneDropdownCorner.CornerRadius = UDim.new(0, 5)
ZoneDropdownCorner.Parent = ZoneDropdown

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
    dropdownFrame.Size = UDim2.new(0, 160, 0, 150)
    dropdownFrame.Position = UDim2.new(0.3, 0, 0.5, 16)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    dropdownFrame.BackgroundTransparency = 0.1
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = ZoneFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 5)
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
            selectedZone = zone.name
            ZoneDropdown.Text = zone.icon .. " " .. zone.name
            closeDropdown()
        end)
    end
end

ZoneDropdown.MouseButton1Click:Connect(function()
    if dropdownOpen then
        closeDropdown()
    else
        openDropdown()
    end
end)

-- ========== INSTAN KILL (SEKALI JALAN) ==========
local KillFrame = Instance.new("Frame")
KillFrame.Size = UDim2.new(1, 0, 0, 30)
KillFrame.Position = UDim2.new(0, 0, 0, 70)
KillFrame.BackgroundTransparency = 1
KillFrame.Parent = Content

local KillLabel = Instance.new("TextLabel")
KillLabel.Size = UDim2.new(0.6, 0, 1, 0)
KillLabel.BackgroundTransparency = 1
KillLabel.Text = "💀 INSTAN KILL"
KillLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
KillLabel.Font = Enum.Font.FredokaOne
KillLabel.TextSize = 12
KillLabel.TextXAlignment = Enum.TextXAlignment.Left
KillLabel.Parent = KillFrame

local KillBtn = Instance.new("TextButton")
KillBtn.Size = UDim2.new(0, 50, 0, 24)
KillBtn.Position = UDim2.new(1, -55, 0.5, -12)
KillBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
KillBtn.Text = "RUN"
KillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillBtn.Font = Enum.Font.GothamBold
KillBtn.TextSize = 11
KillBtn.BorderSizePixel = 0
KillBtn.Parent = KillFrame

local KillBtnCorner = Instance.new("UICorner")
KillBtnCorner.CornerRadius = UDim.new(0, 5)
KillBtnCorner.Parent = KillBtn

-- Status Instan Kill (small)
local KillStatus = Instance.new("TextLabel")
KillStatus.Size = UDim2.new(0, 40, 0, 14)
KillStatus.Position = UDim2.new(1, -100, 0.5, -7)
KillStatus.BackgroundTransparency = 1
KillStatus.Text = ""
KillStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
KillStatus.Font = Enum.Font.Gotham
KillStatus.TextSize = 8
KillStatus.Parent = KillFrame

-- ========== CONVERT SP TOGGLE ==========
local ConvertFrame = Instance.new("Frame")
ConvertFrame.Size = UDim2.new(1, 0, 0, 30)
ConvertFrame.Position = UDim2.new(0, 0, 0, 105)
ConvertFrame.BackgroundTransparency = 1
ConvertFrame.Parent = Content

local ConvertLabel = Instance.new("TextLabel")
ConvertLabel.Size = UDim2.new(0.6, 0, 1, 0)
ConvertLabel.BackgroundTransparency = 1
ConvertLabel.Text = "✨ CONVERT SP"
ConvertLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
ConvertLabel.Font = Enum.Font.FredokaOne
ConvertLabel.TextSize = 12
ConvertLabel.TextXAlignment = Enum.TextXAlignment.Left
ConvertLabel.Parent = ConvertFrame

local ConvertToggle = Instance.new("TextButton")
ConvertToggle.Size = UDim2.new(0, 50, 0, 24)
ConvertToggle.Position = UDim2.new(1, -55, 0.5, -12)
ConvertToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ConvertToggle.Text = "OFF"
ConvertToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ConvertToggle.Font = Enum.Font.GothamBold
ConvertToggle.TextSize = 11
ConvertToggle.BorderSizePixel = 0
ConvertToggle.Parent = ConvertFrame

local ConvertToggleCorner = Instance.new("UICorner")
ConvertToggleCorner.CornerRadius = UDim.new(0, 5)
ConvertToggleCorner.Parent = ConvertToggle

-- ========== STATUS BAR (kecil) ==========
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, 0, 0, 24)
StatusFrame.Position = UDim2.new(0, 0, 0, 140)
StatusFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
StatusFrame.BackgroundTransparency = 0.3
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = Content

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 5)
StatusCorner.Parent = StatusFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.33, 0, 1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱️ --"
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextSize = 9
timerLabel.Parent = StatusFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0.4, 0, 1, 0)
targetLabel.Position = UDim2.new(0.33, 0, 0, 0)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "🎯 --"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 9
targetLabel.Parent = StatusFrame

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0.27, 0, 1, 0)
killLabel.Position = UDim2.new(0.73, 0, 0, 0)
killLabel.BackgroundTransparency = 1
killLabel.Text = "💀 0"
killLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
killLabel.Font = Enum.Font.Gotham
killLabel.TextSize = 9
killLabel.Parent = StatusFrame

-- ========== GUI ELEMENTS ==========
guiElements = {
    timerLabel = timerLabel,
    targetLabel = targetLabel,
    killLabel = killLabel,
    instanKillStatus = KillStatus
}

-- Update kill counter
task.spawn(function()
    while true do
        if guiElements and guiElements.killLabel then
            guiElements.killLabel.Text = "💀 " .. killCount
        end
        task.wait(0.3)
    end
end)

-- ========== TOGGLE FUNCTIONS ==========
RaidToggle.MouseButton1Click:Connect(function()
    AutoRaid = not AutoRaid
    if AutoRaid then
        RaidToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        RaidToggle.Text = "ON"
        killCount = 0
        killLabel.Text = "💀 0"
    else
        RaidToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        RaidToggle.Text = "OFF"
        timerLabel.Text = "⏱️ --"
        targetLabel.Text = "🎯 --"
    end
end)

KillBtn.MouseButton1Click:Connect(function()
    if not instanKillLoaded then
        KillBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        KillBtn.Text = "RUN"
        KillStatus.Text = "LOADING..."
        task.spawn(function()
            loadInstanKill()
            KillStatus.Text = "✅"
            task.wait(2)
            KillStatus.Text = ""
        end)
    end
end)

ConvertToggle.MouseButton1Click:Connect(function()
    ConvertSP = not ConvertSP
    if ConvertSP then
        ConvertToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ConvertToggle.Text = "ON"
    else
        ConvertToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        ConvertToggle.Text = "OFF"
    end
end)

-- Minimize
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Main.Size = UDim2.new(0, 260, 0, 40)
        Content.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 260, 0, 200)
        Content.Visible = true
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutoRaid = false
    ConvertSP = false
    screenGui:Destroy()
end)

print("═══════════════════════════════════════════")
print("   ZAIXPLOIT | MELEE RNG")
print("═══════════════════════════════════════════")
print("⚔️ AUTO RAID (Pilih zone, loop 20s)")
print("💀 INSTAN KILL (Tekan RUN, sekali jalan)")
print("✨ CONVERT SP (Toggle ON/OFF)")
print("═══════════════════════════════════════════")