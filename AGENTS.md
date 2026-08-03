# AGENTS.md

## Requirements

- **World of Warcraft 1.12.1** (Interface `11200`) — TurtleWoW or any other
  vanilla 1.12 server

## WoW 1.12.1 Vanilla and Lua 5.0 Coding rules

The code follows vanilla Lua 5.0 constraints strictly:

- `this` in event handlers and `OnClick` scripts, never `self`
- SetScript syntax: Frame:SetScript("EventType", function() end) - no parameters allowed in function()
- "..." (varargs) - use explicit parameters instead
- "%" (modulo) - use math.mod(a, b)
- "#" (length) - use string.len() or table.getn()
- "match"/"gmatch" - use string.find() with patterns
- String concatenation: use .. operator

Safe to drop into any vanilla 1.12 or TurtleWoW client.