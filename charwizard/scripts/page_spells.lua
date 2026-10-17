--
-- Spells tab: the caster's starting spells. The top says how many of each
-- spell level the class gets at the chosen level and which schools or spheres
-- it may use; one button per spell level shows picked / allowed and switches
-- the list; a school/sphere filter and a search box narrow it.
--

-- Spell level the list is showing (0 = all levels at once).
local nSpellFilter = 1;

function onInit()
	CharWizard2E.applyWallpaper(spells_art, "charwizard2e_proficiencies_art");
	refresh();
end

function onPageShow()
	CharWizard2E.applyWallpaper(spells_art, "charwizard2e_proficiencies_art");
	refresh();
end

local function isCaster()
	return CharWizard2E.isClassComplete() and CharWizard2E.getMaxSpellLevel() > 0;
end

local _bFillingCaster = false;

-- The caster box: one entry per spell-casting class (shown with two or more).
function fillCaster()
	local tCasters = CharWizard2E.getCasterEntries();
	_bFillingCaster = true;
	spell_caster.clear();
	for _, c in ipairs(tCasters) do
		spell_caster.add(c.label);
	end
	local cActive = CharWizard2E.getActiveCaster();
	if cActive then spell_caster.setValue(cActive.label); end
	_bFillingCaster = false;
	spell_caster.setVisible(#tCasters > 1);
end

function onCasterChanged()
	if _bFillingCaster then
		return;
	end
	CharWizard2E.setActiveCasterByLabel(spell_caster.getValue());
	refresh();
end

function refresh()
	if CharWizard2E.isClassComplete() then
		fillCaster();
	else
		spell_caster.setVisible(false);
	end
	local bHaveClass = CharWizard2E.isClassComplete();
	local bCaster = isCaster();
	label_nocaster.setValue(Interface.getString(bHaveClass and "charwizard2e_msg_nocaster" or "charwizard2e_msg_needclass_for_spells"));
	label_nocaster.setVisible(not bCaster);
	for _, c in ipairs({ spell_guide, spell_filter_label, spell_filter, spell_search_label, spell_search, spell_list }) do
		c.setVisible(bCaster);
	end
	spell_list.closeAll();
	if not bCaster then
		for n = 0, 9 do self["spell_lvl_" .. n].setVisible(false); end
		return;
	end
	spell_guide.setValue(CharWizard2E.getSpellGuidance());
	local bDivine = CharWizard2E.getCasterType() == "divine";
	spell_filter_label.setValue(Interface.getString(bDivine and "charwizard2e_spell_sphere" or "charwizard2e_spell_school"));
	fillFilter(bDivine);
	nSpellFilter = 1;
	buildSpellList();
	updateSlots();
end

-- The filter choices: every school or sphere named by the spells offered.
function fillFilter(bDivine)
	local tSeen, tList = {}, {};
	for _, r in ipairs(CharWizard2E.buildSpellCatalog()) do
		for sPart in (r.sSchool or ""):gmatch("[^,/]+") do
			sPart = StringManager.trim(sPart);
			local sKey = sPart:lower();
			if sPart ~= "" and not tSeen[sKey] then
				tSeen[sKey] = true;
				table.insert(tList, StringManager.capitalize(sPart));
			end
		end
	end
	table.sort(tList);
	spell_filter.clear();
	spell_filter.add(Interface.getString("charwizard2e_spell_any"));
	for _, s in ipairs(tList) do spell_filter.add(s); end
	spell_filter.setValue(Interface.getString("charwizard2e_spell_any"));
end

-- Level buttons: "1st 2/4" (picked / allowed), the shown level highlighted,
-- green when that level is full. Called when a spell is added or removed.
function updateSlots()
	if not isCaster() then return; end
	local nMax = CharWizard2E.getMaxSpellLevel();
	for n = 1, 9 do
		local c = self["spell_lvl_" .. n];
		if n <= nMax then
			local nUsed, nAllowed = CharWizard2E.getSpellsUsedAtLevel(n), CharWizard2E.getSpellSlots(n);
			c.setValue(string.format("%s %d/%d", CharWizard2E.ordinal(n), nUsed, nAllowed));
			c.setColor(n == nSpellFilter and "FFFFFF" or (nUsed >= nAllowed and "2E7D32" or "000000"));
			c.setFrame(n == nSpellFilter and "buttondown" or "fieldlight", 7, 5, 7, 5);
			c.setVisible(true);
		else
			c.setVisible(false);
		end
	end
	spell_lvl_0.setValue(Interface.getString("charwizard2e_spell_lvl_all"));
	spell_lvl_0.setColor(nSpellFilter == 0 and "FFFFFF" or "000000");
	spell_lvl_0.setFrame(nSpellFilter == 0 and "buttondown" or "fieldlight", 7, 5, 7, 5);
	spell_lvl_0.setVisible(true);
end

function onSpellLevelSet(n)
	local nMax = CharWizard2E.getMaxSpellLevel();
	if n < 0 then n = 0; elseif n > nMax then n = nMax; end
	nSpellFilter = n;
	buildSpellList();
	updateSlots();
end

function buildSpellList()
	spell_list.closeAll();
	local sAny = Interface.getString("charwizard2e_spell_any");
	local sFilter = (spell_filter.getValue() or ""):lower();
	if sFilter == sAny:lower() then sFilter = ""; end
	local sSearch = StringManager.trim(spell_search.getValue() or ""):lower();
	for _, r in ipairs(CharWizard2E.buildSpellCatalog()) do
		local bShow = (nSpellFilter == 0 or r.nLevel == nSpellFilter)
			and (sFilter == "" or (r.sSchool or ""):lower():find(sFilter, 1, true))
			and (sSearch == "" or r.sName:lower():find(sSearch, 1, true));
		if bShow then
			local w = spell_list.createWindow();
			if w then
				w.button_select.setVisible(true);
				w.spellpath.setValue(r.sPath);
				w.spelllevel.setValue(tostring(r.nLevel));
				w.spellname.setValue(string.format("(%d) %s", r.nLevel, r.sName));
				w.spellschool.setValue(r.sSchool or "");
				if r.sPath and r.sPath ~= "" then
					w.shortcut.setValue("reference_spell", r.sPath); -- click to read the spell
				end
				w.updateMark();
			end
		end
	end
end
