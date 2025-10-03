# Script PotionSellNPC.gd
extends StaticBody2D
class_name PotionSellerNPC

# Danh sách các hoạt ảnh "hành vi" ngẫu nhiên
const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false
var hero_in_range = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer
@onready var interaction_prompt_button: Button = $InteractionPromptButton
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready():
	PlayerStats.register_potion_seller_npc(self)
	PlayerStats.village_level_changed.connect(_on_village_level_changed)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	interaction_prompt_button.pressed.connect(_on_interaction_prompt_button_pressed)
	
	_check_activation(PlayerStats.village_level)
	
func _on_village_level_changed(new_level: int):
	print("EquipmentSellerNPC: Nhan duoc tin hieu lang len cap: %d" % new_level)
	_check_activation(new_level)
	
func _check_activation(current_village_level: int):
	# Dựa vào cấp làng để quyết định NPC có nên hoạt động hay không
	if current_village_level >= 2:
		set_active(true)
	else:
		set_active(false)
	
func set_active(active: bool):
	is_active = active
	
	# Bật/tắt khả năng tương tác
	collision_shape.disabled = not active
	if not active:
		interaction_prompt_button.visible = false

func _on_interaction_area_body_entered(body):
	if is_active and body.is_in_group("heroes"):
		hero_in_range = body
		interaction_prompt_button.visible = true

func _on_interaction_area_body_exited(body):
	if body == hero_in_range:
		hero_in_range = null
		interaction_prompt_button.visible = false
					
func _on_interaction_prompt_button_pressed():
	if is_instance_valid(hero_in_range):
		hero_in_range.stop_and_interact_with_npc(self)
		
func open_shop_panel(hero_interacting):
	GameEvents.hero_arrived_at_potion_shop.emit(hero_interacting)

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
	
