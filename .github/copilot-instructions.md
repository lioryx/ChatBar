# Project Guidelines

## Architecture
- This repository is a World of Warcraft addon targeting Interface 11200. There is no build step; the addon is loaded by the game from [ChatBar.toc](../ChatBar.toc).
- Keep the load order intact: [ChatBar.toc](../ChatBar.toc) loads localization files before [ChatBar.lua](../ChatBar.lua), and the Lua logic expects those CHATBAR_* constants to already exist.
- Most behavior lives in [ChatBar.lua](../ChatBar.lua). Extend the table-driven `ChatBar_ChatTypes` definitions and existing update/menu helpers instead of adding unrelated one-off branches.
- The UI is created in [ChatBar.lua](../ChatBar.lua). Keep named frames and regions compatible with existing globals such as `ChatBarFrameButton1`, `ChatBarFrameTooltip`, and `ChatBar_DropDown`.
- [SkinSolid](../SkinSolid) and [SkinSquares](../SkinSquares) are parallel skin directories with the same texture filenames. New skins should follow the same file layout expected by `ChatBar_UpdateArt`.

## WoW 1.12.1 Vanilla and Lua 5.0 Coding rules
- SetScript syntax: Frame:SetScript("EventType", function() end) - no parameters allowed in function()
- "..." (varargs) - use explicit parameters instead
- "%" (modulo) - use math.mod(a, b)
- "#" (length) - use string.len() or table.getn()
- "match"/"gmatch" - use string.find() with patterns
- String concatenation: use .. operator

## Conventions
- Preserve the addon's classic WoW UI style: global functions and state use `ChatBar_`, `CHAT_BAR_`, and `CHATBAR_` prefixes; frame handlers rely on globals such as `this`, `arg1`, and `event`.
- Prefer small, compatible edits over modern Lua refactors. This codebase is written against the legacy WoW API and assumes globals remain available.
- When changing localization, treat [localization.en.lua](../localization.en.lua) as the canonical key list and keep translated files aligned with it.
- When changing UI creation or asset references, verify filenames and paths carefully. The addon depends on the exact files declared in [ChatBar.toc](../ChatBar.toc) and the skin folders.
- Chronos and VisibilityOptions are optional integrations. Do not assume they are installed when changing channel reorder or visibility behavior.

## Build And Test
- There are no repository build, lint, or automated test commands.
- Validation is manual in game: place the ChatBar folder under `World of Warcraft/Interface/AddOns`, load the addon, and verify button rendering, right-click menus, channel buttons, and saved settings after `/reload`.
- For changes that touch button visibility, chat routing, or SavedVariables, test at least the affected chat types and one reload cycle.

## Documentation
- See [README.md](../README.md) for end-user installation, feature descriptions, and option behavior. Link to it instead of duplicating those details here.