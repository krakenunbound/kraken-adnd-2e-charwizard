--
-- Kraken AD&D 2E Character Wizard
-- Global manager: data enumeration, dice rolling, and character commit.
--
-- Borrows the high-level pattern from the 5E charwizard (gather choices, then
-- commit to a real charsheet) but drives the existing 2E CharManager functions
-- to do the heavy lifting (race/class application, advancement, HP, THAC0, etc.).
--

aAlignments = {
	"Lawful Good", "Neutral Good", "Chaotic Good",
	"Lawful Neutral", "True Neutral", "Chaotic Neutral",
	"Lawful Evil", "Neutral Evil", "Chaotic Evil",
};

-- The wizard window currently receiving dice results (rolls are async).
local _wActive = nil;

function onInit()
	ActionsManager.registerResultHandler("charwiz_ability", onAbilityResult);
	ActionsManager.registerResultHandler("charwiz_strpct", onStrPctResult);
	ActionsManager.registerResultHandler("charwiz_wealth", onWealthResult);
	ActionsManager.registerResultHandler("charwiz_heirloom", onHeirloomResult);

	-- DM toggle (Options > "Kraken Character Wizard" > "Grant free starter items").
	-- Global (not bLocal) so it is a host/campaign setting; default off. When on,
	-- a new character is granted its free class kit (instrument, holy symbol,
	-- thieves' picks, spellbook, ...) plus an adventuring pack, at no gold cost.
	OptionsManager.registerOption2("CWFI", false, "option_header_charwizard2e",
		"option_label_free_items", "", { default = "off" });

	-- DM toggle: when on, abilities can be rolled only once per character (no
	-- re-rolling until you like the numbers). Global/host setting, default off.
	OptionsManager.registerOption2("CWRL", false, "option_header_charwizard2e",
		"option_label_roll_lock", "", { default = "off" });

	-- DM toggle: when on, the Equipment tab offers a random "family heirloom" roll
	-- (The Drowned Archive table), added to the new character. Global, default off.
	OptionsManager.registerOption2("CWHEIR", false, "option_header_charwizard2e",
		"option_label_heirloom", "", { default = "off" });

	-- DM toggles: which PHB ability-score generation methods players may pick from
	-- on the Abilities tab. The player chooses among whichever are enabled. Global.
	OptionsManager.registerOption2("CWM1", false, "option_header_charwizard2e",
		"option_label_method1", "", { default = "on" });   -- 3d6 in order
	OptionsManager.registerOption2("CWM2", false, "option_header_charwizard2e",
		"option_label_method2", "", { default = "on" });   -- 3d6 arrange
	OptionsManager.registerOption2("CWM3", false, "option_header_charwizard2e",
		"option_label_method3", "", { default = "on" });   -- best of six 3d6
	OptionsManager.registerOption2("CWM4", false, "option_header_charwizard2e",
		"option_label_method4", "", { default = "on" });   -- 12 sets, keep best 6
	OptionsManager.registerOption2("CWM5", false, "option_header_charwizard2e",
		"option_label_method5", "", { default = "on" });   -- 4d6 drop lowest
	OptionsManager.registerOption2("CWM6", false, "option_header_charwizard2e",
		"option_label_method6", "", { default = "on" });   -- all 8s + place 7d6
end

function setActiveWindow(w)
	_wActive = w;
end

--
-- Wizard shell: window registration, tab switching, shared build state.
--

local _wMain = nil;
local _tCharData = {};
local _tTabs = { "abilities", "race", "class", "kit", "alignment", "equipment", "proficiencies", "commit" };

function registerWindow(w)
	_wMain = w;
	_tCharData = {};
	CharWizard2E.onTabButtonPressed(w, "abilities");
	updateTabStatus();
end

function unregisterWindow(w)
	if _wMain == w then
		_wMain = nil;
	end
	if _wActive == w then
		_wActive = nil;
	end
end

function getMainWindow()
	return _wMain;
end

-- Show one page subwindow and highlight its tab; hide the rest.
function onTabButtonPressed(w, sTab)
	if not w then
		return;
	end
	for _, v in ipairs(_tTabs) do
		local cButton = w.sub_tabs and w.sub_tabs.subwindow and w.sub_tabs.subwindow["button_" .. v];
		local cSub = w["sub_" .. v];
		if cButton then
			cButton.setFrame(v == sTab and "buttondown" or "buttonup", 5, 5, 5, 5);
		end
		if cSub then
			cSub.setVisible(v == sTab);
		end
	end
	local cTarget = w["sub_" .. sTab];
	if cTarget and cTarget.subwindow and cTarget.subwindow.onPageShow then
		cTarget.subwindow.onPageShow();
	end
	updateTabStatus();
end

--
-- Tab completion (5E-style checkmark / alert icons on each tab button).
--

function areAbilitiesComplete()
	for _, sAbility in ipairs(DataCommon.abilities) do
		if getAbilityScore(sAbility) <= 0 then
			return false;
		end
	end
	return true;
end

function isRaceComplete()
	local t = getRace();
	if not t or not t.text or t.text == "" then
		return false;
	end
	if getRacePending() then
		return false;
	end
	return true;
end

function isClassComplete()
	local t = getClass();
	if not t or not t.text or t.text == "" then
		return false;
	end
	if getClassPending() then
		return false;
	end
	return true;
end

-- Kit is its own tab after Class. Optional, but green requires an explicit
-- decision (pick a kit OR press "No Kit") so it isn't pre-checked.
function isKitComplete()
	return isClassComplete() and (_tCharData.kitchosen == true);
end

function isAlignmentComplete()
	local t = getAlignment();
	return t and t.text and t.text ~= "";
end

function isEquipmentComplete()
	return isWealthRolled();
end

-- Green once a class is chosen and the weapon + nonweapon slots are fully spent.
-- (Still optional for commit -- isReadyToCommit does not require it -- but this
-- gives the tab a real red->green progression instead of being pre-checked.)
function isProficienciesComplete()
	if not isClassComplete() then
		return false;
	end
	if getWeaponSlotsUsed() < getWeaponSlots() then
		return false;
	end
	if getNWPUsed() < getNWPSlots() then
		return false;
	end
	return true;
end

function isTabComplete(sTab)
	if sTab == "abilities" then
		return areAbilitiesComplete();
	elseif sTab == "race" then
		return isRaceComplete();
	elseif sTab == "class" then
		return isClassComplete();
	elseif sTab == "kit" then
		return isKitComplete();
	elseif sTab == "alignment" then
		return isAlignmentComplete();
	elseif sTab == "equipment" then
		return isEquipmentComplete();
	elseif sTab == "proficiencies" then
		return isProficienciesComplete();
	elseif sTab == "commit" then
		return isReadyToCommit();
	end
	return false;
end

function updateTabStatus()
	local w = getMainWindow();
	if not w or not w.sub_tabs or not w.sub_tabs.subwindow then
		return;
	end
	local wTabs = w.sub_tabs.subwindow;
	for _, sTab in ipairs(_tTabs) do
		local cButton = wTabs["button_" .. sTab];
		if cButton and cButton.addBitmapWidget then
			local cStatus = cButton.findWidget("tabstatus");
			if not cStatus then
				cStatus = cButton.addBitmapWidget();
				cStatus.setPosition("bottomright", -5, -5);
				cStatus.setSize(20, 20);
				cStatus.setName("tabstatus");
			end
			if isTabComplete(sTab) then
				cStatus.setBitmap("button_dialog_ok_down");
				cStatus.setVisible(true);
			else
				cStatus.setBitmap("button_dialog_check_red");
				cStatus.setVisible(true);
			end
		end
	end
end

--
-- Shared build state accessors.
--

function getData()
	return _tCharData;
end

-- Snapshot for the Commit tab / createCharacter().
function getBuildPayload(sName)
	return {
		name = sName or getBuildName(),
		alignment = getAlignmentName(),
		abilities = _tCharData.abilities or {},
		strpercent = getStrPercent(),
		racelink = getRace(),
		classlink = getClass(),
		kitlink = getKit(),
		targetlevel = getTargetLevel(),
		equipment = getEquipmentData(),
	};
end

-- Character name typed on the Commit tab (persists across tab switches).
function getBuildName()
	return _tCharData.name or "";
end
function setBuildName(s)
	_tCharData.name = s or "";
end

-- Required choices for a valid character (kit and equipment are optional).
function isReadyToCommit()
	return areAbilitiesComplete() and isRaceComplete()
		and isClassComplete() and isAlignmentComplete();
end

-- List of human-readable warnings for missing required choices.
function getBuildWarnings()
	local t = {};
	if not areAbilitiesComplete() then
		table.insert(t, Interface.getString("charwizard2e_warn_abilities"));
	end
	if not isRaceComplete() then
		table.insert(t, Interface.getString("charwizard2e_warn_race"));
	end
	if not isClassComplete() then
		table.insert(t, Interface.getString("charwizard2e_warn_class"));
	end
	if not isAlignmentComplete() then
		table.insert(t, Interface.getString("charwizard2e_warn_alignment"));
	end
	-- Soft (non-blocking) notes.
	if not isWealthRolled() then
		table.insert(t, Interface.getString("charwizard2e_warn_wealth"));
	end
	return t;
end

-- Multi-line read-only summary of every choice, for the Commit tab.
function getBuildSummaryText()
	local tLines = {};
	local function add(sLabel, sValue)
		table.insert(tLines, sLabel .. ": " .. (sValue or ""));
	end

	-- Abilities (with exceptional STR percentile when present).
	local tAb = _tCharData.abilities or {};
	local tParts = {};
	for _, sAb in ipairs(DataCommon.abilities) do
		local n = tAb[sAb] or 0;
		local s = sAb:sub(1, 3):upper() .. " " .. n;
		if sAb == "strength" and n == 18 and getStrPercent() > 0 then
			s = s .. "/" .. string.format("%02d", getStrPercent());
		end
		table.insert(tParts, s);
	end
	add(Interface.getString("charwizard2e_sum_abilities"), table.concat(tParts, "   "));

	local tRace = getRace();
	if tRace and tRace.text and tRace.text ~= "" then
		local sRace = tRace.text;
		if tRace.parenttext and tRace.parenttext ~= "" then
			sRace = string.format("%s (%s)", tRace.parenttext, tRace.text);
		end
		add(Interface.getString("charwizard2e_sum_race"), sRace);
	end

	if getClassName() ~= "" then
		add(Interface.getString("charwizard2e_sum_class"), getClassDisplayName());
	end

	if getAlignmentName() ~= "" then
		add(Interface.getString("charwizard2e_sum_alignment"), getAlignmentName());
	end

	if isWealthRolled() then
		add(Interface.getString("charwizard2e_sum_gold"), string.format("%d gp", getStartingGold()));
	end

	add(Interface.getString("charwizard2e_sum_freebies"),
		Interface.getString(getDmFreebies() and "charwizard2e_val_on" or "charwizard2e_val_off"));

	local tItems = getChosenItems();
	if #tItems > 0 then
		local tNames = {};
		for _, r in ipairs(tItems) do
			local s = r.sName or "";
			if (r.nQty or 1) > 1 then
				s = s .. " x" .. r.nQty;
			end
			table.insert(tNames, s);
		end
		add(Interface.getString("charwizard2e_sum_items"), table.concat(tNames, ", "));
	end

	return table.concat(tLines, "\r");
end

-- Close the wizard window (called after a successful create).
function closeWizard()
	if _wMain then
		_wMain.close();
	end
end

--
-- Character details / bio (Commit tab). Persisted in _tCharData.bio; keys match
-- the charsheet "notes" field names so applyBio can write them 1:1.
--
local _tBioFields = {
	"gender", "age", "agemax", "height", "weight", "size", "deity",
	"personalitytraits", "ideals", "bonds", "flaws", "appearance", "notes",
};

function getBioFieldKeys()
	return _tBioFields;
end

function getBio()
	_tCharData.bio = _tCharData.bio or {};
	return _tCharData.bio;
end

function getBioField(sKey)
	return getBio()[sKey] or "";
end

function setBioField(sKey, sValue)
	getBio()[sKey] = sValue or "";
end

-- Fill race/gender-derived fields the player hasn't set yet (size, age, max age,
-- height, weight; gender is rolled so the body tables have something to use).
function autofillBioDefaults()
	local tBio = getBio();
	if (tBio.gender or "") == "" then
		tBio.gender = CharWizard2EBio.rollGender();
	end
	local sRace = getRaceCategoryName();
	if sRace ~= "" then
		if (tBio.size or "") == "" then tBio.size = CharWizard2EBio.getSize(sRace); end
		if (tBio.age or "") == "" then tBio.age = CharWizard2EBio.rollAge(sRace); end
		if (tBio.agemax or "") == "" then tBio.agemax = CharWizard2EBio.rollMaxAge(sRace); end
		if (tBio.height or "") == "" then tBio.height = CharWizard2EBio.rollHeight(sRace, tBio.gender); end
		if (tBio.weight or "") == "" then tBio.weight = CharWizard2EBio.rollWeight(sRace, tBio.gender); end
	end
end

function getAbilityScore(sAbility)
	return (_tCharData.abilities or {})[sAbility] or 0;
end
function setAbilityScore(sAbility, n)
	_tCharData.abilities = _tCharData.abilities or {};
	_tCharData.abilities[sAbility] = n or 0;
end
function getStrPercent()
	return _tCharData.strpercent or 0;
end
function setStrPercent(n)
	_tCharData.strpercent = n or 0;
end

function getRace()
	return _tCharData.race;
end
function setRace(t)
	_tCharData.race = t;
end
function getRacePending()
	return _tCharData.racepending;
end
function setRacePending(t)
	_tCharData.racepending = t;
end
function clearRacePending()
	_tCharData.racepending = nil;
	_tCharData.subraces = nil;
end
function getPendingSubraces()
	return _tCharData.subraces;
end
function setPendingSubraces(t)
	_tCharData.subraces = t;
end
function getRaceName()
	return (_tCharData.race and _tCharData.race.text) or "";
end
-- PHB Table 7 uses the parent race (e.g. Halfling), not the subrace label (Stout).
function getRaceCategoryName()
	local t = _tCharData.race;
	if not t then
		return "";
	end
	return t.parenttext or t.text or "";
end
function getClass()
	return _tCharData.class;
end
function setClass(t)
	_tCharData.class = t;
end

local function notifyRacePage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_race and wMain.sub_race.subwindow and wMain.sub_race.subwindow.updateRaceUI then
		wMain.sub_race.subwindow.updateRaceUI();
	end
end

local function notifyClassPage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_class and wMain.sub_class.subwindow and wMain.sub_class.subwindow.updateClassUI then
		wMain.sub_class.subwindow.updateClassUI();
	end
end

local function notifyKitPage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_kit and wMain.sub_kit.subwindow and wMain.sub_kit.subwindow.updateKitUI then
		wMain.sub_kit.subwindow.updateKitUI();
	end
end

local function notifyAlignmentPage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_alignment and wMain.sub_alignment.subwindow and wMain.sub_alignment.subwindow.updateAlignmentUI then
		wMain.sub_alignment.subwindow.updateAlignmentUI();
	end
end

local function notifyEquipmentPage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_equipment and wMain.sub_equipment.subwindow and wMain.sub_equipment.subwindow.updateEquipmentUI then
		wMain.sub_equipment.subwindow.updateEquipmentUI();
	end
end

-- Refresh only the slot counters on the Profs page (no list rebuild, so it's
-- safe to call from inside a row's add/remove click).
local function notifyProficienciesPage()
	local wMain = getMainWindow();
	if wMain and wMain.sub_proficiencies and wMain.sub_proficiencies.subwindow
			and wMain.sub_proficiencies.subwindow.updateSlots then
		wMain.sub_proficiencies.subwindow.updateSlots();
	end
	updateTabStatus(); -- slots changed -> the Profs tab check may flip
end

function clearClass()
	_tCharData.class = nil;
	_tCharData.classpending = nil;
	_tCharData.kits = nil;
	_tCharData.kit = nil;
	_tCharData.kitchosen = nil;
	_tCharData.alignment = nil;
	_tCharData.equipment = nil;
	_tCharData.profs = nil; -- weapon allowance/slots depend on class
	_tCharData.targetlevel = nil; -- level cap depends on class
	notifyClassPage();
	notifyKitPage();
	notifyAlignmentPage();
	notifyEquipmentPage();
	updateTabStatus();
end

function getClassPending()
	return _tCharData.classpending;
end
function setClassPending(t)
	_tCharData.classpending = t;
end
function clearClassPending()
	_tCharData.classpending = nil;
	_tCharData.kits = nil;
end
function getPendingKits()
	return _tCharData.kits;
end
function setPendingKits(t)
	_tCharData.kits = t;
end
function getKit()
	return _tCharData.kit;
end
function setKit(t)
	_tCharData.kit = t;
end
function getKitName()
	return (_tCharData.kit and _tCharData.kit.text) or "";
end

function getClassName()
	-- During the kit-selection step the class is "pending" (committed only once a
	-- kit is picked or skipped). Fall back to the pending class so kit filtering
	-- evaluates against the class the player just chose.
	if _tCharData.class and _tCharData.class.text then
		return _tCharData.class.text;
	end
	if _tCharData.classpending and _tCharData.classpending.text then
		return _tCharData.classpending.text;
	end
	return "";
end

function getClassDisplayName()
	local sClass = getClassName();
	local sKit = getKitName();
	if sClass == "" then
		return "";
	end
	if sKit ~= "" then
		return string.format("%s (%s)", sClass, sKit);
	end
	return sClass;
end

-- PHB Table 7 demihuman class/level limits (base values; ability scores can raise
-- these in play). 20 == effectively unlimited. Humans have no limit.
local _tLevelLimits = {
	dwarf        = { fighter = 15, cleric = 10, thief = 12, default = 12 },
	elf          = { fighter = 12, ranger = 15, mage = 15, cleric = 12, thief = 20, druid = 12, default = 12 },
	gnome        = { fighter = 11, cleric = 9, thief = 20, illusion = 15, mage = 15, default = 11 },
	["half-elf"] = { fighter = 14, ranger = 16, cleric = 14, mage = 12, druid = 20, thief = 20, bard = 20, default = 14 },
	halfling     = { fighter = 9, cleric = 8, thief = 20, default = 12 },
	["half-orc"] = { fighter = 10, cleric = 4, thief = 8, default = 10 },
};

-- Highest level the current race may attain in the current class (PHB Table 7).
function getRaceClassMaxLevel()
	local sRace = getRaceCategoryName():lower();
	local sClass = getClassName():lower();
	if sRace == "" or sClass == "" then
		return 20;
	end
	local tLimits;
	if sRace:find("half", 1, true) and sRace:find("elf", 1, true) then
		tLimits = _tLevelLimits["half-elf"];
	elseif sRace:find("half", 1, true) and sRace:find("orc", 1, true) then
		tLimits = _tLevelLimits["half-orc"];
	elseif sRace:find("dwarf", 1, true) or sRace:find("dwarv", 1, true) then
		tLimits = _tLevelLimits.dwarf;
	elseif sRace:find("elf", 1, true) or sRace:find("elv", 1, true) then
		tLimits = _tLevelLimits.elf;
	elseif sRace:find("gnome", 1, true) then
		tLimits = _tLevelLimits.gnome;
	elseif sRace:find("halfling", 1, true) then
		tLimits = _tLevelLimits.halfling;
	else
		return 20; -- human / unlisted: unlimited
	end
	for sKey, nCap in pairs(tLimits) do
		if sKey ~= "default" and sClass:find(sKey, 1, true) then
			return nCap;
		end
	end
	return tLimits.default or 12;
end

function getTargetLevel()
	local n = tonumber(_tCharData.targetlevel) or 1;
	return math.max(1, math.min(n, getRaceClassMaxLevel()));
end

function setTargetLevel(n)
	n = math.max(1, math.min(tonumber(n) or 1, getRaceClassMaxLevel()));
	_tCharData.targetlevel = n;
	updateTabStatus();
end

-- Does this source-book label look like a Player's Handbook?
function isPlayersHandbookLabel(sLabel)
	local s = (sLabel or ""):lower();
	return (s:find("player", 1, true) ~= nil) and (s:find("handbook", 1, true) ~= nil);
end

-- Faded full-frame wallpaper used on each wizard page. Pass the page's
-- (square) art genericcontrol and a registered icon name. The art is scaled to
-- *cover* the whole frame (square source, so draw = the larger frame side,
-- centered), then tinted to ~15% so it reads as a background behind the content.
function applyWallpaper(cControl, sIcon)
	if not cControl or not cControl.addBitmapWidget then
		return;
	end
	local cExisting = cControl.findWidget and cControl.findWidget("cw2e_wallpaper");
	if cExisting then
		cExisting.destroy();
	end

	local nBoxW, nBoxH = 700, 470;
	if cControl.getSize then
		local w, h = cControl.getSize();
		if w and w > 0 then nBoxW = w; end
		if h and h > 0 then nBoxH = h; end
	end
	local nDraw = math.max(nBoxW, nBoxH);

	local cWidget = cControl.addBitmapWidget({
		name = "cw2e_wallpaper",
		icon = sIcon,
		position = "center",
		x = 0,
		y = 0,
		w = nDraw,
		h = nDraw,
	});
	if cWidget and cWidget.setColor then
		cWidget.setColor("26FFFFFF"); -- ~15% opacity white tint
	end
end

-- The source label that pickers should default to: a Player's Handbook if one is
-- present in the list, otherwise "" (All). Lets the player default to core content
-- and opt into other books manually.
function getDefaultSourceLabel(tLabels)
	for _, s in ipairs(tLabels or {}) do
		if isPlayersHandbookLabel(s) then
			return s;
		end
	end
	-- Looser fallback: any label mentioning "player".
	for _, s in ipairs(tLabels or {}) do
		if (s or ""):lower():find("player", 1, true) then
			return s;
		end
	end
	return "";
end

function getAlignment()
	return _tCharData.alignment;
end
function setAlignment(t)
	_tCharData.alignment = t;
end
function clearAlignment()
	_tCharData.alignment = nil;
	notifyAlignmentPage();
	updateTabStatus();
end
function getAlignmentName()
	return (_tCharData.alignment and _tCharData.alignment.text) or "";
end

local function raceNodeHasSubraces(node)
	if not node then
		return false;
	end
	local tChildren = DB.getChildren(node, "subraces");
	return tChildren and next(tChildren) ~= nil;
end

local function buildSubraceTable(nodeParent)
	local tGrouped = {};
	for _, vSub in pairs(DB.getChildren(nodeParent, "subraces") or {}) do
		local sName = StringManager.trim(DB.getValue(vSub, "name", ""));
		if sName ~= "" then
			local rRecord = {};
			rRecord.vNode = vSub;
			rRecord.sDisplayName = sName;
			rRecord.sDisplayNameLower = sName:lower();
			rRecord.sLinkClass = "reference_subrace";
			rRecord.sModuleName = DB.getModule(vSub) or "";
			local tInfo = Module.getModuleInfo(rRecord.sModuleName);
			rRecord.sModule = (tInfo and tInfo.displayname) or rRecord.sModuleName;
			if rRecord.sModule == "" then
				rRecord.sModule = Interface.getString("charwizard2e_book_campaign");
			end
			tGrouped[rRecord.sDisplayNameLower] = tGrouped[rRecord.sDisplayNameLower] or {};
			table.insert(tGrouped[rRecord.sDisplayNameLower], rRecord);
		end
	end
	return tGrouped;
end

local function finalizeRace(tRace, sChatName)
	setRace(tRace);
	clearRacePending();
	clearClassPending();
	_tCharData.class = nil;
	_tCharData.kit = nil;
	_tCharData.alignment = nil;
	_tCharData.equipment = nil;
	notifyClassPage();
	notifyAlignmentPage();
	notifyEquipmentPage();
	ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_racepicked"), sChatName or tRace.text or ""));
	notifyRacePage();
	updateTabStatus();
end

-- User picked a base race from the list (+ button).
function processRace(wEntry)
	if not wEntry then
		return;
	end

	local sClass, sRecord = wEntry.shortcut.getValue();
	local node = DB.findNode(sRecord);
	local sName = node and DB.getValue(node, "name", "") or wEntry.name.getValue();
	local sBook = wEntry.module.getValue();

	if node and raceNodeHasSubraces(node) then
		setRacePending({
			text = sName,
			linkclass = sClass or "reference_race",
			linkrecord = sRecord,
			book = sBook,
		});
		setPendingSubraces(buildSubraceTable(node));
		setRace(nil);
		clearClassPending();
		_tCharData.class = nil;
		_tCharData.kit = nil;
		_tCharData.alignment = nil;
		_tCharData.equipment = nil;
		notifyClassPage();
		notifyAlignmentPage();
		notifyEquipmentPage();
		notifyRacePage();
		updateTabStatus();
		return;
	end

	finalizeRace({
		text = sName,
		linkclass = sClass or "reference_race",
		linkrecord = sRecord,
		book = sBook,
		issubrace = false,
	}, sName);
end

-- User picked a subrace after choosing a parent race that has subraces.
function processSubrace(wEntry)
	if not wEntry then
		return;
	end

	local tPending = getRacePending();
	if not tPending then
		return;
	end

	local sClass, sRecord = wEntry.shortcut.getValue();
	local node = DB.findNode(sRecord);
	local sSubName = node and DB.getValue(node, "name", "") or wEntry.name.getValue();
	local sDisplay = string.format("%s (%s)", tPending.text, sSubName);

	finalizeRace({
		text = sSubName,
		parenttext = tPending.text,
		linkclass = sClass or "reference_subrace",
		linkrecord = sRecord,
		book = wEntry.module.getValue(),
		parentlink = {
			text = tPending.text,
			linkclass = tPending.linkclass,
			linkrecord = tPending.linkrecord,
			book = tPending.book,
		},
		issubrace = true,
	}, sDisplay);
end

-- Kit filtering: read explicit class/race fields on the kit record, then fall back to
-- handbook module name patterns (Complete Fighter's Handbook, etc.).
--
-- Notes on the 2E source books these target:
--  * The "Complete Book of ..." race titles are PLURAL ("Dwarves", "Elves"), so
--    the singular race word is NOT a substring -- match the plural stems.
--  * Order matters: patterns are tested top-to-bottom and the first whose text is
--    found in the module name wins, so multi-word / combined titles come first.
--  * A pattern may restrict by class AND race (e.g. Demihuman Deities = priest kits
--    for demihumans); the character must satisfy EVERY dimension the book restricts.
local _tHumanoidRaces = {
	"orc", "half-orc", "goblin", "hobgoblin", "kobold", "gnoll", "bugbear",
	"ogre", "troll", "lizard", "centaur", "minotaur", "satyr", "giant",
	"mongrel", "aarakocra", "alaghi", "bullywug", "flind", "swanmay", "wemic",
};
local _tArcaneClasses = {
	"mage", "wizard", "abjurer", "conjurer", "diviner", "enchanter",
	"invoker", "necromancer", "transmuter", "illusion",
};
local _tKitBookPatterns = {
	-- Race books (Complete Book of ...). Combined title first so it wins.
	{ pattern = "gnomes and halflings", races = { "gnome", "halfling" } },
	{ pattern = "dwarves", races = { "dwarf" } },
	{ pattern = "dwarf", races = { "dwarf" } },
	{ pattern = "elves", races = { "elf", "half-elf" } },
	{ pattern = "elf", races = { "elf", "half-elf" } },
	{ pattern = "gnomes", races = { "gnome" } },
	{ pattern = "gnome", races = { "gnome" } },
	{ pattern = "halflings", races = { "halfling" } },
	{ pattern = "halfling", races = { "halfling" } },
	{ pattern = "humanoids", races = _tHumanoidRaces },
	{ pattern = "humanoid", races = _tHumanoidRaces },
	-- Class books (Complete <Class>'s Handbook, etc.). Warrior books (Fighter's,
	-- Barbarian's) are usable by all warriors (fighter, ranger, paladin, barbarian).
	{ pattern = "barbarian", classes = { "fighter", "ranger", "paladin", "barbarian" } },
	{ pattern = "fighter", classes = { "fighter", "ranger", "paladin" } },
	{ pattern = "ranger", classes = { "ranger" } },
	{ pattern = "paladin", classes = { "paladin" } },
	-- Demihuman Deities: priest kits restricted to demihuman races.
	{ pattern = "demihuman deities", classes = { "cleric", "priest" },
		races = { "dwarf", "elf", "half-elf", "gnome", "halfling" } },
	{ pattern = "priest", classes = { "cleric", "priest" } },
	{ pattern = "druid", classes = { "druid" } },
	{ pattern = "thief", classes = { "thief" } },
	{ pattern = "bard", classes = { "bard" } },
	{ pattern = "necromancer", classes = { "mage", "wizard", "necromancer" } },
	-- Tome of Magic adds both wizard and priest material.
	{ pattern = "tome of magic", classes = { "mage", "wizard", "abjurer", "conjurer",
		"diviner", "enchanter", "invoker", "necromancer", "transmuter", "illusion",
		"cleric", "priest" } },
	{ pattern = "wizard", classes = _tArcaneClasses },
};

local function parseRestrictionList(sValue)
	local tOut = {};
	for sPart in string.gmatch((sValue or ""):lower(), "[^,;/]+") do
		sPart = StringManager.trim(sPart);
		if sPart ~= "" and sPart ~= "any" and sPart ~= "all" then
			table.insert(tOut, sPart);
		end
	end
	return tOut;
end

local function addRestrictionFromNode(node, tOut)
	if not node then
		return;
	end
	local sName = StringManager.trim(DB.getValue(node, "name", ""));
	if sName ~= "" then
		table.insert(tOut, sName:lower());
		return;
	end
	local sClass, sRecord = DB.getValue(node, "shortcut", "", "");
	if sClass == "" then
		sClass, sRecord = DB.getValue(node, "link", "", "");
	end
	if sRecord ~= "" then
		local nodeRef = DB.findNode(sRecord);
		if nodeRef then
			sName = StringManager.trim(DB.getValue(nodeRef, "name", ""));
			if sName ~= "" then
				table.insert(tOut, sName:lower());
			end
		end
	end
end

local function collectKitRestrictions(node)
	local tClasses = {};
	local tRaces = {};

	for _, sField in ipairs({ "class", "classes", "classrestriction", "allowedclass", "classreq" }) do
		for _, sPart in ipairs(parseRestrictionList(DB.getValue(node, sField, ""))) do
			table.insert(tClasses, sPart);
		end
	end
	for _, sField in ipairs({ "race", "races", "racerestriction", "allowedrace", "racereq" }) do
		for _, sPart in ipairs(parseRestrictionList(DB.getValue(node, sField, ""))) do
			table.insert(tRaces, sPart);
		end
	end
	for _, sChild in ipairs({ "classes", "classlist", "races", "racelist" }) do
		for _, vChild in pairs(DB.getChildren(node, sChild) or {}) do
			if sChild:find("class", 1, true) then
				addRestrictionFromNode(vChild, tClasses);
			else
				addRestrictionFromNode(vChild, tRaces);
			end
		end
	end

	return tClasses, tRaces;
end

local function nameMatchesKeyword(sName, sKeyword)
	if sName == "" or sKeyword == "" then
		return false;
	end
	return sName:find(sKeyword, 1, true) or sKeyword:find(sName, 1, true);
end

local function restrictionsAllow(tRequired, sChosen)
	if #tRequired == 0 then
		return true;
	end
	sChosen = (sChosen or ""):lower();
	for _, sReq in ipairs(tRequired) do
		if nameMatchesKeyword(sChosen, sReq) then
			return true;
		end
	end
	return false;
end

local function classMatchesAny(sClass, tKeywords)
	for _, sKeyword in ipairs(tKeywords) do
		if sClass:find(sKeyword, 1, true) then
			return true;
		end
	end
	return false;
end

local function raceMatchesAny(sRace, tKeywords)
	for _, sKeyword in ipairs(tKeywords) do
		if nameMatchesKeyword(sRace, sKeyword) then
			return true;
		end
	end
	return false;
end

local function modulePatternAllows(sModuleName, sClassName, sRaceName)
	local sMod = (sModuleName or ""):lower();
	-- Campaign-created / PHB kits (no source module) are always offered.
	if sMod == "" then
		return true;
	end
	local sClass = (sClassName or ""):lower();
	local sRace = (sRaceName or ""):lower();
	for _, tPattern in ipairs(_tKitBookPatterns) do
		if sMod:find(tPattern.pattern, 1, true) then
			-- The character must satisfy every dimension this book restricts.
			if tPattern.classes and not classMatchesAny(sClass, tPattern.classes) then
				return false;
			end
			if tPattern.races and not raceMatchesAny(sRace, tPattern.races) then
				return false;
			end
			return true;
		end
	end
	-- A named source we don't recognize: leave it visible rather than hide a
	-- potentially valid third-party / homebrew kit.
	return true;
end

function isKitAllowedForCharacter(nodeKit)
	if not nodeKit then
		return false;
	end

	local tClasses, tRaces = collectKitRestrictions(nodeKit);
	local sClassName = getClassName();
	local sRaceName = getRaceCategoryName();
	local sModule = DB.getModule(nodeKit) or "";

	if #tClasses > 0 and not restrictionsAllow(tClasses, sClassName) then
		return false;
	end
	if #tRaces > 0 and not restrictionsAllow(tRaces, sRaceName) then
		return false;
	end
	if #tClasses == 0 and #tRaces == 0 and not modulePatternAllows(sModule, sClassName, sRaceName) then
		return false;
	end
	return true;
end

local function addKitListRecord(vNode, tGrouped)
	local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
	if sName == "" then
		return;
	end
	if not isKitAllowedForCharacter(vNode) then
		return;
	end

	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = sName;
	rRecord.sDisplayNameLower = sName:lower();
	rRecord.sLinkClass = "reference_background";
	rRecord.sModuleName = DB.getModule(vNode) or "";
	local tInfo = Module.getModuleInfo(rRecord.sModuleName);
	rRecord.sModule = (tInfo and tInfo.displayname) or rRecord.sModuleName;
	if rRecord.sModule == "" then
		rRecord.sModule = Interface.getString("charwizard2e_book_campaign");
	end

	tGrouped[rRecord.sDisplayNameLower] = tGrouped[rRecord.sDisplayNameLower] or {};
	table.insert(tGrouped[rRecord.sDisplayNameLower], rRecord);
end

function buildKitTable()
	local tGrouped = {};
	local function addRecord(vNode)
		addKitListRecord(vNode, tGrouped);
	end
	if RecordManager.callForEachRecord then
		RecordManager.callForEachRecord("background", addRecord);
	else
		local tMappings = LibraryData.getMappings("background") or {};
		for _, sMapping in ipairs(tMappings) do
			for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
				addKitListRecord(vNode, tGrouped);
			end
		end
	end
	return tGrouped;
end

-- User picked a class from the list (+ button). The class commits immediately;
-- the kit is chosen separately on the Kit tab.
function processClass(wEntry)
	if not wEntry then
		return;
	end

	local sClass, sRecord = wEntry.shortcut.getValue();
	local node = DB.findNode(sRecord);
	local sName = node and DB.getValue(node, "name", "") or wEntry.name.getValue();

	setClass({
		text = sName,
		linkclass = sClass or "reference_class",
		linkrecord = sRecord,
		book = wEntry.module.getValue(),
	});

	-- Reset everything that depends on class.
	clearClassPending();
	setKit(nil);
	_tCharData.kitchosen = nil;
	_tCharData.alignment = nil;
	_tCharData.equipment = nil;
	_tCharData.profs = nil;
	_tCharData.targetlevel = nil;

	-- Build the kit list for the Kit tab (filtered against the chosen class).
	setPendingKits(buildKitTable());

	ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_classpicked"), sName));
	notifyClassPage();
	notifyKitPage();
	notifyAlignmentPage();
	notifyEquipmentPage();
	updateTabStatus();
end

-- User picked a kit on the Kit tab (+ button).
function processKit(wEntry)
	if not wEntry then
		return;
	end
	local sClass, sRecord = wEntry.shortcut.getValue();
	local node = DB.findNode(sRecord);
	local sKitName = node and DB.getValue(node, "name", "") or wEntry.name.getValue();

	setKit({
		text = sKitName,
		linkclass = sClass or "reference_background",
		linkrecord = sRecord,
		book = wEntry.module.getValue(),
	});
	_tCharData.kitchosen = true;

	ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_kitpicked"), sKitName));
	notifyKitPage();
	updateTabStatus();
end

-- User chose to take no kit (optional).
function processNoKit()
	setKit(nil);
	_tCharData.kitchosen = true;
	notifyKitPage();
	updateTabStatus();
end

-- Re-open the kit choice (Change Kit button on the Kit tab).
function resetKitChoice()
	setKit(nil);
	_tCharData.kitchosen = nil;
	setPendingKits(buildKitTable());
	notifyKitPage();
	updateTabStatus();
end

-- User picked an alignment from the list (+ button).
function processAlignment(wEntry)
	if not wEntry then
		return;
	end

	local sName = StringManager.trim(wEntry.name.getValue() or "");
	if sName == "" then
		return;
	end

	if not isAlignmentAllowedForClass(sName, getClassName()) then
		return;
	end

	setAlignment({ text = sName });
	ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_alignmentpicked"), sName));
	notifyAlignmentPage();
	updateTabStatus();
end

-- Roll all six abilities as animated 4d6-drop-lowest rolls; results route back
-- to the wizard window via the registered result handler.
-- DM "one roll only" lock (Options > Kraken Character Wizard).
function isRollLocked()
	return OptionsManager.isOption("CWRL", "on");
end
function hasRolledAbilities()
	return _tCharData.bRolledAbilities == true;
end
function hasRolledStrPct()
	return _tCharData.bRolledStrPct == true;
end

-- ===== Ability-score generation methods (PHB Methods I-V) =====
-- "each" = roll the dice once per ability; "array" = one roll fills all six.
-- agg: how onAbilityResult turns the rolled dice into a score.
local function _abMakeDice(sDie, n)
	local t = {};
	for i = 1, n do t[i] = sDie; end
	return t;
end
local function _abCopyDice(t)
	local out = {};
	for k, v in pairs(t) do out[k] = v; end
	return out;
end
-- kind: "each" (roll the dice once per ability), "collect" (roll a 3d6 group N
-- times and gather the totals), "vipool" (Method VI 7d6 pool).
-- agg: single | bestgroup | collect mode (array6 | keepbest6) | vipool.
local _tAbilityMethods = {
	-- arrange  = drag-to-rearrange the rolled scores is allowed (the "arrange to
	--            taste" array methods). In-order / placement methods set false.
	-- perAbility = the per-ability dice icon is meaningful (roll/place one ability).
	--            The array methods hide it (you roll the whole array at once).
	[1] = { name = "Method I",   short = "3d6, in order", arrange = false, perAbility = true,
		all = { kind = "each",  aDice = { "d6", "d6", "d6" }, agg = "single" },
		one = { aDice = { "d6", "d6", "d6" }, agg = "single" } },
	[2] = { name = "Method II",  short = "3d6 twice each, keep higher, in order", arrange = false, perAbility = true,
		all = { kind = "each",  aDice = _abMakeDice("d6", 6), agg = "bestgroup" },
		one = { aDice = _abMakeDice("d6", 6), agg = "bestgroup" } },
	[3] = { name = "Method III", short = "3d6 six times, arrange to taste", arrange = true, perAbility = false,
		all = { kind = "collect", aDice = { "d6", "d6", "d6" }, count = 6, agg = "array6" },
		one = { aDice = { "d6", "d6", "d6" }, agg = "single" } },
	[4] = { name = "Method IV",  short = "3d6 twelve times, keep best 6, arrange", arrange = true, perAbility = false,
		all = { kind = "collect", aDice = { "d6", "d6", "d6" }, count = 12, agg = "keepbest6" },
		one = { aDice = { "d6", "d6", "d6" }, agg = "single" } },
	[5] = { name = "Method V",   short = "4d6 drop lowest, arrange", arrange = true, perAbility = false,
		all = { kind = "each",  aDice = { expr = "4d6d1" }, agg = "single" },
		one = { aDice = { expr = "4d6d1" }, agg = "single" } },
	[6] = { name = "Method VI",  short = "all 8s, then place 7d6 (max 18)", arrange = false, perAbility = true,
		all = { kind = "vipool", aDice = _abMakeDice("d6", 7), agg = "vipool" },
		one = { kind = "viplace" } },
};

-- Whether the current method lets you drag-rearrange / shows per-ability dice.
function abilityMethodArranges()
	local meta = _tAbilityMethods[getAbilityMethod()];
	return meta and meta.arrange == true;
end
function abilityMethodPerAbility()
	local meta = _tAbilityMethods[getAbilityMethod()];
	return meta and meta.perAbility == true;
end

-- Methods the DM has enabled in Options (never empty -> falls back to Method V).
function getAllowedAbilityMethods()
	local t = {};
	for n = 1, 6 do
		if OptionsManager.isOption("CWM" .. n, "on") then t[#t + 1] = n; end
	end
	if #t == 0 then t = { 5 }; end
	return t;
end

-- Method VI: the rolled-but-not-yet-placed 7d6 dice.
function getViPool()
	return _tCharData.viPool or {};
end

function getAbilityMethod()
	local tAllowed = getAllowedAbilityMethods();
	local n = _tCharData.abilityMethod;
	for _, m in ipairs(tAllowed) do
		if m == n then return n; end
	end
	for _, m in ipairs(tAllowed) do
		if m == 5 then _tCharData.abilityMethod = 5; return 5; end -- prefer V if allowed
	end
	_tCharData.abilityMethod = tAllowed[1];
	return tAllowed[1];
end

function setAbilityMethod(n)
	_tCharData.abilityMethod = n;
end

function getAbilityMethodLabel(n)
	local meta = _tAbilityMethods[n or getAbilityMethod()];
	if not meta then return ""; end
	return meta.name .. " (" .. meta.short .. ")";
end

local function _abDiceResults(rRoll)
	local t = {};
	for _, d in ipairs(rRoll.aDice or {}) do
		if type(d) == "table" and d.result then t[#t + 1] = d.result; end
	end
	return t;
end
local function _abBestGroup(t, nGroup)
	local nBest = 0;
	for i = 1, #t, nGroup do
		local s = 0;
		for j = i, math.min(i + nGroup - 1, #t) do s = s + t[j]; end
		if s > nBest then nBest = s; end
	end
	return nBest;
end
local function _abGroupSums(t, nGroup)
	local out = {};
	for i = 1, #t, nGroup do
		local s = 0;
		for j = i, math.min(i + nGroup - 1, #t) do s = s + t[j]; end
		out[#out + 1] = s;
	end
	return out;
end
-- Assign a list of scores to the six abilities in order (player can drag-arrange).
local function _abAssignArray(w, tScores)
	for i, sAbility in ipairs(DataCommon.abilities) do
		w.setSlotValue(sAbility, tScores[i] or 0);
	end
end

function rollAllAbilities(w)
	if isRollLocked() and _tCharData.bRolledAbilities then
		ChatManager.SystemMessage(Interface.getString("charwizard2e_msg_rolllocked"));
		return;
	end
	_wActive = w;
	if w and w.resetSlots then w.resetSlots(); end
	_tCharData.bRolledAbilities = true;
	_tCharData.viPool = nil;
	if w and w.updateRollLock then w.updateRollLock(); end

	local meta = _tAbilityMethods[getAbilityMethod()];
	if not meta then return; end
	if meta.all.kind == "each" then
		for _, sAbility in ipairs(DataCommon.abilities) do
			ActionsManager.actionDirect(nil, "charwiz_ability", { {
				sType = "charwiz_ability",
				sDesc = "[CHARGEN] " .. StringManager.capitalize(sAbility) .. " (" .. meta.name .. ")",
				aDice = _abCopyDice(meta.all.aDice), nMod = 0,
				sAbility = sAbility, sAgg = meta.all.agg,
			} }, { {} });
		end
	elseif meta.all.kind == "collect" then
		-- III/IV: roll a 3d6 group `count` times and gather the totals (each is a clean
		-- 3d6 score). onAbilityResult buffers them and assigns once they have all landed.
		_tCharData.abCollect = { buf = {}, target = meta.all.count, mode = meta.all.agg, name = meta.name };
		for _ = 1, meta.all.count do
			ActionsManager.actionDirect(nil, "charwiz_ability", { {
				sType = "charwiz_ability",
				sDesc = "[CHARGEN] 3d6 (" .. meta.name .. ")",
				aDice = _abCopyDice(meta.all.aDice), nMod = 0, sAgg = "collect",
			} }, { {} });
		end
	else
		-- "vipool" (Method VI): one 7d6 roll feeds the placement pool.
		ActionsManager.actionDirect(nil, "charwiz_ability", { {
			sType = "charwiz_ability",
			sDesc = "[CHARGEN] Abilities (" .. meta.name .. ")",
			aDice = _abCopyDice(meta.all.aDice), nMod = 0, sAgg = meta.all.agg,
		} }, { {} });
	end
end

-- Roll a single ability (the per-attribute dice) -- e.g. roll "old school" in
-- order straight down the list.
-- Method VI: place the largest unplaced die that still fits (<=18) into sAbility.
local function placeViDie(w, sAbility)
	local pool = _tCharData.viPool;
	if not pool or #pool == 0 then
		ChatManager.SystemMessage("Method VI: no unplaced dice -- click the big dice to roll 7d6 first (or to start over).");
		return;
	end
	local nCur = getAbilityScore(sAbility) or 8;
	if nCur < 8 then nCur = 8; end
	table.sort(pool, function(a, b) return a > b; end);
	local nIdx;
	for i, d in ipairs(pool) do
		if nCur + d <= 18 then nIdx = i; break; end
	end
	if not nIdx then
		ChatManager.SystemMessage(StringManager.capitalize(sAbility) .. " can't take another die without passing 18.");
		return;
	end
	local nDie = table.remove(pool, nIdx);
	_tCharData.viPool = pool;
	if w and w.setSlotValue then w.setSlotValue(sAbility, nCur + nDie); end
	if w and w.updateMethodUI then w.updateMethodUI(); end
end

function rollOneAbility(w, sAbility)
	local meta = _tAbilityMethods[getAbilityMethod()];
	if meta and meta.one and meta.one.kind == "viplace" then
		placeViDie(w, sAbility); -- Method VI: allocate a die (not a roll; no lock)
		return;
	end
	if isRollLocked() and (getAbilityScore(sAbility) or 0) > 0 then
		ChatManager.SystemMessage(Interface.getString("charwizard2e_msg_rolllocked"));
		return; -- lock allows each ability's first roll, but no re-rolls
	end
	_wActive = w;
	_tCharData.bRolledAbilities = true;
	if w and w.updateRollLock then w.updateRollLock(); end
	if not meta then return; end
	ActionsManager.actionDirect(nil, "charwiz_ability", { {
		sType = "charwiz_ability",
		sDesc = "[CHARGEN] " .. StringManager.capitalize(sAbility) .. " (" .. meta.name .. ")",
		aDice = _abCopyDice(meta.one.aDice), nMod = 0,
		sAbility = sAbility, sAgg = meta.one.agg,
	} }, { {} });
end

function onAbilityResult(rSource, _, rRoll)
	local sAgg = rRoll.sAgg or "single";
	-- "collect" rolls (III/IV fire many 3d6 groups) post a single summary when the
	-- last one lands, rather than spamming one chat line per group.
	if sAgg ~= "collect" then
		Comm.deliverChatMessage(ActionsManager.createActionMessage(rSource, rRoll));
	end
	if not (_wActive and _wActive.setSlotValue) then return; end

	if sAgg == "bestgroup" then            -- II: best of the two 3d6 totals
		_wActive.setSlotValue(rRoll.sAbility, _abBestGroup(_abDiceResults(rRoll), 3));
	elseif sAgg == "collect" then          -- III/IV: gather each 3d6-group total, then assign
		local c = _tCharData.abCollect;
		if c then
			c.buf[#c.buf + 1] = ActionsManager.total(rRoll);
			if #c.buf >= c.target then
				local rolled = {};
				for _, v in ipairs(c.buf) do rolled[#rolled + 1] = v; end
				if c.mode == "keepbest6" then
					table.sort(c.buf, function(a, b) return a > b; end); -- best six land first
				end
				_abAssignArray(_wActive, c.buf); -- fills the six ability slots (player arranges)
				table.sort(rolled, function(a, b) return a > b; end);
				ChatManager.SystemMessage(string.format("%s: rolled %d sets of 3d6 -> %s%s",
					c.name, c.target, table.concat(rolled, ", "),
					(c.mode == "keepbest6") and "  (keeping the best six)" or "  (arrange to taste)"));
				_tCharData.abCollect = nil;
			end
		end
	elseif sAgg == "vipool" then           -- VI: 7d6 rolled; start all at 8, then place
		_tCharData.viPool = _abDiceResults(rRoll);
		for _, sAbility in ipairs(DataCommon.abilities) do
			_wActive.setSlotValue(sAbility, 8);
		end
		if _wActive.updateMethodUI then _wActive.updateMethodUI(); end
	else                                   -- I / V: one total per ability
		_wActive.setSlotValue(rRoll.sAbility, ActionsManager.total(rRoll));
	end
end

-- Roll the d100 exceptional-strength percentile (for a natural 18 Strength).
function rollStrPercent(w)
	if isRollLocked() and _tCharData.bRolledStrPct then
		ChatManager.SystemMessage(Interface.getString("charwizard2e_msg_rolllocked"));
		return;
	end
	_wActive = w;
	_tCharData.bRolledStrPct = true;
	local rRoll = {
		sType = "charwiz_strpct",
		sDesc = "[CHARGEN] Exceptional Strength (d100)",
		aDice = { "d100" },
		nMod = 0,
	};
	ActionsManager.actionDirect(nil, "charwiz_strpct", { rRoll }, { {} });
end

function onStrPctResult(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local nResult = ActionsManager.total(rRoll);
	if nResult <= 0 then
		nResult = 100; -- a roll of 00 means 18/00 (the best)
	end
	if _wActive and _wActive.setStrPercent then
		_wActive.setStrPercent(nResult);
	end
end

-- Resolve the source book (module display name) of a record path.
local function getRecordBook(sPath)
	local sModule = StringManager.split(sPath or "", "@")[2] or "";
	if sModule == "" then
		return Interface.getString("charwizard2e_book_campaign");
	end
	local tInfo = Module.getModuleInfo(sModule);
	return (tInfo and tInfo.displayname) or sModule;
end

-- Enumerate library records (race/class) as selection options.
-- Each option: { text, linkclass, linkrecord, book }.
function getOptions(sRecordType, sLinkClass)
	local tOptions = {};
	local tSeen = {};
	local tMappings = LibraryData.getMappings(sRecordType) or {};
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
			local sKey = sName:lower();
			if sName ~= "" and not tSeen[sKey] then
				tSeen[sKey] = true;
				local sPath = DB.getPath(vNode);
				table.insert(tOptions, {
					text = sName,
					linkclass = sLinkClass,
					linkrecord = sPath,
					book = getRecordBook(sPath),
				});
			end
		end
	end
	table.sort(tOptions, function(a, b)
		if a.book ~= b.book then
			return a.book < b.book;
		end
		return a.text < b.text;
	end);
	return tOptions;
end

function getRaceOptions()
	return getOptions("race", "reference_race");
end

function getClassOptions()
	return getOptions("class", "reference_class");
end

--
-- Class-by-race restrictions (AD&D 2E PHB Table 7).
-- Maps a recognized PHB race to the set of class-name keywords it may take.
-- A class option passes if its name contains any allowed keyword. Races not
-- recognized here (subraces, splatbook races) and Humans get all classes.
--
-- PHB Table 7 race -> allowed class-name keywords. Built lazily (not at file load:
-- party-script init runs before standard globals like ipairs are available).
local _tRaceClasses = nil;
local function getRaceClassTable()
	if _tRaceClasses then
		return _tRaceClasses;
	end
	_tRaceClasses = {
		["dwarf"] = { "fighter", "cleric", "priest", "thief" },
		["halfling"] = { "fighter", "cleric", "priest", "thief" },
		["gnome"] = { "fighter", "cleric", "priest", "thief", "illusion" },
		["elf"] = {
			"fighter", "ranger", "thief", "cleric", "priest",
			"mage", "wizard", "abjurer", "conjurer", "diviner",
			"enchanter", "invoker", "necromancer", "transmuter", "illusion",
		},
		["half-elf"] = {
			"fighter", "ranger", "cleric", "priest", "druid", "thief", "bard",
			"mage", "wizard", "abjurer", "conjurer", "diviner",
			"enchanter", "invoker", "necromancer", "transmuter", "illusion",
		},
	};
	return _tRaceClasses;
end

-- Reduce a race name to one of the six PHB categories (or nil = unrestricted).
local function getRaceCategory(sRaceName)
	local s = (sRaceName or ""):lower();
	if s:find("half%-elf") or s:find("half elf") then return "half-elf"; end
	if s:find("halfling") then return "halfling"; end
	if s:find("dwar") then return "dwarf"; end
	if s:find("gnome") then return "gnome"; end
	if s:find("elf") or s:find("elv") then return "elf"; end
	if s:find("human") then return "human"; end
	return nil;
end

-- Class options legal for the given race name (PHB Table 7). Human / unknown
-- races return the full list.
function getClassOptionsForRace(sRaceName)
	local tAll = getClassOptions();
	local sCat = getRaceCategory(sRaceName or getRaceCategoryName());
	if not sCat or sCat == "human" then
		return tAll;
	end
	local tAllowed = getRaceClassTable()[sCat];
	if not tAllowed then
		return tAll;
	end
	local tOut = {};
	for _, tOpt in ipairs(tAll) do
		local sName = (tOpt.text or ""):lower();
		for _, sKeyword in ipairs(tAllowed) do
			if sName:find(sKeyword, 1, true) then
				table.insert(tOut, tOpt);
				break;
			end
		end
	end
	return tOut;
end

-- True if this class name is allowed for the current race (PHB Table 7).
function isClassAllowedForRace(sClassName)
	local sCat = getRaceCategory(getRaceCategoryName());
	if not sCat or sCat == "human" then
		return true;
	end
	local tAllowed = getRaceClassTable()[sCat];
	if not tAllowed then
		return true;
	end
	local sName = (sClassName or ""):lower();
	for _, sKeyword in ipairs(tAllowed) do
		if sName:find(sKeyword, 1, true) then
			return true;
		end
	end
	return false;
end

-- PHB-style alignment restrictions by class name keyword.
function isAlignmentAllowedForClass(sAlignment, sClassName)
	local sClass = (sClassName or ""):lower();
	local sAlign = sAlignment or "";

	if sClass:find("paladin", 1, true) then
		return sAlign == "Lawful Good";
	end
	if sClass:find("druid", 1, true) then
		return sAlign == "True Neutral";
	end
	if sClass:find("monk", 1, true) then
		return sAlign:find("Lawful", 1, true) == 1;
	end
	return true;
end

function getAlignmentOptions()
	local tOut = {};
	for _, sAlignment in ipairs(aAlignments) do
		if isAlignmentAllowedForClass(sAlignment, getClassName()) then
			table.insert(tOut, sAlignment);
		end
	end
	return tOut;
end

function getAlignmentRestrictionHint()
	local sClass = getClassName():lower();
	if sClass:find("paladin", 1, true) then
		return Interface.getString("charwizard2e_hint_paladin_alignment");
	end
	if sClass:find("druid", 1, true) then
		return Interface.getString("charwizard2e_hint_druid_alignment");
	end
	if sClass:find("monk", 1, true) then
		return Interface.getString("charwizard2e_hint_monk_alignment");
	end
	return "";
end

--
-- Equipment: PHB starting wealth by class group + optional DM freebies.
--

function getEquipmentData()
	_tCharData.equipment = _tCharData.equipment or {};
	return _tCharData.equipment;
end

function getStartingGold()
	return getEquipmentData().nGold or 0;
end

function setStartingGold(n)
	getEquipmentData().nGold = n or 0;
	getEquipmentData().bRolled = true;
	updateTabStatus();
end

function isWealthRolled()
	return getEquipmentData().bRolled == true;
end

-- "Clear Roll" only clears the gold roll -- chosen starter items are kept.
function clearStartingWealth()
	local tEq = getEquipmentData();
	tEq.nGold = nil;
	tEq.bRolled = nil;
	notifyEquipmentPage();
	updateTabStatus();
end

-- Whether the DM has enabled free starter items (Options menu, not per-character).
function getDmFreebies()
	return OptionsManager.isOption("CWFI", "on");
end

-- Family heirloom (Equipment tab; only when the DM allows it). A random keepsake
-- text stored on the build and granted as an inventory item on commit.
function isHeirloomAllowed()
	return OptionsManager.isOption("CWHEIR", "on");
end
function getHeirloom()
	return getEquipmentData().heirloom or "";
end
function setHeirloom(sText)
	getEquipmentData().heirloom = sText or "";
end
function clearHeirloom()
	getEquipmentData().heirloom = nil;
end

--
-- Player-chosen starter items. A small curated handful; each item's cost is
-- deducted from the rolled starting gold as it's added (refunded on remove).
-- Stored as { { sPath, sName, sCost, nQty }, ... } in the equipment build data.
--
function getChosenItems()
	local tEq = getEquipmentData();
	tEq.tItems = tEq.tItems or {};
	return tEq.tItems;
end

local function findChosenItem(sPath)
	for i, r in ipairs(getChosenItems()) do
		if r.sPath == sPath then
			return i, r;
		end
	end
	return nil, nil;
end

function getChosenQty(sPath)
	local _, r = findChosenItem(sPath);
	return (r and r.nQty) or 0;
end

-- Parse an item cost string ("5 gp", "2 sp", "10 cp", "1 pp") to a gp value.
local function parseItemCostGP(sCost)
	local s = (sCost or ""):lower();
	local n = tonumber(s:match("([%d%.]+)"));
	if not n then return 0; end
	if s:find("pp", 1, true) then return n * 5; end
	if s:find("ep", 1, true) then return n * 0.5; end
	if s:find("sp", 1, true) then return n * 0.1; end
	if s:find("cp", 1, true) then return n * 0.01; end
	return n; -- gp, or no unit given
end

-- Total gp value of everything currently chosen (used to refund on Clear).
function getStarterSpentGold()
	local nTotal = 0;
	for _, r in ipairs(getChosenItems()) do
		nTotal = nTotal + parseItemCostGP(r.sCost) * (r.nQty or 1);
	end
	return nTotal;
end

-- Light refresh of just the Equipment tab's gold display (no list rebuild, so it
-- is safe to call from inside a row's add/remove click).
local function notifyEquipmentPurse()
	local wMain = getMainWindow();
	if wMain and wMain.sub_equipment and wMain.sub_equipment.subwindow
			and wMain.sub_equipment.subwindow.updatePurse then
		wMain.sub_equipment.subwindow.updatePurse();
	end
end

-- add/remove deliberately do NOT rebuild the list (the click originates from a
-- row inside it); the row refreshes its own qty label, and we refresh just the
-- gold display via notifyEquipmentPurse.
function addChosenItem(sPath, sName, sCost)
	if not sPath or sPath == "" then
		return;
	end
	if not isWealthRolled() then
		ChatManager.SystemMessage("Roll your starting wealth first, then buy gear.");
		return;
	end
	local tEq = getEquipmentData();
	local nCost = parseItemCostGP(sCost);
	if nCost > (tEq.nGold or 0) then
		ChatManager.SystemMessage("Not enough gold for that item -- pick a cheaper option, or shop the Items list.");
		return;
	end
	local _, r = findChosenItem(sPath);
	if r then
		r.nQty = (r.nQty or 1) + 1;
	else
		table.insert(getChosenItems(), { sPath = sPath, sName = sName or "", sCost = sCost or "", nQty = 1 });
	end
	tEq.nGold = (tEq.nGold or 0) - nCost; -- deduct from the rolled purse
	notifyEquipmentPurse();
end

-- Free kit item: the player selects it, but it costs no gold (and never deducts
-- or refunds). Granted on commit alongside the bought items.
function addFreeItem(sPath, sName)
	if not sPath or sPath == "" then
		return;
	end
	local _, r = findChosenItem(sPath);
	if r then
		r.nQty = (r.nQty or 1) + 1;
	else
		table.insert(getChosenItems(), { sPath = sPath, sName = sName or "", sCost = "", nQty = 1, bFree = true });
	end
	notifyEquipmentPurse();
end

function removeChosenItem(sPath)
	local i, r = findChosenItem(sPath);
	if r then
		local nCost = parseItemCostGP(r.sCost);
		r.nQty = (r.nQty or 1) - 1;
		if r.nQty <= 0 then
			table.remove(getChosenItems(), i);
		end
		local tEq = getEquipmentData();
		tEq.nGold = (tEq.nGold or 0) + nCost; -- refund
		notifyEquipmentPurse();
	end
end

function clearChosenItems()
	local tEq = getEquipmentData();
	tEq.nGold = (tEq.nGold or 0) + getStarterSpentGold(); -- refund everything first
	tEq.tItems = {};
	notifyEquipmentPage();
end

--
-- Proficiencies (Profs tab). Stored in _tCharData.profs. Slot counts and weapon
-- allowances are PHB rules by class group (the ruleset doesn't carry this data).
--
function getProfData()
	_tCharData.profs = _tCharData.profs or {};
	return _tCharData.profs;
end

-- warrior | priest | druid | rogue | bard | wizard
local function profClassGroup(sClassName)
	local s = (sClassName or ""):lower();
	if s:find("fighter", 1, true) or s:find("ranger", 1, true)
			or s:find("paladin", 1, true) or s:find("barbarian", 1, true) then
		return "warrior";
	end
	if s:find("bard", 1, true) then return "bard"; end
	if s:find("thief", 1, true) then return "rogue"; end
	if s:find("druid", 1, true) then return "druid"; end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) then return "priest"; end
	if s:find("mage", 1, true) or s:find("wizard", 1, true) or s:find("illusion", 1, true)
			or s:find("conjur", 1, true) or s:find("divin", 1, true) or s:find("enchant", 1, true)
			or s:find("invok", 1, true) or s:find("necrom", 1, true) or s:find("transmut", 1, true)
			or s:find("abjur", 1, true) then
		return "wizard";
	end
	return "warrior";
end

-- PHB initial weapon proficiency slots at level 1, by group.
function getWeaponSlots()
	local g = profClassGroup(getClassName());
	if g == "warrior" then return 4; end
	if g == "wizard" then return 1; end
	return 2; -- priest, druid, rogue, bard
end

-- nil => any weapon. Otherwise the class may only be proficient in weapons whose
-- name matches one of these keywords (PHB class weapon restrictions).
local _tWeaponAllow = {
	wizard = { "dagger", "dart", "knife", "sling", "staff", "quarterstaff" },
	priest = { "club", "mace", "hammer", "warhammer", "staff", "quarterstaff", "sling",
		"flail", "morning star", "scourge", "mancatcher", "whip", "bludgeon" },
	druid  = { "club", "dagger", "dart", "scimitar", "sling", "spear", "staff",
		"quarterstaff", "sickle", "dagger" },
	rogue  = { "club", "dagger", "dirk", "dart", "crossbow", "knife", "lasso", "bow",
		"sling", "broad sword", "long sword", "rapier", "short sword", "scimitar", "staff" },
};

function getAllowedWeaponKeywords()
	local g = profClassGroup(getClassName());
	if g == "warrior" or g == "bard" then
		return nil; -- any weapon
	end
	return _tWeaponAllow[g];
end

-- Short, race+class-recommended weapon shortlist for the proficiency picker
-- (CharWizard2EBio.getRecommendedWeapons). Previously this listed EVERY weapon in
-- every loaded module; now it returns a curated set in recommended order, with the
-- race's signature weapons first. Plain names, in order (the picker no longer alpha-sorts).
function buildWeaponCatalog()
	local tOut = {};
	for _, rWpn in ipairs(CharWizard2EBio.getRecommendedWeapons(getClassName(), getRaceCategoryName()) or {}) do
		table.insert(tOut, rWpn.name);
	end
	return tOut;
end

function getChosenWeapons()
	getProfData().weapons = getProfData().weapons or {};
	return getProfData().weapons;
end

function isWeaponChosen(sName)
	for _, s in ipairs(getChosenWeapons()) do
		if s == sName then return true; end
	end
	return false;
end

-- A specialization consumes one extra weapon slot (proficient + specialize).
function getWeaponSlotsUsed()
	local n = #getChosenWeapons();
	if (getProfData().specialize or "") ~= "" then
		n = n + 1;
	end
	return n;
end

function addWeaponProf(sName)
	if not sName or sName == "" or isWeaponChosen(sName) then
		return;
	end
	if getWeaponSlotsUsed() >= getWeaponSlots() then
		return; -- no slots remaining
	end
	table.insert(getChosenWeapons(), sName);
	notifyProficienciesPage();
end

function removeWeaponProf(sName)
	local t = getChosenWeapons();
	for i, s in ipairs(t) do
		if s == sName then
			table.remove(t, i);
			if getProfData().specialize == sName then
				getProfData().specialize = nil; -- a removed weapon can't stay specialized
			end
			notifyProficienciesPage();
			return;
		end
	end
end

-- Weapon specialization (single-class fighters only; not rangers/paladins).
function canSpecialize()
	return getClassName():lower():find("fighter", 1, true) ~= nil;
end

function getSpecialization()
	return getProfData().specialize or "";
end

function isSpecialized(sName)
	return sName ~= "" and getSpecialization() == sName;
end

-- Toggle specialization on a proficient weapon. To switch the specialized weapon,
-- turn the current one off first (keeps each click affecting only its own row).
function setSpecialization(sName)
	if not canSpecialize() or not isWeaponChosen(sName) then
		return;
	end
	local sCur = getSpecialization();
	if sCur == sName then
		getProfData().specialize = nil; -- toggle off, frees the slot
		notifyProficienciesPage();
	elseif sCur == "" then
		if getWeaponSlotsUsed() >= getWeaponSlots() then
			return; -- no free slot to spend on specialization
		end
		getProfData().specialize = sName;
		notifyProficienciesPage();
	end
	-- else: a different weapon is specialized -> ignore (toggle it off first)
end

-- Languages: racial tongues are auto-known; the player may pick this many extra
-- languages (PHB Intelligence "number of languages" table).
local function intToLanguages(nInt)
	if nInt <= 1 then return 0; end
	if nInt <= 8 then return 1; end
	if nInt <= 11 then return 2; end
	if nInt <= 13 then return 3; end
	if nInt <= 15 then return 4; end
	if nInt == 16 then return 5; end
	if nInt == 17 then return 6; end
	if nInt == 18 then return 7; end
	if nInt == 19 then return 8; end
	if nInt == 20 then return 9; end
	if nInt == 21 then return 10; end
	if nInt == 22 then return 11; end
	if nInt == 23 then return 12; end
	if nInt == 24 then return 15; end
	return 20;
end

function getLanguageCount()
	local nInt = tonumber((_tCharData.abilities or {}).intelligence) or 0;
	return intToLanguages(nInt);
end

function getRaceKnownLanguages()
	return CharWizard2EBio.getRaceLanguages(getRaceCategoryName());
end

function getChosenLanguages()
	getProfData().languages = getProfData().languages or {};
	return getProfData().languages;
end

function isLanguageChosen(sLang)
	for _, s in ipairs(getChosenLanguages()) do
		if s == sLang then return true; end
	end
	return false;
end

function getLanguagesUsed()
	return #getChosenLanguages();
end

-- Pickable extras: the master list minus the racial-known languages.
function buildLanguageCatalog()
	local tKnown = {};
	for _, s in ipairs(getRaceKnownLanguages()) do
		tKnown[s:lower()] = true;
	end
	local tOut = {};
	for _, s in ipairs(CharWizard2EBio.getLanguageList()) do
		if not tKnown[s:lower()] then
			table.insert(tOut, s);
		end
	end
	return tOut;
end

function addLanguage(sLang)
	if not sLang or sLang == "" or isLanguageChosen(sLang) then
		return;
	end
	if getLanguagesUsed() >= getLanguageCount() then
		return;
	end
	table.insert(getChosenLanguages(), sLang);
	notifyProficienciesPage();
end

function removeLanguage(sLang)
	local t = getChosenLanguages();
	for i, s in ipairs(t) do
		if s == sLang then
			table.remove(t, i);
			notifyProficienciesPage();
			return;
		end
	end
end

-- Nonweapon proficiencies: PHB initial slots by class group. (Group/cost is not
-- in FG's data, so these are picked from the full skill library, slot-limited.)
function getNWPSlots()
	local g = profClassGroup(getClassName());
	if g == "wizard" or g == "priest" or g == "druid" then return 4; end
	return 3; -- warrior, rogue, bard
end

function getChosenNWPs()
	getProfData().nwps = getProfData().nwps or {};
	return getProfData().nwps;
end

function isNWPChosen(sPath)
	for _, r in ipairs(getChosenNWPs()) do
		if r.sPath == sPath then return true; end
	end
	return false;
end

-- Slot COST of a nonweapon proficiency. The 2E ruleset encodes it in the skill
-- name as a "[N]" suffix (e.g. "Survival [2]" costs 2 slots); no suffix = 1 slot.
local function nwpCost(sName)
	local n = tostring(sName or ""):match("%[(%d+)%]");
	return tonumber(n) or 1;
end

function getNWPUsed()
	local n = 0;
	for _, r in ipairs(getChosenNWPs()) do
		n = n + nwpCost(r.sName);
	end
	return n;
end

-- Distinct nonweapon proficiencies ("skill" records) from the loaded libraries,
-- filtered to the ones that fit the chosen class (General + the class's own PHB
-- group). Falls back to the full list if nothing matches, so the picker is never
-- empty (e.g. an unusual skill library whose names don't match the allow-list).
function buildNWPCatalog()
	local sGroup = profClassGroup(getClassName());
	local function gather(bFilter)
		local tSeen = {};
		local tOut = {};
		local tMappings = LibraryData.getMappings("skill") or {};
		for _, sMapping in ipairs(tMappings) do
			for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
				local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
				local sLower = sName:lower();
				if sName ~= "" and not tSeen[sLower]
						and (not bFilter or CharWizard2EBio.isNWPAllowed(sName, sGroup)) then
					tSeen[sLower] = true;
					table.insert(tOut, { sName = sName, sPath = DB.getPath(vNode) });
				end
			end
		end
		table.sort(tOut, function(a, b) return a.sName < b.sName; end);
		return tOut;
	end
	local tFiltered = gather(true);
	if #tFiltered == 0 then
		return gather(false);
	end
	return tFiltered;
end

function addNWP(sPath, sName)
	if not sPath or sPath == "" or isNWPChosen(sPath) then
		return;
	end
	if getNWPUsed() + nwpCost(sName) > getNWPSlots() then
		return; -- not enough slots left for this proficiency's cost
	end
	table.insert(getChosenNWPs(), { sName = sName or "", sPath = sPath });
	notifyProficienciesPage();
end

function removeNWP(sPath)
	local t = getChosenNWPs();
	for i, r in ipairs(t) do
		if r.sPath == sPath then
			table.remove(t, i);
			notifyProficienciesPage();
			return;
		end
	end
end

-- Spells (caster classes only). Wizard group = arcane; priest/druid = divine.
function getCasterType()
	local g = profClassGroup(getClassName());
	if g == "wizard" then return "arcane"; end
	if g == "priest" or g == "druid" then return "divine"; end
	return nil; -- warriors/rogues/bards: no spells at creation in this MVP
end

-- Highest spell level castable at the target level (PHB progression).
function getMaxSpellLevel()
	local sType = getCasterType();
	if not sType then return 0; end
	local nMax = math.ceil(getTargetLevel() / 2);
	if sType == "arcane" then return math.min(9, nMax); end
	return math.min(7, nMax);
end

-- Spells memorizable per spell level, by class level (PHB Tables 21 / 24).
local _tWizSlots = {
	[1] = {1}, [2] = {2}, [3] = {2,1}, [4] = {3,2}, [5] = {4,2,1},
	[6] = {4,2,2}, [7] = {4,3,2,1}, [8] = {4,3,3,2}, [9] = {4,3,3,2,1},
	[10] = {4,4,3,2,2}, [11] = {4,4,4,3,3}, [12] = {4,4,4,4,4,1},
	[13] = {5,5,5,4,4,2}, [14] = {5,5,5,4,4,3,1}, [15] = {5,5,5,5,5,3,2},
};
local _tPriestSlots = {
	[1] = {1}, [2] = {2}, [3] = {2,1}, [4] = {3,2}, [5] = {3,3,1},
	[6] = {3,3,2}, [7] = {3,3,2,1}, [8] = {3,3,3,2}, [9] = {4,4,3,2,1},
	[10] = {4,4,3,3,2}, [11] = {5,4,4,3,2,1}, [12] = {6,5,5,3,2,2},
	[13] = {6,6,6,4,2,2}, [14] = {6,6,6,5,3,2,1}, [15] = {6,6,6,6,4,2,1},
};
-- Priest bonus spells from high Wisdom (PHB Table 5), per spell level.
local _tPriestWisBonus = {
	[13] = {1}, [14] = {2}, [15] = {2,1}, [16] = {2,2},
	[17] = {2,2,1}, [18] = {2,2,1,1},
};

-- How many spells of nSpellLevel the caster gets (per-level cap for picking).
function getSpellSlots(nSpellLevel)
	local sType = getCasterType();
	if not sType then return 0; end
	local nLevel = math.min(getTargetLevel(), 15);
	local nBase = 0;
	if sType == "arcane" then
		local tRow = _tWizSlots[nLevel];
		nBase = (tRow and tRow[nSpellLevel]) or 0;
	else
		local tRow = _tPriestSlots[nLevel];
		nBase = (tRow and tRow[nSpellLevel]) or 0;
		-- Wisdom bonus spells apply only where the priest already has slots.
		if nBase > 0 then
			local nWis = tonumber((_tCharData.abilities or {}).wisdom) or 0;
			if nWis >= 13 then
				local tBonus = _tPriestWisBonus[math.min(nWis, 18)];
				if tBonus and tBonus[nSpellLevel] then
					nBase = nBase + tBonus[nSpellLevel];
				end
			end
		end
	end
	return nBase;
end

function getSpellsUsedAtLevel(nSpellLevel)
	local n = 0;
	for _, r in ipairs(getChosenSpells()) do
		if (r.nLevel or 1) == nSpellLevel then
			n = n + 1;
		end
	end
	return n;
end

-- Spells from the loaded spell libraries for the caster's type, level <= max.
-- A spell record's level is "level"; arcane spells carry a "school", divine
-- spells carry a "sphere" (that's how we tell wizard vs priest spells apart).
function buildSpellCatalog()
	local sType = getCasterType();
	if not sType then return {}; end
	local nMax = getMaxSpellLevel();
	local tOut = {};
	local tSeen = {};
	local tMappings = LibraryData.getMappings("spell") or {};
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			local nLvl = DB.getValue(vNode, "level", 0);
			if nLvl >= 1 and nLvl <= nMax then
				-- Priest spells carry a "sphere" (and often a school too); wizard
				-- spells have a school but never a sphere. So sphere-presence is what
				-- tells divine from arcane -- testing "has a school" wrongly leaked
				-- priest spells (which also have one) into the mage list.
				local bDivine = StringManager.trim(DB.getValue(vNode, "sphere", "")) ~= "";
				local bMatch = (sType == "divine" and bDivine) or (sType == "arcane" and not bDivine);
				if bMatch then
					local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
					local sKey = sName:lower();
					if sName ~= "" and not tSeen[sKey] then
						tSeen[sKey] = true;
						table.insert(tOut, { sName = sName, sPath = DB.getPath(vNode), nLevel = nLvl });
					end
				end
			end
		end
	end
	table.sort(tOut, function(a, b)
		if a.nLevel ~= b.nLevel then return a.nLevel < b.nLevel; end
		return a.sName < b.sName;
	end);
	return tOut;
end

function getChosenSpells()
	getProfData().spells = getProfData().spells or {};
	return getProfData().spells;
end

function isSpellChosen(sPath)
	for _, r in ipairs(getChosenSpells()) do
		if r.sPath == sPath then return true; end
	end
	return false;
end

function getSpellsUsed()
	return #getChosenSpells();
end

function addSpell(sPath, sName, nLevel)
	if not sPath or sPath == "" or isSpellChosen(sPath) then
		return;
	end
	nLevel = nLevel or 1;
	if getSpellsUsedAtLevel(nLevel) >= getSpellSlots(nLevel) then
		return; -- that spell level is full
	end
	table.insert(getChosenSpells(), { sName = sName or "", sPath = sPath, nLevel = nLevel });
	notifyProficienciesPage();
end

function removeSpell(sPath)
	local t = getChosenSpells();
	for i, r in ipairs(t) do
		if r.sPath == sPath then
			table.remove(t, i);
			notifyProficienciesPage();
			return;
		end
	end
end

-- PHB Chapter 6 starting funds: Warrior 5d4×10, Priest 3d6×10, Rogue 2d6×10, Wizard (1d4+1)×10.
local function getClassWealthGroup(sClassName)
	local s = (sClassName or ""):lower();
	if s:find("fighter", 1, true) or s:find("ranger", 1, true) or s:find("paladin", 1, true) then
		return "warrior";
	end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) or s:find("druid", 1, true) then
		return "priest";
	end
	if s:find("thief", 1, true) or s:find("bard", 1, true) then
		return "rogue";
	end
	if s:find("mage", 1, true) or s:find("wizard", 1, true) or s:find("illusion", 1, true)
			or s:find("conjur", 1, true) or s:find("divin", 1, true) or s:find("enchant", 1, true)
			or s:find("invok", 1, true) or s:find("necrom", 1, true) or s:find("transmut", 1, true) then
		return "wizard";
	end
	return "warrior";
end

function getClassWealthInfo()
	local sGroup = getClassWealthGroup(getClassName());
	if sGroup == "priest" then
		return { sExpr = "3d6*10", sLabel = Interface.getString("charwizard2e_wealth_priest") };
	elseif sGroup == "rogue" then
		return { sExpr = "2d6*10", sLabel = Interface.getString("charwizard2e_wealth_rogue") };
	elseif sGroup == "wizard" then
		return { sExpr = "(1d4+1)*10", sLabel = Interface.getString("charwizard2e_wealth_wizard") };
	end
	return { sExpr = "5d4*10", sLabel = Interface.getString("charwizard2e_wealth_warrior") };
end

function rollStartingWealth(w)
	_wActive = w;
	local tWealth = getClassWealthInfo();
	local rRoll = {
		sType = "charwiz_wealth",
		sDesc = "[CHARGEN] Starting wealth (" .. (tWealth.sLabel or tWealth.sExpr) .. ")",
		aDice = { expr = tWealth.sExpr },
		nMod = 0,
	};
	ActionsManager.actionDirect(nil, "charwiz_wealth", { rRoll }, { {} });
end

function onWealthResult(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local nTotal = ActionsManager.total(rRoll);
	if _wActive and _wActive.setWealthResult then
		_wActive.setWealthResult(nTotal);
	end
end

-- Roll a random family heirloom (d20 on the Drowned Archive table).
function rollHeirloom(w)
	_wActive = w;
	local rRoll = {
		sType = "charwiz_heirloom",
		sDesc = "[CHARGEN] Family heirloom (d20)",
		aDice = { "d20" },
		nMod = 0,
	};
	ActionsManager.actionDirect(nil, "charwiz_heirloom", { rRoll }, { {} });
end

function onHeirloomResult(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local nTotal = ActionsManager.total(rRoll);
	setHeirloom(CharWizard2EBio.getHeirloomByRoll(nTotal));
	notifyEquipmentPage();
end

local function applyStartingGold(nodeChar, nGP)
	if not nGP or nGP <= 0 then
		return;
	end
	-- The purse can be fractional gp (gear priced in sp/cp was deducted from it).
	-- Convert to whole coins (2E: 1 gp = 10 sp = 100 cp) and lay out the standard
	-- denominations PP/GP/EP/SP/CP so the sheet shows the proper labeled coin boxes
	-- instead of a single "43.97 GP" field. Gold stays as gold (PP/EP left at 0).
	local nCPTotal  = math.floor(nGP * 100 + 0.5); -- everything in copper
	local nGold     = math.floor(nCPTotal / 100);
	local nRem      = nCPTotal - nGold * 100;
	local nSilver   = math.floor(nRem / 10);
	local nCopper   = nRem - nSilver * 10;

	local nodeCoins = DB.createChild(nodeChar, "coins");
	if not nodeCoins then
		return;
	end
	-- Clear whatever the fresh sheet started with; the wizard owns the purse.
	for _, vCoin in pairs(DB.getChildren(nodeCoins) or {}) do
		DB.deleteNode(vCoin);
	end
	local tDenoms = { { "PP", 0 }, { "GP", nGold }, { "EP", 0 }, { "SP", nSilver }, { "CP", nCopper } };
	for i, d in ipairs(tDenoms) do
		local nodeCoin = DB.createChild(nodeCoins, string.format("id-%05d", i));
		if nodeCoin then
			DB.setValue(nodeCoin, "name", "string", d[1]);
			DB.setValue(nodeCoin, "amount", "number", d[2]);
		end
	end
end

local function findItemPathByName(sItemName)
	local sTarget = StringManager.trim(sItemName or ""):lower();
	if sTarget == "" then
		return nil;
	end
	local tMappings = LibraryData.getMappings("item") or {};
	-- Pass 1: exact (case-insensitive) name match across every item library.
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			if StringManager.trim(DB.getValue(vNode, "name", "")):lower() == sTarget then
				return DB.getPath(vNode);
			end
		end
	end
	-- Pass 2: substring match (item libraries vary in naming, e.g. "Holy symbol, silver").
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			if StringManager.trim(DB.getValue(vNode, "name", "")):lower():find(sTarget, 1, true) then
				return DB.getPath(vNode);
			end
		end
	end
	return nil;
end

-- Return the path of the first item matching any of the candidate names.
local function findItemPathByNames(tNames)
	for _, sName in ipairs(tNames or {}) do
		local sPath = findItemPathByName(sName);
		if sPath then
			return sPath;
		end
	end
	return nil;
end

-- The cheap item a class needs to do its job. Bards need an instrument, priests
-- a holy symbol, thieves their picks, arcane casters a spellbook, etc. Each entry
-- lists name variants (different item modules name these differently) and we grant
-- the first match found in the loaded item libraries.
local function getClassEssentialItemNames(sClassName)
	local s = (sClassName or ""):lower();
	if s:find("bard", 1, true) then
		return { "Lute", "Mandolin", "Lyre", "Horn", "Musical Instrument", "Instrument" };
	end
	if s:find("thief", 1, true) then
		return { "Thieves' Picks", "Thieves Picks", "Thieves' Tools", "Thieves Tools", "Lock Picks", "Lockpicks" };
	end
	if s:find("druid", 1, true) then
		return { "Mistletoe", "Holy Symbol", "Holy Item" };
	end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) then
		return { "Holy Symbol", "Holy Symbol, Silver", "Holy Symbol, Wooden", "Symbol, Holy", "Holy Item" };
	end
	if s:find("mage", 1, true) or s:find("wizard", 1, true) or s:find("illusion", 1, true)
			or s:find("conjur", 1, true) or s:find("divin", 1, true) or s:find("enchant", 1, true)
			or s:find("invok", 1, true) or s:find("necrom", 1, true) or s:find("transmut", 1, true)
			or s:find("abjur", 1, true) then
		return { "Spellbook", "Spell Book", "Book, Spell", "Wizard's Spellbook" };
	end
	return {};
end

-- Index every loaded item once: lowercased name -> { sPath, sName, sCost }.
local function buildItemIndex()
	local tIndex = {};
	local tMappings = LibraryData.getMappings("item") or {};
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
			local sCost = StringManager.trim(DB.getValue(vNode, "cost", ""));
			local nGP = parseItemCostGP(sCost);
			-- The starter catalog must only ever surface mundane, sensibly-priced
			-- gear. Skip priceless/magic items (no parseable cost), enchanted names
			-- ("+1", etc.), and anything pricier than a starting adventurer carries.
			-- (Fixes random magic items -- e.g. a 3,000 gp dagger -- from leaking in
			-- via the substring fallback.)
			local bEnchanted = sName:find("%+%s*%d") ~= nil;
			if sName ~= "" and sCost ~= "" and nGP > 0 and nGP <= 200 and not bEnchanted then
				local sLower = sName:lower();
				if not tIndex[sLower] then
					tIndex[sLower] = { sPath = DB.getPath(vNode), sName = sName, sCost = sCost };
				end
			end
		end
	end
	return tIndex;
end

-- Find a single item record by exact name across all loaded item libraries.
-- Unfiltered (heirlooms can be pricey/magical), used to grant the rolled family
-- heirloom as its real Drowned Archive item record.
local function findItemNodeByExactName(sName)
	if not sName or sName == "" then return nil; end
	local sTarget = StringManager.trim(sName):lower();
	for _, sMapping in ipairs(LibraryData.getMappings("item") or {}) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			if StringManager.trim(DB.getValue(vNode, "name", "")):lower() == sTarget then
				return vNode;
			end
		end
	end
	return nil;
end

-- Details of the rolled family heirloom for the Equipment tab's display: the
-- item's own picture asset (qualified with its module) and a plain-text version
-- of its description. Returns nil if nothing has been rolled.
function getHeirloomDetails()
	local sName = getHeirloom();
	if not sName or sName == "" then return nil; end
	local nodeItem = findItemNodeByExactName(sName);
	local sPic, sDesc = "", "";
	if nodeItem then
		-- The item's picture is stored relative to its own module; qualify it with
		-- "@<module>" (taken from the node path) so it resolves from the wizard.
		local sMod = (DB.getPath(nodeItem) or ""):match("@(.+)$");
		sPic = DB.getValue(nodeItem, "picture", "");
		if type(sPic) ~= "string" then sPic = ""; end
		if sPic ~= "" and not sPic:find("@", 1, true) and sMod then
			sPic = sPic .. "@" .. sMod;
		end
		sDesc = DB.getValue(nodeItem, "description", "");
		if type(sDesc) ~= "string" then sDesc = ""; end
		sDesc = sDesc:gsub("</p>%s*<p>", "\r\r"):gsub("<[^>]+>", "");
		sDesc = sDesc:gsub("&#34;", '"'):gsub("&#39;", "'"):gsub("&apos;", "'")
			:gsub("&quot;", '"'):gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">");
		sDesc = sDesc:gsub("^%s+", ""):gsub("%s+$", "");
	end
	return { sName = sName, sPicture = sPic, sDesc = sDesc,
		sPath = nodeItem and DB.getPath(nodeItem) or "" };
end

-- Resolve a list of name-variant arrays against the loaded item libraries; returns
-- an ordered array of { sPath, sName, sCost }. Callers list the Drowned Archive
-- "(Poor)" names first, so an exact match prefers them over standard items.
local function buildCatalogFrom(tNamesList)
	local tIndex = buildItemIndex();

	local function resolve(tNames)
		for _, sN in ipairs(tNames) do
			local r = tIndex[sN:lower()];
			if r then
				return r;
			end
		end
		-- Fall back to a substring match; prefer the shortest matching name.
		local rBest = nil;
		for _, sN in ipairs(tNames) do
			local sNl = sN:lower();
			for k, r in pairs(tIndex) do
				if k:find(sNl, 1, true) then
					if not rBest or #r.sName < #rBest.sName then
						rBest = r;
					end
				end
			end
			if rBest then
				return rBest;
			end
		end
		return nil;
	end

	local tResolved = {};
	local tSeen = {};
	for _, tNames in ipairs(tNamesList or {}) do
		local r = resolve(tNames);
		if r and not tSeen[r.sPath] then
			tSeen[r.sPath] = true;
			table.insert(tResolved, r);
		end
	end
	return tResolved;
end

-- FREE class kit (granted at no gold cost): class kit item + adventuring pack.
function buildFreeCatalog()
	return buildCatalogFrom(CharWizard2EBio.getFreeGearNames(getClassName()));
end

-- BUY starter gear (cost deducted from rolled gold): recommended weapons + armor
-- (+ matching ammo). Anything more, the player buys from FG's own Items list.
function buildStarterCatalog()
	return buildCatalogFrom(CharWizard2EBio.getBuyGearNames(getClassName(), getRaceCategoryName()));
end

local function collectItemLinksFromNode(node, tSeen, tOut)
	if not node then
		return;
	end
	for _, vChild in pairs(DB.getChildren(node) or {}) do
		local sPath = DB.getPath(vChild);
		if not tSeen[sPath] then
			tSeen[sPath] = true;
			local sClass, sRecord = DB.getValue(vChild, "link", "", "");
			if (sClass == "" or sClass == "item") and sRecord ~= "" then
				table.insert(tOut, sRecord);
			end
			sClass, sRecord = DB.getValue(vChild, "shortcut", "", "");
			if sClass == "item" and sRecord ~= "" then
				table.insert(tOut, sRecord);
			end
			collectItemLinksFromNode(vChild, tSeen, tOut);
		end
	end
end

local function applyDmFreebies(nodeChar, tClassLink, sClassName, tSkip)
	local tItems = {};
	local tSeen = {};

	-- Any item links the class record itself carries (kit gear, etc.).
	if tClassLink and tClassLink.linkrecord then
		local nodeClass = DB.findNode(tClassLink.linkrecord);
		if nodeClass then
			collectItemLinksFromNode(nodeClass, tSeen, tItems);
		end
	end

	-- The free class kit (kit item + adventuring pack), resolved with the Drowned
	-- Archive "(Poor)" / "(Secondhand)" versions preferred.
	for _, rItem in ipairs(buildFreeCatalog()) do
		table.insert(tItems, rItem.sPath);
	end

	-- Dedupe by path so links from the class record don't double up with the
	-- explicit pack / essential lookups. Seed with tSkip so we never re-grant an
	-- item the player already picked from the curated list.
	local nAdded = 0;
	local tDone = {};
	for sPath in pairs(tSkip or {}) do
		tDone[sPath] = true;
	end
	local sCharPath = DB.getPath(nodeChar);
	for _, sItemPath in ipairs(tItems) do
		if sItemPath ~= "" and not tDone[sItemPath]
				and ItemManager and ItemManager.handleItem then
			ItemManager.handleItem(sCharPath, "inventorylist", "item", sItemPath, true);
			tDone[sItemPath] = true;
			nAdded = nAdded + 1;
		end
	end

	if nAdded > 0 then
		ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_freebies_added"), nAdded));
	else
		ChatManager.SystemMessage(Interface.getString("charwizard2e_msg_freebies_none"));
	end
end

-- Grant the items the player picked from the curated starter list.
-- Grant the contents of a "pack" item (any item that defines <subitems>, e.g. an
-- adventuring pack). A manual drag unpacks these via the ruleset's drop handler,
-- but ItemManager.handleItem (what the wizard uses) does NOT -- so we replicate it
-- here. Safe from double-granting precisely because handleItem never unpacks.
local function grantSubitems(sCharPath, sSourcePath)
	local nodeSource = DB.findNode(sSourcePath);
	if not nodeSource or DB.getChildCount(nodeSource, "subitems") == 0 then
		return;
	end
	-- Subitem links are authored bare (e.g. "item.id-00044") and a bare path resolves
	-- to the *campaign*, not the module the pack came from. Qualify them with the
	-- pack's own "@<module>" suffix so the contents resolve from the loaded module.
	local sModule = (sSourcePath or ""):match("(@.+)$") or "";
	for _, vSub in pairs(DB.getChildren(nodeSource, "subitems")) do
		local sSubClass, sSubRecord = DB.getValue(vSub, "link", "", "");
		if sSubRecord and sSubRecord ~= "" and sModule ~= "" and not sSubRecord:find("@", 1, true) then
			sSubRecord = sSubRecord .. sModule;
		end
		local nCount = DB.getValue(vSub, "count", 1);
		if sSubRecord and sSubRecord ~= "" and ItemManager and ItemManager.handleItem then
			local nodeNew = ItemManager.handleItem(sCharPath, "inventorylist",
				(sSubClass ~= "" and sSubClass) or "item", sSubRecord, true);
			if nodeNew and nCount and nCount > 1 then
				DB.setValue(nodeNew, "count", "number", nCount);
			end
		end
	end
end

local function applyChosenItems(nodeChar, tEq)
	local tItems = tEq.tItems;
	if not tItems or #tItems == 0 then
		return;
	end
	local sCharPath = DB.getPath(nodeChar);
	local nAdded = 0;
	for _, rItem in ipairs(tItems) do
		if rItem.sPath and rItem.sPath ~= "" and ItemManager and ItemManager.handleItem then
			for _ = 1, (rItem.nQty or 1) do
				ItemManager.handleItem(sCharPath, "inventorylist", "item", rItem.sPath, true);
				nAdded = nAdded + 1;
			end
			grantSubitems(sCharPath, rItem.sPath); -- unpack pack contents, if any
		end
	end
	if nAdded > 0 then
		ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_items_added"), nAdded));
	end
end

local function applyEquipment(nodeChar, rBuild)
	local tEq = rBuild.equipment or {};
	if tEq.nGold and tEq.nGold > 0 then
		applyStartingGold(nodeChar, tEq.nGold);
	end

	-- All chosen gear is granted here: the player's selected free kit (bFree, no
	-- gold) AND the items they bought. Free items are picked by the player now,
	-- not auto-granted, so they feel like a real choice.
	applyChosenItems(nodeChar, tEq);

	-- Family heirloom (if the DM enabled it and the player rolled one): grant the
	-- actual rolled item record from The Drowned Archive, so it arrives with its
	-- own art, stats, and description -- exactly as if dragged from the book.
	if tEq.heirloom and tEq.heirloom ~= "" then
		local nodeHeir = findItemNodeByExactName(tEq.heirloom);
		if nodeHeir and ItemManager and ItemManager.handleItem then
			ItemManager.handleItem(DB.getPath(nodeChar), "inventorylist", "item", DB.getPath(nodeHeir), true);
		else
			-- Fallback (item record not found, e.g. the module isn't loaded): drop a
			-- named keepsake so the player still receives something.
			local nodeItem = DB.createChild(nodeChar, "inventorylist");
			if nodeItem then
				DB.setValue(nodeItem, "name", "string", tEq.heirloom);
				DB.setValue(nodeItem, "count", "number", 1);
				DB.setValue(nodeItem, "isidentified", "number", 1);
			end
		end
	end
end

-- Armor Class for a freshly built character.
--
-- The sheet's total-AC field (number_chartotalac) only recomputes defenses.ac.total
-- via onUpdate handlers that attach when the charsheet WINDOW is open. During wizard
-- creation the window isn't open, so setting base/armor/shield leaves total at 0 --
-- which is exactly the "AC 0 while wearing armor" the player sees. We therefore:
--   (1) equip the single best (lowest-AC) armor + best shield (and unequip any other
--       armor/shield so the ruleset's pass is deterministic -- it lets the *last*
--       worn armor set the base), so the worn armor actually counts;
--   (2) run CharManager.calcItemArmorClass to set base/armor/shield; then
--   (3) recompute defenses.ac.total with the sheet's exact formula.
local function recalcArmorClass(nodeChar)
	local nodeBestArmor, nBestArmorAC = nil, 99;
	local nodeBestShield, nBestShieldAC = nil, 99;
	local tArmor, tShield = {}, {};
	for _, vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		local bShield = ItemManager2 and ItemManager2.isShield and ItemManager2.isShield(vNode);
		local bArmor = ItemManager2 and ItemManager2.isArmor and ItemManager2.isArmor(vNode);
		if bShield then
			tShield[#tShield + 1] = vNode;
			local nAC = DB.getValue(vNode, "ac", 0);
			if nAC < nBestShieldAC then nBestShieldAC = nAC; nodeBestShield = vNode; end
		elseif bArmor then
			tArmor[#tArmor + 1] = vNode;
			local nAC = DB.getValue(vNode, "ac", 10);
			if nAC < nBestArmorAC then nBestArmorAC = nAC; nodeBestArmor = vNode; end
		end
	end
	for _, v in ipairs(tArmor) do
		DB.setValue(v, "carried", "number", (v == nodeBestArmor) and 2 or 1);
	end
	for _, v in ipairs(tShield) do
		DB.setValue(v, "carried", "number", (v == nodeBestShield) and 2 or 1);
	end

	if CharManager and CharManager.calcItemArmorClass then
		CharManager.calcItemArmorClass(nodeChar);
	end

	local nDexBonus = 0;
	if ActorManager and ActorManagerADND and ActorManagerADND.getAbilityBonus then
		local rActor = ActorManager.resolveActor(nodeChar);
		nDexBonus = ActorManagerADND.getAbilityBonus(rActor, "dexterity", "defenseadj") or 0;
	end
	local nTotal = nDexBonus
		+ DB.getValue(nodeChar, "defenses.ac.temporary", 0)
		+ DB.getValue(nodeChar, "defenses.ac.base", 10)
		+ DB.getValue(nodeChar, "defenses.ac.armor", 0)
		+ DB.getValue(nodeChar, "defenses.ac.shield", 0)
		+ DB.getValue(nodeChar, "defenses.ac.misc", 0);
	local sAsc = (OptionsManager and OptionsManager.getOption
		and OptionsManager.getOption("HouseRule_ASCENDING_AC")) or "";
	if type(sAsc) == "string" and sAsc:match("on") then nTotal = 20 - nTotal; end
	DB.setValue(nodeChar, "defenses.ac.total", "number", nTotal);
end

-- Backfill blank weapon-attack names. The ruleset's addToWeaponDB copies each weapon
-- item's weaponlist entries onto the sheet, but occasionally an entry lands with an
-- empty name (the source item's weapon sub-entry wasn't named yet when copied) --
-- leaving an unnamed attack in the Actions tab. Each weapon entry links back to its
-- inventory item via its shortcut; that item's name is always present, so use it.
local function fixWeaponNames(nodeChar)
	for _, vW in pairs(DB.getChildren(nodeChar, "weaponlist")) do
		local sName = DB.getValue(vW, "name", "");
		if type(sName) ~= "string" or StringManager.trim(sName) == "" then
			local _, sRec = DB.getValue(vW, "shortcut", "", "");
			local sItemId = (type(sRec) == "string") and sRec:match("inventorylist%.([%w%-]+)%s*$") or nil;
			local nodeItem = sItemId and DB.getChild(nodeChar, "inventorylist." .. sItemId) or nil;
			local sItemName = nodeItem and DB.getValue(nodeItem, "name", "") or "";
			if type(sItemName) == "string" and sItemName ~= "" then
				DB.setValue(vW, "name", "string", sItemName);
				local nodeNote = DB.getChild(vW, "itemnote");
				if nodeNote then
					DB.setValue(nodeNote, "name", "string", sItemName);
				end
			end
		end
	end
end

-- Write the player's chosen weapon proficiencies into the charsheet proficiency
-- list (deduped by name), the same structure the sheet's own prof picker uses.
local function applyWeaponProfs(nodeChar)
	local tWeapons = getProfData().weapons;
	if not tWeapons or #tWeapons == 0 then
		return;
	end
	local nodeList = DB.createChild(nodeChar, "proficiencylist");
	if not nodeList then
		return;
	end
	local sSpec = getProfData().specialize or "";
	for _, sName in ipairs(tWeapons) do
		local bExists = false;
		for _, vProf in pairs(DB.getChildren(nodeList)) do
			if DB.getValue(vProf, "name", "") == sName then
				bExists = true;
				break;
			end
		end
		if not bExists then
			local nodeEntry = DB.createChild(nodeList);
			DB.setValue(nodeEntry, "name", "string", sName);
			DB.setValue(nodeEntry, "locked", "number", 1);
			-- Specialization: +1 to hit, +2 damage (matches the ruleset's own
			-- onWeaponProfSelect specialization handling).
			if sName == sSpec then
				DB.setValue(nodeEntry, "hitadj", "number", 1);
				DB.setValue(nodeEntry, "dmgadj", "number", 2);
			end
		end
	end

	-- Auto-apply each chosen proficiency to any granted weapon of that type, so
	-- purchased gear is proficient on commit instead of carrying the -2 penalty
	-- until the player hand-ticks the box.
	--
	-- Matching is PROFICIENCY-DRIVEN, not item-name guessing: the equipment
	-- catalog builds every weapon's name as "<Proficiency>" or "<Proficiency>
	-- (quality)", so a weapon belongs to proficiency P iff its name is exactly P
	-- or begins with "P (" (e.g. "Long Sword (Poor)"). Because we reconstruct the
	-- expected names from the chosen proficiencies, this can't be defeated by how
	-- any item library happens to spell or punctuate a weapon -- no per-weapon
	-- testing or alias table needed.
	if CombatManagerADND and CombatManagerADND.setWeaponProfApplication then
		local function weaponMatchesProf(sItem, sProf)
			return sItem == sProf or sItem:sub(1, #sProf + 2) == (sProf .. " (");
		end
		for _, nodeWeapon in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
			if DB.getChildCount(nodeWeapon, "proflist") < 1 then
				local sItem = DB.getValue(nodeWeapon, "name", ""):lower();
				for _, sProf in ipairs(tWeapons) do
					if weaponMatchesProf(sItem, sProf:lower()) then
						CombatManagerADND.setWeaponProfApplication(nodeWeapon, sProf, true);
						DB.setValue(nodeWeapon, "applied", "number", 1);
						local nHit = (sProf == sSpec) and 1 or 0;
						local nDmg = (sProf == sSpec) and 2 or 0;
						for _, nodeP in pairs(DB.getChildren(nodeWeapon, "proflist")) do
							if DB.getValue(nodeP, "prof", "") == sProf then
								DB.setValue(nodeP, "hitadj", "number", nHit);
								DB.setValue(nodeP, "dmgadj", "number", nDmg);
							end
						end
						break;
					end
				end
			end
		end
	end
end

-- Copy the player's chosen spells onto the character via PowerManager.addPower,
-- grouped by spell level ("Level 1", "Level 2", ...).
local function applySpells(nodeChar)
	local tSpells = getProfData().spells;
	if not tSpells or #tSpells == 0 or not (PowerManager and PowerManager.addPower) then
		return;
	end
	for _, rSpell in ipairs(tSpells) do
		local nodeSource = DB.findNode(rSpell.sPath);
		if nodeSource then
			PowerManager.addPower("reference_spell", nodeSource, nodeChar,
				string.format("Level %d", rSpell.nLevel or 1));
		end
	end
end

-- Add the player's chosen nonweapon proficiencies via the ruleset's addSkillRef.
local function applyNWPs(nodeChar)
	local tNWPs = getProfData().nwps;
	if not tNWPs or #tNWPs == 0 or not (CharManager and CharManager.addSkillRef) then
		return;
	end
	for _, rNWP in ipairs(tNWPs) do
		if rNWP.sPath and rNWP.sPath ~= "" then
			CharManager.addSkillRef(nodeChar, getClassName(), rNWP.sPath);
		end
	end
end

-- Grant the languages a character automatically knows from their race (Common +
-- racial tongue), using the ruleset's own addLanguageDB. Additional languages
-- (the longer learnable lists / INT-bonus picks) are left for the player.
local function applyLanguages(nodeChar)
	if not (CharManager and CharManager.addLanguageDB) then
		return;
	end
	-- Racial tongues (always known)...
	for _, sLang in ipairs(CharWizard2EBio.getRaceLanguages(getRaceCategoryName())) do
		CharManager.addLanguageDB(nodeChar, sLang);
	end
	-- ...plus the player's chosen extra (Intelligence) languages.
	for _, sLang in ipairs(getProfData().languages or {}) do
		CharManager.addLanguageDB(nodeChar, sLang);
	end
end

-- Write the Commit-tab character details to the charsheet "notes" fields. The
-- ruleset's alignment field is set separately; everything else is free text.
local function applyBio(nodeChar)
	local tBio = getBio();
	for _, sKey in ipairs(_tBioFields) do
		local sVal = tBio[sKey];
		if sVal and sVal ~= "" then
			DB.setValue(nodeChar, sKey, "string", sVal);
		end
	end
end

-- Create the base sub-structures a new 2E character needs before race/class
-- application. Mirrors what the char sheet creates the first time it opens.
local function initBaseStructures(nodeChar)
	-- Saves: default base of 20 for each (the ruleset improves these per class).
	for _, sSave in ipairs(DataCommon.saves) do
		DB.setValue(nodeChar, "saves." .. sSave .. ".base", "number", 20);
	end
	-- Proficiency slot tracking.
	DB.setValue(nodeChar, "proficiencies.weapon.max", "number", 0);
	DB.setValue(nodeChar, "proficiencies.nonweapon.max", "number", 0);
	-- Hit point container.
	DB.setValue(nodeChar, "hp.total", "number", 0);
end

-- Apply the rolled/assigned ability bases and recompute derived values.
local function applyAbilities(nodeChar, rBuild)
	for _, sAbility in ipairs(DataCommon.abilities) do
		local nScore = tonumber(rBuild.abilities[sAbility]) or 9;
		DB.setValue(nodeChar, "abilities." .. sAbility .. ".base", "number", nScore);
	end

	local nStr = tonumber(rBuild.abilities.strength) or 0;
	local nStrPercent = tonumber(rBuild.strpercent) or 0;
	if nStr == 18 and nStrPercent > 0 then
		DB.setValue(nodeChar, "abilities.strength.percentbase", "number", nStrPercent);
	end

	-- Recompute totals and derived properties (no open sheet to do it for us).
	AbilityScoreADND.detailsUpdate(nodeChar);
	AbilityScoreADND.detailsPercentUpdate(nodeChar);
	AbilityScoreADND.updateForEffects(nodeChar);
end

-- Create the character sheet from the gathered build data.
function createCharacter(rBuild)
	if not Session.IsHost then
		ChatManager.SystemMessage(Interface.getString("charwizard2e_msg_hostonly"));
		return nil;
	end

	local nodeChar = DB.createChild("charsheet");
	if not nodeChar then
		return nil;
	end

	-- Mirror the standard "new character" setup (identity, registration, base nodes).
	if RecordManager.onRecordAddEvent then
		RecordManager.onRecordAddEvent("charsheet", nodeChar);
	end

	local sName = StringManager.trim(rBuild.name or "");
	if sName == "" then
		sName = "New Character";
	end
	DB.setValue(nodeChar, "name", "string", sName);

	if rBuild.alignment and rBuild.alignment ~= "" then
		DB.setValue(nodeChar, "alignment", "string", rBuild.alignment);
	end

	-- Pre-create base structures the char sheet would normally build on open.
	-- In particular the "saves" node must exist before class advancement runs,
	-- otherwise the ruleset hits a createChild(nodeSaves, <number>) fallback
	-- that errors and aborts HP/THAC0/save processing.
	initBaseStructures(nodeChar);

	-- Abilities first, so racial adjustments and CON-based HP land correctly.
	applyAbilities(nodeChar, rBuild);

	-- Race (handles racial traits, proficiencies, ability adjustments, subraces).
	if rBuild.racelink and rBuild.racelink.linkrecord then
		CharManager.addRaceRef(nodeChar, rBuild.racelink.linkclass or "reference_race", rBuild.racelink.linkrecord);
	end

	-- Class. addClassRef advances one level per call (full advancement each time),
	-- so reaching level N means calling it N times. Capped by the race/class limit.
	if rBuild.classlink and rBuild.classlink.linkrecord then
		local sClassLinkClass = rBuild.classlink.linkclass or "reference_class";
		local nTarget = math.max(1, tonumber(rBuild.targetlevel) or 1);
		for _ = 1, nTarget do
			CharManager.addClassRef(nodeChar, sClassLinkClass, rBuild.classlink.linkrecord);
		end
	end

	-- Kit (2E "background" record on the main sheet).
	if rBuild.kitlink and rBuild.kitlink.linkrecord then
		CharManager.addBackgroundRef(nodeChar, rBuild.kitlink.linkclass or "reference_background", rBuild.kitlink.linkrecord);
	end

	-- Recompute after race adjustments may have changed ability totals.
	AbilityScoreADND.detailsUpdate(nodeChar);
	AbilityScoreADND.detailsPercentUpdate(nodeChar);
	AbilityScoreADND.updateForEffects(nodeChar);

	applyEquipment(nodeChar, rBuild);

	-- Armor Class: equip the best worn armor/shield, run the ruleset's item-AC pass,
	-- and recompute the displayed total (the sheet's own total handler isn't live
	-- until its window opens, so without this a new character shows AC 0).
	recalcArmorClass(nodeChar);

	-- Chosen weapon + nonweapon proficiencies and spells.
	-- Backfill blank weapon-attack names FIRST: applyWeaponProfs matches weapons to
	-- proficiencies by weaponlist name, so an unnamed weapon would also miss its prof.
	fixWeaponNames(nodeChar);
	applyWeaponProfs(nodeChar);
	applyNWPs(nodeChar);
	applySpells(nodeChar);

	-- Languages automatically known from race (Common + racial tongue).
	applyLanguages(nodeChar);

	-- Character details (gender, age, height, weight, size, deity, traits, etc.).
	applyBio(nodeChar);

	ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_created"), sName));

	-- Open the finished sheet.
	Interface.openWindow("charsheet", nodeChar);
	return nodeChar;
end
