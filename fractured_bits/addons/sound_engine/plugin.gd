tool
extends EditorPlugin


func _enter_tree() -> void:
	var script := preload("res://addons/sound_engine/sound_lib/SoundLib.gd")
	add_custom_type("SoundLib", "Node", script, preload("res://addons/sound_engine/icons/sound_lib.svg"))
	add_custom_type("SoundLib2D", "Node2D", script, preload("res://addons/sound_engine/icons/sound_lib_2D.svg"))
	add_custom_type("SoundLib3D", "Spatial", script, preload("res://addons/sound_engine/icons/sound_lib_3D.svg"))


func _exit_tree() -> void:
	remove_custom_type("SoundLib")
	remove_custom_type("SoundLib2D")
	remove_custom_type("SoundLib3D")
