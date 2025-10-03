# Script CraftingPanel.gd (Đã sửa lỗi và tối ưu)
extends PanelContainer

const RecipeTooltipScene = preload("res://Scene/UI/RecipeTooltip.tscn")
var recipe_tooltip_instance = null

signal recipe_selected(recipe)
signal panel_closed

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var recipe_grid: GridContainer = $VBoxContainer/ScrollContainer/RecipeGrid
@onready var close_button: Button = $VBoxContainer/CloseButton

func setup(station_type: String):
	if station_type == "blacksmith":
		title_label.text = "Rèn Trang Bị"
	elif station_type == "alchemist":
		title_label.text = "Điều Chế Thuốc"
	
	var recipes = GameDataManager.get_recipes_for_station(station_type)
	_populate_recipe_grid(recipes)
	
	close_button.pressed.connect(_on_close_button_pressed)

func _process(_delta):
	if is_instance_valid(recipe_tooltip_instance) and recipe_tooltip_instance.visible:
		recipe_tooltip_instance.position = get_viewport().get_mouse_position() + Vector2(25, 25)

func _populate_recipe_grid(recipes: Array):
	for child in recipe_grid.get_children():
		child.queue_free()

	var total_slots = max(100, recipes.size())
	for i in range(total_slots):
		var recipe_slot = preload("res://Scene/UI/item_slot.tscn").instantiate()
		recipe_grid.add_child(recipe_slot)

		if i < recipes.size():
			var recipe = recipes[i]
			var result_item_id = recipe["result"]["item_id"]
			var result_amount = recipe["result"].get("amount", 1)
			recipe_slot.display_item(ItemDatabase.get_item_icon(result_item_id), result_amount)
			
			# Kết nối tooltip cho TẤT CẢ các slot có công thức
			recipe_slot.mouse_entered.connect(_on_recipe_mouse_entered.bind(recipe))
			recipe_slot.mouse_exited.connect(_on_recipe_mouse_exited)

			if PlayerStats.can_craft(recipe):
				# Đủ nguyên liệu -> sáng, cho phép click
				recipe_slot.modulate = Color.WHITE
				recipe_slot.disabled = false
				recipe_slot.pressed.connect(recipe_selected.emit.bind(recipe))
			else:
				# Thiếu nguyên liệu -> xám, không cho click
				recipe_slot.modulate = Color(0.5, 0.5, 0.5)
				recipe_slot.disabled = true
		else:
			# Ô trống
			recipe_slot.display_item(null, 0)
			recipe_slot.disabled = true

func _on_close_button_pressed():
	panel_closed.emit()
	queue_free()

# --- CÁC HÀM BỊ THIẾU ĐÃ ĐƯỢC THÊM VÀO ---

# Hàm này được gọi khi di chuột VÀO một công thức
func _on_recipe_mouse_entered(recipe: Dictionary):
	# Kiểm tra xem tooltip đã được tạo chưa, nếu chưa thì tạo
	if not is_instance_valid(recipe_tooltip_instance):
		recipe_tooltip_instance = RecipeTooltipScene.instantiate()
		add_child(recipe_tooltip_instance)
	
	# Cập nhật nội dung tooltip và hiển thị nó
	recipe_tooltip_instance.build_tooltip(recipe)
	recipe_tooltip_instance.show()

# Hàm này được gọi khi di chuột RA KHỎI một công thức
func _on_recipe_mouse_exited():
	# Nếu tooltip tồn tại thì ẩn nó đi
	if is_instance_valid(recipe_tooltip_instance):
		recipe_tooltip_instance.hide()
