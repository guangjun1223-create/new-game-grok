# res://script/UI/shop_panel.gd
extends Control
class_name ShopPanel

# --- THAM CHIẾU & TÍN HIỆU ---
const BuybackQuantityPanelScene = preload("res://Scene/UI/buyback_quantity_panel.tscn")
const ItemSlotScene = preload("res://Scene/UI/item_slot.tscn")
const MAX_SHOP_SLOTS = 200

@onready var title_label: Label = $PanelContainer/VBoxContainer/Panel/TitleLabel
@onready var item_grid: GridContainer = $PanelContainer/VBoxContainer/Panel2/ScrollContainer/ItemGrid
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

var item_tooltip: PopupPanel # Sẽ được truyền vào từ ui.gd
var _current_hero: Hero
var _shop_type: String

func _ready():
	add_to_group("panels")
	close_button.pressed.connect(close_panel)
	GameEvents.ui_panel_opened.emit()

func close_panel():
	# Phát tín hiệu báo rằng panel sắp đóng
	# Camera sẽ lắng nghe tín hiệu này để mở lại zoom.
	GameEvents.ui_panel_closed.emit()
	
	# Sau khi phát tín hiệu, tự hủy
	queue_free()

# Hàm khởi tạo, nhận cả hero đang mua sắm
func setup(p_shop_type: String, p_hero: Hero):
	_shop_type = p_shop_type
	_current_hero = p_hero

	if _shop_type == "potion":
		title_label.text = "Cửa Hàng Potion"
		_populate_shop_by_category("potion")
	elif _shop_type == "equipment":
		title_label.text = "Bán Trang Bị"
		_populate_shop_by_category("equipment")

# --- LOGIC "VẼ" CỬA HÀNG ---
func _populate_shop_by_category(category_to_display: String):
	# 1. Dọn dẹp các item cũ trong shop
	for child in item_grid.get_children():
		child.queue_free()

	# 2. Lọc ra các vật phẩm phù hợp từ trong kho
	var items_to_show: Array = []
	var warehouse_items: Array = PlayerStats.warehouse
	for item_instance in warehouse_items:
		# Kiểm tra xem item có hợp lệ không
		if item_instance and item_instance.has("id"):
			var item_data = ItemDatabase.get_item_data(item_instance["id"])
			# Dùng một cách kiểm tra duy nhất, nhất quán cho mọi loại shop
			if item_data.get("category") == category_to_display:
				items_to_show.append(item_instance)

	# 3. "Vẽ" lại toàn bộ cửa hàng với số slot cố định
	for i in range(MAX_SHOP_SLOTS):
		var new_slot = ItemSlotScene.instantiate()
		item_grid.add_child(new_slot)

		# Nếu vẫn còn vật phẩm trong danh sách đã lọc, hãy hiển thị nó
		if i < items_to_show.size():
			var item_instance = items_to_show[i]
			var item_id = item_instance["id"]
			var icon = ItemDatabase.get_item_icon(item_id)
			
			new_slot.display_item(icon, item_instance.get("quantity", 0))
			new_slot.disabled = false

			# Kết nối tín hiệu với dữ liệu chính xác từ kho
			new_slot.mouse_entered.connect(_on_shop_item_mouse_entered.bind(item_instance))
			new_slot.mouse_exited.connect(_on_shop_item_mouse_exited)
			new_slot.pressed.connect(_on_buy_item_pressed.bind(item_instance))
		else:
			# Nếu không, slot này sẽ là một ô trống và không thể tương tác
			new_slot.display_item(null, 0)
			new_slot.disabled = true


# --- CÁC HÀM XỬ LÝ SỰ KIỆN ---
func _on_shop_item_mouse_entered(item_info: Dictionary):
	if is_instance_valid(item_tooltip):
		item_tooltip.update_tooltip(item_info, "price") 
		item_tooltip.popup()

func _on_shop_item_mouse_exited():
	if is_instance_valid(item_tooltip):
		item_tooltip.hide()

# Khi click vào một vật phẩm để mua
func _on_buy_item_pressed(item_info: Dictionary):
	var quantity_panel = BuybackQuantityPanelScene.instantiate()
	quantity_panel.purchase_confirmed.connect(_on_purchase_quantity_confirmed)
	add_child(quantity_panel)
	quantity_panel.setup(_current_hero, item_info)

# Khi người chơi xác nhận số lượng mua
func _on_purchase_quantity_confirmed(hero: Hero, item_id: String, quantity: int):
	var item_data = ItemDatabase.get_item_data(item_id)
	var total_cost = item_data.get("price", 0) * quantity

	# Kiểm tra xem hero có đủ tiền không
	if hero.gold >= total_cost:
		hero.gold -= total_cost
		hero.add_item(item_id, quantity)
		# (Tùy chọn) Có thể trừ vật phẩm khỏi kho người chơi ở đây
		PlayerStats.remove_item_from_warehouse(item_id, quantity)
		_populate_shop_by_category(_shop_type)
	else:
		print("Hero '%s' không đủ tiền!" % hero.hero_name)
		
