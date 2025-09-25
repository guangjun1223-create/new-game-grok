# res://script/UI/hero_barracks_entry.gd (Phiên bản GỠ LỖI)
extends PanelContainer

signal info_requested(hero_roster_index)
signal dismiss_requested(hero_roster_index)

@onready var hero_info_label: RichTextLabel = $HBoxContainer/HeroInfoLabel
@onready var info_button: Button = $HBoxContainer/InfoButton
@onready var dismiss_button: Button = $HBoxContainer/DismissButton

var _hero_roster_index: int = -1

func _ready():
	print("DEBUG ENTRY: _ready() được gọi. Index hiện tại là: ", _hero_roster_index)
	info_button.pressed.connect(_on_info_button_pressed)
	dismiss_button.pressed.connect(_on_dismiss_button_pressed)

func setup(hero: Hero, roster_index: int):
	print("DEBUG ENTRY: setup() được gọi cho Hero '%s' với index: %d" % [hero.name, roster_index])
	_hero_roster_index = roster_index
	
	var hero_name = hero.hero_name
	var full_name = hero.name
	
	var rarity = "N/A"
	if full_name.contains("("):
		var start = full_name.find("(") + 1
		var end = full_name.find(")")
		rarity = full_name.substr(start, end - start)
	
	var rarity_bbcode = "[color=gray]%s[/color]" % rarity
	hero_info_label.text = "[b]%s[/b] (Hạng: %s)" % [hero_name, rarity_bbcode]

func _on_info_button_pressed():
	print("DEBUG ENTRY: Nút 'Chi tiết' được nhấn. Gửi đi index: ", _hero_roster_index)
	info_requested.emit(_hero_roster_index)

func _on_dismiss_button_pressed():
	print("DEBUG ENTRY: Nút 'Sa thải' được nhấn. Gửi đi index: ", _hero_roster_index)
	dismiss_requested.emit(_hero_roster_index)
