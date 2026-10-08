extends Unit
class_name Enemy

enum AttackType {
	BASIC,
	BLINK_ATTACK,
	AOE_KNOCKBACK_STUN,
	SUMMON
}

# The attack behavior used by this enemy.
@export var attack_type: AttackType = AttackType.BASIC

# Minimum attack range of this enemy.
@export var attack_min_range: int = 1

# Maximum attack range of this enemy.
@export var attack_max_range: int = 1

# Damage dealt by this enemy's basic attack.
@export var attack_damage: int = 4


# Execute this enemy's action during the Enemy Turn.
func take_turn(
	_heroes: Array[Hero],
	_pathfinding: Pathfinding,
	_deployment_manager: DeploymentManager,
	_attack_system: AttackSystem
) -> void:
	await get_tree().process_frame
