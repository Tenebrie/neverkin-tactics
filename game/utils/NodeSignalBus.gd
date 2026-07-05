class_name NodeSignalBus extends RefCounted

static var _buses: Array[WeakRef] = []

func _init() -> void:
	_buses.append(weakref(self))

static func ClearAll() -> void:
	for wr in _buses:
		var bus: Object = wr.get_ref()
		if bus == null:
			continue
		for sig in bus.get_signal_list():
			for conn in bus.get_signal_connection_list(sig.name):
				bus.disconnect(sig.name, conn.callable)
	_buses.clear()
