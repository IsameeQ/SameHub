repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ========== КОНФИГУРАЦИЯ ==========
local CONFIG = {
    SERVERHOP_DELAY = 3,           -- Секунд без предметов до хопа
    SERVERHOP_COOLDOWN = 15,       -- Кулдаун между хопами
    ITEM_REFRESH_INTERVAL = 2,     -- Интервал обновления списка предметов
    FARM_LOOP_DELAY = 0.5,         -- Задержка основного цикла
    TELEPORT_WAIT = 0.3,           -- Задержка после телепорта
    SELL_DELAY = 0.1,              -- Задержка продажи
    LUCKY_ARROW_MAX = 10,          -- Макс Lucky Arrow для покупки
    LUCKY_ARROW_PRICE = 75000,     -- Цена Lucky Arrow
}

-- ========== ЛОГГЕР ==========
local LOG_FILE = "SameHub_Log.txt"
local MAX_LOG_SIZE = 50000 -- ~50KB

local function Log(msg, level)
    level = level or "INFO"
    local line = string.format("[%s] %s: %s", os.date("%Y-%m-%d %H:%M:%S"), level, msg)
    
    pcall(function()
        local currentLog = isfile(LOG_FILE) and readfile(LOG_FILE) or ""
        -- Обрезаем лог если слишком большой
        if #currentLog > MAX_LOG_SIZE then
            currentLog = string.sub(currentLog, -MAX_LOG_SIZE/2)
        end
        writefile(LOG_FILE, currentLog .. line .. "\n")
    end)
    
    if level == "ERROR" then
        warn(line)
    else
        print(line)
    end
end

-- ========== СОХРАНЕНИЕ НАСТРОЕК ==========
local SETTINGS_FILE = "SameHub_Settings.json"

local defaultSettings = {
    BuyLucky = true,
    AutoSell = true,
    AutoReconnect = true,
    ServerHopEnabled = true,
    SellItems = {
        ["Gold Coin"] = true,
        ["Rokakaka"] = true,
        ["Pure Rokakaka"] = true,
        ["Mysterious Arrow"] = true,
        ["Diamond"] = true,
        ["Ancient Scroll"] = true,
        ["Caesar's Headband"] = true,
        ["Stone Mask"] = true,
        ["Rib Cage of The Saint's Corpse"] = true,
        ["Quinton's Glove"] = true,
        ["Zeppeli's Hat"] = true,
        ["Lucky Arrow"] = false,
        ["Clackers"] = true,
        ["Steel Ball"] = true,
        ["Dio's Diary"] = true
    }
}

local Settings = {}

local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[k] = DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

local function LoadSettings()
    if isfile(SETTINGS_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end)
        if ok and data then
            -- Мержим с дефолтными настройками (для новых полей)
            Settings = DeepCopy(defaultSettings)
            for k, v in pairs(data) do
                if type(v) == "table" and type(Settings[k]) == "table" then
                    for k2, v2 in pairs(v) do
                        Settings[k][k2] = v2
                    end
                else
                    Settings[k] = v
                end
            end
            Log("Settings loaded")
            return
        end
    end
    Settings = DeepCopy(defaultSettings)
    Log("Using default settings")
end

local function SaveSettings()
    local ok, err = pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings))
    end)
    if not ok then
        Log("Failed to save settings: " .. tostring(err), "ERROR")
    end
end

LoadSettings()

-- ========== СОЗДАНИЕ ПАПОК ДЛЯ ПРЕДМЕТОВ ==========
local function EnsureItemFolders()
    if not workspace:FindFirstChild("Item_Spawns") then
        local folder = Instance.new("Folder")
        folder.Name = "Item_Spawns"
        folder.Parent = workspace
    end
    if not workspace.Item_Spawns:FindFirstChild("Items") then
        local folder = Instance.new("Folder")
        folder.Name = "Items"
        folder.Parent = workspace.Item_Spawns
    end
end

EnsureItemFolders()

-- ========== HWID И КЛЮЧ ==========
local KEY_URL = "[raw.githubusercontent.com](https://raw.githubusercontent.com/IsameeQ/SameHub/main/keys.txt)"
local HWID_FILE = "SameHub_HWID.txt"
local KEY_INFO_FILE = "SameHub_KeyInfo.txt"
local RESET_LOG_FILE = "SameHub_ResetLog.txt"

local function GetHWID()
    local executor = identifyexecutor and identifyexecutor() or "Unknown"
    local userId = Player.UserId
    local hwid_raw = ""
    
    if syn and syn.crypt and syn.crypt.custom then
        hwid_raw = syn.crypt.custom() or ""
    elseif gethwid then
        hwid_raw = gethwid() or ""
    elseif syn and syn.get_hwid then
        hwid_raw = syn.get_hwid() or ""
    end
    
    return string.format("%s|%s|%s", executor, userId, hwid_raw)
end

local function SaveHWID(hwid)
    writefile(HWID_FILE, hwid)
end

local function LoadHWID()
    return isfile(HWID_FILE) and readfile(HWID_FILE) or nil
end

local function ResetHWID()
    if isfile(HWID_FILE) then
        delfile(HWID_FILE)
    end
end

local function SaveKeyInfo(key)
    writefile(KEY_INFO_FILE, HttpService:JSONEncode({
        key = key,
        activated = os.time()
    }))
end

local function LoadKeyInfo()
    if isfile(KEY_INFO_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_INFO_FILE))
        end)
        if success and data then
            return data
        end
    end
    return nil
end

local function ClearKeyInfo()
    if isfile(KEY_INFO_FILE) then
        delfile(KEY_INFO_FILE)
    end
end

local function GetDaysLeft()
    local info = LoadKeyInfo()
    if not info then return 0 end
    local left = 30 - (os.time() - info.activated) / 86400
    return left > 0 and math.floor(left) or 0
end

local function IsKeyValid()
    local info = LoadKeyInfo()
    return info and (os.time() - info.activated) <= 30 * 86400
end

local function CheckKey()
    local inputKey = ""
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "KeyCheck"
    dialog.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 170)
    frame.Position = UDim2.new(0.5, -160, 0.5, -85)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Parent = dialog
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 2
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🔐 SameHub - Enter Key"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.85, 0, 0, 40)
    textBox.Position = UDim2.new(0.075, 0, 0.3, 0)
    textBox.PlaceholderText = "Enter your key..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 14
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, 0, 0, 40)
    button.Position = UDim2.new(0.25, 0, 0.65, 0)
    button.Text = "✓ Activate"
    button.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    
    local submitted = false
    
    button.MouseButton1Click:Connect(function()
        inputKey = textBox.Text
        submitted = true
        dialog:Destroy()
    end)
    
    repeat task.wait() until submitted
    
    -- Загрузка ключей
    local keyList = nil
    for attempt = 1, 5 do
        local success, res = pcall(function()
            return game:HttpGet(KEY_URL)
        end)
        if success then
            keyList = res
            break
        end
        task.wait(2)
    end
    
    if not keyList then
        Player:Kick("Failed to load keys. Check your internet connection.")
        return
    end
    
    local isValid = false
    for line in keyList:gmatch("[^\r\n]+") do
        if line == inputKey then
            isValid = true
            break
        end
    end
    
    if not isValid then
        Player:Kick("Invalid Key!")
        return
    end
    
    SaveKeyInfo(inputKey)
    Log("Key activated successfully")
end

-- Проверка HWID и ключа
local currentHWID = GetHWID()
local savedHWID = LoadHWID()

if savedHWID and savedHWID ~= currentHWID then
    Log("HWID changed, resetting activation")
    ResetHWID()
    ClearKeyInfo()
    savedHWID = nil
end

if not savedHWID then
    CheckKey()
    if not IsKeyValid() then
        Player:Kick("Key expired (30 days). Purchase a new key.")
    end
    SaveHWID(currentHWID)
    Log("HWID activated")
else
    if not IsKeyValid() then
        ResetHWID()
        ClearKeyInfo()
        Player:Kick("Key expired (30 days). Restart with a new key.")
    end
end

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SameHub"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 220)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(80, 80, 150)
stroke.Thickness = 2

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleLabel.Text = "⚡ SameHub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner", titleLabel)
titleCorner.CornerRadius = UDim.new(0, 10)

-- Драг функционал
local dragging = false
local dragStart, frameStart

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

-- Статус лейблы
local function CreateLabel(yPos, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = mainFrame
    return label
end

local statusLabel = CreateLabel(50, "Status: Starting...")
local itemsLabel = CreateLabel(75, "Items: 0")
local daysLabel = CreateLabel(100, "Days left: " .. GetDaysLeft())
local moneyLabel = CreateLabel(125, "Money: $0")
local luckyLabel = CreateLabel(150, "Lucky Arrows: 0")

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(1, -20, 0, 18)
hwidLabel.Position = UDim2.new(0, 10, 0, 180)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Text = "HWID: " .. string.sub(currentHWID, 1, 20) .. "..."
hwidLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
hwidLabel.Font = Enum.Font.Gotham
hwidLabel.TextSize = 10
hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
hwidLabel.Parent = mainFrame

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function GetCharacter(Part)
    local char = Player.Character
    if char then
        if not Part then
            return char
        elseif typeof(Part) == "string" then
            return char:FindFirstChild(Part)
        end
    end
    return nil
end

local function TeleportTo(Position)
    local HumanoidRootPart = GetCharacter("HumanoidRootPart")
    if HumanoidRootPart and typeof(Position) == "CFrame" then
        HumanoidRootPart.CFrame = Position
    end
end

local noclipActive = false

RunService.Stepped:Connect(function()
    if noclipActive then
        local Char = GetCharacter()
        if Char then
            for _, Child in pairs(Char:GetDescendants()) do
                if Child:IsA("BasePart") then
                    Child.CanCollide = false
                end
            end
        end
    end
end)

local function SetNoclip(Value)
    noclipActive = Value
    if not Value then
        local Char = GetCharacter()
        if Char then
            for _, Child in pairs(Char:GetDescendants()) do
                if Child:IsA("BasePart") and Child.Name ~= "HumanoidRootPart" then
                    Child.CanCollide = true
                end
            end
        end
    end
end

local function CountLuckyArrows()
    local count = 0
    
    if Player.Backpack then
        for _, Tool in ipairs(Player.Backpack:GetChildren()) do
            if Tool.Name == "Lucky Arrow" then
                count = count + 1
            end
        end
    end
    
    local char = Player.Character
    if char then
        for _, Tool in ipairs(char:GetChildren()) do
            if Tool:IsA("Tool") and Tool.Name == "Lucky Arrow" then
                count = count + 1
            end
        end
    end
    
    return count
end

local function GetMoney()
    local stats = Player:FindFirstChild("PlayerStats")
    if stats then
        local money = stats:FindFirstChild("Money")
        if money then
            return money.Value
        end
    end
    return 0
end

-- ========== ДИНАМИЧЕСКАЯ ПАПКА ПРЕДМЕТОВ ==========
local function GetItemsContainer()
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if itemSpawns then
        return itemSpawns:FindFirstChild("Items")
    end
    return nil
end

-- ========== ОБНАРУЖЕНИЕ ПРЕДМЕТОВ ==========
local function GetItemInfo(Model)
    if Model and Model:IsA("Model") and Model.Parent and Model.Parent.Name == "Items" then
        local PrimaryPart = Model.PrimaryPart
        if not PrimaryPart then
            -- Попробуем найти первую BasePart
            for _, child in pairs(Model:GetChildren()) do
                if child:IsA("BasePart") then
                    PrimaryPart = child
                    break
                end
            end
        end
        
        if not PrimaryPart then return nil end
        
        local Position = PrimaryPart.Position
        local ProximityPrompt = nil
        
        for _, ItemInstance in pairs(Model:GetDescendants()) do
            if ItemInstance:IsA("ProximityPrompt") and ItemInstance.MaxActivationDistance ~= 0 then
                ProximityPrompt = ItemInstance
                break
            end
        end
        
        if ProximityPrompt then
            return {
                Name = ProximityPrompt.ObjectText or Model.Name,
                ProximityPrompt = ProximityPrompt,
                Position = Position,
                Model = Model
            }
        end
    end
    return nil
end

getgenv().SpawnedItems = {}
local itemsCollected = 0
local lastItemTime = tick()

local function RefreshItemList()
    local container = GetItemsContainer()
    if container then
        -- Очищаем старые/несуществующие предметы
        for model, _ in pairs(getgenv().SpawnedItems) do
            if not model.Parent then
                getgenv().SpawnedItems[model] = nil
            end
        end
        
        -- Добавляем новые
        for _, model in pairs(container:GetChildren()) do
            if not getgenv().SpawnedItems[model] then
                local info = GetItemInfo(model)
                if info then
                    getgenv().SpawnedItems[model] = info
                    lastItemTime = tick()
                end
            end
        end
    end
end

local function OnItemAdded(Model)
    task.delay(0.3, function()
        local info = GetItemInfo(Model)
        if info then
            getgenv().SpawnedItems[Model] = info
            lastItemTime = tick()
        end
    end)
end

-- Подключение к папке Items
task.spawn(function()
    while true do
        local container = GetItemsContainer()
        if container then
            container.ChildAdded:Connect(OnItemAdded)
            Log("Connected to Items folder")
            break
        end
        task.wait(1)
    end
end)

-- Периодическое обновление списка
task.spawn(function()
    while true do
        RefreshItemList()
        task.wait(CONFIG.ITEM_REFRESH_INTERVAL)
    end
end)

-- ========== SERVER HOP ==========
local lastHopTime = 0
local isHopping = false

local function GetAvailableServers()
    local servers = {}
    
    local success, result = pcall(function()
        local url = string.format(
            "[games.roblox.com](https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100)",
            game.PlaceId
        )
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing and server.maxPlayers and server.id then
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, {
                        id = server.id,
                        players = server.playing,
                        maxPlayers = server.maxPlayers
                    })
                end
            end
        end
    end
    
    return servers
end

local function ServerHop()
    if isHopping then return false end
    if tick() - lastHopTime < CONFIG.SERVERHOP_COOLDOWN then return false end
    
    isHopping = true
    lastHopTime = tick()
    statusLabel.Text = "Status: Server Hopping..."
    Log("Initiating server hop")
    
    local servers = GetAvailableServers()
    
    if #servers > 0 then
        -- Сортируем по количеству игроков (меньше = лучше для фарма)
        table.sort(servers, function(a, b)
            return a.players < b.players
        end)
        
        -- Берём случайный из топ-10 серверов с наименьшим количеством игроков
        local maxIndex = math.min(10, #servers)
        local selectedServer = servers[math.random(1, maxIndex)]
        
        Log(string.format("Hopping to server with %d/%d players", selectedServer.players, selectedServer.maxPlayers))
        
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedServer.id)
        end)
        
        if not success then
            Log("Teleport failed: " .. tostring(err), "ERROR")
            isHopping = false
            return false
        end
        
        return true
    else
        Log("No available servers found, using fallback", "WARN")
        
        -- Фоллбэк
        pcall(function()
            TeleportService:Teleport(game.PlaceId, Player)
        end)
        
        isHopping = false
        return false
    end
end

-- Логика ServerHop: если нет предметов для фарма
task.spawn(function()
    task.wait(10) -- Даём время на загрузку
    
    while true do
        task.wait(1)
        
        if not Settings.ServerHopEnabled then continue end
        if isHopping then continue end
        
        local container = GetItemsContainer()
        local itemCount = 0
        
        if container then
            itemCount = #container:GetChildren()
        end
        
        -- Обновляем GUI
        itemsLabel.Text = "Items: " .. itemCount
        
        -- Проверяем нужен ли хоп
        local timeSinceLastItem = tick() - lastItemTime
        
        if itemCount == 0 and timeSinceLastItem >= CONFIG.SERVERHOP_DELAY then
            Log(string.format("No items for %.1f seconds, hopping", timeSinceLastItem))
            ServerHop()
            task.wait(10)
            lastItemTime = tick()
        end
    end
end)

-- ========== БАЙПАСЫ ==========
pcall(function()
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    if Modules then
        local FunctionLibrary = Modules:FindFirstChild("FunctionLibrary")
        if FunctionLibrary then
            local FL = require(FunctionLibrary)
            local OldPcall = FL.pcall
            FL.pcall = function(...)
                local f = ...
                if type(f) == "function" then
                    local upvals = getupvalues(f)
                    if upvals and #upvals == 11 then
                        return
                    end
                end
                return OldPcall(...)
            end
        end
    end
end)

-- Обработка ошибок и кика
CoreGui.DescendantAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        task.spawn(function()
            local GrabError = child:FindFirstChild("ErrorMessage", true)
            if GrabError then
                repeat task.wait() until GrabError.Text ~= "Label"
                local Reason = GrabError.Text:lower()
                
                if Reason:match("kick") or Reason:match("you") or Reason:match("conn") or Reason:match("rejoin") then
                    Log("Error detected, reconnecting: " .. GrabError.Text)
                    if Settings.AutoReconnect then
                        TeleportService:Teleport(game.PlaceId, Player)
                    end
                end
            end
        end)
    end
end)

-- Magnitude bypass
pcall(function()
    local oldMagnitude
    oldMagnitude = hookmetamethod(Vector3.new(), "__index", newcclosure(function(self, index)
        local CallingScript = tostring(getcallingscript())
        if not checkcaller() and index == "magnitude" and CallingScript == "ItemSpawn" then
            return 0
        end
        return oldMagnitude(self, index)
    end))
end)

-- Namecall bypass
pcall(function()
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local Args = {...}
        if not checkcaller() and self.Name == "Returner" and Args[1] == "idklolbrah2de" then
            return " ___XP DE KEY"
        end
        return oldNc(self, ...)
    end))
end)

-- ========== АНТИ-AFK ==========
local VirtualUser = game:GetService("VirtualUser")

Player.Idled:Connect(function()
    Log("Anti-AFK triggered")
    pcall(function()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Дополнительный анти-АФК
task.spawn(function()
    while true do
        task.wait(60)
        pcall(function()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ========== АВТО-РЕКОННЕКТ ==========
local function SetupAutoReconnect()
    local bindable = Instance.new("BindableEvent")
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("ResetButtonCallback", bindable)
    end)
    
    bindable.Event:Connect(function()
        if Settings.AutoReconnect then
            Log("Reset button pressed, reconnecting")
            TeleportService:Teleport(game.PlaceId, Player)
        end
    end)
end

task.spawn(SetupAutoReconnect)

-- ========== ОБНОВЛЕНИЕ GUI ==========
local function UpdateGUI()
    pcall(function()
        daysLabel.Text = "Days left: " .. GetDaysLeft()
        moneyLabel.Text = "Money: $" .. tostring(GetMoney())
        luckyLabel.Text = "Lucky Arrows: " .. CountLuckyArrows()
        
        local container = GetItemsContainer()
        if container then
            itemsLabel.Text = "Items: " .. #container:GetChildren()
        end
    end)
end

task.spawn(function()
    while true do
        UpdateGUI()
        task.wait(2)
    end
end)

-- ========== СКИП GUI (мягкий) ==========
task.delay(2, function()
    pcall(function()
        local guisToRemove = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        
        for _, name in pairs(guisToRemove) do
            local s = PlayerGui:FindFirstChild(name)
            if s then s:Destroy() end
        end
        
        local wsLoading = workspace:FindFirstChild("LoadingScreen")
        if wsLoading then wsLoading:Destroy() end
    end)
end)

-- ========== ЗАПУСК ФАРМА ==========
local SAFE_POSITION = CFrame.new(978, -42, -49)

repeat task.wait() until GetCharacter() and GetCharacter("RemoteEvent")

pcall(function()
    GetCharacter("RemoteEvent"):FireServer("PressedPlay")
end)

TeleportTo(SAFE_POSITION)
Log("Started farming")
statusLabel.Text = "Status: Farming"

task.wait(1)

-- Респавн в безопасную точку
Player.CharacterAdded:Connect(function(Char)
    task.wait(0.2)
    pcall(function()
        local hrp = Char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            hrp.CFrame = SAFE_POSITION
            Log("Respawned to safe spot")
        end
    end)
end)

-- ========== ПРОДАЖА ПРЕДМЕТОВ ==========
local function SellItem(itemName)
    if not Settings.AutoSell then return end
    if not Settings.SellItems[itemName] then return end
    
    local tool = Player.Backpack:FindFirstChild(itemName)
    if not tool then return end
    
    pcall(function()
        local humanoid = GetCharacter("Humanoid")
        local remoteEvent = GetCharacter("RemoteEvent")
        
        if humanoid and remoteEvent then
            humanoid:EquipTool(tool)
            task.wait(0.05)
            
            remoteEvent:FireServer("EndDialogue", {
                NPC = "Merchant",
                Dialogue = "Dialogue5",
                Option = "Option2"
            })
            
            Log("Sold: " .. itemName)
        end
    end)
end

-- Автопродажа при получении предмета
if Player.Backpack then
    Player.Backpack.ChildAdded:Connect(function(tool)
        task.wait(0.1)
        if tool:IsA("Tool") and Settings.SellItems[tool.Name] then
            SellItem(tool.Name)
        end
    end)
end

-- ========== ПОКУПКА LUCKY ARROW ==========
local function BuyLuckyArrows()
    if not Settings.BuyLucky then return end
    
    local money = GetMoney()
    local currentArrows = CountLuckyArrows()
    
    if currentArrows >= CONFIG.LUCKY_ARROW_MAX then return end
    if money < CONFIG.LUCKY_ARROW_PRICE then return end
    
    local remoteEvent = GetCharacter("RemoteEvent")
    if not remoteEvent then return end
    
    local attempts = 0
    while money >= CONFIG.LUCKY_ARROW_PRICE and attempts < 15 and CountLuckyArrows() < CONFIG.LUCKY_ARROW_MAX do
        pcall(function()
            remoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
        end)
        
        task.wait(1)
        money = GetMoney()
        attempts = attempts + 1
    end
    
    if attempts > 0 then
        Log("Bought Lucky Arrows, attempts: " .. attempts)
    end
end

-- ========== ОСНОВНОЙ ЦИКЛ ФАРМА ==========
while true do
    -- Собираем все предметы
    for Model, ItemInfo in pairs(getgenv().SpawnedItems) do
        -- Проверяем что предмет ещё существует
        if not Model.Parent then
            getgenv().SpawnedItems[Model] = nil
            continue
        end
        
        local HumanoidRootPart = GetCharacter("HumanoidRootPart")
        if not HumanoidRootPart then
            task.wait(1)
            continue
        end
        
        statusLabel.Text = "Status: Collecting " .. (ItemInfo.Name or "item")
        
        local ProximityPrompt = ItemInfo.ProximityPrompt
        local Position = ItemInfo.Position
        
        -- Удаляем из списка сразу
        getgenv().SpawnedItems[Model] = nil
        lastItemTime = tick()
        
        -- Создаём BodyVelocity для стабильности
        local BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        BodyVelocity.Parent = HumanoidRootPart
        
        SetNoclip(true)
        
        -- Телепорт к предмету (под землю чтобы не видели)
        TeleportTo(CFrame.new(Position.X, Position.Y - 25, Position.Z))
        task.wait(0.3)
        
        -- Подбираем
        pcall(function()
            fireproximityprompt(ProximityPrompt)
        end)
        
        task.wait(0.3)
        
        -- Возвращаемся
        BodyVelocity:Destroy()
        TeleportTo(SAFE_POSITION)
        task.wait(CONFIG.TELEPORT_WAIT)
        
        SetNoclip(false)
        
        itemsCollected = itemsCollected + 1
        statusLabel.Text = "Status: Farming"
    end
    
    task.wait(CONFIG.FARM_LOOP_DELAY)
    
    -- Продажа предметов
    if Settings.AutoSell then
        for Item, ShouldSell in pairs(Settings.SellItems) do
            if ShouldSell and Player.Backpack and Player.Backpack:FindFirstChild(Item) then
                SellItem(Item)
                task.wait(CONFIG.SELL_DELAY)
            end
        end
    end
    
    -- Покупка Lucky Arrow
    BuyLuckyArrows()
    
    -- Обновляем GUI
    UpdateGUI()
    
    task.wait(1)
end
