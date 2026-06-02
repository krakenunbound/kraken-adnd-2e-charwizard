--
-- Kraken AD&D 2E Character Wizard - Abilities page.
-- Method V: roll 4d6-drop-lowest, arrange to taste (drag to swap),
-- exceptional Strength percentile on a natural 18 STR.
--

local _tSlotByKey = {};
local _tSlotByName = {};
local _bSuppressCombo = false; -- guard against re-entrant combo onValueChanged

-- Faded full-frame wallpaper behind the labels and lore (shared helper).
function ensureAbilitiesArt()
	CharWizard2E.applyWallpaper(abilities_art, "charwizard2e_abilities_art");
end

function onInit()
	_tSlotByKey = {
		strength = str_score,
		dexterity = dex_score,
		constitution = con_score,
		intelligence = int_score,
		wisdom = wis_score,
		charisma = cha_score,
	};
	_tSlotByName = {
		str_score = str_score,
		dex_score = dex_score,
		con_score = con_score,
		int_score = int_score,
		wis_score = wis_score,
		cha_score = cha_score,
	};
	lore_text.setValue(Interface.getString("charwizard2e_lore_abilities"));
	ensureAbilitiesArt();
	buildMethodCombo();
	refreshFromData();
end

-- Called by the manager when this tab becomes visible.
function onPageShow()
	lore_text.setValue(Interface.getString("charwizard2e_lore_abilities"));
	ensureAbilitiesArt();
	buildMethodCombo();
	refreshFromData();
end

function refreshFromData()
	for _, sAbility in ipairs(DataCommon.abilities) do
		local c = _tSlotByKey[sAbility];
		if c then
			c.setValue(CharWizard2E.getAbilityScore(sAbility));
		end
	end
	updateStrPercentUI();
	updateMethodUI();
end

-- Populate the method dropdown with the DM-allowed methods and select the current.
function buildMethodCombo()
	_bSuppressCombo = true;
	method_combo.clear();
	for _, n in ipairs(CharWizard2E.getAllowedAbilityMethods()) do
		method_combo.add(CharWizard2E.getAbilityMethodLabel(n));
	end
	method_combo.setValue(CharWizard2E.getAbilityMethodLabel(CharWizard2E.getAbilityMethod()));
	_bSuppressCombo = false;
end

function onMethodComboChanged()
	if _bSuppressCombo then return; end
	local sSel = method_combo.getValue();
	for _, n in ipairs(CharWizard2E.getAllowedAbilityMethods()) do
		if CharWizard2E.getAbilityMethodLabel(n) == sSel then
			CharWizard2E.setAbilityMethod(n);
			break;
		end
	end
	refreshFromData();
end

-- Single source of truth for the method UI: roll-lock (big dice), dropdown value,
-- per-ability dice visibility, header, and hint.
function updateMethodUI()
	local bLocked = CharWizard2E.isRollLocked() and CharWizard2E.hasRolledAbilities();
	roll_button.setVisible(not bLocked);

	_bSuppressCombo = true;
	method_combo.setValue(CharWizard2E.getAbilityMethodLabel());
	_bSuppressCombo = false;
	abilities_header.setValue("Ability Scores -- " .. CharWizard2E.getAbilityMethodLabel());

	-- Per-ability dice only where rolling/placing ONE ability fits the method
	-- (the in-order methods + Method VI placement). The "arrange" array methods
	-- hide them -- you roll the whole array with the big dice, then drag-arrange.
	local bPer = CharWizard2E.abilityMethodPerAbility();
	roll_str.setVisible(bPer);
	roll_dex.setVisible(bPer);
	roll_con.setVisible(bPer);
	roll_int.setVisible(bPer);
	roll_wis.setVisible(bPer);
	roll_cha.setVisible(bPer);

	if CharWizard2E.getAbilityMethod() == 6 then
		local tPool = CharWizard2E.getViPool();
		if #tPool > 0 then
			table.sort(tPool, function(a, b) return a > b; end);
			hint_label.setValue("Method VI: click an ability's dice icon to add the largest die that fits (max 18).  Unplaced dice: "
				.. table.concat(tPool, "  "));
		else
			hint_label.setValue("Method VI: every ability starts at 8. Click the big dice to roll 7d6, then place each die into an ability with its own dice icon (whole die, max 18).");
		end
	else
		hint_label.setValue(Interface.getString(
			bLocked and "charwizard2e_label_hint_locked" or "charwizard2e_label_hint"));
	end
end

-- Manager calls this after rolls; the method UI is the single source of truth
-- (it handles the roll-lock button + hint).
function updateRollLock()
	updateMethodUI();
end

--
-- Rolling
--

-- Manager clears the slots before an animated roll batch starts.
function resetSlots()
	for _, sAbility in ipairs(DataCommon.abilities) do
		_tSlotByKey[sAbility].setValue(0);
		CharWizard2E.setAbilityScore(sAbility, 0);
	end
	CharWizard2E.setStrPercent(0);
	updateStrPercentUI();
	CharWizard2E.updateTabStatus();
end

-- Manager pushes each animated ability result back here.
function setSlotValue(sAbility, n)
	local c = _tSlotByKey[sAbility];
	if c then
		c.setValue(n);
	end
	CharWizard2E.setAbilityScore(sAbility, n);
	onAbilitiesChanged();
end

--
-- Arrange to taste (drag one score onto another to swap)
--

function onSlotDragStart(sName, nValue, draginfo)
	-- Only "arrange to taste" methods allow rearranging; in-order / placement
	-- methods (I, II, VI) keep the scores where they landed.
	if not CharWizard2E.abilityMethodArranges() then
		return false;
	end
	if (nValue or 0) <= 0 then
		return false;
	end
	draginfo.setType("charwiz_ability_swap");
	draginfo.setStringData(sName);
	draginfo.setNumberData(nValue);
	draginfo.setDescription(tostring(nValue));
	return true;
end

function onSlotDrop(sTargetName, draginfo)
	if draginfo.getType() ~= "charwiz_ability_swap" then
		return false;
	end
	local sSourceName = draginfo.getStringData();
	if sSourceName == sTargetName then
		return true;
	end
	local cSrc = _tSlotByName[sSourceName];
	local cTgt = _tSlotByName[sTargetName];
	if not cSrc or not cTgt then
		return true;
	end

	local nTargetOld = cTgt.getValue();
	cTgt.setValue(draginfo.getNumberData());
	cSrc.setValue(nTargetOld);

	storeAll();
	onAbilitiesChanged();
	return true;
end

-- Sync all slot values back into the shared build state.
function storeAll()
	for sAbility, c in pairs(_tSlotByKey) do
		CharWizard2E.setAbilityScore(sAbility, c.getValue());
	end
end

function onAbilitiesChanged()
	updateStrPercentUI();
	CharWizard2E.updateTabStatus();
end

--
-- Exceptional Strength (natural 18 STR)
--

function updateStrPercentUI()
	local bExceptional = (str_score.getValue() == 18);
	-- Hide the % roll button once rolled if the DM locked re-rolls.
	local bSpecLocked = CharWizard2E.isRollLocked() and CharWizard2E.hasRolledStrPct();
	strpct_button.setVisible(bExceptional and not bSpecLocked);

	local nPct = CharWizard2E.getStrPercent();
	if not bExceptional then
		strpct_label.setValue("");
	elseif nPct > 0 then
		local sPct = (nPct == 100) and "00" or string.format("%02d", nPct);
		strpct_label.setValue("18/" .. sPct);
	else
		strpct_label.setValue(Interface.getString("charwizard2e_strpct_prompt"));
	end
end

-- Manager pushes the d100 exceptional-strength result back here.
function setStrPercent(n)
	CharWizard2E.setStrPercent(n);
	updateStrPercentUI();
end
