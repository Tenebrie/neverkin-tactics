extends Node

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

var snapshots: Array[Snapshot]

func GenerateSnapshot() -> Snapshot:
	var before = OS.get_static_memory_usage()
	var snapshot = Snapshot.Collect()
	var after = OS.get_static_memory_usage()
	var kilobytesConsumed = (after - before) / 1024.0
	var megabytesConsumed = (after - before) / 1024.0 / 1024.0
	MessageLog.PrintChatMessage("Snapshot created")
	var actorCount = snapshot.actors.values().filter(func(value): return value != null).size()
	var immutablesCount = snapshot.actors.size() - actorCount
	if megabytesConsumed > 1.0:
		Log.info("Snapshot requires %.1fMB of memory (%d actors, %d immutables)"%[actorCount, immutablesCount, megabytesConsumed])
	else:
		Log.info("Snapshot requires %.1fKB of memory (%d actors, %d immutables)"%[actorCount, immutablesCount, kilobytesConsumed])
	snapshots.push_back(snapshot)
	return snapshot

func RestoreSnapshot(snapshot: Snapshot):
	var actorsRemoved = 0
	var actorsRestored = 0
	var immutablesSkipped = 0
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

	MessageLog.PrintChatMessage("Snapshot restored")
	Log.info("Restored %d actors, skipped %d immutables, removed %d new actors"%[actorsRestored, immutablesSkipped, actorsRemoved])
