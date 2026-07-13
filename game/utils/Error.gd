class_name Error

var Message: String

func _init(message: String) -> void:
	Message = message

static func AsBoolean(errorOrBool: Variant, errorValue: bool = false) -> bool:
	return errorValue if errorOrBool is Error else errorOrBool as bool
