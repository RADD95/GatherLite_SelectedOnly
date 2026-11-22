# GatherLite: Selected Only

**GatherLite: Selected Only** is a lightweight, high-performance companion addon for [GatherLite](https://www.curseforge.com/wow/addons/gatherlite) on World of Warcraft Forever.

Tired of opening your World Map only to find it completely cluttered with thousands of nodes from every profession? **GatherLite: Selected Only** adds a discreet toggle button right next to GatherLite's map button, allowing you to display **strictly the resources, fish, or route points you are currently tracking**.

---

## ✨ Features

- 🎯 **Only Show What You Need:** Instantly filters out non-selected herbs, ores, and fish. When you select Copper Ore or Peacebloom in the GatherLite sidebar, only those nodes are shown.
- ⚡ **Route & Fishing Plugin Integration:** Automatically detects nodes from active routes (`/gatherroutes`) and selected fish catches (`/gather` fishing).
- 🧹 **Instant Clean Map (Hide-All Mode):** Shift + Left Click instantly hides all pins from the World Map without losing your settings—perfect for questing or reading zone geography.
- 🚀 **High Performance & Zero Lag:** Fully optimized hooks designed to prevent FPS drops even while viewing or drawing paths with `/gatherroutes`.
- 🗺️ **World Map & Minimap Control:** Control World Map filtering and Minimap filtering independently.
- 🌐 **Localization:** Full native support for English (`enUS`, `enGB`) and Spanish (`esES`, `esMX`).
- 🛡️ **Zero Modifications to GatherLite:** Safe, non-destructive hooks (`hooksecurefunc` and non-polluting wrappers) that will not break when GatherLite is updated.

---

## 🎮 Controls & Shortcuts

The addon adds a spyglass icon directly to the World Map header (next to the GatherLite button):

| Action | Function |
| :--- | :--- |
| **Left Click** | Toggle **Selected Only** filter on the **World Map** |
| **Right Click** | Toggle **Selected Only** filter on the **Minimap** |
| **Shift + Left Click** | **Hide / Restore ALL pins** on the **World Map** |
| **Shift + Right Click** | **Hide / Restore ALL pins** on the **Minimap** |
| **Hover** | Displays active filter status and list of currently selected resources |

---

## ⌨️ Slash Commands

You can also control the addon via `/glonly` or `/glselectedonly`:

- `/glonly` : Toggle 'Selected Only' filter on the World Map.
- `/glonly minimap` (or `/glonly mini`) : Toggle 'Selected Only' filter on the Minimap.
- `/glonly hide` (or `/glonly hideall`) : Toggle Hide All pins on the World Map.
- `/glonly hide mini` : Toggle Hide All pins on the Minimap.
- `/glonly status` : Prints full diagnostic audit (active resources, allowed IDs, anchor status).
- `/glonly reset` : Clears caches and forces a map pin refresh.
- `/glonly help` : Lists all available commands.

---

## 📦 Requirements

- **World of Warcraft:** WoW Forever
- **Dependency:** [GatherLite](https://www.curseforge.com/wow/addons/gatherlite)

---

## 📄 License

Distributed under the MIT License. Free to use, modify, and distribute.
