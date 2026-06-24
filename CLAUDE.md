# ToysByFunction

## Critical: WoW 12.0 Midnight API Rules

### DO NOT USE (Removed/Broken):
- COMBAT_LOG_EVENT_UNFILTERED — removed in 12.0
- CombatLogGetCurrentEventInfo() — removed
- UnitHealth() for math — returns secret values during combat

### Secret Values (CRITICAL):
- During M+/PvP/encounters, combat data returns as opaque tokens
- Always check: if issecretvalue(val) then return end
- Use CurveObject/DurationObject for visual display

### Interface Version:
- Current: 120001 (Patch 12.0.1)
- Addons below 120000 will NOT load

## Architecture

### File Load Order (defined in .toc):
1. Libs/ — External libraries (LibStub, CallbackHandler)
2. Init.lua — Namespace + event dispatcher + ADDON_LOADED/PLAYER_LOGIN + slash commands
3. Core.lua — Feature logic + frame creation + combat queue
4. Config.lua — Settings panel registration

### Namespace Pattern:
local addonName, ns = ...
-- All code uses ns.* to share between files
-- NEVER create globals except slash commands

## Coding Conventions

### Always:
- Use `local` for everything
- Check issecretvalue() before comparing combat values
- Check InCombatLockdown() before modifying secure frames
- Use hooksecurefunc() for post-hooks (never wrap secure functions)
- Use BAG_UPDATE_DELAYED (not BAG_UPDATE)

### Never:
- Generate CLEU handlers
- Call functions listed as removed in 12.0
- Create globals without explicit declaration in .luacheckrc
- Call SetScript() on Blizzard frames (use HookScript)