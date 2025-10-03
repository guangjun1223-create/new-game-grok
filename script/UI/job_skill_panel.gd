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

	job_name_label.text = "Kỹ năng %s" % GameDataManager.get_job_display_name(job_key)

	for child in skill_grid.get_children():
		child.queue_free()

	var skills_for_job: Array = SkillDatabase.get_skills_for_job(job_key)

	for skill_id in skills_for_job:
		var new_skill_slot = SkillSlotScene.instantiate()
		skill_grid.add_child(new_skill_slot)
		new_skill_slot.setup(skill_id, hero)
		
		# Kết nối tín hiệu từ SkillSlot -> JobSkillPanel
		new_skill_slot.upgrade_requested.connect(upgrade_requested.emit)
		new_skill_slot.equip_requested.connect(equip_requested.emit)
		new_skill_slot.unequip_requested.connect(unequip_requested.emit)
