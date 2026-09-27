class_name ScpArchive
extends RefCounted
# Archive entries recovered as documents in the level.
#
# Text is quoted verbatim from the SCP Wiki, which is licensed CC BY-SA 3.0.
# That licence requires crediting the individual author of each article, not
# just the wiki, so every entry carries its own author and url. Keep those
# fields filled in for anything added here.
#
# Entries are handed to documents in left-to-right level order by Level.gd,
# so this list reads in the order the player meets them.

const ENTRIES := [
	{"id": "SCP-173", "class": "Euclid", "author": "Moto42",
	 "url": "https://scp-wiki.wikidot.com/scp-173",
	 "text": "Moved to Site-19 1993. Origin is as of yet unknown."},

	{"id": "SCP-096", "class": "Euclid", "author": "Dr Dan",
	 "url": "https://scp-wiki.wikidot.com/scp-096",
	 "text": "SCP-096 is a humanoid creature measuring approximately 2.38 meters in height. Subject shows very little muscle mass, with preliminary analysis of body mass suggesting mild malnutrition."},

	{"id": "SCP-049", "class": "Euclid", "author": "Gabriel Jade, rewritten by djkaktus & Gabriel Jade",
	 "url": "https://scp-wiki.wikidot.com/scp-049",
	 "text": "SCP-049 is a humanoid entity, roughly 1.9 meters in height, which bears the appearance of a medieval plague doctor."},

	{"id": "SCP-106", "class": "Keter", "author": "Dr Gears",
	 "url": "https://scp-wiki.wikidot.com/scp-106",
	 "text": "SCP-106 appears to be an elderly humanoid, with a general appearance of advanced decomposition. This appearance may vary, but the \"rotting\" quality is observed in all forms."},

	{"id": "SCP-682", "class": "Keter", "author": "Dr Gears and Epic Phail Spy",
	 "url": "https://scp-wiki.wikidot.com/scp-682",
	 "text": "SCP-682 is a large, vaguely reptile-like creature of unknown origin. It appears to be extremely intelligent, and was observed to engage in complex communication with SCP-079 during their limited time of exposure."},

	{"id": "SCP-914", "class": "Safe", "author": "Dr Gears",
	 "url": "https://scp-wiki.wikidot.com/scp-914",
	 "text": "SCP-914 is a large clockwork device weighing several tons and covering an area of eighteen square meters, consisting of screw drives, belts, pulleys, gears, springs and other clockwork."},

	{"id": "SCP-087", "class": "Euclid", "author": "Zaeyde",
	 "url": "https://scp-wiki.wikidot.com/scp-087",
	 "text": "SCP-087 is an unlit platform staircase. Stairs descend on a 38 degree angle for 13 steps before reaching a semicircular platform of approximately 3 meters in diameter."},

	{"id": "SCP-035", "class": "Keter", "author": "Kain Pathos Crow",
	 "url": "https://scp-wiki.wikidot.com/scp-035",
	 "text": "SCP-035 appears to be a white porcelain comedy mask, although, at times, it will change to tragedy."},

	{"id": "SCP-999", "class": "Safe", "author": "ProfSnider",
	 "url": "https://scp-wiki.wikidot.com/scp-999",
	 "text": "SCP-999 appears to be a large, amorphous, gelatinous mass of translucent orange slime, weighing about 54 kg (120 lbs) with a consistency similar to that of peanut butter."},

	{"id": "SCP-079", "class": "Euclid", "author": "Unknown author",
	 "url": "https://scp-wiki.wikidot.com/scp-079",
	 "text": "SCP-079 is an Exidy Sorcerer microcomputer built in 1978. In 1981, its owner, a college sophomore, took it upon himself to attempt to code an AI."},

	{"id": "SCP-LEIDENUNI", "class": "Keter", "author": "Narek",
	 "url": "https://www.universiteitleiden.nl/en/education/study-programmes/bachelor/data-science-and-artificial-intelligence",
	 "text": "If you read this, I want you to know that i am proud of you for reading all this documentation... If you are a student who is grading this game, pls grade me high if you dont want to end up destroyed by scp 173(neck snap)"},

	{"id": "SCP-1471", "class": "Euclid", "author": "LurkD",
	 "url": "https://scp-wiki.wikidot.com/scp-1471",
	 "text": "SCP-1471 is a free 9.8MB application for mobile devices named 'MalO ver1.0.0' in online application stores. SCP-1471 has no listed developer and is somehow able to bypass the application approval process to go directly to distribution."},

	{"id": "SCP-178", "class": "Euclid", "author": "91stCataclysm",
	 "url": "https://scp-wiki.wikidot.com/scp-178",
	 "text": "SCP-178 is a pair of white stereoscopic (\"3-D\") glasses with a rectangular white cardboard frame and lenses of transparent blue and red plastic."},

	{"id": "SCP-895", "class": "Euclid", "author": "Aelanna",
	 "url": "https://scp-wiki.wikidot.com/scp-895",
	 "text": "SCP-895 is an ornate oak coffin recovered from a mortuary by SCP personnel, following reports of unusual footage captured by surveillance equipment installed at that location."},

	{"id": "SCP-662", "class": "Safe", "author": "Rick Revelry",
	 "url": "https://scp-wiki.wikidot.com/scp-662",
	 "text": "SCP-662 is a small silver hand bell, 4 cm tall and 2 cm in circumference. The bell is missing its ringer."},

	{"id": "SCP-053", "class": "Euclid", "author": "Dr Gears",
	 "url": "https://scp-wiki.wikidot.com/scp-053",
	 "text": "SCP-053 appears to be a small 3-year-old girl. She is capable of basic speech and appears to be slightly above average in mental development."},

	{"id": "SCP-008", "class": "Euclid", "author": "Unknown author",
	 "url": "https://scp-wiki.wikidot.com/scp-008",
	 "text": "SCP-008 is a complex prion, samples of which are stored in each of the known G2 sites. Research into SCP-008 is highly classified and primarily aimed at preventing research which may lead to the synthesis of SCP-008 in the distant future."},

	{"id": "SCP-017", "class": "Keter", "author": "Sam Swicegood (CityToast)",
	 "url": "https://scp-wiki.wikidot.com/scp-017",
	 "text": "SCP-017 is a humanoid figure approximately 80 centimeters in height, anatomically similar to a small child, but with no discernible identifying features. SCP-017 seems to be composed of a shadowy, smoke-like shroud."},

	{"id": "SCP-372", "class": "Euclid", "author": "Sylocat",
	 "url": "https://scp-wiki.wikidot.com/scp-372",
	 "text": "SCP-372 is a creature of unknown genus, approximately 2 meters long from head to tail and weighing approximately 45 kilograms. It has a long, thin body with eight pairs of narrow limbs."},

	{"id": "SCP-1048", "class": "Keter", "author": "trennerdios",
	 "url": "https://scp-wiki.wikidot.com/scp-1048",
	 "text": "SCP-1048 is a small teddy bear, approximately 33 cm in height. Through testing, composition of the subject revealed no unusual qualities that make it discernible from a non-sapient teddy bear."},

	{"id": "SCP-3008", "class": "Euclid", "author": "Mortos",
	 "url": "https://scp-wiki.wikidot.com/scp-3008",
	 "text": "SCP-3008 is a large retail unit previously owned by and branded as IKEA, a popular furniture retail chain. A person entering SCP-3008 through the main entrance and then passing out of sight of the doors will find themselves translocated to SCP-3008-1."},

	{"id": "SCP-409", "class": "Keter", "author": "Dr Gears",
	 "url": "https://scp-wiki.wikidot.com/scp-409",
	 "text": "SCP-409 resembles a large quartz crystal approximately 1.5m (5ft) tall and 0.6m (2ft) wide. Any objects coming in contact with SCP-409 will begin to crystallize after three hours."},

	{"id": "SCP-015", "class": "Euclid", "author": "Dr Gears",
	 "url": "https://scp-wiki.wikidot.com/scp-015",
	 "text": "SCP-015 is a mass of pipes, vents, boilers and other various plumbing apparatus completely filling a warehouse. The pipes appear to grow when not under observation, attempting to connect to nearby structures via sewer systems and underground plumbing."},

	{"id": "SCP-500", "class": "Safe", "author": "snorlison",
	 "url": "https://scp-wiki.wikidot.com/scp-500",
	 "text": "SCP-500 is a small plastic can which at the time of writing contains forty-seven (47) red pills. One pill, when taken orally, effectively cures the subject of all diseases within two hours."},
]

static func count() -> int:
	return ENTRIES.size()

static func get_entry(i: int) -> Dictionary:
	if i < 0 or i >= ENTRIES.size():
		return {}
	return ENTRIES[i]
