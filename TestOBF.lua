--[[
    dEnzCreator | TP ATTACK ONLY
    Standalone TP ATTACK extracted from GELUT_REMOTE_WHITELIST.
    Panel width: 120px. Player rows toggle the selected target.
    Cycle: random TP -> Grab object -> TP to selected target -> Throw.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
if not player then
    warn("[TP ATTACK] LocalPlayer tidak ditemukan.")
    return
end
local playerGui = player:WaitForChild("PlayerGui")

-- REMOTE WHITELIST GATE (same URL and validation as GELUT)
local WHITELIST_URL =
    "https://raw.githubusercontent.com/dEnzETW/EatTheWorld/refs/heads/main/WhiteList.lua"

local whitelistOK, whitelistResult = pcall(function()
    local source = game:HttpGet(WHITELIST_URL)
    assert(type(source) == "string" and #source > 0, "Whitelist file kosong")
    local chunk, compileError = loadstring(source)
    assert(chunk, compileError or "Whitelist compile gagal")
    return chunk()
end)

if not whitelistOK or whitelistResult ~= true then
    warn("[TP ATTACK] WHITELIST DENIED / LOAD FAILED")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "dEnzCreator",
            Text = "Whitelist gagal atau akses ditolak.",
            Duration = 5
        })
    end)
    return
end

-- Remove only this standalone TP ATTACK GUI
local old
pcall(function()
    old = (gethui and gethui():FindFirstChild("DENZ_TP_ATTACK_ONLY"))
        or CoreGui:FindFirstChild("DENZ_TP_ATTACK_ONLY")
end)
if not old then old = playerGui:FindFirstChild("DENZ_TP_ATTACK_ONLY") end
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DENZ_TP_ATTACK_ONLY"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = false
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and typeof(result) == "Instance" then
        parented = pcall(function() gui.Parent = result end) and gui.Parent == result
    end
end
if not parented then
    parented = pcall(function() gui.Parent = CoreGui end) and gui.Parent == CoreGui
end
if not parented then
    gui.Parent = playerGui
end

local RED = Color3.fromRGB(190, 32, 54)
local DARK = Color3.fromRGB(15, 14, 19)
local ROW = Color3.fromRGB(38, 37, 43)
local PILL = Color3.fromRGB(69, 68, 75)
local WHITE = Color3.fromRGB(244, 242, 246)
local MUTED = Color3.fromRGB(145, 140, 148)
local ACTIVE = Color3.fromRGB(91, 20, 36)

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end

local function makeButton(parent, name, text, size, pos, textSize)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = PILL
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = textSize or 8
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 7)
    return b
end

local panel = Instance.new("Frame")
panel.Name = "TPAttackPanel"
panel.Size = UDim2.fromOffset(120, 240)
panel.Position = UDim2.new(0.08, 0, 0.20, 0)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 16)

local outline = Instance.new("UIStroke")
outline.Color = RED
outline.Thickness = 2
outline.Parent = panel

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -54, 0, 28)
header.Position = UDim2.fromOffset(8, 4)
header.BackgroundTransparency = 1
header.Text = "TP ATTACK"
header.TextColor3 = WHITE
header.TextSize = 9
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local minimize = makeButton(panel, "Minimize", "–",
    UDim2.fromOffset(18, 19), UDim2.new(1, -43, 0, 7), 13)
minimize.BackgroundColor3 = Color3.fromRGB(119, 13, 31)
local close = makeButton(panel, "Close", "×",
    UDim2.fromOffset(18, 19), UDim2.new(1, -21, 0, 7), 13)
close.BackgroundColor3 = Color3.fromRGB(119, 13, 31)

local refresh = makeButton(panel, "Refresh", "↻",
    UDim2.fromOffset(22, 19), UDim2.new(1, -29, 0, 33), 12)
local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -14, 0, 19)
status.Position = UDim2.fromOffset(7, 33)
status.BackgroundTransparency = 1
status.Text = "Pilih target"
status.TextColor3 = MUTED
status.TextSize = 7
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, -12, 1, -61)
playerList.Position = UDim2.fromOffset(6, 56)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 2
playerList.ScrollBarImageColor3 = RED
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new()
playerList.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = playerList

local attackEnabled = false
local attackTarget = nil
local attackBusy = false
local cycleToken = 0

local function getCharacter(plr)
    local char = plr and plr.Character
    if not char then return nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart")
end

local function stopAttack()
    attackEnabled = false
    cycleToken += 1
    attackBusy = false
    status.Text = "Pilih target"
    status.TextColor3 = MUTED
end

local function refreshPlayers()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("TextButton") and child.Name:sub(1, 10) == "PlayerRow_" then
            child:Destroy()
        end
    end

    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(targets, p) end
    end
    table.sort(targets, function(a, b)
        return string.lower(a.DisplayName .. a.Name) < string.lower(b.DisplayName .. b.Name)
    end)

    local slots = math.max(8, #targets)
    for i = 1, slots do
        local target = targets[i]
        local selected = target ~= nil and target == attackTarget and attackEnabled
        local row = Instance.new("TextButton")
        row.Name = "PlayerRow_" .. (target and tostring(target.UserId) or ("Empty" .. i))
        row.LayoutOrder = i
        row.Size = UDim2.new(1, -1, 0, 24)
        row.BackgroundColor3 = selected and ACTIVE or ROW
        row.BackgroundTransparency = target and 0 or 0.48
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Active = target ~= nil
        row.Parent = playerList
        corner(row, 6)

        local rowText = Instance.new("TextLabel")
        rowText.Name = "PlayerName"
        rowText.Size = UDim2.new(1, -8, 1, 0)
        rowText.Position = UDim2.fromOffset(4, 0)
        rowText.BackgroundTransparency = 1
        rowText.Text = target and (target.DisplayName .. " (@" .. target.Name .. ")") or "— Kosong —"
        rowText.TextColor3 = selected and Color3.fromRGB(255, 90, 120)
            or (target and WHITE or MUTED)
        rowText.TextSize = 6
        rowText.Font = Enum.Font.GothamBold
        rowText.TextXAlignment = Enum.TextXAlignment.Left
        rowText.TextTruncate = Enum.TextTruncate.AtEnd
        rowText.Parent = row

        if target then
            local chosen = target
            row.Activated:Connect(function()
                if chosen.Parent ~= Players then
                    refreshPlayers()
                    return
                end
                if attackEnabled and attackTarget == chosen then
                    stopAttack()
                    attackTarget = nil
                else
                    stopAttack()
                    attackTarget = chosen
                    attackEnabled = true
                    cycleToken += 1
                    status.Text = "ON: " .. chosen.Name
                    status.TextColor3 = Color3.fromRGB(80, 220, 120)
                    local token = cycleToken
                    task.spawn(function()
                        while gui.Parent and attackEnabled and cycleToken == token do
                            local currentTarget = attackTarget
                            local char, root = getCharacter(player)
                            local targetChar, targetRoot = getCharacter(currentTarget)

                            if not char or not root or not targetChar or not targetRoot
                                or currentTarget.Parent ~= Players then
                                status.Text = "Menunggu karakter"
                                task.wait(0.2)
                            elseif not attackBusy then
                                attackBusy = true
                                status.Text = "Mencari objek..."

                                -- Search position: retain GELUT random bounds.
                                pcall(function()
                                    char:PivotTo(CFrame.new(
                                        math.random(-140, 140),
                                        math.random(10, 50),
                                        math.random(-140, 140)
                                    ))
                                end)

                                -- Match GELUT AutoGrab's verified local trigger first:
                                -- ReplicatedStorage.LocalEvents.Grab is a BindableEvent.
                                task.wait(0.3)
                                if not attackEnabled or cycleToken ~= token then
                                    attackBusy = false
                                    break
                                end

                                local RS = game:GetService("ReplicatedStorage")
                                local localEvents = RS:FindFirstChild("LocalEvents")
                                local localGrab = localEvents and localEvents:FindFirstChild("Grab")
                                local grabCalled = false

                                if localGrab and localGrab:IsA("BindableEvent") then
                                    local ok = pcall(function()
                                        localGrab:Fire()
                                    end)
                                    grabCalled = ok
                                end

                                -- Fallback to the character RemoteEvent used by rEm.lua
                                -- only when GELUT's LocalEvents.Grab is unavailable.
                                if not grabCalled then
                                    char, root = getCharacter(player)
                                    local charEvents = char and char:FindFirstChild("Events")
                                    local serverGrab = charEvents and charEvents:FindFirstChild("Grab")
                                    if serverGrab and serverGrab:IsA("RemoteEvent") then
                                        local ok = pcall(function()
                                            serverGrab:FireServer(false, false, false)
                                        end)
                                        grabCalled = ok
                                    end
                                end

                                if not grabCalled then
                                    status.Text = "Grab remote tidak ditemukan"
                                    attackBusy = false
                                    task.wait(0.3)
                                    continue
                                end
                                status.Text = "Grab dipanggil"

                                -- Keep following the chosen target while Throw is sent.
                                task.wait(0.05)
                                targetChar, targetRoot = getCharacter(currentTarget)
                                char, root = getCharacter(player)
                                local followConnection = nil
                                if attackEnabled and cycleToken == token
                                    and targetChar and targetRoot and char and root then
                                    followConnection = RunService.Heartbeat:Connect(function()
                                        if not gui.Parent or not attackEnabled or cycleToken ~= token then
                                            return
                                        end
                                        local liveTargetChar, liveTargetRoot = getCharacter(currentTarget)
                                        local liveChar, liveRoot = getCharacter(player)
                                        if liveTargetChar and liveTargetRoot and liveChar and liveRoot then
                                            local mySize = liveChar:GetExtentsSize().Z
                                            local targetSize = liveTargetChar:GetExtentsSize().Z
                                            local safeDistance = (mySize / 2) + (targetSize / 2) + 2
                                            liveChar:PivotTo(liveTargetRoot.CFrame * CFrame.new(0, 0, safeDistance))
                                        end
                                    end)

                                    -- Throw quickly after the follow has placed us in target range.
                                    task.wait(0.05)
                                    if attackEnabled and cycleToken == token then
                                        local currentChar = player.Character
                                        local currentEvents = currentChar and currentChar:FindFirstChild("Events")
                                        local throwEvent = currentEvents and currentEvents:FindFirstChild("Throw")
                                        if throwEvent then
                                            pcall(function() throwEvent:FireServer() end)
                                            status.Text = "Throw dipanggil"
                                        else
                                            status.Text = "Throw remote tidak ditemukan"
                                        end
                                    end
                                    task.wait(0.15)
                                end
                                if followConnection then
                                    followConnection:Disconnect()
                                    followConnection = nil
                                end

                                attackBusy = false
                                task.wait(0.3)
                            else
                                task.wait(0.05)
                            end
                        end
                    end)
                end
                refreshPlayers()
            end)
        end
    end
end

refresh.Activated:Connect(refreshPlayers)
Players.PlayerAdded:Connect(function() task.defer(refreshPlayers) end)
Players.PlayerRemoving:Connect(function(leaving)
    if leaving == attackTarget then
        stopAttack()
        attackTarget = nil
    end
    task.defer(refreshPlayers)
end)

-- Drag panel from header
local dragging = false
local dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    playerList.Visible = not minimized
    status.Visible = not minimized
    refresh.Visible = not minimized
    panel.Size = minimized and UDim2.fromOffset(120, 36) or UDim2.fromOffset(120, 240)
end)
close.Activated:Connect(function()
    stopAttack()
    gui:Destroy()
end)

refreshPlayers()
