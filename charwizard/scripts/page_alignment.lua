--
-- Alignment tab: show picker or confirm chosen alignment (requires a class).
--

function onInit()
	CharWizard2E.applyWallpaper(alignment_art, "charwizard2e_alignment_art");
	alignment_help.setValue(CharWizard2EBio.getAlignmentOverview());
	updateAlignmentUI();
end

function onPageShow()
	CharWizard2E.applyWallpaper(alignment_art, "charwizard2e_alignment_art");
	updateAlignmentUI();
	if sub_alignmentselection.subwindow and sub_alignmentselection.subwindow.onPageShow then
		sub_alignmentselection.subwindow.onPageShow();
	end
end

-- Alignment write-up panel (shown once an alignment is confirmed; mirrors Race/Class/Kit).
function setAlignmentDetailsVisible(bVisible)
	alignment_about_header.setVisible(bVisible);
	alignment_desc.setVisible(bVisible);
end

function showAlignmentDetails(sAlignment)
	local sDesc = CharWizard2EBio.getAlignmentDescription(sAlignment);
	if sDesc == "" then
		setAlignmentDetailsVisible(false);
		return;
	end
	alignment_desc.setValue(sDesc);
	setAlignmentDetailsVisible(true);
end

function updateAlignmentUI()
	setAlignmentDetailsVisible(false);

	if not CharWizard2E.isClassComplete() then
		label_needclass.setVisible(true);
		label_restrictions.setVisible(false);
		sub_alignmentselection.setVisible(false);
		alignment_help.setVisible(false);
		button_changealignment.setVisible(false);
		alignment_header.setValue(Interface.getString("charwizard2e_title_alignments"));
		return;
	end

	label_needclass.setVisible(false);

	local t = CharWizard2E.getAlignment();
	if t and t.text and t.text ~= "" then
		-- Confirmed: hide the list and the restriction hint, show the write-up.
		label_restrictions.setVisible(false);
		sub_alignmentselection.setVisible(false);
		alignment_help.setVisible(false);
		button_changealignment.setVisible(true);
		alignment_header.setValue(string.upper(t.text));
		showAlignmentDetails(t.text);
		return;
	end

	-- Choosing: show the restriction hint (if any) above the list.
	local sRestriction = CharWizard2E.getAlignmentRestrictionHint();
	if sRestriction and sRestriction ~= "" then
		label_restrictions.setValue(sRestriction);
		label_restrictions.setVisible(true);
	else
		label_restrictions.setVisible(false);
	end

	sub_alignmentselection.setVisible(true);
	alignment_help.setVisible(true);
	button_changealignment.setVisible(false);
	alignment_header.setValue(Interface.getString("charwizard2e_title_alignments"));
end

function resetAlignment()
	CharWizard2E.clearAlignment();
	updateAlignmentUI();
	if sub_alignmentselection.subwindow and sub_alignmentselection.subwindow.buildAlignments then
		sub_alignmentselection.subwindow.buildAlignments();
	end
	CharWizard2E.updateTabStatus();
end
