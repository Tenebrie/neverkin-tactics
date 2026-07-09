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
	node.label_settings = LabelSettings.new()
	node.label_settings.outline_size = 1
	node.label_settings.outline_color = Color.RED
	node.label_settings.shadow_size = 2
	node.label_settings.font_size = 20
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
	var item = Asset.Instantiate(MessageLogFloatingItem)
	item.text = message
	item.global_position = instance.get_viewport().get_mouse_position() - Vector2(instance.get_viewport_rect().size.x / 2, 24)
	instance.get_tree().root.add_child(item)

static func PrintErrorObject(error: Error) -> void:
	var item = Asset.Instantiate(MessageLogFloatingItem)
	item.text = error.Message
	item.global_position = instance.get_viewport().get_mouse_position() - Vector2(instance.get_viewport_rect().size.x / 2, 24)
	instance.get_tree().root.add_child(item)

static func PrintWorldMessage(message: String, point: Vector3) -> void:
	var item = Asset.Instantiate(MessageLogFloatingItem)
	item.text = message
	item.followCamera = true
	item.worldPosition = point
	instance.get_tree().root.add_child(item)
	item.screenOffset = -Vector2(item.size.x / 2, 24)

static func PrintActorMessage(message: String, actor: Actor) -> void:
	PrintWorldMessage(message, actor.global_position)
