# res://autoload/SkillDatabase.gd
extends Node

var _skill_data: Dictionary = {}
# BIẾN MỚI: Dùng để lưu trữ các skill đã được nhóm theo nghề.
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
	
	# === PHẦN BỔ SUNG QUAN TRỌNG ===
	# Sau khi tải xong, gọi hàm xử lý để nhóm các skill lại.
	_process_and_group_skills()
	# =================================

# HÀM MỚI: Chạy 1 lần duy nhất để sắp xếp skill vào từng "ngăn" theo nghề.
func _process_and_group_skills():
	# Lặp qua tất cả skill_id trong dữ liệu gốc
	for skill_id in _skill_data:
		var skill_info: Dictionary = _skill_data[skill_id]
		# Lấy ra job_key của skill đó (Lưu ý: trong file json của bạn là "job")
		var job_key: String = skill_info.get("job")

		# Nếu chưa có "ngăn" cho nghề này, tạo một Array mới
		if not _skills_by_job.has(job_key):
			_skills_by_job[job_key] = []

		# Thêm ID của skill này vào đúng "ngăn" của nó
		_skills_by_job[job_key].append(skill_id)
		
	print("SkillDatabase: Đã nhóm skill cho %d nghề." % _skills_by_job.size())


# Hàm lấy thông tin 1 skill (giữ nguyên)
func get_skill_data(skill_id: String) -> Dictionary:
	return _skill_data.get(skill_id, {})

# === HÀM BỊ THIẾU MÀ CHÚNG TA THÊM VÀO ===
# Hàm này sẽ trả về một Array chứa ID của tất cả các skill thuộc về một nghề.
func get_skills_for_job(job_key: String) -> Array:
	# Trả về danh sách đã được nhóm sẵn, cực kỳ nhanh!
	# Nếu không có skill nào cho nghề đó, trả về một mảng rỗng.
	return _skills_by_job.get(job_key, [])
