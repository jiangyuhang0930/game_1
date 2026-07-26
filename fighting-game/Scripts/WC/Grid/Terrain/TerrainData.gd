extends RefCounted

class_name TerrainData

var terrain_name := ""

func get_miss_bonus() -> float:
	return 0.0

func get_move_cost() -> int:
	return 1

func on_enter(unit):
	pass

func on_turn_end(unit):
	pass
