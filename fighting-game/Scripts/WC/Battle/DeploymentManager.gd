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


func add_hero(hero: Hero) -> void:
	if heroes.has(hero):
		return
	heroes.append(hero)


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
