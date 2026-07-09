--[[ ------------------------------------------------------------------------
	Title: 			Minimap.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-21
	Description: 	Functions for Blizzards Addon Compartment system, which provides a minimap dropdown button without needing LibDataBroker or custom minimap handling.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

--[[---------------------------------------------------------------------------
    Function:   ToysByFunctionAddon_OpenOptions
    Purpose:    Open the addon's options panel in the Blizzard Interface Options.
-----------------------------------------------------------------------------]]
local function ToysByFunctionAddon_OpenOptions()
    if ns.data.settingsCategoryID and Settings then
        Settings.OpenToCategory(ns.data.settingsCategoryID)
    else
        -- let user know there was an issue, then open the options panel normally
        ns:Print(ns.L["Issue with addon options panel, cannot open settings. If persists please open a ticket."])
    end
end

--[[---------------------------------------------------------------------------
    Function:   ToysByFunctionAddon_ScanToys
    Purpose:    Scan the player's toy collection and update the addon's database.
-----------------------------------------------------------------------------]]
local function ToysByFunctionAddon_ScanToys()
    ns.ToyFunctions:LoadToySteps()
end

-- ---------------------------------------------------------------------------
-- ADDON COMPARTMENT HANDLERS
-- These MUST be global functions (not local, not on a table).
-- The function names MUST exactly match the TOC field values.
-- ---------------------------------------------------------------------------

-- Called when the user LEFT-clicks or RIGHT-clicks the compartment entry.
-- name: the addon name string (e.g. "CompartmentDemo")
-- mouseButton: "LeftButton" or "RightButton"
function ToysByFunctionAddon_OnClick(name, mouseButton)
    --@debug@
    -- functions for dev mode
    local function IsDevModeSelected()
        return ns.gets:GetDevMode()
    end
    local function SetDevMode()
        ns.sets:SetDevMode()
    end
    --@end-debug@

    -- process menu clicks
    if mouseButton == "LeftButton" then
        -- open main window
        ns:ShowFunctionUI()
    elseif mouseButton == "RightButton" then
        -- open functions window
        -- owner populated by the Compartment system, used as the anchor for the dropdown menu
        MenuUtil.CreateContextMenu(owner, function(owner, rootDescription)
            rootDescription:CreateButton(ns.L["Open Configuration"], function() ns:ShowConfigUI() end)
            rootDescription:CreateDivider()
            rootDescription:CreateButton("Open Addon Options", ToysByFunctionAddon_OpenOptions)
            rootDescription:CreateButton("(Re)Scan Toys", ToysByFunctionAddon_ScanToys)
            --@debug@
            rootDescription:CreateDivider()
            rootDescription:CreateCheckbox(ns.L["Dev Mode"], IsDevModeSelected, SetDevMode)
            --@end-debug@
        end)
        -- ns:Print("Minimap button right-clicked. No options menu yet, but this is where it would go.")
    end
end

-- Called when the mouse cursor enters the compartment entry.
-- Used to show a tooltip. menuButtonFrame is the anchor for the tooltip.
function ToysByFunctionAddon_OnEnter(name, menuButtonFrame)
    -- GameTooltip is the global shared tooltip frame used by most UI elements.
    -- SetOwner tells it where to appear and how to anchor.
    -- "ANCHOR_LEFT" positions the tooltip to the left of the anchor frame. 
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")

    -- SetText sets the title line (bold, larger font).
    GameTooltip:SetText(ns.L["Toys by Function"], 1, 1, 1)

    -- AddLine adds a body line. Args: text, r, g, b (0-1 color values).
    -- White text for primary instructions.
    GameTooltip:AddLine(ns.L["Left-click open main config window."], 0.7, 0.7, 0.7)
    -- Gray text for secondary instructions.
    GameTooltip:AddLine(ns.L["Right-click for function window."], 0.7, 0.7, 0.7)

    -- Show() makes the tooltip visible with all the lines we've added.
    GameTooltip:Show()
end

-- Called when the mouse cursor leaves the compartment entry.
-- Always hide the tooltip here to prevent it from lingering on screen.
function ToysByFunctionAddon_OnLeave(name, menuButtonFrame)
    GameTooltip:Hide()
end