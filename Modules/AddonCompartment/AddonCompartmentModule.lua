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
local AddonCompartmentModule = PasteNG:NewModule("AddonCompartmentModule")
local MinimapModule = PasteNG:GetModule("MinimapModule")

function PasteNG_OnAddonCompartmentClick(_, button)
    MinimapModule:ButtonClicked(button)
end

function PasteNG_OnAddonCompartmentEnter(_, frame)
    GameTooltip:SetOwner(frame)

    MinimapModule:CreateTooltip(GameTooltip)

    GameTooltip:Show()
end

function PasteNG_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end