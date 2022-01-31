extends CanvasLayer

var subtitle_theme :Theme = null # set this to customize
var subtitle_padding_min := Vector2(20,20)
var subtitle_padding_max := Vector2(20,20)
var character_line_width_percent := 0.7
var default_subtitle_position := Vector2(50, 2000) # use really big y to clamp to bottom
# would be nice to be able to set some kind of alignment/anchoring that is customizable


var character_dialogue_queue := []
var character_dialogue_current :PanelContainer = null
var stream_mapping := {}

func _ready() -> void:
	var sub_theme := preload("res://testing/resources/subtitle_theme.tres")
	Subtitles.subtitle_theme = sub_theme

func _process(delta: float) -> void:
	for c in get_children():
		if stream_mapping.has(c):
			var stream = stream_mapping[c]
			_update_subtitle(c, stream)

func _update_subtitle(panel : PanelContainer, stream) -> void:
	var pos = panel.rect_position
	if stream is AudioStreamPlayer3D:
		pos = _subtitle_3d(stream, panel)
		pos = _fix_position(pos, panel)
	panel.rect_position = pos

func create_subtitle(stream, key : String) -> void:
	var pos := default_subtitle_position
	var panel := _subtitle_obj(key)
	var time_remaining := 1.0
	var theme := subtitle_theme
	if stream is AudioStreamPlayer3D:
		pos = _subtitle_3d(stream, panel)
		pos = _fix_position(pos, panel) # fix pos either way to fix erronous default positions
		# maybe should I change this to use a timer that waits the expected length of the sound? That would fix this and prevent the gradual build-up of subtitles
		time_remaining = (stream as AudioStreamPlayer3D).stream.get_length()
	if "time_padding" in stream:
		# this checks if a node has a certain property
		time_remaining += stream.time_padding
	if "subtitle_theme" in stream:
		if stream.subtitle_theme != null:
			theme = stream.subtitle_theme
	panel.rect_position = pos
	var timer := Timer.new()
	panel.add_child(timer)
	timer.connect("timeout", panel, "queue_free")
	timer.autostart = true
	stream_mapping[panel] = stream
	panel.connect("tree_exiting", self, "_clear_mapping", [panel])
	if subtitle_theme:
		panel.theme = theme
	
func _clear_mapping(panel : PanelContainer) -> void:
	stream_mapping.erase(panel)

func _subtitle_3d(stream :KeyedAudioStreamPlayer3D, panel : PanelContainer) -> Vector2:
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

func _fix_position(pos : Vector2, panel : PanelContainer) -> Vector2:
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
	_manage_character_dialogue(panel)
	return panel

func _manage_character_dialogue(panel : PanelContainer) -> void:
	if character_dialogue_current == null:
		character_dialogue_current = panel
		character_dialogue_current.connect("tree_exiting", self, "_next_char_dialogue")
	else:
		panel.set_process(false)
		panel.visible = false
		character_dialogue_queue.append(panel)

func _next_char_dialogue() -> void:
	character_dialogue_current = null
	if not character_dialogue_queue.empty():
		print("Loading next character subtitle, of %d" % character_dialogue_queue.size())
		character_dialogue_current = character_dialogue_queue[0]
		character_dialogue_queue.remove(0)
		character_dialogue_current.visible = true
		character_dialogue_current.set_process(true)
		print("character_dialogue_current = ", character_dialogue_current)
