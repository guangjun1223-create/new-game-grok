# res://script/UI/upgrade_choice_dialog.gd
extends Control

signal choice_made(upgrade_type) # "weapon" hoặc "armor"

@onready var weapon_button: Button = $Panel/VBoxContainer/WeaponButton
@onready var armor_button: Button = $Panel/VBoxContainer/ArmorButton

func _ready():
	weapon_button.pressed.connect(_on_weapon_button_pressed)
	armor_button.pressed.connect(_on_armor_button_pressed)

func _on_weapon_button_pressed():
	choice_made.emit("weapon")
	queue_free() # Tự hủy sau khi chọn

func _on_armor_button_pressed():
	choice_made.emit("armor")
	queue_free()
