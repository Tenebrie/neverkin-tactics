extends Skill
class_name AlgaeHunterSwipe

const Damage = 1

var damageTelegraph = TelegraphPreset.SingleActor.new()

func _ready() -> void:
	definition = preload("./AlgaeHunterSwipe.tres").duplicate()
	damageTelegraph.HealthThreat = Damage
	damageTelegraph.TargetFilters.push_back(func(actor: Actor) -> bool:
		return ActorUtils.isHostileTo(actor, parent)
	)

	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		damageTelegraph,
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = AlgaeHunterSwipeEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = actor.global_position
	effect.global_position.y = 2
	effect.Play()
	get_tree().create_timer(0.1).timeout.connect(func():
		actor.Stats.DealSkillDamage(targets)
	)
