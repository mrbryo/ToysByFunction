--[[ ------------------------------------------------------------------------
	Title: 			ToyMaint.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-26
	Description: 	Building the Toy Maintenance tab in the UI.
-----------------------------------------------------------------------------]]

---@class ns
local addonName, ns = ...

-- store all toy maintenance functions to its own space in the namespace...why? easier code completion and organization
ns.toyMaint = {}

-- track the toys the user has selected
ns.toyMaint.selectedToys = {}

-- dropdown id's
ns.toyMaint.dropdownId = {
    filter = 0,
    move = 1,
}

-- store each frames height
ns.toyMaint.toyScrollFrameHeight = {}

--[[---------------------------------------------------------------------------
    Function:   LogEntry
    Purpose:    Add an entry to the move log for toy maintenance actions.
    Arguments:  itemId - the ID of the toy being moved
                message - a descriptive message about the action taken
-----------------------------------------------------------------------------]]
local function LogEntry(itemId, message)
    table.insert(ns.db.log.toyMove, { itemId = tostring(itemId), message = message })
end

local function PopulateLogs()
    if ns.data.ui.scroll.moveLog == nil then return end

    -- create data provided for scrollbox
    if ns.data.dp.moveLog == nil then
        ns.data.dp.moveLog = CreateDataProvider()

        -- pass refreshed data into scroll box
        ns.data.ui.scroll.moveLog:SetDataProvider(ns.data.dp.moveLog)
        --@debug@
        -- ns:Print("Created DataProvider for Left Toy List")
        --@end-debug@
    end

    -- reset data provider
    ns.data.dp.moveLog:Flush()

    -- insert log entries into the data provider
    if ns.db.log.toyMove ~= nil then
        for _, logEntry in ipairs(ns.db.log.toyMove) do
            ns.data.dp.moveLog:Insert(logEntry)
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   PopulateToysByTag
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
local function PopulateToysByTag()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- make sure frame exists before proceeding
    -- if not ns.data.ui.frame.filteredToys then return end

    -- current selected tag
    local selectedTag = ns.gets:GetFilterTag() or "none"

    -- create data provided for scrollbox
    if ns.data.dp.leftToyList == nil then
        ns.data.dp.leftToyList = CreateDataProvider()

        -- pass refreshed data into scroll box
        ns.data.ui.scroll.toysLeft:SetDataProvider(ns.data.dp.leftToyList)
        --@debug@
        -- ns:Print("Created DataProvider for Left Toy List")
        --@end-debug@
    end

    -- loop over toys by tag if a selected tag is returned
    if selectedTag ~= "none" then
        -- reset data provider
        ns.data.dp.leftToyList:Flush()

        -- collect valid toys into a sortable table
        local toyRows = {}
        if ns.db.global.toys.byTag[selectedTag] ~= nil then
            for _, itemId in pairs(ns.db.global.toys.byTag[selectedTag]) do
                local strItemId = tostring(itemId)
                if ns.db.global.toys.byItemId[strItemId] then
                    local itemInfo = ns.db.global.toys.byItemId[strItemId]
                    toyRows[#toyRows + 1] = {
                        itemId = itemId,
                        name   = itemInfo.name or "",
                        icon   = itemInfo.icon,
                        effect  = itemInfo.tooltip.effect,
                    }
                else
                    -- TODO: Add an error log for missing data or issues.
                    --@debug@
                    -- ns:Print(("No item data found for itemId %s, skipping."):format(itemId))
                    --@end-debug@
                end
            end
        end

        -- sort alphabetically based on the configured sort order
        if toyRows ~= {} then
            local sortOrder = ns.gets:GetToySortingOrderMainConfig() or "az"
            if sortOrder == "za" then
                table.sort(toyRows, function(a, b) return a.name > b.name end)
            else
                table.sort(toyRows, function(a, b) return a.name < b.name end)
            end

            -- insert sorted rows into the data provider
            for _, row in ipairs(toyRows) do
                ns.data.dp.leftToyList:Insert(row)
            end
        end

        --@debug@
        -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
        --@end-debug@
    end
end

--[[---------------------------------------------------------------------------
    Function:   CreateToyMainOptionsButton
    Purpose:    Create a button that opens a dropdown menu for toy options.
                This includes sorting order and tooltip display options.
-----------------------------------------------------------------------------]]
local function CreateToyMainOptionsButton(parent)
    -- local functions for sorting
    local function SetSorting(key)
        --@debug@
        -- ns:Print(("SetToySortingOrderMainConfig called with key: %s"):format(tostring(key)))
        --@end-debug@
        ns.sets:SetToySortingOrderConfigFrame(key)
        PopulateToysByTag()
    end

    local function GetSorting(key)
        local value = ns.gets:GetToySortingOrderMainConfig()
        --@debug@
        -- ns:Print(("GetToySortingOrderMainConfig returned value: %s"):format(tostring(value)))
        --@end-debug@
        return value == key
    end

    -- local functions for showing tooltips
    local function SetTooltips()
        ns.sets:SetTooltipOption(scrollKey)
    end

    local function IsTooltipEnabled()
        local value = ns.gets:GetOptionShowToyTooltips()
        --@debug@
        -- ns:Print(("(IsTooltipEnabled) Show Toy Tooltips option is: %s"):format(tostring(value)))
        --@end-debug@
        return value
    end

    local function GeneratorFunction(owner, rootDescription)
        -- checkbox for enabling/disabling toy tooltips
        rootDescription:CreateCheckbox(ns.L["Show Toy Tooltips"], IsTooltipEnabled, SetTooltips)

        -- submenu for setting sort order
        local sortSubMenu = rootDescription:CreateButton("Sort");
        sortSubMenu:CreateRadio(ns.L["A-Z"], GetSorting, SetSorting, "az")
        sortSubMenu:CreateRadio(ns.L["Z-A"], GetSorting, SetSorting, "za")
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
    Function:   PopulateRow
    Purpose:    Populate a row in the scroll box with toy data.
                This includes the icon, name, and tooltip functionality.
    Arguments:  frame - the row frame to populate
                data - the toy data to display in the row
-----------------------------------------------------------------------------]]
local function PopulateRow(frame, data)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- checkbox for selection
    if frame.checkbox == nil then
        frame.checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        frame.checkbox:SetText("")
        frame.checkbox:SetScript("OnClick", function(selfObject)
            ns.toyMaint.selectedToys[data.itemId] = selfObject:GetChecked()
        end)
    end
    frame.checkbox:SetChecked(ns.toyMaint.selectedToys[data.itemId] or false)

    -- icon on left
    if frame.icon == nil then
        frame.icon = frame:CreateTexture(nil, "OVERLAY")
        frame.icon:SetSize(32, 32)
        -- frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        frame.icon:SetPoint("LEFT", frame.checkbox, "RIGHT", padding, 0)
    end
    frame.icon:SetTexture(data.icon or "Interface\\Icons\\inv_misc_questionmark")

    -- toy name on top right of icon
    if frame.toyName == nil then
        frame.toyName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.toyName:SetJustifyH("LEFT")
        frame.toyName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", padding, 0)
    end
    frame.toyName:SetText(data.name or "Unknown Toy")

    -- usage below name
    if frame.toyUsage == nil then
        frame.toyUsage = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.toyUsage:SetJustifyH("LEFT")
        frame.toyUsage:SetWordWrap(true)
    end
    if data.effect == nil then
        frame.toyUsage:ClearAllPoints()
    else
        frame.toyUsage:SetPoint("TOPLEFT", frame.toyName, "BOTTOMLEFT", 0, -5)
        frame.toyUsage:SetPoint("RIGHT", frame, "RIGHT", -padding, 0)
        frame.toyUsage:SetText(data.effect or ns.L["No usage information available."])
    end

    -- set height of frame based on content; if no usage then just use name height + padding
    local currentHeight = frame:GetHeight()
    local newHeight = frame.toyName:GetStringHeight() + frame.toyUsage:GetStringHeight() + (padding * 2) + 5
    newHeight = math.max(newHeight, currentHeight)
    frame:SetHeight(newHeight)

    -- store the height for scrolling since frames are hidden or show based on scrolling through the list
    ns.toyMaint.toyScrollFrameHeight[data.itemId] = newHeight

    -- add tooltip functionality
    frame:SetScript("OnEnter", function(self)
        local showTooltips = ns.gets:GetOptionShowToyTooltips()
        if not showTooltips then return end

        if showTooltips == true then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetToyByItemID(data.itemId)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

--[[---------------------------------------------------------------------------
    Function:   CreateToyScrollList
    Purpose:    Create a scrollable list frame for displaying toys.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
local function CreateToyScrollList(parentFrame, positionFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, parentFrame, "WowScrollBoxList")
    scrollBox:SetPoint("TOP", positionFrame, "BOTTOM", 0, -padding)
    scrollBox:SetPoint("LEFT", parentFrame, "LEFT", 5, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 5)

    local scrollBar = CreateFrame("EventFrame", nil, parentFrame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- 2. Configure view with fixed row height; for variable-height elements
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(dataIndex, data)
        --@debug@
        -- ns:Print(("Calculating height for dataIndex %d with name %s"):format(dataIndex, data.name or "Unknown"))
        --@end-debug@
        local height = ns.toyMaint.toyScrollFrameHeight[data.itemId]
        if height == nil then
            height = 32 + padding + padding
        end
        return height
    end)

    -- 3. Element initializer (called when a row becomes visible)
    view:SetElementInitializer("InsetFrameTemplate", function(frame, data)
        PopulateRow(frame, data)
    end)

    -- 4. Element resetter (cleanup when row scrolls out of view)
    view:SetElementResetter(function(frame, data)
        PopulateRow(frame, data)
    end)

    -- 5. Connect everything
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- 6. Auto-hide scrollbar when not needed
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)

    --@debug@
    -- ns:Print("Created Scroll Box List for Toys")
    --@end-debug@

    return scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   UpdateDropdowns
    Purpose:    Update the dropdown with the current tags.
-----------------------------------------------------------------------------]]
local function UpdateDropdowns()
    -- initialize drop down items with "none" option
    local items = {}
    local itemOrder = {}

    -- populate drop down with all tags
    local tagsInserted = false
    for tagID, tagData in pairs(ns.db.global.tags.order) do
        -- insert tags into items table by tag id
        items[tagID] = tagData.name or ns.L[tagID] or tagID

        -- insert tag
        itemOrder[tagData.order] = tagID

        -- confirm tag inserted
        tagsInserted = true

        --@debug@
        -- ns:Print(("Filter Updated: %s (%s) with order %d"):format(tagID, ns.L[tagID] or tagID, tagData.order))
        --@end-debug@
    end

    -- if no tags then add base value
    if tagsInserted == false then
        items["none"] = ns.L["No Tags"]
        itemOrder[1] = "none"
    end

    -- update tag filter dropdown
    local selectedItem = ns.gets:GetFilterTag() or ns.data.constants.defaults.tagFilter
    ns.data.ui.dropdown.filterToysByTag:UpdateItems(itemOrder, items, selectedItem)

    -- update tag move dropdown
    selectedItem = ns.gets:GetMoveToyTag() or ns.data.constants.defaults.tagMove
    ns.data.ui.dropdown.moveToys:UpdateItems(itemOrder, items, selectedItem)

    --@debug@
    -- for x, y in pairs(items) do
    --     ns:Print(("Dropdown Item: %s (%s)"):format(x, y))
    -- end
    -- for x, y in ipairs(itemOrder) do
    --     ns:Print(("Dropdown Order: %d - %s"):format(x, y))
    -- end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   CreateLeftToyFrame
    Purpose:    Create the left frame for displaying the list of toys based on the selected tag.
-----------------------------------------------------------------------------]]
local function CreateLeftToyFrame(parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all the content on the left side
    local colFrame = CreateFrame("Frame", nil, parentFrame)
    colFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", padding, -padding)
    colFrame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", padding, padding)
    colFrame:SetWidth(400)

    -- add label to left frame
    local leftFrameLabel = colFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftFrameLabel:SetJustifyH("LEFT")
    leftFrameLabel:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 0, 0)
    leftFrameLabel:SetText(ns.L["Filtered List of Toys by Tag:"])

    -- create inset frame
    local colInset = CreateFrame("Frame", nil, colFrame, "InsetFrameTemplate")
    colInset:SetPoint("TOPLEFT", leftFrameLabel, "BOTTOMLEFT", 0, -5)
    colInset:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", 0, 0)

    -- label for dropdown
    local dropdownLabel = colInset:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(ns.L["Tag:"])

    -- initialize drop down items with "none" option
    local items = {["none"] = ns.L["No Tags"]}

    -- set initial tag order
    local itemOrder = {"none"}

    -- create dropdown
    ns.data.ui.dropdown.filterToysByTag = ns:CreateDropdown(colInset, itemOrder, items, ns.gets:GetFilterTag(), ns.gets:GetObjectName("DropdownFilterTag"), function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            --@debug@
            -- ns:Print(("Tag Selected: %s"):format(key))
            --@end-debug@
            -- need to add code to reload view of toys based on the selected tag
            -- ns:SetFilterTag(key)
            -- ns:UpdateToyList()
            ns.sets:SetFilterTag(key)
            PopulateToysByTag()
        end
    end)
    ns.data.ui.dropdown.filterToysByTag:SetID(ns.toyMaint.dropdownId.filter)
    ns.data.ui.dropdown.filterToysByTag:SetWidth(200)

    -- position the label and the dropdown
    local dropdownOffset = (ns.data.ui.dropdown.filterToysByTag:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    dropdownLabel:SetPoint("TOPLEFT", colInset, "TOPLEFT", padding, -(padding + dropdownOffset))
    ns.data.ui.dropdown.filterToysByTag:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)

    -- add menu button for sorting
    local optionButton = CreateToyMainOptionsButton(colInset)
    optionButton:SetPoint("LEFT", ns.data.ui.dropdown.filterToysByTag, "RIGHT", padding, 0)

    -- new scroll tech
    ns.data.ui.scroll.toysLeft = CreateToyScrollList(colInset, ns.data.ui.dropdown.filterToysByTag)

    -- return top level frame
    return colFrame
end

local function MoveToyToTag(itemId, oldTag, newTag)
    -- must convert to string to correctly access db
    local strItemId = tostring(itemId)

    -- verify we still have a valid itemId
    if ns.db.global.toys.byItemId[strItemId] == nil then
        LogEntry(strItemId, ("Error: No toy data found for itemId %d."):format(itemId, newTag))
        return
    end

    -- remove from old tag; loop over the assigned tags and remove the old tag
    local newTagFound = false
    for idx, tag in pairs(ns.db.global.toys.byItemId[strItemId].tags) do
        if tag == oldTag then
            table.remove(ns.db.global.toys.byItemId[strItemId].tags, idx)
            LogEntry(strItemId, ("Removed Toy: %s (Item ID: %d) from Tag: %s"):format(ns.db.global.toys.byItemId[strItemId].name or ns.L["Unknown"], itemId, oldTag))
            break
        elseif tag == newTag then
            newTagFound = true
        end
    end

    -- add to new tag
    if newTagFound == false then
        table.insert(ns.db.global.toys.byItemId[strItemId].tags, newTag)
        LogEntry(strItemId, ("Added Toy: %s (Item ID: %d) to Tag: %s"):format(ns.db.global.toys.byItemId[strItemId].name or ns.L["Unknown"], itemId, newTag))
    else
        LogEntry(strItemId, ("Toy: %s (Item ID: %d) already exists in Tag: %s, not adding."):format(ns.db.global.toys.byItemId[strItemId].name or ns.L["Unknown"], itemId, newTag))
    end
end

local function MoveToys()
    -- disable ui features during a move
    -- TODO: Implement UI disabling if necessary

    -- clear the log
    ns.db.log.toyMove = {}

    -- get the selected tag
    local moveToTag = ns.gets:GetMoveToyTag()
    local oldTag = ns.gets:GetFilterTag()

    -- if the value is none then nothing has been selected; exit function
    if moveToTag == "none" then
        ns:GenericPopup(ns.L["No Tag Selected"])
        return
    end

    -- get the list of selected toys from the left scroll box
    local selectedToys = {}
    for itemId, isSelected in pairs(ns.toyMaint.selectedToys) do
        if isSelected == true then
            local strItemId = tostring(itemId)
            table.insert(selectedToys, strItemId)
            --@debug@
            --[[
            local name = ""
            if ns.db.global.toys.byItemId[strItemId] == nil then
                ns:Print(("Error: No toy data found for itemId %d."):format(itemId))
                name = ns.L["Unknown"]
            else
                name = ns.db.global.toys.byItemId[strItemId].name or ns.L["Unknown"]
                ns:Print(("Moving Toy: %s (Item ID: %d) to Tag: %s"):format(name, itemId or 0, moveToTag))
            end
            --]]
            --@end-debug@
        end
    end

    if #selectedToys == 0 then
        ns:GenericPopup(ns.L["No toys selected to move. Please select toys from the list."])
        return
    end

    -- move the selected toys to the new tag
    for _, itemId in ipairs(selectedToys) do
        MoveToyToTag(itemId, oldTag, moveToTag)
    end

    -- set all toys to not selected
    for itemId, _ in pairs(ns.toyMaint.selectedToys) do
        ns.toyMaint.selectedToys[itemId] = false
        -- ns:Print(("Deselected Toy: %s (Item ID: %d) after move."):format(ns.db.global.toys.byItemId[tostring(itemId)].name or ns.L["Unknown"], itemId))
    end

    -- update by tag global data
    ns.toyMaint:RefreshTranslations()

    -- refresh the toy list after moving toys
    PopulateToysByTag()

    -- refresh logs
    PopulateLogs()

    -- enable ui features after move
    -- TODO: Implement UI enabling if necessary
end

local function CreateToyFunctionFrame(parentFrame, relativeFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all the content on the left side
    local colFrame = CreateFrame("Frame", nil, parentFrame)
    colFrame:SetPoint("TOPLEFT", relativeFrame, "TOPRIGHT", padding, 0)
    colFrame:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -padding, -padding)
    colFrame:SetHeight(100)

    -- add label to left frame
    local frameLabel = colFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frameLabel:SetJustifyH("LEFT")
    frameLabel:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 0, 0)
    frameLabel:SetText(ns.L["Toy Functions"])
    local frameHeight = frameLabel:GetHeight()

    -- create inset frame
    local colInset = CreateFrame("Frame", nil, colFrame, "InsetFrameTemplate")
    colInset:SetPoint("TOPLEFT", frameLabel, "BOTTOMLEFT", 0, -5)
    colInset:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", 0, 0)
    frameHeight = frameHeight + 5

    -- create label for dropdown
    local dropdownLabel = colInset:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(ns.L["Tag:"])

    -- initialize drop down items with "none" option
    local items = {["none"] = ns.L["No Tag Selected"]}

    -- set initial tag order
    local itemOrder = {"none"}

    -- create dropdown
    ns.data.ui.dropdown.moveToys = ns:CreateDropdown(colInset, itemOrder, items, ns.gets:GetMoveToyTag(), ns.gets:GetObjectName("DropdownTargetTag"), function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            --@debug@
            -- ns:Print(("Tag Selected: %s"):format(key))
            --@end-debug@
            ns.sets:SetMoveToyTag(key)
        end
    end)
    ns.data.ui.dropdown.moveToys:SetID(ns.toyMaint.dropdownId.move)
    ns.data.ui.dropdown.moveToys:SetWidth(200)

    -- position the label and the dropdown
    local dropdownOffset = (ns.data.ui.dropdown.moveToys:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    local yOffset = padding + dropdownOffset
    dropdownLabel:SetPoint("TOPLEFT", colInset, "TOPLEFT", padding, -yOffset)
    ns.data.ui.dropdown.moveToys:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)
    frameHeight = frameHeight + ns.data.ui.dropdown.moveToys:GetHeight() + yOffset

    -- add menu button for sorting
    -- local optionButton = CreateToyMainOptionsButton(colInset)
    -- optionButton:SetPoint("LEFT", ns.data.ui.dropdown.moveToys, "RIGHT", padding, 0)

    -- button to trigger move of toys to new tag
    local moveButton = ns:CreateStandardButton(colInset, nil, ns.L["Move Toys"], nil, function(btnMoveToys)
        MoveToys()
    end)
    moveButton:SetPoint("LEFT", dropdownLabel, "LEFT", 0, -padding)
    moveButton:SetPoint("TOP", ns.data.ui.dropdown.moveToys, "BOTTOM", 0, -padding)
    frameHeight = frameHeight + moveButton:GetHeight() + padding

    -- adjust height
    colFrame:SetHeight(frameHeight)

    -- return top level frame
    return colFrame
end

local function PopulateLogRow(frame, data)
    if frame.text == nil then
        local padding = 5
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.text:SetJustifyH("LEFT")
        frame.text:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        frame.text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
    end
    frame.text:SetText(data.message or "")
end

local function CreateLogScrollbox(parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create scroll box for log entries
    local scrollBox = CreateFrame("Frame", nil, parentFrame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 5, -5)
    scrollBox:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 5)

    local scrollBar = CreateFrame("EventFrame", nil, parentFrame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- configure view with fixed row height
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(dataIndex, data)
        return 20
    end)

    -- element initializer
    view:SetElementInitializer("BackdropTemplate", function(frame, data)
        PopulateLogRow(frame, data)
    end)

    -- element resetter
    view:SetElementResetter(function(frame, data)
        PopulateLogRow(frame, data)
    end)

    -- connect everything
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- auto-hide scrollbar when not needed
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)

    return scrollBox
end

local function CreateLogFrame(parentFrame, relativeFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all the content on the left side
    local colFrame = CreateFrame("Frame", nil, parentFrame)
    colFrame:SetPoint("TOPLEFT", relativeFrame, "BOTTOMLEFT", 0, -padding)
    colFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -padding, padding)

    -- add label to left frame
    local frameLabel = colFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frameLabel:SetJustifyH("LEFT")
    frameLabel:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 0, 0)
    frameLabel:SetText(ns.L["Last Log"])

    -- create inset frame
    local colInset = CreateFrame("Frame", nil, colFrame, "InsetFrameTemplate")
    colInset:SetPoint("TOPLEFT", frameLabel, "BOTTOMLEFT", 0, -5)
    colInset:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", 0, 0)

    -- create scroll box for log entries
    ns.data.ui.scroll.moveLog = CreateLogScrollbox(colInset)

    -- populate the log scroll box with existing log entries
    PopulateLogs()

    -- return top level frame
    return colFrame
end

--[[---------------------------------------------------------------------------
    Function:   BuildUI
    Purpose:    Build the UI for the Toy Maintenance tab.
-----------------------------------------------------------------------------]]
local function BuildUI(parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create title for frame
    local title = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", padding, -padding)
    title:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -padding, -padding)
    title:SetHeight(30)
    title:SetJustifyH("CENTER")
    title:SetText(ns.L["Maintain Toys"])

    -- create inset frame
    local insetFrame = CreateFrame("Frame", nil, parentFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -padding, padding)

    -- create list of toys
    local leftColumn = CreateLeftToyFrame(insetFrame)

    -- create the frame with the list functions
    local moveToysFrame = CreateToyFunctionFrame(insetFrame, leftColumn)

    -- update the dropdown with the current tags
    UpdateDropdowns()

    -- create log frame
    local logFrame = CreateLogFrame(insetFrame, moveToysFrame)

    -- populate the log frame
    PopulateLogs()
end

local function OnShow_ToyMaintFrame(frameSelf)
    --@debug@
    -- ns:Print("OnShow triggered for Toy Maintenance tab")
    --@end-debug@
    UpdateDropdowns()
end

--[[---------------------------------------------------------------------------
    Function:   ProcessToyMaintFrame
    Purpose:    Create the Toy Maintenance tab content frame and build the UI.
                If the frame already exists, it will not be recreated.
    Arguments:  tabKey - the key for the tab to be processed
-----------------------------------------------------------------------------]]
function ns.toyMaint:ProcessToyMaintFrame(tabKey)
    -- set the tabkey property
    ns.toyMaint.tabKey = tabKey

    -- skip if the tab already exists
    if ns.data.ui.tabs[ns.toyMaint.tabKey] ~= nil then return end

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    ns.tabs:CreateTabContentFrame(tabKey)

    -- add on show to update data
    ns.data.ui.tabs[ns.toyMaint.tabKey]:SetScript("OnShow", function(frameSelf)
        OnShow_ToyMaintFrame()
    end)

    -- trigger the build of the toy ui
    BuildUI(ns.data.ui.tabs[ns.toyMaint.tabKey])
end

function ns.toyMaint:RefreshTranslations()
    -- reset the data structure
    ns.db.global.toys.byTag = {}

    -- loop over all the toys and rebuild the byTag structure
    for itemId, toyData in pairs(ns.db.global.toys.byItemId) do
        for _, tag in ipairs(toyData.tags) do
            if ns.db.global.toys.byTag[tag] == nil then
                ns.db.global.toys.byTag[tag] = {}
            end
            table.insert(ns.db.global.toys.byTag[tag], itemId)
        end
    end
end