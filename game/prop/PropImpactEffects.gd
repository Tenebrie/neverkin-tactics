extends Component

var meshInstance: MeshInstance3D
var mat: StandardMaterial3D
var damageTintFraction = 0.0

func _parentReady():
	meshInstance = parent.get_node("MeshInstance3D")
	parent.stats.damageTaken.connect(func():
		if mat == null:
			mat = meshInstance.get_active_material(0).duplicate()
			meshInstance.material_override = mat
		damageTintFraction = 1.2
		_updateTint()
	)

func _updateTint():
	if damageTintFraction > 1.0:
		mat.albedo_color = Color(2.0, 2.0, 2.0)
	else:
		var c = clampf(1.0 - damageTintFraction, 0, 1)
		mat.albedo_color = Color(1.0, c, c)

func _process(delta: float) -> void:
	if damageTintFraction <= 0.0:
		return
	_updateTint()
	damageTintFraction = clampf(damageTintFraction - delta * 5.0, 0.0, 2.0)
