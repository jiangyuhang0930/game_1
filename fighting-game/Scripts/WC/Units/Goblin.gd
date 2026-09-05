extends "res://Scripts/WC/Units/Enemy.gd"
class_name Goblin


func take_turn(
	heroes: Array[Hero],
	pathfinding: Pathfinding,
	deployment_manager: DeploymentManager
) -> void:

	# Do nothing if there are no heroes.
	if heroes.is_empty():
		return

	# Find the closest hero that can be reached.
	var closest_path: Array[Vector2i] = []
	var shortest_distance := INF

	for hero in heroes:

		var path := pathfinding.find_path(
			grid_data,
			occupied_map_position,
			hero.occupied_map_position
		)

		if path.is_empty():
			continue

		if path.size() < shortest_distance:
			shortest_distance = path.size()
			closest_path = path

	# Do nothing if no hero can be reached.
	if closest_path.is_empty():
		return

	# Stop next to the hero instead of moving onto the hero's cell.
	var max_path_index := closest_path.size() - 2

	# Do not move if already next to the hero.
	if max_path_index < 1:
		return

	# Limit movement by the Goblin's movement range.
	var target_path_index = min(
		move_range,
		max_path_index
	)

	var target_cell := closest_path[target_path_index]

	# Remember the starting position.
	previous_map_position = occupied_map_position

	# Update grid occupancy before the movement starts.
	var moved := deployment_manager.move_unit_to_occupied_cell(
		self,
		target_cell
	)

	if not moved:
		return

	# Move the Goblin visually along the path.
	await move_along_path(
		closest_path.slice(0, target_path_index + 1)
	)

	# Mark the Goblin as having moved this turn.
	finish_move()
