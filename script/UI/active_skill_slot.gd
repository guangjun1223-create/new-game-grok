# res://Scene/UI/active_skill_slot.gd
extends Control

@onready var icon: TextureRect = $Icon
@onready var cooldown_progress: TextureProgressBar = $CooldownProgress

var _skill_id: String
var _cooldown_timer: SceneTreeTimer # Dùng để quản lý thời gian

func _process(_delta: float):
	# Liên tục cập nhật giá trị của progress bar nếu timer đang chạy
	if is_instance_valid(_cooldown_timer):
		cooldown_progress.value = (_cooldown_timer.time_left / cooldown_progress.max_value) * 100
	else:
		cooldown_progress.value = 0

# Cập nhật icon cho slot
func display_skill(p_skill_id: String):
	self._skill_id = p_skill_id

	if _skill_id.is_empty():
		icon.texture = null # Nếu không có skill, xóa icon
		return

	var skill_data = SkillDatabase.get_skill_data(_skill_id)
	if skill_data.is_empty():
		icon.texture = null
		return

	# Dùng AtlasTexture để cắt icon từ file atlas
	var coords = skill_data.get("atlas_coords")
	if coords is Dictionary and coords.has_all(["x", "y", "w", "h"]):
		var atlas_icon = AtlasTexture.new()
		atlas_icon.atlas = preload("res://texture/item.png") # THAY ĐÚNG ĐƯỜNG DẪN
		atlas_icon.region = Rect2(coords.x, coords.y, coords.w, coords.h)
		icon.texture = atlas_icon

# Bắt đầu chạy cooldown
func start_cooldown(duration: float):
	# Nếu đang có cooldown cũ, hủy nó đi
	if is_instance_valid(_cooldown_timer):
		_cooldown_timer.disconnect("timeout", _on_cooldown_finished)

	cooldown_progress.max_value = duration
	cooldown_progress.value = 100

	# Tạo một SceneTreeTimer mới
	_cooldown_timer = get_tree().create_timer(duration)
	_cooldown_timer.connect("timeout", _on_cooldown_finished)

func _on_cooldown_finished():
	_cooldown_timer = null # Xóa tham chiếu đến timer
	cooldown_progress.value = 0
