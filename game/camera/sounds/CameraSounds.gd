extends Node
class_name CameraSounds

@onready var sweepPlayer: AudioStreamPlayer = $SweepPlayer

func playSweep():
	sweepPlayer.play()
