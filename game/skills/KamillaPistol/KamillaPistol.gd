extends Skill
class_name KamillaPistol

var Damage = 1
var HitboxWidth = 0.04

var invisibleTelegraph = TelegraphPreset.Projectile.new().TargetingHostiles().Invisible().WithWidth(HitboxWidth).AvoidingLowCover()
var damageTelegraph = TelegraphPreset.Projectile.new().TargetingHostiles().WithWidth(HitboxWidth).Invisible()
var visualTelegraph = TelegraphPreset.Projectile.new().TargetingHostiles().WithDamage(Damage).WithWidth(HitboxWidth).AvoidingLowCover()

func _ready() -> void:
	Definition = preload("res://game/skills/KamillaPistol/KamillaPistol.tres").duplicate()
	#visualTelegraph.Processors.push_back(func(telegraph: RectangularTelegraph):
		#var allTargets = TelegraphManager.Instance.FindTelegraph(invisibleTelegraph).Targets
		#if allTargets.size() == 0:
			#telegraph.length = invisibleTelegraph.RectLength
			#return
		#allTargets.sort_custom(func(a: Actor, b: Actor) -> bool:
			#return a.global_position.distance_squared_to(Parent.global_position) < b.global_position.distance_squared_to(Parent.global_position)
		#)
		#var closestTarget = allTargets[0]
		#telegraph.length = closestTarget.global_position.distance_to(Parent.global_position)
	#)
	#visualTelegraph.TargetFilters.push_back(func(actor: Actor) -> bool:
		#var allTargets = TelegraphManager.Instance.FindTelegraph(invisibleTelegraph).Targets
		#if allTargets.size() <= 1:
			#return true
		#allTargets.sort_custom(func(a: Actor, b: Actor) -> bool:
			#return a.global_position.distance_squared_to(Parent.global_position) < b.global_position.distance_squared_to(Parent.global_position)
		#)
		#return actor == allTargets[0]
	#)
	Definition.Telegraphs = [
		invisibleTelegraph,
		damageTelegraph,
		visualTelegraph
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var effect = KamillaPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5

	if targets.perTelegraph[damageTelegraph].size() == 0:
		var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * Definition.TargetingMaxRange
		effect.Play(furthestPoint)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.stats.DealDamage(Damage)
		var effectVector = actor.global_position - Parent.global_position
		var effectDuration = effectVector.length() / Definition.TargetingMaxRange
		effect.Play(effectVector, 0.2 * effectDuration)
