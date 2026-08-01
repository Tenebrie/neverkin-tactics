extends Component
class_name ActorCastApproach

const RangeMargin = 0.05
const CircleSampleCount = 48
const ResolveMovementThreshold = 0.0

class Solution:
	var target: Actor
	var castOrigin: Vector3
	var path: PackedVector3Array
	var pathCost: float
	var canCast: bool

@onready var pathPreview: AgentPath = createChild(AgentPath)

var solvedSolution: Solution = null
var solvedSkill: Skill = null
var solvedTarget: Actor = null
var solvedPosition: Vector3
var solvedMovement: float
var showingCursorCost = false

func _parentReady() -> void:
	pathPreview.LineColor = Color(0.0, 1.0, 0.0, 0.8)

var CastOrigin: Vector3:
	get:
		var solution = CurrentSolution()
		if solution:
			return solution.castOrigin
		return parent.global_position

var CastOffset: Vector3:
	get:
		var offset = CastOrigin - parent.global_position
		return Vector3(offset.x, 0.0, offset.z)

func ExecuteApproach() -> bool:
	var solution = CurrentSolution()
	if solution == null or solution.path.size() < 2:
		return true
	await moveAlong(solution.path)
	if not solution.canCast:
		return false
	return ActorUtils.flatDistanceBetween(parent.global_position, solution.castOrigin) < 0.01

func moveAlong(path: PackedVector3Array) -> void:
	parent.telegraphs.Freeze()
	parent.actions.IssueOrder_MoveThroughPath(path)
	await parent.navigator.stopped
	parent.telegraphs.Unfreeze()

func CurrentSolution() -> Solution:
	var skill = parent.Skills.SelectedSkill
	if skill == null or not skill.definition.TargetingApproachTarget:
		return null
	if parent.actions.isFreeRecast():
		return null
	if parent.Behaviour is not ActorBehaviourPlayerControlled:
		return null
	var target = findTarget()
	if target == null:
		return null
	if skill == solvedSkill and target == solvedTarget \
			and parent.global_position.distance_to(solvedPosition) < ResolveMovementThreshold \
			and absf(parent.actions.MovementAvailable - solvedMovement) < 0.001:
		return solvedSolution
	solvedSolution = solve(skill, target)
	solvedSkill = skill
	solvedTarget = target
	solvedPosition = parent.global_position
	solvedMovement = parent.actions.MovementAvailable
	return solvedSolution

func findTarget() -> Actor:
	for target in parent.telegraphs.FilteredOnlyTargets:
		if target != parent:
			return target
	return null

func solve(skill: Skill, target: Actor) -> Solution:
	var mapRid = parent.navigator.agent.get_navigation_map()
	var fullRange = skill.definition.TargetingMaxRange + parent.physicalSize + target.physicalSize
	var castRange = fullRange - RangeMargin
	var acceptRange = fullRange - RangeMargin / 2.0
	var center = ActorUtils.flatPositionOf(target)
	if ActorUtils.flatDistanceBetween(parent.global_position, center) <= fullRange:
		return null

	var best = PackedVector3Array()
	var bestCost = INF

	var idealPoint = center + (ActorUtils.flatPositionOf(parent) - center).normalized() * castRange
	var idealSnapped = NavigationServer3D.map_get_closest_point(mapRid, idealPoint)
	var directPath = NavigationUtils.getPath(mapRid, parent.global_position, idealSnapped)
	var truncated = truncateAtRange(directPath, center, acceptRange)
	if truncated.size() > 1:
		best = truncated
		bestCost = NavigationUtils.getPathLength(truncated)

	for i in CircleSampleCount:
		var angle = TAU * i / CircleSampleCount
		var point = center + Vector3(cos(angle), 0.0, sin(angle)) * castRange
		var snapped = NavigationServer3D.map_get_closest_point(mapRid, point)
		if ActorUtils.flatDistanceBetween(snapped, center) > acceptRange:
			continue
		var path = NavigationUtils.getPath(mapRid, parent.global_position, snapped)
		if path.size() < 2 or ActorUtils.flatDistanceBetween(path[path.size() - 1], snapped) > 0.05:
			continue
		var cost = NavigationUtils.getPathLength(path)
		if cost < bestCost - 0.01:
			bestCost = cost
			best = path

	if best.size() < 2:
		return null

	var solution = Solution.new()
	solution.target = target
	var castBudget = parent.actions.MovementBuffer + parent.actions.MovementSpeedPerAP * maxi(0, parent.actions.ActionPointsAvailable - skill.ActionPointCost)
	if bestCost <= castBudget:
		solution.canCast = true
		solution.path = best
		solution.pathCost = bestCost
		solution.castOrigin = best[best.size() - 1]
	else:
		solution.canCast = false
		solution.path = ActorUtils.limitPathLength(best, castBudget)
		solution.pathCost = ActorNavigator.GetPathMovementCost(solution.path)
		solution.castOrigin = solution.path[solution.path.size() - 1]
	return solution

static func truncateAtRange(path: PackedVector3Array, center: Vector3, castRange: float) -> PackedVector3Array:
	var result = PackedVector3Array()
	for i in path.size():
		if ActorUtils.flatDistanceBetween(path[i], center) > castRange:
			result.append(path[i])
			continue
		if i == 0:
			return PackedVector3Array()
		var outside = path[i - 1]
		var inside = path[i]
		var low = 0.0
		var high = 1.0
		for iteration in 24:
			var mid = (low + high) / 2.0
			if ActorUtils.flatDistanceBetween(outside.lerp(inside, mid), center) <= castRange:
				high = mid
			else:
				low = mid
		result.append(outside.lerp(inside, high))
		return result
	return PackedVector3Array()

func _process(_delta: float) -> void:
	if TurnManager.Instance.activeActor != parent or parent.navigator.IsMoving():
		clearPreview()
		return
	var solution = CurrentSolution()
	if solution == null or solution.path.size() < 2:
		clearPreview()
		return
	pathPreview.SetPath(solution.path, parent.position)
	var apCount = parent.actions.GetMovementActionPointCost(solution.pathCost)
	var shownApCount = mini(apCount, parent.actions.ActionPointsAvailable)
	CombatUI.cursor.ShowActionPointCost(shownApCount, solution.pathCost)
	parent.targeting.PredictedActionPointCost = shownApCount
	showingCursorCost = true

func clearPreview() -> void:
	pathPreview.ClearPath()
	if showingCursorCost:
		CombatUI.cursor.HideActionPointCost()
		parent.targeting.PredictedActionPointCost = 0
		showingCursorCost = false
