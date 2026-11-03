# unitscan (v1.1)

A rare unit scanner for **WoW 3.3.5a - Epoch Reborn** with dead unit cooldown tracking and pfQuest map integration.

## Features

- Scans for configured rare units and displays a popup when one is detected nearby.
- Includes a built-in list of rare units across all Epoch Reborn zones and dungeons.
- Tracks confirmed kills and skips units while they are on respawn cooldown. Uses respawn times from pfQuest's unit database when available, with a configurable default fallback (8 hours).
- Removes a rare's map pin when killed, keeps it hidden during its respawn cooldown across map refreshes, and automatically restores it when the cooldown expires.
- When in a instance applies a 1-hour cooldown when closing a unit popup

## Slash Commands

| Command | Action |
|---|---|
| `/unitscan` | Open configuration |
| `/unitscan cooldowns` | List all units on dead cooldown with time remaining |
| `/unitscan cooldown <hours>` | Set fallback respawn cooldown for units not in pfQuest |
| `/unitscan nearby` | Print a list of all units being scanned in the current zone |
| `/unitscan target` | Add/remove your current target from the list of scanned units |
| `/unitscan unitname` | Add/remove 'unitname' to scanned units, works with any unit name |
| `/unitscan ignore unitname` | Add/Remove 'unitname' from the built in list of scanned units |

## Compatibility

- **Server:** Epoch Reborn
- **Interface:** 30300 (WoW 3.3.5a)
- **Lua:** 5.1
- Optional: **[pfQuest-Epoch](https://github.com/Bennylavaa/pfQuest-epoch)** for accurate per-unit respawn times and map icon management

## Credit
- Original 3.3.5 backport by [Sattva-108](https://github.com/Sattva-108/unitscan)
- Epoch fixes by [Defcon and David](https://github.com/Defcons/epoch-addons/tree/master/unitscan)
