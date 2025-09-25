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
func _populate_recipe_grid(recipes: Array):
	# Dọn dẹp các slot cũ
	for child in recipe_grid.get_children():
		child.queue_free()

	# BƯỚC 1: Đặt ra số lượng slot cố định
	var total_slots = 100
	var num_recipes = recipes.size()

	# BƯỚC 2: Chạy một vòng lặp cố định 100 lần để tạo slot
	for i in range(total_slots):
		var recipe_slot = preload("res://Scene/UI/item_slot.tscn").instantiate()
		recipe_grid.add_child(recipe_slot)

		# BƯỚC 3: Kiểm tra xem có công thức tương ứng cho ô này không
		if i < num_recipes:
			# NẾU CÓ: Lấp đầy ô bằng dữ liệu công thức
			var recipe = recipes[i]
			var result_item_id = recipe["result"]["item_id"]
			recipe_slot.display_item(ItemDatabase.get_item_icon(result_item_id), 1)

			if PlayerStats.can_craft(recipe):
				recipe_slot.modulate = Color(1, 1, 1)
				recipe_slot.pressed.connect(recipe_selected.emit.bind(recipe))
			else:
				recipe_slot.modulate = Color(0.5, 0.5, 0.5)
				recipe_slot.disabled = true
				recipe_slot.mouse_entered.connect(_on_locked_recipe_mouse_entered.bind(recipe))
				recipe_slot.mouse_exited.connect(_on_locked_recipe_mouse_exited)
		else:
			# NẾU KHÔNG: Đây là một ô trống
			recipe_slot.display_item(null, 0) # Hiển thị ô trống
			recipe_slot.disabled = true # Vô hiệu hóa để không click vào được

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
