extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var grass_layer: TileMapLayer = $GrassLayer
@onready var obstacle_layer: TileMapLayer = $ObstacleLayer

@onready var grid_data: GridData = $Managers/GridData

@onready var cursor: Cursor = $UI/Cursor
@onready var selection: Sprite2D = $Overlay/Selection
@onready var movement_overlay: Node2D = $Overlay/MovementOverlay
var current_map_position: Vector2i = Vector2i(-999999, -999999)

@onready var deployment_manager: DeploymentManager = $Managers/DeploymentManager
@onready var pathfinding: Pathfinding = $Managers/Pathfinding

# Hero scene used to create new units.
@export var hero_scene: PackedScene

# ------------------------------------------------------------------
# Battle Phase
# ------------------------------------------------------------------

enum BattlePhase {
	DEPLOYMENT,
	HERO_ACTION
}

# The current phase of the battle.
var current_phase: BattlePhase = BattlePhase.DEPLOYMENT

# Currently selected unit during the hero action phase.
var selected_unit: Unit = null

# Cells currently reachable by the selected unit.
var movement_cells: Array[Vector2i] = []

# Whether a unit is currently moving.
var is_unit_moving: bool = false

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

	create_hero(Vector2i(-7, 3))
	create_hero(Vector2i(-9, 4))
	# create_hero(Vector2i(-9, 5))
	# create_hero(Vector2i(-7, 4))
	

# ------------------------------------------------------------------
# Battle Phase Control
# ------------------------------------------------------------------

# Finish deployment and enter the hero action phase.
func start_battle() -> void:

	# Only allow the phase transition from deployment.
	if current_phase != BattlePhase.DEPLOYMENT:
		return

	# Make sure no unit is still being dragged.
	if deployment_manager.is_dragging:
		var unit := deployment_manager.get_selected_unit()

		if unit != null:
			unit.end_drag()

		deployment_manager.stop_drag()

	# Switch to the hero action phase.
	current_phase = BattlePhase.HERO_ACTION
	# Hide the deployment cursor after entering the action phase.
	selection.visible = false

	print("Battle Phase: HERO_ACTION")
	

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

	# Handle hero selection during the action phase.
	if current_phase == BattlePhase.HERO_ACTION:

		# Do not switch selection while a unit is moving.
		if is_unit_moving:
			return

		# Select the clicked hero directly.
		select_hero_for_action(unit)
		return

	# Heroes can only be dragged during the deployment phase.
	if current_phase != BattlePhase.DEPLOYMENT:
		return

	# Ignore repeated clicks.
	if deployment_manager.is_dragging:
		return

	deployment_manager.start_drag(unit)
	unit.begin_drag()
	
	
# Select a unit and display its movement range.
func select_hero_for_action(unit: Unit) -> void:

	# Clear the previous unit's movement range.
	clear_unit_selection()

	# Select the newly clicked unit.
	selected_unit = unit

	# Calculate reachable cells from the selected unit.
	movement_cells = pathfinding.get_reachable_cells(
		grid_data,
		unit.occupied_map_position,
		unit.move_range
	)

	# Show the new movement range.
	show_movement_cells()
	
	
# Show all cells that the selected unit can reach.
func show_movement_cells() -> void:

	# Remove previous movement indicators.
	for child in movement_overlay.get_children():
		child.queue_free()

	# Create an indicator for every reachable cell.
	for map_position in movement_cells:

		var indicator := Sprite2D.new()

		# Use the existing selection texture.
		indicator.texture = selection.texture

		# Make the movement indicator smaller.
		indicator.scale = Vector2(0.8, 0.8)

		# Place the indicator on the corresponding map cell.
		indicator.position = grid_data.map_to_world(map_position)

		movement_overlay.add_child(indicator)


# Hide all movement indicators and clear the selected unit.
func clear_unit_selection() -> void:

	# Remove all movement indicators.
	for child in movement_overlay.get_children():
		child.queue_free()

	# Clear the selected unit.
	selected_unit = null

	# Clear the cached movement cells.
	movement_cells.clear()


# Move the selected unit to the target cell.
func move_selected_unit(target_cell: Vector2i) -> void:

	if selected_unit == null:
		return

	if is_unit_moving:
		return

	# The target must be inside the current movement range.
	# If it is not, cancel the current selection.
	if not movement_cells.has(target_cell):
		clear_unit_selection()
		return

	# Do not allow the unit to move onto its current cell.
	if target_cell == selected_unit.occupied_map_position:
		clear_unit_selection()
		return

	is_unit_moving = true

	var unit := selected_unit

	# Find the shortest path to the target cell.
	var path := pathfinding.find_path(
		grid_data,
		unit.occupied_map_position,
		target_cell
	)

	# Stop if no valid path exists.
	if path.is_empty():
		is_unit_moving = false
		return

	# Update grid occupancy before the movement starts.
	var moved := deployment_manager.move_unit_to_occupied_cell(
		unit,
		target_cell
	)

	if not moved:
		is_unit_moving = false
		return

	# Clear the selection while the unit is moving.
	clear_unit_selection()

	# Move the unit along the calculated path.
	await unit.move_along_path(path)

	is_unit_moving = false


func _unhandled_input(event: InputEvent) -> void:
	# Right-click cancels the current unit selection.
	if event.is_action_pressed("right_click"):

		if current_phase == BattlePhase.HERO_ACTION:
			clear_unit_selection()

		# Mark the input as handled.
		get_viewport().set_input_as_handled()
		return
	
	# --------------------------------------------------------------
	# Hero Action Phase
	# --------------------------------------------------------------

	if current_phase == BattlePhase.HERO_ACTION:

		# Ignore input while a unit is moving.
		if is_unit_moving:
			return

		# Only handle left mouse clicks.
		if not event.is_action_pressed("left_click"):
			return

		# There must be a selected unit.
		if selected_unit == null:
			return

		# Convert the mouse position to a map cell.
		var mouse_world := get_global_mouse_position()
		var target_cell := ground_layer.local_to_map(mouse_world)

		# Try to move to the selected cell.
		move_selected_unit(target_cell)

		get_viewport().set_input_as_handled()
		return

	# --------------------------------------------------------------
	# Deployment Phase
	# --------------------------------------------------------------

	
	# Deployment input is only available during the deployment phase.
	if current_phase != BattlePhase.DEPLOYMENT:
		return
		
	# Press Enter to finish deployment.
	if event.is_action_pressed("ui_accept"):
		start_battle()
		return

	# Only handle left mouse click.
	if not event.is_action_pressed("left_click"):
		return

	# Ignore if no unit is being dragged.
	if not deployment_manager.is_dragging:
		return

	# Convert mouse position to map coordinate.
	var deployment_mouse_world := get_global_mouse_position()
	var map_position := ground_layer.local_to_map(deployment_mouse_world)

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
