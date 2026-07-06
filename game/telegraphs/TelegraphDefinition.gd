@abstract extends Resource
class_name TelegraphDefinition

@export var Shape: Telegraph.Shape = Telegraph.Shape.Circle
@export var Attachment: Telegraph.Attachment = Telegraph.Attachment.None
@export var Icon: Texture2D

## Returns whether the telegraph as a whole is valid
@export var Validators: Array[func(Telegraph) -> bool] = [func(_t): return true]
## Returns whether an individual actor is a valid target
@export var TargetFilters: Array[func(Actor) -> bool] = [func(_a): return true]
@export var HealthThreat: int = 0
@export var HealthThreatSelector = func(_actor: Actor) -> int: return HealthThreat

## While this telegraph is active, close cover is disabled
@export var ShootFromCover: bool = false

@export var PiercingPower = 0
@export var PenetrationPower = 0

@export var TargetSnapping: bool = false
@export var LookAtMouse: bool = false

@export var Processors: Array[Callable] = []

@export_group("Circular Shape", "Circle")
@export var CircleRadius: float = 1.0

@export_group("Rectangular Shape", "Rect")
@export var RectWidth: float = 1.0
@export var RectLength: float = 1.0
@export var RectOrigin: RectangularTelegraph.Origin = RectangularTelegraph.Origin.Center

@abstract func Load(skill: Skill) -> void
var ParentSkill: Skill
