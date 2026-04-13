-- Вырезаны все названия. Чистая логика из исходников.
repeat task.wait() until game:IsLoaded()

-- Конфиг предметов из твоих файлов
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

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. МОМЕНТАЛЬНЫЙ СКИН ГУИ И ВХОД (Логика из ITEMFARM)
task.spawn(function()
    pcall(function()
        local pg = Player:WaitForChild("PlayerGui")
        local guis = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, n in pairs(guis) do if pg:FindFirstChild(n) then pg[n]:Destroy() end end
        
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or (ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteEvent"))
        if remote then remote:FireServer("PressedPlay") end
    end)
end)

-- 2. АНТИ-ЧИТ (Логика из Xenon/Confirmed)
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

-- 3. ПРОВЕРКА ИНВЕНТАРЯ
local function HasMax(name)
    local c = 0
    for _, v in pairs(Player.Backpack:GetChildren()) do if v.Name == name then c = c + 1 end end
    if Player.Character and Player.Character:FindFirstChild(name) then c = c + 1 end
    return c >= (MaxItemAmounts[name] or 99)
end

-- 4. SERVER HOP (Моментальный из твоих файлов)
local function Hop()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))()
end

-- 5. ОСНОВНОЙ ЦИКЛ ФАРМА (Скрещенная логика)
task.spawn(function()
    while task.wait(0.5) do
        local char = Player.Character or Player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local remote = char:WaitForChild("RemoteEvent", 5)
        
        if hrp and remote then
            -- Поиск предметов в папке (стандарт YBA)
            local folder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
            local foundSomething = false
            
            if folder then
                for _, item in pairs(folder:GetChildren()) do
                    if item:IsA("Model") and item.PrimaryPart then
                        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and not HasMax(prompt.ObjectText) then
                            foundSomething = true
                            -- Телепорт и сбор
                            hrp.CFrame = item.PrimaryPart.CFrame
                            task.wait(0.2)
                            fireproximityprompt(prompt)
                            task.wait(0.1)
                        end
                    end
                end
            end
            
            -- Если предметов нет или всё собрали - продаем и ливаем
            if AutoSell then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    if SellItems[tool.Name] then
                        char.Humanoid:EquipTool(tool)
                        remote:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                        task.wait(0.05)
                    end
                end
            end
            
            if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
                remote:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
            end
            
            -- Ливаем сразу после круга
            Hop()
            break -- Выход из цикла, чтобы не двоилось при хопе
        end
    end
end)
