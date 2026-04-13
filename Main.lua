-- FULL MERGE: ITEMFARM + XENON + CONFIRMED
-- Прямое копирование логики из твоих 5 файлов

print("Waiting Loading...")
task.wait(8.0) -- Из message (1).txt

repeat task.wait() until game:IsLoaded()

-- Таблица из Confirmed_YBAV7.txt
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

-- 1. ОПТИМИЗАЦИЯ КАРТЫ (из xenon v3+cream.txt)
local MapFolder = Instance.new("Folder", workspace)
for _, Part in pairs(workspace:GetDescendants()) do
    if Part:IsA("BasePart") and Part.Parent == workspace.Map then
        task.spawn(function() Part.Parent = MapFolder end)
    end
end

-- 2. ВХОД В ИГРУ (из ITEMFARM.txt)
task.spawn(function()
    pcall(function()
        local pg = Player:WaitForChild("PlayerGui")
        if pg:FindFirstChild("LoadingScreen") then pg.LoadingScreen:Destroy() end
        if pg:FindFirstChild("IntroGui") then pg.IntroGui:Destroy() end
        
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:WaitForChild("Events"):FindFirstChild("RemoteEvent")
        remote:FireServer("PressedPlay")
    end)
end)

-- 3. АНТИЧИТ БАЙПАС (из 2h236hb.txt)
local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if not checkcaller() and self.Name == "Returner" and args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return old(self, ...)
end))

-- 4. SERVER HOP (из Confirmed_YBAV7.txt)
local function ServerHop()
    local x = {}
    local res = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100")
    local data = HttpService:JSONDecode(res)
    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(x, v.id)
        end
    end
    if #x > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, x[math.random(1, #x)])
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))()
    end
end

-- 5. ЛОГИКА СБОРА (из ITEMFARM.txt)
local function GetItemCount(name)
    local count = 0
    for _, v in pairs(Player.Backpack:GetChildren()) do if v.Name == name then count = count + 1 end end
    if Player.Character and Player.Character:FindFirstChild(name) then count = count + 1 end
    return count
end

task.spawn(function()
    -- Ждем персонажа как в исходнике
    repeat task.wait(1) until Player.Character and Player.Character:FindFirstChild("RemoteEvent")
    local Root = Player.Character:WaitForChild("HumanoidRootPart")
    
    -- Даем вещам заспавниться (важно!)
    task.wait(2)
    
    local ItemSpawns = workspace:FindFirstChild("Item_Spawns") and workspace.Item_Spawns:FindFirstChild("Items")
    
    if ItemSpawns then
        local allItems = ItemSpawns:GetChildren()
        if #allItems > 0 then
            for _, item in pairs(allItems) do
                if item:IsA("Model") and item.PrimaryPart then
                    local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and GetItemCount(prompt.ObjectText) < (MaxItems[prompt.ObjectText] or 99) then
                        
                        -- Телепорт (логика из Confirmed)
                        Root.CFrame = item.PrimaryPart.CFrame
                        task.wait(0.3)
                        fireproximityprompt(prompt)
                        task.wait(0.2)
                    end
                end
            end
        end
    end

    -- 6. ПРОДАЖА (из message (1).txt)
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

    -- 7. ПОКУПКА ЛАККИ (из ITEMFARM.txt)
    if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
        Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(0.5)
    end

    -- 8. ПРЫЖОК
    ServerHop()
end)

-- 9. NO COLLIDE (из 2h236hb.txt)
game:GetService("RunService").Stepped:Connect(function()
    if Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)
