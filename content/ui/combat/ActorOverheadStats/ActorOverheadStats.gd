extends CanvasLayer
class_name ActorOverheadStats

@onready var parent: Actor = get_parent()

@onready var nameLabel: Label = $%NameLabel
@onready var healthBar: SegmentedBar = $%HealthBar
@onready var actionPointBar: SegmentedBar = $%ActionPointBar

@onready var focusTargetCount: Control = %CurrentFocusTargetCount

static var GloballyVisible = true

func _ready():
	healthBar.FillColor = Color(0.0, 0.6, 0.2)
	healthBar.ThreatColor = Color(0.0, 0.4, 0.2)
	healthBar.InhumanColor = Color(0.8, 0.6, 0.0)
	actionPointBar.FillColor = Color(0.8, 0.8, 0.0)
	actionPointBar.ThreatColor = Color(0.6, 0.4, 0.0)
	actionPointBar.InhumanColor = Color(1.6, 0.6, 0.0)

func _process(_delta: float):
	if visible != GloballyVisible:
		visible = GloballyVisible
	if not GloballyVisible:
		return
	updatePosition()
	updateValues()

func updatePosition():
	var cam := get_viewport().get_camera_3d()
	var screen := cam.unproject_position(parent.global_position)
	offset = screen - Vector2($VBoxContainer.size.x / 2, $VBoxContainer.size.y) - Vector2(0, world_to_pixels(parent.PhysicalSize) + 4)

func world_to_pixels(world_size: float) -> float:
	var camera = get_viewport().get_camera_3d()
	var viewport_height = get_viewport().get_visible_rect().size.y
	return world_size * viewport_height / camera.size

func updateValues():
	var stats = parent.Stats
	var actions = parent.actions

	nameLabel.text = stats.Name

	healthBar.Value = stats.HealthCurrent
	healthBar.MaxValue = stats.HealthMaximum
	healthBar.InhumanValue = stats.HealthHumanityThreshold
	healthBar.ThreatValue = stats.HealthThreatened

	actionPointBar.Value = actions.ActionPointsAvailable
	actionPointBar.MaxValue = max(actions.ActionPointsMax, actions.ActionPointsAvailable)
	actionPointBar.InhumanValue = actions.ActionPointsSavedMax

	actionPointBar.ThreatValue = parent.targeting.PredictedActionPointCost + actions.ActionPointsThreatened

	var focusedTargets = Actor.Repository.Alive.List.filter(func(actor):
		if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
			return behaviour.FocusedTarget == parent
		return false
	)
	focusTargetCount.visible = focusedTargets.size() > 0
	if focusTargetCount.visible:
		focusTargetCount.get_node("Label").text = str(focusedTargets.size())

func fadeOut(duration: float = 0.3):
	var container: Control = $VBoxContainer
	create_tween().tween_property(container, "modulate:a", 0, duration)
