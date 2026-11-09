extends CharacterBody2D

var spikeball = load("res://Scenes/FG/spikeball.tscn")
var player
var health = 20
var sprite
var dashing = false
var dash_position : Vector2 = Vector2(-999, -999)
var prev_dis
var shielded = false
@export var area_1 : Area2D
@export var speed = 300
@onready var shield_sound = $shield_sound
@onready var dash_cooldown = $DashTimer
@onready var dash_stop_timer = $DashStopTimer
@onready var spikeball_cooldown = $SpikeballTimer
@onready var hit_sound = $AudioStreamPlayer2D
@onready var shield_sprite = $shield

func _ready() -> void:
	sprite = $Sprite2D
	player = get_tree().get_first_node_in_group("player")
	dash_stop_timer.paused = true
	



func _process(_delta):
	if spikeball_cooldown.is_stopped():
		#if instance != null:
			#instance.queue_free()
		shoot_spikeball()
		spikeball_cooldown.start()
		
	if health == 0:
		queue_free()
	var touching_objects = area_1.get_overlapping_bodies()
	for body in touching_objects:
		if body.name == "Knight":
			dashing = false
			speed = 300
			dash_cooldown.start()
			dash_stop_timer.start()
			dash_stop_timer.paused = true

			if position.x - 50 > player.position.x:
				player.knockback_direction = 'left'
			else:
				player.knockback_direction = 'right'
			if not player.invinsible:
				player.take_damage("normal")



func _on_area_2d_area_entered(area: Area2D) -> void:

	if area.is_in_group("slash") and !shielded:
		if self not in player.attack_object_hit:
			player.attack_object_hit.append(self)
			
			player.apply_knockback(player.melee_recoil_force)
			health -= 1

			if health == 10:
				shielding()
			if !hit_sound.playing:
				hit_sound.play()
	elif area.is_in_group("slash") and shielded:
		shield_sound.play()
		
	
func _physics_process(_delta: float) -> void:

	if dash_cooldown.is_stopped() and !dashing:
		dashing = true
		speed = 1500
		dash_stop_timer.paused = false
		
		if global_position.x < player.global_position.x:
			dash_position = player.global_position + Vector2(350, 0)
		else:
			dash_position = player.global_position - Vector2(300, 0)
		var dash_direction = global_position.direction_to(dash_position)
		
		# Set velocity and move
		velocity.x = (dash_direction * speed).x
		move_and_slide()
		return
		
	if dashing:


		if global_position.distance_to(dash_position) < 50 \
			or global_position.x < 1110 or global_position.x > 5176 \
			or dash_stop_timer.is_stopped():

			dashing = false
			speed = 300
			dash_cooldown.start()
			dash_stop_timer.start()
			dash_stop_timer.paused = true
		else:
			move_and_slide()
			return

	# Get direction vector towards the player
	var direction: Vector2 = global_position.direction_to(player.global_position + Vector2(50, 0))
	# Set velocity and move
	velocity.x = (direction * speed).x

	if velocity.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	move_and_slide()
	prev_dis = abs(global_position.x - dash_position.x)
	

func shoot_spikeball():

	var instance = spikeball.instantiate()
	get_tree().current_scene.add_child(instance)
	var random_int = randi_range(800, 2500)
	var r_sign : int
	if sprite.flip_h:
		r_sign = -1
	else:
		r_sign = 1
	instance.global_position = global_position
	instance.linear_velocity = Vector2((0 + random_int) * r_sign, -3000)

func shielding():
	shielded = true
	shield_sprite.visible = true

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
