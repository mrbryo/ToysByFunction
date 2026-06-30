--[[ ------------------------------------------------------------------------
	Title: 			Main.lua
	Author: 		mrbryo
	Create Date : 	06/13/2025 21:24
	Description: 	Main program for Toys by Function addon.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

--[[---------------------------------------------------------------------------
    Function:   AfterCombat
    Purpose:    Safely execute a WoW API call after combat ends.
    Arguments:  func - Function to call
-----------------------------------------------------------------------------]]
ns.combatQueue = {}
function ns.AfterCombat(fn)
    if InCombatLockdown() then
        ns.combatQueue[#ns.combatQueue + 1] = fn
    else
        fn()
    end
end

--[[---------------------------------------------------------------------------
    Event:      PLAYER_REGEN_ENABLED
    Purpose:    Trigger queued functions after combat ends.
    Arguments:  func - Function to call
-----------------------------------------------------------------------------]]
ns.RegisterEvent("PLAYER_REGEN_ENABLED", function()
    for _, fn in ipairs(ns.combatQueue) do fn() end
    wipe(ns.combatQueue)
end)

-- Build frames, register gameplay events, start timers.
function ns:Enable()
    
    -- Create minimap button using LibDBIcon
    ns:CreateMinimapButton()
end

-- Tear down / hide what Enable created.
function ns:Disable()
    -- Unregister events by removing the event frame
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnEvent", nil)
    end

    if self.gets:GetDevMode() == true then
        self:Print(self.L["Disabled"])
    end

    -- same clean up should occur when disabled
    self:EventPlayerLogout()
end

--[[---------------------------------------------------------------------------
    Function:   FormatDateString
    Purpose:    Convert a date string from YYYYMMDDHHMISS or YYYY-MM-DD HH:MI:SS format to YYYY, Mon DD HH:MI:SS format.
-----------------------------------------------------------------------------]]
function ns:FormatDateString(dateString)    
    -- validate input
    if dateString == self.L["Never"] then
        return self.L["Never"]
    elseif not dateString or type(dateString) ~= "string" then
        return self.L["Invalid Date"]
    end
    
    local year, month, day, hour, minute, second
    
    -- Check for YYYY-MM-DD HH:MI:SS format (19 characters with spaces and dashes)
    if string.len(dateString) == 19 and string.match(dateString, "^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$") then
        -- Extract components from YYYY-MM-DD HH:MI:SS
        year = string.sub(dateString, 1, 4)
        month = tonumber(string.sub(dateString, 6, 7))
        day = string.sub(dateString, 9, 10)
        hour = string.sub(dateString, 12, 13)
        minute = string.sub(dateString, 15, 16)
        second = string.sub(dateString, 18, 19)
        
    -- Check for YYYYMMDDHHMISS format (14 characters, all digits)
    elseif string.len(dateString) == 14 and string.match(dateString, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
        -- Extract components from YYYYMMDDHHMISS
        year = string.sub(dateString, 1, 4)
        month = tonumber(string.sub(dateString, 5, 6))
        day = string.sub(dateString, 7, 8)
        hour = string.sub(dateString, 9, 10)
        minute = string.sub(dateString, 11, 12)
        second = string.sub(dateString, 13, 14)
        
    else
        return self.L["Invalid Date"]
    end
    
    -- month names
    local monthNames = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    }
    
    -- validate month
    if month < 1 or month > 12 then
        return self.L["Invalid Date"]
    end
    
    -- format and return the readable date string
    return string.format("%s, %s %s %s:%s:%s", year, monthNames[month], day, hour, minute, second)
end

--[[---------------------------------------------------------------------------
    Function:   RemoveFrameChildren
    Purpose:    Remove all children from a frame.
-----------------------------------------------------------------------------]]
function ns:RemoveFrameChildren(parent)
    -- if no scroll region, nothing to do
    if not parent then return end

    -- loop over children and remove them
    for i, child in ipairs({ parent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
        child = nil
    end

    -- remove all font strings and textures (regions)
    for _, region in ipairs({ parent:GetRegions() }) do
        region:Hide()
        region:SetParent(nil)
        region = nil
    end
end

--[[---------------------------------------------------------------------------
    Function:   SafeWoWAPICall
    Purpose:    Safely execute a WoW API call with error handling.
    Arguments:  func - Function to call
                ... - Arguments to pass to the function
    Returns:    Table with success status, result, and error message
-----------------------------------------------------------------------------]]
function ns:SafeWoWAPICall(func, ...)
    -- set language variable
    local L = self.L
    
    local success, result = pcall(func, ...)
    
    if success then
        return {
            success = true,
            result = result,
            error = nil
        }
    else
        --@debug@
        if self.gets:GetDevMode() == true then
            self:Print((self.L["API Error: %s"]):format(tostring(result)))
        end
        --@end-debug@
        
        return {
            success = false,
            result = nil,
            error = result or L["Unknown"]
        }
    end
end

--[[---------------------------------------------------------------------------
    Function:   EnableDevelopment
    Purpose:    Enable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ns:EnableDevelopment()
    -- enable development mode
    self:SetDevMode(true)

    -- enable button
    self:SetDeveloperTabVisibleState(true)

    -- give user status
    self:Print(self.L["Development Mode: Enabled"])
end

--[[---------------------------------------------------------------------------
    Function:   DisableDevelopment
    Purpose:    Disable development mode for testing and debugging.
-----------------------------------------------------------------------------]]
function ns:DisableDevelopment()
    if self.gets:GetTab() == "developer" then
        -- switch to default tab if the user is on the developer tab
        self:SetTab("introduction")
    end

    -- disable development mode
    self:SetDevMode(false)

    -- enable button
    self:SetDeveloperTabVisibleState(false)

    -- give user status
    self:Print(self.L["Development Mode: Disabled"])
end

--[[---------------------------------------------------------------------------
    Function:   StoreFramePosition
    Purpose:    Store the current frame position in the character database.
    Arguments:  frame - the frame whose position to store
-----------------------------------------------------------------------------]]
function ns:StoreFramePosition(frame)
    -- Get current position
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    -- get frame name
    local frameName = frame:GetName()
    if not frameName then
        if self.gets:GetDevMode() == true then
            self:Print(self.L["Error: Frame has no name, cannot store position."])
        end
        return
    end

    -- store position data in the character database
    local isSuccess = ns.sets:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)

    --@debug@
    -- if self.gets:GetDevMode() == true then
    --     self:Print(("Frame position stored: %s %s %.1f %.1f"):format(point, relativePoint, xOfs, yOfs))
    -- end
    --@end-debug@

    return isSuccess
end

--[[---------------------------------------------------------------------------
    Function:   RestoreFramePosition
    Purpose:    Restore the frame position from stored data or center if bounds are invalid.
    Arguments:  frame - the frame to position
                frameWidth - width of the frame
                frameHeight - height of the frame
-----------------------------------------------------------------------------]]
function ns:RestoreFramePosition(frame, frameWidth, frameHeight)
    -- get frame name
    local frameName = frame:GetName()
    
    -- get stored position data
    local storedPosition = ns.gets:GetFramePosition(frameName)
    ns:Print(("Stored Position for %s: %s"):format(frameName, storedPosition and ("point=%s, relativePoint=%s, xOffset=%.1f, yOffset=%.1f"):format(storedPosition.point, storedPosition.relativePoint, storedPosition.xOffset, storedPosition.yOffset) or "nil"))
    if storedPosition == nil then
        --@debug@
        if ns.gets:GetDevMode() == true then
            ns:Print((ns.L["No stored position data found for frame: %s"]):format(frameName))
        end
        --@end-debug@
    end
    
    -- default to center position
    local point = "CENTER"
    local relativePoint = "CENTER"
    local xOffset = 0
    local yOffset = 0
    
    -- if we have stored position data, validate it's within bounds
    if storedPosition and storedPosition.point and storedPosition.xOffset and storedPosition.yOffset then
        local testX = storedPosition.xOffset
        local testY = storedPosition.yOffset
        
        -- get UIParent dimensions for bounds checking
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        -- calculate frame boundaries
        local halfWidth = frameWidth / 2
        local halfHeight = frameHeight / 2
        
        -- check if frame would be completely within UIParent bounds
        local withinBounds = true
        
        -- for CENTER positioning, check if frame stays within screen
        if storedPosition.point == "CENTER" then
            if (testX - halfWidth < -screenWidth/2) or (testX + halfWidth > screenWidth/2) or
               (testY - halfHeight < -screenHeight/2) or (testY + halfHeight > screenHeight/2) then
                withinBounds = false
            end

        -- for other anchor points, do more specific bounds checking
        elseif storedPosition.point == "TOPLEFT" then
            if testX < 0 or testY > 0 or 
               (testX + frameWidth > screenWidth) or (testY - frameHeight < -screenHeight) then
                withinBounds = false
            end
        elseif storedPosition.point == "BOTTOMRIGHT" then
            if testX > 0 or testY < 0 or
               (testX - frameWidth < -screenWidth) or (testY + frameHeight > screenHeight) then
                withinBounds = false
            end
        end
        
        -- use stored position if within bounds
        if withinBounds == true then
            point = storedPosition.point
            relativePoint = storedPosition.relativePoint
            xOffset = testX
            yOffset = testY
            
            --@debug@
            -- if ns.gets:GetDevMode() == true then
            --     ns:Print(("Frame positioned from stored data: %s %.1f %.1f."):format(point, xOffset, yOffset))
            -- end
            --@end-debug@
        else
            --@debug@
            -- if ns.gets:GetDevMode() == true then
            --     ns:Print("Stored frame position is outside bounds, centering frame.")
            -- end
            --@end-debug@
        end
    else
        --@debug@
        -- if ns.gets:GetDevMode() == true then
        --     ns:Print("No stored frame position found, centering frame.")
        -- end
        --@end-debug@
    end
    
    -- Set the frame position
    frame:SetPoint(point, frame:GetParent(), relativePoint, xOffset, yOffset)
    return true
end

--[[---------------------------------------------------------------------------
    Function:   ShowUI
    Purpose:    Open custom UI to show last sync errors to user.
-----------------------------------------------------------------------------]]
function ns:ShowUI(openDelaySeconds)
    -- make sure key name, server and spec are set
    ns.sets:SetKeyPlayerServerSpec()

    -- make sure openDelaySeconds is not nil
    if openDelaySeconds == nil then
        openDelaySeconds = 0
    end

    -- be sure frame doesn't exist
    if ns.data.ui.frame.main == nil then
        -- create main frame
        ns:CreateMainFrame()

        -- create tab group
        ns.tabs:ProcessTabSystem()

        -- load left side
        -- ns:CreateLeftToyFrame()

        -- load tag maintenance frame
        -- ns:CreateMaintainTagsFrame()
    end

    -- display the frame
    ns.data.ui.frame.main:Show()
end

--[[---------------------------------------------------------------------------
    Function:   CreateMainFrame
    Purpose:    Create the main frame for the addon UI.
-----------------------------------------------------------------------------]]
function ns:CreateMainFrame()
    -- get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- set initial sizes
    local frameWidth = screenWidth * 0.4
    local frameHeight = screenHeight * 0.4

    -- make sure its the minimum size
    if frameWidth < ns.data.constants.ui.mainFrame.minWidth then
        frameWidth = ns.data.constants.ui.mainFrame.minWidth
    end
    if frameHeight < ns.data.constants.ui.mainFrame.minHeight then
        frameHeight = ns.data.constants.ui.mainFrame.minHeight
    end

    --@debug@
    ns:Print(("Creating main frame with size: %.1f x %.1f"):format(frameWidth, frameHeight))
    --@end-debug@

    -- if already created exit function
    if ns.data.ui.frame.main ~= nil then
        return
    end

    -- use PortraitFrameTemplate which is more reliable in modern WoW
    ns.data.ui.frame.main = CreateFrame("Frame", "ToysByFunctionMainFrame", UIParent, "PortraitFrameTemplate")
    ns.data.ui.frame.main:SetSize(frameWidth, frameHeight)

    -- set the frame location
    local posnRestored = ns:RestoreFramePosition(ns.data.ui.frame.main, frameWidth, frameHeight)

    -- frame:SetPoint("CENTER")
    ns.data.ui.frame.main:SetMovable(true)
    ns.data.ui.frame.main:EnableMouse(true)
    ns.data.ui.frame.main:RegisterForDrag("LeftButton")
    ns.data.ui.frame.main:SetScript("OnDragStart", ns.data.ui.frame.main.StartMoving)
    ns.data.ui.frame.main:SetScript("OnDragStop", function()
        -- must be self; since this is a frame function
        ns.data.ui.frame.main:StopMovingOrSizing()
        -- store window position; must use ToysByFunction since its an addon function
        ns:StoreFramePosition(ns.data.ui.frame.main)
    end)
    ns.data.ui.frame.main:SetFrameStrata("HIGH")
    ns.data.ui.frame.main:SetTitle(ns.L["Toys by Function"] or "Toys by Function")
    ns.data.ui.frame.main:SetPortraitToAsset("Interface\\Icons\\inv_misc_coinbag_special")
    
    -- enable escape key functionality following WoW addon patterns
    ns.data.ui.frame.main:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            ns.data.ui.frame.main:Hide()
        end
    end)
    ns.data.ui.frame.main:EnableKeyboard(true)
    ns.data.ui.frame.main:SetPropagateKeyboardInput(true)

    -- setup OnShow event
    ns.data.ui.frame.main:SetScript("OnShow", function()
        -- nothing yet
    end)
    
    -- register frame for escape key handling using WoW's standard system
    tinsert(UISpecialFrames, ns.data.ui.frame.main:GetName())
end

--EOF