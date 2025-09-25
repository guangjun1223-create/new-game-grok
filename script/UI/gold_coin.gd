# gold_coin.gd
extends Area2D

var gold_amount: int = 1 # Số vàng chứa trong đồng xu này
var is_picked_up: bool = false # Cờ để tránh nhặt nhiều lần

@onready var despawn_timer: Timer = $DespawnTimer

func _ready():
	# Kết nối tín hiệu "body_entered" của chính Area2D này
	# với hàm _on_body_entered để xử lý va chạm
	body_entered.connect(_on_body_entered)
	despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	
	despawn_timer.start()

func _on_body_entered(body: Node2D):
	# 1. Kiểm tra xem đã bị nhặt chưa và đối tượng va chạm có phải là Hero không
	if is_picked_up or not body is Hero:
		return
	# 2. Đánh dấu là đã nhặt
	is_picked_up = true
	despawn_timer.stop()
	# 3. Gọi hàm cộng vàng của PlayerStats
	body.add_gold(gold_amount)
	
	# === PHẦN THÊM MỚI ===
	# Lấy vị trí để hiển thị text (phía trên đồng vàng một chút)
	var text_position = global_position - Vector2(0, 80)
	# Tạo chuỗi văn bản, ví dụ: "+50 Golds"
	var text_to_show = "+" + str(gold_amount) + " Golds"
	# Gọi FloatingTextManager để hiển thị với màu VÀNG
	FloatingTextManager.show_text(text_to_show, Color.GOLD, text_position)
	
	# 4. Tạo hiệu ứng đẹp mắt (tùy chọn nhưng nên có)
	var tween = create_tween()
	# Làm đồng vàng bay lên một chút và mờ dần trong 0.3 giây
	tween.tween_property(self, "position:y", position.y - 50, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	
	# 5. Sau khi hiệu ứng kết thúc, xóa đồng vàng khỏi game
	tween.finished.connect(queue_free)
	
	
func _on_despawn_timer_timeout():
	# Nếu sau 60 giây mà vẫn chưa bị nhặt (is_picked_up == false)
	if not is_picked_up:
		print(">>> Dong vang da het han va tu dong bien mat.")
		# Tự hủy
		queue_free()
