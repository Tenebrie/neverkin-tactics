extends ActorBehaviour
class_name ActorBehaviourPlayerControlled

## Highest priority character is selected by default
var CharacterPriority: int:
	get: return parent.Definition.RenderPriority
var Portrait: Texture2D:
	get: return parent.Definition.AvatarTexture

func _ready() -> void:
	var inputProvider = ActorPlayerInputProvider.new()
	await get_tree().process_frame
	parent.add_child(inputProvider)
	parent.InputProvider = inputProvider
