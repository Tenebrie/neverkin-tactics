extends Node3D
class_name Skill

@onready var Controller: SkillController = get_parent()

@export var Name: String = "Unnamed"

func Cast() -> void:
	printerr("Cast function is not implemented for " + str(get_script()))

func GetIcon() -> Texture2D:
	printerr("GetIcon function is not implemented for " + str(get_script()))
	return null

enum TargetMode {
	DirectClick,
}

func GetTargetMode() -> TargetMode:
	printerr("GetTargetMode function is not implemented for " + str(get_script()))
	return TargetMode.DirectClick
