@tool
extends Node3D
class_name PropWall

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
@onready var WallGroupName: StringName = "obstaclegroup_" + str(randi())

const xSpacing = 0.2
const ySpacing = 0.2

func _ready():
	rebuild()
	Repository.Register(self)
	if CanBeIgnored and not Engine.is_editor_hint():
		TurnManager.Instance.CurrentActorChanged.connect(checkDistances)
		Actor.SignalBus.ActorSelectedSkillChanged.connect(checkDistances)

func _exit_tree() -> void:
	Repository.Unregister(self)

func IsIgnoredFor(actor: Actor) -> bool:
	if not CanBeIgnored:
		return false
	if not actor.Skills.SelectedSkill:
		return false

	var actorPosition = actor.global_position
	var distanceThreshold = pow(actor.PhysicalSize * 2, 2)

	for child in get_children():
		if child is not Node3D:
			continue
		if child.global_position.distance_squared_to(actorPosition) < distanceThreshold:
			return true
	return false

func checkDistances():
	var currentActor = TurnManager.Instance.ActorTakingTurn
	if not currentActor:
		setIgnored(false)
		return

	var selectedSkill = currentActor.Skills.SelectedSkill
	if not selectedSkill:
		setIgnored(false)
		return

	var shootFromCover = selectedSkill.Definition.Telegraphs.any(func(telegraph: TelegraphDefinition) -> bool:
		return telegraph.ShootFromCover
	)
	if shootFromCover:
		setIgnored(IsIgnoredFor(currentActor))
	else:
		setIgnored(false)

func setIgnored(enabled: bool):
	var groupName = "propwall_ignored"
	if enabled and not is_in_group(groupName):
		add_to_group(groupName)
		for child in get_children():
			if child.has_node("MeshInstance3D"):
				child.get_node("MeshInstance3D").transparency = 0.95
	elif not enabled and is_in_group(groupName):
		remove_from_group(groupName)
		for child in get_children():
			if child.has_node("MeshInstance3D"):
				child.get_node("MeshInstance3D").transparency = 0

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

	var xOffset = -(ObstacleWidth - 1) * xSpacing * 0.5
	var yOffset = -(ObstacleDepth - 1) * ySpacing * 0.5

	for ix in range(ObstacleWidth):
		for iy in range(ObstacleDepth):
			if ix == 0 and iy == 0:
				# reposition the prototype itself into the grid
				prototype.position = Vector3(xOffset, prototype.position.y, yOffset)
				prototype.add_to_group(WallGroupName)
				if prototype is Actor:
					prototype.Definition.HealthMaximum = SegmentHealth
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
			clone.add_to_group(WallGroupName)

static var Repository = RepositoryImplementation.new()
static func FindAllIgnoredFor(actor: Actor) -> Array[StringName]:
	var ignored: Array[StringName]
	for wall in Repository.List:
		if wall.IsIgnoredFor(actor):
			ignored.push_back(wall.WallGroupName)
	return ignored

#region Repository
class RepositoryImplementation:
	var List: Array[PropWall] = []

	func Register(prop: PropWall):
		var index = List.find(prop)
		if index > 0:
			return
		List.push_back(prop)

	func Unregister(prop: PropWall):
		var index = List.find(prop)
		if index < 0:
			return
		List.remove_at(index)
#endregion
