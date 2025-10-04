# res://script/autoload/AppearanceDatabase.gd
extends Node

var _appearance_data: Dictionary = {}

func _ready():
	var file = FileAccess.open("res://Data/appearance_data.json", FileAccess.READ)
	if not file:
		push_error("AppearanceDatabase: Không thể mở file appearance_data.json!")
		return
	var content = file.get_as_text()
	var parse_result = JSON.parse_string(content)
	if parse_result:
		_appearance_data = parse_result
		# === THÊM LỆNH GHI ÂM SỐ 1 ===

func get_all_faces() -> Array:
	if _appearance_data.has("faces"):
		return _appearance_data.faces
	return [] # Trả về mảng rỗng nếu không có

# Hàm trả về toàn bộ danh sách mũ/tóc
func get_all_helmets() -> Array:
	if _appearance_data.has("helmets"):
		return _appearance_data.helmets
	return []

# Hàm trả về toàn bộ danh sách bộ giáp
func get_all_armor_sets() -> Array:
	if _appearance_data.has("armor_sets"):
		return _appearance_data.armor_sets
	return []


# Hàm lấy một khuôn mặt ngẫu nhiên
func get_random_face() -> String:
	if _appearance_data.has("faces") and not _appearance_data.faces.is_empty():
		var random_face_data: Dictionary = _appearance_data.faces.pick_random()
		# SỬA LỖI: Lấy "path" từ random_face_data
		return random_face_data.get("path", "")
	return ""

# Hàm lấy một chiếc mũ ngẫu nhiên
func get_random_helmet() -> String:
	if _appearance_data.has("helmets") and not _appearance_data.helmets.is_empty():
		var random_helmet_data: Dictionary = _appearance_data.helmets.pick_random()
		# SỬA LỖI: Lấy "path" từ random_helmet_data
		return random_helmet_data.get("path", "")
	return ""


# Hàm lấy một bộ giáp ngẫu nhiên
func get_random_armor_set() -> Dictionary:
	if _appearance_data.has("armor_sets") and not _appearance_data.armor_sets.is_empty():
		# Trả về cả Dictionary của bộ giáp
		return _appearance_data.armor_sets.pick_random()
	return {} # Trả về Dictionary rỗng nếu không có
