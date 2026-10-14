--
-- Commit tab: gather every wizard choice, show a summary + validation, and on
-- "Create Character" hand the build to CharWizard2E.createCharacter() (which
-- drives the ruleset's CharManager add*Ref calls so FG applies all the math).
--

function onInit()
	CharWizard2E.applyWallpaper(commit_art, "charwizard2e_commit_art");
	refresh();
end

function onPageShow()
	CharWizard2E.applyWallpaper(commit_art, "charwizard2e_commit_art");
	refresh();
	if sub_details.subwindow and sub_details.subwindow.onPageShow then
		sub_details.subwindow.onPageShow();
	end
end

function refresh()
	name_entry.setValue(CharWizard2E.getBuildName());

	local tWarn = CharWizard2E.getBuildWarnings();
	if #tWarn == 0 then
		warn_text.setValue(Interface.getString("charwizard2e_commit_ready"));
	else
		local tLines = { Interface.getString("charwizard2e_commit_missing") };
		for _, s in ipairs(tWarn) do
			table.insert(tLines, "- " .. s);
		end
		warn_text.setValue(table.concat(tLines, "\r"));
	end

	-- Always available: an unfinished character is saved with the open
	-- choices at the top of its notes, to finish later with the DM.
	create_button.setVisible(true);
end

function onCreate()
	local sName = StringManager.trim(name_entry.getValue() or "");
	CharWizard2E.setBuildName(sName);

	local tOpen = CharWizard2E.getBuildWarnings();
	local nodeChar = CharWizard2E.createCharacter(CharWizard2E.getBuildPayload(sName));
	if nodeChar then
		if #tOpen > 0 then
			local sOpen = string.format(Interface.getString("charwizard2e_notes_unfinished"), table.concat(tOpen, " "));
			local sNotes = DB.getValue(nodeChar, "notes", "");
			DB.setValue(nodeChar, "notes", "string", sNotes ~= "" and (sOpen .. string.char(10, 10) .. sNotes) or sOpen);
			ChatManager.SystemMessage(string.format(Interface.getString("charwizard2e_msg_unfinished"),
					DB.getValue(nodeChar, "name", ""), table.concat(tOpen, " ")));
		end
		CharWizard2E.closeWizard();
	end
end
