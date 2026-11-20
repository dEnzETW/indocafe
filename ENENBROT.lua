--[[
    ENENBROT | Standalone Defense Panel
    Version: 0.1.1
    Status: Initial CORE DEFENSE extraction + panel foundation
    Visual reference: dEnzCreator (dark navy / purple accent / Gotham)
    Width reference: 125 px

    Separation:
      - Does not load, modify, or depend on dEnzCreator.
      - Does not overwrite Empty Tools or MountEiger source files.
      - All non-CORE modules are placeholders and remain inactive.
      - Anchor Lock is experimental and intentionally unavailable in this build.

    CORE DEFENSE:
      - Anchor Deflect: suppresses supported force objects on the local character.
      - Anti Anchor: detects and releases anchored BaseParts on the local character.
      - Both modules track state and clean up their own connections/state on OFF.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

--==================================================
-- ENENBROT CONFIG / STATE
--==================================================

local PANEL_WIDTH = 125
local HEADER_HEIGHT = 32
local PANEL_BG = Color3.fromRGB(7, 10, 27)
local HEADER_BG = Color3.fromRGB(7, 10, 27)
local BORDER = Color3.fromRGB(83, 99, 226)
local TEXT = Color3.fromRGB(245, 247, 255)
local MUTED = Color3.fromRGB(190, 197, 220)
local ROW_BG = Color3.fromRGB(17, 22, 48)
local OFF_BG = Color3.fromRGB(15, 20, 43)
local ON_BG = Color3.fromRGB(28, 145, 82)
local FOLDER_BG = Color3.fromRGB(48, 66, 103)
local EXPERIMENTAL_BG = Color3.fromRGB(39, 43, 65)

local featureState = {
    AnchorDeflect = false,
    AntiAnchor = false,
    AnchorLock = false,
}

local connections = {}
local originalForceProperties = {}
local originalAnchored = {}
local currentCharacter = nil
local characterAddedConnection = nil
local isShuttingDown = false

local function disconnect(name)
    local connection = connections[name]
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
        connections[name] = nil
    end
end

local function safeGet(object, property)
    local ok, value = pcall(function()
        return object[property]
    end)
    if ok then
        return value
    end
    return nil
end

local function safeSet(object, property, value)
    return pcall(function()
        object[property] = value
    end)
end

local function isForceObject(object)
    if not object then
        return false
    end

    return object:IsA("BodyMover")
        or object:IsA("LinearVelocity")
        or object:IsA("AngularVelocity")
        or object:IsA("VectorForce")
        or object:IsA("AlignPosition")
        or object:IsA("AlignOrientation")
        or object:IsA("Torque")
end

local FORCE_ZERO_VALUES = {
    MaxForce = Vector3.zero,
    MaxTorque = Vector3.zero,
    Force = Vector3.zero,
    Torque = Vector3.zero,
    Velocity = Vector3.zero,
    AngularVelocity = Vector3.zero,
    P = 0,
    D = 0,
    Responsiveness = 0,
    Enabled = false,
}

local function suppressForceObject(object)
    if not object or not object.Parent or originalForceProperties[object] then
        return
    end

    local saved = {}

    -- Save each property only when the property exists and the write succeeds.
    for property, zeroValue in pairs(FORCE_ZERO_VALUES) do
        local oldValue = safeGet(object, property)
        if oldValue ~= nil then
            local ok = safeSet(object, property, zeroValue)
            if ok then
                saved[property] = oldValue
            end
        end
    end

    if next(saved) ~= nil then
        originalForceProperties[object] = saved
        pcall(function()
            object:SetAttribute("ENENBROT_Suppressed", true)
        end)
    end
end

local function restoreForceObjects()
    for object, properties in pairs(originalForceProperties) do
        if object and object.Parent then
            for property, oldValue in pairs(properties) do
                safeSet(object, property, oldValue)
            end
            pcall(function()
                object:SetAttribute("ENENBROT_Suppressed", nil)
            end)
        end
    end
    table.clear(originalForceProperties)
end

local function scanCharacterForForces(character)
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if isForceObject(object) then
            suppressForceObject(object)
        end
    end
end

local function startAnchorDeflect(character)
    disconnect("DeflectDescendantAdded")
    restoreForceObjects()

    currentCharacter = character
    scanCharacterForForces(character)

    if character then
        connections.DeflectDescendantAdded = character.DescendantAdded:Connect(function(object)
            if not featureState.AnchorDeflect then
                return
            end
            if isForceObject(object) then
                -- Dynamic objects are tracked too; this fixes the source behavior
                -- where newly-added force objects were suppressed without snapshots.
                suppressForceObject(object)
            end
        end)
    end
end

local function stopAnchorDeflect()
    disconnect("DeflectDescendantAdded")
    restoreForceObjects()
end

local function restoreAnchoredParts()
    for part, wasAnchored in pairs(originalAnchored) do
        if part and part.Parent then
            safeSet(part, "Anchored", wasAnchored)
        end
    end
    table.clear(originalAnchored)
end

local function releaseAnchoredPart(part)
    if not part or not part:IsA("BasePart") then
        return
    end

    if originalAnchored[part] == nil then
        originalAnchored[part] = part.Anchored
    end

    if part.Anchored then
        safeSet(part, "Anchored", false)
    end
end

local function scanCharacterForAnchoredParts(character)
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            releaseAnchoredPart(object)
        end
    end
end

local function startAntiAnchor(character)
    disconnect("AntiAnchorDescendantAdded")
    disconnect("AntiAnchorRender")
    restoreAnchoredParts()

    currentCharacter = character
    scanCharacterForAnchoredParts(character)

    if character then
        connections.AntiAnchorDescendantAdded = character.DescendantAdded:Connect(function(object)
            if featureState.AntiAnchor and object:IsA("BasePart") then
                releaseAnchoredPart(object)
            end
        end)
    end

    connections.AntiAnchorRender = RunService.RenderStepped:Connect(function()
        if not featureState.AntiAnchor then
            return
        end

        local activeCharacter = LocalPlayer.Character
        if not activeCharacter then
            return
        end

        for _, object in ipairs(activeCharacter:GetDescendants()) do
            if object:IsA("BasePart") and object.Anchored then
                releaseAnchoredPart(object)
            end
        end
    end)
end

local function stopAntiAnchor()
    disconnect("AntiAnchorDescendantAdded")
    disconnect("AntiAnchorRender")
    restoreAnchoredParts()
end

local function setFeature(featureName, enabled)
    enabled = enabled == true
    if featureState[featureName] == nil then
        return false
    end

    featureState[featureName] = enabled

    if featureName == "AnchorDeflect" then
        if enabled then
            startAnchorDeflect(LocalPlayer.Character)
        else
            stopAnchorDeflect()
        end
    elseif featureName == "AntiAnchor" then
        if enabled then
            startAntiAnchor(LocalPlayer.Character)
        else
            stopAntiAnchor()
        end
    end

    return true
end

-- Character respawn handling: re-apply only enabled modules.
characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.25)
    currentCharacter = character

    if featureState.AnchorDeflect then
        startAnchorDeflect(character)
    end
    if featureState.AntiAnchor then
        startAntiAnchor(character)
    end
end)

--==================================================
-- UI FOUNDATION
--==================================================

local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ENENBROT_UI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ENENBROT_UI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(PANEL_WIDTH, 40)
panel.Position = UDim2.new(0, 18, 0.28, 0)
panel.BackgroundColor3 = PANEL_BG
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Active = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 9)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = BORDER
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
header.BackgroundColor3 = HEADER_BG
header.BorderSizePixel = 0
header.Active = true
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -34, 1, 0)
title.Position = UDim2.fromOffset(8, 0)
title.BackgroundTransparency = 1
title.Text = "ENENBROT"
title.TextColor3 = TEXT
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Size = UDim2.fromOffset(25, 25)
minimize.Position = UDim2.new(1, -29, 0, 3)
minimize.BackgroundColor3 = Color3.fromRGB(28, 34, 57)
minimize.BorderSizePixel = 0
minimize.Text = "–"
minimize.TextColor3 = TEXT
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 17
minimize.Parent = header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimize

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "FolderList"
scroll.Position = UDim2.fromOffset(5, 37)
scroll.Size = UDim2.new(1, -10, 1, -42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = BORDER
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local function makeToggle(parent, labelText, featureName, order, isAvailable)
    -- Whole feature row is the toggle surface: OFF = navy, ON = green.
    -- No separate circular switch or ON/OFF text is displayed.
    local row = Instance.new("TextButton")
    row.Name = featureName or ("Placeholder_" .. tostring(order))
    row.Size = UDim2.new(1, -2, 0, 22)
    row.BackgroundColor3 = OFF_BG
    row.BorderSizePixel = 0
    row.AutoButtonColor = isAvailable
    row.Active = isAvailable
    row.Text = ""
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 5)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.fromOffset(6, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = isAvailable and MUTED or Color3.fromRGB(112, 119, 143)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row

    local enabled = false
    local function render()
        row.BackgroundColor3 = enabled and ON_BG or OFF_BG
        row.BackgroundTransparency = isAvailable and 0 or 0.25
        label.TextColor3 = isAvailable and TEXT or Color3.fromRGB(112, 119, 143)
    end
    render()

    if isAvailable then
        row.Activated:Connect(function()
            enabled = not enabled
            render()
            setFeature(featureName, enabled)
        end)
    end

    return {
        Set = function(value)
            if not isAvailable then
                return
            end
            enabled = value == true
            render()
            setFeature(featureName, enabled)
        end,
        Get = function()
            return enabled
        end,
        Available = isAvailable,
    }
end

local folders = {
    {
        key = "01_CORE_DEFENSE",
        title = "CORE DEFENSE",
        features = {
            {label = "Anchor Deflect", key = "AnchorDeflect", available = true},
            {label = "Anti Anchor", key = "AntiAnchor", available = true},
            {label = "Force Protection", key = nil, available = false},
            {label = "Anchor Lock (WIP)", key = "AnchorLock", available = false},
        }
    },
    {
        key = "02_ANTI_FLING",
        title = "ANTI-FLING",
        features = {
            {label = "Anti-Fling", available = false},
            {label = "Velocity Guard", available = false},
            {label = "Angular Velocity Guard", available = false},
            {label = "Safe Position Recovery", available = false},
        }
    },
    {
        key = "03_CHARACTER_STABILITY",
        title = "CHARACTER",
        features = {
            {label = "Anti-Ragdoll", available = false},
            {label = "Physics State Protection", available = false},
            {label = "PlatformStand Protection", available = false},
            {label = "Character Recovery", available = false},
        }
    },
    {
        key = "04_GRAB_DEFENSE",
        title = "GRAB DEFENSE",
        features = {
            {label = "Grab Detection", available = false},
            {label = "Position Change Monitor", available = false},
            {label = "Follow / Carry Detection", available = false},
            {label = "Grab State Monitor", available = false},
        }
    },
    {
        key = "05_MOVEMENT_PROTECTION",
        title = "MOVEMENT",
        features = {
            {label = "Movement Monitor", available = false},
            {label = "Movement Anomaly Detection", available = false},
            {label = "Movement Recovery", available = false},
        }
    },
    {
        key = "06_DIAGNOSTICS",
        title = "DIAGNOSTICS",
        features = {
            {label = "Force Object Logger", available = false},
            {label = "Velocity Monitor", available = false},
            {label = "Character State Logger", available = false},
            {label = "Test Mode", available = false},
        }
    },
    {
        key = "07_SETTINGS",
        title = "SETTINGS",
        features = {
            {label = "Auto Restore", available = false},
            {label = "Safe Shutdown", available = false},
            {label = "Save Configuration", available = false},
            {label = "Reset Configuration", available = false},
        }
    },
    {
        key = "08_EXPERIMENTAL",
        title = "EXPERIMENTAL",
        features = {
            {label = "Experimental Module A", available = false},
            {label = "Experimental Module B", available = false},
            {label = "WIP Features", available = false},
        }
    },
}

local folderControllers = {}
local function createFolder(folderData, folderOrder)
    local wrapper = Instance.new("Frame")
    wrapper.Name = folderData.key
    wrapper.Size = UDim2.new(1, -2, 0, 25)
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0
    wrapper.LayoutOrder = folderOrder
    wrapper.Parent = scroll

    local folderHeader = Instance.new("Frame")
    folderHeader.Name = "FolderHeader"
    folderHeader.Size = UDim2.new(1, 0, 0, 25)
    folderHeader.BackgroundColor3 = FOLDER_BG
    folderHeader.BorderSizePixel = 0
    folderHeader.Parent = wrapper

    local folderCorner = Instance.new("UICorner")
    folderCorner.CornerRadius = UDim.new(0, 6)
    folderCorner.Parent = folderHeader

    local folderTitle = Instance.new("TextLabel")
    folderTitle.Size = UDim2.new(1, -45, 1, 0)
    folderTitle.Position = UDim2.fromOffset(6, 0)
    folderTitle.BackgroundTransparency = 1
    folderTitle.Text = folderData.title
    folderTitle.TextColor3 = TEXT
    folderTitle.Font = Enum.Font.GothamBold
    folderTitle.TextSize = 9
    folderTitle.TextXAlignment = Enum.TextXAlignment.Left
    folderTitle.TextTruncate = Enum.TextTruncate.AtEnd
    folderTitle.Parent = folderHeader

    local master = Instance.new("TextButton")
    master.Name = "FolderMaster"
    master.Size = UDim2.fromOffset(17, 23)
    master.Position = UDim2.new(1, -42, 0, 1)
    master.BackgroundTransparency = 1
    master.BorderSizePixel = 0
    master.Text = ""
    master.Parent = folderHeader

    local expand = Instance.new("TextButton")
    expand.Name = "Expand"
    expand.Size = UDim2.fromOffset(20, 23)
    expand.Position = UDim2.new(1, -22, 0, 1)
    expand.BackgroundTransparency = 1
    expand.Text = "+"
    expand.TextColor3 = TEXT
    expand.Font = Enum.Font.GothamBold
    expand.TextSize = 13
    expand.Parent = folderHeader

    local content = Instance.new("Frame")
    content.Name = "Features"
    content.Position = UDim2.fromOffset(0, 28)
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = wrapper

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    local controllers = {}
    local availableControllers = {}

    for index, feature in ipairs(folderData.features) do
        local controller = makeToggle(
            content,
            feature.label,
            feature.key,
            index,
            feature.available == true
        )
        table.insert(controllers, controller)
        if controller.Available then
            table.insert(availableControllers, controller)
        end
    end

    local expanded = false
    local masterEnabled = false
    local function updateMasterVisual()
        folderHeader.BackgroundColor3 = masterEnabled and ON_BG or FOLDER_BG
    end

    local function setExpanded(value)
        expanded = value
        content.Visible = expanded
        expand.Text = expanded and "–" or "+"
        local contentHeight = expanded and (#folderData.features * 24 - 2) or 0
        content.Size = UDim2.new(1, 0, 0, contentHeight)
        wrapper.Size = UDim2.new(1, -2, 0, expanded and (28 + contentHeight) or 25)
    end

    expand.Activated:Connect(function()
        setExpanded(not expanded)
    end)

    folderHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            -- Header title area toggles accordion; master/expand buttons remain independent.
            local x = input.Position.X
            local rightEdge = folderHeader.AbsolutePosition.X + folderHeader.AbsoluteSize.X
            if x < rightEdge - 43 then
                setExpanded(not expanded)
            end
        end
    end)

    master.Activated:Connect(function()
        masterEnabled = not masterEnabled
        for _, controller in ipairs(availableControllers) do
            controller.Set(masterEnabled)
        end
        updateMasterVisual()
    end)

    folderControllers[folderData.key] = {
        SetMaster = function(value)
            masterEnabled = value == true
            for _, controller in ipairs(availableControllers) do
                controller.Set(masterEnabled)
            end
            updateMasterVisual()
        end
    }
end

for index, folder in ipairs(folders) do
    createFolder(folder, index)
end

--==================================================
-- PANEL DRAG / MINIMIZE / CLEANUP
--==================================================

local minimized = false
local expandedHeight = 300

local function updatePanelHeight()
    if minimized then
        panel.Size = UDim2.fromOffset(PANEL_WIDTH, HEADER_HEIGHT + 8)
        scroll.Visible = false
    else
        panel.Size = UDim2.fromOffset(PANEL_WIDTH, expandedHeight)
        scroll.Visible = true
    end
end

minimize.Activated:Connect(function()
    minimized = not minimized
    minimize.Text = minimized and "+" or "–"
    updatePanelHeight()
end)

do
    local dragging = false
    local dragStart
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
        end
    end)

    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function safeShutdown()
    if isShuttingDown then
        return
    end
    isShuttingDown = true

    featureState.AnchorDeflect = false
    featureState.AntiAnchor = false
    stopAnchorDeflect()
    stopAntiAnchor()

    if characterAddedConnection then
        pcall(function()
            characterAddedConnection:Disconnect()
        end)
        characterAddedConnection = nil
    end

    for name in pairs(connections) do
        disconnect(name)
    end

    if gui and gui.Parent then
        gui:Destroy()
    end
end

-- Bind shutdown to GUI removal; no global executor hooks are used.
gui.Destroying:Connect(function()
    if not isShuttingDown then
        safeShutdown()
    end
end)

updatePanelHeight()
print("[ENENBROT] v0.1.1 loaded | CORE DEFENSE foundation ready")
