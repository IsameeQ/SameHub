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

-- ========== ПРОВЕРКА ПАПКИ ПРЕДМЕТОВ (с диагностикой) ==========
local function EnsureItemFolders()
    local itemSpawns = workspace:FindFirstChild("Item_Spawns")
    if not itemSpawns then
        print("[SameHub] Creating Item_Spawns folder")
        itemSpawns = Instance.new("Folder", workspace)
        itemSpawns.Name = "Item_Spawns"
    end
    local itemsFolder = itemSpawns:FindFirstChild("Items")
    if not itemsFolder then
        print("[SameHub] Creating Items folder")
        itemsFolder = Instance.new("Folder", itemSpawns)
        itemsFolder.Name = "Items"
    end
    return itemsFolder
end

local ItemsFolder = EnsureItemFolders()
print("[SameHub] Items folder found/created at:", ItemsFolder:GetFullName())

-- ========== HWID И КЛЮЧ (сокращённо, без изменений) ==========
local KEY_URL = "https://raw.githubusercontent.com/IsameeQ/SameHub/main/keys.txt"
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

local function SaveHWID(hwid) writefile(HWID_FILE, hwid) end
local function LoadHWID() return isfile(HWID_FILE) and readfile(HWID_FILE) or nil end
local function ResetHWID() if isfile(HWID_FILE) then delfile(HWID_FILE) end end
local function CanResetHWID()
    if not isfile(RESET_LOG_FILE) then return true end
    local lastReset = tonumber(readfile(RESET_LOG_FILE))
    return not lastReset or (os.time() - lastReset) >= 86400
end
local function LogReset() writefile(RESET_LOG_FILE, tostring(os.time())) end

local function SaveKeyInfo(key)
    writefile(KEY_INFO_FILE, HttpService:JSONEncode({ key = key, activated = os.time() }))
end
local function LoadKeyInfo()
    if isfile(KEY_INFO_FILE) then
        local success, data = pcall(HttpService.JSONDecode, HttpService, readfile(KEY_INFO_FILE))
        if success and data then return data end
    end
    return nil
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
local function ClearKeyInfo() if isfile(KEY_INFO_FILE) then delfile(KEY_INFO_FILE) end end

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
        if success then keyList = res; break end
        task.wait(2)
    end
    if not keyList then Player:Kick("Failed to load keys") return end
    local isValid = false
    for line in keyList:gmatch("[^\r\n]+") do
        if line == inputKey then isValid = true; break end
    end
    if not isValid then Player:Kick("Invalid Key!") return end
    SaveKeyInfo(inputKey)
end

local currentHWID = GetHWID()
local savedHWID = LoadHWID()

if savedHWID and savedHWID ~= currentHWID then
    Player:Kick("HWID mismatch!")
elseif not savedHWID then
    CheckKey()
    if not IsKeyValid() then Player:Kick("Key expired (30 days).") end
    SaveHWID(currentHWID)
else
    if not IsKeyValid() then
        ResetHWID()
        ClearKeyInfo()
        Player:Kick("Key expired. Restart with new key.")
    end
end

-- ========== НАСТРОЙКИ ==========
local BuyLucky = true
local AutoSell = true
local SellItems = {
    ["Gold Coin"] = true, ["Rokakaka"] = true, ["Pure Rokakaka"] = true,
    ["Mysterious Arrow"] = true, ["Diamond"] = true, ["Ancient Scroll"] = true,
    ["Caesar's Headband"] = true, ["Stone Mask"] = true,
    ["Rib Cage of The Saint's Corpse"] = true, ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true, ["Lucky Arrow"] = false, ["Clackers"] = true,
    ["Steel Ball"] = true, ["Dio's Diary"] = true
}

-- ========== GUI (минимальное, без лишнего) ==========
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

local dragging = false
local dragStart, frameStart
titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

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

local daysLabel = Instance.new("TextLabel")
daysLabel.Size = UDim2.new(1, -20, 0, 25)
daysLabel.Position = UDim2.new(0, 10, 0, 100)
daysLabel.BackgroundTransparency = 1
daysLabel.Text = "Days left: " .. GetDaysLeft()
daysLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
daysLabel.Font = Enum.Font.Gotham
daysLabel.TextSize = 13
daysLabel.TextXAlignment = Enum.TextXAlignment.Left
daysLabel.Parent = mainFrame

local hwidLabel = Instance.new("TextLabel")
hwidLabel.Size = UDim2.new(1, -20, 0, 25)
hwidLabel.Position = UDim2.new(0, 10, 0, 130)
hwidLabel.BackgroundTransparency = 1
hwidLabel.Text = "HWID: " .. string.sub(currentHWID, 1, 16) .. "..."
hwidLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
hwidLabel.Font = Enum.Font.Gotham
hwidLabel.TextSize = 11
hwidLabel.TextXAlignment = Enum.TextXAlignment.Left
hwidLabel.Parent = mainFrame

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.8, 0, 0, 30)
resetButton.Position = UDim2.new(0.1, 0, 0, 170)
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
            if SellItems[tool.Name] then count = count + 1 end
        end
        itemsLabel.Text = "Items to sell: " .. count
        daysLabel.Text = "Days left: " .. GetDaysLeft()
    end)
end
task.spawn(function()
    while true do
        UpdateGUI()
        task.wait(2)
    end
end)

-- ========== БАЙПАСЫ (сжатые) ==========
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
pcall(function()
    oldMagnitude = hookmetamethod(Vector3.new(), "__index", newcclosure(function(self, index)
        local CallingScript = tostring(getcallingscript())
        if not checkcaller() and index == "magnitude" and CallingScript == "ItemSpawn" then return 0 end
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
    if noclipActive then
        local Char = GetCharacter()
        if Char then
            for _, Child in pairs(Char:GetDescendants()) do
                if Child:IsA("BasePart") then Child.CanCollide = false end
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
                if Child:IsA("BasePart") then Child.CanCollide = true end
            end
        end
    end
end

local function CountLuckyArrows()
    local count = 0
    for _, Tool in ipairs(Player.Backpack:GetChildren()) do
        if Tool.Name == "Lucky Arrow" then count = count + 1 end
    end
    if Player.Character then
        for _, Tool in ipairs(Player.Character:GetChildren()) do
            if Tool:IsA("Tool") and Tool.Name == "Lucky Arrow" then count = count + 1 end
        end
    end
    return count
end

-- ========== ОБНАРУЖЕНИЕ ПРЕДМЕТОВ (упрощённое, с принтами) ==========
local function GetItemInfo(Model)
    if Model and Model:IsA("Model") and Model.Parent and Model.Parent.Name == "Items" then
        local PrimaryPart = Model.PrimaryPart
        if not PrimaryPart then return nil end
        local Position = PrimaryPart.Position
        local ProximityPrompt = nil
        for _, ItemInstance in pairs(Model:GetChildren()) do
            if ItemInstance:IsA("ProximityPrompt") and ItemInstance.MaxActivationDistance ~= 0 then
                ProximityPrompt = ItemInstance
                break
            end
        end
        if ProximityPrompt then
            return { Name = ProximityPrompt.ObjectText, ProximityPrompt = ProximityPrompt, Position = Position }
        end
    end
    return nil
end

getgenv().SpawnedItems = {}

local function RefreshItemList()
    local folder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
    if folder then
        local newCount = 0
        for _, model in pairs(folder:GetChildren()) do
            if not getgenv().SpawnedItems[model] then
                local info = GetItemInfo(model)
                if info then
                    getgenv().SpawnedItems[model] = info
                    newCount = newCount + 1
                    print("[SameHub] Detected item:", info.Name, "at", info.Position)
                end
            end
        end
        if newCount > 0 then
            print("[SameHub] Total tracked items:", #getgenv().SpawnedItems)
        end
    else
        print("[SameHub] Items folder not found!")
    end
end

-- Наблюдатель за появлением новых предметов
local function OnItemAdded(Model)
    task.wait(0.5)
    if Model:IsA("Model") then
        local info = GetItemInfo(Model)
        if info then
            getgenv().SpawnedItems[Model] = info
            print("[SameHub] New item spawned:", info.Name)
        end
    end
end

task.spawn(function()
    while true do
        local folder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
        if folder then
            folder.ChildAdded:Connect(OnItemAdded)
            break
        end
        task.wait(2)
    end
end)

-- Периодическое обновление (раз в 5 секунд)
task.spawn(function()
    while true do
        RefreshItemList()
        task.wait(5)
    end
end)

-- ========== СЕРВЕР-ХОП (упрощённый, с диагностикой) ==========
local function ServerHop()
    print("[SameHub] ServerHop triggered!")
    local servers = {}
    local res = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    local data = HttpService:JSONDecode(res)
    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        print("[SameHub] Hopping to server:", servers[math.random(1, #servers)])
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
    else
        print("[SameHub] No servers found, using fallback hop")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))()
    end
end

-- Мониторинг предметов (каждую секунду)
task.spawn(function()
    local noItemTimer = 0
    while true do
        task.wait(1)
        local itemsFolder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
        if itemsFolder then
            local itemCount = #itemsFolder:GetChildren()
            if itemCount == 0 then
                noItemTimer = noItemTimer + 1
                if noItemTimer >= 3 then
                    print("[SameHub] No items for 3 seconds, hopping...")
                    statusLabel.Text = "Status: No items, hopping"
                    ServerHop()
                    task.wait(10)
                    noItemTimer = 0
                    statusLabel.Text = "Status: Farming"
                end
            else
                if noItemTimer > 0 then
                    print("[SameHub] Items found again, resetting timer")
                    noItemTimer = 0
                end
                if statusLabel.Text ~= "Status: Farming" then
                    statusLabel.Text = "Status: Farming"
                end
            end
        else
            print("[SameHub] Items folder missing, incrementing timer")
            noItemTimer = noItemTimer + 1
            if noItemTimer >= 3 then
                print("[SameHub] Items folder missing for 3 seconds, hopping...")
                statusLabel.Text = "Status: Items folder missing, hopping"
                ServerHop()
                task.wait(10)
                noItemTimer = 0
                statusLabel.Text = "Status: Farming"
            end
        end
    end
end)

-- ========== СКИП GUI ==========
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
print("[SameHub] Teleported to safe spot")
task.wait(1)

task.spawn(function()
    Player.CharacterAdded:Connect(function(Char)
        task.wait(0.15)
        pcall(function()
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                Char.HumanoidRootPart.CFrame = CFrame.new(978, -42, -49)
                print("[SameHub] Respawned to safe spot")
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

-- ========== ОСНОВНОЙ ЦИКЛ ФАРМА ==========
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
    -- Диагностика: сколько предметов в очереди
    local queueSize = 0
    for _ in pairs(getgenv().SpawnedItems) do queueSize = queueSize + 1 end
    if queueSize > 0 then
        print("[SameHub] Items in queue:", queueSize)
    end

    for Index, ItemInfo in pairs(getgenv().SpawnedItems) do
        local HumanoidRootPart = GetCharacter("HumanoidRootPart")
        if HumanoidRootPart then
            print("[SameHub] Collecting:", ItemInfo.Name)
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
        end
    end

    task.wait(3)

    -- Автоселл
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
    if BuyLucky and CountLuckyArrows() < 10 then
        local attempts = 0
        while Money.Value >= 75000 and attempts < 15 and CountLuckyArrows() < 10 do
            Player.Character.RemoteEvent:FireServer("PurchaseShopItem", { ItemName = "1x Lucky Arrow" })
            task.wait(1)
            attempts = attempts + 1
        end
    end

    UpdateGUI()
    task.wait(2)
end
