# FloatingText.gd
extends Node2D

@onready var label: Label = $Label

# Hàm này sẽ được gọi từ bên ngoài để thiết lập chữ
func start(text: String, color: Color, is_crit: bool = false):
	label.text = text
	
	# Thiết lập màu sắc và kích thước
	var label_settings = label.get_label_settings()
	label_settings.font_color = color
	if is_crit:
		label_settings.font_size = 36 # To hơn cho crit
		label_settings.outline_size = 3

	# Bắt đầu animation
	animate()

func animate():
	var tween = create_tween()
	# Đặt tween chạy song song để vừa di chuyển vừa mờ dần
	tween.set_parallel(true)

	# 1. Animation mờ dần (fade out)
	# Thay đổi thuộc tính "modulate" của Label từ màu hiện tại -> trong suốt
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 2. Animation di chuyển (arc - hình vòng cung)
	# Di chuyển tương đối (relative) so với vị trí ban đầu
	# Đi lên 100px rồi đi xuống 50px trong 1.5 giây
	tween.tween_method(Callable(self, "_move_arc"), 0.0, 1.0, 1.5)

	# 3. Tự hủy sau khi animation kết thúc
	await tween.finished
	queue_free()

# Hàm tùy chỉnh để tạo đường cong
func _move_arc(t: float):
	# t là tiến trình của tween (từ 0.0 đến 1.0)
	var upward_motion = -100 * sin(t * PI) # sin(t*PI) tạo ra đường cong lên và xuống
	var horizontal_motion = 30 * t # Hơi lệch sang ngang một chút
	
	# Áp dụng chuyển động vào vị trí của Label
	label.position = Vector2(horizontal_motion, upward_motion)
