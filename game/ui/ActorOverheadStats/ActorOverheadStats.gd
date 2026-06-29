extends CanvasLayer

@onready var parent: Actor = get_parent()

@onready var nameLabel: Label = $%NameLabel
@onready var healthBar: SegmentedBar = $%HealthBar
@onready var actionPointBar: SegmentedBar = $%ActionPointBar

func _ready():
	healthBar.FillColor = Color(0.0, 0.6, 0.2)
	healthBar.ThreatColor = Color(0.0, 0.4, 0.2)
	healthBar.InhumanColor = Color(0.8, 0.6, 0.0)
	actionPointBar.FillColor = Color(0.8, 0.8, 0.0)
	actionPointBar.ThreatColor = Color(0.6, 0.6, 0.0)

func _process(_delta: float):
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
	var stats = parent.stats
	var actions = parent.actions

	nameLabel.text = stats.Name

	healthBar.Value = stats.HealthCurrent
	healthBar.MaxValue = stats.HealthMaximum
	healthBar.InhumanValue = stats.HealthHumanityThreshold
	healthBar.ThreatValue = stats.HealthThreatened

	actionPointBar.Value = actions.ActionPointsAvailable
	actionPointBar.MaxValue = max(actions.ActionPointsMax, actions.ActionPointsAvailable)
	actionPointBar.InhumanValue = 0

	actionPointBar.ThreatValue = parent.targeting.PredictedActionPointCost + actions.ActionPointsThreatened
