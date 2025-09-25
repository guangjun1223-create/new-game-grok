# res://script/UI/BuybackQuantityPanel.gd
extends PanelContainer
class_name BuybackQuantityPanel

# Tín hiệu không thay đổi, rất tốt!
signal purchase_confirmed(hero, item_id, quantity)

# --- THAM CHIẾU NODE (Không thay đổi) ---
@onready var item_name_label: Label = $VBoxContainer/ItemNameLabel
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel
@onready var total_cost_label: Label = $VBoxContainer/TotalCostLabel
@onready var quantity_slider: HSlider = $VBoxContainer/QuantitySlider
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/HBoxContainer/CancelButton

# --- BIẾN LƯU TRỮ (Thêm Type Hint để code an toàn hơn) ---
var _hero_ref: Hero
var _item_id: String
var _item_price: int = 0 # Khởi tạo giá trị mặc định an toàn
var _max_quantity: int = 0 # Khởi tạo giá trị mặc định an toàn

func _ready():
	quantity_slider.value_changed.connect(_on_quantity_slider_value_changed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(queue_free)

# --- HÀM KHỞI TẠO (Thay đổi quan trọng nhất) ---
func setup(hero: Hero, item_info: Dictionary):
	# BƯỚC 1: KIỂM TRA DỮ LIỆU ĐẦU VÀO
	if not is_instance_valid(hero) or not item_info:
		push_error("BuybackPanel: Dữ liệu hero hoặc item_info không hợp lệ.")
		queue_free() # Tự hủy nếu dữ liệu không đúng
		return

	_hero_ref = hero
	_item_id = item_info.get("id", "")
	_max_quantity = item_info.get("quantity", 0)

	var item_data = ItemDatabase.get_item_data(_item_id)
	
	# BƯỚC 2: KIỂM TRA DỮ LIỆU ITEM VÀ GIÁ
	if item_data.is_empty() or _max_quantity <= 0:
		push_error("BuybackPanel: Không tìm thấy dữ liệu cho item '%s' hoặc số lượng không hợp lệ." % _item_id)
		queue_free() # Tự hủy nếu không có item hoặc số lượng
		return
		
	_item_price = item_data.get("price", 0)
	
	if _item_price <= 0:
		push_warning("BuybackPanel: Item '%s' có giá bán <= 0. Không thể mua lại." % _item_id)
		# Có thể hiển thị một thông báo cho người dùng ở đây
		queue_free()
		return

	# BƯỚC 3: NẾU MỌI THỨ OK, TIẾP TỤC CÀI ĐẶT GIAO DIỆN
	item_name_label.text = "Mua Lại: " + item_data.get("item_name", "???")
	
	quantity_slider.min_value = 1
	quantity_slider.max_value = _max_quantity
	quantity_slider.value = 1
	
	_update_labels(1)

func _on_quantity_slider_value_changed(value: float):
	_update_labels(int(value))

# --- HÀM CẬP NHẬT GIAO DIỆN (Không thay đổi nhiều) ---
func _update_labels(quantity: int):
	quantity_label.text = "Số lượng: " + str(quantity)
	var total_cost = _item_price * quantity
	total_cost_label.text = "Tổng chi phí: %d Vàng" % total_cost
	
	# Logic kiểm tra tiền vẫn rất tốt!
	var can_afford = PlayerStats.player_gold >= total_cost
	confirm_button.disabled = not can_afford
	
	if can_afford:
		total_cost_label.modulate = Color.WHITE
	else:
		total_cost_label.modulate = Color.RED

# --- HÀM XÁC NHẬN (Không thay đổi) ---
func _on_confirm_button_pressed():
	var quantity = int(quantity_slider.value)
	var total_cost = _item_price * quantity
	
	# Kiểm tra lại một lần cuối trước khi phát tín hiệu
	if PlayerStats.player_gold >= total_cost:
		purchase_confirmed.emit(_hero_ref, _item_id, quantity)
		queue_free()
	else:
		push_warning("Không đủ tiền để mua lại! Lỗi logic ở đâu đó.")
