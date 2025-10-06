# res://autoload/SkillDatabase.gd
extends Node

var _skill_data: Dictionary = {}
var _skills_by_job: Dictionary = {}


func _ready():
	_load_skill_data()

func _load_skill_data():
	var file_path = "res://Data/skill_data.json"
	if not FileAccess.file_exists(file_path):
		push_error("LỖI: Không tìm thấy file skill_data.json tại: %s" % file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		push_error("LỖI: Dữ liệu trong skill_data.json bị lỗi!")
		return
	
	_skill_data = parse_result
	print("SkillDatabase: Đã tải %d kỹ năng từ JSON." % _skill_data.size())
	
	_process_and_group_skills()

func _process_and_group_skills():
	_skills_by_job.clear() # Xóa dữ liệu cũ phòng trường hợp load lại
	for skill_id in _skill_data:
		var skill_info: Dictionary = _skill_data[skill_id]
		var job_key: String = skill_info.get("job")

		if not _skills_by_job.has(job_key):
			_skills_by_job[job_key] = []

		_skills_by_job[job_key].append(skill_id)
		
	print("SkillDatabase: Đã nhóm skill cho %d nghề." % _skills_by_job.size())

# Hàm lấy thông tin 1 skill (giữ nguyên)
func get_skill_data(skill_id: String) -> Dictionary:
	return _skill_data.get(skill_id, {})

# HÀM DUY NHẤT VÀ CHÍNH XÁC ĐỂ LẤY SKILL THEO NGHỀ
func get_skills_for_job(job_key: String) -> Array:
	return _skills_by_job.get(job_key, [])
