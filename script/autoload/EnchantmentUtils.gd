# res://script/autoload/EnchantmentUtils.gd
extends Node

# Bảng tỷ lệ thành công (tính bằng %) cho mỗi cấp độ từ +0 -> +19
# Ví dụ: SUCCESS_RATES[0] là tỷ lệ để đập từ +0 lên +1
const SUCCESS_RATES = [
	100, 100, 100, 100, 100, # +0 -> +5
	90, 80, 70, 60, 50,     # +5 -> +10
	45, 40, 35, 30, 25,     # +10 -> +15
	20, 15, 10, 8, 5         # +15 -> +20
]

# Hàm để lấy tỷ lệ thành công dựa trên cấp hiện tại của trang bị
static func get_success_rate(current_level: int) -> int:
	if current_level < 0 or current_level >= SUCCESS_RATES.size():
		return 0 # Không thể cường hóa nếu cấp độ không hợp lệ
	return SUCCESS_RATES[current_level]

# Hàm để lấy số lượng đá cần thiết cho mỗi lần cường hóa
static func get_required_materials(item_data: Dictionary) -> Dictionary:
	var level = item_data.get("enchant_level", 0)
	var amount = 1 + floori(level / 5.0) # Cứ 5 cấp lại tốn thêm 1 viên

	var weapon_type = item_data.get("weapon_type")
	if weapon_type in ["SWORD", "DAGGER", "STAFF", "BOW"]:
		return {"id": "weapon_upgrade_stone", "quantity": amount}
	else: # Mũ, áo, giày, khiên...
		return {"id": "armor_upgrade_stone", "quantity": amount}

# Chúng ta sẽ viết hàm chính để xử lý việc cường hóa ở bước tiếp theo
static func attempt_enchant(item_data: Dictionary) -> Dictionary:
	# TODO: Sẽ viết ở bước sau
	return {"success": false, "item_destroyed": false, "new_item_data": item_data}
