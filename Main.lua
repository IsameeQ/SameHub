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

repeat task.wait(1) until game:IsLoaded()

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

getgenv().SpawnedItems = {}
local ItemSpawnFolder = Workspace:WaitForChild("Item_Spawns", 10):WaitForChild("Items", 10)

ItemSpawnFolder.ChildAdded:Connect(function(m)
    task.wait(1)
    if m:IsA("Model") and m.PrimaryPart then
        local p = m:FindFirstChildOfClass("ProximityPrompt")
        if p then getgenv().SpawnedItems[m] = {Name = p.ObjectText, ProximityPrompt = p, Position = m.PrimaryPart.Position} end
    end
end)

task.spawn(function()
    pcall(function()
        PlayerGui:WaitForChild("LoadingScreen1"):Destroy()
        task.wait(0.5)
        PlayerGui:WaitForChild("LoadingScreen"):Destroy()
    end)
end)

repeat task.wait() until GetCharacter() and GetCharacter("RemoteEvent")
GetCharacter("RemoteEvent"):FireServer("PressedPlay")
TeleportTo(CFrame.new(978, -42, -49))
task.wait(5)

while true do
    for m, info in pairs(getgenv().SpawnedItems) do
        if not HasMaxItem(info.Name) then
            local HRP = GetCharacter("HumanoidRootPart")
            if HRP then
                getgenv().SpawnedItems[m] = nil
                local bv = Instance.new("BodyVelocity", HRP)
                bv.Velocity = Vector3.new(0, 0, 0)
                ToggleNoclip(true)
                TeleportTo(CFrame.new(info.Position.X, info.Position.Y + 25, info.Position.Z))
                task.wait(0.5)
                fireproximityprompt(info.ProximityPrompt)
                task.wait(0.5)
                bv:Destroy()
                TeleportTo(CFrame.new(978, -42, -49))
            end
        else
            getgenv().SpawnedItems[m] = nil
        end
    end

    if AutoSell then
        for item, sell in pairs(SellItems) do
            if sell and Player.Backpack:FindFirstChild(item) then
                GetCharacter("Humanoid"):EquipTool(Player.Backpack[item])
                GetCharacter("RemoteEvent"):FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                task.wait(0.1)
            end
        end
    end

    local Money = Player.PlayerStats.Money
    if BuyLucky and Money.Value >= 75000 then
        Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
        task.wait(1)
    end

    task.wait(5)
    ServerHop()
    task.wait(10)
end
