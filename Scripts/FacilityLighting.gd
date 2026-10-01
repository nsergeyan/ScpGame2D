extends Node2D
# Containment Breach style lighting for a level, built in code so the level
# scene needs no hand-placed lights.
#
# - a CanvasModulate darkens everything in the world
# - ceiling lamps are placed by reading the Ground tilemap: every few columns
#   it looks up from the floor for the ceiling and hangs a lamp under it, so
#   lamps follow the level when it is edited
# - the player carries a faint light so they are never lost in a dark stretch
# - a screen overlay adds the vignette, film grain and colour grade
#
# Things that must stay readable in the dark (wall text, lasers, acid, the
# rifle guard's sight line) use the unshaded material, which skips lighting.

const UNSHADED := preload("res://Assets/Materials/unshaded.tres")
const GRADE := preload("res://Assets/Shaders/facility_grade.gdshader")
const Lamp := preload("res://Scripts/FacilityLamp.gd")

const AMBIENT := Color(0.3, 0.31, 0.32)   # how dark it is away from any lamp
const LAMP_EVERY := 6                     # columns between lamps (6 * 64 = 384px)
const TILE := 64
const FLOOR_ROW := 8                      # the row a player stands in; the floor surface is row 9

func build(level: Node, ground: TileMapLayer, player: Node2D, hud: CanvasLayer) -> void:
	var dark := CanvasModulate.new()
	dark.color = AMBIENT
	add_child(dark)

	var glow := _radial_texture()
	_place_lamps(ground, glow)

	var carry := PointLight2D.new()
	carry.texture = glow
	carry.texture_scale = 1.3
	carry.energy = 0.45
	carry.color = Color(0.85, 0.9, 1.0)
	carry.position = Vector2(0, -40)
	player.add_child(carry)

	for label in level.get_node("WallText").get_children():
		label.material = UNSHADED
	level.get_node("Tiles/Acid").material = UNSHADED

	# First child of the HUD layer, so it grades the world but not the HUD
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = GRADE
	overlay.material = mat
	hud.add_child(overlay)
	hud.move_child(overlay, 0)

func _place_lamps(ground: TileMapLayer, glow: Texture2D) -> void:
	var used := ground.get_used_rect()
	var col := used.position.x + 3
	while col < used.end.x - 1:
		var c := col
		# stairs and crates fill the floor row: slide right until there is room
		while c < col + 3 and _solid(ground, c, FLOOR_ROW):
			c += 1
		var ceiling := _ceiling_above(ground, c, FLOOR_ROW)
		if ceiling >= 0 and ceiling != FLOOR_ROW:
			var lamp := Lamp.new()
			lamp.position = Vector2(c * TILE + TILE / 2.0, (ceiling + 1) * TILE)
			add_child(lamp)
			lamp.setup(glow, c, (c * 7) % 5 == 0)
		col += LAMP_EVERY

func _ceiling_above(ground: TileMapLayer, col: int, from_row: int) -> int:
	for r in range(from_row, -1, -1):
		if _solid(ground, col, r):
			return r
	return -1

func _solid(ground: TileMapLayer, col: int, row: int) -> bool:
	return ground.get_cell_source_id(Vector2i(col, row)) != -1

func _radial_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color.BLACK)
	g.add_point(0.45, Color(0.38, 0.38, 0.38))   # bright core, long soft tail
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t
