# Script ShopNPC.gd
extends StaticBody2D

const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer
@onready var interaction_prompt_button: Button = $InteractionPromptButton

var hero_in_range = null

func _ready():
	# Ngay khi được tạo ra, NPC sẽ báo danh với PlayerStats
	PlayerStats.register_shop_npc(self)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	interaction_prompt_button.pressed.connect(_on_interaction_prompt_button_pressed)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("heroes"):
		hero_in_range = body
		interaction_prompt_button.visible = true # Hiện Button lên

func _on_interaction_area_body_exited(body):
	if body == hero_in_range:
		hero_in_range = null
		interaction_prompt_button.visible = false # Ẩn Button đi

func _on_interaction_prompt_button_pressed():
	# Nếu có một Hero đang trong tầm
	if is_instance_valid(hero_in_range):
		# Yêu cầu Hero dừng lại và giao dịch với chính NPC này
		hero_in_range.stop_and_interact_with_npc(self)

func open_shop_panel(hero_interacting):
	print("Mo cua hang '%s' cho Hero: '%s'" % [name, hero_interacting.name])
	# Tại đây, chúng ta mới phát tín hiệu toàn cục để UI mở panel shop
	GameEvents.hero_arrived_at_shop.emit(hero_interacting)

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
