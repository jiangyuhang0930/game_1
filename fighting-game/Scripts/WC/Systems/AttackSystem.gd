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


func execute_attack(
	hero: Hero,
	targets: Array[Enemy]
) -> void:

	if hero.has_attacked:
		return

	hero.has_attacked = true

	# Start the attack animation.
	hero.play_animation("attack")

	# Wait until the middle of the attack animation.
	var attack_duration := hero.get_animation_duration("attack")
	await get_tree().create_timer(
		attack_duration * 0.5
	).timeout

	# Trigger the hit at the attack midpoint.
	for target in targets:
		target.play_hit_reaction(hero.attack_damage)

	# Apply damage at the hit point.
	var dead_targets: Array[Enemy] = []

	for target in targets:
		var target_died: bool = target.take_damage(hero.attack_damage)

		if target_died:
			dead_targets.append(target)

	# Wait for the attacker's animation to finish.
	if hero.sprite.is_playing():
		await hero.sprite.animation_finished

	# Return the attacker to idle immediately after the attack.
	hero.play_animation("idle")

	# Wait for targets that are still playing their hit reaction.
	for target in targets:
		if (
			not target.is_dead
			and target.sprite.animation == "take_hit"
			and target.sprite.is_playing()
		):
			await target.sprite.animation_finished

	# Play death animations after the hit reaction finishes.
	for target in dead_targets:
		await target.play_death_animation()

	# Remove dead targets after their death animations finish.
	for target in dead_targets:
		battle.remove_dead_unit(target)


# Execute a basic attack from an Enemy against a Hero.
func execute_enemy_attack(
	enemy: Enemy,
	target: Hero
) -> void:

	# Do not attack a dead target.
	if target.is_dead:
		return

	# Do not attack if the target is outside attack range.
	var distance: int = (
		abs(
			enemy.occupied_map_position.x
			- target.occupied_map_position.x
		)
		+ abs(
			enemy.occupied_map_position.y
			- target.occupied_map_position.y
		)
	)

	if distance < enemy.attack_min_range:
		return

	if distance > enemy.attack_max_range:
		return

	# Mark the Enemy as having attacked.
	enemy.has_attacked = true

	# Face the target before the attack animation.
	enemy.face_toward_map_position(
		target.occupied_map_position
	)

	# Start the attack animation.
	enemy.play_animation("attack")

	# Wait until the middle of the attack animation.
	var attack_duration := enemy.get_animation_duration("attack")
	await get_tree().create_timer(
		attack_duration * 0.5
	).timeout

	# Trigger the hit at the attack midpoint.
	target.play_hit_reaction(enemy.attack_damage)

	# Apply damage at the hit point.
	var target_died: bool = target.take_damage(enemy.attack_damage)

	# Wait for the attacker's animation to finish.
	if enemy.sprite.is_playing():
		await enemy.sprite.animation_finished

	# Return the attacker to idle immediately after the attack.
	enemy.play_animation("idle")

	# Wait for the target's hit reaction to finish.
	if (
		not target.is_dead
		and target.sprite.animation == "take_hit"
		and target.sprite.is_playing()
	):
		await target.sprite.animation_finished

	# Play the death animation if the target was defeated.
	if target_died:
		await target.play_death_animation()

		# Remove the defeated Hero from the battle.
		battle.remove_dead_unit(target)
