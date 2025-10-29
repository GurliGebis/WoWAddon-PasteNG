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
local DialogModule

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

_G.BINDING_HEADER_PASTENG = "PasteNG"
_G.BINDING_NAME_PASTENG_OPEN = L["Open the PasteNG window"]

local keyBindingName_PasteNG_Open = "PASTENG_OPEN"

local function SetKeybinding(bindingName, binding)
    -- Get existing bindings for the key binding and remove them.
    for _, key in ipairs({ GetBindingKey(bindingName) }) do
        if key then
            -- Remove existing binding.
            SetBinding(key)
        end
    end

    -- If ESC was pressed to clear the binding, binding is empty.
    -- In that case, we shouldn't call SetBinding for it.
    -- If we call SetBinding with an empty key, it creates an "empty" binding, which is wrong.
    if binding ~= "" then
        -- Set the new key binding.
        SetBinding(binding, bindingName)
    end

    -- Save the key binding to the current key binding set.
    SaveBindings(GetCurrentBindingSet())
end

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
                return not DBModule.AceDB.profile.minimapIcon.hide
            end,
            set = function(_, val)
                DBModule.AceDB.profile.minimapIcon.hide = not val
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
                DialogModule = DialogModule or PasteNG:GetModule("DialogModule")
                DialogModule:ResetCoordinates()
            end
        },
        keyBindings = {
            order = 7,
            name = KEY_BINDINGS,
            type = "header"
        },
        showWindowKeyBinding = {
            order = 8,
            type = "keybinding",
            width = "double",
            name = L["Open the PasteNG window"],
            desc = L["Create a key binding to open the PasteNG window"],
            get = function()
                return GetBindingKey(keyBindingName_PasteNG_Open)
            end,
            set = function(_, val)
                SetKeybinding(keyBindingName_PasteNG_Open, val)
            end
        },
        sharingHeader = {
            order = 9,
            name = L["Sharing"],
            type = "header"
        },
        sharingDescription = {
            order = 10,
            name = L["Sharing with party / raid members"],
            type = "description"
        },
        enableSharing = {
            order = 11,
            type = "toggle",
            width = "double",
            name = L["Enable sharing with party / raid members"],
            desc = L["When in a group, allow sending and recieving pastes from group members"],
            get = function()
                return DBModule:GetValue("enable_sharing")
            end,
            set = function(_, val)
                DBModule:SetValue("enable_sharing", val)
            end
        },
        disableAnnouncements = {
            order = 12,
            type = "toggle",
            width = "double",
            name = L["Disable announcements"],
            desc = L["Disable announcing presence to party/raid members when joining groups"],
            get = function()
                return DBModule:GetValue("disable_announcements")
            end,
            set = function(_, val)
                DBModule:SetValue("disable_announcements", val)
            end
        }
    }
}

function ConfigModule:OnInitialize()
    AceConfig:RegisterOptionsTable(addonName, options)
    ConfigModule.OptionsFrame, ConfigModule.CategoryId = AceConfigDialog:AddToBlizOptions(addonName, addonName)
end