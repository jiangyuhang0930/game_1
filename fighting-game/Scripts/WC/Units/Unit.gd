extends Node2D
class_name Unit
signal clicked(unit: Unit)


# Emitted whenever the unit's HP changes.
signal hp_changed(current_hp: int, max_hp: int)

## Tile position on the map.
var map_position: Vector2i

## Grid cell currently occupied by this unit.
var occupied_map_position: Vector2i

## Maximum number of cells this unit can move.
@export var move_range: int = 3

## Maximum health of this unit.
@export var max_hp: int = 8

## Current health of this unit.
var current_hp: int

## Whether this unit has already died.
var is_dead: bool = false

## Display name of this unit.
@export var unit_name: String = "Unit"

## Portrait displayed in the unit information panel.
@export var portrait: Texture2D

## Whether this unit has already moved this turn.
var has_moved: bool = false

## Whether the unit can undo its latest movement.
var can_undo_move: bool = false

## Whether this unit has already attacked this turn.
var has_attacked: bool = false

## Reference to the GridData.
var grid_data: GridData

## Animated sprite used to display the unit.
@onready var sprite: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D

## Root node used as the visual pivot for the unit.
@onready var visual_root: Node2D = $VisualRoot

## Effect root.
@onready var effects: Node2D = $Effects

## UI root.
@onready var ui: Node2D = $UI

@onready var click_area: Area2D = $ClickArea

# HP bar displayed above the unit.
var overhead_hp_bar: ProgressBar

# Timer used to hide the overhead HP bar after combat.
var overhead_hp_bar_timer: Timer

# Tween used to animate the overhead HP bar.
var overhead_hp_tween: Tween

# Vertical spacing between the ClickArea and the HP bar.
@export var overhead_hp_bar_spacing: float = 8.0

# Width of the overhead HP bar.
@export var overhead_hp_bar_width: float = 16.0

# Height of the overhead HP bar.
@export var overhead_hp_bar_height: float = 3.0

# Horizontal adjustment for the overhead HP bar.
@export var overhead_hp_bar_offset_x: float = 0.0

# Whether the unit is currently being dragged.
var is_dragging: bool = false

# Mouse offset when dragging starts.
var drag_offset: Vector2

# Grid position before dragging.
var previous_map_position: Vector2i

# Horizontal facing direction before the latest movement.
var previous_facing_scale_x: float

func _ready() -> void:
	current_hp = max_hp
	play_animation("idle")
	click_area.input_event.connect(_on_click_area_input_event)
	
	create_overhead_hp_bar()

# Create an HP bar above the unit using its ClickArea bounds.
func create_overhead_hp_bar() -> void:
	overhead_hp_bar = ProgressBar.new()

	# Configure the HP bar.
	overhead_hp_bar.show_percentage = false
	overhead_hp_bar.min_value = 0
	overhead_hp_bar.max_value = max_hp
	overhead_hp_bar.value = current_hp
	
	# Use a dark gray background for the HP bar.
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.16, 0.16, 0.16, 1.0)
	background_style.set_corner_radius_all(1)
	background_style.set_content_margin_all(0.0)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.12, 0.12, 1.0)
	fill_style.set_corner_radius_all(1)
	fill_style.set_content_margin_all(0.0)

	overhead_hp_bar.add_theme_stylebox_override(
		"background",
		background_style
	)
	overhead_hp_bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)

	# Counteract the Unit scale.
	overhead_hp_bar.scale = Vector2(
		1.0 / max(abs(scale.x), 0.001),
		1.0 / max(abs(scale.y), 0.001)
	)

	# Hide the HP bar until the unit takes damage.
	overhead_hp_bar.hide()

	# Add the HP bar to the unit UI.
	ui.add_child(overhead_hp_bar)
	
	# Apply the final dimensions after adding the Control to the scene tree.
	overhead_hp_bar.custom_minimum_size = Vector2(
		overhead_hp_bar_width,
		overhead_hp_bar_height
	)
	overhead_hp_bar.size = Vector2(
		overhead_hp_bar_width,
		overhead_hp_bar_height
	)
	
	# Create a timer that hides the HP bar after combat.
	overhead_hp_bar_timer = Timer.new()
	overhead_hp_bar_timer.one_shot = true
	overhead_hp_bar_timer.wait_time = 2.0
	overhead_hp_bar_timer.timeout.connect(_on_overhead_hp_bar_timeout)
	add_child(overhead_hp_bar_timer)

	# Get the ClickArea collision shape.
	var collision_shape := click_area.get_node(
		"CollisionShape2D"
	) as CollisionShape2D

	var rectangle_shape := collision_shape.shape as RectangleShape2D

	# Get the unit's symmetry axis in UI local coordinates.
	var unit_center := ui.to_local(global_position)

	# Find the top-center point of the ClickArea in UI coordinates.
	var shape_top_global := collision_shape.to_global(
		Vector2(0.0, -rectangle_shape.size.y * 0.5)
	)
	var shape_top_ui := ui.to_local(shape_top_global)

	# Account for the HP bar's own scale when centering it.
	var displayed_bar_width: float = overhead_hp_bar.size.x * abs(overhead_hp_bar.scale.x)
	var displayed_bar_height: float = overhead_hp_bar.size.y * abs(overhead_hp_bar.scale.y)

	# Center the bar on the unit's symmetry axis.
	overhead_hp_bar.position = Vector2(
		unit_center.x - displayed_bar_width * 0.5,
		shape_top_ui.y - displayed_bar_height - overhead_hp_bar_spacing + 7.0
	)


# Show the overhead HP bar and animate it to the current HP.
func update_overhead_hp_bar() -> void:
	if overhead_hp_bar == null:
		return

	overhead_hp_bar.show()
	overhead_hp_bar.max_value = max_hp

	# Stop the previous animation if it is still running.
	if overhead_hp_tween != null and overhead_hp_tween.is_running():
		overhead_hp_tween.kill()

	# Animate the bar toward the current HP.
	overhead_hp_tween = create_tween()
	overhead_hp_tween.tween_property(
		overhead_hp_bar,
		"value",
		current_hp,
		0.25
	)

	# Restart the hide timer after each hit.
	overhead_hp_bar_timer.start()


# Hide the overhead HP bar after the timer expires.
func _on_overhead_hp_bar_timeout() -> void:
	if overhead_hp_bar != null:
		overhead_hp_bar.hide()

func initialize(grid: GridData, start_position: Vector2i) -> void:
	grid_data = grid
	set_map_position(start_position)

func set_grid_data(grid: GridData) -> void:
	grid_data = grid

func set_map_position(new_position: Vector2i) -> void:
	map_position = new_position
	occupied_map_position = new_position

	update_world_position()
	update_grass_transparency()
	
func play_animation(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func play_animation_and_wait(animation_name: String) -> void:
	if not sprite.sprite_frames.has_animation(animation_name):
		return

	sprite.play(animation_name)
	await sprite.animation_finished

# Get the duration of an animation in seconds.
func get_animation_duration(animation_name: String) -> float:
	if not sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	var animation_speed := sprite.sprite_frames.get_animation_speed(animation_name)

	if animation_speed <= 0.0:
		return 0.0

	return float(frame_count) / animation_speed

# Play the death animation and wait until it finishes.
func play_death_animation() -> void:
	if is_dead:
		return

	is_dead = true

	# Play the death animation.
	await play_animation_and_wait("death")

# Play the hit reaction, flash white, and show the damage number.
func play_hit_reaction(amount: int) -> void:
	# Start the white flash without blocking the hit animation.
	flash_white()

	# Show the damage number.
	show_damage_number(amount)

	# Play the hit reaction animation.
	await play_animation_and_wait("take_hit")

	# Return to idle after the hit reaction finishes.
	play_animation("idle")

# Show a floating damage number above the unit.
func show_damage_number(amount: int) -> void:
	var damage_label := Label.new()

	damage_label.text = "-" + str(amount)

	# Get the ClickArea collision shape.
	var collision_shape := click_area.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle_shape := collision_shape.shape as RectangleShape2D

	# Convert the ClickArea position into Effects local coordinates.
	var click_area_position := effects.to_local(
		click_area.global_position
	)

	# Place the damage number above the top of the ClickArea.
	damage_label.position = click_area_position + Vector2(
		-6,
		-rectangle_shape.size.y * 0.5 - 15
	)
	
	# Keep the damage number at a consistent visual size regardless of Unit scale.
	damage_label.scale = Vector2(
		1.0 / abs(scale.x),
		1.0 / abs(scale.y)
	)

	# Use a red color for damage numbers.
	damage_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

	# Make the damage number easier to read.
	damage_label.add_theme_font_size_override("font_size", 8)
	damage_label.add_theme_color_override(
		"font_outline_color",
		Color.BLACK
	)
	damage_label.add_theme_constant_override(
		"outline_size",
		1
	)

	effects.add_child(damage_label)

	# Move the damage number upward and fade it out.
	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		damage_label,
		"position",
		damage_label.position + Vector2(0, -24),
		0.5
	)

	tween.tween_property(
		damage_label,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	damage_label.queue_free()

# Flash the unit white briefly when receiving damage.
func flash_white() -> void:
	var cell := grid_data.get_cell_from_map(map_position)
	var alpha := 1.0

	if cell.terrain is GrassData:
		alpha = 0.5

	# Brighten the unit for the hit flash.
	visual_root.modulate = Color(
		2.0,
		2.0,
		2.0,
		alpha
	)

	# Keep the flash visible briefly.
	await get_tree().create_timer(0.12).timeout

	# Restore the normal unit appearance.
	update_grass_transparency()

# Face the target direction before attacking.
func face_toward_map_position(target_map_position: Vector2i) -> void:
	if target_map_position.x > occupied_map_position.x:
		visual_root.scale.x = abs(visual_root.scale.x)
	elif target_map_position.x < occupied_map_position.x:
		visual_root.scale.x = -abs(visual_root.scale.x)

#func update_world_position() -> void:
#	if grid_data == null:
#		return
#
#	position = grid_data.map_to_world(map_position)

# Drag
func begin_drag() -> void:
	is_dragging = true
	
	# Remember the current grid position.
	previous_map_position = map_position

	# Keep the relative position between the mouse and the unit.
	drag_offset = global_position - get_global_mouse_position()


func end_drag() -> void:
	is_dragging = false


func can_move() -> bool:
	return not has_moved


# Check whether this unit has completed both actions and confirmed its movement.
func has_finished_action() -> bool:
	return has_moved and has_attacked and not can_undo_move


func undo_move() -> void:
	if not can_undo_move:
		return

	set_map_position(previous_map_position)
	visual_root.scale.x = previous_facing_scale_x

	has_moved = false
	can_undo_move = false
	
	# Update the unit's appearance after undoing the movement.
	update_grass_transparency()


func finish_move() -> void:
	has_moved = true
	can_undo_move = true


func reset_action() -> void:
	has_moved = false
	has_attacked = false


# Move the unit along a grid path.
# Move the unit along a path of occupied grid cells.
func move_along_path(path: Array[Vector2i]) -> void:

	# Do nothing if there is no movement path.
	if path.size() <= 1:
		return

	# Play the running animation.
	play_animation("run")

	# Move through each cell in the path.
	for i in range(1, path.size()):

		# Pathfinding uses the unit's occupied grid coordinates.
		var target_occupied_position: Vector2i = path[i]

		# The visual map position is now the same as the occupied cell.
		var target_map_position := target_occupied_position
		
		# Face the direction of horizontal movement.
		if target_occupied_position.x > occupied_map_position.x:
			visual_root.scale.x = abs(visual_root.scale.x)
		elif target_occupied_position.x < occupied_map_position.x:
			visual_root.scale.x = -abs(visual_root.scale.x)

		# Convert the visual map position to world position.
		var target_world_position := grid_data.map_to_world(
			target_map_position
		)

		# Smoothly move the unit to the target cell.
		var tween := create_tween()

		tween.tween_property(
			self,
			"position",
			target_world_position,
			0.15
		)

		await tween.finished

		# Update the unit's visual map position.
		map_position = target_map_position

		# Update the occupied grid position.
		occupied_map_position = target_occupied_position
		
		# Update transparency based on terrain.
		update_grass_transparency()

	# Return to idle animation.
	play_animation("idle")


func _process(_delta: float) -> void:
	if not is_dragging:
		return

	# Follow the mouse directly while dragging.
	global_position = get_global_mouse_position() + drag_offset


func update_world_position() -> void:
	if grid_data == null:
		return

	position = grid_data.map_to_world(map_position)


func update_grass_transparency() -> void:
	if grid_data == null:
		return

	var cell := grid_data.get_cell_from_map(map_position)

	var alpha := 1.0

	if cell.terrain is GrassData:
		alpha = 0.5

	# Make the unit gray after completing both movement and attack.
	var brightness := 1.0

	if has_finished_action():
		brightness = 0.5

	visual_root.modulate = Color(
		brightness,
		brightness,
		brightness,
		alpha
	)


func _on_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:

	if event.is_action_pressed("left_click"):

		# Notify Battle that this unit was clicked.
		clicked.emit(self)

		# Prevent the same click from being treated as a movement command.
		get_viewport().set_input_as_handled()


# Attack and Damage

# Apply damage to this unit.
func take_damage(amount: int) -> bool:
	if is_dead:
		return true

	current_hp -= amount
	current_hp = max(current_hp, 0)

	# Notify listeners that the unit's HP has changed.
	hp_changed.emit(current_hp, max_hp)
	
	# Update the overhead HP bar after taking damage.
	update_overhead_hp_bar()

	print(unit_name, " HP: ", current_hp)

	return current_hp <= 0
