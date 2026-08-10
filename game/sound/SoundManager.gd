extends Node
class_name SoundManager

const MAX_AUDIO_CHANNELS = 16

var audioChannels: Array[AudioStreamPlayer3D]

static var Instance: SoundManager:
	get:
		return SoundManagerInstance

func _ready() -> void:
	add_child(Asset.Instantiate(SoundAmbiencePlayer))
	for i in MAX_AUDIO_CHANNELS:
		var player = AudioStreamPlayer3D.new()
		audioChannels.push_back(player)
		add_child(player)

static func playOneShot(sfx: AudioStream, location: Vector3, loudness: float = 0.5):
	if Instance.audioChannels.is_empty():
		Log.error("Unable to play SFX - no available channels", "Sound")
		return

	var player = Instance.audioChannels.pop_front()
	player.global_position = location
	player.stream = sfx
	player.volume_linear = loudness
	player.play()
	await player.finished
	Instance.audioChannels.push_front(player)
