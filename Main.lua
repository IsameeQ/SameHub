repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ========== КОНФИГУРАЦИЯ ==========
local KEY_URL = "https://raw.githubusercontent.com/IsameeQ/SameHub/main/keys.txt"
local HWID_FILE = "SameHub_HWID.txt"
local KEY_INFO_FILE = "SameHub_KeyInfo.txt"
local RESET_LOG_FILE = "SameHub_ResetLog.txt"

-- ========== HWID ==========
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
    if isfile(HWID_FILE) then
        return readfile(HWID_FILE)
    end
    return nil
end

local function ResetHWID()
    if isfile(HWID_FILE) then
        delfile(HWID_FILE)
    end
end

-- ========== СБРОС HWID (1 раз в 24 часа) ==========
local function CanResetHWID()
    if not isfile(RESET_LOG_FILE) then return true end
    local lastReset = tonumber(readfile(RESET_LOG_FILE))
    if not lastReset then return true end
    return (os.time() - lastReset) >= 86400
end

local function LogReset()
    writefile(RESET_LOG_FILE, tostring(os.time()))
end

-- ========== КЛЮЧ + СРОК ДЕЙСТВИЯ 30 ДНЕЙ ==========
local function SaveKeyInfo(key)
    local data = { key = key, activated = os.time() }
    writefile(KEY_INFO_FILE, HttpService:JSONEncode(data))
end

local function LoadKeyInfo()
    if isfile(KEY_INFO_FILE) then
        local str = readfile(KEY_INFO_FILE)
        local success, data = pcall(HttpService.JSONDecode, HttpService, str)
        if success and data then return data end
    end
    return nil
end

local function IsKeyValid()
    local info = LoadKeyInfo()
    if not info then return false end
    return (os.time() - info.activated) <= 30 * 86400
end

local function ClearKeyInfo()
    if isfile(KEY_INFO_FILE) then delfile(KEY_INFO_FILE) end
end

-- ========== ПРОВЕРКА КЛЮЧА ==========
local function CheckKey()
    local inputKey = ""
    local dialog = Instance.new("ScreenGui")
    local frame = Instance.new("Frame")
    local textBox = Instance.new("TextBox")
    local button = Instance.new("TextButton")
    local title = Instance.new("TextLabel")
    dialog.Name = "KeyCheck"
    dialog.Parent = CoreGui
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BorderSizePixel = 0
    frame.Parent = dialog
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SameHub - Enter Key"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame
    textBox.Size = UDim2.new(0.8, 0, 0, 35)
    textBox.Position = UDim2.new(0.1, 0, 0.35, 0)
    textBox.PlaceholderText = "Your key"
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 14
    textBox.Parent = frame
    button.Size = UDim2.new(0.4, 0, 0, 35)
    button.Position = UDim2.new(0.3, 0, 0.7, 0)
    button.Text = "Activate"
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = frame
    local submitted = false
    button.MouseButton1Click:Connect(function()
        inputKey = textBox.Text
        submitted = true
        dialog:Destroy()
    end)
    repeat task.wait() until submitted
    local keyList = nil
    for attempt = 1, 5 do
        local success, res = pcall(game.HttpGet, game, KEY_URL)
        if success then
            keyList = res
            break
        end
        task.wait(2)
    end
    if not keyList then
        Player:Kick("Failed to load keys")
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
end

-- ========== ПРОВЕРКА HWID И КЛЮЧА ПРИ ЗАПУСКЕ ==========
local currentHWID = GetHWID()
local savedHWID = LoadHWID()

if savedHWID and savedHWID ~= currentHWID then
    Player:Kick("HWID mismatch!")
    error("HWID mismatch")
elseif not savedHWID then
    CheckKey()
    if not IsKeyValid() then
        Player:Kick("Key expired (30 days). Purchase a new key.")
        error("Key expired")
    end
    SaveHWID(currentHWID)
else
    if not IsKeyValid() then
        ResetHWID()
        ClearKeyInfo()
        Player:Kick("Key expired (30 days). Restart with a new key.")
        error("Key expired")
    end
end

-- ========== ОСНОВНЫЕ НАСТРОЙКИ ==========
local BuyLucky = true
local AutoSell = true
local SellItems = {
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

-- ========== GUI (простой, человеческий) ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SameHub"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 280)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SameHub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Farming"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size = UDim2.new(1, -20, 0, 25)
itemsLabel.Position = UDim2.new(0, 10, 0, 70)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Text = "Items: 0"
itemsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
itemsLabel.Font = Enum.Font.Gotham
itemsLabel.TextSize = 13
itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
itemsLabel.Parent = mainFrame

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(1, -20, 0, 25)
hwidLabel.Position = UDim2.new(0, 10, 0, 100)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Text = "HWID: " .. string.sub(currentHWID, 1, 16) .. "..."
hwidLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
hwidLabel.Font = Enum.Font.Gotham
hwidLabel.TextSize = 11
hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
hwidLabel.Parent = mainFrame

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.8, 0, 0, 30)
resetButton.Position = UDim2.new(0.1, 0, 0, 140)
resetButton.Text = "Reset HWID"
resetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 13
resetButton.Parent = mainFrame
resetButton.MouseButton1Click:Connect(function()
    if not CanResetHWID() then
        statusLabel.Text = "Status: Reset only once per 24h"
        task.wait(2)
        statusLabel.Text = "Status: Farming"
        return
    end
    ResetHWID()
    ClearKeyInfo()
    LogReset()
    Player:Kick("HWID reset. Restart script with a key.")
end)

local function UpdateGUI()
    pcall(function()
        local count = 0
        for _, tool in pairs(Player.Backpack:GetChildren()) do
            if SellItems[tool.Name] then
                count = count + 1
            end
        end
        itemsLabel.Text = "Items to sell: " .. count
    end)
end
task.spawn(function()
    while true do
        UpdateGUI()
        task.wait(2)
    end
end)

-- ========== БАЙПАСЫ ==========
pcall(function()
    local FunctionLibrary = require(ReplicatedStorage:WaitForChild("Modules").FunctionLibrary)
    local OldPcall = FunctionLibrary.pcall
    FunctionLibrary.pcall = function(...)
        local f = ...
        if type(f) == "function" and #getupvalues(f) == 11 then return end
        return OldPcall(...)
    end
end)

CoreGui.DescendantAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        local GrabError = child:FindFirstChild("ErrorMessage", true)
        repeat task.wait() until GrabError.Text ~= "Label"
        local Reason = GrabError.Text
        if Reason:match("kick") or Reason:match("You") or Reason:match("conn") or Reason:match("rejoin") then
            TeleportService:Teleport(2809202155, Player)
        end
    end
end)

local Has2x = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778)

local oldMagnitude
pcall(function()
    oldMagnitude = hookmetamethod(Vector3.new(), "__index", newcclosure(function(self, index)
        local CallingScript = tostring(getcallingscript())
        if not checkcaller() and index == "magnitude" and CallingScript == "ItemSpawn" then
            return 0
        end
        return oldMagnitude(self, index)
    end))
end)

local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

-- ========== ПАПКА ПРЕДМЕТОВ ==========
local ItemSpawnFolder
pcall(function()
    ItemSpawnFolder = Workspace:WaitForChild("Item_Spawns", 10):WaitForChild("Items", 10)
end)
if not ItemSpawnFolder then
    task.wait(5)
    ItemSpawnFolder = Workspace:FindFirstChild("Item_Spawns")
    if ItemSpawnFolder then ItemSpawnFolder = ItemSpawnFolder:FindFirstChild("Items") end
end

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function GetCharacter(Part)
    if Player.Character then
        if not Part then return Player.Character
        elseif typeof(Part) == "string" then return Player.Character:FindFirstChild(Part) end
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
    if not noclipActive then return end
    local Char = GetCharacter()
    if not Char then return end
    for _, Child in pairs(Char:GetDescendants()) do
        if Child:IsA("BasePart") then Child.CanCollide = false end
    end
end)

local function SetNoclip(Value)
    noclipActive = Value
    if Value then return end
    local Char = GetCharacter()
    if not Char then return end
    for _, Child in pairs(Char:GetDescendants()) do
        if Child:IsA("BasePart") then Child.CanCollide = true end
    end
end

local MaxItemAmounts = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10,
    ["Mysterious Arrow"] = 25, ["Diamond"] = 30, ["Ancient Scroll"] = 10,
    ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 20, ["Quinton's Glove"] = 10,
    ["Zeppeli's Hat"] = 10, ["Lucky Arrow"] = 10, ["Clackers"] = 10,
    ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}
if Has2x then
    for k, v in pairs(MaxItemAmounts) do MaxItemAmounts[k] = v * 2 end
end

local function HasMaxItem(Item)
    local Count = 0
    for _, Tool in pairs(Player.Backpack:GetChildren()) do
        if Tool.Name == Item then Count += 1 end
    end
    return MaxItemAmounts[Item] and Count >= MaxItemAmounts[Item] or false
end

local function CountLuckyArrows()
    local count = 0
    for _, Tool in ipairs(Player.Backpack:GetChildren()) do
        if Tool.Name == "Lucky Arrow" then count += 1 end
    end
    if Player.Character then
        for _, Tool in ipairs(Player.Character:GetChildren()) do
            if Tool:IsA("Tool") and Tool.Name == "Lucky Arrow" then count += 1 end
        end
    end
    return count
end

local function HasLuckyArrows() return CountLuckyArrows() >= 10 end
local function IsMoneyMaxed() return Player.PlayerStats.Money.Value >= 1000000 end

local function AllKeepItemsFull()
    for Item, Sell in pairs(SellItems) do
        if not Sell and Item ~= "Lucky Arrow" then
            if not HasMaxItem(Item) then return false end
        end
    end
    return true
end

local function ShouldStopFarming()
    if AllKeepItemsFull() then return true end
    if HasLuckyArrows() and IsMoneyMaxed() then return true end
    return false
end

-- ========== СЕРВЕР-ХОП (рабочий) ==========
local function ServerHop()
    local servers = {}
    local res = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    local data = HttpService:JSONDecode(res)
    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))()
    end
end

-- ========== ОБНАРУЖЕНИЕ ПРЕДМЕТОВ ==========
local function GetItemInfo(Model)
    if Model and Model:IsA("Model") and Model.Parent and Model.Parent.Name == "Items" then
        local PrimaryPart = Model.PrimaryPart
        local Position = PrimaryPart.Position
        local ProximityPrompt
        for _, ItemInstance in pairs(Model:GetChildren()) do
            if ItemInstance:IsA("ProximityPrompt") and ItemInstance.MaxActivationDistance ~= 0 then
                ProximityPrompt = ItemInstance
            end
        end
        if ProximityPrompt then
            return { Name = ProximityPrompt.ObjectText, ProximityPrompt = ProximityPrompt, Position = Position }
        end
    end
    return nil
end

getgenv().SpawnedItems = {}
if ItemSpawnFolder then
    ItemSpawnFolder.ChildAdded:Connect(function(Model)
        task.wait(1)
        if Model:IsA("Model") then
            local ItemInfo = GetItemInfo(Model)
            if ItemInfo then
                getgenv().SpawnedItems[Model] = ItemInfo
            end
        end
    end)
end

-- ========== СКИП GUI И ЗАГРУЗКИ ==========
task.wait(1)
if not PlayerGui:FindFirstChild("HUD") then
    local HUD = ReplicatedStorage.Objects.HUD:Clone()
    HUD.Parent = PlayerGui
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local screens = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
            for _, name in pairs(screens) do
                local screen = PlayerGui:FindFirstChild(name)
                if screen then screen:Destroy() end
            end
            if workspace:FindFirstChild("LoadingScreen") then
                workspace.LoadingScreen:Destroy()
            end
            if workspace:FindFirstChild("LoadingScreen") and workspace.LoadingScreen:FindFirstChild("Song") then
                workspace.LoadingScreen.Song:Destroy()
            end
        end)
    end
end)

repeat task.wait() until GetCharacter() and GetCharacter("RemoteEvent")
GetCharacter("RemoteEvent"):FireServer("PressedPlay")
TeleportTo(CFrame.new(978, -42, -49))
task.wait(1)

task.spawn(function()
    Player.CharacterAdded:Connect(function(Char)
        task.wait(0.15)
        pcall(function()
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                Char.HumanoidRootPart.CFrame = CFrame.new(978, -42, -49)
            end
        end)
    end)
end)

-- ========== УДАЛЕНИЕ ТЕКСТУР ==========
task.spawn(function()
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(workspace.IgnoreInstances) then
                if v.Name ~= "HumanoidRootPart" and not v:IsDescendantOf(Player.Character) then
                    v.Material = Enum.Material.Plastic
                    v.TextureID = ""
                    v.Color = Color3.new(0.5, 0.5, 0.5)
                end
            end
        end
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            for _, child in pairs(mapFolder:GetChildren()) do
                if child:IsA("BasePart") then
                    child.Transparency = 1
                    child.CanCollide = false
                end
            end
        end
    end)
end)

task.wait(5)

-- ========== ОСНОВНОЙ ЦИКЛ С ТАЙМЕРОМ ХОПА ==========
local lastItemTime = tick()
local NO_ITEMS_TIMEOUT = 20
local cycleStartTime = tick()
local maxCycleTime = 60

local function SellItemNow(itemName)
    if AutoSell and SellItems[itemName] then
        local tool = Player.Backpack:FindFirstChild(itemName)
        if tool then
            pcall(function()
                GetCharacter("Humanoid"):EquipTool(tool)
                task.wait(0.05)
                GetCharacter("RemoteEvent"):FireServer("EndDialogue", {
                    NPC = "Merchant",
                    Dialogue = "Dialogue5",
                    Option = "Option2"
                })
                task.wait(0.05)
            end)
        end
    end
end

Player.Backpack.ChildAdded:Connect(function(tool)
    task.wait(0.1)
    if tool:IsA("Tool") and SellItems[tool.Name] then
        SellItemNow(tool.Name)
    end
end)

while true do
    if ShouldStopFarming() then
        statusLabel.Text = "Status: Waiting (max)"
        repeat task.wait(5) until not ShouldStopFarming()
        statusLabel.Text = "Status: Farming"
        lastItemTime = tick()
        cycleStartTime = tick()
    end

    local collected = false
    for Index, ItemInfo in pairs(getgenv().SpawnedItems) do
        local HumanoidRootPart = GetCharacter("HumanoidRootPart")
        if HumanoidRootPart then
            if not HasMaxItem(ItemInfo.Name) then
                collected = true
                lastItemTime = tick()
                local ProximityPrompt = ItemInfo.ProximityPrompt
                local Position = ItemInfo.Position
                getgenv().SpawnedItems[Index] = nil
                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.Parent = HumanoidRootPart
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                SetNoclip(true)
                TeleportTo(CFrame.new(Position.X, Position.Y - 25, Position.Z))
                task.wait(0.5)
                fireproximityprompt(ProximityPrompt)
                task.wait(0.5)
                BodyVelocity:Destroy()
                TeleportTo(CFrame.new(978, -42, -49))
                task.wait(0.3)
                SetNoclip(false)
            else
                getgenv().SpawnedItems[Index] = nil
            end
        end
    end

    task.wait(3)

    -- ХОП если 20 секунд нет предметов ИЛИ если цикл длится больше 60 секунд
    if (tick() - lastItemTime > NO_ITEMS_TIMEOUT) or (tick() - cycleStartTime > maxCycleTime) then
        statusLabel.Text = "Status: No items, hopping"
        ServerHop()
        task.wait(10)
        lastItemTime = tick()
        cycleStartTime = tick()
        statusLabel.Text = "Status: Farming"
    end

    -- Автоселл (оставшиеся)
    if AutoSell then
        for Item, Sell in pairs(SellItems) do
            if Sell and Player.Backpack and Player.Backpack:FindFirstChild(Item) then
                GetCharacter("Humanoid"):EquipTool(Player.Backpack:FindFirstChild(Item))
                GetCharacter("RemoteEvent"):FireServer("EndDialogue", {
                    NPC = "Merchant",
                    Dialogue = "Dialogue5",
                    Option = "Option2"
                })
                task.wait(0.1)
            end
        end
    end

    -- Покупка Lucky Arrows
    local Money = Player.PlayerStats.Money
    if BuyLucky and not HasLuckyArrows() then
        local attempts = 0
        while Money.Value >= 75000 and attempts < 15 do
            Player.Character.RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
            task.wait(1)
            attempts = attempts + 1
            if CountLuckyArrows() >= 10 then break end
            if attempts > 3 and CountLuckyArrows() == 9 then break end
        end
    end

    UpdateGUI()
    task.wait(2)
end
