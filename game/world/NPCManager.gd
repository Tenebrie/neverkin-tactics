extends Node
class_name NPCManager

## Toggle between two AI regimes:
##  Instant  — enemy moves and fires within its own turn.
##  Delayed  — enemy queues a shot via Skills.Select this turn (telegraph stays
##             visible so the player can react) and it resolves at the start of
##             the enemy's next turn.
const MODE: EnemyBrain.Mode = EnemyBrain.Mode.Instant

const FACE_TARGET_TIME: float = 0.4
const POST_ACTION_PAUSE: float = 0.3

func _ready() -> void:
	TurnManager.Instance.FactionTurnStarted.connect(func(faction):
		if faction != Actor.Alliance.Player:
			playAsFaction(faction)
	)

func playAsFaction(faction: Actor.Alliance):
	var actors = Actor.Repository.All.List.filter(func(actor):
		return actor.Definition.Alliance == faction and actor.Behaviour
	)

	if MODE == EnemyBrain.Mode.Delayed:
		await resolveQueuedAttacks(actors)

	for actor in actors:
		if not is_instance_valid(actor):
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout

		await takeTurn(actor)

	TurnManager.Instance.EndWorldTurn()

## Delayed mode Phase 1: any NPC that carried a SelectedSkill from last turn
## fires it now, spending fresh-turn AP. Matches the original NPCManager
## sequence — the telegraph seen by the player during their turn is what
## actually resolves.
func resolveQueuedAttacks(actors: Array) -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.Skills.SelectedSkill:
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout
		actor.targeting.PerformAction_CastSelectedSkill()
		actor.Skills.Select(null)
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout

func takeTurn(actor: Actor) -> void:
	if MODE == EnemyBrain.Mode.Instant:
		for step in 4:
			if actor.actions.ActionPointsAvailable <= 0:
				break
			var plan := EnemyBrain.PlanTurn(actor, EnemyBrain.Mode.Instant)
			MessageLog.PrintMessage("[AI:instant] %s -> %s" % [actor.Definition.Name, plan.Describe()])
			var didAct := await executePlan(actor, plan)
			if not didAct:
				break
	else:
		var plan := EnemyBrain.PlanTurn(actor, EnemyBrain.Mode.Delayed)
		MessageLog.PrintMessage("[AI:delayed] %s -> %s" % [actor.Definition.Name, plan.Describe()])
		await executePlan(actor, plan)

func executePlan(actor: Actor, plan: EnemyBrain.Plan) -> bool:
	var moved: bool = false
	if plan.path.size() > 1 and plan.apMoveCost > 0:
		actor.actions.IssueOrder_MoveThroughPath(plan.path)
		await actor.actions.ActionQueue.QueueEmptied
		moved = true

	if plan.chosenSkill and plan.target and is_instance_valid(plan.target):
		actor.Skills.Select(plan.chosenSkill)
		create_tween().tween_property(
			actor.InputProvider,
			"CursorPosition",
			plan.target.global_position,
			FACE_TARGET_TIME
		)
		await get_tree().create_timer(FACE_TARGET_TIME + 0.2).timeout

		if MODE == EnemyBrain.Mode.Instant:
			actor.targeting.PerformAction_CastSelectedSkill()
			actor.Skills.Select(null)
			await get_tree().create_timer(POST_ACTION_PAUSE).timeout
		# Delayed: leave the skill selected and the telegraph in place. It will
		# resolve at the start of this actor's next turn via resolveQueuedAttacks.
		return true

	return moved
