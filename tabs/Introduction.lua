--[[ ------------------------------------------------------------------------
	Title: 			Introduction.lua
	Author: 		mrbryo
	Create Date : 	06/13/2025 21:24
	Description: 	Introduction tab for Toys by Function addon.
-----------------------------------------------------------------------------]]

local addonName, ns = ...
ns.intro = {}

function ns.intro:ProcessIntroductionFrame(tabKey)
    -- standard variables
    local padding = ns.data.constants.ui.generic.padding

    -- create the content frame for the tab if it doesn't exist, if it exists then all this content already exists
    ns.tabs:CreateTabContentFrame(tabKey)

    -- create title for instructions frame
    local title = ns.data.ui.tabs[tabKey]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", ns.data.ui.tabs[tabKey], "TOPLEFT", 10, -10)
    title:SetPoint("TOPRIGHT", ns.data.ui.tabs[tabKey], "TOPRIGHT", -10, -10)
    title:SetJustifyH("CENTER")
    title:SetText(ns.L["Introduction"])
end