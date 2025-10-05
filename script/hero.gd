# res://script/hero.gd
# ============================================================================
# HERO SCRIPT - PHIÊN BẢN COMPONENT (Tái cấu trúc bởi TopTopGame)
# Vai trò: "Nhạc trưởng", điều khiển hành vi (AI, di chuyển, animation)
# và điều phối các component con (Stats, Inventory, Skills).
# ============================================================================
extends CharacterBody2D
class_name Hero

# ============================================================================
# TÍN HIỆU (SIGNALS)
# ============================================================================
signal hp_changed(current_hp, max_hp)
signal sp_changed(current_sp, max_sp)
signal started_resting(hero, heal_rate)
signal finished_resting(hero)
signal potion_cooldown_started(slot_key, duration)

# ============================================================================
# HẰNG SỐ & ENUM
# ============================================================================
const VFX_Scene = preload("res://Scene/VFX/vfx_player.tscn")
const magic_ball = preload("res://Data/items/magic.tscn")
var _current_attack_animation_name: String = "Attack"
const GATE_ARRIVAL_RADIUS: float = 30.0

enum State {
	IDLE,         # Đứng yên, suy nghĩ
	WANDER,       # Lang thang farm quái (Chế độ Farm)
	NAVIGATING,   # Di chuyển giữa các cổng
	COMBAT,       # Giao tranh
	GHOST,        # Trạng thái linh hồn
	TRADING,      # Tương tác với NPC
	RESTING,      # Nghỉ ngơi trong nhà trọ
	IN_BARRACKS,  # Ở trong doanh trại, không hoạt động
	PLAYER_COMMAND, # Di chuyển theo lệnh người chơi (Chế độ Thi Hành Lệnh)
	DEAD          # Trạng thái vừa chết, chờ biến thành Ghost
}

# ============================================================================
# THAM CHIẾU COMPONENT & NODE (@ONREADY)
# ============================================================================
@onready var hero_stats: HeroStats = $HeroStats
@onready var hero_inventory: HeroInventory = $HeroInventory
@onready var hero_skills: HeroSkills = $HeroSkills

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_timer: Timer = $StateTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var skill_timer: Timer = $SkillTimer
@onready var scan_timer: Timer = $ScanTimer
@onready var detection_area: Area2D = $DetectionRadius
@onready var attack_area: Area2D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# --- Tham chiếu đến UI & Hình ảnh ---
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var skeleton_2d: Skeleton2D = $Skeleton2D
@onready var face_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Head_Bone/Face_Sprite
@onready var armor_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/ArmorSprite
@onready var helmet_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Head_Bone/helmet_sprite
@onready var gloves_l_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_trai/Arm_L_Bone/Arm_L_Sprite
@onready var gloves_r_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_Phai/Arm_R_Bone/Arm_R_Sprite
@onready var boots_l_sprite: Sprite2D = $Skeleton2D/HipBone/Chan_trai/Leg_L_Bone/BootsLSprite
@onready var boots_r_sprite: Sprite2D = $Skeleton2D/HipBone/Chan_Phai/Leg_R_Bone/BootsRSprite
@onready var weapon_container: Node2D = $Skeleton2D/HipBone/Than_Minh/Tay_trai/Arm_L_Bone/Hand_L_Bone/WeaponContainer
@onready var offhand_sprite: Sprite2D = $Skeleton2D/HipBone/Than_Minh/Tay_Phai/Arm_R_Bone/Hand_R_Bone/Offhand

# ============================================================================
# THUỘC TÍNH HÀNH VI & TRẠNG THÁI
# ============================================================================
var _current_state = State.IDLE
var target_monster = null
var is_dead: bool = false
var _is_attacking: bool = false
var is_ui_interacting: bool = false
var has_dealt_damage_this_attack: bool = false
var death_timer: float = 0.0

# --- AI & Di chuyển ---
var _current_route: Array = []
var _current_navigation_gate: Node2D = null
var _boundary_shape: Shape2D = null
var _boundary_transform: Transform2D
var player_command_target_area: Area2D = null
var player_command_target_position: Vector2 = Vector2.ZERO
var attackers: Array = []
var wander_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU))

# --- Dữ liệu vật lý & Sinh tồn ---
var speed: float = 150.0
var current_hp: float = 0.0
var current_sp: float = 0.0
var max_hp: float = 1.0 # Giá trị gốc ở HeroStats, dùng để cập nhật UI
var max_sp: float = 1.0
var _potion_cooldowns: Dictionary = {"POTION_1": 0.0, "POTION_2": 0.0, "POTION_3": 0.0}

# --- Tham chiếu ngoài & Dữ liệu khởi tạo ---
var movement_area: Area2D
var world_node: Node2D
var gate_connections: Array = []
var hero_name: String = "Tan Binh"
var base_appearance: Dictionary = {}
var staged_data: Dictionary = {}
var _ui_controller: Node

# ============================================================================
# VÒNG ĐỜI GODOT (LIFECYCLE FUNCTIONS)
# ============================================================================
func _ready() -> void:
	hero_stats.stats_updated.connect(_on_stats_updated)
	hero_inventory.equipment_changed.connect(_on_equipment_changed)
	
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	state_timer.timeout.connect(_on_state_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	skill_timer.timeout.connect(_on_skill_timer_timeout)
	scan_timer.timeout.connect(_on_scan_timer_timeout)
	GameEvents.inn_room_chosen.connect(_on_inn_room_chosen)
	
	if not staged_data.is_empty(): _apply_loaded_data(staged_data)
	else:
		name_label.text = hero_name; hero_stats.initialize_stats(); heal_to_full()
		doi_trang_thai(State.IDLE)

func _physics_process(delta: float) -> void:
	if _current_state in [State.IN_BARRACKS, State.RESTING]:
		velocity = Vector2.ZERO; move_and_slide(); return
	if is_dead: _handle_ghost_physics(delta); return

	_handle_passive_regeneration(delta); _check_and_use_potions()
	_update_potion_cooldowns(delta); hero_skills.update_cooldowns(delta)
	
	velocity = Vector2.ZERO
	match _current_state:
		State.COMBAT:
			if not is_instance_valid(target_monster) or target_monster.is_dead:
				find_new_target_in_radius(); return
			var distance = global_position.distance_to(target_monster.global_position)
			if distance > hero_stats.attack_range_calculated:
				_is_attacking = false; nav_agent.target_position = target_monster.global_position
				if not nav_agent.is_navigation_finished():
					velocity = global_position.direction_to(nav_agent.get_next_path_position()) * speed
			else: velocity = Vector2.ZERO
		State.WANDER:
			nav_agent.target_position = global_position + wander_direction * 1000
			if not nav_agent.is_navigation_finished():
				velocity = global_position.direction_to(nav_agent.get_next_path_position()) * speed
			if velocity.length() < 10 or nav_agent.is_target_reached():
				wander_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		State.IDLE, State.TRADING: pass
		_:
			if not nav_agent.is_navigation_finished():
				velocity = global_position.direction_to(nav_agent.get_next_path_position()) * speed
	move_and_slide(); _update_animation(); _update_flip_direction()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		GameEvents.hero_selected.emit(self)

# ============================================================================
# HỆ THỐNG TRẠNG THÁI & AI (STATE MACHINE & AI)
# ============================================================================
func doi_trang_thai(new_state: State):
	if _current_state == new_state: return
	_exit_state(_current_state); _enter_state(new_state); _update_animation()

func _exit_state(state: State):
	match state:
		State.COMBAT:
			if is_instance_valid(attack_timer): attack_timer.stop()
			if is_instance_valid(skill_timer): skill_timer.stop()
			_is_attacking = false
		State.WANDER: scan_timer.stop()

func _enter_state(state: State):
	_current_state = state
	match state:
		State.IDLE:
			if is_instance_valid(movement_area):
				var duration = randf_range(1.5, 2.5)
				if not is_in_village_area(): find_new_target_in_radius()
				if _current_state != State.COMBAT: state_timer.start(duration)
			else: state_timer.start(0.5)
		State.WANDER: scan_timer.start()
		State.PLAYER_COMMAND: scan_timer.stop()
		State.NAVIGATING, State.GHOST, State.TRADING, State.DEAD:
			state_timer.stop(); scan_timer.stop()
		State.COMBAT:
			state_timer.stop(); scan_timer.stop()
			if is_instance_valid(attack_timer): attack_timer.start()
			if is_instance_valid(skill_timer) and skill_timer.is_stopped():
				skill_timer.start(randf_range(1.5, 3.0))

func _on_state_timer_timeout():
	if not is_dead and _current_state == State.IDLE: find_new_target_in_radius()

func _on_scan_timer_timeout():
	if _current_state == State.WANDER: find_new_target_in_radius()

func _on_skill_timer_timeout():
	if _current_state == State.COMBAT and is_instance_valid(target_monster):
		hero_skills.try_activate_random_skill()

# ============================================================================
# MỆNH LỆNH NGƯỜI CHƠI & DI CHUYỂN
# ============================================================================
func issue_player_command(target_pos: Vector2, target_area: Area2D = null):
	_is_attacking = false; target_monster = null; attackers.clear()
	if is_instance_valid(attack_timer): attack_timer.stop()
	player_command_target_position = target_pos; player_command_target_area = target_area
	nav_agent.target_position = player_command_target_position; doi_trang_thai(State.PLAYER_COMMAND)

func stop_and_interact_with_npc(npc):
	nav_agent.target_position = global_position; _current_route.clear(); doi_trang_thai(State.TRADING)
	var scale_x = abs(skeleton_2d.scale.x)
	if npc.global_position.x < global_position.x: skeleton_2d.scale.x = -scale_x
	else: skeleton_2d.scale.x = scale_x
	if npc.has_method("open_shop_panel"): npc.open_shop_panel(self)

func _on_navigation_finished():
	if _current_state == State.PLAYER_COMMAND:
		if player_command_target_area == null:
			player_command_target_position = Vector2.ZERO; doi_trang_thai(State.IDLE)
		return
	if _current_state in [State.RESTING, State.TRADING]: return
	if _current_state == State.GHOST:
		visible = false; respawn_timer.start(60.0); GameEvents.respawn_started.emit(self); return
	if _current_state == State.NAVIGATING and is_instance_valid(_current_navigation_gate):
		_khi_den_cong(); return
	doi_trang_thai(State.IDLE)

func _khi_den_cong():
	if _current_route.is_empty(): doi_trang_thai(State.IDLE); return
	var conn: GateConnection = _current_route.pop_front()
	var area_node = world_node.get_node_or_null(conn.area_to)
	if is_instance_valid(area_node):
		movement_area = area_node; cap_nhat_ranh_gioi_di_chuyen()
		if player_command_target_area == movement_area:
			player_command_target_area = null; player_command_target_position = Vector2.ZERO
			doi_trang_thai(State.WANDER); return
		if not _current_route.is_empty(): bat_dau_buoc_di_chuyen_tiep()
		else: doi_trang_thai(State.WANDER)
	else:
		_current_route.clear(); doi_trang_thai(State.WANDER)

func bat_dau_buoc_di_chuyen_tiep():
	if _current_route.is_empty(): doi_trang_thai(State.IDLE); return
	var conn: GateConnection = _current_route[0]
	var gate = world_node.get_node_or_null(conn.gate_node)
	if is_instance_valid(gate):
		_current_navigation_gate = gate; nav_agent.target_position = _current_navigation_gate.global_position
		if _current_state != State.GHOST: doi_trang_thai(State.NAVIGATING)
	else:
		_current_route.clear(); doi_trang_thai(State.IDLE)

func tim_duong_di(start: Area2D, end: Area2D) -> Array:
	var q = [[start, []]]; var visited = {start: true}
	while not q.is_empty():
		var data = q.pop_front(); var area: Area2D = data[0]; var path: Array = data[1]
		if area == end: return path
		for conn in gate_connections:
			var from = world_node.get_node_or_null(conn.area_from)
			var to = world_node.get_node_or_null(conn.area_to)
			if from == area and is_instance_valid(to) and not visited.has(to):
				visited[to] = true; var new_path = path.duplicate(); new_path.append(conn)
				q.push_back([to, new_path])
	return []

func di_den_khu_vuc(target_area: Area2D):
	if not is_instance_valid(target_area) or movement_area == target_area:
		return

	# Tìm một điểm hợp lệ bên trong khu vực đích để bắt đầu di chuyển
	var target_shape: Shape2D = null
	var target_transform: Transform2D
	for child in target_area.get_children():
		if child is CollisionShape2D and is_instance_valid(child.shape):
			target_shape = child.shape
			target_transform = child.global_transform
			break
	
	if target_shape == null:
		push_error("Hero '%s' không tìm thấy ranh giới (CollisionShape2D) trong khu vực đích '%s'" % [name, target_area.name])
		return
	
	# Tạo một điểm ngẫu nhiên bên trong hình dạng ranh giới
	var rect = target_shape.get_rect()
	var random_point_local = Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	var random_point_global = target_transform * random_point_local
	
	# Tìm điểm trên lưới navigation gần nhất với điểm ngẫu nhiên
	var valid_nav_point = NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, random_point_global)

	# Gọi hàm ra lệnh tổng, truyền cả vị trí và khu vực đích
	# Đây là mấu chốt để hero biết nhiệm vụ sẽ hoàn thành khi nó bước vào khu vực mới
	issue_player_command(valid_nav_point, target_area)

func move_to_location_by_player(target_position: Vector2):
	if is_dead or _current_state in [State.RESTING, State.IN_BARRACKS]:
		return
	
	# Gọi hàm ra lệnh tổng, chỉ truyền vào vị trí (khu vực đích là null)
	# để Hero biết đây là lệnh di chuyển tới một điểm chính xác.
	issue_player_command(target_position, null)
# ============================================================================
# HỆ THỐNG CHIẾN ĐẤU (COMBAT)
# ============================================================================
func find_new_target_in_radius():
	if is_in_village_area(): doi_trang_thai(State.IDLE); return
	attackers = attackers.filter(func(m): return is_instance_valid(m) and not m.is_dead)
	if not attackers.is_empty():
		target_monster = attackers.pop_front(); doi_trang_thai(State.COMBAT); return
	var bodies = detection_area.get_overlapping_bodies()
	var closest = null; var min_dist = INF
	for body in bodies:
		if body.is_in_group("monsters") and not body.is_dead:
			var dist = global_position.distance_to(body.global_position)
			if dist < min_dist: min_dist = dist; closest = body
	if is_instance_valid(closest): target_monster = closest; doi_trang_thai(State.COMBAT)
	else: doi_trang_thai(State.WANDER)

func _on_detection_radius_body_entered(body):
	if _current_state in [State.COMBAT, State.PLAYER_COMMAND, State.TRADING] or is_dead or is_in_village_area(): return
	if body.is_in_group("monsters") and not body.is_dead: find_new_target_in_radius()
	
func _on_detection_radius_body_exited(body):
	if body == target_monster:
		target_monster = null
		if not is_dead: doi_trang_thai(State.IDLE)

func _on_attack_timer_timeout():
	if is_dead or _current_state != State.COMBAT or not is_instance_valid(target_monster): return
	if velocity.length() < 1.0:
		_is_attacking = true
		# Sửa lỗi: Sử dụng biến để gọi animation, thay vì một tên cố định
		animation_player.play(_current_attack_animation_name)
		
func execute_attack_on(target_node, use_magic: bool, skill_multiplier: float = 1.0):
	if not is_instance_valid(target_node) or target_node.is_dead: return
	var result = CombatUtils.hero_tan_cong_quai(self, target_node, use_magic, skill_multiplier)
	var text_pos = target_node.global_position - Vector2(0, 150)
	if result.is_miss: FloatingTextManager.show_text("MISS!!", Color.GRAY, text_pos)
	else:
		var text = str(result.damage); var color = Color.WHITE
		if skill_multiplier > 1.0: color = Color.ORANGE_RED
		if result.is_crit: color = Color.YELLOW; text += "!!"
		FloatingTextManager.show_text(text, color, text_pos, result.is_crit)
		if result.damage > 0: target_node.take_damage(result.damage, self)
		
func take_damage(amount: float, from_monster = null):
	if is_dead: return
	current_hp -= amount; _update_hp_display()
	if is_instance_valid(from_monster) and not from_monster in attackers: attackers.append(from_monster)
	_check_and_use_potions();
	if current_hp <= 0 and not is_dead: die()
		
func die():
	if is_dead: return
	is_dead = true; target_monster = null; velocity = Vector2.ZERO
	if is_instance_valid(attack_timer): attack_timer.stop()
	if is_instance_valid(state_timer): state_timer.stop()
	if is_instance_valid(skill_timer): skill_timer.stop()
	doi_trang_thai(State.DEAD); collision_shape.set_deferred("disabled", true)
	animation_player.play("Death"); death_timer = 2.0
		
# ============================================================================
# HÀM ỦY THÁC CHO COMPONENT (DELEGATION FUNCTIONS)
# ============================================================================
func setup(items, gold): hero_inventory.setup(items, gold)
func gain_exp(amount: int): hero_stats.gain_exp(amount)
func add_item(id: String, q: int = 1) -> bool: return hero_inventory.add_item(id, q)
func remove_item_from_inventory(id: String, q: int) -> bool: return hero_inventory.remove_item_from_inventory(id, q)
func add_gold(amount: int): hero_inventory.add_gold(amount)
func change_job(key: String): hero_stats.change_job(key)
func nang_cap_chi_so(name: String): hero_stats.nang_cap_chi_so(name)
func equip_from_inventory(index: int): hero_inventory.equip_from_inventory(index)
func unequip_item(key: String): hero_inventory.unequip_item(key)
func learn_or_upgrade_skill(id: String): hero_skills.learn_or_upgrade_skill(id)
func equip_skill(id: String): hero_skills.equip_skill(id)
func unequip_skill(id: String): hero_skills.unequip_skill(id)
func get_skill_level(id: String) -> int: return hero_skills.get_skill_level(id)
func is_skill_equipped(id: String) -> bool: return hero_skills.is_skill_equipped(id)
func check_skill_requirements(id: String) -> Dictionary: return hero_skills.check_skill_requirements(id)
func get_current_weapon_type() -> String: return hero_inventory.get_current_weapon_type()

# ============================================================================
# HÀM XỬ LÝ TÍN HIỆU & GIAO TIẾP
# ============================================================================
func _on_stats_updated():
	self.max_hp = hero_stats.max_hp; self.max_sp = hero_stats.max_sp
	if is_instance_valid(attack_timer): attack_timer.wait_time = hero_stats.attack_time
	current_hp = min(current_hp, self.max_hp); current_sp = min(current_sp, self.max_sp)
	_update_hp_display(); _update_sp_display(); _update_equipment_visuals()

func _on_equipment_changed(_new_equipment):
	# 1. Yêu cầu component Stats tính toán lại chỉ số (đã có, và đúng)
	hero_stats.update_secondary_stats()
	
	# 2. BỔ SUNG DÒNG CÒN THIẾU:
	# Yêu cầu "vẽ" lại hình ảnh trang bị trên người hero
	_update_equipment_visuals()

func heal_to_full():
	if is_instance_valid(hero_stats):
		current_hp = hero_stats.max_hp; current_sp = hero_stats.max_sp
		_update_hp_display(); _update_sp_display()
		
# ============================================================================
# LƯU & TẢI GAME (PHIÊN BẢN COMPONENT)
# ============================================================================
func save_data() -> Dictionary:
	var area_name = ""
	if is_instance_valid(movement_area): area_name = movement_area.name
	var data = {
		"name": name, "hero_name": hero_name, "base_appearance": base_appearance,
		"pos_x": global_position.x, "pos_y": global_position.y,
		"current_hp": current_hp, "current_sp": current_sp, "_current_state": _current_state,
		"current_area_name": area_name,
		"stats_data": hero_stats.save_data(), "inventory_data": hero_inventory.save_data(),
		"skills_data": hero_skills.save_data() }
	return data

func load_data(data: Dictionary): staged_data = data

func _apply_loaded_data(data: Dictionary):
	name = data.get("name", "Hero"); hero_name = data.get("hero_name", "Tan Binh")
	base_appearance = data.get("base_appearance", {})
	
	hero_stats.load_data(data.get("stats_data", {})); hero_inventory.load_data(data.get("inventory_data", {}))
	hero_skills.load_data(data.get("skills_data", {}))
	
	current_hp = data.get("current_hp", self.max_hp); current_sp = data.get("current_sp", self.max_sp)
	global_position.x = data.get("pos_x", 0); global_position.y = data.get("pos_y", 0)
	_current_state = data.get("_current_state", State.IDLE)
	
	var area_name = data.get("current_area_name", "")
	if not area_name.is_empty() and is_instance_valid(world_node):
		movement_area = world_node.find_child(area_name, true, false)
	_update_hp_display(); _update_sp_display()

# ============================================================================
# CÁC HÀM HỖ TRỢ & HÀNH VI CŨ
# ============================================================================
func _handle_passive_regeneration(delta: float):
	if is_dead or _current_state == State.COMBAT or not is_instance_valid(hero_stats): return
	var heal_r = (hero_stats.max_hp / 200.0) + (hero_stats.VIT / 5.0)
	var sp_r = (hero_stats.max_sp / 100.0) + (hero_stats.INTEL / 6.0)
	if current_hp < max_hp: current_hp = min(current_hp + heal_r * delta, max_hp); _update_hp_display()
	if current_sp < max_sp: current_sp = min(current_sp + sp_r * delta, max_sp); _update_sp_display()

func _check_and_use_potions():
	if is_dead or max_hp <= 0: return
	if (current_hp / max_hp) <= PlayerStats.auto_potion_hp_threshold:
		var slot = _tim_potion_slot_san_sang("hp")
		if not slot.is_empty(): dung_potion(slot); return
	if max_sp > 0 and (current_sp / max_sp) <= PlayerStats.auto_potion_sp_threshold:
		var slot = _tim_potion_slot_san_sang("sp")
		if not slot.is_empty(): dung_potion(slot)
		
func dung_potion(slot_key: String):
	var item_pkg = hero_inventory.equipment.get(slot_key)
	if not (item_pkg is Dictionary): return
	var data = ItemDatabase.get_item_data(item_pkg.get("id")); if data.is_empty(): return
	var stats = data.get("stats", {}); var heal = stats.get("heal_amount", 0); var sp_r = stats.get("sp_restore_amount", 0)
	var text_pos = global_position - Vector2(0, 100)
	if heal > 0:
		current_hp = min(current_hp + heal, max_hp); _update_hp_display()
		FloatingTextManager.show_text("+" + str(heal), Color.GREEN, text_pos)
	if sp_r > 0:
		current_sp = min(current_sp + sp_r, max_sp); _update_sp_display()
		FloatingTextManager.show_text("+" + str(sp_r), Color.BLUE, text_pos)
	_spawn_vfx("heal")
	item_pkg["quantity"] -= 1
	if item_pkg["quantity"] <= 0: hero_inventory.equipment[slot_key] = null
	var cd = data.get("cooldown", 5.0); _potion_cooldowns[slot_key] = cd
	potion_cooldown_started.emit(slot_key, cd); hero_inventory.equipment_changed.emit(hero_inventory.equipment)
	
func _tim_potion_slot_san_sang(type: String = "hp") -> String:
	for key in ["POTION_1", "POTION_2", "POTION_3"]:
		if _potion_cooldowns.get(key, 0.0) <= 0:
			var pkg = hero_inventory.equipment.get(key)
			if pkg is Dictionary:
				var data = ItemDatabase.get_item_data(pkg.get("id")); var stats = data.get("stats", {})
				if type == "hp" and stats.get("heal_amount", 0) > 0: return key
				elif type == "sp" and stats.get("sp_restore_amount", 0) > 0: return key
	return ""

func _update_potion_cooldowns(delta: float):
	for key in _potion_cooldowns:
		if _potion_cooldowns[key] > 0: _potion_cooldowns[key] -= delta
	
func _update_hp_display():
	if is_instance_valid(hp_bar): 
		hp_bar.max_value = self.max_hp; hp_bar.value = self.current_hp
	if is_instance_valid(hp_label): hp_label.text = "%d/%d" % [roundi(current_hp), roundi(max_hp)]
	hp_changed.emit(current_hp, max_hp)
	
func _update_sp_display(): sp_changed.emit(current_sp, max_sp)
	
func _update_equipment_visuals():
	# Phần 1: Áp dụng ngoại hình cơ bản (áo, mũ, mặt...)
	_apply_base_appearance()
	
	# Phần 2: Xử lý các trang bị khác (khiên, giáp...)
	# (Phần code xử lý khiên và các trang bị khác của bạn giữ nguyên ở đây)
	# Ví dụ:
	var visual_map: Dictionary = {
		"HelmetSprite": helmet_sprite, "ArmorSprite": armor_sprite, "GlovesLSprite": gloves_l_sprite,
		"GlovesRSprite": gloves_r_sprite, "BootsLSprite": boots_l_sprite, "BootsRSprite": boots_r_sprite,
	}
	if is_instance_valid(offhand_sprite):
		offhand_sprite.visible = false
		var shield_id = hero_inventory.equipment.get("OFF_HAND")
		if typeof(shield_id) == TYPE_STRING and not shield_id.is_empty():
			var data = ItemDatabase.get_item_data(shield_id)
			if data.get("equip_slot") == "OFF_HAND":
				var icon_path = data.get("icon_path", "")
				if not icon_path.is_empty() and FileAccess.file_exists(icon_path): offhand_sprite.texture = load(icon_path)
				offhand_sprite.visible = true
	for slot in ["HELMET", "ARMOR", "GLOVES", "BOOTS", "PANTS"]:
		var item_id = hero_inventory.equipment.get(slot)
		if typeof(item_id) == TYPE_STRING and not item_id.is_empty():
			var data = ItemDatabase.get_item_data(item_id)
			if data.has("visuals"):
				var visuals = data.get("visuals")
				if visuals is Array:
					for part in visuals: _apply_visual_data(part, visual_map)
				elif visuals is Dictionary: _apply_visual_data(visuals, visual_map)


	# --- PHẦN 3: XỬ LÝ VŨ KHÍ (ĐÃ VIẾT LẠI HOÀN TOÀN) ---
	if not is_instance_valid(weapon_container): return

	# 3.1. Luôn ẩn tất cả các sprite vũ khí trước
	for child in weapon_container.get_children():
		if child is Sprite2D:
			child.visible = false
	
	# 3.2. Lấy dữ liệu vũ khí đang trang bị
	var weapon_id = hero_inventory.equipment.get("MAIN_HAND")
	
	# 3.3. Nếu không trang bị vũ khí
	if not weapon_id:
		_current_attack_animation_name = "Attack" # Dùng animation mặc định
		return # Kết thúc hàm

	var weapon_data = ItemDatabase.get_item_data(weapon_id)
	if weapon_data.is_empty():
		_current_attack_animation_name = "Attack"
		return
		
	var weapon_type = weapon_data.get("weapon_type", "SWORD")
	var icon_path = weapon_data.get("icon_path", "")

	# 3.4. Dùng `match` để xử lý từng loại vũ khí, hiển thị sprite và gán animation
	match weapon_type:
		"SWORD":
			var sprite = weapon_container.get_node_or_null("SwordSprite")
			if is_instance_valid(sprite) and not icon_path.is_empty():
				sprite.texture = load(icon_path)
				sprite.visible = true
			_current_attack_animation_name = "Attack" # Sửa thành tên animation kiếm của bạn

		"BOW":
			var sprite = weapon_container.get_node_or_null("BowSprite")
			if is_instance_valid(sprite) and not icon_path.is_empty():
				sprite.texture = load(icon_path)
				sprite.visible = true
			_current_attack_animation_name = "Shooting" # Sửa thành tên animation bắn cung của bạn
			
		"STAFF":
			var sprite = weapon_container.get_node_or_null("StaffSprite")
			if is_instance_valid(sprite) and not icon_path.is_empty():
				sprite.texture = load(icon_path)
				sprite.visible = true
			_current_attack_animation_name = "Attack" # Sửa thành tên animation dùng gậy của bạn

		"DAGGER":
			var sprite = weapon_container.get_node_or_null("DaggerSprite")
			if is_instance_valid(sprite) and not icon_path.is_empty():
				sprite.texture = load(icon_path)
				sprite.visible = true
			_current_attack_animation_name = "Attack" # Sửa thành tên animation dao găm của bạn
		
		_: # Trường hợp mặc định nếu không khớp
			_current_attack_animation_name = "Attack"

func _apply_visual_data(data: Dictionary, map: Dictionary):
	var s_name = data.get("target_sprite", ""); var path = data.get("texture_path", "")
	if map.has(s_name):
		var node = map[s_name]
		if is_instance_valid(node):
			if not path.is_empty() and FileAccess.file_exists(path):
				node.texture = load(path); node.visible = true
			else: node.visible = false

func _apply_base_appearance():
	var face = base_appearance.get("face", "")
	if is_instance_valid(face_sprite) and not face.is_empty(): face_sprite.texture = load(face)
	var helmet = base_appearance.get("helmet", "")
	if is_instance_valid(helmet_sprite):
		if not helmet.is_empty() and FileAccess.file_exists(helmet): helmet_sprite.texture = load(helmet); helmet_sprite.visible = true
		else: helmet_sprite.visible = false
	var armor = base_appearance.get("armor_set", {})
	if not armor.is_empty():
		var p = armor.get("armor_sprite", "")
		if not p.is_empty() and is_instance_valid(armor_sprite): armor_sprite.texture = load(p)
		p = armor.get("gloves_l_sprite", "")
		if not p.is_empty() and is_instance_valid(gloves_l_sprite): gloves_l_sprite.texture = load(p)
		p = armor.get("gloves_r_sprite", "")
		if not p.is_empty() and is_instance_valid(gloves_r_sprite): gloves_r_sprite.texture = load(p)
		p = armor.get("boots_l_sprite", "")
		if not p.is_empty() and is_instance_valid(boots_l_sprite): boots_l_sprite.texture = load(p)
		p = armor.get("boots_r_sprite", "")
		if not p.is_empty() and is_instance_valid(boots_r_sprite): boots_r_sprite.texture = load(p)

func _update_animation():
	if _is_attacking: return
	var anim = "Idle"
	if velocity.length() > 5.0: anim = "Walk"
	if animation_player.current_animation != anim: animation_player.play(anim)

func _update_flip_direction():
	var x = abs(skeleton_2d.scale.x)
	if is_instance_valid(target_monster):
		if target_monster.global_position.x < global_position.x: skeleton_2d.scale.x = -x
		else: skeleton_2d.scale.x = x
	elif abs(velocity.x) > 0.1:
		if velocity.x < 0: skeleton_2d.scale.x = -x
		else: skeleton_2d.scale.x = x

func _handle_ghost_physics(delta: float):
	if death_timer > 0:
		death_timer -= delta
		if death_timer <= 0:
			doi_trang_thai(State.GHOST); animation_player.play("Walk"); remove_from_group("heroes")
			detection_area.monitoring = false; modulate = Color(1, 1, 1, 0.5)
			if is_instance_valid(PlayerStats.ghost_respawn_point):
				nav_agent.target_position = PlayerStats.ghost_respawn_point.global_position
	if _current_state == State.GHOST:
		if not nav_agent.is_navigation_finished():
			velocity = global_position.direction_to(nav_agent.get_next_path_position()) * speed
		else: velocity = Vector2.ZERO
		if animation_player.current_animation != "Walk": animation_player.play("Walk")
	else: velocity = Vector2.ZERO
	move_and_slide(); _update_flip_direction()

func _on_animation_finished(anim_name):
	if is_dead: return
	if anim_name.begins_with("Attack"):
		_is_attacking = false; has_dealt_damage_this_attack = false
		if _current_state != State.COMBAT: animation_player.play("Idle")

func _on_respawn_timer_timeout():
	is_dead = false; add_to_group("heroes"); visible = true
	current_hp = 1; current_sp = 1; _update_hp_display()
	if is_instance_valid(PlayerStats.ghost_respawn_point):
		global_position = PlayerStats.ghost_respawn_point.global_position
	modulate = Color(1, 1, 1, 1); collision_shape.disabled = false
	detection_area.monitoring = true
	if is_instance_valid(PlayerStats.village_boundary): movement_area = PlayerStats.village_boundary
	doi_trang_thai(State.IDLE); GameEvents.respawn_finished.emit(self)

func _on_inn_room_chosen(hero, inn_level):
	if hero != self: return
	var data = GameDataManager.get_inn_level_data(inn_level)
	if hero_inventory.gold < data["cost"]: return
	hero_inventory.add_gold(-data["cost"])
	doi_trang_thai(State.RESTING); hide()
	started_resting.emit(self, data["heal_percent"])

func finish_resting():
	heal_to_full(); show(); doi_trang_thai(State.IDLE)
	finished_resting.emit(self)
	
func is_in_village_area() -> bool:
	return is_instance_valid(movement_area) and movement_area.name == "Village_Boundary"

func cap_nhat_ranh_gioi_di_chuyen() -> bool:
	if not is_instance_valid(movement_area): _boundary_shape = null; return false
	for child in movement_area.get_children():
		if child is CollisionShape2D and is_instance_valid(child.shape):
			_boundary_shape = child.shape; _boundary_transform = child.global_transform
			return true
	_boundary_shape = null; return false

func change_hero_face(new_face_texture: Texture2D) -> void:
	if is_instance_valid(face_sprite): face_sprite.texture = new_face_texture
	
func _shoot_projectile(projectile_scene: PackedScene, is_magic: bool = false):
	if not is_instance_valid(target_monster) or not projectile_scene: return
	var p = projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	if p.has_method("start"):
		p.start(global_position, target_monster, self, 1000.0, is_magic)
		
func _spawn_vfx(animation_name: String, offset_y: float = -60.0, p_scale: Vector2 = Vector2.ONE):
	# Kiểm tra xem VFX_Scene đã được preload chưa
	if not VFX_Scene: return

	var vfx_instance = VFX_Scene.instantiate()
	add_child(vfx_instance)
	
	vfx_instance.scale = p_scale
	vfx_instance.position.y = offset_y
	vfx_instance.play_effect(animation_name)
