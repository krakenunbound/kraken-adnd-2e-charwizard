--
-- Proficiencies & Languages tab. Gated on class (slot counts come from class).
--   * Weapon proficiencies - class-filtered weapon list, slot-limited.
--   * Languages - racial tongues shown as known + spend INT-bonus extra picks.
--   * Spells - class-filtered, viewed one spell level at a time.
--

-- Spell level the picker is currently showing (0 = all levels at once).
local nSpellFilter = 1;

function onInit()
	CharWizard2E.applyWallpaper(proficiencies_art, "charwizard2e_proficiencies_art");
	refresh();
end

function onPageShow()
	CharWizard2E.applyWallpaper(proficiencies_art, "charwizard2e_proficiencies_art");
	refresh();
end

function refresh()
	local bHaveClass = CharWizard2E.isClassComplete();
	label_needclass.setVisible(not bHaveClass);
	setSectionsVisible(bHaveClass);

	local bCaster = bHaveClass and (CharWizard2E.getCasterType() ~= nil);
	setSpellSectionVisible(bCaster);

	-- Grow the last visible list to fill a stretched window. For casters the spell
	-- list already grows to the bottom (XML); for everyone else the NWP list is the
	-- last section, so anchor IT to the bottom (it was leaving dead space below).
	if bCaster then
		nwp_list.setAnchor("bottom", "nwp_slots", "bottom", "relative", 194); -- fixed ~190 tall
	else
		nwp_list.setAnchor("bottom", "bottomanchor", "bottom", "relative", -12); -- fill to bottom
	end

	if bHaveClass then
		known_label.setValue(string.format(
			Interface.getString("charwizard2e_lang_known"),
			table.concat(CharWizard2E.getRaceKnownLanguages(), ", ")));
		updateSlots();
		buildWeaponList();
		buildLanguageList();
		buildNWPList();
		if bCaster then
			nSpellFilter = 1;
			buildSpellList();
			updateSpellLevelUI();
		end
	end
end

function setSectionsVisible(bVisible)
	weapon_header.setVisible(bVisible);
	weapon_slots.setVisible(bVisible);
	weapon_list.setVisible(bVisible);
	language_header.setVisible(bVisible);
	known_label.setVisible(bVisible);
	language_slots.setVisible(bVisible);
	language_list.setVisible(bVisible);
	nwp_header.setVisible(bVisible);
	nwp_slots.setVisible(bVisible);
	nwp_list.setVisible(bVisible);
	if not bVisible then
		weapon_list.closeAll();
		language_list.closeAll();
		nwp_list.closeAll();
	end
end

function setSpellSectionVisible(bVisible)
	spell_header.setVisible(bVisible);
	spell_info.setVisible(bVisible);
	spell_lvl_prev.setVisible(bVisible);
	spell_lvl_all.setVisible(bVisible);
	spell_lvl_next.setVisible(bVisible);
	spell_list.setVisible(bVisible);
	if not bVisible then
		spell_list.closeAll();
	end
end

-- Slot counters (used / total). Called live by rows as they add/remove.
function updateSlots()
	weapon_slots.setValue(string.format(
		Interface.getString("charwizard2e_weapon_slots"),
		CharWizard2E.getWeaponSlotsUsed(), CharWizard2E.getWeaponSlots()));
	language_slots.setValue(string.format(
		Interface.getString("charwizard2e_lang_slots"),
		CharWizard2E.getLanguagesUsed(), CharWizard2E.getLanguageCount()));
	nwp_slots.setValue(string.format(
		Interface.getString("charwizard2e_nwp_slots"),
		CharWizard2E.getNWPUsed(), CharWizard2E.getNWPSlots()));
	if CharWizard2E.getCasterType() ~= nil then
		updateSpellLevelUI();
	end
end

-- Spell-level filter: which level the list is showing, plus a per-level tally
-- (current level bracketed) so the player can see how many they can take and
-- have taken at each level.
function updateSpellLevelUI()
	local tParts = {};
	for nLvl = 1, CharWizard2E.getMaxSpellLevel() do
		local sSeg = string.format("L%d %d/%d", nLvl,
			CharWizard2E.getSpellsUsedAtLevel(nLvl), CharWizard2E.getSpellSlots(nLvl));
		if nLvl == nSpellFilter then sSeg = "[" .. sSeg .. "]"; end
		table.insert(tParts, sSeg);
	end
	local sShown = (nSpellFilter == 0) and "all levels" or string.format("Level %d", nSpellFilter);
	spell_info.setValue(string.format("Showing %s.    %s", sShown, table.concat(tParts, "   ")));
end

function onSpellLevelSet(n)
	local nMax = CharWizard2E.getMaxSpellLevel();
	if n < 0 then n = 0; elseif n > nMax then n = nMax; end
	nSpellFilter = n;
	buildSpellList();
	updateSpellLevelUI();
end

function onSpellLevelStep(nDelta)
	local nMax = CharWizard2E.getMaxSpellLevel();
	local n = (nSpellFilter <= 0 and 1 or nSpellFilter) + nDelta;
	if n < 1 then n = 1; elseif n > nMax then n = nMax; end
	onSpellLevelSet(n);
end

function buildWeaponList()
	weapon_list.closeAll();
	local bSpec = CharWizard2E.canSpecialize();
	for _, sName in ipairs(CharWizard2E.buildWeaponCatalog()) do
		local w = weapon_list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.button_spec.setVisible(bSpec);
			w.wpnname.setValue(sName);
			w.updateMark();
		end
	end
end

function buildLanguageList()
	language_list.closeAll();
	for _, sName in ipairs(CharWizard2E.buildLanguageCatalog()) do
		local w = language_list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.langname.setValue(sName);
			w.updateMark();
		end
	end
end

function buildNWPList()
	nwp_list.closeAll();
	for _, rNWP in ipairs(CharWizard2E.buildNWPCatalog()) do
		local w = nwp_list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.nwpname.setValue(rNWP.sName);
			w.nwppath.setValue(rNWP.sPath);
			if rNWP.sPath and rNWP.sPath ~= "" then
				w.shortcut.setValue("reference_skill", rNWP.sPath); -- click to read the skill
			end
			w.updateMark();
		end
	end
end

function buildSpellList()
	spell_list.closeAll();
	for _, rSpell in ipairs(CharWizard2E.buildSpellCatalog()) do
		if nSpellFilter == 0 or rSpell.nLevel == nSpellFilter then
			local w = spell_list.createWindow();
			if w then
				w.button_select.setVisible(true);
				w.spellpath.setValue(rSpell.sPath);
				w.spelllevel.setValue(tostring(rSpell.nLevel));
				w.spellname.setValue(string.format("(%d) %s", rSpell.nLevel, rSpell.sName));
				if rSpell.sPath and rSpell.sPath ~= "" then
					w.shortcut.setValue("reference_spell", rSpell.sPath); -- click to read the spell
				end
				w.updateMark();
			end
		end
	end
end
