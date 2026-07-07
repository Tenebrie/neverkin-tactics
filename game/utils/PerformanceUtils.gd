class_name PerformanceUtils

class ProfileTimer:
	var label: String
	var startedAt: float

	func endMeasure():
		var duration = Time.get_ticks_usec() - startedAt
		print("- %s: %.2f ms"%[label, duration / 1000.0])

static func startMeasure(label: String) -> ProfileTimer:
	var timer = ProfileTimer.new()
	timer.label = label
	timer.startedAt = Time.get_ticks_usec()
	return timer
