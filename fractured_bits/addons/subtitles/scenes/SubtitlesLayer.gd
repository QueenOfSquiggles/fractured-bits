extends CanvasLayer
"""
Subtitles (SubtitlesLayer.gd)

see 'create_subtitle' for core functionality

"""

var subtitle_theme :Theme = null # set this to customize
var subtitle_padding_min := Vector2(20,20)
var subtitle_padding_max := Vector2(20,20)
var character_line_width_percent := 0.7
var default_subtitle_position := Vector2(50, 2000) # use really big y to clamp to bottom
# would be nice to be able to set some kind of alignment/anchoring that is customizable


var _stream_mapping := {}
onready var _char_subtitles := VBoxContainer.new()

func _ready() -> void:
	var sub_theme := preload("res://testing/resources/subtitle_theme.tres")
	Subtitles.subtitle_theme = sub_theme
	add_child(_char_subtitles)
	_char_subtitles.alignment = BoxContainer.ALIGN_END
	_char_subtitles.set_anchors_preset(Control.PRESET_WIDE, true)

func _process(delta: float) -> void:
	for c in get_children():
		if _stream_mapping.has(c):
			var stream = _stream_mapping[c]
			_update_subtitle(c, stream)

func _update_subtitle(panel : PanelContainer, stream) -> void:
	var pos = panel.rect_position
	if stream is AudioStreamPlayer3D:
		pos = _subtitle_3d(stream, panel)
		pos = _fix_position(pos, panel)
	panel.rect_position = pos

func create_subtitle(stream, key : String, override_theme : Theme = null) -> void:
	"""
	The main function for loading subtitles for something. Everything is functionally handled automatically. The plugin autoloads the render layer and the sound data can be passed easily using a KeyedAudioStreamPlayer. This isn't intended to be a very complex implementation for subtitles, but a solution that "just works" and is simple enough to use for a Jam game.
	Currently positional audio subtitles are only supported for 3D environments. 2D has yet to be implemented because I mostly develop for 3D. Also 2D environments might benefit less from positional subtitles
	Params:
		'stream': the AudioStreamPlayer (or 2D, 3D variants)
		'key': the subtitle key. If it includes a ':' it is assumed to be a character dialogue and the first half is treated as the character's name while the remaining is treated as the actual subtitle key
		'override_theme': an optional override theme for special use cases
	"""
	var pos := default_subtitle_position
	var panel := _subtitle_obj(key)
	var time_remaining := 1.0
	var theme := subtitle_theme
	if override_theme:
		theme = override_theme
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
	timer.start(time_remaining)
	_stream_mapping[panel] = stream
	panel.connect("tree_exiting", self, "_clear_mapping", [panel])
	if subtitle_theme:
		panel.theme = theme
	
func _clear_mapping(panel : PanelContainer) -> void:
	_stream_mapping.erase(panel)

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
	_char_subtitles.add_child(panel)
	return panel
