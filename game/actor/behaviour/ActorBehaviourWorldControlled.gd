extends ActorBehaviour
class_name ActorBehaviourWorldControlled

func _ready() -> void:
	var inputProvider = ActorInputProvider.new()
	await get_tree().process_frame
	parent.add_child(inputProvider)
	parent.InputProvider = inputProvider
