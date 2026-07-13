extends Skill
class_name IveraGriffonForm

var griffonDefinition = preload("res://content/actors/Ivera/shapeshift/IveraGriffon.tres")

var Damage = 3
var GriffonSize = griffonDefinition.physicalSize
var LandingAreaSize = 1.3
var LandingMaxDist = LandingAreaSize - GriffonSize

var damageArea = TelegraphPreset.PointArea.new(LandingAreaSize).WithDamageToHostiles(Damage)
var exclusionArea = TelegraphPreset.PointArea.new(GriffonSize)

func _prepare() -> void:
	damageArea.Validators.push_back(func(_telegraph: Telegraph):
		var exclusionAreaTelegraph = parent.telegraphs.FindTelegraph(exclusionArea)
		if not exclusionAreaTelegraph.IsPathable(GriffonSize):
			return Error.new("Not enough free space at destination.")
	)

	exclusionArea.Processors.push_back(func(telegraph: Telegraph):
		if telegraph.IsPathable(GriffonSize):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)

	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		damageArea,
		exclusionArea,
	]

func _cast(targets: Skill.TargetData) -> void:
	for target in targets.perTelegraph[damageArea]:
		StartSequence()
			.AddStep(0.3, func():
				var effect = SkillClawStrikeEffect.new()
				get_tree().current_scene.add_child(effect)
				effect.global_position = target.global_position
				effect.global_position.y = 2
				effect.Play())
			.AddStep(0.4, func(): target.stats.dealSkillDamage(targets))

	parent.definition = definition.ShapeshiftTargetActor
	create_tween().tween_property(parent, "global_position", targets.mousePoint, 0.3)
	var collision = parent.collision_layer
	parent.collision_layer = 0
	await get_tree().create_timer(0.3).timeout
	parent.collision_layer = collision
