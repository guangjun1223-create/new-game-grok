# res://script/NPC/job_changer_npc.gd
extends CharacterBody2D
class_name JobChangerNPC

signal open_job_change_panel(hero)

const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false
var hero_in_range: Hero = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D # Thêm tham chiếu Collision
@onready var interaction_prompt_button: Button = $InteractionPromptButton


func _ready():
	# Kết nối các tín hiệu cần thiết
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	interaction_prompt_button.pressed.connect(_on_interaction_prompt_button_pressed)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	PlayerStats.register_job_changer_npc(self)
	_check_activation(PlayerStats.village_level)
	PlayerStats.village_level_changed.connect(_check_activation)
	
func _check_activation(current_village_level: int):
	if current_village_level >= 4:
		set_active(true)
	else:
		set_active(false)
		
func set_active(active: bool):
	is_active = active
	collision_shape.disabled = not active
	if not active:
		interaction_prompt_button.visible = false
		
func _on_interaction_area_body_entered(body):
	if is_active and body is Hero:
		hero_in_range = body
		interaction_prompt_button.visible = true

func _on_interaction_area_body_exited(body):
	if body == hero_in_range:
		hero_in_range = null
		interaction_prompt_button.visible = false

func _on_interaction_prompt_button_pressed():
	if not is_instance_valid(hero_in_range): return
	if hero_in_range.can_change_job():
		# Nếu đủ, phát tín hiệu để UI mở bảng chọn nghề
		print("[NPC] Đã kiểm tra thành công. Đang phát tín hiệu 'open_job_change_panel'...")
		open_job_change_panel.emit(hero_in_range)
	else:
		# Nếu không, hiển thị thông báo
		var message = "%s không đủ điều kiện. Hãy đến đây lần sau." % hero_in_range.hero_name
		print("[NPC] Hero không đủ điều kiện. Hiển thị thông báo.")
		FloatingTextManager.show_text(message, Color.ORANGE_RED, global_position - Vector2(0, 150))
		
		
func _on_animation_timer_timeout():
	if animated_sprite.animation in ["Idle", "Idle Blinking"]:
		animated_sprite.play(FLAVOR_ANIMATIONS.pick_random())
	animation_timer.wait_time = randf_range(5.0, 10.0)

func _on_animation_finished():
	if animated_sprite.animation in FLAVOR_ANIMATIONS:
		animated_sprite.play("Idle Blinking")
		animation_timer.start()
