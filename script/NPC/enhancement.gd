# res://script/NPC/enhancement.gd
extends StaticBody2D
class_name EnhancementNPC

signal upgrade_panel_requested(hero)

const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false
var hero_in_range: Hero = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer
@onready var interaction_prompt_button: Button = $InteractionPromptButton
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready():
	# Kết nối các tín hiệu
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	interaction_prompt_button.pressed.connect(_on_button_pressed) # Chỉ kết nối đến 1 hàm duy nhất
	PlayerStats.village_level_changed.connect(_on_village_level_changed) # Thêm kết nối còn thiếu

	# Đăng ký NPC với PlayerStats (sửa lại tên hàm cho đúng)
	PlayerStats.register_enhancement_npc(self)
	
	# Kiểm tra trạng thái kích hoạt lần đầu
	_check_activation(PlayerStats.village_level)
	animation_timer.start(randf_range(3.0, 6.0))

func _on_village_level_changed(new_level: int):
	_check_activation(new_level)

func _check_activation(current_village_level: int):
	# Dựa vào cấp làng để quyết định NPC có nên hoạt động hay không
	if current_village_level >= 1:
		set_active(true)
	else:
		set_active(false)

func set_active(active: bool):
	is_active = active
	visible = active # Thêm dòng này để ẩn/hiện cả NPC
	collision_shape.disabled = not active
	if not active:
		interaction_prompt_button.visible = false

func _on_body_entered(body):
	if is_active and body is Hero:
		hero_in_range = body
		interaction_prompt_button.visible = true

func _on_body_exited(body):
	if body == hero_in_range:
		hero_in_range = null
		interaction_prompt_button.visible = false

# Hàm xử lý nút bấm duy nhất và hoàn chỉnh
func _on_button_pressed():
	if is_instance_valid(hero_in_range):
		# 1. Ra lệnh cho hero dừng lại và quay mặt vào NPC
		hero_in_range.stop_and_interact_with_npc(self)
		
		# 2. Phát tín hiệu yêu cầu mở bảng nâng cấp
		upgrade_panel_requested.emit(hero_in_range)
		
# --- Các hàm xử lý animation (giữ nguyên) ---
func _on_animation_timer_timeout():
	if animated_sprite.animation in ["Idle", "Idle Blinking"]:
		animated_sprite.play(FLAVOR_ANIMATIONS.pick_random())
	animation_timer.wait_time = randf_range(5.0, 10.0)
	animation_timer.start()

func _on_animation_finished():
	if animated_sprite.animation in FLAVOR_ANIMATIONS:
		animated_sprite.play("Idle Blinking")
