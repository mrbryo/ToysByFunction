--[[ ------------------------------------------------------------------------
	Title: 			Options.lua
	Author: 		mrbryo
	Create Date : 	2026-Jun-21
	Description: 	Generate options panel for Blizzard's Interface Options system.
-----------------------------------------------------------------------------]]

local addonName, ns = ...

-- ─── Settings panel (Blizzard Settings API) ──────────────
function ns:RegisterSettings()
    local category = Settings.RegisterCanvasLayoutCategory(
        ns:CreateOptionsPanel(), addonName
    )
    Settings.RegisterAddOnCategory(category)
    ns.data.settingsCategoryID = category:GetID()
end

--[[---------------------------------------------------------------------------
    Function:   CreateOptionsPanel
    Purpose:    Create a single options pane for the Interface Options.
    Note:       This function should be called after the mini-map button is created in order to get proper visibility status.
-----------------------------------------------------------------------------]]
function ns:CreateOptionsPanel()
    -- create the main options panel frame
    local panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
    panel.name = ns.L["Toys by Function"] or "Toys by Function"

    -- create title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText(ns.L["Toys by Function"] or "Toys by Function")

    -- create description
    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    description:SetPoint ("RIGHT", panel, "RIGHT", -16, 0)
    description:SetJustifyH("LEFT")
    description:SetWordWrap(true)
    description:SetText(ns.L["Toys by Function allows you to manage your toys by what action they perform."] .. "\n\n" .. ns.L["You can open the Toys by Function interface using the following slash commands or, if visible, left clicking the mini-map button:"] .. "\n\n - /toysbyfunction\n - /tbf")

    -- create button to open the addon
    local openButton = CreateFrame("Button", "ToysByFunctionOpenButton", panel, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -24)
    openButton:SetSize(150, 22)
    openButton:SetText(ns.L["Open Toys by Function"] or "Open Toys by Function")
    openButton:SetScript("OnClick", function()
        self:ShowUI()
        -- Close the settings panel properly using WoW's UI system
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
    end)

    -- add to Interface Options (modern system only)
    -- local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)

    -- must set the category ID
    -- category.ID = self.optionID
    -- Settings.RegisterAddOnCategory(category)

    -- store category reference for opening later
    -- panel.optionsCategory = category

    -- store panel reference globally for minimap button access
    -- self.optionsPanel = panel
    return panel
end