# cc3dmodman (Crazy Cattle 3D Mod Manager)

An **unofficial**, reversible mod manager / mod loader for Crazy Cattle 3D.  
The first public tool that lets you load multiple mods without permanently modifying the game.

## Community Mods
You can share your mods or download others in the [community Discord server](https://discord.gg/RPZvdXMhGT).

![gameplay](docs/media/gameplay.gif)

## What it does
- Lets you enable/disable mods without repackaging the game
- Restores the game to its original state when you’re done
- Supports Windows and Linux

## How to use
1. Extract the release folder anywhere.
2. Run `cc3dmodman`.
3. Select the Crazy Cattle 3D executable when prompted.
4. Launch.

## Mods
The release includes a few example mods to get started:
- Rocket booster
- Gun mod
- Cosmetic accessories
- Simple UI / overlay tweaks

You can add your own mods by dropping them into the [mods/](mods/) folder.

## Notes
- Mods are applied at runtime using a local copy of the game data.
- Your original game files are not permanently modified.
- To uninstall, just delete the folder.

## Making mods
Documentation for the modding API and examples is in [docs/](docs/).  
If you can write basic GDScript, you can make a mod.

## Disclaimer
This project is not affiliated with or endorsed by [4nn4t4t](https://4nn4t4t.itch.io/), the CrazyCattle3D developer.
