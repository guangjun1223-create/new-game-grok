# res://script/autoload/MonsterDataManager.gd
extends Node

# --- CÁC CÔNG THỨC CÂN BẰNG CHO QUÁI VẬT ---
# Đây là nơi bạn sẽ tinh chỉnh độ khó của game sau này

# Hàm chính: Nhận "ADN" từ JSON, trả về một Dictionary chứa các chỉ số cuối cùng
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
	final_stats["max_hp"] = (level * 10) + (VIT * 8) # Quái vật thường có HP gốc cao hơn hero
	final_stats["def"] = VIT / 2.0
	final_stats["mdef"] = INTEL + (VIT / 5.0)
	
	# Chính xác & Né tránh
	final_stats["hit"] = level + DEX
	final_stats["flee"] = level + AGI
	final_stats["perfect_dodge"] = LUK / 10.0
	
	# Sát thương
	final_stats["min_atk"] = STR + (DEX / 5.0)
	final_stats["max_atk"] = final_stats["min_atk"] + (level / 2.0) # Sát thương quái ổn định hơn
	final_stats["min_matk"] = INTEL
	final_stats["max_matk"] = final_stats["min_matk"] + (level / 2.0)
	
	# Tấn công phụ
	final_stats["crit_rate"] = LUK / 3.0
	final_stats["crit_damage"] = 1.4 # Quái vật crit yếu hơn hero (140%)
	
	# Trả về bộ chỉ số hoàn chỉnh
	return final_stats
