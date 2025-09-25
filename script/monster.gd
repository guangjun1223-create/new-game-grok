#res://script/monster.gd
extends CharacterBody2D

# ============================================================================
# SIGNALS & ENUMS
# ============================================================================
enum MonsterState { IDLE, WANDER, CHASE, ATTACK }
enum MonsterType { NORMAL, ELITE, BOSS }

# ============================================================================
# BIẾN EXPORT (TÙY CHỈNH TRONG EDITOR)
# ============================================================================
@export var monster_id: String = ""
@export var stopping_distance: float = 200.0

# ============================================================================
# THAM CHIẾU NODE (KẾT NỐI VỚI EDITOR)
# ============================================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var detection_area: Area2D = $DetectionRadius
@onready var state_timer: Timer = $StateTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var respawn_timer: Timer = $RespawnTimer # Timer cho việc tự hồi sinh
@export var respawn_radius: float = 200.0

# ============================================================================
# BIẾN TRẠNG THÁI & CHỈ SỐ
# ============================================================================
# --- State Machine ---
var _current_state = MonsterState.IDLE
var is_dead: bool = false
var target_hero: CharacterBody2D = null
var damage_dealt_by_heroes: Dictionary = {}

# --- Chỉ số từ file JSON ---
var monster_name: String = "Monster"
var monster_type: MonsterType = MonsterType.NORMAL
var level: int = 1
var max_hp: float = 10.0
var current_hp: float
var atk: float = 1.0
var matk: float = 0.0
var def_quai: float = 0.0
var mdef_quai: float = 0.0
var hit_rate: float = 10.0
var crit_rate: float = 0.0
var giap_quai: float = 0.0
var respawn_time: float = 10.0 # Mặc định 10 giây

# --- Di chuyển & Vị trí ---
var speed: float = 100.0
var wander_radius_fixed: float = 400.0
var _initial_spawn_position: Vector2
var movement_area: Area2D
var attack_range: float = 150.0
var hit: float = 50.0  # hoặc tính theo level/quái


var exp_reward: int = 0
var gold_drop: Array = []

const DroppedItemScene = preload("res://Data/items/DroppedItem.tscn")

# ============================================================================
# HÀM KHỞI TẠO CỦA GODOT
# ============================================================================
func _ready():
	add_to_group(&"monsters")
	_initial_spawn_position = global_position
	movement_area = get_parent()

	# Kết nối tất cả các tín hiệu cần thiết
	state_timer.timeout.connect(_on_state_timer_timeout)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	
	# Kết nối tín hiệu khi animation kết thúc
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Tải dữ liệu và bắt đầu hoạt động một cách an toàn
	call_deferred("_initialize_monster")
	call_deferred("_start_idle")


# ============================================================================
# HÀM VẬT LÝ & VÒNG LẶP CHÍNH
# ============================================================================
func _process(_delta):
	if is_dead or not is_instance_valid(target_hero) or target_hero.is_dead:
		if _current_state == MonsterState.CHASE or _current_state == MonsterState.ATTACK:
			target_hero = null
			_start_idle()
		return

	# Logic ra quyết định trạng thái dựa trên khoảng cách
	var distance_to_target = global_position.distance_to(target_hero.global_position)
	if distance_to_target <= attack_range:
		_current_state = MonsterState.ATTACK
		nav_agent.target_position = global_position
	else:
		_current_state = MonsterState.CHASE
		nav_agent.target_position = target_hero.global_position

func _physics_process(_delta):
	# 1. Nếu đã chết thì bỏ qua mọi xử lý khác, để animation Death tự chạy
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 2. Xác định vận tốc dựa trên trạng thái
	if _current_state == MonsterState.IDLE or _current_state == MonsterState.ATTACK:
		velocity = Vector2.ZERO
	else: # CHASE hoặc WANDER
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			velocity = global_position.direction_to(next_pos) * speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()

	# 3. Chọn animation phù hợp (chỉ khi chưa Attack/Death)
	if animated_sprite.animation in ["Attack", "Death"]:
		# Giữ nguyên Attack/Death, không cho Idle/Walk đè
		pass
	elif velocity.length() > 5.0:
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")
	else: # Đứng yên
		if animated_sprite.animation != "Idle":
			animated_sprite.play("Idle")

	# 4. Xử lý hướng nhìn
	if is_instance_valid(target_hero):
		animated_sprite.flip_h = target_hero.global_position.x < global_position.x
	elif velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0


# ============================================================================
# HỆ THỐNG CHIẾN ĐẤU & SÁT THƯƠNG
# ============================================================================
func take_damage(amount: float, from_hero = null):
	if is_dead: return
	current_hp -= amount
	hp_bar.value = current_hp
	
	if is_instance_valid(from_hero):
		if damage_dealt_by_heroes.has(from_hero):
			damage_dealt_by_heroes[from_hero] += amount
		else:
			damage_dealt_by_heroes[from_hero] = amount
	
	if current_hp <= 0:
		die(from_hero)
	elif is_instance_valid(from_hero):
		# SỬA LỖI Ở ĐÂY: Chỉ chuyển sang CHASE nếu đang không phải combat
		if _current_state == MonsterState.IDLE or _current_state == MonsterState.WANDER:
			target_hero = from_hero
			_current_state = MonsterState.CHASE
			state_timer.stop()
			attack_timer.start()

func _on_attack_timer_timeout():
	
	if is_dead or not is_instance_valid(target_hero):
		return
		
	if _current_state != MonsterState.ATTACK:
		return
		
	var distance = global_position.distance_to(target_hero.global_position)
	if distance > attack_range + 10:
		return
		
	animated_sprite.play("Attack")
	_apply_damage_to_hero() # Tạm thời tắt để chỉ kiểm tra animation

func _apply_damage_to_hero():
	# Hàm này được gọi bởi animation để gây sát thương
	if is_dead or not is_instance_valid(target_hero): return

	if global_position.distance_to(target_hero.global_position) <= attack_range + 20:
		# 1. Yêu cầu CombatUtils tính toán và trả về "báo cáo"
		var combat_result = CombatUtils.quai_tan_cong_hero(atk, matk, hit_rate, crit_rate, level, target_hero.def, target_hero.mdef, target_hero.flee, target_hero.level, false)

		# 2. Lấy vị trí hiển thị chữ (trên đầu Hero)
		var text_position = target_hero.global_position - Vector2(0, 250)

		# 3. Đọc "báo cáo" và yêu cầu hiển thị
		if combat_result.is_miss:
			FloatingTextManager.show_text("MISS!!",Color.WEB_GRAY, text_position)
		else:
			var text_to_show = str(combat_result.damage)
			var color = Color.WHITE # Sát thương quái gây ra có màu khác
			if combat_result.is_crit:
				color = Color.RED # Crit của quái có màu đỏ
				text_to_show += "!!"

			FloatingTextManager.show_text(text_to_show, color, text_position, combat_result.is_crit)

			# 4. Gây sát thương thực sự lên Hero
			if combat_result.damage > 0:
				target_hero.take_damage(combat_result.damage, self)

# ============================================================================
# HỆ THỐNG SỰ SỐNG & CÁI CHẾT (TỰ HỒI SINH)
# ============================================================================
func die(last_hitter = null):
	if is_dead:
		return
	is_dead = true

	print(">>> Quái vật '%s' đang chết..." % monster_name)

	# BƯỚC 1: XỬ LÝ PHẦN THƯỞNG NGAY LẬP TỨC
	_distribute_exp(last_hitter)
	_handle_drops() # << DÒNG LỆNH QUAN TRỌNG NHẤT ĐÃ ĐƯỢC THÊM VÀO

	# BƯỚC 2: DỌN DẸP TRẠNG THÁI & VẬT LÝ
	velocity = Vector2.ZERO
	attack_timer.stop()
	state_timer.stop()
	target_hero = null
	collision_shape.set_deferred("disabled", true)
	damage_dealt_by_heroes.clear()
	_current_state = MonsterState.IDLE

	# BƯỚC 3: KÍCH HOẠT ANIMATION CUỐI CÙNG
	animated_sprite.play("Death")
	
	

func _on_respawn_timer_timeout():
	print(">>> HỒI SINH: '%s' đã trở lại!" % monster_name)
	is_dead = false
	current_hp = max_hp
	hp_bar.value = current_hp

	# --- LOGIC HỒI SINH NGẪU NHIÊN ---
	# 1. Tạo một vị trí ngẫu nhiên trong bán kính hồi sinh
	var offset = Vector2(randf_range(-respawn_radius, respawn_radius), randf_range(-respawn_radius, respawn_radius))
	var candidate_pos = _initial_spawn_position + offset

	# 2. Tìm điểm hợp lệ gần nhất trên bản đồ di chuyển (NavMesh) để tránh kẹt tường
	var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, candidate_pos)

	# 3. Đặt vị trí và reset agent
	global_position = valid_nav_point
	nav_agent.target_position = global_position

	# Kích hoạt lại các thành phần
	collision_shape.disabled = false
	show() # Dùng show() để hiện lại một cách đáng tin cậy

	_start_idle()

# ============================================================================
# HỆ THỐNG TRÍ TUỆ NHÂN TẠO (AI)
# ============================================================================
func _start_idle():
	_current_state = MonsterState.IDLE
	nav_agent.target_position = global_position
	# Bắt đầu đếm giờ để chuyển sang đi lang thang
	state_timer.start(randf_range(3.0, 5.0))
	animated_sprite.play("Idle")

func _on_state_timer_timeout():
	match _current_state:
		MonsterState.IDLE:
			_current_state = MonsterState.WANDER
			_start_wander()
			var wander_time = randf_range(3.0, 5.0)
			state_timer.start(wander_time)
		MonsterState.WANDER:
			_current_state = MonsterState.IDLE
			_stop_moving()
			var idle_time = randf_range(3.0, 5.0)
			state_timer.start(idle_time)

func _stop_moving():
	nav_agent.target_position = global_position
	velocity = Vector2.ZERO


func _start_wander():
	var tries = 0
	while tries < 10:
		tries += 1 # Tăng biến đếm để tránh vòng lặp vô tận

		# 1. Chọn một điểm ngẫu nhiên xung quanh vị trí ban đầu
		var offset = Vector2(randf_range(-wander_radius_fixed, wander_radius_fixed), randf_range(-wander_radius_fixed, wander_radius_fixed))
		var candidate_pos = _initial_spawn_position + offset
		
		# 2. Lấy ra Node CollisionShape2D từ khu vực di chuyển
		var shape_node = movement_area.find_child("CollisionShape2D")
		if not shape_node:
			# Nếu không tìm thấy shape, không thể đi lang thang -> quay về IDLE
			_start_idle()
			return

		# 3. Lấy ra hình chữ nhật (Rect2) với tọa độ TOÀN CỤC
		var global_rect = shape_node.get_global_transform() * shape_node.shape.get_rect()
		
		# 4. Kiểm tra xem điểm ngẫu nhiên có nằm trong hình chữ nhật toàn cục đó không
		if global_rect.has_point(candidate_pos):
			# 5. Nếu điểm hợp lệ, tìm điểm gần nhất trên NavMesh và ra lệnh di chuyển
			var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, candidate_pos)
			nav_agent.target_position = valid_nav_point
			state_timer.start(randf_range(5.0, 8.0)) # Đặt giờ để quay lại IDLE
			return # Đã tìm thấy điểm, thoát khỏi hàm

	# Nếu sau 10 lần thử vẫn không tìm được điểm hợp lệ, hãy quay lại IDLE
	_start_idle()

func _on_hero_entered(body):
	# Dành cho quái Elite/Boss tự động tấn công
	if is_dead or not body.is_in_group("heroes") or monster_type == MonsterType.NORMAL:
		return
	if not is_instance_valid(target_hero):
		target_hero = body
		_current_state = MonsterState.CHASE
		state_timer.stop()
		attack_timer.start()

func _on_hero_exited(body):
	if body == target_hero:
		target_hero = null
		
# ============================================================================
# CÁC HÀM HỖ TRỢ
# ============================================================================
func _initialize_monster():
	if monster_id == "": return
	var data = MonsterManager.get_monster_data(monster_id)
	if data.is_empty(): queue_free(); return

	# Tải dữ liệu chính
	monster_name = data.get("name", "Unnamed Monster")
	level = data.get("level", 1)
	respawn_time = data.get("respawn_time", 10.0)
	
	var monster_type_string = data.get("type", "NORMAL").to_upper()
	if monster_type_string == "ELITE": monster_type = MonsterType.ELITE
	elif monster_type_string == "BOSS": monster_type = MonsterType.BOSS
	else: monster_type = MonsterType.NORMAL

	# Tải chỉ số
	var stats = data.get("stats", {})
	max_hp = stats.get("max_hp", 10.0)
	atk = stats.get("atk", 1.0)
	matk = stats.get("matk", 0.0)
	def_quai = stats.get("def", 0.0)
	mdef_quai = stats.get("mdef", 0.0)
	hit_rate = stats.get("hit", 1.0)
	crit_rate = stats.get("crit", 0.0)
	giap_quai = stats.get("giap", 0.0)
	exp_reward = data.get("exp_reward", 0)
	gold_drop = data.get("gold_drop", [])

	# Tải hình ảnh
	var frames_path = data.get("sprite_frames_path", "")
	if frames_path != "" and FileAccess.file_exists(frames_path):
		animated_sprite.sprite_frames = load(frames_path)
	
	# Thiết lập máu và thanh HP
	current_hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

		
func _on_animation_finished():
	if not is_dead:
		# Quái còn sống thì chỉ xử lý Attack
		if animated_sprite.animation == "Attack" and _current_state == MonsterState.ATTACK:
			animated_sprite.play("Idle")
	else:
		# Nếu đang chết và animation Death vừa kết thúc
		if animated_sprite.animation == "Death":
			hide()
			respawn_timer.start(respawn_time)
			print(">>> Quái vật '%s' đã chết. Hồi sinh sau %.1f giây." % [monster_name, respawn_time])
			
	
func get_body_radius() -> float:
	# Lấy ra hình dạng va chạm chính của Hero
	var shape = collision_shape.shape

	# --- BỘ NÃO ĐO ĐẠC MỚI ---
	# Kiểm tra xem hình dạng thuộc loại nào

	# NẾU LÀ HÌNH CON NHỘNG (CAPSULE)
	if shape is CapsuleShape2D:
		# Bán kính của hình con nhộng chính là chiều rộng của nó
		return shape.radius

	# NẾU LÀ HÌNH TRÒN (CIRCLE)
	elif shape is CircleShape2D:
		return shape.radius

	# NẾU LÀ HÌNH CHỮ NHẬT (RECTANGLE)
	elif shape is RectangleShape2D:
		return shape.size.x / 2

	# Nếu là một hình dạng phức tạp nào khác (ví dụ Polygon),
	# trả về một giá trị mặc định an toàn.
	return 30.0

func _distribute_exp(last_hitter = null):
	if damage_dealt_by_heroes.is_empty():
		return # Không có ai tấn công thì không chia EXP

	var total_exp_to_give = float(exp_reward)
	print("\n--- Monster Died! Distributing %d EXP ---" % total_exp_to_give)

	for hero in damage_dealt_by_heroes:
		# Bỏ qua nếu hero không còn tồn tại
		if not is_instance_valid(hero):
			continue

		var damage_dealt = damage_dealt_by_heroes[hero]
		var damage_percent = damage_dealt / max_hp
		var exp_share = total_exp_to_give * damage_percent

		# Kiểm tra thưởng đòn kết liễu
		if hero == last_hitter:
			var bonus_exp = exp_share * 0.20 # 20% bonus
			exp_share += bonus_exp
			print("   -> %s (dealt %.1f%% dmg) gets %.1f EXP + %.1f BONUS!" % [hero.hero_name, damage_percent * 100, (exp_share - bonus_exp), bonus_exp])
		else:
			print("   -> %s (dealt %.1f%% dmg) gets %.1f EXP." % [hero.hero_name, damage_percent * 100, exp_share])
		
		# Gửi EXP cho Hero (làm tròn)
		hero.gain_exp(roundi(exp_share))
	
	print("---------------------------------------\n")

func _handle_drops():
	var data = MonsterManager.get_monster_data(monster_id)
	if not data: return

	# 1. Xử lý rơi Vàng
	if data.has("gold_drop") and data["gold_drop"] is Array and data["gold_drop"].size() == 2:
		var min_gold = data["gold_drop"][0]
		var max_gold = data["gold_drop"][1]
		var amount = randi_range(min_gold, max_gold)
		if amount > 0:
			_spawn_item("gold_coin", amount)

	# 2. Xử lý rơi Vật phẩm từ "loot_table"
	if data.has("loot_table") and data["loot_table"] is Array:
		for loot_data in data["loot_table"]:
			var item_id = ""
			var chance = 100.0 # Mặc định 100%
			var min_qty = 1
			var max_qty = 1

			# Phân tích data, dù là String hay Dictionary
			if loot_data is String:
				item_id = loot_data
			elif loot_data is Dictionary:
				item_id = loot_data.get("item_id", "")
				# Tương thích với chance dạng 1.0 = 100%
				chance = float(loot_data.get("chance", 1.0)) * 100.0
				if loot_data.has("quantity") and loot_data["quantity"] is Array and loot_data["quantity"].size() == 2:
					min_qty = loot_data["quantity"][0]
					max_qty = loot_data["quantity"][1]

			if item_id.is_empty():
				continue

			# Tung xúc xắc
			if randf() * 100.0 < chance:
				var quantity = randi_range(min_qty, max_qty)
				if quantity > 0:
					_spawn_item(item_id, quantity)

# Hàm phụ trợ tạo vật phẩm rơi, đã được tối ưu
func _spawn_item(p_item_id: String, p_quantity: int):
	# Đảm bảo scene vật phẩm đã được load
	if not DroppedItemScene:
		push_error("monster.gd: DroppedItemScene chưa được preload!")
		return

	var drop_instance = DroppedItemScene.instantiate()
	drop_instance.item_id = p_item_id
	drop_instance.quantity = p_quantity

	# Hiệu ứng văng ra
	var angle = randf_range(0, TAU)
	var distance = randf_range(100.0, 100.0)
	var offset = Vector2.RIGHT.rotated(angle) * distance
	var target_pos = self.global_position + offset
	var valid_pos = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, target_pos)

	drop_instance.global_position = valid_pos
	get_parent().call_deferred("add_child", drop_instance)
