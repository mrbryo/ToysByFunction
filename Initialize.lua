--[[ ------------------------------------------------------------------------
	Title: 			Initialize.lua
	Author: 		mrbryo
	Create Date : 	11/16/2024 3:01:25 PM
	Description: 	All initialization needed for the addon to function.
-----------------------------------------------------------------------------]]

-- instantiate variable to hold functionality!
ToysByFunction = {
	-- always set to false so the event can set it to true
	hasPlayerEnteredWorld = false,
	modules = {},
	events = {},
	name = "@addon-name@",
	version = "@project-version@",
	prefix = "ToysByFunctionUIObject",
	optionID = "ToysByFunction",

	-- addon ui columns
	columns = {},

	-- track minimap button issues
	minimap = {
		libdbiconStatus = true,
		libdbStatus = true,
		libstubStatus = true,
	},

	-- addon access to UI elements
	ui = {
		label = {},
		editbox = {},
		scroll = {},
		group = {},
		dropdown = {},
		frame = {},
		checkbox = {},
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

	-- ui tabs
	uitabs = {
		["order"] = {},
		["varnames"] = {},
		["buttons"] = {},
		["buttonref"] = {},
		["tabframe"] = {},
	},

	-- track timers
	timers = {},
}

-- initialize the main db
if not ToysByFunctionDB then
	ToysByFunctionDB = {}
end

--[[ slash command must be global to work correctly; I know there is another way to do it but not important right now. ]]

-- register slash commands
SLASH_TOYSBYFUNCTION1 = "/toysbyfunction"
SLASH_TOYSBYFUNCTION2 = "/tbf"
 
-- register slash command function
SlashCmdList.TOYSBYFUNCTION = function(msg, editBox)
	ToysByFunction:SlashCommand(msg)
end

--[[---------------------------------------------------------------------------
	Function:   AddModule
	Purpose:    Add a module to the addon.
-----------------------------------------------------------------------------]]
function ToysByFunction:AddModule(name, module)
	local module = {}
	module.name = name
	module.parent = self
	self.modules[name] = module
	return module
end

--[[---------------------------------------------------------------------------
	Function:   GetModule
	Purpose:    Retrieve a module from the addon.
-----------------------------------------------------------------------------]]
function ToysByFunction:GetModule(name)
	return self.modules[name]
end

--[[---------------------------------------------------------------------------
	Function:   Print
	Purpose:    Standard print function for the addon.
-----------------------------------------------------------------------------]]
function ToysByFunction:Print(msg)
	if msg then
		print(("%s%s:|r %s"):format("|cffffd100", ToysByFunction.L["Toys by Function"], tostring(msg)))
	end
end

--[[---------------------------------------------------------------------------
	Function:   RegisterEvent
	Purpose:    Register new events with in the addon.
-----------------------------------------------------------------------------]]
function ToysByFunction:RegisterEvent(event, handler)
	--@debug@
	-- self:Print(("Registering Event: %s"):format(event))
	--@end-debug@
	self.events[event] = handler or function() end
	self.eventFrame:RegisterEvent(event)
end

--[[---------------------------------------------------------------------------
	Function:   Timer
	Purpose:    Create a timer to call a function after a delay.
-----------------------------------------------------------------------------]]
function ToysByFunction:Timer(name, delay, func)
	-- if timer already exists; clear and cancel it first
	if ToysByFunction.timers[name] then
		ToysByFunction.timers[name]:Cancel()
		ToysByFunction.TimerClear(name)
	end

	-- trigger new timer
	ToysByFunction.timers[name] = C_Timer.After(delay, func)
end

--[[---------------------------------------------------------------------------
	Function:   TimerClear
	Purpose:    Clear a timer by name.
-----------------------------------------------------------------------------]]
function ToysByFunction:TimerClear(name)
	if ToysByFunction.timers[name] then
		ToysByFunction.timers[name] = nil
	end
end

--[[---------------------------------------------------------------------------
	Function:   UnregisterEvent
	Purpose:    Unregister events within the addon.
-----------------------------------------------------------------------------]]
function ToysByFunction:UnregisterEvent(event)
	self.events[event] = nil
	self.eventFrame:UnregisterEvent(event)
end

--[[---------------------------------------------------------------------------
	Initialize addon loaded event.
-----------------------------------------------------------------------------]]
ToysByFunction.eventFrame = CreateFrame("Frame")
ToysByFunction.eventFrame:SetScript("OnEvent", function(self, event, ...)
	-- NOTE: Can't use self on any functions or variables...must use addon variable for a function parameter to work correctly here since this is a function passed as a parameter.

	-- trigger function handler assigned to the registered event
	ToysByFunction.events[event](self, event, ...)
end)