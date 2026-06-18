--[[---------------------------------------------------------------------------
    Function:   GetDevMode
    Purpose:    Get the developer mode for the current character.
-----------------------------------------------------------------------------]]
function ToysByFunction:GetDevMode()
    local defaultValue = false
    defaultValue = false
    --@debug@
    -- for development purposes, uncomment next line to always enable dev mode
    -- defaultValue = true
    --@end-debug@

    -- get player unique key; if not already set
    if not self.currentPlayerServerSpec and self.currentPlayerServerSpec ~= self.L["Unknown"] then
        return defaultValue
    end

    -- check dev mode exists, if not set it to false
    if not ToysByFunctionDB.char then
        ToysByFunctionDB.char = {}
    end
    if not ToysByFunctionDB.char[self.currentPlayerServerSpec] then
        ToysByFunctionDB.char[self.currentPlayerServerSpec] = {}
    end
    if not ToysByFunctionDB.char[self.currentPlayerServerSpec].isDevMode then
        ToysByFunctionDB.char[self.currentPlayerServerSpec].isDevMode = false
    end

    --@debug@
    -- ToysByFunctionDB.char[self.currentPlayerServerSpec].isDevMode = defaultValue
    --@end-debug@

    -- finally return the dev mode value
    return ToysByFunctionDB.char[self.currentPlayerServerSpec].isDevMode
end

--[[---------------------------------------------------------------------------
    Function:   GetMinimapButtonVisible
    Purpose:    Get whether the minimap button should be visible (defaults to true).
-----------------------------------------------------------------------------]]
function ToysByFunction:GetMinimapButtonVisible()
    if not ToysByFunctionDB or not ToysByFunctionDB.global then
        return true -- default to showing the button
    end
    
    if ToysByFunctionDB.global.minimap and ToysByFunctionDB.global.minimap.hide ~= nil then
        return not ToysByFunctionDB.global.minimap.hide -- LibDBIcon uses 'hide' property, we want 'show'
    end
    
    return true -- default to showing the button
end

--[[---------------------------------------------------------------------------
    Function:   GetFramePosition
    Purpose:    Retrieve the position of a frame from the profile database.
    Parameters: frameName - the name of the frame
-----------------------------------------------------------------------------]]
function ToysByFunction:GetFramePosition(frameName)
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- retrieve position data
        return ToysByFunctionDB.profile[self.currentPlayerServer].ui.positions[frameName] or self.L["Unknown"]
    else
        return self.L["Unknown"]
    end
end

--[[---------------------------------------------------------------------------
    Function:   GetObjectName
    Purpose:    Create frame object name with addon prefix.
-----------------------------------------------------------------------------]]
function ToysByFunction:GetObjectName(postfix)
    if not postfix then postfix = "UnknownObjectName" end
    return ("%s%s"):format(ToysByFunction.prefix, postfix)
end

--[[---------------------------------------------------------------------------
    Function:   GetSelectedTag
    Purpose:    Get the currently selected tag for filtering toys.
-----------------------------------------------------------------------------]]
function ToysByFunction:GetSelectedTag()
    -- make sure the current player key is set
    if not self.currentPlayerServer then return false end

    -- ensure profile DB structure exists
    local isSet = self:SetupProfileDB()
    
    if isSet == true then
        -- retrieve position data
        return ToysByFunctionDB.profile[self.currentPlayerServer].selectedTag or "none"
    else
        return "none"
    end
end

--[[---------------------------------------------------------------------------
    Function:   HasCustomTags
    Purpose:    Check if the user has any custom tags.
-----------------------------------------------------------------------------]]
-- function ToysByFunction:HasCustomTags()
--     local count = 0
--     for _ in pairs(ToysByFunctionDB.profile[self.currentPlayerServer].tags.custom) do
--         count = count + 1
--         break -- we only need to know if at least one entry exists
--     end
--     return count > 0
-- end

--[[---------------------------------------------------------------------------
    Function:   HasCustomTagOrder
    Purpose:    Check if the user has a custom tag order defined.
-----------------------------------------------------------------------------]]
-- function ToysByFunction:HasCustomTagOrder()
--     local count = 0
--     for _ in pairs(ToysByFunctionDB.profile[self.currentPlayerServer].tags.order) do
--         count = count + 1
--         break -- we only need to know if at least one entry exists
--     end
--     return count > 0
-- end