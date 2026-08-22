extends Node2D

var health = 5

func _process(_delta):
	if health == 0:
		queue_free()
	


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		var player = get_tree().get_first_node_in_group("player")
		player.apply_knockback(player.melee_recoil_force)
	
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body)
