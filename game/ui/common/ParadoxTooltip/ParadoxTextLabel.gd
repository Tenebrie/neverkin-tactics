@tool
class_name ParadoxTextLabel
extends RichTextLabel

class Metadata:
	var keywordId: int = -1

var enableColor = true

var _activeTagId: String
var _activeMetadata: Metadata = null
var _activeTooltip: ParadoxTooltip

func _ready() -> void:
	bbcode_enabled = true
	meta_hover_started.connect(_onHoverStarted)
	meta_hover_ended.connect(_onHoverEnded)
	meta_clicked.connect(func():
		if _activeTooltip:
			_activeTooltip.lockTooltip()
	)
	reset_size()

	text_changed.connect(_processText)
	_processText()

func _onHoverStarted(tagId: String) -> void:
	_activeTagId = tagId

	var metadata = Metadata.new()
	if tagId.begins_with("keyword:"):
		metadata.keywordId = int(tagId.split(":")[1])
	_activeMetadata = metadata

	if metadata.keywordId > -1:
		var tooltipScene = Asset.Instantiate(ParadoxTooltipKeyword)
		get_tree().root.add_child(tooltipScene)
		var def = KeywordManager.Instance.allKeywords[metadata.keywordId].definition
		tooltipScene.setKeyword(def)
		_activeTooltip = tooltipScene
		tooltipScene.layer = getCurrentRenderLayer() + 1
		tooltipScene.visible = true

		var parent = getCurrentTooltip()
		if parent:
			tooltipScene.usesForcedPosition = true
			var mouse = get_viewport().get_mouse_position().y
			if (parent.offset.x + parent.root.size.x / 2.0) >= get_viewport_rect().size.x / 2.0:
				tooltipScene.forcedPosition = Vector2(parent.offset.x - tooltipScene.root.size.x - 16, mouse - tooltipScene.root.size.y / 2.0)
			else:
				tooltipScene.forcedPosition = Vector2(parent.offset.x + parent.root.size.x + 16, mouse - tooltipScene.root.size.y / 2.0)


func getCurrentRenderLayer() -> int:
	var node = get_parent()
	while node:
		if node is CanvasLayer canvas:
			return canvas.layer
		node = node.get_parent()
	return 0

func getCurrentTooltip() -> ParadoxTooltip:
	var node = get_parent()
	while node:
		if node is ParadoxTooltip tooltip:
			return tooltip
		node = node.get_parent()
	return null

func _onHoverEnded() -> void:
	if _activeTooltip and not _activeTooltip.isLocked:
		_activeTooltip.queue_free()
		_activeTooltip = null

const OPENING_MARKER = "[url][/url]"
func _processText() -> void:
	if text.begins_with(OPENING_MARKER):
		return
	text = OPENING_MARKER + StringUtils.evaluateTemplate(text, enableColor)
