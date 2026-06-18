--[[ ------------------------------------------------------------------------
	Title: 			Main.lua
	Author: 		mrbryo
	Create Date : 	06/13/2025 21:24
	Description: 	Main program for Toys by Function addon.
-----------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
    Function:   InitializeLocalization
    Purpose:    Load the localization table for the current locale.
-----------------------------------------------------------------------------]]
function ToysByFunction:InitializeLocalization()
    -- get current local
    local locale = GetLocale() or "enUS"

    -- get language data
    self.L = self.locales[locale]

    -- clear locales to free memory
    self.locales = nil
end

--[[---------------------------------------------------------------------------
	Register the addon loaded event to begin further initialization.
-----------------------------------------------------------------------------]]
ToysByFunction:RegisterEvent("ADDON_LOADED", function(self, event, addonName, ...)
	if addonName ~= "ToysByFunction" then
		return
	end

	--@debug@
	-- ToysByFunction:Print(("%s loaded for Addon: %s"):format(event, addonName))
	--@end-debug@

    -- initialize language
    ToysByFunction:InitializeLocalization()

    -- Check the DB
    if not ToysByFunctionDB then
        ToysByFunction:Print(ToysByFunction.L["Database Not Found? Strange...please reload the UI. If error returns, restart the game."])
    end

    -- Register Events using native system
    ToysByFunction:RegisterAddonEvents()
    
    -- Create minimap button using LibDBIcon
    ToysByFunction:CreateMinimapButton()

    -- Create and register the options panel
    ToysByFunction:CreateOptionsPanel()

	-- unregister event
	ToysByFunction:UnregisterEvent("ADDON_LOADED")
end)

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBChar
    Purpose:    Ensure the character specific DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ToysByFunction:InstantiateDBChar(barID)
    -- create the character structure
    if not self.char then
        self.char = {}
    end

    -- currentBarData holds the last scan of data fetched from the action bars for the current character; hence stored in char
    if not self.char[self.currentPlayerServerSpec] then
        self.char[self.currentPlayerServerSpec] = {}
    end

    -- copy the tags as tabs
    if not self.char[self.currentPlayerServerSpec].tabs then
        -- loop over the tags and copy them to create tab id's and the initial order of the tabs
        for index, tag in ipairs(self.tags) do
            -- if tabs is empty, create it
            if not self.char[self.currentPlayerServerSpec].tabs then
                self.char[self.currentPlayerServerSpec].tabs = {}
            end

            -- add the tag
            table.insert(self.char[self.currentPlayerServerSpec].tabs, {
                id = tag,
                order = index
            })
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBGlobal
    Purpose:    Ensure the global DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ToysByFunction:InstantiateDBGlobal(barID)
    -- create the global structure
    self:SetupGlobalDB()
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBProfile
    Purpose:    Ensure the profile DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ToysByFunction:InstantiateDBProfile()
    -- create/fix/update the profile structure
    self:SetupProfileDB()

    -- create initial value for storing custom tag settings
    if not ToysByFunctionDB.profile[self.currentPlayerServer].tags then
        ToysByFunctionDB.profile[self.currentPlayerServer].tags = {}
    end

    -- create inital value for storing custom tags
    if not ToysByFunctionDB.profile[self.currentPlayerServer].tags.custom then
        ToysByFunctionDB.profile[self.currentPlayerServer].tags.custom = {}
    end

    -- create initial value for storing custom tags and/or order
    if not ToysByFunctionDB.profile[self.currentPlayerServer].tags.order then
        ToysByFunctionDB.profile[self.currentPlayerServer].tags.order = {}
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateTags
    Purpose:    Copy the tags into the DB from the ToyDB.lua file as this is the source of record as the ToyDB.lua is maintained by the python script.
-----------------------------------------------------------------------------]]
function ToysByFunction:InstantiateTags()
    -- make sure tags exists from the ToyDB.lua file
    if self.tags then
        -- loop over those tags
        for idx, id in pairs(self.tags) do
            -- check if the tag exists, if not add it
            if not ToysByFunctionDB.profile[self.currentPlayerServer].tags.order[id] then
                -- if not, copy it in from the source of record; order is determined by the index of the tag; always add as enabled by default
                ToysByFunctionDB.profile[self.currentPlayerServer].tags.order[id] = {
                    order = idx,
                    enabled = true,
                }
            end
        end

        --@debug@
        -- for tagID, tagdata in pairs(ToysByFunctionDB.profile[self.currentPlayerServer].tags.order) do
        --     ToysByFunction:Print(("Tag in DB: %s with order %d and enabled state %s"):format(tagID, tostring(tagdata.order), tostring(tagdata.enabled)))
        -- end
        --@end-debug@
    else
        self:Print(self.L["Tags Missing from Toy DB; unable to process default tags. Please open a ticket."])
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDB
    Purpose:    Ensure the DB has all the necessary values. Can run anytime to check and fix all data with default values.
-----------------------------------------------------------------------------]]
function ToysByFunction:InstantiateDB()
    --@debug@
    if self:GetDevMode() == true then
        self:Print(ToysByFunction.L["DB Initialization"])
    end
    --@end-debug@
    -- make sure player key is set
    self:SetKeyPlayerServerSpec()
    self:SetKeyPlayerServer()

    -- instantiate db
    self:InstantiateDBProfile()
    self:InstantiateDBGlobal()
    self:InstantiateDBChar()

    -- instantiate tags; must be called after InstantiateDBProfile
    self:InstantiateTags()
end

--[[---------------------------------------------------------------------------
    Function:   FormatDateString
    Purpose:    Convert a date string from YYYYMMDDHHMISS or YYYY-MM-DD HH:MI:SS format to YYYY, Mon DD HH:MI:SS format.
-----------------------------------------------------------------------------]]
function ToysByFunction:FormatDateString(dateString)    
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
function ToysByFunction:RemoveFrameChildren(parent)
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
function ToysByFunction:SafeWoWAPICall(func, ...)
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
        if self:GetDevMode() == true then
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
function ToysByFunction:EnableDevelopment()
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
function ToysByFunction:DisableDevelopment()
    if self:GetTab() == "developer" then
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
    Function:   SlashCommand
    Purpose:    Respond to all slash commands.
-----------------------------------------------------------------------------]]
function ToysByFunction:SlashCommand(text)
    -- if no text is provided, show the options dialog
    if text == nil or text == "" then
        self:ShowUI()
        return
    end

    -- get args
    for _, arg in ipairs(self:GetArgs(text)) do
        if arg:lower() == "enablemodedeveloper" then
            if not self:GetDevMode() or self:GetDevMode() == false then
                self:EnableDevelopment()
            else
                self:DisableDevelopment()
            end
        else
            self:Print((self.L["Unknown Command: %s"]):format(arg))
        end
    end
end

--[[---------------------------------------------------------------------------
    Function:   EventPlayerLogout
    Purpose:    Handle functionality which is best or must wait for the PLAYER_LOGOUT event.
-----------------------------------------------------------------------------]]
function ToysByFunction:EventPlayerLogout()
    --@debug@
    if self:GetDevMode() == true then self:Print(self.L["Player Logging Out..."]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
    Function:   OnDisable
    Purpose:    Trigger code when addon is disabled.
-----------------------------------------------------------------------------]]
function ToysByFunction:OnDisable()
    -- set language variable
    local L = self.L
    
    -- Unregister events by removing the event frame
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnEvent", nil)
    end

    if self:GetDevMode() == true then
        self:Print(self.L["Disabled"])
    end

    -- same clean up should occur when disabled
    self:EventPlayerLogout()
end

--[[---------------------------------------------------------------------------
    Function:   RegisterAddonEvents
    Purpose:    Register all events for the addon using native WoW event system.
-----------------------------------------------------------------------------]]
function ToysByFunction:RegisterAddonEvents()
    --@debug@
    -- if self:GetDevMode() == true then
    --     self:Print(ToysByFunction.L["Registering Events..."]) 
    -- end
    --@end-debug@

    -- PLAYER_ENTERING_WORLD
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, ...)
        -- get event parameters
        local isInitialLogin, isReload = ...
        --@debug@
        ToysByFunction:Print(("Event Triggered - %s, isInitialLogin: %s, isReload: %s"):format(event, tostring(isInitialLogin) and ToysByFunction.L["Yes"] or ToysByFunction.L["No"], tostring(isReload) and ToysByFunction.L["Yes"] or ToysByFunction.L["No"]))
        --@end-debug@

        -- instantiate player keys
        ToysByFunction:SetKeyPlayerServerSpec()
        ToysByFunction:SetKeyPlayerServer()

        -- run db initialize again but pass in barName to make sure all keys are setup for this barName
        ToysByFunction:InstantiateDB()
        
        -- update global variable for tracking if event has triggered
        ToysByFunction.hasPlayerEnteredWorld = true
    end)

    -- PLAYER_LOGOUT
    self:RegisterEvent("PLAYER_LOGOUT", function(self, event, ...)
        --@debug@
        ToysByFunction:Print(("Event Triggered - %s"):format(event))
        --@end-debug@
        ToysByFunction:EventPlayerLogout()
    end)

    -- VARIABLES_LOADED
    self:RegisterEvent("VARIABLES_LOADED", function(self, event, ...)
        --@debug@
        ToysByFunction:Print(("Event Triggered - %s"):format(event))
        --@end-debug@
    end)
end

--[[---------------------------------------------------------------------------
    Function:   StoreFramePosition
    Purpose:    Store the current frame position in the character database.
    Arguments:  frame - the frame whose position to store
-----------------------------------------------------------------------------]]
function ToysByFunction:StoreFramePosition(frame)
    -- Get current position
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    -- get frame name
    local frameName = frame:GetName()
    if not frameName then
        if self:GetDevMode() == true then
            self:Print(self.L["Error: Frame has no name, cannot store position."])
        end
        return
    end

    -- store position data in the character database
    local isSuccess = self:SetFramePosition(frameName, point, relativePoint, xOfs, yOfs)

    --@debug@
    -- if self:GetDevMode() == true then
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
function ToysByFunction:RestoreFramePosition(frame, frameWidth, frameHeight)
    -- set language variable
    local L = self.L

    -- get frame name
    local frameName = frame:GetName()
    
    -- get stored position data
    local storedPosition = self:GetFramePosition(frameName)
    if not storedPosition then
        --@debug@
        if self:GetDevMode() == true then
            self:Print((self.L["No stored position data found for frame: %s"]):format(frameName))
        end
        --@end-debug@
        return false
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
            -- if self:GetDevMode() == true then
            --     self:Print(("Frame positioned from stored data: %s %.1f %.1f."):format(point, xOffset, yOffset))
            -- end
            --@end-debug@
        else
            --@debug@
            -- if self:GetDevMode() == true then
            --     self:Print("Stored frame position is outside bounds, centering frame.")
            -- end
            --@end-debug@
        end
    else
        --@debug@
        -- if self:GetDevMode() == true then
        --     self:Print("No stored frame position found, centering frame.")
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
function ToysByFunction:ShowUI(openDelaySeconds)
    -- make sure key name, server and spec are set
    self:SetKeyPlayerServerSpec()

    -- make sure openDelaySeconds is not nil
    if not openDelaySeconds then
        openDelaySeconds = 0
    end

    -- be sure frame doesn't exist
    if not ToysByFunctionMainFrame then
        -- create main frame
        self:CreateMainFrame()

        -- load filter bar
        self:CreateMainFrameFilterBar()

        -- load content
        self:CreateMainFrameContent()

        -- show initial tab
        -- local tabKey = self:GetTab()

        -- check on developer mode
        -- if self:GetDevMode() == false then
        --     -- hide developer tab button
        --     --self:SetDeveloperTabVisibleState(false)

        --     -- if the current tab is developer then switch to introduction
        --     if tabKey == "developer" then
        --         tabKey = "introduction"
        --         self:SetTab(tabKey)
        --     end
        -- else
        --     -- show developer tab button
        --     self:SetDeveloperTabVisibleState(true)
        -- end
        --@debug@
        -- self:Print(("(ShowUI) Showing Initial Tab after creating UI: %s"):format(tabKey))
        --@end-debug@
        -- self:ShowTabContent(tabKey)
        -- local buttonID = ToysByFunction.uitabs["buttonref"][tabKey]
        -- PanelTemplates_SetTab(ToysByFunctionMainFrameTabs, buttonID)
    end

    -- display the frame
    ToysByFunctionMainFrame:Show()
end

--[[---------------------------------------------------------------------------
    Function:   CreateMainFrame
    Purpose:    Create the main frame for the addon UI.
-----------------------------------------------------------------------------]]
function ToysByFunction:CreateMainFrame()   
    -- get screen size
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()

    -- set initial sizes
    local frameWidth = screenWidth * 0.4
    local frameHeight = screenHeight * 0.4

    -- make sure its the minimum size
    if frameWidth < self.constants.ui.mainFrame.minWidth then
        frameWidth = self.constants.ui.mainFrame.minWidth
    end
    if frameHeight < self.constants.ui.mainFrame.minHeight then
        frameHeight = self.constants.ui.mainFrame.minHeight
    end
    
    -- use PortraitFrameTemplate which is more reliable in modern WoW
    local frameName = "ToysByFunctionMainFrame"
    local frame = CreateFrame("Frame", frameName, UIParent, "PortraitFrameTemplate")
    frame:SetSize(frameWidth, frameHeight)

    -- set the frame location
    local posnRestored = self:RestoreFramePosition(frame, frameWidth, frameHeight)

    -- frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        -- must be self; since this is a frame function
        self:StopMovingOrSizing()
        -- store window position; must use ToysByFunction since its an addon function
        ToysByFunction:StoreFramePosition(self)
    end)
    frame:SetFrameStrata("HIGH")
    frame:SetTitle(self.L["Toys by Function"] or "Toys by Function")
    frame:SetPortraitToAsset("Interface\\Icons\\inv_misc_coinbag_special")
    
    -- enable escape key functionality following WoW addon patterns
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)

    -- setup OnShow event
    frame:SetScript("OnShow", function(self)
        -- nothing yet
    end)
    
    -- register frame for escape key handling using WoW's standard system
    tinsert(UISpecialFrames, frameName)
    
    -- finally return the frame
    return frame
end

--[[---------------------------------------------------------------------------
    Function:   CreateMainFrameFilterBar
    Purpose:    Create the filter bar for the main frame.
-----------------------------------------------------------------------------]]
function ToysByFunction:CreateMainFrameFilterBar()
    -- standard variables
    local padding = self.constants.ui.generic.padding
    local frameHeight = 50

    -- create top frame to hold filter controls
    local filterBar = CreateFrame("Frame", "ToysByFunctionMainFrameFilterBar", ToysByFunctionMainFrame) --, "InsetFrameTemplate")
    filterBar:SetPoint("TOPLEFT", ToysByFunctionMainFrame, "TOPLEFT", 65, -25)
    filterBar:SetPoint("TOPRIGHT", ToysByFunctionMainFrame, "TOPRIGHT", -15, -25)
    filterBar:SetHeight(frameHeight)

    -- label for dropdown
    local dropdownLabel = filterBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dropdownLabel:SetJustifyH("LEFT")
    dropdownLabel:SetText(self.L["Tag:"])

    -- initialize drop down items with "none" option
    local items = {["none"] = self.L["No Tag Selected"]}

    -- populate drop down with all tags
    -- for tagKey, tagData in pairs(self.tags) do
    --     items[tagKey] = self.L[tagData.name] or tagData.name
    -- end

    local itemOrder = {"none"}
    self.ui.dropdown.filterTag = self:CreateDropdown(filterBar, itemOrder, items, "none", self:GetObjectName("DropdownFilterTag"), function(key)
        -- track choice by character
        if key ~= "none" and key ~= nil then
            -- need to add code to reload view of toys based on the selected tag
            -- self:SetSelectedTag(key)
            -- self:UpdateToyList()
            --@debug@
            ToysByFunction:Print(("Tag Selected: %s"):format(key))
            --@end-debug@
        end
    end)
    self.ui.dropdown.filterTag:SetWidth(200)

    -- update the dropdown with the current tags
    self:UpdateFilterBarTags()

    -- position the label and then dropdown
    local dropdownOffset = (self.ui.dropdown.filterTag:GetHeight() - dropdownLabel:GetStringHeight()) / 2
    dropdownLabel:SetPoint("TOPLEFT", filterBar, "TOPLEFT", 0, -(padding + dropdownOffset))
    self.ui.dropdown.filterTag:SetPoint("LEFT", dropdownLabel, "RIGHT", padding, 0)

    -- readjust the filter bar height
    frameHeight = self.ui.dropdown.filterTag:GetHeight() + (padding * 2)
    filterBar:SetHeight(frameHeight)
end

--[[---------------------------------------------------------------------------
    Function:   UpdateFilterBarTags
    Purpose:    Update the filter bar dropdown with the current tags.
-----------------------------------------------------------------------------]]
function ToysByFunction:UpdateFilterBarTags()
    -- initialize drop down items with "none" option
    local items = {["none"] = self.L["No Tag Selected"]}
    local itemOrder = {"none"}

    -- populate drop down with all tags
    for tagID, tagData in pairs(ToysByFunctionDB.profile[self.currentPlayerServer].tags.order) do
        items[tagID] = self.L[tagID] or tagID
        -- add 1 to the order number to account for the "none" option at the beginning
        local orderNbr = tagData.order + 1
        table.insert(itemOrder, orderNbr, tagID)
        -- self:Print(("Filter Updated: %s (%s) with order %d"):format(tagID, self.L[tagID] or tagID, tagData.order))
    end

    --@debug@
    -- for idx, id in pairs(itemOrder) do
    --     ToysByFunction:Print(("Dropdown Item Order %d: %s"):format(idx, id))
    -- end
    --@end-debug@

    -- get the last selected tag
    local selectedItem = self:GetSelectedTag() or "none"

    -- trigger update
    self.ui.dropdown.filterTag:UpdateItems(itemOrder, items, selectedItem)
end

--[[---------------------------------------------------------------------------
    Function:   MainFrameContent
    Purpose:    Create the main content for the addon UI.
-----------------------------------------------------------------------------]]
function ToysByFunction:CreateMainFrameContent()
    -- standard variables
    local padding = self.constants.ui.generic.padding

    -- create sub frame
    local contentFrame = CreateFrame("Frame", "ToysByFunctionMainFrameContent", ToysByFunctionMainFrame)
    contentFrame:SetPoint("TOPLEFT", ToysByFunctionMainFrameFilterBar, "BOTTOMLEFT", 0, -padding)
    contentFrame:SetPoint("BOTTOMRIGHT", ToysByFunctionMainFrame, "BOTTOMRIGHT", 0, padding) 
end

--[[---------------------------------------------------------------------------
    Function:   CreateOptionsPanel
    Purpose:    Create a single options pane for the Interface Options.
    Note:       This function should be called after the mini-map button is created in order to get proper visibility status.
-----------------------------------------------------------------------------]]
function ToysByFunction:CreateOptionsPanel()
    -- create the main options panel frame
    local panel = CreateFrame("Frame", "ToysByFunctionOptionsPanel", InterfaceOptionsFramePanelContainer)
    panel.name = self.L["Toys by Function"] or "Toys by Function"
    
    -- create title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText(self.L["Toys by Function"] or "Toys by Function")
    
    -- create description
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    description:SetPoint ("RIGHT", panel, "RIGHT", -16, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    description:SetText(self.L["Toys by Function allows you to manage your toys by what action they perform."] .. "\n\n" .. self.L["You can open the Toys by Function interface using the following slash commands or, if visible, left clicking the mini-map button:"] .. "\n\n - /toysbyfunction\n - /tbf")
    
    -- create button to open the addon
    local openButton = CreateFrame("Button", "ToysByFunctionOpenButton", panel, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -24)
    openButton:SetSize(150, 22)
    openButton:SetText(self.L["Open Toys by Function"] or "Open Toys by Function")
    openButton:SetScript("OnClick", function()
        self:ShowUI()
        -- Close the settings panel properly using WoW's UI system
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
    end)
    
    -- create checkbox for minimap button visibility
    local minimapCheckbox = self:CreateCheckbox(
        panel,
        self.L["Show Mini-map Button"],
        self:GetMinimapButtonVisible(),
        "ToysByFunctionMinimapVisibilityCheckbox",
        function(self, button, checked)
            -- must use 'ToysByFunction' instead of 'self' since it's passing a function as a parameter
            ToysByFunction:SetMinimapButtonVisible(checked)
            ToysByFunction:UpdateMinimapButtonVisibility()
        end
    )
    minimapCheckbox:SetPoint("TOPLEFT", openButton, "BOTTOMLEFT", 0, -16)

    -- add a note if any of the libraries are missing
    if self.minimap.libstubStatus == false or self.minimap.libdbiconStatus == false or self.minimap.libdbStatus == false then
        local libStubNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        libStubNote:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -8)
        libStubNote:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
        libStubNote:SetJustifyH("LEFT")
        libStubNote:SetWordWrap(true)
        libStubNote:SetText(self.L["Note: LibDBIcon-1.0 is missing or one of its dependencies (LibStub and LibDataBroker), therefore, mini-map button cannot be created. Also, not sure why, but LibDBIcon-1.0 may not show up in the addon list even if it is installed."])
    end
    
    -- add to Interface Options (modern system only)
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    
    -- must set the category ID
    category.ID = self.optionID
    Settings.RegisterAddOnCategory(category)

    -- store category reference for opening later
    panel.optionsCategory = category
    
    -- store panel reference globally for minimap button access
    self.optionsPanel = panel
end

--[[---------------------------------------------------------------------------
    Function:   CreateMinimapButton
    Purpose:    Create minimap button using LibDBIcon-1.0.
-----------------------------------------------------------------------------]]
function ToysByFunction:CreateMinimapButton()
    -- check if LibStub and LibDBIcon are available
    if not LibStub then
        self.minimap.libstubStatus = false
        return
    end
    
    local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LibDBIcon then
        self.minimap.libdbiconStatus = false
        return
    end
    
    local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LDB then
        self.minimap.libdbStatus = false
        return
    end
    
    -- Create the data broker object
    local minimapLDB = LDB:NewDataObject("ToysByFunction", {
        type = "launcher",
        text = "ToysByFunction",
        icon = "Interface\\Icons\\inv_misc_coinbag_special",
        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                self:ShowUI()
            elseif button == "RightButton" then
                -- open to addon options pane if it was created successfully, if not just open the panel normally
                -- self.optionsPanel is the actual frame built for the addon options
                -- self.optionID is the static string value assigned to the addons options pane
                if self.optionsPanel and Settings then
                    Settings.OpenToCategory(self.optionID)
                else
                    -- let user know there was an issue, then open the options panel normally
                    self:Print(self.L["Issue with addon options panel, cannot open settings."])
                    self.optionsPanel:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(self.L["Toys by Function"] or "Toys by Function")
            tooltip:AddLine(self.L["Click to open Toys by Function"] or "Click to open Toys by Function", 1, 1, 1)
            tooltip:AddLine(self.L["Right-click for Options"] or "Right-click for Options", 1, 1, 1)
        end,
    })
    
    -- Initialize database for minimap settings if needed
    if not ToysByFunctionDB.global.minimap then
        ToysByFunctionDB.global.minimap = {
            hide = false,
        }
    end
    
    -- Register with LibDBIcon
    LibDBIcon:Register("ToysByFunction", minimapLDB, ToysByFunctionDB.global.minimap)
    
    -- Store reference
    self.minimapLDB = minimapLDB
end

--[[---------------------------------------------------------------------------
    Function:   UpdateMinimapButtonVisibility
    Purpose:    Update the minimap button visibility using LibDBIcon.
-----------------------------------------------------------------------------]]
function ToysByFunction:UpdateMinimapButtonVisibility()
    local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
    if not LibDBIcon or not self.minimapLDB then
        return
    end
    
    local shouldShow = self:GetMinimapButtonVisible()
    if shouldShow then
        LibDBIcon:Show("ToysByFunction")
    else
        LibDBIcon:Hide("ToysByFunction")
    end
end

--EOF