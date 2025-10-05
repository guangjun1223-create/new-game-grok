# res://script/hero/hero_inventory.gd
extends Node
class_name HeroInventory

signal inventory_changed
signal equipment_changed(new_equipment)
signal gold_changed(new_gold_amount)
signal potion_cooldown_started(slot_key, duration)

var hero: Hero

const HERO_INVENTORY_SIZE: int = 20
var inventory: Array = []
var equipment: Dictionary = {
	"MAIN_HAND": null, "OFF_HAND": null, "HELMET": null, "ARMOR": null, "PANTS": null,
	"GLOVES": null, "BOOTS": null, "AMULET": null, "RING": null,
	"POTION_1": null, "POTION_2": null, "POTION_3": null
}
var _potion_cooldowns: Dictionary = {"POTION_1": 0.0, "POTION_2": 0.0, "POTION_3": 0.0}
var gold: int = 0

func _ready():
	# await get_parent().ready # Dòng này có thể không cần thiết nếu cấu trúc scene đơn giản
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
	var max_stack = item_data.get("max_stack_size", 1); var quantity_left = quantity_to_add
	var item_added = false
	if is_stackable:
		for i in range(inventory.size()):
			var slot = inventory[i]
			if slot and slot["id"] == item_id and slot["quantity"] < max_stack:
				var can_add_here = max_stack - slot["quantity"]
				var add_amount = min(quantity_left, can_add_here)
				slot["quantity"] += add_amount; quantity_left -= add_amount; item_added = true
				if quantity_left <= 0: inventory_changed.emit(); return true
		while quantity_left > 0:
			var found_empty_slot = false
			for i in range(inventory.size()):
				if inventory[i] == null:
					var add_amount = min(quantity_left, max_stack)
					inventory[i] = {"id": item_id, "quantity": add_amount}
					quantity_left -= add_amount; item_added = true; found_empty_slot = true
					break
			if not found_empty_slot: break
	else:
		for _i in range(quantity_to_add):
			var found_empty_slot = false
			for j in range(inventory.size()):
				if inventory[j] == null:
					inventory[j] = {"id": item_id, "quantity": 1}
					quantity_left -= 1; item_added = true; found_empty_slot = true
					break
			if not found_empty_slot: break
	if item_added: inventory_changed.emit()
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

func equip_from_inventory(inventory_slot_index: int):
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.size(): return
	var item_package_to_equip = inventory[inventory_slot_index]; if not item_package_to_equip: return
	var item_id_to_equip = item_package_to_equip.get("id"); var item_data = ItemDatabase.get_item_data(item_id_to_equip)
	var item_type = item_data.get("item_type")
	if item_type == "EQUIPMENT":
		var slot_key = item_data.get("equip_slot"); if not equipment.has(slot_key): return
		var old_equipped_item_id = equipment.get(slot_key)
		if old_equipped_item_id and not slot_key.begins_with("POTION"):
			var swapped = false
			for i in range(inventory.size()):
				if inventory[i] == null:
					inventory[i] = {"id": old_equipped_item_id, "quantity": 1}; swapped = true
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
	
	# Lấy và trả về toàn bộ dữ liệu của vũ khí từ Database
	return ItemDatabase.get_item_data(weapon_id)
