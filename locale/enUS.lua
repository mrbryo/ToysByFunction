--[[---------------------------------------------------------------------------
    Localization for Action Bar Sync
    Language: English (US)
-----------------------------------------------------------------------------]]

-- make sure locales variable exists
if not ToysByFunction.locales then
    ToysByFunction.locales = {}
end

-- add the locale
ToysByFunction.locales["enUS"] = {}
local L = ToysByFunction.locales["enUS"]

-- following line is replaced when packaged through curseforge using their localization tool
--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="english")@

--@do-not-package@ 
--[[ leaving all for development purposes, export from curseforge ]]

-- Development
L["DB Initialization"] = "DB Initialization"
L["Error: Frame has no name, cannot store position."] = "Error: Frame has no name, cannot store position."

-- Generic
L["Toys by Function"] = "Toys by Function"
L["Unknown"] = "Unknown"
L["Yes"] = "Yes"

-- Events
L["Player Logging Out..."] = "Player Logging Out..."

-- Filter Bar
L["Tag:"] = "Tag:"
L["No Tag Selected"] = "No Tag Selected"

-- Mini Map Button
L["Click to open Toys by Function"] = "Click to open Toys by Function"
L["Right-click for Options"] = "Right-click for Options"
L["Toys by Function allows you to manage your toys by what action they perform."] = "Toys by Function allows you to manage your toys by what action they perform."
L["You can open the Toys by Function interface using the following slash commands or, if visible, left clicking the mini-map button:"] = "You can open the Toys by Function interface using the following slash commands or, if visible, left clicking the mini-map button:"
L["Open Toys by Function"] = "Open Toys by Function"
L["Show Mini-map Button"] = "Show Mini-map Button"
L["Note: LibDBIcon-1.0 is missing or one of its dependencies (LibStub and LibDataBroker), therefore, mini-map button cannot be created. Also, not sure why, but LibDBIcon-1.0 may not show up in the addon list even if it is installed."] = "Note: LibDBIcon-1.0 is missing or one of its dependencies (LibStub and LibDataBroker), therefore, mini-map button cannot be created. Also, not sure why, but LibDBIcon-1.0 may not show up in the addon list even if it is installed."

-- Tags
L["buff"] = "Buff"
L["combat"] = "Combat"
L["costume"] = "Costume"
L["fireworks"] = "Fireworks"
L["fishing"] = "Fishing"
L["food_and_drink"] = "Food & Drink"
L["healing"] = "Healing"
L["mount"] = "Mount"
L["music"] = "Music"
L["pet"] = "Pet"
L["prop"] = "Prop"
L["social"] = "Social"
L["teleport"] = "Teleport"
L["transformation"] = "Transformation"
L["uncategorized"] = "Uncategorized"
L["vanity"] = "Vanity"
L["visual_effect"] = "Visual Effect"

--@end-do-not-package@