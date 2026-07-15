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
