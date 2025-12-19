--[[
    PANEL MANAGER - Prevents panel stacking
    When one panel opens, all others automatically close
    
    Usage:
    local PanelManager = require(script.Parent:WaitForChild("PanelManager"))
    
    -- Register your panel
    PanelManager:Register("ShopPanel", closeFunction)
    
    -- When opening your panel
    PanelManager:Open("ShopPanel")
    
    -- When closing your panel
    PanelManager:Close("ShopPanel")
]]

local PanelManager = {}

-- Stores registered panels and their close functions
local registeredPanels = {}
local currentOpenPanel = nil

-- Register a panel with its close function
function PanelManager:Register(panelName, closeFunction)
    registeredPanels[panelName] = {
        closeFunc = closeFunction,
        isOpen = false
    }
end

-- Open a panel (closes all other panels first)
function PanelManager:Open(panelName)
    -- Close all other panels first
    for name, panel in pairs(registeredPanels) do
        if name ~= panelName and panel.isOpen then
            if panel.closeFunc then
                panel.closeFunc()
            end
            panel.isOpen = false
        end
    end
    
    -- Mark this panel as open
    if registeredPanels[panelName] then
        registeredPanels[panelName].isOpen = true
        currentOpenPanel = panelName
    end
end

-- Close a specific panel
function PanelManager:Close(panelName)
    if registeredPanels[panelName] then
        registeredPanels[panelName].isOpen = false
        if currentOpenPanel == panelName then
            currentOpenPanel = nil
        end
    end
end

-- Check if a panel is currently open
function PanelManager:IsOpen(panelName)
    if registeredPanels[panelName] then
        return registeredPanels[panelName].isOpen
    end
    return false
end

-- Get currently open panel name
function PanelManager:GetCurrentPanel()
    return currentOpenPanel
end

-- Close all panels
function PanelManager:CloseAll()
    for name, panel in pairs(registeredPanels) do
        if panel.isOpen and panel.closeFunc then
            panel.closeFunc()
        end
        panel.isOpen = false
    end
    currentOpenPanel = nil
end

return PanelManager
