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
PasteNG = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")

PasteNG.Name = C_AddOns.GetAddOnMetadata(addonName, "Title")
PasteNG.Version = C_AddOns.GetAddOnMetadata(addonName, "Version")

-- Called from keybinding.
function PasteNG:ShowDialog(keyState)
    -- We need to be sure that we catch the key up event.
    -- If we catch the key down event, and people is holding down the keys, the dialog will recieve the inputs.
    if keyState == "up" then
        local DialogModule = PasteNG:GetModule("DialogModule")
        DialogModule:ShowDialog()
    end
end