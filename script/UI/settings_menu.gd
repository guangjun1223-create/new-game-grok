# res://script/UI/settings_menu.gd
extends Control

# ĐÃ SỬA LẠI ĐƯỜNG DẪN CHÍNH XÁC 100% DỰA TRÊN ẢNH CHỤP MÀN HÌNH CỦA BẠN
@onready var hp_slider: HSlider = $Panel/VBoxContainer/HBoxContainer/HPS
@onready var hp_percent_label: Label = $Panel/VBoxContainer/HBoxContainer/HP
@onready var sp_slider: HSlider = $Panel/VBoxContainer/HBoxContainer2/SPS
@onready var sp_percent_label: Label = $Panel/VBoxContainer/HBoxContainer2/SP
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var close_x_button: TextureButton = $Panel/CloseXButton


func _ready():
	hp_slider.value_changed.connect(_on_hp_slider_value_changed)
	sp_slider.value_changed.connect(_on_sp_slider_value_changed)
	close_button.pressed.connect(hide)
	close_x_button.pressed.connect(hide)

	_load_settings_to_ui() # GỌI Ở ĐÂY LÀ AN TOÀN NHẤT
	hide()

# Hàm để tải cài đặt từ PlayerStats và cập nhật lên giao diện
func _load_settings_to_ui():
	if hp_slider == null or sp_slider == null:
		push_error("Slider chưa được khởi tạo!")
		return

	var hp_percent = PlayerStats.auto_potion_hp_threshold * 100.0
	hp_slider.value = hp_percent
	hp_percent_label.text = "%d%%" % hp_percent
	
	var sp_percent = PlayerStats.auto_potion_sp_threshold * 100.0
	sp_slider.value = sp_percent
	sp_percent_label.text = "%d%%" % sp_percent


# Hàm được gọi khi thanh trượt HP thay đổi
func _on_hp_slider_value_changed(value: float):
	hp_percent_label.text = "%d%%" % value
	PlayerStats.auto_potion_hp_threshold = value / 100.0


# Hàm được gọi khi thanh trượt SP thay đổi
func _on_sp_slider_value_changed(value: float):
	sp_percent_label.text = "%d%%" % value
	PlayerStats.auto_potion_sp_threshold = value / 100.0
