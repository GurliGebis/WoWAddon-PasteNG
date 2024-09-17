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
        if DBModule:GetValue("enableMinimapIcon") then
            MinimapModule:CreateMinimapIcon()
        end

        MinimapModule:RefreshMinimapIcon()
    end

    function MinimapModule:ShowIcon()
        if MinimapIcon == nil then
            self:CreateMinimapIcon()
        end

        MinimapIcon:Show("PasteNG")
    end

    function MinimapModule:HideIcon()
        if MinimapIcon == nil then
            return
        end

        MinimapIcon:Hide("PasteNG")
    end

    function MinimapModule:ToggleMinimapIcon()
        DBModule:SetValue("enableMinimapIcon", not DBModule:GetValue("enableMinimapIcon"))

        MinimapModule:RefreshMinimapIcon()
    end

    function MinimapModule:RefreshMinimapIcon()
        if DBModule:GetValue("enableMinimapIcon") then
            MinimapModule:ShowIcon()
        else
            MinimapModule:HideIcon()
        end
    end

    function MinimapModule:CreateMinimapIcon()
        local LibDataBroker = LibStub("LibDataBroker-1.1", true)
        MinimapIcon = LibDataBroker and LibStub("LibDBIcon-1.0", true)

        if LibDataBroker == nil then
            return
        end

        local minimapButton = LibDataBroker:NewDataObject("PNGBtn", {
            type = "launcher",
            text = "PasteNG",
            icon = "Interface\\Icons\\inv_scroll_08",
            OnClick = function(_, button)
                if button == "LeftButton" then
                    -- Show the PasteNG dialog
                    local DialogModule = PasteNG:GetModule("DialogModule")
                    DialogModule:ShowDialog()
                else
                    -- Show config dialog
                    local ConfigModule = PasteNG:GetModule("ConfigModule")
                    Settings.OpenToCategory(ConfigModule.OptionsFrame.name)
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("PasteNG")
                tooltip:AddLine("|cffffff00" .. L["Left Click"] .. "|r " .. L["to show window"])
                tooltip:AddLine("|cffffff00" .. L["Right Click"] .. "|r " .. L["to open options"])
            end,
            OnLeave = HideTooltip
        })

        if MinimapIcon then
            DBModule.AceDB.global.minimap = DBModule.AceDB.global.minimap or {}
            MinimapIcon:Register("PasteNG", minimapButton, DBModule.AceDB.global.minimap)
        end
    end
end