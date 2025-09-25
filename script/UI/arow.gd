# arrow.gd
extends Area2D

var speed: float
var target: Node2D
var direction: Vector2
var attacker: Node = null

@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	# Kết nối các tín hiệu
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free) # Tự hủy khi hết giờ

# Hàm này được gọi từ Hero để khởi tạo viên đạn
func start(start_pos: Vector2, target_node: Node2D, shot_attacker: Node, new_speed: float):
	global_position = start_pos
	target = target_node
	attacker = shot_attacker
	speed = new_speed
	# Hướng bay ban đầu
	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()
	lifetime_timer.start()

func _physics_process(delta):
	# Cập nhật lại hướng bay nếu mục tiêu di chuyển
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

	# Di chuyển viên đạn
	global_position += direction * speed * delta

# Xử lý khi viên đạn trúng một body
func _on_body_entered(body):
	# Nếu trúng một con quái vật và nó chưa chết
	if body.is_in_group("monsters") and not body.is_dead:
		# Gây sát thương
		if is_instance_valid(attacker):
			attacker.execute_attack_on(body, false)
		# Tự hủy sau khi trúng
		queue_free()
