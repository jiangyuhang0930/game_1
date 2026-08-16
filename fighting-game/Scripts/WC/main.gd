extends Node2D


func _ready():
	print("Battle Game Start")


func _process(_delta):
	pass
	
func _input(event):
	if event.is_action_pressed("switch_fg"):
		get_tree().change_scene_to_file("res://Scenes/FG/stage_1.tscn")
