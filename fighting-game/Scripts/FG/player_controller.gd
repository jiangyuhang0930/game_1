extends CharacterBody2D
class_name PlayerController
@export var health = 10
@export var speed = 10.0
@export var jump_power = 50.0
@export var camera : Camera2D
@export var sword_slash_right : Sprite2D
@export var sword_slash_left : Sprite2D
@export var sword_slash_up : Sprite2D
@export var sword_slash_down : Sprite2D
@export var melee_recoil_force: float = 4000.0
var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0
var jump_charges = 1
var curr_sword_slash
var external_force = 0
var knockback_direction : String

var is_attacking = false
var facing_right = true

func _input(event):
	# Handle jump.
	if event.is_action_pressed("jump") and (is_on_floor() or jump_charges > 0):
		jump_charges -= 1
		velocity.y = jump_power * jump_multiplier
	
	if event.is_action_pressed("switch_wc"):
		get_tree().change_scene_to_file("res://Scenes/WC/Battle/battle.tscn")
		
	if event.is_action_pressed("dash"):
		print("dash")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 3
		
	if is_on_floor():
		jump_charges = 1
	
	if Input.is_action_pressed("attack") and !is_attacking:
		is_attacking = true
		if Input.is_action_pressed("up"):
			curr_sword_slash = sword_slash_up
			knockback_direction = 'down'
		elif Input.is_action_pressed("down") and not is_on_floor():
			curr_sword_slash = sword_slash_down
			knockback_direction = 'up'
		elif Input.get_axis("move_left", "move_right") == 1:
			curr_sword_slash = sword_slash_right
			knockback_direction = 'left'
		elif Input.get_axis("move_left", "move_right") == -1:
			curr_sword_slash = sword_slash_left
			knockback_direction = 'right'
		else:

			if !facing_right:
				curr_sword_slash = sword_slash_left
				knockback_direction = 'right'
			else:
				curr_sword_slash = sword_slash_right
				knockback_direction = 'left'
		curr_sword_slash.visible = true
		curr_sword_slash.process_mode = Node.PROCESS_MODE_INHERIT
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, speed * speed_multiplier)
	velocity.x += external_force
	external_force = move_toward(external_force, 0, 2 * speed * speed_multiplier)
	#if external_force != 0:
		#print(external_force)
		#print(velocity.x)
	move_and_slide()
	
func apply_knockback(recoil_force: float)-> void:
	if knockback_direction == 'down':
		velocity.y = 1 * recoil_force * 0.5
	elif knockback_direction == 'up' and not is_on_floor():
		velocity.y = -1 * recoil_force * 0.5
	elif knockback_direction == 'left':
		if Input.get_axis("move_left", "move_right") == 1:
			external_force = -1 * recoil_force
		else:
			velocity.x = -1 * recoil_force
	elif knockback_direction == 'right':
		if Input.get_axis("move_left", "move_right") == -1:
			external_force = 1 * recoil_force
		else:
			velocity.x = 1 * recoil_force
