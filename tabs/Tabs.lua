--[[ ------------------------------------------------------------------------
	Title: 			Tabs.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-05
	Description: 	All tab functions for the addon.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.tabs = {}

--[[---------------------------------------------------------------------------
    Function:   ShowTabContent
    Purpose:    Show the content for the selected tab.
-----------------------------------------------------------------------------]]
function ns.tabs:ShowTabContent(tabKey)
    -- get current tab to hide
    local currentTab = ns.tabs:GetTab()

    -- get global variable friendly tab name
    -- local varName = ns.tabs.uitabs["varnames"][currentTab]

    -- get the global name of the tab
    -- local tabContentFrame = self:GetObjectName(ns.data.constants.objectNames.tabContentFrame .. varName)
    --@debug@
    -- self:Print(("(ShowTabContent) tabKey: %s, varName: %s, tabContentFrame is nil: %s"):format(tostring(tabKey), tostring(varName), tostring(tabContentFrame == nil)))
    --@end-debug@

    -- hide the tab
    if currentTab ~= nil and ns.data.ui.tabs ~= nil then
        if ns.data.ui.tabs[currentTab] ~= nil then
            ns.data.ui.tabs[currentTab]:Hide()
        end
    end
    -- if _G[tabContentFrame] then
    --     _G[tabContentFrame]:Hide()
    -- end

    --@debug@
    -- self:Print(("Showing Tab Content for tabKey: %s"):format(tostring(tabKey)))
    --@end-debug@

    -- set the tab
    ns.tabs:SetTab(tabKey)

    -- currentframe
    -- local currentFrame = nil

    -- switch to the selected tab
    if tabKey == "about" then
        -- tabs\About.lua
        ns.about:ProcessAboutFrame(tabKey)
    elseif tabKey == "introduction" then
        -- tabs\Introduction.lua
        ns.intro:ProcessIntroductionFrame(tabKey)
    elseif tabKey == "tagmaint" then
        -- tabs\TagMaint.lua
        ns.tagMaint:ProcessTagMaintFrame(tabKey)
    elseif tabKey == "toymaint" then
        -- tabs\ToyMaint.lua
        ns.toymaint:ProcessToyMaintFrame(tabKey)
    -- elseif tabKey == "developer" then
    --     -- tabs\Developer.lua
    --     ns.developer:ProcessDeveloperFrame(tabKey)
    end

    -- show new tab content frame
    -- if currentFrame ~= nil then
    if ns.data.ui.tabs[tabKey] ~= nil then
        ns.data.ui.tabs[tabKey]:Show()
    end
end

--[[---------------------------------------------------------------------------
    Function:   ProcessTabSystem
    Purpose:    Create a tab system at the bottom of the main frame.
-----------------------------------------------------------------------------]]
function ns.tabs:ProcessTabSystem()
    -- instantiate variable for the main tab frame
    -- local tabFrame = nil
    
    -- check to see if tab system already exists; if not create the main frame to hold the tabs
    if ns.data.ui.tabs.tabframe == nil then
        -- create a frame to hold the tabs
        ns.data.ui.tabs.tabframe = CreateFrame("Frame", nil, ns.data.ui.frame.main)

        -- position tabs at the bottom of the frame like Collections Journal
        ns.data.ui.tabs.tabframe:SetPoint("BOTTOMLEFT", ns.data.ui.frame.main, "BOTTOMLEFT", 10, -5)
        ns.data.ui.tabs.tabframe:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.main, "BOTTOMRIGHT", -10, -5)
        ns.data.ui.tabs.tabframe:SetHeight(30)
    end

    -- track the tabs as we build them
    -- local tabButtons = {}

    -- keep track of tab count
    local tabCount = 0

    -- track previous tab key
    local prevTabKey = nil

    -- create tab buttons using PanelTabButtonTemplate
    for tabIndex, tabKey in ipairs(ns.data.tabs.order) do
        -- get global variable friendly tab name
        -- local tabID = ns.tabs.uitabs["varnames"][tabKey]
        --@debug@
        -- ns:Print(("Processing Tab ID: %s (Index: %d, Key: %s, Var Friendly: %s, Label: %s)"):format(tostring(tabKey), tabIndex, tostring(tabKey), tostring(tabID), tostring(ns.tabs.uitabs.tabs[tabKey])))
        --@end-debug@

        -- create the tab button ID
        -- local tabButtonID = ns.gets:GetObjectName("TabButton" .. tabID)
        --@debug@
        -- ns:Print(("Creating Tab Button: %s"):format(tabButtonID))
        --@end-debug@

        -- create variable for button
        -- local button = nil

        -- if tabButtonID doesn't exist create it
        -- if not _G[tabButtonID] then
        if ns.data.tabs.buttons[tabKey] == nil then
            -- use PanelTabButtonTemplate for authentic Collections UI styling
            ns.data.tabs.buttons[tabKey] = CreateFrame("Button", nil, ns.data.ui.tabs.tabframe, "PanelTabButtonTemplate")
            ns.data.tabs.buttons[tabKey]:SetID(tabIndex)
            -- local tabname = ns.tabs.uitabs.tabs[tabKey]
            ns.data.tabs.buttons[tabKey]:SetText(ns.L[tabKey])
            ns.data.tabs.buttonIndex[tabKey] = tabIndex
            -- ns.tabs.uitabs["buttonref"][tabKey] = tabIndex

            -- use PanelTemplates functions for proper tab behavior
            PanelTemplates_TabResize(ns.data.tabs.buttons[tabKey], 0)

            -- set the buttons OnClick event
            ns.data.tabs.buttons[tabKey]:SetScript("OnClick", function(btn)
                --@debug@
                -- ns:Print(("Tab Clicked: %s (ID: %d)"):format(tabname, self:GetID()))
                --@end-debug@
                -- use PanelTemplates to handle tab selection properly
                PanelTemplates_SetTab(ns.data.ui.tabs.tabframe, btn:GetID())

                -- create the content for the tab
                ns.tabs:ShowTabContent(tabKey)
            end)
        -- else
            -- if it already exists just reference it
            -- button = _G[tabButtonID]
        end

        -- if this is the developer tab, hide it unless in dev mode
        if tabKey == "developer" and ns.tabs:GetDevMode() == false then
            ns.data.tabs.buttons[tabKey]:Hide()
        end

        -- position tabs horizontally with proper spacing for Collections style
        if tabIndex == 1 then
            ns.data.tabs.buttons[tabKey]:SetPoint("TOPLEFT", ns.data.ui.frame.main, "BOTTOMLEFT", 11, 2)
        else
            ns.data.tabs.buttons[tabKey]:SetPoint("LEFT", ns.data.tabs.buttons[prevTabKey], "RIGHT", 0, 0)
        end

        -- add button to table
        -- tabButtons[tabIndex] = ns.data.tabs.buttons[tabKey]

        -- count the tabs
        tabCount = tabCount + 1

        -- update previous tag key
        prevTabKey = tabKey
    end

    -- Set up the tab frame with PanelTemplates
    PanelTemplates_SetNumTabs(ns.data.ui.tabs.tabframe, tabCount)

    -- set the proper tab to be selected based on the user's last selection
    local tabIndex = ns.data.tabs.buttonIndex[ns.tabs:GetTab()]
    PanelTemplates_SetTab(ns.data.ui.tabs.tabframe, tabIndex)

    -- show the tab content
    ns.tabs:ShowTabContent(ns.tabs:GetTab())

    -- initialize first tab to users last, if not set to introduction (which is done in GetTab)
    -- self:UpdateTabButtons()

    -- assign buttons to addon global
    -- ns.tabs.uitabs["buttons"] = tabButtons
end

--[[---------------------------------------------------------------------------
    Function:   GetTab
    Purpose:    Get the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ns.tabs:GetTab()
    local tabValue = ns.db.profile[ns.data.currentPlayerServer].mytab or "introduction"
    --@debug@
    -- ns:Print("(GetTab) ID: " .. tostring(tabValue) .. " for " .. tostring(ns.data.currentPlayerServer))
    --@end-debug@
    return tabValue
end

--[[---------------------------------------------------------------------------
    Function:   SetTab
    Purpose:    Set the current selected tab in the options.
-----------------------------------------------------------------------------]]
function ns.tabs:SetTab(key)
    --@debug@
    -- ns:Print("(SetTab) Setting tab to: " .. tostring(key) .. " for " .. tostring(ns.data.currentPlayerServer))
    --@end-debug@

    -- update the current tab
    ns.db.profile[ns.data.currentPlayerServer].mytab = key
end

--[[---------------------------------------------------------------------------
    Function:   CreateTabContentFrame
    Purpose:    Create a standard content frame for a tab.
    Arguments:  tabKey - unique key for the tab (e.g., "about", "introduction", "tagmaint", "toymaint", "developer")
-----------------------------------------------------------------------------]]
function ns.tabs:CreateTabContentFrame(tabKey)
    --@debug@
    -- ns:Print(("(CreateTabContentFrame) Called with tabKey: %s"):format(tostring(tabKey)))
    --@end-debug@

    -- check if nil
    if tabKey == nil then
        self:Print((ns.L["Error: tabKey (%s) provided to CreateTabContentFrame is invalid."]):format(tostring(tabKey)))
        return false
    end

    -- check if content frame exists, if not create it
    if ns.data.ui.tabs[tabKey] == nil then
        -- create the frame
        ns.data.ui.tabs[tabKey] = CreateFrame("Frame", nil, ns.data.ui.frame.main) --, "InsetFrameTemplate")
        ns.data.ui.tabs[tabKey]:SetPoint("TOPLEFT", ns.data.ui.frame.main, "TOPLEFT", 0, -20)
        -- 2 points of Y movement aligns the main frame to the tab content frame...due to the graphical edge I think.
        ns.data.ui.tabs[tabKey]:SetPoint("BOTTOMRIGHT", ns.data.ui.frame.main, "BOTTOMRIGHT", 0, 2)
    end
end