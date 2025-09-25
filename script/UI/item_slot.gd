# res://script/UI/item_slot.gd
# PHIÊN BẢN SỬA LỖI HOÀN CHỈNH

extends Button

@onready var item_icon: TextureRect = $ItemIcon
@onready var quantity_label: Label = $Label
@onready var timer: Timer = $Timer
@onready var cooldown_overlay: ColorRect = $CooldownOverlay


func _ready():
	cooldown_overlay.visible = false
	timer.timeout.connect(_on_timer_timeout)
	display_item(null, 0)
	
func _process(_delta):
	# Nếu đang trong chế độ Editor, không chạy logic update
	if Engine.is_editor_hint():
		return
	
	# Liên tục cập nhật hiệu ứng mờ dần khi đang cooldown
	if not timer.is_stopped():
		# Tính toán tỉ lệ thời gian còn lại
		var remaining_ratio = timer.time_left / timer.wait_time
		# Dùng tỉ lệ này để tô màu cho lớp phủ, tạo hiệu ứng cooldown chạy vòng
		cooldown_overlay.material.set_shader_parameter("progress", remaining_ratio)

func display_item(new_icon: Texture2D, amount: int):
	if new_icon:
# Đã sửa lại để dùng đúng tên tham số "new_icon"
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
# === CÁC HÀM MỚI CHO LOGIC COOLDOWN ===
# ========================================

# Bắt đầu đếm ngược cooldown
func start_cooldown(duration: float):
	if duration <= 0: return
	
	
	timer.wait_time = duration
	timer.start()
	cooldown_overlay.visible = true


# Kiểm tra xem ô này có đang cooldown không
func is_ready() -> bool:
	return timer.is_stopped()

# Được gọi khi Timer đếm ngược xong
func _on_timer_timeout():
	cooldown_overlay.visible = false
