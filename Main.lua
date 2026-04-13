-- Ожидание загрузки и базовые настройки
repeat task.wait(0.5) until game:IsLoaded()

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

-- Лимиты инвентаря [cite: 17, 801]
local MaxItemAmounts = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10, ["Mysterious Arrow"] = 25,
    ["Diamond"] = 30, ["Ancient Scroll"] = 10, ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 10, ["Quinton's Glove"] = 10, ["Zeppeli's Hat"] = 10,
    ["Lucky Arrow"] = 10, ["Clackers"] = 10, ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Проверка X2 инвентаря [cite: 17, 800]
if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778) then
    for i, v in pairs(MaxItemAmounts) do MaxItemAmounts[i] = v * 2 end
end

-- Полный скип GUI и авто-нажатие Play [cite: 596]
task.spawn(function()
    pcall(function()
        local loadingGuis = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, name in pairs(loadingGuis) do
            local gui = PlayerGui:FindFirstChild(name)
            if gui then gui:Destroy() end
        end
        local blur = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
        if blur then blur:Destroy() end
        
        local event = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RemoteEvent")
        if event then event:FireServer("PressedPlay") end
    end)
end)

-- Анти-чит байпас [cite: 596]
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

-- Вспомогательные функции
local function GetCharacter() return Player.Character or Player.CharacterAdded:Wait() end

local function HasMaxItem(ItemName)
    local count = 0
    for _, tool in pairs(Player.Backpack:GetChildren()) do
        if tool.Name == ItemName then count = count + 1 end
    end
    if GetCharacter():FindFirstChild(ItemName) then count = count + 1 end
    return count >= (MaxItemAmounts[ItemName] or 99)
end

-- Логика сбора и фарма [cite: 1, 783]
local ItemSpawnFolder = workspace:WaitForChild("Item_Spawns", 20):WaitForChild("Items", 20)
local ServerHop = loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))

while true do
    local items = ItemSpawnFolder:GetChildren()
    for _, item in pairs(items) do
        if item:IsA("Model") and item.PrimaryPart then
            local prompt = item:FindFirstChildOfClass("ProximityPrompt")
            if prompt and not HasMaxItem(prompt.ObjectText) then
                local char = GetCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = item.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                end
            end
        end
    end

    -- Продажа предметов торговцу [cite: 595, 637]
    if AutoSell then
        pcall(function()
            local remote = GetCharacter():FindFirstChild("RemoteEvent")
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    GetCharacter().Humanoid:EquipTool(tool)
                    remote:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.1)
                end
            end
        end)
    end

    -- Покупка Lucky Arrow [cite: 637]
    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        local remote = GetCharacter():FindFirstChild("RemoteEvent")
        if remote then
            remote:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        end
    end

    task.wait(2)
    ServerHop()
    task.wait(10)
end
