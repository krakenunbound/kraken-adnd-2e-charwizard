--
-- Kraken AD&D 2E Character Wizard - biography random tables.
--
-- Provides random/derived values for the Commit tab's character-details fields.
-- Age / max age / height / weight / size are derived from race (and gender);
-- the flavor fields (deity, personality, philosophy, relationships, faults,
-- appearance) roll on simple tables. Everything can also be typed by the player.
--
-- Exposed as the global CharWizard2EBio (named <script> package). Public
-- functions are declared as plain `function foo()` so FG registers them as
-- CharWizard2EBio.foo; do NOT prefix them with the table name.
--

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

-- base + count d sides (e.g. roll(40, 5, 6) = 40 + 5d6).
local function roll(nBase, nCount, nSides)
	local n = nBase or 0;
	for _ = 1, (nCount or 0) do
		n = n + math.random(nSides or 1);
	end
	return n;
end

local function pick(t)
	if not t or #t == 0 then
		return "";
	end
	return t[math.random(#t)];
end

-- Normalize any race/subrace label to a base race key.
local function raceKey(sRace)
	local s = (sRace or ""):lower();
	if s:find("half", 1, true) and s:find("elf", 1, true) then return "half-elf"; end
	if s:find("half", 1, true) and s:find("orc", 1, true) then return "half-orc"; end
	if s:find("dwarf", 1, true) or s:find("dwarv", 1, true) then return "dwarf"; end
	if s:find("elf", 1, true) or s:find("elv", 1, true) then return "elf"; end
	if s:find("gnome", 1, true) then return "gnome"; end
	if s:find("halfling", 1, true) or s:find("hobbit", 1, true) then return "halfling"; end
	return "human";
end

local function genderKey(sGender)
	local s = (sGender or ""):lower();
	if s:find("female", 1, true) or s == "f" then return "female"; end
	return "male";
end

-- ---------------------------------------------------------------------------
-- Race data (approximate AD&D 2E values)
-- ---------------------------------------------------------------------------

-- Starting age: base + count d sides. Max age: base + count d sides.
local _tAge = {
	["human"]    = { start = {15, 1, 4},  max = {90, 2, 20} },
	["dwarf"]    = { start = {40, 5, 6},  max = {325, 1, 100} },
	["elf"]      = { start = {100, 5, 6}, max = {600, 2, 100} },
	["gnome"]    = { start = {60, 3, 12}, max = {300, 1, 100} },
	["half-elf"] = { start = {20, 1, 6},  max = {160, 2, 20} },
	["halfling"] = { start = {20, 3, 4},  max = {100, 2, 20} },
	["half-orc"] = { start = {13, 1, 4},  max = {60, 2, 10} },
};

-- 2E sizes: demihumans of small stature are Small, the rest Medium.
local _tSize = {
	["human"] = "M", ["elf"] = "M", ["half-elf"] = "M", ["half-orc"] = "M",
	["dwarf"] = "M", ["gnome"] = "S", ["halfling"] = "S",
};

-- Height in inches and weight in pounds: base + count d sides, per race/gender.
local _tBody = {
	["human"]    = { male = { h = {60, 2, 10}, w = {140, 6, 10} }, female = { h = {59, 2, 8},  w = {100, 6, 8} } },
	["dwarf"]    = { male = { h = {43, 1, 8},  w = {130, 4, 10} }, female = { h = {41, 1, 8},  w = {105, 4, 8} } },
	["elf"]      = { male = { h = {55, 2, 8},  w = {85,  3, 10} }, female = { h = {54, 2, 6},  w = {70,  3, 8} } },
	["gnome"]    = { male = { h = {38, 1, 6},  w = {72,  5, 4} },  female = { h = {36, 1, 6},  w = {65,  5, 4} } },
	["half-elf"] = { male = { h = {60, 2, 10}, w = {110, 4, 10} }, female = { h = {58, 2, 8},  w = {90,  4, 8} } },
	["halfling"] = { male = { h = {32, 2, 6},  w = {52,  5, 3} },  female = { h = {30, 2, 6},  w = {48,  5, 3} } },
	["half-orc"] = { male = { h = {62, 2, 10}, w = {150, 6, 10} }, female = { h = {60, 2, 8},  w = {120, 6, 8} } },
};

-- ---------------------------------------------------------------------------
-- Flavor tables
-- ---------------------------------------------------------------------------

local _tGenders = { "Male", "Female" };

-- A representative spread of Greyhawk powers (plus the demihuman patrons).
local _tDeities = {
	"Pelor", "St. Cuthbert", "Heironeous", "Hextor", "Boccob", "Wee Jas",
	"Nerull", "Kord", "Olidammara", "Fharlanghn", "Pholtus", "Obad-Hai",
	"Ehlonna", "Rao", "Trithereon", "Erythnul", "Vecna", "Zilchus",
	"Istus", "Beory", "Corellon Larethian", "Moradin", "Yondalla",
	"Garl Glittergold", "Ulaa",
};

local _tTraits = {
	"Quick to laugh, slow to anger.",
	"Speaks bluntly, with little patience for flattery.",
	"Endlessly curious about anything new.",
	"Calm and deliberate, never rushes a decision.",
	"Boastful, certain of their own importance.",
	"Quiet and watchful; misses nothing.",
	"Fiercely loyal once your trust is earned.",
	"Restless - happiest on the move.",
	"Wry humor, especially in danger.",
	"Generous to a fault with friends and strangers alike.",
	"Suspicious of magic and those who wield it.",
	"Honor-bound; a promise given is a promise kept.",
	"Hot-headed and itching for a fight.",
	"Soft-spoken but absolutely immovable when resolved.",
	"Collects stories and trinkets from every road.",
};

local _tIdeals = {
	"Freedom. Chains of any kind must be broken.",
	"Honor. My word is the truest coin I carry.",
	"Knowledge. The world rewards those who understand it.",
	"Power. Strength decides who shapes the future.",
	"Faith. My god's will is my compass.",
	"Glory. I will be remembered in song.",
	"Order. Law and tradition keep the dark at bay.",
	"Mercy. The strong protect the weak.",
	"Greed. Coin and comfort are their own reward.",
	"Nature. The wild is wiser than any throne.",
	"Redemption. I have wrongs to set right.",
	"Self-reliance. Trust your own hands above all.",
};

local _tBonds = {
	"Sworn to protect a younger sibling left behind.",
	"Indebted to a mentor who vanished without a trace.",
	"Carries a keepsake from a lost love.",
	"Owes a life-debt to a stranger met on the road.",
	"Loyal to a mercenary company or guild.",
	"Seeks a rival who bested them years ago.",
	"Guards a secret entrusted by a dying friend.",
	"Devoted to restoring a fallen family name.",
	"Bound to a homeland they may never see again.",
	"Watches over an orphan or apprentice.",
	"Hunts the band that destroyed their village.",
	"Honors a pact made with a strange patron.",
};

local _tFlaws = {
	"Cannot resist a wager, however foolish.",
	"Holds grudges far longer than is wise.",
	"Trusts too easily and is often deceived.",
	"Drinks to forget, then forgets to stop.",
	"Pride blinds them to good counsel.",
	"Terrified of a particular creature or place.",
	"Greed overrides caution near treasure.",
	"Speaks first and thinks much, much later.",
	"Secretly a coward when truly alone.",
	"Owes money to dangerous people.",
	"Cannot abide authority of any kind.",
	"Haunted by a past failure they hide from all.",
};

local _tAppearance = {
	"Weathered and scarred, with a steady gaze.",
	"Travel-worn clothes kept scrupulously clean.",
	"A crooked smile and laughing eyes.",
	"Tall and gaunt, moving with quiet economy.",
	"Broad-shouldered, with calloused, capable hands.",
	"A faded tattoo hints at an old allegiance.",
	"Bright, mismatched garments and too much jewelry.",
	"Plain features easily lost in a crowd.",
	"A notable scar across the brow or cheek.",
	"Close-cropped hair and a soldier's bearing.",
	"Long braided hair threaded with small charms.",
	"Eyes of an unusual, arresting color.",
};

-- Languages automatically known by race (Common + racial tongue). The longer
-- lists of "learnable" racial languages are left for the player to spend slots on.
local _tRaceLanguages = {
	["human"]    = { "Common" },
	["dwarf"]    = { "Common", "Dwarvish" },
	["elf"]      = { "Common", "Elvish" },
	["gnome"]    = { "Common", "Gnomish" },
	["half-elf"] = { "Common", "Elvish" },
	["halfling"] = { "Common", "Halfling" },
	["half-orc"] = { "Common", "Orcish" },
};

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function getRaceLanguages(sRace)
	local tSrc = _tRaceLanguages[raceKey(sRace)] or { "Common" };
	local tOut = {};
	for _, s in ipairs(tSrc) do
		tOut[#tOut + 1] = s;
	end
	return tOut;
end

-- Master list of languages the player can pick as "extra" (INT-bonus) languages.
local _tLanguageList = {
	"Common", "Dwarvish", "Elvish", "Gnomish", "Halfling", "Orcish",
	"Goblin", "Hobgoblin", "Kobold", "Gnoll", "Bugbear", "Ogre", "Giant",
	"Troll", "Dragon", "Sylvan", "Centaur", "Lizard Man", "Sprite",
	"Treant", "Minotaur", "Druidic", "Thieves' Cant",
};

function getLanguageList()
	local tOut = {};
	for _, s in ipairs(_tLanguageList) do
		tOut[#tOut + 1] = s;
	end
	return tOut;
end

-- Condensed PHB race write-ups (appearance + temperament + key mechanics) shown
-- on the Race tab once a race is confirmed.
-- Each entry splits into { top, below } for the magazine-wrap layout:
--   top   -- flavor (appearance/temperament), sized to fill beside the portrait;
--   below -- mechanics/classes/languages, runs full width under the portrait.
local _tRaceDesc = {
	["human"] = {
		top =
			"A human? Why, most likely that is just what you are yourself, little one -- and what I am " ..
			"too. Humans come in every shape and shade you can dream of: tall and short, pale and " ..
			"dark, from every land under the sun, for they have no single look the way the dwarves or " ..
			"elves do.\r\r" ..
			"What marks a human is not the face but the fire inside. They are a restless folk, always " ..
			"building, always wandering, always reaching for the one thing just past their " ..
			"fingertips. They do not live as long as the elves, nor dig as deep as the dwarves, nor " ..
			"tread as softly as the halflings -- but oh, how brightly and how quickly their hearts " ..
			"burn.",
		below =
			"Where do they come from? From everywhere, child -- the farms and the cities, the cold " ..
			"mountains and the warm shores, the great kingdoms and the wild edges of the map. " ..
			"Wherever there is a place to settle, you will find that humans have already arrived, " ..
			"raising walls and naming the rivers.\r\r" ..
			"In one short life a human may raise a kingdom, break an old curse, or change the whole " ..
			"wide world, and that hungry, hurrying spirit is their greatest gift. It is why, of all " ..
			"the peoples, humankind has wandered the farthest and built the most.\r\r" ..
			"Traits: humans have no special powers and no ability bonuses or penalties -- their " ..
			"strength is sheer versatility. A human may take ANY class and rise to ANY level, free of " ..
			"the limits the other races live by, and may dual-class as they grow. They begin speaking " ..
			"the Common tongue.",
	},
	["elf"] = {
		top =
			"An elf, now -- there is a sight to remember. Slender and fair they are, a little shorter " ..
			"than a grown man yet light on their feet, with faces finely made as though carved by a " ..
			"careful hand, and ears that rise to a graceful point. Bright as moonlight on still " ..
			"water, the old songs say, with voices like soft music.\r\r" ..
			"Those keen ears miss nothing; an elf can catch a secret whispered in the rustle of the " ..
			"leaves. They may seem distant, child, as if listening to stars that you and I cannot " ..
			"hear -- but do not take that for coldness. An elf simply loves different things: beauty, " ..
			"and song, and the long slow turning of the years.",
		below =
			"Where do they dwell? In deep old forests and in shining halls beneath the boughs, in " ..
			"places far older than any city of men, where magic drifts between the trees like morning " ..
			"mist. An elf may live more than a thousand years, so a sorrow or a friendship born today " ..
			"may still be warm in their heart long after you and I are gone.\r\r" ..
			"They are slow to take up a new friend, slower still to forget one, and slower yet to " ..
			"forgive a wrong. Both swordplay and spellcraft fascinate them endlessly, and many an elf " ..
			"is a master of each.\r\r" ..
			"Traits: an elf may be a cleric, fighter, mage, thief, or ranger, and may blend several as " ..
			"a multi-class. They resist sleep and charm magic almost wholly (90%), see in the dark by " ..
			"infravision to 60 feet, and notice hidden and secret doors merely by passing near. They " ..
			"strike truer with bow (not crossbow) and with short and long sword (+1), and out of metal " ..
			"armor move so quietly that foes are caught by surprise. Initial languages: common, elf, " ..
			"gnome, halfling, goblin, hobgoblin, orc, and gnoll. They begin with +1 Dexterity and -1 " ..
			"Constitution.",
	},
	["dwarf"] = {
		top =
			"Ah, a dwarf! Picture a fellow no taller than your big brother, yet broad as an old oak " ..
			"stump and near as heavy -- all shoulders and muscle, built low and solid as a doorpost. " ..
			"His skin is ruddy like sun-warmed clay, his eyes dark and deep beneath heavy brows, and " ..
			"every grown dwarf wears a great bushy beard, combed and oiled and proud. Never you laugh " ..
			"at that beard, child, for a dwarf holds it dearer than gold.\r\r" ..
			"They dress plain and sturdy in good leather and honest iron, with little care for frills " ..
			"-- though a dwarf will happily tuck away a bright gem just to know that it is his. And " ..
			"they live a long, long while: three hundred years and more, so the dwarf you meet today " ..
			"may well have bounced your great-great-grandmother on his knee.",
		below =
			"Where do they come from, you ask? From under the mountains, little one -- down in the " ..
			"deep places where the world is all stone and lantern-light. There the dwarves hew great " ..
			"halls out of the living rock, with pillars tall as trees, and they dig for iron and " ..
			"silver and gold, and ring their hammers on the anvil from the dark of morning to the " ..
			"dark of night. Whole kingdoms of them dwell below, old as the hills themselves, where a " ..
			"dwarf can name his father's father back farther than you could ever count.\r\r" ..
			"They are a serious folk, dwarves -- slow to laugh, slower still to trust a stranger, and " ..
			"they can grumble like far-off thunder when the mood is on them. They put little faith in " ..
			"magic, trusting good steel and honest stone instead, and they bear no love at all for " ..
			"the goblins and orcs they have fought since the world was young. But mark me well: earn " ..
			"a dwarf's friendship and you have earned it for life. A dwarf never forgets a kindness " ..
			"and never breaks a promise -- and a friend like that is a shield that will never break.\r\r" ..
			"Traits: a nonmagical nature grants Con-based bonuses to saves vs. wands, staves, rods, " ..
			"spells, and poison -- but a 20% chance to fumble any magic item not suited to their " ..
			"class. +1 to hit orcs, half-orcs, goblins, hobgoblins; ogres/trolls/giants/titans suffer " ..
			"-4 to hit them. 60-ft infravision; senses slopes, new construction, shifting walls, " ..
			"traps, and depth underground.\r\r" ..
			"Initial languages: common, dwarf, gnome, goblin, kobold, orc. Begins +1 Con, -1 Cha.",
	},
	["gnome"] = {
		top =
			"A gnome! Ha -- there is a clever little folk. Kin to the dwarves they are, but smaller " ..
			"and slighter, with skin of dark tan or brown, hair gone snowy white, and (do not tell " ..
			"them I said so) a fine large nose they are rather proud of. Bright-eyed and curious, " ..
			"forever grinning at some private joke.\r\r" ..
			"Their pockets are always full of odd little tools, shiny stones, and half-finished " ..
			"notions that may or may not go bang. They love growing things, well-cut gems, and a good " ..
			"trick played in fun. And never think a gnome harmless for being small, child -- behind " ..
			"that grin may sit a riddle, a spell, or a plan three steps ahead of you.",
		below =
			"Where do they live? In cozy burrows and hidden, rolling hills, in snug homes dug into the " ..
			"green, where laughter mixes with the tap-tap-tap of tinkering and the soft rasp of a " ..
			"jeweler's file. They keep a wary eye on the bigger folk but wish them no harm, and they " ..
			"are fond of their dwarven cousins, even if they find all that dwarvish gloom a little " ..
			"silly. Three hundred years and more they may live -- time enough to learn a great many " ..
			"clever things.\r\r" ..
			"Traits: a gnome may be a fighter, thief, cleric, or illusionist, and may join two of " ..
			"these as a multi-class (never three). Like dwarves they are stoutly magic-resistant, " ..
			"with Constitution-based bonuses to saves against wands, staves, rods, and spells, and a " ..
			"20% chance to fumble most magic items outside their class (their own weapons, armor, and " ..
			"illusionist and thief items excepted). They strike +1 against kobolds and goblins, while " ..
			"gnolls, bugbears, ogres, trolls, giants, and titans take -4 to hit them. Infravision to " ..
			"60 feet and a keen underground sense. Initial languages: common, dwarf, gnome, halfling, " ..
			"goblin, and kobold. They begin with +1 Intelligence and -1 Wisdom.",
	},
	["halfling"] = {
		top =
			"A halfling, bless them -- the smallest of all the good folk, and among the gentlest. " ..
			"Picture a little person no higher than your waist, round-faced and ruddy and often " ..
			"comfortably plump, with curly hair and bare feet so tough and hairy they have no need of " ..
			"boots at all.\r\r" ..
			"There is no folk alive that loves a warm hearth, a soft bed, a full pantry, and a long " ..
			"peaceful day more than a halfling does. They would far sooner hear a tale by the fire " ..
			"than go chasing one out in the cold. But comfort, child, is not the same thing as " ..
			"cowardice -- you remember that.",
		below =
			"Where do they come from? From snug little villages among round green hills and tidy " ..
			"gardens, where the bread is always baking and nobody is ever in much of a hurry. For all " ..
			"their love of ease, halflings are sturdy and hard-working, honest and steady when a " ..
			"neighbor is in need, and they get on with very nearly everyone -- more openly than elf " ..
			"or dwarf or gnome. They live a good long while, some hundred and fifty years.\r\r" ..
			"And when danger does come creeping to the door? Why, a halfling can go quieter than a " ..
			"mouse, stand braver than a knight, and prove twice as hard to catch. The smallest hand, " ..
			"remember, may yet carry the luckiest stone.\r\r" ..
			"Traits: a halfling may be a cleric, fighter, thief, or fighter/thief. Their hardy nature " ..
			"grants Constitution-based bonuses to saves against wands, staves, rods, spells, and " ..
			"poison. They are deadly with sling and thrown stone (+1 to hit), and out of metal armor " ..
			"they move so stealthily that foes are caught by surprise. By lineage some see in the " ..
			"dark to 30 or 60 feet and can sense slope and direction underground. Initial languages: " ..
			"common, halfling, dwarf, elf, gnome, goblin, and orc. They begin with -1 Strength and +1 " ..
			"Dexterity.",
	},
	["half-elf"] = {
		top =
			"A half-elf is a child of two worlds, little one -- born where humankind and elvenkind " ..
			"meet, with one foot on the dusty roads of men and the other beneath the silver boughs of " ..
			"the elven wood. In looks they favor their elven side: handsome and fine-featured, a touch " ..
			"taller than a full elf, with only the gentlest point to the ear.\r\r" ..
			"From their human blood comes the quick fire -- curiosity, ambition, the urge to be up " ..
			"and doing. From their elven blood comes the quiet wonder -- keen senses, a love of wild " ..
			"and growing things, and an eye for beauty. To carry both at once is a rare gift indeed.",
		below =
			"Where do they belong? In many places, and sometimes, sadly, fully in none. A half-elf is " ..
			"welcome at the human hearth and beneath the elven stars alike, yet now and again feels a " ..
			"stranger in both -- and so they learn young to listen well, to wander far, and to know a " ..
			"lonely heart when they meet one. They live some hundred and sixty years, longer than a " ..
			"human and far shorter than an elf.\r\r" ..
			"It is a wandering, watchful, open-hearted sort of life, and it makes half-elves fine " ..
			"companions and finer friends.\r\r" ..
			"Traits: of all the demihumans the half-elf has the widest choice of path -- cleric, " ..
			"druid, fighter, ranger, mage, specialist wizard, thief, or bard -- and may blend many of " ..
			"these as a multi-class; they make especially fine druids and rangers. They resist sleep " ..
			"and charm magic somewhat (30%), see in the dark by infravision to 60 feet, and share the " ..
			"elven knack for spotting hidden and secret doors. They have no tongue of their own, but " ..
			"may begin with common, elf, gnome, halfling, goblin, hobgoblin, orc, or gnoll. They " ..
			"receive no ability adjustments.",
	},
};

function getRaceDescription(sRace)
	local t = _tRaceDesc[raceKey(sRace)];
	if not t then return ""; end
	return t.top .. "\r\r" .. t.below;
end

-- Top block (beside the portrait) for the magazine-wrap layout.
function getRaceDescTop(sRace)
	local t = _tRaceDesc[raceKey(sRace)];
	return t and t.top or "";
end

-- Below block (full width, under the portrait).
function getRaceDescBelow(sRace)
	local t = _tRaceDesc[raceKey(sRace)];
	return t and t.below or "";
end

-- Portrait icon for a race (empty string if none registered).
function getRaceImage(sRace)
	local sKey = raceKey(sRace);
	if _tRaceDesc[sKey] then
		return "charwizard2e_race_" .. (sKey == "half-elf" and "halfelf" or sKey);
	end
	return "";
end

-- Native pixel size of each race portrait. The art is tall and varies in aspect
-- ratio race to race, so the page scales by these to fit the frame WITHOUT
-- distorting the image. If you replace a race_*.png, update its size here (or the
-- page falls back to a centered square, which would letterbox an off-aspect image).
local _tRaceImageSize = {
	["human"]    = { w = 940, h = 1540 },
	["elf"]      = { w = 941, h = 1672 },
	["dwarf"]    = { w = 941, h = 1277 },
	["gnome"]    = { w = 941, h = 1269 },
	["halfling"] = { w = 941, h = 1305 },
	["half-elf"] = { w = 941, h = 1672 },
};

function getRaceImageSize(sRace)
	local t = _tRaceImageSize[raceKey(sRace)];
	if t then
		return t.w, t.h;
	end
	return nil, nil;
end

-- Alignment write-ups (outlook + roleplaying guidance), shown on the Alignment tab
-- once an alignment is confirmed. Keyed by the full alignment name (matches aAlignments).
local _tAlignmentDesc = {
	["Lawful Good"] =
		"Lawful Good characters believe order and compassion go hand in hand -- that just laws, " ..
		"honest dealing, and personal honor are the surest shield the weak have against the strong. " ..
		"They keep their word, aid those in need, and oppose cruelty wherever it hides, but prefer to " ..
		"fight it through duty, law, and example rather than reckless violence.\r\r" ..
		"At their best they are the paladin, the honest magistrate, the knight who guards the village. " ..
		"At their worst they grow rigid, mistaking the letter of the law for its spirit. The natural " ..
		"home of paladins, and common among clerics and fighters.",
	["Neutral Good"] =
		"Neutral Good characters want to do as much good as they can, and care little whether that good " ..
		"comes wrapped in law or in freedom. Rules are welcome when they help people and worth bending " ..
		"when they do not.\r\r" ..
		"They give to the needy, defend the innocent, and judge an act by its kindness rather than its " ..
		"legality. Reliable allies and gentle souls, they hold goodness itself as their highest loyalty " ..
		"-- above any king, code, or cause.",
	["Chaotic Good"] =
		"Chaotic Good characters follow their own conscience and trust freedom over rules. They do what " ..
		"is right as they see it, and bristle at any authority that bullies, hoards, or oppresses.\r\r" ..
		"Generous, independent, and quick to help the downtrodden, they make loyal friends and " ..
		"troublesome subjects. They will break an unjust law without a second thought -- though a fair " ..
		"one they will usually honor, simply because it suits them to. The rebel with a kind heart.",
	["Lawful Neutral"] =
		"Lawful Neutral characters prize order, structure, and reliability above all -- not because order " ..
		"is kind, but because it works. They keep their oaths, honor their contracts, and follow the code " ..
		"they have chosen, be it a kingdom's law, a temple's discipline, or their own strict personal honor.\r\r" ..
		"Good and evil are secondary to consistency; the trains, as it were, must run on time. Judges, " ..
		"disciplined soldiers, and monks often walk this road.",
	["True Neutral"] =
		"True Neutral characters seek balance, or simply decline to take sides. Some hold it as a " ..
		"philosophy -- that good and evil, law and chaos must all endure for the world to stay whole -- " ..
		"and will even aid the weaker side to keep any one force from ruling unchecked.\r\r" ..
		"Others are simply practical folk, beasts, or commoners who act from instinct and self-interest " ..
		"rather than grand principle. Druids embrace this balance as a sacred duty: for them neutrality " ..
		"is not indifference but stewardship of the natural order.",
	["Chaotic Neutral"] =
		"Chaotic Neutral characters love freedom above everything and answer to no one -- not law, not " ..
		"tradition, and not the labels of good and evil. They follow whims and chase impulses, which can " ..
		"look generous one day and selfish the next.\r\r" ..
		"They are not cruel for its own sake, but they will not be bound, herded, or counted on. The " ..
		"wanderer, the gambler, the free spirit who keeps their own counsel and goes their own way.",
	["Lawful Evil"] =
		"Lawful Evil characters use order, hierarchy, and law as tools to get what they want. They keep " ..
		"their bargains -- to the letter, and not one inch beyond -- and expect others to do the same. " ..
		"Honor, rank, and tradition matter to them, but always in service of power rather than kindness.\r\r" ..
		"They make disciplined tyrants and dangerous, dependable villains: you can trust a Lawful Evil " ..
		"foe to honor a deal, and to exploit every loophole in it. The shared outlook of tyrants, " ..
		"ruthless officials, and devils.",
	["Neutral Evil"] =
		"Neutral Evil characters are out for themselves and let neither law nor chaos stand in the way. " ..
		"They follow rules when rules help and break them when they do not, ally when convenient and " ..
		"betray when profitable.\r\r" ..
		"Theirs is pure, practical selfishness, without the discipline of the lawful or the recklessness " ..
		"of the chaotic -- they do whatever they can get away with. The mercenary who sells out the " ..
		"party, the schemer who serves only their own advancement.",
	["Chaotic Evil"] =
		"Chaotic Evil characters are driven by greed, hatred, or the sheer love of destruction, and they " ..
		"despise anything that would restrain them: law, mercy, loyalty, or other people's lives. They " ..
		"take what they want by force or guile and trust no one.\r\r" ..
		"Violent and unpredictable, they are the most dangerous of villains precisely because they cannot " ..
		"be bargained with or relied upon. The alignment of marauders, mad cultists, and the cruelest " ..
		"monsters.",
};

function getAlignmentDescription(sAlignment)
	return _tAlignmentDesc[sAlignment or ""] or "";
end

-- Shown on the Alignment tab while the player is still choosing: a primer on
-- what alignment means and a one-line gloss of all nine, to fill the panel and
-- help newcomers decide before they pick.
local _sAlignmentOverview =
	"Your alignment is your character's moral compass -- a short description of how they treat " ..
	"other people and how they feel about rules and authority. It is a guide for roleplaying, " ..
	"not a cage; characters can struggle, grow, and surprise themselves.\r\r" ..
	"It is built from two axes:\r\r" ..
	"ORDER (Lawful - Neutral - Chaotic): how much you trust laws, oaths, tradition, and " ..
	"authority. The Lawful keep to a code; the Chaotic follow their own conscience; the Neutral " ..
	"sit between.\r\r" ..
	"MORALITY (Good - Neutral - Evil): how much you care for the welfare of others. The Good " ..
	"protect and help; the Evil exploit and harm; the Neutral mostly look after their own.\r\r" ..
	"The nine combinations:\r\r" ..
	"Lawful Good -- honorable protector; keeps its word and shields the weak.\r" ..
	"Neutral Good -- does the most good it can, with or around the law.\r" ..
	"Chaotic Good -- free-spirited do-gooder who answers to conscience, not rules.\r" ..
	"Lawful Neutral -- order and duty above all; reliable, neither kind nor cruel.\r" ..
	"True Neutral -- seeks balance, or simply acts from practical self-interest.\r" ..
	"Chaotic Neutral -- prizes personal freedom above everything; unpredictable.\r" ..
	"Lawful Evil -- ruthless, but honors its bargains and its hierarchy.\r" ..
	"Neutral Evil -- pure practical selfishness; loyal only to itself.\r" ..
	"Chaotic Evil -- violent and destructive; trusts no one, restrained by nothing.\r\r" ..
	"Pick the one that best fits the hero you imagine. Your class has already removed any " ..
	"alignments it forbids, so every choice in the list is legal for this character. Select one " ..
	"to read a fuller description.";

function getAlignmentOverview()
	return _sAlignmentOverview;
end

-- ==== Nonweapon proficiency filtering (PHB Table 37) ====
-- FG skill records carry no group tag, so we keep a name allow-list per group.
-- A class may pick from the General group plus its own group; everything else is
-- hidden so the picker only offers proficiencies that fit the class.
local function _normNWP(s)
	s = (s or ""):lower():gsub("[^%a%d]+", " ");
	s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ");
	return s;
end
local _tNWPGroups = {
	general = { "Agriculture","Animal Handling","Animal Training","Artistic Ability","Blacksmithing",
		"Brewing","Carpentry","Cobbling","Cooking","Dancing","Direction Sense","Etiquette",
		"Fire-building","Fishing","Gaming","Heraldry","Languages, Modern","Languages, Ancient",
		"Leatherworking","Mining","Pottery","Riding, Land-based","Riding, Airborne","Rope Use",
		"Seamanship","Seamstress","Tailor","Singing","Stonemasonry","Swimming","Weather Sense","Weaving" },
	warrior = { "Animal Handling","Armorer","Blind-fighting","Bowyer","Fletcher","Charioteering",
		"Endurance","Gaming","Hunting","Mountaineering","Running","Set Snares","Survival","Tracking",
		"Weaponsmithing" },
	priest = { "Agriculture","Ancient History","Astrology","Brewing","Ceremony","Engineering",
		"Healing","Herbalism","Languages, Ancient","Local History","Musical Instrument","Navigation",
		"Reading/Writing","Religion","Spellcraft" },
	wizard = { "Ancient History","Astrology","Engineering","Herbalism","Languages, Ancient",
		"Navigation","Reading/Writing","Religion","Spellcraft" },
	rogue = { "Appraising","Blind-fighting","Disguise","Forgery","Gaming","Gem Cutting","Jumping",
		"Juggling","Local History","Musical Instrument","Reading/Writing","Set Snares",
		"Tightrope Walking","Tumbling","Ventriloquism" },
};
-- Built lazily on first use: FG does not bind pairs/ipairs during a global
-- package's top-level initialization, so this normalization must run at call
-- time (inside a function), never at script load.
local _tNWPNorm = nil;
local function _nwpNorms()
	if not _tNWPNorm then
		_tNWPNorm = {};
		for sGrp, tList in pairs(_tNWPGroups) do
			local t = {};
			for _, sN in ipairs(tList) do t[_normNWP(sN)] = true; end
			_tNWPNorm[sGrp] = t;
		end
	end
	return _tNWPNorm;
end
local function _nwpGroupKey(sGroup)
	if sGroup == "druid" then return "priest"; end
	if sGroup == "bard" then return "rogue"; end
	return sGroup;
end
local function _nwpHit(tSet, sNorm)
	if tSet[sNorm] then return true; end
	for sA in pairs(tSet) do
		if sNorm:find(sA, 1, true) == 1 or sA:find(sNorm, 1, true) == 1 then
			return true;
		end
	end
	return false;
end
-- True if a nonweapon proficiency belongs to the General group or the class's
-- own group (warrior/priest/wizard/rogue; druid->priest, bard->rogue).
function isNWPAllowed(sName, sGroup)
	local sNorm = _normNWP(sName);
	if sNorm == "" then return false; end
	local N = _nwpNorms();
	if _nwpHit(N.general, sNorm) then return true; end
	local tg = N[_nwpGroupKey(sGroup) or ""];
	if tg and _nwpHit(tg, sNorm) then return true; end
	return false;
end

-- ---------------------------------------------------------------------------
-- Recommended weapon proficiencies (Profs tab).
-- Instead of listing every weapon in every loaded module, the picker shows a
-- short, sensible shortlist built by COMPOSING two small tables:
--   * _tClassWeapons  -- ordered recommended weapons per class group (also the
--                        legal set for the restricted groups: wizard/priest/druid/rogue);
--   * _tRaceFavored   -- a few signature weapons per race, bumped to the top / starred.
-- getRecommendedWeapons(class, race) returns an ordered list of { name, favored }.
-- ---------------------------------------------------------------------------

-- Weapon group for recommendation purposes (mirrors the manager's prof groups).
local function weaponGroupForClass(sClass)
	local s = (sClass or ""):lower();
	if s:find("fighter", 1, true) or s:find("ranger", 1, true)
			or s:find("paladin", 1, true) or s:find("barbarian", 1, true) then
		return "warrior";
	end
	if s:find("bard", 1, true) then return "bard"; end
	if s:find("thief", 1, true) or s:find("rogue", 1, true) then return "rogue"; end
	if s:find("druid", 1, true) then return "druid"; end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) then return "priest"; end
	return "wizard"; -- mage + specialist wizards
end

-- Groups that may use ANY weapon (so race-favored picks not in the base list are
-- still added). The others are weapon-restricted, so favored picks only re-order
-- weapons already legal for the class.
local _tWeaponAnyGroup = { warrior = true, bard = true };

local _tClassWeapons = {
	warrior = {
		"Long Sword", "Battle Axe", "War Hammer", "Two-Handed Sword", "Spear",
		"Halberd", "Mace", "Flail", "Short Sword", "Long Bow", "Short Bow",
		"Light Crossbow", "Dagger",
	},
	bard = {
		"Long Sword", "Short Sword", "Rapier", "Dagger", "Sling", "Short Bow",
		"Light Crossbow", "Quarterstaff",
	},
	rogue = {
		"Short Sword", "Long Sword", "Rapier", "Broad Sword", "Dagger", "Club",
		"Sling", "Dart", "Light Crossbow", "Quarterstaff",
	},
	priest = {
		"Mace", "War Hammer", "Club", "Flail", "Morning Star", "Quarterstaff",
		"Sling", "Staff Sling",
	},
	druid = {
		"Scimitar", "Spear", "Club", "Dagger", "Dart", "Sling", "Quarterstaff", "Sickle",
	},
	wizard = {
		"Dagger", "Dart", "Quarterstaff", "Sling", "Knife",
	},
};

local _tRaceFavored = {
	["dwarf"]    = { "Battle Axe", "War Hammer", "Light Crossbow", "Hand Axe", "Military Pick" },
	["elf"]      = { "Long Sword", "Short Sword", "Long Bow", "Short Bow" },
	["gnome"]    = { "Light Crossbow", "War Hammer", "Short Sword", "Dagger" },
	["halfling"] = { "Sling", "Short Sword", "Dagger", "Light Crossbow" },
	["half-elf"] = { "Long Sword", "Long Bow", "Short Sword" },
	["half-orc"] = { "Battle Axe", "Two-Handed Sword", "Spear" },
	["human"]    = {},
};

function getRecommendedWeapons(sClass, sRace)
	local sGroup = weaponGroupForClass(sClass);
	local tBase = _tClassWeapons[sGroup] or {};
	local tFav = _tRaceFavored[raceKey(sRace)] or {};
	local bAny = _tWeaponAnyGroup[sGroup] == true;

	local tBaseSet = {};
	for _, w in ipairs(tBase) do tBaseSet[w] = true; end
	local tFavSet = {};
	for _, w in ipairs(tFav) do tFavSet[w] = true; end

	local tOut = {};
	local tSeen = {};
	-- Favored picks first (for restricted classes, only those already legal).
	for _, w in ipairs(tFav) do
		if not tSeen[w] and (bAny or tBaseSet[w]) then
			tOut[#tOut + 1] = { name = w, favored = true };
			tSeen[w] = true;
		end
	end
	-- Then the rest of the class list, starring any that are race-favored.
	for _, w in ipairs(tBase) do
		if not tSeen[w] then
			tOut[#tOut + 1] = { name = w, favored = tFavSet[w] == true };
			tSeen[w] = true;
		end
	end
	return tOut;
end

-- ---------------------------------------------------------------------------
-- Starter gear (Equipment tab): a small handful of class-appropriate items to
-- buy with rolled gold -- an adventuring pack, a couple of recommended weapons,
-- basic armor, and the class's essential item. Each entry is a list of name
-- variants (item modules name things differently); the manager resolves the
-- first that exists in the loaded item libraries. NOT a full shop -- the player
-- uses FG's own Items list for anything more.
-- ---------------------------------------------------------------------------

-- Basic armor options. Prefer the Drowned Archive "(Poor)" versions; fall back to
-- standard items if the book isn't loaded.
local function starterArmorNames(sGroup)
	if sGroup == "wizard" then
		return {}; -- arcane casters skip armor at creation
	end
	local t = {
		{ "Leather Armor (Poor)", "Leather Armor", "Leather" },
		{ "Studded Leather Armor (Poor)", "Studded Leather Armor", "Studded Leather" },
		{ "Wooden Shield (Poor)", "Shield, Medium", "Medium Shield", "Shield" },
	};
	if sGroup == "warrior" then
		table.insert(t, { "Chain Mail (Poor)", "Chain Mail", "Chainmail" });
	end
	return t;
end

-- The class's "kit" -- the cheap thing it needs to function. Keyed by the SPECIFIC
-- class (fighter/ranger/paladin each get their own, since the book has all three).
-- Drowned Archive "(Poor)" name first, then generic fallbacks.
local function classKitNames(sClass)
	local s = (sClass or ""):lower();
	if s:find("paladin", 1, true) then
		return { "Paladin's Vigil Kit (Poor)", "Paladin's Vigil Kit" };
	end
	if s:find("ranger", 1, true) then
		return { "Ranger's Fieldcraft Kit (Poor)", "Ranger's Fieldcraft Kit" };
	end
	if s:find("fighter", 1, true) or s:find("barbarian", 1, true) then
		return { "Fighter's Maintenance Roll (Poor)", "Fighter's Maintenance Roll" };
	end
	if s:find("bard", 1, true) then
		return { "Bard's Traveling Lute (Poor)", "Lute", "Mandolin", "Musical Instrument", "Instrument" };
	end
	if s:find("thief", 1, true) or s:find("rogue", 1, true) then
		return { "Thief's Tools (Poor)", "Thieves' Tools", "Thieves' Picks", "Lock Picks", "Lockpicks" };
	end
	if s:find("druid", 1, true) then
		return { "Druid's Gathering Satchel (Poor)", "Mistletoe", "Holy Symbol" };
	end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) then
		return { "Cleric's Holy Symbol (Poor)", "Holy Symbol", "Holy Symbol, Silver", "Symbol, Holy" };
	end
	if s:find("mage", 1, true) or s:find("wizard", 1, true) or s:find("illusion", 1, true)
			or s:find("conjur", 1, true) or s:find("divin", 1, true) or s:find("enchant", 1, true)
			or s:find("invok", 1, true) or s:find("necrom", 1, true) or s:find("transmut", 1, true)
			or s:find("abjur", 1, true) then
		return { "Spellbook (Poor)", "Spellbook", "Spell Book", "Book, Spell" };
	end
	return nil;
end

local function backpackNames()
	return { "Adventure Pack (Poor)", "Adventure Pack (Secondhand)", "Adventure Pack", "Adventurer's Pack", "Adventurers Pack", "Backpack" };
end

-- FREE items (granted at no gold cost): the class kit + an adventuring pack.
function getFreeGearNames(sClass)
	local tOut = {};
	local tKit = classKitNames(sClass);
	if tKit then
		tOut[#tOut + 1] = tKit;
	end
	tOut[#tOut + 1] = backpackNames();
	return tOut;
end

-- BUY items (cost deducted from rolled gold): recommended weapons + basic armor,
-- plus matching ammo when a bow or sling is among the weapons. "(Poor)" preferred.
function getBuyGearNames(sClass, sRace)
	local sGroup = weaponGroupForClass(sClass);
	local tOut = {};
	local bHasBow, bHasSling = false, false;
	local tW = getRecommendedWeapons(sClass, sRace);
	for i = 1, math.min(4, #tW) do
		local sName = tW[i].name;
		tOut[#tOut + 1] = { sName .. " (Poor)", sName };
		local sl = sName:lower();
		if sl:find("bow", 1, true) then bHasBow = true; end
		if sl:find("sling", 1, true) then bHasSling = true; end
	end
	if bHasBow then
		tOut[#tOut + 1] = { "Arrows, bundle of 10 (Poor)", "Arrows", "Flight Arrows", "Arrow" };
	end
	if bHasSling then
		tOut[#tOut + 1] = { "Sling stones, pouch of 10 (Poor)", "Sling stones", "Sling Bullets", "Bullets" };
	end
	for _, tArmor in ipairs(starterArmorNames(sGroup)) do
		tOut[#tOut + 1] = tArmor;
	end
	return tOut;
end

-- Family heirlooms (The Drowned Archive d20 table). A purely random keepsake from
-- home -- NOT filtered by class/race; it may even be useless to the class, which is
-- the point. Index == the d20 result so an actual die roll picks the entry.
-- The 20 packaged heirloom items in The Drowned Archive, in d20 order (matching
-- that module's "Family heirlooms" table: roll 1 -> item.id-00024 ... roll 20 ->
-- item.id-00043). On commit we grant the real item record by name, so the player
-- receives the actual heirloom -- with its own art, stats, and description.
local _tHeirloomItems = {
	"Grandfather's Initialed Dagger",
	"Distant Cousin's Silver Holy Symbol",
	"Unanswered Signet and Sealed Letter",
	"Cloak of the Foreign Coin",
	"Northfinding Walking Stick",
	"Grandmother Eda's Restorative Recipes",
	"Moonlit Mirror of Frank Advice",
	"Uncle Ren's Belt Knife and Whetstone",
	"Key to an Unremembered Door",
	"Traveler's Bedroll with Map Fragment",
	"Copper Coin of Second Thoughts",
	"Great-Aunt Maribel's Restorative Brandy",
	"Grandmother's Warm Brooch",
	"Iron Ring of the Taper",
	"Smiling-Stone Sling",
	"Scabbard of the Patient Edge",
	"Owl Whistle of Borrowed Calls",
	"Deck of the Missing Queen",
	"Cedar-Scented Crest Blanket",
	"Locket of the Watchful Portrait",
};

-- Heirloom item name for a given d20 roll (1-20); clamps out-of-range rolls.
function getHeirloomByRoll(nRoll)
	local n = math.max(1, math.min(20, tonumber(nRoll) or 1));
	return _tHeirloomItems[n] or "";
end

-- Normalize a class record name to a class key. Specialist wizards keep their own
-- key (each has its own portrait); checked before the generic mage/wizard fallback.
local function classKey(sClass)
	local s = (sClass or ""):lower();
	for _, k in ipairs({ "abjurer", "conjurer", "diviner", "enchanter",
			"illusionist", "invoker", "necromancer", "transmuter" }) do
		if s:find(k, 1, true) then return k; end
	end
	if s:find("paladin", 1, true) then return "paladin"; end
	if s:find("ranger", 1, true) then return "ranger"; end
	if s:find("fighter", 1, true) then return "fighter"; end
	if s:find("druid", 1, true) then return "druid"; end
	if s:find("cleric", 1, true) or s:find("priest", 1, true) then return "cleric"; end
	if s:find("bard", 1, true) then return "bard"; end
	if s:find("thief", 1, true) or s:find("rogue", 1, true) then return "thief"; end
	if s:find("mage", 1, true) or s:find("wizard", 1, true) then return "mage"; end
	return s;
end

-- Class write-ups (narrator voice), shown on the Class tab once a class is confirmed.
-- top = lead paragraph (beside the portrait); below = second paragraph (full width, scrollable).
local _tClassDesc = {
	["abjurer"] = {
		top =
			"The Abjurer is the wizard who stands between doom and the door. Where other mages fling " ..
			"fire or bend minds, the Abjurer studies the art of warding, banishing, sealing, and " ..
			"protection. They are the chalk circle on the stone floor, the whispered counterspell " ..
			"before the demon crosses the threshold, the raised hand that turns aside claws, curses, " ..
			"and hostile magic alike. Their craft is not flashy in the tavern-tale sense, but every " ..
			"adventuring company learns to love the one who can say, \"No farther.\"",
		below =
			"In the field, an Abjurer is a guardian-scholar: cautious, exacting, and often a little " ..
			"severe, for they know how thin the walls are between the world and what waits beyond it. " ..
			"They unravel enchantments, shield companions from harm, and drive away creatures that " ..
			"should never have been summoned in the first place. To an Abjurer, magic is not merely " ..
			"power; it is a lock, a wall, a warning sigil burning blue in the dark.",
	},
	["bard"] = {
		top =
			"The Bard is the wanderer with a song on their lips, a blade at their hip, and a story for " ..
			"every locked door, suspicious guard, and haunted ruin. They are neither purely warrior, " ..
			"thief, nor wizard, but a bright thread woven through all three: clever enough to survive " ..
			"by wit, bold enough to stand in the fray, and learned enough to know that old songs often " ..
			"remember what kings and sages forget.",
		below =
			"In an adventuring company, the Bard is the spark that keeps the fire from dying. They " ..
			"lift weary hearts, twist words into weapons, pick through ancient lore, charm a hostile " ..
			"room, and turn a desperate battle with courage, mockery, music, or magic. A Bard does " ..
			"not merely witness legends; they collect them, polish them, and sometimes, with a grin " ..
			"and a flourish, become the reason the next one is sung.",
	},
	["cleric"] = {
		top =
			"The Cleric is the armored hand of faith, a mortal vessel carrying the will of powers far " ..
			"greater than themselves. They stride into darkness with holy symbol raised, not as a " ..
			"scholar chasing secrets or a knight chasing glory, but as one who has been entrusted with " ..
			"purpose. Through prayer, discipline, and devotion, they call down blessings, mend broken " ..
			"flesh, shield the innocent, and bring righteous wrath upon the profane.",
		below =
			"In an adventuring company, the Cleric is often the steady heart. They stand where fear is " ..
			"thickest, turning undead horrors back into the grave, restoring companions when battle " ..
			"has left them bloodied, and reminding all present that courage can be sacred. Whether " ..
			"gentle healer, stern crusader, village priest, or battle-tempered champion, the Cleric " ..
			"carries their temple with them: in their words, their weapon, and the light that answers " ..
			"when they call.",
	},
	["conjurer"] = {
		top =
			"The Conjurer is the mage who knows that the world is not alone. Beyond the veil lie other " ..
			"places, other powers, other hungers -- and the Conjurer has learned the names, signs, " ..
			"and bargains needed to draw them near. Where some wizards shape what is already present, " ..
			"the Conjurer reaches outward, calling forth servants, creatures, tools, and forces from " ..
			"elsewhere, turning empty air into sudden threat or salvation.",
		below =
			"In the company of adventurers, a Conjurer is the one who makes the impossible appear at " ..
			"exactly the wrong moment for their enemies. A beast where there was none, a cloud of " ..
			"choking mist, a summoned ally clawing its way into the fight, a thing best not examined " ..
			"too closely standing between the party and death. They are bold, curious, and often " ..
			"dangerously confident, for every summoning is a door -- and every door, once opened, " ..
			"reminds the wise to wonder what might be looking back.",
	},
	["diviner"] = {
		top =
			"The Diviner is the wizard who listens to the hidden machinery of fate. While others bend " ..
			"flame, flesh, or fear, the Diviner studies signs: a pattern in scattered bones, a tremor " ..
			"in a silver bowl, a name half-heard in dreams, a future glimpsed in the turning of a " ..
			"card. To them, magic is not always a hammer or shield; sometimes it is a lantern held up " ..
			"to secrets the world hoped to keep buried.",
		below =
			"In an adventuring company, the Diviner is the whisper before the ambush, the answer " ..
			"pulled from silence, the uneasy warning that the road ahead is not what it seems. They " ..
			"find lost things, pierce disguises, read omens, and ask questions no locked chest or " ..
			"lying noble can easily withstand. A Diviner may not always tell their companions " ..
			"everything they have seen -- for prophecy is a tricky knife -- but when they grow quiet " ..
			"and stare past the firelight, wise friends learn to listen.",
	},
	["druid"] = {
		top =
			"The Druid is the old voice of the green world, the keeper of root, fang, storm, and " ..
			"standing stone. They do not command nature like a lord commands servants; they bargain " ..
			"with it, honor it, and sometimes unleash it. Where civilization draws borders, builds " ..
			"roads, and names itself master, the Druid remembers that forests were ancient before " ..
			"kings had crowns, and that the earth has laws older than any written code.",
		below =
			"In an adventuring company, the Druid is guide, healer, omen-reader, and wrath of the " ..
			"wild made flesh. They call upon beasts, bend weather, mend wounds with herbs and prayer, " ..
			"and bring thorns, flame, and thunder against those who defile the balance. A Druid may " ..
			"seem quiet beside the campfire, but there is always something listening with them: owl " ..
			"eyes in the branches, wolves beyond the trees, and the deep patience of the land itself.",
	},
	["enchanter"] = {
		top =
			"The Enchanter is the wizard who knows that the strongest chains are not made of iron, but " ..
			"of desire, fear, trust, and suggestion. They study the secret doors of the mind, " ..
			"learning how a glance, a word, or a carefully woven spell can turn hatred into " ..
			"hesitation, loyalty into doubt, or an enemy's blade aside before it ever falls. Where " ..
			"other mages break walls, the Enchanter convinces someone to open the gate.",
		below =
			"In an adventuring company, the Enchanter is silver tongue and subtle hand, the one who " ..
			"can quiet a mob, charm a guard, cloud a tyrant's judgment, or turn a monster's fury into " ..
			"momentary calm. Yet their art is a dangerous one, for magic that touches the will leaves " ..
			"questions behind it. A wise Enchanter learns restraint; a foolish one learns too late " ..
			"that minds, once bent, may remember the shape of the hand that bent them.",
	},
	["fighter"] = {
		top =
			"The Fighter is the steel backbone of the adventuring company, the one who has learned " ..
			"that survival is built from discipline, scars, and the hard arithmetic of blade, shield, " ..
			"and battlefield. They may be a knight in polished mail, a grim mercenary, a village " ..
			"champion, or a veteran soldier with nothing left but their sword-arm and a reason to " ..
			"keep going. Whatever their origin, they are defined by mastery of arms and the courage " ..
			"to stand where danger is thickest.",
		below =
			"In the field, the Fighter is the wall enemies break against and the spearpoint that " ..
			"drives the party forward. They know weapons the way bards know songs: the reach of a " ..
			"polearm, the weight of an axe, the timing of a shield-bash, the moment when a battle " ..
			"turns. Wizards may reshape reality and priests may call on gods, but when the ogre comes " ..
			"crashing through the door, it is often the Fighter who steps forward first.",
	},
	["illusionist"] = {
		top =
			"The Illusionist is the wizard who proves that the eye is a gullible little thing. They " ..
			"weave light, sound, shadow, and expectation into lies so convincing that the world seems " ..
			"to agree with them. A bridge where there is none, a dragon's roar in an empty hall, a " ..
			"vanished doorway, a double walking calmly into danger -- these are the tools of a mage " ..
			"who knows that belief can be as sharp as any blade.",
		below =
			"In an adventuring company, the Illusionist is misdirection made magnificent. They hide " ..
			"allies, frighten foes, lure guards from their posts, and turn confusion into " ..
			"opportunity. Their magic rarely wins by brute force; it wins by making the enemy swing " ..
			"at ghosts, flee from phantoms, or trust the wrong thing at the perfect moment. Around an " ..
			"Illusionist, reality may still be real -- but it has terrible manners.",
	},
	["invoker"] = {
		top =
			"The Invoker is the wizard who speaks in thunder and answers insult with fire. They study " ..
			"magic at its most forceful and unmistakable: bolts of lightning, walls of flame, blasts " ..
			"of raw power, and words that make the air itself recoil. Where subtler mages whisper at " ..
			"reality's edges, the Invoker kicks the door off its hinges and dares the darkness to " ..
			"complain.",
		below =
			"In an adventuring company, the Invoker is the storm held in human shape. They are the " ..
			"one allies glance toward when numbers turn ugly, when monsters mass in the corridor, " ..
			"when something vast and armored needs to be reminded that flesh burns. Yet a wise " ..
			"Invoker learns control, for power cast carelessly makes no distinction between enemy, " ..
			"friend, treasure, or ceiling. Their art is magnificent, terrifying, and usually very " ..
			"loud.",
	},
	["mage"] = {
		top =
			"The Mage is the true student of wizardry in its broadest form: not bound to one narrow " ..
			"road, but wandering the entire labyrinth of arcane knowledge. They are the candlelit " ..
			"scholar, the patient experimenter, the keeper of strange formulae and " ..
			"older-than-comfortable books. To a Mage, every spell is another key, and every key " ..
			"suggests a door that perhaps should -- or absolutely should not -- be opened.",
		below =
			"In an adventuring company, the Mage is possibility itself. One day they may shield the " ..
			"party, the next they may unravel a curse, conjure light in the deep earth, read a " ..
			"forgotten script, or turn a battlefield with a single carefully chosen spell. They lack " ..
			"the fierce focus of a specialist, but in exchange they carry breadth, adaptability, and " ..
			"that dangerous wizardly habit of having \"just the thing\" tucked away in a spellbook no " ..
			"sensible person would touch barehanded.",
	},
	["necromancer"] = {
		top =
			"The Necromancer is the wizard who studies the cold borderland between breath and " ..
			"silence. They are drawn to bones, spirits, fading life-force, and the grim laws that " ..
			"govern death's door. Some seek mastery over the dead out of cruelty, some out of " ..
			"obsession, and some because they know that every living thing casts a shadow -- and " ..
			"shadows, too, may be studied.",
		below =
			"In an adventuring company, the Necromancer is unsettling but useful, the one who can sap " ..
			"strength, speak of corpses without flinching, and recognize the hand of death where " ..
			"others see only fear. Their magic may weaken foes, command terrible servants, or reveal " ..
			"truths hidden in grave-dust and old blood. Few companions are entirely comfortable " ..
			"beside a Necromancer, but when the crypt seals shut and something begins scratching from " ..
			"the other side, comfort is often the first luxury to die.",
	},
	["paladin"] = {
		top =
			"The Paladin is the bright blade of righteousness, a warrior whose courage is sharpened by " ..
			"faith and whose honor is meant to shine even in the filthiest dungeon. They are more " ..
			"than a knight and more than a priestly champion; they are a sworn answer to evil, bound " ..
			"by duty, mercy, discipline, and the terrible weight of being expected to do what is " ..
			"right when doing so is costly.",
		below =
			"In an adventuring company, the Paladin stands as shield, sword, and conscience. They " ..
			"heal with a touch, sense corruption, drive back darkness, and meet monsters not merely " ..
			"with steel, but with conviction. This does not make them gentle, nor simple, nor easy to " ..
			"travel with -- goodness can be a demanding road. But when fear spreads through the ranks " ..
			"and the dead rise in the moonlight, the Paladin is the one who steps forward glowing " ..
			"like dawn remembered.",
	},
	["ranger"] = {
		top =
			"The Ranger is the watcher beyond the firelight, the hunter of lonely trails, ruined " ..
			"borders, and monster-haunted woods. They know the language of tracks, broken branches, " ..
			"distant birds, and silence where silence should not be. Civilization may call them wild, " ..
			"but the Ranger understands a truth city folk forget: the world beyond the walls is " ..
			"alive, and not all of it is friendly.",
		below =
			"In an adventuring company, the Ranger is guide, scout, archer, blade, and early warning. " ..
			"They find safe paths through cruel country, read enemies by the marks they leave behind, " ..
			"and strike with the patience of a predator. Whether stalking goblins through pine " ..
			"forests or leading companions across mountains under bad stars, the Ranger moves as one " ..
			"who belongs where others merely trespass.",
	},
	["thief"] = {
		top =
			"The Thief is the shadow with quick hands, quicker feet, and a professional disrespect for " ..
			"locked doors. They live by nerve, timing, and the useful belief that most obstacles were " ..
			"designed by someone less clever than themselves. A Thief may be a cutpurse, scout, " ..
			"tomb-robber, spy, or charming disaster in a hood, but all share the same talent: getting " ..
			"into places, out of trouble, and occasionally away with the silver.",
		below =
			"In an adventuring company, the Thief is the one sent ahead when the hallway looks too " ..
			"clean, the chest too inviting, or the noble too smug. They find traps, open locks, climb " ..
			"walls, vanish into alleys, and strike where armor is weakest. They may not boast the " ..
			"Fighter's endurance or the Wizard's cosmic arrogance, but give a Thief darkness, a " ..
			"dagger, and five seconds of distraction, and suddenly the whole shape of the problem " ..
			"changes.",
	},
	["transmuter"] = {
		top =
			"The Transmuter is the wizard who refuses to accept that anything must remain what it is. " ..
			"Stone may soften, flesh may harden, air may thicken, and the weak may become strong " ..
			"beneath their shifting art. To the Transmuter, reality is not a wall but clay: stubborn, " ..
			"yes, but wonderfully negotiable in the hands of someone with the proper words and a " ..
			"dangerous amount of curiosity.",
		below =
			"In an adventuring company, the Transmuter is the master of alteration and adaptation. " ..
			"They turn obstacles into tools, enemies into lesser problems, and companions into " ..
			"swifter, stronger, stranger versions of themselves. Their magic may reshape the " ..
			"battlefield, the body, or the very materials of the world. Around a Transmuter, nothing " ..
			"is quite final -- not the locked gate, not the iron chain, not even the person you were " ..
			"when the spell began.",
	},
};

function getClassDescription(sClass)
	local t = _tClassDesc[classKey(sClass)];
	if not t then return ""; end
	return t.top .. "\r\r" .. t.below;
end

function getClassDescTop(sClass)
	local t = _tClassDesc[classKey(sClass)];
	return t and t.top or "";
end

function getClassDescBelow(sClass)
	local t = _tClassDesc[classKey(sClass)];
	return t and t.below or "";
end

-- Portrait icon for a class (empty string if none registered).
function getClassImage(sClass)
	local sKey = classKey(sClass);
	if _tClassDesc[sKey] then
		return "charwizard2e_class_" .. sKey;
	end
	return "";
end

function rollGender()
	return pick(_tGenders);
end

function getSize(sRace)
	return _tSize[raceKey(sRace)] or "M";
end

function rollAge(sRace)
	local t = _tAge[raceKey(sRace)] or _tAge["human"];
	return tostring(roll(t.start[1], t.start[2], t.start[3]));
end

function rollMaxAge(sRace)
	local t = _tAge[raceKey(sRace)] or _tAge["human"];
	return tostring(roll(t.max[1], t.max[2], t.max[3]));
end

local function fmtHeight(nInches)
	local nFeet = math.floor(nInches / 12);
	local nIn = nInches - (nFeet * 12);
	return string.format("%d'%d\"", nFeet, nIn);
end

function rollHeight(sRace, sGender)
	local tR = _tBody[raceKey(sRace)] or _tBody["human"];
	local tG = tR[genderKey(sGender)] or tR["male"];
	return fmtHeight(roll(tG.h[1], tG.h[2], tG.h[3]));
end

function rollWeight(sRace, sGender)
	local tR = _tBody[raceKey(sRace)] or _tBody["human"];
	local tG = tR[genderKey(sGender)] or tR["male"];
	return tostring(roll(tG.w[1], tG.w[2], tG.w[3])) .. " lbs";
end

function rollDeity()
	return pick(_tDeities);
end

function rollTrait()
	return pick(_tTraits);
end

function rollIdeal()
	return pick(_tIdeals);
end

function rollBond()
	return pick(_tBonds);
end

function rollFlaw()
	return pick(_tFlaws);
end

function rollAppearance()
	return pick(_tAppearance);
end
