#res://script/ui.gd
extends CanvasLayer
class_name UIController

# --- CÁC HẰNG SỐ SCENE ---
const ItemSlotScene = preload("res://Scene/UI/item_slot.tscn")
const RespawnBarScene = preload("res://UI/respawn_bar.tscn")
const InnRoomSelectionScene = preload("res://Scene/inn_room_selection.tscn")
const CraftingPanelScene = preload("res://Scene/UI/crafting_panel.tscn")
const BuybackQuantityPanelScene = preload("res://Scene/UI/buyback_quantity_panel.tscn")
const ShopPanelScene = preload("res://Scene/UI/shop_panel.tscn")
const HeroBarracksPanelScene = preload("res://Scene/UI/hero_barracks_panel.tscn")
const CraftingQuantityPanelScene = preload("res://Scene/UI/crafting_quantity_panel.tscn")
const VillageUpgradePanelScene = preload("res://Scene/UI/village_upgrade_panel.tscn")
const JobSkillPanelScene = preload("res://Scene/UI/job_skill_panel.tscn") # <-- THAY ĐÚNG ĐƯỜNG DẪN
const SkillSlotScene = preload("res://Scene/UI/skill_slot.tscn")
const ActiveSkillSlotScene = preload("res://Scene/UI/active_skill_slot.tscn")
var _active_skill_slots_ui: Array = []
# --- LỘ TRÌNH NGHỀ ---
const HERO_JOB_PROGRESSION = ["Novice", "Swordsman", "Knight"] # <-- DANH SÁCH LỘ TRÌNH NGHỀ

# ====================
# BIẾN THAM CHIẾU NODE (QUAN TRỌNG: KIỂM TRA LẠI ĐƯỜNG DẪN)
# ====================
# --- BIẾN TRẠNG THÁI ---
var _current_hero: Hero = null
var _hero_in_view: Hero = null
var _main_camera: Camera2D
var _active_respawn_bars: Dictionary = {}
const MAX_SKILL_SLOTS = 4
var equipped_skills: Array = []

var _potion_cooldowns: Dictionary = {
	"POTION_1": 0.0,
	"POTION_2": 0.0,
	"POTION_3": 0.0
}

# --- CÁC PANEL CHÍNH ---
@onready var selected_hero_panel: Panel = $SelectedHeroPanel
@onready var hero_info_panel: PanelContainer = $HeroInfoPanel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var warehouse_panel: PanelContainer = $Warehouse
@onready var main_command_menu: PanelContainer = $MainCommandMenu
@onready var shop_list_panel: PanelContainer = $ShopListPanel
@onready var movement_buttons: Control = $MovementButtons
@onready var buyback_panel: PanelContainer = $BuybackPanel
@onready var job_change_panel: JobChangePanel = $JobChangePanel
@onready var bottom_bar_container: HBoxContainer = $HBoxContainer
# --- THANH THÔNG TIN NGƯỜI CHƠI ---
@onready var player_name_label: Label = $PlayerInfoBar/HBoxContainer/PlayerNameLabel
@onready var player_level_label: Label = $PlayerInfoBar/HBoxContainer/PlayerLevelLabel
@onready var player_gold_label: Label = $PlayerInfoBar/HBoxContainer/PlayerGoldLabel
@onready var player_diamonds_label: Label = $PlayerInfoBar/HBoxContainer/PlayerDiamondsLabel
@onready var hero_count_label: RichTextLabel = $PlayerInfoBar/HBoxContainer/HeroCountLabel
@onready var village_upgrade_button: Button = $PlayerInfoBar/HBoxContainer/VillageUpgradeButton
# --- PANEL HERO ĐƯỢC CHỌN (HUD NHỎ) ---
@onready var name_label: Label = $SelectedHeroPanel/VBoxContainer/HBoxContainer2/NameLabel
@onready var rarity_label: RichTextLabel = $SelectedHeroPanel/VBoxContainer/HBoxContainer2/RarityLabel
@onready var job_change_button: Button = $SelectedHeroPanel/VBoxContainer/HBoxContainer/JobChangeButton
@onready var hp_bar_fill: NinePatchRect = $SelectedHeroPanel/VBoxContainer/HPBar/HP_Fill
@onready var hp_bar_bg: NinePatchRect = $SelectedHeroPanel/VBoxContainer/HPBar/HP_Background
@onready var hp_label: Label = $SelectedHeroPanel/VBoxContainer/HPBar/HP_Label
@onready var sp_bar_fill: NinePatchRect = $SelectedHeroPanel/VBoxContainer/SP/SP_Fill
@onready var sp_bar_bg: NinePatchRect = $SelectedHeroPanel/VBoxContainer/SP/SP_Background
@onready var sp_label: Label = $SelectedHeroPanel/VBoxContainer/SP/SP_Label
@onready var exp_bar_fill: NinePatchRect = $SelectedHeroPanel/VBoxContainer/ExpBar/ExpFill
@onready var exp_bar_bg: NinePatchRect = $SelectedHeroPanel/VBoxContainer/ExpBar/ExpBackground
@onready var exp_label: Label = $SelectedHeroPanel/VBoxContainer/ExpBar/Exp_Label

# ----- Panel Thông tin Chi tiết -----
@onready var info_name_label: Label = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/Info_NameLabel"
@onready var info_job_label: Label = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer2/Info_JobLabel"
@onready var info_rarity_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer2/info_rarityLabel"
@onready var info_level_label: Label = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer4/Info_LevelLabel"
@onready var info_exp_label: Label = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/Info_ExpLabel"
@onready var info_hp_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/Info_HPLabel"
@onready var info_sp_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/Info_SPLabel"
@onready var info_str_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_StrLabel"
@onready var info_agi_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_AgiLabel"
@onready var info_vit_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_VitLabel"
@onready var info_int_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_IntLabel"
@onready var info_dex_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_DexLabel"
@onready var info_luk_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer/Info_LukLabel"
@onready var info_atk_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer3/Info_AtkLabel"
@onready var info_matk_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer3/Info_MatkLabel"
@onready var info_def_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/Info_DefLabel"
@onready var info_mdef_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/Info_MdefLabel"
@onready var info_hit_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/Info_HitLabel"
@onready var info_flee_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/info_fleeLabel"
@onready var info_crit_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/Info_CritLabel"
@onready var info_critDame_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/VBoxContainer2/info_critDameLabel"
@onready var info_attackspeed_label: RichTextLabel = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/Info_AttackSpeedLabel"

#=====================Nút nâng cấp tự do =============================
@onready var stat_buttons: Array[Button] = [
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button", #STR
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button2", #AGI
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button3", # VIT
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button4", #INT
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button5", #DEX
	$"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer/HBoxContainer8/VBoxContainer2/Button6", #LUCK
]
@onready var free_points_label: Label = $"HeroInfoPanel/HeroInfoPanel/Thông tin/VBoxContainer/HBoxContainer4/FreePointsLabel"
@onready var skill_list_container: VBoxContainer = hero_info_panel.find_child("SkillListContainer")
@onready var active_skill_grid: GridContainer = hero_info_panel.find_child("ActiveSkillGrid")
@onready var skill_points_label: Label = hero_info_panel.find_child("SkillPointsLabel")
@onready var sa_thai_button = $"HeroInfoPanel/HeroInfoPanel/Thông tin/FunctionButtons/SaThaiButton" # <-- Sửa đường dẫn cho đúng
@onready var close_button = $"HeroInfoPanel/HeroInfoPanel/Thông tin/FunctionButtons/CloseButton"

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
@onready var warehouse_grid: GridContainer = $Warehouse/VBoxContainer/Panel/ScrollContainer/GridContainer
@onready var warehouse_button: Button = $HBoxContainer/WarehouseButton
@onready var close_warehouse_button: Button = $Warehouse/VBoxContainer/CloseButton
@onready var hero_gold_label: Label = $InventoryPanel/HBoxContainer/BackpackBG/MarginContainer/BackpackUI/HeroGoldLabel
@onready var respawn_bar_container: VBoxContainer = $RespawnBarContainer

# ------- phần MovementButtons-----
@onready var go_to_village_button: Button = $MovementButtons/VBox/GoToVillageButton
@onready var go_to_forest_button: Button = $MovementButtons/VBox/GoToForestButton
@onready var go_to_forest2_button: Button = $MovementButtons/VBox/GoToForestButton2
@onready var go_to_forest3_button: Button = $MovementButtons/VBox/GoToForestButton3
#-------------- Phần Shop mua bán đồ BuybackPanel----------------------
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

@export var blacksmith_npc: StaticBody2D
@export var alchemist_npc: StaticBody2D
@export var potion_seller_npc: StaticBody2D
@export var equipment_seller_npc: StaticBody2D

var hero_hien_tai: Hero

var current_open_panel: Control = null
var village_upgrade_panel_instance = null

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
# HÀM TÍCH HỢP CỦA GODOT
# ====================
func _ready() -> void:
	await get_tree().process_frame
	
	PlayerStats.register_ui_controller(self)
	_main_camera = get_tree().root.get_camera_2d()
	
	# Ẩn các panel chính lúc ban đầu
	selected_hero_panel.visible = false
	hero_info_panel.visible = false
	inventory_panel.visible = false
	movement_buttons.visible = false
	warehouse_panel.visible = false
	buyback_panel.visible = false
	shop_list_panel.hide()
	main_command_menu.hide()
	
	# Kết nối các tín hiệu toàn cục
	_connect_global_signals()
	
	# Kết nối các nút bấm trên giao diện
	_connect_button_signals()
	
	# Cập nhật giao diện lần đầu
	_update_player_info_bar()
	_update_warehouse_display()
	_update_hero_count_display()
	_update_backpack_display()
	
	for slot_key in equipment_slots.keys():
		equipment_slots[slot_key].pressed.connect(_on_equipment_slot_pressed.bind(slot_key))
	for slot_key in equipment_slots.keys():
		var slot_node = equipment_slots[slot_key]
		slot_node.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(slot_key))
		slot_node.mouse_exited.connect(_on_equipment_slot_mouse_exited)
		
	_create_slots_for_grid(backpack_grid, backpack_slots, 20, Callable(self, "_on_backpack_slot_mouse_entered"), Callable(self, "_on_backpack_slot_pressed"))
	_create_slots_for_grid(warehouse_grid, warehouse_slots, 100, Callable(self, "_on_warehouse_slot_mouse_entered"))
	_create_slots_for_grid(hero_buyback_grid, hero_buyback_slots, 20, Callable(self, "_on_backpack_slot_mouse_entered"))
	_create_slots_for_grid(warehouse_buyback_grid, warehouse_buyback_slots, 100, Callable(self, "_on_warehouse_slot_mouse_entered"))
	
	for child in active_skill_grid.get_children():
		child.queue_free()

	for i in range(MAX_SKILL_SLOTS):
		var new_slot = ActiveSkillSlotScene.instantiate()
		active_skill_grid.add_child(new_slot)
		_active_skill_slots_ui.append(new_slot)
	
	
func _connect_global_signals():
	GameEvents.hero_selected.connect(_on_hero_selected)
	GameEvents.hero_arrived_at_shop.connect(_on_hero_arrived_at_shop)
	GameEvents.hero_arrived_at_inn.connect(_on_hero_arrived_at_inn)
	GameEvents.hero_arrived_at_potion_shop.connect(_on_hero_arrived_at_potion_shop)
	GameEvents.hero_arrived_at_equipment_shop.connect(_on_hero_arrived_at_equipment_shop)
	GameEvents.respawn_started.connect(_on_respawn_started)
	GameEvents.respawn_finished.connect(_on_respawn_finished)
	PlayerStats.player_stats_changed.connect(_update_player_info_bar)
	PlayerStats.warehouse_changed.connect(_update_warehouse_display)
	PlayerStats.hero_count_changed.connect(_update_hero_count_display)
	PlayerStats.village_level_changed.connect(_update_hero_count_display)
	PlayerStats.player_stats_changed.connect(_update_warehouse_display)
	
func _connect_button_signals():
	selected_hero_panel.gui_input.connect(_on_panel_gui_input)
	hero_info_panel.gui_input.connect(_on_panel_gui_input)
	inventory_panel.gui_input.connect(_on_panel_gui_input)
	bottom_bar_container.gui_input.connect(_on_panel_gui_input)
	movement_buttons.gui_input.connect(_on_panel_gui_input)
	barracks_button.pressed.connect(_on_barracks_button_pressed)
	job_change_button.pressed.connect(_on_job_change_button_pressed)
	village_upgrade_button.pressed.connect(_on_village_upgrade_button_pressed)
	close_warehouse_button.pressed.connect(_on_close_button_pressed)
	close_buyback_button.pressed.connect(_on_close_buyback_button_pressed)
	sa_thai_button.pressed.connect(_on_sa_thai_button_pressed)
	
	var job_changer_npc = get_tree().get_root().get_node("World/Village_Boundary/JobChangerNpc")
	
	if is_instance_valid(blacksmith_npc):
		blacksmith_npc.blacksmith_panel_requested.connect(_on_blacksmith_panel_requested)
	else:
		push_warning("Chưa kết nối với blacksmith NPC")
	if is_instance_valid(alchemist_npc):
		alchemist_npc.alchemist_panel_requested.connect(_on_alchemist_panel_requested)
	else:
		push_warning("UI CHƯA ĐƯỢC KẾT NỐI VỚI ALCHEMIST NPC!")
	if is_instance_valid(job_changer_npc):
		job_changer_npc.open_job_change_panel.connect(_on_open_job_change_panel)
	else:
		push_warning("Không tìm thấy NPC chuyển nghề trong World")
	
	
func _close_all_main_panels():
	get_tree().call_group("panels", "hide")
	
func _process(_delta: float) -> void:
	if item_tooltip.visible:
		item_tooltip.position = get_viewport().get_mouse_position() + Vector2(30, 30)
	for hero in _active_respawn_bars:
		var bar = _active_respawn_bars[hero]
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

func _on_str_button_pressed():
	_add_point_to_stat("str")

func _on_agi_button_pressed():
	_add_point_to_stat("agi")

func _on_vit_button_pressed():
	_add_point_to_stat("vit")

func _on_int_button_pressed():
	_add_point_to_stat("int")

func _on_dex_button_pressed():
	_add_point_to_stat("dex")

func _on_luk_button_pressed():
	_add_point_to_stat("luk")

func _add_point_to_stat(stat_name: String):
	# Giao diện chỉ cần kiểm tra có hero không và ra lệnh, không cần tính toán gì cả
	if is_instance_valid(_current_hero):
		_current_hero.nang_cap_chi_so(stat_name)

func _update_stat_buttons_visibility():
	if not is_instance_valid(_current_hero):
		for b in stat_buttons: 
			b.hide()
		free_points_label.hide()
		return

	var has_points = _current_hero.free_points > 0

	# Ẩn/hiện nút cộng điểm
	for b in stat_buttons:
		b.visible = has_points

	# Ẩn/hiện label
	free_points_label.visible = has_points
	if has_points:
		free_points_label.text = "Điểm tự do: %d" % _current_hero.free_points


# ===================================================
# === HÀM MỚI ĐỂ XỬ LÝ CLICK XUYÊN UI ===
# ===================================================

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		
# ====================
# HÀM XỬ LÝ TÍN HIỆU
# ====================
func _on_summon_button_pressed():
	PlayerStats.try_to_summon_hero()

func _on_hero_selected(hero: Hero) -> void:
	var previous_hero = _current_hero
	if hero == previous_hero:
		_current_hero = null
	else:
		_current_hero = hero
	
	# 1. NGẮT KẾT NỐI KHỎI HERO CŨ (Luôn dùng 'previous_hero')
	if is_instance_valid(previous_hero):
		previous_hero.hp_changed.disconnect(_update_hp_bar)
		previous_hero.sp_changed.disconnect(_update_sp_bar)
		previous_hero.exp_changed.disconnect(_update_exp_bar)
		if previous_hero.is_connected("stats_updated", _on_hero_stats_updated):
			previous_hero.stats_updated.disconnect(_on_hero_stats_updated)
		if previous_hero.is_connected("equipment_changed", _update_equipment_display):
			previous_hero.equipment_changed.disconnect(_update_equipment_display)
		if previous_hero.is_connected("inventory_changed", _on_inventory_changed):
			previous_hero.inventory_changed.disconnect(_on_inventory_changed)
		if previous_hero.is_connected("gold_changed", _on_player_stats_gold_changed):
			previous_hero.gold_changed.disconnect(_on_player_stats_gold_changed)
		if previous_hero.is_connected("sp_changed", _on_hero_sp_changed):
			previous_hero.sp_changed.disconnect(_on_hero_sp_changed)
		if previous_hero.is_connected("free_points_changed", _on_free_points_changed):
			previous_hero.free_points_changed.disconnect(_on_free_points_changed)
		if previous_hero.is_connected("skill_activated", _on_hero_skill_activated):
			previous_hero.skill_activated.disconnect(_on_hero_skill_activated)
		# SỬA LẠI: Ngắt kết nối từ 'previous_hero'
		if previous_hero.is_connected("potion_cooldown_started", _on_hero_potion_cooldown_started):
			previous_hero.potion_cooldown_started.disconnect(_on_hero_potion_cooldown_started)

	# 2. KẾT NỐI VỚI HERO MỚI (Luôn dùng '_current_hero')
	if is_instance_valid(_current_hero):
		_current_hero.hp_changed.connect(_update_hp_bar)
		_current_hero.sp_changed.connect(_update_sp_bar)
		_current_hero.exp_changed.connect(_update_exp_bar)
		_current_hero.stats_updated.connect(_on_hero_stats_updated)
		_current_hero.equipment_changed.connect(_update_equipment_display)
		_current_hero.inventory_changed.connect(_on_inventory_changed)
		_current_hero.gold_changed.connect(_on_player_stats_gold_changed)
		_current_hero.sp_changed.connect(_on_hero_sp_changed)
		_current_hero.free_points_changed.connect(_on_free_points_changed)
		_current_hero.skill_activated.connect(_on_hero_skill_activated)
		# SỬA LẠI: Kết nối với '_current_hero'
		_current_hero.potion_cooldown_started.connect(_on_hero_potion_cooldown_started)

	# 3. CẬP NHẬT GIAO DIỆN (Phần này giữ nguyên)
	var is_hero_selected = is_instance_valid(_current_hero)
	selected_hero_panel.visible = is_hero_selected
	main_command_menu.visible = is_hero_selected
	
	# Luôn đóng các panel chi tiết khi đổi hero
	hero_info_panel.visible = false
	inventory_panel.visible = false
	movement_buttons.hide()
	shop_list_panel.hide()
	
	if is_hero_selected:
		_update_selected_hero_panel()

	# 5. CẬP NHẬT DỮ LIỆU
	if is_hero_selected:
		_update_selected_hero_panel()
		_update_gold_display(_current_hero.gold)
		_update_backpack_display()
		_update_equipment_display()
		_update_stat_buttons_visibility()
	else:
		_update_gold_display(0)
		_update_backpack_display()
		_update_equipment_display()
		_update_stat_buttons_visibility()
		
func _update_hp_bar(current_hp, max_hp):
	var percentage = 0.0
	if max_hp > 0: percentage = float(current_hp) / float(max_hp)
	hp_bar_fill.size.x = hp_bar_bg.size.x * percentage
	hp_label.text = "%d/%d HP" % [int(current_hp), int(max_hp)]

func _update_sp_bar(current_sp, max_sp):
	var percentage = 0.0
	if max_sp > 0: percentage = float(current_sp) / float(max_sp)
	sp_bar_fill.size.x = sp_bar_bg.size.x * percentage
	sp_label.text = "%d/%d SP" % [int(current_sp), int(max_sp)]

func _update_exp_bar(current_exp, max_exp):
	var percentage = 0.0
	if max_exp > 0: percentage = float(current_exp) / float(max_exp)
	exp_bar_fill.size.x = exp_bar_bg.size.x * percentage
	exp_label.text = "%d/%d EXP" % [int(current_exp), int(max_exp)]
	
func _on_hp_bar_mouse_entered():
	hp_label.show()

func _on_hp_bar_mouse_exited():
	hp_label.hide()

func _on_sp_bar_mouse_entered():
	sp_label.show()

func _on_sp_bar_mouse_exited():
	sp_label.hide()

func _on_exp_bar_mouse_entered():
	exp_label.show()

func _on_exp_bar_mouse_exited():
	exp_label.hide()
		
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
		
	var npc_position = PlayerStats.get_shop_npc_position()
	
	if npc_position == Vector2.ZERO:
		return
		
	_current_hero.di_den_diem(npc_position)
	
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
	if not is_instance_valid(_current_hero): return
	
	# Gán hero đang được xem để các hàm khác sử dụng
	_hero_in_view = _current_hero
	hero_info_panel.show()
	
	# Cập nhật tất cả thông tin (chỉ số, skill...)
	_update_hero_info_panel() # <- Hàm này đã bao gồm việc cập nhật skill points label
	
	if is_instance_valid(skill_list_container):
		skill_list_container.visible = true
	if is_instance_valid(active_skill_grid):
		active_skill_grid.visible = true
	if is_instance_valid(skill_points_label):
		skill_points_label.visible = true
	
	# === PHẦN CHỈNH SỬA QUAN TRỌNG ===
	_build_skill_tree_panel() # Xây dựng lại cây skill từ đầu
	_update_active_skill_slots() # Cập nhật các ô skill đã trang bị
	# =================================

	# Lắng nghe tín hiệu thay đổi skill từ hero
	var skill_tree_signal = _hero_in_view.skill_tree_changed
	if not skill_tree_signal.is_connected(_on_hero_skill_tree_changed):
		skill_tree_signal.connect(_on_hero_skill_tree_changed)

func _refresh_skill_panel():
	if not is_instance_valid(_hero_in_view) or not is_instance_valid(skill_list_container):
		return

	for job_panel in skill_list_container.get_children():
		# Kiểm tra xem nó có phải JobSkillPanel và biến skill_grid của nó có tồn tại không
		if job_panel is JobSkillPanel and is_instance_valid(job_panel.skill_grid):
			
			# Lặp qua các SkillSlot và ra lệnh cập nhật
			for slot in job_panel.skill_grid.get_children():
				if slot is SkillSlot:
					slot.refresh_display()
		else:
			push_warning("UI Refresh: Bỏ qua một node không hợp lệ trong SkillListContainer.")

func _on_skill_upgrade_requested(skill_id: String):
	print(">>> TRAM GAC 3: UIController da nhan lenh UPGRADE skill '%s'!" % skill_id) # <-- THÊM DÒNG NÀY
	if is_instance_valid(_hero_in_view):
		print("    -> Ra lenh cho Hero...")
		_hero_in_view.learn_or_upgrade_skill(skill_id)

func _on_skill_equip_requested(skill_id: String):
	print(">>> TRAM GAC 3: UIController da nhan lenh EQUIP skill '%s'!" % skill_id)
	if is_instance_valid(_hero_in_view):
		_hero_in_view.equip_skill(skill_id)
		
func _on_skill_unequip_requested(skill_id: String):
	print(">>> TRAM GAC 3: UIController da nhan lenh UNEQUIP skill '%s'!" % skill_id)
	if is_instance_valid(_hero_in_view):
		_hero_in_view.unequip_skill(skill_id)

func _on_hero_skill_tree_changed():
	if hero_info_panel.visible and is_instance_valid(_hero_in_view):
		# Cập nhật lại tất cả mọi thứ liên quan đến skill
		_update_hero_info_panel() # Cập nhật số điểm skill
		_refresh_skill_panel() # "Vẽ" lại các skill slot (ví dụ: nút bấm từ disable -> enable)
		_update_active_skill_slots() # Cập nhật icon các skill đã trang bị

func _update_active_skill_slots():
	if not is_instance_valid(_hero_in_view):
		# Nếu không có hero, làm trống tất cả các slot
		for slot in _active_skill_slots_ui:
			slot.display_skill("") # Truyền chuỗi rỗng là đúng
		return

	var equipped_skills_array = _hero_in_view.equipped_skills
	
	# Lặp qua các slot UI và gán skill tương ứng
	for i in range(_active_skill_slots_ui.size()):
		var slot_node = _active_skill_slots_ui[i]
		
		# Lấy skill_id hoặc null từ mảng của hero
		var skill_id_or_null = equipped_skills_array[i] if i < equipped_skills_array.size() else null
		
		# === PHẦN SỬA LỖI QUAN TRỌNG ===
		# Dùng str() để đảm bảo giá trị truyền vào luôn là String
		# Nếu skill_id_or_null là null, str() sẽ biến nó thành ""
		slot_node.display_skill(str(skill_id_or_null))
		# ================================
		
func _on_hero_skill_activated(skill_id: String, cooldown_duration: float):
	# Tìm đúng slot UI đang hiển thị skill đó và ra lệnh bắt đầu cooldown
	for slot in _active_skill_slots_ui:
		if slot._skill_id == skill_id:
			slot.start_cooldown(cooldown_duration)
			return # Dừng lại khi đã tìm thấy
			
func _build_tooltip_string_for_skill(skill_data: Dictionary, hero: Hero) -> String:
	var skill_id = skill_data.get("id", "") # Cần đảm bảo skill_data có id
	var hero_skill_level = hero.get_skill_level(skill_id)
	var max_level = skill_data.get("max_level", 1)
	
	var tooltip_string = "[font_size=28][color=gold]%s[/color][/font_size]\n" % skill_data.get("skill_name", "???")
	tooltip_string += "[font_size=20]Cấp %d / %d[/font_size]\n\n" % [hero_skill_level, max_level]

	if hero_skill_level > 0:
		var effect_desc = skill_data.get("effects_per_level")[hero_skill_level - 1].get("description", "")
		tooltip_string += "Hiệu ứng: [color=cyan]%s[/color]" % effect_desc
	else:
		tooltip_string += "Chưa học"
		
	return tooltip_string
			
			
func _on_skill_upgrade_requested_static(skill_id: String):
	if is_instance_valid(_hero_in_view):
		# Ra lệnh cho hero đang được xem thực hiện việc học/nâng cấp
		_hero_in_view.learn_or_upgrade_skill(skill_id)

# Hàm được gọi khi nút "Trang bị" được nhấn
func _on_skill_equip_requested_static(skill_id: String):
	if is_instance_valid(_hero_in_view):
		_hero_in_view.equip_skill(skill_id)

# Hàm được gọi khi nút "Tháo" được nhấn
func _on_skill_unequip_requested_static(skill_id: String):
	if is_instance_valid(_hero_in_view):
		_hero_in_view.unequip_skill(skill_id)
		
		
func _build_skill_tree_panel():
	if not is_instance_valid(_hero_in_view): return
	if not is_instance_valid(skill_list_container):
		push_error("Lỗi UI: Không tìm thấy 'SkillListContainer'!")
		return

	# Dọn dẹp các bảng skill cũ
	for child in skill_list_container.get_children():
		child.queue_free()

	# Tìm vị trí của nghề hiện tại trong lộ trình
	var current_job_index = HERO_JOB_PROGRESSION.find(_hero_in_view.job_key)
	if current_job_index == -1:
		push_warning("Nghề '%s' của hero không có trong HERO_JOB_PROGRESSION." % _hero_in_view.job_key)
		current_job_index = 0
		
	# Lặp qua các nghề mà hero đã có
	for i in range(current_job_index + 1):
		var job_key = HERO_JOB_PROGRESSION[i]
		
		var new_job_panel = JobSkillPanelScene.instantiate()
		skill_list_container.add_child(new_job_panel)
		
		# Ra lệnh cho JobSkillPanel tự xây dựng các SkillSlot bên trong nó
		new_job_panel.build_for_job(job_key, _hero_in_view)

		# === NỐI DÂY TÍN HIỆU CUỐI CÙNG (QUAN TRỌNG NHẤT) ===
		# Kết nối tín hiệu từ JobSkillPanel về các hàm xử lý của UIController.
		# Đây chính là 3 dòng code còn thiếu để hoàn thiện luồng sự kiện.
		new_job_panel.upgrade_requested.connect(_on_skill_upgrade_requested)
		new_job_panel.equip_requested.connect(_on_skill_equip_requested)
		new_job_panel.unequip_requested.connect(_on_skill_unequip_requested)


func _on_close_info_button_pressed():
	hero_info_panel.visible = false
	_hero_in_view = null# Dọn dẹp "trí nhớ" để tránh lỗi

func _on_inventory_button_pressed():
	_close_all_main_panels()
	if is_instance_valid(_current_hero):
		inventory_panel.visible = not inventory_panel.visible
		hero_info_panel.visible = false
# ====================
# HÀM CẬP NHẬT GIAO DIỆN
# ====================
func _update_selected_hero_panel() -> void:
	if not is_instance_valid(_current_hero): return
	await get_tree().process_frame
	
	name_label.text = _current_hero.hero_name
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
	rarity_label.text = rarity_bbcode
	
		
	if _current_hero.job_key == "Novice" and _current_hero.level >= _current_hero.MAX_LEVEL_NOVICE:
		job_change_button.show()
	else:
		job_change_button.hide()
		
	_update_hp_bar(_current_hero.current_hp, _current_hero.max_hp)
	_update_sp_bar(_current_hero.current_sp, _current_hero.max_sp)
	_update_exp_bar(_current_hero.current_exp, _current_hero.exp_to_next_level)

func _update_hero_info_panel():
	if not is_instance_valid(_hero_in_view):
		hero_info_panel.hide()
		return
	
	skill_points_label.text = "Điểm kỹ năng: %d" % _hero_in_view.skill_points	
	
	info_name_label.text = "Tên: " + _hero_in_view.hero_name
	info_job_label.text = "Nghề: " + GameDataManager.get_job_display_name(_hero_in_view.job_key)
	var rarity = "Chưa rõ"
	if _hero_in_view.name.contains("("):
		rarity = _hero_in_view.name.substr(_hero_in_view.name.find("(") + 1, _hero_in_view.name.find(")") - _hero_in_view.name.find("(") - 1)
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
		
	info_level_label.text = "Cấp: " + str(_hero_in_view.level)
	info_exp_label.text = "EXP: %d/%d" % [_hero_in_view.current_exp, _hero_in_view.exp_to_next_level]
	# 1. Lấy ra các giá trị gốc và bonus từ hero
	var bonus_hp = snapped(_hero_in_view.bonus_max_hp, 0.01)
	var base_hp = snapped(_hero_in_view.max_hp - bonus_hp, 0.01)
	var bonus_sp = snapped(_hero_in_view.bonus_max_sp, 0.01)
	var base_sp = snapped(_hero_in_view.max_sp - bonus_sp, 0.01)
	var base_str = snapped(_hero_in_view.STR, 0.01)
	var bonus_str = snapped(_hero_in_view.bonus_str, 0.01)
	var base_agi = snapped(_hero_in_view.AGI, 0.01)
	var bonus_agi = snapped(_hero_in_view.bonus_agi, 0.01)
	var base_vit = snapped(_hero_in_view.VIT, 0.01)
	var bonus_vit = snapped(_hero_in_view.bonus_vit, 0.01)
	var base_intel = snapped(_hero_in_view.INTEL, 0.01)
	var bonus_intel = snapped(_hero_in_view.bonus_intel, 0.01)
	var base_dex = snapped(_hero_in_view.DEX, 0.01)
	var bonus_dex = snapped(_hero_in_view.bonus_dex, 0.01)
	var base_luk = snapped(_hero_in_view.LUK, 0.01)
	var bonus_luk = snapped(_hero_in_view.bonus_luk, 0.01)
	var bonus_def = snapped(_hero_in_view.bonus_def, 0.01)
	var base_def = snapped(_hero_in_view.def - bonus_def, 0.01)
	var bonus_mdef = snapped(_hero_in_view.bonus_mdef, 0.01)
	var base_mdef = snapped(_hero_in_view.mdef - bonus_mdef, 0.01)
	var bonus_hit = snapped(_hero_in_view.bonus_hit, 0.01)
	var base_hit = snapped(_hero_in_view.hit - bonus_hit - _hero_in_view.bonus_hit_hidden, 0.01)
	var bonus_flee = snapped(_hero_in_view.bonus_flee, 0.01)
	var base_flee = snapped(_hero_in_view.flee - bonus_flee, 0.01)
	var bonus_crit = snapped(_hero_in_view.bonus_crit_rate, 0.01)
	var base_crit = snapped(_hero_in_view.crit_rate - bonus_crit - _hero_in_view.bonus_crit_rate_hidden, 0.01)
	var bonus_crit_dame = snapped(_hero_in_view.bonus_crit_dame, 0.01)
	var base_crit_dame = snapped(_hero_in_view.crit_damage - bonus_crit_dame, 0.01)
	
	
	var current_hp_int = int(_hero_in_view.current_hp)
	info_hp_label.text = "HP: %d/%s" % [current_hp_int, str(roundi(base_hp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hp)) if bonus_hp > 0 else "")
	var current_sp_int = int(_hero_in_view.current_sp)
	info_sp_label.text = "SP: %d/%s" % [current_sp_int, str(roundi(base_sp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_sp)) if bonus_sp > 0 else "")
	
	info_str_label.text = "Sức mạnh: %s" % str(roundi(base_str)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_str)) if bonus_str > 0 else "")
	info_agi_label.text = "Nhanh nhẹn: %s" % str(roundi(base_agi)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_agi)) if bonus_agi > 0 else "")
	info_vit_label.text = "Thể lực: %s" % str(roundi(base_vit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_vit)) if bonus_vit > 0 else "")
	info_int_label.text = "Trí tuệ: %s" % str(roundi(base_intel)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_intel)) if bonus_intel > 0 else "")
	info_dex_label.text = "Độ chuẩn: %s" % str(roundi(base_dex)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_dex)) if bonus_dex > 0 else "")
	info_luk_label.text = "May mắn: %s" % str(roundi(base_luk)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_luk)) if bonus_luk > 0 else "")
	info_atk_label.text = "Sát thương: %d - %d" % [int(_hero_in_view.min_atk), int(_hero_in_view.max_atk)] 
	info_matk_label.text = "Sát thương phép: %d - %d" % [int(_hero_in_view.min_matk), int(_hero_in_view.max_matk)]
	info_def_label.text = "Phòng thủ: %s" % str(roundi(base_def)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_def)) if bonus_def > 0 else "")
	info_mdef_label.text = "Phòng thủ phép: %s" % str(roundi(base_mdef)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_mdef)) if bonus_mdef > 0 else "")
	info_hit_label.text = "Chính xác: %s" % str(roundi(base_hit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hit)) if bonus_hit > 0 else "")
	info_flee_label.text = "Tránh né: %s" % str(roundi(base_flee)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_flee)) if bonus_flee > 0 else "")
	info_crit_label.text = "Tỉ lệ trí mạng: %s%%" % str(snapped(base_crit, 0.1)) + ("[color=cyan] +%s%%[/color]" % str(snapped(bonus_crit, 0.1)) if bonus_crit > 0 else "")
	info_critDame_label.text = "ST chí mạng: x%s" % str(snapped(base_crit_dame, 0.1)) + ("[color=cyan] +%s[/color]" % str(snapped(bonus_crit_dame, 0.1)) if bonus_crit_dame > 0 else "")
	info_attackspeed_label.text = "Tốc độ đánh: %.2f giây/đòn" % _hero_in_view.attack_speed_calculated
	info_sp_label.text = "SP: %d/%d" % [int(_hero_in_view.current_sp), int(_hero_in_view.max_sp)]


# Hàm này được gọi khi tín hiệu "stats_updated" của hero được phát ra (khi lên cấp).
func _on_hero_stats_updated():
	if not is_instance_valid(_current_hero): return
	_update_selected_hero_panel()
	if hero_info_panel.visible:
		# Truyền Hero đang được chọn vào hàm
		_update_hero_info_panel()
		_update_stat_buttons_visibility()
		free_points_label.text = "Điểm tự do: %d" % _current_hero.free_points
		
func _on_free_points_changed():
	if is_instance_valid(_current_hero):
		# Cập nhật label và ẩn/hiện nút
		_update_stat_buttons_visibility()
		
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
	if is_instance_valid(_current_hero):
		var item_info = _current_hero.equipment.get(slot_key)
		if item_info:
			# SỬA Ở ĐÂY: Gọi trực tiếp đến item_tooltip và gửi cả dictionary
			item_tooltip.update_tooltip(item_info)
			item_tooltip.popup(Rect2(get_viewport().get_mouse_position(), item_tooltip.size))

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

func _on_warehouse_button_pressed() -> void:
	_close_all_main_panels()
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
		player_level_label.text = "Cấp: " + str(PlayerStats.village_level)

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
	summon_button.disabled = not PlayerStats.can_summon()

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
	if is_instance_valid(_current_hero):
		var item_info = _current_hero.inventory[slot_index]
		if item_info:
			# SỬA LẠI: Gọi thẳng tới tooltip và gửi cả dictionary
			item_tooltip.update_tooltip(item_info)
			item_tooltip.popup(Rect2(get_viewport().get_mouse_position(), item_tooltip.size))

# Xử lý khi di chuột vào ô NHÀ KHO
func _on_warehouse_slot_mouse_entered(slot_index: int):
	var item_info = PlayerStats.warehouse[slot_index]
	if item_info:
		# SỬA Ở ĐÂY:
		item_tooltip.update_tooltip(item_info)
		item_tooltip.popup(Rect2(get_viewport().get_mouse_position(), item_tooltip.size))

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
	crafting_panel.recipe_selected.connect(_on_crafting_recipe_selected)
	

func _on_alchemist_panel_requested():
	var crafting_panel = CraftingPanelScene.instantiate()
	crafting_panel.panel_closed.connect(_on_crafting_panel_closed.bind(null))
	add_child(crafting_panel)
	crafting_panel.setup("alchemist")
	crafting_panel.recipe_selected.connect(_on_crafting_recipe_selected)

func _on_crafting_recipe_selected(recipe: Dictionary):
	# In ra để kiểm tra
	print("UI đã nhận được yêu cầu chế tạo: ", recipe["result"]["item_id"])

	# 1. Tạo ra panel chọn số lượng
	var quantity_panel = CraftingQuantityPanelScene.instantiate()
	add_child(quantity_panel)

	# 2. Thiết lập cho panel đó (bạn cần có hàm setup trong script của quantity_panel)
	quantity_panel.setup(recipe)

	# 3. Hiển thị panel
	quantity_panel.show()

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
	shop_panel.add_to_group("panels")
	shop_panel.item_tooltip = item_tooltip 
	add_child(shop_panel)
	shop_panel.setup("potion", hero)
	current_open_panel = shop_panel

func _on_hero_potion_cooldown_started(slot_key: String, duration: float):
	# Dựa vào slot_key, tìm ra ItemSlot UI tương ứng
	var target_slot: ItemSlot = null
	match slot_key:
		"POTION_1":
			# Giả sử bạn có node tên là PotionSlot1 trong scene
			target_slot = $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion1slot
		"POTION_2":
			target_slot = $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion2slot
		"POTION_3":
			target_slot = $InventoryPanel/HBoxContainer/EquipBG/EquipmentUI/EquipmentPanel/potion3slot

	# Nếu tìm thấy, ra lệnh cho nó bắt đầu hiển thị cooldown
	if is_instance_valid(target_slot):
		# Chúng ta sẽ tạo hàm này ở bước tiếp theo
		target_slot.start_cooldown(duration) 

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
	if is_instance_valid(village_upgrade_panel_instance):
		print("Đã mở panel update village")
		return
	_close_all_main_panels()
	village_upgrade_panel_instance = VillageUpgradePanelScene.instantiate()
	village_upgrade_panel_instance.panel_closed.connect(_on_village_upgrade_panel_closed)
	add_child(village_upgrade_panel_instance)
	
func _on_village_upgrade_panel_closed():
	_close_all_main_panels()
	# Khi nhận được tín hiệu panel đã đóng, xóa tham chiếu
	village_upgrade_panel_instance = null
	print("Panel nang cap lang da dong. Co the mo lai.")
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
	barracks_panel.add_to_group("panel")
	
	_close_all_main_panels()
		# Kết nối tín hiệu mới từ panel kho hero
	barracks_panel.display_hero_info_requested.connect(_on_display_barracks_hero_info)
	add_child(barracks_panel)
	
func _on_display_barracks_hero_info(hero_from_barracks: Hero):
	if not is_instance_valid(hero_from_barracks): return
	
	# Gán "trí nhớ" cho hero từ sảnh
	_hero_in_view = hero_from_barracks

	_update_hero_info_panel()
	
	if is_instance_valid(skill_list_container):
		skill_list_container.visible = false
	if is_instance_valid(active_skill_grid):
		active_skill_grid.visible = false
	if is_instance_valid(skill_points_label):
		skill_points_label.visible = false
	if is_instance_valid(free_points_label):
		free_points_label.visible = false
	# Ẩn tất cả các nút cộng điểm chỉ số
	for btn in stat_buttons:
		btn.visible = false
	
	hero_info_panel.show()
	hero_info_panel.move_to_front()


func request_hero_dismissal(hero_to_dismiss: Hero):
	if not is_instance_valid(hero_to_dismiss):
		print("Lỗi: Yêu cầu sa thải một hero không hợp lệ.")
		return

	var hero_name = hero_to_dismiss.name

	# Nếu InfoPanel đang mở và hiển thị hero này, hãy đóng nó và dọn dẹp
	if hero_to_dismiss == _hero_in_view:
		hero_info_panel.hide()
		_hero_in_view = null

	# Nếu hero này đang được chọn ngoài world, hủy chọn
	if hero_to_dismiss == _current_hero:
		GameEvents.hero_selected.emit(null)

	# Gọi logic sa thải cốt lõi
	PlayerStats.sa_thai_hero(hero_to_dismiss)
	print("Đã sa thải thành công hero: " + hero_name)

func _on_sa_thai_button_pressed():
	request_hero_dismissal(_hero_in_view)
	
func _update_main_stats_display():
	if not is_instance_valid(_hero_in_view):
		# Nếu không có hero nào được chọn, có thể xóa text hoặc để trống
		info_str_label.text = "STR: --"
		info_agi_label.text = "AGI: --"
		info_vit_label.text = "VIT: --"
		info_int_label.text = "INT: --"
		info_dex_label.text = "DEX: --"
		info_luk_label.text = "LUK: --"
		return

	# Cập nhật text cho các label chỉ số
	info_str_label.text = "STR: %d" % _hero_in_view.STR
	info_agi_label.text = "AGI: %d" % _hero_in_view.AGI
	info_vit_label.text = "VIT: %d" % _hero_in_view.VIT
	info_int_label.text = "INT: %d" % _hero_in_view.INTEL
	info_dex_label.text = "DEX: %d" % _hero_in_view.DEX
	info_luk_label.text = "LUK: %d" % _hero_in_view.LUK
	# ... (cập nhật các label khác nếu có)

func _on_setting_button_pressed() -> void:
	var settings_menu_node = $SettingsMenu
	if settings_menu_node.visible:
		settings_menu_node.hide()
	else:
		settings_menu_node.show()


func _on_button_pressed() -> void:
	_close_all_main_panels()
	inventory_panel.visible = false
