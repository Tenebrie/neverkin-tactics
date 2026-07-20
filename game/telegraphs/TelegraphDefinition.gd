extends Resource
class_name TelegraphDefinition

signal created(telegraph: Telegraph)
signal targetsChanged(targets: Array[Actor])

@export var Shape: Telegraph.Shape = Telegraph.Shape.Circle
@export var Attachment: Telegraph.Attachment = Telegraph.Attachment.None
@export var Icon: Texture2D
@export var IconPerTarget: Texture2D
@export var TextMessage: String

## Returns whether the telegraph as a whole is valid
@export var Validators: Array[func(Telegraph) -> Variant] = [func(_t): return true]
## Returns whether an individual actor is a valid target
@export var TargetFilters: Array[func(Actor, Telegraph) -> Variant] = [func(_a, _t): return true]
## Resource to be damaged
@export var HealthThreat: int = 0
@export var HealthThreatSelector = func(_actor: Actor) -> int: return HealthThreat
@export var ManaThreat: int = 0
@export var ManaThreatSelector = func(_actor: Actor) -> int: return ManaThreat
@export var ActionPointThreat: int = 0
@export var ActionPointThreatSelector = func(_actor: Actor) -> int: return ActionPointThreat
## Resource to be restored
@export var HealthPromise: int = 0
@export var HealthPromiseSelector = func(_actor: Actor) -> int: return HealthPromise
@export var ManaPromise: int = 0
@export var ManaPromiseSelector = func(_actor: Actor) -> int: return ManaPromise
@export var ActionPointPromise: int = 0
@export var ActionPointPromiseSelector = func(_actor: Actor) -> int: return ActionPointPromise
## Whether the telegraph is hidden and ignored for targeting/casting validation
@export var Disabled: bool = false
@export var DisabledSelector = func() -> bool: return Disabled

## While this telegraph is active, close cover is disabled
@export var ShootFromCover: bool = false
@export var ShootFromCoverOrigin: Vector3 = Vector3.ZERO

@export var PiercingPower = 0
@export var PenetrationPower = 0

@export var TargetSnapping: bool = false
@export var LookAtMouse: bool = false

## Update functions ran BEFORE targets are acquired
@export var Processors: Array[func(Telegraph) -> void] = []
## Update functions ran AFTER targets are acquired
@export var PostProcessors: Array[func(Telegraph) -> void] = []

@export var collisionMask: int = CollisionLayer.ACTOR

@export_group("Projectile", "Projectile")
@export var projectileCanHitCaster = false

@export_group("Circular Shape", "Circle")
@export var CircleRadius: float = 1.0

@export_group("Rectangular Shape", "Rect")
@export var RectWidth: float = 1.0
@export var RectLength: float = 1.0
@export var RectOrigin: BeamTelegraph.Origin = BeamTelegraph.Origin.Center

var ParentSkill: Skill

func getInstance() -> Telegraph:
	return ParentSkill.parent.telegraphs.FindTelegraph(self)

func Load(_skill: Skill) -> void:
	pass

func coerce() -> TelegraphDefinition:
	return self

## Returns whether the telegraph as a whole is valid
func addValidator(filter: func(Telegraph) -> Variant) -> TelegraphDefinition:
	Validators.push_back(filter)
	return self

## Returns whether an individual actor is a valid target
func addTargetFilter(filter: func(Actor, Telegraph) -> bool) -> TelegraphDefinition:
	TargetFilters.push_back(filter)
	return self

## Processors are update functions ran BEFORE targets are acquired
func addProcessor(processor: func(Telegraph) -> void) -> TelegraphDefinition:
	Processors.push_back(processor)
	return self

## Post processors are update functions ran AFTER the targets are acquired
func addPostProcessor(processor: func(Telegraph) -> void) -> TelegraphDefinition:
	PostProcessors.push_back(processor)
	return self

## Allow a certain collision layer to be targeted
func addCollisionLayer(layer: int) -> TelegraphDefinition:
	collisionMask |= layer
	return self

## Allow cover to be explicitly targeted
func collideWithCover() -> TelegraphDefinition:
	return addCollisionLayer(CollisionLayer.LOW_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.FULL_COVER)

## Allow obstacles and cover to be explicitly targeted
func collideWithObstacles() -> TelegraphDefinition:
	return addCollisionLayer(CollisionLayer.OBSTACLE | CollisionLayer.LOW_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.FULL_COVER)
