extends CanvasLayer
# HUD: hearts, documents, keycard, timer, subtitle/message box, alarm overlay.

var heart_full: AtlasTexture
var heart_empty: AtlasTexture
var msg_tween: Tween
var t: float = 0.0

@onready var hearts: HBoxContainer = $Hearts
@onready var docs_label: Label = $Docs/DocsLabel
@onready var time_label: Label = $TimeLabel
@onready var key_icon: TextureRect = $KeyIcon
@onready var message_box: Control = $MessageBox
@onready var message_label: Label = $MessageBox/MessageLabel
@onready var skip_hint: Label = $SkipHint
@onready var alarm_overlay: ColorRect = $AlarmOverlay

func _ready() -> void:
	var sheet: Texture2D = load("res://Assets/Spritesheet/platformPack_tilesheet.png")
	heart_full = AtlasTexture.new()
	heart_full.atlas = sheet
	heart_full.region = Rect2(11 * 64, 4 * 64, 64, 64)
	heart_empty = AtlasTexture.new()
	heart_empty.atlas = sheet
	heart_empty.region = Rect2(11 * 64, 2 * 64, 64, 64)
	GameManager.hp_changed.connect(_on_hp)
	GameManager.message.connect(_on_message)
	GameManager.keycard_changed.connect(func(has: bool): key_icon.visible = has)
	key_icon.visible = GameManager.has_keycard
	message_box.modulate.a = 0.0
	_on_hp(GameManager.hp, GameManager.max_hp)

func _on_hp(hp: int, max_hp: int) -> void:
	for i in hearts.get_child_count():
		var h: TextureRect = hearts.get_child(i)
		h.visible = i < max_hp
		h.texture = heart_full if i < hp else heart_empty

func _on_message(text: String, duration: float) -> void:
	message_label.text = text
	if msg_tween and msg_tween.is_valid():
		msg_tween.kill()
	msg_tween = create_tween()
	msg_tween.tween_property(message_box, "modulate:a", 1.0, 0.12)
	msg_tween.tween_interval(maxf(duration - 0.5, 0.2))
	msg_tween.tween_property(message_box, "modulate:a", 0.0, 0.4)

func _process(delta: float) -> void:
	t += delta
	docs_label.text = "x %d" % GameManager.score
	if GameManager.escape_running:
		time_label.text = GameManager.format_escape()
		# steady red, then flashing for the last 30 seconds
		var a: float = 1.0
		if GameManager.escape_left < 30.0:
			a = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 10.0))
		time_label.modulate = Color(1.0, 0.25, 0.2, a)
	else:
		time_label.text = GameManager.format_time()
		time_label.modulate = Color(1, 1, 1, 1)
	skip_hint.visible = GameManager.announcing
	if GameManager.alarm_on:
		alarm_overlay.color = Color(1, 0, 0, 0.05 + 0.09 * (0.5 + 0.5 * sin(t * 6.0)))
	else:
		alarm_overlay.color = Color(1, 0, 0, 0)
