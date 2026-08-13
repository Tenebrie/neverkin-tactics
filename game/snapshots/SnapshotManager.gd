extends Node

signal snapshotRestored
signal snapshotsChanged

class Snapshot:
	var timestampMsec = Time.get_ticks_msec()
	var actors: Dictionary[int, Actor.Snapshot]

	static func Collect() -> Snapshot:
		var snapshot = Snapshot.new()
		for actor in Actor.Repository.All.asList():
			var actorSnapshot = actor.createSnapshot()
			#if not actorSnapshot:
				#continue
			snapshot.actors[actor.get_instance_id()] = actorSnapshot
		return snapshot


var isRestoringSnapshot = false
var snapshots: Array[Snapshot]
var snapshotHead = -1
var snapshotDirty = false


func _ready() -> void:
	ActorTargeting.SignalBus.castActionStarted.connect(func():
		if TurnManager.Instance.activeFaction == Actor.PlayerFaction:
			if snapshotDirty:
				CreateSnapshot(true)
			else:
				_pruneRedoHistory()
				snapshotsChanged.emit()
	)
	ActorActions.SignalBus.castResolved.connect(func():
		if TurnManager.Instance.activeFaction == Actor.PlayerFaction:
			CreateSnapshot()
	)
	ActorNavigator.SignalBus.ActorTraversed.connect(func():
		if TurnManager.Instance.activeFaction != Actor.PlayerFaction:
			return
		snapshotDirty = true
		_pruneRedoHistory()
		snapshotsChanged.emit()
	)
	TurnManager.Instance.FactionTurnStarted.connect(func(faction):
		if faction == Actor.PlayerFaction:
			CreateSnapshot()
	)
	TurnManager.Instance.FactionTurnEnded.connect(func(faction):
		if snapshotDirty and faction == Actor.PlayerFaction:
			CreateSnapshot()
	)

func CreateSnapshot(force: bool = false) -> Snapshot:
	if not force and not Error.AsBooleanWithPrint(_isSnapshotAllowed()):
		return null

	var measure = PerformanceUtils.startMeasure("Snapshot collection")
	var before = OS.get_static_memory_usage()
	var snapshot = Snapshot.Collect()
	var after = OS.get_static_memory_usage()
	measure.endMeasure()
	var kilobytesConsumed = (after - before) / 1024.0
	var megabytesConsumed = (after - before) / 1024.0 / 1024.0
	var actorCount = snapshot.actors.values().filter(func(value): return value != null).size()
	var immutablesCount = snapshot.actors.size() - actorCount
	if megabytesConsumed > 1.0:
		Log.debug("Snapshot created: %.1fMB of memory (%d actors, %d immutables)"%[megabytesConsumed, actorCount, immutablesCount])
	else:
		Log.debug("Snapshot created: %.1fKB of memory (%d actors, %d immutables)"%[kilobytesConsumed, actorCount, immutablesCount])

	_pruneRedoHistory()

	snapshots.push_back(snapshot)
	snapshotHead += 1
	snapshotDirty = false

	snapshotsChanged.emit()
	return snapshot


func RestorePreviousSnapshot() -> void:
	if not Error.AsBooleanWithPrint(_isSnapshotAllowed()):
		return

	if snapshotHead >= 0 and snapshotDirty:
		CreateSnapshot()

	if snapshotHead <= 0:
		return

	snapshotHead -= 1
	_restoreSnapshot(snapshots[snapshotHead])


func RestoreNextSnapshot() -> void:
	if not Error.AsBooleanWithPrint(_isSnapshotAllowed()):
		return

	if snapshotHead >= snapshots.size() - 1:
		return

	snapshotHead += 1
	_restoreSnapshot(snapshots[snapshotHead])


func RestoreEarliestSnapshot() -> void:
	if not Error.AsBooleanWithPrint(_isSnapshotAllowed()):
		return

	if snapshotHead <= 0:
		return

	snapshotHead = 0
	_restoreSnapshot(snapshots[snapshotHead])


func _restoreSnapshot(snapshot: Snapshot) -> void:
	isRestoringSnapshot = true
	var actorsRemoved = 0
	var actorsRestored = 0
	var immutablesSkipped = 0
	var measure = PerformanceUtils.startMeasure("Snapshot restoration")
	for actor in Actor.Repository.All.asList():
		if not snapshot.actors.has(actor.get_instance_id()):
			actor.queue_free()
			actorsRemoved += 1
			continue
		var actorSnapshot = snapshot.actors[actor.get_instance_id()]
		if not actorSnapshot:
			immutablesSkipped += 1
			continue
		actor.restoreSnapshot(snapshot.actors[actor.get_instance_id()])
		actorsRestored += 1
	measure.endMeasure()

	snapshotDirty = false
	isRestoringSnapshot = false
	snapshotRestored.emit()
	Log.info("Snapshot restored (%d actors, skipped %d immutables, removed %d actors)"%[actorsRestored, immutablesSkipped, actorsRemoved])

func _pruneRedoHistory():
	var snapshotsToPrune = snapshots.size() - snapshotHead - 1
	if snapshotHead >= 0 and snapshotsToPrune > 0:
		Log.info("Pruned %d snapshot%s"%[snapshotsToPrune, "" if snapshotsToPrune == 1 else "s"])
		snapshots = snapshots.slice(0, snapshotHead + 1)

func PruneAllSnapshots():
	snapshots = []
	snapshotHead = -1

func _isSnapshotAllowed() -> Variant:
	if isRestoringSnapshot:
		return Error.new("Already restoring a snapshot")

	var isLockedInTargeting = Actor.Repository.Alive.any(func(actor):
		return actor.actions?.isLockedInTargeting ?? false
	)
	if isLockedInTargeting:
		return Error.new("Snapshots disabled while targeting a skill")

	var isCastingAnySkill = Actor.Repository.Alive.any(func(actor):
		return actor.Skills?.isAnySkillBeingCast() ?? false
	)
	if isCastingAnySkill:
		return Error.new("Snapshots disabled during animation")

	var isMoving = Actor.Repository.Alive.any(func(actor):
		return actor.navigator?.IsMoving() ?? false
	)
	if isMoving:
		return Error.new("Snapshots disabled while an actor is moving")

	return true
