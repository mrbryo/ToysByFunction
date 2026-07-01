--[[ ------------------------------------------------------------------------
	Title: 			ToyMaint.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-26
	Description: 	Building the Toy Maintenance tab in the UI.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.toyMaint = {}

--[[---------------------------------------------------------------------------
    Function:   CreateLeftToyFrame
    Purpose:    Create the left frame for displaying the list of toys based on the selected tag.
-----------------------------------------------------------------------------]]
function ns.toyMaint:CreateLeftToyFrame()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all the content on the left side
    ns.data.ui.frame.leftFrame = CreateFrame("Frame", nil, ns.data.ui.frame.main)
    ns.data.ui.frame.leftFrame:SetPoint("TOPLEFT", ns.data.ui.frame.main, "TOPLEFT", padding, -60)
    ns.data.ui.frame.leftFrame:SetPoint("BOTTOMLEFT", ns.data.ui.frame.main, "BOTTOMLEFT", padding, padding)
    ns.data.ui.frame.leftFrame:SetWidth(400)

    -- add label to left frame
    local leftFrameLabel = ns.data.ui.frame.leftFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftFrameLabel:SetJustifyH("LEFT")
    leftFrameLabel:SetPoint("TOPLEFT", ns.data.ui.frame.leftFrame, "TOPLEFT", 0, 0)
    leftFrameLabel:SetText(ns.L["Filtered List of Toys by Tag:"])

    -- create inset frame
    local mainleft = CreateFrame("Frame", nil, ns.data.ui.frame.leftFrame, "InsetFrameTemplate")
    mainleft:SetPoint("TOPLEFT", leftFrameLabel, "BOTTOMLEFT", 0, 0)
    mainleft:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.leftFrame, "BOTTOMRIGHT", 0, 0)

    -- label for dropdown
    local dropdownLabel = mainleft:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(ns.L["Tag:"])

    -- initialize drop down items with "none" option
    local items = {["none"] = ns.L["No Tag Selected"]}

    -- set initial tag order
    local itemOrder = {"none"}

    -- create dropdown
    ns.data.ui.dropdown.filterToysByTag = ns:CreateDropdown(mainleft, itemOrder, items, "none", ns.gets:GetObjectName("DropdownFilterTag"), function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            --@debug@
            ns:Print(("Tag Selected: %s"):format(key))
            --@end-debug@
            -- need to add code to reload view of toys based on the selected tag
            -- ns:SetFilterTag(key)
            -- ns:UpdateToyList()
            ns.sets:SetFilterTag(key)
            ns:PopulateToysByTag()
        end
    end)
    ns.data.ui.dropdown.filterToysByTag:SetWidth(200)

    -- position the label and the dropdown
    local dropdownOffset = (ns.data.ui.dropdown.filterToysByTag:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    dropdownLabel:SetPoint("TOPLEFT", mainleft, "TOPLEFT", padding, -(padding + dropdownOffset))
    ns.data.ui.dropdown.filterToysByTag:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)

    -- add menu button for sorting
    local optionButton = ns:CreateToyMainOptionsButton(mainleft)
    optionButton:SetPoint("LEFT", ns.data.ui.dropdown.filterToysByTag, "RIGHT", padding, 0)

    -- new scroll tech
    ns.data.ui.scroll.toysLeft = ns:CreateToyScrollList(mainleft)

    -- update the dropdown with the current tags
    ns:UpdateFilterBarTags()
end

--[[---------------------------------------------------------------------------
    Function:   CreateToyMainOptionsButton
    Purpose:    Create a button that opens a dropdown menu for toy options.
                This includes sorting order and tooltip display options.
-----------------------------------------------------------------------------]]
function ns.toyMaint:CreateToyMainOptionsButton(parent)
    -- local functions for sorting
    local function SetSorting(key)
        --@debug@
        -- ns:Print(("SetToySortingOrderMainConfig called with key: %s"):format(tostring(key)))
        --@end-debug@
        ns.sets:SetToySortingOrderMainConfig(key)
        ns:PopulateToysByTag()
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
        ns.sets:SetOptionShowToyTooltips()
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
    Function:   CreateToyScrollList
    Purpose:    Create a scrollable list frame for displaying toys.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
function ns.toyMaint:CreateToyScrollList(parent)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    scrollBox:SetPoint("TOP", ns.data.ui.dropdown.filterToysByTag, "BOTTOM", 0, -padding)
    scrollBox:SetPoint("LEFT", parent, "LEFT", 5, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 5)

    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- 2. Configure view with fixed row height; for variable-height elements
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(dataIndex, data)
        --@debug@
        -- ns:Print(("Calculating height for dataIndex %d with name %s"):format(dataIndex, data.name or "Unknown"))
        --@end-debug@
        return 32 + padding + padding
    end)

    -- 3. Element initializer (called when a row becomes visible)
    view:SetElementInitializer("InsetFrameTemplate", function(frame, data)
        -- standard variables
        local padding = ns.data.constants.ui.generic.padding

        -- icon on left
        if frame.icon == nil then
            frame.icon = frame:CreateTexture(nil, "OVERLAY")
            frame.icon:SetSize(32, 32)
            frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        end
        frame.icon:SetTexture(data.icon or "Interface\\Icons\\inv_misc_questionmark")

        -- toy name on top right of icon
        if not frame.toyName then
            frame.toyName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.toyName:SetJustifyH("LEFT")
            frame.toyName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", padding, 0)
        end
        frame.toyName:SetText(data.name or "Unknown Toy")

        -- tooltip data
        -- if not frame.lines then
        --     frame.lines = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        --     frame.lines:SetJustifyH("LEFT")
        --     frame.lines:SetPoint("TOPLEFT", frame.toyName, "BOTTOMLEFT", 0, -padding)
        --     frame.lines:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
        -- end
        -- frame.lines:SetText(data.lines)
        -- local newHeight = frame.toyName:GetStringHeight() + frame.lines:GetStringHeight() + (padding * 3)
        -- frame:SetHeight(newHeight)

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

    --@debug@
    -- ns:Print("Created Scroll Box List for Toys")
    --@end-debug@

    return scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   PopulateToysByTag
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
function ns.toyMaint:PopulateToysByTag()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- make sure frame exists before proceeding
    -- if not ns.data.ui.frame.filteredToys then return end

    -- current selected tag
    local selectedTag = ns.gets:GetFilterTag() or "none"

    -- create data provided for scrollbox
    if ns.data.dp.leftToyList == nil then
        ns.data.dp.leftToyList = CreateDataProvider()
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
        for _, itemId in pairs(ns.db.global.toys.byTag[selectedTag]) do
            local strItemId = tostring(itemId)
            if ns.db.global.toys.byItemId[strItemId] then
                local itemInfo = ns.db.global.toys.byItemId[strItemId]
                toyRows[#toyRows + 1] = {
                    itemId = itemId,
                    name   = itemInfo.name or "",
                    icon   = itemInfo.icon,
                }
            else
                -- TODO: Add an error log for missing data or issues.
                --@debug@
                -- ns:Print(("No item data found for itemId %s, skipping."):format(itemId))
                --@end-debug@
            end
        end

        -- sort alphabetically based on the configured sort order
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

        -- pass refreshed data into scroll box
        ns.data.ui.scroll.toysLeft:SetDataProvider(ns.data.dp.leftToyList)

        --@debug@
        -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
        --@end-debug@
    end
end

--[[---------------------------------------------------------------------------
    Function:   UpdateFilterBarTags
    Purpose:    Update the filter bar dropdown with the current tags.
-----------------------------------------------------------------------------]]
function ns.toyMaint:UpdateFilterBarTags()
    -- initialize drop down items with "none" option
    local items = {["none"] = self.L["No Tag Selected"]}
    local itemOrder = {"none"}

    -- determine tag order
    local tagOrder = {}

    -- does player profile have an order? if not use global settings
    if ns.db.profile[ns.data.currentPlayerServer].tags and ns.db.profile[ns.data.currentPlayerServer].tags.order then
        tagOrder = ns.db.profile[ns.data.currentPlayerServer].tags.order
    end
    if #tagOrder == 0 then
       tagOrder = ns.db.global.tags.order
    end

    -- populate drop down with all tags
    for tagID, tagData in pairs(tagOrder) do
        items[tagID] = ns.L[tagID] or tagID
        -- add 1 to the order number to account for the "none" option at the beginning
        local orderNbr = tagData.order + 1
        table.insert(itemOrder, orderNbr, tagID)
        -- ns:Print(("Filter Updated: %s (%s) with order %d"):format(tagID, ns.L[tagID] or tagID, tagData.order))
    end

    --@debug@
    -- for idx, id in pairs(itemOrder) do
    --     ns:Print(("Dropdown Item Order %d: %s"):format(idx, id))
    -- end
    --@end-debug@

    -- get the last selected tag
    local selectedItem = ns.gets:GetFilterTag() or "none"

    -- trigger update
    ns.data.ui.dropdown.filterToysByTag:UpdateItems(itemOrder, items, selectedItem)
end