--[[
    Copyright (C) 2024-2026 GurliGebis

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
        enable_sharing = "true",
        disable_announcements = "false"
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
        for _ in pairs(self:GetProfile().savedPastes) do
            return true
        end

        return false
    end

    function DBModule:DoesPasteExist(name)
        local profile = self:GetProfile()

        return profile.savedPastes[name] ~= nil
    end

    function DBModule:ListSavedPastes()
        local result = {}

        for k in pairs(self:GetProfile().savedPastes) do
            result[#result+1] = k
        end

        table.sort(result)

        return result
    end

    function DBModule:LoadPaste(name)
        local encoded = self:GetProfile().savedPastes[name]
        return encoded and base64_dec(encoded) or nil
    end

    function DBModule:SavePaste(name, text)
        local encoded = base64_enc(text)

        self:GetProfile().savedPastes[name] = encoded
    end

    function DBModule:DeletePaste(name)
        self:GetProfile().savedPastes[name] = nil
    end

    function DBModule:ExportAllPastes()
        local pastes = {}
        local profile = self:GetProfile()

        for name, encodedText in pairs(profile.savedPastes) do
            -- Decode the saved paste and re-encode it for export
            local decodedText = base64_dec(encodedText)
            pastes[name] = decodedText
        end

        local AceSerializer = LibStub("AceSerializer-3.0")
        local serializedData = AceSerializer:Serialize(pastes)
        return base64_enc(serializedData)
    end

    function DBModule:ImportAllPastes(importData)
        local AceSerializer = LibStub("AceSerializer-3.0")

        -- Decode the base64 data
        local decodedData = base64_dec(importData)
        if not decodedData or decodedData == "" then
            return false, "Invalid import data"
        end

        -- Deserialize the data
        local success, pastes = AceSerializer:Deserialize(decodedData)
        if not success or type(pastes) ~= "table" then
            return false, "Failed to parse import data"
        end

        local importCount = 0
        local profile = self:GetProfile()

        -- Import each paste
        for name, text in pairs(pastes) do
            if type(name) == "string" and type(text) == "string" and name ~= "" then
                profile.savedPastes[name] = base64_enc(text)
                importCount = importCount + 1
            end
        end

        return true, importCount
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