extends Hero
class_name HellfireRhino

func _ready() -> void:
	super._ready()
	attack_type = AttackType.RANGED
	attack_min_range = 3
	attack_max_range = 3
