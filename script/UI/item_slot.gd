# res://script/UI/item_slot.gd (PHIÊN BẢN HOÀN CHỈNH DỰA TRÊN CODE CỦA BẠN)
class_name ItemSlot
extends Button

# Đảm bảo các tên này khớp với tên node trong Scene của bạn
@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $Label
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var cooldown_progress: TextureProgressBar = $CooldownOverlay

func _ready():
	# Ẩn và reset cooldown khi bắt đầu
	cooldown_progress.visible = false
	cooldown_progress.value = 0 # Sửa lại tên biến cho đúng
	cooldown_timer.timeout.connect(_on_cooldown_timer_finished) # Kết nối tín hiệu
	
	# Hiển thị ô trống lúc đầu
	display_item(null, 0)
	
func _process(_delta):
	# Không chạy code nếu đang trong Editor
	if Engine.is_editor_hint():
		return
	
	# Liên tục cập nhật giá trị của thanh cooldown nếu timer đang chạy
	if not cooldown_timer.is_stopped():
		# Giá trị của progress bar = % thời gian còn lại (từ 0 đến 100)
		cooldown_progress.value = (cooldown_timer.time_left / cooldown_timer.wait_time) * 100
	
# Hàm hiển thị item, không thay đổi
func display_item(new_icon: Texture2D, amount: int):
	if new_icon:
		item_icon.texture = new_icon
		item_icon.visible = true
		if amount > 1:
			quantity_label.text = str(amount)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		item_icon.texture = null
		item_icon.visible = false
		quantity_label.visible = false

# ===============================================
# === LOGIC COOLDOWN MỚI THEO CÁCH CỦA BẠN ===
# ===============================================

# Hàm này sẽ được gọi từ ui.gd
func start_cooldown(duration: float):
	if duration <= 0: return
	
	cooldown_timer.wait_time = duration
	cooldown_timer.start()
	
	# Hiển thị thanh cooldown và đặt nó ở mức 100%
	cooldown_progress.visible = true
	cooldown_progress.value = 100

# Được gọi khi Timer đếm ngược xong
func _on_cooldown_timer_finished():
	cooldown_progress.visible = false
	cooldown_progress.value = 0
