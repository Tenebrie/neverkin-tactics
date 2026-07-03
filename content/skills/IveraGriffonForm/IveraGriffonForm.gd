extends Skill
class_name IveraGriffonForm

var Damage = 1

var damageArea = TelegraphPreset.PointArea.new(1.2).WithDamageToHostiles(Damage)
var exclusionArea = TelegraphPreset.PointArea.new(0.8)

func _ready() -> void:
	Definition = preload("res://content/skills/IveraGriffonForm/IveraGriffonForm.tres").duplicate()

	damageArea.Validators.push_back(func(_telegraph: Telegraph):
		var exclusionAreaTelegraph = TelegraphManager.Instance.FindTelegraph(exclusionArea)
		if not exclusionAreaTelegraph.IsPathable():
			return Error.new("Not enough free space at destination.")
	)

	exclusionArea.Processors.push_back(func(telegraph: Telegraph):
		if telegraph.IsPathable():
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)

	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		damageArea,
		exclusionArea,
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	Parent.Definition = Definition.ShapeshiftTargetActor
	create_tween().tween_property(Parent, "global_position", targets.mousePoint, 0.3)
	await get_tree().create_timer(0.3).timeout
	for target in targets.perTelegraphIndex[1]:
		var effect = IveraClawsStrikeEffect.new()
		get_tree().current_scene.add_child(effect)
		effect.global_position = target.global_position
		effect.global_position.y = 2
		effect.scale = Vector3(1.7,1.7,1.7)
		effect.Play()
		get_tree().create_timer(0.1).timeout.connect(func():
			target.stats.DealDamage(Damage)
		)
