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

@export var SegmentHealth: int = 3:
	set(v):
		SegmentHealth = v
		if is_node_ready():
			rebuild()

@export var CanBeIgnored: bool = true

const xSpacing = 0.2
const ySpacing = 0.2

func _ready():
	rebuild()
	if CanBeIgnored and not Engine.is_editor_hint():
		TurnManager.Instance.CurrentActorChanged.connect(checkDistances)
		Actor.SignalBus.ActorSelectedSkillChanged.connect(checkDistances)

func checkDistances():
	var currentActor = TurnManager.Instance.ActorTakingTurn
	if not currentActor:
		return

	if not currentActor.Skills.SelectedSkill:
		setIgnored(false)
		return

	var actorPosition = currentActor.global_position
	var distanceThreshold = pow(currentActor.PhysicalSize * 2, 2)

	for child in get_children():
		if child is not Node3D:
			continue
		if child.global_position.distance_squared_to(actorPosition) < distanceThreshold:
			setIgnored(true)
			return

	setIgnored(false)

func setIgnored(enabled: bool):
	var groupName = "propwall_ignored"
	if enabled and not is_in_group(groupName):
		add_to_group(groupName)
		for child in get_children():
			if child.has_node("MeshInstance3D"):
				child.get_node("MeshInstance3D").transparency = 0.95
				(child as CharacterBody3D).collision_layer |= CollisionLayer.IGNORED_COVER
	elif not enabled and is_in_group(groupName):
		remove_from_group(groupName)
		for child in get_children():
			if child.has_node("MeshInstance3D"):
				child.get_node("MeshInstance3D").transparency = 0
				(child as CharacterBody3D).collision_layer &= ~CollisionLayer.IGNORED_COVER

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
			if clone is Actor:
				clone.Definition.HealthMaximum = SegmentHealth
			clone.add_to_group(groupName)
