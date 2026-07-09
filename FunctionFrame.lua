--[[ ------------------------------------------------------------------------
	Title: 			FunctionFrame.lua
	Author: 		mrbryo
	Create Date : 	07/08/2025
	Description: 	Standard UI window for using toys post configuration being completed.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

ns.funcFrame = {
    scrollKey = "FunctionFrame"
}

--[[---------------------------------------------------------------------------
    Function:   CreateToyMainOptionsButton
    Purpose:    Create a button that opens a dropdown menu for toy options.
                This includes sorting order and tooltip display options.
-----------------------------------------------------------------------------]]
local function CreateOptionButton(parent)
    -- local functions for sorting
    local function SetSorting(key)
        --@debug@
        -- ns:Print(("SetToySortingOrderMainConfig called with key: %s"):format(tostring(key)))
        --@end-debug@
        ns.sets:SetToySortingOrderFunctionFrame(key)
        ns.toyScroll:PopulateToysByTag(ns.funcFrame.scrollKey)
    end

    local function GetSorting(key)
        local value = ns.gets:GetToySortingOrderFunctionFrame() -- ns.gets:GetToySortingOrderMainConfig()
        --@debug@
        -- ns:Print(("GetToySortingOrderFunctionFrame returned value: %s"):format(tostring(value)))
        --@end-debug@
        return value == key
    end

    -- local functions for showing tooltips
    local function SetTooltips()
        ns.toyScroll:SetTooltipOption(ns.funcFrame.scrollKey)
    end

    local function IsTooltipEnabled()
        local value = ns.toyScroll:GetTooltipOption(ns.funcFrame.scrollKey)
        --@debug@
        -- ns:Print(("(IsTooltipEnabled) Show Toy Tooltips option is: %s"):format(tostring(value)))
        --@end-debug@
        return value
    end

    -- local function for restoring window size
    local function ResetWindowSize()
        local frameWidth = ns.data.constants.ui.functionFrame.minWidth
        local frameHeight = ns.data.constants.ui.functionFrame.minHeight
        ns.sets:SetFrameSize(ns.data.ui.frame.useToys:GetName(), frameWidth, frameHeight)
        ns.data.ui.frame.useToys:SetWidth(frameWidth)
        ns.data.ui.frame.useToys:SetHeight(frameHeight)
    end

    -- local functions for toy effects showing
    local function IsToyEffectsEnabled()
        local value = ns.toyScroll:GetToyEffectsOption(ns.funcFrame.scrollKey)
        return value
    end

    local function SetToyEffects()
        ns.toyScroll:SetToyEffectsOption(ns.funcFrame.scrollKey)
        ns.toyScroll:PopulateToysByTag(ns.funcFrame.scrollKey)
    end

    -- generate the menu
    local function GeneratorFunction(owner, rootDescription)
        -- checkbox for enabling/disabling toy tooltips
        rootDescription:CreateCheckbox(ns.L["Show Toy Tooltips"], IsTooltipEnabled, SetTooltips)

        -- checkbox for enabling/disabling toy effect
        rootDescription:CreateCheckbox(ns.L["Show Toy Effects"], IsToyEffectsEnabled, SetToyEffects)

        -- submenu for setting sort order
        local sortSubMenu = rootDescription:CreateButton("Sort");
        sortSubMenu:CreateRadio(ns.L["A-Z"], GetSorting, SetSorting, "az")
        sortSubMenu:CreateRadio(ns.L["Z-A"], GetSorting, SetSorting, "za")

        -- reset window size
        rootDescription:CreateDivider()
        rootDescription:CreateButton(ns.L["Reset Window Size"], function(itself)
            ResetWindowSize()
        end)
    end

    -- create dropdown button using the format which shows the button name with a right facing arrow
    local button = CreateFrame("DropdownButton", nil, parent, "WowStyle1FilterDropdownTemplate")
    -- button:SetSize(width, 22)
    button:SetText(ns.L["Options"])
    button:SetupMenu(GeneratorFunction)

    -- finally return the button to be positioned and visible in the UI
    return button
end

--[[---------------------------------------------------------------------------
    Function:   ShowFunctionUI
    Purpose:    Open UI to view just a dropdown of the tags and the toys assigned to the selected tag. A search filter is available.
-----------------------------------------------------------------------------]]
function ns:ShowFunctionUI()
    -- frame name
    local frameName = "ToysByFunctionUseToysFrame"

    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- if already created exit function
    if ns.data.ui.frame.useToys ~= nil then
        return
    end

    -- set initial sizes
    local frameSize = ns.gets:GetFrameSize(frameName)
    local frameWidth = frameSize.width or nil
    local frameHeight = frameSize.height or nil

    -- make sure its the minimum size
    if frameWidth ~= nil and frameHeight ~= nil then
        if frameWidth < ns.data.constants.ui.functionFrame.minWidth then
            frameWidth = ns.data.constants.ui.functionFrame.minWidth
        end
        if frameHeight < ns.data.constants.ui.functionFrame.minHeight then
            frameHeight = ns.data.constants.ui.functionFrame.minHeight
        end
    else
        frameWidth = ns.data.constants.ui.functionFrame.minWidth
        frameHeight = ns.data.constants.ui.functionFrame.minHeight
    end

    --@debug@
    ns:Print(("Creating the use Toys frame with size: %.1f x %.1f"):format(frameWidth, frameHeight))
    --@end-debug@

    -- use PortraitFrameTemplate which is more reliable in modern WoW
    ns.data.ui.frame.useToys = CreateFrame("Frame", frameName, UIParent, "PortraitFrameTemplate")
    ns.data.ui.frame.useToys:SetSize(frameWidth, frameHeight)

    -- set the frame location
    local posnRestored = ns:RestoreFramePosition(ns.data.ui.frame.useToys, frameWidth, frameHeight)

    -- frame settings
    ns.data.ui.frame.useToys:SetMovable(true)
    ns.data.ui.frame.useToys:EnableMouse(true)
    ns.data.ui.frame.useToys:RegisterForDrag("LeftButton")
    ns.data.ui.frame.useToys:SetScript("OnDragStart", ns.data.ui.frame.useToys.StartMoving)
    ns.data.ui.frame.useToys:SetScript("OnDragStop", function()
        -- must be self; since this is a frame function
        ns.data.ui.frame.useToys:StopMovingOrSizing()
        -- store window position; must use ToysByFunction since its an addon function
        ns:StoreFramePosition(ns.data.ui.frame.useToys)
    end)
    ns.data.ui.frame.useToys:SetFrameStrata("HIGH")
    ns.data.ui.frame.useToys:SetTitle(ns.L["Toys by Function"] or "Toys by Function")
    ns.data.ui.frame.useToys:SetPortraitToAsset("Interface\\Icons\\inv_misc_coinbag_special")
    ns.data.ui.frame.useToys:SetResizable(true)
    ns.data.ui.frame.useToys:SetResizeBounds(300, 300)

    -- resize grip in bottom-right corner
    local grip = CreateFrame("Button", nil, ns.data.ui.frame.useToys)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT")
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(itself)
        itself:GetParent():StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function(itself)
        itself:GetParent():StopMovingOrSizing()
        ns.sets:SetFrameSize(frameName, itself:GetWidth(), itself:GetHeight())
    end)

    -- enable escape key functionality following WoW addon patterns
    ns.data.ui.frame.useToys:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            ns.data.ui.frame.useToys:Hide()
        end
    end)
    ns.data.ui.frame.useToys:EnableKeyboard(true)
    ns.data.ui.frame.useToys:SetPropagateKeyboardInput(true)

    -- add button to reset size back to default
    local optionButton = CreateOptionButton(ns.data.ui.frame.useToys)
    optionButton:SetPoint("TOP", ns.data.ui.frame.useToys.TitleContainer, "BOTTOM", 0, -padding)
    optionButton:SetPoint("RIGHT", ns.data.ui.frame.useToys, "RIGHT", -padding, 0)

    -- create frame to hold scroll area and filter dropdown
    local contentFrame = CreateFrame("Frame", nil, ns.data.ui.frame.useToys)
    contentFrame:SetPoint("TOP", optionButton, "BOTTOM", 0, -padding)
    contentFrame:SetPoint("LEFT", ns.data.ui.frame.useToys, "LEFT", padding, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.useToys, "BOTTOMRIGHT", -padding, padding)

    -- create content
    ns.toyScroll:CreateToyListing(ns.funcFrame.scrollKey, contentFrame, false)

    -- setup OnShow event
    ns.data.ui.frame.useToys:SetScript("OnShow", function()
        -- nothing yet
    end)

    -- register frame for escape key handling using WoW's standard system
    tinsert(UISpecialFrames, ns.data.ui.frame.useToys:GetName())
end