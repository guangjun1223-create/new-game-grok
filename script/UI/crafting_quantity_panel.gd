# res://script/UI/CraftingQuantityPanel.gd
extends PanelContainer
class_name CraftingQuantityPanel

# Tín hiệu sẽ được phát ra khi người chơi xác nhận chế tạo
signal craft_confirmed(recipe_id, quantity)

# --- THAM CHIẾU NODE ---
@onready var item_name_label: Label = $PanelContainer/VBoxContainer/ItemNameLabel
@onready var quantity_label: Label = $PanelContainer/VBoxContainer/QuantityLabel
@onready var quantity_slider: HSlider = $PanelContainer/VBoxContainer/HBoxContainer/QuantitySlider
@onready var max_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/MaxButton
@onready var materials_label: RichTextLabel = $PanelContainer/VBoxContainer/MaterialsLabel
@onready var confirm_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: Button = $PanelContainer/VBoxContainer/ButtonContainer/CancelButton

# --- BIẾN LƯU TRỮ ---
var _recipe_id: String
var _recipe_data: Dictionary
var _max_craftable: int = 0

func _ready():
	# Kết nối các tín hiệu nội bộ
	quantity_slider.value_changed.connect(_on_quantity_slider_value_changed)
	max_button.pressed.connect(_on_max_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(queue_free)

# Hàm này sẽ được gọi từ CraftingPanel để khởi tạo
func setup(p_recipe_id: String):
	_recipe_id = p_recipe_id
	_recipe_data = GameDataManager.get_recipe_data(_recipe_id)

	if _recipe_data.is_empty():
		push_error("CraftingQuantityPanel: Không tìm thấy công thức cho '%s'" % _recipe_id)
		queue_free()
		return

	var item_data = ItemDatabase.get_item_data(_recipe_data["result_id"])
	item_name_label.text = "Chế tạo: " + item_data.get("item_name", "???")

	_calculate_max_craftable()

	if _max_craftable <= 0:
		quantity_slider.editable = false
		confirm_button.disabled = true
	else:
		quantity_slider.min_value = 1
		quantity_slider.max_value = _max_craftable
		quantity_slider.value = 1

	_update_display(1)

# Tính toán xem có thể chế tạo tối đa bao nhiêu vật phẩm
func _calculate_max_craftable():
	_max_craftable = 999 # Giả định ban đầu là có thể chế tạo rất nhiều
	var ingredients = _recipe_data.get("ingredients", [])
	
	for ingredient in ingredients:
		var item_id = ingredient["id"]
		var required_qty = ingredient["quantity"]
		var player_has_qty = PlayerStats.get_item_quantity_in_warehouse(item_id)
		
		# Số lượng có thể chế tạo của một món đồ bị giới hạn bởi nguyên liệu thiếu hụt nhất
		_max_craftable = min(_max_craftable, floori(float(player_has_qty) / required_qty))

# Cập nhật hiển thị khi thanh trượt thay đổi
func _on_quantity_slider_value_changed(value: float):
	_update_display(int(value))

# Cập nhật toàn bộ giao diện dựa trên số lượng
func _update_display(quantity: int):
	quantity_label.text = "Số lượng: " + str(quantity)
	
	var materials_text = "[b]Nguyên liệu cần thiết:[/b]\n"
	var can_craft = true
	
	for ingredient in _recipe_data.get("ingredients", []):
		var item_id = ingredient["id"]
		var required_qty = ingredient["quantity"] * quantity
		var player_has_qty = PlayerStats.get_item_quantity_in_warehouse(item_id)
		var item_name = ItemDatabase.get_item_data(item_id).get("item_name", "???")
		
		if player_has_qty >= required_qty:
			materials_text += "[color=white]%s: %d/%d[/color]\n" % [item_name, required_qty, player_has_qty]
		else:
			materials_text += "[color=red]%s: %d/%d[/color]\n" % [item_name, required_qty, player_has_qty]
			can_craft = false
	
	materials_label.text = materials_text
	confirm_button.disabled = not can_craft

# Khi nhấn nút "Max"
func _on_max_button_pressed():
	if _max_craftable > 0:
		quantity_slider.value = _max_craftable

# Khi nhấn nút "Chế Tạo"
func _on_confirm_button_pressed():
	var quantity = int(quantity_slider.value)
	craft_confirmed.emit(_recipe_id, quantity)
	queue_free()
