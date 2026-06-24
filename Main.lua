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

        -- load left side
        ns:CreateLeftToyFrame()
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

--[[---------------------------------------------------------------------------
    Function:   CreateLeftToyFrame
    Purpose:    Create the left frame for displaying the list of toys based on the selected tag.
-----------------------------------------------------------------------------]]
function ns:CreateLeftToyFrame()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all the content on the left side
    local leftFrame = CreateFrame("Frame", nil, ns.data.ui.frame.main)
    leftFrame:SetPoint("TOPLEFT", ns.data.ui.frame.main, "TOPLEFT", padding, -60)
    leftFrame:SetPoint("BOTTOMLEFT", ns.data.ui.frame.main, "BOTTOMLEFT", padding, padding)
    leftFrame:SetWidth(400)

    -- add label to left frame
    local leftFrameLabel = leftFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftFrameLabel:SetJustifyH("LEFT")
    leftFrameLabel:SetPoint("TOPLEFT", leftFrame, "TOPLEFT", 0, 0)
    leftFrameLabel:SetText(ns.L["Filtered List of Toys by Tag:"])

    -- create inset frame
    local mainleft = CreateFrame("Frame", nil, leftFrame, "InsetFrameTemplate")
    mainleft:SetPoint("TOPLEFT", leftFrameLabel, "BOTTOMLEFT", 0, 0)
    mainleft:SetPoint("BOTTOMRIGHT", leftFrame, "BOTTOMRIGHT", 0, 0)

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
            -- ns:SetSelectedTag(key)
            -- ns:UpdateToyList()
            ns.sets:SetSelectedTag(key)
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
function ns:CreateToyMainOptionsButton(parent)
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
        ns:Print(("(IsTooltipEnabled) Show Toy Tooltips option is: %s"):format(tostring(value)))
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

    -- MenuUtil.CreateRadioContextMenu(button, GetToySortingOrderMainConfig, SetToySortingOrderMainConfig,
    --     {ns.L["A-Z"], "az"},
    --     {ns.L["Z-A"], "za"}
    -- )

    -- finally return the button to be positioned and visible in the UI
    return button
end

--[[---------------------------------------------------------------------------
    Function:   CreateToyScrollList
    Purpose:    Create a scrollable list frame for displaying toys.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
function ns:CreateToyScrollList(parent)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    scrollBox:SetPoint("TOP", ns.data.ui.dropdown.filterToysByTag, "BOTTOM", 0, -padding)
    scrollBox:SetPoint("LEFT", parent, "LEFT", 5, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -17, 5)

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
        if not frame.icon then
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
    Function:   UpdateToyList
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
function ns:PopulateToysByTag()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- make sure frame exists before proceeding
    -- if not ns.data.ui.frame.filteredToys then return end

    -- current selected tag
    local selectedTag = ns.gets:GetSelectedTag() or "none"

    -- create data provided for scrollbox
    if not ns.data.dp.leftToyList then
        ns.data.dp.leftToyList = CreateDataProvider()
        --@debug@
        -- ns:Print("Created DataProvider for Left Toy List")
        --@end-debug@
    end

    -- loop over toys by tag if a selected tag is returned
    if selectedTag ~= "none" then

        -- track the index of frames
        local frameIndex = 1
        local prevIndex = 0
        local previousFrame = ns.data.ui.frame.filteredToys

        -- tracking frames
        if not ns.data.ui.frame.items then
            ns.data.ui.frame.items = {}
            ns.data.ui.frame.itemIcons = {}
            ns.data.itemFrameCount = 0
        end

        -- reset data provider
        ns.data.dp.leftToyList:Flush()

        -- loop over the toys in the tag listing and create frames for each toy
        for _, itemId in pairs(ns.db.global.toys.byTag[selectedTag]) do
            -- convert itemId to a string
            local strItemId = tostring(itemId)

            -- verify item exists
            local itemInfo = {}
            if ns.db.global.toys.byItemId[strItemId] then
                -- -- get the toy item data
                itemInfo = ns.db.global.toys.byItemId[strItemId]

                --@debug@
                -- ns:Print(("Processing toy with itemId %s for tag %s"):format(itemId, selectedTag))
                --@end-debug@

                -- item texture
                local itemIconFileId = itemInfo.icon

                -- add record to data provider
                ns.data.dp.leftToyList:Insert({
                    itemId = itemId,
                    name = itemInfo.name,
                    icon = itemIconFileId,
                })
            else
                --@debug@
                -- ns:Print(("No item data found for itemId %s, skipping."):format(itemId))
                --@end-debug@
            end
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
function ns:UpdateFilterBarTags()
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
    local selectedItem = ns.gets:GetSelectedTag() or "none"

    -- trigger update
    ns.data.ui.dropdown.filterToysByTag:UpdateItems(itemOrder, items, selectedItem)
end

function ns:CreateMaintainTags()

end

--EOF