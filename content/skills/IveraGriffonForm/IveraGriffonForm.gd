extends Skill
class_name IveraGriffonForm

var Damage = 3

const GRIFFON_SIZE = 0.8
var damageArea = TelegraphPreset.PointArea.new(1.2).WithDamageToHostiles(Damage)
var exclusionArea = TelegraphPreset.PointArea.new(GRIFFON_SIZE)

func _ready() -> void:
	definition = preload("./IveraGriffonForm.tres").duplicate()

	damageArea.Validators.push_back(func(_telegraph: Telegraph):
		var exclusionAreaTelegraph = parent.telegraphs.FindTelegraph(exclusionArea)
		if not exclusionAreaTelegraph.IsPathable(GRIFFON_SIZE):
			return Error.new("Not enough free space at destination.")
	)

	exclusionArea.Processors.push_back(func(telegraph: Telegraph):
		if telegraph.IsPathable(GRIFFON_SIZE):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)

	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		damageArea,
		exclusionArea,
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	for target in targets.perTelegraph[damageArea]:
		StartSequence()
			.AddStep(0.3, func():
				var effect = IveraClawsStrikeEffect.new()
				get_tree().current_scene.add_child(effect)
				effect.global_position = target.global_position
				effect.global_position.y = 2
				effect.Play())
			.AddStep(0.4, func(): target.Stats.DealSkillDamage(targets))

	parent.definition = definition.ShapeshiftTargetActor
	create_tween().tween_property(parent, "global_position", targets.mousePoint, 0.3)
	var collision = parent.collision_layer
	parent.collision_layer = 0
	await get_tree().create_timer(0.3).timeout
	parent.collision_layer = collision
