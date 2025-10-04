#res://script/hero.gd
extends CharacterBody2D
class_name Hero

# ==== SIGNALS ====
signal exp_changed(current_exp, exp_to_next_level)
signal stats_updated
signal equipment_changed(new_equipment)
signal inventory_changed
signal gold_changed(new_gold_amount)
signal started_resting(hero, heal_rate)
signal finished_resting(hero)
signal sp_changed(current_sp, max_sp)
signal hp_changed(current_hp, max_hp)
signal free_points_changed
signal skill_tree_changed
signal skill_activated(skill_id, cooldown_duration)
signal potion_cooldown_started(slot_key, duration) 

var debug_print_timer: float = 0.0

const VFX_Scene = preload("res://Scene/VFX/vfx_player.tscn")

# ==== CONSTANTS & ENUM ====
const magic_ball = preload("res://Data/items/magic.tscn")
const MAX_SKILL_SLOTS = 4 # Giả sử có 4 ô skill
var equipped_skills: Array = []
var skill_points: int = 0
var learned_skills: Dictionary = {}


const SP_COST_PER_SPELL: int = 5
const MAX_LEVEL_NOVICE: int = 10
const ATTACK_RANGE: float = 200.0
const HEAL_PER_SECOND_IN_VILLAGE: float = 0.5
const SP_PER_SECOND_IN_VILLAGE: float = 0.5
const HERO_INVENTORY_SIZE: int = 20
const GATE_ARRIVAL_RADIUS: float = 30.0

enum State {
	IDLE,
	WANDER,
	NAVIGATING,
	COMBAT,
	GHOST,
	TRADING,
	RESTING,
	IN_BARRACKS,
	PLAYER_COMMAND,
	CHASE, # <--- BỔ SUNG DÒNG NÀY
	DEAD   # <--- BỔ SUNG DÒNG NÀY
}

var _potion_cooldowns: Dictionary = {
	"POTION_1": 0.0,
	"POTION_2": 0.0,
	"POTION_3": 0.0
}

# ==== EXPORTS, READY VARS ====
@export var stopping_distance: float = 50.0
@onready var skill_timer: Timer = $SkillTimer

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_timer: Timer = $StateTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var detection_area: Area2D = $DetectionRadius
@onready var attack_area: Area2D = $AttackArea
@onready var attack_range_area: Area2D = $AttackRangeArea
@onready var attack_range_shape: CollisionShape2D = $AttackRangeArea/CollisionShape2D
@onready var attack_area_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel

#=========HERO BODY============================
@onready var skeleton_2d: Skeleton2D = $Skeleton2D
@onready var face_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Head_Bone/Face_Sprite
@onready var armor_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/ArmorSprite
@onready var helmet_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Head_Bone/Head_Sprite
@onready var gloves_l_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_trai/Arm_L_Bone/Arm_L_Sprite
@onready var gloves_r_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_Phai/Arm_R_Bone/Arm_R_Sprite
@onready var boots_l_sprite: Sprite2D = $Skeleton2D/HipBone/Chan_trai/Leg_L_Bone/BootsLSprite
@onready var boots_r_sprite: Sprite2D = $Skeleton2D/HipBone/Chan_Phai/Leg_R_Bone/BootsRSprite
@onready var weapon_container: Node2D = $Skeleton2D/HipBone/Than_Minh/Tay_trai/Arm_L_Bone/Hand_L_Bone/WeaponContainer
@onready var offhand_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_Phai/Arm_R_Bone/Hand_R_Bone/Offhand

# ==== HERO DATA ====
var _current_state = State.IDLE
var staged_data: Dictionary = {} 
var _is_attacking: bool = false
var is_dead: bool = false
var is_ui_interacting: bool = false
var is_resting: bool = false
var current_heal_rate: float = 0.0
var free_points: int = 0
var heal_rate: float = 0.0
var sp_rate: float = 0.0
var _ui_controller: UIController
var _current_attack_animation_name: String = "Attack"
var _skill_cooldowns: Dictionary = {}

var base_appearance: Dictionary = {
	"face": "",
	"helmet": "",
	"armor_set": {}
}


# Chỉ số gốc & tăng trưởng
var str_co_ban: float = 1.0
var agi_co_ban: float = 1.0
var vit_co_ban: float = 1.0
var int_co_ban: float = 1.0
var dex_co_ban: float = 1.0
var luk_co_ban: float = 1.0
var str_tang_truong: float = 0.0
var agi_tang_truong: float = 0.0
var vit_tang_truong: float = 0.0
var int_tang_truong: float = 0.0
var dex_tang_truong: float = 0.0
var luk_tang_truong: float = 0.0

# Chỉ số tính toán
var STR: int = 1
var AGI: int = 1
var VIT: int = 1
var INTEL: int = 1 # Đổi thành INTEL để tránh trùng lặp
var DEX: int = 1
var LUK: int = 1
var max_hp: float = 0.0
var current_hp: float = 0.0
var max_sp: float = 0.0
var current_sp: float = 0.0
var atk: float = 0.0
var matk: float = 0.0
var def: float = 0.0
var mdef: float = 0.0
var attack_speed_calculated: float = 2.0
var attack_range_calculated: float = 150.0
var bonus_hit_hidden: float = 0.0
var bonus_crit_rate_hidden: float = 0.0

# Chỉ số tấn công chi tiết
var min_atk: float = 0
var max_atk: float = 0
var min_matk: float = 0
var max_matk: float = 0

# Tốc độ đánh chi tiết
var aspd: float = 156
var attack_time: float = 1.0 # Thời gian giữa mỗi đòn đánh

# Chỉ số phụ khác
var hit: float = 0
var flee: float = 0
var crit_rate: float = 0
var crit_damage: float = 1.5 # 150%
var perfect_dodge: float = 0
var crit_resist: float = 0
var cast_time_reduction: float = 0.0
var healing_item_bonus: float = 1.0


# ==== BONUS STATS (từ trang bị, skill,...) ====
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
var bonus_hit: float = 0.0
var bonus_flee: float = 0.0
var bonus_crit_rate: float = 0.0
var bonus_crit_dame: float = 0.0
var bonus_perfect_dodge: float = 0.0
var bonus_crit_resist: float = 0.0
var bonus_aspd_flat: float = 0.0
var attack_speed_mod: float = 0.0
var bonus_attack_range: float = 0.0 

# ==== DERIVED STATS (các chỉ số phụ được tính toán) ====
var hp_regen: float = 0.0
var sp_regen: float = 0.0

# Thông tin di chuyển
var level: int = 1
var hero_name: String = "Tan Binh"
var job_key: String = "Novice"
var speed: float = 150.0
var movement_area: Area2D
var gate_connections: Array = []
var world_node: Node2D
var _current_route: Array = []
var _current_navigation_gate: Node2D = null
var _boundary_shape: Shape2D = null
var _boundary_transform: Transform2D
var player_command_target: Vector2 = Vector2.ZERO


var target_monster = null
var gold: int = 0
var current_exp: int = 0
var exp_to_next_level: int = 100
var attack_hit_frame = 5
var has_dealt_damage_this_attack = false
var death_timer: float = 0.0

# Inventory & equipment
var inventory: Array = []
var equipment: Dictionary = {
	"MAIN_HAND": null, "OFF_HAND": null, "HELMET": null, "ARMOR": null, "PANTS": null,
	"GLOVES": null, "BOOTS": null, "AMULET": null, "RING": null,
	"POTION_1": null, "POTION_2": null, "POTION_3": null
}

# ============================================================================
# HÀM KHỞI TẠO CỦA GODOT
# ============================================================================
func _ready() -> void:
	# Kết nối các tín hiệu
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	state_timer.timeout.connect(_on_state_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	GameEvents.inn_room_chosen.connect(_on_inn_room_chosen)
	
	if not staged_data.is_empty():
		# Thì gọi hàm xử lý dữ liệu (bây giờ tất cả @onready var đã sẵn sàng)
		_apply_loaded_data(staged_data)
	# Nếu không (tức là hero này là hero mới toanh)
	else:
		# Thì chạy logic khởi tạo như bình thường
		name_label.text = hero_name
		_initialize_stats()
		current_hp = max_hp
		current_sp = max_sp
		doi_trang_thai(State.IDLE) # Bắt đầu ở trạng thái IDLE
	# ================================

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	skill_timer.timeout.connect(_on_skill_timer_timeout)

	_update_hp_display()
	_update_equipment_visuals()

	# Cập nhật animation cuối cùng sau khi đã có trạng thái
	if not _is_attacking:
		animation_player.play(&"Idle")

	equipped_skills.resize(MAX_SKILL_SLOTS)
	equipped_skills.fill(null)

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
func _physics_process(delta: float) -> void:
	# --- BƯỚC 1: XỬ LÝ CÁC TRẠNG THÁI ƯU TIÊN CAO ---
	if _current_state in [State.IN_BARRACKS, State.RESTING]:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if is_dead:
		_handle_ghost_physics(delta)
		return

	# --- BƯỚC 2: CÁC HÀNH ĐỘNG THỤ ĐỘNG ---
	_handle_passive_regeneration(delta)
	_check_and_use_potions()
	_update_potion_cooldowns(delta)
	_update_cooldowns(delta)
	# --- BƯỚC 3: TÍNH TOÁN VẬN TỐC DỰA TRÊN TRẠNG THÁI ---
	velocity = Vector2.ZERO
	
	match _current_state:
		State.COMBAT:
			# Ưu tiên 1: Kiểm tra mục tiêu có còn tồn tại không
			if not is_instance_valid(target_monster) or target_monster.is_dead:
				find_new_target_in_radius()
				return # Thoát ra ngay để frame sau xử lý trạng thái mới

			var distance_to_monster = global_position.distance_to(target_monster.global_position)

			# Ưu tiên 2: Kiểm tra khoảng cách
			# NẾU NGOÀI TẦM ĐÁNH -> DI CHUYỂN, KHÔNG TẤN CÔNG
			if distance_to_monster > attack_range_calculated:
				_is_attacking = false # Đảm bảo không ở trong trạng thái animation tấn công
				nav_agent.target_position = target_monster.global_position
				
				if not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					velocity = global_position.direction_to(next_pos) * speed
			
			# NẾU TRONG TẦM ĐÁNH -> ĐỨNG YÊN, CHỜ TIMER ĐỂ TẤN CÔNG
			else:
				velocity = Vector2.ZERO
				# Việc tấn công sẽ được xử lý bởi _on_attack_timer_timeout
				# Chúng ta không cần làm gì thêm ở đây
		
		State.IDLE, State.TRADING:
			pass
			
		_: 
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				velocity = global_position.direction_to(next_pos) * speed

	# --- BƯỚC 4: ÁP DỤNG DI CHUYỂN & CẬP NHẬT HÌNH ẢNH ---
	move_and_slide()
	_update_animation()
	_update_flip_direction()
	_update_attack_area_position()




func _update_animation():
	if _is_attacking:
		return
		
	if animation_player == null:
		return

	var new_anim = "Idle"
	if velocity.length() > 5.0:
		new_anim = "Walk"
		
	if animation_player.current_animation != new_anim:
		animation_player.play(new_anim)

func _update_flip_direction():
	# Lấy giá trị tuyệt đối (luôn dương) của scale.x hiện tại.
	# Việc này giúp giữ lại kích thước gốc mà bạn đã chỉnh trong Editor.
	var original_scale_x = abs(skeleton_2d.scale.x)

	# Ưu tiên 1: Quay mặt về phía quái vật
	if is_instance_valid(target_monster):
		if target_monster.global_position.x < global_position.x:
			skeleton_2d.scale.x = -original_scale_x
		else:
			skeleton_2d.scale.x = original_scale_x
	# Ưu tiên 2: Quay mặt theo hướng di chuyển
	elif abs(velocity.x) > 0.1:
		if velocity.x < 0:
			skeleton_2d.scale.x = -original_scale_x
		else:
			skeleton_2d.scale.x = original_scale_x

func _apply_visual_data(visual_data: Dictionary, visual_sprites_map: Dictionary):
	# Lấy thông tin từ data
	var target_sprite_name = visual_data.get("target_sprite", "")
	var texture_path = visual_data.get("texture_path", "")
	
	# Kiểm tra xem tên sprite có trong bản đồ của chúng ta không
	if visual_sprites_map.has(target_sprite_name):
		var target_sprite_node = visual_sprites_map[target_sprite_name]
		
		if is_instance_valid(target_sprite_node):
			if not texture_path.is_empty() and FileAccess.file_exists(texture_path):
				target_sprite_node.texture = load(texture_path)
				target_sprite_node.visible = true
			else:
				# Nếu không có path hoặc file không tồn tại, ẩn sprite đi
				target_sprite_node.visible = false
				push_warning("Không tìm thấy texture tại: %s" % texture_path)
	else:
		push_warning("Tên target_sprite '%s' trong JSON không khớp với bất kỳ Node nào trong visual_sprites_map." % target_sprite_name)

func _update_equipment_visuals():
	# BƯỚC 1: LUÔN MẶC ĐỒ GỐC LÀM NỀN TRƯỚC TIÊN
	# Hàm này sẽ đảm bảo Hero luôn có một bộ dạng cơ bản.
	_apply_base_appearance()

	# BƯỚC 2: TẠO "BẢN ĐỒ" ĐỂ DỄ DÀNG TÌM SPRITE
	# Việc này giúp chúng ta tìm sprite bằng tên thay vì phải gọi từng biến.
	var visual_sprites_map: Dictionary = {
		"HelmetSprite": helmet_sprite,
		"ArmorSprite": armor_sprite,
		"GlovesLSprite": gloves_l_sprite,
		"GlovesRSprite": gloves_r_sprite,
		"BootsLSprite": boots_l_sprite,
		"BootsRSprite": boots_r_sprite,
		# Thêm các sprite khác nếu có
	}

	# BƯỚC 3: KIỂM TRA VÀ "ĐÈ" HÌNH ẢNH TRANG BỊ ĐANG MẶC LÊN TRÊN
	
	# --- PHẦN 3.1: XỬ LÝ VŨ KHÍ TAY CHÍNH (MAIN_HAND) ---
	if is_instance_valid(weapon_container):
		# Ẩn tất cả các loại vũ khí đi trước
		for weapon_node in weapon_container.get_children():
			if weapon_node is Sprite2D:
				weapon_node.visible = false

		var weapon_id = equipment.get("MAIN_HAND")
		if typeof(weapon_id) == TYPE_STRING and not weapon_id.is_empty():
			var weapon_data = ItemDatabase.get_item_data(weapon_id)
			if not weapon_data.is_empty():
				var weapon_type = weapon_data.get("weapon_type", "SWORD")
				var target_sprite_name = ""
				match weapon_type:
					"SWORD": target_sprite_name = "SwordSprite"
					"BOW": target_sprite_name = "BowSprite"
					"STAFF": target_sprite_name = "StaffSprite"
					"DAGGER": target_sprite_name = "DaggerSprite"
					_: target_sprite_name = "SwordSprite"

				if not target_sprite_name.is_empty():
					var target_sprite = weapon_container.get_node_or_null(target_sprite_name)
					if is_instance_valid(target_sprite):
						var icon_path = weapon_data.get("icon_path", "")
						if not icon_path.is_empty() and FileAccess.file_exists(icon_path):
							target_sprite.texture = load(icon_path)
						else:
							target_sprite.texture = null
						target_sprite.visible = true
		else:
			_current_attack_animation_name = "AttackSword"

	# --- PHẦN 3.2: XỬ LÝ KHIÊN TAY PHỤ (OFF_HAND) ---
	if is_instance_valid(offhand_sprite):
		# Ẩn khiên đi trước khi kiểm tra
		offhand_sprite.visible = false
		var shield_id = equipment.get("OFF_HAND")
		if typeof(shield_id) == TYPE_STRING and not shield_id.is_empty():
			var shield_data = ItemDatabase.get_item_data(shield_id)
			if shield_data.get("equip_slot") == "OFF_HAND":
				var icon_path = shield_data.get("icon_path", "")
				if not icon_path.is_empty() and FileAccess.file_exists(icon_path):
					offhand_sprite.texture = load(icon_path)
					offhand_sprite.visible = true
				else:
					push_warning("Không tìm thấy texture cho khiên '%s' tại: %s" % [shield_id, icon_path])

	# --- PHẦN 3.3: XỬ LÝ CÁC TRANG BỊ CÒN LẠI ---
	var slots_to_check = ["HELMET", "ARMOR", "GLOVES", "BOOTS", "PANTS"]
	for slot_key in slots_to_check:
		var item_id = equipment.get(slot_key)
		
		# Chỉ xử lý nếu ô đó có trang bị (item_id là một String hợp lệ)
		if typeof(item_id) == TYPE_STRING and not item_id.is_empty():
			var item_data = ItemDatabase.get_item_data(item_id)
			
			if item_data.has("visuals"):
				var visuals = item_data.get("visuals")
				
				# Nếu "visuals" là một mảng (đồ đôi như găng tay, giày)
				if visuals is Array:
					for visual_part in visuals:
						_apply_visual_data(visual_part, visual_sprites_map)
				# Nếu "visuals" là một đối tượng (đồ đơn như mũ, áo)
				elif visuals is Dictionary:
					_apply_visual_data(visuals, visual_sprites_map)


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		GameEvents.hero_selected.emit(self)	
		
func _handle_ghost_physics(delta: float):
	# Đếm ngược thời gian chờ trước khi biến thành ghost
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0:
			# Chuyển sang trạng thái ghost
			doi_trang_thai(State.GHOST)
			animation_player.play("Walk")
			remove_from_group("heroes")
			detection_area.monitoring = false
			modulate = Color(1, 1, 1, 0.3) # Làm mờ hero
			
			# Tìm điểm hồi sinh và di chuyển đến đó
			if is_instance_valid(PlayerStats.ghost_respawn_point):
				nav_agent.target_position = PlayerStats.ghost_respawn_point.global_position
			else:
				push_error("Không thấy điểm hồi sinh cho ghost!")
				# Di chuyển về làng như một phương án dự phòng
				if is_instance_valid(PlayerStats.village_boundary):
					nav_agent.target_position = PlayerStats.village_boundary.global_position

	# Logic di chuyển khi đang ở trạng thái GHOST
	if _current_state == State.GHOST:
		# Di chuyển nếu là GHOST và chưa đến đích
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_pos)
			velocity = dir * speed
		else:
			velocity = Vector2.ZERO
			
		# CHỈ ÉP ANIMATION "WALK" KHI ĐÃ LÀ GHOST
		# Đây chính là thay đổi mấu chốt!
		if animation_player.current_animation != "Walk":
			animation_player.play("Walk")
			
	# BƯỚC 2: NẾU CHƯA PHẢI LÀ GHOST (TỨC LÀ ĐANG CHẠY ANIMATION DEATH)
	else:
		# Đảm bảo Hero đứng yên hoàn toàn trong lúc animation Death diễn ra
		velocity = Vector2.ZERO

	# ======================================================================

	move_and_slide()
	_update_flip_direction()
# ============================================================================
# HỆ THỐNG TRẠNG THÁI (STATE MACHINE)
# ============================================================================
# HÀM MỚI 1: Chuyên xử lý việc "dọn dẹp" khi RỜI KHỎI một trạng thái
func _exit_state(state: State):
	match state:
		State.COMBAT:
			# Khi hết combat, đảm bảo dừng timer tấn công và skill
			if is_instance_valid(attack_timer): attack_timer.stop()
			if is_instance_valid(skill_timer): skill_timer.stop()
			_is_attacking = false # Tắt trạng thái đang tấn công


# HÀM MỚI 2: Chuyên xử lý việc "thiết lập" khi BƯỚC VÀO một trạng thái mới
func _enter_state(state: State):
	_current_state = state # Cập nhật trạng thái hiện tại
	
	match state:
		State.IDLE:
			# --- PHẦN SỬA LỖI ---
			# Thêm biến kiểm tra xem hero đã được "sẵn sàng" để hoạt động hay chưa
			var is_ready_to_act = is_instance_valid(movement_area)

			if is_ready_to_act:
				# Nếu đã sẵn sàng, chạy logic như cũ
				var idle_duration = randf_range(0.5, 1.0)
				if is_in_village_area():
					idle_duration = randf_range(1.0, 2.0)
				else:
					# Tối ưu: Quét quái ngay khi rảnh rỗi, không cần chờ
					find_new_target_in_radius()

				# Nếu không tìm thấy quái và chuyển sang combat, thì mới đứng chờ
				if _current_state != State.COMBAT:
					state_timer.start(idle_duration)
			else:
				# Nếu chưa sẵn sàng (mới spawn), chỉ đứng IDLE và chờ một chút
				# để hệ thống bên ngoài (PlayerStats) kịp gán khu vực di chuyển.
				state_timer.start(0.5)

			if is_instance_valid(attack_timer):
				attack_timer.stop()
			# ---------------------
				
		State.WANDER:
			if cap_nhat_ranh_gioi_di_chuyen():
				chon_diem_den_ngau_nhien()
				state_timer.start(randf_range(3.0, 5.0)) # Tăng thời gian đi wander
			else:
				# Thay đổi câu báo lỗi để rõ ràng hơn một chút
				push_error("LỖI WANDER: Không tìm thấy ranh giới trong '%s', quay lại IDLE." % movement_area.name if is_instance_valid(movement_area) else "khu vực không xác định")
				doi_trang_thai(State.IDLE)
				
		State.NAVIGATING, State.GHOST, State.TRADING, State.DEAD:
			state_timer.stop()
			
		State.COMBAT:
			state_timer.stop()
			if is_instance_valid(attack_timer): attack_timer.start()
			if is_instance_valid(skill_timer):
				if not skill_timer.is_stopped(): skill_timer.stop()
				skill_timer.start(randf_range(1.5, 3.0))


# HÀM CŨ ĐƯỢC NÂNG CẤP: Giờ nó sẽ gọi 2 hàm trên
func doi_trang_thai(new_state: State):
	# Không đổi sang trạng thái mà nó vốn đang ở
	if _current_state == new_state:
		return
		
	# Dọn dẹp trạng thái cũ trước
	_exit_state(_current_state)
	# Thiết lập trạng thái mới
	_enter_state(new_state)
	
	# Cập nhật animation cuối cùng
	_update_animation()

func _on_state_timer_timeout():
	if is_ui_interacting or is_dead: return
	if _current_state == State.IDLE:
		if not is_in_village_area():
			find_new_target_in_radius()
		else:
			doi_trang_thai(State.WANDER)
	elif _current_state == State.WANDER:
		doi_trang_thai(State.IDLE)
	
# ============================================================================
# HỆ THỐNG CHIẾN ĐẤU & SÁT THƯƠNG
# ============================================================================
func _on_attack_timer_timeout():
	if is_dead or _current_state != State.COMBAT or not is_instance_valid(target_monster):
		return

	if velocity.length() < 1.0:
		var main_hand_item_id = ""
		var main_hand = equipment.get("MAIN_HAND")
		if main_hand is String:
			main_hand_item_id = main_hand
		
		var weapon_data = {}
		if not main_hand_item_id.is_empty():
			weapon_data = ItemDatabase.get_item_data(main_hand_item_id)
		
		var weapon_type = weapon_data.get("weapon_type", "SWORD")

		# --- LOGIC MỚI, ĐÚNG CHUẨN ---
		_is_attacking = true
		animation_player.play(_current_attack_animation_name)

		match weapon_type:
			"STAFF":
				if current_sp >= SP_COST_PER_SPELL:
					current_sp -= SP_COST_PER_SPELL
					sp_changed.emit(current_sp, max_sp)
					_update_sp_display()
					_check_and_use_potions()
					_shoot_projectile(magic_ball, true)
			"BOW":
				pass

			_: # Kiếm, dao găm và các loại khác
				has_dealt_damage_this_attack = false



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
	
	_check_and_use_potions()

	if current_hp <= 0 and not is_dead:
		die()
	
# ============================================================================
# HỆ THỐNG "LINH HỒN" & HỒI SINH
# ============================================================================
func die():
	if is_dead:
		print("[DEBUG] Ham die() duoc goi nhung is_dead da la true -> bo qua.") # Print mới
		return
	
	print("[DEBUG] >>> BAT DAU QUA TRINH DIE <<<") # Print mới
	
	is_dead = true
	target_monster = null
	velocity = Vector2.ZERO
	
	if is_instance_valid(attack_timer): attack_timer.stop()
	if is_instance_valid(state_timer): state_timer.stop()
	if is_instance_valid(skill_timer): skill_timer.stop()
	
	doi_trang_thai(State.DEAD)
	
	print("[DEBUG] Da play animation 'Death'. Animation hien tai la: ", animation_player.current_animation) # Print mới
	
	collision_shape.set_deferred("disabled", true)
	
	animation_player.play("Death")
	print("[DEBUG] Đã ra lệnh: animation_player.play(\"Death\")")
		
	debug_print_timer = 1.0
	death_timer = 10.0
	print("[DEBUG] Đã cài đặt death_timer = %.1f giây." % death_timer)

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

	# TÌM MỘT ĐIỂM HỢP LỆ BÊN TRONG KHU VỰC ĐÍCH
	var target_shape: Shape2D = null
	var target_transform: Transform2D
	for child in target_area.get_children():
		if child is CollisionShape2D and is_instance_valid(child.shape):
			target_shape = child.shape
			target_transform = child.global_transform
			break
			
	if target_shape == null:
		push_error("Không tìm thấy ranh giới trong khu vực đích '%s'" % target_area.name)
		return
		
	var rect = target_shape.get_rect()
	var random_point_local = Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	var random_point_global = target_transform * random_point_local
	var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, random_point_global)

	# GỌI HÀM MỆNH LỆNH MỚI
	move_to_location_by_player(valid_nav_point)

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
	if _current_state == State.PLAYER_COMMAND:
		doi_trang_thai(State.IDLE)
		return
	
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
func _reset_bonus_stats():
	bonus_str = 0.0; bonus_agi = 0.0; bonus_vit = 0.0
	bonus_intel = 0.0; bonus_dex = 0.0; bonus_luk = 0.0
	bonus_atk = 0.0; bonus_matk = 0.0
	bonus_max_hp = 0.0; bonus_max_sp = 0.0
	bonus_def = 0.0; bonus_mdef = 0.0
	bonus_hit = 0.0; bonus_flee = 0.0
	bonus_crit_rate = 0.0; bonus_crit_dame = 0.0
	bonus_perfect_dodge = 0.0
	bonus_crit_resist = 0.0
	bonus_aspd_flat = 0.0
	attack_speed_mod = 0.0
	bonus_attack_range = 0.0
	
func _apply_item_stats(item_id: String):
	var item_data = ItemDatabase.get_item_data(item_id)
	if item_data.is_empty(): return

	var item_stats = item_data.get("stats", {})
	if item_stats.is_empty(): return
	
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
	bonus_perfect_dodge += item_stats.get("perfect_dodge", 0.0)
	bonus_crit_resist += item_stats.get("crit_resist", 0.0)
	bonus_aspd_flat += item_stats.get("bonus_aspd_flat", 0.0)
	attack_speed_mod += item_stats.get("attack_speed_mod", 0.0)
	bonus_attack_range += item_stats.get("attack_range_bonus", 0.0)

func _initialize_stats():
	var du_lieu_nghe = GameDataManager.get_hero_definition(job_key)
	if du_lieu_nghe.is_empty():
		push_error("Không tìm thấy dữ liệu nghề cho: " + job_key)
		return

	# Chỉ số ban đầu = Chỉ số Gacha + Chỉ số gốc của nghề
	STR = str_co_ban + du_lieu_nghe.get("str", 0)
	AGI = agi_co_ban + du_lieu_nghe.get("agi", 0)
	VIT = vit_co_ban + du_lieu_nghe.get("vit", 0)
	INTEL = int_co_ban + du_lieu_nghe.get("int", 0)
	DEX = dex_co_ban + du_lieu_nghe.get("dex", 0)
	LUK = luk_co_ban + du_lieu_nghe.get("luk", 0)

	# Cập nhật các chỉ số phụ lần đầu tiên
	_update_secondary_stats()

func _update_secondary_stats():
	# --- PHẦN 0: RESET BONUS STATS ---
	_reset_bonus_stats()
	for slot in equipment:
		var item_id = equipment[slot]
		if typeof(item_id) == TYPE_STRING and not item_id.is_empty():
			_apply_item_stats(item_id)
		elif typeof(item_id) == TYPE_DICTIONARY:
			continue
			
	_apply_passive_skill_bonuses()

	# --- PHẦN 1: TÍNH TỔNG CHỈ SỐ CƠ BẢN ---
	var total_str = STR + bonus_str
	var total_agi = AGI + bonus_agi
	var total_vit = VIT + bonus_vit
	var total_intel = INTEL + bonus_intel
	var total_dex = DEX + bonus_dex
	var total_luk = LUK + bonus_luk
	
	# --- PHẦN 3: ÁP DỤNG CÁC CÔNG THỨC TÍNH TOÁN CHI TIẾT ---
	
	# Lấy thông tin vũ khí để dùng cho nhiều công thức
	var weapon_id = equipment.get("MAIN_HAND")
	var weapon_type = ""
	var weapon_data = {}
	if typeof(weapon_id) == TYPE_STRING and not weapon_id.is_empty():
		weapon_data = ItemDatabase.get_item_data(weapon_id)
		weapon_type = weapon_data.get("weapon_type", "")
		
	# -- 3.1: SINH TỒN & PHÒNG THỦ --
	var base_hp = (level * 10.0) + (total_vit * 5.0)
	if weapon_type == "SWORD":
		base_hp += total_str * 0.5
	max_hp = base_hp * (1.0 + total_vit * 0.01) + bonus_max_hp
	
	var base_sp = (level * 5.0) + (total_intel * 3.0)
	max_sp = base_sp * (1.0 + total_intel * 0.01) + bonus_max_sp
	
	hp_regen = (max_hp / 200.0) + (total_vit / 5.0)
	sp_regen = (max_sp / 100.0) + (total_intel / 6.0)
	
	def = (total_vit / 2.0) + bonus_def
	mdef = total_intel + (total_vit / 5.0) + (total_dex / 5.0) + (level / 4.0) + bonus_mdef
	
	perfect_dodge = (total_luk / 10.0) + bonus_perfect_dodge
	crit_resist = (total_luk / 5.0) + bonus_crit_resist
	healing_item_bonus = 1.0 + (total_vit * 0.02)
	
	# -- 3.2: CHÍNH XÁC & NÉ TRÁNH --
	hit = level + total_dex + bonus_hit
	flee = level + total_agi + bonus_flee
	
	# -- 3.3: SÁT THƯƠNG VẬT LÝ --
	var base_max_atk = 0.0
	match weapon_type:
		"SWORD": base_max_atk = (total_str * 1.5) + (total_dex * 0.3)
		"DAGGER": base_max_atk = (total_str * 1.0) + (total_dex * 0.2) + (total_agi * 0.2)
		"BOW": base_max_atk = (total_dex * 1.2) + (total_str * 0.3)
		"STAFF": base_max_atk = total_str * 0.5
		_: base_max_atk = total_str # Tay không và các loại khác

	var bonus_atk_from_stats = pow(int(total_str / 10), 2) - 1 + (total_dex / 5) + (total_luk / 5)
	max_atk = base_max_atk + bonus_atk_from_stats + bonus_atk
	min_atk = max_atk * (1.0 - (total_dex / 200.0))
	
	# -- 3.4: SÁT THƯƠNG PHÉP --
	var base_min_matk = total_intel + pow(int(total_intel / 7), 2)
	var base_max_matk = total_intel + pow(int(total_intel / 5), 2)
	
	if weapon_type == "STAFF":
		base_min_matk *= 1.5
		base_max_matk *= 1.5
	else:
		base_min_matk = total_intel / 2.9
		base_max_matk = total_intel / 2.0

	var bonus_matk_from_stats = pow(int(total_intel / 10), 2) - 1
	min_matk = base_min_matk + bonus_matk_from_stats + bonus_matk
	max_matk = base_max_matk + bonus_matk_from_stats + bonus_matk
	
	# -- 3.5: TẤN CÔNG PHỤ --
	crit_rate = (total_luk * 0.3) + bonus_crit_rate
	if weapon_type == "KATAR":
		crit_rate *= 2
	crit_damage = 1.5 + (total_agi / 500.0) + (total_luk / 200.0) + bonus_crit_dame
	
	# -- 3.6: TỐC ĐỘ & THỜI GIAN --
	var weapon_penalty = 0.0
	if not weapon_data.is_empty(): weapon_penalty += weapon_data.get("aspd_penalty", 0.0)
	var shield_id = equipment.get("OFF_HAND")
	if typeof(shield_id) == TYPE_STRING and not shield_id.is_empty():
		weapon_penalty += ItemDatabase.get_item_data(shield_id).get("aspd_penalty", 0.0)
	
	var stat_bonus_aspd = sqrt( (total_dex*total_dex / 80.0) + (total_agi*total_agi / 32.0) )
	aspd = round(156 + stat_bonus_aspd - weapon_penalty + bonus_aspd_flat)
	aspd = clamp(aspd, 0, 193)
	
	if (200.0 - aspd) > 0:
		var attacks_per_second = 50.0 / (200.0 - aspd)
		var base_attack_time = 1.0 / attacks_per_second
		attack_time = base_attack_time * (1.0 - (total_dex * 0.001))
	else:
		attack_time = 0.2 # Tốc độ đánh tối đa

	attack_range_calculated = ATTACK_RANGE + bonus_attack_range
	if is_instance_valid(attack_range_shape) and attack_range_shape.shape is CircleShape2D:
		attack_range_shape.shape.radius = attack_range_calculated
	cast_time_reduction = (total_dex / 15.0) * 0.10
	
	# -- 3.7: CẬP NHẬT TRẠNG THÁI CUỐI CÙNG --
	current_hp = min(current_hp, max_hp)
	current_sp = min(current_sp, max_sp)
	
	if is_instance_valid(attack_timer):
		attack_timer.wait_time = attack_time
	
	_update_equipment_visuals()
	stats_updated.emit()

func _on_detection_radius_body_entered(body):
	# Nếu đang chiến đấu hoặc đã chết, không tìm mục tiêu mới
	if _current_state == State.COMBAT or is_dead or State.PLAYER_COMMAND:
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

func move_to_location_by_player(target_position: Vector2):
	# Dừng lại nếu đang thực hiện các hành động không thể bị gián đoạn
	if is_dead or _current_state in [State.RESTING, State.IN_BARRACKS]:
		return
		
	print(">>> Hero '%s' nhận mệnh lệnh di chuyển từ người chơi!" % hero_name)
	
	# Chuyển sang trạng thái Mệnh Lệnh Tối Cao
	doi_trang_thai(State.PLAYER_COMMAND)
	
	# Đặt mục tiêu di chuyển
	nav_agent.target_position = target_position

func _update_attack_area_position():
	var offset_x = 10.0 # Hoặc một giá trị khác bạn muốn cho tầm đánh cận chiến
	
	# === PHẦN SỬA LỖI QUAN TRỌNG ===
	# Kiểm tra trạng thái lật từ scale.x của Skeleton2D
	if skeleton_2d.scale.x < 0: # Nếu scale.x là -1, nghĩa là đang quay sang trái
		attack_area.position.x = -offset_x
		attack_area.scale.x = -1
	else: # Nếu scale.x là 1, nghĩa là đang quay sang phải
		attack_area.position.x = offset_x
		attack_area.scale.x = 1

func cap_nhat_ranh_gioi_di_chuyen() -> bool:
	if not is_instance_valid(movement_area):
		_boundary_shape = null
		return false

	# --- LOGIC MỚI, LINH HOẠT HƠN ---
	# Lặp qua tất cả các con trực tiếp của khu vực di chuyển
	for child in movement_area.get_children():
		# Nếu tìm thấy một node là CollisionShape2D và nó có shape hợp lệ
		if child is CollisionShape2D and is_instance_valid(child.shape):
			# Lấy thông tin và trả về true ngay lập tức
			_boundary_shape = child.shape
			_boundary_transform = child.global_transform
			return true
	
	# Nếu lặp hết mà không tìm thấy, báo lỗi và trả về false
	_boundary_shape = null
	push_warning("Không tìm thấy CollisionShape2D hợp lệ trong khu vực '%s'" % movement_area.name)
	return false

func chon_diem_den_ngau_nhien() -> void:
	if _boundary_shape == null: return
	var rect = _boundary_shape.get_rect()
	var random_point_local = Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	var random_point_global = _boundary_transform * random_point_local
	var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, random_point_global)
	nav_agent.target_position = valid_nav_point
	
	
func _on_animation_finished(anim_name): 
	if is_dead:
		print("[DEBUG] _on_animation_finished: Hero da chet, bo qua logic.") # Print mới
		return

	if anim_name in ["Attack", "Shooting"]:
		_is_attacking = false
		has_dealt_damage_this_attack = false
		animation_player.play(&"Idle")
		
		detection_area.monitoring = false
		modulate = Color(1,1,1,0.5)
		animation_player.play("Walk")
		
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
	var min_distance = INF
	for body in bodies:
		if body.is_in_group("monsters") and not body.is_dead:
			var distance = global_position.distance_to(body.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_monster = body
	if is_instance_valid(closest_monster):
		target_monster = closest_monster
		doi_trang_thai(State.COMBAT)
	else:
		# Nếu đang ở village thì IDLE, còn ngoài village thì chuyển sang WANDER
		if is_in_village_area():
			doi_trang_thai(State.IDLE)
		else:
			doi_trang_thai(State.WANDER)
		
func is_in_village_area() -> bool:
	return movement_area == PlayerStats.village_boundary

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
	if is_dead or (job_key == "Novice" and level >= MAX_LEVEL_NOVICE):
		return

	if level >= 100:
		return
	current_exp += amount
	# Sau khi cộng xong, gọi hàm kiểm tra lên cấp
	level_up()

	# HIỂN THỊ SỐ EXP BAY LÊN
	var text_position = global_position - Vector2(0, 150) # Vị trí hơi cao hơn số sát thương
	FloatingTextManager.show_text("+" + str(amount) + " EXP", Color.YELLOW, text_position)

func level_up():
	# Sử dụng vòng lặp while để xử lý an toàn việc lên nhiều cấp
	var has_leveled_up = false
	while current_exp >= exp_to_next_level and level < 100:
		has_leveled_up = true
		
		# Trừ đi lượng EXP cần để lên cấp
		current_exp -= exp_to_next_level
		
		# Tăng cấp và các chỉ số
		level += 1
		free_points += 5
		skill_points += 100
		
		# Tính lại lượng EXP cần cho cấp độ tiếp theo
		exp_to_next_level = int(100 * pow(level, 3.35))
		
		print("!!!!!!!!!! LEVEL UP !!!!!!!!!!")
		print(">>> '%s' đã đạt đến cấp độ %d!" % [hero_name, level])
		
		# Tăng chỉ số gốc
		STR += roundi(str_tang_truong)
		AGI += roundi(agi_tang_truong)
		VIT += roundi(vit_tang_truong)
		INTEL += roundi(int_tang_truong)
		DEX += roundi(dex_tang_truong)
		LUK += roundi(luk_tang_truong)

	# Nếu có ít nhất một lần lên cấp, thực hiện các hành động cuối cùng
	if has_leveled_up:
		# Cập nhật lại toàn bộ chỉ số phụ MỘT LẦN DUY NHẤT sau khi đã lên hết cấp
	
		# Hồi đầy máu và năng lượng
		current_hp = max_hp
		current_sp = max_sp
		# Phát tín hiệu và cập nhật UI
		_update_hp_display()
		sp_changed.emit(current_sp, max_sp)
		free_points_changed.emit()
		skill_tree_changed.emit()
	
	# Luôn phát tín hiệu EXP thay đổi ở cuối để UI cập nhật trạng thái cuối cùng
	exp_changed.emit(current_exp, exp_to_next_level)
	
	_update_secondary_stats()

func equip_from_inventory(inventory_slot_index: int):
	if inventory_slot_index < 0 or inventory_slot_index >= inventory.size():
		return
	var item_package_to_equip = inventory[inventory_slot_index]
	if not item_package_to_equip:
		return

	var item_id_to_equip = item_package_to_equip.get("id")
	var item_data = ItemDatabase.get_item_data(item_id_to_equip)
	var item_type = item_data.get("item_type")

	if item_type == "EQUIPMENT":
		var slot_key = item_data.get("equip_slot")
		if not equipment.has(slot_key):
			return

		# BỎ: bắt phải tháo trước, THAY BẰNG:
		var old_equipped_item_id = equipment.get(slot_key)
		# Nếu có trang bị cũ, thực hiện hoán đổi nhanh (ngoại trừ slot potion)
		if old_equipped_item_id and not slot_key.begins_with("POTION"):
			# Đưa item đang trang bị về lại túi (nếu còn chỗ)
			var swapped = false
			for i in range(inventory.size()):
				if inventory[i] == null:
					inventory[i] = {"id": old_equipped_item_id, "quantity": 1}
					swapped = true
					break
			if not swapped:
				# Nếu không còn chỗ, không thực hiện hoán đổi
				print("Túi đồ đã đầy, không thể hoán đổi nhanh!")
				return
		# Trang bị item mới vào slot
		equipment[slot_key] = item_id_to_equip
		inventory[inventory_slot_index] = null
		
	elif item_type == "CONSUMABLE":
		# Giữ nguyên logic cũ cho consumable (potion)
		var quantity_to_add = item_package_to_equip.get("quantity", 1)
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			var existing_package = equipment.get(slot_key)
			if existing_package != null and existing_package.get("id") == item_id_to_equip:
				existing_package["quantity"] += quantity_to_add
				inventory[inventory_slot_index] = null
				stats_updated.emit()
				equipment_changed.emit(equipment)
				inventory_changed.emit()
				return
		for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
			if equipment.get(slot_key) == null:
				equipment[slot_key] = item_package_to_equip
				inventory[inventory_slot_index] = null
				stats_updated.emit()
				equipment_changed.emit(equipment)
				inventory_changed.emit()
				return
		print("Tất cả các ô Potion đã đầy!")
		return
	else:
		print("Vật phẩm '%s' không thể trang bị." % item_data.get("item_name"))
		return

	# Cập nhật giao diện và chỉ số
	stats_updated.emit()
	equipment_changed.emit(equipment)
	inventory_changed.emit()
	_update_secondary_stats()

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
		stats_updated.emit()
		equipment_changed.emit(equipment)
		inventory_changed.emit()
	else:
		print("Không thể tháo trang bị, túi đồ đã đầy!")
		_update_secondary_stats()
		
func _update_hp_display():
	# Phần 1: Cập nhật thanh máu trên đầu hero (giữ nguyên code của bạn)
	if is_instance_valid(hp_bar):
		hp_bar.value = current_hp
	if is_instance_valid(hp_label):
		var hp_hien_tai = roundi(current_hp)
		var hp_toi_da = roundi(max_hp)
		hp_label.text = "%d/%d" % [hp_hien_tai, hp_toi_da]

	# === PHẦN NÂNG CẤP QUAN TRỌNG ===
	# Phần 2: "Phát thanh" tín hiệu ra ngoài cho các hệ thống khác (như SelectedHeroPanel) lắng nghe
	hp_changed.emit(current_hp, max_hp)
	# ==============================
	
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
	if is_dead:
		return
		
	var hp_percent = current_hp / max_hp
	
	# === THAY ĐỔI QUAN TRỌNG ===
	# Thay vì so sánh với số 0.5 cứng, giờ đây nó sẽ đọc giá trị từ cài đặt chung
	if hp_percent > PlayerStats.auto_potion_hp_threshold:
		return
	# ===========================
		
	if not is_instance_valid(_ui_controller):
		return

	var san_sang_slot_key = _ui_controller.tim_potion_slot_san_sang()
	
	if san_sang_slot_key != "":
		dung_potion(san_sang_slot_key)

func _xu_ly_tu_dong_dung_sp_potion():
	if is_dead or max_sp <= 0: return

	var sp_percent = current_sp / max_sp
	
	# === THAY ĐỔI QUAN TRỌNG ===
	# Đọc giá trị SP threshold từ cài đặt chung
	if sp_percent > PlayerStats.auto_potion_sp_threshold:
		return
	# ===========================

	if not is_instance_valid(_ui_controller): return

	var san_sang_slot_key = _ui_controller.tim_potion_slot_san_sang("sp")

	if not san_sang_slot_key.is_empty():
		dung_potion(san_sang_slot_key)


func dung_potion(slot_key: String):
	var item_package = equipment.get(slot_key)
	if not (item_package is Dictionary): return

	var item_id = item_package.get("id")
	var item_data = ItemDatabase.get_item_data(item_id)
	if item_data.is_empty(): return

	var stats_data = item_data.get("stats", {})
	var heal_amount = stats_data.get("heal_amount", 0)
	var sp_restore_amount = stats_data.get("sp_restore_amount", 0)
	var text_position = global_position - Vector2(0, 100)

	if heal_amount > 0:
		current_hp = min(current_hp + heal_amount, max_hp)
		_update_hp_display()
		FloatingTextManager.show_text("+" + str(heal_amount), Color.GREEN, text_position)

	var vfx_instance = VFX_Scene.instantiate()
	add_child(vfx_instance)
	vfx_instance.play_effect("heal")
	vfx_instance.position.y = -60

	if sp_restore_amount > 0:
		current_sp = min(current_sp + sp_restore_amount, max_sp)
		sp_changed.emit(current_sp, max_sp)
		FloatingTextManager.show_text("+" + str(sp_restore_amount), Color.BLUE, text_position)

	item_package["quantity"] -= 1
	if item_package["quantity"] <= 0:
		equipment[slot_key] = null

	# === THAY ĐỔI QUAN TRỌNG: HERO TỰ KÍCH HOẠT COOLDOWN ===
	var cooldown = item_data.get("cooldown", 5.0)
	_potion_cooldowns[slot_key] = cooldown
	potion_cooldown_started.emit(slot_key, cooldown) 
	# ========================================================
	# Dòng này vẫn giữ để UI có thể cập nhật số lượng
	equipment_changed.emit(equipment)
	

func _tim_potion_slot_san_sang(potion_type: String = "hp") -> String:
	for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
		# 1. Kiểm tra xem ô này có đang bị cooldown không
		var is_on_cooldown = _potion_cooldowns.get(slot_key, 0.0) > 0
		if not is_on_cooldown:
			# 2. Kiểm tra xem trong ô có đúng loại Potion cần tìm không
			var item_package = equipment.get(slot_key)
			if item_package is Dictionary:
				var item_id = item_package.get("id")
				var item_data = ItemDatabase.get_item_data(item_id)
				var stats_data = item_data.get("stats", {})

				if potion_type == "hp" and stats_data.get("heal_amount", 0) > 0:
					return slot_key # Tìm thấy!
				elif potion_type == "sp" and stats_data.get("sp_restore_amount", 0) > 0:
					return slot_key # Tìm thấy!

	return "" # Không tìm thấy ô nào phù hợp

func _update_potion_cooldowns(delta: float):
	for slot_key in _potion_cooldowns:
		if _potion_cooldowns[slot_key] > 0:
			_potion_cooldowns[slot_key] -= delta

func _check_and_use_potions():
	if is_dead: return

	# --- 1. Ưu tiên kiểm tra và dùng Potion HP ---
	var hp_percent = current_hp / max_hp
	if hp_percent <= PlayerStats.auto_potion_hp_threshold:
		# === THAY ĐỔI QUAN TRỌNG: GỌI HÀM CỦA CHÍNH HERO ===
		var hp_potion_slot = _tim_potion_slot_san_sang("hp")
		# =================================================
		if not hp_potion_slot.is_empty():
			dung_potion(hp_potion_slot)
			return

	# --- 2. Nếu không cần dùng Potion HP, mới kiểm tra SP ---
	if max_sp > 0:
		var sp_percent = current_sp / max_sp
		if sp_percent <= PlayerStats.auto_potion_sp_threshold:
			# === THAY ĐỔI QUAN TRỌNG: GỌI HÀM CỦA CHÍNH HERO ===
			var sp_potion_slot = _tim_potion_slot_san_sang("sp")
			# =================================================
			if not sp_potion_slot.is_empty():
				dung_potion(sp_potion_slot)

# ===============================================
# === HỆ THỐNG LƯU TRỮ DỮ LIỆU (SAVE/LOAD) ===
# ===============================================

# Hàm này "đóng gói" toàn bộ thông tin quan trọng của Hero thành một Dictionary
func save_data() -> Dictionary:
	var area_name = ""
	if is_instance_valid(movement_area):
		area_name = movement_area.name

	var nav_target_x = global_position.x
	var nav_target_y = global_position.y
	if is_instance_valid(nav_agent):
		nav_target_x = nav_agent.target_position.x
		nav_target_y = nav_agent.target_position.y

	var data = {
		"name": name,
		"hero_name": hero_name,
		"job_key": job_key,
		"level": level,
		"current_exp": current_exp,
		"exp_to_next_level": exp_to_next_level,
		"is_dead": is_dead,
		"str_co_ban": str_co_ban,
		"agi_co_ban": agi_co_ban,
		"vit_co_ban": vit_co_ban,
		"int_co_ban": int_co_ban,
		"dex_co_ban": dex_co_ban,
		"luk_co_ban": luk_co_ban,
		"str_tang_truong": str_tang_truong,
		"agi_tang_truong": agi_tang_truong,
		"vit_tang_truong": vit_tang_truong,
		"int_tang_truong": int_tang_truong,
		"dex_tang_truong": dex_tang_truong,
		"luk_tang_truong": luk_tang_truong,
		# --- LƯU CHỈ SỐ ĐÃ CỘNG (rất quan trọng) ---
		"STR": STR,
		"agi": AGI,
		"vit": VIT,
		"intel": INTEL,
		"dex": DEX,
		"luk": LUK,
		"free_points": free_points,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"current_hp": current_hp,
		"current_sp": current_sp,
		"current_area_name": area_name,
		"inventory": inventory,
		"equipment": equipment,
		"gold": gold,
		"_current_state": _current_state,
		"nav_target_pos_x": nav_target_x,
		"nav_target_pos_y": nav_target_y,
		
		"skill_points": skill_points,
		"learned_skills": learned_skills,
		"equipped_skills": equipped_skills,
		"base_appearance": base_appearance
		
		
		
	}
	return data

func load_data(data: Dictionary):
	# Chỉ tạm cất dữ liệu, không xử lý gì cả
	staged_data = data

func _apply_loaded_data(data: Dictionary):
	# Dừng các timer (giờ đã an toàn để gọi)
	if is_instance_valid(state_timer): state_timer.stop()
	if is_instance_valid(attack_timer): attack_timer.stop()
	
	# === DÁN TOÀN BỘ NỘI DUNG CỦA HÀM LOAD_DATA CŨ CỦA BẠN VÀO ĐÂY ===
	# Ví dụ:
	name = data.get("name", "Hero Bi Loi")
	hero_name = data.get("hero_name", "Tan Binh")
	level = data.get("level", 1)
	current_exp = data.get("current_exp", 0)
	exp_to_next_level = data.get("exp_to_next_level", 100)
	base_appearance = data.get("base_appearance", {})
	
	str_co_ban = data.get("str_co_ban", 1.0)
	agi_co_ban = data.get("agi_co_ban", 1.0)
	vit_co_ban = data.get("vit_co_ban", 1.0)
	int_co_ban = data.get("int_co_ban", 1.0)
	dex_co_ban = data.get("dex_co_ban", 1.0)
	luk_co_ban = data.get("luk_co_ban", 1.0)


	str_tang_truong = data.get("str_tang_truong", 0.1)
	agi_tang_truong = data.get("agi_tang_truong", 0.1)
	vit_tang_truong = data.get("vit_tang_truong", 0.1)
	int_tang_truong = data.get("int_tang_truong", 0.1)
	dex_tang_truong = data.get("dex_tang_truong", 0.1)
	luk_tang_truong = data.get("luk_tang_truong", 0.1)
	# --- KHÔI PHỤC CHỈ SỐ ĐÃ CỘNG ---
	STR = data.get("STR", str_co_ban)
	AGI = data.get("agi", agi_co_ban)
	VIT = data.get("vit", vit_co_ban)
	INTEL = data.get("intel", int_co_ban)
	DEX = data.get("dex", dex_co_ban)
	LUK = data.get("luk", luk_co_ban)
	free_points = data.get("free_points", 0)
	inventory = data.get("inventory", []).duplicate(true)
	equipment = data.get("equipment", {}).duplicate(true)
	gold = data.get("gold", 0)
	
	skill_points = data.get("skill_points", 0)
	learned_skills = data.get("learned_skills", {}).duplicate(true)
	equipped_skills = data.get("equipped_skills", []).duplicate(true)
	if equipped_skills.size() < MAX_SKILL_SLOTS:
		equipped_skills.resize(MAX_SKILL_SLOTS)
		# fill() sẽ không ghi đè lên các giá trị đã có
		equipped_skills.fill(null) 

	# Tính lại các chỉ số phụ dựa trên chỉ số hiện tại
	_update_secondary_stats()

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

	# Chuyển trạng thái cuối cùng, sau khi mọi thứ đã sẵn sàng
	if loaded_state in [State.NAVIGATING, State.WANDER, State.GHOST, State.IDLE, State.IN_BARRACKS, State.PLAYER_COMMAND, State.DEAD]:
		# Đừng gọi doi_trang_thai ở đây, hãy gán trực tiếp và để _ready xử lý
		_current_state = loaded_state
		nav_agent.target_position = target_pos
		if loaded_state == State.GHOST:
			collision_shape.set_deferred("disabled", true)
			detection_area.monitoring = false
			modulate = Color(1, 1, 1, 0.5)
			animation_player.play("Walk")
	else:
		if loaded_state == State.WANDER:
			loaded_state = State.IDLE
		doi_trang_thai(loaded_state) # Gọi doi_trang_thai ở đây là an toàn

	_update_hp_display()
	_update_sp_display()
	inventory_changed.emit()
	gold_changed.emit()

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
	
func _shoot_projectile(projectile_scene: PackedScene, is_magic_attack: bool = false):
	if not is_instance_valid(target_monster) or not projectile_scene:
		return
		
	var projectile_speed = 1500.0 / attack_speed_calculated
	var new_projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(new_projectile)
	
	# Truyền thêm is_magic_attack vào projectile để nó biết cách tính sát thương
	# Lưu ý: Hàm start() trong script của arow.gd và magic.gd cần được cập nhật để nhận tham số này
	if new_projectile.has_method("start"):
		new_projectile.start(global_position, target_monster, self, projectile_speed, is_magic_attack)

func execute_attack_on(target_monster_node, p_su_dung_phep: bool, skill_damage_multiplier: float = 1.0):
	if not is_instance_valid(target_monster_node) or target_monster_node.is_dead:
		return

	# Gọi hàm chiến đấu và truyền hệ số sát thương mới vào
	var combat_result = CombatUtils.hero_tan_cong_quai(self, target_monster_node, p_su_dung_phep, skill_damage_multiplier)

	var text_position = target_monster_node.global_position - Vector2(0, 150)

	if combat_result.is_miss:
		FloatingTextManager.show_text("MISS!!", Color.GRAY, text_position)
	else:
		var text_to_show = str(combat_result.damage)
		# Sát thương từ skill (multiplier > 1) sẽ có màu khác
		var color = Color.ORANGE_RED if skill_damage_multiplier > 1.0 else Color.WHITE
		
		if combat_result.is_crit:
			color = Color.YELLOW # Crit của skill màu vàng cho nổi bật
			text_to_show += "!!"

		FloatingTextManager.show_text(text_to_show, color, text_position, combat_result.is_crit)

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

func nang_cap_chi_so(stat_name: String):
	# 1. Kiểm tra xem còn điểm để cộng không
	if free_points <= 0:
		return # Dừng hàm nếu không còn điểm

	# 2. Trừ 1 điểm
	free_points -= 1

	# 3. Tăng chỉ số tương ứng
	match stat_name:
		"str":
			STR += 1
		"agi":
			AGI += 1
		"vit":
			VIT += 1
		"int":
			INTEL += 1
		"dex":
			DEX += 1
		"luk":
			LUK += 1
	

	# 5. Phát tín hiệu để UI cập nhật lại
	stats_updated.emit()
	free_points_changed.emit() # Báo cho UI biết số điểm đã thay đổi
	
	_update_secondary_stats()

func stop_and_interact_with_npc(npc):
	# Dừng mọi hoạt động di chuyển
	nav_agent.target_position = global_position
	_current_route.clear()
	
	# Chuyển sang trạng thái TRADING để Hero đứng im
	doi_trang_thai(State.TRADING)
	
	# Quay mặt về phía NPC
	if npc.global_position.x < global_position.x:
		skeleton_2d.scale.x = -1
	else:
		skeleton_2d.scale.x = 1

	# Yêu cầu NPC mở panel tương ứng
	if npc.has_method("open_shop_panel"):
		npc.open_shop_panel(self)

# ============================================================================
# HỆ THỐNG KỸ NĂNG (SKILL SYSTEM)
# ============================================================================

# Hàm để UI hỏi xem skill đã học cấp mấy
func get_skill_level(skill_id: String) -> int:
	return learned_skills.get(skill_id, 0)

# Hàm chính để học hoặc nâng cấp skill
func learn_or_upgrade_skill(skill_id: String):
	var skill_data = SkillDatabase.get_skill_data(skill_id)
	if skill_data.is_empty(): 
		return

	var current_level = get_skill_level(skill_id)
	var max_level = skill_data.get("max_level", 1)
	if current_level >= max_level: 
		return
		
	var cost_array = skill_data.get("skill_point_cost", [])
	if current_level >= cost_array.size():
		return

	var cost = cost_array[current_level]

	
	if skill_points >= cost:
		skill_points -= cost
		learned_skills[skill_id] = current_level + 1
		
		if skill_data.get("usage_type") == "PASSIVE":
			_update_secondary_stats()
		
		# QUAN TRỌNG: Phát tín hiệu để UI "vẽ" lại
		skill_tree_changed.emit()
	else:
		print("Không đủ điểm kỹ năng để nâng cấp!")

	_update_secondary_stats()

# Hàm này sẽ được gọi bên trong _update_secondary_stats
func _apply_passive_skill_bonuses():
	for skill_id in learned_skills:
		var skill_level = learned_skills[skill_id]
		var skill_data = SkillDatabase.get_skill_data(skill_id)

		# Chỉ áp dụng hiệu ứng cho các skill BỊ ĐỘNG (PASSIVE)
		if skill_data.get("usage_type") == "PASSIVE":
			var effects_data = skill_data.get("effects_per_level", [])[skill_level - 1]
			
			# Cộng dồn các bonus vào biến bonus chung
			bonus_max_hp += effects_data.get("bonus_max_hp", 0.0)
			bonus_max_sp += effects_data.get("bonus_max_sp", 0.0)
			bonus_flee += effects_data.get("bonus_flee", 0.0)
			# ... thêm các bonus khác nếu có ...

func is_skill_equipped(skill_id: String) -> bool:
	return skill_id in equipped_skills

# Hàm để trang bị skill vào một ô trống
func equip_skill(skill_id: String):
	if is_skill_equipped(skill_id): return
	var empty_slot = equipped_skills.find(null)
	if empty_slot != -1:
		equipped_skills[empty_slot] = skill_id
		skill_tree_changed.emit()

# Hàm để tháo một skill
func unequip_skill(skill_id: String):
	var slot = equipped_skills.find(skill_id)
	if slot != -1:
		equipped_skills[slot] = null
		skill_tree_changed.emit()
		
func _on_skill_timer_timeout():
	# Chỉ dùng skill khi đang combat và có mục tiêu
	if _current_state != State.COMBAT or not is_instance_valid(target_monster):
		return

	# --- BƯỚC 1: TÌM KIẾM SKILL KHẢ DỤNG ---
	var usable_skills: Array = []
	# Lặp qua các ô skill đã trang bị
	for skill_id in equipped_skills:
		# Nếu ô có skill (không phải null)
		if skill_id != null:
			var skill_data = SkillDatabase.get_skill_data(skill_id)
			var skill_level = get_skill_level(skill_id)
			
			# Lấy SP cần dùng cho cấp độ hiện tại
			var sp_cost = skill_data.get("sp_cost_per_level", [])[skill_level - 1]
			
			# Kiểm tra 3 điều kiện:
			# 1. Skill đã hết hồi chiêu chưa?
			# 2. Hero có đủ SP không?
			# 3. (Tùy chọn) Vũ khí có phù hợp không?
			var is_on_cooldown = _skill_cooldowns.has(skill_id) and _skill_cooldowns[skill_id] > 0
			
			if not is_on_cooldown and current_sp >= sp_cost:
				usable_skills.append(skill_id)

	# --- BƯỚC 2: QUYẾT ĐỊNH VÀ HÀNH ĐỘNG ---
	if not usable_skills.is_empty():
		# Chọn ngẫu nhiên một skill trong danh sách khả dụng
		var chosen_skill_id = usable_skills.pick_random()
		
		# KÍCH HOẠT SKILL (Chúng ta sẽ viết hàm này ở bước tiếp theo)
		_activate_skill(chosen_skill_id)
		
	else:
		# Nếu không có skill nào để dùng, hẹn giờ lại để kiểm tra sau
		skill_timer.start(randf_range(2.0, 4.0))

# Hàm này sẽ được cập nhật trong _physics_process để đếm ngược cooldown
func _update_cooldowns(delta: float):
	for skill_id in _skill_cooldowns:
		if _skill_cooldowns[skill_id] > 0:
			_skill_cooldowns[skill_id] -= delta

# Tạm thời tạo hàm rỗng để không bị lỗi
func _activate_skill(skill_id: String):
	# --- BƯỚC 1: LẤY DỮ LIỆU VÀ KIỂM TRA ---
	var skill_data = SkillDatabase.get_skill_data(skill_id)
	var skill_level = get_skill_level(skill_id)
	
	# Dừng lại nếu không có dữ liệu skill hoặc skill chưa học
	if skill_data.is_empty() or skill_level == 0:
		return

	# --- BƯỚC 2: TRỪ TÀI NGUYÊN VÀ BẮT ĐẦU COOLDOWN ---
	var sp_cost = skill_data.get("sp_cost_per_level", [])[skill_level - 1]
	
	# Kiểm tra SP lần cuối cùng
	if current_sp < sp_cost:
		skill_timer.start(1.0) # Nếu không đủ SP, thử lại sau 1 giây
		return
		
	current_sp -= sp_cost
	sp_changed.emit(current_sp, max_sp) # Báo cho UI cập nhật
	_check_and_use_potions()
	
	var cooldown = skill_data.get("cooldown", 5.0)
	_skill_cooldowns[skill_id] = cooldown
	
	skill_activated.emit(skill_id, cooldown) 
	
	print(">>> HERO '%s' đã dùng skill '%s'! (Trừ %d SP, hồi chiêu %.1f giây)" % [hero_name, skill_data.get("skill_name"), sp_cost, cooldown])

	# --- BƯỚC 3: ÁP DỤNG HIỆU ỨNG TÙY THEO SKILL ---
	var effects = skill_data.get("effects_per_level")[skill_level - 1]
	var vfx_scale_value = effects.get("vfx_scale", 1.0)
	var final_scale = Vector2(vfx_scale_value, vfx_scale_value)
	
	match skill_id:
		"NOV_SWORD_BOOM":
			var desired_scale = Vector2(2.0 ,2.0)
			_spawn_vfx("sword_boom", -60.0, desired_scale)
			# Skill cận chiến, gây sát thương vật lý được khuếch đại
			var multiplier = effects.get("damage_multiplier", 1.0)
			
			# Tạm dừng đòn đánh thường để thực hiện skill animation
			attack_timer.stop()
			animation_player.play(&"Attack") # Dùng tạm animation đánh thường, sau này có thể đổi
			
			# Gọi hàm chiến đấu với hệ số sát thương từ skill
			execute_attack_on(target_monster, false, multiplier) 
			
			# Bắt đầu lại đòn đánh thường sau một khoảng trễ nhỏ
			await get_tree().create_timer(attack_time).timeout
			if _current_state == State.COMBAT: # Chỉ bắt đầu lại nếu vẫn đang trong combat
				attack_timer.start()
			
		"NOV_DOUBLE_SHOT":
			# Skill bắn cung, tạo ra 2 mũi tên
			var arrow_scene = preload("res://Data/items/arow.tscn")
			_shoot_projectile(arrow_scene) # Bắn mũi tên đầu tiên
			
			# Bắn mũi tên thứ hai sau một khoảng trễ rất ngắn
			await get_tree().create_timer(0.2).timeout
			if is_instance_valid(target_monster): # Kiểm tra xem quái còn sống không
				_shoot_projectile(arrow_scene)

		"NOV_FIRE_BOLT":
			# Skill phép thuật, tạo ra quả cầu lửa
			var magic_scene = preload("res://Data/items/magic.tscn")
			_shoot_projectile(magic_scene, true) # Tham số 'true' báo hiệu đây là đòn phép
	
	# --- BƯỚC 4: HẸN GIỜ CHO LẦN DÙNG SKILL TIẾP THEO ---
	# Hẹn giờ lại để AI tiếp tục suy nghĩ cho lần dùng skill khác
	skill_timer.start(randf_range(3.0, 5.0))
	
func _spawn_vfx(animation_name: String, offset_y: float = -60.0, p_scale: Vector2 = Vector2.ONE):
	# Kiểm tra xem VFX_Scene đã được preload chưa
	if not VFX_Scene: return

	var vfx_instance = VFX_Scene.instantiate()
	add_child(vfx_instance)
	
	vfx_instance.scale = p_scale
	# Điều chỉnh độ cao của hiệu ứng so với gốc của Hero
	vfx_instance.position.y = offset_y 
	vfx_instance.play_effect(animation_name)

func change_hero_face(new_face_texture: Texture2D) -> void:
	# Kiểm tra để chắc chắn node tồn tại trước khi thay đổi
	if is_instance_valid(face_sprite):
		face_sprite.texture = new_face_texture
	else:
		push_warning("Không tìm thấy Node 'face_sprite' để thay đổi texture!")

func get_current_weapon_type() -> String:
	var weapon_id = equipment.get("MAIN_HAND")
	# Nếu không trang bị vũ khí, trả về "UNARMED"
	if not (weapon_id is String and not weapon_id.is_empty()):
		return "UNARMED"

	var weapon_data = ItemDatabase.get_item_data(weapon_id)
	if weapon_data.is_empty():
		return "UNARMED"

	# Trả về loại vũ khí, ví dụ: "SWORD", "BOW", "STAFF"
	return weapon_data.get("weapon_type", "SWORD") # Mặc định là SWORD nếu không có

# HÀM MỚI 2: Kiểm tra tất cả các điều kiện của một skill
# Trả về một Dictionary chứa kết quả và lý do
func check_skill_requirements(skill_id: String) -> Dictionary:
	var result = {
		"can_equip": true,
		"reason": ""
	}

	var skill_data = SkillDatabase.get_skill_data(skill_id)
	if skill_data.is_empty():
		result.can_equip = false
		result.reason = "Skill không hợp lệ."
		return result

	# --- KIỂM TRA YÊU CẦU VŨ KHÍ ---
	if skill_data.has("required_weapon_type"):
		var required_weapon = skill_data["required_weapon_type"]
		var current_weapon = get_current_weapon_type()
		
		if required_weapon != current_weapon:
			result.can_equip = false
			result.reason = "Cần trang bị: " + required_weapon
			return result # Nếu không đủ điều kiện, trả về kết quả ngay

	# (Trong tương lai, bạn có thể thêm các kiểm tra khác ở đây, ví dụ: level, job...)

	return result

# HÀM MỚI: Dùng để "vẽ" lại hình dạng gốc của Hero


func _apply_base_appearance():
	# --- 1. ÁP DỤNG KHUÔN MẶT ---
	var face_path = base_appearance.get("face", "")
	if is_instance_valid(face_sprite) and not face_path.is_empty() and FileAccess.file_exists(face_path):
		face_sprite.texture = load(face_path)

	# --- 2. ÁP DỤNG MŨ GỐC ---
	var helmet_path = base_appearance.get("helmet", "")
	if is_instance_valid(helmet_sprite):
		if not helmet_path.is_empty() and FileAccess.file_exists(helmet_path):
			helmet_sprite.texture = load(helmet_path)
			helmet_sprite.visible = true
		else:
			helmet_sprite.visible = false

	# --- 3. ÁP DỤNG BỘ GIÁP GỐC ---
	var armor_set = base_appearance.get("armor_set", {})
	if not armor_set.is_empty():
		var armor_path = armor_set.get("armor_sprite", "")
		if is_instance_valid(armor_sprite) and not armor_path.is_empty() and FileAccess.file_exists(armor_path):
			armor_sprite.texture = load(armor_path)

		var glove_l_path = armor_set.get("gloves_l_sprite", "")
		if is_instance_valid(gloves_l_sprite) and not glove_l_path.is_empty() and FileAccess.file_exists(glove_l_path):
			gloves_l_sprite.texture = load(glove_l_path)

		var glove_r_path = armor_set.get("gloves_r_sprite", "")
		if is_instance_valid(gloves_r_sprite) and not glove_r_path.is_empty() and FileAccess.file_exists(glove_r_path):
			gloves_r_sprite.texture = load(glove_r_path)

		var boot_l_path = armor_set.get("boots_l_sprite", "")
		if is_instance_valid(boots_l_sprite) and not boot_l_path.is_empty() and FileAccess.file_exists(boot_l_path):
			boots_l_sprite.texture = load(boot_l_path)

		var boot_r_path = armor_set.get("boots_r_sprite", "")
		if is_instance_valid(boots_r_sprite) and not boot_r_path.is_empty() and FileAccess.file_exists(boot_r_path):
			boots_r_sprite.texture = load(boot_r_path)
