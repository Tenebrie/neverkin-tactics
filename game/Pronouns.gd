class_name Pronouns

enum Preset {
	Neutral,
	Feminine,
	Masculine,
	Impersonal
}

class Values:
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

static func FromPreset(preset: Preset):
	match (preset):
		Preset.Feminine: 	return Pronouns.Feminine()
		Preset.Masculine: 	return Pronouns.Masculine()
		Preset.Impersonal: 	return Pronouns.Impersonal()
		_: 					return Pronouns.Neutral()

static func Neutral() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase.nominative = "they"
	pronouns.lowercase.objectve = "them"
	pronouns.lowercase.dependentPossessive = "their"
	pronouns.lowercase.independentPossessive = "theirs"
	pronouns.capitalized.nominative = "They"
	pronouns.capitalized.objectve = "Them"
	pronouns.capitalized.dependentPossessive = "Their"
	pronouns.capitalized.independentPossessive = "Theirs"
	return pronouns

static func Feminine() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase.nominative = "she"
	pronouns.lowercase.objectve = "her"
	pronouns.lowercase.dependentPossessive = "her"
	pronouns.lowercase.independentPossessive = "hers"
	pronouns.capitalized.nominative = "She"
	pronouns.capitalized.objectve = "Her"
	pronouns.capitalized.dependentPossessive = "Her"
	pronouns.capitalized.independentPossessive = "Hers"
	return pronouns

static func Masculine() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase.nominative = "he"
	pronouns.lowercase.objectve = "him"
	pronouns.lowercase.dependentPossessive = "his"
	pronouns.lowercase.independentPossessive = "his"
	pronouns.capitalized.nominative = "He"
	pronouns.capitalized.objectve = "Him"
	pronouns.capitalized.dependentPossessive = "His"
	pronouns.capitalized.independentPossessive = "His"
	return pronouns

static func Impersonal() -> Pronouns:
	var pronouns = Pronouns.new()
	pronouns.lowercase.nominative = "it"
	pronouns.lowercase.objectve = "it"
	pronouns.lowercase.dependentPossessive = "its"
	pronouns.lowercase.independentPossessive = "its"
	pronouns.capitalized.nominative = "It"
	pronouns.capitalized.objectve = "It"
	pronouns.capitalized.dependentPossessive = "Its"
	pronouns.capitalized.independentPossessive = "Its"
	return pronouns
