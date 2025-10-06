# res://script/UI/upgrade_panel.gd
extends Control

const ItemSlotScene = preload("res://Scene/UI/item_slot.tscn") 

# Biến để lưu trạng thái
var current_hero: Hero
var upgrade_type: String # Sẽ là "weapon" hoặc "armor"
var selected_item_instance: Variant
var selected_item_slot_index: int = -1

# Tham chiếu đến các node trong scene (nhờ có % nên đường dẫn rất gọn)
@onready var hero_inventory_grid: GridContainer = $Panel/HBoxContainer/PanelContainer/ScrollContainer/HeroInventoryGrid
@onready var title_label: Label = $Panel/HBoxContainer/VBoxContainer/TitleLabel
@onready var item_to_upgrade_slot: ItemSlot = $Panel/HBoxContainer/VBoxContainer/ItemToUpgradeSlot
@onready var info_label: RichTextLabel = $Panel/HBoxContainer/VBoxContainer/InfoLabel
@onready var upgrade_button: Button = $Panel/HBoxContainer/VBoxContainer/HBoxContainer/UpgradeButton
@onready var cancel_button: Button = $Panel/HBoxContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var close_button: Button = $Panel/CloseButton

func _ready():
	# Kết nối tín hiệu của các nút bấm
	cancel_button.pressed.connect(queue_free) # Nút "Bỏ đi" sẽ tự hủy panel
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	close_button.pressed.connect(queue_free)
	hide() # Mặc định ẩn panel này đi

# Hàm này được gọi từ bên ngoài (ui.gd) để mở và thiết lập panel
func setup(hero: Hero, type: String):
	current_hero = hero
	upgrade_type = type
	title_label.text = "Tiệm Rèn - Nâng Cấp " + ("Vũ Khí" if type == "weapon" else "Trang Bị")

	_update_hero_inventory_grid()
	_clear_selection()
	show()

# Cập nhật danh sách đồ bên trái
func _update_hero_inventory_grid():
	# 1. Xóa các slot cũ đi
	for child in hero_inventory_grid.get_children():
		child.queue_free()

	var inventory = current_hero.hero_inventory.inventory
	var inventory_size = current_hero.hero_inventory.HERO_INVENTORY_SIZE

	# 2. Lặp qua TẤT CẢ các ô trong túi đồ (kể cả ô trống)
	for i in range(inventory_size):
		var slot = ItemSlotScene.instantiate()
		hero_inventory_grid.add_child(slot)
		
		var item_instance = inventory[i]
		
		# 3. Kiểm tra xem ô này có chứa trang bị không
		if item_instance is Dictionary and item_instance.has("base_id"):
			var item_data = ItemDatabase.get_item_data(item_instance.base_id)
			var is_weapon = item_data.has("weapon_type")
			var icon = ItemDatabase.get_item_icon(item_instance.base_id)
			
			# Hiển thị item lên slot
			slot.display_item(icon, item_instance.upgrade_level)
			
			# 4. Kiểm tra xem item có ĐÚNG LOẠI đang cần nâng cấp không
			if (upgrade_type == "weapon" and is_weapon) or (upgrade_type == "armor" and not is_weapon):
				# Nếu ĐÚNG: slot bình thường, có thể tương tác
				slot.disabled = false
				slot.modulate = Color.WHITE
				slot.pressed.connect(_on_item_selected.bind(item_instance, i))
			else:
				# Nếu SAI loại: làm mờ slot và không cho tương tác
				slot.disabled = true
				slot.modulate = Color(0.5, 0.5, 0.5, 0.8) # Màu xám mờ
		else:
			# 5. Nếu ô này trống (null), hiển thị ô trống và không cho tương tác
			slot.display_item(null, 0)
			slot.disabled = true

# Reset khung hiển thị bên phải về mặc định
func _clear_selection():
	selected_item_instance = null
	selected_item_slot_index = -1
	item_to_upgrade_slot.display_item(null, 0)
	info_label.text = "Hãy chọn một trang bị từ túi đồ bên trái."
	upgrade_button.disabled = true

# Hàm được gọi khi người chơi click vào một món đồ ở túi đồ bên trái
func _on_item_selected(item_inst: Dictionary, slot_index: int):
	selected_item_instance = item_inst
	selected_item_slot_index = slot_index

	var base_id = item_inst.base_id
	var current_level = item_inst.upgrade_level
	var item_data = ItemDatabase.get_item_data(base_id)

	# Cập nhật ô hiển thị item được chọn
	item_to_upgrade_slot.display_item(ItemDatabase.get_item_icon(base_id), current_level)

	var max_level = GameDataManager.get_max_upgrade_level()
	if current_level >= max_level:
		info_label.text = "Trang bị này đã đạt cấp tối đa."
		upgrade_button.disabled = true
		return

	var next_level = current_level + 1
	var upgrade_info = GameDataManager.get_upgrade_info(current_level)
	var success_rate = upgrade_info.get("success_rate", 0.0)

	var stone_id = "weapon_upgrade_stone" if upgrade_type == "weapon" else "armor_upgrade_stone"
	var stone_data = ItemDatabase.get_item_data(stone_id)
	var stones_owned = PlayerStats.get_item_quantity_in_warehouse(stone_id)
	var stones_required = GameDataManager.get_upgrade_stone_cost(current_level)
	
	var gold_required = GameDataManager.get_upgrade_gold_cost(current_level)
	var gold_owned_by_hero = current_hero.hero_inventory.gold
	# ===================================================

	# Tạo chuỗi thông tin hiển thị cho người chơi
	var info_text = "Bạn có chắc chắn rèn [b]%s[/b] lên [color=lime]+%d[/color]?\n\n" % [item_data.item_name, next_level]
	info_text += "Tỉ lệ thành công: [color=yellow]%.1f%%[/color]\n\n" % success_rate
	info_text += "Bạn sẽ mất:\n"
	info_text += "- %d x %s (Hiện có: %d)\n" % [stones_required, stone_data.item_name, stones_owned]
	info_text += "- [color=gold]%s Vàng[/color] (Hero đang có: %s)" % [Utils.format_number(gold_required), Utils.format_number(gold_owned_by_hero)]
	
	info_label.bbcode_enabled = true
	info_label.text = info_text

	upgrade_button.text = "Đồng ý rèn"
	# Sửa lại điều kiện vô hiệu hóa nút bấm
	upgrade_button.disabled = (stones_owned < stones_required or gold_owned_by_hero < gold_required)

# Hàm được gọi khi người chơi nhấn nút "Đồng ý rèn"
func _on_upgrade_button_pressed():
	if not selected_item_instance: return

	var current_level = selected_item_instance.upgrade_level
	
	var upgrade_info = GameDataManager.get_upgrade_info(current_level)
	var success_rate = upgrade_info.get("success_rate", 0.0)
	
	var stone_id = "weapon_upgrade_stone" if upgrade_type == "weapon" else "armor_upgrade_stone"
	var stones_required = GameDataManager.get_upgrade_stone_cost(current_level)
	var gold_required = GameDataManager.get_upgrade_gold_cost(current_level)
	
	if PlayerStats.get_item_quantity_in_warehouse(stone_id) < stones_required:
		FloatingTextManager.show_text("Không đủ đá!", Color.RED, global_position)
		return
	# Kiểm tra vàng
	if current_hero.hero_inventory.gold < gold_required:
		FloatingTextManager.show_text("Hero không đủ vàng!", Color.RED, global_position)
		return
		
	PlayerStats.remove_item_from_warehouse(stone_id, stones_required)
	current_hero.hero_inventory.add_gold(-gold_required)
	PlayerStats.add_gold_to_player(gold_required)

	# Quay số may rủi
	if randf() * 100 < success_rate:
		# THÀNH CÔNG
		selected_item_instance["upgrade_level"] += 1
		FloatingTextManager.show_text("NÂNG CẤP THÀNH CÔNG!", Color.LIME, global_position)
	else:
		# THẤT BẠI
		FloatingTextManager.show_text("NÂNG CẤP THẤT BẠI!", Color.RED, global_position)
		var penalty = upgrade_info.get("penalty_on_fail", "none")
		if penalty == "destroy_item":
			# Xóa item khỏi túi của hero
			current_hero.hero_inventory.inventory[selected_item_slot_index] = null
			_clear_selection()

	# Cập nhật lại toàn bộ giao diện sau khi nâng cấp
	_update_hero_inventory_grid()
	if selected_item_instance:
		_on_item_selected(selected_item_instance, selected_item_slot_index)

	# Cập nhật chỉ số và lưu game
	current_hero.hero_stats.update_secondary_stats()
	PlayerStats.save_game()
	
