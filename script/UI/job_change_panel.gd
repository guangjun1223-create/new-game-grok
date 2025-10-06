# res://script/UI/job_change_panel.gd
extends Control
class_name JobChangePanel

# Biến để "ghi nhớ" xem Hero nào đang thực hiện chuyển nghề
var current_hero: Hero = null

# Kết nối các node giao diện từ Editor
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/VBoxContainer/DescriptionLabel
@onready var requirements_label: RichTextLabel = $PanelContainer/VBoxContainer/RequirementsLabel
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
	print("[JobChangePanel] Hàm open_panel() đã được gọi. Đang hiển thị panel...")
	current_hero = hero_to_change
	
	title_label.text = "Con Đường Mới cho %s" % current_hero.hero_name
	
	var stats_component = current_hero.hero_stats
	description_label.text = "Cấp %d %s. Hãy chọn một nhánh nghề để phát triển sức mạnh." % [stats_component.level, stats_component.job_key]
	
	# Hiển thị các yêu cầu
	var requirements = GameDataManager.get_job_change_requirements()
	var req_text = "[b]Yêu cầu:[/b]\n"
	req_text += "- Vàng: [color=gold]%d[/color]\n" % requirements.get("gold_cost", 0)
	for item in requirements.get("items", []):
		var item_data = ItemDatabase.get_item_data(item["id"])
		req_text += "- %s: x%d\n" % [item_data.get("name", item["id"]), item["quantity"]]
	requirements_label.text = req_text
	
	show()
	

func _on_job_button_pressed(new_job_key: String):
	if not is_instance_valid(current_hero):
		push_error("Lỗi Panel: Không có Hero nào để chuyển nghề!")
		return
		
	# Kiểm tra lại một lần nữa trước khi trừ tiền
	if not current_hero.can_change_job():
		FloatingTextManager.show_text("Không đủ điều kiện!", Color.RED, get_viewport().get_mouse_position())
		return
	
	# Trừ chi phí
	current_hero.consume_job_change_costs()
	
	# Ra lệnh cho Hero thực hiện việc chuyển nghề
	current_hero.change_job(new_job_key)
	
	hide()
