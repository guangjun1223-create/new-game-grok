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
const UpgradeChoiceDialogScene = preload("res://Scene/UI/upgrade_choice_dialog.tscn")
const UpgradePanelScene = preload("res://Scene/UI/upgrade_panel.tscn")
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
@onready var info_str_label: RichTextLabel = %Info_StrLabel
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
@export var job_changer_npc: CharacterBody2D
@export var enhancement_npc: StaticBody2D

var hero_hien_tai: Hero

var current_open_panel: Control = null
var village_upgrade_panel_instance = null
var _hero_for_upgrade: Hero = null

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
	
	PlayerStats.initialize_world_references()
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
	
# ====================
# HÀM XỬ LÝ TÍN HIỆU
# ====================
func _on_hero_selected(hero: Hero) -> void:
	var previous_hero = _current_hero
	if hero == previous_hero: _current_hero = null
	else: _current_hero = hero
	
	if is_instance_valid(previous_hero):
		if previous_hero.hp_changed.is_connected(_update_hp_bar):
			previous_hero.hp_changed.disconnect(_update_hp_bar)
		if previous_hero.sp_changed.is_connected(_update_sp_bar):
			previous_hero.sp_changed.disconnect(_update_sp_bar)
		if previous_hero.hero_stats.exp_changed.is_connected(_update_exp_bar):
			previous_hero.hero_stats.exp_changed.disconnect(_update_exp_bar)
		if previous_hero.hero_stats.stats_updated.is_connected(_on_hero_stats_updated):
			previous_hero.hero_stats.stats_updated.disconnect(_on_hero_stats_updated)
		if previous_hero.hero_stats.free_points_changed.is_connected(_on_free_points_changed):
			previous_hero.hero_stats.free_points_changed.disconnect(_on_free_points_changed)
		if previous_hero.hero_inventory.equipment_changed.is_connected(_update_equipment_display):
			previous_hero.hero_inventory.equipment_changed.disconnect(_update_equipment_display)
		if previous_hero.hero_inventory.inventory_changed.is_connected(_on_inventory_changed):
			previous_hero.hero_inventory.inventory_changed.disconnect(_on_inventory_changed)
		if previous_hero.hero_inventory.gold_changed.is_connected(_on_hero_gold_changed):
			previous_hero.hero_inventory.gold_changed.disconnect(_on_hero_gold_changed)
		if previous_hero.hero_skills.skill_activated.is_connected(_on_hero_skill_activated):
			previous_hero.hero_skills.skill_activated.disconnect(_on_hero_skill_activated)

	if is_instance_valid(_current_hero):
		selected_hero_panel.show(); main_command_menu.show()
		_current_hero.hp_changed.connect(_update_hp_bar)
		_current_hero.sp_changed.connect(_update_sp_bar)
		_current_hero.hero_stats.exp_changed.connect(_update_exp_bar)
		_current_hero.hero_stats.stats_updated.connect(_on_hero_stats_updated)
		_current_hero.hero_stats.free_points_changed.connect(_on_free_points_changed)
		_current_hero.hero_inventory.equipment_changed.connect(_update_equipment_display)
		_current_hero.hero_inventory.inventory_changed.connect(_on_inventory_changed)
		_current_hero.hero_inventory.gold_changed.connect(_on_hero_gold_changed)
		_current_hero.hero_skills.skill_activated.connect(_on_hero_skill_activated)
		_update_selected_hero_info() # Cập nhật toàn bộ info
	else:
		selected_hero_panel.hide(); main_command_menu.hide(); hero_info_panel.hide()
		inventory_panel.hide(); movement_buttons.hide(); shop_list_panel.hide()
	
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
	job_change_button.pressed.connect(_on_job_changer_button_pressed)
	village_upgrade_button.pressed.connect(_on_village_upgrade_button_pressed)
	close_warehouse_button.pressed.connect(_on_close_button_pressed)
	close_buyback_button.pressed.connect(_on_close_buyback_button_pressed)
	sa_thai_button.pressed.connect(_on_sa_thai_button_pressed)
	
	if is_instance_valid(blacksmith_npc):
		blacksmith_npc.blacksmith_panel_requested.connect(_on_blacksmith_panel_requested)
	else:
		push_warning("Chưa kết nối với blacksmith NPC")
	if is_instance_valid(alchemist_npc):
		alchemist_npc.alchemist_panel_requested.connect(_on_alchemist_panel_requested)
	else:
		push_warning("UI CHƯA ĐƯỢC KẾT NỐI VỚI ALCHEMIST NPC!")
	if is_instance_valid(job_changer_npc):
		if not job_changer_npc.open_job_change_panel.is_connected(_on_open_job_change_panel):
			job_changer_npc.open_job_change_panel.connect(_on_open_job_change_panel)
	if is_instance_valid(enhancement_npc):
		enhancement_npc.upgrade_panel_requested.connect(_on_upgrade_panel_requested)
	
func _close_all_main_panels():
	get_tree().call_group("panels", "hide")
	
# ============================================================================
# CÁC HÀM CẬP NHẬT GIAO DIỆN (ĐÃ SỬA LỖI TOÀN BỘ)
# ============================================================================
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
	
		
	if _current_hero.hero_stats.job_key == "Novice" and _current_hero.hero_stats.level >= 10:
		job_change_button.show()
	else:
		job_change_button.hide()
		
	_update_hp_bar(_current_hero.current_hp, _current_hero.max_hp)
	_update_sp_bar(_current_hero.current_sp, _current_hero.max_sp)
	_update_exp_bar(_current_hero.hero_stats.current_exp, _current_hero.hero_stats.exp_to_next_level)

func _update_hero_info_panel():
	if not is_instance_valid(_hero_in_view):
		hero_info_panel.hide()
		return
	
	# --- BẮT ĐẦU SỬA LỖI: LẤY DỮ LIỆU TỪ ĐÚNG COMPONENT ---
	
	# Lấy dữ liệu từ component HeroSkills
	skill_points_label.text = "Điểm kỹ năng: %d" % _hero_in_view.hero_skills.skill_points
	
	# Lấy dữ liệu trực tiếp từ Hero (vì hero_name không đổi)
	info_name_label.text = "Tên: " + _hero_in_view.hero_name
	
	# Lấy dữ liệu từ component HeroStats
	info_job_label.text = "Nghề: " + GameDataManager.get_job_display_name(_hero_in_view.hero_stats.job_key)
	
	# Lấy độ hiếm từ tên Node của Hero
	var rarity = "Chưa rõ"
	if _hero_in_view.name.contains("("):
		rarity = _hero_in_view.name.substr(_hero_in_view.name.find("(") + 1, _hero_in_view.name.find(")") - _hero_in_view.name.find("(") - 1)
	
	var rarity_bbcode: String = rarity
	match rarity:
		"F": rarity_bbcode = "[color=#4a4a4a]F[/color]"
		"D": rarity_bbcode = "[color=#808080]D[/color]"
		"C": rarity_bbcode = "[color=#b2b2b2]C[/color]"
		"B": rarity_bbcode = "[color=#e5e5e5]B[/color]"
		"A": rarity_bbcode = "[color=white]A[/color]"
		"S": rarity_bbcode = "[color=palegreen]S[/color]"
		"SS": rarity_bbcode = "[color=cyan]SS[/color]"
		"SSS": rarity_bbcode = "[color=gold]SSS[/color]"
		"SSR": rarity_bbcode = "[color=orangered]SSR[/color]"
		"UR": rarity_bbcode = "[rainbow freq=1 sat=0.8 val=1.0]UR[/rainbow]"

	info_rarity_label.text = "Hạng: " + rarity_bbcode
	
	# Lấy dữ liệu từ component HeroStats
	info_level_label.text = "Cấp: " + str(_hero_in_view.hero_stats.level)
	info_exp_label.text = "EXP: %d/%d" % [_hero_in_view.hero_stats.current_exp, _hero_in_view.hero_stats.exp_to_next_level]
	
	# Lấy ra các giá trị gốc và bonus từ component HeroStats
	var stats = _hero_in_view.hero_stats
	var bonus_hp = snapped(stats.bonus_max_hp, 0.01)
	var base_hp = snapped(stats.max_hp - bonus_hp, 0.01)
	var bonus_sp = snapped(stats.bonus_max_sp, 0.01)
	var base_sp = snapped(stats.max_sp - bonus_sp, 0.01)
	var base_str = snapped(stats.STR, 0.01)
	var bonus_str = snapped(stats.bonus_str, 0.01)
	var base_agi = snapped(stats.AGI, 0.01)
	var bonus_agi = snapped(stats.bonus_agi, 0.01)
	var base_vit = snapped(stats.VIT, 0.01)
	var bonus_vit = snapped(stats.bonus_vit, 0.01)
	var base_intel = snapped(stats.INTEL, 0.01)
	var bonus_intel = snapped(stats.bonus_intel, 0.01)
	var base_dex = snapped(stats.DEX, 0.01)
	var bonus_dex = snapped(stats.bonus_dex, 0.01)
	var base_luk = snapped(stats.LUK, 0.01)
	var bonus_luk = snapped(stats.bonus_luk, 0.01)
	var bonus_def = snapped(stats.bonus_def, 0.01)
	var base_def = snapped(stats.def - bonus_def, 0.01)
	var bonus_mdef = snapped(stats.bonus_mdef, 0.01)
	var base_mdef = snapped(stats.mdef - bonus_mdef, 0.01)
	var bonus_hit = snapped(stats.bonus_hit, 0.01)
	var base_hit = snapped(stats.hit - bonus_hit, 0.01)
	var bonus_flee = snapped(stats.bonus_flee, 0.01)
	var base_flee = snapped(stats.flee - bonus_flee, 0.01)
	var bonus_crit = snapped(stats.bonus_crit_rate, 0.01)
	var base_crit = snapped(stats.crit_rate - bonus_crit, 0.01)
	
	# Lấy HP/SP hiện tại từ "nhạc trưởng" hero.gd
	var current_hp_int = int(_hero_in_view.current_hp)
	info_hp_label.text = "HP: %d/%s" % [current_hp_int, str(roundi(base_hp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hp)) if bonus_hp > 0 else "")
	var current_sp_int = int(_hero_in_view.current_sp)
	info_sp_label.text = "SP: %d/%s" % [current_sp_int, str(roundi(base_sp))] + ("[color=cyan] +%s[/color]" % str(roundi(bonus_sp)) if bonus_sp > 0 else "")
	
	# Hiển thị các chỉ số khác từ component HeroStats
	info_str_label.text = "Sức mạnh: %s" % str(roundi(base_str)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_str)) if bonus_str > 0 else "")
	info_agi_label.text = "Nhanh nhẹn: %s" % str(roundi(base_agi)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_agi)) if bonus_agi > 0 else "")
	info_vit_label.text = "Thể lực: %s" % str(roundi(base_vit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_vit)) if bonus_vit > 0 else "")
	info_int_label.text = "Trí tuệ: %s" % str(roundi(base_intel)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_intel)) if bonus_intel > 0 else "")
	info_dex_label.text = "Độ chuẩn: %s" % str(roundi(base_dex)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_dex)) if bonus_dex > 0 else "")
	info_luk_label.text = "May mắn: %s" % str(roundi(base_luk)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_luk)) if bonus_luk > 0 else "")
	info_atk_label.text = "Sát thương: %d - %d" % [int(stats.min_atk), int(stats.max_atk)]
	info_matk_label.text = "Sát thương phép: %d - %d" % [int(stats.min_matk), int(stats.max_matk)]
	info_def_label.text = "Phòng thủ: %s" % str(roundi(base_def)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_def)) if bonus_def > 0 else "")
	info_mdef_label.text = "Phòng thủ phép: %s" % str(roundi(base_mdef)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_mdef)) if bonus_mdef > 0 else "")
	info_hit_label.text = "Chính xác: %s" % str(roundi(base_hit)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_hit)) if bonus_hit > 0 else "")
	info_flee_label.text = "Tránh né: %s" % str(roundi(base_flee)) + ("[color=cyan] +%s[/color]" % str(roundi(bonus_flee)) if bonus_flee > 0 else "")
	info_crit_label.text = "Tỉ lệ trí mạng: %s%%" % str(snapped(base_crit, 0.1)) + ("[color=cyan] +%s%%[/color]" % str(snapped(bonus_crit, 0.1)) if bonus_crit > 0 else "")
	
	# Lưu ý nhỏ: crit_damage và attack_speed_calculated không có bonus riêng, nên ta hiển thị thẳng
	info_critDame_label.text = "ST chí mạng: x%.2f" % stats.crit_damage
	info_attackspeed_label.text = "Tốc độ đánh: %.2f giây/đòn" % stats.attack_time

func _update_stat_buttons_visibility():
	var should_be_visible = false
	# Chỉ hiển thị nút nếu có hero được chọn VÀ hero đó có điểm tiềm năng
	if is_instance_valid(_current_hero) and _current_hero.hero_stats.free_points > 0:
		should_be_visible = true
	
	# Áp dụng trạng thái ẩn/hiện cho tất cả các nút
	for b in stat_buttons:
		b.visible = should_be_visible
	
	# Ẩn/hiện label
	free_points_label.visible = should_be_visible
	if should_be_visible:
		# SỬA LỖI: Lấy 'free_points' từ component hero_stats
		free_points_label.text = "Điểm tự do: %d" % _current_hero.hero_stats.free_points

func _update_backpack_display() -> void:
	if not is_instance_valid(_current_hero):
		for slot_node in backpack_slots:
			slot_node.display_item(null, 0)
		return

	var inv: Array = _current_hero.hero_inventory.inventory
	var inv_size: int = inv.size()

	for i in range(backpack_slots.size()):
		var slot_node = backpack_slots[i]
		var item_info = inv[i] if i < inv_size else null

		# --- LOGIC SỬA LỖI NẰM Ở ĐÂY ---
		if item_info is Dictionary:
			var item_id = ""
			var quantity = 1
			var upgrade_level = 0
			
			if item_info.has("base_id"): # Xử lý TRANG BỊ (cấu trúc mới)
				item_id = item_info.base_id
				upgrade_level = item_info.upgrade_level
				# Hiển thị cấp + cho trang bị
				slot_node.display_item(ItemDatabase.get_item_icon(item_id), upgrade_level)
			elif item_info.has("id"): # Xử lý VẬT PHẨM THƯỜNG (cấu trúc cũ)
				item_id = item_info.id
				quantity = item_info.get("quantity", 1)
				slot_node.display_item(ItemDatabase.get_item_icon(item_id), quantity)
			else:
				slot_node.display_item(null, 0)
		else:
			# Nếu ô trống (null)
			slot_node.display_item(null, 0)

func _update_equipment_display(new_equipment: Dictionary = {}):
	if not is_instance_valid(_current_hero) or not is_instance_valid(_current_hero.hero_inventory):
		for slot_key in equipment_slots:
			equipment_slots[slot_key].display_item(null, 0)
		return

	var hero_equipment = _current_hero.hero_inventory.equipment
	if not new_equipment.is_empty():
		hero_equipment = new_equipment

	for slot_key in equipment_slots:
		var slot_node = equipment_slots[slot_key]
		var equipped_item_pkg = hero_equipment.get(slot_key)

		if not equipped_item_pkg:
			slot_node.display_item(null, 0)
			continue

		var item_id = ""
		var quantity = 0 # Sử dụng 0 cho trang bị để hiển thị cấp độ, > 1 cho vật phẩm

		if equipped_item_pkg is Dictionary:
			if equipped_item_pkg.has("base_id"): # Ưu tiên kiểm tra trang bị trước
				item_id = equipped_item_pkg.base_id
				# Lấy cấp độ nâng cấp để hiển thị thay cho số lượng
				quantity = equipped_item_pkg.get("upgrade_level", 0)
			elif equipped_item_pkg.has("id"): # Sau đó mới kiểm tra vật phẩm thường
				item_id = equipped_item_pkg.id
				quantity = equipped_item_pkg.get("quantity", 1)

		if not item_id.is_empty():
			var new_icon = ItemDatabase.get_item_icon(item_id)
			slot_node.display_item(new_icon, quantity)
		else:
			slot_node.display_item(null, 0)

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

func _update_selected_hero_info():
	if not is_instance_valid(_current_hero.hero_stats):
		return
		
	# Gọi tất cả các hàm cập nhật giao diện con
	_update_selected_hero_panel()
	_update_gold_display(_current_hero.hero_inventory.gold) # Sửa lỗi: Lấy gold từ component
	_update_backpack_display()
	_update_equipment_display()
	_update_stat_buttons_visibility()
	
	# Nếu panel info chi tiết đang mở, cũng cập nhật nó luôn
	if hero_info_panel.visible:
		_update_hero_info_panel()

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


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		

func _on_summon_button_pressed():
	PlayerStats.trieu_hoi_hero()

		
func _update_hp_bar(current_hp, max_hp):
	var percentage = 0.0
	if max_hp > 0: percentage = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	hp_bar_fill.size.x = hp_bar_bg.size.x * percentage
	hp_label.text = "%d/%d HP" % [int(current_hp), int(max_hp)]

func _update_sp_bar(current_sp, max_sp):
	var percentage = 0.0
	if max_sp > 0: percentage = clamp(float(current_sp) / float(max_sp), 0.0, 1.0)
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
		
	var target_pos = PlayerStats.get_shop_npc_position()
	if target_pos != Vector2.ZERO:
		# Sửa lỗi: Đổi tên hàm thành move_to_location_by_player
		_current_hero.move_to_location_by_player(target_pos)
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
	_update_hero_info_panel()
	
	# Hiển thị các thành phần của panel skill
	if is_instance_valid(skill_list_container):
		skill_list_container.visible = true
	if is_instance_valid(active_skill_grid):
		active_skill_grid.visible = true
	if is_instance_valid(skill_points_label):
		skill_points_label.visible = true
	
	# Xây dựng và cập nhật UI cho skill
	_build_skill_tree_panel()
	_update_active_skill_slots()

	# --- PHẦN SỬA LỖI ---
	# Lấy tín hiệu từ component HeroSkills thay vì từ Hero
	var skill_tree_signal = _hero_in_view.hero_skills.skill_tree_changed
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
		for slot in _active_skill_slots_ui:
			# Sửa lỗi: Truyền chuỗi rỗng "" thay vì null
			slot.display_skill("") 
		return

	var equipped_skills_array = _hero_in_view.hero_skills.equipped_skills
	
	if _active_skill_slots_ui.size() != equipped_skills_array.size():
		push_warning("Số lượng slot UI kỹ năng không khớp với dữ liệu của Hero!")
		return
		
	for i in range(_active_skill_slots_ui.size()):
		var skill_id = equipped_skills_array[i] # skill_id có thể là String hoặc null
		var slot_ui = _active_skill_slots_ui[i]
		
		# Sửa lỗi: Nếu skill_id là null, ta truyền vào chuỗi rỗng ""
		slot_ui.display_skill(skill_id if skill_id else "")
		
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
	
	# Xóa các panel kỹ năng cũ
	for child in skill_list_container.get_children():
		child.queue_free()

	# --- LOGIC MỚI: DỰA VÀO LỊCH SỬ CỦA HERO ---
	
	# 1. Lấy ra lịch sử các nghề mà hero đã học từ component HeroStats
	var hero_job_history = _hero_in_view.hero_stats.job_history
	
	# 2. Lặp qua từng nghề trong lịch sử đó
	for job_key in hero_job_history:
		# Tạo một Bảng kỹ năng (JobSkillPanel) cho từng nghề
		var job_panel = JobSkillPanelScene.instantiate()
		
		# Thêm bảng kỹ năng này vào VBoxContainer
		skill_list_container.add_child(job_panel)
		
		# Ra lệnh cho bảng kỹ năng đó tự xây dựng danh sách skill của nghề tương ứng
		job_panel.build_for_job(job_key, _hero_in_view)
		
		# Kết nối các tín hiệu như cũ
		job_panel.upgrade_requested.connect(_on_skill_upgrade_requested)
		job_panel.equip_requested.connect(_on_skill_equip_requested)
		job_panel.unequip_requested.connect(_on_skill_unequip_requested)

func _on_close_hero_info_button_pressed():
	if is_instance_valid(_hero_in_view):
		# --- PHẦN SỬA LỖI ---
		# Ngắt kết nối tín hiệu từ component HeroSkills
		var skill_tree_signal = _hero_in_view.hero_skills.skill_tree_changed
		if skill_tree_signal.is_connected(_on_hero_skill_tree_changed):
			skill_tree_signal.disconnect(_on_hero_skill_tree_changed)
			
	_hero_in_view = null
	hero_info_panel.hide()

func _on_inventory_button_pressed():
	_close_all_main_panels()
	if is_instance_valid(_current_hero):
		inventory_panel.visible = not inventory_panel.visible
		hero_info_panel.visible = false


# Hàm này được gọi khi tín hiệu "stats_updated" của hero được phát ra (khi lên cấp).
func _on_hero_stats_updated():
	if not is_instance_valid(_current_hero): return
	
	_update_selected_hero_panel()
	
	if hero_info_panel.visible:
		_update_hero_info_panel()
		_update_stat_buttons_visibility()
		# SỬA LỖI: Lấy 'free_points' từ component hero_stats
		free_points_label.text = "Điểm tự do: %d" % _current_hero.hero_stats.free_points
		
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
	

			
func _on_item_slot_mouse_entered(slot_index: int) -> void:
	if not is_instance_valid(_current_hero):
		return
	
	# SỬA LỖI: Lấy 'inventory' từ component hero_inventory
	var inventory_array = _current_hero.hero_inventory.inventory
	
	if slot_index < 0 or slot_index >= inventory_array.size():
		return

	var item_info = inventory_array[slot_index]

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

func _on_equipment_slot_pressed(slot_key: String):
	if not is_instance_valid(_current_hero):
		return

	# Ra lệnh cho hero đang được chọn tháo vật phẩm ở vị trí tương ứng
	_current_hero.unequip_item(slot_key)

func _on_equipment_slot_mouse_entered(slot_key: String):
	if is_instance_valid(_current_hero):
		# SỬA LỖI: Lấy 'equipment' từ component hero_inventory
		var item_info = _current_hero.hero_inventory.equipment.get(slot_key)
		
		if item_info:
			item_tooltip.update_tooltip(item_info)
			item_tooltip.popup(Rect2(get_viewport().get_mouse_position(), item_tooltip.size))

func _on_equipment_slot_mouse_exited():
	item_tooltip.hide()


func _on_hero_gold_changed(new_gold_amount):
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

	# Sửa lỗi: Sử dụng hàm mới để ra lệnh cho Hero di chuyển đến điểm
	_current_hero.move_to_location_by_player(inn_position)
	
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
		# Lấy thông tin item từ túi đồ của hero
		var item_info = _current_hero.hero_inventory.inventory[slot_index]
		
		# Chỉ hiển thị tooltip nếu ô đó có vật phẩm
		if item_info is Dictionary:
			# Gửi cả dictionary thông tin item vào cho tooltip
			# Hàm update_tooltip của bạn sẽ cần xử lý cả hai loại cấu trúc
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
	print("[UI] Đã nhận được tín hiệu 'open_job_change_panel'. Chuẩn bị mở panel...")
	# Kiểm tra xem node job_change_panel có hợp lệ không
	if not is_instance_valid(job_change_panel):
		push_error("LỖI UI: Tham chiếu đến 'job_change_panel' không hợp lệ!")
		return
		
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
		# Sửa lỗi: Đổi tên hàm thành move_to_location_by_player
		_current_hero.move_to_location_by_player(target_pos)
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

func _on_job_changer_button_pressed():
	if not is_instance_valid(_current_hero): return
	
	var target_pos = PlayerStats.get_job_changer_position()
	
	if target_pos != Vector2.ZERO:
		print("UI: Ra lệnh cho Hero '%s' di chuyển đến NPC Chuyển Nghề." % _current_hero.name)
		_current_hero.move_to_location_by_player(target_pos)
	else:
		push_warning("UI: Không tìm thấy vị trí của JobChangerNPC.")
		
func _on_equipment_shop_button_pressed():
	if not is_instance_valid(_current_hero): return
	var target_pos = PlayerStats.get_equipment_seller_position()
	if target_pos != Vector2.ZERO:
		_current_hero.move_to_location_by_player(target_pos)
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
	
func _on_enhancement_button_pressed() -> void:
	if not is_instance_valid(_current_hero): return
	
	# Sửa lại tên biến và tên hàm
	var target_pos = PlayerStats.get_enhancement_npc_position() # Tên hàm đúng
	if target_pos != Vector2.ZERO:
		_current_hero.move_to_location_by_player(target_pos) # Dùng target_pos
		if is_instance_valid(shop_list_panel): shop_list_panel.hide()
		if is_instance_valid(main_command_menu): main_command_menu.show()
		
func _on_upgrade_panel_requested(hero: Hero):
	# 1. Lưu lại hero đang tương tác để dùng cho bước sau
	_hero_for_upgrade = hero
	
	# 2. Tạo ra bảng lựa chọn nhỏ
	var choice_dialog = UpgradeChoiceDialogScene.instantiate()
	
	# 3. Lắng nghe xem người chơi sẽ chọn gì từ bảng đó
	choice_dialog.choice_made.connect(_on_upgrade_choice_made)
	
	# 4. Thêm bảng lựa chọn vào game và hiển thị nó
	add_child(choice_dialog)
	choice_dialog.global_position = get_viewport().get_mouse_position()

# Hàm này được gọi sau khi người chơi đã chọn "Vũ khí" hoặc "Trang bị"
func _on_upgrade_choice_made(upgrade_type: String):
	# Kiểm tra an toàn
	if not is_instance_valid(_hero_for_upgrade): return
	
	# 1. Tạo ra bảng nâng cấp chính
	var panel = UpgradePanelScene.instantiate()
	
	# 2. Thêm vào game
	add_child(panel)
	
	# 3. Thiết lập cho bảng nâng cấp với hero và loại trang bị đã chọn
	panel.setup(_hero_for_upgrade, upgrade_type)
	
	# 4. Dọn dẹp biến tạm
	_hero_for_upgrade = null

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
	barracks_panel.add_to_group("panels")
	
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
	


func _on_setting_button_pressed() -> void:
	var settings_menu_node = $SettingsMenu
	if settings_menu_node.visible:
		settings_menu_node.hide()
	else:
		settings_menu_node.show()


func _on_button_pressed() -> void:
	_close_all_main_panels()
	inventory_panel.visible = false
