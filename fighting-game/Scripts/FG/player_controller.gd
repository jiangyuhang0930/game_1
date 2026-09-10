extends CharacterBody2D
class_name PlayerController
@export var health = 5
@export var max_health = 5
@export var speed = 10.0
@export var jump_power = 50.0
@export var camera : Camera2D
@export var sword_slash_right : Sprite2D
@export var sword_slash_left : Sprite2D
@export var sword_slash_up : Sprite2D
@export var sword_slash_down : Sprite2D
@export var melee_recoil_force: float = 4000.0
@onready var dash_cooldown = $DashCooldown
var speed_multiplier = 30.0
var jump_multiplier = -30.0
var direction = 0
var jump_charges = 1
var curr_sword_slash
var external_force = 0
var knockback_direction : String

var is_attacking = false
var facing_right = true
var grounded = false
var invinsible = false
var hurt = false
var is_dashing = false

var hearts_list : Array[TextureRect]

func _ready():
	var hearts_parent = $HealthBar/HealthBarContainer
	for child in hearts_parent.get_children():
		hearts_list.append(child)
	

func _input(event):
	# Handle jump.
	if event.is_action_pressed("jump") and (is_on_floor() or jump_charges > 0):
		jump_charges -= 1
		velocity.y = jump_power * jump_multiplier
	
	if event.is_action_pressed("switch_wc"):
		get_tree().change_scene_to_file("res://Scenes/WC/Battle/battle.tscn")
		
	if event.is_action_pressed("dash"):
		is_dashing = true
		if facing_right:
			velocity.x = 1 * speed * speed_multiplier * 2.5
		else:
			velocity.x = -1 * speed * speed_multiplier * 2.5
		if dash_cooldown.is_stopped():
			set_collision_layer_value(1, false)
			set_collision_layer_value(2, true)
			set_collision_mask_value(1, false)
			set_collision_mask_value(2, true)
			$PlayerAnimator/Sprite2D.modulate.a = 0.5
			dash_cooldown.start()
		await get_tree().create_timer(0.25).timeout
		is_dashing = false
		set_collision_layer_value(1, true)
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, false)
		$PlayerAnimator/Sprite2D.modulate.a = 1
		

func _physics_process(delta: float) -> void:
	if is_dashing:
		move_and_slide()
		return
		
	if health == 0:
		get_tree().quit()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 3
		
	if is_on_floor():
		jump_charges = 1
	
	if Input.is_action_pressed("attack") and !is_attacking and !grounded:
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
	if direction and not grounded:
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
			
func slow_down_time():
	Engine.time_scale = 0.5
	grounded = true
	invinsible = true
	await get_tree().create_timer(0.25).timeout
	Engine.time_scale = 1.0
	grounded = false
	await get_tree().create_timer(0.25).timeout
	$PlayerAnimator/Sprite2D.modulate = Color(1.0, 1.0, 1.0) 
	invinsible = false
	
func update_hearts_container():

	for i in range(len(hearts_list)):
		if i < health:
			hearts_list[i].visible = true
		else:
			hearts_list[i].visible = false
