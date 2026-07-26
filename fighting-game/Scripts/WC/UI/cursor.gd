extends Node2D

class_name Cursor

const CURSOR_SCALE := 1.5

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.scale = Vector2.ONE * CURSOR_SCALE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = event.position
