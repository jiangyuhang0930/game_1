extends Node2D

var health = 5
@export var area : Area2D

func _process(_delta):
	if health == 0:
		queue_free()
	var touching_objects = area.get_overlapping_bodies()
	for body in touching_objects:
		if body.name == "Knight":
			var player = get_tree().get_first_node_in_group("player")
			if position.x - 50 > player.position.x:
				player.knockback_direction = 'left'
			else:
				player.knockback_direction = 'right'
			if not player.invinsible:
				player.apply_knockback(player.melee_recoil_force)
				player.health -= 1
				player.slow_down_time()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		var player = get_tree().get_first_node_in_group("player")
		player.apply_knockback(player.melee_recoil_force)
		health -= 1
	
	


#func _on_area_2d_body_entered(body: Node2D) -> void:
	#if body.name == 'Knight':
		#var player = get_tree().get_first_node_in_group("player")
		#if position.x - 50 > player.position.x:
			#player.knockback_direction = 'left'
		#else:
			#player.knockback_direction = 'right'
		#if not player.invinsible:
			#player.apply_knockback(player.melee_recoil_force * 0.7)
			#player.health -= 1
			#player.slow_down_time()
