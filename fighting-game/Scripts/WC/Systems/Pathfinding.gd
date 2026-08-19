extends Node

class_name Pathfinding


# ------------------------------------------------------------------
# Movement Range
# ------------------------------------------------------------------

# Get all cells that a unit can reach within its movement range.
func get_reachable_cells(
	grid_data: GridData,
	start_position: Vector2i,
	move_range: int
) -> Array[Vector2i]:

	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []

	# Start from the unit's current occupied cell.
	queue.append(start_position)
	visited[start_position] = 0

	while not queue.is_empty():

		var current: Vector2i = queue.pop_front()
		var current_distance: int = visited[current]

		# Add the current cell to the reachable list.
		# Do not include the unit's current cell.
		if current != start_position:
			reachable.append(current)

		# Stop expanding when the movement range is reached.
		if current_distance >= move_range:
			continue

		# Check the four neighboring cells.
		var directions: Array[Vector2i] = [
			Vector2i.UP,
			Vector2i.DOWN,
			Vector2i.LEFT,
			Vector2i.RIGHT
		]

		for direction in directions:

			var next: Vector2i = current + direction
			
			# Skip cells outside the walkable map bounds.
			if (
				next.x < grid_data.min_walkable_x
				or next.x > grid_data.max_walkable_x
				or next.y < grid_data.min_walkable_y
				or next.y > grid_data.max_walkable_y
			):
				continue

			# Skip cells outside the map.
			if not grid_data.has_cell(next):
				continue

			# Skip blocked cells.
			if grid_data.is_obstacle(next):
				continue

			# Skip cells that have already been visited.
			if visited.has(next):
				continue

			visited[next] = current_distance + 1
			queue.append(next)

	return reachable


# Find the shortest path between two walkable cells.
func find_path(
	grid_data: GridData,
	start: Vector2i,
	target: Vector2i
) -> Array[Vector2i]:

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {}

	came_from[start] = start

	while not frontier.is_empty():

		var current: Vector2i = frontier.pop_front()

		if current == target:
			break

		for direction in [
			Vector2i.UP,
			Vector2i.DOWN,
			Vector2i.LEFT,
			Vector2i.RIGHT
		]:

			var next: Vector2i = current + direction

			# Skip cells outside the map.
			if (
				next.x < grid_data.min_walkable_x
				or next.x > grid_data.max_walkable_x
				or next.y < grid_data.min_walkable_y
				or next.y > grid_data.max_walkable_y
			):
				continue

			# Skip cells outside the grid data.
			if not grid_data.has_cell(next):
				continue

			# Skip blocked cells.
			if grid_data.is_obstacle(next) and next != target:
				continue

			if came_from.has(next):
				continue

			came_from[next] = current
			frontier.append(next)

	# No path found.
	if not came_from.has(target):
		return []

	# Reconstruct the path.
	var path: Array[Vector2i] = []
	var current_node: Vector2i = target

	while current_node != start:
		path.push_front(current_node)
		current_node = came_from[current_node]

	path.push_front(start)

	return path
