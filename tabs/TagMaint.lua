--[[ ------------------------------------------------------------------------
	Title: 			TagMaint.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-26
	Description: 	Building the Tag Maintenance tab in the UI.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.tagMaint = {}

--[[---------------------------------------------------------------------------
    Function:   ButtonCheckWidth
    Purpose:    Ensure all buttons in a given list have the same width based on the widest button's text.
    Arguments:  buttons - a table of button objects to check and adjust
-----------------------------------------------------------------------------]]
local function ButtonCheckWidth(buttons)
    -- track width
    local maxWidth = 0

    -- loop over all the buttons passed in
    for _, button in pairs(buttons) do
        -- calculate the width based on the text width plus padding
        local buttonWidth = button:GetTextWidth() + 20
        --@debug@
        -- ns:Print(("Button '%s' width calculated as %.1f"):format(button:GetText(), buttonWidth))
        --@end-debug@

        -- find the max width among all buttons
        if buttonWidth > maxWidth then
            maxWidth = buttonWidth
        end
    end

    -- loop again to update all button widths
    for _, button in pairs(buttons) do
        button:SetWidth(maxWidth)
    end
end

--[[---------------------------------------------------------------------------
    Function:   EnableEditMode
    Purpose:    Enable or disable the edit mode for tag maintenance.
                When enabled, the edit, delete, insert above and insert below buttons are active, and the edit boxes are editable.
                When disabled, the buttons are inactive, and the edit boxes are read-only.
    Arguments:  enable - boolean value to enable (true) or disable (false) edit mode
-----------------------------------------------------------------------------]]
local function EnableEditMode(enable)
    if enable == true then
        ns.data.ui.button.editTag:Enable()
        ns.data.ui.button.deleteTag:Enable()
        ns.data.ui.button.newTagAbove:Enable()
        ns.data.ui.button.newTagBelow:Enable()
        ns.data.ui.button.tagMoveUp:Enable()
        ns.data.ui.button.tagMoveDown:Enable()
        ns.data.ui.editbox.tagIDEditBox:SetEnabled(true)
        ns.data.ui.editbox.tagNameEditBox:SetEnabled(true)
    else
        ns.data.ui.button.editTag:Disable()
        ns.data.ui.button.deleteTag:Disable()
        ns.data.ui.button.newTagAbove:Disable()
        ns.data.ui.button.newTagBelow:Disable()
        ns.data.ui.button.tagMoveUp:Disable()
        ns.data.ui.button.tagMoveDown:Disable()
        ns.data.ui.editbox.tagIDEditBox:SetEnabled(false)
        ns.data.ui.editbox.tagNameEditBox:SetEnabled(false)
    end
end

--[[---------------------------------------------------------------------------
    Function:   CheckedTagMaintenance
    Purpose:    Handle the logic when a tag maintenance checkbox is clicked.
                Act like a radio button where only one checkbox can be checked.
-----------------------------------------------------------------------------]]
local function CheckedTagMaintenance(checkedBox)
    -- get the checkbox addon attribute which contains the tag ID
    local id = checkedBox:GetAttribute(ns.data.tagAttrName)

    -- loop over all checkboxes and uncheck them but the checked box
    for _, globalName in pairs(ns.data.ui.checkbox.tagMaint) do
        local checkbox = _G[globalName]
        if checkbox and checkbox ~= checkedBox then
            checkbox:SetChecked(false)
        end
    end

    -- update edit mode
    EnableEditMode(checkedBox:GetChecked() == true)

    -- update profile with selected tag
    if checkedBox:GetChecked() == true then
        ns.sets:SetTagCheckedForMaint(id)
    else
        ns.sets:SetTagCheckedForMaint("none")
    end

    --@debug@
    if false then
        local isChecked = checkedBox:GetChecked()
        local name = checkedBox:GetName()
        local order = checkedBox:GetAttribute(ns.data.tagAttrOrder)
        ns:Print(("Tag '%s' checkbox clicked. Checked: %s (ID: %s, Order: %s)"):format(name, tostring(isChecked), tostring(id), tostring(order)))
    end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   CSVString
    Purpose:    Helper function to create a comma-separated string from values.
                If the existing value is empty, it starts with the new value.
                Otherwise, it appends the new value to the existing string.
    Arguments:  value - the existing string
                newValue - the new value to append
    Returns:    A comma-separated string of values.
-----------------------------------------------------------------------------]]
local function CSVString(value, newValue)
    if value == "" then
        value = tostring(newValue)
    else
        value = ("%s, %s"):format(value, tostring(newValue))
    end
    return value
end

--[[---------------------------------------------------------------------------
    Function:   PopulateTagMaintList
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
local function PopulateTagMaintList()
    -- create data provider for scrollbox
    if ns.data.dp.toyMaintList == nil then
        -- create the data provider
        ns.data.dp.toyMaintList = CreateDataProvider()

        -- assign the data provider to the scroll box
        ns.data.ui.scroll.tagMaint:SetDataProvider(ns.data.dp.toyMaintList)

        --@debug@
        -- ns:Print("Created DataProvider for Toy Maintenance List")
        --@end-debug@
    end

    -- reset data provider
    ns.data.dp.toyMaintList:Flush()

    -- collect tags into a sortable table
    for tagId, tagData in pairs(ns.db.global.tags.order) do
        ns.data.dp.toyMaintList:Insert({
            tagId = tagId,
            name = tagData.name or ns.L[tagId] or tagId,
            order = tagData.order
        })
    end

    -- insert sorted rows into the data provider
    ns.data.dp.toyMaintList:Sort(function(a, b) return a.order < b.order end)

    --@debug@
    -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   MoveTag
    Purpose:    Move a tag up or down in the order. Should run PopulateTagMaintList after this function to refresh the list in the UI.
    Arguments:  id - unique identifier for the tag to move
                moveUp - boolean indicating if the tag should be moved up (true) or down (false)
-----------------------------------------------------------------------------]]
local function MoveTag(id, moveUp)
    -- for moving down we need the order number + 1 and -1 for moving up since we sort by order in assending order
    local testOrder = nil
    if moveUp == true then
        testOrder = ns.db.global.tags.order[id].order - 1
    else
        testOrder = ns.db.global.tags.order[id].order + 1
    end

    -- loop over the tags and find the tag with an order one greater than the moving tag id order
    for tagId, tagData in pairs(ns.db.global.tags.order) do
        -- test if the tag in the list has the move to order value
        if testOrder == tagData.order then
            -- set the order value of the moving tag to the target order
            ns.db.global.tags.order[tagId].order = ns.db.global.tags.order[id].order
            ns.db.global.tags.order[id].order = testOrder
            break
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   OnClick_TagMoveDown
    Purpose:    Handle the click event for moving a tag down in the order.
    Arguments:  tagId - the ID of the tag to move down
-----------------------------------------------------------------------------]]
local function OnClick_TagMoveDown(tagId)
    --@debug@
    -- ns:Print(("OnClick_TagMoveDown called for tagId: %s"):format(tagId))
    --@end-debug@
    MoveTag(tagId, false)
    PopulateTagMaintList()
end

--[[---------------------------------------------------------------------------
    Function:   OnClick_TagMoveUp
    Purpose:    Handle the click event for moving a tag up in the order.
    Arguments:  tagId - the ID of the tag to move up
-----------------------------------------------------------------------------]]
local function OnClick_TagMoveUp(tagId)
    --@debug@
    -- ns:Print(("OnClick_TagMoveUp called for tagId: %s"):format(tagId))
    --@end-debug@
    MoveTag(tagId, true)
    PopulateTagMaintList()
end

--[[---------------------------------------------------------------------------
    Function:   UpdateTagOrderFrom
    Purpose:    Update the order values of tags starting from a specific index.
                This function is used when a tag is deleted or inserted to adjust the order of remaining tags.
    Arguments:  fromIndex - the order index from which to start updating
                recordInserted - boolean indicating if a record was inserted (true) or deleted (false)
    Returns:    A string representation of the updated order values for debugging purposes. Only in debug mode.
-----------------------------------------------------------------------------]]
local function UpdateTagOrderFrom(fromIndex, recordInserted)
    --@debug@
    local debugMsg = ""
    --@end-debug@

    -- adjust the order addition value based on if a record was inserted or not; inserted then we need to add 1 to all high order values, otherwise, minus one since a record was deleted
    local addValue = 1
    if recordInserted == false then
        addValue = -1
    end

    for tagId, tagData in pairs(ns.db.global.tags.order) do
        if tagData.order >= fromIndex then
            local currentOrder = ns.db.global.tags.order[tagId].order
            ns.db.global.tags.order[tagId].order = currentOrder + addValue
            --@debug@
            debugMsg = CSVString(debugMsg, tostring(currentOrder))
            --@end-debug@
        end
    end

    --@debug@
    return debugMsg
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   ResetOrder
    Purpose:    Reset the order values of all tags based on their name sorted alphabetically.
                This function will reassign order numbers to all tags, starting from 1, based on the alphabetical order of their names.
-----------------------------------------------------------------------------]]
local function ResetOrder()
    -- create a temp table
    local tmptbl = {}

    -- get a listing of the current tags so we don't lose any custom tags
    for tagId, tagData in pairs(ns.db.global.tags.order) do
        tmptbl[tagId] = { name = tagData.name or ns.L[tagId] }
    end

    -- collect keys sorted alphabetically by their localized name
    local sortedKeys = {}
    for tagId in pairs(tmptbl) do
        sortedKeys[#sortedKeys + 1] = tagId
    end
    table.sort(sortedKeys, function(a, b) return tmptbl[a].name < tmptbl[b].name end)

    -- assign order based on sorted position
    local counter = 1
    for _, tagId in ipairs(sortedKeys) do
        ns.db.global.tags.order[tagId].order = counter
        counter = counter + 1
    end
end

--[[---------------------------------------------------------------------------
    Function:   ResetOrderConfirmation
    Purpose:    Show a confirmation dialog to the user before resetting the order values of all tags.
                This function ensures that the user is aware that they will lose any custom order changes they have made.
-----------------------------------------------------------------------------]]
local function ResetOrderConfirmation()
    -- first make sure user wants to as they will lose all the order changes they have done
    -- need global index name for each popup
    ns.data.popups.resetOrderConfirm = addonName .. "ResetOrderConfirm"

    -- notify user we are going to reset toy filters
    if StaticPopupDialogs[ns.data.popups.resetOrderConfirm] == nil then
        local newIndex = #ns.data.popups + 1
        StaticPopupDialogs[ns.data.popups.resetOrderConfirm] = {
            text = ns.L["This will reorder all tags in alphabetical order based on name. Proceed?"],
            button1 = ns.L["OK"],
            button2 = ns.L["Cancel"],
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = newIndex,
            OnAccept = function()
                -- reset the data
                ResetOrder()

                -- refresh the scroll
                PopulateTagMaintList()
            end,
        }
    end

    -- show the popup
    StaticPopup_Show(ns.data.popups.resetOrderConfirm)
end

--[[---------------------------------------------------------------------------
    Function:   InsertTag
    Purpose:    Insert a new tag into the global tags order and refresh the list.
    Arguments:  id - unique identifier for the new tag
                name - display name for the new tag
                order - order value for the new tag
                enabled - boolean indicating if the tag is enabled
    Returns:    A table with success status and an optional message.
-----------------------------------------------------------------------------]]
local function InsertTag(id, name, order, enabled)
    --@debug@
    -- store the debug message
    local debugMsg = ""

    --print out insert details
    ns:Print(("Inserting Tag: ID='%s', Name='%s', Order=%d, Enabled=%s"):format(id, name, order, tostring(enabled)))
    --@end-debug@

    -- confirm the tag doesn't already exist, if not, insert it, update orders for all tags and refresh the list
    if ns.db.global.tags.order[id] == nil then
        -- update all order values to ensure they are sequential and unique
        debugMsg = UpdateTagOrderFrom(order)

        -- insert after orders are updated
        ns.db.global.tags.order[id] = { ["order"] = order, ["enabled"] = enabled, ["name"] = name }

        --@debug@
        ns:Print(("Updated Order on Records: %s"):format(debugMsg))
        --@end-debug@

        -- return status
        return {
            success = true,
            message = nil
        }
    else
        return {
            success = false,
            message = ns.L["Tag ID already exists. Please choose a unique ID."]
        }
    end
end

--[[---------------------------------------------------------------------------
    Function:   OnClick_NewTag
    Purpose:    Handle the click event for creating a new tag, either above or below the currently selected tag.
    Arguments:  above - boolean indicating if the new tag should be placed above (true, -1) or below (false, +1) the selected tag.
-----------------------------------------------------------------------------]]
local function OnClick_NewTag(above)
    --@debug@
    -- ns:Print(("(OnClick_NewTag) Called with above: %s"):format(tostring(above)))
    --@end-debug@

    -- verify tag selected
    if ns.tagMaint:IsTagSelected() == false then
        ns.tagMaint:DialogInvalidData(ns.L["You must select a tag from the list before creating a new tag."])
        return
    end

    -- get data
    local newId = ns.data.ui.editbox.tagIDEditBox:GetText()
    local newName = ns.data.ui.editbox.tagNameEditBox:GetText()
    local checkedTag = ns.gets:GetTagCheckedForMaint()
    local enabled = true
    local newOrder = ns.db.global.tags.order[checkedTag].order

    -- check id doesn't include anything but lowercase letters and numbers
    local passIdCharCheck = true
    local passIdLengthCheck = true
    if not newId:match("^[a-z0-9]+$") then
        passIdCharCheck = false
    elseif #newId > 20 or #newId < 1 then
        passIdLengthCheck = false
    end

    -- check name doesn't include anything but mixed case letters and numbers and spaces and the length is 20 characters or less
    local passNameCharCheck = true
    local passNameLengthCheck = true
    if not newName:match("^[a-zA-Z0-9 ]+$") then
        passNameCharCheck = false
    elseif #newName > 20 or #newName < 1 then
        passNameLengthCheck = false
    end

    -- show failure dialog if any checks fail
    if passIdCharCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: ID may only contain lowercase letters and numbers."])
        return
    elseif passIdLengthCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: ID may only be 1 to 20 characters."])
        return
    elseif passNameCharCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: Name may only contain mixed case letters, spaces and numbers."])
        return
    elseif passNameLengthCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: Name may only be 1 to 20 characters."])
        return
    end

    -- process based on placement of new tag
    -- true then use the existing order of the checked record
    -- false then use the existing order of the checked record plus 1
    if above == false then
        newOrder = newOrder + 1
    end

    -- insert new tag
    local newTagInserted = InsertTag(newId, newName, newOrder, enabled)
    if newTagInserted.success == false then
        ns.tagMaint:DialogInvalidData(newTagInserted.message)
        return
    end

    -- refresh the tag list
    PopulateTagMaintList()

    --@debug@
    -- ns:Print(("(OnClick_NewTag) Done"))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   DeleteTag
    Purpose:    Delete a tag from the global tag order and update the order of remaining tags.
    Arguments:  deleteme - the ID of the tag to delete
-----------------------------------------------------------------------------]]
local function DeleteTag(deleteme)
    -- keep track of the deleted tag order number but subtract one so the update function updates all tags from one less than the deleted record
    local deletedOrder = ns.db.global.tags.order[deleteme].order

    -- delete the tag
    ns.db.global.tags.order[deleteme] = nil

    -- update the order now that one tag is deleted
    local debugMsg = UpdateTagOrderFrom(deletedOrder, false)

    -- check button status


    --@debug@
    -- ns:Print(("Tag '%s' deleted successfully; Updated order: %s"):format(deleteme, debugMsg))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   OnClick_DeleteTag
    Purpose:    Handle the click event for deleting a tag. This function will remove the tag from all toys and delete it from the tag list.
-----------------------------------------------------------------------------]]
local function OnClick_DeleteTag()
    -- need global index name for each popup
    ns.data.popups.deletetag = addonName .. "DeleteTag"

    -- create popup
    if StaticPopupDialogs[ns.data.popups.deletetag] == nil then
        local newIndex = #ns.data.popups + 1
        StaticPopupDialogs[ns.data.popups.deletetag] = {
            text = ("%s %s"):format(ns.L["Uncategorized"], ns.L["is required for the addon to function correctly. Can't delete it."]),
            button1 = ns.L["OK"],
            timeout = 30,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = newIndex,
        }
    end

    -- get the selected tag to delete
    local deleteTag = ns.gets:GetTagCheckedForMaint()

    -- prevent uncategorized from being deleted
    if deleteTag == "uncategorized" then
        StaticPopup_Show(ns.data.popups.deletetag)
        return
    end

    -- first, find the toys with the tag to delete, remove it and if no tags are assigned then add the uncategorized tag
    local selectedTag = ns.gets:GetTagCheckedForMaint()
    for toyId, toyData in pairs(ns.db.global.toys.byItemId) do
        -- track index of tag in table
        local tagFound = -1

        -- look for the tag to delete and see if it has the uncategorized tag already
        for tagIdx, tagId in ipairs(toyData.tags) do
            if tagId == selectedTag then
                tagFound = tagIdx
            end
        end

        -- delete the tag if found; value greater than -1
        if tagFound > -1 then
            table.remove(ns.db.global.toys.byItemId[toyId].tags, tagFound)
        end

        -- if tag count is zero then add uncategorized
        if #toyData.tags == 0 then
            table.insert(ns.db.global.toys.byItemId[toyId].tags, "uncategorized")
        end
    end

    -- next, delete the tag from the tag table
    DeleteTag(selectedTag)

    -- check buttons
    EnableEditMode(false)

    -- next fresh the tag listing
    PopulateTagMaintList()
end

--[[---------------------------------------------------------------------------
    Function:   BuildTagOptionsFrame
    Purpose:    Create a frame with options for tag maintenance (checkbox and buttons).
    Arguments:  parentFrame - the parent frame to attach the options frame to
-----------------------------------------------------------------------------]]
local function BuildTagOptionsFrame(parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- label for the options frame
    local optionLabel = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    optionLabel:SetJustifyH("LEFT")
    optionLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", padding, -padding)
    optionLabel:SetText(ns.L["Tag Edits:"])
    local frameHeight = optionLabel:GetHeight() + padding

    -- create inset frame for order reset button info and button
    local insetFrameResetOrder = CreateFrame("Frame", nil, parentFrame, "InsetFrameTemplate")
    insetFrameResetOrder:SetPoint("LEFT", parentFrame, "LEFT", padding, 0)
    insetFrameResetOrder:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -padding, padding)
    insetFrameResetOrder:SetHeight(40)

    -- reset button of order values
    local resetOrderNote = insetFrameResetOrder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    resetOrderNote:SetPoint("TOPLEFT", insetFrameResetOrder, "TOPLEFT", padding, -padding)
    resetOrderNote:SetPoint("RIGHT", insetFrameResetOrder, "RIGHT", -padding, 0)
    resetOrderNote:SetText(("%s%s%s%s"):format(ns.data.colors.orange, ns.L["Note: "], ns.data.colors.ending, ns.L["Resetting order values will reassign order numbers to all tags based on their name sorted alphabetically."]))
    resetOrderNote:SetJustifyH("LEFT")
    local resetOrderButton = ns:CreateStandardButton(insetFrameResetOrder, nil, ns.L["Reset Order Values"], 100, function()
        ResetOrderConfirmation()
        PopulateTagMaintList()
    end)
    local resetOrderButtonWidth = resetOrderButton:GetTextWidth()
    resetOrderButton:SetWidth(resetOrderButtonWidth + (padding * 2))
    resetOrderButton:SetPoint("TOPLEFT", resetOrderNote, "BOTTOMLEFT", 0, -padding)
    insetFrameResetOrder:SetHeight(resetOrderNote:GetHeight() + resetOrderButton:GetHeight() + (padding * 3))

    -- frame to hold buttons
    local insetFrame = CreateFrame("Frame", nil, parentFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", optionLabel, "BOTTOMLEFT", 0, -5)
    insetFrame:SetPoint("BOTTOMRIGHT", insetFrameResetOrder, "TOPRIGHT", 0, padding)

    -- add padding for insetFrame but not the height of the frame since we don't know it yet
    frameHeight = frameHeight + padding

    -- create checkbox to prevent tag deletion if toys are still associated with itemIDs
    local function PreventTagDelete_OnClick()
        ns.sets:SetOptionPreventTagDelete()
    end
    local function GetPreventTagDelete()
        return ns.gets:GetOptionPreventTagDelete()
    end
    local checkboxLabel = ns.L["Prevent Tag Deletion if Toys Assigned"]
    local checkboxTooltip = ns.L["If checked, tags assigned to toys will NOT be deleted. Otherwise, tags are deleted but associated toys moved to the uncategorized tag."]
    local checkboxPreventDelete = ns:CreateCheckboxTextWrap(insetFrame, checkboxLabel, GetPreventTagDelete, nil, checkboxTooltip, PreventTagDelete_OnClick)
    checkboxPreventDelete.frame:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", padding, -padding)
    checkboxPreventDelete.frame:SetPoint("RIGHT", insetFrame, "RIGHT", -padding, 0)
    checkboxPreventDelete.frame:SetHeight(checkboxPreventDelete.label:GetStringHeight() + padding)
    frameHeight = frameHeight + checkboxPreventDelete.frame:GetHeight() + (padding * 2)

    -- create buttons for managing tags (Edit, Delete)
    ns.data.ui.button.editTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Rename Tag"], 40, function() ns.tagMaint:OnClick_EditTag() end)
    ns.data.ui.button.editTag:SetPoint("TOPLEFT", checkboxPreventDelete.frame, "BOTTOMLEFT", 0, -5)
    ns.data.ui.button.editTag:Disable()
    ns.data.ui.button.deleteTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Delete Tag"], 40, function() OnClick_DeleteTag() end)
    ns.data.ui.button.deleteTag:SetPoint("TOPLEFT", ns.data.ui.button.editTag, "BOTTOMLEFT", 0, -5)
    ns.data.ui.button.deleteTag:Disable()

    -- create buttons for moving tags up and down
    ns.data.ui.button.tagMoveUp = ns:CreateStandardButton(insetFrame, nil, ns.L["Move Up"], 40, function() OnClick_TagMoveUp(ns.gets:GetTagCheckedForMaint()) end)
    ns.data.ui.button.tagMoveUp:SetPoint("TOPLEFT", ns.data.ui.button.editTag, "TOPRIGHT", padding, 0)
    ns.data.ui.button.tagMoveUp:Disable()
    ns.data.ui.button.tagMoveDown = ns:CreateStandardButton(insetFrame, nil, ns.L["Move Down"], 40, function() OnClick_TagMoveDown(ns.gets:GetTagCheckedForMaint()) end)
    ns.data.ui.button.tagMoveDown:SetPoint("TOPLEFT", ns.data.ui.button.deleteTag, "TOPRIGHT", padding, 0)
    ns.data.ui.button.tagMoveDown:Disable()

    -- create frame for tag creation
    local tagCreateFrame = CreateFrame("Frame", nil, insetFrame) --, "InsetFrameTemplate")
    tagCreateFrame:SetPoint("TOPLEFT", ns.data.ui.button.deleteTag, "BOTTOMLEFT", 0, -padding)
    tagCreateFrame:SetPoint("BOTTOMRIGHT", insetFrame, "BOTTOMRIGHT", -padding, padding)

    -- create new title
    local tagCreateTitle = tagCreateFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tagCreateTitle:SetPoint("TOPLEFT", tagCreateFrame, "TOPLEFT", 0, 0)
    tagCreateTitle:SetText(ns.L["Create a Tag:"])

    -- create labels and adjust width
    local tagIDEditBoxLabel = tagCreateFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tagIDEditBoxLabel:SetPoint("TOPLEFT", tagCreateTitle, "BOTTOMLEFT", 0, -padding)
    tagIDEditBoxLabel:SetText(ns.L["ID:"])
    tagIDEditBoxLabel:SetJustifyH("RIGHT")
    local tagNameEditBoxLabel = tagCreateFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tagNameEditBoxLabel:SetPoint("TOPLEFT", tagIDEditBoxLabel, "BOTTOMLEFT", 0, -padding)
    tagNameEditBoxLabel:SetText(ns.L["Name:"])
    tagNameEditBoxLabel:SetJustifyH("RIGHT")

    -- fix width of labels for edit boxes
    local width1 = tagIDEditBoxLabel:GetWidth()
    local width2 = tagNameEditBoxLabel:GetWidth()
    local maxWidth = math.max(width1, width2)
    tagIDEditBoxLabel:SetWidth(maxWidth)
    tagNameEditBoxLabel:SetWidth(maxWidth)

    -- edit box for tag ID
    ns.data.ui.editbox.tagIDEditBox = ns:CreateEditBox(tagCreateFrame, 200, 20, true, function(editbox) end)
    ns.data.ui.editbox.tagIDEditBox:SetPoint("LEFT", tagIDEditBoxLabel, "RIGHT", padding, 0)

    -- create edit box for tag name
    ns.data.ui.editbox.tagNameEditBox = ns:CreateEditBox(tagCreateFrame, 200, 20, true, function(editbox) end)
    ns.data.ui.editbox.tagNameEditBox:SetPoint("LEFT", tagNameEditBoxLabel, "RIGHT", padding, 0)

    -- add insert buttons
    ns.data.ui.button.newTagAbove = ns:CreateStandardButton(insetFrame, nil, ns.L["Insert Above"], 40, function() OnClick_NewTag(true) end)
    ns.data.ui.button.newTagBelow = ns:CreateStandardButton(insetFrame, nil, ns.L["Insert Below"], 40, function() OnClick_NewTag(false) end)
    ns.data.ui.button.clearNewTagEdits = ns:CreateStandardButton(insetFrame, nil, ns.L["Clear Data"], 40, function()
        ns.data.ui.editbox.tagIDEditBox:SetText("")
        ns.data.ui.editbox.tagNameEditBox:SetText("")
    end)
    ns.data.ui.button.newTagAbove:Disable()
    ns.data.ui.button.newTagBelow:Disable()

    -- fix button widths
    ButtonCheckWidth({
        ns.data.ui.button.newTagAbove,
        ns.data.ui.button.newTagBelow,
        ns.data.ui.button.editTag,
        ns.data.ui.button.deleteTag,
        ns.data.ui.button.tagMoveUp,
        ns.data.ui.button.tagMoveDown,
        ns.data.ui.button.clearNewTagEdits
    })

    -- position buttons
    ns.data.ui.button.newTagAbove:SetPoint("TOP", ns.data.ui.editbox.tagNameEditBox, "BOTTOM", 0, -padding)
    ns.data.ui.button.newTagAbove:SetPoint("LEFT", tagCreateFrame, "LEFT", 0, 0)
    ns.data.ui.button.newTagBelow:SetPoint("TOPLEFT", ns.data.ui.button.newTagAbove, "BOTTOMLEFT", 0, -5)
    ns.data.ui.button.clearNewTagEdits:SetPoint("TOPLEFT", ns.data.ui.button.newTagAbove, "TOPRIGHT", padding, 0)

    -- note about permissible characters for ID and Name
    local notes = tagCreateFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    notes:SetPoint("TOPLEFT", ns.data.ui.button.newTagBelow, "BOTTOMLEFT", 0, -padding)
    notes:SetPoint("RIGHT", tagCreateFrame, "RIGHT", -padding, 0)
    notes:SetText(("%s%s%s%s"):format(ns.data.colors.orange, ns.L["Note: "], ns.data.colors.ending, ns.L["ID may only contain lowercase letters and numbers. Name may only contain mixed case letters and numbers. Both have a max length of 20 characters."]))
    notes:SetJustifyH("LEFT")
end

--[[---------------------------------------------------------------------------
    Function:   IsTagSelected
    Purpose:    Check if a tag is currently selected for maintenance.
    Returns:    true if a tag is selected, false otherwise.
-----------------------------------------------------------------------------]]
function ns.tagMaint:IsTagSelected()
    local selectedTag = ns.gets:GetTagCheckedForMaint()
    return selectedTag ~= "none"
end

--[[---------------------------------------------------------------------------
    Function:   DialogInvalidData
    Purpose:    Show a dialog to the user indicating that the input data for a new tag is invalid.
    Arguments:  message - the message to display in the dialog
-----------------------------------------------------------------------------]]
function ns.tagMaint:DialogInvalidData(message)
    -- global id for dialog
    ns.data.popups.newtaginputfail = addonName .. "NewTagInputFailure"

    -- notify user we are going to reset toy filters
    StaticPopupDialogs[ns.data.popups.newtaginputfail] = {
        text = message,
        button1 = ns.L["OK"],
        timeout = 30,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- show the popup
    StaticPopup_Show(ns.data.popups.newtaginputfail)
end

--[[---------------------------------------------------------------------------
    Function:   RenameTag
    Purpose:    Rename a tag in the global tag order after validating the new name.
    Arguments:  tagId - the ID of the tag to rename
                newName - the new name for the tag
-----------------------------------------------------------------------------]]
local function RenameTag(tagId, newName)
    --@debug@
    -- ns:Print(("RenameTag called for tagId: %s with newName: %s"):format(tagId, newName))
    --@end-debug@

    -- check name doesn't include anything but mixed case letters and numbers and spaces and the length is 20 characters or less
    local passNameCharCheck = true
    local passNameLengthCheck = true
    if not newName:match("^[a-zA-Z0-9 ]+$") then
        passNameCharCheck = false
    elseif #newName > 20 or #newName < 1 then
        passNameLengthCheck = false
    end

    -- show failure dialog if any checks fail
    if passNameCharCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: Name may only contain mixed case letters, spaces and numbers."])
        return
    elseif passNameLengthCheck == false then
        ns.tagMaint:DialogInvalidData(ns.L["Error: Name may only be 1 to 20 characters."])
        return
    end

    -- rename the tag in the database
    ns.db.global.tags.order[tagId].name = newName

    -- refresh the tag list
    PopulateTagMaintList()
end

--[[---------------------------------------------------------------------------
    Function:   OnClick_EditTag
    Purpose:    Handle the click event for editing a tag. This function will reset toy filters and reload the toy list and tag list.
-----------------------------------------------------------------------------]]
local function OnClick_EditTag()
    -- need global index name for each popup
    ns.data.popups.editTag = addonName .. "NewTagInput"

    -- notify user we are going to reset toy filters
    if StaticPopupDialogs[ns.data.popups.editTag] == nil then
        local newIndex = #ns.data.popups + 1
        StaticPopupDialogs[ns.data.popups.editTag] = {
            text = ns.L["Enter a new Name for the tag. Name may only contain mixed case letters, spaces and numbers and have a max length of 20 characters."],
            button1 = ns.L["OK"],
            button2 = ns.L["Cancel"],
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = newIndex,
            hasEditBox = true,
            maxLetters = 20,
            OnAccept = function(thepopup)
                -- get selected tag and its data
                local tagId = ns.gets:GetTagCheckedForMaint()

                -- trigger the rename
                RenameTag(tagId, thepopup.EditBox:GetText())
            end,
            OnShow = function(thepopup)
                -- get selected tag and its data
                local tagId = ns.gets:GetTagCheckedForMaint()
                local tagData = ns.db.global.tags.order[tagId]

                -- populate the edit box
                thepopup.EditBox:SetText((tagData.name or ""))

                -- make it easier for user to just start typing
                thepopup.EditBox:SetFocus()
            end,
        }
    end

    -- show the popup
    StaticPopup_Show(ns.data.popups.editTag)
end

--[[---------------------------------------------------------------------------
    Function:   BuildAndRefreshTagRow
    Purpose:    Build or refresh a row in the tag maintenance scroll list with the given data.
    Arguments:  frame - the frame representing the row
                data - the data associated with the tag (tagId, name, order)
-----------------------------------------------------------------------------]]
local function BuildAndRefreshTagRow(frame, data)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- track global names of checkboxes
    if ns.data.ui.checkbox == nil then
        ns.data.ui.checkbox = {}
    end
    if ns.data.ui.checkbox.tagMaint == nil then
        ns.data.ui.checkbox.tagMaint = {}
    end

    -- checkbox with the tag as a label
    if frame.tagCheckbox == nil then
        -- create global name
        local checkboxName = ns.gets:GetObjectName("CheckboxTagMaint" .. data.tagId)

        -- add to list
        if ns.data.ui.checkbox.tagMaint[checkboxName] == nil then
            table.insert(ns.data.ui.checkbox.tagMaint, checkboxName)
        end

        -- create checkbox
        frame.tagCheckbox = CreateFrame("CheckButton", checkboxName, frame, "UICheckButtonTemplate")
        frame.tagCheckbox:SetPoint("LEFT", frame, "LEFT", padding, 0)
        frame.tagCheckbox:SetSize(24, 24)
        frame.tagCheckbox:SetScript("OnClick", function(self)
            CheckedTagMaintenance(self)
        end)
    end

    -- add label for tab id
    if frame.tagIdLabel == nil then
        -- add smaller text below title with tag id
        frame.tagIdLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        frame.tagIdLabel:SetPoint("LEFT", frame.tagCheckbox.text, "RIGHT", 5, 0)
    end

    --@debug@
    -- add order number just for testing purposes
    if frame.orderValueLabel == nil then
        frame.orderValueLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        frame.orderValueLabel:SetPoint("LEFT", frame.tagIdLabel, "RIGHT", 5, 0)
    end
    frame.orderValueLabel:SetText(("(%s)"):format(tostring(data.order)))
    --@end-debug@

    -- update/set attribute and text
    frame.tagCheckbox:SetAttribute(ns.data.tagAttrName, data.tagId)
    frame.tagCheckbox:SetAttribute(ns.data.tagAttrOrder, data.order)
    frame.tagCheckbox.Text:SetText(data.name)
    frame.tagIdLabel:SetText(("(%s)"):format(tostring(data.tagId)))

    -- update if checked
    if ns.gets:GetTagCheckedForMaint() == data.tagId then
        frame.tagCheckbox:SetChecked(true)
        frame.tagCheckbox:GetScript("OnClick")(frame.tagCheckbox) -- simulate click to ensure proper state
    else
        frame.tagCheckbox:SetChecked(false)
    end
end

--[[---------------------------------------------------------------------------
    Function:   TagRowInitializer
    Purpose:    Initialize the content of a row in the tag maintenance scroll list.
    Arguments:  frame - the frame representing the row
                data - the data associated with the tag (tagId, name, order)
-----------------------------------------------------------------------------]]
local function TagRowInitializer(frame, data)
    -- build row objects and assign tag data
    BuildAndRefreshTagRow(frame, data)

    -- frame events
    -- frame:SetScript("OnEnter", function(itself)
        -- itself.upbutton:Show()
        -- itself.downbutton:Show()
    -- end)
    -- frame:SetScript("OnLeave", function(itself)
        -- if ns:IsMouseOverOrChild(itself) then return end
        -- if MouseIsOver(itself) then return end

        -- hide the buttons
        -- itself.upbutton:Hide()
        -- itself.downbutton:Hide()
    -- end)
end

--[[---------------------------------------------------------------------------
    Function:   CreateTagMaintScrollList
    Purpose:    Create a scrollable list frame for maintaining tags.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
local function CreateTagMaintScrollList(parent)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- frame to contain label and scroll box
    ns.data.ui.frame.tagMaintTagListTopFrame = CreateFrame("Frame", nil, parent)
    ns.data.ui.frame.tagMaintTagListTopFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    ns.data.ui.frame.tagMaintTagListTopFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    -- ns.data.ui.frame.tagMaintTagListTopFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    -- ns.data.ui.frame.tagMaintTagListTopFrame:SetWidth(200)

    -- frame label
    local scrollBoxLabel = ns.data.ui.frame.tagMaintTagListTopFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scrollBoxLabel:SetJustifyH("LEFT")
    scrollBoxLabel:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaintTagListTopFrame, "TOPLEFT", padding, -padding)
    scrollBoxLabel:SetText(ns.L["Pick a tag:"])

    -- create parent frame for the scroll box
    ns.data.ui.frame.tagMaintTagListScrollBoxParent = CreateFrame("Frame", nil, ns.data.ui.frame.tagMaintTagListTopFrame, "InsetFrameTemplate")
    ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("TOPLEFT", scrollBoxLabel, "BOTTOMLEFT", 0, -5)
    ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.tagMaintTagListTopFrame, "BOTTOMRIGHT", 0, padding)
    -- ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("BOTTOM", parent, "BOTTOM", 0, padding)
    -- ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetWidth(parent:GetWidth() / 2)

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, ns.data.ui.frame.tagMaintTagListScrollBoxParent, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaintTagListScrollBoxParent, "TOPLEFT", 5, -5)
    scrollBox:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.tagMaintTagListScrollBoxParent, "BOTTOMRIGHT", -20, 5)

    local scrollBar = CreateFrame("EventFrame", nil, ns.data.ui.frame.tagMaintTagListScrollBoxParent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- 2. Configure view with fixed row height; for variable-height elements
    local view = CreateScrollBoxListLinearView()
    ns.data.ui.height.toyMaintCell = 25

    -- 3. Element initializer (called when a row becomes visible)
    view:SetElementInitializer("BackdropTemplate", function(frame, data)
        TagRowInitializer(frame, data)
    end)

    -- 4. Element resetter (cleanup when row scrolls out of view)
    view:SetElementResetter(function(frame, data)
        BuildAndRefreshTagRow(frame, data)
    end)

    -- 5. Element extent calculator (determine height of each row).
    view:SetElementExtentCalculator(function(dataIndex, data)
        --@debug@
        -- ns:Print(("Calculating height for dataIndex %d with name %s"):format(dataIndex, data.name or "Unknown"))
        --@end-debug@
        return ns.data.ui.height.toyMaintCell
    end)

    -- 6. Connect everything
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- 7. Auto-hide scrollbar when not needed
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)

    -- 8. Return the scroll box for external use.
    return scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   BuildTagListingColumn
    Purpose:    Create a scrollable list of tags for selection.
-----------------------------------------------------------------------------]]
local function BuildTagListingColumn(parentFrame)
    -- create scroll box for tag maintenance
    -- variable mainly for the PopulateTagMaintList function to access the scroll box
    ns.data.ui.scroll.tagMaint = CreateTagMaintScrollList(parentFrame)

    -- populate the scroll box with tag data
    PopulateTagMaintList()
end

--[[---------------------------------------------------------------------------
    Function:   CreateMaintainTagsFrame
    Purpose:    Create a frame for maintaining tags.
-----------------------------------------------------------------------------]]
local function CreateMaintainTagsFrame()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all content for maintaining tags
    local mainFrame = CreateFrame("Frame", nil, ns.data.ui.tabs[ns.tagMaint.tabKey]) --, "InsetFrameTemplate")
    mainFrame:SetPoint("TOPLEFT", ns.data.ui.tabs[ns.tagMaint.tabKey], "TOPLEFT", padding, -50)
    mainFrame:SetPoint("BOTTOMRIGHT", ns.data.ui.tabs[ns.tagMaint.tabKey], "BOTTOMRIGHT", -padding, padding)
    mainFrame:SetScript("OnShow", function(thisframe)
        if ns.data.dp.toyMaintList ~= nil then
            PopulateTagMaintList()
        end
    end)
    -- mainFrame:SetScript("OnHide", function(thisframe)
    --     ns:Print(("Tag Maintenance tab hidden, resetting edit mode."))
    -- end)

    -- create title for frame
    local title = ns.data.ui.tabs[ns.tagMaint.tabKey]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", ns.data.ui.tabs[ns.tagMaint.tabKey], "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", ns.data.ui.tabs[ns.tagMaint.tabKey], "TOPRIGHT", -padding, -padding)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(ns.L["Maintain Tags"])

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, mainFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", 0, 0)

    -- create an inset frame for each area: pick a tag, tag edits and reset order values
    -- 1. create frame to hold all content
    local pickTagFrame = CreateFrame("Frame", nil, insetFrame) --, "InsetFrameTemplate")
    pickTagFrame:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", 0, 0)
    pickTagFrame:SetPoint("BOTTOMLEFT", insetFrame, "BOTTOMLEFT", 0, 0)
    pickTagFrame:SetWidth(550)

    -- 2. create frame to hold all content for tag edits
    local optionFrame = CreateFrame("Frame", nil, insetFrame)
    optionFrame:SetPoint("TOPLEFT", pickTagFrame, "TOPRIGHT", 0, 0)
    optionFrame:SetPoint("RIGHT", insetFrame, "RIGHT", 0, 0)

    -- populate options and button
    BuildTagOptionsFrame(optionFrame)

    -- populate frame for picking a tag
    BuildTagListingColumn(pickTagFrame)
end

--[[---------------------------------------------------------------------------
    Function:   ProcessTagMaintFrame
    Purpose:    Create a frame with a checkbox to protect on delete and buttons for tag maintenance actions (New, Edit, Delete).
-----------------------------------------------------------------------------]]
function ns.tagMaint:ProcessTagMaintFrame(tabKey)
    -- set the tabkey property
    ns.tagMaint.tabKey = tabKey
    
    -- skip if the tab already exists
    if ns.data.ui.tabs[ns.tagMaint.tabKey] ~= nil then return end

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    ns.tabs:CreateTabContentFrame(tabKey)

    -- create the tag listing scroll frame
    CreateMaintainTagsFrame()
end