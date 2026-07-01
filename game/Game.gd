extends Node
class_name Game

static var Instance: Game:
	get:
		return GameInstance

static var Scene: GameScene:
	get:
		var root = Instance.get_tree().root
		for child in root.get_children():
			if child is GameScene:
				return child
		return null
