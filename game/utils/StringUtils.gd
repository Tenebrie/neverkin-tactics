class_name StringUtils

static var CLEANUP_REGEX = RegEx.create_from_string("\\$|!buff|!skill|!actor")
static var DOUBLE_NEWLINE_REGEX = RegEx.create_from_string("\\n\\n")
static var SINGLE_NEWLINE_REGEX = RegEx.create_from_string("\\n")
static var PARAGRAPH_RESTORE_REGEX = RegEx.create_from_string("<PARA>")

static func evaluateTemplate(text: String, enableColor: bool) -> String:
	var keywords = KeywordManager.Instance.allKeywords

	for keyword in keywords:
		var replacement = "[url=keyword:%d]$1[/url]"%[keyword.id]
		if enableColor:
			replacement = "[color=%s]%s[/color]"%[keyword.definition.color.to_html(), replacement]
		text = keyword.pattern.sub(text, replacement, true)

	text = CLEANUP_REGEX.sub(text, "", true)
	text = DOUBLE_NEWLINE_REGEX.sub(text, "<PARA>", true)
	text = SINGLE_NEWLINE_REGEX.sub(text, "[br]", true)
	text = PARAGRAPH_RESTORE_REGEX.sub(text, "\n", true)

	return text

static var _templateRegex: RegEx = RegEx.create_from_string("%(?|\\{(\\w+)\\}([%m]?)|(\\w+)([%m]?))")

static func populateNodeValues(text: String, skill: Node) -> String:
	var result = ""
	var lastEnd = 0

	for regexMatch in _templateRegex.search_all(text):
		result += text.substr(lastEnd, regexMatch.get_start() - lastEnd)

		var propName = regexMatch.get_string(1)
		var suffix = regexMatch.get_string(2)
		var value: Variant = skill.get(propName)

		if value == null:
			push_warning("Unknown template variable: %%%s" % propName)
			result += regexMatch.get_string()
		elif suffix == "%":
			result += "[color=orange]%d%%[/color]" % roundi(value * 100.0)
		elif suffix == "m":
			result += "[color=orange]%.2fm[/color]" % value
		elif value is int:
			result += "[color=orange]%d[/color]" % value
		else:
			result += "[color=orange]%.2f[/color]" % value

		lastEnd = regexMatch.get_end()

	result += text.substr(lastEnd)

	return result

static func populateBuffValues(text: String, buff: Buff) -> String:
	var result = populateNodeValues(text, buff)

	return result

static func populateSkillValues(text: String, skill: Skill) -> String:
	var result = populateNodeValues(text, skill)

	if skill.definition.TargetingMaxRange > 0.0:
		if result.length() > 0:
			result += "\n\n"
		result += "[color=orange]$Range:[/color] %.2fm"%skill.definition.TargetingMaxRange

	return result

static func getSkillCategoryString(category: Skill.Category):
	match (category):
		Skill.Category.Item: return "Item Ability"
		Skill.Category.Innate: return "Innate"
		Skill.Category.Learned: return "Learned Ability"
		_: return ""
