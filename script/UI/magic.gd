# magic.gd (Phiên bản nâng cấp)
extends Area2D

var speed: float
var target: Node2D
var direction: Vector2
var attacker: Node = null
var is_magic: bool = false # <-- BIẾN MỚI để lưu loại sát thương

var is_hitting: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	animated_sprite.animation_finished.connect(_on_animation_finished)

# Sửa lại hàm start() để nhận 5 tham số
func start(start_pos: Vector2, target_node: Node2D, shot_attacker: Node, new_speed: float, p_is_magic: bool):
	global_position = start_pos
	target = target_node
	attacker = shot_attacker
	speed = new_speed
	self.is_magic = p_is_magic # <-- Lưu lại loại sát thương được truyền vào

	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()
	lifetime_timer.start()
	animated_sprite.play("fly")

func _physics_process(delta):
	if is_hitting:
		return
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("monsters") and not body.is_dead:
		is_hitting = true
		if is_instance_valid(attacker):
			# SỬA LẠI: Thêm tham số thứ 3 (skill_multiplier) là 1.0 cho đòn đánh thường
			attacker.execute_attack_on(body, self.is_magic, 1.0)
		animated_sprite.play("hit")
		
func _on_animation_finished():
	# Kiểm tra xem animation vừa kết thúc có phải là "hit" không
	if animated_sprite.animation == "hit":
		# Nếu đúng, tự hủy đối tượng quả cầu phép
		queue_free()
