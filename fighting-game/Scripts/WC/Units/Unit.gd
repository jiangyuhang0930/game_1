extends Node2D
class_name Unit
signal clicked(unit: Unit)

## Tile position on the map.
var map_position: Vector2i

## Reference to the GridData.
var grid_data: GridData

## Animated sprite.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

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
	print("ClickArea connected:", click_area)
	
func initialize(grid: GridData, start_position: Vector2i) -> void:
	grid_data = grid
	set_map_position(start_position)

func set_grid_data(grid: GridData) -> void:
	grid_data = grid

func set_map_position(new_position: Vector2i) -> void:
	map_position = new_position
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

func _process(delta: float) -> void:
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
		clicked.emit(self)
		
