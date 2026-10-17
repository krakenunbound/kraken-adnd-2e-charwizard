# Changelog

All releases: [GitHub Releases](../../releases). Install steps: [README](README.md#install) and the [Install & User Guide](GUIDE.md).

## v1.0-beta8 (2026-10-16)

- **Multi-class and dual-class characters** (PHB Chapter 3). The Class tab has a **Class type** box under the starting level:
  - **Multi-class** (demihumans only): the combinations in the PHB's Multi-Class Combinations table for the race that include the chosen class (an elf fighter: Fighter/Mage, Fighter/Thief, Fighter/Mage/Thief; a gnome illusionist: Fighter/Illusionist, Cleric/Illusionist, Illusionist/Thief...). Offered only when the scores meet every class's minimums and some alignment suits every class; paladins, bards and specialist wizards (except gnome illusionists) can't multi-class. Every class advances to the starting level, each stopping at the race's limit for it (a halfling fighter/thief at 12th is Fighter 9 / Thief 12).
  - **Dual-class** (humans only): 15 or more in the first class's prime requisites, 17 or more in the new class's. Set the first class's levels (at least 2nd); the starting level is the new class's. The sheet gets the first class marked inactive: no new hit points until the new class passes the old one's level.
  - Hit points split between the classes, best THAC0 and saves (the sheet's own multi-class handling). Proficiency slots: the largest initial number and the fastest rate (PHB), also written to the sheet. Starting gold rolled for the most generous class. A multi-class priest keeps his priest weapons (a fighter/cleric uses blunt weapons; a fighter/druid the druid's), a multi-class fighter can't specialize, and a priest returns leftover gold only when every class is a priest.
  - Spells for each casting class at its own level: the Spells tab has a caster box (Mage / Cleric) when there are two, and each class's spells go to the sheet in their own groups ("Mage Level 1", "Cleric Level 1").
- **Dual-class rules from the class handbooks**: a paladin needs 15 in Strength, Constitution and Wisdom to change class (Complete Paladin's Handbook); barbarians dual-class only between barbarian fighter and shaman, with Dexterity, Constitution and the new class's own score at 17 (Complete Barbarian's Handbook).
- **Kits for multi-class characters**: the Complete Fighter's and Thief's Handbooks' kits are for single-class characters only, so a multi-class doesn't see them; priest kits and the race books' multi-class kits (Complete Book of Elves: Bladesinger, War Wizard...; Dwarves; Gnomes and Halflings) are offered; barbarian kits only to a dwarf fighter/cleric. One kit in all.
- **Experience on the sheet**: each class gets the experience its starting level needs (a 5th-level fighter 16,000; a Fighter 4 / Mage 3 dual-class 8,000 and 5,000), the character's total is their sum, marked as already granted.
- **Alignment limits for every class** (PHB): rangers always good, bards at least partly neutral, thieves never lawful good, besides paladins and druids. A multi- or dual-class meets all of its classes' limits.

## v1.0-beta7 (2026-10-15)

- **Spells have their own tab**, right after Kit, shown only for a class that casts at the chosen level (and checked automatically for one that doesn't). Before, the spell list sat below the proficiency lists and was out of sight unless the window was stretched.
- **Spell guidance**: the top of the tab says how many spells of each level the class gets at the chosen level and what it may use (a specialist's extra spell and barred schools, a priest's spheres, Wisdom bonus spells). One button per spell level shows picked / allowed ("2nd 1/3", green when full) and switches the list; a School or Sphere filter and a Search box narrow it; each spell shows its school or sphere. Picking past the limit says so in chat.
- **Bards, paladins and rangers cast**: bards wizard spells from 2nd level (PHB Table 32), paladins priest spells of the combat, divination, healing and protection spheres from 9th (Table 17), rangers plant and animal spells from 8th (Table 18); no Wisdom bonus spells for paladins and rangers. A multi-class character with a mage class gets mage spells.
- Tabs are a little narrower so nine fit.
- **Weapon proficiencies tick on every attack of the weapon**: a Staff sling gives two attacks, "Staff- sling (Bullet)" and "Staff- sling (Stone)", and neither was marked proficient because the names differ in punctuation. Matching now ignores punctuation and also goes by the inventory item each attack comes from.
- **Removed the DM options "Grant free starter items" and "Allow family heirloom items"** and the Equipment tab's Free Starter Kit and heirloom sections. Both depended on a supplement module the wizard no longer uses; everything is now bought with the rolled gold.

## v1.0-beta6 (2026-10-15)

- **DM option: Starting gold above 1st level** (Options > Kraken Character Wizard). The PHB leaves extra funds for a higher-level start to the DM. *PHB (one roll)* keeps Table 43 at any level (default); *One roll per level* rolls the group's Table 43 dice once per level and adds them up (a 5th-level warrior rolls 25d4 x 10); *Roll x level* multiplies one roll by the level. Both give the same average (a 5th-level warrior about 625 gp: plate mail about half the time, field plate never before 16th); one roll per level spreads much less, so players of the same level end up evenly equipped. Changing the level after rolling clears the roll.
- **Priests return their leftover gold** (PHB Table 43): after shopping a priest (cleric, druid, specialty priest) keeps 3 gp and the rest goes back to his order; chat says how much. Multi-class characters with a warrior, rogue or wizard class keep theirs.
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
