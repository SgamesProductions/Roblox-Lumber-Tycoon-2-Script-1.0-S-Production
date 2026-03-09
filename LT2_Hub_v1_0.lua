-- ============================================
--   S-Productions | LT2 Hub v1.0
--   Auto Chop | Vehicle Speed | ESP | Teleport | Auto Sell
--   Mobil Optimize | TR/EN
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- DİL SİSTEMİ
-- ============================================
local Lang = {
    TR = {
        title       = "LT2 HUB",
        autochop    = "🪓  Auto Chop",
        chopDelay   = "Kesme Hızı",
        vspeed      = "🚗  Araç Hızı",
        vspeedVal   = "Hız Değeri",
        esp         = "🌳  Ağaç ESP",
        teleport    = "🗺️  Teleport",
        autosell    = "💰  Auto Sell",
        tp_spawn    = "📍 Spawn",
        tp_store    = "🏪 Mağaza",
        tp_wood     = "🌲 Orman",
        tp_sawmill  = "⚙️ Testere",
        sec_chop    = "AUTO CHOP",
        sec_vehicle = "VEHICLE",
        sec_esp     = "ESP",
        sec_tp      = "TELEPORT",
        sec_sell    = "AUTO SELL",
        loaded      = "✓  LT2 Hub v1.0 Yüklendi!",
        watermark   = "S-Productions  •  LT2 Hub v1.0  •  Mobil",
        selectLang  = "🌐  Dil Seçin / Select Language",
    },
    EN = {
        title       = "LT2 HUB",
        autochop    = "🪓  Auto Chop",
        chopDelay   = "Chop Speed",
        vspeed      = "🚗  Vehicle Speed",
        vspeedVal   = "Speed Value",
        esp         = "🌳  Tree ESP",
        teleport    = "🗺️  Teleport",
        autosell    = "💰  Auto Sell",
        tp_spawn    = "📍 Spawn",
        tp_store    = "🏪 Store",
        tp_wood     = "🌲 Forest",
        tp_sawmill  = "⚙️ Sawmill",
        sec_chop    = "AUTO CHOP",
        sec_vehicle = "VEHICLE",
        sec_esp     = "ESP",
        sec_tp      = "TELEPORT",
        sec_sell    = "AUTO SELL",
        loaded      = "✓  LT2 Hub v1.0 Loaded!",
        watermark   = "S-Productions  •  LT2 Hub v1.0  •  Mobile",
        selectLang  = "🌐  Dil Seçin / Select Language",
    },
}
local currentLang = "TR"
local function T(k) return Lang[currentLang][k] end

-- ============================================
-- AYARLAR
-- ============================================
local Settings = {
    AutoChop  = { Enabled = false, Delay = 0.1 },
    Vehicle   = { Enabled = false, Speed = 100 },
    ESP       = { Enabled = false },
    AutoSell  = { Enabled = false },
}

-- ============================================
-- TELEPORT NOKTALARı
-- ============================================
local Locations = {
    Spawn   = CFrame.new(130, 5, -130),
    Store   = CFrame.new(-68, 3, -69),
    Forest  = CFrame.new(200, 5, 200),
    Sawmill = CFrame.new(60, 3, -8),
}

local function TeleportTo(cf)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
end

-- ============================================
-- AUTO CHOP
-- ============================================
local chopConn
local lastChop = 0

local function GetAxe()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (
            string.find(string.lower(tool.Name), "axe") or
            string.find(string.lower(tool.Name), "balta") or
            string.find(string.lower(tool.Name), "saw")
        ) then
            return tool
        end
    end
    -- Backpack'te de ara
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (
                string.find(string.lower(tool.Name), "axe") or
                string.find(string.lower(tool.Name), "saw")
            ) then
                return tool
            end
        end
    end
    return nil
end

local function GetNearestTree()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest = nil
    local nearDist = math.huge

    -- LT2'de ağaçlar Trees klasöründe
    local treesFolder = Workspace:FindFirstChild("Trees")
    if not treesFolder then return nil end

    for _, tree in pairs(treesFolder:GetChildren()) do
        local root = tree:FindFirstChild("TreeRegion") or
                     tree:FindFirstChild("Trunk") or
                     tree:FindFirstChildOfClass("Part")
        if root then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist < nearDist and dist < 20 then
                nearDist = dist
                nearest = tree
            end
        end
    end
    return nearest
end

local function ChopTree(tree)
    if not tree then return end
    -- LT2'de kesme remote event'i
    local chopRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Chop")
        or game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
        and game:GetService("ReplicatedStorage").RemoteEvents:FindFirstChild("Chop")

    local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChildOfClass("Part")
    if trunk and chopRemote then
        chopRemote:FireServer(trunk)
    end

    -- Alternatif: tool'u kullan
    local axe = GetAxe()
    if axe and trunk then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Ağaca doğru yürü
                hrp.CFrame = CFrame.new(trunk.Position + Vector3.new(3, 0, 0), trunk.Position)
            end
        end
        -- Tool activate
        local activateRemote = axe:FindFirstChild("Activate") or axe:FindFirstChildOfClass("RemoteEvent")
        if activateRemote then
            activateRemote:FireServer()
        end
    end
end

local function EnableAutoChop()
    chopConn = RunService.Heartbeat:Connect(function()
        if not Settings.AutoChop.Enabled then return end
        local now = tick()
        if now - lastChop < Settings.AutoChop.Delay then return end
        lastChop = now

        local char = LocalPlayer.Character
        if not char then return end

        -- En yakın ağacı bul ve kes
        local treesFolder = Workspace:FindFirstChild("Trees")
        if not treesFolder then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, tree in pairs(treesFolder:GetChildren()) do
            local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChildOfClass("UnionOperation")
            if trunk then
                local dist = (hrp.Position - trunk.Position).Magnitude
                if dist < 15 then
                    -- Clickdetector varsa tıkla
                    local cd = trunk:FindFirstChildOfClass("ClickDetector")
                        or tree:FindFirstChildOfClass("ClickDetector")
                    if cd then
                        fireclickdetector(cd)
                    end
                end
            end
        end
    end)
end

-- ============================================
-- VEHICLE SPEED
-- ============================================
RunService.Heartbeat:Connect(function()
    if not Settings.Vehicle.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Seat'e oturuyorsa hızlandır
    local seat = hrp:FindFirstChildOfClass("Weld") and hrp.Weld.Part1
    if not seat then
        -- VehicleSeat ara
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat") and obj.Occupant then
                if obj.Occupant.Parent == char then
                    obj.MaxSpeed = Settings.Vehicle.Speed
                    obj.Torque = 50
                    obj.TurnSpeed = 2
                end
            end
        end
    end
end)

-- ============================================
-- AĞAÇ ESP
-- ============================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "LT2_ESP"
ESPFolder.Parent = game.CoreGui

local espObjects = {}

local function ClearESP()
    for _, v in pairs(espObjects) do
        if v and v.Parent then v:Destroy() end
    end
    espObjects = {}
end

local function UpdateTreeESP()
    ClearESP()
    if not Settings.ESP.Enabled then return end

    local treesFolder = Workspace:FindFirstChild("Trees")
    if not treesFolder then return end

    for _, tree in pairs(treesFolder:GetChildren()) do
        local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChildOfClass("Part")
            or tree:FindFirstChildOfClass("UnionOperation")
        if trunk then
            local bb = Instance.new("BillboardGui")
            bb.Name = "TreeESP"
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 100, 0, 40)
            bb.StudsOffset = Vector3.new(0, 5, 0)
            bb.Adornee = trunk
            bb.Parent = ESPFolder

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.Text = "🌲 " .. tree.Name
            lbl.Parent = bb

            table.insert(espObjects, bb)
        end
    end
end

-- ESP sürekli güncelle
RunService.Heartbeat:Connect(function()
    if not Settings.ESP.Enabled then
        if #espObjects > 0 then ClearESP() end
        return
    end
    -- Her 3 saniyede bir güncelle (performans için)
    if tick() % 3 < 0.05 then
        UpdateTreeESP()
    end
    -- Mesafeyi güncelle
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, bb in pairs(espObjects) do
        if bb and bb.Adornee and bb.Adornee.Parent then
            local dist = math.floor((hrp.Position - bb.Adornee.Position).Magnitude)
            local lbl = bb:FindFirstChildOfClass("TextLabel")
            if lbl then
                local treeName = bb.Parent and bb.Name or "Tree"
                lbl.Text = "🌲 [" .. dist .. "m]"
                -- Yakınsa yeşil, uzaksa sarı
                if dist < 30 then
                    lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
                elseif dist < 80 then
                    lbl.TextColor3 = Color3.fromRGB(255, 220, 50)
                else
                    lbl.TextColor3 = Color3.fromRGB(255, 120, 50)
                end
            end
        end
    end
end)

-- ============================================
-- AUTO SELL
-- ============================================
local sellConn
local lastSell = 0

local function TrySell()
    -- LT2'de satış Wood Dropoff noktasına gidip bırakmak
    -- Önce player'ın taşıdığı logları bul
    local char = LocalPlayer.Character
    if not char then return end

    -- Satış remote'u
    local sellRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Sell")
    if sellRemote then
        sellRemote:FireServer()
        return
    end

    -- Wood Dropoff'a teleport et
    local dropoff = Workspace:FindFirstChild("WoodDropOff")
        or Workspace:FindFirstChild("DropOff")
        or Workspace:FindFirstChild("LogDropOff")

    if dropoff then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = dropoff.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

sellConn = RunService.Heartbeat:Connect(function()
    if not Settings.AutoSell.Enabled then return end
    local now = tick()
    if now - lastSell < 5 then return end -- her 5 saniyede bir
    lastSell = now
    TrySell()
end)

EnableAutoChop()

-- ============================================
-- ANİMASYONLU INTRO
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SProductionsLT2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game.CoreGui

local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
IntroFrame.BorderSizePixel = 0
IntroFrame.ZIndex = 100
IntroFrame.Parent = ScreenGui

local ig = Instance.new("UIGradient")
ig.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 12, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 8, 0)),
})
ig.Rotation = 135
ig.Parent = IntroFrame

local SLetter = Instance.new("TextLabel")
SLetter.Size = UDim2.new(0, 130, 0, 130)
SLetter.Position = UDim2.new(0.5, -65, 0.5, -115)
SLetter.BackgroundTransparency = 1
SLetter.Font = Enum.Font.GothamBold
SLetter.TextSize = 110
SLetter.TextColor3 = Color3.fromRGB(80, 200, 80)
SLetter.Text = "S"
SLetter.TextTransparency = 1
SLetter.ZIndex = 101
SLetter.Parent = IntroFrame

local introLine = Instance.new("Frame")
introLine.Size = UDim2.new(0, 0, 0, 3)
introLine.Position = UDim2.new(0.5, 0, 0.5, 20)
introLine.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
introLine.BorderSizePixel = 0
introLine.AnchorPoint = Vector2.new(0.5, 0.5)
introLine.ZIndex = 101
introLine.Parent = IntroFrame
Instance.new("UICorner", introLine).CornerRadius = UDim.new(1, 0)

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(1, 0, 0, 50)
introText.Position = UDim2.new(0, 0, 0.5, 30)
introText.BackgroundTransparency = 1
introText.Font = Enum.Font.GothamBold
introText.TextSize = isMobile and 30 or 34
introText.TextColor3 = Color3.fromRGB(255, 255, 255)
introText.Text = "S-Productions"
introText.TextTransparency = 1
introText.ZIndex = 101
introText.Parent = IntroFrame

local introSub = Instance.new("TextLabel")
introSub.Size = UDim2.new(1, 0, 0, 28)
introSub.Position = UDim2.new(0, 0, 0.5, 82)
introSub.BackgroundTransparency = 1
introSub.Font = Enum.Font.Gotham
introSub.TextSize = isMobile and 14 or 16
introSub.TextColor3 = Color3.fromRGB(80, 200, 80)
introSub.Text = "LT2 Hub  v1.0"
introSub.TextTransparency = 1
introSub.ZIndex = 101
introSub.Parent = IntroFrame

local function PlayIntro(onFinish)
    task.delay(0.3, function()
        TweenService:Create(SLetter, TweenInfo.new(0.6, Enum.EasingStyle.Back), { TextTransparency = 0 }):Play()
    end)
    task.delay(0.8, function()
        TweenService:Create(introLine, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { Size = UDim2.new(0, 300, 0, 3) }):Play()
    end)
    task.delay(1.1, function()
        TweenService:Create(introText, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    end)
    task.delay(1.4, function()
        TweenService:Create(introSub, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
    end)
    task.delay(2.9, function()
        TweenService:Create(SLetter,    TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        TweenService:Create(introLine,  TweenInfo.new(0.5), { Size = UDim2.new(0, 0, 0, 3) }):Play()
        TweenService:Create(introText,  TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        TweenService:Create(introSub,   TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        TweenService:Create(IntroFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        task.delay(0.6, function()
            IntroFrame:Destroy()
            onFinish()
        end)
    end)
end

-- ============================================
-- DİL SEÇİM EKRANI
-- ============================================
local function ShowLangSelect(onSelect)
    local LF = Instance.new("Frame")
    LF.Size = UDim2.new(0, 290, 0, 215)
    LF.Position = UDim2.new(0.5, -145, 0.5, -107)
    LF.BackgroundColor3 = Color3.fromRGB(8, 14, 8)
    LF.BorderSizePixel = 0
    LF.BackgroundTransparency = 1
    LF.ZIndex = 50
    LF.Parent = ScreenGui
    Instance.new("UICorner", LF).CornerRadius = UDim.new(0, 16)

    local ls = Instance.new("UIStroke")
    ls.Color = Color3.fromRGB(80, 200, 80)
    ls.Thickness = 2
    ls.Parent = LF

    local lt = Instance.new("TextLabel")
    lt.Size = UDim2.new(1, 0, 0, 60)
    lt.BackgroundTransparency = 1
    lt.Font = Enum.Font.GothamBold
    lt.TextSize = isMobile and 17 or 15
    lt.TextColor3 = Color3.fromRGB(255, 255, 255)
    lt.Text = T("selectLang")
    lt.TextTransparency = 1
    lt.ZIndex = 51
    lt.Parent = LF

    local function MakeBtn(text, yPos, lang)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.82, 0, 0, isMobile and 54 or 46)
        btn.Position = UDim2.new(0.09, 0, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isMobile and 16 or 14
        btn.TextColor3 = Color3.fromRGB(220, 240, 220)
        btn.Text = text
        btn.BorderSizePixel = 0
        btn.BackgroundTransparency = 1
        btn.ZIndex = 51
        btn.Parent = LF
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bs = Instance.new("UIStroke")
        bs.Color = Color3.fromRGB(40, 70, 40)
        bs.Thickness = 1
        bs.Parent = btn

        btn.MouseButton1Click:Connect(function()
            currentLang = lang
            TweenService:Create(LF, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
            task.delay(0.4, function() LF:Destroy() onSelect() end)
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(40, 140, 40), BackgroundTransparency = 0,
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(15, 25, 15), BackgroundTransparency = 0,
            }):Play()
        end)
        return btn
    end

    TweenService:Create(LF, TweenInfo.new(0.5, Enum.EasingStyle.Back), { BackgroundTransparency = 0 }):Play()
    task.delay(0.2, function()
        TweenService:Create(lt, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
    end)
    local b1 = MakeBtn("🇹🇷  Türkçe", 68, "TR")
    local b2 = MakeBtn("🇬🇧  English", 132, "EN")
    task.delay(0.3, function()
        TweenService:Create(b1, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(b2, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
    end)
end

-- ============================================
-- ANA GUI
-- ============================================
local function BuildMainGui()
    local FW = isMobile and 330 or 310
    local FH = isMobile and 580 or 555
    local TH = isMobile and 60 or 52
    local TS = isMobile and 14 or 12
    local TITLES = isMobile and 18 or 16
    local ACCENT = Color3.fromRGB(80, 200, 80)
    local ACCENT2 = Color3.fromRGB(40, 140, 40)
    local BG = Color3.fromRGB(6, 12, 6)
    local BG2 = Color3.fromRGB(12, 22, 12)

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, FW, 0, FH)
    MainFrame.Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2)
    MainFrame.BackgroundColor3 = BG
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

    local ms = Instance.new("UIStroke")
    ms.Color = ACCENT
    ms.Thickness = 1.8
    ms.Parent = MainFrame

    local mg = Instance.new("UIGradient")
    mg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 20, 10)),
        ColorSequenceKeypoint.new(1, BG),
    })
    mg.Rotation = 135
    mg.Parent = MainFrame

    -- Başlık
    local TB = Instance.new("Frame")
    TB.Size = UDim2.new(1, 0, 0, 65)
    TB.BackgroundColor3 = BG2
    TB.BorderSizePixel = 0
    TB.Parent = MainFrame
    Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 14)

    local al = Instance.new("Frame")
    al.Size = UDim2.new(0, 4, 0.65, 0)
    al.Position = UDim2.new(0, 14, 0.175, 0)
    al.BackgroundColor3 = ACCENT
    al.BorderSizePixel = 0
    al.Parent = TB
    Instance.new("UICorner", al).CornerRadius = UDim.new(1, 0)

    local cl = Instance.new("TextLabel")
    cl.Size = UDim2.new(1, -95, 0, 20)
    cl.Position = UDim2.new(0, 26, 0, 8)
    cl.BackgroundTransparency = 1
    cl.Font = Enum.Font.GothamBold
    cl.TextSize = 10
    cl.TextColor3 = ACCENT2
    cl.TextXAlignment = Enum.TextXAlignment.Left
    cl.Text = "S-PRODUCTIONS"
    cl.Parent = TB

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -95, 0, 28)
    tl.Position = UDim2.new(0, 26, 0, 26)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = TITLES
    tl.TextColor3 = Color3.fromRGB(230, 255, 230)
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Text = "🌲 " .. T("title") .. "  v1.0"
    tl.Parent = TB

    local bS = isMobile and 36 or 30

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, bS, 0, bS)
    MinBtn.Position = UDim2.new(1, -(bS*2+18), 0.5, -bS/2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.TextColor3 = ACCENT
    MinBtn.Text = "▼"
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TB
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, bS, 0, bS)
    CloseBtn.Position = UDim2.new(1, -(bS+10), 0.5, -bS/2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(160, 30, 30)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Text = "✕"
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TB
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, FW, 0, 0), BackgroundTransparency = 1,
        }):Play()
        task.delay(0.35, function() ScreenGui:Destroy() end)
    end)

    -- Mini frame
    local MF = Instance.new("Frame")
    MF.Size = UDim2.new(0, FW, 0, 52)
    MF.Position = MainFrame.Position
    MF.BackgroundColor3 = BG
    MF.BorderSizePixel = 0
    MF.Visible = false
    MF.Active = true
    MF.Draggable = true
    MF.Parent = ScreenGui
    Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)
    local mfs = Instance.new("UIStroke")
    mfs.Color = ACCENT
    mfs.Thickness = 1.5
    mfs.Parent = MF

    local mfl = Instance.new("TextLabel")
    mfl.Size = UDim2.new(1, -80, 1, 0)
    mfl.Position = UDim2.new(0, 16, 0, 0)
    mfl.BackgroundTransparency = 1
    mfl.Font = Enum.Font.GothamBold
    mfl.TextSize = 13
    mfl.TextColor3 = Color3.fromRGB(200, 240, 200)
    mfl.TextXAlignment = Enum.TextXAlignment.Left
    mfl.Text = "🌲 LT2 HUB  •  S-PRODUCTIONS"
    mfl.Parent = MF

    local EB = Instance.new("TextButton")
    EB.Size = UDim2.new(0, bS, 0, bS)
    EB.Position = UDim2.new(1, -(bS+10), 0.5, -bS/2)
    EB.BackgroundColor3 = Color3.fromRGB(30, 110, 30)
    EB.Font = Enum.Font.GothamBold
    EB.TextSize = 14
    EB.TextColor3 = Color3.fromRGB(255, 255, 255)
    EB.Text = "▲"
    EB.BorderSizePixel = 0
    EB.Parent = MF
    Instance.new("UICorner", EB).CornerRadius = UDim.new(0, 8)

    MinBtn.MouseButton1Click:Connect(function()
        MF.Position = MainFrame.Position
        MainFrame.Visible = false
        MF.Visible = true
    end)
    EB.MouseButton1Click:Connect(function()
        MainFrame.Position = MF.Position
        MF.Visible = false
        MainFrame.Visible = true
    end)

    -- İçerik
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, 0, 1, -70)
    Content.Position = UDim2.new(0, 0, 0, 70)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = isMobile and 4 or 3
    Content.ScrollBarImageColor3 = ACCENT
    Content.ScrollingDirection = Enum.ScrollingDirection.Y
    Content.Parent = MainFrame

    -- Yardımcılar
    local function Section(yPos, text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -28, 0, 24)
        l.Position = UDim2.new(0, 14, 0, yPos)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextColor3 = ACCENT2
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "▸ " .. string.upper(text)
        l.Parent = Content
    end

    local function Toggle(yPos, label, onToggle)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -24, 0, TH)
        f.Position = UDim2.new(0, 12, 0, yPos)
        f.BackgroundColor3 = BG2
        f.BorderSizePixel = 0
        f.Parent = Content
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = Color3.fromRGB(25, 45, 25)
        fs.Thickness = 1
        fs.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 1, 0)
        lbl.Position = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = TS
        lbl.TextColor3 = Color3.fromRGB(200, 235, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = label
        lbl.Parent = f

        local bW = isMobile and 54 or 46
        local bH = isMobile and 30 or 24
        local cW = isMobile and 22 or 18

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, bW, 0, bH)
        bg.Position = UDim2.new(1, -(bW+12), 0.5, -bH/2)
        bg.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
        bg.BorderSizePixel = 0
        bg.Parent = f
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, cW, 0, cW)
        circle.Position = UDim2.new(0, 4, 0.5, -cW/2)
        circle.BackgroundColor3 = Color3.fromRGB(100, 140, 100)
        circle.BorderSizePixel = 0
        circle.Parent = bg
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

        local toggled = false
        local onP = bW - cW - 4

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = f

        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            TweenService:Create(circle, TweenInfo.new(0.18), {
                Position = toggled and UDim2.new(0, onP, 0.5, -cW/2) or UDim2.new(0, 4, 0.5, -cW/2),
                BackgroundColor3 = toggled and Color3.fromRGB(255,255,255) or Color3.fromRGB(100,140,100),
            }):Play()
            TweenService:Create(bg, TweenInfo.new(0.18), {
                BackgroundColor3 = toggled and ACCENT2 or Color3.fromRGB(30,50,30),
            }):Play()
            onToggle(toggled)
        end)
    end

    local function Slider(yPos, label, minV, maxV, defV, onChange)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -24, 0, TH)
        f.Position = UDim2.new(0, 12, 0, yPos)
        f.BackgroundColor3 = BG2
        f.BorderSizePixel = 0
        f.Parent = Content
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = Color3.fromRGB(25, 45, 25)
        fs.Thickness = 1
        fs.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.68, 0, 0, 22)
        lbl.Position = UDim2.new(0, 16, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = TS
        lbl.TextColor3 = Color3.fromRGB(180, 215, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = label
        lbl.Parent = f

        local vl = Instance.new("TextLabel")
        vl.Size = UDim2.new(0.3, -10, 0, 22)
        vl.Position = UDim2.new(0.7, 0, 0, 6)
        vl.BackgroundTransparency = 1
        vl.Font = Enum.Font.GothamBold
        vl.TextSize = TS
        vl.TextColor3 = ACCENT
        vl.TextXAlignment = Enum.TextXAlignment.Right
        vl.Text = tostring(defV)
        vl.Parent = f

        local tH2 = isMobile and 8 or 6
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -32, 0, tH2)
        track.Position = UDim2.new(0, 16, 0, TH - tH2 - 10)
        track.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
        track.BorderSizePixel = 0
        track.Parent = f
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local r0 = (defV - minV) / (maxV - minV)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(r0, 0, 1, 0)
        fill.BackgroundColor3 = ACCENT2
        fill.BorderSizePixel = 0
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local kS = isMobile and 20 or 14
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, kS, 0, kS)
        knob.Position = UDim2.new(r0, -kS/2, 0.5, -kS/2)
        knob.BackgroundColor3 = Color3.fromRGB(200, 255, 200)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(1, 0, 4, 0)
        tb.Position = UDim2.new(0, 0, 0.5, -tH2*2)
        tb.BackgroundTransparency = 1
        tb.Text = ""
        tb.ZIndex = 3
        tb.Parent = track

        local function upd(x)
            local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + r*(maxV-minV))
            fill.Size = UDim2.new(r, 0, 1, 0)
            knob.Position = UDim2.new(r, -kS/2, 0.5, -kS/2)
            vl.Text = tostring(v)
            onChange(v)
        end

        tb.MouseButton1Down:Connect(function() dragging = true end)
        tb.TouchStarted:Connect(function(t) dragging = true upd(t.Position.X) end)
        tb.TouchMoved:Connect(function(t) if dragging then upd(t.Position.X) end end)
        tb.TouchEnded:Connect(function() dragging = false end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or
               i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        RunService.Heartbeat:Connect(function()
            if dragging then upd(UserInputService:GetMouseLocation().X) end
        end)
    end

    -- Teleport butonu
    local function TpButton(yPos, label, location)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.47, 0, 0, isMobile and 48 or 42)
        btn.Position = UDim2.new(location == "left" and 0.02 or 0.51, 0, 0, yPos)
        btn.BackgroundColor3 = BG2
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = TS
        btn.TextColor3 = Color3.fromRGB(200, 235, 200)
        btn.Text = label
        btn.BorderSizePixel = 0
        btn.Parent = Content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local bs = Instance.new("UIStroke")
        bs.Color = Color3.fromRGB(25, 45, 25)
        bs.Thickness = 1
        bs.Parent = btn

        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = ACCENT2 }):Play()
            task.delay(0.2, function()
                TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = BG2 }):Play()
            end)
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(20, 50, 20) }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = BG2 }):Play()
        end)

        return btn
    end

    -- ============================================
    -- TOGGLELAR
    -- ============================================
    local y = 0

    -- AUTO CHOP
    Section(y, T("sec_chop"))    y = y + 26
    Toggle(y, T("autochop"), function(on)
        Settings.AutoChop.Enabled = on
    end) y = y + TH + 6
    Slider(y, T("chopDelay"), 1, 10, 5, function(v)
        Settings.AutoChop.Delay = v / 10
    end) y = y + TH + 8

    -- VEHICLE
    Section(y, T("sec_vehicle")) y = y + 26
    Toggle(y, T("vspeed"), function(on)
        Settings.Vehicle.Enabled = on
    end) y = y + TH + 6
    Slider(y, T("vspeedVal"), 50, 300, 100, function(v)
        Settings.Vehicle.Speed = v
    end) y = y + TH + 8

    -- ESP
    Section(y, T("sec_esp"))     y = y + 26
    Toggle(y, T("esp"), function(on)
        Settings.ESP.Enabled = on
        if not on then ClearESP() else UpdateTreeESP() end
    end) y = y + TH + 8

    -- TELEPORT
    Section(y, T("sec_tp"))      y = y + 26
    local tpBtnH = isMobile and 48 or 42
    local b1 = TpButton(y, T("tp_spawn"), "left")
    local b2 = TpButton(y, T("tp_store"), "right")
    b1.MouseButton1Click:Connect(function() TeleportTo(Locations.Spawn) end)
    b2.MouseButton1Click:Connect(function() TeleportTo(Locations.Store) end)
    y = y + tpBtnH + 6
    local b3 = TpButton(y, T("tp_wood"), "left")
    local b4 = TpButton(y, T("tp_sawmill"), "right")
    b3.MouseButton1Click:Connect(function() TeleportTo(Locations.Forest) end)
    b4.MouseButton1Click:Connect(function() TeleportTo(Locations.Sawmill) end)
    y = y + tpBtnH + 8

    -- AUTO SELL
    Section(y, T("sec_sell"))    y = y + 26
    Toggle(y, T("autosell"), function(on)
        Settings.AutoSell.Enabled = on
    end) y = y + TH + 14

    Content.CanvasSize = UDim2.new(0, 0, 0, y)

    -- Watermark
    local wm = Instance.new("TextLabel")
    wm.Size = UDim2.new(1, -24, 0, 22)
    wm.Position = UDim2.new(0, 12, 1, -28)
    wm.BackgroundTransparency = 1
    wm.Font = Enum.Font.Gotham
    wm.TextSize = 10
    wm.TextColor3 = Color3.fromRGB(50, 80, 50)
    wm.TextXAlignment = Enum.TextXAlignment.Center
    wm.Text = T("watermark")
    wm.Parent = MainFrame

    -- Bildirim
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 275, 0, 44)
    nf.Position = UDim2.new(0.5, -137, 1, 10)
    nf.BackgroundColor3 = ACCENT2
    nf.BorderSizePixel = 0
    nf.Parent = ScreenGui
    Instance.new("UICorner", nf).CornerRadius = UDim.new(0, 10)

    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(1, 0, 1, 0)
    nt.BackgroundTransparency = 1
    nt.Font = Enum.Font.GothamBold
    nt.TextSize = 13
    nt.TextColor3 = Color3.fromRGB(255, 255, 255)
    nt.Text = T("loaded")
    nt.Parent = nf

    TweenService:Create(nf, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -137, 1, -62)
    }):Play()
    task.delay(3.5, function()
        TweenService:Create(nf, TweenInfo.new(0.4), { Position = UDim2.new(0.5, -137, 1, 10) }):Play()
        task.delay(0.5, function() nf:Destroy() end)
    end)
end

-- ============================================
-- INTRO → DİL → GUI
-- ============================================
PlayIntro(function()
    ShowLangSelect(function()
        BuildMainGui()
    end)
end)

print("[S-Productions] LT2 Hub v1.0 - Yüklendi!")
