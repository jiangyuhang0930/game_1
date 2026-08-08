extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var grass_layer: TileMapLayer = $GrassLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer

@onready var grid_data: GridData = $Managers/GridData

@onready var cursor: Cursor = $UI/Cursor
@onready var selection: Sprite2D = $Overlay/Selection
var current_map_position: Vector2i = Vector2i(-999999, -999999)

@onready var deployment_manager: DeploymentManager = $Managers/DeploymentManager

# Hero scene used to create new units.
@export var hero_scene: PackedScene


# ------------------------------------------------------------------
# Hero Creation
# ------------------------------------------------------------------

# Create and initialize a hero.
func create_hero(start_position: Vector2i) -> Hero:

	var hero := hero_scene.instantiate() as Hero

	# Add to the scene.
	$Units.add_child(hero)

	# Initialize hero.
	hero.set_grid_data(grid_data)
	hero.set_map_position(start_position)

	# Register hero.
	var added := deployment_manager.add_hero(hero)

	# Cancel hero creation if the target cell is already occupied.
	if not added:
		hero.queue_free()
		return null

	# Listen for click events.
	hero.clicked.connect(_on_hero_clicked)
	return hero


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
	
	# ------------------------------------------------------------------
	# Create initial heroes.
	# ------------------------------------------------------------------

	create_hero(Vector2i(-7, 4))
	create_hero(Vector2i(-9, 5))
	# create_hero(Vector2i(-9, 5))
	# create_hero(Vector2i(-7, 4))
	

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

	# Check whether the target cell is valid for deployment.
	var can_deploy := deployment_manager.is_deployment_cell(map_position)

	# Get the current dragging unit.
	var unit := deployment_manager.get_selected_unit()
	# Make sure a unit is actually being dragged.
	if unit == null:
		return

	unit.end_drag()

	if can_deploy:

		# Try to move the unit to the target cell.
		var moved := deployment_manager.move_unit(
			unit,
			map_position
		)

		# Return to the previous position if the target cell is blocked.
		if not moved:
			unit.set_map_position(unit.previous_map_position)

	else:

		# Return to the previous position if the target is outside
		# the deployment area.
		unit.set_map_position(unit.previous_map_position)

	deployment_manager.stop_drag()

	# Prevent this click from reaching the hero again.
	get_viewport().set_input_as_handled()
