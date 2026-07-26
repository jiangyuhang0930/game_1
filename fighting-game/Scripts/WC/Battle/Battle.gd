extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var grass_layer: TileMapLayer = $GrassLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer

@onready var grid_data: GridData = $Managers/GridData

@onready var cursor: Cursor = $UI/Cursor
@onready var selection: Sprite2D = $Overlay/Selection
var current_map_position: Vector2i = Vector2i(-999999, -999999)

@onready var hero: Hero = $Units/Hero

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	grid_data.initialize(
		ground_layer,
		grass_layer,
		obstacle_layer
	)
	selection.visible = true
	
	hero.set_grid_data(grid_data)
	hero.set_map_position(Vector2i(-7, 5))


func _process(_delta: float) -> void:

	var world_position := get_global_mouse_position()
	var map_position := ground_layer.local_to_map(world_position)

	# print(map_position)
	
	# when mouse on grid show the select
	if map_position == current_map_position:
		return

	current_map_position = map_position
	if not grid_data.can_select(map_position):
		selection.visible = false
		return

	selection.visible = true
	selection.position = grid_data.map_to_world(map_position)
	# print(current_map_position)
