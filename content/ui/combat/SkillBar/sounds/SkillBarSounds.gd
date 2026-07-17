extends Node
class_name SkillBarSounds

@onready var skillPressedPlayer: AudioStreamPlayer = $SkillPressedPlayer
@onready var skillReleasedPlayer: AudioStreamPlayer = $SkillReleasedPlayer
@onready var skillDeclinedPlayer: AudioStreamPlayer = $SkillDeclinedPlayer

func playPressed():
	#mouseDownPlayer.play()
	pass

func playReleased():
	skillReleasedPlayer.play()

func playDeclined(index: int):
	var order = [0, 3, 5, 7, 10, 12, 15, 17, 19, 22, 24]
	skillDeclinedPlayer.pitch_scale = _semitones(order[index])
	skillDeclinedPlayer.play()
	pass

func _semitones(n: float) -> float:
	return pow(2.0, n / 12.0)
