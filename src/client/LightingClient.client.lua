--[[
    LIGHTING CLIENT - LOCAL ONLY
    Lighting changes are purely local (per-player)
    No server involvement - theme resets on rejoin
    
    Uses HUD template button for main trigger (Right side)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ✅ LOAD CONFIG
local LightingConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("LightingConfig"))

-- ✅ PANEL MANAGER
local PanelManager = require(script.Parent:WaitForChild("PanelManager"))

-- ✅ SKYBOX FOLDER
local skyboxesFolder = ReplicatedStorage:FindFirstChild("Skyboxes")

-- ✅ CURRENT THEME
local currentTheme = LightingConfig.DefaultTheme

-- ✅ COLOR SCHEME
local COLORS = {
    Background = Color3.fromRGB(25, 25, 30),
    Panel = Color3.fromRGB(30, 30, 35),
    Header = Color3.fromRGB(35, 35, 40),
    Button = Color3.fromRGB(45, 45, 50),
    ButtonHover = Color3.fromRGB(55, 55, 60),
    ButtonActive = Color3.fromRGB(88, 101, 242),
    Accent = Color3.fromRGB(255, 170, 80),
    AccentHover = Color3.fromRGB(255, 190, 100),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 185),
    Success = Color3.fromRGB(67, 181, 129),
    Border = Color3.fromRGB(50, 50, 55)
}

local THEME_COLORS = {
    Siang = Color3.fromRGB(255, 200, 100),
    Sore = Color3.fromRGB(255, 120, 80),
    Malam = Color3.fromRGB(80, 100, 180),
}

-- ✅ UTILITY FUNCTIONS
local function createCorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function createStroke(color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

-- ✅ CREATE SCREENGUI FOR POPUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LightingGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ==================== USE HUD BUTTON TEMPLATE (RIGHT SIDE) ====================

local hudGui = playerGui:WaitForChild("HUD", 10)
local rightFrame = hudGui and hudGui:FindFirstChild("Right")
local buttonTemplate = rightFrame and rightFrame:FindFirstChild("ButtonTemplate")

local floatingButton = nil
local buttonText = nil
local buttonContainer = nil

if buttonTemplate then
    -- ✅ Hide the original template
    buttonTemplate.Visible = false
    
    -- Clone the template
    buttonContainer = buttonTemplate:Clone()
    buttonContainer.Name = "LightButton"
    buttonContainer.Visible = true
    buttonContainer.LayoutOrder = 4 -- Fourth button on right (after Photo)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = rightFrame
    
    -- Get references
    floatingButton = buttonContainer:FindFirstChild("ImageButton")
    buttonText = buttonContainer:FindFirstChild("TextLabel")
    
    -- Set button properties
    if floatingButton then
        floatingButton.Image = "" -- No icon, using text
        floatingButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100) -- Sun color
        floatingButton.BackgroundTransparency = 0.3
        
        -- Add sun icon as text
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Text = "☀️"
        iconLabel.TextScaled = true
        iconLabel.Parent = floatingButton
        
        local iconConstraint = Instance.new("UITextSizeConstraint")
        iconConstraint.MaxTextSize = 28
        iconConstraint.Parent = iconLabel
    end
    
    if buttonText then
        buttonText.Text = "Light"
    end
    
    print("✅ [LIGHTING] Using HUD template button (Right)")
else
    -- Fallback: Create button manually if template not found
    warn("[LIGHTING] HUD template not found, creating button manually")
    
    floatingButton = Instance.new("ImageButton")
    floatingButton.Name = "LightButton"
    floatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
    floatingButton.Position = UDim2.new(0.99, 0, 0.7, 0)
    floatingButton.AnchorPoint = Vector2.new(1, 0)
    floatingButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    floatingButton.BackgroundTransparency = 0.3
    floatingButton.BorderSizePixel = 0
    floatingButton.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 0)
    corner.Parent = floatingButton
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = "☀️"
    iconLabel.TextScaled = true
    iconLabel.Parent = floatingButton
    
    buttonText = Instance.new("TextLabel")
    buttonText.Size = UDim2.new(1, 0, 0.3, 0)
    buttonText.Position = UDim2.new(0, 0, 1, 2)
    buttonText.BackgroundTransparency = 1
    buttonText.Font = Enum.Font.GothamBold
    buttonText.Text = "Light"
    buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
    buttonText.TextScaled = true
    buttonText.Parent = floatingButton
end

-- ✅ PANEL STATE
local panelOpen = false

-- ✅ TOGGLE PANEL FUNCTION (forward declaration)
local togglePanel

-- ✅ CREATE POPUP PANEL
local popupPanel = Instance.new("Frame")
popupPanel.Name = "LightingPopup"
popupPanel.Size = UDim2.new(0.28, 0, 0.45, 0)
popupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
popupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
popupPanel.BackgroundColor3 = COLORS.Background
popupPanel.BorderSizePixel = 0
popupPanel.Visible = false
popupPanel.Parent = screenGui

createCorner(12).Parent = popupPanel
createStroke(COLORS.Border, 2).Parent = popupPanel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = popupPanel

createCorner(12).Parent = header

local headerBottom = Instance.new("Frame")
headerBottom.Size = UDim2.new(1, 0, 0, 15)
headerBottom.Position = UDim2.new(0, 0, 1, -15)
headerBottom.BackgroundColor3 = COLORS.Header
headerBottom.BorderSizePixel = 0
headerBottom.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "💡 Pilih Suasana"
title.TextColor3 = COLORS.Text
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = COLORS.Button
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "✕"
closeButton.TextColor3 = COLORS.Text
closeButton.TextSize = 18
closeButton.Parent = header

createCorner(6).Parent = closeButton

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 60)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = popupPanel

-- Scrolling Frame for Themes
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = contentContainer

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- ✅ UPDATE ACTIVE THEME VISUALS (forward declaration)
local updateThemeVisuals

-- ✅ APPLY LIGHTING LOCALLY (purely local, no server)
local function applyLightingLocal(themeKey)
    local theme = LightingConfig.Themes[themeKey]
    if not theme then
        warn(string.format("[LIGHTING] ❌ Theme not found: %s", themeKey))
        return
    end
    
    print(string.format("[LIGHTING] 🎨 Applying theme: %s", themeKey))
    
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Apply lighting properties
    TweenService:Create(Lighting, tweenInfo, {
        Ambient = theme.Ambient,
        Brightness = theme.Brightness,
        ExposureCompensation = theme.ExposureCompensation,
        OutdoorAmbient = theme.OutdoorAmbient,
        ColorShift_Top = theme.ColorShift_Top,
        GeographicLatitude = theme.GeographicLatitude
    }):Play()
    
    Lighting.TimeOfDay = theme.TimeOfDay
    
    -- Apply atmosphere
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        TweenService:Create(atmosphere, tweenInfo, {
            Density = theme.AtmosphereDensity,
            Offset = theme.AtmosphereOffset
        }):Play()
    end
    
    -- Apply skybox
    if skyboxesFolder then
        local skyboxTemplate = skyboxesFolder:FindFirstChild(theme.Skybox)
        
        if skyboxTemplate and skyboxTemplate:IsA("Sky") then
            -- Remove existing Sky objects
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") then
                    child:Destroy()
                end
            end
            
            task.wait()
            
            -- Clone and apply new skybox
            local newSky = skyboxTemplate:Clone()
            newSky.Name = theme.Skybox
            newSky.Parent = Lighting
        end
    end
    
    currentTheme = themeKey
    if updateThemeVisuals then
        updateThemeVisuals(themeKey)
    end
    print(string.format("[LIGHTING] ✅ Theme applied: %s", themeKey))
end

-- ✅ CREATE THEME BUTTONS
local themeButtons = {}

for index, themeKey in ipairs(LightingConfig.ThemeOrder) do
    local theme = LightingConfig.Themes[themeKey]
    if not theme then continue end
    
    local buttonColor = THEME_COLORS[themeKey] or COLORS.Accent
    
    local themeBtn = Instance.new("TextButton")
    themeBtn.Name = themeKey .. "Button"
    themeBtn.Size = UDim2.new(1, 0, 0, 70)
    themeBtn.BackgroundColor3 = COLORS.Button
    themeBtn.BorderSizePixel = 0
    themeBtn.Text = ""
    themeBtn.AutoButtonColor = false
    themeBtn.LayoutOrder = index
    themeBtn.Parent = scrollFrame
    
    createCorner(10).Parent = themeBtn
    
    local activeBar = Instance.new("Frame")
    activeBar.Name = "ActiveBar"
    activeBar.Size = UDim2.new(0, 4, 0.8, 0)
    activeBar.Position = UDim2.new(0, 5, 0.1, 0)
    activeBar.BackgroundColor3 = buttonColor
    activeBar.BackgroundTransparency = 0.7
    activeBar.BorderSizePixel = 0
    activeBar.Parent = themeBtn
    
    createCorner(2).Parent = activeBar
    
    local btnIcon = Instance.new("TextLabel")
    btnIcon.Size = UDim2.new(0, 50, 1, 0)
    btnIcon.Position = UDim2.new(0, 15, 0, 0)
    btnIcon.BackgroundTransparency = 1
    btnIcon.Font = Enum.Font.GothamBold
    btnIcon.Text = theme.Icon
    btnIcon.TextColor3 = COLORS.Text
    btnIcon.TextScaled = true
    btnIcon.Parent = themeBtn
    
    local btnIconConstraint = Instance.new("UITextSizeConstraint")
    btnIconConstraint.MaxTextSize = 36
    btnIconConstraint.Parent = btnIcon
    
    local btnTitle = Instance.new("TextLabel")
    btnTitle.Size = UDim2.new(1, -80, 0.5, 0)
    btnTitle.Position = UDim2.new(0, 70, 0, 10)
    btnTitle.BackgroundTransparency = 1
    btnTitle.Font = Enum.Font.GothamBold
    btnTitle.Text = theme.DisplayName
    btnTitle.TextColor3 = COLORS.Text
    btnTitle.TextSize = 16
    btnTitle.TextXAlignment = Enum.TextXAlignment.Left
    btnTitle.Parent = themeBtn
    
    local btnDesc = Instance.new("TextLabel")
    btnDesc.Size = UDim2.new(1, -80, 0.4, 0)
    btnDesc.Position = UDim2.new(0, 70, 0.5, 0)
    btnDesc.BackgroundTransparency = 1
    btnDesc.Font = Enum.Font.Gotham
    btnDesc.Text = theme.Description
    btnDesc.TextColor3 = COLORS.TextSecondary
    btnDesc.TextSize = 12
    btnDesc.TextXAlignment = Enum.TextXAlignment.Left
    btnDesc.TextTruncate = Enum.TextTruncate.AtEnd
    btnDesc.Parent = themeBtn
    
    local checkmark = Instance.new("TextLabel")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(0, 30, 0, 30)
    checkmark.Position = UDim2.new(1, -40, 0.5, -15)
    checkmark.BackgroundTransparency = 1
    checkmark.Font = Enum.Font.GothamBold
    checkmark.Text = "✓"
    checkmark.TextColor3 = COLORS.Success
    checkmark.TextSize = 20
    checkmark.Visible = false
    checkmark.Parent = themeBtn
    
    themeBtn.MouseEnter:Connect(function()
        TweenService:Create(themeBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.ButtonHover
        }):Play()
        TweenService:Create(activeBar, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3
        }):Play()
    end)
    
    themeBtn.MouseLeave:Connect(function()
        if currentTheme ~= themeKey then
            TweenService:Create(themeBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.Button
            }):Play()
            TweenService:Create(activeBar, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.7
            }):Play()
        end
    end)
    
    themeBtn.MouseButton1Click:Connect(function()
        if currentTheme == themeKey then return end
        
        -- ✅ Apply lighting locally
        applyLightingLocal(themeKey)
        
        -- ✅ Close panel after selection
        if panelOpen then
            togglePanel()
        end
    end)
    
    themeButtons[themeKey] = {
        Button = themeBtn,
        ActiveBar = activeBar,
        Checkmark = checkmark,
        Color = buttonColor
    }
end

-- ✅ UPDATE ACTIVE THEME VISUALS
updateThemeVisuals = function(themeKey)
    for key, data in pairs(themeButtons) do
        if key == themeKey then
            TweenService:Create(data.Button, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(
                    math.floor(data.Color.R * 255 * 0.3 + COLORS.Button.R * 255 * 0.7),
                    math.floor(data.Color.G * 255 * 0.3 + COLORS.Button.G * 255 * 0.7),
                    math.floor(data.Color.B * 255 * 0.3 + COLORS.Button.B * 255 * 0.7)
                )
            }):Play()
            TweenService:Create(data.ActiveBar, TweenInfo.new(0.3), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 5, 0.8, 0)
            }):Play()
            data.Checkmark.Visible = true
        else
            TweenService:Create(data.Button, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Button
            }):Play()
            TweenService:Create(data.ActiveBar, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.7,
                Size = UDim2.new(0, 4, 0.8, 0)
            }):Play()
            data.Checkmark.Visible = false
        end
    end
end

-- ✅ CLOSE PANEL FUNCTION (for PanelManager)
local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    TweenService:Create(popupPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    task.delay(0.2, function()
        popupPanel.Visible = false
    end)
    PanelManager:Close("LightingPanel")
end

-- ✅ OPEN PANEL FUNCTION (for PanelManager)
local function openPanel()
    PanelManager:Open("LightingPanel")
    panelOpen = true
    popupPanel.Size = UDim2.new(0, 0, 0, 0)
    popupPanel.Visible = true
    TweenService:Create(popupPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.28, 0, 0.45, 0)
    }):Play()
end

-- ✅ TOGGLE PANEL
togglePanel = function()
    if panelOpen then
        closePanel()
    else
        openPanel()
    end
end

-- Register with PanelManager
PanelManager:Register("LightingPanel", closePanel)

-- ✅ BUTTON CLICK
if floatingButton then
    floatingButton.MouseButton1Click:Connect(function()
        togglePanel()
    end)
end

-- ✅ CLOSE BUTTON EVENTS
closeButton.MouseButton1Click:Connect(closePanel)

closeButton.MouseEnter:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = COLORS.ButtonHover
    }):Play()
end)

closeButton.MouseLeave:Connect(function()
    TweenService:Create(closeButton, TweenInfo.new(0.2), {
        BackgroundColor3 = COLORS.Button
    }):Play()
end)

-- ✅ ADAPTIVE SCALING FOR POPUP
local function updateScale()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if viewportSize.X < 600 then
        if panelOpen then
            popupPanel.Size = UDim2.new(0.85, 0, 0.55, 0)
        end
    else
        if panelOpen then
            popupPanel.Size = UDim2.new(0.28, 0, 0.45, 0)
        end
    end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- ✅ INITIALIZE - Apply default theme
task.spawn(function()
    task.wait(1)
    
    -- Apply default theme on load
    applyLightingLocal(LightingConfig.DefaultTheme)
    updateThemeVisuals(LightingConfig.DefaultTheme)
    print(string.format("[LIGHTING] Initialized with theme: %s", LightingConfig.DefaultTheme))
end)

print("✅ [LIGHTING CLIENT] Loaded (Local Only - No Persistence)")
