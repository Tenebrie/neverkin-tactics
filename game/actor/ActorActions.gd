extends Component
class_name ActorActions

const StutterStepMovement = 1.0

signal ActionPointsChanged(current: int)
signal MovementPointsChanged(current: float)

var ActionPointsUsed: int = 0

var ActionPointsMax: int:
	get: return parent.definition.ActionPointsMax + ActionPointsTemporary
var ActionPointsTemporary: int = 0
var ActionPointsForNextTurn: int = 0

var ActionPointsAvailable: int:
	get:
		return ActionPointsMax - ActionPointsUsed

var _actionPointsThreatenedFromSkill: int = 0
var ActionPointsThreatened: int:
	get:
		return _actionPointsThreatenedFromSkill + parent.buffs.Count(BuffActionPointThreat)

func AddTemporaryActionPoints(value: int):
	ActionPointsForNextTurn += value

func ConsumeActionPoints(value: int):
	ActionPointsUsed += value
	MovementBuffer = StutterStepMovement
	ActionPointsChanged.emit(ActionPointsAvailable)
	SignalBus.ActionPointsChanged.emit(parent, ActionPointsAvailable)
	SignalBus.ActionPointsConsumedPermanently.emit(parent, value)

func ConsumeActionPointsRefundable(value: int):
	ActionPointsUsed += value
	ActionPointsChanged.emit(ActionPointsAvailable)
	SignalBus.ActionPointsChanged.emit(parent, ActionPointsAvailable)

func RefundActionPoints(value: int):
	while ActionPointsUsed > 0 && value > 0:
		value -= 1
		ActionPointsUsed -= 1
	ActionPointsChanged.emit(ActionPointsAvailable)
	SignalBus.ActionPointsChanged.emit(parent, ActionPointsAvailable)

#region Movement
var MovementSpeedPerAP: float:
	get:
		return parent.movementSpeedPerAction
var MovementBuffer: float = 0.0:
	set(v):
		MovementBuffer = v
		MovementPointsChanged.emit(v)
var MovementAvailable: float:
	get:
		return MovementBuffer + MovementSpeedPerAP * ActionPointsAvailable

func _parentReady() -> void:
	parent.Skills.SelectedSkillChanged.connect(func(skill, previous):
		if skill == previous:
			return

		if not skill or (skill and skill != previous):
			isCastingMode = false
			precastsRemaining = 0
			recastsRemaining = 0
			_actionPointsThreatenedFromSkill = 0
		elif isFreeRecast():
			_actionPointsThreatenedFromSkill = 0
		else:
			_actionPointsThreatenedFromSkill = skill.definition.ActionPointCost

	)
	TurnManager.Instance.FactionTurnStarted.connect(onTurnStarted)
	TurnManager.Instance.FactionTurnEnded.connect(onTurnEnded)

func ConsumeMovement(value: float):
	for i in 50:
		if value <= MovementBuffer:
			MovementBuffer -= value
			return
		MovementBuffer += MovementSpeedPerAP
		ConsumeActionPointsRefundable(1)

		if ActionPointsAvailable < 0:
			MovementBuffer = 0.0
			ActionPointsUsed = ActionPointsMax
			return

func RefundMovement(value: float):
	MovementBuffer += value
	for i in 50:
		if MovementBuffer < MovementSpeedPerAP:
			return
		if ActionPointsUsed == 0:
			return
		MovementBuffer -= MovementSpeedPerAP
		RefundActionPoints(1)

func GetMovementActionPointCost(value: float) -> int:
	return maxi(0, ceil((value - MovementBuffer) / MovementSpeedPerAP))
#endregion

#region ActionQueue
var isCastingMode = false
var precastsRemaining: int = 0
var recastsRemaining: int = 0
var ActionQueue: ActorActionQueue = ActorActionQueue.new()

func isFreeRecast() -> bool:
	return precastsRemaining > 0 or recastsRemaining > 0

func IsPerformingAnyAction() -> bool:
	return ActionQueue.Busy()

#endregion

func onTurnStarted(faction: Actor.Faction) -> void:
	if faction != parent.faction:
		return
	MovementBuffer = StutterStepMovement

func onTurnEnded(faction: Actor.Faction) -> void:
	if faction != parent.faction:
		return
	MovementBuffer = StutterStepMovement
	ActionPointsUsed = 0
	ActionPointsTemporary = ActionPointsForNextTurn
	ActionPointsForNextTurn = 0

#region Orders
func IssueOrder_MoveThroughPath(path: PackedVector3Array):
	var lastPoint := path[path.size() - 1]
	parent.navigator.StartMovingTowards(lastPoint)
	var pathCost = ActorNavigator.GetPathMovementCost(path)
	parent.actions.ConsumeMovement(pathCost)
	ActionQueue.Push("dummy value")
	parent.navigator.agent.target_reached.connect(func():
		ActionQueue.ConsumeFirst(),
	CONNECT_ONE_SHOT)

func _validateSkillCast():
	for telegraph in parent.telegraphs.telegraphs:
		if telegraph.definition.DisabledSelector.call():
			continue

		for validator in telegraph.definition.Validators:
			var result: Variant = validator.call(telegraph)
			if result is bool and result == false:
				return false
			if result is Error:
				MessageLog.PrintErrorObject(result)
				return false
	return true

func IssueOrder_ConfirmCast(skill: Skill, targets: Skill.TargetData):
	if precastsRemaining > 0:
		if not _validateSkillCast():
			return

		await skill.PerformCast(targets)
		precastsRemaining -= 1
		parent.Skills.NotifyRecast()
		return

	if recastsRemaining > 0:
		if not _validateSkillCast():
			return

		recastsRemaining -= 1
		await skill.PerformCast(targets)
		parent.Skills.NotifyRecast()
		return

	var validationResult: Variant = skill.isCastable()
	if not Error.AsBoolean(skill.isCastable()):
		MessageLog.PrintErrorObject(validationResult)
		return

	if not _validateSkillCast():
		return

	if not isCastingMode and skill.getPrecastCount() > 0:
		isCastingMode = true
		precastsRemaining = skill.getPrecastCount()
		await skill.PerformCast(targets)
		precastsRemaining -= 1
		parent.Skills.NotifyRecast()
		return

	recastsRemaining = skill.getRecastCount()

	if skill.HealthCost > 0:
		parent.stats.dealDamage(DamageInstance.ForSkill(skill, skill.HealthCost))
	if skill.ManaCost > 0:
		parent.stats.consumeMana(DamageInstance.ForSkill(skill, skill.ManaCost))
	if skill.ActionPointCost > 0:
		ConsumeActionPoints(skill.ActionPointCost)
	if skill.ChargesRequired > 0:
		skill.consumeCharges(skill.ChargesRequired)
	skill.startCooldown()
	await skill.PerformCast(targets)
	if recastsRemaining > 0:
		parent.Skills.NotifyRecast()
	else:
		isCastingMode = false
		skill.cleanUp.emit()

func IssueOrder_Stop():
	if ActionQueue.Empty():
		return
	ActionQueue.Clear()
	var toRefund = (roundf(parent.navigator.GetRemainingPathLength() * 1000) / 1000)
	RefundMovement(maxf(0.0, toRefund - 0.1))

	parent.navigator.HardStop()

#endregion

class ActorActionQueue:
	signal StepCompleted
	signal QueueEmptied

	var queue: Array[String] = []

	func Empty() -> bool:
		return queue.size() == 0

	func Busy() -> bool:
		return queue.size() > 0

	func Clear() -> void:
		queue.pop_front()

	func Push(action: String) -> void:
		queue.push_back(action)

	func ConsumeFirst() -> void:
		queue.pop_front()
		StepCompleted.emit()
		if queue.size() == 0:
			QueueEmptied.emit()

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal ActionPointsChanged(actor: Actor, current: int)
	signal ActionPointsConsumedPermanently(actor: Actor, value: int)
