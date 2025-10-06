extends Node

# Hai biến để lưu trữ hai loại dữ liệu riêng biệt
var _game_data: Dictionary = {}      # Sẽ chứa dữ liệu từ game_data.json
var _crafting_data: Dictionary = {}  # Sẽ chứa dữ liệu từ crafting.json
var _job_change_data: Dictionary = {}
enum ItemQuality { BI_HONG, KEM, THUONG, TOT, RAT_TOT, HIEM }

func _ready():
	# Tải file dữ liệu game chính
	_load_json_file("res://Data/game_data.json", "_game_data")
	# Tải file dữ liệu chế tác
	_load_json_file("res://Data/crafting.json", "_crafting_data")
	_load_job_change_data()

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
	
func get_job_change_requirements() -> Dictionary:
	# Lấy yêu cầu cụ thể cho việc chuyển từ nghề "Novice"
	if _job_change_data.has("Novice"):
		return _job_change_data["Novice"]
	
	# Nếu không tìm thấy, trả về một dictionary rỗng để tránh lỗi
	push_warning("GameDataManager: Không tìm thấy yêu cầu chuyển nghề cho 'Novice' trong job_change.json.")
	return {}
	
func _load_job_change_data():
	var file_path = "res://Data/job_change.json"
	if not FileAccess.file_exists(file_path):
		push_error("LỖI: Không tìm thấy file job_change.json tại: %s" % file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		push_error("LỖI: Dữ liệu trong job_change.json bị lỗi!")
		return
	_job_change_data = parse_result
	
func get_max_upgrade_level() -> int:
	return 20

func get_upgrade_gold_cost(current_level: int) -> int:
	if current_level <= 9: # Từ +0 -> +9 (để lên +1 đến +10)
		return 10000
	else: # Từ +10 -> +19 (để lên +11 đến +20)
		return 20000

func get_upgrade_stone_cost(current_level: int) -> int:
	# Chi phí đá = cấp độ tiếp theo
	return current_level + 1

# Hàm này tính toán tỉ lệ và hình phạt dựa trên cấp độ hiện tại của trang bị
func get_upgrade_info(current_level: int) -> Dictionary:
	var success_rate = 0.0
	var penalty = "none"

	if current_level <= 4: # Lên +1 đến +5
		success_rate = 100.0
		penalty = "none"
	elif current_level <= 14: # Lên +6 đến +15
		# Tỉ lệ giảm từ 90% ở +5 xuống 10% ở +14
		success_rate = 90.0 - (current_level - 5) * 8.0 
		penalty = "lose_materials"
	elif current_level <= 19: # Lên +16 đến +20
		# Tỉ lệ giảm từ 10% ở +15 xuống 1% ở +19
		success_rate = 10.0 - (current_level - 15) * 2.25
		penalty = "destroy_item"

	return {
		"success_rate": clamp(success_rate, 1.0, 100.0), # Đảm bảo tỉ lệ không bao giờ dưới 1%
		"penalty_on_fail": penalty
	}
	
