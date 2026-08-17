extends Node2D

@export var player_controller : PlayerController
@export var animation_player : AnimationPlayer
@export var sprite : Sprite2D

func _process(delta):
	# flips the character sprite
	if not player_controller.is_attacking:
		if player_controller.direction == 1:
			sprite.flip_h = false
			player_controller.facing_right = true
			#for child in player_controller.get_children():
				#if child is Sprite2D:
					#child.flip_h = false
		elif player_controller.direction == -1:
			sprite.flip_h = true
			player_controller.facing_right = false
			#for child in player_controller.get_children():
				#if child is Sprite2D:
					#child.flip_h = true
		
	if player_controller.is_attacking:
		animation_player.play("knight_attack")
		await animation_player.animation_finished
		player_controller.is_attacking = false
		player_controller.curr_sword_slash.visible = false
		player_controller.curr_sword_slash.process_mode = Node.PROCESS_MODE_DISABLED
		

	##plays the movement animation
	if abs(player_controller.velocity.x) > 0.0:
		animation_player.play("knight_walk")
	else:
		animation_player.play("knight_idle")
		
	if player_controller.velocity.y != 0.0:
		animation_player.play("knight_jump")	
	
