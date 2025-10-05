# res://script/hero/HeroInventory.gd
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
	hero = get_parent()

func setup(starting_items: Array, starting_gold: int):
	self.gold = starting_gold; inventory.clear(); inventory.resize(HERO_INVENTORY_SIZE)
	for item_data in starting_items: add_item(item_data["id"], item_data["quantity"])
	inventory_changed.emit(); gold_changed.emit(gold)

func add_gold(amount: int):
	if amount == 0: return; gold += amount; gold_changed.emit(gold)

func add_item(item_id: String, quantity_to_add: int = 1) -> bool:
	var item_data = ItemDatabase.get_item_data(item_id); if item_data.is_empty(): return false
	var is_stackable = item_data.get("is_stackable", false)
	var max_stack = item_data.get("max_stack_size", 1); var quantity_left = quantity_to_add; var item_added = false
	if is_stackable:
		for i in range(inventory.size()):
			var slot = inventory[i]
			if slot and slot["id"] == item_id and slot["quantity"] < max_stack:
				var can_add = max_stack - slot["quantity"]; var add = min(quantity_left, can_add)
				slot["quantity"] += add; quantity_left -= add; item_added = true
				if quantity_left <= 0: inventory_changed.emit(); return true
		while quantity_left > 0:
			var found_slot = false
			for i in range(inventory.size()):
				if inventory[i] == null:
					var add = min(quantity_left, max_stack)
					inventory[i] = {"id": item_id, "quantity": add}
					quantity_left -= add; item_added = true; found_slot = true; break
			if not found_slot: break
	else:
		for _i in range(quantity_to_add):
			var found_slot = false
			for j in range(inventory.size()):
				if inventory[j] == null:
					inventory[j] = {"id": item_id, "quantity": 1}
					quantity_left -= 1; item_added = true; found_slot = true; break
			if not found_slot: break
	if item_added: inventory_changed.emit()
	return quantity_left <= 0

func remove_item_from_inventory(item_id: String, quantity_to_remove: int) -> bool:
	var quantity_left = quantity_to_remove
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if slot and slot["id"] == item_id:
			var remove = min(quantity_left, slot["quantity"])
			slot["quantity"] -= remove; quantity_left -= remove
			if slot["quantity"] <= 0: inventory[i] = null
			if quantity_left <= 0: inventory_changed.emit(); return true
	inventory_changed.emit(); return quantity_left <= 0

func equip_from_inventory(inventory_slot_index: int):
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.size(): return
	var item_package_to_equip = inventory[inventory_slot_index]
	if not item_package_to_equip: return
	
	var item_id_to_equip = item_package_to_equip.get("id")
	var item_data = ItemDatabase.get_item_data(item_id_to_equip)
	
	if item_data.get("item_type") != "EQUIPMENT":
		# (Tùy chọn: Xử lý logic cho Potion ở đây nếu bạn muốn trang bị Potion từ túi đồ)
		print("Vật phẩm này không phải là trang bị.")
		return

	var slot_key = item_data.get("equip_slot")
	if not equipment.has(slot_key): return
		
	var old_item_id = equipment.get(slot_key)
	
	# --- LOGIC SWAP MỚI, DỰA TRÊN CODE GỐC CỦA BẠN ---
	# 1. Nếu có vật phẩm cũ đang mặc...
	if old_item_id:
		# ...thì tìm một ô trống trong túi đồ để đặt nó vào.
		var empty_slot_index = -1
		for i in range(inventory.size()):
			# Bỏ qua chính ô đang chứa vật phẩm mới
			if i == inventory_slot_index: continue 
			if inventory[i] == null:
				empty_slot_index = i
				break
		
		# Nếu tìm thấy ô trống
		if empty_slot_index != -1:
			inventory[empty_slot_index] = {"id": old_item_id, "quantity": 1}
		# Nếu không tìm thấy ô trống (và ô đang click không phải là nơi duy nhất)
		else:
			# Kiểm tra xem có thể swap trực tiếp không (khi túi đồ chỉ còn đúng 1 ô trống là ô đang click)
			var can_direct_swap = true
			for item in inventory:
				if item == null:
					can_direct_swap = false
					break
			
			if can_direct_swap:
				inventory[inventory_slot_index] = {"id": old_item_id, "quantity": 1}
			else:
				print("Túi đồ đã đầy, không thể tháo trang bị cũ!")
				return # Dừng lại, không cho swap

	# 2. Dọn dẹp ô túi đồ của vật phẩm mới (nếu không phải là swap trực tiếp)
	if old_item_id == null or inventory[inventory_slot_index] != {"id": old_item_id, "quantity": 1}:
		inventory[inventory_slot_index] = null
	
	# 3. Mặc vật phẩm mới vào
	equipment[slot_key] = item_id_to_equip
	# ----------------------------------------------------

	# 4. Phát tín hiệu và cập nhật chỉ số
	equipment_changed.emit(equipment)
	inventory_changed.emit()

func unequip_item(slot_key: String):
	var item_to_unequip = equipment.get(slot_key); if not item_to_unequip: return
	var success = false
	if item_to_unequip is Dictionary: success = add_item(item_to_unequip["id"], item_to_unequip["quantity"])
	elif item_to_unequip is String: success = add_item(item_to_unequip, 1)
	if success:
		equipment[slot_key] = null
		equipment_changed.emit(equipment); inventory_changed.emit()

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

func save_data() -> Dictionary:
	return { "inventory": inventory, "equipment": equipment, "gold": gold }

func load_data(data: Dictionary):
	if data.is_empty(): return
	inventory = data.get("inventory", []).duplicate(true)
	equipment = data.get("equipment", {}).duplicate(true)
	gold = data.get("gold", 0)

func get_current_weapon_data() -> Dictionary:
	var weapon_id = equipment.get("MAIN_HAND")
	if not (weapon_id is String and not weapon_id.is_empty()):
		return {} # Trả về dictionary rỗng nếu không có vũ khí
	return ItemDatabase.get_item_data(weapon_id)
