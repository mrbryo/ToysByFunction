--[[ ------------------------------------------------------------------------
	Title: 			TagMaint.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-26
	Description: 	Building the Tag Maintenance tab in the UI.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.tagMaint = {}

--[[---------------------------------------------------------------------------
    Function:   ProcessTagMaintFrame
    Purpose:    Create a frame with a checkbox to protect on delete and buttons for tag maintenance actions (New, Edit, Delete).
-----------------------------------------------------------------------------]]
function ns.tagMaint:ProcessTagMaintFrame(tabKey)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- set the tabkey property
    ns.tagMaint.tabKey = tabKey

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    ns.tabs:CreateTabContentFrame(tabKey)

    -- create the tag listing scroll frame
    ns.tagMaint:CreateMaintainTagsFrame()
end

--[[---------------------------------------------------------------------------
    Function:   CreateMaintainTagsFrame
    Purpose:    Create a frame for maintaining tags.
-----------------------------------------------------------------------------]]
function ns.tagMaint:CreateMaintainTagsFrame()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all content for maintaining tags
    local mainFrame = CreateFrame("Frame", nil, ns.data.ui.tabs[ns.tagMaint.tabKey]) --, "InsetFrameTemplate")
    mainFrame:SetPoint("TOPLEFT", ns.data.ui.tabs[ns.tagMaint.tabKey], "TOPLEFT", padding, -50)
    mainFrame:SetPoint("BOTTOMRIGHT", ns.data.ui.tabs[ns.tagMaint.tabKey], "BOTTOMRIGHT", -padding, padding)
    -- mainFrame:SetPoint("BOTTOMLEFT", ns.data.ui.frame.leftFrame, "BOTTOMRIGHT", padding, 0)
    -- mainFrame:SetWidth(400)

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

    -- create left column for instructions
    local instructFrame = ns.tagMaint:BuildInstructionColumn(insetFrame, 350)

    -- create frame for picking a tag
    local pickTagFrame = ns.tagMaint:BuildTagListingColumn(insetFrame, instructFrame, 200)

    -- creation options and button
    local optionsFrame = ns.tagMaint:BuildTagOptionsFrame(insetFrame, pickTagFrame)
end

--[[---------------------------------------------------------------------------
    Function:   BuildInstructionColumn
    Purpose:    Create instructions for the tag maintenance functionality.
-----------------------------------------------------------------------------]]
function ns.tagMaint:BuildInstructionColumn(parentFrame, columnWidth)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all content
    local instructFrame = CreateFrame("Frame", nil, parentFrame) --, "InsetFrameTemplate")
    instructFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    instructFrame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 0, 0)
    instructFrame:SetWidth(columnWidth)

    -- instruction frame title
    local title = instructFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", instructFrame, "TOPLEFT", padding, -padding)
    title:SetText(ns.L["Instructions:"])

    -- instruction frame
    local instructTextFrame = CreateFrame("Frame", nil, instructFrame, "InsetFrameTemplate")
    instructTextFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    instructTextFrame:SetPoint("BOTTOMRIGHT", instructFrame, "BOTTOMRIGHT", 0, padding)

    -- define instructions
    local instructions = {
        {
            title = ns.L["Add a New Tag"],
            text = {
                ns.L["Select a tag from the list. Then click 'New Tag Above' or 'New Tag Below' to create a new tag relative to the selected tag."],
                ns.L["A dialog will show and you must  enter a unique ID and a name for the new tag. The ID may only contain lowercase letters and numbers."],
            }
        },
        {
            title = ns.L["Rename Tag"],
            text = {
                ns.L["Select a tag from the list. Then click 'Rename Tag' to change the name of the selected tag. ID is not editable."],
                ns.L["A dialog will show and you must enter a new name for the tag."],
                ns.L["Note: If you want to change the ID you must create a new tag and delete the old one."]
            }
        },
        {
            title = ns.L["Delete Tag"],
            text = {
                ns.L["Select a tag from the list. Then click 'Delete Tag' to remove the selected tag."],
                (ns.L["If the option '%s' is checked, the tag will NOT be deleted."]):format(ns.L["Prevent Tag Deletion if Toys Assigned"]),
                ns.L["Otherwise, tags are deleted but associated toys moved to the uncategorized tag."]
            }
        }
    }

    -- keep track of objects for the loop
    local rowFrame = {}

    -- padding for text listing
    local spacing = 5

    -- loop over the instructions and build the text
    for dataIdx, instructData in pairs(instructions) do
        -- track height
        local frameHeight = 0

        -- create row
        rowFrame[dataIdx] = CreateFrame("Frame", nil, instructTextFrame) --, "InsetFrameTemplate")
        if dataIdx == 1 then
            rowFrame[dataIdx]:SetPoint("TOPLEFT", instructTextFrame, "TOPLEFT", spacing, -spacing)
            rowFrame[dataIdx]:SetPoint("TOPRIGHT", instructTextFrame, "TOPRIGHT", -spacing, -spacing)
        else
            rowFrame[dataIdx]:SetPoint("TOPLEFT", rowFrame[dataIdx - 1], "BOTTOMLEFT", 0, -spacing)
            rowFrame[dataIdx]:SetPoint("TOPRIGHT", rowFrame[dataIdx - 1], "BOTTOMRIGHT", 0, -spacing)
        end
        rowFrame[dataIdx]:SetHeight(100)

        -- add header
        local instructHdr = rowFrame[dataIdx]:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        instructHdr:SetPoint("TOPLEFT", rowFrame[dataIdx], "TOPLEFT", spacing, -spacing)
        instructHdr:SetPoint("RIGHT", rowFrame[dataIdx], "RIGHT", -spacing, 0)
        instructHdr:SetText(instructData.title)
        instructHdr:SetJustifyH("LEFT")
        frameHeight = instructHdr:GetStringHeight() + (spacing * 2)

        -- reset the textFrame table
        local textFrame = {}

        -- loop over the text
        for idx, rowData in pairs(instructData.text) do
            -- text frame
            textFrame[idx] = CreateFrame("Frame", nil, rowFrame[dataIdx]) --, "InsetFrameTemplate")
            if idx == 1 then
                textFrame[idx]:SetPoint("TOPLEFT", instructHdr, "BOTTOMLEFT", 0, -spacing)
                textFrame[idx]:SetPoint("TOPRIGHT", instructHdr, "BOTTOMRIGHT", 0, -spacing)
            else
                textFrame[idx]:SetPoint("TOPLEFT", textFrame[idx - 1], "BOTTOMLEFT", 0, -spacing)
                textFrame[idx]:SetPoint("TOPRIGHT", textFrame[idx - 1], "BOTTOMRIGHT", 0, -spacing)
            end
            textFrame[idx]:SetHeight(100)

            -- add bullet
            local bullet = textFrame[idx]:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            bullet:SetText("• ")
            bullet:SetPoint("TOPLEFT", textFrame[idx], "TOPLEFT", spacing, -spacing)

            -- add text
            local instructText = textFrame[idx]:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            instructText:SetPoint("TOPLEFT", bullet, "TOPRIGHT", 0, 0)
            instructText:SetPoint("RIGHT", textFrame[idx], "RIGHT", -spacing, 0)
            instructText:SetText(rowData)
            instructText:SetJustifyH("LEFT")
            instructText:SetJustifyV("TOP")
            instructText:SetWordWrap(true)

            -- set height of frame
            textFrame[idx]:SetHeight(instructText:GetStringHeight() + (spacing * 2))
            frameHeight = frameHeight + textFrame[idx]:GetHeight() + spacing
        end

        -- set frame height
        rowFrame[dataIdx]:SetHeight(frameHeight)
    end

    -- return the column
    return instructFrame
end

--[[---------------------------------------------------------------------------
    Function:   BuildTagListingColumn
    Purpose:    Create a scrollable list of tags for selection.
-----------------------------------------------------------------------------]]
function ns.tagMaint:BuildTagListingColumn(parentFrame, positionFrame, columnWidth)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all content
    local pickTagFrame = CreateFrame("Frame", nil, parentFrame) --, "InsetFrameTemplate")
    pickTagFrame:SetPoint("TOPLEFT", positionFrame, "TOPRIGHT", 0, 0)
    pickTagFrame:SetPoint("BOTTOMLEFT", positionFrame, "BOTTOMRIGHT", 0, 0)
    pickTagFrame:SetWidth(columnWidth)

    -- create scroll box for tag maintenance
    -- variable mainly for the PopulateTagMaintList function to access the scroll box
    ns.data.ui.scroll.tagMaint = ns.tagMaint:CreateTagMaintScrollList(pickTagFrame)

    -- populate the scroll box with tag data
    ns.tagMaint:PopulateTagMaintList()

    -- return the frame
    return pickTagFrame
end

--[[---------------------------------------------------------------------------
    Function:   ButtonCheckWidth
    Purpose:    Ensure all buttons in a given list have the same width based on the widest button's text.
    Arguments:  buttons - a table of button objects to check and adjust
-----------------------------------------------------------------------------]]
function ns.tagMaint:ButtonCheckWidth(buttons)
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

function ns.tagMaint:IsTagSelected()
    local selectedTag = ns.gets:GetSelectedTag()
    return selectedTag ~= "none"
end

function ns.tagMaint:OnClick_NewTag(above)
    -- verify tag selected
    if ns.tagMaint:IsTagSelected() == false then return end

    -- need global index name for each popup
    ns.data.popups.newtaginput = addonName .. "NewTagInput"

    -- notify user we are going to reset toy filters
    StaticPopupDialogs[ns.data.popups.newtaginput] = {
        text = ns.L["Enter an ID and Name for the tag. ID may only contain lowercase letters and numbers and have a max length of 20 characters."],
        button1 = ns.L["OK"],
        button2 = ns.L["Cancel"],
        timeout = 30,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function()
            local toyCount = ns.ToyFunctions:ResetAPIFilters()
            ns:Print(("Toy Count: %s"):format(toyCount))
            ns.ToyFunctions:LoadToyList(toyCount)
            ns.ToyFunctions:LoadTagList()
            ns.ToyFunctions:UpdateToyIndexes()
        end
    }

    -- show the popup
    StaticPopup_Show(ns.data.popups.resettoyfilters)

    -- process based on placement of new tag
    if above == true then

    else

    end
end

function ns.tagMaint:OnClick_EditTag()

end

function ns.tagMaint:OnClick_DeleteTag()

end

--[[---------------------------------------------------------------------------
    Function:   BuildTagOptionsFrame
    Purpose:    Create a frame with options for tag maintenance (checkbox and buttons).
    Arguments:  parentFrame - the parent frame to attach the options frame to
                positionFrame - the frame to position the options frame relative to
-----------------------------------------------------------------------------]]
function ns.tagMaint:BuildTagOptionsFrame(parentFrame, positionFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- top level frame to hold all visible items for this section
    local optionFrame = CreateFrame("Frame", nil, parentFrame)
    optionFrame:SetPoint("TOPLEFT", positionFrame, "TOPRIGHT", 0, 0)
    optionFrame:SetPoint("RIGHT", parentFrame, "RIGHT", 0, 0)

    -- label for the options frame
    local optionLabel = optionFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    optionLabel:SetJustifyH("LEFT")
    optionLabel:SetPoint("TOPLEFT", optionFrame, "TOPLEFT", padding, -padding)
    optionLabel:SetText(ns.L["Tag Edits:"])
    local frameHeight = optionLabel:GetHeight() + padding

    -- frame to hold buttons
    local insetFrame = CreateFrame("Frame", nil, optionFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", optionLabel, "BOTTOMLEFT", 0, -5)
    insetFrame:SetPoint("BOTTOMRIGHT", optionFrame, "BOTTOMRIGHT", -padding, padding)

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

    -- create buttons for managing tags (New, Edit, Delete)
    local buttonPadding = 5
    local btnNewTagAbove = ns:CreateStandardButton(insetFrame, nil, ns.L["New Tag Above"], 40, function() ns.tagMaint:OnClick_NewTag(true) end)
    btnNewTagAbove:SetPoint("TOPLEFT", checkboxPreventDelete.frame, "BOTTOMLEFT", 0, -buttonPadding)
    frameHeight = frameHeight + btnNewTagAbove:GetHeight() + buttonPadding
    local btnNewTagBelow = ns:CreateStandardButton(insetFrame, nil, ns.L["New Tag Below"], 40, function() ns.tagMaint:OnClick_NewTag(false) end)
    btnNewTagBelow:SetPoint("TOPLEFT", btnNewTagAbove, "BOTTOMLEFT", 0, -buttonPadding)
    frameHeight = frameHeight + btnNewTagBelow:GetHeight() + buttonPadding
    local btnEditTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Rename Tag"], 40, function() ns.tagMaint:OnClick_EditTag() end)
    btnEditTag:SetPoint("TOPLEFT", btnNewTagBelow, "BOTTOMLEFT", 0, -buttonPadding)
    frameHeight = frameHeight + btnEditTag:GetHeight() + buttonPadding
    local btnDeleteTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Delete Tag"], 40, function() ns.tagMaint:OnClick_DeleteTag() end)
    btnDeleteTag:SetPoint("TOPLEFT", btnEditTag, "BOTTOMLEFT", 0, -buttonPadding)

    -- instead of buttonPadding (5) we want the same padding as the top
    frameHeight = frameHeight + btnDeleteTag:GetHeight() + padding

    -- fix button widths
    ns.tagMaint:ButtonCheckWidth({btnNewTagAbove, btnNewTagBelow, btnEditTag, btnDeleteTag})

    -- set height of the option frame
    optionFrame:SetHeight(frameHeight)
end

--[[---------------------------------------------------------------------------
    Function:   CreateTagMaintScrollList
    Purpose:    Create a scrollable list frame for maintaining tags.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
function ns.tagMaint:CreateTagMaintScrollList(parent)
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
    view:SetElementExtentCalculator(function(dataIndex, data)
        --@debug@
        -- ns:Print(("Calculating height for dataIndex %d with name %s"):format(dataIndex, data.name or "Unknown"))
        --@end-debug@
        return ns.data.ui.height.toyMaintCell
    end)

    -- 3. Element initializer (called when a row becomes visible)
    view:SetElementInitializer("BackdropTemplate", function(frame, data)
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
                ns.tagMaint:CheckedTagMaintenance(self)
            end)
        end

        -- update/set attribute and text
        frame.tagCheckbox:SetAttribute(ns.data.tagAttrName, data.tagId)
        frame.tagCheckbox:SetAttribute(ns.data.tagAttrOrder, data.order)
        frame.tagCheckbox.Text:SetText(data.name)
    end)

    -- 4. Element resetter (cleanup when row scrolls out of view)
    view:SetElementResetter(function(frame)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end)

    -- 5. Connect everything
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- 6. Auto-hide scrollbar when not needed
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)

    return scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   CheckedTagMaintenance
    Purpose:    Handle the logic when a tag maintenance checkbox is clicked.
-----------------------------------------------------------------------------]]
function ns.tagMaint:CheckedTagMaintenance(checkedBox)
    -- get the checkbox addon attribute which contains the tag ID
    local id = checkedBox:GetAttribute(ns.data.tagAttrName)

    -- loop over all checkboxes and uncheck them but this one
    for _, globalName in pairs(ns.data.ui.checkbox.tagMaint) do
        local checkbox = _G[globalName]
        if checkbox and checkbox ~= checkedBox then
            checkbox:SetChecked(false)
        end
    end

    --@debug@
    if true then
        local isChecked = checkedBox:GetChecked()
        local name = checkedBox:GetName()
        local order = checkedBox:GetAttribute(ns.data.tagAttrOrder)
        ns:Print(("Tag '%s' checkbox clicked. Checked: %s (ID: %s, Order: %s)"):format(name, tostring(isChecked), tostring(id), tostring(order)))
    end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   PopulateTagMaintList
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
function ns.tagMaint:PopulateTagMaintList()
    -- create data provider for scrollbox
    if ns.data.dp.toyMaintList == nil then
        ns.data.dp.toyMaintList = CreateDataProvider()
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

    -- pass refreshed data into scroll box
    ns.data.ui.scroll.tagMaint:SetDataProvider(ns.data.dp.toyMaintList)

    --@debug@
    -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
    --@end-debug@
end