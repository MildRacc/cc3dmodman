# CrazyCattle3D Mod Loader - User Guide

---

## What is the Mod Loader?

The CrazyCattle3D Mod Loader lets you change the game with custom modifications created by the community. Mods can add new features, change visuals, introduce new mechanics, and more.

---

## Installation

1. Download the CrazyCattle3D Mod Loader
2. Extract it to a folder on your computer
3. Launch the game using the `cc3dmodman` executable

---

## Mods

### Installing a Mod

1. Download the mod (usually a `.zip` file)
2. Extract the mod folder
3. Place the extracted folder in the `mods/` directory next to the `cc3dmodman` executable
4. Your folder structure should look like:
   ```
   cc3dmodman.exe
   mods/
   └── ModName/
       ├── mod.json
       ├── main.gd
       └── assets/
   ```
5. Launch the game - mods load automatically

### Removing Mods

To disable a mod:
- Delete or move the mod's folder out of the `mods/` directory, or uncheck the mod in the CC3DModMan application window
- Restart the game

---

## Troubleshooting

### Mod Not Loading

- Check that the mod folder is directly inside `mods/`
- Verify the folder contains `mod.json` and `main.gd`
- Check for error messages in the console

### Game Crashes

- Try removing recently installed mods one at a time
- Some mods may conflict with each other
- Check mod descriptions for compatibility information

### Performance Issues

- Some mods may be resource-intensive
- Try disabling visual effect mods if experiencing lag
- Check your system meets the recommended requirements

---

## Mod Information

Each mod contains a `mod.json` file with information about:
- **Name**: The mod's display name
- **Description**: What the mod does
- **Author**: Who created the mod
- **Version**: The mod's version number

You can view this information by opening the `mod.json` file in any text editor.