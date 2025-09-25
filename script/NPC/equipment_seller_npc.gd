# Script PotionSellNPC.gd
extends StaticBody2D
class_name EquipmentSellerNPC

# Danh sách các hoạt ảnh "hành vi" ngẫu nhiên
const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer

func _ready():
	if PlayerStats.village_level >= 2:
		set_active(true)
	else:
		set_active(false)
	PlayerStats.register_equipment_seller_npc(self)
	# Kết nối các tín hiệu cần thiết
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_interaction_area_body_entered(body):
	if not is_active or not body is Hero:
		return
	# Chỉ phản ứng nếu một Node thuộc nhóm "heroes" đi vào
	if body.is_in_group("heroes"):
		# Ép kiểu an toàn
		var hero = body as Hero
		# Chỉ kích hoạt nếu hero đang di chuyển (để tránh kích hoạt lại khi đang đứng yên)
		if hero and hero._current_state == Hero.State.NAVIGATING:
			print(">>> NPC: Phat hien hero '%s' da den. Phat tin hieu..." % hero.name)
			# Phát tín hiệu toàn cục, báo cho UI và các hệ thống khác biết
			GameEvents.hero_arrived_at_equipment_shop.emit(body)

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
	# Bật/tắt khả năng tương tác bằng cách bật/tắt vùng va chạm của Area2D
	$InteractionArea/CollisionShape2D.disabled = not active
