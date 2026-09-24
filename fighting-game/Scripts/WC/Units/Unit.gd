extends Node2D
class_name Unit
signal clicked(unit: Unit)

## Tile position on the map.
var map_position: Vector2i

## Grid cell currently occupied by this unit.
var occupied_map_position: Vector2i

## Maximum number of cells this unit can move.
@export var move_range: int = 3

## Maximum health of this unit.
@export var max_hp: int = 10

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

# Play the death animation and wait until it finishes.
func play_death_animation() -> void:
	if is_dead:
		return

	is_dead = true

	# Play the death animation.
	await play_animation_and_wait("death")

# Play the hit reaction, flash white, and return to idle.
func play_hit_reaction() -> void:
	# Start the white flash without blocking the hit animation.
	flash_white()

	# Play the hit reaction animation.
	await play_animation_and_wait("take_hit")

	# Return to idle after the hit reaction finishes.
	play_animation("idle")

# Flash the unit white briefly when receiving damage.
func flash_white() -> void:
	var original_modulate := visual_root.modulate

	# Flash white.
	visual_root.modulate = Color.WHITE

	# Wait briefly.
	await get_tree().create_timer(0.08).timeout

	# Restore the original appearance.
	visual_root.modulate = original_modulate

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

	print(unit_name, " HP: ", current_hp)

	return current_hp <= 0
