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
        deletedPastes = {},
        selected_target = CHAT_DEFAULT,
        selected_target_name = "",
        shift_enter_send = "false",
        ignore_comment_lines = "true",
        enable_sharing = "true",
        disable_announcements = "false"
    }
}

do
    local letters = "abcdefghijklmnopqrstuvwxyz"

    local function GenerateUniqueName(baseName, existsFunc)
        if not existsFunc(baseName) then
            return baseName
        end

        local name

        repeat
            local suffix = ""

            for _ = 1, 5 do
                local index = math.random(1, #letters)
                suffix = suffix .. string.sub(letters, index, index)
            end

            name = baseName .. "-" .. suffix
        until not existsFunc(name)

        return name
    end

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

    function DBModule:SoftDeletePaste(name)
        local profile = self:GetProfile()
        local encoded = profile.savedPastes[name]

        if not encoded then
            return nil
        end

        local deletedName = GenerateUniqueName(name, function(n)
            return profile.deletedPastes[n] ~= nil
        end)

        profile.deletedPastes[deletedName] = {
            data = encoded,
            deletedAt = time()
        }

        profile.savedPastes[name] = nil

        return deletedName
    end

    function DBModule:AnyDeletedPastes()
        for _ in pairs(self:GetProfile().deletedPastes) do
            return true
        end

        return false
    end

    function DBModule:ListDeletedPastes()
        local result = {}

        for k in pairs(self:GetProfile().deletedPastes) do
            result[#result+1] = k
        end

        table.sort(result)

        return result
    end

    function DBModule:LoadDeletedPaste(name)
        local entry = self:GetProfile().deletedPastes[name]

        if not entry then
            return nil
        end

        return base64_dec(entry.data)
    end

    function DBModule:UndeletePaste(name)
        local profile = self:GetProfile()
        local entry = profile.deletedPastes[name]

        if not entry then
            return nil
        end

        local savedName = GenerateUniqueName(name, function(n)
            return profile.savedPastes[n] ~= nil
        end)

        profile.savedPastes[savedName] = entry.data
        profile.deletedPastes[name] = nil

        return savedName
    end

    function DBModule:PruneDeletedPastes()
        local profile = self:GetProfile()
        local cutoff = time() - (30 * 24 * 60 * 60)
        local toRemove = {}

        for name, entry in pairs(profile.deletedPastes) do
            if entry.deletedAt < cutoff then
                toRemove[#toRemove+1] = name
            end
        end

        for _, name in ipairs(toRemove) do
            profile.deletedPastes[name] = nil
        end
    end

    function DBModule:PurgeAllDeletedPastes()
        self:GetProfile().deletedPastes = {}
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

    local function MigrateDeletedPastes(profile)
        profile.deletedPastes = profile.deletedPastes or {}

        profile.dataVersion = 2
        return GetDataVersion(profile)
    end

    function DBModule:MigrateProfile()
        local profile = self:GetProfile()
        local version = GetDataVersion(profile)

        if version < 1 then
            version = MigrateMinimapIcon(profile)
        end

        if version < 2 then
            version = MigrateDeletedPastes(profile)
        end
    end
end