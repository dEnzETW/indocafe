--[[
    TP GRAB TEST - Standalone
    Mekanisme:
      1) ON untuk mengaktifkan mode tunggu.
      2) Klik satu nama di daftar player.
      3) Simpan posisi awal, teleport 3 stud di belakang target,
         ikuti target secara real-time, panggil Grab satu kali,
         pertahankan follow sebentar, lalu kembali ke posisi awal.
      4) Tidak ada auto-repeat. Klik nama lagi untuk aksi berikutnya.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

-- Shared remote whitelist gate used by dEnzCreator scripts.
local WHITELIST_URL = "https://raw.githubusercontent.com/dEnzETW/EatTheWorld/refs/heads/main/WhiteList.lua"
local whitelistOK, whitelistResult = pcall(function()
    local source = game:HttpGet(WHITELIST_URL)
    assert(type(source) == "string" and #source > 0, "Whitelist kosong")
    local chunk, compileError = loadstring(source)
    assert(chunk, compileError or "Whitelist compile gagal")
    return chunk()
end)
if not whitelistOK or whitelistResult ~= true then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TP GRAB", Text = "Whitelist gagal atau akses ditolak.", Duration = 5
        })
    end)
    warn("[TP GRAB] Whitelist denied / load failed")
    return
end

-- Remove only an older copy of this standalone test.
local oldGui
pcall(function()
    if type(gethui) == "function" then
        local h = gethui()
        if typeof(h) == "Instance" then oldGui = h:FindFirstChild("TP_GRAB_TEST") end
    end
end)
oldGui = oldGui or CoreGui:FindFirstChild("TP_GRAB_TEST") or playerGui:FindFirstChild("TP_GRAB_TEST")
if oldGui then oldGui:Destroy() end

local RED = Color3.fromRGB(190, 32, 54)
local DARK = Color3.fromRGB(15, 14, 19)
local ROW = Color3.fromRGB(38, 37, 43)
local PILL = Color3.fromRGB(69, 68, 75)
local WHITE = Color3.fromRGB(244, 242, 246)
local MUTED = Color3.fromRGB(145, 140, 148)
local ACTIVE = Color3.fromRGB(91, 20, 36)

local gui = Instance.new("ScreenGui")
gui.Name = "TP_GRAB_TEST"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = false
if type(gethui) == "function" then
    local ok, h = pcall(gethui)
    if ok and typeof(h) == "Instance" then
        local success = pcall(function() gui.Parent = h end)
        parented = success and gui.Parent == h
    end
end
if not parented then
    local ok = pcall(function() gui.Parent = CoreGui end)
    parented = ok and gui.Parent == CoreGui
end
if not parented then gui.Parent = playerGui end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end

local function makeButton(parent, name, text, size, position, textSize)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = PILL
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = textSize or 9
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 7)
    return b
end

local panel = Instance.new("Frame")
panel.Name = "TPGrabPanel"
panel.Size = UDim2.fromOffset(190, 285)
panel.Position = UDim2.new(0.08, 0, 0.22, 0)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 14)
local stroke = Instance.new("UIStroke")
stroke.Color = RED
stroke.Thickness = 2
stroke.Parent = panel

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -70, 0, 28)
header.Position = UDim2.fromOffset(10, 5)
header.BackgroundTransparency = 1
header.Text = "TP GRAB"
header.TextColor3 = WHITE
header.TextSize = 13
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local closeButton = makeButton(panel, "Close", "×", UDim2.fromOffset(23, 22), UDim2.new(1, -29, 0, 7), 15)
local onButton = makeButton(panel, "ToggleON", "● OFF", UDim2.fromOffset(72, 23), UDim2.fromOffset(9, 38), 9)
onButton.BackgroundColor3 = Color3.fromRGB(119, 13, 31)
local refreshButton = makeButton(panel, "Refresh", "↻ REFRESH", UDim2.fromOffset(82, 23), UDim2.new(1, -91, 0, 38), 8)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -18, 0, 18)
status.Position = UDim2.fromOffset(9, 65)
status.BackgroundTransparency = 1
status.Text = "Status: OFF | Klik ON untuk mulai"
status.TextColor3 = MUTED
status.TextSize = 8
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Name = "TargetPlayerList"
list.Size = UDim2.new(1, -18, 1, -94)
list.Position = UDim2.fromOffset(9, 86)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = RED
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

-- Test parameters. Follow distance is measured from the target HRP reference frame.
local FOLLOW_DISTANCE = 3
local GRAB_SETTLE_TIME = 0.08
local FOLLOW_AFTER_GRAB = 1.5
local DROP_GUARD_RADIUS = 6
local DROP_NAMES = {Cube=true, Token=true, Candy=true, Present=true, Ornament=true, Egg=true}

local armed = false
local busy = false
local selectedTarget = nil
local actionToken = 0
local followConnection = nil
local rowByPlayer = {}

local function getCharacter(who)
    local character = who and who.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return nil, nil, nil end
    return character, humanoid, root
end

local function disconnectFollow()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
end

local function setStatus(message, color)
    status.Text = "Status: " .. message
    status.TextColor3 = color or MUTED
end

local function setArmed(value)
    armed = value
    onButton.Text = armed and "● ON" or "● OFF"
    onButton.BackgroundColor3 = armed and Color3.fromRGB(25, 105, 65) or Color3.fromRGB(119, 13, 31)
    if armed then
        setStatus(busy and "Menjalankan aksi..." or "ON | Pilih nama target", Color3.fromRGB(100, 220, 150))
    elseif not busy then
        setStatus("OFF | Klik ON untuk mulai")
    end
end

local function updateRow(target, active)
    local row = rowByPlayer[target]
    if not row or not row.Parent then return end
    row.BackgroundColor3 = active and ACTIVE or ROW
    local name = row:FindFirstChild("PlayerName")
    if name then name.TextColor3 = active and Color3.fromRGB(255, 90, 120) or WHITE end
end

local function targetIsValid(target, token)
    return gui.Parent ~= nil and armed and actionToken == token and busy
        and selectedTarget == target and target ~= nil and target.Parent == Players
        and getCharacter(target) ~= nil
end

local function teleportBehind(targetRoot)
    local character = player.Character
    if not character or not targetRoot or not targetRoot.Parent then return false end
    local behindPosition = targetRoot.Position - targetRoot.CFrame.LookVector * FOLLOW_DISTANCE
    local facing = targetRoot.CFrame.LookVector
    local behindCFrame = CFrame.lookAt(behindPosition, behindPosition + facing, targetRoot.CFrame.UpVector)
    return pcall(function() character:PivotTo(behindCFrame) end)
end

local function nearbyFoodBlocksGrab()
    local _, _, myRoot = getCharacter(player)
    if not myRoot then return true, "karakter lokal tidak siap" end
    local ok, found = pcall(function()
        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("BasePart") and DROP_NAMES[item.Name] then
                local ancestor = item.Parent
                local belongsToPlayer = false
                while ancestor and ancestor ~= workspace do
                    if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then
                        belongsToPlayer = true
                        break
                    end
                    ancestor = ancestor.Parent
                end
                if not belongsToPlayer and (item.Position - myRoot.Position).Magnitude <= DROP_GUARD_RADIUS then
                    return item.Name
                end
            end
        end
        return nil
    end)
    if not ok then return true, "pemeriksaan objek gagal" end
    if found then return true, "ada objek " .. tostring(found) .. " di dekat karakter" end
    return false, nil
end

local function fireGrabOnce()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local localEvents = replicatedStorage:FindFirstChild("LocalEvents")
    local grabEvent = localEvents and localEvents:FindFirstChild("Grab")
    if not grabEvent or not grabEvent:IsA("BindableEvent") then
        return false, "LocalEvents.Grab tidak ditemukan / bukan BindableEvent"
    end
    local blocked, reason = nearbyFoodBlocksGrab()
    if blocked then return false, "Grab dilewati: " .. tostring(reason) end
    local ok, err = pcall(function() grabEvent:Fire() end)
    if not ok then return false, "Grab error: " .. tostring(err) end
    return true, "Grab dipanggil satu kali"
end

local function waitWhileValid(target, token, duration)
    local elapsed = 0
    while elapsed < duration do
        if not targetIsValid(target, token) then return false end
        task.wait(math.min(0.05, duration - elapsed))
        elapsed += math.min(0.05, duration - elapsed)
    end
    return targetIsValid(target, token)
end

local function runOneAction(target)
    if busy or not armed then return end
    local _, _, myRoot = getCharacter(player)
    local _, _, targetRoot = getCharacter(target)
    if not myRoot or not targetRoot then
        setStatus("Karakter / target belum siap", Color3.fromRGB(255, 170, 80))
        return
    end

    busy = true
    selectedTarget = target
    actionToken += 1
    local token = actionToken
    local startCFrame = myRoot.CFrame
    updateRow(target, true)
    setStatus("Menuju belakang " .. target.Name, Color3.fromRGB(100, 220, 150))

    task.spawn(function()
        local completed = false
        local failureReason = nil
        local ok, err = pcall(function()
            local _, _, currentTargetRoot = getCharacter(target)
            if not currentTargetRoot or not teleportBehind(currentTargetRoot) then
                failureReason = "Teleport awal gagal"
                return
            end

            -- Keep position locked behind the target during the one-shot Grab window.
            disconnectFollow()
            followConnection = RunService.Heartbeat:Connect(function()
                if not targetIsValid(target, token) then
                    disconnectFollow()
                    return
                end
                local _, _, liveTargetRoot = getCharacter(target)
                if liveTargetRoot then teleportBehind(liveTargetRoot) end
            end)

            if not waitWhileValid(target, token, GRAB_SETTLE_TIME) then
                failureReason = "Aksi dibatalkan / target tidak valid"
                return
            end

            local called, message = fireGrabOnce()
            if not called then
                failureReason = message
                return
            end
            setStatus("Grab dipanggil | mengikuti target", Color3.fromRGB(100, 220, 150))

            if not waitWhileValid(target, token, FOLLOW_AFTER_GRAB) then
                failureReason = "Target hilang atau aksi dibatalkan"
                return
            end
            completed = true
        end)
        if not ok then failureReason = tostring(err) end

        disconnectFollow()
        -- Return to the exact position captured before this click, if character still exists.
        local currentCharacter = player.Character
        if currentCharacter and startCFrame then
            pcall(function() currentCharacter:PivotTo(startCFrame) end)
        end

        if selectedTarget == target then updateRow(target, false) end
        busy = false
        selectedTarget = nil
        if completed then
            setStatus("Selesai | siap klik target lagi", Color3.fromRGB(100, 220, 150))
        else
            setStatus((failureReason or "Tidak selesai") .. " | posisi dikembalikan", Color3.fromRGB(255, 170, 80))
        end
    end)
end

local function refreshPlayers()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    rowByPlayer = {}
    local targets = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then table.insert(targets, target) end
    end
    table.sort(targets, function(a, b)
        return string.lower(a.DisplayName .. a.Name) < string.lower(b.DisplayName .. b.Name)
    end)

    for i = 1, math.max(8, #targets) do
        local target = targets[i]
        local row = Instance.new("TextButton")
        row.Name = "PlayerRow_" .. (target and tostring(target.UserId) or ("Empty" .. i))
        row.LayoutOrder = i
        row.Size = UDim2.new(1, -2, 0, 27)
        row.BackgroundColor3 = ROW
        row.BackgroundTransparency = target and 0 or 0.48
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Active = target ~= nil
        row.Parent = list
        corner(row, 7)

        local playerName = Instance.new("TextLabel")
        playerName.Name = "PlayerName"
        playerName.Size = UDim2.new(1, -12, 1, 0)
        playerName.Position = UDim2.fromOffset(7, 0)
        playerName.BackgroundTransparency = 1
        playerName.Text = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or "— Slot kosong —"
        playerName.TextColor3 = target and WHITE or MUTED
        playerName.TextSize = 8
        playerName.Font = Enum.Font.GothamBold
        playerName.TextXAlignment = Enum.TextXAlignment.Left
        playerName.TextTruncate = Enum.TextTruncate.AtEnd
        playerName.Parent = row

        if target then
            rowByPlayer[target] = row
            local chosen = target
            row.Activated:Connect(function()
                if chosen.Parent ~= Players then refreshPlayers(); return end
                if not armed then
                    setStatus("Klik ON dahulu", Color3.fromRGB(255, 170, 80))
                    return
                end
                if busy then
                    setStatus("Sedang menjalankan satu aksi", Color3.fromRGB(255, 170, 80))
                    return
                end
                runOneAction(chosen)
            end)
        end
    end
end

onButton.Activated:Connect(function()
    if busy then
        -- OFF cancels follow and the current sequence; runOneAction restores the saved origin.
        armed = false
        actionToken += 1
        onButton.Text = "● OFF"
        onButton.BackgroundColor3 = Color3.fromRGB(119, 13, 31)
        setStatus("Membatalkan aksi...", Color3.fromRGB(255, 170, 80))
        return
    end
    setArmed(not armed)
end)

refreshButton.Activated:Connect(refreshPlayers)
closeButton.Activated:Connect(function()
    armed = false
    actionToken += 1
    disconnectFollow()
    gui:Destroy()
end)

Players.PlayerAdded:Connect(function()
    task.defer(function() if gui.Parent then refreshPlayers() end end)
end)
Players.PlayerRemoving:Connect(function(leaving)
    if leaving == selectedTarget then
        actionToken += 1
        disconnectFollow()
    end
    task.defer(function() if gui.Parent then refreshPlayers() end end)
end)

-- Drag panel by header area.
local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

refreshPlayers()
task.delay(0.5, function() if gui.Parent then refreshPlayers() end end)
print("[TP GRAB] Standalone test loaded. ON lalu klik satu nama player.")
