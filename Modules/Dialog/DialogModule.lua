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
local DialogModule = PasteNG:NewModule("DialogModule", "AceConsole-3.0")
local DBModule = PasteNG:GetModule("DBModule")
local ConfigModule = PasteNG:GetModule("ConfigModule")
local MinimapModule = PasteNG:GetModule("MinimapModule")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local AceGUI = LibStub("AceGUI-3.0")

do
    local isPastedAllowed = false

    local function GetTextBoxHeader()
        if IsWindowsClient() then
            return string.format(L["Use %s to paste the clipboard into this box"], L["Control-V"])
        elseif IsMacClient() then
            return string.format(L["Use %s to paste the clipboard into this box"], L["Command-V"])
        else
            return string.format(L["Use %s to paste the clipboard into this box"], L["System paste shortcut"])
        end
    end

    local function CleanupText(text)
        -- Convert all versions of line breaks to '\n'
        text = string.gsub(text, "\r\n?", "\n")

        -- Remove empty lines by replacing any sequence of a newline followed by optional whitespace and another newline with a single newline
        text = string.gsub(text, "\n%s*\n", "\n")

        -- Remove leading whitespace followed by a newline at the start of the text
        text = string.gsub(text, "^%s*\n", "")

        -- Remove trailing newline followed by whitespace at the end of the text
        text = string.gsub(text, "\n%s*$", "")

        -- Ensure that any newline surrounded by whitespace is replaced with a single newline
        text = string.gsub(text, "%s*\n%s*", "\n")

        return text
    end

    function DialogModule:UpdateFooter()
        -- Get the text from the textbox and clean it up.
        local cleanedText = CleanupText(DialogModule.TextBox:GetText())

        -- Count the number of line breaks and characters.
        local lineCount = select(2, string.gsub(cleanedText, "\n", ""))
        local charCount = #cleanedText - lineCount

        -- If there is any text at all, the line count should be increased by 1.
        -- So if no text, we have 0 lines, but if we have any, we add 1, since there are no linebreak in front of the first line.
        if charCount > 0 then
            lineCount = lineCount + 1
            DialogModule.SaveButton:Enable()
        else
            DialogModule.SaveButton:Disable()
        end

        -- Set the footer status text.
        DialogModule.PasteDialog:SetStatusText(string.format("%d %s, %d %s", lineCount, L["lines"], charCount, L["characters"]))
    end

    local function RefreshTargetDropdown(dropdown)
        local targetDropdown = dropdown or DialogModule.TargetDropdown

        -- Default targets, always there.
        local targets = {
            [CHAT_DEFAULT] = CHAT_DEFAULT,
            [CHAT_MSG_SAY] = CHAT_MSG_SAY,
            [CHAT_MSG_YELL] = CHAT_MSG_YELL,
            [CHAT_MSG_WHISPER_INFORM] = CHAT_MSG_WHISPER_INFORM,
        }

        -- Check and add optional targets
        local function addTarget(condition, key)
            if condition then
                targets[key] = key
            end
        end

        -- Are we connected to battle net chat? (sometimes this goes offline, so better to check)
        addTarget(BNFeaturesEnabledAndConnected(), BN_WHISPER)

        -- Are we in a group?
        addTarget(GetNumGroupMembers() > 0, CHAT_MSG_PARTY)

        -- Are we in a raid?
        addTarget(IsInRaid(), CHAT_MSG_RAID)

        -- Are we are in a raid group, and are we the Leader or Assistant?
        addTarget(IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")), CHAT_MSG_RAID_WARNING)

        -- Are we in an instance? (dungeon, raid, scenario etc)
        addTarget(IsInGroup(LE_PARTY_CATEGORY_INSTANCE), INSTANCE_CHAT)

        -- Are we in a guild?
        addTarget(IsInGuild(), CHAT_MSG_GUILD)
        addTarget(IsInGuild(), CHAT_MSG_OFFICER)

        -- If the drop down isn't open, we can set the targets (we don't want to override it while it is open)
        if not targetDropdown.open then
            -- Set targets for the drop down.
            targetDropdown:SetList(targets)

            -- Set the current target to the one stored in the settings.
            -- If the one stored in the settings isn't available, we default to the default chat.
            local previousSelectedTarget = DBModule:GetValue("selected_target")
            local targetValue = targets[previousSelectedTarget] and previousSelectedTarget or CHAT_DEFAULT

            targetDropdown:SetValue(targetValue)
            DBModule:SetValue("selected_target", targetValue)
        end

        return targets
    end

    function DialogModule:RefreshLoadDeleteButtons()
        local anySavedPastes = DBModule:AnySavedPastes()

        if anySavedPastes then
            DialogModule.LoadButton:Enable()
            DialogModule.DeleteButton:Enable()
        else
            DialogModule.LoadButton:Disable()
            DialogModule.DeleteButton:Disable()
        end
    end

    function DialogModule:RefreshPasteCloseButtons()
        local function SetButtonStatus(enabled)
            DialogModule.PasteButton:SetEnabled(enabled)
            DialogModule.PasteCloseButton:SetEnabled(enabled)

            isPastedAllowed = enabled
        end

        local text = DialogModule.TextBox:GetText()

        if not text or text == "" then
            -- If no text is in the textbox, we disable the buttons.
            SetButtonStatus(false)
            return
        end

        local selectedTarget = DBModule:GetValue("selected_target")

        if selectedTarget == CHAT_MSG_WHISPER_INFORM or selectedTarget == BN_WHISPER then
            local targetName = DBModule:GetValue("selected_whisper_target")

            if not targetName or targetName == "" then
                -- If no target name is set, we disable the buttons.
                SetButtonStatus(false)
                return
            end
        end

        -- Everything is fine, so we enable the buttons.
        SetButtonStatus(true)
    end

    local function SendPaste()
        -- Wrapper function to handle different types of chat messages
        local function SendChatMessageWrapper(message, chatType, target)
            if chatType == CHAT_DEFAULT then
                -- We cannot post directly to the default (currently selected) chat, so we have to do a little "macro" work.
                -- Open the current chat window.
                ChatFrame_OpenChat("")

                -- Get the current chat window text box.
                local edit = ChatEdit_GetActiveWindow()

                -- Set the text we want to send into the text box.
                edit:SetText(message)

                -- Send the message.
                ChatEdit_SendText(edit, 1)

                -- Close the chat window again.
                ChatEdit_DeactivateChat(edit)
            elseif chatType == BN_WHISPER then
                local bnetAccountID = BNet_GetBNetIDAccount(target)

                if not bnetAccountID then
                    StaticPopup_Show("PASTENG_BATTLE_NET_FRIEND_NOT_FOUND")
                    return
                end

                BNSendWhisper(bnetAccountID, message)
            else
                SendChatMessage(message, chatType, nil, target)
            end
        end

        -- Function to split a line if it exceeds the maximum length
        local function SplitLineIfTooLong(line)
            local max_length = 250
            local result = {}
            local current_line = ""

            for word in line:gmatch("%S+") do
                if #current_line + #word + 1 > max_length then
                    table.insert(result, current_line)
                    current_line = word
                else
                    if #current_line > 0 then
                        current_line = current_line .. " " .. word
                    else
                        current_line = word
                    end
                end
            end

            if #current_line > 0 then
                table.insert(result, current_line)
            end

            return result
        end

        local targets = RefreshTargetDropdown()
        local selectedTarget = DBModule:GetValue("selected_target")

        if not targets[selectedTarget] then
            return
        end

        -- Clean up the text, removing whitespaces and empty lines.
        local message = CleanupText(DialogModule.TextBox:GetText())

        -- Split the message into lines.
        local lines = { strsplit("\n", message) }

        -- Define delay to use for pasting into guild chat.
        local delay = 0

        -- Look up the target, if we are to whisper someone.
        local target = (selectedTarget == BN_WHISPER or selectedTarget == CHAT_MSG_WHISPER_INFORM) and DBModule:GetValue("selected_whisper_target") or nil

        for _, line in ipairs(lines) do
            local splitLines = SplitLineIfTooLong(line)

            for _, splitLine in ipairs(splitLines) do
                if splitLine:find("^/%w") then
                    -- The current line starts with a forward slash, so we send it to the DEFAULT channel.
                    SendChatMessageWrapper(splitLine, CHAT_DEFAULT)
                elseif selectedTarget ~= CHAT_MSG_GUILD then
                    SendChatMessageWrapper(splitLine, selectedTarget, target)
                else
                    -- Guild chat has to use a delay for some reason.
                    C_Timer.After(delay, function() SendChatMessageWrapper(splitLine, selectedTarget, target) end)
                    delay = delay + 0.25
                end
            end
        end
    end

    local function LoadButton_OnClick()
        local function LoadPaste(name)
            local text = DBModule:LoadPaste(name)

            if text then
                DialogModule.TextBox:SetText(text)
                DialogModule:UpdateFooter()
            end
        end

        MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
            rootDescription:CreateTitle(L["Select paste to load"])

            for _, savedPaste in ipairs(DBModule:ListSavedPastes()) do
                rootDescription:CreateButton(savedPaste, function()
                    LoadPaste(savedPaste)

                    DialogModule:RefreshPasteCloseButtons()
                end)
            end
        end)
    end

    local function SaveButton_OnClick()
        StaticPopup_Show("PASTENG_SAVE", nil, nil, DialogModule.TextBox:GetText())
    end

    local function DeleteButton_OnClick()
        MenuUtil.CreateContextMenu(UIParent, function(_, rootDescription)
            rootDescription:CreateTitle(L["Select paste to delete"])

            for _, savedPaste in ipairs(DBModule:ListSavedPastes()) do
                rootDescription:CreateButton(savedPaste, function()
                    StaticPopupDialogs["PASTENG_CONFIRM_DELETE"].text = string.format(L["Do you want to delete the %s paste?"], savedPaste)
                    StaticPopup_Show("PASTENG_CONFIRM_DELETE", nil, nil, savedPaste)
                end)
            end
        end)
    end

    local function ClearButton_OnClick()
        DialogModule.TextBox:SetText("")
        DialogModule:UpdateFooter()
        DialogModule.TextBox:SetFocus()

        DialogModule:RefreshPasteCloseButtons()
    end

    local function PasteCloseButton_OnClick()
        DialogModule.PasteDialog:Hide()
        SendPaste()
    end

    local function PasteButton_OnClick()
        SendPaste()
    end

    local function TextBox_OnTextChanged()
        DialogModule:UpdateFooter()
        DialogModule:RefreshLoadDeleteButtons()
        DialogModule:RefreshPasteCloseButtons()
    end

    local function TextBox_OnEnterPressed()
        local shiftEnterSend = DBModule:GetValue("shift_enter_send")

        -- We need to make sure the paste buttons are enabled as well.
        -- Otherwise, we might try and paste when it is not possible.
        if shiftEnterSend and IsShiftKeyDown() and isPastedAllowed then
            SendPaste()
            DialogModule.PasteDialog:Hide()
        else
            DialogModule.TextBox.editBox:Insert("\n")
        end
    end

    local function TargetDropdown_OnValueChanged(key, targetNameTextBox)
        DBModule:SetValue("selected_target", key)

        if key == CHAT_MSG_WHISPER_INFORM or key == BN_WHISPER then
            targetNameTextBox:SetDisabled(false)
            targetNameTextBox:SetFocus()

            DialogModule:RefreshPasteCloseButtons()
        else
            targetNameTextBox:SetDisabled(true)
        end
    end

    local function TargetNameTextBox_OnEnterPressed(self)
        self:ClearFocus()
    end

    local function TargetNameTextBox_OnTextChanged()
        DBModule:SetValue("selected_whisper_target", DialogModule.TargetNameTextBox:GetText())

        DialogModule:RefreshPasteCloseButtons()
    end

    local function CreateDialog()
        local rightButtonsWidth = 100
        local bottomButtonWidth = 176
        local textBoxRightMargin = rightButtonsWidth + 50
        local textBoxBottomMargin = 145

        local function CreateMainFrame()
            local mainFrame = AceGUI:Create("Frame")

            local minimumFrameWidth = 500
            local minimumFrameHeight = 400

            -- Create the window and set the title.
            mainFrame:SetTitle(string.format("%s %s", PasteNG.Name, PasteNG.Version))

            -- Prevent the window from being dragged off screen.
            mainFrame.frame:SetClampedToScreen(true)

            -- "Downgrade" the Frame Strata to "DIALOG" to avoid it being on top of dropdown menues.
            mainFrame.frame:SetFrameStrata("DIALOG")

            -- Persist the window position in the config, so it is remembered between sessions.
            mainFrame:SetStatusTable(DBModule.AceDB.profile.mainFramePosition)

            -- Set window size if width and height isn't stored, we default to the minimums.
            if not DBModule.AceDB.profile.mainFramePosition.width or not DBModule.AceDB.profile.mainFramePosition.height then
                mainFrame:SetWidth(minimumFrameWidth)
                mainFrame:SetHeight(minimumFrameHeight)
            end

            mainFrame.frame:SetResizeBounds(minimumFrameWidth, minimumFrameHeight)

            -- Store the frame on the module.
            DialogModule.PasteDialog = mainFrame

            return mainFrame
        end

        local function CreateButton(parentFrame, anchor, text, width, height, point, xOffset, yOffset)
            local button = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
            button:SetPoint(point, anchor, xOffset, yOffset)
            button:SetHeight(height)
            button:SetWidth(width)
            button:SetText(text)
            return button
        end

        local function CreateTextBox(mainFrame)
            local textBoxContainer = AceGUI:Create("SimpleGroup")
            textBoxContainer:SetLayout("Fill")

            -- Dummy values, since the resize hook will make sure it has the correct size as soon as the window loads.
            textBoxContainer:SetWidth(100)
            textBoxContainer:SetHeight(100)

            local textBox = AceGUI:Create("MultiLineEditBox")
            textBox:SetMaxLetters(0)    -- Allow unlimited number of characters in the textbox.
            textBox:SetNumLines(10)     -- Show 10 lines of text.
            textBox:DisableButton(true) -- Remove the Okay button.
            textBox:SetText("")         -- Clear any text that might be in the textbox

            -- Enable full width and height, so we follow the container, which follows the window size.
            textBox:SetFullHeight(true)
            textBox:SetFullWidth(true)

            -- Set the textbox header label to the correct value.
            textBox:SetLabel(GetTextBoxHeader())

            textBoxContainer:AddChild(textBox)
            mainFrame:AddChild(textBoxContainer)

            return textBox, textBoxContainer
        end

        local function CreateTargetDropdown(mainFrame)
            local targetGroup = AceGUI:Create("SimpleGroup")
            targetGroup:SetLayout("Flow")
            targetGroup:SetFullWidth(true)

            local targetDropdown = AceGUI:Create("Dropdown")
            targetDropdown:SetMultiselect(false)
            targetDropdown:SetLabel(L["Paste to:"])
            targetDropdown:SetWidth(bottomButtonWidth - 5)
            RefreshTargetDropdown(targetDropdown)

            local targetNameTextBox = AceGUI:Create("EditBox")
            targetNameTextBox:SetMaxLetters(30)
            targetNameTextBox:SetWidth(bottomButtonWidth)
            targetNameTextBox:DisableButton(true)
            targetNameTextBox:SetText(DBModule:GetValue("selected_whisper_target") or "")

            local previousSelectedTarget = DBModule:GetValue("selected_target")
            targetNameTextBox:SetDisabled(previousSelectedTarget ~= CHAT_MSG_WHISPER_INFORM and previousSelectedTarget ~= BN_WHISPER)

            targetGroup:AddChild(targetDropdown)
            targetGroup:AddChild(targetNameTextBox)

            mainFrame:AddChild(targetGroup)

            return targetDropdown, targetNameTextBox
        end

        -- Define all controls
        local mainFrame = CreateMainFrame()
        local loadButton = CreateButton(mainFrame.frame, mainFrame.frame, L["Load"], rightButtonsWidth, 24, "TOPRIGHT", -27, -27)
        local saveButton = CreateButton(mainFrame.frame, loadButton, L["Save"], rightButtonsWidth, 24, "TOPRIGHT", 0, -24)
        local deleteButton = CreateButton(mainFrame.frame, saveButton, L["Delete"], rightButtonsWidth, 24, "TOPRIGHT", 0, -24)
        local clearButton = CreateButton(mainFrame.frame, deleteButton, L["Clear"], rightButtonsWidth, 24, "TOPRIGHT", 0, -24)
        local pasteButton = CreateButton(mainFrame.frame, mainFrame.frame, L["Paste"], bottomButtonWidth, 24, "BOTTOMLEFT", 15, 45)
        local pasteCloseButton = CreateButton(mainFrame.frame, pasteButton, L["Paste and Close"], bottomButtonWidth, 24, "BOTTOMLEFT", bottomButtonWidth, 0)
        local textBox, textBoxContainer = CreateTextBox(mainFrame)
        local targetDropdown, targetNameTextBox = CreateTargetDropdown(mainFrame)

        -- Store controls on the module
        DialogModule.LoadButton = loadButton
        DialogModule.SaveButton = saveButton
        DialogModule.DeleteButton = deleteButton
        DialogModule.PasteButton = pasteButton
        DialogModule.PasteCloseButton = pasteCloseButton
        DialogModule.TextBox = textBox
        DialogModule.TextBoxContainer = textBoxContainer
        DialogModule.TargetDropdown = targetDropdown
        DialogModule.TargetNameTextBox = targetNameTextBox

        -- Attach event handlers
        loadButton:SetScript("OnClick", LoadButton_OnClick)
        saveButton:SetScript("OnClick", SaveButton_OnClick)
        deleteButton:SetScript("OnClick", DeleteButton_OnClick)
        clearButton:SetScript("OnClick", ClearButton_OnClick)
        pasteButton:SetScript("OnClick", PasteButton_OnClick)
        pasteCloseButton:SetScript("OnClick", PasteCloseButton_OnClick)
        textBox:SetCallback("OnTextChanged", function() TextBox_OnTextChanged() end)
        textBox.editBox:SetScript("OnEnterPressed", TextBox_OnEnterPressed)
        targetDropdown:SetCallback("OnEnter", function(self) RefreshTargetDropdown(self) end)
        targetDropdown:SetCallback("OnValueChanged", function(_, _, key) TargetDropdown_OnValueChanged(key, targetNameTextBox) end)
        targetNameTextBox:SetCallback("OnTextChanged", function() TargetNameTextBox_OnTextChanged() end )
        targetNameTextBox:SetCallback("OnEnterPressed", function(self) TargetNameTextBox_OnEnterPressed(self) end)

        -- Hook window vertical resizing
        hooksecurefunc(mainFrame, "OnHeightSet", function(_, newHeight)
            DialogModule.TextBoxContainer:SetHeight(newHeight - textBoxBottomMargin)
        end)

        -- Hook window horizontal resizing
        hooksecurefunc(mainFrame, "OnWidthSet", function(_, newWidth)
            DialogModule.TextBoxContainer:SetWidth(newWidth - textBoxRightMargin)
        end)

        -- Update the footer with the initial value.
        DialogModule:UpdateFooter()

        -- Refresh button status
        DialogModule:RefreshLoadDeleteButtons()
        DialogModule:RefreshPasteCloseButtons()

        -- Hook the escape key, so we can close the dialog with the escape key.
        local globalFrameName = "PasteNGDialogFrame"
        _G[globalFrameName] = mainFrame.frame
        tinsert(UISpecialFrames, globalFrameName)
    end

    function DialogModule:ShowDialog()
        if DialogModule.PasteDialog == nil then
            CreateDialog()
        end

        DialogModule.PasteDialog:Show()
        DialogModule.TextBox:SetFocus()
    end

    function DialogModule:ResetCoordinates()
        if DialogModule.PasteDialog then
            -- Close the dialog first, if it is open.
            DialogModule.PasteDialog:Hide()

            -- Release the frame.
            AceGUI:Release(DialogModule.PasteDialog)
        end

        -- Reset the saved data.
        DBModule.AceDB.profile.mainFramePosition = {}

        -- Clear the stored frame, to force recreation on next open.
        DialogModule.PasteDialog = nil

        -- Show message box.
        StaticPopup_Show("PASTENG_POSITION_RESET")
    end
end

function DialogModule:OnInitialize()
    if not C_AddOns.IsAddOnLoaded("Paste") then
        DialogModule:RegisterChatCommand("paste", "HandleChatCommand")
    else
        StaticPopup_Show("PASTENG_WARN_ABOUT_PASTE")
    end

    DialogModule:RegisterChatCommand("pasteng", "HandleChatCommand")
end

function PrintUsage()
    print(L["PasteNG Usage:"])
    print(L["/pasteng show - Show the pasteng dialog"])
    print(L["/pasteng config - Open the configuration"])
    print(L["/pasteng minimap - Toggle the minimap icon"])
end

function DialogModule:HandleChatCommand(message)
    if message == "show" then
        self:ShowDialog()
    elseif message == "config" then
        Settings.OpenToCategory(ConfigModule.OptionsFrame.name)
    elseif message == "minimap" then
        MinimapModule:ToggleMinimapIcon()
    else
        PrintUsage()
    end
end

StaticPopupDialogs["PASTENG_CONFIRM_DELETE"] = {
    text = "",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        DBModule:DeletePaste(data)
        DialogModule:RefreshLoadDeleteButtons()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["PASTENG_SAVE"] = {
    text = L["Please enter the name of your paste:"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    OnAccept = function(self, data)
        DBModule:SavePaste(self.editBox:GetText(), data)
        DialogModule:RefreshLoadDeleteButtons()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["PASTENG_WARN_ABOUT_PASTE"] = {
    text = L["PasteNG isn't compatible with the Paste addon (including the old PasteNG version). Please uninstall or delete the Paste addon folder."],
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["PASTENG_BATTLE_NET_FRIEND_NOT_FOUND"] = {
    text = L["Battle.net friend not found."],
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["PASTENG_POSITION_RESET"] = {
    text = L["Window size and position has been reset."],
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}