#res://script/hero.gd
extends CharacterBody2D
class_name Hero

signal exp_changed(current_exp, exp_to_next_level)
signal stats_updated
signal equipment_changed(new_equipment)
signal inventory_changed
signal gold_changed(new_gold_amount)
signal started_resting(hero, heal_rate) # Báo cho Inn biết để tạo thanh trạng thái
signal finished_resting(hero) # Báo cho Inn biết để xóa thanh trạng thái
signal sp_changed(current_sp, max_sp)
var heal_rate: float = 0.0
var sp_rate: float = 0.0

const magic_ball = preload("res://Data/items/magic.tscn")
const arrow = preload("res://Data/items/arow.tscn")
const SP_COST_PER_SPELL: int = 5
const MAX_LEVEL_NOVICE: int = 10

# ============================================================================
# ENUMS & HẰNG SỐ
# ============================================================================
enum State {
	IDLE,       # Đứng yên
	WANDER,     # Đi lang thang
	NAVIGATING, # Di chuyển giữa các khu vực
	COMBAT,     # Chiến đấu
	GHOST,     # Trạng thái linh hồn sau khi chết
	TRADING,
	RESTING,
	IN_BARRACKS
}

const ATTACK_RANGE: float = 150.0
const HEAL_PER_SECOND_IN_VILLAGE: float = 0.5
const SP_PER_SECOND_IN_VILLAGE: float = 0.5

@export var stopping_distance: float = 50.0
var death_timer: float = 0.0
const HERO_INVENTORY_SIZE: int = 20
var _ui_controller: UIController
var is_ui_interacting: bool = false
var is_resting: bool = false
var current_heal_rate: float = 0.0

var bonus_hit_hidden: float = 0.0
var bonus_crit_rate_hidden: float = 0.0
var attack_speed_calculated: float = 2.0
var attack_range_calculated: float = 150.0

# ============================================================================
# THAM CHIẾU NODE (KẾT NỐI VỚI EDITOR)
# ============================================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_timer: Timer = $StateTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var detection_area: Area2D = $DetectionRadius
@onready var attack_area: Area2D = $AttackArea
@onready var attack_range_area: Area2D = $AttackRangeArea
@onready var attack_area_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel

# ============================================================================
# BIẾN TRẠNG THÁI & CHỈ SỐ
# ============================================================================
# --- State Machine ---
var _current_state = State.IDLE
var is_dead: bool = false

# --- Chỉ số Gốc (Random từ Gacha) ---
var str_co_ban: float = 1.0
var agi_co_ban: float = 1.0
var vit_co_ban: float = 1.0
var int_co_ban: float = 1.0
var dex_co_ban: float = 1.0
var luk_co_ban: float = 1.0

# --- Tăng trưởng (Từ Nghề + Độ hiếm) ---
var str_tang_truong: float = 0.0
var agi_tang_truong: float = 0.0
var vit_tang_truong: float = 0.0
var int_tang_truong: float = 0.0
var dex_tang_truong: float = 0.0
var luk_tang_truong: float = 0.0

# --- Chỉ số Chính (Tính toán) ---
var STR: float = 1.0
var agi: float = 1.0
var vit: float = 1.0
var intel: float = 1.0
var dex: float = 1.0
var luk: float = 1.0

# --- Chỉ số Phụ (Tính toán) ---
var max_hp: float = 0.0
var current_hp: float = 0.0
var max_sp: float = 0.0
var current_sp: float = 0.0
var atk: float = 0.0
var matk: float = 0.0
var def: float = 0.0
var mdef: float = 0.0
var def_min: float = 0.0
var def_max: float = 0.0

var hit: float = 0.0
var flee: float = 0.0
var crit_rate: float = 0.0
var crit_damage: float = 1.5

# === PHẦN 1: KHỞI TẠO CÁC BIẾN BONUS TỪ TRANG BỊ ===
var bonus_str: float = 0.0
var bonus_agi: float = 0.0
var bonus_vit: float = 0.0
var bonus_intel: float = 0.0
var bonus_dex: float = 0.0
var bonus_luk: float = 0.0
var bonus_atk: float = 0.0
var bonus_matk: float = 0.0
var bonus_max_hp: float = 0.0
var bonus_max_sp: float = 0.0
var bonus_def: float = 0.0
var bonus_mdef: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_hit: float = 0.0
var bonus_flee: float = 0.0
var bonus_crit_rate: float = 0.0
var bonus_crit_dame: float = 0.0
# --- Thông tin & Di chuyển ---
var level: int = 1
var hero_name: String = "Tan Binh"
var job_key: String = "Novice"
var speed: float = 150.0
var movement_area: Area2D
var gate_connections: Array[GateConnection] = []
var world_node: Node2D
var _current_route: Array = []
var _current_navigation_gate: Node2D = null
var _boundary_shape: Shape2D = null
var _boundary_transform: Transform2D
var target_monster = null
var su_dung_phep: bool = false
var gold: int = 0

var current_exp: int = 0
var exp_to_next_level: int = 100

# --- Điều khiển Animation Tấn công ---
var attack_hit_frame = 5
var has_dealt_damage_this_attack = false

# --- Trang bị ---
var inventory: Array = [] 
var equipment: Dictionary = {
	"MAIN_HAND": null,
	"OFF_HAND": null,
	"HELMET": null,
	"ARMOR": null,
	"PANTS": null, # Bạn có thể thêm ô Quần vào giao diện nếu muốn
	"GLOVES": null,
	"BOOTS": null,
	"AMULET": null,
	"RING": null,

	# === PHẦN THÊM VÀO ===
	"POTION_1": null,
	"POTION_2": null,
	"POTION_3": null
}

const GATE_ARRIVAL_RADIUS: float = 30.0
var attack_reset_frame = 8
var nearest_monster = null

# ============================================================================
# HÀM KHỞI TẠO CỦA GODOT
# ============================================================================
func _ready() -> void:
	# Kết nối các tín hiệu
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	state_timer.timeout.connect(_on_state_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	GameEvents.inn_room_chosen.connect(_on_inn_room_chosen)

	# Thiết lập ban đầu
	name_label.text = hero_name
	_initialize_stats()
	current_hp = max_hp
	current_sp = max_sp
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	attack_timer.wait_time = attack_speed_calculated
	
	_update_hp_display()

	# Tải hình ảnh
	var frames_resource = load("res://Data/novice.tres")
	if frames_resource:
		animated_sprite.sprite_frames = frames_resource
	else:
		push_error("Khong the tai resource sprite frames: res://Data/novice.tres")

	# Bắt đầu vòng lặp trạng thái
	doi_trang_thai(State.IDLE)


func setup(starting_items: Array, starting_gold: int) -> void:
	# 1) Init túi đồ riêng cho hero
	if inventory.is_empty():
		inventory.resize(HERO_INVENTORY_SIZE)
		inventory.fill(null)

	# 2) Nạp item khởi đầu (mỗi phần tử dạng {"id": String, "quantity": int})
	for pkg in starting_items:
		if typeof(pkg) == TYPE_DICTIONARY and pkg.has("id"):
			var idx := inventory.find(null)
			if idx != -1:
				inventory[idx] = {
					"id": pkg["id"],
					"quantity": int(pkg.get("quantity", 1))
				}

	# 3) Gán vàng ban đầu
	gold = starting_gold

	# 4) Báo cho UI cập nhật
	inventory_changed.emit()
	gold_changed.emit(gold)
	
# ============================================================================
# HÀM VẬT LÝ & INPUT
# ============================================================================
func _physics_process(_delta: float) -> void:
	if _current_state == State.IN_BARRACKS:
		return
	_handle_passive_regeneration(_delta)
	_xu_ly_tu_dong_dung_potion()
	if _current_state == State.RESTING:
		velocity = Vector2.ZERO # Đảm bảo vận tốc bằng 0

	if is_dead:
		# Đếm thời gian khi hero vừa chết
		if death_timer > 0:
			death_timer -= _delta
			if death_timer <= 0:
				# Chuyển sang trạng thái ghost sau 3 giây
				doi_trang_thai(State.GHOST)
				remove_from_group("heroes")
				detection_area.monitoring = false
				modulate = Color(1, 1, 1, 0.3)
				animated_sprite.play("Walk")
				if is_instance_valid(PlayerStats.ghost_respawn_point):
					nav_agent.target_position = PlayerStats.ghost_respawn_point.global_position
				else:
					push_error("Không thấy điểm hồi sinh")
					if is_instance_valid(PlayerStats.village_boundary):
						nav_agent.target_position = PlayerStats.village_boundary.global_position

		# Khi là linh hồn, vẫn cho phép di chuyển về điểm hồi sinh
		if _current_state == State.GHOST and not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_pos)
			velocity = dir * speed
			animated_sprite.flip_h = velocity.x < 0
		else:
			velocity = Vector2.ZERO

		move_and_slide()
		return

	# Xử lý logic di chuyển dựa trên trạng thái nếu chưa chết
	match _current_state:
		State.COMBAT:
			# 1. Luôn kiểm tra mục tiêu trước
			if not is_instance_valid(target_monster) or target_monster.is_dead:
				target_monster = null
				find_new_target_in_radius()
				return
			# 2. Luôn quay mặt về phía mục tiêu
			animated_sprite.flip_h = target_monster.global_position.x < global_position.x
			# 3. Tính toán khoảng cách hiện tại đến quái vật
			var distance_to_monster = global_position.distance_to(target_monster.global_position)
			# 4. Logic DI CHUYỂN và TẤN CÔNG mới:
			# - NẾU đang ở ngoài tầm đánh (ATTACK_RANGE)
			if distance_to_monster > attack_range_calculated:
			# Thì tiếp tục di chuyển lại gần quái vật
				nav_agent.target_position = target_monster.global_position
				var next_pos = nav_agent.get_next_path_position()
				velocity = global_position.direction_to(next_pos) * speed
	#    - NGƯỢC LẠI, NẾU đã vào trong tầm đánh
			else:
		# Thì dừng lại ngay lập tức
				velocity = Vector2.ZERO
		# Và để cho _on_attack_timer_timeout() tự lo việc tấn công
	
		_:
			if nav_agent.is_navigation_finished():
				velocity = Vector2.ZERO
			else:
				var next_pos = nav_agent.get_next_path_position()
				velocity = global_position.direction_to(next_pos) * speed

	move_and_slide()

	# Cập nhật animation
	if animated_sprite.animation not in [&"Attack", &"Death"]:
		if velocity.length() > 5.0:
			animated_sprite.play(&"Walk")
		else:
			animated_sprite.play(&"Idle")

	if _current_state != State.COMBAT:
		if abs(velocity.x) > 0.1:
			animated_sprite.flip_h = velocity.x < 0

	_update_attack_area_position()


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		GameEvents.hero_selected.emit(self)	
	
# ============================================================================
# HỆ THỐNG TRẠNG THÁI (STATE MACHINE)
# ============================================================================
func doi_trang_thai(new_state: State) -> void:
	if _current_state == new_state and _current_state != State.WANDER:
		return
		
	_current_state = new_state
	
	match _current_state:
		State.IDLE:
			state_timer.start(randf_range(3.0, 5.0))
			attack_timer.stop()
		State.WANDER:
			if cap_nhat_ranh_gioi_di_chuyen():
				chon_diem_den_ngau_nhien()
				state_timer.start(randf_range(5.0, 8.0))
			else:
				push_error("LỖI WANDER: Không tìm thấy ranh giới, quay lại IDLE.")
				doi_trang_thai(State.IDLE)
			attack_timer.stop()
		State.NAVIGATING, State.GHOST, State.TRADING:
			state_timer.stop()
			attack_timer.stop()
		State.RESTING:
			collision_shape.disabled = true
			state_timer.stop()
			attack_timer.stop()
		State.COMBAT:
			state_timer.stop()
			attack_timer.start()

func _on_state_timer_timeout():
	if is_ui_interacting: return
	if is_dead: return
	if _current_state == State.IDLE:
		doi_trang_thai(State.WANDER)
	elif _current_state == State.WANDER:
		doi_trang_thai(State.IDLE)	
	
# ============================================================================
# HỆ THỐNG CHIẾN ĐẤU & SÁT THƯƠNG
# ============================================================================
func _on_attack_timer_timeout():
	if is_dead or _current_state != State.COMBAT or not is_instance_valid(target_monster):
		return

	if velocity.length() < 1.0: # Nếu Hero đã đứng yên
		var main_hand_item_id = ""
		var main_hand = equipment.get("MAIN_HAND")
		if main_hand is String:
			main_hand_item_id = main_hand
		
		var weapon_data = {}
		if not main_hand_item_id.is_empty():
			weapon_data = ItemDatabase.get_item_data(main_hand_item_id)
		
		var weapon_type = weapon_data.get("weapon_type", "SWORD")

		# === LOGIC MỚI: CHỌN ĐÚNG LOẠI ĐẠN ĐÃ NẠP SẴN ===
		match weapon_type:
			"STAFF":
				# Nếu là Gậy Phép, bắn ra magic_ball với sát thương phép (matk)
				if current_sp >= SP_COST_PER_SPELL:
					# BƯỚC 2: NẾU ĐỦ, TRỪ SP VÀ BẮN PHÉP
					current_sp -= SP_COST_PER_SPELL
					print("Hero '%s' dùng phép, SP còn lại: %d/%d" % [hero_name, current_sp, max_sp]) # Dòng này để debug
					sp_changed.emit(current_sp, max_sp)
					_update_sp_display()
					_shoot_projectile(magic_ball)
				else:
					# BƯỚC 3: NẾU KHÔNG ĐỦ, CHUYỂN SANG ĐÁNH THƯỜNG
					print("Hero '%s' hết SP, buộc phải đánh thường!" % hero_name)
					has_dealt_damage_this_attack = false
					animated_sprite.play("Attack")
			"BOW":
				# Nếu là Cung, bắn ra arrow với sát thương vật lý (atk)
				_shoot_projectile(arrow)
			_: # Các trường hợp còn lại (SWORD, DAGGER, v.v.)
				# Nếu là vũ khí cận chiến, thực hiện đòn đánh thường
				has_dealt_damage_this_attack = false
				animated_sprite.play("Attack")

func _on_animated_sprite_frame_changed():
	if animated_sprite.animation == "Attack" and animated_sprite.frame == attack_hit_frame and not has_dealt_damage_this_attack:
		_check_attack_area_collision()
		has_dealt_damage_this_attack = true

func _check_attack_area_collision():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = attack_area_shape.shape
	query.transform = attack_area.global_transform
	query.collision_mask = attack_area.collision_mask
	var result = space_state.intersect_shape(query)

	for item in result:
		var body = item.get("collider")
		if body and body.is_in_group("monsters") and not body.is_dead:
			# Gọi đến hàm tấn công trung tâm, "false" vì đây là đòn vật lý
			execute_attack_on(body, false)
			
			# Chỉ tấn công một mục tiêu mỗi lần vung vũ khí
			return

func take_damage(amount: float, _from_monster = null):
	if is_dead: return
	current_hp -= amount
	hp_bar.value = current_hp
	_update_hp_display()

	if current_hp <= 0 and not is_dead:
		die()
	
# ============================================================================
# HỆ THỐNG "LINH HỒN" & HỒI SINH
# ============================================================================
func die():
	if is_dead:
		return
	is_dead = true
	target_monster = null
	velocity = Vector2.ZERO
	animated_sprite.play("Death")
	collision_shape.set_deferred("disabled", true)
	
	attack_timer.stop()
	state_timer.stop()
	death_timer = 3.0

func _on_respawn_timer_timeout():
	print("\n--- PHÉP HỒI SINH: Hero '%s' đã trở lại! ---" % hero_name)
	is_dead = false
	add_to_group(&"heroes")
	visible = true
	current_hp = 1
	current_sp = 1
	hp_bar.value = current_hp
	_update_hp_display()
	if is_instance_valid(PlayerStats.ghost_respawn_point):
		global_position = PlayerStats.ghost_respawn_point.global_position
	else:
		global_position = PlayerStats.hero_spawn_point.global_position
	modulate = Color(1, 1, 1, 1)
	collision_shape.disabled = false
	detection_area.monitoring = true
	if is_instance_valid(PlayerStats.village_boundary):
		movement_area = PlayerStats.village_boundary
	doi_trang_thai(State.IDLE)
	GameEvents.respawn_finished.emit(self) # Thông báo cho UI biết là đã xong
# ============================================================================
# HỆ THỐNG DI CHUYỂN & DẪN ĐƯỜNG
# ============================================================================
func di_den_khu_vuc(target_area: Area2D):
	if not is_instance_valid(target_area) or (movement_area == target_area and _current_state != State.GHOST):
		return
	_current_route = tim_duong_di(movement_area, target_area)
	if _current_route.is_empty() and movement_area != target_area:
		push_error("LOI ROUTE: Khong tim thay duong di tu %s den %s" % [movement_area.name, target_area.name])
		return
	bat_dau_buoc_di_chuyen_tiep()

func bat_dau_buoc_di_chuyen_tiep():
	if _current_route.is_empty():
		doi_trang_thai(State.IDLE)
		return
	var next_connection: GateConnection = _current_route[0]
	var gate_node_instance = world_node.get_node_or_null(next_connection.gate_node)
	if is_instance_valid(gate_node_instance):
		_current_navigation_gate = gate_node_instance
		nav_agent.target_position = _current_navigation_gate.global_position
		if _current_state != State.GHOST: doi_trang_thai(State.NAVIGATING)
	else:
		_current_route.clear()
		doi_trang_thai(State.IDLE)

func _khi_den_cong():
	# THÊM BƯỚC KIỂM TRA AN TOÀN NÀY
	if _current_route.is_empty():
		push_warning("Lỗi logic: _khi_den_cong được gọi nhưng _current_route đã rỗng!")
		doi_trang_thai(State.IDLE) # Chuyển về trạng thái an toàn để tránh kẹt
		return

	var connection: GateConnection = _current_route.pop_front()
	var area_to_node = world_node.get_node_or_null(connection.area_to)
	if is_instance_valid(area_to_node):
		movement_area = area_to_node
		cap_nhat_ranh_gioi_di_chuyen()
		if not _current_route.is_empty():
			bat_dau_buoc_di_chuyen_tiep()
		else:
			# Nếu đã đến đích cuối cùng, chuyển sang WANDER thay vì IDLE
			doi_trang_thai(State.WANDER)
	else:
		_current_route.clear()
		doi_trang_thai(State.WANDER)

func _on_navigation_finished():
	if _current_state == State.RESTING or _current_state == State.TRADING:
		return
	if _current_state == State.GHOST:
		print("-> Linh hồn đã về đến làng. Bắt đầu 60 giây hồi sinh.")
		visible = false
		respawn_timer.start(60.0)
		GameEvents.respawn_started.emit(self) # Thông báo cho UI biết
		return
	if _current_state == State.NAVIGATING and is_instance_valid(_current_navigation_gate):
		print(">>> Hero đã đến cổng, kích hoạt chuyển vùng!")
		_khi_den_cong()
		return
		
	doi_trang_thai(State.IDLE)
	

func tim_duong_di(start_area: Area2D, end_area: Area2D) -> Array:
	var queue = [[start_area, []]]
	var visited = {start_area: true}
	while not queue.is_empty():
		var current_data = queue.pop_front()
		var current_area: Area2D = current_data[0]
		var current_path: Array = current_data[1]
		if current_area == end_area:
			return current_path
		for connection in gate_connections:
			var area_from_node = world_node.get_node_or_null(connection.area_from)
			var area_to_node = world_node.get_node_or_null(connection.area_to)
			if area_from_node == current_area and is_instance_valid(area_to_node) and not visited.has(area_to_node):
				visited[area_to_node] = true
				var new_path = current_path.duplicate()
				new_path.append(connection)
				queue.push_back([area_to_node, new_path])
	return []
	
# ============================================================================
# CÁC HÀM HỖ TRỢ
# ============================================================================
func _initialize_stats():
	var du_lieu_nghe = GameDataManager.get_hero_definition(job_key)
	if du_lieu_nghe.is_empty():
		push_error("Không tìm thấy dữ liệu nghề cho: " + job_key)
		return

	# Chỉ số ban đầu = Chỉ số Gacha + Chỉ số gốc của nghề
	STR = str_co_ban + du_lieu_nghe.get("str", 0)
	agi = agi_co_ban + du_lieu_nghe.get("agi", 0)
	vit = vit_co_ban + du_lieu_nghe.get("vit", 0)
	intel = int_co_ban + du_lieu_nghe.get("int", 0)
	dex = dex_co_ban + du_lieu_nghe.get("dex", 0)
	luk = luk_co_ban + du_lieu_nghe.get("luk", 0)

	# Cập nhật các chỉ số phụ lần đầu tiên
	_update_secondary_stats()

func _update_secondary_stats():
	var du_lieu_nghe = GameDataManager.get_hero_definition(job_key)
	if du_lieu_nghe.is_empty():
		return
	
	# --- PHẦN 1: RESET TẤT CẢ CÁC BIẾN BONUS VỀ 0 ---
	bonus_str = 0.0; bonus_agi = 0.0; bonus_vit = 0.0
	bonus_intel = 0.0; bonus_dex = 0.0; bonus_luk = 0.0
	bonus_atk = 0.0; bonus_matk = 0.0
	bonus_max_hp = 0.0; bonus_max_sp = 0.0
	bonus_def = 0.0; bonus_mdef = 0.0
	bonus_hit = 0.0; bonus_flee = 0.0
	bonus_crit_rate = 0.0; bonus_crit_dame = 0.0
	
	# Reset các bonus mới cho tốc độ và tầm đánh
	var bonus_attack_speed_mod: float = 0.0
	var bonus_attack_range: float = 0.0
	
	# Reset các biến bonus ẩn
	bonus_hit_hidden = 0.0
	bonus_crit_rate_hidden = 0.0
	
	# --- PHẦN 2: LẶP QUA TRANG BỊ ĐỂ TÍNH TỔNG BONUS ---
	for slot_key in equipment:
		var equipped_item = equipment.get(slot_key)
		if not equipped_item: continue

		var item_id = ""
		if equipped_item is Dictionary:
			item_id = equipped_item.get("id", "")
		elif equipped_item is String:
			item_id = equipped_item
		
		if item_id.is_empty(): continue
		
		var item_data = ItemDatabase.get_item_data(item_id)
		if item_data.is_empty() or item_data.get("item_type") != "EQUIPMENT":
			continue

		# **LOGIC MỚI: KIỂM TRA LOẠI VŨ KHÍ VÀ CỘNG CHỈ SỐ ẨN**
		if slot_key == "MAIN_HAND":
			var weapon_type = item_data.get("weapon_type", "")
			match weapon_type:
				"STAFF":
					bonus_hit_hidden = 10
					bonus_crit_rate_hidden = 0
				"SWORD":
					bonus_hit_hidden = 5
					bonus_crit_rate_hidden = 5
				"DAGGER":
					bonus_hit_hidden = -5
					bonus_crit_rate_hidden = 15
				"BOW":
					bonus_hit_hidden = -10
					bonus_crit_rate_hidden = 10
		
		var item_stats = item_data.get("stats", {})
		if item_stats.is_empty(): continue
		
		# Cộng dồn các chỉ số bonus tường minh (hiển thị trong tooltip)
		bonus_str += item_stats.get("str", 0.0)
		bonus_agi += item_stats.get("agi", 0.0)
		bonus_vit += item_stats.get("vit", 0.0)
		bonus_intel += item_stats.get("int", 0.0)
		bonus_dex += item_stats.get("dex", 0.0)
		bonus_luk += item_stats.get("luk", 0.0)
		bonus_atk += item_stats.get("atk", 0.0)
		bonus_matk += item_stats.get("matk", 0.0)
		bonus_max_hp += item_stats.get("max_hp", 0.0)
		bonus_max_sp += item_stats.get("max_sp", 0.0)
		bonus_def += item_stats.get("def", 0.0)
		bonus_mdef += item_stats.get("mdef", 0.0)
		bonus_hit += item_stats.get("hit", 0.0)
		bonus_flee += item_stats.get("flee", 0.0)
		bonus_crit_rate += item_stats.get("crit_rate", 0.0)
		bonus_crit_dame += item_stats.get("crit_dame", 0.0)
		bonus_attack_speed_mod += item_stats.get("attack_speed_mod", 0.0)
		bonus_attack_range += item_stats.get("attack_range_bonus", 0.0)

	# --- PHẦN 3: TÍNH TOÁN CHỈ SỐ CUỐI CÙNG ---
	var final_str = STR + bonus_str
	var final_agi = agi + bonus_agi
	var final_vit = vit + bonus_vit
	var final_intel = intel + bonus_intel
	var final_dex = dex + bonus_dex
	var final_luk = luk + bonus_luk

	# --- PHẦN 4: DÙNG CHỈ SỐ CUỐI CÙNG ĐỂ TÍNH TOÁN CÁC CHỈ SỐ PHỤ ---
	max_hp = (level * 10) + (final_vit * 5) + bonus_max_hp
	max_sp = (level * 5) + (final_intel * 3) + bonus_max_sp
	atk = final_str + (final_dex / 4.0) + (final_luk / 5.0) + bonus_atk
	matk = final_intel + (final_intel / 2.0) + (final_dex / 5.0) + bonus_matk
	def = final_vit + (final_agi / 5.0) + bonus_def
	mdef = final_intel + (final_vit / 5.0) + bonus_mdef
	
	# **CÔNG THỨC TÍNH TOÁN CUỐI CÙNG ĐÃ CẬP NHẬT**
	var base_attack_speed = 2.0 - (final_agi + final_dex) * 0.005
	attack_speed_calculated = clamp(base_attack_speed - bonus_attack_speed_mod, 0.2, 5.0)
	hit = float(level + final_dex) + bonus_hit + bonus_hit_hidden
	flee = float(level + final_agi + (final_luk / 5.0)) + bonus_flee
	crit_rate = (final_luk / 3.0) + bonus_crit_rate + bonus_crit_rate_hidden
	crit_damage = 1.5 + bonus_crit_dame
	
	# **Cập nhật tầm đánh và AttackTimer**
	attack_range_calculated = ATTACK_RANGE + bonus_attack_range
	if is_node_ready():
		attack_timer.wait_time = attack_speed_calculated
		if is_instance_valid(attack_range_area) and attack_range_area.get_node_or_null("CollisionShape2D"):
			attack_range_area.get_node("CollisionShape2D").shape.radius = attack_range_calculated
	
	# Cập nhật thanh HP (phần này có thể chạy an toàn vì hp_bar cũng là @onready)
	if is_node_ready():
		hp_bar.max_value = max_hp
		current_hp = min(current_hp, max_hp)
		_update_hp_display()
	
	heal_rate = 0.5 + (final_vit * 0.05) + (level * 0.02)
	sp_rate = 0.5 + (final_intel * 0.08) + (level * 0.02)

func _on_detection_radius_body_entered(body):
	# Nếu đang chiến đấu hoặc đã chết, không tìm mục tiêu mới
	if _current_state == State.COMBAT or is_dead:
		return

	# Chỉ phản ứng khi có một con quái vật MỚI đi vào vùng
	if body.is_in_group("monsters") and not body.is_dead:
		print(">>> Phát hiện có quái vật trong tầm. Bắt đầu quét mục tiêu gần nhất...")
		# Bắt đầu quét
		find_new_target_in_radius()

func _on_detection_radius_body_exited(body):
	if body == target_monster:
		target_monster = null
		if not is_dead: doi_trang_thai(State.IDLE)
			
func _update_attack_area_position():
	var offset_x = 10.0
	if animated_sprite.flip_h:
		attack_area.position.x = -offset_x
		attack_area.scale.x = -1
	else:
		attack_area.position.x = offset_x
		attack_area.scale.x =1

func cap_nhat_ranh_gioi_di_chuyen() -> bool:
	if not is_instance_valid(movement_area): _boundary_shape = null; return false
	var shape_node = movement_area.find_child("CollisionShape2D", false)
	if is_instance_valid(shape_node) and is_instance_valid(shape_node.shape):
		_boundary_shape = shape_node.shape
		_boundary_transform = shape_node.global_transform
		return true
	else:
		_boundary_shape = null
		return false

func chon_diem_den_ngau_nhien() -> void:
	if _boundary_shape == null: return
	var rect = _boundary_shape.get_rect()
	var random_point_local = Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	var random_point_global = _boundary_transform * random_point_local
	var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, random_point_global)
	nav_agent.target_position = valid_nav_point
	
	
func _on_animation_finished():
	if animated_sprite.animation == "Attack":
		has_dealt_damage_this_attack = false
		animated_sprite.play("Idle")
	elif animated_sprite.animation == "Death":
		doi_trang_thai(State.GHOST)
		remove_from_group("heroes")
		
		detection_area.monitoring = false
		modulate = Color(1,1,1,0.5)
		animated_sprite.play("Walk")
		
		if is_instance_valid(PlayerStats.ghost_respawn_point):
			nav_agent.target_position = PlayerStats.ghost_respawn_point.global_position
		else:
			push_error("Không thấy điểm hồi sinh")
			if is_instance_valid(PlayerStats.village_boundary):
				nav_agent.target_position = PlayerStats.village_boundary.global_position
		
func is_target_in_attack_area() -> bool:
	# Lấy danh sách tất cả các đối tượng đang va chạm với vùng AttackArea
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	# Kiểm tra xem mục tiêu của chúng ta (target_monster) có nằm trong danh sách đó không
	if is_instance_valid(target_monster) and overlapping_bodies.has(target_monster):
		return true
	return false

func find_new_target_in_radius():
	var bodies = detection_area.get_overlapping_bodies()
	var closest_monster = null
	var min_distance = INF # Vô cực

	for body in bodies:
		if body.is_in_group("monsters") and not body.is_dead:
			var distance = global_position.distance_to(body.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_monster = body

	# Nếu tìm thấy mục tiêu mới, chuyển sang tấn công ngay
	if is_instance_valid(closest_monster):
		print(">>> Truy sát liên tục! Mục tiêu mới: ", closest_monster.name)
		target_monster = closest_monster
		doi_trang_thai(State.COMBAT)
	# Nếu không, quay về trạng thái bình thường
	else:
		doi_trang_thai(State.IDLE)
		
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

func gain_exp(amount: int):
if level >= 100:
return
	if is_dead or (job_key == "Novice" and level >= MAX_LEVEL_NOVICE):
		return

	current_exp += amount
	exp_changed.emit(current_exp, exp_to_next_level)
	print(">>> '%s' nhận được %d EXP. (Tổng: %d / %d)" % [hero_name, amount, current_exp, exp_to_next_level])

	# HIỂN THỊ SỐ EXP BAY LÊN
	var text_position = global_position - Vector2(0, 150) # Vị trí hơi cao hơn số sát thương
	FloatingTextManager.show_text("+" + str(amount) + " EXP", Color.YELLOW, text_position)

	# Kiểm tra điều kiện lên cấp
	if current_exp >= exp_to_next_level:
		level_up()

func level_up():
	level += 1
	current_exp -= exp_to_next_level
	exp_to_next_level = int(100 * pow(level, 3.35))

	print("!!!!!!!!!! LEVEL UP !!!!!!!!!!")
	print(">>> '%s' đã đạt đến cấp độ %d!" % [hero_name, level])
	
	# ===================================================
	# === TĂNG CHỈ SỐ KHI LÊN CẤP ===
	STR += str_tang_truong
	agi += agi_tang_truong
	vit += vit_tang_truong
	intel += int_tang_truong
	dex += dex_tang_truong
	luk += luk_tang_truong
	
	# In ra để kiểm tra
	print("   -> STR: %.2f, AGI: %.2f, VIT: %.2f" % [STR, agi, vit])

	# Cập nhật lại các chỉ số phụ (HP, ATK, DEF...)
	_update_secondary_stats()
	# ===================================================
	
	# Hồi đầy máu và năng lượng
	current_hp = max_hp
	current_sp = max_sp
	sp_changed.emit(current_sp, max_sp)
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	_update_hp_display()
	exp_changed.emit(current_exp, exp_to_next_level)
	stats_updated.emit()
	# Kiểm tra xem có đủ exp để lên cấp nữa không
	if current_exp >= exp_to_next_level:
		level_up()

func equip_from_inventory(inventory_slot_index: int):
	print("\n--- DEBUG EQUIP: Nhan lenh trang bi tu o so %d ---" % inventory_slot_index)
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.size():
		return
	var item_package_to_equip = inventory[inventory_slot_index]
	if not item_package_to_equip:
		print("DEBUG EQUIP: Loi - O trong tui do bi trong.")
		return

	var item_id_to_equip = item_package_to_equip.get("id")
	var item_data = ItemDatabase.get_item_data(item_id_to_equip)
	var item_type = item_data.get("item_type")
	print("DEBUG EQUIP: Dang trang bi item '%s', loai '%s'" % [item_id_to_equip, item_type])

	# TRƯỜNG HỢP 1: NẾU LÀ TRANG BỊ (VŨ KHÍ, GIÁP...)
	if item_type == "EQUIPMENT":
		var slot_key = item_data.get("equip_slot")
		if not equipment.has(slot_key):
			print("DEBUG EQUIP: Loi - Hero khong co o trang bi loai '%s'." % slot_key)
			return

		# Logic hoán đổi trang bị cũ
		var old_equipped_item_id = equipment.get(slot_key)
		equipment[slot_key] = item_id_to_equip # Trang bị ID của item mới

		if old_equipped_item_id:
			inventory[inventory_slot_index] = {"id": old_equipped_item_id, "quantity": 1}
			print("DEBUG EQUIP: Da thao do cu '%s' va tra ve tui do." % old_equipped_item_id)
		else:
			inventory[inventory_slot_index] = null
			print("DEBUG EQUIP: O trang bi trong, da xoa item khoi tui do.")
	
	elif item_type == "CONSUMABLE":
		var quantity_to_add = item_package_to_equip.get("quantity", 1)
		# BƯỚC A: ƯU TIÊN TÌM VÀ GỘP VÀO STACK CÓ SẴN
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			var existing_package = equipment.get(slot_key)
			# Kiểm tra xem ô có Potion không và có cùng ID không
			if existing_package != null and existing_package.get("id") == item_id_to_equip:
				print("Da tim thay Potion cung loai, bat dau gop.")
				# Cộng dồn số lượng
				existing_package["quantity"] += quantity_to_add
				# Xóa item khỏi túi đồ
				inventory[inventory_slot_index] = null
								
				# Phát tín hiệu cập nhật và kết thúc hàm
				_update_secondary_stats()
				stats_updated.emit()
				equipment_changed.emit(equipment)
				inventory_changed.emit()
				return # << Kết thúc sớm khi đã gộp xong

		# BƯỚC B: NẾU KHÔNG GỘP ĐƯỢC, TÌM Ô TRỐNG ĐỂ THÊM MỚI
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			if equipment.get(slot_key) == null:
				print("Khong tim thay stack co san, chuyen vao o trong.")
				# Di chuyển cả gói item vào ô trang bị trống
				equipment[slot_key] = item_package_to_equip
				inventory[inventory_slot_index] = null
				
				# Phát tín hiệu cập nhật và kết thúc hàm
				_update_secondary_stats()
				stats_updated.emit()
				equipment_changed.emit(equipment)
				inventory_changed.emit()
				return # << Kết thúc sớm khi đã thêm vào ô trống

		# BƯỚC C: NẾU CHẠY HẾT CẢ 2 VÒNG LẶP MÀ KHÔNG LÀM GÌ ĐƯỢC
		print("Tat ca cac o Potion da day!")
		return

	else:
		print("Vật phẩm '%s' không thể trang bị." % item_data.get("item_name"))
		return

	# Phát tín hiệu cập nhật chung (chỉ dành cho trang bị EQUIPMENT)
	_update_secondary_stats()
	stats_updated.emit()
	equipment_changed.emit(equipment)
	inventory_changed.emit()

func unequip_item(slot_key: String):
	var item_to_unequip = equipment.get(slot_key)
	if not item_to_unequip:
		return

	var success = false
	# TRƯỜNG HỢP 1: NẾU LÀ POTION (dữ liệu là Dictionary)
	if item_to_unequip is Dictionary:
		# Trả cả chồng Potion về lại túi đồ
		success = add_item(item_to_unequip["id"], item_to_unequip["quantity"])
	# TRƯỜNG HỢP 2: NẾU LÀ TRANG BỊ THƯỜNG (dữ liệu là String ID)
	elif item_to_unequip is String:
		success = add_item(item_to_unequip, 1)

	# Nếu trả về túi thành công, dọn dẹp ô trang bị
	if success:
		equipment[slot_key] = null
		_update_secondary_stats()
		stats_updated.emit()
		equipment_changed.emit(equipment)
		inventory_changed.emit()
	else:
		print("Không thể tháo trang bị, túi đồ đã đầy!")
		
func _update_hp_display():
	hp_bar.value = current_hp 
	if not is_instance_valid(hp_label): return
	# Làm tròn số HP để hiển thị cho đẹp
	var hp_hien_tai = roundi(current_hp)
	var hp_toi_da = roundi(max_hp)
	# Cập nhật text của Label
	hp_label.text = "%d/%d" % [hp_hien_tai, hp_toi_da]
	
func _update_sp_display():
	# Giả sử bạn có một ProgressBar tên là SPBar và một Label tên là SPLabel
	# Nếu chưa có, hãy tạo chúng trong Editor, tương tự như HPBar
	# @onready var sp_bar: ProgressBar = $VBoxContainer/SPBar
	# @onready var sp_label: Label = $VBoxContainer/SPBar/SPLabel
	
	# sp_bar.max_value = max_sp
	# sp_bar.value = current_sp
	# sp_label.text = "%d/%d" % [roundi(current_sp), roundi(max_sp)]
	pass # Tạm thời bỏ qua nếu bạn chưa tạo UI cho SP

func add_item(item_id: String, quantity_to_add: int = 1) -> bool:
	var item_data = ItemDatabase.get_item_data(item_id)
	if item_data.is_empty():
		push_error("add_item: Không tìm thấy dữ liệu cho item ID '%s'" % item_id)
		return false

	var is_stackable = item_data.get("is_stackable", false)
	var max_stack = item_data.get("max_stack_size", 1)
	var quantity_left = quantity_to_add
	var item_added = false

	# BƯỚC 1: NẾU VẬT PHẨM CÓ THỂ XẾP CHỒNG
	if is_stackable:
		# Vòng lặp 1: Tìm các chồng (stack) có sẵn và lấp đầy chúng
		for i in range(inventory.size()):
			var slot = inventory[i]
			# Nếu ô có đồ, cùng ID, và chưa đầy
			if slot and slot["id"] == item_id and slot["quantity"] < max_stack:
				var can_add_here = max_stack - slot["quantity"]
				var add_amount = min(quantity_left, can_add_here)

				slot["quantity"] += add_amount
				quantity_left -= add_amount
				item_added = true

				# Nếu đã thêm đủ, thoát sớm
				if quantity_left <= 0:
					inventory_changed.emit()
					return true

		# Vòng lặp 2: Nếu vẫn còn item, tìm ô trống để tạo chồng mới
		while quantity_left > 0:
			var found_empty_slot = false
			for i in range(inventory.size()):
				if inventory[i] == null: # Tìm ô trống
					var add_amount = min(quantity_left, max_stack)
					inventory[i] = {"id": item_id, "quantity": add_amount}
					quantity_left -= add_amount
					item_added = true
					found_empty_slot = true
					break # Thoát vòng lặp tìm ô trống, tiếp tục vòng lặp while

			# Nếu không còn ô trống nào, dừng lại
			if not found_empty_slot:
				break


	# BƯỚC 2: NẾU VẬT PHẨM KHÔNG THỂ XẾP CHỒNG
	else:
		for _i in range(quantity_to_add):
			var found_empty_slot = false
			for j in range(inventory.size()):
				if inventory[j] == null:
					inventory[j] = {"id": item_id, "quantity": 1}
					quantity_left -= 1
					item_added = true
					found_empty_slot = true
					break # Đã tìm được chỗ cho item này, chuyển sang item tiếp theo

			# Nếu không tìm được ô trống cho 1 item, dừng lại
			if not found_empty_slot:
				break

	# BƯỚC 3: KIỂM TRA KẾT QUẢ VÀ CẬP NHẬT UI
	if item_added:
		inventory_changed.emit() # Chỉ phát tín hiệu nếu có thay đổi

	if quantity_left > 0:
		var item_name = item_data.get("item_name", item_id)
		push_warning("Túi đồ của '%s' đã đầy! Không thể thêm %d '%s'." % [hero_name, quantity_left, item_name])
		return false # Báo hiệu thêm không hoàn tất

	return true # Báo hiệu thêm thành công
	
func add_gold(amount: int):
	if amount <= 0: return
	gold += amount
	gold_changed.emit(gold)
	print("Hero '%s' nhặt được %d vàng. Tổng: %d" % [hero_name, amount, gold])

func _xu_ly_tu_dong_dung_potion():
	# Điều kiện cơ bản: phải còn sống
	if is_dead:
		return
		
	# --- DEBUG: In ra HP hiện tại để kiểm tra ---
	var hp_percent = current_hp / max_hp
	# print("DEBUG Hero: HP hien tai = %.2f %%" % (hp_percent * 100)) # Mở dòng này nếu bạn muốn xem HP liên tục

	# 1. Điều kiện máu: dưới 50% (thay vì 20% để dễ test)
	if hp_percent > 0.5:
		# print("DEBUG Hero: HP > 50%, bo qua.") # Mở dòng này nếu cần
		return
		
	# 2. Nếu không có tham chiếu đến UI, không thể tìm Potion
	if not is_instance_valid(_ui_controller):
		return

	# 3. Nhờ UI tìm giúp một ô Potion sẵn sàng
	var san_sang_slot_key = _ui_controller.tim_potion_slot_san_sang()
	
	# 4. Nếu tìm thấy (kết quả không phải là chuỗi rỗng)
	if san_sang_slot_key != "":
		# Uống Potion từ ô đó
		dung_potion(san_sang_slot_key)


# Hàm thực thi việc dùng Potion
func dung_potion(slot_key: String):
	var item_package = equipment.get(slot_key)
	if item_package == null or not item_package is Dictionary:
		return
		
	var item_id = item_package.get("id")
	var item_data = ItemDatabase.get_item_data(item_id)
	
	if item_data.is_empty():
		return
	
	# === DÒNG SỬA LỖI QUAN TRỌNG ===
	# Sửa "effects" thành "stats" để khớp với dữ liệu Potion của bạn
	var stats_data = item_data.get("stats", {})
	var heal_amount = stats_data.get("heal_amount", 0)
	# ==============================
	
	if heal_amount <= 0:
		return
		
	current_hp = min(current_hp + heal_amount, max_hp)
	_update_hp_display()
	
	var text_position = global_position - Vector2(0, 100)
	FloatingTextManager.show_text("+" + str(heal_amount), Color.GREEN, text_position)
	
	item_package["quantity"] -= 1
	
	if item_package["quantity"] <= 0:
		equipment[slot_key] = null
	
	var cooldown = item_data.get("cooldown", 5.0)
	if is_instance_valid(_ui_controller):
		_ui_controller.bat_dau_cooldown_potion(slot_key, cooldown)
	
	equipment_changed.emit(equipment)

# ===============================================
# === HỆ THỐNG LƯU TRỮ DỮ LIỆU (SAVE/LOAD) ===
# ===============================================

# Hàm này "đóng gói" toàn bộ thông tin quan trọng của Hero thành một Dictionary
func save_data() -> Dictionary:
	var area_name = ""
	if is_instance_valid(movement_area):
		area_name = movement_area.name

	# --- BƯỚC 1: TẠO CÁC BIẾN TẠM AN TOÀN ---
	var nav_target_x = global_position.x
	var nav_target_y = global_position.y

	# --- BƯỚC 2: KIỂM TRA XEM NAV_AGENT CÓ TỒN TẠI KHÔNG ---
	# Chỉ lấy vị trí của nav_agent NẾU nó đã được khởi tạo
	if is_instance_valid(nav_agent):
		nav_target_x = nav_agent.target_position.x
		nav_target_y = nav_agent.target_position.y

	var data = {
		# --- Các phần khác giữ nguyên ---
		"name": name, "hero_name": hero_name, "job_key": job_key, "level": level,
		"current_exp": current_exp, "is_dead": is_dead,
		"str_co_ban": str_co_ban, "agi_co_ban": agi_co_ban, "vit_co_ban": vit_co_ban,
		"int_co_ban": int_co_ban, "dex_co_ban": dex_co_ban, "luk_co_ban": luk_co_ban,
		"str_tang_truong": str_tang_truong, "agi_tang_truong": agi_tang_truong,
		"vit_tang_truong": vit_tang_truong, "int_tang_truong": int_tang_truong,
		"dex_tang_truong": dex_tang_truong, "luk_tang_truong": luk_tang_truong,
		"pos_x": global_position.x, "pos_y": global_position.y,
		"current_hp": current_hp, "current_sp": current_sp,
		"current_area_name": area_name,
		"inventory": inventory, "equipment": equipment, "gold": gold,
		"_current_state": _current_state,
		
		# --- BƯỚC 3: SỬ DỤNG CÁC BIẾN TẠM AN TOÀN ---
		"nav_target_pos_x": nav_target_x,
		"nav_target_pos_y": nav_target_y
	}
	return data
# Hàm này nhận một Dictionary và khôi phục lại trạng thái của Hero
func load_data(data: Dictionary):
	if is_instance_valid(state_timer):
		state_timer.stop()
	if is_instance_valid(attack_timer):
		attack_timer.stop()
	
	# --- Khôi phục thông tin cơ bản ---
	name = data.get("name", "Hero Bi Loi")
	hero_name = data.get("hero_name", "Tan Binh")
	job_key = data.get("job_key", "Novice")
	level = data.get("level", 1)
	current_exp = data.get("current_exp", 0)
	
	# --- Khôi phục chỉ số gốc (từ Gacha) ---
	str_co_ban = data.get("str_co_ban", 1.0)
	agi_co_ban = data.get("agi_co_ban", 1.0)
	vit_co_ban = data.get("vit_co_ban", 1.0)
	int_co_ban = data.get("int_co_ban", 1.0)
	dex_co_ban = data.get("dex_co_ban", 1.0)
	luk_co_ban = data.get("luk_co_ban", 1.0)
	
	# --- Khôi phục chỉ số tăng trưởng ---
	str_tang_truong = data.get("str_tang_truong", 0.1)
	agi_tang_truong = data.get("agi_tang_truong", 0.1)
	vit_tang_truong = data.get("vit_tang_truong", 0.1)
	int_tang_truong = data.get("int_tang_truong", 0.1)
	dex_tang_truong = data.get("dex_tang_truong", 0.1)
	luk_tang_truong = data.get("luk_tang_truong", 0.1)
	
	# --- Kho đồ & Vàng ---
	# Đối với Array và Dictionary, chúng ta cần sao chép sâu (deep copy)
	# để tránh các lỗi không mong muốn về tham chiếu
	inventory = data.get("inventory", []).duplicate(true)
	equipment = data.get("equipment", {}).duplicate(true)
	gold = data.get("gold", 0)
	
	# --- Tính toán lại toàn bộ chỉ số dựa trên dữ liệu đã nạp ---
	_initialize_stats() # Hàm này tính STR, AGI... từ chỉ số gốc và nghề
	_update_secondary_stats() # Hàm này tính HP, ATK... từ STR, AGI và trang bị
	
	# --- Khôi phục trạng thái cuối cùng ---
	# Dùng set_deferred để đảm bảo thay đổi vị trí không bị lỗi vật lý
	global_position.x = data.get("pos_x", global_position.x)
	global_position.y = data.get("pos_y", global_position.y)
	current_hp = min(data.get("current_hp", max_hp), max_hp)
	current_sp = min(data.get("current_sp", max_sp), max_sp)
	is_dead = data.get("is_dead", false)
	
	var loaded_state = data.get("_current_state", State.IDLE)
	var target_pos = Vector2(
		data.get("nav_target_pos_x", global_position.x),
		data.get("nav_target_pos_y", global_position.y)
	)
	
	# Nếu hero là "linh hồn" khi được lưu...
	if loaded_state in [State.NAVIGATING, State.WANDER, State.GHOST]:
		_current_state = loaded_state # Đặt trạng thái trực tiếp
		nav_agent.target_position = target_pos # Đặt lại đích đến
		# Nếu là ghost, đảm bảo các thuộc tính ghost được áp dụng
		if loaded_state == State.GHOST:
			collision_shape.set_deferred("disabled", true)
			detection_area.monitoring = false
			modulate = Color(1, 1, 1, 0.5)
			animated_sprite.play("Walk")
	else:
		# Nếu là các trạng thái khác, gọi hàm doi_trang_thai như bình thường
		doi_trang_thai(loaded_state)
		
		_update_hp_display()
		_update_sp_display()
		
		inventory_changed.emit()
		gold_changed.emit()
		
		# Khôi phục khu vực di chuyển
	var area_name = data.get("current_area_name", "")
	if area_name != "":
		var area_node = world_node.find_child(area_name, true, false)
		if is_instance_valid(area_node):
			movement_area = area_node
			cap_nhat_ranh_gioi_di_chuyen()
	
func di_den_diem(target_position: Vector2):
	# Ra lệnh cho NavigationAgent tìm đường đến vị trí mục tiêu
	nav_agent.target_position = target_position
	# Chuyển sang trạng thái di chuyển
	doi_trang_thai(State.NAVIGATING)

func _on_inn_room_chosen(hero, inn_level):
	# Chỉ phản ứng nếu tín hiệu này dành cho chính mình
	if hero != self: return

	var level_data = GameDataManager.get_inn_level_data(inn_level)
	var cost = level_data["cost"]

	if gold < cost: return # Kiểm tra tiền lần cuối

	gold -= cost
	gold_changed.emit(gold)

	current_heal_rate = level_data["heal_percent"]
	is_resting = true
	doi_trang_thai(State.RESTING)
	hide()

# Hàm này sẽ được gọi bởi Inn khi hồi phục xong
func start_resting(inn_level: int):
	print("--- DEBUG HERO: Nhan lenh bat dau nghi ngoi ---")
	var level_data = GameDataManager.get_inn_level_data(inn_level)
	if level_data.is_empty(): return

	var cost = level_data["cost"]
	if gold < cost: return

	gold -= cost
	PlayerStats.add_gold_to_player(cost)
	gold_changed.emit(gold)

	current_heal_rate = level_data["heal_percent"]
	is_resting = true
	doi_trang_thai(State.RESTING)
	hide()

	print("--- DEBUG HERO: Da an di va chuan bi phat tin hieu cho Inn ---")
	started_resting.emit(self, current_heal_rate)

func finish_resting():
	print("--- DEBUG HERO: Nhan lenh ket thuc nghi ngoi ---")
	is_resting = false
	# Reset lại các giá trị hồi phục
	current_heal_rate = 0.0
	current_hp = max_hp
	current_sp = max_sp
	_update_hp_display()

	show()
	collision_shape.disabled = false
	# Đặt về IDLE sau khi đã hiện ra
	doi_trang_thai(State.IDLE)
	
	# THÊM DÒNG NÀY VÀO CUỐI HÀM
	# Báo cho các hệ thống khác (như Inn) biết là Hero này đã nghỉ ngơi xong
	finished_resting.emit(self)

func remove_item_from_inventory(item_id: String, quantity_to_remove: int) -> bool:
	var quantity_left = quantity_to_remove
	# Vòng lặp từ cuối lên để xóa không bị lỗi index
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if slot and slot["id"] == item_id:
			var remove_amount = min(quantity_left, slot["quantity"])
			slot["quantity"] -= remove_amount
			quantity_left -= remove_amount

			if slot["quantity"] <= 0:
				inventory[i] = null

			if quantity_left <= 0:
				inventory_changed.emit()
				return true # Đã xóa đủ

	inventory_changed.emit()
	# Trả về false nếu không xóa đủ số lượng yêu cầu
	return quantity_left <= 0
	
func _shoot_projectile(projectile_scene: PackedScene):
	if not is_instance_valid(target_monster) or not projectile_scene:
		return
		#Bước 1: tính toán tốc độ
	var projectile_speed = 1500.0/ attack_speed_calculated
	var new_projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
		#Bước 2: truyền tốc độ
	new_projectile.start(global_position, target_monster, self, projectile_speed)

func execute_attack_on(target_monster_node, p_su_dung_phep: bool):
	# Kiểm tra mục tiêu có hợp lệ không
	if not is_instance_valid(target_monster_node) or target_monster_node.is_dead:
		return

	# Đây là logic tính toán sát thương bạn đã có, giờ nó sẽ được dùng cho mọi loại tấn công
	var combat_result = CombatUtils.hero_tan_cong_quai(
		atk, matk, dex, crit_rate, hit, level, 
		target_monster_node.def_quai, target_monster_node.mdef_quai, 
		target_monster_node.giap_quai, target_monster_node.level, 
		p_su_dung_phep
	)

	# Lấy vị trí để hiển thị số bay lên (trên đầu quái)
	var text_position = target_monster_node.global_position - Vector2(0, 150)

	# Hiển thị "MISS" hoặc số sát thương
	if combat_result.is_miss:
		FloatingTextManager.show_text("MISS!!", Color.GRAY, text_position)
	else:
		var text_to_show = str(combat_result.damage)
		var color = Color.WHITE
		if combat_result.is_crit:
			color = Color.RED
			text_to_show += "!!"

		FloatingTextManager.show_text(text_to_show, color, text_position, combat_result.is_crit)

		# Nếu có sát thương, ra lệnh cho quái vật nhận sát thương
		if combat_result.damage > 0:
			target_monster_node.take_damage(combat_result.damage, self)
			

func change_job(new_job_key: String):
	# BƯỚC 1: KIỂM TRA (Giữ nguyên)
	var new_job_data = GameDataManager.get_hero_definition(new_job_key)
	if new_job_data.is_empty():
		push_error("LỖI CHUYỂN NGHỀ: Không tìm thấy dữ liệu cho nghề '%s'" % new_job_key)
		return

	print("--- HERO '%s' BẮT ĐẦU CHUYỂN NGHỀ ---" % hero_name)
	print("Nghề cũ: %s -> Nghề mới: %s" % [job_key, new_job_key])

	# BƯỚC 2: CẬP NHẬT job_key VÀ CHỈ SỐ TĂNG TRƯỞNG (Giữ nguyên)
	job_key = new_job_key
	str_tang_truong = new_job_data.get("str_growth", 0.0)
	agi_tang_truong = new_job_data.get("agi_growth", 0.0)
	vit_tang_truong = new_job_data.get("vit_growth", 0.0)
	int_tang_truong = new_job_data.get("int_growth", 0.0)
	dex_tang_truong = new_job_data.get("dex_growth", 0.0)
	luk_tang_truong = new_job_data.get("luk_growth", 0.0)
	
	# === PHẦN BỔ SUNG QUAN TRỌNG ===
	# BƯỚC 3: RESET LEVEL VÀ EXP
	level = 1
	current_exp = 0
	# Tính lại lượng EXP cần cho cấp tiếp theo (cấp 2)
	exp_to_next_level = int(100 * pow(level, 1.5)) 
	print("Đã reset Level về 1 và EXP về 0.")
	# ==============================
	
	# BƯỚC 4: TÍNH TOÁN LẠI TOÀN BỘ CHỈ SỐ (Giữ nguyên)
	# Hàm _initialize_stats sẽ tính lại chỉ số chính (STR, AGI...) dựa trên nghề mới
	# Nó sẽ lấy str_co_ban (chỉ số gốc lúc sinh ra) + chỉ số gốc của nghề mới.
	_initialize_stats()
	# Hàm _update_secondary_stats sẽ tính lại HP, ATK, DEF... từ chỉ số chính và trang bị
	_update_secondary_stats()
	
	# BƯỚC 5: HỒI ĐẦY MÁU/NĂNG LƯỢNG VÀ PHÁT TÍN HIỆU (Giữ nguyên)
	current_hp = max_hp
	current_sp = max_sp
	_update_hp_display()
	_update_sp_display()
	
	# Phát tín hiệu để cập nhật giao diện người dùng
	stats_updated.emit()
	exp_changed.emit(current_exp, exp_to_next_level) # Báo cho UI biết EXP đã thay đổi
	
	print("--- CHUYỂN NGHỀ THÀNH CÔNG! ---")

func _handle_passive_regeneration(delta: float):
	# Không hồi phục nếu đã chết, đang chiến đấu hoặc đang nghỉ ngơi trong nhà trọ
	if is_dead or _current_state == State.COMBAT or is_resting:
		return

	# Chỉ hồi phục nếu HP hoặc SP chưa đầy
	if current_hp < max_hp or current_sp < max_sp:
		# Hồi HP và SP dựa trên rate và thời gian delta
		current_hp += heal_rate * delta
		current_sp += sp_rate * delta

		# Đảm bảo không vượt quá giới hạn tối đa
		current_hp = min(current_hp, max_hp)
		current_sp = min(current_sp, max_sp)

		# Cập nhật giao diện
		_update_hp_display()
		_update_sp_display()
