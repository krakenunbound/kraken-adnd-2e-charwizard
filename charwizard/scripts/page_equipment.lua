--
-- Equipment tab: PHB starting wealth roll and the gear shop.
--

function onInit()
	CharWizard2E.applyWallpaper(equipment_art, "charwizard2e_equipment_art");
	updateEquipmentUI();
end

function onPageShow()
	CharWizard2E.applyWallpaper(equipment_art, "charwizard2e_equipment_art");
	updateEquipmentUI();
end

function updateEquipmentUI()
	if not CharWizard2E.isAlignmentComplete() then
		label_needalignment.setVisible(true);
		wealth_formula_label.setVisible(false);
		wealth_formula.setVisible(false);
		wealth_roll_button.setVisible(false);
		wealth_result_label.setVisible(false);
		wealth_result.setVisible(false);
		wealth_clear_button.setVisible(false);
		setItemAreaVisible(false);
		equipment_header.setValue(Interface.getString("charwizard2e_title_equipment"));
		return;
	end

	label_needalignment.setVisible(false);
	wealth_formula_label.setVisible(true);
	wealth_formula.setVisible(true);
	wealth_roll_button.setVisible(true);
	wealth_result_label.setVisible(true);
	wealth_result.setVisible(true);
	wealth_clear_button.setVisible(true);
	setItemAreaVisible(true);

	local tWealth = CharWizard2E.getClassWealthInfo();
	wealth_formula.setValue(tWealth.sLabel or "");
	updatePurse();

	buildItemList();
end

function setItemAreaVisible(bVisible)
	items_hint.setVisible(bVisible);
	items_header.setVisible(bVisible);
	items_search_label.setVisible(bVisible);
	items_search.setVisible(bVisible);
	items_type.setVisible(bVisible);
	button_clear_items.setVisible(bVisible);
	item_list.setVisible(bVisible);
	if not bVisible then
		item_list.closeAll();
	end
end

-- Rebuild the curated starter-gear list, reflecting current chosen quantities.
function buildItemList()
	item_list.closeAll();
	local tCatalog = CharWizard2E.buildStarterCatalog();
	for _, rItem in ipairs(tCatalog) do
		local w = item_list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.shortcut.setValue("item", rItem.sPath);
			w.name.setValue(rItem.sName);
			w.cost.setValue((rItem.sCost ~= "" and rItem.sCost) or "-");
			w.category.setValue(rItem.sCat or "");
			-- Sorted by type (Armor, Weapons, Ammunition, Gear), then name.
			local nOrder = 9;
			for i, sCat in ipairs(CharWizard2E.SHOP_TYPES) do
				if sCat == rItem.sCat then nOrder = i; end
			end
			w.sortkey.setValue(nOrder .. " " .. rItem.sName:lower());
			local nQty = CharWizard2E.getChosenQty(rItem.sPath);
			w.qty.setValue((nQty > 0) and ("x" .. nQty) or "");
		end
	end
	if items_type.getValue() == "" then
		items_type.clear();
		items_type.add("All");
		for _, sCat in ipairs(CharWizard2E.SHOP_TYPES) do
			items_type.add(sCat);
		end
		items_type.setValue("All");
	end
	item_list.applyFilter();
end

function clearWealthRoll()
	CharWizard2E.clearStartingWealth();
	updateEquipmentUI();
end

-- Manager pushes animated wealth roll result here.
function setWealthResult(nGold)
	CharWizard2E.setStartingGold(nGold);
	updateEquipmentUI();
end

-- Light refresh of just the gold figure (called by the manager as starter items
-- are bought/removed, so the purse ticks down without rebuilding the list).
function updatePurse()
	local nGold = CharWizard2E.getStartingGold();
	if CharWizard2E.isWealthRolled() then
		wealth_result.setValue(string.format(Interface.getString("charwizard2e_wealth_result_value"), nGold));
	else
		wealth_result.setValue(Interface.getString("charwizard2e_wealth_result_none"));
	end
	-- Hide what the purse no longer covers (kept: anything already bought).
	item_list.applyFilter();
end

function isRowShown(w)
	local sType = items_type.getValue() or "";
	if sType ~= "" and sType ~= "All" and w.category.getValue() ~= sType then
		return false;
	end
	local sSearch = StringManager.trim(items_search.getValue() or ""):lower();
	if sSearch ~= "" and not (w.name.getValue() or ""):lower():find(sSearch, 1, true) then
		return false;
	end
	if (CharWizard2E.getChosenQty(w.shortcut.getValue() and select(2, w.shortcut.getValue()) or "") or 0) > 0 then
		return true;
	end
	return CharWizard2E.getItemCostGP(w.cost.getValue()) <= CharWizard2E.getStartingGold();
end
