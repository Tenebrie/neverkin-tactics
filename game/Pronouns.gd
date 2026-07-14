@tool
class_name Pronouns

enum Preset {
	Neutral = 0,
	Feminine = 1,
	Masculine = 2,
	Impersonal = 3,
	HumanoidRandom = 4,
}

class Values:
	# is/is/are/is
	var verb: String
	# she/he/they/it
	var nominative: String
	# her/him/them/it
	var objectve: String
	# her/his/their/its
	var dependentPossessive: String
	# hers/his/theirs/its
	var independentPossessive: String

var lowercase: Values
var capitalized: Values

const _TOKEN_MAP = {
	"are": "verb",
	"they": "nominative",
	"them": "objectve",
	"their": "dependentPossessive",
	"theirs": "independentPossessive",
}

static var _regex: RegEx

func evaluate(text: String) -> String:
	if _regex == null:
		_regex = RegEx.new()
		_regex.compile("\\$(They|Them|Their|Theirs|Are|they|them|their|theirs|are)\\b")
	var result = ""
	var last = 0
	for m in _regex.search_all(text):
		result += text.substr(last, m.get_start() - last)
		var token: String = m.get_string(1)
		var field: String = _TOKEN_MAP[token.to_lower()]
		var values: Values = capitalized if token[0] == token[0].to_upper() else lowercase
		result += values.get(field)
		last = m.get_end()
	result += text.substr(last)
	return result

static func FromPreset(preset: Preset) -> Pronouns:
	if preset == Preset.HumanoidRandom:
		preset = randi_range(Preset.Neutral, Preset.Masculine) as Preset

	match (preset):
		Preset.Feminine: 	return Pronouns.Feminine()
		Preset.Masculine: 	return Pronouns.Masculine()
		Preset.Impersonal: 	return Pronouns.Impersonal()
		_: 					return Pronouns.Neutral()

static func Neutral() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase = Values.new()
	pronouns.capitalized = Values.new()
	pronouns.lowercase.verb = "are"
	pronouns.lowercase.nominative = "they"
	pronouns.lowercase.objectve = "them"
	pronouns.lowercase.dependentPossessive = "their"
	pronouns.lowercase.independentPossessive = "theirs"
	pronouns.capitalized.verb = "Are"
	pronouns.capitalized.nominative = "They"
	pronouns.capitalized.objectve = "Them"
	pronouns.capitalized.dependentPossessive = "Their"
	pronouns.capitalized.independentPossessive = "Theirs"
	return pronouns

static func Feminine() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase = Values.new()
	pronouns.capitalized = Values.new()
	pronouns.lowercase.verb = "is"
	pronouns.lowercase.nominative = "she"
	pronouns.lowercase.objectve = "her"
	pronouns.lowercase.dependentPossessive = "her"
	pronouns.lowercase.independentPossessive = "hers"
	pronouns.capitalized.verb = "Is"
	pronouns.capitalized.nominative = "She"
	pronouns.capitalized.objectve = "Her"
	pronouns.capitalized.dependentPossessive = "Her"
	pronouns.capitalized.independentPossessive = "Hers"
	return pronouns

static func Masculine() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase = Values.new()
	pronouns.capitalized = Values.new()
	pronouns.lowercase.verb = "is"
	pronouns.lowercase.nominative = "he"
	pronouns.lowercase.objectve = "him"
	pronouns.lowercase.dependentPossessive = "his"
	pronouns.lowercase.independentPossessive = "his"
	pronouns.capitalized.verb = "Is"
	pronouns.capitalized.nominative = "He"
	pronouns.capitalized.objectve = "Him"
	pronouns.capitalized.dependentPossessive = "His"
	pronouns.capitalized.independentPossessive = "His"
	return pronouns

static func Impersonal() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase = Values.new()
	pronouns.capitalized = Values.new()
	pronouns.lowercase.verb = "is"
	pronouns.lowercase.nominative = "it"
	pronouns.lowercase.objectve = "it"
	pronouns.lowercase.dependentPossessive = "its"
	pronouns.lowercase.independentPossessive = "its"
	pronouns.capitalized.verb = "Is"
	pronouns.capitalized.nominative = "It"
	pronouns.capitalized.objectve = "It"
	pronouns.capitalized.dependentPossessive = "Its"
	pronouns.capitalized.independentPossessive = "Its"
	return pronouns
