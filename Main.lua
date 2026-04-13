-- ПОЛНОСТЬЮ ВЫРЕЗАНЫ ВСЕ НАЗВАНИЯ И ЛИШНИЙ МУСОР
repeat task.wait() until game:IsLoaded()

-- Настройки из твоих файлов
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

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. ЖЕСТКИЙ СКИН ГУИ И АВТО-ПЛЕЙ (из ITEMFARM)
task.spawn(function()
    local pg = Player:WaitForChild("PlayerGui")
    pcall(function()
        if pg:FindFirstChild("LoadingScreen") then pg.LoadingScreen:Destroy() end
        if pg:FindFirstChild("LoadingScreen1") then pg.LoadingScreen1:Destroy() end
        -- Отправка сигнала PressedPlay (без этого сбор не работает!)
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:WaitForChild("Events"):FindFirstChild("RemoteEvent")
        remote:FireServer("PressedPlay")
    end)
end)

-- 2. АНТИЧИТ БАЙПАС (Копия из твоих исходников)
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if not checkcaller() and (method == "FireServer" or method == "InvokeServer") and self.Name == "Returner" and args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return old(self, ...)
end))

-- 3. ФУНКЦИЯ СЕРВЕР ХОПА (из твоих файлов)
local function ServerHop()
    local x = {}
    for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")).data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            x[#x + 1] = v.id
        end
    end
    if #x > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, x[math.random(1, #x)])
    else
        -- Резервный метод
        loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))()
    end
end

-- 4. ГЛАВНАЯ ЛОГИКА СБОРА (Взята из ITEMFARM)
task.spawn(function()
    -- Ждем, пока персонаж реально загрузится
    repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("RemoteEvent")
    
    local Root = Player.Character:WaitForChild("HumanoidRootPart")
    
    -- Проверяем наличие папки предметов
    local ItemFolder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
    
    if ItemFolder then
        local children = ItemFolder:GetChildren()
        if #children > 0 then
            for _, item in pairs(children) do
                if item:IsA("Model") and item.PrimaryPart then
                    local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        -- Телепорт прямо на предмет (как в твоем ITEMFARM)
                        Root.CFrame = item.PrimaryPart.CFrame
                        task.wait(0.2)
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                end
            end
        end
    end

    -- 5. АВТО-ПРОДАЖА И ПОКУПКА ПЕРЕД ЛИВОМ
    if AutoSell then
        pcall(function()
            local remote = Player.Character.RemoteEvent
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    Player.Character.Humanoid:EquipTool(tool)
                    remote:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.1)
                end
            end
        end)
    end

    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(0.5)
    end

    -- 6. МОМЕНТАЛЬНЫЙ ХОП
    ServerHop()
end)
