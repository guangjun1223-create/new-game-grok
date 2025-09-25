# res://script/UI/shop_panel.gd
extends Control
class_name ShopPanel

# --- THAM CHIẾU & TÍN HIỆU ---
const BuybackQuantityPanelScene = preload("res://Scene/UI/buyback_quantity_panel.tscn")

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var item_grid: GridContainer = $PanelContainer/VBoxContainer/ScrollContainer/ItemGrid
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

var item_tooltip: PopupPanel # Sẽ được truyền vào từ ui.gd
var _current_hero: Hero
var _shop_type: String

func _ready():
	close_button.pressed.connect(queue_free)

# Hàm khởi tạo, nhận cả hero đang mua sắm
func setup(p_shop_type: String, p_hero: Hero):
	_shop_type = p_shop_type
	_current_hero = p_hero

	if _shop_type == "potion":
		title_label.text = "Cửa Hàng Potion"
		_populate_shop_by_category("potion")
	elif _shop_type == "equipment":
		title_label.text = "Cửa hàng trang bị"
		_populate_shop_by_category("equipment")

# --- LOGIC "VẼ" CỬA HÀNG ---
func _populate_shop_by_category(category: String):
	# Dọn dẹp các ô cũ
	for child in item_grid.get_children():
		child.queue_free()

	# 1. Lọc ra danh sách các item duy nhất theo category từ kho
	var items_to_sell: Array[String] = []
	var unique_ids: Dictionary = {}
	for item_info in PlayerStats.warehouse:
		if item_info and item_info.has("id"):
			var item_id = item_info["id"]
			if not unique_ids.has(item_id):
				var item_data = ItemDatabase.get_item_data(item_id)
				if item_data.get("category") == category:
					items_to_sell.append(item_id)
					unique_ids[item_id] = true
	
	# 2. Chạy một vòng lặp cố định để tạo đủ số slot
	var total_slots = PlayerStats.WAREHOUSE_SIZE # Lấy số lượng từ PlayerStats
	var num_items_to_sell = items_to_sell.size()

	for i in range(total_slots):
		var new_slot = preload("res://Scene/UI/item_slot.tscn").instantiate()
		item_grid.add_child(new_slot)

		# 3. Kiểm tra xem có vật phẩm để lấp vào ô này không
		if i < num_items_to_sell:
			# NẾU CÓ: Lấp đầy ô bằng dữ liệu vật phẩm
			var item_id = items_to_sell[i]
			var item_data = ItemDatabase.get_item_data(item_id)
			
			new_slot.display_item(item_data["icon"], 0) # Ẩn số lượng
			
			# Kết nối các tín hiệu
			new_slot.mouse_entered.connect(_on_shop_item_mouse_entered.bind(item_id))
			new_slot.mouse_exited.connect(_on_shop_item_mouse_exited)
			new_slot.pressed.connect(_on_buy_item_pressed.bind(item_id))
		else:
			# NẾU KHÔNG: Đây là ô trống
			new_slot.display_item(null, 0)
			new_slot.disabled = true # Vô hiệu hóa ô trống


# --- CÁC HÀM XỬ LÝ SỰ KIỆN ---
func _on_shop_item_mouse_entered(item_id: String):
	if is_instance_valid(item_tooltip):
		item_tooltip.update_tooltip(item_id, "price") # Gọi tooltip ở chế độ "price"
		item_tooltip.popup()

func _on_shop_item_mouse_exited():
	if is_instance_valid(item_tooltip):
		item_tooltip.hide()

# Khi click vào một vật phẩm để mua
func _on_buy_item_pressed(item_id: String):
	var quantity_panel = BuybackQuantityPanelScene.instantiate()
	# Chuyển tên hàm kết nối cho rõ ràng hơn
	quantity_panel.purchase_confirmed.connect(_on_purchase_quantity_confirmed)
	add_child(quantity_panel)

	# Tạo một item_info giả để tương thích với hàm setup của BuybackPanel
	var item_info = {"id": item_id, "quantity": 999999} # 999 là số lượng tối đa có thể mua
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
		# PlayerStats.remove_item_from_warehouse(item_id, quantity)
		print("Hero '%s' đã mua %d %s với giá %d vàng." % [hero.hero_name, quantity, item_data["item_name"], total_cost])
	else:
		print("Hero '%s' không đủ tiền!" % hero.hero_name)
		
