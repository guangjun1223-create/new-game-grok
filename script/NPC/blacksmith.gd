# Script BlacksmithNPC.gd
extends StaticBody2D

signal blacksmith_panel_requested
# Danh sách các hoạt ảnh "hành vi" ngẫu nhiên
const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_timer: Timer = $AnimationTimer

func _ready():
	if PlayerStats.village_level >= 2:
		set_active(true)
	else:
		set_active(false)
		
	PlayerStats.register_blacksmith_npc(self)
	# Kết nối các tín hiệu cần thiết
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _input_event(_viewport, event, _shape_idx):
	if not is_active:
		return
	# Kiểm tra xem có phải là một cú click chuột trái vừa được nhấn không
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Phát tín hiệu ra để báo cho UI biết
		blacksmith_panel_requested.emit()
		print("DEBUG: Blacksmith clicked!") # Dòng print để kiểm tra

# Hàm này được gọi mỗi khi Timer kết thúc
func _on_animation_timer_timeout():
	# Chỉ chơi animation ngẫu nhiên nếu đang ở trạng thái rảnh rỗi (Idle)
	if animated_sprite.animation == "Idle" or animated_sprite.animation == "Idle Blinking":
		# Chọn một animation ngẫu nhiên từ danh sách
		var next_anim = FLAVOR_ANIMATIONS.pick_random()
		animated_sprite.play(next_anim)
	
	# Đặt lại thời gian chờ ngẫu nhiên cho lần tiếp theo (từ 5 đến 10 giây)
	animation_timer.wait_time = randf_range(5.0, 10.0)
	animation_timer.start()

# Hàm này được gọi khi một animation chơi xong
func _on_animation_finished():
	# Sau khi chơi xong bất kỳ animation nào, quay trở lại trạng thái Idle Blinking
	animated_sprite.play("Idle Blinking")
	
func set_active(active: bool):
	is_active = active
	$CollisionShape2D.disabled = not active
