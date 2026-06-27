extends Component
class_name PlayerController

## Highest priority character is selected by default
var CharacterPriority: int:
	get: return parent.Definition.RenderPriority
var Portrait: Texture2D:
	get: return parent.Definition.AvatarTexture

func _ready() -> void:
	pass # Replace with function body.
