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

        -- load tag maintenance frame
        ns:CreateMaintainTagsFrame()
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
function ns:CreateToyScrollList(parent)
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
function ns:PopulateToysByTag()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- make sure frame exists before proceeding
    -- if not ns.data.ui.frame.filteredToys then return end

    -- current selected tag
    local selectedTag = ns.gets:GetSelectedTag() or "none"

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

--[[---------------------------------------------------------------------------
    Function:   CreateMaintainTagsFrame
    Purpose:    Create a frame for maintaining tags.
-----------------------------------------------------------------------------]]
function ns:CreateMaintainTagsFrame()
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create frame to hold all content for maintaining tags
    ns.data.ui.frame.tagMaint = CreateFrame("Frame", nil, ns.data.ui.frame.main) --, "InsetFrameTemplate")
    ns.data.ui.frame.tagMaint:SetPoint("TOPLEFT", ns.data.ui.frame.leftFrame, "TOPRIGHT", padding, 0)
    ns.data.ui.frame.tagMaint:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.main, "BOTTOMRIGHT", -padding, padding)
    -- ns.data.ui.frame.tagMaint:SetPoint("BOTTOMLEFT", ns.data.ui.frame.leftFrame, "BOTTOMRIGHT", padding, 0)
    -- ns.data.ui.frame.tagMaint:SetWidth(400)

    -- add title to frame
    local titleLabel = ns.data.ui.frame.tagMaint:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleLabel:SetJustifyH("LEFT")
    titleLabel:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaint, "TOPLEFT", 0, 0)
    titleLabel:SetText(ns.L["Maintain Tags:"])

    -- create inset frame to hold the tag list
    local insetFrame = CreateFrame("Frame", nil, ns.data.ui.frame.leftFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, 0)
    insetFrame:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.tagMaint, "BOTTOMRIGHT", 0, 0)

    -- create scroll box for tag maintenance
    -- variable mainly for the PopulateTagMaintList function to access the scroll box
    ns.data.ui.scroll.tagMaint = ns:CreateTayMaintScrollList(insetFrame)

    -- populate the scroll box with tag data
    ns:PopulateTagMaintList()

    -- load the button frame for tag maintenance
    ns:CreateTagMaintButtonFrame(insetFrame)
end

--[[---------------------------------------------------------------------------
    Function:   CreateTayMaintScrollList
    Purpose:    Create a scrollable list frame for maintaining tags.
                This is Blizzards new version for scroll frames.
    Arguments:  parent - the parent frame to attach the scroll list to
-----------------------------------------------------------------------------]]
function ns:CreateTayMaintScrollList(parent)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- frame to contain label and scroll box
    ns.data.ui.frame.tagMaintTagListTopFrame = CreateFrame("Frame", nil, parent)
    ns.data.ui.frame.tagMaintTagListTopFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    ns.data.ui.frame.tagMaintTagListTopFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    ns.data.ui.frame.tagMaintTagListTopFrame:SetWidth(200)

    -- frame label
    local scrollBoxLabel = ns.data.ui.frame.tagMaintTagListTopFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scrollBoxLabel:SetJustifyH("LEFT")
    scrollBoxLabel:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaintTagListTopFrame, "TOPLEFT", padding, -padding)
    scrollBoxLabel:SetText(ns.L["Pick a tag or click 'New Tag':"])

    -- create parent frame for the scroll box
    ns.data.ui.frame.tagMaintTagListScrollBoxParent = CreateFrame("Frame", nil, ns.data.ui.frame.tagMaintTagListTopFrame, "InsetFrameTemplate")
    ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("TOPLEFT", scrollBoxLabel, "BOTTOMLEFT", 0, -5)
    ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.tagMaintTagListTopFrame, "BOTTOMRIGHT", 0, padding)
    -- ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetPoint("BOTTOM", parent, "BOTTOM", 0, padding)
    -- ns.data.ui.frame.tagMaintTagListScrollBoxParent:SetWidth(parent:GetWidth() / 2)

    -- 1. Create components
    local scrollBox = CreateFrame("Frame", nil, ns.data.ui.frame.tagMaintTagListScrollBoxParent, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaintTagListScrollBoxParent, "TOPLEFT", 5, -5)
    scrollBox:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.tagMaintTagListScrollBoxParent, "BOTTOMRIGHT", -20, 5)

    local scrollBar = CreateFrame("EventFrame", nil, ns.data.ui.frame.tagMaintTagListScrollBoxParent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- 2. Configure view with fixed row height; for variable-height elements
    local view = CreateScrollBoxListLinearView()
    ns.data.ui.height.toyMaintCell = 25
    view:SetElementExtentCalculator(function(dataIndex, data)
        --@debug@
        -- ns:Print(("Calculating height for dataIndex %d with name %s"):format(dataIndex, data.name or "Unknown"))
        --@end-debug@
        return ns.data.ui.height.toyMaintCell
    end)

    -- 3. Element initializer (called when a row becomes visible)
    view:SetElementInitializer("BackdropTemplate", function(frame, data)
        -- standard variables
        local padding = ns.data.constants.ui.generic.padding

        -- track global names of checkboxes
        if ns.data.ui.checkbox == nil then
            ns.data.ui.checkbox = {}
        end
        if ns.data.ui.checkbox.tagMaint == nil then
            ns.data.ui.checkbox.tagMaint = {}
        end

        -- checkbox with the tag as a label
        if frame.tagCheckbox == nil then
            -- create global name
            local checkboxName = ns.gets:GetObjectName("CheckboxTagMaint" .. data.tagId)

            -- add to list
            if ns.data.ui.checkbox.tagMaint[checkboxName] == nil then
                table.insert(ns.data.ui.checkbox.tagMaint, checkboxName)
            end

            -- create checkbox
            frame.tagCheckbox = CreateFrame("CheckButton", checkboxName, frame, "UICheckButtonTemplate")
            frame.tagCheckbox:SetPoint("LEFT", frame, "LEFT", padding, 0)
            frame.tagCheckbox:SetSize(24, 24)
            frame.tagCheckbox:SetAttribute(ns.data.tagAttrName, data.tagId)
            frame.tagCheckbox:SetScript("OnClick", function(self)
                ns:CheckedTagMaintenance(self)
            end)
        end
        frame.tagCheckbox.Text:SetText(data.name)
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

    return scrollBox
end

--[[---------------------------------------------------------------------------
    Function:   CheckedTagMaintenance
    Purpose:    Handle the logic when a tag maintenance checkbox is clicked.
-----------------------------------------------------------------------------]]
function ns:CheckedTagMaintenance(checkedBox)
    -- get the checkbox addon attribute which contains the tag ID
    local id = checkedBox:GetAttribute(ns.data.tagAttrName)

    -- loop over all checkboxes and uncheck them but this one
    for _, globalName in pairs(ns.data.ui.checkbox.tagMaint) do
        local checkbox = _G[globalName]
        if checkbox and checkbox ~= checkedBox then
            checkbox:SetChecked(false)
        end
    end

    --@debug@
    if false then
        local isChecked = checkedBox:GetChecked()
        local name = checkedBox:GetName()
        ns:Print(("Tag '%s' checkbox clicked. Checked: %s (ID: %s)"):format(name, tostring(isChecked), tostring(id)))
    end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   PopulateTagMaintList
    Purpose:    Update the list of toys displayed in the left frame based on the selected tag.
-----------------------------------------------------------------------------]]
function ns:PopulateTagMaintList()
    -- create data provider for scrollbox
    if ns.data.dp.toyMaintList == nil then
        ns.data.dp.toyMaintList = CreateDataProvider()
        --@debug@
        -- ns:Print("Created DataProvider for Toy Maintenance List")
        --@end-debug@
    end

    -- reset data provider
    ns.data.dp.toyMaintList:Flush()

    -- collect tags into a sortable table
    for tagId, tagData in pairs(ns.db.global.tags.order) do
        ns.data.dp.toyMaintList:Insert({
            tagId = tagId,
            name = tagData.name or ns.L[tagId] or tagId,
            order = tagData.order
        })
    end

    -- insert sorted rows into the data provider
    ns.data.dp.toyMaintList:Sort(function(a, b) return a.order < b.order end)

    -- pass refreshed data into scroll box
    ns.data.ui.scroll.tagMaint:SetDataProvider(ns.data.dp.toyMaintList)

    --@debug@
    -- ns:Print(("Total Toy Frames Created: %d"):format(#ns.data.ui.frame.items))
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   CreateTagMaintButtonFrame
    Purpose:    Create a frame with a checkbox to protect on delete and buttons for tag maintenance actions (New, Edit, Delete).
-----------------------------------------------------------------------------]]
function ns:CreateTagMaintButtonFrame(parent)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- top level frame to hold all visible items for this section
    local optionFrame = CreateFrame("Frame", nil, parent)
    optionFrame:SetPoint("TOPLEFT", ns.data.ui.frame.tagMaintTagListTopFrame, "TOPRIGHT", 0, 0)
    optionFrame:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- label for the options frame
    local optionLabel = optionFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    optionLabel:SetJustifyH("LEFT")
    optionLabel:SetPoint("TOPLEFT", optionFrame, "TOPLEFT", padding, -padding)
    optionLabel:SetText(ns.L["Tag Edits:"])

    -- frame to hold buttons
    local insetFrame = CreateFrame("Frame", nil, optionFrame, "InsetFrameTemplate")
    insetFrame:SetPoint("TOPLEFT", optionLabel, "BOTTOMLEFT", 0, -5)
    insetFrame:SetPoint("BOTTOMRIGHT", optionFrame, "BOTTOMRIGHT", -padding, padding)

    -- create checkbox to prevent tag deletion if toys are still associated with itemIDs
    local function PreventTagDelete_OnClick()
        ns.sets:SetOptionPreventTagDelete()
    end
    local function GetPreventTagDelete()
        return ns.gets:GetOptionPreventTagDelete()
    end
    local checkboxLabel = ns.L["Prevent Tag Deletion if Toys Assigned"]
    local checkboxTooltip = ns.L["If checked, tags assigned to toys will NOT be deleted. Otherwise, tags are deleted but associated toys moved to the uncategorized tag."]
    local checkboxPreventDelete = ns:CreateCheckboxTextWrap(insetFrame, checkboxLabel, GetPreventTagDelete, nil, checkboxTooltip, PreventTagDelete_OnClick)
    checkboxPreventDelete.frame:SetPoint("TOPLEFT", insetFrame, "TOPLEFT", padding, -padding)
    checkboxPreventDelete.frame:SetPoint("RIGHT", insetFrame, "RIGHT", -padding, 0)
    checkboxPreventDelete.frame:SetHeight(checkboxPreventDelete.label:GetStringHeight() + padding)

    -- create buttons for managing tags (New, Edit, Delete)
    local buttonPadding = -5
    local btnNewTagAbove = ns:CreateStandardButton(insetFrame, nil, ns.L["New Tag Above"], 40, function() ns:OnClick_NewTag(true) end)
    btnNewTagAbove:SetPoint("TOPLEFT", checkboxPreventDelete.frame, "BOTTOMLEFT", 0, buttonPadding)
    local btnNewTagBelow = ns:CreateStandardButton(insetFrame, nil, ns.L["New Tag Below"], 40, function() ns:OnClick_NewTag(false) end)
    btnNewTagBelow:SetPoint("TOPLEFT", btnNewTagAbove, "BOTTOMLEFT", 0, buttonPadding)
    local btnEditTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Rename Tag"], 40, function() ns:OnClick_EditTag() end)
    btnEditTag:SetPoint("TOPLEFT", btnNewTagBelow, "BOTTOMLEFT", 0, buttonPadding)
    local btnDeleteTag = ns:CreateStandardButton(insetFrame, nil, ns.L["Delete Tag"], 40, function() ns:OnClick_DeleteTag() end)
    btnDeleteTag:SetPoint("TOPLEFT", btnEditTag, "BOTTOMLEFT", 0, buttonPadding)

    -- fix button widths
    ns:ButtonCheckWidth({btnNewTagAbove, btnNewTagBelow, btnEditTag, btnDeleteTag})

    -- calculate height
    local frameHeight = checkboxPreventDelete.frame:GetHeight() + btnNewTagAbove:GetHeight() + btnNewTagBelow:GetHeight() + btnEditTag:GetHeight() + btnDeleteTag:GetHeight() + (buttonPadding * 4) + (padding * 2)
    insetFrame:SetHeight(frameHeight)
end

--[[---------------------------------------------------------------------------
    Function:   ButtonCheckWidth
    Purpose:    Ensure all buttons in a given list have the same width based on the widest button's text.
    Arguments:  buttons - a table of button objects to check and adjust
-----------------------------------------------------------------------------]]
function ns:ButtonCheckWidth(buttons)
    -- track width
    local maxWidth = 0

    -- loop over all the buttons passed in
    for _, button in pairs(buttons) do
        -- calculate the width based on the text width plus padding
        local buttonWidth = button:GetTextWidth() + 20
        --@debug@
        -- ns:Print(("Button '%s' width calculated as %.1f"):format(button:GetText(), buttonWidth))
        --@end-debug@

        -- find the max width among all buttons
        if buttonWidth > maxWidth then
            maxWidth = buttonWidth
        end
    end

    -- loop again to update all button widths
    for _, button in pairs(buttons) do
        button:SetWidth(maxWidth)
    end
end

function ns:OnClick_NewTag(above)
    if above == true then

    else

    end
end

function ns:OnClick_EditTag()

end

function ns:OnClick_DeleteTag()

end

--EOF