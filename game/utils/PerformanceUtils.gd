extends Node
class_name PerformanceUtils

func _ready():
	Log.debug("- %s: %.2f ms"%["[init] Engine startup", Time.get_ticks_usec() / 1000.0], "Profiler")
	var timer = startMeasure("[init] Scene tree ready")
	await get_tree().process_frame
	timer.endMeasure()

class ProfileTimer:
	var label: String
	var startedAt: float

	func endMeasure():
		var duration = Time.get_ticks_usec() - startedAt
		Log.debug("- %s: %.2f ms"%[label, duration / 1000.0], "Profiler")

static func startMeasure(label: String) -> ProfileTimer:
	var timer = ProfileTimer.new()
	timer.label = label
	timer.startedAt = Time.get_ticks_usec()
	return timer
