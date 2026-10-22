extends RigidBody2D

var player
var hp = 2

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _on_area_2d_body_entered(body: Node2D) -> void:

	#if body.is_in_group("boundary"):
		#print(1)

	if body.is_in_group("player"):
		queue_free()
		
		if not player.invinsible:
			player.apply_knockback(player.melee_recoil_force * 0.75)
			player.health -= 1
			player.slow_down_time()
			player.update_hearts_container()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		hp -= 1
		if hp == 0:
			queue_free()
		
		linear_velocity = Vector2(0, 0)
		if player.position.x < position.x:
			linear_velocity.x += 500
		else:
			linear_velocity.x -= 500
		
		if player.position.y < position.y:
			linear_velocity.y += 500
		else:
			linear_velocity.y  -= 500
