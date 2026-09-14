extends Hero
class_name SpearWarrior

func _ready() -> void:
	super._ready()
	attack_type = AttackType.PIERCE
	attack_min_range = 1
	attack_max_range = 3
