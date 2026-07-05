extends Node3D
class_name Sequencer

var Steps: Array[Step]

func AddStep(delay: float, callback: Callable) -> Sequencer:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = delay
	timer.timeout.connect(func():
		callback.call()
		timer.queue_free()
		if get_child_count() == 1:
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
