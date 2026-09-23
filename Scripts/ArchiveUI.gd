extends CanvasLayer
# Autoload: the recovered-document archive, opened with TAB.
#
# Built in code rather than as a scene so it exists on every screen, including
# the end screen, without being placed in each one. Pauses the tree while open,
# and runs with PROCESS_MODE_ALWAYS so it can still take input while paused.

const DIM := Color(0.38, 0.40, 0.43)
const BODY := Color(0.78, 0.79, 0.80)
const HEAD := Color(0.92, 0.92, 0.89)

var is_open: bool = false
var header: Label
var list: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.021, 0.026, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 54)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	header = Label.new()
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", HEAD)
	header.add_theme_constant_override("outline_size", 0)
	col.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)

	var footer := Label.new()
	footer.text = "TAB  -  close"
	footer.add_theme_font_size_override("font_size", 17)
	footer.add_theme_color_override("font_color", DIM)
	footer.add_theme_constant_override("outline_size", 0)
	col.add_child(footer)

func _label(text: String, size: int, colour: Color, wrap: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_constant_override("outline_size", 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	header.text = "SITE-19 ARCHIVE      %d / %d RECOVERED" % [
		GameManager.collected_entries.size(), ScpArchive.count()]
	for i in ScpArchive.count():
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if GameManager.collected_entries.has(i):
			var e := ScpArchive.get_entry(i)
			# "class" is a GDScript keyword, so read it with brackets
			row.add_child(_label("%s  //  %s" % [e["id"], str(e["class"]).to_upper()], 23, HEAD, false))
			row.add_child(_label(e["text"], 19, BODY, true))
			row.add_child(_label("%s, CC BY-SA 3.0" % e["author"], 14, DIM, true))
		else:
			row.add_child(_label("[ REDACTED ]", 23, DIM, false))
		list.add_child(row)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Archive"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	is_open = not is_open
	if is_open:
		_refresh()
	visible = is_open
	get_tree().paused = is_open
	AudioManager.set_paused(is_open)
