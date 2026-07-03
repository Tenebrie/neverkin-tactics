@tool
extends Node3D

@export var ObstacleWidth: int = 1:
	set(v):
		ObstacleWidth = maxi(v, 1)
		if is_node_ready():
			rebuild()

@export var ObstacleDepth: int = 1:
	set(v):
		ObstacleDepth = maxi(v, 1)
		if is_node_ready():
			rebuild()

const xSpacing = 0.2
const ySpacing = 0.2

func _ready():
	rebuild()

func rebuild():
	var children = get_children()
	if children.is_empty():
		return

	var prototype = children[0] as Node3D

	# Clear previously spawned clones (keep the prototype)
	for i in range(children.size() - 1, 0, -1):
		var clone = children[i]
		remove_child(clone)
		clone.queue_free()

	var groupName = "obstaclegroup_" + str(randi())

	var xOffset = -(ObstacleWidth - 1) * xSpacing * 0.5
	var yOffset = -(ObstacleDepth - 1) * ySpacing * 0.5

	for ix in range(ObstacleWidth):
		for iy in range(ObstacleDepth):
			if ix == 0 and iy == 0:
				# reposition the prototype itself into the grid
				prototype.position = Vector3(xOffset, prototype.position.y, yOffset)
				prototype.add_to_group(groupName)
				continue
			var clone = prototype.duplicate() as Node3D
			clone.position = Vector3(
				xOffset + ix * xSpacing,
				prototype.position.y,
				yOffset + iy * ySpacing
			)
			add_child(clone)
			clone.add_to_group(groupName)
