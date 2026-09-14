extends Unit
class_name Hero

enum AttackType {
	CLASSIC,
	RANGED,
	PIERCE
}

@export var attack_type: AttackType = AttackType.CLASSIC
@export var attack_min_range: int = 1
@export var attack_max_range: int = 1
