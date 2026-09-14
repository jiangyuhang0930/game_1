extends Hero
class_name Knight

func _ready() -> void:
	super._ready()
	attack_type = AttackType.CLASSIC
	attack_min_range = 1
	attack_max_range = 2
