# Changelog

All releases: [GitHub Releases](../../releases). Install steps: [README](README.md#install) and the [Install & User Guide](GUIDE.md).

## Unreleased

- **DM option: Starting gold above 1st level** (Options > Kraken Character Wizard). The PHB leaves extra funds for a higher-level start to the DM. *PHB (one roll)* keeps Table 43 at any level (default); *One roll per level* rolls the group's Table 43 dice once per level and adds them up (a 5th-level warrior rolls 25d4 x 10); *Roll x level* multiplies one roll by the level. Both give the same average (a 5th-level warrior about 625 gp: plate mail about half the time, field plate never before 16th); one roll per level spreads much less, so players of the same level end up evenly equipped. Changing the level after rolling clears the roll.
- **Proficiency slots grow with the starting level** (PHB Table 34): a 5th-level fighter starts with 5 weapon and 4 nonweapon slots, not 4 and 3. Warriors gain a weapon slot every 3 levels, priests and rogues every 4, wizards every 6; nonweapon slots every 3 levels (rogues every 4). Kits that fix a career total (Witch, Envoy) keep it.

## v1.0-beta5 (2026-10-15)

- **Weapon names on the Actions tab.** Gear bought in the wizard is now marked identified, so each attack shows the weapon's name ("Club, Spiked") instead of its unidentified name ("Club Spiked"). Weapons whose book entry has no unidentified name (Battle Axe, Longsword, Two-handed Sword, the crossbows, Quarterstaff and about 40 more) showed a blank line; they now show their name.
- **Weapon proficiencies list every weapon your class may use**, not only a short recommended list. The recommended weapons still come first, then every other weapon the shop sells your class, A-Z. A fighter could buy a Spiked Club but not take a proficiency in it.
- **Clerics keep to blunt weapons** (PHB: "Any blunt or bludgeoning weapon"), judged by each weapon's damage type in its book: a morning star (piercing and bludgeoning) is allowed, a spiked club (piercing) is not.
- **Kit weapon rules** from the kits' own Weapon Proficiencies text, for the books' 200+ kits: weapons a kit is limited to (Loremaster, Jester, Beggar, Seeker...), forbidden weapons (Meistersinger, Gypsy-bard, Peasant Hero), no missile weapons (Berserker, Ravager, Battlerager), weapons a kit adds (Bandit, Ritual Priest, wizard kits), required weapons listed first with a note under the slot count, and slot changes (Witch none, Brute and Envoy two, Thespian, Medician and Seeker one; Samurai, Thug, Swashbuckler and others get their extra slots).
- **Recommended weapons use the books' item names**, so a proficiency always attaches to its weapon on the sheet (a proficiency named "Mace" matched neither the footman's nor the horseman's mace).
- **Spells follow sphere access and specialist schools** (PHB): clerics no longer get plant, animal or weather spells and get elemental spells only up to 3rd level; druids get their own spheres; spells of a god's specialty priests (Demihuman Deities) are left out; specialist wizards lose their opposition schools and gain their extra spell per level; Wild Magic spells only for wild mages.
- A scabbard or baldric typed as a weapon in its book is sold as gear, not offered as a weapon proficiency.
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
