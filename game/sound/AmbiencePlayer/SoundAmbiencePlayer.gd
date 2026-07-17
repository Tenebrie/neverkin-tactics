extends Node
class_name SoundAmbiencePlayer

@onready var playerA: AudioStreamPlayer = $AudioStreamPlayerA
@onready var playerB: AudioStreamPlayer = $AudioStreamPlayerB

func _ready() -> void:
	playerA.play()
	playerB.play(playerB.stream.get_length() * 0.37)
	_drift(playerA)
	_drift(playerB)

func _drift(p: AudioStreamPlayer) -> void:
	while true:
		var t = create_tween()
		t.tween_property(p, "pitch_scale", randf_range(0.985, 1.015), randf_range(20.0, 40.0))
		t.parallel().tween_property(p, "volume_db", randf_range(-3.0, 0.0), randf_range(15.0, 30.0))
		await t.finished
