extends Node2D
class_name Unit
signal clicked(unit: Unit)

## Tile position on the map.
var map_position: Vector2i

## Grid cell currently occupied by this unit.
var occupied_map_position: Vector2i

## Maximum number of cells this unit can move.
@export var move_range: int = 3

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

func _ready() -> void:
	play_animation("idle")
	click_area.input_event.connect(_on_click_area_input_event)
	# print("ClickArea connected:", click_area)
	
func initialize(grid: GridData, start_position: Vector2i) -> void:
	grid_data = grid
	set_map_position(start_position)

func set_grid_data(grid: GridData) -> void:
	grid_data = grid

func set_map_position(new_position: Vector2i) -> void:
	map_position = new_position

	# The unit occupies the cell one row below its visual position.
	occupied_map_position = Vector2i(
		new_position.x,
		new_position.y - 1
	)

	update_world_position()
	
func play_animation(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

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

		# Convert the occupied cell to the unit's visual map position.
		var target_map_position := Vector2i(
			target_occupied_position.x,
			target_occupied_position.y + 1
		)
		
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
