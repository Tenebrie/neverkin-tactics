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
	pass
	#var npcActors = Actor.Repository.All.List.filter(func(actor):
		#return actor.Stats.Alliance != Actor.Alliance.Player
	#)
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
	var behaviour = actor.Behaviour as ActorBehaviourWorldControlled
	for step in 4:
		if actor.actions.ActionPointsAvailable <= 0:
			break
		var start = Time.get_ticks_usec()
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

func executeMoveToAction(actor: Actor, params: ActorBehaviour.TurnAction.MoveToParams):
	var path = ActorUtils.GetPathTo(actor, params.point)
	actor.actions.IssueOrder_MoveThroughPath(path)
	await actor.actions.ActionQueue.QueueEmptied

func executeUseSkillAction(actor: Actor, params: ActorBehaviour.TurnAction.UseSkillParams):
	var skill = actor.Skills.Get(params.skill)
	if not skill:
		printerr("Actor %s does not have skill %s"%[actor, params.skill])
		return
	actor.Skills.Select(skill)
	MessageLog.PrintActorMessage(skill.Definition.Name, actor)
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
