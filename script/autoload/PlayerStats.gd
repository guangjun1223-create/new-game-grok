# PlayerStats.gd
extends Node

const VFX_scene = preload("res://Scene/VFX/vfx_player.tscn")
const DIAMOND_COST_FOR_SUMMON = 100

#signal inventory_changed
signal gold_changed(new_gold_amount)
signal player_stats_changed
signal warehouse_changed
signal village_level_changed(new_level)
signal hero_count_changed

const NPC_UPGRADE_ORDER = ["inn", "AlchemistNPC", "PotionSellerNPC", "blacksmith", "EquipmentSellerNPC"]

var npc_levels = {
	"inn": 1,
	"blacksmith": 1,
	"AlchemistNPC": 1,
	"PotionSellerNPC": 1,
	"EquipmentSellerNPC": 1
}

const SAVE_FILE_PATH = "user://savegame.dat"  
var player_name: String = "người chơi mới"
var should_load_on_enter: bool = false
var player_level: int = 1 # << THÊM DÒNG NÀY VÀO
var village_level: int = 1

const BARRACKS_SIZE: int = 50
var hero_roster: Array[Hero] = []

var hero_scene: PackedScene
var ui_controller_ref: Node 
var camera_ref: Camera2D

var gold: int = 1000
var auto_potion_hp_threshold: float = 0.5 # Mặc định: tự dùng HP Potion khi máu dưới 50%
var auto_potion_sp_threshold: float = 0.3 # Mặc định: tự dùng SP Potion khi SP dưới 30%

var shop_npc_ref: Node = null
var blacksmith_ref: Node = null
var alchemist_ref: Node = null
var inn_ref: Node = null 
var potion_seller_ref: Node = null
var job_changer_ref: Node = null
var equipment_seller_ref: Node = null

var gate_connections: Array[GateConnection] = []
var hero_container: Node
var village_boundary: Area2D
var hero_spawn_point: Marker2D
var ghost_respawn_point: Marker2D
var world_node: Node2D # BIẾN MỚI: Để lưu tham chiếu đến World
var inventory: Array = [] # Mảng chính lưu trữ dữ liệu túi đồ
const INVENTORY_SIZE: int = 20 # Sức chứa tối đa của túi đồ

var player_gold: int = 1000      # Vàng trong kho
var player_diamonds: int = 500    # Kim cương
var warehouse: Array = []        # Mảng chứa đồ trong Nhà kho
const WAREHOUSE_SIZE: int = 500  # Sức chứa của Nhà kho
var current_inn_level: int = 1


func register_gate_connections(connections: Array[GateConnection]):
	gate_connections = connections

func _ready():
	hero_scene = load("res://Scene/hero.tscn")
	# Chờ một frame để đảm bảo tất cả các node con (như UI) đã sẵn sàng
	await get_tree().process_frame
	
	# Khởi tạo các tham chiếu như cũ
	PlayerStats.register_gate_connections(gate_connections)
	
	# === PHẦN MỚI THÊM VÀO ===
	# Kiểm tra xem có lệnh "tải game" đang chờ không
	if PlayerStats.should_load_on_enter:
		PlayerStats.load_game()
		# Reset lại cờ hiệu sau khi đã thực hiện xong
		PlayerStats.should_load_on_enter = false 
	
	if warehouse.is_empty():
		print("PlayerStats: Khoi tao Nha kho lan dau.")
		warehouse.resize(WAREHOUSE_SIZE)
		
	
func initialize_world_references():
	var main_scene_root = get_tree().current_scene
	
	if not main_scene_root is Node2D:
		push_error("Loi initialize_world_references: Scene hien tai khong phai Node2D!")
		return
	
	world_node = main_scene_root
	camera_ref = main_scene_root.get_node_or_null("Camera2D")
	if not is_instance_valid(camera_ref):
		push_error("Loi: PlayerStats khong tim thay MainCamera trong world.tscn!")
	
	hero_container = main_scene_root.find_child("HeroContainer", true, false)
	village_boundary = main_scene_root.find_child("Village_Boundary", true, false)
	hero_spawn_point = main_scene_root.find_child("HeroSpawnPoint", true, false)
	ghost_respawn_point = main_scene_root.find_child("GhostRespawnPoint", true, false)
	
	if not is_instance_valid(hero_container):
		push_error("LỖI: PlayerStats không tìm thấy node 'HeroContainer' trong world!")
	hero_count_changed.emit()

# THAY THẾ TOÀN BỘ HÀM CŨ BẰNG PHIÊN BẢN NÀY
func trieu_hoi_hero():
	# --- BƯỚC 1: KIỂM TRA ĐIỀU KIỆN CHUNG ---
	# Luôn kiểm tra chỗ trống trong doanh trại trước tiên.
	if hero_roster.size() >= BARRACKS_SIZE + get_max_heroes():
		print("Doanh trại và nhà chính đã đầy! Không thể triệu hồi.")
		# Thông báo cho UI biết là không thể triệu hồi (tùy chọn)
		# get_tree().call_group("ui_elements", "show_notification", "Doanh trại đầy!")
		return

	# --- BƯỚC 2: KIỂM TRA TÀI NGUYÊN VÀ TRIỆU HỒI ---
	var summon_success = false
	
	# Ưu tiên 1: Kiểm tra Cuộn Giấy Triệu Hồi
	if get_item_quantity_in_warehouse("summon_scroll") > 0:
		print(">>> Sử dụng Cuộn Giấy Triệu Hồi...")
		remove_item_from_warehouse("summon_scroll", 1)
		summon_success = true
	
	# Ưu tiên 2: Nếu không có cuộn giấy, kiểm tra Kim Cương
	elif player_diamonds >= DIAMOND_COST_FOR_SUMMON:
		print(">>> Hết cuộn giấy, sử dụng %d Kim Cương..." % DIAMOND_COST_FOR_SUMMON)
		# Hàm spend_player_diamonds sẽ trừ tiền và trả về true nếu thành công
		if spend_player_diamonds(DIAMOND_COST_FOR_SUMMON):
			summon_success = true
	
	# --- BƯỚC 3: XỬ LÝ KẾT QUẢ ---
	if summon_success:
		# Nếu một trong hai tài nguyên trên được sử dụng thành công
		# thì mới bắt đầu tạo hero.
		var new_hero = _tao_mot_hero_moi()
		
		# Thêm hero vào game và lưu lại
		hero_roster.append(new_hero)
		deploy_hero(new_hero)
		save_game()
		
		print(">>> Triệu hồi thành công hero: %s" % new_hero.name)
	else:
		# Nếu không có bất kỳ tài nguyên nào đủ
		print(">>> Không đủ Cuộn Giấy Triệu Hồi hoặc Kim Cương.")
		# Thông báo cho UI biết là không đủ tài nguyên (tùy chọn)
		# get_tree().call_group("ui_elements", "show_notification", "Không đủ tài nguyên!")

func _tao_mot_hero_moi() -> Hero:
	var new_hero = hero_scene.instantiate()
	var stats_component: HeroStats = new_hero.get_node("HeroStats")
	var inventory_component: HeroInventory = new_hero.get_node("HeroInventory")
	var skills_component: HeroSkills = new_hero.get_node("HeroSkills")
	
	stats_component.hero = new_hero
	inventory_component.hero = new_hero
	skills_component.hero = new_hero
	
	new_hero.world_node = world_node
	new_hero.gate_connections = gate_connections
	# _ui_controller sẽ được gán sau nếu cần, hoặc bạn có thể gán trực tiếp
	# new_hero._ui_controller = ui_controller_ref

	# --- TẠO CHỈ SỐ GỐC ---
	var str_co_ban = randi_range(1, 5)
	var agi_co_ban = randi_range(1, 5)
	var vit_co_ban = randi_range(1, 5)
	var int_co_ban = randi_range(1, 5)
	var dex_co_ban = randi_range(1, 5)
	var luk_co_ban = randi_range(1, 5)
	
	var tong_diem = str_co_ban + agi_co_ban + vit_co_ban + int_co_ban + dex_co_ban + luk_co_ban
	var do_hiem: String
	var mod_tang_truong: float

	if tong_diem < 30:
		var roll_do_hiem = randf()
		if roll_do_hiem < 0.4: do_hiem = "F"
		elif roll_do_hiem < 0.7: do_hiem = "D"
		elif roll_do_hiem < 0.85: do_hiem = "C"
		elif roll_do_hiem < 0.95: do_hiem = "B"
		elif roll_do_hiem < 0.99: do_hiem = "A"
		else: do_hiem = "S"
		mod_tang_truong = 0.0 # Độ hiếm thấp không có mod tăng trưởng
	else:
		var roll_do_hiem = randf()
		if roll_do_hiem < 0.5: do_hiem = "SS"
		elif roll_do_hiem < 0.8: do_hiem = "SSS"
		elif roll_do_hiem < 0.95: do_hiem = "SSR"
		else: do_hiem = "UR"
		mod_tang_truong = randf_range(0.1, 0.5)
	
	var job_key = "Novice"
	var du_lieu_nghe = GameDataManager.get_hero_definition(job_key)

	# --- TẠO NGOẠI HÌNH ---
	var all_faces = AppearanceDatabase.get_all_faces()
	var all_head = AppearanceDatabase.get_all_head()
	var all_armor_sets = AppearanceDatabase.get_all_armor_sets()
	var hero_gender = ["male", "female"].pick_random()
	var valid_faces = all_faces.filter(func(face): return face.get("gender", "unisex") in [hero_gender, "unisex"])
	var valid_head = all_head.filter(func(head): return head.get("gender", "unisex") in [hero_gender, "unisex"])
	var valid_armor_sets = all_armor_sets.filter(func(aset): return aset.get("gender", "unisex") in [hero_gender, "unisex"])

	var chosen_face_data = valid_faces.pick_random() if not valid_faces.is_empty() else all_faces.pick_random()
	var chosen_head_data = valid_head.pick_random() if not valid_head.is_empty() else all_head.pick_random()
	var chosen_armor_set_data = valid_armor_sets.pick_random() if not valid_armor_sets.is_empty() else all_armor_sets.pick_random()
	
	var new_hero_appearance = {
		"face": chosen_face_data.get("path"),
		"head": chosen_head_data.get("path"),
		"armor_set": chosen_armor_set_data
	}
	
	# ======================================================================
	# === PHẦN SỬA LỖI QUAN TRỌNG: GÁN DỮ LIỆU VÀO ĐÚNG COMPONENT CON ===
	# ======================================================================

	# 1. Gán dữ liệu cho "Nhạc trưởng" hero.gd
	var ten_ngau_nhien = GameDataManager.tao_ten_ngau_nhien()
	new_hero.hero_name = ten_ngau_nhien
	new_hero.name = "%s (%s)" % [ten_ngau_nhien, do_hiem]
	new_hero.base_appearance = new_hero_appearance

	# 2. Gán dữ liệu cho component HeroStats
	# Gán chỉ số Gacha
	stats_component.str_co_ban = str_co_ban
	stats_component.agi_co_ban = agi_co_ban
	stats_component.vit_co_ban = vit_co_ban
	stats_component.int_co_ban = int_co_ban
	stats_component.dex_co_ban = dex_co_ban
	stats_component.luk_co_ban = luk_co_ban
	stats_component.str_tang_truong = du_lieu_nghe.get("str_growth", 0.0) + mod_tang_truong
	stats_component.agi_tang_truong = du_lieu_nghe.get("agi_growth", 0.0) + mod_tang_truong
	stats_component.vit_tang_truong = du_lieu_nghe.get("vit_growth", 0.0) + mod_tang_truong
	stats_component.int_tang_truong = du_lieu_nghe.get("int_growth", 0.0) + mod_tang_truong
	stats_component.dex_tang_truong = du_lieu_nghe.get("dex_growth", 0.0) + mod_tang_truong
	stats_component.luk_tang_truong = du_lieu_nghe.get("luk_growth", 0.0) + mod_tang_truong
	stats_component.job_key = job_key
	# Gán nghề
	stats_component.initialize_stats()
	
	# 4. Cập nhật HP/SP cho "Nhạc trưởng"
	new_hero.current_hp = stats_component.max_hp
	new_hero.current_sp = stats_component.max_sp
	
	# 5. Yêu cầu component HeroInventory thiết lập đồ và vàng
	var starting_items = [{"id": "simple_sword", "quantity": 1}, {"id": "magic_staff", "quantity": 1}, {"id": "long_bow", "quantity": 1}]
	var starting_gold = 50
	inventory_component.setup(starting_items, starting_gold)
	
	return new_hero

func _tao_ngoai_hinh_ngau_nhien() -> Dictionary:
	# BƯỚC 1: LẤY DỮ LIỆU TỪ ĐÚNG NƠI (AppearanceDatabase)
	var all_faces = AppearanceDatabase.get_all_faces()
	var all_head = AppearanceDatabase.get_all_head()
	var all_armor_sets = AppearanceDatabase.get_all_armor_sets()

	# Kiểm tra nếu một trong các danh sách bị rỗng thì thoát để tránh lỗi
	if all_faces.is_empty() or all_head.is_empty() or all_armor_sets.is_empty():
		push_error("Không thể tạo ngoại hình vì một trong các danh sách (faces, head, armor_sets) bị rỗng.")
		return {}

	# BƯỚC 2: QUYẾT ĐỊNH GIỚI TÍNH NGẪU NHIÊN CHO HERO
	var hero_gender = ["male", "female"].pick_random()
	print("[DEBUG] Giới tính ngẫu nhiên cho Hero: ", hero_gender)

	# BƯỚC 3: LỌC DANH SÁCH CÁC BỘ PHẬN THEO GIỚI TÍNH
	var valid_faces = all_faces.filter(func(face): return face.get("gender", "unisex") == hero_gender or face.get("gender", "unisex") == "unisex")
	var valid_head = all_head.filter(func(head): return head.get("gender", "unisex") == hero_gender or head.get("gender", "unisex") == "unisex")
	var valid_armor_sets = all_armor_sets.filter(func(aset): return aset.get("gender", "unisex") == hero_gender or aset.get("gender", "unisex") == "unisex")

	# BƯỚC 4: CHỌN NGẪU NHIÊN TỪ DANH SÁCH ĐÃ LỌC (phòng trường hợp danh sách rỗng thì dùng lại danh sách gốc)
	var chosen_face_data = valid_faces.pick_random() if not valid_faces.is_empty() else all_faces.pick_random()
	var chosen_head_data = valid_head.pick_random() if not valid_head.is_empty() else all_head.pick_random()
	var chosen_armor_set_data = valid_armor_sets.pick_random() if not valid_armor_sets.is_empty() else all_armor_sets.pick_random()

	# BƯỚC 5: TẠO DICTIONARY NGOẠI HÌNH CUỐI CÙNG
	
	var final_armor_set = {
		"set_name": chosen_armor_set_data.get("set_name"),
		"armor_sprite": chosen_armor_set_data.get("armor_sprite"),
		"gloves_l_sprite": chosen_armor_set_data.get("gloves_l_sprite"),
		"gloves_r_sprite": chosen_armor_set_data.get("gloves_r_sprite"),
		"boots_l_sprite": chosen_armor_set_data.get("boots_l_sprite"),
		"boots_r_sprite": chosen_armor_set_data.get("boots_r_sprite"),
	}


	var final_appearance = {
		"face": chosen_face_data.get("path"),
		"head": chosen_head_data.get("path"),
		"armor_set": final_armor_set
	}
	
	print("\n--- [DEBUG] PlayerStats đã tạo bộ ngoại hình ngẫu nhiên cho Hero mới: ---\n", final_appearance, "\n------------------------------------------------------------------\n")

	return final_appearance

func add_gold(amount: int):
	if amount <= 0: return # Không làm gì nếu số vàng cộng vào là số âm hoặc 0
	
	gold += amount
	gold_changed.emit(gold) # Phát tín hiệu báo cho UI cập nhật
	print(">>> Người chơi nhận được %d vàng. Tổng cộng: %d" % [amount, gold])
	
	
func register_ui_controller(ui_node: Node):
	ui_controller_ref = ui_node
	print(">>> PlayerStats: Da dang ky UIController thanh cong!")
	
func save_game():
	var hero_roster_data = []
	for hero in hero_roster:
		if is_instance_valid(hero):
			hero_roster_data.append(hero.save_data())

	# Chuẩn bị một "gói dữ liệu tổng" để lưu
	var game_data = {
		"player_name": player_name,
		"player_gold": player_gold,
		"player_diamonds": player_diamonds,
		"player_warehouse": warehouse,
		"village_level": village_level,
		"npc_levels": npc_levels,
		
		"auto_potion_hp_threshold": auto_potion_hp_threshold, # <--- THÊM DÒNG NÀY
		"auto_potion_sp_threshold": auto_potion_sp_threshold, # <--- THÊM DÒNG NÀY
		
		"camera_pos_x": camera_ref.global_position.x if is_instance_valid(camera_ref) else 0.0,
		"camera_pos_y": camera_ref.global_position.y if is_instance_valid(camera_ref) else 0.0,
		
		"hero_roster_data": hero_roster_data
	}

	# Bây giờ, chúng ta có thể an toàn lặp và append dữ liệu vào mảng đã tồn tại
	var json_string = JSON.stringify(game_data, "\t") # Dùng "\t" để file save dễ đọc hơn
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	
	print(">>> GAME SAVED! (Hệ thống Roster mới)")
	
func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("LOAD FAILED: Khong tim thay file luu!")
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		push_error("Lỗi nghiêm trọng: Dữ liệu trong file lưu bị lỗi!")
		return
	var game_data: Dictionary = parse_result

	# Xóa tất cả các hero cũ trên sân và trong danh sách
	for hero in hero_roster:
		if is_instance_valid(hero):
			hero.queue_free()
	hero_roster.clear()
	
	# Khôi phục dữ liệu của Người Chơi
	player_name = game_data.get("player_name", "Nguoi Choi Moi")
	player_gold = game_data.get("player_gold", 1000)
	warehouse = game_data.get("player_warehouse", [])
	village_level = game_data.get("village_level", 1)
	var default_npc_levels = { "inn": 1, "blacksmith": 1, "AlchemistNPC": 1, "PotionSellerNPC": 1, "EquipmentSellerNPC": 1 }
	npc_levels = game_data.get("npc_levels", default_npc_levels)
	
	# ======================= PHẦN CẬP NHẬT =======================
	# Tải cài đặt tự dùng Potion, nếu không có thì dùng giá trị mặc định
	auto_potion_hp_threshold = game_data.get("auto_potion_hp_threshold", 0.5) # <--- THÊM DÒNG NÀY
	auto_potion_sp_threshold = game_data.get("auto_potion_sp_threshold", 0.3) # <--- THÊM DÒNG NÀY
	# =============================================================
	
	# Tái tạo lại từng Hero từ dữ liệu và thêm vào roster
	var saved_roster_data = game_data.get("hero_roster_data", [])
	for hero_data in saved_roster_data:
		var new_hero = hero_scene.instantiate()
		new_hero.world_node = world_node
		new_hero.gate_connections = gate_connections
		new_hero._ui_controller = ui_controller_ref
		
		# Nạp dữ liệu vào đối tượng Hero
		new_hero.load_data(hero_data)
		# Thêm đối tượng Hero hoàn chỉnh vào danh sách
		hero_roster.append(new_hero)
	
	# Sau khi có đầy đủ roster, "triển khai" những Hero đang hoạt động
	for hero in hero_roster:
		if hero._current_state != Hero.State.IN_BARRACKS and hero._current_state != Hero.State.GHOST:
			deploy_hero(hero)

	# Cập nhật camera và phát tín hiệu
	if is_instance_valid(camera_ref):
		var cam_x = game_data.get("camera_pos_x", 0)
		var cam_y = game_data.get("camera_pos_y", 0)
		camera_ref.global_position = Vector2(cam_x, cam_y)

	
	update_npc_unlock_state()
	player_stats_changed.emit()
	warehouse_changed.emit()
	village_level_changed.emit(village_level)
	hero_count_changed.emit() # Rất quan trọng để cập nhật UI số lượng hero

	print(">>> GAME LOADED! (Hệ thống Roster mới)")

func delete_save_file():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_FILE_PATH.replace("user://", ""))
			print("Da xoa file save cu.")

# Hàm _notification được Godot tự động gọi khi có sự kiện hệ thống
func _notification(what):
	# Dùng hằng số chính xác của Godot 4
	if what == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		print("Phat hien nguoi choi thoat game, tu dong luu...")
		
		# Chỉ lưu nếu chúng ta đang ở trong màn hình game chính
		if get_tree().current_scene.scene_file_path == "res://Scene/world.tscn":
			save_game()
			
		# Cho phép game thoát sau khi đã lưu
		get_tree().quit()

func add_item_to_warehouse(item_data_or_id, quantity_to_add: int = 1) -> bool:
	var item_id: String
	var item_data: Dictionary

	# Tự động nhận diện xem đang nhận vào ID hay một Dictionary đầy đủ
	if typeof(item_data_or_id) == TYPE_STRING:
		item_id = item_data_or_id
		item_data = ItemDatabase.get_item_data(item_id)
	elif typeof(item_data_or_id) == TYPE_DICTIONARY:
		item_data = item_data_or_id
		item_id = item_data["id"]
	else:
		push_error("add_item_to_warehouse: Du lieu vao khong hop le.")
		return false

	if item_data.is_empty():
		push_error("add_item_to_warehouse: Khong tim thay du lieu cho item ID '%s'" % item_id)
		return false

	var is_stackable = item_data.get("is_stackable", false)

	# XỬ LÝ TRANG BỊ (KHÔNG XẾP CHỒNG)
	if not is_stackable:
		for i in range(warehouse.size()):
			if warehouse[i] == null:
				warehouse[i] = item_data # Lưu cả dictionary vào slot
				warehouse_changed.emit()
				return true
		return false # Hết chỗ

	# XỬ LÝ VẬT PHẨM THƯỜNG (XẾP CHỒNG ĐƯỢC)
	var max_stack = item_data.get("max_stack_size", 999)
	var quantity_left = quantity_to_add
	var item_added_somewhere = false

	# Vòng 1: Tìm các chồng có sẵn để cộng dồn
	for i in range(warehouse.size()):
		var slot = warehouse[i]
		if slot and slot["id"] == item_id and slot["quantity"] < max_stack:
			var can_add_here = max_stack - slot["quantity"]
			var add_amount = min(quantity_left, can_add_here)
			slot["quantity"] += add_amount
			quantity_left -= add_amount
			item_added_somewhere = true
			if quantity_left <= 0: break

	# Vòng 2: Nếu vẫn còn, tìm ô trống
	if quantity_left > 0:
		for i in range(warehouse.size()):
			if warehouse[i] == null:
				var add_amount = min(quantity_left, max_stack)
				warehouse[i] = {"id": item_id, "quantity": add_amount}
				quantity_left -= add_amount
				item_added_somewhere = true
				if quantity_left <= 0: break

	if item_added_somewhere:
		warehouse_changed.emit()

	return quantity_left <= 0

func add_gold_to_player(amount: int):
	if amount <= 0: return
	player_gold += amount
	player_stats_changed.emit()

func add_diamonds_to_player(amount: int):
	if amount <= 0: return
	player_diamonds += amount
	player_stats_changed.emit()

func register_shop_npc(npc_node: Node):
	shop_npc_ref = npc_node
	print(">>> PlayerStats: Da dang ky ShopNPC thanh cong!")

# Hàm để các script khác hỏi vị trí của NPC
func get_shop_npc_position() -> Vector2:
	if is_instance_valid(shop_npc_ref):
		return shop_npc_ref.global_position
	else:
		# Trả về một vị trí an toàn nếu không tìm thấy NPC
		push_error("Loi: Khong tim thay tham chieu ShopNPC trong PlayerStats!")
		return Vector2.ZERO 

func register_inn(inn_node: Node):
	inn_ref = inn_node
	print(">>> PlayerStats: Da dang ky Nha Tro (Inn) thanh cong!")

# Hàm để các script khác hỏi vị trí cửa vào của Inn
func get_inn_entrance_position() -> Vector2:
	if is_instance_valid(inn_ref) and inn_ref.has_node("InnEntranceArea"):
		return inn_ref.get_node("InnEntranceArea").global_position
	else:
		push_error("Loi: Khong tim thay tham chieu Inn hoac InnEntranceArea!")
		return Vector2.ZERO

func remove_item_from_warehouse(item_id: String, quantity_to_remove: int = 1) -> bool:
	var quantity_left_to_remove = quantity_to_remove
	
	# Vòng lặp từ cuối lên để việc xóa không làm ảnh hưởng đến chỉ số của mảng
	for i in range(warehouse.size() - 1, -1, -1):
		var slot_data = warehouse[i]
		
		# Bỏ qua các ô trống hoặc các item không đúng ID
		if not slot_data or slot_data.get("id") != item_id:
			continue

		# --- LOGIC SỬA LỖI ---
		# Lấy dữ liệu gốc của item để kiểm tra xem nó có xếp chồng được không
		var base_item_data = ItemDatabase.get_item_data(item_id)
		var is_stackable = base_item_data.get("is_stackable", false)
		
		if is_stackable:
			# Nếu là item xếp chồng được, nó chắc chắn có key "quantity"
			var remove_amount = min(quantity_left_to_remove, slot_data["quantity"])
			slot_data["quantity"] -= remove_amount
			quantity_left_to_remove -= remove_amount
			
			# Nếu số lượng trong ô về 0, làm trống ô đó
			if slot_data["quantity"] <= 0:
				warehouse[i] = null
		else:
			# Nếu là trang bị (không xếp chồng), coi như số lượng là 1
			# Chỉ xóa khi chúng ta vẫn cần xóa item (quantity_left_to_remove > 0)
			if quantity_left_to_remove > 0:
				warehouse[i] = null # Xóa toàn bộ trang bị khỏi ô
				quantity_left_to_remove -= 1
		
		# Nếu đã xóa đủ số lượng yêu cầu, thoát khỏi vòng lặp
		if quantity_left_to_remove <= 0:
			break
	
	warehouse_changed.emit()
	
	# Trả về true nếu đã xóa đủ (quantity_left == 0), ngược lại trả về false
	return quantity_left_to_remove <= 0
	
func can_craft(recipe: Dictionary) -> bool:
	var materials_needed = recipe.get("materials", [])
	
	# Nếu công thức không cần nguyên liệu, luôn có thể chế tạo
	if materials_needed.is_empty():
		return true
		
	# Lặp qua từng nguyên liệu yêu cầu
	for material in materials_needed:
		var required_item_id = material["item_id"]
		var required_quantity = material["quantity"]
		var quantity_in_warehouse = 0
		
		# Đếm xem trong kho có bao nhiêu nguyên liệu này
		for item_in_warehouse in warehouse:
			if item_in_warehouse and item_in_warehouse["id"] == required_item_id:
				quantity_in_warehouse += item_in_warehouse["quantity"]
				
		# Nếu số lượng có trong kho ít hơn số lượng yêu cầu, trả về false ngay lập tức
		if quantity_in_warehouse < required_quantity:
			return false
			
	# Nếu lặp hết mà không thiếu nguyên liệu nào, trả về true
	return true

func get_max_craftable_amount(recipe: Dictionary) -> int:
	var materials_needed = recipe.get("materials", [])
	
	if materials_needed.is_empty():
		# Nếu không cần nguyên liệu, có thể chế tạo vô hạn (hoặc một số rất lớn)
		return 9999 
		
	var max_amount = INF # Bắt đầu với một con số vô cực
	
	# Lặp qua từng nguyên liệu yêu cầu
	for material in materials_needed:
		var required_item_id = material["item_id"]
		var required_quantity_per_item = material["quantity"]
		var quantity_in_warehouse = 0
		
		# Đếm số lượng nguyên liệu có trong kho
		for item_in_warehouse in warehouse:
			if item_in_warehouse and item_in_warehouse["id"] == required_item_id:
				quantity_in_warehouse += item_in_warehouse["quantity"]
		
		# Tính xem với nguyên liệu này, có thể làm được bao nhiêu sản phẩm
		var possible_amount = quantity_in_warehouse / required_quantity_per_item
		
		max_amount = min(max_amount, possible_amount)
		
	return max_amount

func register_blacksmith_npc(npc_node: Node):
	blacksmith_ref = npc_node

# Hàm để Người Điều Chế Thuốc "báo danh"
func register_alchemist_npc(npc_node: Node):
	alchemist_ref = npc_node

# Hàm để các script khác hỏi vị trí của Thợ Rèn
func get_blacksmith_position() -> Vector2:
	if is_instance_valid(blacksmith_ref):
		return blacksmith_ref.get_node("InteractionArea").global_position
	return Vector2.ZERO 

# Hàm để các script khác hỏi vị trí của Người Điều Chế Thuốc
func get_alchemist_position() -> Vector2:
	if is_instance_valid(alchemist_ref):
		return alchemist_ref.get_node("InteractionArea").global_position
	return Vector2.ZERO

func spend_player_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		player_stats_changed.emit()
		return true # Giao dịch thành công
	else:
		return false # Không đủ tiền

func register_potion_seller_npc(npc_node: Node):
	potion_seller_ref = npc_node

func get_potion_seller_position() -> Vector2:
	if is_instance_valid(potion_seller_ref):
		return potion_seller_ref.global_position
	return Vector2.ZERO

func register_job_changer_npc(npc_node: Node):
	job_changer_ref = npc_node

func get_job_changer_position() -> Vector2:
	if is_instance_valid(job_changer_ref):
		return job_changer_ref.global_position
	return Vector2.ZERO
	
func register_equipment_seller_npc(npc_node: Node):
	equipment_seller_ref = npc_node

func get_equipment_seller_position() -> Vector2:
	if is_instance_valid(equipment_seller_ref):
		return equipment_seller_ref.global_position
	return Vector2.ZERO
	
#=======Upgrate làng và shop=========
# Hàm kiểm tra xem người chơi có đủ tài nguyên để nâng cấp không
func can_upgrade_village() -> bool:
	var next_level_string = str(village_level + 1)
	var upgrade_data = GameDataManager.get_village_level_data(next_level_string)
	# Nếu không có dữ liệu cho cấp tiếp theo, nghĩa là đã max level
	if upgrade_data.is_empty():
		return false
	# Kiểm tra Vàng
	if player_gold < upgrade_data.get("gold_cost", 999999999):
		return false
	# Kiểm tra Nguyên liệu
	var materials_needed = upgrade_data.get("materials", [])
	for material in materials_needed:
		if get_item_quantity_in_warehouse(material["id"]) < material["quantity"]:
			return false # Chỉ cần thiếu 1 loại là không đủ
	# Nếu qua được tất cả các bài kiểm tra
	return true
# Hàm thực hiện việc nâng cấp
func upgrade_village():
	if not can_upgrade_village():
		print("Không đủ điều kiện để nâng cấp Làng!")
		return
	var next_level = village_level + 1
	var next_level_string = str(next_level)
	var upgrade_data = GameDataManager.get_village_level_data(next_level_string)
	print("--- BẮT ĐẦU NÂNG CẤP LÀNG LÊN CẤP %s ---" % next_level_string)
	# 1. Trừ Vàng và Nguyên liệu
	spend_player_gold(upgrade_data.get("gold_cost", 0))
	var materials_needed = upgrade_data.get("materials", [])
	for material in materials_needed:
		remove_item_from_warehouse(material["id"], material["quantity"])
	# 2. Tăng cấp Làng
	village_level = next_level
	# 3. Xử lý Mở khóa và Nâng cấp NPC
	# Mở khóa NPC mới (nếu có)
	var npcs_to_unlock = upgrade_data.get("unlocks_npc", [])
	for npc_name in npcs_to_unlock:
		var npc_node = world_node.find_child(npc_name, true, false)
		if is_instance_valid(npc_node) and npc_node.has_method("set_active"):
			npc_node.set_active(true)
			print("Đã mở khóa: ", npc_name)
	# Nâng cấp NPC theo chu kỳ (từ level 6 trở đi)
	if village_level > 5:
		# Phép chia lấy dư để lặp lại chu kỳ 5 NPC
		var upgrade_index = (village_level - 6) % NPC_UPGRADE_ORDER.size()
		var npc_key_to_upgrade = NPC_UPGRADE_ORDER[upgrade_index]
		
		if npc_levels.has(npc_key_to_upgrade):
			npc_levels[npc_key_to_upgrade] += 1
			print("Đã nâng cấp '%s' lên cấp %d" % [npc_key_to_upgrade, npc_levels[npc_key_to_upgrade]])
	
	# 4. Phát tín hiệu báo cho các hệ thống khác biết
	village_level_changed.emit(village_level)
	player_stats_changed.emit() # Cập nhật UI chung (ví dụ: lượng vàng)
	update_hero_deployment()

func update_npc_unlock_state():
	var max_level = village_level
	# Lặp từng cấp từ 2 tới max_level, mỗi cấp gọi mở khóa nếu có
	for level in range(2, max_level + 1):
		var upgrade_data = GameDataManager.get_village_level_data(str(level))
		var npcs_to_unlock = upgrade_data.get("unlocks_npc", [])
		for npc_name in npcs_to_unlock:
			var npc_node = world_node.find_child(npc_name, true, false)
			if is_instance_valid(npc_node) and npc_node.has_method("set_active"):
				npc_node.set_active(true)

func get_item_quantity_in_warehouse(item_id: String) -> int:
	var total_quantity = 0
	# Lặp qua tất cả các ô trong nhà kho
	for item_info in warehouse:
		# Nếu ô có đồ và đúng ID chúng ta đang tìm
		if item_info and item_info.get("id") == item_id:
			# Cộng dồn số lượng vào tổng
			total_quantity += item_info.get("quantity", 0)
	# Trả về tổng số lượng đếm được
	return total_quantity
	
func get_current_hero_count() -> int:
	if is_instance_valid(hero_container):
		# 2. Trả về số lượng node con (chính là các hero) đang có trong container
		return hero_container.get_child_count()
	push_warning("PlayerStats: Tham chiếu 'hero_container' không hợp lệ. Không thể đếm hero.")
	return 0

func get_max_heroes() -> int:
	# Giới hạn là 1 + cấp độ làng
	return village_level + 1

func get_active_hero_count() -> int:
	var active_count = 0
	for hero in hero_roster:
		if hero._current_state != Hero.State.IN_BARRACKS:
			active_count += 1
	return active_count

# Hàm để "triển khai" một Hero ra sân
func deploy_hero(hero: Hero):
	if not is_instance_valid(hero):
		return
	
	# Chỉ thêm vào Scene nếu nó chưa có ở đó
	if not hero.is_inside_tree():
		
		# === PHẦN BỊ THIẾU SỐ 1: ĐẶT VỊ TRÍ XUẤT HIỆN ===
		# Đặt Hero vào đúng vị trí xuất phát bạn đã định nghĩa
		if is_instance_valid(hero_spawn_point):
			hero.global_position = hero_spawn_point.global_position
		# ===============================================

		# Thêm Hero vào Scene
		hero_container.add_child(hero)
		
		# === PHẦN BỊ THIẾU SỐ 2: "CHỈ ĐƯỜNG" CHO HERO ===
		# Gán khu vực làng làm movement_area mặc định cho Hero
		if is_instance_valid(village_boundary):
			hero.movement_area = village_boundary
		else:
			push_warning("PlayerStats: Không tìm thấy village_boundary để gán cho Hero mới!")
		# ==============================================

	# Đảm bảo trạng thái của Hero không phải là IN_BARRACKS (phần này của bạn đã đúng)
	if hero._current_state == Hero.State.IN_BARRACKS:
		hero.doi_trang_thai(Hero.State.IDLE)

# Hàm để "triệu hồi" một Hero về sảnh
func recall_hero(hero: Hero):
	if not hero in hero_roster:
		push_error("Không thể triệu hồi Hero không có trong danh sách!")
		return

	# Xóa node Hero khỏi cây scene
	if hero.is_inside_tree():
		hero_container.remove_child(hero)

	hero.doi_trang_thai(Hero.State.IN_BARRACKS)
	hero_count_changed.emit() # Báo cho UI cập nhật
	print("Đã triệu hồi Hero '%s' về sảnh!" % hero.name)
	
func sa_thai_hero(hero_can_xoa: Hero):
	if not is_instance_valid(hero_can_xoa):
		print("Loi: Khong the sa thai hero khong hop le.")
		return

	# Lưu lại trạng thái của hero TRƯỚC KHI xóa
	var was_in_world = hero_can_xoa.is_inside_tree()

	# 1. Xóa khỏi danh sách chính (roster)
	if hero_can_xoa in hero_roster:
		hero_roster.erase(hero_can_xoa)
		print("Da xoa '%s' khoi danh sach roster." % hero_can_xoa.name)
	
	# 2. Nếu hero đang ở ngoài world, xóa node của nó khỏi game
	if was_in_world:
		hero_can_xoa.queue_free()

	# === LOGIC MỚI: TỰ ĐỘNG TRIỂN KHAI HERO THAY THẾ ===
	# 3. Chỉ thực hiện khi hero bị sa thải là hero ngoài world
	if was_in_world:
		# Tìm một hero đang rảnh rỗi trong sảnh
		var next_hero_in_barracks = _find_hero_in_barracks()
		
		# Nếu tìm thấy một hero
		if is_instance_valid(next_hero_in_barracks):
			print("Một hero trong sảnh sẽ được triển khai để thay thế.")
			# Gọi hàm triển khai đã có sẵn
			deploy_hero(next_hero_in_barracks)
		else:
			# Nếu không tìm thấy hero nào trong sảnh
			print("Sảnh trống, không có hero nào để thay thế.")
	# =================================================

	# 4. Phát tín hiệu để UI cập nhật lại số lượng hero
	update_hero_deployment()
	save_game()

func _find_hero_in_barracks() -> Hero:
	for hero in hero_roster:
		if is_instance_valid(hero) and hero._current_state == Hero.State.IN_BARRACKS:
			return hero # Tìm thấy, trả về hero ngay lập tức
	return null # Nếu lặp hết mà không có, trả về null

func _check_and_deploy_barracks_heroes():
	# Vòng lặp: Tiếp tục chạy chừng nào số hero trên world vẫn ít hơn giới hạn
	while get_current_hero_count() < get_max_heroes():
		# Tìm một hero đang rảnh rỗi trong sảnh
		var hero_to_deploy = _find_hero_in_barracks()
		
		# Nếu tìm thấy...
		if is_instance_valid(hero_to_deploy):
			print("Còn chỗ trống trên world. Triển khai hero '%s' từ sảnh." % hero_to_deploy.name)
			deploy_hero(hero_to_deploy)
		else:
			# Nếu không còn hero nào trong sảnh, thoát khỏi vòng lặp
			print("Sảnh đã trống.")
			break
	
	# Sau khi lấp đầy tất cả các chỗ có thể, phát tín hiệu MỘT LẦN DUY NHẤT
	# để UI cập nhật lại lần cuối cho chính xác.
	hero_count_changed.emit()

func update_hero_deployment():
	# Vòng lặp: Tiếp tục chạy chừng nào số hero trên world vẫn ít hơn giới hạn
	while get_current_hero_count() < get_max_heroes():
		# Tìm một hero đang rảnh rỗi trong sảnh
		var hero_to_deploy = _find_hero_in_barracks()
		
		# Nếu tìm thấy...
		if is_instance_valid(hero_to_deploy):
			deploy_hero(hero_to_deploy)
		else:
			# Nếu không còn hero nào trong sảnh, thoát khỏi vòng lặp
			break
	
	# Sau khi lấp đầy tất cả các chỗ có thể, phát tín hiệu MỘT LẦN DUY NHẤT
	# để UI cập nhật lại lần cuối cho chính xác.
	hero_count_changed.emit()

func can_summon() -> bool:
	# Điều kiện 1: Đủ kim cương?
	if player_diamonds >= DIAMOND_COST_FOR_SUMMON:
		return true
	# Điều kiện 2: Có cuộn giấy?
	if get_item_quantity_in_warehouse("summon_scroll") > 0:
		return true
	# Nếu không thỏa mãn cả hai
	return false

func spend_player_diamonds(amount: int) -> bool:
	if player_diamonds >= amount:
		player_diamonds -= amount
		player_stats_changed.emit()
		return true
	return false
