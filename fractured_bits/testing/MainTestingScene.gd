extends Node


onready var sound_lib :SoundLib = $SoundLib

func _ready() -> void:
	SoundEngine.connect("on_sound_played", self, "process_sound")

func process_sound(stream, key : String) -> void:
	if key != SoundEngine.DEFAULT_SOUND_KEY:
		print("Sound of key [%s] was played" % key)

func _on_Button_pressed() -> void:
	sound_lib.play("impact_metal")


func _on_Button2_pressed() -> void:
	sound_lib.play("impact_metal_no_key")
