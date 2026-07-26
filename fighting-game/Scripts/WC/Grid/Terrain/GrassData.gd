extends TerrainData

class_name GrassData

func _init():
	terrain_name = "Grass"

func get_miss_bonus() -> float:
	return 0.5
