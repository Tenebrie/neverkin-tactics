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

static var _templateRegex: RegEx = RegEx.create_from_string("%(?|\\{(\\w+)\\}([%mt]?)|(\\w+)([%mt]?))")

static func populateNodeValues(text: String, skill: Node) -> String:
	var result = ""
	var lastEnd = 0

	for regexMatch in _templateRegex.search_all(text):
		result += text.substr(lastEnd, regexMatch.get_start() - lastEnd)

		var propName = regexMatch.get_string(1)
		var suffix = regexMatch.get_string(2)
		var value: Variant = skill.get(propName)

		lastEnd = regexMatch.get_end()

		if value == null:
			push_warning("Unknown template variable: %%%s" % propName)
			result += regexMatch.get_string()
		elif suffix == "%":
			result += "[color=orange]%d%%[/color]" % roundi(value * 100.0)
		elif suffix == "m":
			result += "[color=orange]%.2fm[/color]" % value
		elif suffix == "t":
			result += "[color=orange]%d[/color] turn%s"%[value, "" if value == 1 else "s"]
		elif value is int:
			result += "[color=orange]%d[/color]" % value
		elif value is float:
			result += "[color=orange]%.2f[/color]" % value
		elif value is bool and value == true:
			result += "[color=#55DD55]Active[/color]"
		elif value is bool and value == false:
			result += "[color=#DD5555]Inactive[/color]"
		elif value is String and value.length() == 0:
			if result.ends_with("\r\n"):
				result = result.substr(0, result.length() - 2)
			elif result.ends_with("\n"):
				result = result.substr(0, result.length() - 1)
		else:
			result += value

	result += text.substr(lastEnd)

	return result

static func populateBuffValues(text: String, buff: Buff) -> String:
	var result = populateNodeValues(text, buff)
	if not result:
		return result

	if buff.definition and buff.Duration >= 0:
		result += "\n\n$Duration: "
		if buff.Duration == 0:
			result += "Until the end of this turn"
		elif buff.Duration == 1:
			result += "Until the end of $their next turn"
		elif buff.Duration >= 2:
			result += "Lasts [color=orange]%d[/color] turns"%buff.Duration

	if buff.definition and buff.definition.stackType != Buff.StackType.Parallel:
		result += "\n"
		if buff.definition.stackType == Buff.StackType.StacksDuration:
			result += "$Stacks Duration"
		elif buff.definition.stackType == Buff.StackType.StacksIntensity:
			result += "$Stacks Intensity"
		elif buff.definition.stackType == Buff.StackType.None:
			result += "$Does not stack"

	return result

static func populateActorValues(text: String, actor: Actor) -> String:
	return populateNodeValues(text, actor)

static func populateSkillValues(text: String, skill: Skill) -> String:
	var description = populateNodeValues(text, skill)
	description = skill.parent.pronouns.evaluate(description)

	var commonLines: Array[String]
	if skill.definition.TargetingMaxRange > 0.0:
		commonLines.push_back("[color=orange]$Range:[/color] %.2fm"%skill.definition.TargetingMaxRange)
	if skill.definition.HealthCost > 0.0:
		commonLines.push_back("[color=#FF5555]$Health Cost:[/color] %d"%skill.HealthCost)
	if skill.definition.ManaCost > 0.0:
		commonLines.push_back("[color=#7777FF]$Mana Cost:[/color] %d"%skill.ManaCost)
	if skill.definition.Cooldown > 0:
		var cooldownMax = maxi(skill.definition.Cooldown, skill.cooldownRemaining)
		var cooldownPassed = cooldownMax - skill.cooldownRemaining
		var cooldown = "%d / %d"%[cooldownPassed, cooldownMax] if skill.cooldownRemaining > 0 else "%d"%skill.definition.Cooldown
		commonLines.push_back("[color=orange]$Cooldown:[/color] %s turn%s"%[cooldown, "" if cooldownMax == 1 else "s"])
	if skill.definition.ChargesMaximum > 0:
		var charges = "%d / %d"%[skill.chargesLeft, skill.chargesMaximum] if skill.chargesLeft < skill.chargesMaximum else "%d"%skill.chargesMaximum
		charges = "[color=orange]$Charges:[/color] %s"%charges
		commonLines.push_back(charges)
		if skill.ChargesRequired > 1:
			commonLines.push_back("[color=orange]$Charges Per Use:[/color] %d"%skill.ChargesRequired)

	if commonLines.size() == 0:
		return description

	var commonInfo = commonLines[0]
	for i in range(1, commonLines.size()):
		commonInfo += "\n" + commonLines[i]

	if commonInfo.length() == 0:
		return description
	if description.length() == 0:
		return commonInfo

	return commonInfo + "\n\n" + description

static func getSkillCategoryString(category: Skill.Category):
	match (category):
		Skill.Category.Item: return "Item Ability"
		Skill.Category.Innate: return "Innate"
		Skill.Category.Learned: return "Learned Ability"
		_: return ""
