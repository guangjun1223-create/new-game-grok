# res://script/monster_spawner.gd
extends Node

# Đường dẫn đến scene quái vật bạn đã tạo ở Phần 2
const MONSTER_SCENE = preload("res://Scene/Monster.tscn")

var spawn_data: Dictionary
@onready var monster_container: Node = get_tree().current_scene.find_child("MonsterContainer", true, false)

func _ready():
	# Tải "kịch bản" từ file JSON
	var file = FileAccess.open("res://Data/spawn_data.json", FileAccess.READ)
	if not file:
		push_error("MonsterSpawner: Không thể mở file spawn_zones.json!")
		return
	var content = file.get_as_text()
	spawn_data = JSON.parse_string(content)
	
	if not is_instance_valid(monster_container):
		push_error("MonsterSpawner: Không tìm thấy node 'MonsterContainer' trong scene!")
		return

	# Bắt đầu tạo quái vật cho tất cả các khu vực được định nghĩa trong JSON
	for zone_name in spawn_data:
		spawn_monsters_for_zone(zone_name)

func spawn_monsters_for_zone(zone_name: String):
	if not spawn_data.has(zone_name): return

	var zone_info = spawn_data[zone_name]
	var zone_boundary = get_tree().current_scene.find_child(zone_name, true, false)
	if not is_instance_valid(zone_boundary):
		push_warning("MonsterSpawner: Không tìm thấy boundary Area2D có tên '%s'" % zone_name)
		return

	for monster_entry in zone_info.get("monsters", []):
		var monster_id = monster_entry["monster_id"]
		var quantity = monster_entry["quantity"]
		var spawn_type = monster_entry["spawn_type"]

		for i in range(quantity):
			var spawn_pos = Vector2.ZERO
			if spawn_type == "random":
				spawn_pos = _get_random_point_in_boundary(zone_boundary)
			elif spawn_type == "fixed":
				var points = monster_entry.get("spawn_points", [])
				if i < points.size():
					spawn_pos = Vector2(points[i].x, points[i].y)

			if spawn_pos != Vector2.ZERO:
				_spawn_one_monster(monster_id, spawn_pos, zone_boundary)

# Hàm tìm một điểm ngẫu nhiên bên trong một Area2D
func _get_random_point_in_boundary(boundary: Area2D) -> Vector2:
	var shape_owner = boundary.find_child("CollisionShape2D", false)
	if shape_owner is CollisionShape2D and shape_owner.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_owner.shape
		var rect_extents = rect_shape.size / 2.0
		var random_local_pos = Vector2(randf_range(-rect_extents.x, rect_extents.x), randf_range(-rect_extents.y, rect_extents.y))
		return shape_owner.global_transform * random_local_pos
	return Vector2.ZERO

func _spawn_one_monster(monster_id: String, position: Vector2, boundary: Area2D):
	var new_monster = MONSTER_SCENE.instantiate()
	monster_container.add_child(new_monster)
	
	# Khởi tạo "bộ não" của quái vật với các thông tin cần thiết
	new_monster.setup(monster_id, position, boundary)
	
	# Lắng nghe tín hiệu "chết" từ quái vật để hồi sinh nó
	new_monster.died.connect(_on_monster_died)

func _on_monster_died(monster_id, spawn_position, respawn_time, boundary):
	# Tạo một Timer tạm thời để đếm ngược thời gian hồi sinh
	var timer = Timer.new()
	timer.wait_time = respawn_time
	timer.one_shot = true
	# Dùng bind để truyền các tham số cần thiết cho hàm hồi sinh
	timer.timeout.connect(_respawn_monster.bind(monster_id, spawn_position, boundary))
	add_child(timer)
	timer.start()
	# Sau khi timeout, timer sẽ tự hủy khi hàm _respawn_monster được gọi

func _respawn_monster(monster_id: String, position: Vector2, boundary: Area2D):
	print("Hồi sinh ", monster_id, " tại ", position)
	_spawn_one_monster(monster_id, position, boundary)
	# Lấy timer vừa kích hoạt và xóa nó đi
	get_child(get_child_count() - 1).queue_free()
