--
-- Class tab: class list, or confirmed class + starting level.
-- (Kits moved to their own tab after Class, 5E-style.)
--

function ensureClassArt()
	CharWizard2E.applyWallpaper(class_art, "charwizard2e_class_art");
end

function onInit()
	ensureClassArt();
	updateClassUI();
end

function onPageShow()
	ensureClassArt();
	updateClassUI();
	if sub_classselection.subwindow and sub_classselection.subwindow.onPageShow then
		sub_classselection.subwindow.onPageShow();
	end
end

function updateClassUI()
	-- No race yet: can't choose a class.
	if not CharWizard2E.isRaceComplete() then
		label_needrace.setVisible(true);
		sub_classselection.setVisible(false);
		button_changeclass.setVisible(false);
		setLevelUIVisible(false);
		setClassDetailsVisible(false);
		class_header.setValue(Interface.getString("charwizard2e_title_classes"));
		return;
	end
	label_needrace.setVisible(false);

	local tClass = CharWizard2E.getClass();
	if tClass and tClass.text and tClass.text ~= "" then
		-- Confirmed: hide the list and show the portrait + write-up (like the Race tab),
		-- with the level selector pinned at the top.
		sub_classselection.setVisible(false);
		class_header.setValue(string.upper(tClass.text));
		button_changeclass.setVisible(true);
		setLevelUIVisible(true);
		updateLevelUI();
		showClassDetails(tClass.text);
	else
		-- Not yet chosen: show the list so a class can be picked.
		sub_classselection.setVisible(true);
		setClassDetailsVisible(false);
		class_header.setValue(Interface.getString("charwizard2e_title_classes"));
		button_changeclass.setVisible(false);
		setLevelUIVisible(false);
	end
end

-- Class portrait + description panel (shown once a class is confirmed).
function setClassDetailsVisible(bVisible)
	class_about_header.setVisible(bVisible);
	class_image.setVisible(bVisible);
	class_desc_top.setVisible(bVisible);
	class_desc_below.setVisible(bVisible);
	if not bVisible and class_image.findWidget then
		local c = class_image.findWidget("class_portrait");
		if c then c.destroy(); end
	end
end

function showClassDetails(sClass)
	if CharWizard2EBio.getClassDescription(sClass) == "" then
		setClassDetailsVisible(false);
		return;
	end
	setClassDetailsVisible(true);
	class_desc_top.setValue(CharWizard2EBio.getClassDescTop(sClass));
	class_desc_below.setValue(CharWizard2EBio.getClassDescBelow(sClass));
	setClassImage(CharWizard2EBio.getClassImage(sClass));
end

function setClassImage(sIcon)
	if not class_image.addBitmapWidget then
		return;
	end
	local cExisting = class_image.findWidget and class_image.findWidget("class_portrait");
	if cExisting then
		cExisting.destroy();
	end
	if not sIcon or sIcon == "" then
		return;
	end
	local nW, nH = 240, 300;
	if class_image.getSize then
		local w, h = class_image.getSize();
		if w and w > 0 then nW = w; end
		if h and h > 0 then nH = h; end
	end
	class_image.addBitmapWidget({
		name = "class_portrait", icon = sIcon, position = "center", x = 0, y = 0, w = nW, h = nH,
	});
end

function setLevelUIVisible(bVisible)
	lbl_level.setVisible(bVisible);
	level_dec.setVisible(bVisible);
	level_value.setVisible(bVisible);
	level_inc.setVisible(bVisible);
	level_max.setVisible(bVisible);
end

function updateLevelUI()
	level_value.setValue(tostring(CharWizard2E.getTargetLevel()));
	level_max.setValue(string.format(
		Interface.getString("charwizard2e_level_max"), CharWizard2E.getRaceClassMaxLevel()));
end

function onLevelInc()
	CharWizard2E.setTargetLevel(CharWizard2E.getTargetLevel() + 1);
	updateLevelUI();
end

function onLevelDec()
	CharWizard2E.setTargetLevel(CharWizard2E.getTargetLevel() - 1);
	updateLevelUI();
end

function resetClass()
	CharWizard2E.clearClass();
	updateClassUI();
	if sub_classselection.subwindow and sub_classselection.subwindow.buildClasses then
		sub_classselection.subwindow.buildClasses();
	end
	CharWizard2E.updateTabStatus();
end
