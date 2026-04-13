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

-- Скип интро
task.spawn(function()
    pcall(function()
        if Player.PlayerGui:FindFirstChild("LoadingScreen") then Player.PlayerGui.LoadingScreen:Destroy() end
        local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or (ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteEvent"))
        if remote then remote:FireServer("PressedPlay") end
    end)
end)

-- Байпас античита (из твоих файлов)
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
    return count >= (MaxItemAmounts[name] or 99)
end

local ServerHop = loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))

-- Функция поиска ПРЕДМЕТОВ по всему Workspace
local function FindItems()
    local found = {}
    -- Ищем во всем ворлдспейсе объекты, у которых есть ProximityPrompt
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Parent:IsA("Model") then
            local model = obj.Parent
            if model.PrimaryPart or model:FindFirstChildOfClass("BasePart") then
                table.insert(found, {Model = model, Prompt = obj, Name = obj.ObjectText})
            end
        end
    end
    return found
end

repeat task.wait(1) until GetCharacter():FindFirstChild("RemoteEvent")

while true do
    local items = FindItems()
    local collectedAny = false

    if #items > 0 then
        for _, itemData in pairs(items) do
            if not HasMaxItem(itemData.Name) then
                local hrp = GetCharacter():FindFirstChild("HumanoidRootPart")
                local targetPart = itemData.Model.PrimaryPart or itemData.Model:FindFirstChildOfClass("BasePart")
                
                if hrp and targetPart then
                    collectedAny = true
                    local bv = Instance.new("BodyVelocity", hrp)
                    bv.Velocity = Vector3.new(0,0,0)
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
                    task.wait(0.3)
                    fireproximityprompt(itemData.Prompt)
                    task.wait(0.2)
                    bv:Destroy()
                end
            end
        end
    end

    -- Продажа и покупка
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

    -- Мгновенный лив, если предметов больше нет
    task.wait(0.5)
    ServerHop()
    task.wait(3)
end
