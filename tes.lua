-- ========== TAMBAHKAN STATUS ZONE DETECT KE GUI SANTET SLIME ==========
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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

-- ========== FUNGSI BACA TEKS DARI UI ==========
local function getTextFromUI()
    local ufoUI = player.PlayerGui:FindFirstChild("Root") 
        and player.PlayerGui.Root:FindFirstChild("UfoStatusRoot")
    
    if not ufoUI then
        ufoUI = player.PlayerGui:FindFirstChild("UfoStatusRoot")
    end
    
    if not ufoUI then
        return nil, nil
    end
    
    -- Kumpulkan semua teks
    local texts = {}
    local rawTexts = {}
    
    local function scan(obj)
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if child.Text and child.Text ~= "" then
                    table.insert(texts, child.Text)
                    table.insert(rawTexts, {name = child.Name, text = child.Text})
                end
            end
            scan(child)
        end
    end
    scan(ufoUI)
    
    return texts, rawTexts
end

-- ========== FUNGSI DETECT ZONE ==========
local function detectZoneFromText(text)
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

-- ========== FUNGSI TELEPORT ==========
local function teleportToZone(zoneNum, zoneName)
    local targetPart = workspace:FindFirstChild("Zones") 
        and workspace.Zones:FindFirstChild(tostring(zoneNum)) 
        and workspace.Zones[tostring(zoneNum)]:FindFirstChild("POI") 
        and workspace.Zones[tostring(zoneNum)].POI:FindFirstChild("PlayerSpawn")
    
    if not targetPart then
        targetPart = workspace:FindFirstChild(zoneName)
        if not targetPart and workspace:FindFirstChild("Zones") then
            targetPart = workspace.Zones:FindFirstChild(tostring(zoneNum))
        end
    end
    
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local hrp = char.HumanoidRootPart
    hrp.CFrame = CFrame.new(targetPart.Position.X, targetPart.Position.Y + 3, targetPart.Position.Z)
    return true
end

-- ========== CARI GUI SANTET SLIME ==========
local santetGui = player.PlayerGui:FindFirstChild("ZAIXPLOIT")
if not santetGui then
    print("❌ GUI Santet Slime tidak ditemukan!")
    return
end

local mainFrame = santetGui:FindFirstChildOfClass("Frame")
if not mainFrame then
    print("❌ Frame utama tidak ditemukan!")
    return
end

local contentFrame = mainFrame:FindFirstChild("ContentFrame")
if not contentFrame then
    contentFrame = mainFrame
end

-- ========== BUAT CARD STATUS ZONE ==========
-- Hapus card lama jika ada
local oldCard = contentFrame:FindFirstChild("ZoneStatusCard")
if oldCard then oldCard:Destroy() end

-- Card utama
local zoneCard = Instance.new("Frame")
zoneCard.Name = "ZoneStatusCard"
zoneCard.Size = UDim2.new(1, -20, 0, 80)
zoneCard.Position = UDim2.new(0, 10, 0, 5)
zoneCard.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
zoneCard.BackgroundTransparency = 0.2
zoneCard.BorderSizePixel = 0
zoneCard.Parent = contentFrame

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 8)
cardCorner.Parent = zoneCard

-- Icon
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 35, 1, 0)
icon.Position = UDim2.new(0, 5, 0, 0)
icon.BackgroundTransparency = 1
icon.Text = "📡"
icon.TextColor3 = Color3.fromRGB(100, 200, 255)
icon.TextSize = 20
icon.Font = Enum.Font.FredokaOne
icon.Parent = zoneCard

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 18)
title.Position = UDim2.new(0, 45, 0, 4)
title.BackgroundTransparency = 1
title.Text = "UI STATUS READER"
title.TextColor3 = Color3.fromRGB(150, 150, 200)
title.Font = Enum.Font.FredokaOne
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = zoneCard

-- Teks yang terbaca
local detectedTextLabel = Instance.new("TextLabel")
detectedTextLabel.Size = UDim2.new(1, -45, 0, 20)
detectedTextLabel.Position = UDim2.new(0, 45, 0, 22)
detectedTextLabel.BackgroundTransparency = 1
detectedTextLabel.Text = "📝 Teks: --"
detectedTextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
detectedTextLabel.Font = Enum.Font.FredokaOne
detectedTextLabel.TextSize = 10
detectedTextLabel.TextXAlignment = Enum.TextXAlignment.Left
detectedTextLabel.Parent = zoneCard

-- Zone terdeteksi
local zoneDetectedLabel = Instance.new("TextLabel")
zoneDetectedLabel.Size = UDim2.new(1, -45, 0, 20)
zoneDetectedLabel.Position = UDim2.new(0, 45, 0, 40)
zoneDetectedLabel.BackgroundTransparency = 1
zoneDetectedLabel.Text = "🗺️ Zone: --"
zoneDetectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
zoneDetectedLabel.Font = Enum.Font.FredokaOne
zoneDetectedLabel.TextSize = 11
zoneDetectedLabel.TextXAlignment = Enum.TextXAlignment.Left
zoneDetectedLabel.Parent = zoneCard

-- Status auto teleport
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.6, -45, 0, 16)
statusLabel.Position = UDim2.new(0, 45, 0, 60)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⚡ Auto TP: ON"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.FredokaOne
statusLabel.TextSize = 9
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = zoneCard

-- Tombol toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 45, 0, 18)
toggleBtn.Position = UDim2.new(1, -50, 0, 58)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
toggleBtn.Text = "ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.FredokaOne
toggleBtn.TextSize = 9
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = zoneCard
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 4)
toggleCorner.Parent = toggleBtn

local autoTeleport = true
local lastTeleportedZone = nil

toggleBtn.MouseButton1Click:Connect(function()
    autoTeleport = not autoTeleport
    if autoTeleport then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        toggleBtn.Text = "ON"
        statusLabel.Text = "⚡ Auto TP: ON"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        print("🟢 Auto Zone Teleport: ON")
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        toggleBtn.Text = "OFF"
        statusLabel.Text = "⚡ Auto TP: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        print("🔴 Auto Zone Teleport: OFF")
    end
end)

-- ========== UPDATE STATUS SETIAP DETIK ==========
task.spawn(function()
    while true do
        local texts, rawTexts = getTextFromUI()
        
        if texts and #texts > 0 then
            -- Tampilkan teks pertama yang terbaca
            local firstText = texts[1]
            detectedTextLabel.Text = "📝 Teks: \"" .. firstText .. "\""
            detectedTextLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            -- Coba detect zone dari teks
            local zoneNum, zoneName = detectZoneFromText(firstText)
            
            if zoneNum then
                zoneDetectedLabel.Text = "🗺️ Zone: " .. zoneNum .. " - " .. zoneName
                zoneDetectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                -- Auto teleport jika ON dan zone berubah
                if autoTeleport and zoneNum ~= lastTeleportedZone then
                    print("🔄 Zone terdeteksi: " .. zoneName .. ", teleport...")
                    local success = teleportToZone(zoneNum, zoneName)
                    if success then
                        lastTeleportedZone = zoneNum
                        zoneDetectedLabel.Text = "🗺️ Zone: " .. zoneNum .. " - " .. zoneName .. " ✅"
                    end
                end
            else
                zoneDetectedLabel.Text = "🗺️ Zone: Tidak terdeteksi"
                zoneDetectedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        else
            detectedTextLabel.Text = "📝 Teks: (Tidak ada)"
            detectedTextLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            zoneDetectedLabel.Text = "🗺️ Zone: UI tidak ditemukan"
            zoneDetectedLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        task.wait(1) -- Update setiap 1 detik
    end
end)

-- Geser elemen lain ke bawah
task.wait(0.5)
for _, child in pairs(contentFrame:GetChildren()) do
    if child ~= zoneCard and child:IsA("Frame") then
        local currentPos = child.Position.Y.Offset
        if currentPos < 90 then
            child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, currentPos + 90)
        end
    end
end

print("═══════════════════════════════════════════")
print("   STATUS ZONE DETECT TELAH DITAMBAHKAN")
print("═══════════════════════════════════════════")
print("📡 Membaca dari: PlayerGui.Root.UfoStatusRoot")
print("📝 Menampilkan teks yang terbaca")
print("🗺️ Auto detect nama zone")
print("⚡ Auto teleport saat zone berubah (bisa toggle)")
print("═══════════════════════════════════════════")