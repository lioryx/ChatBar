# AGENTS.md

## Requirements

- **WoW Forever** (Interface `16001`) — modern client, product flavor `wowf`
- Lua 5.1

## Forever / Lua 5.1 coding rules

- Script handlers receive the frame and explicit arguments: `function(self, button)`, `function(self, event, ...)`, `function(self, elapsed)`. Do not use the globals `this`, `event`, or `arg1`..`arg9`.
- `...` (varargs), `#` (length), `%` (modulo), and `string.match` / `string.gmatch` are available. Do not use `table.getn`, `math.mod`, `string.gfind`, or `getglobal` (`_G[]` instead).
- Iterate tables with `pairs` / `ipairs`. `for k, v in someTable do` is a Lua 5.0 form and errors on 5.1.
- Frames that call `SetBackdrop` must be created with the `BackdropTemplate` mixin.
- Solid colors use `SetColorTexture`, not `SetTexture(r, g, b)`.
- Group state: `IsInGroup()`, `IsInRaid()`, `IsInGroup(LE_PARTY_CATEGORY_INSTANCE)`, `UnitIsGroupLeader`, `UnitIsGroupAssistant`, event `GROUP_ROSTER_UPDATE`.
- Battleground / instance chat type is `INSTANCE_CHAT` (not `BATTLEGROUND`).
- Chat edit boxes are protected. Change type with `SetAttribute("chatType", ...)` / `SetAttribute("channelTarget", ...)` outside combat, then `ChatEdit_ActivateChat` and `ChatEdit_UpdateHeader`. Pick the box with `ChatEdit_ChooseBoxForSend()`.
- Do not replace `SendChatMessage`. Use `hooksecurefunc`.
- Dropdown helpers use the modern argument order: `UIDropDownMenu_SetWidth(frame, width)`, `UIDropDownMenu_SetText(frame, text)`.
- Prefer `C_*` namespaces (`C_GuildInfo`, `C_PartyInfo`) and test that the function exists before calling it.
- This addon does not provide buttons for third-party addons.
