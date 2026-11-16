local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local TS = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local char, hum, hrp
local function updateCharacter(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
    hum = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end

if plr.Character then updateCharacter(plr.Character) else plr.CharacterAdded:Wait(); updateCharacter(plr.Character) end
plr.CharacterAdded:Connect(updateCharacter)

getgenv().defaultWalkSpeed = tonumber(plr.PlayerGui.ScreenGui.Shop.ShopFrames.Upgrades.UpgradeList.Speed.UpgradeFrame.Amount.Text)
getgenv().defaultJumpPower = 50
getgenv().currentSelectedPlayer = nil
getgenv().tpDistance = 3
getgenv().tpHeight = -1.5
getgenv().randomTeleportTime = getgenv().randomTeleportTime or 0.5

getgenv().SendNotification = function(title, content, duration, image)
if Rayfield then
        Rayfield:Notify({
    Title = title or "GG hub",
        Content = content or "",
        Duration = duration or 3,
        Image = image or 5107182098,
})
end
end

local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
local gameName = gameInfo.Name
local Window = Rayfield:CreateWindow({
    Name = "GG hub - " .. gameName,
    Icon = 16570037140,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by DNzinGG",
    ShowText = "GG hub",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "GG_hub", FileName = "GG hub - Eat The World" }
})

local Main = Window:CreateTab("Main", 124620632231839)
local MainOthers = Window:CreateTab("MainOthers", 124620632231839)
local Upgrades = Window:CreateTab("Upgrades", 83020221502927)
local Others = Window:CreateTab("Others", 12122755689)

local SliderWalkSpeed = Others:CreateSlider({
        Name = "Change WalkSpeed",
        Range = {1, 1000},
        Increment = 1,
        CurrentValue = defaultWalkSpeed,
        Callback = function(v)
                getgenv().currentWalkSpeed = v
        end,
})

local InputWalkSpeed = Others:CreateInput({
        Name = "Input WalkSpeed",
        CurrentValue = tostring(defaultWalkSpeed),
        PlaceholderText = tostring(defaultWalkSpeed),
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
                local num = tonumber(Text)
                if num then
                        if num <= 1000 then
                                getgenv().currentWalkSpeed = num
                        else
                                SendNotification("GG hub", "The maximum value is 1000!", 2)
                        end
                else
                        SendNotification("GG hub", "Invalid WalkSpeed value, use numbers!", 2)
                end
        end,
})

task.spawn(function()
        while task.wait(0.05) do
                if hum then
                        pcall(function()
                                hum.WalkSpeed = tonumber(getgenv().currentWalkSpeed) or defaultWalkSpeed
                        end)
                end
        end
end)

local SliderJumpPower = Others:CreateSlider({
        Name = "Change JumpPower",
        Range = {1, 1000},
        Increment = 1,
        CurrentValue = defaultJumpPower,
        Callback = function(Value)
                if hum then
                        hum.UseJumpPower = true
                        hum.JumpPower = Value
                end
        end,
})

local InputJumpPower = Others:CreateInput({
        Name = "Input JumpPower",
        CurrentValue = tostring(defaultJumpPower),
        PlaceholderText = tostring(defaultJumpPower),
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
                local num = tonumber(Text)
                if num then
                        if num <= 1000 then
                                getgenv().currentJumpPower = num
                                if hum then hum.JumpPower = num end
                        else
                                SendNotification("GG hub", "The maximum value is 1000!", 2)
                        end
                else
                        SendNotification("GG hub", "Invalid JumpPower value, use numbers!", 2)
                end
        end,
})

Others:CreateButton({ Name = "Reset WalkSpeed", Callback = function() if hum then hum.WalkSpeed = defaultWalkSpeed SliderWalkSpeed:Set(defaultWalkSpeed) InputWalkSpeed:Set(tostring(defaultWalkSpeed)) end end })
Others:CreateButton({ Name = "Reset JumpPower", Callback = function() if hum then hum.JumpPower = defaultJumpPower SliderJumpPower:Set(defaultJumpPower) InputJumpPower:Set(tostring(defaultJumpPower)) end end })

local jumpConnection
Others:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "Infinite Jump",
    Callback = function(Value)
        if jumpConnection then jumpConnection:Disconnect() end
        if Value then
            jumpConnection = UserInputService.JumpRequest:Connect(function()
                local h = plr.Character and plr.Character:FindFirstChild("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end,
})

local ButtonGetTPTool = Others:CreateButton({
Name = "Get TP Tool",
Callback = function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Backpack = player:WaitForChild("Backpack")

if Backpack:FindFirstChild("TPTool") then
Backpack.TPTool:Destroy()
end

local tool = Instance.new("Tool")
tool.Name = "TPTool"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.Parent = Backpack

local soundId = "rbxassetid://9118823109"

tool.Activated:Connect(function()
local mouse = player:GetMouse()
local character = player.Character
if not character then return end
local root = character:FindFirstChild("HumanoidRootPart")
if not root then return end

local targetPos = mouse.Hit.p + Vector3.new(0, 3, 0)  

local sound = Instance.new("Sound")  
sound.SoundId = soundId  
sound.Volume = 1  
sound.Parent = root  
sound:Play()  
game.Debris:AddItem(sound, 2)  

root.CFrame = CFrame.new(targetPos)

end)
end,
})

local ButtonForceReset = Others:CreateButton({
Name = "Force Reset",
Callback = function()
plr.Character.Humanoid.Health = 0
end,
})


Others:CreateButton({ Name = "Fly Gui", Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end) end })

local ToggleNoClip = Others:CreateToggle({
        Name = "No Clip",
        CurrentValue = false,
        Flag = "No Clip",
        Callback = function(Value)
                getgenv().noClip = Value
                task.spawn(function()
                        while noClip do task.wait(0.001)
                                if char then
                                        for _, v in pairs(char:GetChildren()) do
                                                if (v:IsA("MeshPart") or v:IsA("Part")) then
                                                        v.CanCollide = not noClip
                                                end
                                        end
                                end
                        end
                end)
        end,
})

local ButtonAntiLag = Others:CreateButton({ Name = "Anti Lag", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/LegiteriumZ/RobloxScript/main/binh%20hub%20fps%20booster%20v1.lua"))() end,})
local ButtonDestroyGui = Others:CreateButton({
        Name = "Destroy Gui",
        Callback = function()
        Rayfield:Destroy()
        end,
})

local ToggleAutoGrab = Main:CreateToggle({
        Name = "Auto Grab",
        CurrentValue = false,
        Flag = "Auto Grab",
        Callback = function(Value)
                getgenv().autoGrab = Value

                local lastChange = tick()
                local lastValue = nil

                while autoGrab do
                        task.wait(.5)

                        local chunk = char:FindFirstChild("CurrentChunk")
                        if chunk then
                                local v = chunk.Value

                                if v ~= lastValue then
                                        lastChange = tick()
                                        lastValue = v
                                end

                                if v == nil then
                                        local args = {false,false,false}
                                        char.Events.Grab:FireServer(unpack(args))

                                        if tick() - lastChange > 1.3 then
                                                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-10,10),1,math.random(-10,10))
                                                getgenv().autoGrab = false
                                                task.wait(1.2)
                                                getgenv().autoGrab = true
                                                lastChange = tick()
                                        end
                                end
                        end
                end
        end,
})

local ToggleAutoGrabWithTeleport = Main:CreateToggle({
        Name = "Auto Grab With Teleport",
        CurrentValue = false,
        Flag = "Auto Grab With Teleport",
        Callback = function(Value)
                getgenv().autoGrabWithTp = Value

                task.spawn(function()
                        while autoGrabWithTp do
                                task.wait(.0001)
                                local chunk = char:FindFirstChild("CurrentChunk")
                                if chunk and chunk.Value == nil then
                                        char.Events.Grab:FireServer(false, false, false)
                                        task.wait(getgenv().autoThrow and 2.3 or 3.5)
                                        local randPos = hrp.Position + Vector3.new(
                                                math.random(-5, 10),
                                                1.3,
                                                math.random(-5, 10)
                                        )
                                        local randRot = math.rad(math.random(0, 360))
                                        hrp.CFrame = CFrame.new(randPos) * CFrame.Angles(0, randRot, 0)
                                end
                        end
                end)
        end,
})

local ToggleAutoEat = Main:CreateToggle({
        Name = "Auto Eat",
        CurrentValue = false,
        Flag = "Auto Eat",
        Callback = function(Value)
                getgenv().autoEat = Value

                while autoEat do task.wait(.1)
                        game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Eat"):FireServer()
                end
end,
})

local ToggleAutoThrow = Main:CreateToggle({
        Name = "Auto Throw",
        CurrentValue = false,
        Flag = "Auto Throw",
        Callback = function(Value)
                getgenv().autoThrow = Value

                while autoThrow do task.wait(.15)
                        game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Throw"):FireServer()
                end

end,
})

local ToggleAutoSell = Main:CreateToggle({
        Name = "Auto Sell",
        CurrentValue = false,
        Flag = "Auto Sell",
        Callback = function(Value)
                getgenv().autoSell = Value

                while autoSell do task.wait(.1)
                        if char:FindFirstChild("Size") and plr.PlayerGui.ScreenGui.Sell.SellText.Visible then
                        game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Sell"):FireServer()
                        end
end
end,
})

local function touchOrTp(part)
    local ok = pcall(function()
        firetouchinterest(part,hrp,0)
        task.wait()
        firetouchinterest(part,hrp,1)
    end)

    if not ok then
        local old = hrp.CFrame
        hrp.CFrame = part.CFrame + Vector3.new(0,1,0)
        task.wait(.3)
        hrp.CFrame = old
    end
end

local function getPart(obj)
    if obj:IsA("BasePart") then
        return obj
    end
    return obj:FindFirstChildWhichIsA("BasePart")
end

local ToggleAutoCollectAllRewards = Main:CreateToggle({
        Name = "Auto Collect All Rewards",
        CurrentValue = false,
        Flag = "Auto Collect All Rewards",
        Callback = function(Value)
        getgenv().autoCollectRewards = Value
        pcall(function()
                while autoCollectRewards do
            task.wait()
            for _,obj in ipairs(Workspace:GetChildren()) do
                if obj:FindFirstChildOfClass("TouchTransmitter") then
                    local part = getPart(obj)
                    if part then
                        touchOrTp(part)
                    end
                end
            end
        end
        end)
end,
})

local ToggleAutoCollectCubes = Main:CreateToggle({
    Name = "Auto Collect Cubes",
    CurrentValue = false,
    Flag = "Auto Collect Cubes",
    Callback = function(Value)
        getgenv().autoCollectCubes = Value
        pcall(function()
        while autoCollectCubes do
            task.wait()
            for _,obj in ipairs(Workspace:GetChildren()) do
                if obj:FindFirstChildOfClass("TouchTransmitter") and (obj.Name == "Cube" or obj.Name == "Cubes") then
                    local part = getPart(obj)
                    if part then
                        touchOrTp(part)
                    end
                end
            end
        end
        end)
    end
})

local ToggleAutoCollectCandy = Main:CreateToggle({
    Name = "Auto Collect Candy",
    CurrentValue = false,
    Flag = "Auto Collect Candy",
    Callback = function(Value)
        getgenv().autoCollectCandy = Value
        pcall(function()
        while autoCollectCandy do
            task.wait()
            for _,obj in ipairs(Workspace:GetChildren()) do
                if obj:FindFirstChildOfClass("TouchTransmitter") and obj.Name == "Candy" then
                    local part = getPart(obj)
                    if part then
                        touchOrTp(part)
                    end
                end
            end
        end
        end)
    end
})

local ToggleAutoRandomTeleport = Main:CreateToggle({
        Name = "Auto Random Teleport",
        CurrentValue = false,
        Flag = "Auto Random Teleport",
        Callback = function(Value)
                getgenv().autoTp = Value

                task.spawn(function()
                        while autoTp do
                                task.wait(getgenv().randomTeleportTime)

                                local bedrock = workspace.Map:WaitForChild("Bedrock")
                                local list = {}

                                for _,v in ipairs(workspace.Map.Fragmentable:GetChildren()) do
                                        if v:IsA("Part") and v.Position.Y > bedrock.Position.Y then
                                                list[#list+1] = v
                                        end
                                end

                                if #list > 0 then
                                        hrp.CFrame = list[math.random(1, #list)].CFrame + Vector3.new(0, 1, 0)
                                end
                        end
                end)
        end,
})

local SliderRandomTeleportTime = Main:CreateSlider({
        Name = "Random Teleport Time",
        Range = {0.1, 5},
        Increment = 0.1,
        CurrentValue = getgenv().randomTeleportTime,
        Flag = "Random Teleport Time",
        Callback = function(Value)
                getgenv().randomTeleportTime = Value
        end,
})

local ButtonResetTime = Main:CreateButton({
        Name = "Reset Time",
        Callback = function()
                getgenv().randomTeleportTime = 0.5
                SliderRandomTeleportTime:Set(0.5)
end,
})

local ToggleAutoSpinRewards = Main:CreateToggle({
        Name = "Auto Spin Rewards",
        CurrentValue = false,
        Flag = "Auto Spin Rewards",
        Callback = function(Value)
        getgenv().autoSpin = Value

        while autoSpin do task.wait(.1)
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("SpinEvent"):FireServer()
        end
end,
})

local UpgGui = plr.PlayerGui:WaitForChild("ScreenGui").Shop.ShopFrames.Upgrades.UpgradeList
local CubesText = plr.PlayerGui.ScreenGui.Shop.CubeFrame.CounterFrame.Cubes

local function toNumber(str)
    return tonumber((str:gsub(",", ""))) or 0
end

local function getCubes()
    return toNumber(CubesText.Text)
end

local function getPrice(path)
    local priceObj = path:FindFirstChild("BuyFrame") and path.BuyFrame:FindFirstChild("Price")
    return priceObj and toNumber(priceObj.Text) or math.huge
end

local function buyUpgrade(name)
    local ev = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PurchaseEvent")
    ev:FireServer(name)
end

local upgradeList = {
    { flag = "autoUpgradeMaxSize",       gui = UpgGui.MaxSize,     name = "MaxSize" },
    { flag = "autoUpgradeWalkSpeed",     gui = UpgGui.Speed,       name = "Speed" },
    { flag = "autoUpgradeSizeMultiplier",gui = UpgGui.Multiplier,  name = "Multiplier" },
    { flag = "autoUpgradeEatSpeed",      gui = UpgGui.EatSpeed,    name = "EatSpeed" }
}

task.spawn(function()
    while true do
        task.wait(0.3)

        local cubes = getCubes()
        local cheapestName = nil
        local cheapestPrice = math.huge

        for _, data in ipairs(upgradeList) do
            if getgenv()[data.flag] then
                local p = getPrice(data.gui)
                if p < cheapestPrice then
                    cheapestPrice = p
                    cheapestName = data.name
                end
            end
        end

        if cheapestName and cubes >= cheapestPrice then
            buyUpgrade(cheapestName)
        end
    end
end)

local ToggleAutoUpgradeMaxSize = Upgrades:CreateToggle({
    Name = "Auto Upgrade Max Size",
    CurrentValue = false,
    Flag = "Auto Upgrade Max Size",
    Callback = function(v)
        getgenv().autoUpgradeMaxSize = v
    end,
})

local ToggleAutoUpgradeWalkSpeed = Upgrades:CreateToggle({
    Name = "Auto Upgrade WalkSpeed",
    CurrentValue = false,
    Flag = "Auto Upgrade WalkSpeed",
    Callback = function(v)
        getgenv().autoUpgradeWalkSpeed = v
    end,
})

local ToggleAutoUpgradeSizeMultiplier = Upgrades:CreateToggle({
    Name = "Auto Upgrade Size Multiplier",
    CurrentValue = false,
    Flag = "Auto Upgrade Size Multiplier",
    Callback = function(v)
        getgenv().autoUpgradeSizeMultiplier = v
    end,
})

local ToggleAutoUpgradeEatSpeed = Upgrades:CreateToggle({
    Name = "Auto Upgrade Eat Speed",
    CurrentValue = false,
    Flag = "Auto Upgrade Eat Speed",
    Callback = function(v)
        getgenv().autoUpgradeEatSpeed = v
    end,
})

local function waitForCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char then return char end

    local ok, result = pcall(function()
        return player.CharacterAdded:Wait()
    end)

    return ok and result or nil
end

local function GetPlayers()
    local players = {}
    for _,v in ipairs(Players:GetPlayers()) do
        if v ~= plr then
            players[#players+1] = v.Name
        end
    end
    return players
end

local DropdownSelectPlayers = MainOthers:CreateDropdown({
    Name = "Select Players",
    Options = GetPlayers(),
    CurrentOption = nil,
    Callback = function(opt)
        if type(opt) == "table" then opt = opt[1] end
        getgenv().currentSelectedPlayer = opt
    end,
})

local ButtonRefreshSelectedPlayer = MainOthers:CreateButton({
    Name = "Refresh Selected Player",
    Callback = function()
        DropdownSelectPlayers:Set(GetPlayers())
    end,
})

local SliderDistanceToTeleport = MainOthers:CreateSlider({
    Name = "Distance To Teleport",
    Range = {-30, 30},
    Increment = 1,
    CurrentValue = 3,
    Callback = function(v)
        getgenv().tpDistance = v
    end,
})

local SliderHeightToTeleport = MainOthers:CreateSlider({
    Name = "Height To Teleport",
    Range = {-50, 50},
    Increment = 1,
    CurrentValue = -1.5,
    Callback = function(v)
        getgenv().tpHeight = v
    end,
})

local ButtonResetDistance = MainOthers:CreateButton({
    Name = "Reset Distance",
    Callback = function()
        SliderDistanceToTeleport:Set(3)
    end,
})

local ButtonResetHeight = MainOthers:CreateButton({
    Name = "Reset Height",
    Callback = function()
        SliderHeightToTeleport:Set(-1.5)
    end,
})

local ButtonTeleportToSelectedPlayer = MainOthers:CreateButton({
    Name = "Teleport To Selected Player",
    Callback = function()
        local name = currentSelectedPlayer
        if not name then return end

        local target = Players:FindFirstChild(name)
        if not target then return end

        local targetChar = waitForCharacter(target)
        if not targetChar then return end

        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            or targetChar:WaitForChild("HumanoidRootPart", 3)

        if hrp and targetHRP then
            hrp.CFrame = targetHRP.CFrame * CFrame.new(0, tpHeight, tpDistance)
        end
    end,
})

local ToggleAutoTeleportToSelectedPlayer = MainOthers:CreateToggle({
    Name = "Auto Teleport To Selected Player",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().autoTpPlayer = Value

        task.spawn(function()
            while autoTpPlayer do
                task.wait(.1)

                local name = currentSelectedPlayer
                if not name then continue end

                local target = Players:FindFirstChild(name)
                if not target then continue end

                local targetChar = target.Character
                if not targetChar then
                    targetChar = waitForCharacter(target)
                    if not targetChar then continue end
                end

                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if hrp and targetHRP then
                    hrp.CFrame = targetHRP.CFrame * CFrame.new(0, tpHeight, tpDistance)
                end
            end
        end)
    end,
})

Rayfield:LoadConfiguration()
