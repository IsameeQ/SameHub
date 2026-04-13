local KeysURL = "https://raw.githubusercontent.com/IsameeQ/SameHub/main/keys.txt"
local UserKey = _G.Key or ""

local function VerifyAccess()
    local s, result = pcall(function() return game:HttpGet(KeysURL) end)
    if s then
        return string.find(result, UserKey) ~= nil
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
    ["Caesar's Headband"] = true, ["Stone Mask"] = true, ["Steel Ball"] = true,
    ["Rib Cage of The Saint's Corpse"] = true, ["Quinton's Glove"] = true,
    ["Zeppeli's Hat"] = true, ["Lucky Arrow"] = false, ["Clackers"] = true, ["Dio's Diary"] = true
}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local oldNc; oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Args = {...}
    if not checkcaller() and self.Name == "Returner" and Args[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
    return oldNc(self, ...)
end))

local function SafeTeleport(targetPos)
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    local distance = (Root.Position - targetPos.Position).Magnitude
    local info = TweenInfo.new(distance / 150, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Root, info, {CFrame = targetPos})
    
    local connection = game:GetService("RunService").Stepped:Connect(function()
        if Player.Character then
            for _, part in pairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    
    tween:Play()
    tween.Completed:Wait()
    connection:Disconnect()
end

task.spawn(function()
    pcall(function()
        if PlayerGui:FindFirstChild("LoadingScreen1") then PlayerGui.LoadingScreen1:Destroy() end
        if PlayerGui:FindFirstChild("LoadingScreen") then PlayerGui.LoadingScreen:Destroy() end
    end)
end)

task.spawn(function()
    while true do
        pcall(function()
            local items = workspace:FindFirstChild("Item_Spawns")
            if items and items:FindFirstChild("Items") then
                for _, item in pairs(items.Items:GetChildren()) do
                    if item:IsA("Model") and item.PrimaryPart then
                        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            SafeTeleport(item.PrimaryPart.CFrame + Vector3.new(0, 5, 0))
                            task.wait(0.3)
                            fireproximityprompt(prompt)
                            task.wait(0.2)
                        end
                    end
                end
            end

            if AutoSell then
                local event = Player.Character:FindFirstChild("RemoteEvent")
                if event then
                    for _, tool in pairs(Player.Backpack:GetChildren()) do
                        if SellItems[tool.Name] then
                            Player.Character.Humanoid:EquipTool(tool)
                            event:FireServer("EndDialogue", {["NPC"] = "Merchant", ["Dialogue"] = "Dialogue5", ["Option"] = "Option2"})
                            task.wait(0.1)
                        end
                    end
                end
            end
            
            if BuyLucky and Player.PlayerStats.Money.Value >= 75000 then
                 Player.Character.RemoteEvent:FireServer("PurchaseShopItem", {["ItemName"] = "1x Lucky Arrow"})
            end
        end)
        task.wait(5)
    end
end)
