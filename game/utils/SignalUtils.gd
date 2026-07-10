class_name SignalUtils

static func emitAsync(signals: Array[Signal], ...args: Array):
	for signalToEmit in signals:
		for connection in signalToEmit.get_connections():
			await connection["callable"].callv(args)
