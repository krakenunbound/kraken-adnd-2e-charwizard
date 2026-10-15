--
-- Proficiencies & Languages tab. Gated on class (slot counts come from class).
--   * Weapon proficiencies - class-filtered weapon list, slot-limited.
--   * Languages - racial tongues shown as known + spend INT-bonus extra picks.
--   (Spells have their own tab: page_spells.lua.)
--

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

	-- The nonweapon list is the last section: let it fill a stretched window.
	nwp_list.setAnchor("bottom", "bottomanchor", "bottom", "relative", -12);

	if bHaveClass then
		known_label.setValue(string.format(
			Interface.getString("charwizard2e_lang_known"),
			table.concat(CharWizard2E.getRaceKnownLanguages(), ", ")));
		updateSlots();
		buildWeaponList();
		buildLanguageList();
		buildNWPList();
	end
end

function setSectionsVisible(bVisible)
	weapon_header.setVisible(bVisible);
	weapon_slots.setVisible(bVisible);
	weapon_kitnote.setVisible(bVisible and (weapon_kitnote.getValue() or "") ~= "");
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

-- Slot counters (used / total). Called live by rows as they add/remove.
function updateSlots()
	weapon_slots.setValue(string.format(
		Interface.getString("charwizard2e_weapon_slots"),
		CharWizard2E.getWeaponSlotsUsed(), CharWizard2E.getWeaponSlots()));
	local sKitNote = CharWizard2E.getKitWeaponNote();
	weapon_kitnote.setValue(sKitNote);
	weapon_kitnote.setVisible(sKitNote ~= "");
	language_slots.setValue(string.format(
		Interface.getString("charwizard2e_lang_slots"),
		CharWizard2E.getLanguagesUsed(), CharWizard2E.getLanguageCount()));
	nwp_slots.setValue(string.format(
		Interface.getString("charwizard2e_nwp_slots"),
		CharWizard2E.getNWPUsed(), CharWizard2E.getNWPSlots()));
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
