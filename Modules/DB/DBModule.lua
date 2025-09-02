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
local DBModule = PasteNG:NewModule("DBModule")

local defaultOptions = {
    profile =  {
        mainFramePosition = {},
        minimapIcon = {
            hide = false
        },
        savedPastes = {},
        selected_target = CHAT_DEFAULT,
        selected_target_name = "",
        shift_enter_send = "false",
        enable_sharing = "true"
    }
}

do
    function DBModule:OnInitialize()
        self.AceDB = LibStub("AceDB-3.0"):New("PasteNGDB", defaultOptions, true)

        self:MigrateProfile()
    end

    function DBModule:GetProfile()
        return self.AceDB.profile
    end

    function DBModule:GetValue(key)
        local value = self:GetProfile()[key] or defaultOptions.profile[key]

        if value == "true" then
            return true
        elseif value == "false" then
            return false
        else
            return value
        end
    end

    function DBModule:SetValue(key, value)
        if value == defaultOptions.profile[key] then
            self:GetProfile()[key] = nil
        else
            if value == nil then
                self:GetProfile()[key] = "false"
            else
                self:GetProfile()[key] = tostring(value)
            end
        end
    end

    function DBModule:AnySavedPastes()
        local list = self:ListSavedPastes()

        return #list > 0
    end

    function DBModule:DoesPasteExist(name)
        local profile = self:GetProfile()

        return profile.savedPastes[name] ~= nil
    end

    function DBModule:ListSavedPastes()
        local profile = self:GetProfile()
        local result = {}

        for k, _ in pairs(profile.savedPastes) do
            tinsert(result, k)
        end

        table.sort(result)

        return result
    end

    function DBModule:LoadPaste(name)
        local encoded = self:GetProfile()["savedPastes"][name]

        if not encoded then
            return nil
        end

        return base64_dec(encoded)
    end

    function DBModule:SavePaste(name, text)
        local encoded = base64_enc(text)

        self:GetProfile()["savedPastes"][name] = encoded
    end

    function DBModule:DeletePaste(name)
        self:GetProfile()["savedPastes"][name] = nil
    end
end

do
    local function GetDataVersion(profile)
        return profile.dataVersion or 0
    end

    local function MigrateMinimapIcon(profile)
        -- Make sure minimapIcon isn't nil
        profile.minimapIcon = profile.minimapIcon or {}

        -- Migrate the old minimap icon setting
        profile.minimapIcon.hide = profile.enableMinimapIcon == "false"

        -- Remove the old setting
        profile.enableMinimapIcon = nil

        -- Update the data version
        profile.dataVersion = 1
        return GetDataVersion(profile)
    end

    function DBModule:MigrateProfile()
        local profile = self:GetProfile()
        local version = GetDataVersion(profile)

        if version < 1 then
            version = MigrateMinimapIcon(profile)
        end
    end
end