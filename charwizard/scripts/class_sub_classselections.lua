--
-- Class picker list (source + name filters), restricted by chosen race (PHB Table 7).
--

local _tClasses = {};
local _tModules = {};
local _sComboFilter = "";
local _sFilter = "";

function onInit()
	_sComboFilter = "";
	_sFilter = "";
	self.buildClasses();
	self.buildFilters();
end

function onPageShow()
	_sComboFilter = "";
	_sFilter = "";
	self.buildClasses();
	self.buildFilters();
end

function getAllClasses()
	return _tClasses;
end
function getAllModules()
	return _tModules;
end

function clearRecords()
	_tClasses = {};
	_tModules = {};
	list.closeAll();
end

function buildRecords()
	self.clearRecords();

	if not CharWizard2E.isRaceComplete() then
		return;
	end

	local tMappings = LibraryData.getMappings("class") or {};
	for _, sMapping in ipairs(tMappings) do
		for _, vNode in pairs(DB.getChildrenGlobal(sMapping)) do
			self.addListRecord(vNode, "reference_class");
		end
	end
end

function addListRecord(vNode, sLinkClass)
	if not vNode then
		return;
	end

	local sName = StringManager.trim(DB.getValue(vNode, "name", ""));
	if sName == "" then
		return;
	end

	if not CharWizard2E.isClassAllowedForRace(sName) then
		return;
	end

	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sDisplayName = sName;
	rRecord.sDisplayNameLower = sName:lower();
	rRecord.sLinkClass = sLinkClass or "reference_class";

	rRecord.sModuleName = DB.getModule(vNode) or "";
	local tInfo = Module.getModuleInfo(rRecord.sModuleName);
	rRecord.sModule = (tInfo and tInfo.displayname) or rRecord.sModuleName;
	if rRecord.sModule == "" then
		rRecord.sModule = Interface.getString("charwizard2e_book_campaign");
	end

	local tClasses = self.getAllClasses();
	tClasses[rRecord.sDisplayNameLower] = tClasses[rRecord.sDisplayNameLower] or {};
	table.insert(tClasses[rRecord.sDisplayNameLower], rRecord);

	self.getAllModules()[rRecord.sModule] = true;
end

function buildClasses()
	self.buildRecords();

	local tKeys = {};
	for k in pairs(self.getAllClasses()) do
		table.insert(tKeys, k);
	end
	table.sort(tKeys);

	for _, k in ipairs(tKeys) do
		if self.helperFilterCheck(self.getAllClasses()[k]) then
			self.addDisplayListItem(k, self.getAllClasses()[k]);
		end
	end
end

function addDisplayListItem(_, tClass)
	if #(tClass or {}) == 0 then
		return;
	end

	local w = list.createWindow();
	if not w then
		return;
	end

	w.button_select.setVisible(true);
	w.name.setValue(tClass[1].sDisplayName);

	local tModules = {};
	local tSeenModule = {};
	for _, v in ipairs(tClass) do
		if self.moduleFilterCheck(v) and self.stringFilterCheck(v) then
			if not tSeenModule[v.sModule] then
				tSeenModule[v.sModule] = true;
				table.insert(tModules, v.sModule);
			end
		end
	end
	table.sort(tModules);

	if #tModules == 0 then
		w.close();
		return;
	end

	w.module.addItems(tModules);
	w.module.setVisible(true);

	-- When a class exists in several books, default the row to the Player's
	-- Handbook copy if available, else the first alphabetically.
	local sChosenModule = tModules[1];
	for _, s in ipairs(tModules) do
		if CharWizard2E.isPlayersHandbookLabel(s) then
			sChosenModule = s;
			break;
		end
	end
	w.module.setValue(sChosenModule);

	if #tModules == 1 then
		w.module.setComboBoxReadOnly(true);
		w.module.setFrame(nil);
	end

	local tPick = tClass[1];
	for _, v in ipairs(tClass) do
		if v.sModule == sChosenModule then
			tPick = v;
			break;
		end
	end

	w.shortcut.setValue(tPick.sLinkClass, DB.getPath(tPick.vNode));
end

function onFilterChanged()
	local sSourceFilter = StringManager.trim(filter_source.getValue() or ""):lower();
	local sNameFilter = StringManager.trim(filter_name.getValue() or ""):lower();
	if sSourceFilter == _sComboFilter and sNameFilter == _sFilter then
		return;
	end
	_sComboFilter = sSourceFilter;
	_sFilter = sNameFilter;
	self.buildClasses();
end

function buildFilters()
	filter_name.setValue("");

	filter_source.clear();
	filter_source.add("");
	local tSorted = {};
	for k in pairs(self.getAllModules()) do
		table.insert(tSorted, k);
	end
	table.sort(tSorted);
	for _, s in ipairs(tSorted) do
		filter_source.add(s);
	end

	-- Default to the Player's Handbook (if present); the player can switch to
	-- another book or "" (All) manually.
	local sDefault = CharWizard2E.getDefaultSourceLabel(tSorted);
	filter_source.setValue(sDefault);
	_sComboFilter = (sDefault or ""):lower();
	if _sComboFilter ~= "" then
		self.buildClasses();
		-- Safety: if the PHB filter hides everything (records live in a core
		-- module named differently), fall back to All so the list isn't empty.
		if #(list.getWindows() or {}) == 0 then
			filter_source.setValue("");
			_sComboFilter = "";
			self.buildClasses();
		end
	end
end

function helperFilterCheck(tClass)
	for _, v in ipairs(tClass) do
		if self.moduleFilterCheck(v) and self.stringFilterCheck(v) then
			return true;
		end
	end
	return false;
end

function moduleFilterCheck(tEntry)
	if _sComboFilter == "" then
		return true;
	end
	local sFilter = _sComboFilter;
	local sMod = (tEntry.sModule or ""):lower();
	local sModName = (tEntry.sModuleName or ""):lower();
	return (sFilter == sMod) or (sFilter == sModName);
end

function stringFilterCheck(tEntry)
	if _sFilter == "" then
		return true;
	end
	for _, v in ipairs(StringManager.split(_sFilter, ",", true)) do
		v = StringManager.trim(v):lower();
		if v ~= "" and tEntry.sDisplayNameLower:find(v, 1, true) then
			return true;
		end
	end
	return false;
end
