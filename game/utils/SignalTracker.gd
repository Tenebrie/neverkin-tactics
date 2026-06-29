class_name SignalTracker

var _signal_getter: Callable
var _callback: Callable
var _current: Object = null

func _init(signal_getter: Callable, callback: Callable) -> void:
	_signal_getter = signal_getter
	_callback = callback

func Track(new_value: Object) -> void:
	if _current != null:
		_signal_getter.call(_current).disconnect(_callback)
	_current = new_value
	if _current != null:
		_signal_getter.call(_current).connect(_callback)
