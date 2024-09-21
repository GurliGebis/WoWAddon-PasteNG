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
local ConfigModule = PasteNG:NewModule("ConfigModule")
local DBModule = PasteNG:GetModule("DBModule")
local MinimapModule = PasteNG:GetModule("MinimapModule")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local options = {
    name = "PasteNG",
    handler = ConfigModule,
    type = "group",
    args = {
        generalHeader = {
            order = 1,
            type = "header",
            name = L["General"]
        },
        generalDescription = {
            order = 2,
            type = "description",
            name = L["General settings for PasteNG"]
        },
        minimapIconEnabled = {
            order = 3,
            type = "toggle",
            name = L["Enable Minimap Icon"],
            desc = L["Toggle the minimap icon"],
            get = function()
                return DBModule:GetValue("enableMinimapIcon")
            end,
            set = function(_, val)
                DBModule:SetValue("enableMinimapIcon", val)
                MinimapModule:RefreshMinimapIcon()
            end
        },
        shiftEnterSend = {
            order = 4,
            type = "toggle",
            name = L["Shift-Enter to Send"],
            desc = L["Send the paste with Shift-Enter"],
            get = function()
                return DBModule:GetValue("shift_enter_send")
            end,
            set = function(_, val)
                DBModule:SetValue("shift_enter_send", val)
            end
        },
        positionsHeader = {
            order = 5,
            name = L["Positions and coordinates"],
            type = "header"
        },
        resetCoordinates = {
            order = 6,
            type = "execute",
            width = "double",
            name = L["Reset window size and position"],
            desc = L["Resets the window size and position on screen to the default"],
            func = function()
                local DialogModule = PasteNG:GetModule("DialogModule")
                DialogModule:ResetCoordinates()
            end
        }
    }
}

function ConfigModule:OnInitialize()
    AceConfig:RegisterOptionsTable(addonName, options)
    ConfigModule.OptionsFrame, ConfigModule.CategoryId = AceConfigDialog:AddToBlizOptions(addonName, addonName)
end