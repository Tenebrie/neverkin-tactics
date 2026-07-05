extends Node
class_name NPCManager

const FACE_TARGET_TIME: float = 0.4
const POST_ACTION_PAUSE: float = 0.5

func _ready() -> void:
	TurnManager.Instance.FactionTurnStarted.connect(func(faction):
		if faction != Actor.Alliance.Player:
			performFactionTurn(faction)
		else:
			performPlayerTurnStart()
	)

func performPlayerTurnStart():
	var npcActors = Actor.Repository.All.List.filter(func(actor):
		return actor.Stats.Alliance != Actor.Alliance.Player
	)
	#for actor in npcActors:
		#if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
			#behaviour.UpdateFocusedTarget()

func performFactionTurn(faction: Actor.Alliance):
	var actors = Actor.Repository.All.List.filter(func(actor):
		return actor.Definition.Alliance == faction and actor.Behaviour
	)

	await resolveQueuedAttacks(actors)

	for actor in actors:
		if not is_instance_valid(actor):
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await takeTurn(actor)

	TurnManager.Instance.EndWorldTurn()

func resolveQueuedAttacks(actors: Array[Actor]) -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.Skills.SelectedSkill:
			continue
		TurnManager.Instance.SelectNonPlayableActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout
		actor.targeting.PerformAction_CastSelectedSkill()
		actor.Skills.Unselect()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout

func takeTurn(actor: Actor) -> void:
	for step in 4:
		if actor.actions.ActionPointsAvailable <= 0:
			break
		var plan = BehaviourUtils.PlanTurn(actor)
		MessageLog.PrintChatMessage("[AI:instant] %s -> %s" % [actor.Definition.Name, plan.Describe()])
		var didAct = await executePlan(actor, plan)
		if not didAct:
			break

func executePlan(actor: Actor, plan: BehaviourUtils.Plan) -> bool:
	var moved = false
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

		## Delayed skill will get resolved next turn
		## TODO: Prepay the AP cost
		#if plan.chosenSkill.Definition.TargetingResolvesNextTurn:
			#return true

		actor.targeting.PerformAction_CastSelectedSkill()
		actor.Skills.Unselect()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout
		return true

	return moved
