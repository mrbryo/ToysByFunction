--[[ ------------------------------------------------------------------------
	Title: 			Gets.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-05
	Description: 	All getter functions for the addon.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.sets = {}

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServerSpec
    Purpose:    Get a formatted value with player, server and current spec names.
-----------------------------------------------------------------------------]]
function ns.sets:SetKeyPlayerServerSpec()
    -- verify variable is setup
    if ns.data.currentPlayerServerSpec == nil then
        ns.data.currentPlayerServerSpec = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- get characters current spec number
    local specializationIndex = C_SpecializationInfo.GetSpecialization()
    
    --@debug@
    -- print("Current spec index: " .. tostring(specializationIndex))
    --@end-debug@

    -- get the name of the current spec number
    local specId, specName, description, icon, role, primaryStat, pointsSpent, background, previewPointsSpent, isUnlocked = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)

    --@debug@
    -- print("Current spec name: " .. tostring(specName))
    --@end-debug@

    -- finally return the special key
    if not specName then
        ns.data.currentPlayerServerSpec = ns.L["Unknown"]
    else
        ns.data.currentPlayerServerSpec = ("%s-%s-%s"):format(unitName, unitServer, specName) or nil
        ns.data.currentPlayerServerSpecNoHyphens = ("%s%s%s"):format(unitName, unitServer, specName) or nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServer
    Purpose:    Get a formatted value with player and server name.
-----------------------------------------------------------------------------]]
function ns.sets:SetKeyPlayerServer()
    -- verify variable's are setup
    if ns.data.currentPlayerServer == nil then
        ns.data.currentPlayerServer = ""
    end
    if ns.data.currentPlayerServerWithSpace == nil then
        ns.data.currentPlayerServerWithSpace = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- set values
    ns.data.currentPlayerServer = ("%s-%s"):format(unitName, unitServer)
    ns.data.currentPlayerServerWithSpace = ("%s - %s"):format(unitName, unitServer)
end

--[[---------------------------------------------------------------------------
    Function:   SetFilterTag
    Purpose:    Set the currently selected tag for filtering toys.
-----------------------------------------------------------------------------]]
function ns.sets:SetFilterTag(tagKey)
    ns.db.profile[ns.data.currentPlayerServer].selectedTag = tagKey
end

--[[---------------------------------------------------------------------------
    Function:   SetToySortingOrderMainConfig
    Purpose:    Set the current toy sorting order for the main config.
-----------------------------------------------------------------------------]]
function ns.sets:SetToySortingOrderMainConfig(orderKey)
    ns.db.profile[ns.data.currentPlayerServer].toySortingOrder.main = orderKey
end

--[[---------------------------------------------------------------------------
    Function:   SetOptionShowToyTooltips
    Purpose:    Toggle the option for showing toy tooltips in the main config.
-----------------------------------------------------------------------------]]
function ns.sets:SetOptionShowToyTooltips()
    local previousValue = ns.db.profile[ns.data.currentPlayerServer].showTooltips.main
    ns.db.profile[ns.data.currentPlayerServer].showTooltips.main = not previousValue
    --@debug@
    -- ns:Print(("(SetOptionShowToyTooltips) Show Toy Tooltips option set to: %s; previous value: %s"):format(tostring(ns.db.profile[ns.data.currentPlayerServer].showTooltips.main), tostring(previousValue)))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   SetOptionPreventTagDelete
    Purpose:    Toggle the option for preventing tag deletion if toys are assigned.
-----------------------------------------------------------------------------]]
function ns.sets:SetOptionPreventTagDelete()
    local previousValue = ns.db.profile[ns.data.currentPlayerServer].preventTagDelete
    ns.db.profile[ns.data.currentPlayerServer].preventTagDelete = not previousValue
    --@debug@
    -- ns:Print(("(SetOptionPreventTagDelete) Prevent Tag Deletion option set to: %s; previous value: %s"):format(tostring(ns.db.profile[ns.data.currentPlayerServer].preventTagDelete), tostring(previousValue)))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   SetFramePosition
    Purpose:    Store the position of a frame in the profile database.
    Parameters: frameName - the name of the frame
                point - the point on the frame being set (e.g., "TOPLEFT")
                relativePoint - the point on the relative frame (e.g., "BOTTOMRIGHT")
                xOfs - the x offset from the relative point
                yOfs - the y offset from the relative point
-----------------------------------------------------------------------------]]
function ns.sets:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)
    -- create empty table for frame if it doesn't exist
    if ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName] == nil then
        ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName] = {}
    end

    -- Store position data
    ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName].point = point
    ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName].relativePoint = relativePoint
    ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName].xOffset = xOfs
    ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName].yOffset = yOfs

    -- return true since storage was successful
    return true
end

function ns.sets:SetTagCheckedForMaint(id)
    ns.db.profile[ns.data.currentPlayerServer].selectedTagForEdit = id
end