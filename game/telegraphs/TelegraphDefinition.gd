@abstract extends Resource
class_name TelegraphDefinition

signal created(telegraph: Telegraph)
signal targetsChanged(targets: Array[Actor])

@export var Shape: Telegraph.Shape = Telegraph.Shape.Circle
@export var Attachment: Telegraph.Attachment = Telegraph.Attachment.None
@export var Icon: Texture2D
@export var TextMessage: String

## Returns whether the telegraph as a whole is valid
@export var Validators: Array[func(Telegraph) -> bool] = [func(_t): return true]
## Returns whether an individual actor is a valid target
@export var TargetFilters: Array[func(Actor, Telegraph) -> bool] = [func(_a, _t): return true]
## Health to be damaged
@export var HealthThreat: int = 0
@export var HealthThreatSelector = func(_actor: Actor) -> int: return HealthThreat
@export var ManaThreat: int = 0
@export var ManaThreatSelector = func(_actor: Actor) -> int: return ManaThreat
## Health to be restored
@export var HealthPromise: int = 0
@export var HealthPromiseSelector = func(_actor: Actor) -> int: return HealthPromise
@export var ManaPromise: int = 0
@export var ManaPromiseSelector = func(_actor: Actor) -> int: return ManaPromise

## While this telegraph is active, close cover is disabled
@export var ShootFromCover: bool = false

@export var PiercingPower = 0
@export var PenetrationPower = 0

@export var TargetSnapping: bool = false
@export var LookAtMouse: bool = false

@export var Processors: Array[Callable] = []

@export var collisionMask: int = CollisionLayer.SKILL_TARGETABLE

@export_group("Circular Shape", "Circle")
@export var CircleRadius: float = 1.0

@export_group("Rectangular Shape", "Rect")
@export var RectWidth: float = 1.0
@export var RectLength: float = 1.0
@export var RectOrigin: RectangularTelegraph.Origin = RectangularTelegraph.Origin.Center

@abstract func Load(skill: Skill) -> void
var ParentSkill: Skill

func addValidator(filter: func(Telegraph) -> bool) -> TelegraphDefinition:
	Validators.push_back(filter)
	return self

func addTargetFilter(filter: func(Actor) -> bool) -> TelegraphDefinition:
	TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph):
		return filter.call(actor)
	)
	return self

func addTargetFilterOnTelegraph(filter: func(Actor, Telegraph) -> bool) -> TelegraphDefinition:
	TargetFilters.push_back(filter)
	return self

func addCollisionLayer(layer: int) -> TelegraphDefinition:
	collisionMask |= layer
	return self

func allowObstacles() -> TelegraphDefinition:
	return addCollisionLayer(CollisionLayer.OBSTACLE)
