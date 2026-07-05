extends Node
class_name BehaviourUtils

const BEAM_HEIGHT: float = 5.0
const BEAM_WIDTH: float = 0.1
const RING_ANGLES: int = 12
const RING_ANGLES_TIGHT: int = 8

const WEIGHT_HAS_SHOT: float = 100.0
const WEIGHT_COVER: float = 60.0
const WEIGHT_RANGE: float = 40.0
const WEIGHT_TARGET_DAMAGE: float = 20.0
const WEIGHT_MOVEMENT_COST_PER_AP: float = 10.0
const WEIGHT_UNSPENT_AP: float = 50.0
const WEIGHT_CLUSTER: float = 25.0
## Penalty per metre the candidate lands short of any attack skill's range against the focus target.
## Creates a directional gradient toward the enemy when no shot is possible from this candidate.
const WEIGHT_CHASE_PER_METER: float = 15.0
const PENALTY_UNREACHABLE: float = -INF

## Distance (m) inside which allies who have already acted this turn contribute a cluster penalty.
const CLUSTER_RADIUS: float = 3.0

const RANGE_FOCUS_MULT: float = 3.0
## Safety margin (m) shaved off max-range calculations so the AI never plans a shot that fails
## the runtime range validator by float precision.
const RANGE_SAFETY_MARGIN: float = 0.1

const COVER_SCORE_LOW: float = 0.4
const COVER_SCORE_HIGH: float = 0.7
const COVER_SCORE_FULL: float = 1.0

const COVER_AVG_WEIGHT: float = 0.5
const COVER_WORST_WEIGHT: float = 0.5

class Plan:
	var destination: Vector3
	var path: PackedVector3Array
	var apMoveCost: int
	var chosenSkill: Skill
	var target: Actor
	var castPoint: Vector3
	var score: float = -INF

	func Describe() -> String:
		var skillName = chosenSkill.Definition.Name if chosenSkill else "<none>"
		var targetName = target.Definition.Name if target else "<none>"
		return "score=%0.1f dest=%s ap=%d skill=%s target=%s" % [
			score, destination, apMoveCost, skillName, targetName
		]

## Build a plan for an NPC on its turn.
static func PlanTurn(actor: Actor) -> Plan:
	var behaviour = actor.Behaviour as ActorBehaviourWorldControlled
	var allEnemies = findEnemies(actor)
	var candidates = sampleCandidates(actor)

	var best = Plan.new()
	best.destination = actor.global_position

	var focusEnemies: Array[Actor]
	if behaviour.FocusedTarget:
		focusEnemies.push_back(behaviour.FocusedTarget)
	for candidate in candidates:
		var evaluated = evaluateCandidate(actor, behaviour, candidate, focusEnemies, allEnemies)
		if evaluated.score > best.score:
			best = evaluated

	return best

#region Candidate sampling
static func sampleCandidates(actor: Actor) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var origin = actor.global_position
	out.push_back(origin)

	var maxMove: float = actor.actions.MovementAvailable
	if maxMove <= 0.01:
		return out

	var rings: Array[float] = []
	var step: float = 1.5
	var d: float = step
	while d <= maxMove + 0.01:
		rings.push_back(d)
		d += step
	if rings.is_empty() or rings[rings.size() - 1] < maxMove - 0.5:
		rings.push_back(maxMove)

	for radius in rings:
		var samples = RING_ANGLES_TIGHT if radius < step * 1.5 else RING_ANGLES
		for i in samples:
			var angle: float = TAU * float(i) / float(samples)
			var pos = origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			out.push_back(pos)

	return out
#endregion

#region Candidate evaluation
static func evaluateCandidate(
	actor: Actor,
	behaviour: ActorBehaviourWorldControlled,
	candidate: Vector3,
	focusEnemies: Array[Actor],
	allEnemies: Array[Actor]
) -> Plan:
	var plan = Plan.new()
	plan.destination = candidate

	var path = actor.targeting.getLegalPathTo(candidate)
	if path.size() == 0:
		plan.score = PENALTY_UNREACHABLE
		return plan

	var reachedPos: Vector3 = path[path.size() - 1]
	plan.destination = reachedPos
	plan.path = path

	var pathCost = ActorNavigator.GetPathMovementCost(path)
	plan.apMoveCost = actor.actions.GetMovementActionPointCost(pathCost)

	var affordableSkills: Array[Skill] = []
	for skill in gatherAttackSkills(actor):
		if canAffordAttack(actor, skill, plan.apMoveCost):
			affordableSkills.push_back(skill)

	var bestTarget: Actor = null
	var bestSkill: Skill = null
	var bestTargetScore = -INF
	var attackScore = 0.0

	for skill in affordableSkills:
		for enemy in focusEnemies:
			if not is_instance_valid(enemy) or enemy.Stats.HealthCurrent <= 0:
				continue
			if not hasShot(actor, reachedPos, enemy, skill):
				continue
			var targetScore = scoreTarget(reachedPos, enemy, skill)
			if targetScore > bestTargetScore:
				bestTargetScore = targetScore
				bestTarget = enemy
				bestSkill = skill

	if bestTarget:
		attackScore = WEIGHT_HAS_SHOT * behaviour.WeightHasShot + bestTargetScore * WEIGHT_TARGET_DAMAGE * behaviour.WeightTargetDamage
		plan.chosenSkill = bestSkill
		plan.target = bestTarget
		plan.castPoint = computeCastPoint(actor, reachedPos, bestTarget, bestSkill)

	var coverScore = scoreCover(actor, reachedPos, allEnemies)
	var rangeScore = scoreRange(reachedPos, focusEnemies, allEnemies, behaviour.PreferredRange, behaviour.PreferredRangeTolerance)
	var clusterPenalty = scoreCluster(actor, reachedPos) * WEIGHT_CLUSTER * behaviour.WeightCluster
	var apPenalty = float(plan.apMoveCost) * WEIGHT_MOVEMENT_COST_PER_AP * behaviour.WeightMovementCostPerAp
	var skillApCost: int = plan.chosenSkill.ActionPointCost if plan.chosenSkill else 0
	var apUnspent: int = maxi(0, actor.actions.ActionPointsAvailable - plan.apMoveCost - skillApCost)
	var unspentPenalty = float(apUnspent) * WEIGHT_UNSPENT_AP * behaviour.WeightUnspentAp
	var reachPenalty = 0.0

	if bestTarget == null and focusEnemies.size() > 0:
		var maxRange: float = 0.0
		for skill in gatherAttackSkills(actor):
			maxRange = maxf(maxRange, skill.Definition.TargetingMaxRange)
		var closestDist: float = INF
		for enemy in focusEnemies:
			if not is_instance_valid(enemy) or enemy.Stats.HealthCurrent <= 0:
				continue
			closestDist = minf(closestDist, reachedPos.distance_to(enemy.global_position))
		if closestDist != INF:
			var shortfall: float = maxf(0.0, closestDist - maxRange)
			reachPenalty = shortfall * WEIGHT_CHASE_PER_METER * behaviour.WeightChasePerMeter

	plan.score = attackScore + coverScore * WEIGHT_COVER * behaviour.WeightCover + rangeScore * WEIGHT_RANGE * behaviour.WeightRange - apPenalty - reachPenalty - unspentPenalty - clusterPenalty
	return plan

## Largest circular blast radius across the skill's damage telegraphs. 0 if none.
static func getSkillAoERadius(skill: Skill) -> float:
	var radius: float = 0.0
	for telegraph in skill.Definition.Telegraphs:
		if telegraph.HealthThreat <= 0:
			continue
		if telegraph.Shape == Telegraph.Shape.Circle:
			radius = maxf(radius, telegraph.CircleRadius)
	return radius

## Where the NPC will aim the cursor. For direct-target skills this is the target.
## For ground-targeted skills (grenades), clamps to the skill's maximum cast range along
## the line to the target so the throw succeeds and the blast still catches the enemy.
static func computeCastPoint(actor: Actor, from: Vector3, target: Actor, skill: Skill) -> Vector3:
	if not skill.Definition.BehaviourTargetsGround:
		return target.global_position
	var flatFrom = Vector3(from.x, 0.0, from.z)
	var flatTarget = Vector3(target.global_position.x, 0.0, target.global_position.z)
	var distance = flatFrom.distance_to(flatTarget)
	var maxCastDistance = skill.Definition.TargetingMaxRange + actor.PhysicalSize - RANGE_SAFETY_MARGIN
	if distance <= maxCastDistance or distance < 0.0001:
		return target.global_position
	var direction = (flatTarget - flatFrom).normalized()
	var clamped = flatFrom + direction * maxCastDistance
	clamped.y = target.global_position.y
	return clamped

static func gatherAttackSkills(actor: Actor) -> Array[Skill]:
	var out: Array[Skill] = []
	for i in 16:
		var skill = actor.Skills.GetByIndex(i)
		if skill == null:
			continue
		var hasDamage: bool = skill.Definition.Telegraphs.any(func(t): return t.HealthThreat > 0)
		if hasDamage:
			out.push_back(skill)
	return out

static func canAffordAttack(actor: Actor, skill: Skill, apMoveCost: int) -> bool:
	return actor.actions.ActionPointsAvailable - apMoveCost >= skill.ActionPointCost

static func scoreTarget(from: Vector3, enemy: Actor, skill: Skill) -> float:
	var damage: int = 0
	for telegraph in skill.Definition.Telegraphs:
		damage = maxi(damage, telegraph.HealthThreatSelector.call(enemy))
	var maxHp: int = enemy.Definition.HealthMaximum
	var currentHp: int = enemy.Stats.HealthCurrent
	var lethalBonus: float = 2.0 if damage >= currentHp else 0.0
	var lowHealthBonus: float = 1.0 - clampf(float(currentHp) / float(maxi(maxHp, 1)), 0.0, 1.0)
	var distance: float = from.distance_to(enemy.global_position)
	var skillRange: float = maxf(skill.Definition.TargetingMaxRange, 0.01)
	var proximityBonus: float = 1.0 - clampf(distance / skillRange, 0.0, 1.0)
	var threatBonus: float = enemy.Stats.ThreatCurrent - 1.0
	return float(damage) * 0.6 + lethalBonus + lowHealthBonus + proximityBonus * 0.4 + threatBonus
#endregion

#region Physics: shot & cover checks
static func hasShot(actor: Actor, from: Vector3, target: Actor, skill: Skill) -> bool:
	var maxRange: float = skill.Definition.TargetingMaxRange
	var flatFrom = Vector3(from.x, 0.0, from.z)
	var flatTarget = Vector3(target.global_position.x, 0.0, target.global_position.z)
	var distance: float = flatFrom.distance_to(flatTarget)
	var effectiveRange: float
	if skill.Definition.BehaviourTargetsGround:
		effectiveRange = maxRange + actor.PhysicalSize + getSkillAoERadius(skill)
	else:
		effectiveRange = maxRange + actor.PhysicalSize + target.PhysicalSize
	if distance > effectiveRange - RANGE_SAFETY_MARGIN:
		return false

	if not skill.Definition.BehaviourRequireLineOfSight:
		return true

	var world = actor.get_world_3d()
	if world == null:
		return false
	var space = world.direct_space_state

	var direction: Vector3 = (flatTarget - flatFrom)
	if direction.length_squared() < 0.0001:
		return true
	direction = direction.normalized()

	var basis = Basis.looking_at(direction, Vector3.UP)
	var beamOrigin = Vector3(flatFrom.x, BEAM_HEIGHT / 2.0, flatFrom.z)
	var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.ACTOR
	var initialExclude: Array[RID] = [actor.get_rid()]
	initialExclude.append_array(ignoredWallRidsAt(snapToNavMesh(actor, from), actor.PhysicalSize))

	var contacts = RaycastUtils.GatherBeamContacts(
		space, Vector2(BEAM_WIDTH, BEAM_HEIGHT), basis, beamOrigin, direction,
		distance, mask, initialExclude,
	)

	for contact in contacts:
		var collider = contact.Collider
		if collider == target:
			return true
		if collider.collision_layer & CollisionLayer.IGNORED_COVER != 0:
			continue
		return false

	return false

static func scoreRange(
	candidate: Vector3,
	focusEnemies: Array[Actor],
	allEnemies: Array[Actor],
	preferredRange: float,
	tolerance: float
) -> float:
	if preferredRange <= 0.0 or tolerance <= 0.0:
		return 0.0
	var weightedFit: float = 0.0
	var totalWeight: float = 0.0
	for enemy in allEnemies:
		if not is_instance_valid(enemy) or enemy.Stats.HealthCurrent <= 0:
			continue
		var distance: float = candidate.distance_to(enemy.global_position)
		var deviation: float = (distance - preferredRange) / tolerance
		var fit: float = exp(-deviation * deviation)
		var weight: float = maxf(enemy.Stats.ThreatCurrent, 0.01)
		if focusEnemies.has(enemy):
			weight *= RANGE_FOCUS_MULT
		weightedFit += fit * weight
		totalWeight += weight
	if totalWeight <= 0.0:
		return 0.0
	return weightedFit / totalWeight

## Sums a linear falloff penalty for each same-faction ally that has already spent AP this turn
## and is within CLUSTER_RADIUS of the candidate. Encourages spreading out to reduce AoE risk.
static func scoreCluster(actor: Actor, candidate: Vector3) -> float:
	var total: float = 0.0
	for other in Actor.Repository.All.List:
		if other == actor:
			continue
		if not other.IsAlive:
			continue
		if other.Definition.Alliance != actor.Definition.Alliance:
			continue
		if other.actions.ActionPointsUsed == 0:
			continue
		var distance: float = candidate.distance_to(other.global_position)
		if distance >= CLUSTER_RADIUS:
			continue
		total += 1.0 - distance / CLUSTER_RADIUS
	return total

static func scoreCover(actor: Actor, candidate: Vector3, enemies: Array[Actor]) -> float:
	if enemies.is_empty():
		return 0.0
	var world = actor.get_world_3d()
	if world == null:
		return 0.0
	var space = world.direct_space_state

	var weightedCover: float = 0.0
	var threatSum: float = 0.0
	var maxThreat: float = 0.0
	var maxDanger: float = 0.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.Stats.HealthCurrent <= 0:
			continue

		var flatEnemy = Vector3(enemy.global_position.x, 0.0, enemy.global_position.z)
		var flatCandidate = Vector3(candidate.x, 0.0, candidate.z)
		var direction: Vector3 = flatCandidate - flatEnemy
		var distance: float = direction.length()
		if distance < 0.01:
			continue
		direction = direction.normalized()

		var basis = Basis.looking_at(direction, Vector3.UP)
		var beamOrigin = Vector3(flatEnemy.x, BEAM_HEIGHT / 2.0, flatEnemy.z)
		var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.ACTOR
		var initialExclude: Array[RID] = [enemy.get_rid(), actor.get_rid()]
		initialExclude.append_array(ignoredWallRidsAt(enemy.global_position, enemy.PhysicalSize))

		var contacts = RaycastUtils.GatherBeamContacts(
			space, Vector2(BEAM_WIDTH, BEAM_HEIGHT), basis, beamOrigin, direction,
			distance, mask, initialExclude,
		)

		var blockerLayer: int = 0
		for contact in contacts:
			var collider = contact.Collider
			if collider.collision_layer & CollisionLayer.IGNORED_COVER != 0:
				continue
			blockerLayer = collider.collision_layer
			break

		var coverValue: float = 0.0
		if blockerLayer & CollisionLayer.FULL_COVER != 0:
			coverValue = COVER_SCORE_FULL
		elif blockerLayer & CollisionLayer.HIGH_COVER != 0:
			coverValue = COVER_SCORE_HIGH
		elif blockerLayer & CollisionLayer.LOW_COVER != 0:
			coverValue = COVER_SCORE_LOW

		var threat: float = maxf(enemy.Stats.ThreatCurrent, 0.01)
		weightedCover += coverValue * threat
		threatSum += threat
		maxThreat = maxf(maxThreat, threat)
		maxDanger = maxf(maxDanger, threat * (1.0 - coverValue))

	if threatSum <= 0.0:
		return 0.0
	var weightedAvg: float = weightedCover / threatSum
	var worstCover: float = 1.0 - maxDanger / maxThreat
	return COVER_AVG_WEIGHT * weightedAvg + COVER_WORST_WEIGHT * worstCover

## Emulate PropWall.IsIgnoredFor at an arbitrary position and expand it into
## RIDs. If any segment of a wall is within (physicalSize * 2) of `at`, the
## whole wall's segments are excluded (matching how ApplyCollisionRules ignores
## by obstaclegroup_ group name).
static func ignoredWallRidsAt(at: Vector3, physicalSize: float) -> Array[RID]:
	var out: Array[RID] = []
	var threshold: float = pow(physicalSize * 2.0, 2)
	for wall in PropWall.Repository.List:
		if not wall.CanBeIgnored:
			continue
		var wallIsClose: bool = false
		for segment in wall.get_children():
			if segment is not Node3D:
				continue
			if segment.global_position.distance_squared_to(at) < threshold:
				wallIsClose = true
				break
		if not wallIsClose:
			continue
		for segment in wall.get_children():
			if segment is CollisionObject3D:
				out.push_back((segment as CollisionObject3D).get_rid())
	return out
#endregion

#region Helpers
## Snap a planned position onto the nav mesh the same way ActorNavigator.StartMovingTowards does,
## so plan-time cover ignore calculations match the position the actor will actually settle at.
static func snapToNavMesh(actor: Actor, position: Vector3) -> Vector3:
	var flat = Vector3(position.x, 0.0, position.z)
	var map = actor.navigator.agent.get_navigation_map()
	return NavigationServer3D.map_get_closest_point(map, flat)

static func findEnemies(actor: Actor) -> Array[Actor]:
	var result: Array[Actor] = []
	for other in Actor.Repository.All.List:
		if other == actor:
			continue
		if not ActorUtils.IsHostileTo(other, actor):
			continue
		if not other.IsAlive:
			continue
		result.push_back(other)
	return result
#endregion
