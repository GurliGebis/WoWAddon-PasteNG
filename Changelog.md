# 11.2.5-20251024-1
* Don't send announcements when inside scenarios, since that also can cause the "You aren't in a party" error.

# 11.2.5-20251022-1
* Fixed "You aren't in a party" error by adding check for group size.

# 11.2.5-20251006-1
* Updated TOC to match WoW 11.2.5

# 11.2.0-20250926-2
* Change version checks to check for functionality instead of game version.

# 11.2.0-20250926-1
* Make sure we don't try to send communications when not in a group.
* Remove Cataclysm version from TOC file.

# 11.2.0-20250924-1
* Updated Classic TOC to match 5.5.1

# 11.2.0-20250916-1
* Change print functions to use AceConsole print.
* Tell share target if they are missing PasteNG.

# 11.2.0-20250911-1
* Optimize ConfigModule to simplify code and improve readability.

# 11.2.0-20250909-1
* Optimize DBModule to improve array operations.

# 11.2.0-20250906-1
* Optimize MinimapModule and better error handling.

# 11.2.0-20250904-2
* Correct spelling error in options dialog.
* Don't split lines starting with a forward slash.

# 11.2.0-20250904-1
* Added Russian (ruRU) locale.

# 11.2.0-20250902-1
* Added setting to enable/disable sharing.

# 11.2.0-20250830-1
* Implement functionality to share paste with party members.

# 11.2.0-20250827-1
* Only have the Clear button enabled, if something can be cleared.

# 11.2.0-20250825-1
* Changed SendChatMessage to be C_ChatInfo.SendChatMessage on Retail.

# 11.2.0-20250815-1
* Enable scrolling for the Load and Delete dropdown menues.

# 11.2.0-20250810-1
* Fixed problem caused by previous fix in MoP Classic.

# 11.2.0-20250808-1
* Fixed issue with saving pastes.

# 11.2.0-20250806-1
* Updated TOC to match WoW 11.2.0

# 11.1.7-20250619-1
* Updated TOC to match WoW 11.1.7

# 11.1.5-20250525-1
* Updated TOC to support Classic, MoP Beta and Retail PTR.

# 11.1.5-20250422-1
* Updated TOC to match WoW 11.1.5

# 11.1.0-20250305-1
* Updated Classic TOC version to latest version.

# 11.1.0-20250225-1
* Updated TOC to match WoW 11.1.0

# 11.0.7-20250220-1
* Updated TOC to support Cataclysm Classic.

# 11.0.7-20250128-1
* Added category to TOC file.

# 11.0.7-20241218-1
* Updated TOC to match WoW 11.0.7

# 11.0.5-20241126-1
* Fixed bug when sending paste before having opened the main PasteNG window.

# 11.0.5-20241121-1
* Small refactoring of DialogModule.
* Added option to send a paste from the chat window.

# 11.0.5-20241023-1
* Updated TOC to 11.0.5

# 11.0.2-20241017-1
* Submit the delete dialog when the Enter key is pressed.

# 11.0.2-20241015-1
* Submit the overwrite dialog when the Enter key is pressed.
* Added installation of missing github runner packages.

# 11.0.2-20241009-1
* Enable/Disable the Accept button in the save dialog, depending on text length.
* Submit the save dialog when the Enter key is pressed.

# 11.0.2-20240926-1
* Added support for the addon compartment.

# 11.0.2-20240924-1
* Fixed support for data brokers.

# 11.0.2-20240922-1
* Added key binding support for opening the PasteNG window.

# 11.0.2-20240921-2
* Don't hardcode Accept and Cancel.
* Persist window size across logins.
* Add config button to reset window size and position.
* Warn if a paste is about to be overwritten.

# 11.0.2-20240921-1
* Fix minimap icon disable/enable.
* Fix the "Please enter the name of your paste" string.
* Added frFR locale, since it has been translated.

# 11.0.2-20240920-1
* Complete rewrite and refactor.
* Added load/save functionality.
* Disable buttons when clicking them does not make sense.
* Change license to GPL.

# 11.0.2-20240912-1
* Github actions fixes.

# 11.0.2-20240907-1
* No reason to delay the first chat message.

# 11.0.2-20240905-1
* Fixed issue with out-of-order paste into guild chat, solution provided by tflo on github.

# 11.0.2-20240831-1
* Added icon to the addon list.

# 11.0.2-20240813-1
* Updated TOC to 11.0.2

# 11.0.0-20240725-1
* Change so libraries are downloaded instead of embedded from github.
* Fix logic to open settings dialog.

# 11.0.0-20240723-1
* Updated Ace3 to support The War Within.
* Updated TOC to support 11.0.0

# 10.2.7-20240508_1
* Updated TOC to 10.2.7

# 10.2.6-20240320_1
* Updated TOC to 10.2.6

# 10.2.5-20240117_1
* Updated TOC to 10.2.5

# 10.2.0-20231210_1
* Fix deprecated code.
* More code documentation.

# 10.2.0-20231111_1
* Update libraries and remove old files.
* Code cleanup and added changelog.

# 10.2.0-20231108_1
* Updated TOC to 10.2.0

# 10.1.7-20230923_1
* Remove LibStrataFix, since it is no longer needed, and causes problems with dragon customizations.

# 10.1.7-20230912_1
* Updated TOC to 10.1.7

# 10.1.5-20230712_1
* Updated TOC to 10.1.5

# 10.1.0-20230503_1
* Updated TOC to 10.1.0

# 10.0.7-20230322_1
* Updated TOC to 10.0.7

# 10.0.5_20230131_1
* Updated koKR locale.
* Updated embedded libraries.

# 10.0.5-20230125_1
* Changed to use global profile as default, fixing github issue #3.
* Updated TOC to 10.0.5

# 10.0.2-20221129_1
* Initial implementation of PasteNG.