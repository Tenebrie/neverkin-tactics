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
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()

		var targetPos = actor.global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		var path = actor.targeting.getLegalPathTo(targetPos)
		actor.actions.IssueOrder_MoveThroughPath(path)
		await actor.actions.ActionQueue.QueueEmptied

	TurnManager.Instance.EndWorldTurn()
