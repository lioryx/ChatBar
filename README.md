# ChatBar
ChatBar - Button Bar for openning chat messages of each type.

Current addon version: 3.2

## Original creator
- [KarlKFI](https://wow.curseforge.com/addons/project-1579/)

## Modify creator
- [0ldi](https://github.com/0ldi)
- [Lichery](https://github.com/Lichery)

## Changelog
* v3.2
  - Added localized addon titles and notes for Simplified Chinese, Traditional Chinese, German, and Russian
  - Corrected English and French addon notes in the addon list

* v3.1
  - Added the Color Bars skin with adjustable border size, and independent Button Width / Button Height controls
  - Split the options window into Skin, Text, Behavior, and Channels tabs
  - Added Hover Text Fade, Reverse Text Position, and Auto-hide on mouse leave
  - Buttons can be drag-reordered on the bar; the Channels tab can sort by channel number or name
  - Added shortcut buttons for common addons and tools (Meeting Stone, AtlasLoot, SuperMacro, Outfitter, Tracking, Ready Check, Countdown, Emote Menu, and more); extras are hidden by default
  - Tab key cycles chat channels and recent whisper targets
  - Added TurtleWoW Hardcore channel support and extra battleground zones
  - Moving the bar now requires Ctrl + left click
  - Unused extra buttons are now hidden; raid leader messages flash the Raid button; officer chat visibility follows guild rank

* v3.0
  - Split the original ChatBar.lua into focused files for core logic, buttons, menus, updates, and options
  - Replaced the old Large Buttons toggle with adjustable Button Size, Button Text Size, and Button Spacing settings
  - Added additional built-in skins including Text Only and Octagon, and switched skin selection to a dropdown in the options panel
  - Removed channel reordering and the Chronos dependency
  - Redesigned the options window into General and Channels tabs
  - Removed the old Hide Addon Channels and Hide All Buttons options in favor of per-button visibility control
  - Moved button visibility management into the Channels tab with checkboxes, scroll support, and Select All / Clear All actions

* v.2.5 Thx [Lichery](https://github.com/Lichery) for updates:
  - Added larger buttons option to options menu

* v2.4
  - Added Simplified Chinese Localization (thanks IceChen)
  - Added new Squares skin (thanks Chianti/Кьянти)
  - Added new skin dropdown (Solid, Squares)

* v2.3
  - Added Traditional Chinese Localization
  - Fixed a bug with Russian Localization

* v2.2
  - Removed SeaPrint usage
  - Made Chronos optional: Reorder Channels is disabled w/o Chronos installed.

* v2.1
  - Added Russian Localization (thanks Старостин Алексей)

* v2.0
  - Added Alternate Artwork (thanks Zseton)

* v1.9
  - Added Spanish Localization (thanks NeKRoMaNT)

* v1.8
  - Added an option to Hide All Buttons
  - Fixed menu not showing a list of hidden buttons
  - Fix for display of the BG button only on battlegrounds,   added Localization.ru, fixed Localizations
  - Changed the channel order
  - Added Battleground and RaidWarning channels

* Based on `ChatBar 1.6`

## How to Install
Put `ChatBar` folder to `World of Warcraft\Interface\AddOns` 	

## Detailed description
A little acsii art for demonstration: [oooooooo]

o - Buttons, colored the color of a chat type, left click to open editbox of that type, right click for type specific options. Initial letter of the type on or above the button

[ ] - Ends of the bar, hold Ctrl + left click to drag, right click for options

### Button / ChatType Options:
* Leave (Channel)
* Print Channel User List - List prints to the default chat frame. Same as "/list #"
* Hide This Button - Hide the button for that chat type or channel by name.
* Reply (Whisper) - Open whisper to the last person that whispered you.
* Retell (Whisper) - Open whisper to the last person you whispered.
* Sticky - http://www.wowwiki.com/Chat#Advanced_Chat_Terminology.2FDetails
  - Note: Channels are all or none, other types can be stickied individually.

### ChatBar Options:
* Skin Tab - Artwork and button dimensions
  - Use Alternate Artwork - Select the active built-in skin from a dropdown list (Solid, Squares, Text Only, Octagon, Color Bars)
  - Button Width / Button Height - Adjusts the size of each chat button independently
  - Button Spacing - Adjusts the gap between adjacent buttons
  - Color Bar Border - Adjusts the Color Bars skin border
  - Show Bar Border - Toggles show/hide the bar border/background. Note: You can still click on the ends of the bar when it's hidden

* Text Tab
  - Button Text Size - Adjusts the text size used on or around each button
  - Show Button Text - Toggles chattype abrev visibility
  - Text On Buttons - Toggles chattype abrev on/next to the buttons
  - Reverse Text Position - Toggles which side of the button the text appears on
  - Hover Text Fade - Fades button text in on mouseover
  - Use Channel ID On Buttons - Toggles using the channel index or the first letter of the channel name

* Behavior Tab
  - Vertical Orienation - Toggles vertical/horrizontal bar via sliding
  - Reverse Button Orienation - Toggles button order reversal via sliding
  - Button Message Flashing - Toggles button flashing when you receive a message of that type
  - Auto-hide on mouse leave - Hides the bar until the mouse returns to the chat area
  - Reset Position - Attaches the ChatBarFrame to above the ChatFrame1 tab

* Channels Tab - Lists all available ChatBar buttons and channels with checkbox-based visibility control
  - Channel Visibility - Use the Channels tab checkboxes to choose which buttons are shown
  - Select All / Clear All - Show or hide every listed button in the Channels tab at once
  - Channel Sort - Sort listed buttons by channel number or name
  - Reset Sort - Restore the default button order
  - Drag buttons on the bar to reorder them
  - Scrollable Channel List - Lets you manage all listed buttons even when the list exceeds the panel height

