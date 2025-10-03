# res://script/NPC/job_changer_npc.gd
extends CharacterBody2D
class_name JobChangerNPC

signal open_job_change_panel(hero)

const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

var is_active = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var animation_timer: Timer = $AnimationTimer

func _ready():
	if PlayerStats.village_level >= 5:
		set_active(true)
	else:
		set_active(false)
		
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	PlayerStats.register_job_changer_npc(self)
	
	animation_timer.wait_time = randf_range(2.0, 5.0)
	animation_timer.start()

func _on_hero_entered(body):
	if not is_active or not body is Hero:
		return
		
	if body.job_key == "Novice" and body.level >= body.MAX_LEVEL_NOVICE:
		open_job_change_panel.emit(body)
	else:
		print("NPC: 'Hãy rèn luyện thêm đi, khi nào đủ mạnh mẽ hãy quay lại gặp ta.'")
		
		
func _on_animation_timer_timeout():
	if animated_sprite.animation == "Idle" or animated_sprite.animation == "Idle Blinking":
		# Chọn một animation ngẫu nhiên từ danh sách
		var next_anim = FLAVOR_ANIMATIONS.pick_random()
		animated_sprite.play(next_anim)
	
	animation_timer.wait_time = randf_range(5.0, 10.0)

func _on_animation_finished():
	var finished_anim = animated_sprite.animation
	
	if finished_anim in FLAVOR_ANIMATIONS:
		animated_sprite.play("Idle Blinking")
		
		animation_timer.start()
		
func set_active(active: bool):
	is_active = active
	# Bật/tắt khả năng tương tác bằng cách bật/tắt vùng va chạm của Area2D
	$InteractionArea/CollisionShape2D.disabled = not active
