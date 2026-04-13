-- Полная версия Main.lua на базе твоих исходников
repeat task.wait() until game:IsLoaded()

-- Настройки (взяты из твоих конфигов)
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

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- 1. ЛОГИКА ВХОДА И КИЛЛ ГУИ (из ITEMFARM)
task.spawn(function()
    pcall(function()
        local pg = Player:WaitForChild("PlayerGui")
        local screens = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, n in pairs(screens) do 
            if pg:FindFirstChild(n) then pg[n]:Destroy() end 
        end
        local blur = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
        if blur then blur:Destroy() end
        
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:WaitForChild("Events"):FindFirstChild("RemoteEvent")
        remote:FireServer("PressedPlay")
    end)
end)

-- 2. ПОЛНЫЙ АНТИЧИТ БАЙПАС (Returner & Animation Fix)
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        if self.Name == "Returner" and args[1] == "idklolbrah2de" then
            return "  ___XP DE KEY"
        end
    end
    return old(self, ...)
end))

-- 3. ПРОВЕРКА ЛИМИТОВ (С учетом геймпасса)
pcall(function()
    if game:GetService("MarketplaceService"):UserOwnsGamePassAsync(Player.UserId, 14597778) then
        for i, v in pairs(MaxItems) do MaxItems[i] = v * 2 end
    end
end)

local function CanPick(name)
    local c = 0
    for _, v in pairs(Player.Backpack:GetChildren()) do if v.Name == name then c = c + 1 end end
    if Player.Character and Player.Character:FindFirstChild(name) then c = c + 1 end
    return c < (MaxItems[name] or 99)
end

-- 4. SERVER HOP (Мощная версия из Xenon)
local function Hop()
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

-- 5. ГЛАВНЫЙ ЦИКЛ СБОРА (100% как в твоих файлах)
task.spawn(function()
    -- Ждем прогрузки
    repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("RemoteEvent")
    local char = Player.Character
    local hrp = char:WaitForChild("HumanoidRootPart")
    local remote = char.RemoteEvent
    
    -- Папка предметов
    local folder = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
    
    if folder then
        local items = folder:GetChildren()
        if #items > 0 then
            for _, item in pairs(items) do
                if item:IsA("Model") and item.PrimaryPart then
                    local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and CanPick(prompt.ObjectText) then
                        -- Стабилизация (BodyVelocity) чтобы не кикало
                        local bv = Instance.new("BodyVelocity", hrp)
                        bv.Velocity = Vector3.new(0,0,0)
                        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        
                        hrp.CFrame = item.PrimaryPart.CFrame
                        task.wait(0.2)
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                        
                        bv:Destroy()
                    end
                end
            end
        end
    end

    -- ДИСТАНЦИОННЫЙ СЕЛЛ (из ITEMFARM)
    if AutoSell then
        pcall(function()
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    char.Humanoid:EquipTool(tool)
                    remote:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.1)
                end
            end
        end)
    end

    -- ПОКУПКА ЛАККИ
    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        remote:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(0.5)
    end

    -- МОМЕНТАЛЬНЫЙ ЛИВ
    Hop()
end)

-- Дополнительная защита: убираем коллизию, чтобы не застревать
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if Player.Character then
                for _, part in pairs(Player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end)
