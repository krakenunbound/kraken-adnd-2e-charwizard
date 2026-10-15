# Changelog

All releases: [GitHub Releases](../../releases). Install steps: [README](README.md#install) and the [Install & User Guide](GUIDE.md).

## Unreleased

- **Weapon names on the Actions tab.** Gear bought in the wizard is now marked identified, so each attack shows the weapon's name ("Club, Spiked") instead of its unidentified name ("Club Spiked"). Weapons whose book entry has no unidentified name (Battle Axe, Longsword, Two-handed Sword, the crossbows, Quarterstaff and about 40 more) showed a blank line; they now show their name.
- **Weapon proficiencies list every weapon your class may use**, not only a short recommended list. The recommended weapons still come first, then every other weapon the shop sells your class, A-Z. A fighter could buy a Spiked Club but not take a proficiency in it.
- **Shop search clears when you change the gear type**, so a word left in the box ("sling") no longer empties the new list.

## v1.0-beta4 (2026-10-14)

**Players can create characters.**
- Before this release only the GM (host) could create a character with the wizard. A player's **Create Character** stopped with "only the GM (host) can create characters with this tool in this version".
- Now a player joins, opens **Characters**, clicks the wizard icon, and **Create Character** asks the GM's table for a new character sheet that the player owns, the same as the **+** on Character Selection. The wizard then builds it as before.
- The GM only enables the extension; players install nothing. The campaign needs a free character slot.
- The release now also has a zip with the extension in an `extensions` folder and a Read Me, ready to unzip into the Fantasy Grounds data folder.

## v1.0-beta3 (2026-10-14)

- **Uses every official 2E book you load**, not only the Player's Handbook: the DMG, the Complete Fighter's, Thief's, Priest's, Wizard's, Bard's, Ranger's, Paladin's, Druid's and Barbarian's Handbooks, the Complete Books of Dwarves, Elves, Gnomes & Halflings and Humanoids, Demihuman Deities (specialty priests of the demihuman gods), the Complete Book of Necromancers and Tome of Magic.
- **Filters as you go:**
  - races your rolled scores allow (PHB Table 7, a splatbook race's own score ranges);
  - classes your race may take and your scores qualify for (PHB minimums, a splatbook class's requirements);
  - kits your class, race and scores allow;
  - alignments your class allows.
- **A shop that makes sense:**
  - only the weapons your class may use and the armor it may wear (no plate for a mage);
  - ammunition only for launchers it can use, plus everyday gear from the PHB and your class's own handbook;
  - only what your rolled gold still covers;
  - sorted by type (armor, weapons, ammunition, gear) with a type filter and search;
  - magic items are never in the starting shop.
- **Save unfinished:** **Create Character** works at any point; whatever is still open is listed at the top of the sheet's notes (and in chat) to finish with your DM.
- **Specialty priests** now get their own rules: weapons, armor, spheres and spells by their deity.
- **Half-ogres** and other races with shared score ranges ("a/b") are read correctly.
- New screenshots, README and guide.

## v1.0-beta2 (2026-06-03)

- **Ability Methods III and IV** now roll separate 3d6 groups (six for Method III to arrange; twelve for Method IV, keeping the best six) instead of one big total. Cleaner chat summary.

## v1.0-beta1 (2026-06-02)

First beta. Tabs: Abilities, Race, Class, Kit, Alignment, Equipment, Proficiencies, Commit. Included:
- AC total fix (no more AC 0);
- poor-armor AC penalties (one step worse than standard);
- Adventure Pack (Poor) auto-unpacks;
- coins split into GP/SP/CP;
- weapon-attack name backfill.
