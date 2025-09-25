extends Node

# Hai biến để lưu trữ hai loại dữ liệu riêng biệt
var _game_data: Dictionary = {}      # Sẽ chứa dữ liệu từ game_data.json
var _crafting_data: Dictionary = {}  # Sẽ chứa dữ liệu từ crafting.json


func _ready():
	# Tải file dữ liệu game chính
	_load_json_file("res://Data/game_data.json", "_game_data")
	# Tải file dữ liệu chế tác
	_load_json_file("res://Data/crafting.json", "_crafting_data")

# Hàm phụ trợ để tải và kiểm tra lỗi cho file JSON
func _load_json_file(path: String, target_variable_name: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("GameDataManager: Khong the mo file: %s" % path)
		return
		
	var content = file.get_as_text()
	var parse_result = JSON.parse_string(content)
	
	if parse_result:
		# Sử dụng set() để gán dữ liệu vào biến có tên được truyền vào
		set(target_variable_name, parse_result)
		print("GameDataManager: Da tai thanh cong du lieu tu: %s" % path)
	else:
		push_error("GameDataManager: Loi khi doc file JSON: %s" % path)


# --- CÁC HÀM LẤY DỮ LIỆU TỪ _game_data ---

func get_hero_definition(job_key: String) -> Dictionary:
	if _game_data.has("heroes") and _game_data["heroes"].has(job_key):
		return _game_data["heroes"][job_key]
	return {}

func get_job_display_name(job_key: String) -> String:
	if _game_data.has("job_classes") and _game_data["job_classes"].has(job_key):
		return _game_data["job_classes"][job_key]
	return job_key

func tao_ten_ngau_nhien() -> String:
	if not _game_data.has("names"): return "Nguoi Vo Danh"
	var names = _game_data["names"]
	var first = names["first_names"].pick_random()
	var middle = names["middle_names"].pick_random()
	var last = names["surnames"].pick_random()
	return "%s %s %s" % [last, middle, first]


# --- HÀM LẤY DỮ LIỆU TỪ _crafting_data ---

func get_recipes_for_station(station_type: String) -> Array:
	if _crafting_data.has(station_type):
		return _crafting_data[station_type]
	
	push_error("GameDataManager: Khong tim thay cong thuc cho tram che tac: '%s'" % station_type)
	return []
	
func get_inn_level_data(level: int) -> Dictionary:
	var level_str = str(level)
	if _game_data.has("inn_levels") and _game_data["inn_levels"].has(level_str):
		return _game_data["inn_levels"][level_str]
	return {} # Trả về dictionary rỗng nếu không tìm thấy

func get_village_level_data(level_string: String) -> Dictionary:
	# Kiểm tra xem khóa "village_levels" có tồn tại trong dữ liệu game không
	if not _game_data.has("village_levels"):
		push_error("GameDataManager: Không tìm thấy mục 'village_levels' trong game_data.json!")
		return {}

	var village_data = _game_data["village_levels"]
	
	# Trả về dữ liệu cho cấp độ được yêu cầu, hoặc một Dictionary rỗng nếu không tìm thấy
	return village_data.get(level_string, {})
