# res://script/hero/hero_inventory.gd
extends Node
class_name HeroInventory

signal inventory_changed
signal equipment_changed(new_equipment)
signal gold_changed(new_gold_amount)

var hero: Hero

const HERO_INVENTORY_SIZE: int = 20
var inventory: Array = []
var equipment: Dictionary = {
	"MAIN_HAND": null, "OFF_HAND": null, "HELMET": null, "ARMOR": null, "PANTS": null,
	"GLOVES": null, "BOOTS": null, "AMULET": null, "RING": null,
	"POTION_1": null, "POTION_2": null, "POTION_3": null
}
var gold: int = 0

func _ready():
	# await get_parent().ready # Dòng này có thể không cần thiết nếu cấu trúc scene đơn giản
	hero = get_parent()

func setup(starting_items: Array, starting_gold: int):
	self.gold = starting_gold; inventory.clear(); inventory.resize(HERO_INVENTORY_SIZE)
	for item_data in starting_items: add_item(item_data["id"], item_data["quantity"])
	inventory_changed.emit(); gold_changed.emit(gold)

func add_gold(amount: int):
	if amount == 0:
		return
	gold += amount
	gold_changed.emit(gold)

func add_item(item_id: String, quantity_to_add: int = 1) -> bool:
	var item_data = ItemDatabase.get_item_data(item_id)
	if item_data.is_empty(): 
		return false

	var is_stackable = item_data.get("is_stackable", false)
	var items_added_successfully = true

	# --- LOGIC MỚI CHO TRANG BỊ (KHÔNG XẾP CHỒNG) ---
	if not is_stackable:
		var items_added_count = 0
		for _i in range(quantity_to_add):
			var found_empty_slot = false
			for j in range(inventory.size()):
				if inventory[j] == null:
					# Tạo một instance mới cho trang bị với cấu trúc nâng cấp
					var new_instance = {
						"instance_id": _generate_unique_id(),
						"base_id": item_id,
						"upgrade_level": 0
					}
					inventory[j] = new_instance
					items_added_count += 1
					found_empty_slot = true
					break # Đã tìm thấy chỗ, thoát vòng lặp tìm slot
			if not found_empty_slot:
				items_added_successfully = false # Không tìm thấy slot trống
				break # Dừng lại nếu hết chỗ trong túi đồ
		
		if items_added_count > 0:
			inventory_changed.emit()
		return items_added_successfully

	# --- LOGIC CHO VẬT PHẨM XẾP CHỒNG (is_stackable == true) ---
	else:
		var max_stack = item_data.get("max_stack_size", 999)
		var quantity_left = quantity_to_add
		
		# Vòng 1: Tìm các chồng có sẵn để cộng dồn
		for i in range(inventory.size()):
			var slot = inventory[i]
			# Lưu ý: Vật phẩm xếp chồng dùng key "id", trang bị dùng "base_id"
			if slot and slot.get("id") == item_id and slot.get("quantity", 0) < max_stack:
				var can_add = max_stack - slot["quantity"]
				var add_amount = min(quantity_left, can_add)
				slot["quantity"] += add_amount
				quantity_left -= add_amount
				if quantity_left <= 0: break
		
		# Vòng 2: Nếu vẫn còn, tìm ô trống để tạo chồng mới
		if quantity_left > 0:
			for i in range(inventory.size()):
				if inventory[i] == null:
					var add_amount = min(quantity_left, max_stack)
					inventory[i] = {"id": item_id, "quantity": add_amount}
					quantity_left -= add_amount
					if quantity_left <= 0: break
		
		inventory_changed.emit()
		return quantity_left <= 0

func remove_item_from_inventory(item_id: String, quantity_to_remove: int) -> bool:
	var quantity_left = quantity_to_remove
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if slot and slot["id"] == item_id:
			var remove_amount = min(quantity_left, slot["quantity"])
			slot["quantity"] -= remove_amount; quantity_left -= remove_amount
			if slot["quantity"] <= 0: inventory[i] = null
			if quantity_left <= 0: inventory_changed.emit(); return true
	inventory_changed.emit()
	return quantity_left <= 0
	
func _is_weapon_compatible(job_key: String, item_data: Dictionary) -> bool:
	var equip_slot = item_data.get("equip_slot")

	# 1. Nếu không phải là trang bị tay chính hoặc tay phụ, luôn cho phép
	if equip_slot != "MAIN_HAND" and equip_slot != "OFF_HAND":
		return true

	# 2. Lấy các thuộc tính quan trọng của item
	var weapon_type = item_data.get("weapon_type", "") # Ví dụ: "SWORD", "STAFF"
	var is_shield = item_data.get("is_shield", false)  # Ví dụ: true hoặc false

	# 3. Kiểm tra logic theo từng nghề
	match job_key:
		"Swordsman":
			# Tay chính phải là Kiếm, tay phụ phải là Khiên
			if (equip_slot == "MAIN_HAND" and weapon_type == "SWORD") or (equip_slot == "OFF_HAND" and is_shield):
				return true
		"Mage":
			if equip_slot == "MAIN_HAND" and weapon_type == "STAFF":
				return true
		"Archer":
			if equip_slot == "MAIN_HAND" and weapon_type == "BOW":
				return true
		"Thief":
			if weapon_type == "DAGGER": # Cho phép cầm dao cả 2 tay
				return true
		"Acolyte":
			# Tay chính là Gậy phép, tay phụ là Khiên
			if (equip_slot == "MAIN_HAND" and weapon_type == "STAFF") or (equip_slot == "OFF_HAND" and is_shield):
				return true
		_:
			# Các nghề khác (Novice) được dùng mọi thứ
			return true

	# Nếu không rơi vào các trường hợp được phép ở trên, trả về false
	return false

func equip_from_inventory(inventory_slot_index: int):
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.size(): return
	var item_package_to_equip = inventory[inventory_slot_index]; if not item_package_to_equip: return
	
	var item_id_to_equip = item_package_to_equip.get("id"); var item_data = ItemDatabase.get_item_data(item_id_to_equip)
	var item_type = item_data.get("item_type")
	
	if not _is_weapon_compatible(hero.hero_stats.job_key, item_data):
		print("Không thể trang bị '%s'. Không phù hợp với nghề '%s'." % [item_data.get("name", item_id_to_equip), hero.hero_stats.job_key])
		FloatingTextManager.show_text("Không thể trang bị!", Color.RED, hero.global_position - Vector2(0, 150))
		return # Dừng hàm tại đây
	
	if item_type == "EQUIPMENT":
		var slot_key = item_data.get("equip_slot");
		if not equipment.has(slot_key): return
		var old_equipped_item_id = equipment.get(slot_key)
		if old_equipped_item_id and not slot_key.begins_with("POTION"):
			var swapped = false
			for i in range(inventory.size()):
				if inventory[i] == null:
					inventory[i] = {"id": old_equipped_item_id, "quantity": 1};
					swapped = true
					break
			if not swapped: return
		equipment[slot_key] = item_id_to_equip; inventory[inventory_slot_index] = null
	elif item_type == "CONSUMABLE":
		var quantity_to_add = item_package_to_equip.get("quantity", 1)
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			var existing_package = equipment.get(slot_key)
			if existing_package != null and existing_package.get("id") == item_id_to_equip:
				existing_package["quantity"] += quantity_to_add; inventory[inventory_slot_index] = null
				equipment_changed.emit(equipment); inventory_changed.emit()
				# ======================================================
				# SỬA LỖI: Báo cho hero vẽ lại hình ảnh
				if is_instance_valid(hero): hero._update_equipment_visuals()
				# ======================================================
				return
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			if equipment.get(slot_key) == null:
				equipment[slot_key] = item_package_to_equip; inventory[inventory_slot_index] = null
				equipment_changed.emit(equipment); inventory_changed.emit()
				# ======================================================
				# SỬA LỖI: Báo cho hero vẽ lại hình ảnh
				if is_instance_valid(hero): hero._update_equipment_visuals()
				# ======================================================
				return
		return
	else: return
	equipment_changed.emit(equipment); inventory_changed.emit()
	# ======================================================
	# SỬA LỖI: Báo cho hero vẽ lại hình ảnh sau khi mặc đồ
	if is_instance_valid(hero):
		hero._update_equipment_visuals()
	# ======================================================
	PlayerStats.save_game()

func unequip_item(slot_key: String):
	var item_to_unequip = equipment.get(slot_key); if not item_to_unequip: return
	var success = false
	if item_to_unequip is Dictionary: success = add_item(item_to_unequip["id"], item_to_unequip["quantity"])
	elif item_to_unequip is String: success = add_item(item_to_unequip, 1)
	if success:
		equipment[slot_key] = null
		equipment_changed.emit(equipment); inventory_changed.emit()
		# ======================================================
		# SỬA LỖI: Báo cho hero vẽ lại hình ảnh sau khi tháo đồ
		if is_instance_valid(hero):
			hero._update_equipment_visuals()
		# ======================================================
	PlayerStats.save_game()

func unequip_invalid_items_after_job_change():
	var current_job = hero.hero_stats.job_key
	
	# Kiểm tra vũ khí tay chính
	var main_hand_id = equipment.get("MAIN_HAND")
	if main_hand_id is String and not main_hand_id.is_empty():
		var item_data = ItemDatabase.get_item_data(main_hand_id)
		if not _is_weapon_compatible(current_job, item_data):
			unequip_item("MAIN_HAND")
			print("Đã tự động tháo vũ khí chính không phù hợp.")

	# Kiểm tra vũ khí/khiên tay phụ
	var off_hand_id = equipment.get("OFF_HAND")
	if off_hand_id is String and not off_hand_id.is_empty():
		var item_data = ItemDatabase.get_item_data(off_hand_id)
		if not _is_weapon_compatible(current_job, item_data):
			unequip_item("OFF_HAND")
			print("Đã tự động tháo trang bị tay phụ không phù hợp.")
	PlayerStats.save_game()

func apply_equipment_stats(stats_component: HeroStats):
	for slot in equipment:
		var item_id = equipment[slot]
		if typeof(item_id) == TYPE_STRING and not item_id.is_empty():
			stats_component.apply_item_stats(item_id)


func get_current_weapon_type() -> String:
	var weapon_id = equipment.get("MAIN_HAND")
	if not (weapon_id is String and not weapon_id.is_empty()): return "UNARMED"
	var data = ItemDatabase.get_item_data(weapon_id)
	if data.is_empty(): return "UNARMED"
	return data.get("weapon_type", "SWORD")
	
func get_current_weapon_data() -> Dictionary:
	var weapon_id = equipment.get("MAIN_HAND")
	# Nếu không có vũ khí, trả về một dictionary rỗng
	if not (weapon_id is String and not weapon_id.is_empty()):
		return {}
	# Nếu có, lấy dữ liệu từ database và trả về
	return ItemDatabase.get_item_data(weapon_id)

func save_data() -> Dictionary:
	return { "inventory": inventory, "equipment": equipment, "gold": gold }

func load_data(data: Dictionary):
	if data.is_empty(): return
	inventory = data.get("inventory", []).duplicate(true)
	equipment = data.get("equipment", {}).duplicate(true)
	gold = data.get("gold", 0)

func get_item_quantity(item_id: String) -> int:
	var total_quantity = 0
	# Lặp qua tất cả các ô trong túi đồ
	for item_info in inventory:
		# Nếu ô có đồ và đúng ID chúng ta đang tìm
		if item_info and item_info.get("id") == item_id:
			# Cộng dồn số lượng vào tổng
			total_quantity += item_info.get("quantity", 0)
	# Trả về tổng số lượng đếm được
	return total_quantity
	
func _generate_unique_id() -> String:
	return "item_%s_%s" % [Time.get_unix_time_from_system(), randi()]
