# res://Scene/UI/skill_slot.gd
extends PanelContainer
class_name SkillSlot

# ====================
# SIGNALS (TÍN HIỆU)
# ====================
signal upgrade_requested(skill_id: String)
signal equip_requested(skill_id: String)
signal unequip_requested(skill_id: String)

# ====================
# BIẾN
# ====================
# QUAN TRỌNG: Thay đổi đường dẫn này cho đúng với project của bạn.
const SKILL_ATLAS = preload("res://texture/item001.png")

var _skill_id: String
var _hero_ref: Hero
var _skill_data: Dictionary

# ====================
# THAM CHIẾU NODE (Sử dụng % để an toàn hơn)
# ====================
@onready var icon_rect: TextureRect = $HBoxContainer/Node2D/IconRect
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/InfoContainer/LevelLabel
@onready var desc_label: RichTextLabel = $HBoxContainer/InfoContainer/DescriptionLabel
@onready var upgrade_button: Button = $ButtonContainer/ActionButton
@onready var equip_button: Button = $ButtonContainer/EquipButton

# ====================
# HÀM KHỞI TẠO
# ====================
func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	equip_button.pressed.connect(_on_equip_button_pressed)

# ====================
# HÀM CHÍNH
# ====================
# Được gọi từ JobSkillPanel để thiết lập dữ liệu ban đầu
func setup(p_skill_id: String, p_hero: Hero):
	self._skill_id = p_skill_id
	self._hero_ref = p_hero
	self._skill_data = SkillDatabase.get_skill_data(_skill_id)

	if _skill_data.is_empty():
		push_warning("SkillSlot: Không tìm thấy dữ liệu cho skill '%s'" % _skill_id)
		visible = false
		return
	
	refresh_display()

# Hàm "vẽ" lại toàn bộ thông tin của slot
func refresh_display():
	# Kiểm tra an toàn
	if not is_instance_valid(_hero_ref) or _skill_data.is_empty():
		return

	var hero_skill_level = _hero_ref.get_skill_level(_skill_id)
	var max_level = _skill_data.get("max_level", 1)

	# --- 1. Cập nhật Icon ---
	_set_skill_icon()

	# --- 2. Cập nhật Text ---
	name_label.text = _skill_data.get("skill_name", "Lỗi Tên")
	level_label.text = "Cấp: %d/%d" % [hero_skill_level, max_level]
	
	var effects_array = _skill_data.get("effects_per_level", [])
	if hero_skill_level > 0 and hero_skill_level <= effects_array.size():
		var effect_desc = effects_array[hero_skill_level - 1].get("description", "")
		desc_label.text = "Hiệu ứng: [color=cyan]%s[/color]" % effect_desc
	elif not effects_array.is_empty():
		var effect_desc = effects_array[0].get("description", "")
		desc_label.text = "Hiệu ứng: [color=gray]%s[/color]" % effect_desc
	else:
		desc_label.text = "Chưa có mô tả."

	# --- 3. Cập nhật Logic Nút Bấm ---
	_update_upgrade_button_state(hero_skill_level, max_level)
	_update_equip_button_state(hero_skill_level)

# ====================
# CÁC HÀM PHỤ (PRIVATE)
# ====================
func _set_skill_icon():
	var coords = _skill_data.get("atlas_coords")
	if not (coords is Dictionary and coords.has_all(["x", "y", "w", "h"])):
		icon_rect.texture = null
		return

	var atlas_icon = AtlasTexture.new()
	atlas_icon.atlas = SKILL_ATLAS
	atlas_icon.region = Rect2(coords.x, coords.y, coords.w, coords.h)
	icon_rect.texture = atlas_icon

func _update_upgrade_button_state(current_level: int, max_level: int):
	# --- BƯỚC 1: KIỂM TRA ĐIỀU KIỆN CƠ BẢN ---
	var hero_level = _hero_ref.hero_stats.level 
	var required_level = _skill_data.get("unlock_level", 1)

	if current_level >= max_level:
		upgrade_button.disabled = true
		upgrade_button.text = "Đã đạt cấp tối đa"
		return

	if hero_level < required_level:
		upgrade_button.disabled = true
		upgrade_button.text = "Cần Cấp %d" % required_level
		return

	# --- BƯỚC 2: KIỂM TRA ĐIỂM KỸ NĂNG ---
	var cost_array = _skill_data.get("skill_point_cost", [])
	if current_level >= cost_array.size():
		upgrade_button.disabled = true
		upgrade_button.text = "Lỗi Dữ Liệu Skill"
		return

	var required_points = cost_array[current_level]
	# Sửa lỗi: Lấy 'skill_points' từ component hero_skills
	var current_points = _hero_ref.hero_skills.skill_points 

	if current_points >= required_points:
		upgrade_button.disabled = false
		upgrade_button.text = "Nâng Cấp (%d SP)" % required_points
	else:
		upgrade_button.disabled = true
		upgrade_button.text = "Thiếu %d SP" % (required_points - current_points)

func _update_equip_button_state(current_level: int):
	# --- BƯỚC 1: Kiểm tra các điều kiện cơ bản (giống code của bạn) ---
	# Nếu skill chưa học hoặc không phải skill chủ động, ẩn nút trang bị đi và dừng lại.
	if _skill_data.get("usage_type") != "ACTIVE" or current_level <= 0:
		equip_button.visible = false
		modulate = Color.WHITE # Đảm bảo ô không bị mờ nếu nó là skill bị động
		return
	
	# Nếu qua được bước trên, nút trang bị sẽ được hiện ra
	equip_button.visible = true

	# --- BƯỚC 2 (NÂNG CẤP): Kiểm tra yêu cầu vũ khí từ Hero ---
	var check_result = _hero_ref.check_skill_requirements(_skill_id)
	var can_equip_now = check_result.can_equip
	var reason = check_result.reason

	# --- BƯỚC 3: Cập nhật trạng thái hiển thị dựa trên TẤT CẢ điều kiện ---
	if can_equip_now:
		# Nếu đủ điều kiện vũ khí: Ô sáng, cho phép bấm nút, không cần giải thích
		modulate = Color.WHITE
		tooltip_text = ""
		equip_button.disabled = false
	else:
		# Nếu KHÔNG đủ điều kiện: Ô mờ đi, KHÓA nút, hiện lý do khi di chuột vào
		modulate = Color(0.5, 0.5, 0.5, 1.0) 
		tooltip_text = reason
		equip_button.disabled = true
	
	# --- BƯỚC 4: Cập nhật chữ trên nút (giống code của bạn) ---
	# Dù nút bị khóa, vẫn hiển thị đúng chữ "Tháo" nếu skill đang được trang bị
	equip_button.text = "Tháo" if _hero_ref.is_skill_equipped(_skill_id) else "Trang Bị"

# ====================
# HÀM XỬ LÝ TÍN HIỆU
# ====================
func _on_upgrade_button_pressed():
	print(">>> TRAM GAC 1: SkillSlot da nhan duoc CLICK!") # <-- THÊM DÒNG NÀY
	upgrade_requested.emit(_skill_id)

func _on_equip_button_pressed():
	if _hero_ref.is_skill_equipped(_skill_id):
		unequip_requested.emit(_skill_id)
	else:
		equip_requested.emit(_skill_id)
