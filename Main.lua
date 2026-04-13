-- FULL REBUILD: ITEM FARM + ANTI-SKIP LOGIC
repeat task.wait() until game:IsLoaded()

-- Конфиг (из твоих исходников)
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

-- 1. ЖЕСТКАЯ ЗАДЕРЖКА ЗАГРУЗКИ (как в ITEMFARM)
print("Waiting for assets...")
task.wait(7.0) 

-- 2. КИЛЛ ГУИ И ВХОД
task.spawn(function()
    pcall(function()
        local pg = Player:WaitForChild("PlayerGui")
        local screens = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, n in pairs(screens) do 
            if pg:FindFirstChild(n) then pg[n]:Destroy() end 
        end
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:WaitForChild("Events"):FindFirstChild("RemoteEvent")
        remote:FireServer("PressedPlay")
    end)
end)

-- 3. АНТИЧИТ БАЙПАС (Returner)
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and self.Name == "Returner" and args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return old(self, ...)
end))

-- 4. SERVER HOP API
local function Hop()
    print("No items found or finished. Hopping...")
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

-- 5. ЛОГИКА СБОРА (С ПРОВЕРКОЙ НА ПУСТОТУ)
task.spawn(function()
    repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local hrp = Player.Character.HumanoidRootPart
    
    local folder = workspace:WaitForChild("Item_Spawns", 10):WaitForChild("Items", 10)
    
    -- Даем вещам 2 секунды "догрузиться" в папку
    task.wait(2)
    
    local items = folder:GetChildren()
    
    if #items == 0 then
        -- Если пусто, пробуем подождать еще немного (защита от моментального хопа)
        print("Folder empty, retrying in 3s...")
        task.wait(3)
        items = folder:GetChildren()
    end

    if #items > 0 then
        print("Items found: " .. #items)
        for _, item in pairs(items) do
            if item:IsA("Model") and item.PrimaryPart then
                local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    -- ТП и Стабилизация
                    local bv = Instance.new("BodyVelocity", hrp)
                    bv.Velocity = Vector3.new(0,0,0)
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    
                    hrp.CFrame = item.PrimaryPart.CFrame
                    task.wait(0.3)
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                    bv:Destroy()
                end
            end
        end
    end

    -- ДЕЙСТВИЯ ПЕРЕД ВЫХОДОМ
    if AutoSell then
        pcall(function()
            local remote = Player.Character:FindFirstChild("RemoteEvent")
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    Player.Character.Humanoid:EquipTool(tool)
                    remote:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.2)
                end
            end
        end)
    end

    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(1)
    end

    -- Теперь ливаем
    Hop()
end)

-- No-Collide (чтобы не застрять при ТП)
task.spawn(function()
    while task.wait(0.1) do
        if Player.Character then
            for _, v in pairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)
