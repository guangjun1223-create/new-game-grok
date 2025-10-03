# Script EquipmentNPC.gd
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
@onready var interaction_prompt_button: Button = $InteractionPromptButton

var hero_in_range = null

func _ready():
	PlayerStats.register_equipment_seller_npc(self)
	_check_activation(PlayerStats.village_level)
	
	PlayerStats.village_level_changed.connect(_on_village_level_changed)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	interaction_prompt_button.pressed.connect(_on_interaction_prompt_button_pressed)
	
func _on_village_level_changed(new_level: int):
	print("EquipmentSellerNPC: Nhan duoc tin hieu lang len cap: %d" % new_level)
	_check_activation(new_level)
	
func _check_activation(current_village_level: int):
	# Dựa vào cấp làng để quyết định NPC có nên hoạt động hay không
	if current_village_level >= 2:
		set_active(true)
	else:
		set_active(false)
	
func _on_interaction_area_body_entered(body):
	if is_active and body.is_in_group("heroes"):
		hero_in_range = body
		interaction_prompt_button.visible = true # Hiện Button lên

func _on_interaction_area_body_exited(body):
	if body == hero_in_range:
		hero_in_range = null
		interaction_prompt_button.visible = false # Ẩn Button đi

func _on_interaction_prompt_button_pressed():
	# Nếu có một Hero đang trong tầm
	if is_instance_valid(hero_in_range):
		print("Nguoi choi da click vao button de tuong tac voi: ", name)
		# Yêu cầu Hero dừng lại và giao dịch với chính NPC này
		hero_in_range.stop_and_interact_with_npc(self)
		
func open_shop_panel(hero_interacting):
	print("Mo cua hang '%s' cho Hero: '%s'" % [name, hero_interacting.name])
	#
	# TẠI ĐÂY, BẠN SẼ GỌI HÀM ĐỂ MỞ PANEL MUA SẮM CỦA BẠN
	# Ví dụ: shop_panel.show_panel(hero_interacting)
	#
	# Tạm thời chúng ta có thể dùng một tín hiệu toàn cục nếu bạn đã có sẵn
	GameEvents.hero_arrived_at_equipment_shop.emit(hero_interacting)

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
