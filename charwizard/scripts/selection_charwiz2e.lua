--
-- Shared handlers for wizard list-entry + buttons.
--

function onSelectButtonPressed()
	local sClass = getClass();
	if sClass == "list_entry_charwiz2e_raceselection" then
		CharWizard2E.processRace(self);
	elseif sClass == "list_entry_charwiz2e_subraceselection" then
		CharWizard2E.processSubrace(self);
	elseif sClass == "list_entry_charwiz2e_classselection" then
		CharWizard2E.processClass(self);
	elseif sClass == "list_entry_charwiz2e_kitselection" then
		CharWizard2E.processKit(self);
	elseif sClass == "list_entry_charwiz2e_alignmentselection" then
		CharWizard2E.processAlignment(self);
	end
end

function onModuleValueChanged()
	local sClass = getClass();
	if sClass == "list_entry_charwiz2e_raceselection" then
		self.onModuleValueChangedGeneral("getAllRaces", "reference_race");
	elseif sClass == "list_entry_charwiz2e_subraceselection" then
		self.onModuleValueChangedSubrace();
	elseif sClass == "list_entry_charwiz2e_classselection" then
		self.onModuleValueChangedGeneral("getAllClasses", "reference_class");
	elseif sClass == "list_entry_charwiz2e_kitselection" then
		self.onModuleValueChangedKit();
	end
end

function onModuleValueChangedKit()
	local sName = name.getValue():lower();
	local tRecords = CharWizard2E.getPendingKits();
	if not tRecords then
		return;
	end
	local tList = tRecords[sName];
	if not tList then
		return;
	end
	for _, v2 in ipairs(tList) do
		if module.getValue() == v2.sModule then
			shortcut.setValue(v2.sLinkClass or "reference_background", DB.getPath(v2.vNode));
			return;
		end
	end
end

function onModuleValueChangedSubrace()
	local sName = name.getValue():lower();
	local tRecords = CharWizard2E.getPendingSubraces();
	if not tRecords then
		return;
	end
	local tList = tRecords[sName];
	if not tList then
		return;
	end
	for _, v2 in ipairs(tList) do
		if module.getValue() == v2.sModule then
			shortcut.setValue(v2.sLinkClass or "reference_subrace", DB.getPath(v2.vNode));
			return;
		end
	end
end

function onModuleValueChangedGeneral(sFunction, sRecordClass)
	local sName = name.getValue():lower();
	local tRecords = WindowManager.callOuterWindowFunction(self, sFunction);
	if not tRecords then
		return;
	end
	local tList = tRecords[sName];
	if not tList then
		return;
	end
	for _, v2 in ipairs(tList) do
		if module.getValue() == v2.sModule then
			shortcut.setValue(v2.sLinkClass or sRecordClass, DB.getPath(v2.vNode));
			return;
		end
	end
end
