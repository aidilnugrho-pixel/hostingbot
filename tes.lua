-- ========== AUTO UFO (DETECT UI + BEST ZONE) ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ========== KONFIGURASI ==========
local autoUfoEnabled = true
local lastUIText = nil

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

-- ========== TELEPORT KE ZONE ==========
local function TeleportToZone(zoneNum)
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
    print("✅ Teleport ke Zone " .. zoneNum)
    return true
end

-- ========== PROSES TEKS (1x PER PERUBAHAN) ==========
local function processText(currentText)
    if currentText == lastUIText then return end
    
    local zoneNum, zoneName = detectZoneFromText(currentText)
    
    if zoneNum then
        print("🎯 " .. currentText .. " → Teleport ke " .. zoneName)
        TeleportToZone(zoneNum)
    else
        local bestZone = GetBestOpenZone()
        if bestZone > 0 then
            print("❌ " .. currentText .. " → Teleport ke Best Zone: " .. bestZone)
            TeleportToZone(bestZone)
        end
    end
    
    lastUIText = currentText
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
screenGui.Name = "AutoUfoBestZone"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 150)
frame.Position = UDim2.new(0.5, -160, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(8, 6, 15)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 150, 255)
stroke.Thickness = 1
stroke.Transparency = 0.3
stroke.Parent = frame

-- Side Lamp
local sideLamp = Instance.new("Frame")
sideLamp.Size = UDim2.new(0, 4, 1, -10)
sideLamp.Position = UDim2.new(0, 2, 0, 5)
sideLamp.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
sideLamp.BorderSizePixel = 0
sideLamp.Parent = frame
local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 2)
sideCorner.Parent = sideLamp

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🛸 AUTO UFO"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Tombol ON/OFF
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 26)
toggleBtn.Position = UDim2.new(1, -72, 0.5, -13)
toggleBtn.BackgroundColor3 = autoUfoEnabled and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(200, 50, 50)
toggleBtn.Text = autoUfoEnabled and "ON" or "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = titleBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- Icon
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 45, 0, 45)
icon.Position = UDim2.new(0, 12, 0, 50)
icon.BackgroundTransparency = 1
icon.Text = "🛸"
icon.TextColor3 = Color3.fromRGB(100, 200, 255)
icon.TextSize = 26
icon.Parent = frame

-- Status Text
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -65, 0, 20)
statusText.Position = UDim2.new(0, 65, 0, 52)
statusText.BackgroundTransparency = 1
statusText.Text = "📡 Menunggu perubahan..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 220)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 11
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = frame

-- Teks Terakhir
local lastTextLabel = Instance.new("TextLabel")
lastTextLabel.Size = UDim2.new(1, -65, 0, 18)
lastTextLabel.Position = UDim2.new(0, 65, 0, 75)
lastTextLabel.BackgroundTransparency = 1
lastTextLabel.Text = "📝 Teks: --"
lastTextLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
lastTextLabel.Font = Enum.Font.Gotham
lastTextLabel.TextSize = 10
lastTextLabel.TextXAlignment = Enum.TextXAlignment.Left
lastTextLabel.Parent = frame

-- Status Zone
local zoneStatusLabel = Instance.new("TextLabel")
zoneStatusLabel.Size = UDim2.new(1, -65, 0, 18)
zoneStatusLabel.Position = UDim2.new(0, 65, 0, 95)
zoneStatusLabel.BackgroundTransparency = 1
zoneStatusLabel.Text = "🗺️ Status: --"
zoneStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
zoneStatusLabel.Font = Enum.Font.Gotham
zoneStatusLabel.TextSize = 10
zoneStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
zoneStatusLabel.Parent = frame

-- Aksi
local actionLabel = Instance.new("TextLabel")
actionLabel.Size = UDim2.new(1, -65, 0, 18)
actionLabel.Position = UDim2.new(0, 65, 0, 115)
actionLabel.BackgroundTransparency = 1
actionLabel.Text = "⚡ Aksi: --"
actionLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
actionLabel.Font = Enum.Font.Gotham
actionLabel.TextSize = 10
actionLabel.TextXAlignment = Enum.TextXAlignment.Left
actionLabel.Parent = frame

-- Toggle function
toggleBtn.MouseButton1Click:Connect(function()
    autoUfoEnabled = not autoUfoEnabled
    if autoUfoEnabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
        toggleBtn.Text = "ON"
        sideLamp.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        statusText.Text = "✅ AUTO UFO ON"
        statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
        print("🟢 Auto UFO: ON")
        task.wait(2)
        statusText.Text = "📡 Menunggu perubahan..."
        statusText.TextColor3 = Color3.fromRGB(200, 200, 220)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggleBtn.Text = "OFF"
        sideLamp.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusText.Text = "⏸️ AUTO UFO OFF"
        statusText.TextColor3 = Color3.fromRGB(255, 150, 150)
        print("🔴 Auto UFO: OFF")
    end
end)

-- Update UI
task.spawn(function()
    while true do
        if screenGui and screenGui.Parent then
            local currentText = getUIText()
            if currentText then
                lastTextLabel.Text = "📝 Teks: \"" .. currentText .. "\""
                
                local zoneNum, zoneName = detectZoneFromText(currentText)
                
                if zoneNum then
                    zoneStatusLabel.Text = "🗺️ Status: Zone terdeteksi! (" .. zoneName .. ")"
                    zoneStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    if autoUfoEnabled then
                        actionLabel.Text = "⚡ Aksi: Teleport ke " .. zoneName
                        actionLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                else
                    zoneStatusLabel.Text = "🗺️ Status: Zone tidak terdeteksi"
                    zoneStatusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
                    if autoUfoEnabled then
                        local bestZone = GetBestOpenZone()
                        actionLabel.Text = "⚡ Aksi: Teleport ke Best Zone " .. bestZone
                        actionLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    end
                end
            else
                lastTextLabel.Text = "📝 Teks: (UI tidak ditemukan)"
                zoneStatusLabel.Text = "🗺️ Status: UI tidak ditemukan"
                zoneStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                actionLabel.Text = "⚡ Aksi: --"
            end
        end
        task.wait(0.5)
    end
end)

-- Efek side lamp
task.spawn(function()
    while true do
        if autoUfoEnabled then
            for i = 0.5, 1, 0.1 do
                sideLamp.BackgroundTransparency = i
                task.wait(0.05)
            end
            for i = 1, 0.5, -0.1 do
                sideLamp.BackgroundTransparency = i
                task.wait(0.05)
            end
        else
            sideLamp.BackgroundTransparency = 0
            task.wait(0.5)
        end
    end
end)

print("═══════════════════════════════════════════")
print("   AUTO UFO - DETECT UI + BEST ZONE")
print("═══════════════════════════════════════════")
print("📡 Membaca dari: PlayerGui.Root.UfoStatusRoot")
print("🎯 Nama Zone → Teleport ke zone tersebut")
print("❌ Bukan zone → Teleport ke Best Zone (Colin)")
print("🖱️ GUI bisa di-drag dari title bar")
print("🔘 Tombol ON/OFF")
print("═══════════════════════════════════════════")