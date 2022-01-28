extends CanvasLayer


func create_subtitle(stream, key : String) -> void:
	if stream is AudioStreamPlayer3D:
		subtitle_3d(stream, key)

func subtitle_3d(stream :AudioStreamPlayer3D, key : String) -> void:
	var viewport := get_tree().current_scene.get_viewport()
	var cam :Camera= viewport.get_camera()
	var pos2d := cam.unproject_position(stream.transform.origin)
	
