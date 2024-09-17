# This is the improved version of the classic Paste addon.
Like the original Paste addon, this addon gives you the possibility to paste multi-line/unlimited-length text or commands into WoW.

It also handles the case where you try to paste text longer than 250 characters, just like the original Paste addon.
Some of the new features compared to the original Paste addon:
* Completely open source (GPL)
* Ability to load and save paste for further use.
* Better use of the Ace3 library and better optimised for the changes to the WoW API since 2016.

## Usage
* Open the PasteNG window by typing `/paste show` (only if the original Paste addon isn't installed) or `/pasteng show` or by clicking on the minimap icon.
* You can paste your clipboard text into the textbox using your systems paste shortcut (CTRL+V on Windows, CMD+V on Mac).
* Select the channel you want to paste into from the drop down list.
* Click the `Paste` button.
* If you want to change options for the addon, just run the `/pasteng config` command (or open the addon options like you do for other addons).

## I'm getting a warning about old Paste/PasteNG addon being installed
If you get the following warning when you log in:
![Warning dialog](https://raw.githubusercontent.com/GurliGebis/WoWAddon-PasteNG/master/Images/old-paste-found.webp)
It is due to either the old Paste addon from 2016 being installed, of an older version of PasteNG.

To solve the issue, you should remove the old addon - the easiest way to do this, is to delete the `Paste` folder within the `World of Warcraft\_retail_\Interface\addons` folder, followed by reloading the game by running `/reload`

## Screenshot
### PasteNG window
![The main PasteNG window](https://raw.githubusercontent.com/GurliGebis/WoWAddon-PasteNG/master/Images/main-window.webp)
### Settings window
![The settings window](https://raw.githubusercontent.com/GurliGebis/WoWAddon-PasteNG/master/Images/settings.webp)