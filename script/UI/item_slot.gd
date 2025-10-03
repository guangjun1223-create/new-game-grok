# res://script/UI/item_slot.gd (PHIÊN BẢN HOÀN CHỈNH CUỐI CÙNG)
extends Button

# Đảm bảo các tên này khớp với tên node trong Scene của bạn
@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $Label
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var cooldown_progress: TextureProgressBar = $TextureProgressBar

func _ready():
	# Ẩn lớp phủ cooldown khi bắt đầu
	cooldown_progress.visible = false
	# Kết nối tín hiệu timeout của ĐÚNG timer
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	display_item(null, 0)
	
func _process(_delta):
	# Nếu đang trong chế độ Editor, không chạy
	if Engine.is_editor_hint():
		return
	
	# Liên tục cập nhật giá trị của thanh cooldown nếu timer đang chạy
	if not cooldown_timer.is_stopped(): # Sửa: Dùng đúng biến cooldown_timer
		# Giá trị của progress bar = % thời gian còn lại
		cooldown_progress.value = (cooldown_timer.time_left / cooldown_timer.wait_time) * 100
	else:
		# Đảm bảo giá trị về 0 khi không cooldown
		if cooldown_progress.value > 0:
			cooldown_progress.value = 0
			cooldown_progress.visible = false


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

# ========================================
# === LOGIC COOLDOWN ĐÃ ĐƯỢC SỬA LỖI ===
# ========================================

# Bắt đầu đếm ngược cooldown
func start_cooldown(duration: float):
	if duration <= 0: return
	
	cooldown_timer.wait_time = duration
	cooldown_timer.start() # Sửa: Dùng đúng biến cooldown_timer
	
	cooldown_progress.visible = true
	cooldown_progress.value = 100

# Kiểm tra xem ô này có đang cooldown không
func is_ready() -> bool:
	return cooldown_timer.is_stopped() # Sửa: Dùng đúng biến cooldown_timer

# Được gọi khi Timer đếm ngược xong
func _on_cooldown_finished(): # Sửa: Sửa lại tên hàm cho đúng với signal đã kết nối
	cooldown_progress.visible = false
	cooldown_progress.value = 0
