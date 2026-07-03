extends Node
class_name NPCManager

func _ready() -> void:
	TurnManager.Instance.FactionTurnStarted.connect(func(faction):
		if faction != Actor.Alliance.Player:
			playAsFaction(faction)
	)

func playAsFaction(faction: Actor.Alliance):
	var actors = Actor.Repository.All.List.filter(func(actor):
		return actor.Definition.Alliance == faction
	)

	for actor in actors:
		if not actor.Behaviour or not actor.Skills.SelectedSkill:
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()

		await get_tree().create_timer(0.5).timeout
		actor.targeting.PerformAction_CastSelectedSkill()
		actor.Skills.Select(null)
		await get_tree().create_timer(0.5).timeout

	for actor in actors:
		if not actor.Behaviour:
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()

		#var wanderDist = 2
		#var targetPos = actor.global_position + Vector3(randf_range(-wanderDist, wanderDist), 0, randf_range(-wanderDist, wanderDist))
		#var path = actor.targeting.getLegalPathTo(targetPos)
		#actor.actions.IssueOrder_MoveThroughPath(path)
		#await actor.actions.ActionQueue.QueueEmptied

		var skill = actor.Skills.GetByIndex(0)

		var players = Actor.Repository.All.List.filter(func(filtered: Actor) -> bool:
			return filtered.Definition.Alliance == Actor.Alliance.Player
		)
		var chosenTarget = players[randi_range(0, players.size() - 1)]

		actor.Skills.Select(skill)
		create_tween().tween_property(actor.InputProvider, "CursorPosition", chosenTarget.global_position, 1.0)
		await get_tree().create_timer(1.5).timeout
		#actor.targeting.PerformAction_CastSelectedSkill()
		#await get_tree().create_timer(0.5).timeout

	TurnManager.Instance.EndWorldTurn()
