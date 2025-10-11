# res://script/autoload/MonsterDataManager.gd
extends Node

# Biến để lưu trữ toàn bộ dữ liệu từ monsters.json
var _monster_database: Dictionary = {}

# Hàm này được Godot tự động gọi khi game khởi động
func _ready():
	var file = FileAccess.open("res://Data/monsters.json", FileAccess.READ)
	if not file:
		push_error("MonsterDataManager: Không thể mở file monsters.json!")
		return
		
	var content = file.get_as_text()
	var parse_result = JSON.parse_string(content)
	
	if parse_result:
		_monster_database = parse_result
		print("MonsterDataManager: Đã tải thành công dữ liệu quái vật.")
	else:
		push_error("MonsterDataManager: Lỗi khi đọc file JSON monsters.json!")


# --- HÀM BỊ THIẾU MÀ BẠN CẦN ---
# Hàm này lấy ra "sơ yếu lý lịch" của một quái vật dựa trên ID
func get_monster_definition(monster_id: String) -> Dictionary:
	if _monster_database.has(monster_id):
		return _monster_database[monster_id]
	
	# Trả về một dictionary rỗng nếu không tìm thấy để tránh lỗi
	return {}


# --- CÁC CÔNG THỨC CÂN BẰNG CHO QUÁI VẬT ---
# (Hàm calculate_final_stats của bạn giữ nguyên)
func calculate_final_stats(monster_data: Dictionary) -> Dictionary:
	var level = monster_data.get("level", 1)
	var base_stats = monster_data.get("base_stats", {})
	
	# Lấy các chỉ số gốc từ "ADN"
	var STR = base_stats.get("STR", 1)
	var AGI = base_stats.get("AGI", 1)
	var VIT = base_stats.get("VIT", 1)
	var INTEL = base_stats.get("INTEL", 1)
	var DEX = base_stats.get("DEX", 1)
	var LUK = base_stats.get("LUK", 1)
	
	# Bắt đầu tính toán các chỉ số phụ
	var final_stats = {}
	
	# Sinh tồn & Phòng thủ
	final_stats["max_hp"] = (level * 10) + (VIT * 8)
	final_stats["def"] = VIT / 2.0
	final_stats["mdef"] = INTEL + (VIT / 5.0)
	
	# Chính xác & Né tránh
	final_stats["hit"] = level + DEX
	final_stats["flee"] = level + AGI
	final_stats["perfect_dodge"] = LUK / 10.0
	
	# Sát thương
	final_stats["min_atk"] = STR + (DEX / 5.0)
	final_stats["max_atk"] = final_stats["min_atk"] + (level / 2.0)
	final_stats["min_matk"] = INTEL
	final_stats["max_matk"] = final_stats["min_matk"] + (level / 2.0)
	
	# Tấn công phụ
	final_stats["crit_rate"] = LUK / 3.0
	final_stats["crit_damage"] = 1.4
	
	final_stats["move_speed"] = monster_data.get("move_speed", 75)
	
	# Trả về bộ chỉ số hoàn chỉnh
	return final_stats
