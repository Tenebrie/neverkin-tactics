@tool
class_name ParadoxTextLabel
extends RichTextLabel

static var _stack: Array[ParadoxTextLabel]

class Metadata:
	var test: String

var _activeTagId: String
var _activeMetadata: Metadata = null

func _ready() -> void:
	bbcode_enabled = true
	meta_hover_started.connect(_onHoverStarted)
	meta_hover_ended.connect(_onHoverEnded)
	reset_size()

	text_changed.connect(_processText)
	_processText()

func _onHoverStarted(tagId: String) -> void:
	_activeTagId = tagId
	#_activeMetadata = meta
	print(tagId)

func _onHoverEnded(tagId: String) -> void:
	if tagId == _activeTagId:
		print("Exit")

const OPENING_MARKER = "[url][/url]"
func _processText() -> void:
	if text.begins_with(OPENING_MARKER):
		return
	text = OPENING_MARKER + text.replace("Concerning", "[u][url=\"threat_concerning\"]Concerning[/url][/u]")
