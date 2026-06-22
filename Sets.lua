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
    if not ns.data.currentPlayerServerSpec then
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
    if not ns.data.currentPlayerServer then
        ns.data.currentPlayerServer = ""
    end
    if not ns.data.currentPlayerServerWithSpace then
        ns.data.currentPlayerServerWithSpace = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- set values
    ns.data.currentPlayerServer = ("%s-%s"):format(unitName, unitServer)
    ns.data.currentPlayerServerWithSpace = ("%s - %s"):format(unitName, unitServer)
end

--[[---------------------------------------------------------------------------
    Function:   SetupGlobalDB
    Purpose:    Setup the global DB with default values if they don't already exist.
-----------------------------------------------------------------------------]]
function ns.sets:SetupGlobalDB()
    -- create whole DB if missing
    if not ToysByFunctionDB then ToysByFunctionDB = {} end

    -- actionBars holds just a sorted array of action bar names; needed under global and profile
    if not ToysByFunctionDB.global then
        ToysByFunctionDB.global = {}
    end

    -- create toys data structure
    if not ns.db.global.toys then
        ns.db.global.toys = {}
    end
    if not ns.db.global.toys.byItemId then
        ns.db.global.toys.byItemId = {}
    end
    if not ns.db.global.toys.byTag then
        ns.db.global.toys.byTag = {}
    end
    if not ns.db.global.toys.order then
        ns.db.global.toys.order = {}
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetMinimapButtonVisible
    Purpose:    Set whether the minimap button should be visible.
-----------------------------------------------------------------------------]]
function ns.sets:SetMinimapButtonVisible(visible)
    if not ToysByFunctionDB or not ToysByFunctionDB.global then
        return
    end
    
    -- Initialize minimap settings if they don't exist
    if not ToysByFunctionDB.global.minimap then
        ToysByFunctionDB.global.minimap = {}
    end
    
    -- LibDBIcon uses 'hide' property, so we invert our 'visible' boolean
    ToysByFunctionDB.global.minimap.hide = not visible
end

--[[---------------------------------------------------------------------------
    Function:   SetupProfileDB
    Purpose:    Ensure the profile specific database structure is setup.
-----------------------------------------------------------------------------]]
function ns.sets:SetupProfileDB()
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return false end

    -- create whole DB if missing
    if not ToysByFunctionDB then ToysByFunctionDB = {} end

    -- create profile node if missing
    if not ToysByFunctionDB.profile then ToysByFunctionDB.profile = {} end

    -- add current character if missing
    if not ToysByFunctionDB.profile[ns.data.currentPlayerServer] then
        ToysByFunctionDB.profile[ns.data.currentPlayerServer] = {}
    end

    -- initialize UI settings if they don't exist
    if not ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui then
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui = {}
    end
    if not ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions then
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions = {}
    end

    -- selected tag default
    if not ToysByFunctionDB.profile[ns.data.currentPlayerServer].selectedTag then
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].selectedTag = "none"
    end

    -- return true if we get to here in the code
    return true
end

--[[---------------------------------------------------------------------------
    Function:   SetSelectedTag
    Purpose:    Set the currently selected tag for filtering toys.
-----------------------------------------------------------------------------]]
function ns.sets:SetSelectedTag(tagKey)
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        ns.db.profile[ns.data.currentPlayerServer].selectedTag = tagKey
    end
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
    -- make sure the current player key is set
    if not ns.data.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- create index for this frame
        if not ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName] then
            ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName] = {}
        end
        
        -- Store position data
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].point = point
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].relativePoint = relativePoint
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].xOffset = xOfs
        ToysByFunctionDB.profile[ns.data.currentPlayerServer].ui.positions[frameName].yOffset = yOfs

        -- return true since storage was successful
        return true
    end
end