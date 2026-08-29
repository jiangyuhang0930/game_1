extends Control
class_name UnitInfoPanel


@onready var portrait: TextureRect = $Panel/MarginContainer/HBoxContainer/Portrait

@onready var name_label: Label = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/NameLabel

@onready var hp_label: Label = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/HPLabel

@onready var hp_bar: ProgressBar = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/HPBar


func _ready() -> void:
	hide()


func show_unit(unit: Unit) -> void:

	if unit == null:
		hide()
		return

	portrait.texture = unit.portrait
	name_label.text = unit.unit_name

	update_hp(unit)

	show()


func update_hp(unit: Unit) -> void:

	if unit == null:
		return

	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp

	hp_label.text = "HP  " + str(unit.current_hp) + " / " + str(unit.max_hp)
