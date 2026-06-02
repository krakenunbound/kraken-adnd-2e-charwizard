--
-- Race tab: main race list, optional subrace list, or confirmed choice.
--

-- Faded full-frame wallpaper behind the race list (shared helper).
function ensureRaceArt()
	CharWizard2E.applyWallpaper(race_art, "charwizard2e_race_art");
end

-- Race portrait + description panel (shown once a race is confirmed).
function setRaceDetailsVisible(bVisible)
	race_about_header.setVisible(bVisible);
	race_image.setVisible(bVisible);
	race_desc_top.setVisible(bVisible);
	race_desc_below.setVisible(bVisible);
	if not bVisible and race_image.findWidget then
		local c = race_image.findWidget("race_portrait");
		if c then c.destroy(); end
	end
end

function showRaceDetails(sRace)
	if CharWizard2EBio.getRaceDescription(sRace) == "" then
		setRaceDetailsVisible(false);
		return;
	end
	setRaceDetailsVisible(true);
	race_desc_top.setValue(CharWizard2EBio.getRaceDescTop(sRace));
	race_desc_below.setValue(CharWizard2EBio.getRaceDescBelow(sRace));
	local nImgW, nImgH = CharWizard2EBio.getRaceImageSize(sRace);
	setRaceImage(CharWizard2EBio.getRaceImage(sRace), nImgW, nImgH);
end

function setRaceImage(sIcon, nImgW, nImgH)
	if not race_image.addBitmapWidget then
		return;
	end
	local cExisting = race_image.findWidget and race_image.findWidget("race_portrait");
	if cExisting then
		cExisting.destroy();
	end
	if not sIcon or sIcon == "" then
		return;
	end
	local nW, nH = 240, 300;
	if race_image.getSize then
		local w, h = race_image.getSize();
		if w and w > 0 then nW = w; end
		if h and h > 0 then nH = h; end
	end
	-- The race portraits are tall, varied-aspect art (NOT square, and not the 480x600
	-- the class portraits use), so neither stretching to the full frame nor forcing a
	-- square draws them without distortion. Scale by the image's real pixel size to fit
	-- inside the frame while preserving its aspect ratio (centered, letterboxed) -- that
	-- keeps the source pixels from ever being squished. Falls back to a centered square
	-- if the size is unknown.
	local nDrawW, nDrawH;
	if nImgW and nImgH and nImgW > 0 and nImgH > 0 then
		local nScale = math.min(nW / nImgW, nH / nImgH);
		nDrawW = math.floor(nImgW * nScale);
		nDrawH = math.floor(nImgH * nScale);
	else
		nDrawW = math.min(nW, nH);
		nDrawH = nDrawW;
	end
	race_image.addBitmapWidget({
		name = "race_portrait", icon = sIcon, position = "center", x = 0, y = 0, w = nDrawW, h = nDrawH,
	});
end

function onInit()
	ensureRaceArt();
	updateRaceUI();
end

function onPageShow()
	ensureRaceArt();
	updateRaceUI();
	if sub_raceselection.subwindow and sub_raceselection.subwindow.onPageShow then
		sub_raceselection.subwindow.onPageShow();
	end
end

function updateRaceUI()
	local tRace = CharWizard2E.getRace();
	local tPending = CharWizard2E.getRacePending();

	setRaceDetailsVisible(false);

	if tRace and tRace.text and tRace.text ~= "" then
		sub_raceselection.setVisible(false);
		subrace_selection_list.setVisible(false);
		subrace_selection_header.setVisible(false);
		button_changesubrace.setVisible(false);
		button_changerace.setVisible(true);
		if tRace.parenttext and tRace.parenttext ~= "" then
			race_header.setValue(string.upper(string.format("%s (%s)", tRace.parenttext, tRace.text)));
		else
			race_header.setValue(string.upper(tRace.text));
		end
		showRaceDetails(CharWizard2E.getRaceCategoryName());
		return;
	end

	button_changerace.setVisible(false);

	if tPending and tPending.text and tPending.text ~= "" then
		sub_raceselection.setVisible(false);
		subrace_selection_header.setVisible(true);
		subrace_selection_list.setVisible(true);
		button_changesubrace.setVisible(true);
		race_header.setValue(string.upper(tPending.text));
		setupSubraces();
		return;
	end

	sub_raceselection.setVisible(true);
	subrace_selection_header.setVisible(false);
	subrace_selection_list.setVisible(false);
	subrace_selection_list.closeAll();
	button_changesubrace.setVisible(false);
	race_header.setValue(Interface.getString("charwizard2e_title_races"));
end

function setupSubraces()
	subrace_selection_list.closeAll();

	local tSubraces = CharWizard2E.getPendingSubraces() or {};
	local tKeys = {};
	for k in pairs(tSubraces) do
		table.insert(tKeys, k);
	end
	table.sort(tKeys);

	for _, k in ipairs(tKeys) do
		local tGroup = tSubraces[k];
		if tGroup and #tGroup > 0 then
			local w = subrace_selection_list.createWindow();
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

function resetRace()
	CharWizard2E.setRace(nil);
	CharWizard2E.clearRacePending();
	CharWizard2E.clearClass();
	updateRaceUI();
	if sub_raceselection.subwindow and sub_raceselection.subwindow.buildRaces then
		sub_raceselection.subwindow.buildRaces();
	end
	CharWizard2E.updateTabStatus();
end

function resetSubrace()
	CharWizard2E.clearRacePending();
	CharWizard2E.clearClass();
	updateRaceUI();
	if sub_raceselection.subwindow and sub_raceselection.subwindow.buildRaces then
		sub_raceselection.subwindow.buildRaces();
	end
	CharWizard2E.updateTabStatus();
end
