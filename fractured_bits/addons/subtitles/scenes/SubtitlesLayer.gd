extends CanvasLayer


var subtitle_padding_min := Vector2(20,20)
var subtitle_padding_max := Vector2(20,20)

var character_line_width_percent := 0.7

var default_subtitle_position := Vector2(50, 2000) # use really big y to clamp to bottom
# would be nice to be able to set some kind of alignment/anchoring that is customizable

func create_subtitle(stream, key : String) -> void:
	var pos := default_subtitle_position
	var panel := _subtitle_obj(key)
	if stream is AudioStreamPlayer3D:
		pos = subtitle_3d(stream, panel)
		pos = fix_position(pos, panel) # fix pos either way to fix erronous default positions
		# maybe should I change this to use a timer that waits the expected length of the sound? That would fix this and prevent the gradual build-up of subtitles
		(stream as AudioStreamPlayer3D).connect("finished", panel, "queue_free")
	panel.rect_position = pos

func subtitle_3d(stream :KeyedAudioStreamPlayer3D, panel : PanelContainer) -> Vector2:
	if not stream.handle_position:
		# if not set to positional sound, place in default position
		return default_subtitle_position
	var viewport := get_tree().current_scene.get_viewport()
	var cam :Camera= viewport.get_camera()
	var pos3D := stream.transform.origin
	var result := cam.unproject_position(stream.global_transform.origin)
	if cam.is_position_behind(pos3D):
		result.y = viewport.size.y # force to bottom of screen
		result.x = viewport.size.x - result.x
	return result

func fix_position(pos : Vector2, panel : PanelContainer) -> Vector2:
	var result := pos
	var viewport := get_tree().current_scene.get_viewport()
	
	var min_ := Vector2(0, 0)
	var max_ := Vector2(viewport.size.x, viewport.size.y) - panel.rect_size
	min_ += subtitle_padding_min
	max_ -= subtitle_padding_max
	
	result.x = clamp(pos.x, min_.x, max_.x)
	result.y = clamp(pos.y, min_.y, max_.y)
	return result

func _subtitle_obj(key : String) -> PanelContainer:
	if key.find(":") != -1:
		var arr := key.split(":", false, 1)
		if arr.size() == 2:
			return _subtitle_obj_char(arr[0], arr[1])
		else:
			print("had a false positive on key [%s]" % key)
	var panel := PanelContainer.new()
	var label := Label.new()
	label.text = key
	panel.add_child(label)
	panel.name = "Sub_" + key
	self.add_child(panel)
	return panel

func _subtitle_obj_char(char_name : String, key : String) -> PanelContainer:
	var viewport := get_tree().current_scene.get_viewport()
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var lbl_name := Label.new()
	var lbl_text := Label.new()
	lbl_name.text = char_name
	lbl_text.text = key
	lbl_text.autowrap = true
	lbl_text.rect_min_size.x = viewport.size.x * character_line_width_percent
	vbox.add_child(lbl_name)
	vbox.add_child(lbl_text)
	panel.add_child(vbox)
	panel.name = "Sub_" + char_name + "_" + key
	panel.anchor_left = 0.5
	self.add_child(panel)
	return panel
