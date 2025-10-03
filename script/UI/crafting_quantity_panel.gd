# res://script/UI/CraftingQuantityPanel.gd (ĐÃ SỬA LỖI VÀ ĐỒNG BỘ)
extends PanelContainer
class_name CraftingQuantityPanel

# --- THAM CHIẾU NODE ---
const GameDataManagerScript = preload("res://script/autoload/GameDataManager.gd")

@onready var item_name_label: Label = $PanelContainer/VBoxContainer/ItemNameLabel
@onready var quantity_label: Label = $PanelContainer/VBoxContainer/QuantityLabel
@onready var quantity_slider: HSlider = $PanelContainer/VBoxContainer/HBoxContainer/QuantitySlider
@onready var max_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/MaxButton
@onready var materials_label: RichTextLabel = $PanelContainer/VBoxContainer/MaterialsLabel
@onready var confirm_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/CancelButton

# --- BIẾN LƯU TRỮ ---
var _recipe_data: Dictionary
var _max_craftable: int = 0

func _ready():
	quantity_slider.value_changed.connect(_on_quantity_slider_value_changed)
	max_button.pressed.connect(_on_max_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(queue_free)

func setup(recipe: Dictionary):
	_recipe_data = recipe

	if _recipe_data.is_empty():
		push_error("CraftingQuantityPanel: Nhận được công thức rỗng!")
		queue_free()
		return

	var item_data = ItemDatabase.get_item_data(_recipe_data["result"]["item_id"])
	item_name_label.text = "Chế tạo: " + item_data.get("item_name", "???")

	_calculate_max_craftable()

	if _max_craftable <= 0:
		quantity_slider.editable = false
		confirm_button.disabled = true
		_update_display(0)
	else:
		quantity_slider.min_value = 1
		quantity_slider.max_value = _max_craftable
		quantity_slider.value = 1
		_update_display(1)

func _calculate_max_craftable():
	_max_craftable = 999
	# SỬA LỖI: Dùng đúng key "materials" từ file crafting.json
	var materials = _recipe_data.get("materials", [])
	
	if materials.is_empty():
		_max_craftable = 999 # Có thể chế tạo nếu không cần nguyên liệu
		return
	
	for ingredient in materials:
		# SỬA LỖI: Dùng đúng key "item_id"
		var item_id = ingredient["item_id"] 
		var required_qty = ingredient["quantity"]
		var player_has_qty = PlayerStats.get_item_quantity_in_warehouse(item_id)
		
		if required_qty <= 0: continue
		_max_craftable = min(_max_craftable, floori(float(player_has_qty) / required_qty))

func _on_quantity_slider_value_changed(value: float):
	_update_display(int(value))

func _update_display(quantity: int):
	quantity_label.text = "Số lượng: " + str(quantity)
	var materials_text = "[b]Nguyên liệu cần thiết:[/b]\n"
	var can_craft = true
	
	# SỬA LỖI: Dùng đúng key "materials"
	for ingredient in _recipe_data.get("materials", []):
		# SỬA LỖI: Dùng đúng key "item_id"
		var item_id = ingredient["item_id"]
		var required_qty = ingredient["quantity"] * quantity
		var player_has_qty = PlayerStats.get_item_quantity_in_warehouse(item_id)
		var item_name = ItemDatabase.get_item_data(item_id).get("item_name", "???")
		
		if player_has_qty >= required_qty:
			materials_text += "[color=white]%s: %d/%d[/color]\n" % [item_name, player_has_qty, required_qty]
		else:
			materials_text += "[color=red]%s: %d/%d[/color]\n" % [item_name, player_has_qty, required_qty]
			can_craft = false
	
	materials_label.text = materials_text
	if quantity <= 0:
		can_craft = false
	confirm_button.disabled = not can_craft

func _on_max_button_pressed():
	if _max_craftable > 0:
		quantity_slider.value = _max_craftable

func _on_confirm_button_pressed():
	var recipe = _recipe_data
	var amount_to_craft = int(quantity_slider.value)

	if not recipe or amount_to_craft <= 0:
		return

	var result_item_id = recipe["result"]["item_id"]
	var materials = recipe.get("materials", [])
	
	# --- B1: Trừ nguyên liệu ---
	for ingredient in materials:
		var item_id = ingredient["item_id"]
		var quantity_needed = ingredient["quantity"] * amount_to_craft
		PlayerStats.remove_item_from_warehouse(item_id, quantity_needed)

	# --- B2: Kiểm tra loại vật phẩm và thêm vào kho ---
	var base_item_data = ItemDatabase.get_item_data(result_item_id)
	var item_type = base_item_data.get("item_type", "")
	
	var items_added_successfully = 0
	
	# NẾU LÀ TRANG BỊ -> Roll phẩm chất cho từng món
	if item_type == "EQUIPMENT":
		for i in range(amount_to_craft):
			var new_equipment = GameDataManagerScript.create_equipment_instance(result_item_id)
			if not new_equipment.is_empty(): # Kiểm tra xem có bị hỏng không
				if PlayerStats.add_item_to_warehouse(new_equipment):
					items_added_successfully += 1
	# NẾU LÀ VẬT PHẨM THƯỜNG (thuốc, nguyên liệu...) -> Thêm theo số lượng
	else:
		var result_info = recipe["result"]
		var total_amount = result_info.get("amount", 1) * amount_to_craft
		if PlayerStats.add_item_to_warehouse(result_item_id, total_amount):
			items_added_successfully = total_amount # Đối với đồ stack, thành công là thành công hết

	if items_added_successfully > 0:
		if item_type == "EQUIPMENT":
			print("Chế tạo thành công %d / %d món!" % [items_added_successfully, amount_to_craft])
		else:
			print("Chế tạo thành công %d x %s!" % [items_added_successfully, base_item_data.get("item_name", result_item_id)])
	else:
		print("Không có vật phẩm nào được chế tạo thành công (do bị hỏng hoặc kho đầy).")

	queue_free()
