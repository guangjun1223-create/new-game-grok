extends Node

# Hai biến để lưu trữ hai loại dữ liệu riêng biệt
var _game_data: Dictionary = {}      # Sẽ chứa dữ liệu từ game_data.json
var _crafting_data: Dictionary = {}  # Sẽ chứa dữ liệu từ crafting.json
enum ItemQuality { BI_HONG, KEM, THUONG, TOT, RAT_TOT, HIEM }

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
	
static func create_equipment_instance(base_item_id: String) -> Dictionary:
	var base_item_data = ItemDatabase.get_item_data(base_item_id)
	if base_item_data.is_empty() or base_item_data.get("item_type") != "EQUIPMENT":
		push_error("Loi: Khong the tao instance cho item khong phai trang bi: " + base_item_id)
		return {}

	# --- B1: Roll ngẫu nhiên để xác định chất lượng (Logic này giữ nguyên) ---
	var roll = randf()
	var quality: ItemQuality
	var quality_name: String
	var stat_modifier: float

	if roll < 0.27: # 27% Hỏng
		quality = ItemQuality.BI_HONG
	elif roll < 0.53: # 26% Kém (27% + 26%)
		quality = ItemQuality.KEM
		quality_name = "Kém"
		stat_modifier = 0.6
	elif roll < 0.83: # 30% Thường (53% + 30%)
		quality = ItemQuality.THUONG
		quality_name = "Thường"
		stat_modifier = 0.8
	elif roll < 0.93: # 10% Tốt (83% + 10%)
		quality = ItemQuality.TOT
		quality_name = "Tốt"
		stat_modifier = 1.0
	elif roll < 0.98: # 5% Rất Tốt (93% + 5%)
		quality = ItemQuality.RAT_TOT
		quality_name = "Rất Tốt"
		stat_modifier = 1.2
	else: # 2% Hiếm
		quality = ItemQuality.HIEM
		quality_name = "Hiếm"
		stat_modifier = 1.5

	# --- B2: Xử lý kết quả ---
	if quality == ItemQuality.BI_HONG:
		print("Chế tạo thất bại! Trang bị đã bị hỏng.")
		return {}

	var new_item_instance = base_item_data.duplicate(true)

	# === DÒNG SỬA LỖI QUAN TRỌNG ===
	# Thêm ID gốc vào instance mới để các hàm khác có thể nhận diện
	new_item_instance["id"] = base_item_id
	# ================================

	new_item_instance["quality"] = quality_name

	var base_stats = base_item_data.get("stats", {})
	var final_stats = {}
	for stat_name in base_stats:
		final_stats[stat_name] = int(round(base_stats[stat_name] * stat_modifier))

	new_item_instance["stats"] = final_stats
	new_item_instance["unique_id"] = Time.get_unix_time_from_system() + randi()

	print("Đã tạo ra trang bị: %s [%s]" % [base_item_id, quality_name])
	return new_item_instance
