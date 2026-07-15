class_name SignalUtils

static func emitAsync(signals: Array[Signal], ...args: Array):
	for sig in signals:
		for connection in sig.get_connections():
			var callable: Callable = connection["callable"]
			if not callable.is_valid():
				continue
			if not sig.is_connected(callable):
				continue
			if connection["flags"] & Object.CONNECT_ONE_SHOT:
				sig.disconnect(callable)
			await callable.callv(args)

static func awaitWithTimeout(sig: Signal, seconds: float) -> bool:
	var race = Race.new()
	var onSignal = func(): race.settle(false)
	sig.connect(onSignal, Object.CONNECT_ONE_SHOT)
	var tree = Engine.get_main_loop() as SceneTree
	tree.create_timer(seconds).timeout.connect(func(): race.settle(true), Object.CONNECT_ONE_SHOT)
	var timedOut: bool = await race.Finished
	if not timedOut and sig.is_connected(onSignal):
		pass
	elif sig.is_connected(onSignal):
		sig.disconnect(onSignal)
	return timedOut

#static func awaitWithTimeout(seconds: float, operation: Callable) -> bool:
	#var race = Race.new()
	#var run = func():
		#await operation.call()
		#race.settle(false)
	#run.call()
	#var tree = Engine.get_main_loop() as SceneTree
	#tree.create_timer(seconds).timeout.connect(func(): race.settle(true), Object.CONNECT_ONE_SHOT)
	#return await race.Finished

class Race:
	signal Finished(timedOut: bool)
	var settled = false

	func settle(timedOut: bool):
		if settled:
			return
		settled = true
		Finished.emit(timedOut)
