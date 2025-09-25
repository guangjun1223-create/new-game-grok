#res://script/ui.gd
extends CanvasLayer
class_name UIController

const ItemSlotScene = preload("res://Scene/UI/item_slot.tscn")
const RespawnBarScene = preload("res://UI/respawn_bar.tscn")
const InnRoomSelectionScene = preload("res://Scene/inn_room_selection.tscn")
const CraftingPanelScene = preload("res://Scene/UI/crafting_panel.tscn")
const BuybackQuantityPanelScene = preload("res://Scene/UI/buyback_quantity_panel.tscn")
const ShopPanelScene = preload("res://Scene/UI/shop_panel.tscn")
const HeroBarracksPanelScene = preload("res://Scene/UI/hero_barracks_panel.tscn")
@export var blacksmith_npc: StaticBody2D
@export var alchemist_npc: StaticBody2D
@export var potion_seller_npc: StaticBody2D
@export var equipment_seller_npc: StaticBody2D
var _active_respawn_bars: Dictionary = {}

# ====================
# THAM CHIẾU NODE
# ====================
# ----- Panel Chính -----
@onready var selected_hero_panel: Panel = $SelectedHeroPanel
@onready var name_label: Label = $SelectedHeroPanel/VBoxContainer/NameLabel
@onready var class_label: Label = $SelectedHeroPanel/VBoxContainer/ClassLabel
@onready var level_label: Label = $SelectedHeroPanel/VBoxContainer/HBoxContainer2/LevelLabel
@onready var exp_bar: ProgressBar = $SelectedHeroPanel/VBoxContainer/ExpBar
@onready var rarity_label: RichTextLabel = $SelectedHeroPanel/VBoxContainer/HBoxContainer2/RarityLabel
@onready var exp_label: Label = $SelectedHeroPanel/VBoxContainer/ExpBar/ExpLabel
@onready var job_change_button: Button = $SelectedHeroPanel/VBoxContainer/HBoxContainer/JobChangeButton


# ----- Panel Thông tin Chi tiết -----
@onready var hero_info_panel: PanelContainer = $HeroInfoPanel
@onready var info_name_label: Label = $HeroInfoPanel/VBoxContainer/VBoxContainer/Info_NameLabel
@onready var info_job_label: Label = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer2/Info_JobLabel
@onready var info_rarity_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer2/info_rarityLabel
@onready var info_level_label: Label = $HeroInfoPanel/VBoxContainer/VBoxContainer/Info_LevelLabel
@onready var info_exp_label: Label = $HeroInfoPanel/VBoxContainer/VBoxContainer/Info_ExpLabel
@onready var info_hp_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/Info_HPLabel
@onready var info_sp_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/Info_SPLabel
@onready var info_str_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_StrLabel
@onready var info_agi_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_AgiLabel
@onready var info_vit_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_VitLabel
@onready var info_int_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_IntLabel
@onready var info_dex_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_DexLabel
@onready var info_luk_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_LukLabel
@onready var info_atk_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_AtkLabel
@onready var info_matk_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Info_MatkLabel
@onready var info_def_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Info_DefLabel
@onready var info_mdef_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Info_MdefLabel
@onready var info_hit_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Info_HitLabel
@onready var info_flee_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/info_fleeLabel
@onready var info_crit_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Info_CritLabel
@onready var info_critDame_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer2/info_critDameLabel
@onready var info_attackspeed_label: RichTextLabel = $HeroInfoPanel/VBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Info_AttackSpeedLabel

# ----- Panel Túi đồ (hero) -----
@onready var equipment_slots: Dictionary = {
	"HELMET": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/HelmetSlot,
	"MAIN_HAND": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/WeaponSlot,
	"ARMOR": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/ArmorSlot,
	"OFF_HAND": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/OffhandSlot,
	"BOOTS": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/bootsslot,
	"RING": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/ringslot,
	"AMULET": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/necklaceslot,
	# === PHẦN THÊM VÀO ===
	# Ô sử dụng nhanh (Quick Slots)
	"POTION_1": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion1slot,
	"POTION_2": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion2slot,
	"POTION_3": $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion3slot
}
#-----Phần người chơi------------------
@onready var player_name_label: Label = $PlayerInfoBar/HBoxContainer/PlayerNameLabel
@onready var player_level_label: Label = $PlayerInfoBar/HBoxContainer/PlayerLevelLabel
@onready var player_gold_label: Label = $PlayerInfoBar/HBoxContainer/PlayerGoldLabel
@onready var player_diamonds_label: Label = $PlayerInfoBar/HBoxContainer/PlayerDiamondsLabel
@onready var warehouse_panel: PanelContainer = $Warehouse
@onready var warehouse_grid: GridContainer = $Warehouse/VBoxContainer/Panel/ScrollContainer/GridContainer
@onready var warehouse_button: Button = $HBoxContainer/WarehouseButton
@onready var close_warehouse_button: Button = $Warehouse/VBoxContainer/CloseButton
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var bottom_bar_container: HBoxContainer = $HBoxContainer
@onready var hero_gold_label: Label = $InventoryPanel/HBoxContainer/BackpackBG/MarginContainer/BackpackUI/HeroGoldLabel
@onready var respawn_bar_container: VBoxContainer = $RespawnBarContainer
@onready var hero_count_label: RichTextLabel = $PlayerInfoBar/HBoxContainer/HeroCountLabel

#-------- phần ShopListPanel ----------------
@onready var shop_list_panel: PanelContainer = $ShopListPanel

#-------- phần MainCommandMenu ----------------
@onready var main_command_menu: PanelContainer = $MainCommandMenu
#---------- Phần đổi nghề _______________________
@onready var job_change_panel: JobChangePanel = $JobChangePanel
#==================Nâng cấp làng ==================================
const VillageUpgradePanelScene = preload("res://Scene/UI/village_upgrade_panel.tscn")
@onready var village_upgrade_button: Button = $PlayerInfoBar/HBoxContainer/VillageUpgradeButton

# ------- phần MovementButtons-----
@onready var  movement_buttons: Control = $MovementButtons
@onready var go_to_village_button: Button = $MovementButtons/VBox/GoToVillageButton
@onready var go_to_forest_button: Button = $MovementButtons/VBox/GoToForestButton
@onready var go_to_forest2_button: Button = $MovementButtons/VBox/GoToForestButton2
@onready var go_to_forest3_button: Button = $MovementButtons/VBox/GoToForestButton3
#-------------- Phần Shop mua bán đồ BuybackPanel----------------------
@onready var buyback_panel: PanelContainer = $BuybackPanel
@onready var buyback_hero_name_label: Label = $BuybackPanel/VBoxContainer/HBoxContainer/VBoxContainer/BuybackHeroNameLabel
@onready var hero_buyback_grid: GridContainer = $BuybackPanel/VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/HeroBuybackGrid
@onready var warehouse_buyback_grid: GridContainer = $BuybackPanel/VBoxContainer/HBoxContainer/VBoxContainer2/ScrollContainer/WarehouseBuybackGrid
@onready var close_buyback_button: Button = $BuybackPanel/VBoxContainer/CloseBuybackButton

# ----- Khác -----
@onready var summon_button: Button = $HBoxContainer/SummonButton
@onready var coordinate_label: Label = $HBoxContainer/CoordinateLabel
@onready var backpack_grid: GridContainer = $InventoryPanel/HBoxContainer/BackpackBG/MarginContainer/BackpackUI/BackpackSlots
@onready var barracks_button: Button = $HBoxContainer/BarracksButton
@onready var item_tooltip: PopupPanel = $ItemTooltip



var backpack_slots: Array[Button] = []
var warehouse_slots: Array[Button] = []
var hero_buyback_slots: Array[Button] = []
var warehouse_buyback_slots: Array[Button] = []
var _hero_for_buyback: Hero = null 
# ====================
# BIẾN EXPORT (Kéo thả trong Editor)
# ====================
@export_group("Navigation Targets")
@export var village_boundary: Area2D
@export var forest_boundary: Area2D
@export var forest2_boundary: Area2D
@export var forest3_boundary: Area2D
@export var shop_npc: StaticBody2D

# ====================
# BIẾN NỘI BỘ
# ====================
var _current_hero: Hero = null
var _main_camera: Camera2D

# ====================
# HÀM TÍCH HỢP CỦA GODOT
# ====================
func _ready() -> void:
	if is_instance_valid(blacksmith_npc):
		blacksmith_npc.blacksmith_panel_requested.connect(_on_blacksmith_panel_requested)
	else:
		push_warning("Chưa kết nối với blacksmith NPC")
	if is_instance_valid(alchemist_npc):
		alchemist_npc.alchemist_panel_requested.connect(_on_alchemist_panel_requested)
	else:
		push_warning("UI CHƯA ĐƯỢC KẾT NỐI VỚI ALCHEMIST NPC!")
	
	
	var job_changer_npc = get_tree().get_root().get_node("World/Village_Boundary/JobChangerNpc")
	if is_instance_valid(job_changer_npc):
		job_changer_npc.open_job_change_panel.connect(_on_open_job_change_panel)
	else:
		push_warning("Không tìm thấy NPC chuyển nghề trong World")
		
	PlayerStats.register_ui_controller(self)
	selected_hero_panel.visible = false
	hero_info_panel.visible = false
	inventory_panel.visible = false
	movement_buttons.visible = false
	warehouse_panel.visible = false
	buyback_panel.visible = false
	
	_main_camera = get_tree().root.get_camera_2d()

	PlayerStats.player_stats_changed.connect(_update_player_info_bar)
	PlayerStats.warehouse_changed.connect(_update_warehouse_display)
	GameEvents.hero_selected.connect(_on_hero_selected)
	GameEvents.hero_arrived_at_shop.connect(_on_hero_arrived_at_shop)
	GameEvents.hero_arrived_at_inn.connect(_on_hero_arrived_at_inn)
	GameEvents.hero_arrived_at_potion_shop.connect(_on_hero_arrived_at_potion_shop)
	job_change_button.pressed.connect(_on_job_change_button_pressed)
	GameEvents.hero_arrived_at_equipment_shop.connect(_on_hero_arrived_at_equipment_shop)
	village_upgrade_button.pressed.connect(_on_village_upgrade_button_pressed)
	PlayerStats.hero_count_changed.connect(_update_hero_count_display)
	PlayerStats.village_level_changed.connect(_update_hero_count_display)

	close_buyback_button.pressed.connect(_on_close_buyback_button_pressed)
	
	_create_slots_for_grid(backpack_grid, backpack_slots, 20, Callable(self, "_on_backpack_slot_mouse_entered"), Callable(self, "_on_backpack_slot_pressed"))
	_create_slots_for_grid(warehouse_grid, warehouse_slots, 100, Callable(self, "_on_warehouse_slot_mouse_entered"))
	_create_slots_for_grid(hero_buyback_grid, hero_buyback_slots, 20, Callable(self, "_on_backpack_slot_mouse_entered"))
	_create_slots_for_grid(warehouse_buyback_grid, warehouse_buyback_slots, 100, Callable(self, "_on_warehouse_slot_mouse_entered"))
	
	_update_backpack_display()
	_update_player_info_bar()
	_update_warehouse_display()
	_update_hero_count_display()
	
	for slot_key in equipment_slots.keys():
		equipment_slots[slot_key].pressed.connect(_on_equipment_slot_pressed.bind(slot_key))
	for slot_key in equipment_slots.keys():
		var slot_node = equipment_slots[slot_key]
		slot_node.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(slot_key))
		slot_node.mouse_exited.connect(_on_equipment_slot_mouse_exited)

	selected_hero_panel.gui_input.connect(_on_panel_gui_input)
	hero_info_panel.gui_input.connect(_on_panel_gui_input)
	inventory_panel.gui_input.connect(_on_panel_gui_input)
	bottom_bar_container.gui_input.connect(_on_panel_gui_input)
	movement_buttons.gui_input.connect(_on_panel_gui_input)
	barracks_button.pressed.connect(_on_barracks_button_pressed)
	GameEvents.respawn_started.connect(_on_respawn_started)
	GameEvents.respawn_finished.connect(_on_respawn_finished)
	
	# ===================================================
	
func _process(_delta: float) -> void:
	if item_tooltip.visible:
		# ...thì liên tục cập nhật vị trí của nó theo con trỏ chuột
		# Vector2(25, 25) tạo ra một khoảng cách an toàn về bên phải và xuống dưới
		item_tooltip.position = get_viewport().get_mouse_position() + Vector2(30, 30)
	# Lặp qua tất cả các thanh hồi sinh đang hoạt động
	for hero in _active_respawn_bars:
		var bar = _active_respawn_bars[hero]
		# Lấy thông tin thời gian trực tiếp từ RespawnTimer của Hero
		var timer_node = hero.get_node_or_null("RespawnTimer")
		if is_instance_valid(timer_node):
			bar.update_display(timer_node.time_left, timer_node.wait_time)
	
	
	if is_instance_valid(_main_camera):
		var cam_pos = _main_camera.global_position
		coordinate_label.text = "X: %d | Y: %d" % [roundi(cam_pos.x), roundi(cam_pos.y)]
		
func _unhandled_input(event: InputEvent) -> void:
	# Hàm này giờ đây sẽ chỉ nhận các input không bị UI chặn lại (ví dụ: click lên mặt đất)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if _current_hero != null:
			GameEvents.hero_selected.emit(null) # Gửi tín hiệu bỏ chọn hero
			get_viewport().set_input_as_handled()

# ===================================================
# === HÀM MỚI ĐỂ XỬ LÝ CLICK XUYÊN UI ===
# ===================================================
# Hàm này được gọi khi có bất kỳ input nào (click, di chuột...) trên các panel
# đã được kết nối ở hàm _ready().
func _on_panel_gui_input(event: InputEvent) -> void:
	# Nếu input là một cú click chuột
	if event is InputEventMouseButton:
		# Đánh dấu là input này đã được xử lý.
		# Godot sẽ không gửi nó đến các hàm khác như _unhandled_input nữa.
		get_viewport().set_input_as_handled()
		
		
# ====================
# HÀM XỬ LÝ TÍN HIỆU
# ====================
func _on_summon_button_pressed():
	PlayerStats.trieu_hoi_hero()

func _on_hero_selected(hero: Hero) -> void:
	# === LOGIC CHỌN / BỎ CHỌN HERO (PHIÊN BẢN 4.0 - SỬA LỖI) ===
	var previous_hero = _current_hero
	var next_hero = hero

	# Tối ưu: Nếu chọn lại chính hero đó thì không làm gì cả
	if next_hero == previous_hero:
		return

	# 1. NGẮT KẾT NỐI KHỎI HERO CŨ (NẾU CÓ)
	if is_instance_valid(previous_hero):
		if previous_hero.is_connected("exp_changed", _on_hero_exp_changed):
			previous_hero.exp_changed.disconnect(_on_hero_exp_changed)
		if previous_hero.is_connected("stats_updated", _on_hero_stats_updated):
			previous_hero.stats_updated.disconnect(_on_hero_stats_updated)
		if previous_hero.is_connected("equipment_changed", _update_equipment_display):
			previous_hero.equipment_changed.disconnect(_update_equipment_display)
		# Ngắt kết nối inventory và gold của hero cũ
		if previous_hero.is_connected("inventory_changed", _on_inventory_changed):
			previous_hero.inventory_changed.disconnect(_on_inventory_changed)
		if previous_hero.is_connected("gold_changed", _on_player_stats_gold_changed):
			previous_hero.gold_changed.disconnect(_on_player_stats_gold_changed)
		if previous_hero.is_connected("sp_changed", _on_hero_sp_changed):
			previous_hero.sp_changed.disconnect(_on_hero_sp_changed)


	# 2. CẬP NHẬT HERO HIỆN TẠI
	_current_hero = next_hero

	# 3. KẾT NỐI VỚI HERO MỚI (NẾU CÓ)
	if is_instance_valid(_current_hero):
		_current_hero.exp_changed.connect(_on_hero_exp_changed)
		_current_hero.stats_updated.connect(_on_hero_stats_updated)
		_current_hero.equipment_changed.connect(_update_equipment_display)
		# Kết nối inventory và gold của hero mới
		_current_hero.inventory_changed.connect(_on_inventory_changed)
		_current_hero.gold_changed.connect(_on_player_stats_gold_changed)
		_current_hero.sp_changed.connect(_on_hero_sp_changed)


	# 4. CẬP NHẬT GIAO DIỆN CHUNG
	var is_hero_selected = is_instance_valid(_current_hero)
	selected_hero_panel.visible = is_hero_selected
	#movement_buttons.visible = is_hero_selected
	main_command_menu.visible = is_hero_selected
	hero_info_panel.visible = false
	inventory_panel.visible = false
	movement_buttons.hide()
	shop_list_panel.hide()

	# 5. CẬP NHẬT DỮ LIỆU CỤ THỂ CỦA HERO MỚI
	if is_hero_selected:
		_update_selected_hero_panel()
		_update_gold_display(_current_hero.gold) # << HIỂN THỊ VÀNG CỦA HERO
		_update_backpack_display() # << HIỂN THỊ TÚI ĐỒ CỦA HERO
		_update_equipment_display()
	else:
		# Nếu không có hero nào được chọn, dọn dẹp UI
		_update_gold_display(0)
		_update_backpack_display()
		_update_equipment_display()
	# ===================================================
#========= CÁC HÀM XỬ LÝ TRONG MENU HERO================
func _on_move_button_pressed():
	main_command_menu.hide()
	shop_list_panel.hide()
	movement_buttons.show()

func _on_shop_button_pressed():
	main_command_menu.hide()
	movement_buttons.hide()
	shop_list_panel.show()

func _on_back_to_main_menu_button_pressed(): # Dùng cho cả 2 nút "Quay Lại"
	movement_buttons.hide()
	shop_list_panel.hide()
	main_command_menu.show()

func _on_sell_items_shop_button_pressed():
	if not is_instance_valid(_current_hero):
		print("Vui long chon mot Hero truoc!")
		return
		
	# Hỏi PlayerStats xem NPC ở đâu
	var npc_position = PlayerStats.get_shop_npc_position()
	
	# Nếu vị trí không hợp lệ (Vector2.ZERO là giá trị trả về khi có lỗi)
	if npc_position == Vector2.ZERO:
		return
		
	# Ra lệnh cho Hero di chuyển đến vị trí đã hỏi được
	_current_hero.di_den_diem(npc_position)
	
	# Ẩn các menu đi sau khi ra lệnh
	shop_list_panel.hide()
	main_command_menu.show()

# ----- Xử lý các nút di chuyển -----
func _on_go_to_village_button_pressed():
	if is_instance_valid(_current_hero):
		_current_hero.di_den_khu_vuc(village_boundary)

func _on_go_to_forest_button_pressed():
	if is_instance_valid(_current_hero):
		_current_hero.di_den_khu_vuc(forest_boundary)

func _on_go_to_forest2_button_pressed():
	if is_instance_valid(_current_hero):
		_current_hero.di_den_khu_vuc(forest2_boundary)

func _on_go_to_forest3_button_pressed():
	if is_instance_valid(_current_hero):
		_current_hero.di_den_khu_vuc(forest3_boundary)

func _on_info_button_pressed():
	if is_instance_valid(_current_hero):
		hero_info_panel.visible = not hero_info_panel.visible
		inventory_panel.visible = false
		if hero_info_panel.visible:
			_update_hero_info_panel(_current_hero)

func _on_inventory_button_pressed():
	if is_instance_valid(_current_hero):
		inventory_panel.visible = not inventory_panel.visible
		hero_info_panel.visible = false

func _on_close_info_button_pressed():
	hero_info_panel.visible = false

# ====================
# HÀM CẬP NHẬT GIAO DIỆN
# ====================
func _update_selected_hero_panel() -> void:
	if not is_instance_valid(_current_hero): return
	name_label.text = _current_hero.hero_name
	class_label.text = GameDataManager.get_job_display_name(_current_hero.job_key)
	level_label.text = "Cấp độ: " + str(_current_hero.level)
	var rarity = "N/A"
	if _current_hero.name.contains("("):
		var start = _current_hero.name.find("(") + 1
		var end = _current_hero.name.find(")")
		rarity = _current_hero.name.substr(start, end - start)

	var rarity_bbcode: String = rarity
	match rarity:
		"F": rarity_bbcode = "[color=#aaaaaa]F[/color]"
		"D": rarity_bbcode = "[color=#cccccc]D[/color]"
		"C": rarity_bbcode = "[color=white]C[/color]"
		"B": rarity_bbcode = "[color=greenyellow]B[/color]"
		"A": rarity_bbcode = "[color=deepskyblue]A[/color]"
		"S": rarity_bbcode = "[color=gold]S[/color]"
		"SS": rarity_bbcode = "[color=orangered]SS[/color]"
		"SSR": rarity_bbcode = "[color=magenta]SSR[/color]"
		"UR": rarity_bbcode = "[rainbow freq=1 sat=0.8 val=1.0]UR[/rainbow]"
	rarity_label.text = "Hạng: " + rarity_bbcode
	
	exp_bar.max_value = _current_hero.exp_to_next_level
	if _current_hero.job_key == "Novice" and _current_hero.level >= _current_hero.MAX_LEVEL_NOVICE:
		exp_bar.value = exp_bar.max_value # Lấp đầy thanh EXP
		exp_label.text = "MAX"
	else:
		exp_bar.value = _current_hero.current_exp
		exp_label.text = "%d / %d" % [_current_hero.current_exp, _current_hero.exp_to_next_level]
		
	if _current_hero.job_key == "Novice" and _current_hero.level >= _current_hero.MAX_LEVEL_NOVICE:
		job_change_button.show()
	else:
		job_change_button.hide()

func _update_hero_info_panel(hero_to_display: Hero):
	print("2. Hàm _update_hero_info_panel được gọi.")
	if not is_instance_valid(hero_to_display):
		print("   -> LỖI: hero_to_display không hợp lệ!")
		hero_info_panel.hide()
		return
	
	info_name_label.text = "Tên: " + hero_to_display.hero_name
	print("   -> Đã gán tên ", info_name_label.text)
	var job_text = "Nghề: " + GameDataManager.get_job_display_name(hero_to_display.job_key)
	info_job_label.text = "Nghề: " + GameDataManager.get_job_display_name(hero_to_display.job_key)
	print("   -> Đã gán nghề: ", job_text)
	var rarity = "Chưa rõ"
	if hero_to_display.name.contains("("):
		rarity = hero_to_display.name.substr(hero_to_display.name.find("(") + 1, hero_to_display.name.find(")") - hero_to_display.name.find("(") - 1)
	var rarity_bbcode: String = rarity
	match rarity:
		"F":
			rarity_bbcode = "[color=#4a4a4a]F[/color]" # Xám đen
		"D":
			rarity_bbcode = "[color=#808080]D[/color]" # Xám tối
		"C":
			rarity_bbcode = "[color=#b2b2b2]C[/color]" # Xám sáng
		"B":
			rarity_bbcode = "[color=#e5e5e5]B[/color]" # Gần trắng
		"A":
			rarity_bbcode = "[color=white]A[/color]"     # Trắng
		"S":
			rarity_bbcode = "[color=palegreen]S[/color]"   # Xanh lá nhạt
		"SS":
			rarity_bbcode = "[color=cyan]SS[/color]"      # Xanh dương
		"SSS":
			rarity_bbcode = "[color=gold]SSS[/color]"     # Vàng
		"SSR":
			rarity_bbcode = "[color=orangered]SSR[/color]" # Đỏ cam
		"UR":
		# Dùng hiệu ứng rainbow tích hợp của RichTextLabel
			rarity_bbcode = "[rainbow freq=1 sat=0.8 val=1.0]UR[/rainbow]"

	info_rarity_label.text = "Hạng: " + rarity_bbcode
		
	info_level_label.text = "Cấp: " + str(hero_to_display.level)
	info_exp_label.text = "EXP: %d/%d" % [hero_to_display.current_exp, hero_to_display.exp_to_next_level]
	# 1. Lấy ra các giá trị gốc và bonus từ hero
	var bonus_hp = snapped(hero_to_display.bonus_max_hp, 0.01)
	var base_hp = snapped(hero_to_display.max_hp - bonus_hp, 0.01)
	var bonus_sp = snapped(hero_to_display.bonus_max_sp, 0.01)
	var base_sp = snapped(hero_to_display.max_sp - bonus_sp, 0.01)
	var base_str = snapped(hero_to_display.STR, 0.01)
	var bonus_str = snapped(hero_to_display.bonus_str, 0.01)
	var base_agi = snapped(hero_to_display.agi, 0.01)
	var bonus_agi = snapped(hero_to_display.bonus_agi, 0.01)
	var base_vit = snapped(hero_to_display.vit, 0.01)
	var bonus_vit = snapped(hero_to_display.bonus_vit, 0.01)
	var base_intel = snapped(hero_to_display.intel, 0.01)
	var bonus_intel = snapped(hero_to_display.bonus_intel, 0.01)
	var base_dex = snapped(hero_to_display.dex, 0.01)
	var bonus_dex = snapped(hero_to_display.bonus_dex, 0.01)
	var base_luk = snapped(hero_to_display.luk, 0.01)
	var bonus_luk = snapped(hero_to_display.bonus_luk, 0.01)
	var bonus_atk = snapped(hero_to_display.bonus_atk, 0.01)
	var base_atk = snapped(hero_to_display.atk - bonus_atk, 0.01)
	var bonus_matk = snapped(hero_to_display.bonus_matk, 0.01)
	var base_matk = snapped(hero_to_display.matk - bonus_matk, 0.01)
	var bonus_def = snapped(hero_to_display.bonus_def, 0.01)
	var base_def = snapped(hero_to_display.def - bonus_def, 0.01)
	var bonus_mdef = snapped(hero_to_display.bonus_mdef, 0.01)
	var base_mdef = snapped(hero_to_display.mdef - bonus_mdef, 0.01)
	var bonus_hit = snapped(hero_to_display.bonus_hit, 0.01)
	var base_hit = snapped(hero_to_display.hit - bonus_hit - hero_to_display.bonus_hit_hidden, 0.01)
	var bonus_flee = snapped(hero_to_display.bonus_flee, 0.01)
	var base_flee = snapped(hero_to_display.flee - bonus_flee, 0.01)
	var bonus_crit = snapped(hero_to_display.bonus_crit_rate, 0.01)
	var base_crit = snapped(hero_to_display.crit_rate - bonus_crit - hero_to_display.bonus_crit_rate_hidden, 0.01)
	var bonus_crit_dame = snapped(hero_to_display.bonus_crit_dame, 0.01)
	var base_crit_dame = snapped(hero_to_display.crit_damage - bonus_crit_dame, 0.01)
	
	
	var current_hp_int = int(hero_to_display.current_hp)
	info_hp_label.text = "HP: %d/%s" % [current_hp_int, str(roundi(base_hp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hp)) if bonus_hp > 0 else "")
	var current_sp_int = int(hero_to_display.current_sp)
	info_sp_label.text = "SP: %d/%s" % [current_sp_int, str(roundi(base_sp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_sp)) if bonus_sp > 0 else "")
	
	info_str_label.text = "Sức mạnh: %s" % str(roundi(base_str)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_str)) if bonus_str > 0 else "")
	info_agi_label.text = "Nhanh nhẹn: %s" % str(roundi(base_agi)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_agi)) if bonus_agi > 0 else "")
	info_vit_label.text = "Thể lực: %s" % str(roundi(base_vit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_vit)) if bonus_vit > 0 else "")
	info_int_label.text = "Trí tuệ: %s" % str(roundi(base_intel)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_intel)) if bonus_intel > 0 else "")
	info_dex_label.text = "Độ chuẩn: %s" % str(roundi(base_dex)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_dex)) if bonus_dex > 0 else "")
	info_luk_label.text = "May mắn: %s" % str(roundi(base_luk)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_luk)) if bonus_luk > 0 else "")
	info_atk_label.text = "Sát thương: %s" % str(roundi(base_atk)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_atk)) if bonus_atk > 0 else "")
	info_matk_label.text = "Sát thương phép: %s" % str(roundi(base_matk)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_matk)) if bonus_matk > 0 else "")
	info_def_label.text = "Phòng thủ: %s" % str(roundi(base_def)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_def)) if bonus_def > 0 else "")
	info_mdef_label.text = "Phòng thủ phép: %s" % str(roundi(base_mdef)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_mdef)) if bonus_mdef > 0 else "")
	info_hit_label.text = "Chính xác: %s" % str(roundi(base_hit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hit)) if bonus_hit > 0 else "")
	info_flee_label.text = "Tránh né: %s" % str(roundi(base_flee)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_flee)) if bonus_flee > 0 else "")
	info_crit_label.text = "Tỉ lệ trí mạng: %s%%" % str(snapped(base_crit, 0.1)) + ("[color=cyan] +%s%%[/color]" % str(snapped(bonus_crit, 0.1)) if bonus_crit > 0 else "")
	info_critDame_label.text = "ST chí mạng: x%s" % str(snapped(base_crit_dame, 0.1)) + ("[color=cyan] +%s[/color]" % str(snapped(bonus_crit_dame, 0.1)) if bonus_crit_dame > 0 else "")
	info_attackspeed_label.text = "Tốc độ đánh: %.2f giây/đòn" % hero_to_display.attack_speed_calculated
	info_sp_label.text = "SP: %d/%d" % [int(hero_to_display.current_sp), int(hero_to_display.max_sp)]


func _on_hero_exp_changed(current_exp, exp_to_next_level):
	if not is_instance_valid(_current_hero): return

	# Cập nhật thanh EXP ở panel chính
	exp_bar.max_value = exp_to_next_level
	exp_bar.value = current_exp
	
	# Cập nhật label EXP ở panel chi tiết (nếu nó đang mở)
	if hero_info_panel.visible:
		info_exp_label.text = "EXP: %d/%d" % [current_exp, exp_to_next_level]

# Hàm này được gọi khi tín hiệu "stats_updated" của hero được phát ra (khi lên cấp).
func _on_hero_stats_updated():
	if not is_instance_valid(_current_hero): return
	_update_selected_hero_panel()
	if hero_info_panel.visible:
		# Truyền Hero đang được chọn vào hàm
		_update_hero_info_panel(_current_hero)
		
func _create_backpack_slots(amount: int) -> void:
	# Xóa các ô cũ đi (giữ nguyên)
	for slot in backpack_grid.get_children():
		slot.queue_free()
	backpack_slots.clear()

	# Vòng lặp để tạo ra đủ số lượng ô đồ yêu cầu
	for i in range(amount):
		var new_slot = ItemSlotScene.instantiate()
		backpack_slots.append(new_slot)
		backpack_grid.add_child(new_slot)

		# === NÂNG CẤP QUAN TRỌNG ===
		# Kết nối tín hiệu của từng slot với các hàm xử lý tooltip của UIController
		# Khi chuột đi vào, gọi _on_item_slot_mouse_entered
		new_slot.mouse_entered.connect(_on_item_slot_mouse_entered.bind(i))
		# Khi chuột đi ra, gọi _on_item_slot_mouse_exited
		new_slot.mouse_exited.connect(_on_item_slot_mouse_exited)
		# Khi ô đồ được nhấn, gọi hàm _on_backpack_slot_pressed
		new_slot.pressed.connect(_on_backpack_slot_pressed.bind(i))
		
		
func _on_inventory_changed():
	_update_backpack_display()
	
func _update_backpack_display() -> void:
	# Nếu chưa có hero nào, clear hết slot
	if not is_instance_valid(_current_hero):
		for slot_node in backpack_slots:
			slot_node.display_item(null, 0)
		return

	var inv: Array = _current_hero.inventory
	var inv_size: int = inv.size()

	# Lặp qua tất cả slot hiển thị
	for i in range(backpack_slots.size()):
		var slot_node = backpack_slots[i]
		var item_info = inv[i] if i < inv_size else null

		if item_info != null and item_info.has("id"):
			var item_id: String = item_info["id"]
			var quantity: int = item_info.get("quantity", 1)
			var new_icon = ItemDatabase.get_item_icon(item_id)
			slot_node.display_item(new_icon, quantity)
		else:
			slot_node.display_item(null, 0)
			
func _on_item_slot_mouse_entered(slot_index: int) -> void:
	if not is_instance_valid(_current_hero):
		return
	if slot_index < 0 or slot_index >= _current_hero.inventory.size():
		return

	var item_info = _current_hero.inventory[slot_index]

	if item_info != null and item_info.has("id"):
		var item_id: String = item_info["id"]
		if item_id != "":
			item_tooltip.update_tooltip(item_id)
			item_tooltip.position = get_viewport().get_mouse_position() + Vector2(20, 20)
			item_tooltip.popup()

func _on_item_slot_mouse_exited():
	# Đơn giản là ẩn tooltip đi
	item_tooltip.hide()
			
func _on_backpack_slot_pressed(slot_index: int):
	if is_instance_valid(_current_hero):
		print("UI: Ra lenh cho Hero trang bi item tu o so %d" % slot_index)
		_current_hero.equip_from_inventory(slot_index)

	# Ra lệnh cho hero đang được chọn tự trang bị vật phẩm từ ô túi đồ này
	_current_hero.equip_from_inventory(slot_index)

func _update_equipment_display(new_equipment: Dictionary = {}):
	if not is_instance_valid(_current_hero):
		for slot_key in equipment_slots:
			equipment_slots[slot_key].display_item(null, 0)
		return

	var hero_equipment = _current_hero.equipment
	if not new_equipment.is_empty():
		hero_equipment = new_equipment

	# Lặp qua từng ô trang bị trên UI
	for slot_key in equipment_slots:
		var slot_node = equipment_slots[slot_key]
		var equipped_item = hero_equipment.get(slot_key)

		if not equipped_item:
			slot_node.display_item(null, 0)
			continue

		var item_id = ""
		var quantity = 1 # Mặc định là 1 cho trang bị thường

		# Nếu là Potion, dữ liệu sẽ là Dictionary
		if equipped_item is Dictionary:
			item_id = equipped_item.get("id", "")
			quantity = equipped_item.get("quantity", 1)
		# Nếu là trang bị thường, dữ liệu là String
		elif equipped_item is String:
			item_id = equipped_item

		if not item_id.is_empty():
			var new_icon = ItemDatabase.get_item_icon(item_id)
			slot_node.display_item(new_icon, quantity)
		else:
			slot_node.display_item(null, 0)

func _on_equipment_slot_pressed(slot_key: String):
	if not is_instance_valid(_current_hero):
		return

	# Ra lệnh cho hero đang được chọn tháo vật phẩm ở vị trí tương ứng
	_current_hero.unequip_item(slot_key)

func _on_equipment_slot_mouse_entered(slot_key: String):
	if not is_instance_valid(_current_hero):
		return

	var equipped_item = _current_hero.equipment.get(slot_key)
	if not equipped_item:
		return

	# Bắt đầu kiểm tra xem equipped_item là String hay Dictionary
	var item_id_to_show = ""
	if equipped_item is Dictionary:
		# Nếu là Potion, lấy ID từ bên trong Dictionary
		item_id_to_show = equipped_item.get("id", "")
	elif equipped_item is String:
		# Nếu là trang bị thường, nó chính là ID
		item_id_to_show = equipped_item

	# Chỉ hiển thị tooltip nếu có ID hợp lệ
	if not item_id_to_show.is_empty():
		item_tooltip.update_tooltip(item_id_to_show)
		item_tooltip.position = get_viewport().get_mouse_position() + Vector2(20, 20)
		item_tooltip.popup()

func _on_equipment_slot_mouse_exited():
	item_tooltip.hide()


func _on_player_stats_gold_changed(new_gold_amount: int):
	_update_gold_display(new_gold_amount)

# Hàm chuyên để cập nhật text cho gọn gàng
func _update_gold_display(amount: int):
	# Thêm hiệu ứng số lớn có dấu phẩy cho dễ đọc (ví dụ: 1,234,567)
	var gold_text = "%s" % amount
	var result = ""
	var count = 0
	for i in range(gold_text.length() - 1, -1, -1):
		result = gold_text[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	
	hero_gold_label.text = "Vàng: " + result

func _on_respawn_started(hero: Hero):
	# 1. Kiểm tra để tránh lỗi
	if _active_respawn_bars.has(hero):
		return
	
	# 2. Tạo một thanh hồi sinh mới
	var new_bar = RespawnBarScene.instantiate()
	
	# === THAY ĐỔI QUAN TRỌNG ===
	# BƯỚC 3: Thêm vào cây Scene NGAY LẬP TỨC
	# Việc này sẽ khởi tạo các biến @onready bên trong RespawnBar
	respawn_bar_container.add_child(new_bar)
	
	# BƯỚC 4: Gọi hàm setup để gán dữ liệu
	# Bây giờ new_bar.name_label chắc chắn đã tồn tại
	new_bar.setup(hero)
	
	# BƯỚC 5: Thêm vào danh sách quản lý
	_active_respawn_bars[hero] = new_bar


# Hàm này được gọi khi GameEvents phát tín hiệu "respawn_finished"
func _on_respawn_finished(hero: Hero):
	# 1. Kiểm tra xem hero này có trong danh sách quản lý không
	if _active_respawn_bars.has(hero):
		# 2. Lấy ra thanh hồi sinh tương ứng
		var bar_to_remove = _active_respawn_bars[hero]

		# 3. Xóa nó khỏi danh sách quản lý
		_active_respawn_bars.erase(hero)

		# 4. Lệnh cho thanh hồi sinh tự hủy khỏi Scene
		bar_to_remove.queue_free()

func tim_potion_slot_san_sang() -> String:
	# Chỉ tìm khi đang có hero được chọn
	if not is_instance_valid(_current_hero):
		return ""

	# Lặp qua các ô Potion đã định nghĩa
	for slot_key in ["POTION_1", "POTION_2", "POTION_3"]:
		var slot_node = equipment_slots.get(slot_key)
		var item_in_slot = _current_hero.equipment.get(slot_key)
		
		var is_slot_ready = false
		if is_instance_valid(slot_node):
			is_slot_ready = slot_node.is_ready()

		if item_in_slot != null and is_slot_ready:
			return slot_key
			
	return ""

# Hàm này ra lệnh cho một ô Potion cụ thể bắt đầu cooldown
func bat_dau_cooldown_potion(slot_key: String, duration: float):
	var slot_node = equipment_slots.get(slot_key)
	if is_instance_valid(slot_node):
		slot_node.start_cooldown(duration)

func _on_warehouse_button_pressed() -> void:
	warehouse_panel.visible = not warehouse_panel.visible

func _on_close_button_pressed() -> void:
	warehouse_panel.hide()
	
# Được gọi khi Hero đến chỗ NPC
func _on_hero_arrived_at_shop(hero: Hero):
	print(">>> UI: Da nhan duoc tin hieu tu Hero '%s'!" % hero.name)
	
	# Chuyển trạng thái của Hero sang đang giao dịch
	hero.doi_trang_thai(Hero.State.TRADING)
	
	_hero_for_buyback = hero
	_update_buyback_panel()
	
	# Hiển thị và đưa panel lên trên cùng
	buyback_panel.show()
	buyback_panel.move_to_front()
	
	# "Đóng băng" AI của hero
	hero.is_ui_interacting = true

# Được gọi khi nhấn nút "Đóng"
func _on_close_buyback_button_pressed():
	buyback_panel.hide()
	
	if is_instance_valid(_hero_for_buyback):
		# "Mở băng" AI của hero, cho phép nó đi lang thang trở lại
		_hero_for_buyback.is_ui_interacting = false
		_hero_for_buyback.doi_trang_thai(Hero.State.IDLE)
		
	_hero_for_buyback = null

# Hàm tổng hợp để cập nhật cả hai bên của panel
func _update_buyback_panel():
	if not is_instance_valid(_hero_for_buyback):
		return
		
	buyback_hero_name_label.text = "Túi Đồ Của: " + _hero_for_buyback.hero_name
	
	# Ra lệnh cập nhật 2 lưới đồ với dữ liệu tương ứng
	_populate_buyback_grid(hero_buyback_grid, hero_buyback_slots, _hero_for_buyback.inventory, true)
	_populate_buyback_grid(warehouse_buyback_grid, warehouse_buyback_slots, PlayerStats.warehouse, false)

# Hàm đa năng để vẽ lại các ô đồ
func _populate_buyback_grid(_grid: GridContainer, slot_array: Array, item_array: Array, is_clickable: bool):
	for i in range(slot_array.size()):
		var slot_node = slot_array[i]
		var item_info = item_array[i] if i < item_array.size() else null

		if item_info and item_info.has("id"):
			var item_id: String = item_info["id"]
			var quantity: int = item_info.get("quantity", 1)
			slot_node.display_item(ItemDatabase.get_item_icon(item_id), quantity)

			# === PHẦN KẾT NỐI NÚT BẤM ===
			# Chỉ kết nối tín hiệu "pressed" nếu ô đó được phép click
			if is_clickable:
				# Ngắt kết nối cũ để tránh lỗi
				if slot_node.is_connected("pressed", _on_buyback_hero_item_selected):
					slot_node.pressed.disconnect(_on_buyback_hero_item_selected)
				# Kết nối mới
				slot_node.pressed.connect(_on_buyback_hero_item_selected.bind(item_info))
		else:
			slot_node.display_item(null, 0)
	

func _create_slots_for_grid(grid: GridContainer, slot_array: Array, amount: int, mouse_enter_callback: Callable, pressed_callback: Callable = Callable()):
	# ... (code xóa ô cũ và dọn dẹp mảng giữ nguyên) ...
	for child in grid.get_children():
		child.queue_free()
	slot_array.clear()

	for i in range(amount):
		var new_slot = ItemSlotScene.instantiate()
		slot_array.append(new_slot)
		grid.add_child(new_slot)

		# Kết nối tín hiệu tooltip (đã có)
		new_slot.mouse_entered.connect(mouse_enter_callback.bind(i))
		new_slot.mouse_exited.connect(_on_item_slot_mouse_exited)

		# === PHẦN SỬA LỖI QUAN TRỌNG ===
		# Kết nối tín hiệu nhấn nút (nếu có)
		if pressed_callback.is_valid():
			new_slot.pressed.connect(pressed_callback.bind(i))
		# ==============================

func _update_player_info_bar():
	# Cập nhật các Label ở thanh trên cùng với dữ liệu từ PlayerStats
	if is_instance_valid(player_name_label):
		player_name_label.text = "Tên: " + PlayerStats.player_name
		
	if is_instance_valid(player_level_label):
		player_level_label.text = "Cấp: " + str(PlayerStats.player_level)

	if is_instance_valid(player_gold_label):
		# Sử dụng player_gold thay vì gold (gold là của hero)
		player_gold_label.text = "Vàng (Kho): " + str(PlayerStats.player_gold)

	if is_instance_valid(player_diamonds_label):
		player_diamonds_label.text = "Kim Cương: " + str(PlayerStats.player_diamonds)

# Hàm này được gọi khi tín hiệu "warehouse_changed" được phát ra
func _update_warehouse_display():
	var wh: Array = PlayerStats.warehouse
	var has_scroll = false # Bắt đầu với giả định là không có cuộn giấy
	
	# === VÒNG LẶP DUY NHẤT ĐỂ XỬ LÝ MỌI THỨ ===
	# Lặp qua tất cả các ô slot trong giao diện Nhà kho
	for i in range(warehouse_slots.size()):
		var slot_node = warehouse_slots[i]
		var item_info = wh[i] if i < wh.size() else null
		
		# --- Nhiệm vụ 1: Hiển thị vật phẩm (như cũ) ---
		if item_info and item_info.has("id"):
			var item_id: String = item_info["id"]
			var quantity: int = item_info.get("quantity", 1)
			var item_icon = ItemDatabase.get_item_icon(item_id)
			slot_node.display_item(item_icon, quantity)
			
			# --- Nhiệm vụ 2: Kiểm tra xem có phải là cuộn giấy không ---
			if item_id == "summon_scroll":
				has_scroll = true
		else:
			# Nếu không có vật phẩm, làm trống ô đó
			slot_node.display_item(null, 0)
			
	# Sau khi đã quét xong toàn bộ nhà kho, cập nhật trạng thái nút Summon
	summon_button.disabled = not has_scroll

func _on_rest_button_pressed():
	if not is_instance_valid(_current_hero):
		print("Vui long chon mot Hero truoc!")
		return

	# Hỏi PlayerStats xem cửa nhà trọ ở đâu
	var inn_position = PlayerStats.get_inn_entrance_position()

	if inn_position == Vector2.ZERO:
		return # Dừng lại nếu có lỗi

	# Ra lệnh cho Hero di chuyển đến vị trí đó
	_current_hero.di_den_diem(inn_position)
	
func _on_hero_arrived_at_inn(hero: Hero):
	# Kiểm tra 1: Scene có được load đúng không?
	if not InnRoomSelectionScene:
		push_error("LOI: InnRoomSelectionScene chua duoc load! Kiem tra lai duong dan preload.")
		return
	# Kiểm tra 2: Tạo instance có thành công không?
	var inn_panel = InnRoomSelectionScene.instantiate()
	inn_panel.name = "InnRoomSelection"
	if not is_instance_valid(inn_panel):
		push_error("LOI: Khong the instantiate InnRoomSelectionScene!")
		return
	# Kết nối tín hiệu
	inn_panel.room_selected.connect(_on_inn_room_selected)
	inn_panel.panel_closed.connect(_on_inn_panel_closed)
	# Thêm vào game
	add_child(inn_panel)
	# Gọi hàm setup
	inn_panel.setup(hero)
	# Đóng băng AI
	hero.is_ui_interacting = true
	hero.doi_trang_thai(Hero.State.TRADING)
	# Hiển thị Panel
	inn_panel.show()
	inn_panel.move_to_front()

	
func _on_inn_room_selected(hero, inn_level):
	print("UI da nhan duoc lenh chon phong %d cho hero %s" % [inn_level, hero.name])

	# === KIỂM TRA SỨC KHỎE (QUAN TRỌNG) ===
	if hero.current_hp >= hero.max_hp and hero.current_sp >= hero.max_sp:
		print("UI: Hero da day mau, tu choi nghi ngoi.")
		FloatingTextManager.show_text("HP/SP đã đầy!", Color.RED, hero.global_position - Vector2(0, 150))
		
		# "Mở băng" AI và cho hero quay lại trạng thái bình thường
		hero.is_ui_interacting = false
		hero.doi_trang_thai(Hero.State.IDLE)
		return # <-- Dừng hàm tại đây
	# ======================================

	# Nếu cần hồi phục, mới ra lệnh cho Hero
	hero.start_resting(inn_level)
	hero.is_ui_interacting = false


# Được gọi khi người chơi đóng bảng mà không chọn gì
func _on_inn_panel_closed(hero):
	print("UI: Nguoi choi da dong bang chon phong.")
	# "Mở băng" AI của hero
	hero.is_ui_interacting = false
	hero.doi_trang_thai(Hero.State.IDLE)
		
func _on_backpack_slot_mouse_entered(slot_index: int):
	if not is_instance_valid(_current_hero): return
	if slot_index < 0 or slot_index >= _current_hero.inventory.size(): return

	var item_info = _current_hero.inventory[slot_index]
	if item_info and item_info.has("id"):
		item_tooltip.update_tooltip(item_info["id"])
		item_tooltip.show()

# Xử lý khi di chuột vào ô NHÀ KHO
func _on_warehouse_slot_mouse_entered(slot_index: int):
	if slot_index < 0 or slot_index >= PlayerStats.warehouse.size(): return
	
	var item_info = PlayerStats.warehouse[slot_index]
	if item_info and item_info.has("id"):
		item_tooltip.update_tooltip(item_info["id"])
		# Chỉ ra lệnh "hiện", không cần đặt vị trí ở đây nữa
		item_tooltip.show()

# Hàm này được gọi khi Panel Chế tác bị đóng
func _on_crafting_panel_closed(_hero):
	pass
		
func _on_buyback_hero_item_selected(item_info: Dictionary):
	# Tạo một Bảng Chọn Số Lượng mới
	var quantity_panel = BuybackQuantityPanelScene.instantiate()

	# Lắng nghe tín hiệu xác nhận mua từ bảng đó
	quantity_panel.purchase_confirmed.connect(_on_purchase_confirmed)

	# Thêm vào game và gọi hàm setup
	add_child(quantity_panel)
	quantity_panel.setup(_hero_for_buyback, item_info)

# Được gọi khi người chơi nhấn nút "Mua Lại" trên Bảng Chọn Số Lượng
func _on_purchase_confirmed(hero: Hero, item_id: String, quantity: int):
	var item_data = ItemDatabase.get_item_data(item_id)
	var total_cost = item_data.get("price", 0) * quantity

	# 1. Kiểm tra tiền của Người Chơi
	if PlayerStats.player_gold < total_cost:
		print("Nguoi choi khong du vang!")
		return # Giao dịch thất bại

	# 2. Thực hiện giao dịch
	var hero_sold_item = hero.remove_item_from_inventory(item_id, quantity)

	# Chỉ tiếp tục nếu hero thực sự đã bán được đồ
	if hero_sold_item:
		PlayerStats.spend_player_gold(total_cost)
		PlayerStats.add_item_to_warehouse(item_id, quantity)
		hero.add_gold(total_cost)
		print("Giao dich thanh cong!")
	else:
		print("Giao dich that bai! Hero khong co du so luong de ban.")

	# 3. Cập nhật lại toàn bộ giao diện sau khi giao dịch
	_update_buyback_panel()

func _on_open_job_change_panel(hero_to_change: Hero):
	# Khi nhận được tín hiệu, ra lệnh cho panel mở ra và truyền Hero vào
	job_change_panel.open_panel(hero_to_change)
	
func _on_blacksmith_panel_requested():
	var crafting_panel = CraftingPanelScene.instantiate()
	# Kết nối tín hiệu đóng panel (nếu cần)
	crafting_panel.panel_closed.connect(_on_crafting_panel_closed.bind(null)) # null vì không có hero nào liên quan
	add_child(crafting_panel)
	crafting_panel.setup("blacksmith") # Mở panel với đúng loại chế tác

func _on_alchemist_panel_requested():
	var crafting_panel = CraftingPanelScene.instantiate()
	crafting_panel.panel_closed.connect(_on_crafting_panel_closed.bind(null))
	add_child(crafting_panel)
	crafting_panel.setup("alchemist")
	
func _on_hero_sp_changed(current_sp, max_sp):
	# Chỉ cập nhật nếu panel thông tin đang hiển thị
	if hero_info_panel.visible and is_instance_valid(_current_hero):
		# Lấy các giá trị bonus để hiển thị cho đẹp
		var sp_goc = snapped(max_sp - _current_hero.bonus_max_sp, 0.01)
		var sp_bonus = snapped(_current_hero.bonus_max_sp, 0.01)

		# Cập nhật text của info_sp_label
		info_sp_label.text = "SP: %d/%s" % [int(current_sp), str(roundi(sp_goc))] + ("[color=cyan] + %s[/color]" % str(roundi(sp_bonus)) if sp_bonus > 0 else "")


func _on_potion_shop_button_pressed() -> void:
	if not is_instance_valid(_current_hero): return
	var target_pos = PlayerStats.get_potion_seller_position()
	if target_pos != Vector2.ZERO:
		_current_hero.di_den_diem(target_pos)
		shop_list_panel.hide()
		main_command_menu.show()

func _on_hero_arrived_at_potion_shop(hero: Hero):
	hero.is_ui_interacting = true
	hero.doi_trang_thai(Hero.State.TRADING)
	
	var shop_panel = ShopPanelScene.instantiate()
	shop_panel.item_tooltip = item_tooltip 
	add_child(shop_panel)
	shop_panel.setup("potion", hero)

func _on_job_change_button_pressed():
	if not is_instance_valid(_current_hero): return

	var target_pos = PlayerStats.get_job_changer_position()
	if target_pos != Vector2.ZERO:
		print("UI: Ra lệnh cho Hero '%s' đi đến NPC Chuyển Nghề." % _current_hero.hero_name)
		_current_hero.di_den_diem(target_pos)
		
func _on_go_to_equipment_shop_button_pressed():
	if not is_instance_valid(_current_hero):
		print("Vui lòng chọn một Hero trước khi mua sắm!")
		return
	var target_pos = PlayerStats.get_equipment_seller_position()
	if target_pos != Vector2.ZERO:
		_current_hero.di_den_diem(target_pos)
		shop_list_panel.hide()
		main_command_menu.show()

func _on_hero_arrived_at_equipment_shop(hero: Hero):
	hero.is_ui_interacting = true
	hero.doi_trang_thai(Hero.State.TRADING)

	var shop_panel = ShopPanelScene.instantiate()
	shop_panel.item_tooltip = item_tooltip 
	add_child(shop_panel)
	# Gọi setup với type là "equipment"
	shop_panel.setup("equipment", hero)

func _on_village_upgrade_button_pressed():
	# Tạo một instance mới mỗi lần nhấn để đảm bảo dữ liệu luôn được làm mới
	var upgrade_panel = VillageUpgradePanelScene.instantiate()
	add_child(upgrade_panel)
	# Không cần gọi setup vì panel sẽ tự lấy dữ liệu từ PlayerStats

func _update_hero_count_display(_new_level = 0):
	var current_count = PlayerStats.get_current_hero_count()
	var max_count = PlayerStats.get_max_heroes()

	var text_to_display = "Hero: %d/%d" % [current_count, max_count]

	# Nếu số lượng hiện tại đã bằng hoặc lớn hơn giới hạn
	if current_count >= max_count:
		# Dùng BBCode để tô màu đỏ
		hero_count_label.text = "[color=red]%s MAX[/color]" % text_to_display
	else:
		# Trả về màu mặc định
		hero_count_label.text = text_to_display

func _on_barracks_button_pressed():
	var barracks_panel = HeroBarracksPanelScene.instantiate()
	# Kết nối tín hiệu mới từ panel kho hero
	barracks_panel.display_hero_info_requested.connect(_on_display_barracks_hero_info)
	add_child(barracks_panel)
	
func _on_display_barracks_hero_info(hero_from_barracks: Hero):
	print("\n--- DEBUG INFO PANEL ---")
	print("1. UI đã nhận tín hiệu 'display_hero_info_requested'.")
	if is_instance_valid(hero_from_barracks):
		print("   -> Hero nhận được từ sảnh: ", hero_from_barracks.name)
	else:
		print("   -> LỖI: Hero nhận được không hợp lệ (null)!")
		return
	# Gọi hàm cập nhật với Hero được gửi từ kho
	_update_hero_info_panel(hero_from_barracks)
	# Hiển thị panel
	hero_info_panel.show()
	hero_info_panel.move_to_front()
	print("4. Đã yêu cầu HeroInfoPanel hiển thị.")
	print("------------------------\n")
