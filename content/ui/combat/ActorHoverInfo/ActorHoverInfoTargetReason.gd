extends HBoxContainer
class_name ActorHoverInfoTargetReason

@export var TargetReason: String:
	set(v):
		TargetReason = v
		if is_node_ready():
			$Label.text = v
@export var TargetValue: float:
	set(v):
		TargetValue = v
		if is_node_ready():
			$Value.text = "+%d"%floori(v)

func _ready():
	TargetReason = TargetReason
	TargetValue = TargetValue
	$Value.visible = Input.is_key_pressed(KEY_SHIFT)
