extends Resource
class_name SnapshotResource

func _friendlyName() -> String:
	return get_class()

func _to_string() -> String:
	var parts: PackedStringArray = []
	for prop in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			parts.append("%s=%s" % [prop["name"], get(prop["name"])])
	return "<%s %s>" % [_friendlyName(), " ".join(parts)]
