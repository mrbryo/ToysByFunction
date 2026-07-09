--[[ ------------------------------------------------------------------------
	Title: 			Toys.lua
	Author: 		mrbryo
	Create Date : 	06/21/2026
	Description: 	All Toy Functions for WoW Addons.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

-- instantiate the Toy Functions table
ns.ToyFunctions = {}

--[[---------------------------------------------------------------------------
    Function:   ResetAPIFilters
    Purpose:    Reset all Toy API filters to their default state.
    Returns:    The number of toys after resetting the filters.
    Credit:     To ToyBoxEnhanced, I mean it's all blizzard calls but the function design is theirs and I did copy and paste from ToyBoxEnhanced addon.
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:ResetAPIFilters()
    C_ToyBox.SetAllSourceTypeFilters(true)
    C_ToyBox.SetAllExpansionTypeFilters(true)
    C_ToyBox.SetCollectedShown(true)
    C_ToyBox.SetUncollectedShown(true)
    C_ToyBox.SetUnusableShown(true)
    C_ToyBox.SetFilterString("")

    return C_ToyBox.GetNumFilteredToys()
end

--[[---------------------------------------------------------------------------
    Function:   LoadToySteps
    Purpose:    Load the toy data from the game and populate the addon's data structures.
    Note:       This function should be called on addon initialization and whenever the toy data needs to be refreshed (e.g. after learning a new toy).
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:LoadToySteps()
    -- need global index name for each popup
    ns.data.popups.resettoyfilters = addonName .. "ResetToyListFilters"

    -- notify user we are going to reset toy filters
    StaticPopupDialogs[ns.data.popups.resettoyfilters] = {
        text = ns.L["By default, best to reset the Toy Catelog filters. OK to proceed?"],
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
        end
    }

    -- show the popup
    StaticPopup_Show(ns.data.popups.resettoyfilters)
end

--[[---------------------------------------------------------------------------
    Function:   NewToyEvent
    Purpose:    Handle the event when a new toy is learned.
    Note:       This function should be registered to the appropriate event (e.g. "TOY_LEARNED") to automatically update the toy list when a new toy is acquired.
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:NewToyEvent()
    ns:Print("Not Implemented Yet")
end

local function GetToyInfoFromTooltip(itemData)
    local returnMe = {}

    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToyName", tostring(Enum.TooltipDataLineType.ToyName)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToyText", tostring(Enum.TooltipDataLineType.ToyText)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToyEffect", tostring(Enum.TooltipDataLineType.ToyEffect)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToyDuration", tostring(Enum.TooltipDataLineType.ToyDuration)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToyDescription", tostring(Enum.TooltipDataLineType.ToyDescription)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("ToySource", tostring(Enum.TooltipDataLineType.ToySource)))
    -- ns:Print(("Tooltip Type: %s, Value: %s"):format("UsageRequirement", tostring(Enum.TooltipDataLineType.UsageRequirement)))

    -- loop over the tooltip lines to find the description
    for _, line in ipairs(itemData.lines) do
        if line.type == Enum.TooltipDataLineType.ItemBinding then
            returnMe["binding"] = line.leftText
        
        -- name not needed since we have capture it from a previous call and stored in db; setting to nil so it is removed from the db
        elseif line.type == Enum.TooltipDataLineType.ToyName then
            -- returnMe["name"] = line.leftText
            returnMe["name"] = nil
        elseif line.type == Enum.TooltipDataLineType.ToyText then
            returnMe["text"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.ToyEffect then
            returnMe["effect"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.ToyDuration then
            returnMe["duration"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.ToyDescription then
            returnMe["description"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.ToySource then
            returnMe["source"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.FlavorText then
            returnMe["flavor"] = line.leftText
        elseif line.type == Enum.TooltipDataLineType.UsageRequirement then
            returnMe["usage"] = line.leftText
        end
    end

    return returnMe
end

--[[---------------------------------------------------------------------------
    Function:   LoadToyList
    Purpose:    Load the list of toys based on the selected tag and display them in the left frame.
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:LoadToyList(toyCount)
    -- ns.db.global.toys.byItemId = {}

    -- using the count of filtered toys, starting at 1, loop over this range to get the item id to get the toy item details
    for toyIndex = 1, toyCount do
        -- get the itemId
        local toyItemId = C_ToyBox.GetToyFromIndex(toyIndex)

        -- fetch data from blizzard api
        local itemId, toyName, icon, isFavorite, hasFanfare, itemQuality = C_ToyBox.GetToyInfo(toyItemId)

        -- backup of current toy data
        local currentToyData = {}
        if ns.db.global.toys.byItemId[toyItemId] then
            currentToyData = ns.db.global.toys.byItemId[toyItemId] or {}
        end

        -- get tags from tags db file
        local defaultTags = {}
        if ns.data.TagsByItem[toyItemId] then
            defaultTags = ns.data.TagsByItem[toyItemId] or {}
        end

        -- can player use toy?
        local canUseToy = C_ToyBox.IsToyUsable(toyItemId)

        -- get tooltip data
        local tooltipData = C_TooltipInfo.GetToyByItemID(toyItemId)
        local toyTooltipInfo = GetToyInfoFromTooltip(tooltipData)

        -- instantiate local toy data table
        local toyInfo = {
            toyIndex = toyIndex,
            toyItemId = toyItemId,
            itemId = itemId or currentToyData.itemId or ns.L["Unknown"],
            name = toyName or currentToyData.name or ns.L["Unknown"],
            icon = icon or currentToyData.icon or ns.L["Unknown"],
            isFavorite = isFavorite or currentToyData.isFavorite or false,
            hasFanfare = hasFanfare or currentToyData.hasFanfare or false,
            itemQuality = itemQuality or currentToyData.itemQuality or ns.L["Unknown"],
            canUse = canUseToy or currentToyData.canUse or false,
            status = ns.L["Found"],
            tags = currentToyData.tags or defaultTags,
            tooltip = toyTooltipInfo,
        }

        -- update status if no data returned from API
        if currentToyData ~= nil and toyName == nil then
            toyInfo.status = ns.L["No data returned; previous data retained."]
        elseif toyName == nil then
            toyInfo.status = ns.L["No data returned; previous data not available."]
        end

        -- insert into table
        ns.db.global.toys.byItemId[tostring(toyItemId)] = toyInfo
    end
end

--[[---------------------------------------------------------------------------
    Function:   LoadTagList
    Purpose:    Load the list of tags from the ToyDB and ensure they are represented in the profile database with default values.
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:LoadTagList()
    if ns.data.DefaultTags then
        -- loop over those tags
        for idx, id in pairs(ns.data.DefaultTags) do
            -- check if the tag exists, if not add it
            if ns.db.global.tags.order[id] == nil then
                -- if not, copy it in from the source of record; order is determined by the index of the tag; always add as enabled by default
                ns.db.global.tags.order[id] = {
                    order = idx,
                    enabled = true,
                }
            end
        end

        --@debug@
        -- for tagID, tagdata in pairs(ns.db.global.tags.order) do
        --     ns:Print(("Tag in DB: %s with order %d and enabled state %s"):format(tagID, tostring(tagdata.order), tostring(tagdata.enabled)))
        -- end
        --@end-debug@
    else
        ns:Print(ns.L["Tags Missing from Toy DB; unable to process default tags. Please open a ticket."])
    end
end

--[[---------------------------------------------------------------------------
    Function:   UpdateToyIndexes
    Purpose:    Rebuild the reverse lookup indexes for toys by item ID and by tag.
    Returns:    None
-----------------------------------------------------------------------------]]
function ns.ToyFunctions:UpdateToyIndexes()
    --@debug@
    ns.db.global.toys.byTag = ns.data.ItemsByTag or {}
    --@end-debug@

    -- rebuild indexes
    -- for tagId, items in pairs(ns.data.byTag) do
    --     ns.db.global.toys.byItemId[data.itemId] = data.tags
    --     for _, tag in ipairs(data.tags) do
    --         if not ns.db.global.toys.byTag[tag] then
    --             ns.db.global.toys.byTag[tag] = {}
    --         end
    --         table.insert(ns.db.global.toys.byTag[tag], data.itemId)
    --     end
    -- end
end