# res://script/UI/job_change_panel.gd
extends Control
class_name JobChangePanel

# Biến để "ghi nhớ" xem Hero nào đang thực hiện chuyển nghề
var current_hero: Hero = null

# Kết nối các node giao diện từ Editor
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/VBoxContainer/DescriptionLabel
@onready var swordsman_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/SwordsmanButton
@onready var mage_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/MageButton
@onready var archer_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ArcherButton
@onready var thief_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ThiefButton
@onready var acolyte_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/AcolyteButton
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

func _ready():
	# Kết nối tín hiệu "pressed" của mỗi nút với một hàm xử lý duy nhất
	# Chúng ta dùng bind() để gửi kèm "job_key" tương ứng khi nút được nhấn
	swordsman_button.pressed.connect(_on_job_button_pressed.bind("Swordsman"))
	mage_button.pressed.connect(_on_job_button_pressed.bind("Mage"))
	archer_button.pressed.connect(_on_job_button_pressed.bind("Archer"))
	thief_button.pressed.connect(_on_job_button_pressed.bind("Thief"))
	acolyte_button.pressed.connect(_on_job_button_pressed.bind("Acolyte"))
	
	close_button.pressed.connect(hide) # Nút đóng chỉ cần ẩn panel đi

# Hàm này sẽ được gọi từ script UI chính để mở bảng chọn
func open_panel(hero_to_change: Hero):
	current_hero = hero_to_change
	
	# Cập nhật các dòng chữ để hiển thị đúng thông tin của Hero
	title_label.text = "Con Đường Mới cho %s" % current_hero.hero_name
	description_label.text = "Cấp %d %s. Hãy chọn một nhánh nghề để phát triển sức mạnh." % [current_hero.level, current_hero.job_key]
	
	show() # Hiện bảng chọn lên

# Hàm xử lý chung khi bất kỳ nút chọn nghề nào được nhấn
func _on_job_button_pressed(new_job_key: String):
	# Kiểm tra lại để chắc chắn có một Hero đang được chọn
	if not is_instance_valid(current_hero):
		push_error("Lỗi Panel: Không có Hero nào để chuyển nghề!")
		return
		
	# Ra lệnh cho Hero thực hiện việc chuyển nghề
	current_hero.change_job(new_job_key)
	
	# Sau khi chuyển xong, ẩn bảng chọn đi
	hide()
