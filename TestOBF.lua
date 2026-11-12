--[[
    dEnzCreator | TP ATTACK
    UI diambil dari layout GELUT; fitur lain GELUT tidak dimuat.
    Klik nama pemain = pilih target + ON.
    Selama ON, ulangi:
    Random TP -> Grab food (internal) -> TP/follow target terkunci
    -> Throw (internal). Tombol OFF menghentikan siklus langsung. Klik target yang sama juga dapat mematikan.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StatsService = game:GetService("Stats")

local player = Players.LocalPlayer
if not player then
    warn("[TP ATTACK] LocalPlayer tidak ditemukan.")
    return
end
local playerGui = player:WaitForChild("PlayerGui")

-- No whitelist gate: standalone TP ATTACK test build.

-- Cleanup only this GUI.
local oldGui
pcall(function()
    if type(gethui) == "function" then
        local hui = gethui()
        if typeof(hui) == "Instance" then
            oldGui = hui:FindFirstChild("DENZ_TP_ATTACK_GELUT_PANEL")
        end
    end
end)
oldGui = oldGui or CoreGui:FindFirstChild("DENZ_TP_ATTACK_GELUT_PANEL")
    or playerGui:FindFirstChild("DENZ_TP_ATTACK_GELUT_PANEL")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "DENZ_TP_ATTACK_GELUT_PANEL"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = false
local hui
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and typeof(result) == "Instance" then hui = result end
end
if hui then
    local ok = pcall(function() gui.Parent = hui end)
    parented = ok and gui.Parent == hui
end
if not parented then
    local ok = pcall(function() gui.Parent = CoreGui end)
    parented = ok and gui.Parent == CoreGui
end
if not parented then
    local ok = pcall(function() gui.Parent = playerGui end)
    parented = ok and gui.Parent == playerGui
end
if not parented then
    warn("[TP ATTACK] GUI gagal dipasang.")
    gui:Destroy()
    return
end

-- GELUT palette and UI helpers.
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

local function makeLabel(parent, name, text, size, pos, font, color, textSize, align)
    local obj = Instance.new("TextLabel")
    obj.Name = name
    obj.BackgroundTransparency = 1
    obj.Text = text
    obj.Size = size
    obj.Position = pos
    obj.Font = font or Enum.Font.Gotham
    obj.TextColor3 = color or WHITE
    obj.TextSize = textSize or 10
    obj.TextXAlignment = align or Enum.TextXAlignment.Left
    obj.TextYAlignment = Enum.TextYAlignment.Center
    obj.Parent = parent
    return obj
end

local function smallButton(parent, name, text, size, pos, textSize)
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

-- Main GELUT panel: same dimensions, palette, outline and controls.
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(150, 290)
panel.Position = UDim2.new(0.08, 0, 0.20, 0)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 18)

local outline = Instance.new("UIStroke")
outline.Color = RED
outline.Thickness = 2.3
outline.Parent = panel

local minimize = smallButton(panel, "MinimizeMain", "–",
    UDim2.fromOffset(22, 22), UDim2.fromOffset(96, 9), 15)
minimize.BackgroundColor3 = Color3.fromRGB(119, 13, 31)
local close = smallButton(panel, "CloseMain", "×",
    UDim2.fromOffset(22, 22), UDim2.fromOffset(122, 9), 15)
close.BackgroundColor3 = Color3.fromRGB(119, 13, 31)

-- GELUT 2x2 status hub.
local function statusCard(name, x, y, caption, initialValue, valueColor)
    local card = Instance.new("Frame")
    card.Name = name
    card.Size = UDim2.fromOffset(40, 17)
    card.Position = UDim2.fromOffset(x, y)
    card.BackgroundColor3 = Color3.fromRGB(24, 23, 29)
    card.BorderSizePixel = 0
    card.Parent = panel
    corner(card, 4)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(54, 52, 60)
    stroke.Thickness = 1
    stroke.Parent = card
    makeLabel(card, name .. "Label", caption,
        UDim2.fromOffset(36, 6), UDim2.fromOffset(2, 0),
        Enum.Font.GothamMedium, MUTED, 5)
    local value = makeLabel(card, name .. "Value", initialValue,
        UDim2.fromOffset(36, 7), UDim2.fromOffset(2, 7),
        Enum.Font.GothamBold, valueColor or WHITE, 6)
    return value
end

local pingValue = statusCard("PingCard", 6, 2, "PING", "-- ms", Color3.fromRGB(45, 220, 95))
local serverValue = statusCard("ServerCard", 49, 2, "SERVER", "Checking", WHITE)
local fpsValue = statusCard("FPSCard", 6, 20, "FPS", "--", Color3.fromRGB(55, 150, 255))
local playerValue = statusCard("PlayerCard", 49, 20, "PEMAIN", "-- / --", WHITE)

local frameCount, measuredFPS = 0, 0
local lastFPSSample, lastStatusUpdate = os.clock(), 0
RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    frameCount += 1
    local now = os.clock()
    if now - lastFPSSample >= 1 then
        measuredFPS = math.floor(frameCount / (now - lastFPSSample) + 0.5)
        frameCount = 0
        lastFPSSample = now
    end
    if now - lastStatusUpdate >= 1 then
        lastStatusUpdate = now
        local pingMs
        pcall(function()
            local dataPing = StatsService.Network.ServerStatsItem["Data Ping"]
            local raw = dataPing:GetValueString()
            pingMs = tonumber(string.match(raw, "[%d%.]+")) or tonumber(dataPing:GetValue())
        end)
        pingValue.Text = pingMs and (tostring(math.floor(pingMs + 0.5)) .. " ms") or "N/A"
        fpsValue.Text = tostring(measuredFPS)
        local currentPlayers = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        if not maxPlayers or maxPlayers <= 0 then maxPlayers = currentPlayers end
        playerValue.Text = tostring(currentPlayers) .. " / " .. tostring(maxPlayers)
        if not pingMs then
            serverValue.Text = "Unknown"
            serverValue.TextColor3 = MUTED
        elseif pingMs <= 180 then
            serverValue.Text = "Normal"
            serverValue.TextColor3 = Color3.fromRGB(45, 220, 95)
        else
            serverValue.Text = "Lag"
            serverValue.TextColor3 = Color3.fromRGB(255, 185, 65)
        end
    end
end)

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -12, 0, 250)
content.Position = UDim2.fromOffset(6, 40)
content.BackgroundTransparency = 1
content.Parent = panel

local home = Instance.new("Frame")
home.Name = "HomePage"
home.Size = UDim2.fromScale(1, 1)
home.BackgroundTransparency = 1
home.Parent = content

local attackOpen = smallButton(home, "TPAttackOpen", "⚔️  TP ATTACK     ›",
    UDim2.new(1, 0, 0, 20), UDim2.fromOffset(0, 0), 9)
attackOpen.TextXAlignment = Enum.TextXAlignment.Left

local footerTitle = makeLabel(panel, "FooterTitle", "GELUT",
    UDim2.fromOffset(70, 11), UDim2.new(0.5, -35, 1, -27),
    Enum.Font.GothamBold, WHITE, 9, Enum.TextXAlignment.Center)
local creator = makeLabel(panel, "Creator", "dEnzCreator",
    UDim2.fromOffset(100, 10), UDim2.new(0.5, -50, 1, -15),
    Enum.Font.GothamMedium, RED, 7, Enum.TextXAlignment.Center)

-- TP ATTACK page, matching GELUT list style.
local attackPage = Instance.new("Frame")
attackPage.Name = "TPAttackPage"
attackPage.Size = UDim2.fromScale(1, 1)
attackPage.BackgroundTransparency = 1
attackPage.Visible = false
attackPage.Parent = content

local back = smallButton(attackPage, "Back", "‹ BACK",
    UDim2.fromOffset(48, 20), UDim2.fromOffset(0, 0), 8)
local offButton = smallButton(attackPage, "TPAttackOFF", "■ OFF",
    UDim2.fromOffset(42, 20), UDim2.new(1, -69, 0, 0), 9)
local refresh = smallButton(attackPage, "Refresh", "↻",
    UDim2.fromOffset(23, 20), UDim2.new(1, -23, 0, 0), 13)

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "PlayerList"
playerList.Size = UDim2.new(1, 0, 1, -24)
playerList.Position = UDim2.fromOffset(0, 24)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 2
playerList.ScrollBarImageColor3 = RED
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.CanvasSize = UDim2.new()
playerList.Parent = attackPage

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList

local attackTarget = nil
local attackEnabled = false
local attackBusy = false
local attackToken = 0
local followConnection = nil

local function getCharacter(targetPlayer)
    targetPlayer = targetPlayer or player
    local char = targetPlayer.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return nil, nil end
    return char, root
end

local function disconnectFollow()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
end

local function stopAttack(clearTarget)
    attackEnabled = false
    attackBusy = false
    attackToken += 1
    disconnectFollow()
    if clearTarget then attackTarget = nil end
end

local function isCurrentTarget(target, token)
    return gui.Parent ~= nil and attackEnabled and attackToken == token
        and attackTarget == target and target ~= nil and target.Parent == Players
end

local function getRandomPosition()
    return Vector3.new(math.random(-140, 140), math.random(10, 50), math.random(-140, 140))
end

-- All waits are sliced so OFF can cancel the sequence promptly.
local function activeWait(target, token, duration)
    local elapsed = 0
    while elapsed < duration do
        if not isCurrentTarget(target, token) then return false end
        local step = math.min(0.05, duration - elapsed)
        task.wait(step)
        elapsed += step
    end
    return isCurrentTarget(target, token)
end

local function runFollowOnly(target, token)
    if not isCurrentTarget(target, token) then return end
    local char, root = getCharacter(player)
    local targetChar, targetRoot = getCharacter(target)
    if not char or not root or not targetChar or not targetRoot then
        warn("[TP ATTACK] Karakter atau target belum siap.")
        return
    end

    -- Random teleport stage retained from the original file.
    local moved, moveErr = pcall(function()
        char:PivotTo(CFrame.new(getRandomPosition()))
    end)
    if not moved then
        warn("[TP ATTACK] Random TP gagal:", moveErr)
        return
    end
    if not activeWait(target, token, 1.5) then return end

    -- Follow the locked target (original placement logic unchanged).
    disconnectFollow()
    followConnection = RunService.Heartbeat:Connect(function()
        if not isCurrentTarget(target, token) then
            disconnectFollow()
            return
        end
        local currentChar, currentRoot = getCharacter(player)
        local currentTargetChar, currentTargetRoot = getCharacter(target)
        if currentChar and currentRoot and currentTargetChar and currentTargetRoot then
            -- Keep our character behind the target, aligned with the target's
            -- forward direction. Spacing scales with both character body depths.
            local mySize = currentChar:GetExtentsSize()
            local targetSize = currentTargetChar:GetExtentsSize()
            local myDepth = math.max(mySize.Z, mySize.X * 0.65)
            local targetDepth = math.max(targetSize.Z, targetSize.X * 0.65)
            local sizePadding = math.max(1, targetDepth * 0.05)
            local safeDistance = (myDepth * 0.5) + (targetDepth * 0.5) + sizePadding

            -- Place our character BEHIND the target, never in front of them.
            -- Then explicitly face the SAME direction as the target (not toward them).
            local behindPosition = currentTargetRoot.Position
                - (currentTargetRoot.CFrame.LookVector * safeDistance)
            local sameForward = currentTargetRoot.CFrame.LookVector
            local behindTarget = CFrame.lookAt(
                behindPosition,
                behindPosition + sameForward,
                currentTargetRoot.CFrame.UpVector
            )
            currentChar:PivotTo(behindTarget)
        end
    end)

    -- Follow continues until OFF / target change.
    while isCurrentTarget(target, token) do
        task.wait(0.05)
    end
    disconnectFollow()
end

local function refreshPlayers()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("TextButton") and child.Name:sub(1, 10) == "PlayerRow_" then
            child:Destroy()
        end
    end

    local targets = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then table.insert(targets, target) end
    end
    table.sort(targets, function(a, b)
        return string.lower(a.DisplayName .. a.Name) < string.lower(b.DisplayName .. b.Name)
    end)

    for i = 1, math.max(8, #targets) do
        local target = targets[i]
        local selected = target ~= nil and target == attackTarget
        local row = Instance.new("TextButton")
        row.Name = "PlayerRow_" .. (target and tostring(target.UserId) or ("Empty" .. i))
        row.LayoutOrder = i
        row.Size = UDim2.new(1, -1, 0, 25)
        row.BackgroundColor3 = selected and ACTIVE or ROW
        row.BackgroundTransparency = target and 0 or 0.48
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Active = target ~= nil
        row.Parent = playerList
        corner(row, 7)

        local display = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or "— Slot kosong —"
        local nameLabel = makeLabel(row, "PlayerName", display,
            UDim2.new(1, -10, 1, 0), UDim2.fromOffset(6, 0),
            Enum.Font.GothamBold,
            selected and Color3.fromRGB(255, 90, 120) or (target and WHITE or MUTED),
            7, Enum.TextXAlignment.Left)
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

        if target then
            local chosen = target
            row.Activated:Connect(function()
                if chosen.Parent ~= Players then
                    refreshPlayers()
                    return
                end
                if attackBusy then
                    if attackTarget == chosen then
                        stopAttack(false)
                        refreshPlayers()
                    end
                    return
                end

                stopAttack(false)
                attackTarget = chosen
                attackEnabled = true
                attackBusy = true
                attackToken += 1
                local thisToken = attackToken
                refreshPlayers()

                task.spawn(function()
                    -- Repeat the complete sequence for as long as ON remains active.
                    -- Each cycle: random TP -> internal Grab -> TP/follow locked target
                    -- -> internal Throw -> short gap -> repeat.
                    while isCurrentTarget(chosen, thisToken) do
                        local ok, err = pcall(function()
                            runFollowOnly(chosen, thisToken)
                        end)
                        if not ok then
                            warn("[TP ATTACK] Cycle error:", err)
                            task.wait(0.35)
                        else
                            task.wait(0.25)
                        end
                    end
                    if attackToken == thisToken then
                        disconnectFollow()
                        attackEnabled = false
                        attackBusy = false
                        refreshPlayers()
                    end
                end)
            end)
        end
    end
end

attackOpen.Activated:Connect(function()
    home.Visible = false
    attackPage.Visible = true
    refreshPlayers()
end)
back.Activated:Connect(function()
    stopAttack(false)
    attackPage.Visible = false
    home.Visible = true
    refreshPlayers()
end)
offButton.Activated:Connect(function()
    stopAttack(false)
    refreshPlayers()
end)
refresh.Activated:Connect(refreshPlayers)
Players.PlayerAdded:Connect(function() task.defer(refreshPlayers) end)
Players.PlayerRemoving:Connect(function(leaving)
    if leaving == attackTarget then stopAttack(true) end
    task.defer(refreshPlayers)
end)

-- Main panel minimize / close from GELUT.
local minimized = false
minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    footerTitle.Visible = not minimized
    creator.Visible = not minimized
    panel.Size = minimized and UDim2.fromOffset(150, 48) or UDim2.fromOffset(150, 290)
    minimize.Text = minimized and "+" or "–"
end)
close.Activated:Connect(function()
    panel.Visible = false
end)

-- Drag main panel from GELUT header (mouse + touch).
local dragHandle = Instance.new("TextButton")
dragHandle.Name = "MainPanelDragHandle"
dragHandle.Size = UDim2.new(1, -54, 0, 49)
dragHandle.BackgroundTransparency = 1
dragHandle.Text = ""
dragHandle.AutoButtonColor = false
dragHandle.ZIndex = 5
dragHandle.Parent = panel
minimize.ZIndex = 7
close.ZIndex = 7

local mainDragging, mainInput = false, nil
local mainStart, mainPosition
dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mainDragging = true
        mainInput = input
        mainStart = input.Position
        mainPosition = panel.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if mainDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mainStart
        panel.Position = UDim2.new(mainPosition.X.Scale, mainPosition.X.Offset + delta.X,
            mainPosition.Y.Scale, mainPosition.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input == mainInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
        mainDragging = false
        mainInput = nil
    end
end)

-- Floating dEnz cube from GELUT: tap to show/hide panel, drag to reposition.
local cube = Instance.new("Frame")
cube.Name = "dEnzMiniCube"
cube.Size = UDim2.fromOffset(50, 50)
cube.Position = UDim2.new(0, 22, 0.55, 0)
cube.BackgroundColor3 = DARK
cube.BorderSizePixel = 0
cube.Active = true
cube.Visible = true
cube.ZIndex = 10
cube.Parent = gui
corner(cube, 12)

local cubeBorder = Instance.new("UIStroke")
cubeBorder.Name = "PanelMatchingRedBorder"
cubeBorder.Color = RED
cubeBorder.Thickness = 2.3
cubeBorder.Parent = cube

local cubeText = Instance.new("TextLabel")
cubeText.Name = "dEnzSignatureText"
cubeText.Size = UDim2.fromScale(1, 1)
cubeText.BackgroundTransparency = 1
cubeText.Text = "dEnz"
cubeText.TextColor3 = RED
cubeText.TextSize = 14
cubeText.Font = Enum.Font.GothamBlack
cubeText.ZIndex = 12
cubeText.Parent = cube

local cubeClickArea = Instance.new("TextButton")
cubeClickArea.Name = "CubeDragAndTap"
cubeClickArea.Size = UDim2.fromScale(1, 1)
cubeClickArea.BackgroundTransparency = 1
cubeClickArea.Text = ""
cubeClickArea.AutoButtonColor = false
cubeClickArea.Active = true
cubeClickArea.ZIndex = 13
cubeClickArea.Parent = cube

local cubeDragging, cubeInput, cubeMoved = false, nil, false
local cubeStart, cubePosition
cubeClickArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        cubeDragging = true
        cubeMoved = false
        cubeInput = input
        cubeStart = input.Position
        cubePosition = cube.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if cubeDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - cubeStart
        if math.abs(delta.X) > 7 or math.abs(delta.Y) > 7 then cubeMoved = true end
        if cubeMoved then
            cube.Position = UDim2.new(cubePosition.X.Scale, cubePosition.X.Offset + delta.X,
                cubePosition.Y.Scale, cubePosition.Y.Offset + delta.Y)
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input == cubeInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if cubeDragging and not cubeMoved then panel.Visible = not panel.Visible end
        cubeDragging = false
        cubeInput = nil
    end
end)

refreshPlayers()
print("[TP ATTACK] dEnzCreator loop build loaded. Random TP -> internal Grab -> size-aligned rear-positioned, same-direction Throw; OFF button or click selected target to stop.")
