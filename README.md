# Kraken AD&D 2E Character Wizard

A guided character-creation wizard for **AD&D 2nd Edition** in **Fantasy Grounds Unity**, styled after the 5E Character Wizard.

Tabbed flow: **Abilities → Race → Class → Kit → Alignment → Equipment → Proficiencies → Commit.**

## Install (players / testers)

Grab the latest [**Release**](../../releases/latest) and:

1. Put `KrakenCharWizard2E.ext` in your Fantasy Grounds data folder under `extensions\`.
2. Put `The Drowned Archive.mod` under `modules\`.
   - Data folder is usually `%appdata%\SmiteWorks\Fantasy Grounds`.
3. Launch FGU, load a 2E campaign (as host), click **Extensions** on the load screen, and enable **Kraken AD&D 2E Character Wizard**.
4. In game, open **Library → Modules** and activate **The Drowned Archive**.
5. Open the Characters list and click the wizard icon to build a character.

### Requirements (commercial — not included)
- Fantasy Grounds Unity
- The AD&D 2E ruleset
- The 2E **Player's Handbook** module — races, classes, kits, spells, and nonweapon proficiencies are read from it. Without it those lists are empty.

## The Drowned Archive (companion module)
Supplies the wizard's Equipment tab with "(Poor)" starter gear (intentionally one step worse than standard, so players upgrade), 20 family heirlooms, and an auto-unpacking **Adventure Pack (Poor)**.

## Develop / release

This repository **is** the live extension folder — edit in place and FGU loads it live.

Cut a release (rebuilds the `.ext`, grabs the current `.mod`, and publishes both as GitHub Release assets):

```sh
python release.py             # tag from extension.xml version, e.g. v1.0-beta1
python release.py v1.0-beta2  # explicit tag
```

If you change **The Drowned Archive campaign**, re-export the module from FGU (or rebuild it) before releasing — `release.py` warns when the bundled `.mod` is older than the campaign source.

## License
TBD
