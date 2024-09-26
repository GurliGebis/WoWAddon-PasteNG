--[[
    Copyright (C) 2024 GurliGebis

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

local addonName, _ = ...
local PasteNG = LibStub("AceAddon-3.0"):GetAddon(addonName)
local MinimapModule = PasteNG:NewModule("MinimapModule")
local DBModule = PasteNG:GetModule("DBModule")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

do
    local MinimapIcon = nil

    function MinimapModule:OnInitialize()
        -- Create the minimap icon.
        MinimapModule:CreateMinimapIcon()

        -- Refresh it's status.
        MinimapModule:RefreshMinimapIcon()
    end

    function MinimapModule:ToggleMinimapIcon()
        -- Invert the hide status.
        DBModule.AceDB.profile.minimapIcon.hide = not DBModule.AceDB.profile.minimapIcon.hide

        -- Refresh the minimap icon.
        MinimapModule:RefreshMinimapIcon()
    end

    function MinimapModule:RefreshMinimapIcon()
        -- Refresh the minimap icon.
        MinimapIcon:Refresh(addonName)
    end

    function MinimapModule:CreateTooltip(tooltip)
        tooltip:AddLine("PasteNG")
        tooltip:AddLine("|cffffff00" .. L["Left Click"] .. "|r " .. L["to show window"])
        tooltip:AddLine("|cffffff00" .. L["Right Click"] .. "|r " .. L["to open options"])
    end
    
    function MinimapModule:ButtonClicked(button)
        if button == "LeftButton" then
            -- Show the PasteNG dialog
            local DialogModule = PasteNG:GetModule("DialogModule")
            DialogModule:ShowDialog()
        else
            -- Show config dialog
            local ConfigModule = PasteNG:GetModule("ConfigModule")
            Settings.OpenToCategory(ConfigModule.OptionsFrame.name)
        end
    end

    function MinimapModule:CreateMinimapIcon()
        local LibDataBroker = LibStub("LibDataBroker-1.1", true)
        MinimapIcon = LibDataBroker and LibStub("LibDBIcon-1.0", true)

        -- If LibDataBroker is not available, we cannot create the minimap button.
        if LibDataBroker == nil then
            return
        end

        -- Create the minimap button / data broker object.
        local minimapButton = LibDataBroker:NewDataObject(addonName, {
            type = "launcher",
            text = "PasteNG",
            icon = "Interface\\Icons\\inv_scroll_08",
            OnClick = function(_, button)
                MinimapModule:ButtonClicked(button)
            end,
            OnTooltipShow = function(tooltip)
                MinimapModule:CreateTooltip(tooltip)
            end,
            OnLeave = HideTooltip
        })

        -- Register the minimap button / data broker object.
        if MinimapIcon then
            MinimapIcon:Register(addonName, minimapButton, DBModule.AceDB.profile.minimapIcon)
        end
    end
end