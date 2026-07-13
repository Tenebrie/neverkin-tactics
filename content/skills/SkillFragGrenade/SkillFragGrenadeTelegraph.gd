extends Node3D
class_name SkillFragGrenadeTelegraph

var Damage: int = 1
var Radius: float = 1.0
var TriggeringSkill: Skill

var apSpentTotal = 0.0
var fuseDuration = 1.0 # action points
var fuse: CircularTelegraph

func EnableFuse(origin: Vector3, telegraphDefinition: TelegraphDefinition):
	fuse = ActorTelegraphs.instantiateTelegraph(telegraphDefinition, TriggeringSkill)
	Game.Scene.add_child(fuse)
	fuse.global_position = origin
	fuse.growPercentage = 0.0
	fuse.setColor(Color.RED)
	fuse.cleaningStarted.connect(func():
		for child in get_children():
			child.queue_free()
	)

	ActorActions.SignalBus.ActionPointsConsumedPermanently.connect(func(actor: Actor, apConsumed):
		if actor.stats.Faction != Actor.PlayerFaction or fuse.IsLeaving:
			return
		AdvanceFuse(apConsumed)
	)
	ActorNavigator.SignalBus.ActorTraversed.connect(func(actor, dist):
		if actor.stats.Faction != Actor.PlayerFaction or fuse.IsLeaving:
			return
		var apSpent = dist / actor.movementSpeedPerAction
		AdvanceFuse(apSpent)
		if apSpentTotal >= fuseDuration:
			explode()
	)
	TurnManager.Instance.BeforeFactionTurnEnded.connect(func():
		if fuse.IsLeaving:
			return
		AdvanceFuse(1000)
		MainCamera.lock(self)
		while fuse.growPercentage < 1.0:
			await get_tree().process_frame
		explode()
		await get_tree().create_timer(0.25).timeout
		MainCamera.unlock(self)
	)

	Skill.SignalBus.afterCast.connect(func(_t):
		if apSpentTotal < fuseDuration:
			return

		while fuse.growPercentage < 1.0:
			await get_tree().process_frame
		explode()
		await get_tree().create_timer(0.25).timeout
	)

func AdvanceFuse(apSpent: float):
	apSpentTotal += apSpent

func _process(delta: float) -> void:
	if not fuse:
		return
	var current = fuse.growPercentage
	var target = clampf(apSpentTotal / (fuseDuration - 0.05), 0.0, 1.0)
	if target == current:
		return

	if target > current:
		fuse.growPercentage = clampf(current + delta * fuseDuration, current, target)
	else:
		fuse.growPercentage = clampf(current - delta * fuseDuration, target, current)

func explode():
	fuse.cleanUp()
	fuse.tree_exiting.connect(queue_free)
	PlayExplosionEffect()
	for target in fuse.Targets:
		target.stats.dealDamage(DamageInstance.ForDelayedTelegraph(target, TriggeringSkill, fuse))

func PlayExplosionEffect():
	for i in 150:
		var angle = randf() * TAU
		var distance = sqrt(randf()) * Radius
		var point = global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		MessageLog.PrintWorldMessage("Boom!", point)
