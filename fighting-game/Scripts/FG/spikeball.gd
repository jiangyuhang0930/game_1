extends RigidBody2D



func _on_area_2d_body_entered(body: Node2D) -> void:

	#if body.is_in_group("boundary"):
		#print(1)

	if body.is_in_group("player"):
		queue_free()
		var player = get_tree().get_first_node_in_group("player")
		if not player.invinsible:
			player.apply_knockback(player.melee_recoil_force * 0.75)
			player.health -= 1
			player.slow_down_time()
			player.update_hearts_container()
