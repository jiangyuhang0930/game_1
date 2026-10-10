extends Control
class_name UnitInfoPanel

@onready var portrait: TextureRect = $Panel/MarginContainer/HBoxContainer/Portrait

@onready var name_label: Label = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/NameLabel

@onready var hp_label: Label = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/HPLabel

@onready var hp_bar: ProgressBar = \
	$Panel/MarginContainer/HBoxContainer/InfoContainer/HPBar

# The unit currently displayed in the information panel.
var current_unit: Unit

# Tween used to animate the HP bar.
var hp_tween: Tween

func _ready() -> void:
	hide()


func show_unit(unit: Unit) -> void:
	# Disconnect from the previously displayed unit.
	if current_unit != null:
		if current_unit.hp_changed.is_connected(_on_unit_hp_changed):
			current_unit.hp_changed.disconnect(_on_unit_hp_changed)

	# Handle an empty selection.
	if unit == null:
		if hp_tween != null and hp_tween.is_running():
			hp_tween.kill()
			
		current_unit = null
		hide()
		return

	# Stop any animation belonging to the previously displayed unit.
	if hp_tween != null and hp_tween.is_running():
		hp_tween.kill()

	# Store and connect the newly displayed unit.
	current_unit = unit
	current_unit.hp_changed.connect(_on_unit_hp_changed)

	portrait.texture = unit.portrait
	name_label.text = unit.unit_name

	update_hp(unit, false)

	show()


# Update the HP display when the current unit takes damage.
func _on_unit_hp_changed(_new_current_hp: int, _new_max_hp: int) -> void:
	if current_unit == null:
		return

	update_hp(current_unit)



func update_hp(unit: Unit, animate: bool = true) -> void:
	if unit == null:
		return

	# Update the HP bar range.
	hp_bar.max_value = unit.max_hp

	# Update the HP text immediately.
	hp_label.text = "HP  " + str(unit.current_hp) + " / " + str(unit.max_hp)

	# Stop the previous HP animation if it is still running.
	if hp_tween != null and hp_tween.is_running():
		hp_tween.kill()

	# Update the HP bar immediately when animation is disabled.
	if not animate:
		hp_bar.value = unit.current_hp
		return

	# Animate the HP bar toward the current HP value.
	hp_tween = create_tween()
	hp_tween.tween_property(
		hp_bar,
		"value",
		unit.current_hp,
		0.25
	)
