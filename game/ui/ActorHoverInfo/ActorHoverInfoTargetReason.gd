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
			$Value.text = "+%.2f"%v

func _ready():
	TargetReason = TargetReason
	TargetValue = TargetValue
