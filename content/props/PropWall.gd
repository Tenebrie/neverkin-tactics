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

@export var CoverValue: int = 0
@export var CanBeIgnored: bool = true
@onready var WallGroupName: StringName = "obstaclegroup_" + str(randi())

const xSpacing = 0.2
const ySpacing = 0.2

var boundingCircleRadius = 0.0

func _ready():
	rebuild()
	if not Engine.is_editor_hint():
		Repository.Register(self)
	if CanBeIgnored and not Engine.is_editor_hint():
		TurnManager.Instance.CurrentActorChanged.connect(checkDistances)
		SkillController.SignalBus.SelectedSkillChanged.connect(checkDistances)

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Repository.Unregister(self)

func IsIgnoredFor(actor: Actor) -> bool:
	if not CanBeIgnored:
		return false
	if not actor.Skills.SelectedSkill:
		return false

	var actorPosition = actor.global_position
	var distanceThreshold = pow(actor.physicalSize * 2, 2)

	for child in get_children():
		if child is not Node3D:
			continue
		if child.global_position.distance_squared_to(actorPosition) < distanceThreshold:
			return true
	return false

func checkDistances():
	var activeActor = TurnManager.Instance.activeActor
	if not activeActor:
		setIgnored(false)
		return

	var selectedSkill = activeActor.Skills.SelectedSkill
	if not selectedSkill:
		setIgnored(false)
		return

	var shootFromCover = selectedSkill.definition.telegraphs.any(func(telegraph: TelegraphDefinition) -> bool:
		return telegraph.ShootFromCover
	)
	if shootFromCover:
		setIgnored(IsIgnoredFor(activeActor))
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

var physicsFieldObstacle
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

	boundingCircleRadius = max(xSpacing, ySpacing) * max(ObstacleWidth, ObstacleDepth)

	for ix in range(ObstacleWidth):
		for iy in range(ObstacleDepth):
			if ix == 0 and iy == 0:
				# reposition the prototype itself into the grid
				prototype.position = Vector3(xOffset, prototype.position.y, yOffset)
				prototype.add_to_group(WallGroupName)
				if prototype is Actor:
					prototype.definition.ActionPointsMax = 0
					prototype.definition.MovementSpeedPerActionPoint = 0
					prototype.definition.healthMaximum = SegmentHealth
				continue
			var clone = prototype.duplicate() as Node3D
			clone.position = Vector3(
				xOffset + ix * xSpacing,
				prototype.position.y,
				yOffset + iy * ySpacing
			)
			add_child(clone)
			if clone is Actor:
				clone.definition.ActionPointsMax = 0
				clone.definition.MovementSpeedPerActionPoint = 0
				clone.definition.healthMaximum = SegmentHealth
			clone.add_to_group(WallGroupName)

	physicsFieldObstacle = buildPhysicsFieldObstacle()

func buildPhysicsFieldObstacle():
	var obstacle = PhysicsFieldObstacle.new()
	obstacle.transform = Transform2D(-global_rotation.y, Vector2(global_position.x, global_position.z))
	for segmentNode in get_children():
		if segmentNode is CollisionObject3D node:
			var segment = PhysicsFieldObstacleSegment.new()
			var shape = PhysicsFieldShapeRect.new()
			shape.size = Vector2(xSpacing, ySpacing)
			obstacle.collision_layer = obstacle.collision_layer | node.collision_layer
			segment.shape = shape
			segment.transform = Transform2D(-node.rotation.y, Vector2(node.position.x, node.position.z))
			obstacle.segments.push_back(segment)

	if obstacle.segments.is_empty():
		return obstacle

	for index in obstacle.segments.size():
		var segment = obstacle.segments[index]
		var halfSize = Vector2(xSpacing / 2, ySpacing / 2)
		var localCorners = [
			Vector2(-halfSize.x, -halfSize.y),
			Vector2( halfSize.x, -halfSize.y),
			Vector2( halfSize.x,  halfSize.y),
			Vector2(-halfSize.x,  halfSize.y),
		]
		var worldTransform = obstacle.transform * segment.transform
		for corner in localCorners:
			var world = worldTransform * corner
			if index == 0 and corner == localCorners[0]:
				obstacle.aabb = Rect2(world, Vector2.ZERO)
			else:
				obstacle.aabb = obstacle.aabb.expand(world)
	return obstacle

#region Static Helpers
static func GetIgnoredWallRidsAt(walls: Array[BehaviourUtils.MapTask.WallData], at: Vector3, physicalSize: float) -> Array[PhysicsFieldObstacle]:
	var out: Array[PhysicsFieldObstacle] = []
	var ignoredWalls = GetIgnoredWallsAt(walls, at, physicalSize)
	for wall in ignoredWalls:
		out.push_back(wall.obstacle)
	return out

static func GetIgnoredWallsAt(walls: Array[BehaviourUtils.MapTask.WallData], at: Vector3, physicalSize: float) -> Array[BehaviourUtils.MapTask.WallData]:
	var out: Array[BehaviourUtils.MapTask.WallData] = []
	var threshold: float = pow(physicalSize * 2.0, 2)
	for wall in walls:
		var minimalDistance = wall.boundingCircleRadius + physicalSize * 2.0
		if wall.globalPosition.distance_to(at) > minimalDistance:
			continue

		var wallIsClose: bool = false
		for segment in wall.segmentPositions:
			if segment.distance_squared_to(at) < threshold:
				wallIsClose = true
				break
		if not wallIsClose:
			continue
		out.push_back(wall)
	return out

static func collectBehaviourMapTaskData(includeFullCover: bool = false) -> Array[BehaviourUtils.MapTask.WallData]:
	var out: Array[BehaviourUtils.MapTask.WallData] = []
	for wall in PropWall.Repository.List:
		if not includeFullCover and not wall.CanBeIgnored:
			continue
		var wallData = BehaviourUtils.MapTask.WallData.new()
		wallData.wallName = wall.name
		wallData.globalPosition = wall.global_position
		wallData.boundingCircleRadius = wall.boundingCircleRadius
		wallData.obstacle = wall.physicsFieldObstacle
		wallData.coverValue = wall.CoverValue
		wallData.canBeUsedAsCover = wall.CanBeIgnored
		for segment in wall.get_children():
			if segment is not Node3D:
				continue
			wallData.segmentPositions.push_back(segment.global_position)
		out.push_back(wallData)
	return out

static func collectPhysicsFieldObstacles() -> Array[PhysicsFieldObstacle]:
	var out: Array[PhysicsFieldObstacle]
	for wall in PropWall.Repository.List:
		if wall.physicsFieldObstacle:
			out.push_back(wall.physicsFieldObstacle)
	return out

static func collectPhysicsFieldObstaclesGD() -> Array[PhysicsFieldGD.Obstacle]:
	var out: Array[PhysicsFieldGD.Obstacle]
	for wall in PropWall.Repository.List:
		var obstacle = PhysicsFieldGD.Obstacle.new()
		obstacle.transform = Transform2D(-wall.global_rotation.y, Vector2(wall.global_position.x, wall.global_position.z))
		for segmentNode in wall.get_children():
			if segmentNode is CollisionObject3D node:
				var segment = PhysicsFieldGD.ObstacleSegment.new()
				var shape = PhysicsShape.Rect.new()
				shape.size = Vector2(xSpacing, ySpacing)
				#obstacle.collisionLayer = obstacle.collisionLayer | node.collision_layer
				segment.shape = shape
				segment.transform = Transform2D(-node.rotation.y, Vector2(node.position.x, node.position.z))
				obstacle.segments.push_back(segment)

		if obstacle.segments.is_empty():
			continue

		for index in obstacle.segments.size():
			var segment = obstacle.segments[index]
			var halfSize = Vector2(xSpacing / 2, ySpacing / 2)
			var localCorners = [
				Vector2(-halfSize.x, -halfSize.y),
				Vector2( halfSize.x, -halfSize.y),
				Vector2( halfSize.x,  halfSize.y),
				Vector2(-halfSize.x,  halfSize.y),
			]
			var worldTransform = obstacle.transform * segment.transform
			for corner in localCorners:
				var world = worldTransform * corner
				if index == 0 and corner == localCorners[0]:
					obstacle.aabb = Rect2(world, Vector2.ZERO)
				else:
					obstacle.aabb = obstacle.aabb.expand(world)

		out.push_back(obstacle)
	return out
#endregion

#region Repository
static var Repository = RepositoryImplementation.new()
static func FindAllIgnoredFor(actor: Actor) -> Array[StringName]:
	var ignored: Array[StringName]
	for wall in Repository.List:
		if wall.IsIgnoredFor(actor):
			ignored.push_back(wall.WallGroupName)
	return ignored

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
