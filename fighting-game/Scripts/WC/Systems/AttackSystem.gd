extends Node

class_name AttackSystem

# Reference to the grid data used to read map and cell information.
var grid_data: GridData

# Reference to the current Battle.
var battle: Node

# ------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------

# Initialize the AttackSystem with the current battle grid.
func initialize(grid: GridData, current_battle: Node) -> void:
	grid_data = grid
	battle = current_battle


# ------------------------------------------------------------------
# Attack Range
# ------------------------------------------------------------------

# Calculate all cells inside the selected Hero's normal attack range.
func get_attack_cells(hero: Hero) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var origin := hero.occupied_map_position

	for y in range(
		-hero.attack_max_range,
		hero.attack_max_range + 1
	):
		for x in range(
			-hero.attack_max_range,
			hero.attack_max_range + 1
		):
			var target_cell := origin + Vector2i(x, y)
			var distance: int = abs(x) + abs(y)

			if distance < hero.attack_min_range:
				continue

			if distance > hero.attack_max_range:
				continue

			if not grid_data.has_cell(target_cell):
				continue

			var cell := grid_data.get_cell_from_map(target_cell)

			# Do not show attack range on environment obstacles.
			if cell.object != null:
				continue

			cells.append(target_cell)

	return cells


# Calculate the cells affected by a piercing attack.
func get_pierce_attack_cells(
	hero: Hero,
	target_cell: Vector2i
) -> Array[Vector2i]:

	var cells: Array[Vector2i] = []

	var origin := hero.occupied_map_position
	var direction := target_cell - origin

	# Determine the main attack direction from the mouse position.
	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0:
			direction = Vector2i.RIGHT
		elif direction.x < 0:
			direction = Vector2i.LEFT
		else:
			return cells
	else:
		if direction.y > 0:
			direction = Vector2i.DOWN
		elif direction.y < 0:
			direction = Vector2i.UP
		else:
			return cells

	# Create the piercing attack line.
	for distance in range(
		hero.attack_min_range,
		hero.attack_max_range + 1
	):
		var attack_cell := origin + direction * distance

		# Ignore cells outside the playable map area.
		if not grid_data.is_inside_playable_area(attack_cell):
			continue

		cells.append(attack_cell)

	return cells


# Calculate the cells affected by an attack based on the Hero's attack type.
func get_target_cells(
	hero: Hero,
	target_cell: Vector2i
) -> Array[Vector2i]:

	# Pierce attacks use the direction from the Hero to the mouse.
	if hero.attack_type == Hero.AttackType.PIERCE:
		return get_pierce_attack_cells(hero, target_cell)

	# Classic and Ranged attacks affect only the clicked cell.
	return [target_cell]


# Find all enemy units inside the specified attack cells.
func get_attack_targets(
	target_cells: Array[Vector2i]
) -> Array[Enemy]:

	var targets: Array[Enemy] = []

	for map_position in target_cells:
		if not grid_data.has_cell(map_position):
			continue

		var cell := grid_data.get_cell_from_map(map_position)

		if cell.unit is Enemy:
			targets.append(cell.unit)

	return targets


func execute_attack(hero: Hero, targets: Array[Enemy]) -> void:
	if hero.has_attacked:
		return

	hero.has_attacked = true

	# Play the attack animation.
	await hero.play_animation_and_wait("attack")

	# Start the hit reaction for all targets at the same time.
	for target in targets:
		target.play_hit_reaction()

	# Wait until all hit reactions have finished.
	for target in targets:
		if target.sprite.animation == "take_hit":
			await target.sprite.animation_finished

	# Apply damage to all targets.
	var dead_targets: Array[Enemy] = []

	for target in targets:
		var target_died: bool = target.take_damage(4)

		if target_died:
			dead_targets.append(target)

	# Start all death animations at the same time.
	for target in dead_targets:
		target.play_death_animation()

	# Wait until all death animations have finished.
	for target in dead_targets:
		if target.sprite.animation == "death":
			await target.sprite.animation_finished
	
	# Remove defeated units after their death animations finish.
	for target in dead_targets:
		battle.remove_dead_unit(target)

	# Return the attacker to idle.
	hero.play_animation("idle")
