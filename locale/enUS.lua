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
L["OK"] = "OK"
L["Cancel"] = "Cancel"
L["Note: "] = "Note: "

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
L["No Tags"] = "No Tags"

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

-- languages
L["German"] = "German"
L["Spanish (Spain)"] = "Spanish (Spain)"
L["Spanish (Mexico)"] = "Spanish (Mexico)"
L["French"] = "French"
L["Italian"] = "Italian"
L["Korean"] = "Korean"
L["Portuguese (Brazil)"] = "Portuguese (Brazil)"
L["Russian"] = "Russian"
L["Chinese (Simplified)"] = "Chinese (Simplified)"
L["Chinese (Traditional)"] = "Chinese (Traditional)"

-- tab processing
L["Error: tabKey (%s) provided to ProcessTabContentFrame is invalid."] = "Error: tabKey (%s) provided to ProcessTabContentFrame is invalid."

-- tabs/Tabs.lua
L["about"] = "About"
L["introduction"] = "Introduction"
L["tagmaint"] = "Maintain Tags"
L["toymaint"] = "Maintain Toys"

-- tabs/About.lua
L["Author"] = "Author"
L["Version"] = "Version"
L["If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"] = "If you find this addon useful, please consider supporting its development through one of these options below. Addon development can take hours for the simplest complexity to months for very complex. Thank you for your support!"
L["Patreon"] = "Patreon"
L["If you like this addon and want to support me, please consider becoming a patron."] = "If you like this addon and want to support me, please consider becoming a patron."
L["Buy Me a Coffee"] = "Buy Me a Coffee"
L["If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."] = "If you encounter any issues or bugs, please report them on the issues page linked below. I will do my best to address them as soon as time permits."
L["Issues"] = "Issues"
L["Another support option is to help with localizations. If you are fluent in other language(s) and would like to help translate this addon, please use the link below. I'm still learning about CurseForge's localization system. My hope, as translations are submitted, they are added automatically and the project deploys a new version. If not, please let me know through a ticket using the issues link above."] = "Another support option is to help with localizations. If you are fluent in other language(s) and would like to help translate this addon, please use the link below. I'm still learning about CurseForge's localization system. My hope, as translations are submitted, they are added automatically and the project deploys a new version. If not, please let me know through a ticket using the issues link above."
L["Localization"] = "Localization"
L["Help translate this addon into your language."] = "Help translate this addon into your language."
L["Translators"] = "Translators"

-- tabs/Introduction.lua
L["Introduction"] = "Introduction"

-- tabs/TagMaint.lua
L["Maintain Tags"] = "Maintain Tags"
L["Prevent Tag Deletion if Toys Assigned"] = "Prevent Tag Deletion if Toys Assigned"
L["If the option '%s' is checked, the tag will NOT be deleted."] = "If the option '%s' is checked, the tag will NOT be deleted."
L["Insert Above"] = "Insert Above"
L["Insert Below"] = "Insert Below"
L["Rename Tag"] = "Rename Tag"
L["Delete Tag"] = "Delete Tag"
L["Clear Data"] = "Clear Data"
L["Tag Edits:"] = "Tag Edits:"
L["Pick a tag:"] = "Pick a tag:"
L["Instructions:"] = "Instructions:"
L["ID may only contain lowercase letters and numbers. Name may only contain mixed case letters, spaces and numbers. Both have a max length of 20 characters."] = "ID may only contain lowercase letters and numbers. Name may only contain mixed case letters, spaces and numbers. Both have a max length of 20 characters."
L["This will reorder all tags in alphabetical order based on name. Proceed?"] = "This will reorder all tags in alphabetical order based on name. Proceed?"

-- tabs/TagMaint.lua - new tag
L["ID:"] = "ID:"
L["Name:"] = "Name:"
L["Enter a new Name for the tag. Name may only contain mixed case letters, spaces and numbers and have a max length of 20 characters."] = "Enter a new Name for the tag. Name may only contain mixed case letters, spaces and numbers and have a max length of 20 characters."
L["Tag ID: "] = "Tag ID: "
L["Error: ID may only contain lowercase letters and numbers."] = "Error: ID may only contain lowercase letters and numbers."
L["Error: ID may only be 1 to 20 characters."] = "Error: ID may only be 1 to 20 characters."
L["Error: Name may only contain mixed case letters, spaces and numbers."] = "Error: Name may only contain mixed case letters, spaces and numbers."
L["Error: Name may only be 1 to 20 characters."] = "Error: Name may only be 1 to 20 characters."

-- tabs/TagMaint.lua - delete tag
-- next line uses L["uncategorized"] when being used in a dialog
L["is required for the addon to function correctly. Can't delete it."] = "is required for the addon to function correctly. Can't delete it."

-- tabs/ToyMaint.lua
L["No Tag Selected"] = "No Tag Selected"
L["Toy Functions"] = "Toy Functions"
L["Move Toys"] = "Move Toys"
L["Last Log"] = "Last Log"

--@end-do-not-package@