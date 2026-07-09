--[[ ------------------------------------------------------------------------
	Title: 			ScrollToys.lua
	Author: 		mrbryo
	Create Date : 	07/08/2025
	Description: 	Standard for creating the toy scroll box used in several places.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

-- create holder for all functionality
ns.toyScroll = {
    -- holder for selected records
    selectedItems = {},
    -- holder for frame heights
    rowHeight = {},
    -- data providers
    dp = {},
    -- drop downs
    dropdown = {},
    -- drop down id
    dropdownId = {},
    -- drop down counter for creating the id
    dropdownCounter = 0,
    -- scroll boxes
    scrollbox = {},
    -- parent frames
    parent = {},
    -- checkbox enabled
    checkboxEnabled = {},
}


local function SetFilterTag(scrollKey, value)
    ns.db.profile[ns.data.currentPlayerServer].dropdown[scrollKey] = value
end

local function GetFilterTag(scrollKey)
    return ns.db.profile[ns.data.currentPlayerServer].dropdown[scrollKey] or nil
end

local function SetSortOrder(scrollKey, value)
    ns.db.profile[ns.data.currentPlayerServer].sortOrder[scrollKey] = value
end

local function GetSortOrder(scrollKey)
    return ns.db.profile[ns.data.currentPlayerServer].sortOrder[scrollKey] or nil
end

--[[---------------------------------------------------------------------------
    Function:   GetTooltipOption
    Purpose:    Toggle the option for showing toy tooltips in the main config.
    Arguments:  scrollKey - unique key for the object which can show tooltips
-----------------------------------------------------------------------------]]
function ns.toyScroll:GetTooltipOption(key)
    return ns.db.profile[ns.data.currentPlayerServer].showTooltips[key] or false
end

--[[---------------------------------------------------------------------------
    Function:   SetTooltipOption
    Purpose:    Toggle the option for showing toy tooltips in the main config.
    Arguments:  scrollKey - unique key for the object which can show tooltips
-----------------------------------------------------------------------------]]
function ns.toyScroll:SetTooltipOption(key)
    local previousValue = ns.db.profile[ns.data.currentPlayerServer].showTooltips[key]
    ns.db.profile[ns.data.currentPlayerServer].showTooltips[key] = not previousValue
end

--[[---------------------------------------------------------------------------
    Function:   GetToyEffectsOption
    Purpose:    Return the user's setting for showing toy effects.
    Arguments:  scrollKey - unique key for the object which can show tooltips
-----------------------------------------------------------------------------]]
function ns.toyScroll:GetToyEffectsOption(key)
    local value = ns.db.profile[ns.data.currentPlayerServer].showToyEffects[key] or false
    return value
end

--[[---------------------------------------------------------------------------
    Function:   SetToyEffectsOption
    Purpose:    Return the user's setting for showing toy effects.
    Arguments:  scrollKey - unique key for the object which can show tooltips
-----------------------------------------------------------------------------]]
function ns.toyScroll:SetToyEffectsOption(key)
    local previousValue = ns.db.profile[ns.data.currentPlayerServer].showToyEffects[key]
    ns.db.profile[ns.data.currentPlayerServer].showToyEffects[key] = not previousValue
end

--[[---------------------------------------------------------------------------
    Function:   PopulateToysByTag
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
function ns.toyScroll:PopulateToysByTag(scrollKey)
    -- current selected tag
    local selectedTag = GetFilterTag(scrollKey) or "none"

    -- create data provided for scrollbox
    if ns.toyScroll.dp[scrollKey] == nil then
        -- instantiate the date provider
        local dp = CreateDataProvider()
        ns.toyScroll.dp[scrollKey] = dp

        -- pass refreshed data into scroll box
        ns.toyScroll.scrollbox[scrollKey]:SetDataProvider(ns.toyScroll.dp[scrollKey])
    end

    -- loop over toys by tag if a selected tag is returned
    if selectedTag ~= "none" then
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
                        scrollKey = scrollKey
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
            local sortOrder = GetSortOrder(scrollKey) or "az"
            if sortOrder == "za" then
                table.sort(toyRows, function(a, b) return a.name > b.name end)
            else
                table.sort(toyRows, function(a, b) return a.name < b.name end)
            end

            -- reset data provider
            ns.toyScroll.dp[scrollKey]:Flush()

            -- insert sorted rows into the data provider
            for _, row in ipairs(toyRows) do
                ns.toyScroll.dp[scrollKey]:Insert(row)
            end
        end

        --@debug@
        -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
        --@end-debug@
    end
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
    if ns.toyScroll.checkboxEnabled[data.scrollKey] == true then
        if frame.checkbox == nil then
            frame.checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
            frame.checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
            frame.checkbox:SetText("")
            frame.checkbox:SetScript("OnClick", function(selfObject)
                ns.toyScroll.selectedItems[data.scrollKey][data.itemId] = selfObject:GetChecked()
            end)
        end
        frame.checkbox:SetChecked(ns.toyScroll.selectedItems[data.scrollKey][data.itemId] or false)
    end

    -- icon on left
    if frame.icon == nil then
        frame.icon = frame:CreateTexture(nil, "OVERLAY")
        frame.icon:SetSize(32, 32)
        if frame.checkbox == nil then
            frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
        else
            frame.icon:SetPoint("LEFT", frame.checkbox, "RIGHT", padding, 0)
        end
    end
    frame.icon:SetTexture(data.icon or "Interface\\Icons\\inv_misc_questionmark")

    -- toy name on top right of icon
    if frame.toyName == nil then
        frame.toyName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.toyName:SetJustifyH("LEFT")
        frame.toyName:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", padding, 0)
    end
    frame.toyName:SetText(data.name or "Unknown Toy")
    local newHeight = frame.toyName:GetStringHeight() + (padding * 2)

    -- usage below name
    if ns.toyScroll:GetToyEffectsOption(data.scrollKey) == true then
        if frame.toyUsage == nil then
            frame.toyUsage = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            frame.toyUsage:SetJustifyH("LEFT")
            frame.toyUsage:SetWordWrap(true)
        end
        if data.effect == nil then
            frame.toyUsage:ClearAllPoints()
        else
            frame.toyUsage:Show()
            frame.toyUsage:SetPoint("TOPLEFT", frame.toyName, "BOTTOMLEFT", 0, -5)
            frame.toyUsage:SetPoint("RIGHT", frame, "RIGHT", -padding, 0)
            frame.toyUsage:SetText(data.effect or ns.L["No usage information available."])
        end
        newHeight = newHeight + frame.toyUsage:GetStringHeight() + 5
    else
        if frame.toyUsage ~= nil then
            frame.toyUsage:Hide()
            frame.toyUsage:ClearAllPoints()
        end
    end

    -- set height of frame based on content; if no usage then just use name height + padding
    -- local currentHeight = frame:GetHeight()
    local iconHeight = frame.icon:GetHeight() + (padding * 2)
    newHeight = math.max(newHeight, iconHeight)
    frame:SetHeight(newHeight)

    -- store the height for scrolling since frames are hidden or show based on scrolling through the list
    ns.toyScroll.rowHeight[data.scrollKey][data.itemId] = newHeight

    -- add tooltip functionality
    frame:SetScript("OnEnter", function(self)
        local showTooltips = ns.toyScroll:GetTooltipOption(data.scrollKey)
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
local function CreateToyScrollList(scrollKey, parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- make sure row heights is populated for this scroll list
    if ns.toyScroll.rowHeight[scrollKey] == nil then
        ns.toyScroll.rowHeight[scrollKey] = {}
    end

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, parentFrame, "WowScrollBoxList")
    scrollBox:SetPoint("TOP", ns.toyScroll.dropdown[scrollKey], "BOTTOM", 0, -padding)
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
        local height = ns.toyScroll.rowHeight[data.scrollKey][data.itemId]
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

    -- return scrollBox
    ns.toyScroll.scrollbox[scrollKey] = scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   UpdateDropdowns
    Purpose:    Update the dropdown with the current tags.
-----------------------------------------------------------------------------]]
function ns.toyScroll:UpdateFilter(scrollKey)
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
    local selectedItem = GetFilterTag(scrollKey) or ns.data.constants.defaults.tagFilter
    ns.toyScroll.dropdown[scrollKey]:UpdateItems(itemOrder, items, selectedItem)

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
    Function:   CreateFilterDropdown
    Purpose:    Create a drop down with a listing of tags. User picks one to only show the toys associated to the tag in a scrollbox.
    Arguments:  scrollKey - unique identifier for the instantion of this list as it can be used more than once since we use this same setup in multiple places
                parentFrame - used to position the drop down
-----------------------------------------------------------------------------]]
local function CreateFilterDropdown(scrollKey, parentFrame)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- label for dropdown
    local dropdownLabel = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(ns.L["Tag:"])

    -- initialize drop down items with "none" option
    local items = {["none"] = ns.L["No Tags"]}

    -- set initial tag order
    local itemOrder = {"none"}

    -- create dropdown
    dropdown = ns:CreateDropdown(parentFrame, itemOrder, items, GetFilterTag(scrollKey), nil, function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            SetFilterTag(scrollKey, key)
            if ns.toyScroll.scrollbox[scrollKey] ~= nil then
                ns.toyScroll:PopulateToysByTag(scrollKey)
            end
        end
    end)
    dropdown:SetID(ns.toyScroll.dropdownId[scrollKey])
    dropdown:SetWidth(200)

    -- position the label and the dropdown
    local dropdownOffset = (dropdown:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    dropdownLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -dropdownOffset)
    dropdown:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)

    -- store the value long term
    ns.toyScroll.dropdown[scrollKey] = dropdown
end

--[[---------------------------------------------------------------------------
    Function:   CreateToyListing
    Purpose:    Create the content frame to show a listing of toys filtered by a tag drop down.
    Arguments:  scrollKey - unique identifier for the instantion of this list as it can be used more than once since we use this same setup in multiple places
                parentFrame - used to position the drop down
                checkboxEnabled - whether the checkbox in each row should be visible or not
-----------------------------------------------------------------------------]]
function ns.toyScroll:CreateToyListing(scrollKey, parentFrame, checkboxEnabled)
    --@debug@
    ns:Print(("Scroll Key: %s"):format(scrollKey))
    --@end-debug@

    -- create dropdown id
    ns.toyScroll.dropdownCounter = ns.toyScroll.dropdownCounter + 1
    ns.toyScroll.dropdownId[scrollKey] = ns.toyScroll.dropdownCounter

    -- instantiate select item table
    ns.toyScroll.selectedItems[scrollKey] = {}

    -- instantiate the checkbox enabled value
    ns.toyScroll.checkboxEnabled[scrollKey] = checkboxEnabled

    -- add tag dropdown filter
    CreateFilterDropdown(scrollKey, parentFrame)

    -- load the drop down
    ns.toyScroll:UpdateFilter(scrollKey)

    -- create scroll box of toys
    CreateToyScrollList(scrollKey, parentFrame)

    -- populate the list
    ns.toyScroll:PopulateToysByTag(scrollKey)
end