extends Node
class_name NPCManager

const FACE_TARGET_TIME: float = 0.6
const POST_ACTION_PAUSE: float = 0.25

func _ready() -> void:
	TurnManager.Instance.FactionTurnStarted.connect(func(faction):
		if faction != Actor.PlayerFaction:
			performFactionTurn(faction)
		else:
			performPlayerTurnStart()
	)

func performPlayerTurnStart():
	pass

func performFactionTurn(faction: Actor.Faction):
	var factionActors = Actor.Repository.Alive.List.filter(func(actor):
		return actor.faction == faction and actor.Behaviour
	)
	factionActors.sort_custom(func(a, b):
		return a.initiative > b.initiative
	)

	await resolveQueuedAttacks(factionActors)

	for actor in factionActors:
		if not is_instance_valid(actor):
			continue
		TurnManager.Instance.activateWorldActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await takeTurn(actor)

	TurnManager.Instance.endWorldTurn()

func resolveQueuedAttacks(actors: Array[Actor]) -> void:
	for actor in actors:
		if not is_instance_valid(actor) or not actor.Skills.SelectedSkill:
			continue
		TurnManager.Instance.activateWorldActor(actor)
		await NavmeshManager.Instance.WaitUntilReady()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout
		actor.targeting.PerformAction_CastSelectedSkill()
		actor.Skills.Unselect()
		await get_tree().create_timer(POST_ACTION_PAUSE).timeout

func takeTurn(actor: Actor) -> void:
	var behaviour = actor.Behaviour as ActorBehaviourWorldControlled
	for step in 4:
		if actor.actions.ActionPointsAvailable <= 0:
			break
		behaviour.updateRanking()
		var start = Time.get_ticks_usec()
		@warning_ignore("redundant_await")
		var plan = await behaviour.PlanTurnActions()
		var elapsed = Time.get_ticks_usec() - start
		print("AI planning phase took %.2f ms" % [elapsed / 1000.0])
		for action in plan:
			if actor.actions.ActionPointsAvailable <= 0:
				return
			await executeAction(actor, action)
			await get_tree().create_timer(POST_ACTION_PAUSE).timeout
			if action.variant == ActorBehaviour.ActionVariant.EndTurn:
				return

func executeAction(actor: Actor, action: ActorBehaviour.TurnAction):
	match(action.variant):
		ActorBehaviour.ActionVariant.Skip: await executeSkipAction(actor)
		ActorBehaviour.ActionVariant.MoveTo: await executeMoveToAction(actor, action.moveToParams)
		ActorBehaviour.ActionVariant.UseSkill: await executeUseSkillAction(actor, action.useSkillParams)
		ActorBehaviour.ActionVariant.EndTurn: await executeEndTurnAction(actor)
		_: printerr("Unsupported action %s"%action)

func executeSkipAction(actor: Actor):
	MessageLog.PrintActorMessage("Waiting...", actor)
	actor.actions.ConsumeActionPoints(1)

func executeMoveToAction(actor: Actor, params: ActorBehaviour.TurnAction.MoveToParams):
	var path = ActorUtils.getPathTo(actor, params.point)
	actor.actions.IssueOrder_MoveThroughPath(path)
	await actor.actions.ActionQueue.QueueEmptied

func executeUseSkillAction(actor: Actor, params: ActorBehaviour.TurnAction.UseSkillParams):
	var skill = actor.Skills.Get(params.skill)
	if not skill:
		printerr("Actor %s does not have skill %s"%[actor, params.skill])
		return
	actor.Skills.Select(skill)
	actor.InputProvider.CursorPosition = params.targetPoint
	await get_tree().create_timer(FACE_TARGET_TIME).timeout

	## Delayed skill will get resolved next turn
	## TODO: Prepay the AP cost
	#if plan.chosenSkill.Definition.TargetingResolvesNextTurn:
		#return true

	actor.targeting.PerformAction_CastSelectedSkill()
	actor.Skills.Unselect()
	await get_tree().create_timer(POST_ACTION_PAUSE).timeout
	return true

func executeEndTurnAction(actor: Actor):
	MessageLog.PrintActorMessage("End turn", actor)
	actor.actions.ConsumeActionPoints(100)
	await get_tree().create_timer(FACE_TARGET_TIME).timeout
