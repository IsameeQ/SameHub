local KeysURL = "https://raw.githubusercontent.com/IsameeQ/SameHub/main/keys.txt"
local UserKey = _G.Key or ""

local function VerifyAccess()
    local s, result = pcall(function() return game:HttpGet(KeysURL) end)
    if s and result then
        for k in result:gmatch("[^%s]+") do
            if UserKey == k then return true end
        end
    end
    return false
end

if not VerifyAccess() then
    game:GetService("Players").LocalPlayer:Kick("Access Denied")
    return
end

repeat task.wait(0.1) until game:IsLoaded()

-- Конфиг
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

-- Лимиты X2
pcall(function()
    if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778) then
        for i, v in pairs(MaxItemAmounts) do MaxItemAmounts[i] = v * 2 end
    end
end)

-- Моментальный скип GUI
task.spawn(function()
    pcall(function()
        local guis = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, n in pairs(guis) do if PlayerGui:FindFirstChild(n) then PlayerGui[n]:Destroy() end end
        local blur = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
        if blur then blur:Destroy() end
        local event = ReplicatedStorage:FindFirstChild("RemoteEvent") or (ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteEvent"))
        if event then event:FireServer("PressedPlay") end
    end)
end)

-- Анти-чит
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

local function GetCharacter() return Player.Character or Player.CharacterAdded:Wait() end

local function HasMaxItem(name)
    local count = 0
    for _, t in pairs(Player.Backpack:GetChildren()) do if t.Name == name then count = count + 1 end end
    if GetCharacter():FindFirstChild(name) then count = count + 1 end
    return count >= (MaxItemAmounts[name] or 99)
end

-- Загрузка ServerHop
local ServerHop = loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))

-- Ждем персонажа
repeat task.wait(0.5) until GetCharacter():FindFirstChild("RemoteEvent")
task.wait(1)

-- Основной цикл
while true do
    local ItemSpawnFolder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
    local itemsFound = false

    if ItemSpawnFolder then
        local allItems = ItemSpawnFolder:GetChildren()
        
        for _, item in pairs(allItems) do
            if item:IsA("Model") and item.PrimaryPart then
                local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                local itemName = prompt and prompt.ObjectText or "Unknown"
                
                if not HasMaxItem(itemName) then
                    itemsFound = true
                    local hrp = GetCharacter():FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local bv = Instance.new("BodyVelocity", hrp)
                        bv.Velocity = Vector3.new(0,0,0)
                        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        
                        hrp.CFrame = item.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                        task.wait(0.3)
                        fireproximityprompt(prompt)
                        task.wait(0.2)
                        bv:Destroy()
                    end
                end
            end
        end
    end

    -- После сбора (или если их нет) — дополнительные действия
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

    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        local remote = GetCharacter():FindFirstChild("RemoteEvent")
        if remote then remote:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"}) end
    end

    -- СЕРВЕР ХОП: только если предметов больше нет
    task.wait(0.5)
    ServerHop() 
    task.wait(2) -- Защита от бесконечного цикла, если хоп не сработал сразу
end
