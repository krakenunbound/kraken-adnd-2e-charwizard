--
-- Kit tab (after Class): pick a class kit (2E "background"), or "No Kit".
-- Gated on a chosen class; the kit list is filtered by class + race.
--

function ensureKitArt()
	CharWizard2E.applyWallpaper(kit_art, "charwizard2e_kit_art");
end

function onInit()
	ensureKitArt();
	updateKitUI();
end

function onPageShow()
	ensureKitArt();
	updateKitUI();
end

-- Kit write-up panel (shown once a real kit is confirmed; mirrors Race/Class).
function setKitDetailsVisible(bVisible)
	kit_about_header.setVisible(bVisible);
	kit_desc.setVisible(bVisible);
end

-- Turn a record's formattedtext (markup) into plain paragraphs for the simplestringc.
local function formattedToPlain(sText)
	local s = sText or "";
	s = s:gsub("</p>", "\r\r"):gsub("</h>", "\r\r"):gsub("</li>", "\r");
	s = s:gsub("<[^>]+>", "");
	s = s:gsub("&#13;", "\r"):gsub("&#10;", "\r");
	s = s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&");
	s = s:gsub("\r\r\r+", "\r\r");
	s = s:gsub("^%s+", ""):gsub("%s+$", "");
	return s;
end

-- Pull the chosen kit's description straight from its background record.
local function getKitDescription()
	local tKit = CharWizard2E.getKit();
	if not tKit or not tKit.linkrecord or tKit.linkrecord == "" then
		return "";
	end
	local node = DB.findNode(tKit.linkrecord);
	if not node then
		return "";
	end
	return formattedToPlain(DB.getValue(node, "text", ""));
end

function showKitDetails()
	local sDesc = getKitDescription();
	if sDesc == "" then
		setKitDetailsVisible(false);
		return;
	end
	kit_desc.setValue(sDesc);
	setKitDetailsVisible(true);
end

function updateKitUI()
	setKitDetailsVisible(false);

	if not CharWizard2E.isClassComplete() then
		label_needclass.setVisible(true);
		kit_status.setVisible(false);
		button_changekit.setVisible(false);
		button_nokit.setVisible(false);
		kit_selection_list.setVisible(false);
		kit_selection_list.closeAll();
		kit_header.setValue(Interface.getString("charwizard2e_title_kit"));
		return;
	end
	label_needclass.setVisible(false);

	if CharWizard2E.isKitComplete() then
		-- A decision has been made (a kit, or "No Kit").
		local tKit = CharWizard2E.getKit();
		if tKit and tKit.text and tKit.text ~= "" then
			kit_header.setValue(string.upper(tKit.text));
			kit_status.setVisible(false);
			showKitDetails();
		else
			kit_header.setValue(Interface.getString("charwizard2e_title_kit"));
			kit_status.setValue(Interface.getString("charwizard2e_kit_none"));
			kit_status.setVisible(true);
		end
		button_changekit.setVisible(true);
		button_nokit.setVisible(false);
		kit_selection_list.setVisible(false);
		kit_selection_list.closeAll();
		return;
	end

	-- Choosing a kit.
	kit_header.setValue(Interface.getString("charwizard2e_title_kit"));
	kit_status.setVisible(false);
	button_changekit.setVisible(false);
	button_nokit.setVisible(true);
	kit_selection_list.setVisible(true);
	setupKits();
end

function setupKits()
	kit_selection_list.closeAll();

	-- Rebuild against the current class/race.
	CharWizard2E.setPendingKits(CharWizard2E.buildKitTable());

	local tKits = CharWizard2E.getPendingKits() or {};
	local tKeys = {};
	for k in pairs(tKits) do
		table.insert(tKeys, k);
	end
	table.sort(tKeys);

	for _, k in ipairs(tKeys) do
		local tGroup = tKits[k];
		if tGroup and #tGroup > 0 then
			local w = kit_selection_list.createWindow();
			if w then
				w.button_select.setVisible(true);
				w.name.setValue(tGroup[1].sDisplayName);

				local tModules = {};
				local tSeen = {};
				for _, v in ipairs(tGroup) do
					if not tSeen[v.sModule] then
						tSeen[v.sModule] = true;
						table.insert(tModules, v.sModule);
					end
				end
				table.sort(tModules);

				w.module.addItems(tModules);
				w.module.setVisible(true);
				w.module.setValue(tModules[1]);
				if #tModules == 1 then
					w.module.setComboBoxReadOnly(true);
					w.module.setFrame(nil);
				end

				local tPick = tGroup[1];
				for _, v in ipairs(tGroup) do
					if v.sModule == tModules[1] then
						tPick = v;
						break;
					end
				end
				w.shortcut.setValue(tPick.sLinkClass, DB.getPath(tPick.vNode));
			end
		end
	end
end

function confirmNoKit()
	CharWizard2E.processNoKit();
	updateKitUI();
end

function changeKit()
	CharWizard2E.resetKitChoice();
	updateKitUI();
end
