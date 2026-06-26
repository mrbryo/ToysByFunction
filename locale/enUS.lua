--[[---------------------------------------------------------------------------
    Localization for Action Bar Sync
    Language: English (US)
-----------------------------------------------------------------------------]]

local addonName, ns = ...

local L = setmetatable({}, {
    __index = function(self, key)
        return key  -- fallback: return the key itself
    end,
})
ns.L = L

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

-- Main Frame
L["Sort"] = "Sort"
L["A-Z"] = "A-Z"
L["Z-A"] = "Z-A"
L["Show Toy Tooltips"] = "Show Toy Tooltips"

-- left frame to show filtered toys
L["Filtered List of Toys by Tag:"] = "Filtered List of Toys by Tag:"
L["Tag:"] = "Tag:"
L["No Tag Selected"] = "No Tag Selected"

-- tag maintenance frame
L["Maintain Tags:"] = "Maintain Tags:"
L["Prevent Tag Deletion if Toys Assigned"] = "Prevent Tag Deletion if Toys Assigned"
L["If checked, tags assigned to toys will NOT be deleted. Otherwise, tags are deleted but associated toys moved to the uncategorized tag."] = "If checked, tags assigned to toys will NOT be deleted. Otherwise, tags are deleted but associated toys moved to the uncategorized tag."
L["New Tag Above"] = "New Tag Above"
L["New Tag Below"] = "New Tag Below"
L["Rename Tag"] = "Rename Tag"
L["Delete Tag"] = "Delete Tag"
L["Tag Edits:"] = "Tag Edits:"

-- Mini Map Button
L["Left-click open main config window."] = "Left-click open main config window."
L["Right-click for function window."] = "Right-click for function window."
L["Issue with addon options panel, cannot open settings. If persists please open a ticket."] = "Issue with addon options panel, cannot open settings. If persists please open a ticket."

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