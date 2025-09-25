extends Area2D
class_name DroppedItem

var item_id: String
var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite2D

# Biến cho hiệu ứng hút vật phẩm
var target_hero: Hero = null
var move_speed: float = 400.0
var can_pickup: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(queue_free)

	var item_icon = ItemDatabase.get_item_icon(item_id)
	if item_icon:
		sprite.texture = item_icon
	else:
		print("Không tìm thấy icon cho item: ", item_id)

func _physics_process(delta):
	# Nếu chưa có mục tiêu, không làm gì cả
	if not is_instance_valid(target_hero):
		return

	# Di chuyển về phía mục tiêu
	global_position = global_position.move_toward(target_hero.global_position, move_speed * delta)

	# Kiểm tra khoảng cách để nhặt
	if global_position.distance_to(target_hero.global_position) < 10:
		pickup_item(target_hero)


func _on_body_entered(body):
	# Khi hero đi vào vùng, bắt đầu bị hút
	if body is Hero and target_hero == null and can_pickup:
		target_hero = body

func pickup_item(hero: Hero):
	# Đảm bảo chỉ nhặt 1 lần
	if not can_pickup: return
	can_pickup = false

	var success = false
	# Xử lý riêng cho Vàng
	if item_id == "gold_coin":
		hero.add_gold(quantity)
		success = true
	# Xử lý cho các vật phẩm khác
	else:
		success = hero.add_item(item_id, quantity)

	# Nếu nhặt thành công thì biến mất
	if success:
		queue_free()
	else:
		# Nếu túi đồ đầy, vật phẩm sẽ ngừng di chuyển để hero có thể thử lại sau
		target_hero = null
		can_pickup = true # Cho phép thử nhặt lại
