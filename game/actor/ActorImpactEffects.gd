extends Component

var meshInstance: MeshInstance3D
var damageTintFraction = 0.0

func _parentReady():
	meshInstance = parent.get_node("TokenMeshInstance3D")
	parent.stats.damageTaken.connect(func():
		damageTintFraction = 1.2
		_updateTint()
	)

func _updateTint():
	var mat: StandardMaterial3D = meshInstance.material_override
	if damageTintFraction > 1.0:
		mat.albedo_color = Color(2.0, 2.0, 2.0)
	else:
		mat.albedo_color = Color(1.0, clampf(1.0 - damageTintFraction, 0, 1), clampf(1.0 - damageTintFraction, 0, 1))

func _process(delta: float) -> void:
	if damageTintFraction <= 0.0:
		return

	_updateTint()
	damageTintFraction = clampf(damageTintFraction - delta * 5.0, 0.0, 2.0)
