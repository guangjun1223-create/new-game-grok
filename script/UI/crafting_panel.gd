# Script CraftingPanel.gd
extends PanelContainer

const RecipeTooltipScene = preload("res://Scene/UI/RecipeTooltip.tscn")
var recipe_tooltip_instance = null

# Tín hiệu sẽ được phát ra khi người chơi chọn một công thức
signal recipe_selected(recipe)
# Tín hiệu sẽ được phát ra khi người chơi đóng bảng
signal panel_closed

# Tham chiếu đến các Node con
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var recipe_grid: GridContainer = $VBoxContainer/ScrollContainer/RecipeGrid
@onready var close_button: Button = $VBoxContainer/CloseButton

# Hàm này sẽ được gọi từ bên ngoài (bởi ui.gd) để khởi tạo bảng
func setup(station_type: String):
	if station_type == "blacksmith":
		title_label.text = "Rèn Trang Bị"
	elif station_type == "alchemist":
		title_label.text = "Điều Chế Thuốc"
	
	var recipes = GameDataManager.get_recipes_for_station(station_type)
	_populate_recipe_grid(recipes)
	
	close_button.pressed.connect(_on_close_button_pressed)

func _process(_delta):
	# Nếu tooltip đang tồn tại và đang hiển thị...
	if is_instance_valid(recipe_tooltip_instance) and recipe_tooltip_instance.visible:
		# ...thì liên tục cập nhật vị trí của nó theo con trỏ chuột
		recipe_tooltip_instance.position = get_viewport().get_mouse_position() + Vector2(25, 25)


# Hàm "vẽ" các công thức lên lưới
# THAY THẾ TOÀN BỘ HÀM CŨ BẰNG PHIÊN BẢN NÀY
func _populate_recipe_grid():
	# Dọn dẹp các slot cũ
	for child in recipe_grid.get_children():
		child.queue_free()

	# Lấy danh sách ID của các công thức
	var recipe_ids = GameDataManager.get_recipes_for_station(_station_type)

	for recipe_id in recipe_ids:
		# Lấy dữ liệu đầy đủ của công thức từ ID
		var recipe_data = GameDataManager.get_recipe_data(recipe_id)
		if recipe_data.is_empty(): continue

		var result_item_id = recipe_data["result_id"]
		var recipe_slot = preload("res://Scene/UI/item_slot.tscn").instantiate()
		recipe_grid.add_child(recipe_slot)
		recipe_slot.display_item(ItemDatabase.get_item_icon(result_item_id), 1)

		# --- LOGIC MỚI ĐÃ SỬA LỖI ---
		# 1. Luôn luôn kết nối tín hiệu cho tooltip, bất kể có chế được hay không
		recipe_slot.mouse_entered.connect(_on_recipe_mouse_entered.bind(recipe_id))
		recipe_slot.mouse_exited.connect(_on_recipe_mouse_exited)

		# 2. Dùng dữ liệu đầy đủ của công thức để kiểm tra
		var can_craft = PlayerStats.can_craft_recipe(recipe_id)

		if can_craft:
			# 3. Nếu chế được, làm nó sáng lên VÀ kết nối nút bấm
			recipe_slot.modulate = Color(1, 1, 1)
			recipe_slot.pressed.connect(_on_craftable_recipe_pressed.bind(recipe_id))
		else:
			# 4. Nếu không chế được, chỉ làm nó mờ đi. Click sẽ không có tác dụng.
			recipe_slot.modulate = Color(0.5, 0.5, 0.5)



func _on_close_button_pressed():
	panel_closed.emit()
	queue_free() # Tự hủy

func _on_locked_recipe_mouse_entered(recipe: Dictionary):
	if is_instance_valid(recipe_tooltip_instance):
		recipe_tooltip_instance.queue_free()

	recipe_tooltip_instance = RecipeTooltipScene.instantiate()
	add_child(recipe_tooltip_instance)
	recipe_tooltip_instance.build_tooltip(recipe)

	# === THAY ĐỔI QUAN TRỌNG ===
	# Chỉ ra lệnh "hiện", việc định vị sẽ do _process lo
	recipe_tooltip_instance.show()

func _on_locked_recipe_mouse_exited():
	if is_instance_valid(recipe_tooltip_instance):
		# Chỉ cần ẩn đi, không cần xóa
		recipe_tooltip_instance.hide()
