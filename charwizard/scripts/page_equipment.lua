--
-- Equipment tab: PHB starting wealth roll. The free-items toggle lives in the
-- FG Options menu now; this page just shows its current ON/OFF status.
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
		setHeirloomVisible(false);
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

	buildFreeList();
	buildItemList();

	-- Family heirloom section (DM option "Allow family heirloom items").
	local bHeir = CharWizard2E.isHeirloomAllowed();
	setHeirloomVisible(bHeir);
	if bHeir then
		local sHeir = CharWizard2E.getHeirloom();
		if sHeir ~= "" then
			heirloom_result.setValue("Heirloom: " .. sHeir .. " -- added to your sheet when you finish.");
			showHeirloomArt(CharWizard2E.getHeirloomDetails());
		else
			heirloom_result.setValue("Roll the dice for a random family heirloom -- a keepsake from home, added to your character sheet.");
			showHeirloomArt(nil);
		end
	end
end

function setItemAreaVisible(bVisible)
	free_header.setVisible(bVisible);
	free_list.setVisible(bVisible);
	items_hint.setVisible(bVisible);
	items_header.setVisible(bVisible);
	button_clear_items.setVisible(bVisible);
	item_list.setVisible(bVisible);
	if not bVisible then
		free_list.closeAll();
		item_list.closeAll();
	end
end

function setHeirloomVisible(bVisible)
	heirloom_header.setVisible(bVisible);
	heirloom_roll_button.setVisible(bVisible);
	heirloom_result.setVisible(bVisible);
	if not bVisible then
		showHeirloomArt(nil);
	end
end

-- Show the rolled heirloom: a clickable link that opens its full record (picture
-- + text) plus the plain description below. Pass nil to clear it.
function showHeirloomArt(tD)
	if not tD then
		heirloom_link.setVisible(false);
		heirloom_linklabel.setVisible(false);
		heirloom_desc.setVisible(false);
		return;
	end
	local bLink = (tD.sPath or "") ~= "";
	if bLink then
		heirloom_link.setValue("item", tD.sPath);
	end
	heirloom_link.setVisible(bLink);
	heirloom_linklabel.setVisible(bLink);
	if (tD.sDesc or "") ~= "" then
		heirloom_desc.setValue(tD.sDesc);
		heirloom_desc.setVisible(true);
	else
		heirloom_desc.setVisible(false);
	end
end

-- Free Starter Kit list: the class kit + pack, player-selectable at no gold cost.
-- DM-gated by "Grant free starter items".
function buildFreeList()
	free_list.closeAll();
	if not CharWizard2E.getDmFreebies() then
		free_header.setValue("Free Starter Kit - disabled by the DM (Options > Grant free starter items)");
		return;
	end
	free_header.setValue("Free Starter Kit - click + to add (no gold cost)");
	for _, rItem in ipairs(CharWizard2E.buildFreeCatalog()) do
		local w = free_list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.shortcut.setValue("item", rItem.sPath);
			w.name.setValue(rItem.sName);
			w.cost.setValue("free");
			local nQty = CharWizard2E.getChosenQty(rItem.sPath);
			w.qty.setValue((nQty > 0) and ("x" .. nQty) or "");
		end
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
			local nQty = CharWizard2E.getChosenQty(rItem.sPath);
			w.qty.setValue((nQty > 0) and ("x" .. nQty) or "");
		end
	end
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
end
