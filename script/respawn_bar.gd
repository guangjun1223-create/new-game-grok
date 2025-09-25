extends Control
class_name RespawnBar

# ====================
# THAM CHIẾU NODE
# ====================
@onready var name_label: Label = $NameLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var time_label: Label = $ProgressBar/TimeLabel

# ====================
# BIẾN LƯU TRỮ
# ====================
# Biến này dùng để lưu lại hero mà thanh này đang theo dõi
var hero_ref: Hero 

func setup(hero_to_track: Hero):
	# Gán các giá trị ban đầu
	hero_ref = hero_to_track
	name_label.text = "'%s' được hồi sinh sau:" % hero_ref.hero_name

# ====================
# HÀM CẬP NHẬT GIAO DIỆN
# ====================
func update_display(time_left: float, total_duration: float):
	progress_bar.max_value = total_duration
	progress_bar.value = time_left
	time_label.text = "%d giây" % ceil(time_left)
