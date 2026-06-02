--
-- Commit tab - character details subwindow. Editable bio fields, each with a
-- dice button to roll a random value, plus a "Roll All" button. Age / max age /
-- height / weight / size are auto-derived from race+gender on first show.
--

function onInit()
	onPageShow();
end

function onPageShow()
	CharWizard2E.autofillBioDefaults();
	refresh();
end

local function raceText()
	local tRace = CharWizard2E.getRace();
	if not tRace or not tRace.text or tRace.text == "" then
		return "";
	end
	if tRace.parenttext and tRace.parenttext ~= "" then
		return string.format("%s (%s)", tRace.parenttext, tRace.text);
	end
	return tRace.text;
end

-- Push current build/bio values into the controls.
function refresh()
	val_race.setValue(raceText());
	val_class.setValue(CharWizard2E.getClassDisplayName());
	val_alignment.setValue(CharWizard2E.getAlignmentName());

	fld_gender.setValue(CharWizard2E.getBioField("gender"));
	fld_age.setValue(CharWizard2E.getBioField("age"));
	fld_agemax.setValue(CharWizard2E.getBioField("agemax"));
	fld_height.setValue(CharWizard2E.getBioField("height"));
	fld_weight.setValue(CharWizard2E.getBioField("weight"));
	fld_size.setValue(CharWizard2E.getBioField("size"));
	fld_deity.setValue(CharWizard2E.getBioField("deity"));
	fld_personalitytraits.setValue(CharWizard2E.getBioField("personalitytraits"));
	fld_ideals.setValue(CharWizard2E.getBioField("ideals"));
	fld_bonds.setValue(CharWizard2E.getBioField("bonds"));
	fld_flaws.setValue(CharWizard2E.getBioField("flaws"));
	fld_appearance.setValue(CharWizard2E.getBioField("appearance"));
	fld_notes.setValue(CharWizard2E.getBioField("notes"));
end

-- A field's text was edited by the player.
function onFieldChanged(sKey, sVal)
	CharWizard2E.setBioField(sKey, sVal);
end

-- Roll a single field from its table.
function rollField(sKey)
	local sRace = CharWizard2E.getRaceCategoryName();
	local sGender = CharWizard2E.getBioField("gender");
	local v = nil;
	if sKey == "gender" then
		v = CharWizard2EBio.rollGender();
	elseif sKey == "age" then
		v = CharWizard2EBio.rollAge(sRace);
	elseif sKey == "height" then
		v = CharWizard2EBio.rollHeight(sRace, sGender);
	elseif sKey == "weight" then
		v = CharWizard2EBio.rollWeight(sRace, sGender);
	elseif sKey == "deity" then
		v = CharWizard2EBio.rollDeity();
	elseif sKey == "personalitytraits" then
		v = CharWizard2EBio.rollTrait();
	elseif sKey == "ideals" then
		v = CharWizard2EBio.rollIdeal();
	elseif sKey == "bonds" then
		v = CharWizard2EBio.rollBond();
	elseif sKey == "flaws" then
		v = CharWizard2EBio.rollFlaw();
	elseif sKey == "appearance" then
		v = CharWizard2EBio.rollAppearance();
	end
	if v then
		CharWizard2E.setBioField(sKey, v);
		refresh();
	end
end

-- Roll every random field. Gender first so height/weight use the new gender.
function rollAll()
	for _, sKey in ipairs({
		"gender", "age", "height", "weight", "deity",
		"personalitytraits", "ideals", "bonds", "flaws", "appearance",
	}) do
		rollField(sKey);
	end
end
