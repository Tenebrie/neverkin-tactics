class_name StringUtils

static func EvaluateTemplate(text: String, enableColor: bool) -> String:
	var keywords = KeywordManager.Instance.allKeywords

	for keyword in keywords:
		var replacement = "[url=keyword:%d]$1[/url]"%[keyword.id]
		if enableColor:
			replacement = "[color=%s]%s[/color]"%[keyword.definition.color.to_html(), replacement]
		text = keyword.pattern.sub(text, replacement, true)

	var cleanupRegex = RegEx.new()
	cleanupRegex.compile("\\$")
	text = cleanupRegex.sub(text, "", true)

	var doubleNewlineRegex = RegEx.new()
	doubleNewlineRegex.compile("\\n\\n")
	text = doubleNewlineRegex.sub(text, "<PARA>", true)

	var singleNewlineRegex = RegEx.new()
	singleNewlineRegex.compile("\\n")
	text = singleNewlineRegex.sub(text, "[br]", true)

	var restoreRegex = RegEx.new()
	restoreRegex.compile("<PARA>")
	text = restoreRegex.sub(text, "\n", true)

	return text
