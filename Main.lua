-- FULL MERGE FROM UPLOADED SCRIPTS
repeat task.wait() until game:IsLoaded()

-- Конфигурация из твоих исходников
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

local MaxItems = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10, ["Mysterious Arrow"] = 25,
    ["Diamond"] = 30, ["Ancient Scroll"] = 10, ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 10, ["Quinton's Glove"] = 10, ["Zeppeli's Hat"] = 10,
    ["Lucky Arrow"] = 10, ["Clackers"] = 10, ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}

local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- 1. ЖЕСТКАЯ ЗАДЕРЖКА ЗАГРУЗКИ (из message (1).txt)
print("Waiting Loading...")
task.wait(8.0)

-- 2. СКИН ГУИ И ПОДТВЕРЖДЕНИЕ ВХОДА (из ITEMFARM.txt)
task.spawn(function()
    pcall(function()
        local pg = Player:WaitForChild("PlayerGui")
        local guis = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, n in pairs(guis) do if pg:FindFirstChild(n) then pg[n]:Destroy() end end
        
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:WaitForChild("Events"):FindFirstChild("RemoteEvent")
        remote:FireServer("PressedPlay")
    end)
end)

-- 3. АНТИЧИТ БАЙПАС (из Confirmed_YBAV7.txt)
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and self.Name == "Returner" and args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return old(self, ...)
end))

-- 4. SERVER HOP (Логика из Xenon V3)
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

-- 5. ФУНКЦИИ ПРОВЕРКИ
local function CanPick(name)
    local c = 0
    for _, v in pairs(Player.Backpack:GetChildren()) do if v.Name == name then c = c + 1 end end
    if Player.Character and Player.Character:FindFirstChild(name) then c = c + 1 end
    return c < (MaxItems[name] or 99)
end

-- 6. ГЛАВНЫЙ ЦИКЛ (Скрещенная логика из твоих 5 файлов)
task.spawn(function()
    repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("RemoteEvent")
    local char = Player.Character
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    -- Проверка предметов (с ожиданием прогрузки папки)
    local folder = workspace:WaitForChild("Item_Spawns", 5):WaitForChild("Items", 5)
    
    if folder then
        local items = folder:GetChildren()
        
        -- Если предметов нет, ждем еще 2 секунды (анти-скип)
        if #items == 0 then
            task.wait(2)
            items = folder:GetChildren()
        end

        if #items > 0 then
            print("Items found: " .. #items)
            for _, item in pairs(items) do
                if item:IsA("Model") and item.PrimaryPart then
                    local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and CanPick(prompt.ObjectText) then
                        -- Стабилизатор чтобы не кикало (BodyVelocity)
                        local bv = Instance.new("BodyVelocity", hrp)
                        bv.Velocity = Vector3.new(0,0,0)
                        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        
                        hrp.CFrame = item.PrimaryPart.CFrame
                        task.wait(0.3)
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                        
                        bv:Destroy()
                    end
                end
            end
        end
    end

    -- АВТО-ПРОДАЖА (Remote Only - без ТП к NPC)
    if AutoSell then
        pcall(function()
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    char.Humanoid:EquipTool(tool)
                    char.RemoteEvent:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.1)
                end
            end
        end)
    end

    -- ПОКУПКА ЛАККИ
    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        char.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(0.5)
    end

    -- МОМЕНТАЛЬНЫЙ ПЕРЕХОД
    ServerHop()
end)

-- No-Collide цикл (из message (1).txt)
task.spawn(function()
    while task.wait(0.2) do
        if Player.Character then
            for _, v in pairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)
