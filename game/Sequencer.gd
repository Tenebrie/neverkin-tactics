extends Node3D
class_name Sequencer

var Steps: Array[Step]
signal done

func AddStep(delay: float, callback: Callable) -> Sequencer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(delay, 0.001)
	timer.timeout.connect(func():
		callback.call()
		timer.queue_free()
		remove_child(timer)
		if get_child_count() == 0:
			done.emit()
			queue_free()
	)
	add_child(timer)
	timer.start()
	return self

static func Start(parent: Node) -> Sequencer:
	var sequencer = Sequencer.new()
	parent.add_child(sequencer)
	# Add a dummy step for cleanup of empty sequencers
	sequencer.AddStep(0.01, func(): return)
	return sequencer

class Step:
	var DelaySeconds = 0.0
	var Callback: Callable
