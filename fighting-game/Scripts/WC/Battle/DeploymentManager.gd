extends Node

class_name DeploymentManager

var grid_data: GridData

## All heroes in battle.
var heroes: Array[Hero] = []

## Currently selected hero.
var selected_hero: Hero = null

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
		and map_position.y >= 1
		and map_position.y <= 4
	)

func start_drag(hero: Hero) -> void:

	selected_hero = hero
	is_dragging = true


func stop_drag() -> void:

	selected_hero = null
	is_dragging = false
