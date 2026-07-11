class_name MouseManager

static func forceUpdateHoverState():
	SignalBus.ForceUpdateHoverState.emit()

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation extends NodeSignalBus:
	signal ForceUpdateHoverState()
