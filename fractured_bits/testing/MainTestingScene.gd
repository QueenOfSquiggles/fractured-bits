extends Node


onready var sound_lib :SoundLib = $SoundLib

func _ready() -> void:
	SoundEngine.connect("on_sound_played", self, "process_sound")

func process_sound(stream, key : String) -> void:
	# This is basically all that's needed to connect the sound engine and subtitles systems. This could be made into an autoload to make this happen for all scenes
	if key != SoundEngine.DEFAULT_SOUND_KEY:
		Subtitles.create_subtitle(stream, key)
