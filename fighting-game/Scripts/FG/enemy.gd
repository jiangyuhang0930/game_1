extends Node2D

var health = 2

func _process(_delta):
	if health == 0:
		queue_free()
	


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		health -= 1
