class_name Utils

#region Class Ancestors
static var _classAncestorDict: Dictionary[GDScript, Dictionary] = {}

static func GetClassAncestors(script: GDScript) -> Dictionary:
	if _classAncestorDict.has(script):
		return _classAncestorDict[script]
	var elementSet: Dictionary[GDScript, bool] = {}
	var cur = script
	while cur != null:
		elementSet[cur] = true
		cur = cur.get_base_script()
	_classAncestorDict[script] = elementSet
	return elementSet


static func IsNodeDescendantOf(node: Node, scriptClass: GDScript):
	var nodeScript: GDScript = node.get_script()
	if not nodeScript:
		return false
	return GetClassAncestors(nodeScript).has(scriptClass)
#endregion
