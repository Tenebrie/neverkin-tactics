extends Node
class_name EnemyBrain

## Utility-AI POC. Given an actor, samples candidate positions in a ring around it,
## scores each on (a) whether an enemy can be shot from there, (b) how much cover
## the position offers against enemy fire, (c) AP efficiency. Returns the best
## Plan (destination path + selected skill + intended target).
##
## Two firing modes (see NPCManager for the toggle):
## - Instant: enemy fires this turn, so movement + attack must fit in current AP.
## - Delayed: enemy queues the skill via Skills.Select and it resolves at the
##   start of their next turn. Movement uses this turn's AP; the queued attack
##   uses next turn's AP. Preferred double-shot is chosen when we can afford to
##   stay put and have 2 AP.
enum Mode { Instant, Delayed }

## Beam volume matches TelegraphProcessor.ApplyCollisionRules: a tall thin box swept
## along the shot direction so both low props (~0.5m tall) and taller cover are
## intersected uniformly.
const BEAM_HEIGHT: float = 5.0
const BEAM_WIDTH: float = 0.1
const RING_ANGLES: int = 12
const RING_ANGLES_TIGHT: int = 8

const WEIGHT_HAS_SHOT: float = 100.0
const WEIGHT_COVER: float = 60.0
const WEIGHT_TARGET_DAMAGE: float = 20.0
const WEIGHT_AP_COST: float = 5.0
const PENALTY_NO_TARGET_IN_RANGE: float = 25.0
const PENALTY_UNREACHABLE: float = -INF

const COVER_SCORE_LOW: float = 0.4
const COVER_SCORE_HIGH: float = 0.7
const COVER_SCORE_FULL: float = 1.0

class Plan:
	var destination: Vector3
	var path: PackedVector3Array
	var apMoveCost: int
	var chosenSkill: Skill
	var target: Actor
	var score: float = -INF

	func Describe() -> String:
		var skillName = chosenSkill.Definition.Name if chosenSkill else "<none>"
		var targetName = target.Definition.Name if target else "<none>"
		return "score=%0.1f dest=%s ap=%d skill=%s target=%s" % [
			score, destination, apMoveCost, skillName, targetName
		]

## Build a plan for an NPC on its turn.
static func PlanTurn(actor: Actor, mode: Mode = Mode.Instant) -> Plan:
	var enemies := _findEnemies(actor)
	var candidates := _sampleCandidates(actor)

	var best := Plan.new()
	best.destination = actor.global_position

	for candidate in candidates:
		var evaluated := _evaluateCandidate(actor, candidate, enemies, mode)
		if evaluated.score > best.score:
			best = evaluated

	return best

#region Candidate sampling
static func _sampleCandidates(actor: Actor) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var origin := actor.global_position
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
		var samples := RING_ANGLES_TIGHT if radius < step * 1.5 else RING_ANGLES
		for i in samples:
			var angle: float = TAU * float(i) / float(samples)
			var pos := origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			out.push_back(pos)

	return out
#endregion

#region Candidate evaluation
static func _evaluateCandidate(
	actor: Actor,
	candidate: Vector3,
	enemies: Array[Actor],
	mode: Mode,
) -> Plan:
	var plan := Plan.new()
	plan.destination = candidate

	var path := actor.targeting.getLegalPathTo(candidate)
	if path.size() == 0:
		plan.score = PENALTY_UNREACHABLE
		return plan

	var reachedPos: Vector3 = path[path.size() - 1]
	plan.destination = reachedPos
	plan.path = path

	var pathCost := ActorNavigator.GetPathMovementCost(path)
	plan.apMoveCost = actor.actions.GetMovementActionPointCost(pathCost)

	var wouldMove: bool = plan.apMoveCost > 0
	var skill := _pickAttackSkill(actor, wouldMove, mode)

	var canAttack: bool = skill != null and _canAffordAttack(actor, skill, plan.apMoveCost, mode)

	var bestTarget: Actor = null
	var bestTargetScore: float = -INF
	var attackScore: float = 0.0

	if canAttack:
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.stats.HealthCurrent <= 0:
				continue
			if not _hasShot(actor, reachedPos, enemy, skill):
				continue
			var targetScore := _scoreTarget(actor, reachedPos, enemy, skill)
			if targetScore > bestTargetScore:
				bestTargetScore = targetScore
				bestTarget = enemy

		if bestTarget:
			attackScore = WEIGHT_HAS_SHOT + bestTargetScore * WEIGHT_TARGET_DAMAGE
			plan.chosenSkill = skill
			plan.target = bestTarget

	var coverScore: float = _scoreCover(actor, reachedPos, enemies)
	var apPenalty: float = float(plan.apMoveCost) * WEIGHT_AP_COST
	var reachPenalty: float = 0.0

	if not canAttack or bestTarget == null:
		var enemyReachable := enemies.any(func(e: Actor) -> bool:
			return skill != null and reachedPos.distance_to(e.global_position) <= skill.Definition.TargetingMaxRange
		)
		if not enemyReachable:
			reachPenalty = PENALTY_NO_TARGET_IN_RANGE

	plan.score = attackScore + coverScore * WEIGHT_COVER - apPenalty - reachPenalty
	return plan

## In Delayed mode the queued skill fires on the next turn's AP budget, so a
## stationary Godette (2 max AP + 1 saved carry-over) can afford the 2-AP
## double-shot. Any planned movement forfeits that: fall back to the single-shot.
static func _pickAttackSkill(actor: Actor, wouldMove: bool, mode: Mode) -> Skill:
	if mode == Mode.Delayed and not wouldMove and actor.actions.ActionPointsAvailable >= 2:
		var double := actor.Skills.Get(SkillPistolShotDouble)
		if double != null:
			return double
	return _pickPrimaryAttackSkill(actor)

## Instant needs AP now for both move + cast. Delayed only needs enough AP
## next turn to fire the queued skill (base + saved carry-over).
static func _canAffordAttack(actor: Actor, skill: Skill, apMoveCost: int, mode: Mode) -> bool:
	if mode == Mode.Instant:
		return actor.actions.ActionPointsAvailable - apMoveCost >= skill.ActionPointCost
	var apUsedThisTurn: int = actor.actions.ActionPointsUsed + apMoveCost
	var willSave: int = 1 if apUsedThisTurn < actor.actions.ActionPointsMax else 0
	var nextTurnAp: int = actor.Definition.ActionPointsMax + willSave
	return nextTurnAp >= skill.ActionPointCost

static func _scoreTarget(actor: Actor, from: Vector3, enemy: Actor, skill: Skill) -> float:
	var damage: int = 0
	for tel in skill.Definition.Telegraphs:
		damage = maxi(damage, tel.HealthThreat)
	var maxHp: int = enemy.Definition.HealthMaximum
	var currentHp: int = enemy.stats.HealthCurrent
	var lethalBonus: float = 2.0 if damage >= currentHp else 0.0
	var lowHealthBonus: float = 1.0 - clampf(float(currentHp) / float(maxi(maxHp, 1)), 0.0, 1.0)
	var distance: float = from.distance_to(enemy.global_position)
	var skillRange: float = maxf(skill.Definition.TargetingMaxRange, 0.01)
	var proximityBonus: float = 1.0 - clampf(distance / skillRange, 0.0, 1.0)
	return float(damage) * 0.6 + lethalBonus + lowHealthBonus + proximityBonus * 0.4
#endregion

#region Physics: shot & cover checks
## Would `actor`, if standing at `from`, land the shot on `target` with `skill`?
## Mirrors TelegraphProcessor.ApplyCollisionRules with piercing/penetration=0:
## walks the sorted beam contacts and any actor/cover in the way blocks. Walls
## whose PropWall would be ignored from `from` are excluded (shoot-from-cover).
static func _hasShot(actor: Actor, from: Vector3, target: Actor, skill: Skill) -> bool:
	var maxRange: float = skill.Definition.TargetingMaxRange
	var flatFrom := Vector3(from.x, 0.0, from.z)
	var flatTarget := Vector3(target.global_position.x, 0.0, target.global_position.z)
	var distance: float = flatFrom.distance_to(flatTarget)
	if distance > maxRange + actor.PhysicalSize + target.PhysicalSize:
		return false

	var world = actor.get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state

	var direction: Vector3 = (flatTarget - flatFrom)
	if direction.length_squared() < 0.0001:
		return true
	direction = direction.normalized()

	var basis := Basis.looking_at(direction, Vector3.UP)
	var beamOrigin := Vector3(flatFrom.x, BEAM_HEIGHT / 2.0, flatFrom.z)
	var mask := CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.ACTOR
	var initialExclude: Array[RID] = [actor.get_rid()]
	initialExclude.append_array(_ignoredWallRidsAt(from, actor.PhysicalSize))

	var contacts := RaycastUtils.GatherBeamContacts(
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

## For each enemy, would the enemy have a clean shot at `candidate` (with a
## shot-shaped beam from enemy → candidate)? If blocked, we're in cover; the
## blocker's cover type sets the score. Averaged over enemies.
static func _scoreCover(actor: Actor, candidate: Vector3, enemies: Array[Actor]) -> float:
	if enemies.is_empty():
		return 0.0
	var world = actor.get_world_3d()
	if world == null:
		return 0.0
	var space := world.direct_space_state

	var total: float = 0.0
	var counted: int = 0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.stats.HealthCurrent <= 0:
			continue
		counted += 1

		var flatEnemy := Vector3(enemy.global_position.x, 0.0, enemy.global_position.z)
		var flatCandidate := Vector3(candidate.x, 0.0, candidate.z)
		var direction: Vector3 = flatCandidate - flatEnemy
		var distance: float = direction.length()
		if distance < 0.01:
			continue
		direction = direction.normalized()

		var basis := Basis.looking_at(direction, Vector3.UP)
		var beamOrigin := Vector3(flatEnemy.x, BEAM_HEIGHT / 2.0, flatEnemy.z)
		var mask := CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.FULL_COVER | CollisionLayer.ACTOR
		var initialExclude: Array[RID] = [enemy.get_rid(), actor.get_rid()]
		initialExclude.append_array(_ignoredWallRidsAt(enemy.global_position, enemy.PhysicalSize))

		var contacts := RaycastUtils.GatherBeamContacts(
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

		if blockerLayer & CollisionLayer.FULL_COVER != 0:
			total += COVER_SCORE_FULL
		elif blockerLayer & CollisionLayer.HIGH_COVER != 0:
			total += COVER_SCORE_HIGH
		elif blockerLayer & CollisionLayer.LOW_COVER != 0:
			total += COVER_SCORE_LOW

	if counted == 0:
		return 0.0
	return total / float(counted)

## Emulate PropWall.IsIgnoredFor at an arbitrary position and expand it into
## RIDs. If any segment of a wall is within (physicalSize * 2) of `at`, the
## whole wall's segments are excluded (matching how ApplyCollisionRules ignores
## by obstaclegroup_ group name).
static func _ignoredWallRidsAt(at: Vector3, physicalSize: float) -> Array[RID]:
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
static func _findEnemies(actor: Actor) -> Array[Actor]:
	var result: Array[Actor] = []
	for other in Actor.Repository.All.List:
		if other == actor:
			continue
		if not _isHostileTo(other, actor):
			continue
		if other.stats.HealthCurrent <= 0:
			continue
		result.push_back(other)
	return result

static func _isHostileTo(a: Actor, b: Actor) -> bool:
	var aa: Actor.Alliance = a.Definition.Alliance
	var bb: Actor.Alliance = b.Definition.Alliance
	if aa == Actor.Alliance.Neutral or bb == Actor.Alliance.Neutral:
		return false
	return aa != bb

static func _pickPrimaryAttackSkill(actor: Actor) -> Skill:
	for i in 16:
		var skill := actor.Skills.GetByIndex(i)
		if skill == null:
			continue
		var hasDamage: bool = skill.Definition.Telegraphs.any(func(t): return t.HealthThreat > 0)
		if hasDamage:
			return skill
	return null
#endregion
