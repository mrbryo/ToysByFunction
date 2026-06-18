--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServerSpec
    Purpose:    Get a formatted value with player, server and current spec names.
-----------------------------------------------------------------------------]]
function ToysByFunction:SetKeyPlayerServerSpec()
    -- verify variable is setup
    if not self.currentPlayerServerSpec then
        self.currentPlayerServerSpec = ""
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
        self.currentPlayerServerSpec = self.L["Unknown"]
    else
        self.currentPlayerServerSpec = ("%s-%s-%s"):format(unitName, unitServer, specName) or nil
        self.currentPlayerServerSpecNoHyphens = ("%s%s%s"):format(unitName, unitServer, specName) or nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetKeyPlayerServer
    Purpose:    Get a formatted value with player and server name.
-----------------------------------------------------------------------------]]
function ToysByFunction:SetKeyPlayerServer()
    -- verify variable's are setup
    if not self.currentPlayerServer then
        self.currentPlayerServer = ""
    end
    if not self.currentPlayerServerWithSpace then
        self.currentPlayerServerWithSpace = ""
    end

    -- get player and server name
    local unitName, unitServer = UnitFullName("player")

    -- set values
    self.currentPlayerServer = ("%s-%s"):format(unitName, unitServer)
    self.currentPlayerServerWithSpace = ("%s - %s"):format(unitName, unitServer)
end

--[[---------------------------------------------------------------------------
    Function:   SetupGlobalDB
    Purpose:    Setup the global DB with default values if they don't already exist.
-----------------------------------------------------------------------------]]
function ToysByFunction:SetupGlobalDB()
    -- create whole DB if missing
    if not ToysByFunctionDB then ToysByFunctionDB = {} end

    -- actionBars holds just a sorted array of action bar names; needed under global and profile
    if not ToysByFunctionDB.global then
        ToysByFunctionDB.global = {}
    end
end

--[[---------------------------------------------------------------------------
    Function:   SetMinimapButtonVisible
    Purpose:    Set whether the minimap button should be visible.
-----------------------------------------------------------------------------]]
function ToysByFunction:SetMinimapButtonVisible(visible)
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
function ToysByFunction:SetupProfileDB()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- create whole DB if missing
    if not ToysByFunctionDB then ToysByFunctionDB = {} end

    -- create profile node if missing
    if not ToysByFunctionDB.profile then ToysByFunctionDB.profile = {} end

    -- add current character if missing
    if not ToysByFunctionDB.profile[self.currentPlayerServer] then
        ToysByFunctionDB.profile[self.currentPlayerServer] = {}
    end

    -- initialize UI settings if they don't exist
    if not ToysByFunctionDB.profile[self.currentPlayerServer].ui then
        ToysByFunctionDB.profile[self.currentPlayerServer].ui = {}
    end
    if not ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions then
        ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions = {}
    end

    -- selected tag default
    if not ToysByFunctionDB.profile[self.currentPlayerServer].selectedTag then
        ToysByFunctionDB.profile[self.currentPlayerServer].selectedTag = "none"
    end

    -- return true if we get to here in the code
    return true
end

--[[---------------------------------------------------------------------------
    Function:   SetSelectedTag
    Purpose:    Set the currently selected tag for filtering toys.
-----------------------------------------------------------------------------]]
function ToysByFunction:SetSelectedTag(tagKey)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        ToysByFunctionDB.profile[self.currentPlayerServer].selectedTag = tagKey
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
function ToysByFunction:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- create index for this frame
        if not ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName] then
            ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName] = {}
        end
        
        -- Store position data
        ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName].point = point
        ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName].relativePoint = relativePoint
        ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName].xOffset = xOfs
        ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName].yOffset = yOfs

        -- return true since storage was successful
        return true
    end
end