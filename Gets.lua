--[[ ------------------------------------------------------------------------
	Title: 			Gets.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-05
	Description: 	All getter functions for the addon.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.gets = {}

--[[---------------------------------------------------------------------------
    Function:   GetDevMode
    Purpose:    Get the developer mode for the current character.
-----------------------------------------------------------------------------]]
function ns.gets:GetDevMode()
    local defaultValue = false
    defaultValue = false
    --@debug@
    -- for development purposes, uncomment next line to always enable dev mode
    -- defaultValue = true
    --@end-debug@

    -- get player unique key; if not already set
    if not ns.data.currentPlayerServerSpec and ns.data.currentPlayerServerSpec ~= self.L["Unknown"] then
        return defaultValue
    end

    -- check dev mode exists, if not set it to false
    if not ns.db.char then
        ns.db.char = {}
    end
    if not ns.db.char[ns.data.currentPlayerServerSpec] then
        ns.db.char[ns.data.currentPlayerServerSpec] = {}
    end
    if not ns.db.char[ns.data.currentPlayerServerSpec].isDevMode then
        ns.db.char[ns.data.currentPlayerServerSpec].isDevMode = false
    end

    --@debug@
    -- ToysByFunctionDB.char[ns.data.currentPlayerServerSpec].isDevMode = defaultValue
    --@end-debug@

    -- finally return the dev mode value
    return ns.db.char[ns.data.currentPlayerServerSpec].isDevMode
end

--[[---------------------------------------------------------------------------
    Function:   GetFramePosition
    Purpose:    Retrieve the position of a frame from the profile database.
    Parameters: frameName - the name of the frame
-----------------------------------------------------------------------------]]
function ns.gets:GetFramePosition(frameName)
    -- retrieve position data
    return ns.db.profile[ns.data.currentPlayerServer].ui.positions[frameName]
end

--[[---------------------------------------------------------------------------
    Function:   GetObjectName
    Purpose:    Create frame object name with addon prefix.
-----------------------------------------------------------------------------]]
function ns.gets:GetObjectName(postfix)
    if not postfix then postfix = "UnknownObjectName" end
    return ("%s%s"):format(ns.data.prefix, postfix)
end

--[[---------------------------------------------------------------------------
    Function:   GetSelectedTag
    Purpose:    Get the currently selected tag for filtering toys.
-----------------------------------------------------------------------------]]
function ns.gets:GetSelectedTag()
    -- retrieve selected tag
    return ns.db.profile[ns.data.currentPlayerServer].selectedTag or "none"
end

--[[---------------------------------------------------------------------------
    Function:   GetToySortingOrderMainConfig
    Purpose:    Get the current toy sorting order for the main config.
-----------------------------------------------------------------------------]]
function ns.gets:GetToySortingOrderMainConfig()
    -- retrieve toy sorting order
    return ns.db.profile[ns.data.currentPlayerServer].toySortingOrder.main
end

--[[---------------------------------------------------------------------------
    Function:   GetOptionShowToyTooltips
    Purpose:    Get the option for showing toy tooltips in the main config.
-----------------------------------------------------------------------------]]
function ns.gets:GetOptionShowToyTooltips()
    --@debug@
    -- ns:Print(("(GetOptionShowToyTooltips) Show Toy Tooltips option is: %s"):format(tostring(ns.db.profile[ns.data.currentPlayerServer].showTooltips.main)))
    --@end-debug@

    -- retrieve show toy tooltips option
    return ns.db.profile[ns.data.currentPlayerServer].showTooltips.main
end

--[[---------------------------------------------------------------------------
    Function:   GetOptionPreventTagDelete
    Purpose:    Get the option for preventing tag deletion if toys are assigned.
-----------------------------------------------------------------------------]]
function ns.gets:GetOptionPreventTagDelete()
    --@debug@
    -- ns:Print(("(GetOptionPreventTagDelete) Prevent Tag Deletion option is: %s"):format(tostring(ns.db.profile[ns.data.currentPlayerServer].preventTagDelete)))
    --@end-debug@

    -- retrieve prevent tag deletion option
    return ns.db.profile[ns.data.currentPlayerServer].preventTagDelete
end

--[[---------------------------------------------------------------------------
    Function:   HasCustomTags
    Purpose:    Check if the user has any custom tags.
-----------------------------------------------------------------------------]]
-- function ns.gets:HasCustomTags()
--     local count = 0
--     for _ in pairs(ns.db.profile[ns.data.currentPlayerServer].tags.custom) do
--         count = count + 1
--         break -- we only need to know if at least one entry exists
--     end
--     return count > 0
-- end

--[[---------------------------------------------------------------------------
    Function:   HasCustomTagOrder
    Purpose:    Check if the user has a custom tag order defined.
-----------------------------------------------------------------------------]]
-- function ns.gets:HasCustomTagOrder()
--     local count = 0
--     for _ in pairs(ns.db.profile[ns.data.currentPlayerServer].tags.order) do
--         count = count + 1
--         break -- we only need to know if at least one entry exists
--     end
--     return count > 0
-- end