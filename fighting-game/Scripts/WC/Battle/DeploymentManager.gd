extends Node

class_name DeploymentManager

var grid_data: GridData

## All heroes in battle.
var heroes: Array[Hero] = []

## Currently selected unit.
var selected_unit: Unit = null

var is_dragging: bool = false

func initialize(grid: GridData) -> void:
	grid_data = grid


func add_hero(hero: Hero) -> bool:

	if heroes.has(hero):
		return true

	# Try to occupy the cell corresponding to the unit's position.
	var occupied := grid_data.occupy_cell(
		hero.occupied_map_position,
		hero
	)

	# Do not register the hero if its starting cell is blocked.
	if not occupied:
		push_error("Cannot add hero to blocked cell: " + str(hero.occupied_map_position))
		return false

	heroes.append(hero)
	return true


# Move a unit from its current cell to a new cell.
func move_unit(unit: Unit, new_map_position: Vector2i) -> bool:

	# The unit's logical occupied cell.
	var new_occupied_position := Vector2i(
		new_map_position.x,
		new_map_position.y - 1
	)

	# Do not allow movement onto a blocked cell.
	if not grid_data.can_occupy_cell(new_occupied_position):
		return false

	# Release the old occupied cell.
	grid_data.release_cell(unit.occupied_map_position)

	# Occupy the new cell.
	var occupied := grid_data.occupy_cell(
		new_occupied_position,
		unit
	)

	if not occupied:
		return false

	# Update the unit's visual position.
	unit.set_map_position(new_map_position)

	return true


# Move a unit from its current occupied cell to a new occupied cell.
func move_unit_to_occupied_cell(
	unit: Unit,
	target_occupied_position: Vector2i
) -> bool:

	# The target cell must be available.
	if not grid_data.can_occupy_cell(target_occupied_position):
		return false

	# Release the unit's current occupied cell.
	grid_data.release_cell(unit.occupied_map_position)

	# Occupy the target cell.
	var occupied := grid_data.occupy_cell(
		target_occupied_position,
		unit
	)

	if not occupied:
		# Restore the original cell if something went wrong.
		grid_data.occupy_cell(
			unit.occupied_map_position,
			unit
		)
		return false

	return true


func get_heroes() -> Array[Hero]:
	return heroes


func is_deployment_cell(map_position: Vector2i) -> bool:
	return (
		map_position.x >= -9
		and map_position.x <= -6
		and map_position.y >= 2
		and map_position.y <= 5
	)

# Start dragging a unit.
func start_drag(unit: Unit) -> void:
	selected_unit = unit
	is_dragging = true


# Stop dragging the current unit.
func stop_drag() -> void:
	selected_unit = null
	is_dragging = false


# Get the currently selected unit.
func get_selected_unit() -> Unit:
	return selected_unit
