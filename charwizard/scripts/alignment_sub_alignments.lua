--
-- Alignment picker list (nine PHB alignments, filtered by class restrictions).
--

function onInit()
	self.buildAlignments();
end

function onPageShow()
	self.buildAlignments();
end

function buildAlignments()
	list.closeAll();

	if not CharWizard2E.isClassComplete() then
		return;
	end

	for _, sAlignment in ipairs(CharWizard2E.getAlignmentOptions()) do
		local w = list.createWindow();
		if w then
			w.button_select.setVisible(true);
			w.name.setValue(sAlignment);
		end
	end
end
