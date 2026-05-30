-- ========== AUTO UFO (NAMA ZONE + BEST ZONE ONLY AT 59.30) ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ========== KONFIGURASI ==========
local autoUfoEnabled = true
local isMinimized = false
local lastUIText = nil
local isProcessing = false

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

-- ========== BACA UI ==========
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

-- ========== DETECT ZONE ==========
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

-- ========== CEK APAKAH TIMER = 59.30 ==========
local function isTargetTimer(text)
    if not text then return false end
    -- Cek apakah teks adalah "59.30" atau "59:30"
    return text == "59.30" or text == "59:30"
end

-- ========== TELEPORT KE ZONE ==========
local function TeleportToZone(zoneNum, zoneName)
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
    print("✅ Teleport ke " .. zoneName)
    return true
end

-- ========== PROSES TEKS ==========
local function processText(currentText)
    if isProcessing then return end
    if currentText == lastUIText then return end  -- HANYA 1x SAAT BERUBAH
    
    local zoneNum, zoneName = detectZoneFromText(currentText)
    
    if zoneNum then
        -- NAMA ZONE
        isProcessing = true
        print("🎯 " .. currentText .. " → Teleport ke " .. zoneName)
        TeleportToZone(zoneNum, zoneName)
        lastUIText = currentText
        isProcessing = false
    elseif isTargetTimer(currentText) then
        -- TIMER 59.30 → BEST ZONE
        local colin = GetBestOpenZone()
        local targetZone = colin + 1
        if targetZone <= 40 then
            isProcessing = true
            print("📍 " .. currentText .. " → Timer 59.30! Teleport ke Best Zone " .. targetZone)
            TeleportToZone(targetZone, "Best Zone " .. targetZone)
            lastUIText = currentText
            isProcessing = false
        else
            print("🏆 Sudah di zone maksimal 40!")
            lastUIText = currentText
        end
    else
        -- TIMER LAINNYA DIABAIKAN
        print("⏳ " .. currentText .. " → Timer biasa, diabaikan")
        lastUIText = currentText
    end
end

-- ========== LOOP ==========
task.spawn(function()
    while true do
        if autoUfoEnabled then
            local currentText = getUIText()
            if currentText then
                processText(currentText)
            end
        end
        task.wait(0.5)
    end
end)

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoUfoZone"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 200)
mainFrame.Position = UDim2.new(0.5, -140, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 200, 80)
stroke.Transparency = 0.3
stroke.Thickness = 1
stroke.Parent = mainFrame

-- Side Lamp
local sideLamp = Instance.new("Frame")
sideLamp.Size = UDim2.new(0, 3, 1, -8)
sideLamp.Position = UDim2.new(0, -5, 0, 4)
sideLamp.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
sideLamp.BorderSizePixel = 0
sideLamp.Parent = mainFrame
local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 3)
sideCorner.Parent = sideLamp

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
titleBar.BackgroundTransparency = 0.5
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local indicatorLight = Instance.new("Frame")
indicatorLight.Size = UDim2.new(0, 8, 0, 8)
indicatorLight.Position = UDim2.new(0, 10, 0, 13)
indicatorLight.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
indicatorLight.BorderSizePixel = 0
indicatorLight.Parent = titleBar
local lightCorner = Instance.new("UICorner")
lightCorner.CornerRadius = UDim.new(1, 0)
lightCorner.Parent = indicatorLight

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 0, 18)
titleText.Position = UDim2.new(0, 28, 0, 3)
titleText.BackgroundTransparency = 1
titleText.Text = "AUTO UFO"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.FredokaOne
titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(1, -70, 0, 12)
subTitleText.Position = UDim2.new(0, 28, 0, 20)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "ZONE + BEST ZONE (59.30)"
subTitleText.TextColor3 = Color3.fromRGB(150, 150, 200)
subTitleText.Font = Enum.Font.FredokaOne
subTitleText.TextSize = 8
subTitleText.TextXAlignment = Enum.TextXAlignment.Left
subTitleText.Parent = titleBar

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -28, 0, 6)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
minBtn.BackgroundTransparency = 0.3
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minBtn

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 55, 0, 24)
toggleBtn.Position = UDim2.new(1, -90, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
toggleBtn.BackgroundTransparency = 0
toggleBtn.Text = "ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 11
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = titleBar
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 5)
toggleCorner.Parent = toggleBtn

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Teks Terakhir Card
local lastTextCard = Instance.new("Frame")
lastTextCard.Size = UDim2.new(1, -20, 0, 45)
lastTextCard.Position = UDim2.new(0, 10, 0, 10)
lastTextCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
lastTextCard.BackgroundTransparency = 0.2
lastTextCard.BorderSizePixel = 0
lastTextCard.Parent = contentFrame
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 6)
cardCorner.Parent = lastTextCard

local lastTextIcon = Instance.new("TextLabel")
lastTextIcon.Size = UDim2.new(0, 30, 1, 0)
lastTextIcon.Position = UDim2.new(0, 5, 0, 0)
lastTextIcon.BackgroundTransparency = 1
lastTextIcon.Text = "📝"
lastTextIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
lastTextIcon.TextSize = 16
lastTextIcon.Parent = lastTextCard

local lastTextTitle = Instance.new("TextLabel")
lastTextTitle.Size = UDim2.new(1, -40, 0, 16)
lastTextTitle.Position = UDim2.new(0, 40, 0, 4)
lastTextTitle.BackgroundTransparency = 1
lastTextTitle.Text = "TEKS TERAKHIR"
lastTextTitle.TextColor3 = Color3.fromRGB(150, 150, 200)
lastTextTitle.Font = Enum.Font.FredokaOne
lastTextTitle.TextSize = 8
lastTextTitle.TextXAlignment = Enum.TextXAlignment.Left
lastTextTitle.Parent = lastTextCard

local lastTextValue = Instance.new("TextLabel")
lastTextValue.Size = UDim2.new(1, -40, 0, 20)
lastTextValue.Position = UDim2.new(0, 40, 0, 22)
lastTextValue.BackgroundTransparency = 1
lastTextValue.Text = "--"
lastTextValue.TextColor3 = Color3.fromRGB(200, 200, 220)
lastTextValue.Font = Enum.Font.FredokaOne
lastTextValue.TextSize = 11
lastTextValue.TextXAlignment = Enum.TextXAlignment.Left
lastTextValue.Parent = lastTextCard

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, -20, 0, 45)
statusCard.Position = UDim2.new(0, 10, 0, 62)
statusCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
statusCard.BackgroundTransparency = 0.2
statusCard.BorderSizePixel = 0
statusCard.Parent = contentFrame
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusCard

local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0, 30, 1, 0)
statusIcon.Position = UDim2.new(0, 5, 0, 0)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "🗺️"
statusIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
statusIcon.TextSize = 16
statusIcon.Parent = statusCard

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -40, 0, 16)
statusTitle.Position = UDim2.new(0, 40, 0, 4)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "STATUS"
statusTitle.TextColor3 = Color3.fromRGB(150, 150, 200)
statusTitle.Font = Enum.Font.FredokaOne
statusTitle.TextSize = 8
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

local statusValue = Instance.new("TextLabel")
statusValue.Size = UDim2.new(1, -40, 0, 20)
statusValue.Position = UDim2.new(0, 40, 0, 22)
statusValue.BackgroundTransparency = 1
statusValue.Text = "Menunggu..."
statusValue.TextColor3 = Color3.fromRGB(200, 200, 200)
statusValue.Font = Enum.Font.FredokaOne
statusValue.TextSize = 11
statusValue.TextXAlignment = Enum.TextXAlignment.Left
statusValue.Parent = statusCard

-- Aksi Card
local actionCard = Instance.new("Frame")
actionCard.Size = UDim2.new(1, -20, 0, 45)
actionCard.Position = UDim2.new(0, 10, 0, 114)
actionCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
actionCard.BackgroundTransparency = 0.2
actionCard.BorderSizePixel = 0
actionCard.Parent = contentFrame
local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 6)
actionCorner.Parent = actionCard

local actionIcon = Instance.new("TextLabel")
actionIcon.Size = UDim2.new(0, 30, 1, 0)
actionIcon.Position = UDim2.new(0, 5, 0, 0)
actionIcon.BackgroundTransparency = 1
actionIcon.Text = "⚡"
actionIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
actionIcon.TextSize = 16
actionIcon.Parent = actionCard

local actionTitle = Instance.new("TextLabel")
actionTitle.Size = UDim2.new(1, -40, 0, 16)
actionTitle.Position = UDim2.new(0, 40, 0, 4)
actionTitle.BackgroundTransparency = 1
actionTitle.Text = "AKSI"
actionTitle.TextColor3 = Color3.fromRGB(150, 150, 200)
actionTitle.Font = Enum.Font.FredokaOne
actionTitle.TextSize = 8
actionTitle.TextXAlignment = Enum.TextXAlignment.Left
actionTitle.Parent = actionCard

local actionValue = Instance.new("TextLabel")
actionValue.Size = UDim2.new(1, -40, 0, 20)
actionValue.Position = UDim2.new(0, 40, 0, 22)
actionValue.BackgroundTransparency = 1
actionValue.Text = "Menunggu..."
actionValue.TextColor3 = Color3.fromRGB(200, 200, 200)
actionValue.Font = Enum.Font.FredokaOne
actionValue.TextSize = 11
actionValue.TextXAlignment = Enum.TextXAlignment.Left
actionValue.Parent = actionCard

-- Minimize Function
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 280, 0, 35)
        contentFrame.Visible = false
        minBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 280, 0, 200)
        contentFrame.Visible = true
        minBtn.Text = "−"
    end
end)

-- Toggle Function
toggleBtn.MouseButton1Click:Connect(function()
    autoUfoEnabled = not autoUfoEnabled
    if autoUfoEnabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
        toggleBtn.Text = "ON"
        sideLamp.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
        stroke.Color = Color3.fromRGB(80, 200, 80)
        indicatorLight.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
        print("🟢 Auto UFO: ON")
        TweenService:Create(sideLamp, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 255, 80)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 200, 80)}):Play()
        TweenService:Create(indicatorLight, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 255, 80)}):Play()
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
        toggleBtn.Text = "OFF"
        sideLamp.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        stroke.Color = Color3.fromRGB(255, 50, 50)
        indicatorLight.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        print("🔴 Auto UFO: OFF")
        TweenService:Create(sideLamp, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 50, 50)}):Play()
        TweenService:Create(indicatorLight, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end
end)

-- Update UI
task.spawn(function()
    while true do
        if screenGui and screenGui.Parent then
            local currentText = getUIText()
            if currentText then
                lastTextValue.Text = currentText
                lastTextValue.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                local zoneNum, zoneName = detectZoneFromText(currentText)
                
                if zoneNum then
                    statusValue.Text = "✅ Zone: " .. zoneName
                    statusValue.TextColor3 = Color3.fromRGB(100, 255, 100)
                    if autoUfoEnabled and not isProcessing then
                        actionValue.Text = "Teleport ke " .. zoneName
                        actionValue.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                elseif isTargetTimer(currentText) then
                    local colin = GetBestOpenZone()
                    local targetZone = colin + 1
                    statusValue.Text = "📍 Timer 59.30! Best Zone"
                    statusValue.TextColor3 = Color3.fromRGB(255, 200, 100)
                    if autoUfoEnabled and not isProcessing then
                        actionValue.Text = "Teleport ke Best Zone " .. targetZone
                        actionValue.TextColor3 = Color3.fromRGB(255, 200, 100)
                    end
                else
                    statusValue.Text = "⏳ Timer biasa (diabaikan)"
                    statusValue.TextColor3 = Color3.fromRGB(150, 150, 150)
                    actionValue.Text = "Tidak teleport"
                    actionValue.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            else
                lastTextValue.Text = "(UI tidak ditemukan)"
                lastTextValue.TextColor3 = Color3.fromRGB(255, 100, 100)
                statusValue.Text = "UI tidak ditemukan"
                statusValue.TextColor3 = Color3.fromRGB(255, 100, 100)
                actionValue.Text = "--"
            end
        end
        task.wait(0.5)
    end
end)

print("═══════════════════════════════════════════")
print("   AUTO UFO - ZONE + BEST ZONE (59.30)")
print("═══════════════════════════════════════════")
print("📡 Membaca dari: PlayerGui.Root.UfoStatusRoot")
print("🎯 Nama Zone → Teleport ke zone tersebut")
print("📍 Timer 59.30 → Teleport ke Best Zone (Colin+1)")
print("⏳ Timer lainnya → Diabaikan")
print("🖱️ GUI bisa di-drag | [−] Minimize")
print("🔘 Tombol ON/OFF")
print("═══════════════════════════════════════════")