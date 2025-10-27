**description = "Multi-slot saveloc system with HUD, instant menu teleport, and true hold/release bind"**

A SourceMod plugin for movement practice servers (surf, bhop, KZ, etc.).  
Players can save up to **500 savelocs per player**, teleport back to them, and use either a menu or a keybind for advanced control.

---

## ✨ Features
- Save up to **500 savelocs per player**
- Each saveloc stores:
  - Position
  - View angles
  - Velocity
- **Menu system** (`sm_savelocmenu`) for saving, teleporting, and cycling through slots
- **Keybind system** for true hold/release teleport control:
  - Hold key → teleport and freeze
  - Release key → unfreeze and restore velocity
- Per-player storage, cleared automatically on map change

---

## 📥 Installation
1. Compile the `.sp` file with SourceMod’s compiler.
2. Place the compiled `.smx` file into your server’s `addons/sourcemod/plugins/` folder.
3. Restart the server or change the map.

---

## 🎮 Commands

### Menu & Saving
- `sm_savelocmenu`  
  Opens the saveloc HUD menu with options:
  - **Save** → save your current position, angles, and velocity
  - **Teleport** → teleport to your current saveloc
  - **Previous / Next** → cycle through saved slots and teleport

### Keybind (Hold/Release)
- `+sm_teleport`  
  Teleports you to your current saveloc and **freezes** you in place until you let go of the key it is bound to.
  For example, bind mouse4 to "+sm_teleport", when you hold mouse4, it will teleport and freeze until you let go of the bind.
  
- `sm_saveloc`  
  Saves your current location into the next available slot.  
  If you already have 500 slots, the oldest one is removed.

### Teleporting
- `sm_tele <slot>`  
  Teleports you to a specific slot number (1–500).  
  Example: `/tele 7` → teleports to slot 7.

- `sm_tele`  
  Instantly teleports you to your currently selected slot (the one you last saved or cycled to).
