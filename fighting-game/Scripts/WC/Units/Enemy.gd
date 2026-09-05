extends Unit
class_name Enemy

# Execute this enemy's action during the Enemy Turn.
func take_turn(
	_heroes: Array[Hero],
	_pathfinding: Pathfinding,
	_deployment_manager: DeploymentManager
) -> void:
	await get_tree().process_frame
