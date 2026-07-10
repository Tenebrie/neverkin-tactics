extends Skill
class_name SkillFragGrenade

var Damage = 3
var Radius = 1.5

var damageTelegraph: TelegraphDefinition = TelegraphPreset.PointArea.new(Radius).WithDamageToHostiles(Damage).allowObstacles()

func _ready() -> void:
	Definition = preload("./SkillFragGrenade.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		damageTelegraph
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	var effect = Asset.Instantiate(SkillFragGrenadeTelegraph)
	get_tree().root.add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5
	effect.scale = Vector3(0.3, 0.3, 0.3)
	var startPos = Parent.global_position
	startPos.y = RenderHeight.AboveWalls
	var endPos = targets.mousePoint
	var arcHeight = startPos.distance_to(endPos) / 3.0
	var duration = startPos.distance_to(endPos) / 8.0

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_method(
		func(t: float) -> void:
			var pos = startPos.lerp(endPos, t)
			var hop = pow(sin(t * PI), 0.6)
			pos.z -= hop * arcHeight
			effect.global_position = pos
			effect.global_position.y = RenderHeight.AboveWalls,
		0.0, 1.0, duration
	)

	tween.tween_property(effect, "rotation:y", effect.rotation.y + TAU, duration)
	await get_tree().create_timer(duration + 0.01).timeout

	#if Parent.Stats.Faction == Actor.PlayerFaction:
		#for target in targets.perTelegraph[damageTelegraph]:
			#if is_instance_valid(target):
				#target.Stats.DealSkillDamage(targets)
		#effect.PlayExplosionEffect()
		#effect.queue_free()
	#else:
	effect.Damage = Damage
	effect.Radius = Radius
	effect.TriggeringSkill = self
	effect.EnableFuse(targets.mousePoint, damageTelegraph)
