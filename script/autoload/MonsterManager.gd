# res://script/autoload/MonsterManager.gd
extends Node

const MONSTER_DATA_PATH = "res://Data/monsters.json"
var _monster_database: Dictionary = {}

func _ready():
	var file = FileAccess.open(MONSTER_DATA_PATH, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error("Khong the mo file du lieu quai vat: " + MONSTER_DATA_PATH)
		return

	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("Loi doc file JSON quai vat: " + json.get_error_message())
		return

	_monster_database = json.get_data()
	print("Da tai xong co so du lieu quai vat!")

func get_monster_data(monster_id: String) -> Dictionary:
	if _monster_database.has(monster_id):
		return _monster_database[monster_id]
	else:
		push_error("Khong tim thay quai vat voi ID: " + monster_id)
		return {}
