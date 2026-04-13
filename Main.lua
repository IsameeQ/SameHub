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

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Полный скип GUI загрузки
task.spawn(function()
    pcall(function()
        -- Удаляем стандартные экраны загрузки YBA
        local loadingNames = {"LoadingScreen", "LoadingScreen1", "TeleportGui", "IntroGui"}
        for _, name in pairs(loadingNames) do
            local gui = PlayerGui:FindFirstChild(name)
            if gui then gui:Destroy() end
        end
        
        -- Убираем блюр, если он остался
        local lighting = game:GetService("Lighting")
        local blur = lighting:FindFirstChildOfClass("BlurEffect")
        if blur then blur:Destroy() end
        
        -- Посылаем сигнал старта игры
        local event = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RemoteEvent")
        if event then
            event:FireServer("PressedPlay")
        end
    end)
end)

local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and rawequal(self.Name, "Returner") and rawequal(Args[1], "idklolbrah2de") then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

local function GetCharacter(Part)
    if Player.Character then
        if not Part then return Player.Character
        elseif typeof(Part) == "string" then return Player.Character:FindFirstChild(Part) end
    end
    return nil
end

local function TeleportTo(Position)
    local HRP = GetCharacter("HumanoidRootPart")
    if HRP and typeof(Position) == "CFrame" then HRP.CFrame = Position end
end

local function ToggleNoclip(Value)
    local Char = GetCharacter()
    if Char then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = not Value end
        end
    end
end

local MaxItemAmounts = {
    ["Gold Coin"] = 45, ["Rokakaka"] = 25, ["Pure Rokakaka"] = 10, ["Mysterious Arrow"] = 25,
    ["Diamond"] = 30, ["Ancient Scroll"] = 10, ["Caesar's Headband"] = 10, ["Stone Mask"] = 10,
    ["Rib Cage of The Saint's Corpse"] = 20, ["Quinton's Glove"] = 10, ["Zeppeli's Hat"] = 10,
    ["Lucky Arrow"] = 10, ["Clackers"] = 10, ["Steel Ball"] = 10, ["Dio's Diary"] = 10
}

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 14597778) then
    for i, v in pairs(MaxItemAmounts) do MaxItemAmounts[i] = v * 2 end
end

local function HasMaxItem(Item)
    local c = 0
    for _, t in pairs(Player.Backpack:GetChildren()) do if t.Name == Item then c = c + 1 end end
    return MaxItemAmounts[Item] and c >= MaxItemAmounts[Item] or false
end

local ServerHop = loadstring(game:HttpGet("https://raw.githubusercontent.com/rinqedd/pub_rblx/main/ServerHop", true))

local ItemSpawnFolder = Workspace:WaitForChild("Item_Spawns", 20):WaitForChild("Items", 20)

repeat task.wait(1) until GetCharacter() and GetCharacter():FindFirstChild("RemoteEvent")
task.wait(1)
TeleportTo(CFrame.new(978, -42, -49))

while true do
    local items = ItemSpawnFolder:GetChildren()
    for _, m in pairs(items) do
        if m:IsA("Model") and m.PrimaryPart then
            local p = m:FindFirstChildOfClass("ProximityPrompt")
            if p and not HasMaxItem(p.ObjectText) then
                local HRP = GetCharacter("HumanoidRootPart")
                if HRP then
                    local bv = Instance.new("BodyVelocity", HRP)
                    bv.Velocity = Vector3.new(0, 0, 0)
                    ToggleNoclip(true)
                    TeleportTo(m.PrimaryPart.CFrame + Vector3.new(0, 5, 0))
                    task.wait(0.4)
                    fireproximityprompt(p)
                    task.wait(0.3)
                    bv:Destroy()
                end
            end
        end
    end

    if AutoSell then
        pcall(function()
            local event = GetCharacter("RemoteEvent")
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if SellItems[tool.Name] then
                    Player.Character.Humanoid:EquipTool(tool)
                    event:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                    task.wait(0.1)
                end
            end
        end)
    end

    local Money = Player.PlayerStats.Money
    if BuyLucky and Money.Value >= 75000 then
        GetCharacter("RemoteEvent"):FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(1)
    end

    task.wait(2)
    ServerHop()
    task.wait(10)
end
