# res://script/monster.gd
extends CharacterBody2D
class_name Monster

# Tín hiệu báo cho Spawner biết nó đã chết để chuẩn bị hồi sinh
signal died(monster_id, spawn_position, respawn_time, movement_boundary)

# Các trạng thái (hành vi) của quái vật
enum State { IDLE, WANDERING, CHASING, ATTACKING, RETURNING, DEAD }

# --- CÁC BIẾN THUỘC TÍNH ---
var monster_id: String
var monster_data: Dictionary
var stats: Dictionary
var current_hp: float

var current_state: State = State.IDLE
var target_hero: Hero = null
var spawn_position: Vector2 # Vị trí "nhà"
var patrol_radius: float = 0.0
var ai_type: String = "PASSIVE"
var movement_boundary: Area2D

# --- THAM CHIẾU NODE (@ONREADY) ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var state_timer: Timer = $StateTimer
@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var name_label: Label = $HPBar/NameLabel

# Hàm được gọi bởi MonsterSpawner để khởi tạo quái vật
func setup(p_monster_id: String, p_spawn_position: Vector2, p_movement_boundary: Area2D):
	self.monster_id = p_monster_id
	self.spawn_position = p_spawn_position
	self.global_position = p_spawn_position
	self.movement_boundary = p_movement_boundary
	self.stats = MonsterDataManager.calculate_final_stats(monster_data)
	
	if is_instance_valid(name_label):
		name_label.text = monster_data.get("name", monster_id)

	# Lấy "sơ yếu lý lịch" từ file JSON
	self.monster_data = MonsterDataManager.get_monster_definition(monster_id)
	if monster_data.is_empty():
		push_error("Không tìm thấy dữ liệu cho quái vật ID: %s" % monster_id)
		queue_free() # Tự hủy nếu không có dữ liệu
		return
		
	# Tính toán chỉ số cuối cùng
	self.stats = MonsterDataManager.calculate_final_stats(monster_data)
	
	self.current_hp = stats.get("max_hp", 1)
	self.ai_type = monster_data.get("ai_type", "PASSIVE")
	self.patrol_radius = monster_data.get("patrol_radius", 0)

	# --- LOGIC "THAY DA ĐỔI THỊT" (PHIÊN BẢN AN TOÀN) ---
	if is_instance_valid(skeleton):
		for child in skeleton.get_children(true):
			if child is Sprite2D:
				child.visible = false

	var appearance_data = monster_data.get("appearance", {})
	for sprite_name in appearance_data:
		var sprite_node = find_child(sprite_name, true, false)
		
		if sprite_node is Sprite2D:
			var texture_path = appearance_data[sprite_name]
			
			if not texture_path.is_empty() and FileAccess.file_exists(texture_path):
				sprite_node.texture = load(texture_path)
				sprite_node.visible = true
			else:
				if not texture_path.is_empty():
					push_warning("Không tìm thấy file hình ảnh tại: '%s' cho sprite '%s'" % [texture_path, sprite_name])
		else:
			push_warning("Không tìm thấy Sprite2D có tên '%s' để áp dụng hình ảnh." % sprite_name)
	
	# --- DÒNG QUAN TRỌNG NHẤT CẦN KIỂM TRA ---
	# Đảm bảo bạn có 2 dòng kết nối tín hiệu này ở cuối hàm setup
	state_timer.timeout.connect(_on_state_timer_timeout)

	_update_hp_display()
	doi_trang_thai(State.IDLE)

func _physics_process(_delta):

	if current_state in [State.DEAD, State.ATTACKING]:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# --- LOGIC DI CHUYỂN ---
	if not nav_agent.is_navigation_finished():
		var next_path_position = nav_agent.get_next_path_position()
		var move_speed = stats.get("move_speed", 100)
		velocity = global_position.direction_to(next_path_position) * move_speed
	else:
		velocity = Vector2.ZERO
	# --------------------------
	
	move_and_slide()

	# Khối match để xử lý logic AI
	match current_state:
		State.WANDERING:
			if nav_agent.is_navigation_finished():
				_wander()
		State.CHASING:
			_update_chasing()
		State.RETURNING:
			if nav_agent.is_navigation_finished():
				doi_trang_thai(State.IDLE)
	
	# Các hàm cập nhật hình ảnh
	_update_animation()
	_update_flip_direction()



# Hàm này sẽ được gọi bởi tín hiệu velocity_computed của NavigationAgent2D
func _on_nav_agent_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func doi_trang_thai(new_state):
	if current_state == new_state: return
	current_state = new_state
	
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			state_timer.start(randf_range(3.0, 5.0))
		State.WANDERING:
			_wander()
		State.CHASING:
			# animation_player.play("Run")
			pass
		State.RETURNING:
			target_hero = null
			nav_agent.target_position = spawn_position
		State.DEAD:
			velocity = Vector2.ZERO
			# Tắt va chạm, phát animation chết
			$CollisionShape2D.set_deferred("disabled", true)
			detection_area.monitoring = false
			animation_player.play(&"monster/Death")
			# Sau khi animation Death chạy xong, sẽ gọi hàm die() thực sự

# --- CÁC HÀM HÀNH VI ---

func _wander():
	var target_pos = spawn_position
	if patrol_radius > 0:
		# Lang thang quanh điểm spawn (cho boss/elite)
		target_pos = spawn_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(0, patrol_radius)
	else:
		# Lang thang ngẫu nhiên trong boundary (cho quái thường)
		if is_instance_valid(movement_boundary):
			var shape_owner = movement_boundary.find_child("CollisionShape2D", false)
			if shape_owner is CollisionShape2D and shape_owner.shape is RectangleShape2D:
				var rect_shape: RectangleShape2D = shape_owner.shape
				var rect_extents = rect_shape.size / 2.0
				var random_local_pos = Vector2(randf_range(-rect_extents.x, rect_extents.x), randf_range(-rect_extents.y, rect_extents.y))
				target_pos = shape_owner.global_position + random_local_pos
				

	nav_agent.target_position = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, target_pos)
	

func _update_chasing():
	if not is_instance_valid(target_hero) or target_hero.is_dead:
		doi_trang_thai(State.RETURNING)
		return

	var _distance_to_hero = global_position.distance_to(target_hero.global_position)
	var distance_from_spawn = global_position.distance_to(spawn_position)
	
	# "Dây xích": Nếu đi quá xa nhà, quay về
	if distance_from_spawn > 800:
		doi_trang_thai(State.RETURNING)
		return
	
	# Nếu đủ gần để tấn công, chuyển sang trạng thái tấn công
	# if distance_to_hero <= stats.get("attack_range", 50):
	# 	doi_trang_thai(State.ATTACKING)
	# else: # Nếu chưa đủ gần, tiếp tục đuổi theo
	nav_agent.target_position = target_hero.global_position

func _update_animation():
	if velocity.length() > 1:
		animation_player.play(&"monster/Walk")
	else:
		animation_player.play(&"monster/Idle")

func take_damage(amount, attacker: Hero):
	if current_state == State.DEAD: return
	
	current_hp -= amount
	FloatingTextManager.show_text(str(amount), Color.RED, global_position - Vector2(0, 80))
	
	_update_hp_display()
	
	if current_hp <= 0:
		doi_trang_thai(State.DEAD)
		if is_instance_valid(attacker):
			attacker.gain_exp(monster_data.get("exp_reward", 0))
		return
	
	# Bị đánh sẽ "nổi điên" và đuổi theo, bất kể loại AI
	if is_instance_valid(attacker) and target_hero == null:
		target_hero = attacker
		doi_trang_thai(State.CHASING)

func die():
	# Rớt vàng và vật phẩm
	# (Logic rớt đồ sẽ được thêm vào đây)
	var gold_to_drop = randi_range(monster_data.get("gold_drop", [0,0])[0], monster_data.get("gold_drop", [0,0])[1])
	if gold_to_drop > 0:
		# (Code tạo ra DroppedItem cho vàng)
		pass

	# Báo cho Spawner biết để hồi sinh
	died.emit(monster_id, spawn_position, monster_data.get("respawn_time", 60.0), movement_boundary)
	queue_free()

# --- XỬ LÝ TÍN HIỆU ---

func _on_state_timer_timeout():
	# Khi đang ở trạng thái IDLE và timer kết thúc, chuyển sang lang thang
	if current_state == State.IDLE:
		doi_trang_thai(State.WANDERING)

func _on_hero_entered(body):
	# Chỉ tự động tấn công nếu là loại "hung hăng" và chưa có mục tiêu
	if ai_type == "AGGRESSIVE" and body is Hero and target_hero == null and not body.is_dead:
		print("[AI] Quái vật '", monster_id, "' phát hiện Hero '", body.name, "' và bắt đầu truy đuổi.")
		target_hero = body
		doi_trang_thai(State.CHASING)

func _on_hero_exited(body):
	# Nếu hero thoát khỏi vùng phát hiện chính là mục tiêu hiện tại, hủy mục tiêu
	if body == target_hero:
		print("[AI] Quái vật '", monster_id, "' đã mất dấu Hero '", body.name, "'.")
		target_hero = null
		# Máy trạng thái trong hàm _update_chasing sẽ tự động chuyển sang trạng thái RETURNING

func _on_animation_player_animation_finished(anim_name):
	# Animation chết chạy xong thì mới thực sự biến mất và rớt đồ
	if anim_name == "monster/Death":
		die()

func _update_flip_direction():
	# Thêm chốt an toàn để tránh lỗi nếu skeleton chưa sẵn sàng
	if not is_instance_valid(skeleton): return

	var x_scale = abs(skeleton.scale.x)
	
	# Ưu tiên lật mặt theo mục tiêu đang đuổi theo
	if is_instance_valid(target_hero):
		if target_hero.global_position.x < self.global_position.x:
			skeleton.scale.x = -x_scale
		else:
			skeleton.scale.x = x_scale
	# Nếu không có mục tiêu, lật mặt theo hướng di chuyển (velocity)
	elif abs(velocity.x) > 1.0:
		if velocity.x < 0:
			skeleton.scale.x = -x_scale
		else:
			skeleton.scale.x = x_scale
			
func _update_hp_display():
	if is_instance_valid(hp_bar):
		hp_bar.max_value = stats.get("max_hp", 1)
		hp_bar.value = current_hp
		
