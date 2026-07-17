extends Component3D

var audioPlayer: AudioStreamPlayer3D
var lastPlayedTimeSeconds = 0.0

func _parentReady():
	audioPlayer = AudioStreamPlayer3D.new()
	audioPlayer.bus = &"SFX"
	audioPlayer.panning_strength = 0.8
	add_child(audioPlayer)

	TurnManager.Instance.CurrentPlayerActorChanged.connect(func(current, previous):
		var effectStream = parent.definition.soundReadyEffectStream
		if current != parent or previous == parent or not effectStream:
			return

		var currentTime = Time.get_ticks_msec() / 1000.0
		if currentTime - lastPlayedTimeSeconds < 1.0:
			return

		audioPlayer.stream = effectStream
		audioPlayer.play()
		lastPlayedTimeSeconds = currentTime
	)
