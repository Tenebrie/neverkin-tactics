extends Node3D
class_name SkillFragGrenadeTelegraph

var Damage: int = 1
var Radius: float = 1.0
var TriggeringSkill: Skill

var apSpentTotal = 0.0
var fuseDuration = 1.0 # action points
var fuse: CircularTelegraph

func EnableFuse(origin: Vector3):
	fuse = Asset.Instantiate(CircularTelegraph)
	Game.Scene.add_child(fuse)
	fuse.global_position = origin
	fuse.radius = Radius
	fuse.setColor(Color.RED)
	fuse.Definition = TelegraphPreset.PointArea.new(Radius).WithDamageToHostiles(Damage)

	ActorActions.SignalBus.ActionPointsConsumedPermanently.connect(func(actor: Actor, apConsumed):
		if actor.Stats.Faction != Actor.Faction.Player or fuse.IsLeaving:
			return
		AdvanceFuse(apConsumed)
	)
	ActorNavigator.SignalBus.ActorTraversed.connect(func(actor, dist):
		if actor.Stats.Faction != Actor.Faction.Player or fuse.IsLeaving:
			return
		var apSpent = dist / actor.Definition.MovementSpeedPerActionPoint
		AdvanceFuse(apSpent)
	)
	TurnManager.Instance.FactionTurnEnded.connect(func(faction):
		if fuse.IsLeaving or faction != Actor.Faction.Player:
			return
		AdvanceFuse(1000)
	)

func AdvanceFuse(apSpent: float):
	apSpentTotal += apSpent
	fuse.growPercentage = clampf(apSpentTotal / (fuseDuration - 0.05), 0.0, 1.0)
	if fuse.growPercentage >= 1.0:
		explode()
		fuse.cleanUp()
		fuse.tree_exiting.connect(queue_free)

func explode():
	PlayExplosionEffect()
	for target in fuse.Targets:
		target.Stats.DealDamage(DamageInstance.ForDelayedTelegraph(target, TriggeringSkill, fuse))

func PlayExplosionEffect():
	for i in 150:
		var angle = randf() * TAU
		var distance = sqrt(randf()) * Radius
		var point = global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		MessageLog.PrintWorldMessage("Boom!", point, get_viewport())
