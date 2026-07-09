--[[ ------------------------------------------------------------------------
	Title: 			StandardUI.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-21
	Description: 	Standardize UI element creation for the addon.
-----------------------------------------------------------------------------]]

---@class ns
local addonName, ns = ...

--[[---------------------------------------------------------------------------
    Function:   CreateStandardButton
    Purpose:    Standardize button creation.
    Arguments:  parent   - The parent frame to attach this frame to
                text     - The button text
                width    - The width of the button
                onClick  - Callback function when the button is clicked
    Returns:    The created Button frame.
-----------------------------------------------------------------------------]]
function ns:CreateStandardButton(parent, buttonName, text, width, onClick)
    -- create the button
    local button = CreateFrame("Button", buttonName, parent, "GameMenuButtonTemplate")

    -- update text
    if text ~= nil then
        button:SetText(text)
    end

    -- update the on click script
    button:SetScript("OnClick", onClick)

    -- determine width
    if width == nil then
        local textWidth = button:GetFontString():GetStringWidth()
        width = textWidth + 20  -- Add some padding
    end
    button:SetSize(width, 22)

    -- finally return the button
    return button
end

--[[---------------------------------------------------------------------------
    Function:   CreateEditBox
    Purpose:    Standardize edit box creation.
    Arguments:  parent   - The parent frame to attach this frame to
                width    - The width of the edit box
                height   - The height of the edit box
                readOnly - Boolean to set if the edit box is read-only
                onEnter  - Callback function when Enter is pressed
    Returns:    The created EditBox frame.
-----------------------------------------------------------------------------]]
function ns:CreateEditBox(parent, width, height, readOnly, onEnter)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 200, height or 20)
    editBox:SetAutoFocus(false)

    if readOnly then
        editBox:SetEnabled(false)
        editBox:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    end

    if onEnter then
        editBox:SetScript("OnEnterPressed", function(self)
            onEnter(self)
        end)
    end

    return editBox
end

--[[---------------------------------------------------------------------------
    Function:   SetLabelWithTimer
    Purpose:    Set a label's text and clear it after a specified duration.
    Arguments:  label     - The font string label to update
                text      - The text to display
                duration  - How long to show the text before clearing (optional, default 3 seconds)
                color     - Color table {r, g, b} for the text (optional)
    Returns:    None
-----------------------------------------------------------------------------]]
function ns:SetLabelWithTimer(label, text, duration, color)
    if not label then return end
    
    duration = duration or 3.0  -- Default 3 seconds
    
    -- Cancel any existing timer
    if label.clearTimer then
        label.clearTimer:Cancel()
        label.clearTimer = nil
    end
    
    -- Set the text immediately
    label:SetText(text)
    
    -- Set color if provided
    if color then
        label:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
    end
    
    -- Create timer to clear the text
    label.clearTimer = C_Timer.NewTimer(duration, function()
        label:SetText("")
        label.clearTimer = nil
    end)
end

--[[---------------------------------------------------------------------------
    Function:   CreateCheckbox
    Purpose:    Standardize checkbox creation.
    Arguments:  parent       - The parent frame to attach this frame to
                text         - The label text for the checkbox
                initialValue - The initial checked state (true/false)
                tooltipText  - The tooltip text for the checkbox (optional); nil will skip
                onClick      - Callback function when the checkbox state changes
    Returns:    The created CheckButton frame.
----------------------------------------------------------------------------]]
function ns:CreateCheckbox(parent, text, initialValue, frameName, tooltipText, OnClick)
    -- create checkbox
    local checkbox = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")

    -- set its label
    checkbox.Text:SetText(text)

    -- set if its checked or not
    checkbox:SetChecked(initialValue)

    -- set the OnClick event function to the onChanged parameter function
    checkbox:SetScript("OnClick", function(cb, button, down)
        local checked = cb:GetChecked()
        if OnClick then
            OnClick(cb, button, checked)
        end
    end)

    -- add tooltip
    if tooltipText ~= nil then
        checkbox:SetScript("OnEnter", function(cb)
            GameTooltip:SetOwner(cb, "ANCHOR_TOP")
            GameTooltip:AddLine(tooltipText)
            GameTooltip:Show()
        end)

        checkbox:SetScript("OnLeave", function(cb)
            GameTooltip:Hide()
        end)
    end
    
    -- finally return the checkbox object
    return checkbox
end

--[[---------------------------------------------------------------------------
    Function:   CreateCheckboxTextWrap
    Purpose:    Create a checkbox with a label using a font string to wrap text.
    Arguments:  parent       - The parent frame to attach this frame to.
                text         - The label text for the checkbox.
                initialValue - The initial checked state (true/false).
                frameName    - The name of the frame (optional). The top level frame is frameName + "Frame" and the frameName is assigned to the checkbox itself.
                tooltipText  - The tooltip text for the checkbox (optional); nil will skip.
                OnClick      - Callback function when the checkbox state changes.
    Returns:    A table containing the created frame, checkbox, and label.
-----------------------------------------------------------------------------]]
function ns:CreateCheckboxTextWrap(parent, text, initialValue, frameName, tooltipText, OnClick)
    -- verify input
    if frameName ~= nil and type(frameName) == "string" then
        frameName = frameName .. "Frame"
    end

    -- create frame to hold the checkbox and label
    local frame = CreateFrame("Frame", frameName, parent) --, "InsetFrameTemplate")

    -- create checkbox
    local checkbox = CreateFrame("CheckButton", frameName, frame, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    -- detach the text from the checkbox template and set it to empty string
    checkbox.Text:SetText("")

    -- create label so we can wrap the text if we want
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", checkbox, "TOPRIGHT", 5, -5)
    label:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(text)

    -- set if its checked or not
    checkbox:SetChecked(initialValue)

    -- set the OnClick event function to the onChanged parameter function
    checkbox:SetScript("OnClick", function(cb, button, down)
        local checked = cb:GetChecked()
        if OnClick then
            OnClick(cb, button, checked)
        end
    end)

    -- make the label clickable to toggle the checkbox
    label:EnableMouse(true)
    label:SetScript("OnMouseDown", function()
        checkbox:SetChecked(not checkbox:GetChecked())
        checkbox:GetScript("OnClick")(checkbox)
    end)

    -- add tooltip
    if tooltipText ~= nil then
        frame:SetScript("OnEnter", function(cb)
            GameTooltip:SetOwner(cb, "ANCHOR_TOP")
            GameTooltip:AddLine(tooltipText)
            GameTooltip:Show()
        end)

        frame:SetScript("OnLeave", function(cb)
            GameTooltip:Hide()
        end)
    end

    -- finally return the checkbox object
    return {
        frame = frame,
        checkbox = checkbox,
        label = label
    }
end

--[[---------------------------------------------------------------------------
    Function:   CreateDropdown
    Purpose:    Standardize dropdown creation.
    Arguments:  parent          - The parent frame to attach this frame to
                items           - A table of items for the dropdown (key-value pairs)
                initialValue    - The initial selected value
                onSelectionChanged - Callback function when the selection changes
    Returns:    The created Dropdown frame.
-----------------------------------------------------------------------------]]
function ns:CreateDropdown(parent, itemOrder, items, initialValue, frameName, onChange)
    -- create dropdown and set it up
    local dropdown = CreateFrame("DropdownButton", frameName, parent, "WowStyle1DropdownTemplate")
    
    -- store dropdown state
    dropdown.selectedValue = initialValue or ""
    if items == nil then
        dropdown.selectedText = itemOrder[initialValue] or ""
        dropdown.items = itemOrder
    else
        dropdown.selectedText = items[initialValue] or ""
        dropdown.items = items
    end
    dropdown.itemOrder = itemOrder
    
    -- external function; change selected value
    local function SetSelectedValue(key)
        --@debug@
        -- print("(CreateDropdown) SetSelectedValue called with key:", key)
        --@end-debug@
        if dropdown.items[key] then
            dropdown.selectedValue = key
            dropdown.selectedText = dropdown.items[key] or ""
        elseif dropdown.items[key] == nil then
            dropdown.selectedValue = key
            dropdown.selectedText = key
        else
            dropdown.selectedValue = ""
            dropdown.selectedText = ""
        end
        if onChange then
            onChange(key)
        end
    end

    -- function to check if a value is selected
    local function IsSelectedValue(key)
        return dropdown.selectedValue == key
    end

    -- function to build the dropdown menu from the items parameter
    local function GeneratorFunction(dropdown, rootDescription)
        -- add buttons for each item
        -- for key, value in pairs(dropdown.items) do
        for key, value in pairs(dropdown.itemOrder) do
            local radioValue = dropdown.items[value]
            local radioKey = value
            if items == nil then
                radioValue = value
                radioKey = key
            end
            rootDescription:CreateRadio(radioValue, IsSelectedValue, SetSelectedValue, radioKey)
        end
    end

    -- setup the menu
    dropdown:SetupMenu(GeneratorFunction)

    -- external function; update function
    function dropdown:UpdateItems(newItemOrder, newItems, newValue)
        --@debug@
        -- print("(CreateDropdown) New Value:", newValue)
        --@end-debug@
        if newItems == nil then
            self.selectedText = newItemOrder[newValue] or ""
            self.items = newItemOrder
        else
            self.selectedText = newItems[newValue] or ""
            self.items = newItems
        end
        self.itemOrder = newItemOrder
        SetSelectedValue(newValue)
        dropdown:GenerateMenu()
    end

    -- external function; get selected value
    function dropdown:GetSelectedValue()
        return self.selectedValue
    end

    -- set initial value if provided
    if initialValue and dropdown.items[initialValue] then
        SetSelectedValue(initialValue)
    end
    
    -- return the created dropdown
    return dropdown
end

--[[---------------------------------------------------------------------------
    Function:   DialogInvalidData
    Purpose:    Generic popup dialog to notify the user of something.
    Arguments:  message - the message to display in the dialog
-----------------------------------------------------------------------------]]
function ns:GenericPopup(message)
    -- global id for dialog
    ns.data.popups.generic = addonName .. "GenericPopup"

    -- notify user we are going to reset toy filters
    StaticPopupDialogs[ns.data.popups.generic] = {
        text = message,
        button1 = ns.L["OK"],
        timeout = 30,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- show the popup
    StaticPopup_Show(ns.data.popups.generic)
end

-- EOF