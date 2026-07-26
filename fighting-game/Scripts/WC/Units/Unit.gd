extends Node2D

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

func _ready() -> void:
	play_animation("idle")
	
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

func update_world_position() -> void:
	if grid_data == null:
		return

	position = grid_data.map_to_world(map_position)
