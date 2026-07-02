extends Control
class_name MessageLog

static var instance: MessageLog

func _ready() -> void:
	instance = self
	var container := $%Messages
	while container.get_child_count() > 0:
		var child := container.get_child(0)
		child.queue_free()
		container.remove_child(child)

func printMessage(message: String) -> void:
	var container: VBoxContainer = $%Messages
	while container.get_child_count() > 16:
		var child := container.get_child(0)
		child.queue_free()
		container.remove_child(child)

	var node := Label.new()
	node.add_theme_font_size_override("font_size", 22)
	node.text = message
	container.add_child(node)
	await get_tree().create_timer(8).timeout
	if not is_instance_valid(node):
		return
	create_tween().tween_property(node, ^"modulate", Color.from_hsv(0, 0, 1, 0.0), 0.5)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(node):
		node.queue_free()

static func PrintChatMessage(message: String) -> void:
	instance.printMessage(message)

static func PrintMessage(message: String) -> void:
	#instance.printMessage(message)
	var item = Asset.Instantiate(MessageLogFloatingItem)
	item.text = message
	item.global_position = instance.get_viewport().get_mouse_position() - Vector2(instance.get_viewport_rect().size.x / 2, 24)
	instance.get_tree().root.add_child(item)

static func PrintErrorObject(error: Error) -> void:
	#instance.printMessage(prefix + " " + error.Message)
	var item = Asset.Instantiate(MessageLogFloatingItem)
	item.text = error.Message
	item.global_position = instance.get_viewport().get_mouse_position() - Vector2(instance.get_viewport_rect().size.x / 2, 24)
	instance.get_tree().root.add_child(item)
