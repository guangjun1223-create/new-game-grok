# res://Scene/UI/job_skill_panel.gd (PHIÊN BẢN HOÀN CHỈNH CUỐI CÙNG)
extends PanelContainer
class_name JobSkillPanel

# Tín hiệu để "báo cáo" lên UIController
signal upgrade_requested(skill_id: String)
signal equip_requested(skill_id: String)
signal unequip_requested(skill_id: String)

const SkillSlotScene = preload("res://Scene/UI/skill_slot.tscn")

# Biến này sẽ tự tìm đến node được đánh dấu %SkillGrid, BẤT KỂ nó nằm ở đâu
@onready var skill_grid: VBoxContainer = %SkillGrid
@onready var job_name_label: Label = %JobNameLabel

func build_for_job(job_key: String, hero: Hero):
	# Kiểm tra an toàn
	if not is_instance_valid(skill_grid):
		push_error("JobSkillPanel '%s' không thể tìm thấy node con %SkillGrid!" % self.name)
		return
	# Thêm kiểm tra an toàn cho hero
	if not is_instance_valid(hero):
		push_error("JobSkillPanel: build_for_job được gọi nhưng hero không hợp lệ!")
		# Xóa các skill cũ đi để tránh hiển thị sai
		for child in skill_grid.get_children():
			child.queue_free()
		return

	job_name_label.text = "Kỹ năng %s" % GameDataManager.get_job_display_name(job_key)

	# Xóa các skill cũ
	for child in skill_grid.get_children():
		child.queue_free()

	var skills_for_job: Array = SkillDatabase.get_skills_for_job(job_key)

	for skill_id in skills_for_job:
		var new_skill_slot = SkillSlotScene.instantiate()
		skill_grid.add_child(new_skill_slot)
		
		# 1. Setup thông tin cơ bản cho skill slot (giống code cũ của bạn)
		new_skill_slot.setup(skill_id, hero)
		
		# 4. Kết nối tín hiệu (giống code cũ của bạn)
		new_skill_slot.upgrade_requested.connect(upgrade_requested.emit)
		new_skill_slot.equip_requested.connect(equip_requested.emit)
		new_skill_slot.unequip_requested.connect(unequip_requested.emit)

func refresh_skill_usability(hero: Hero):
	if not is_instance_valid(hero): return
	
	# Lặp qua tất cả các ô skill đang có trên bảng
	for skill_slot in skill_grid.get_children():
		# Lấy skill_id đang được lưu trong mỗi ô
		var skill_id = skill_slot.get_skill_id() # (Bạn cần tạo hàm get_skill_id() trong skill_slot.gd)
		
		# Thực hiện kiểm tra và cập nhật lại y hệt như trên
		var check_result = hero.check_skill_requirements(skill_id)
		skill_slot.set_usability(check_result.can_equip, check_result.reason)
