extends ActorBehaviour
class_name ActorBehaviourPlayerControlled

## Highest priority character is selected by default
var CharacterPriority: int:
	get: return Parent.Definition.RenderPriority
var Portrait: Texture2D:
	get: return Parent.Definition.AvatarTexture

func _ready() -> void:
	var inputProvider = ActorPlayerInputProvider.new()
	await get_tree().process_frame
	Parent.add_child(inputProvider)
	Parent.InputProvider = inputProvider
