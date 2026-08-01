extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var grass_layer: TileMapLayer = $GrassLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer

@onready var grid_data: GridData = $Managers/GridData

@onready var cursor: Cursor = $UI/Cursor
@onready var selection: Sprite2D = $Overlay/Selection
var current_map_position: Vector2i = Vector2i(-999999, -999999)

@onready var hero: Hero = $Units/Hero
@onready var deployment_manager: DeploymentManager = $Managers/DeploymentManager

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	grid_data.initialize(
		ground_layer,
		grass_layer,
		obstacle_layer
	)
	selection.visible = true
	
	# Initialize deployment system.
	deployment_manager.initialize(grid_data)

	# Register hero.
	hero.set_grid_data(grid_data)
	hero.set_map_position(Vector2i(-7, 5))
	deployment_manager.add_hero(hero)

	# Listen for hero click.
	hero.clicked.connect(_on_hero_clicked)
	

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


func _on_hero_clicked(unit: Unit) -> void:

	# Ignore repeated clicks.
	if deployment_manager.is_dragging:
		return

	deployment_manager.start_drag(unit)
	unit.begin_drag()
	
func _unhandled_input(event: InputEvent) -> void:

	# Only handle left mouse click.
	if not event.is_action_pressed("left_click"):
		return

	# Ignore if no unit is being dragged.
	if not deployment_manager.is_dragging:
		return

	# Convert mouse position to map coordinate.
	var mouse_world := get_global_mouse_position()
	var map_position := ground_layer.local_to_map(mouse_world)
	map_position.y += 1

	# Check whether the target cell is inside the deployment area.
	var can_deploy := (
		map_position.x >= -9
		and map_position.x <= -6
		and map_position.y >= 2
		and map_position.y <= 5
	)

	hero.end_drag()

	if can_deploy:
		# Place the hero on the selected cell.
		hero.set_map_position(map_position)

	else:

		# Invalid position. Return to the previous cell.
		hero.set_map_position(hero.previous_map_position)

	deployment_manager.stop_drag()

	# Prevent this click from reaching the hero again.
	get_viewport().set_input_as_handled()
