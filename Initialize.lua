--[[ ------------------------------------------------------------------------
	Title: 			Initialize.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All initialization needed for the addon to function.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

-- ─── Secret Value helper (Midnight 12.0) ─────────────────
ns.SECRETS_ENABLED = type(issecretvalue) == "function"
function ns.SafeValue(val, fallback)
    if ns.SECRETS_ENABLED and issecretvalue(val) then return fallback end
    return val
end

-- ─── Table-dispatch event dispatcher ─────────────────────
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then handler(self, event, ...) end
end)
local function RegisterEvent(event, handler)
    eventHandlers[event] = handler
    eventFrame:RegisterEvent(event)
end
ns.RegisterEvent = RegisterEvent

-- ─── ADDON_LOADED: SavedVariables init + slash commands ──
RegisterEvent("ADDON_LOADED", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    eventFrame:UnregisterEvent("ADDON_LOADED")

    ToysByFunctionDB = ToysByFunctionDB or {}
	if ns.defaults then
		for key, defaultValue in pairs(ns.defaults) do
			if ToysByFunctionDB[key] == nil then ToysByFunctionDB[key] = defaultValue end
		end
    end
    ns.db = ToysByFunctionDB

    --[[ slash command must be global to work correctly; I know there is another way to do it but not important right now. ]]
	local slashKey = "TOYSBYFUNCTION"
	_G["SLASH_" .. slashKey .. "1"] = "/toysbyfunction"
	_G["SLASH_" .. slashKey .. "2"] = "/tbf"
    SlashCmdList[slashKey] = function(input)
        local cmd = strlower(strtrim(input or ""))
        if cmd == "config" or cmd == "options" then
            if ns.data.settingsCategoryID then Settings.OpenToCategory(ns.settingsCategoryID) end
        elseif cmd == "toggle" then
            ns.db.enabled = not ns.db.enabled
        elseif cmd == "reset" then
            for key, value in pairs(ns.defaults) do ns.db[key] = value end
		elseif cmd == "enablemodedeveloper" then
			if not ns:GetDevMode() or ns:GetDevMode() == false then
                ns:EnableDevelopment()
            else
                ns:DisableDevelopment()
            end
        else
            print("/toysbyfunction config — Open Settings")
            print("/toysbyfunction toggle — Enable/Disable")
            print("/toysbyfunction reset  — Reset settings to defaults.")
			--@debug@
			print("/toysbyfunction enablemodedeveloper — Toggle development mode.")
			--@end-debug@
        end
    end

    if ns.RegisterSettings then ns:RegisterSettings() end

	--@debug@
	ns:Print(("Addon Loaded - %s"):format(addonName))
	--@end-debug@
end)

-- instantiate variable to hold functionality!
ns.data = {
	-- always set to false so the event can set it to true
	hasPlayerEnteredWorld = false,
	modules = {},
	events = {},
	name = "@addon-name@",
	version = "@project-version@",
	prefix = "ToysByFunctionUIObject",
	optionID = "ToysByFunction",
	tagAttrName = "TBFTagID",

	-- addon ui columns
	columns = {},

	-- data providers
	dp = {},

	-- addon access to UI elements
	ui = {
		label = {},
		editbox = {},
		scroll = {},
		group = {},
		dropdown = {},
		frame = {},
		checkbox = {},
		height = {},
	},

	-- track popups
	popups = {},

	-- colors
	constants = {
		colors = {
			white = "|cffffffff",
			yellow = "|cffffff00",
			green = "|cff00ff00",
			blue = "|cff0000ff",
			purple = "|cffff00ff",
			red = "|cffff0000",
			orange = "|cffff7f00",
			gray = "|cff7f7f7f",
			label = "|cffffd100"
		},
		ui = {
			checkbox = {
				size = 16,
				padding = 5
			},
			generic = {
				padding = 10
			},
			mainFrame = {
				minWidth = 600,
				minHeight = 600
			},
		},
		objectNames = {
			tabContentFrame = "TabContentFrame",
		},
	},

	-- track timers
	timers = {},
}

--[[--------------------------------------------------------------------------
	Event:	PLAYER_LOGIN
	Purpose:	Start features once the world is ready.
-----------------------------------------------------------------------------]]
RegisterEvent("PLAYER_LOGIN", function(self, event, ...)
	-- get event parameters
	local isInitialLogin, isReload = ...

	-- trigger Enable function if addon enabled; this is where the addon starts doing its thing
    if ns.db.enabled and ns.Enable then ns:Enable() end

	--@debug@
	ns:Print(("Event Triggered - %s, isInitialLogin: %s, isReload: %s"):format(event, tostring(isInitialLogin) and ns.L["Yes"] or ns.L["No"], tostring(isReload) and ns.L["Yes"] or ns.L["No"]))
	--@end-debug@

	-- instantiate player keys
	ns.sets:SetKeyPlayerServerSpec()
	ns.sets:SetKeyPlayerServer()

	-- run db initializer
	ns:InstantiateDB()
        
	-- update global variable for tracking if event has triggered
	ns.data.hasPlayerEnteredWorld = true
end)

--[[--------------------------------------------------------------------------
	Event:		PLAYER_LOGOUT
	Purpose:	Save any necessary data before the player logs out.
-----------------------------------------------------------------------------]]
RegisterEvent("PLAYER_LOGOUT", function(self, event, ...)
	--@debug@
	ns:Print(("Event Triggered - %s"):format(event))
	--@end-debug@
	ns:EventPlayerLogout()
end)

--[[--------------------------------------------------------------------------
	Event:		VARIABLES_LOADED
	Purpose:	Handle any necessary actions after variables are loaded.
-----------------------------------------------------------------------------]]
RegisterEvent("VARIABLES_LOADED", function(self, event, ...)
	--@debug@
	ns:Print(("Event Triggered - %s"):format(event))
	--@end-debug@
end)

--[[---------------------------------------------------------------------------
    Function:   EventPlayerLogout
    Purpose:    Handle functionality which is best or must wait for the PLAYER_LOGOUT event.
-----------------------------------------------------------------------------]]
function ns:EventPlayerLogout()
    --@debug@
    if ns.gets:GetDevMode() == true then ns:Print(ns.L["Player Logging Out..."]) end
    --@end-debug@
end

--[[---------------------------------------------------------------------------
	Function:   Print
	Purpose:    Standard print function for the addon.
-----------------------------------------------------------------------------]]
function ns:Print(msg)
	if msg then
		print(("%s%s:|r %s"):format("|cffffd100", ns.L["Toys by Function"], tostring(msg)))
	end
end

--[[---------------------------------------------------------------------------
	Function:   Timer
	Purpose:    Create a timer to call a function after a delay.
-----------------------------------------------------------------------------]]
function ns:Timer(name, delay, func)
	-- if timer already exists; clear and cancel it first
	if ns.data.timers[name] then
		ns.data.timers[name]:Cancel()
		ns:TimerClear(name)
	end

	-- trigger new timer
	ns.data.timers[name] = C_Timer.After(delay, func)
end

--[[---------------------------------------------------------------------------
	Function:   TimerClear
	Purpose:    Clear a timer by name.
-----------------------------------------------------------------------------]]
function ns:TimerClear(name)
	if ns.data.timers[name] then
		ns.data.timers[name] = nil
	end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDB
    Purpose:    Ensure the DB has all the necessary values. Can run anytime to check and fix all data with default values.
-----------------------------------------------------------------------------]]
function ns:InstantiateDB()
    --@debug@
    if self.gets:GetDevMode() == true then
        self:Print(ns.L["DB Initialization"])
    end
    --@end-debug@
    -- make sure player key is set
    self.sets:SetKeyPlayerServerSpec()
    self.sets:SetKeyPlayerServer()

    -- instantiate db
    self:InstantiateDBProfile()
    self:InstantiateDBGlobal()
    self:InstantiateDBChar()
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBChar
    Purpose:    Ensure the character specific DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ns:InstantiateDBChar(barID)
    -- create the character structure
    if not ns.char then
        ns.char = {}
    end

    -- currentBarData holds the last scan of data fetched from the action bars for the current character; hence stored in char
    if not ns.char[ns.data.currentPlayerServerSpec] then
        ns.char[ns.data.currentPlayerServerSpec] = {}
    end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBGlobal
    Purpose:    Ensure the global DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ns:InstantiateDBGlobal(barID)
    -- instantiate global structure
    if ns.db.global == nil then
        ns.db.global = {}
    end

    -- create toys data structure
    if ns.db.global.toys == nil then
        ns.db.global.toys = {}
    end
    if ns.db.global.toys.byItemId == nil then
        ns.db.global.toys.byItemId = {}
    end
    if ns.db.global.toys.byTag == nil then
        ns.db.global.toys.byTag = {}
    end
    if ns.db.global.toys.order == nil then
        ns.db.global.toys.order = {}
    end

	-- if tags is empty, create it
	if ns.db.global.tags == nil then
		ns.db.global.tags = {}
	end

	-- if order is empty create it
	if ns.db.global.tags.order == nil then
		ns.db.global.tags.order = {}
	end
end

--[[---------------------------------------------------------------------------
    Function:   InstantiateDBProfile
    Purpose:    Ensure the profile DB structure exists and has all necessary values.
-----------------------------------------------------------------------------]]
function ns:InstantiateDBProfile()
    -- make sure the current player key is set
    if ns.data.currentPlayerServer == nil then return false end

    -- create profile node if missing
    if ns.db.profile == nil then ns.db.profile = {} end

    -- add current character if missing
    if ns.db.profile[ns.data.currentPlayerServer] == nil then
        ns.db.profile[ns.data.currentPlayerServer] = {}
    end

    -- initialize UI settings if they don't exist
    if ns.db.profile[ns.data.currentPlayerServer].ui == nil then
        ns.db.profile[ns.data.currentPlayerServer].ui = {}
    end
    if ns.db.profile[ns.data.currentPlayerServer].ui.positions == nil then
        ns.db.profile[ns.data.currentPlayerServer].ui.positions = {}
    end

    -- selected tag default
    if ns.db.profile[ns.data.currentPlayerServer].selectedTag == nil then
        ns.db.profile[ns.data.currentPlayerServer].selectedTag = "none"
    end

    -- toy sorting order defaults; default to A-Z sorting if not set
    if ns.db.profile[ns.data.currentPlayerServer].toySortingOrder == nil then
        ns.db.profile[ns.data.currentPlayerServer].toySortingOrder = {}
    end
    if ns.db.profile[ns.data.currentPlayerServer].toySortingOrder.main == nil then
        ns.db.profile[ns.data.currentPlayerServer].toySortingOrder.main = "az"
    end

    -- show tooltips; main frame is set to true by default
    if ns.db.profile[ns.data.currentPlayerServer].showTooltips == nil then
        ns.db.profile[ns.data.currentPlayerServer].showTooltips = {}
    end
    if ns.db.profile[ns.data.currentPlayerServer].showTooltips.main == nil then
        ns.db.profile[ns.data.currentPlayerServer].showTooltips.main = true
    end

    -- create initial value for storing custom tag settings
    if ns.db.profile[ns.data.currentPlayerServer].tags == nil then
        ns.db.profile[ns.data.currentPlayerServer].tags = {}
    end

    -- create inital value for storing custom tags
    if ns.db.profile[ns.data.currentPlayerServer].tags.custom == nil then
        ns.db.profile[ns.data.currentPlayerServer].tags.custom = {}
    end

    -- create initial value for storing custom tags and/or order
    if ns.db.profile[ns.data.currentPlayerServer].tags.order == nil then
        ns.db.profile[ns.data.currentPlayerServer].tags.order = {}
    end
end