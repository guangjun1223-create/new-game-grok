extends Control

# === THAM CHIẾU NODE ===
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var name_input: VBoxContainer = $NameInput
@onready var continue_button: Button = $MainButtons/ContinueButton
@onready var name_line_edit: LineEdit = $NameInput/NameLineEdit
@onready var loading_screen: PanelContainer = $LoadingScreen
@onready var loading_bar: ProgressBar = $LoadingScreen/VBoxContainer/LoadingBar
@onready var loading_label: Label = $LoadingScreen/VBoxContainer/Label

# === DANH SÁCH TÀI NGUYÊN CẦN TẢI ===
# Đây là những "linh hồn" của game, cần được nạp trước
const RESOURCES_TO_LOAD = [
	"res://Scene/world.tscn",
	"res://Scene/hero.tscn",
	"res://Scene/UI.tscn",
	"res://Scene/Monster.tscn"
]
var _post_load_action: Callable

# === HÀM KHỞI ĐỘNG ===
func _ready():
	name_input.visible = false
	loading_screen.visible = false
	main_buttons.visible = true
	
	# Kiểm tra xem có file save không
	if not FileAccess.file_exists(PlayerStats.SAVE_FILE_PATH):
		# Nếu không có, vô hiệu hóa nút "Continue"
		continue_button.disabled = true
		continue_button.text = "Bạn chưa chơi lần nào!!!"

# === CÁC HÀM XỬ LÝ NÚT BẤM ===
func _on_new_game_button_pressed():
	# Gán hành động sau khi load là "hoàn tất game mới"
	_post_load_action = Callable(self, "_finish_new_game_setup")
	# Bắt đầu chuỗi loading
	_start_loading_sequence()
	
func _on_continue_button_pressed():
	# === LOGIC ĐÚNG NẰM Ở ĐÂY ===
	# 1. Gán hành động là "hoàn tất tải game"
	_post_load_action = Callable(self, "_finish_continue_game_setup")
	# 2. Bắt đầu chuỗi loading
	_start_loading_sequence()

func _start_loading_sequence():
	# ... (code loading thật của bạn giữ nguyên) ...
	main_buttons.visible = false
	loading_screen.visible = true
	var total_resources = RESOURCES_TO_LOAD.size()
	for i in range(total_resources):
		var path = RESOURCES_TO_LOAD[i]
		loading_label.text = "Dang tai: %s" % path.get_file()
		ResourceLoader.load_threaded_request(path)
		var progress = []
		while ResourceLoader.load_threaded_get_status(path, progress) != ResourceLoader.THREAD_LOAD_LOADED:
			var total_progress = (float(i) + progress[0]) / total_resources
			loading_bar.value = total_progress * 100
			await get_tree().process_frame
	loading_label.text = "Hoan tat!"
	loading_bar.value = 100
	await get_tree().create_timer(0.5).timeout
	if _post_load_action.is_valid():
		_post_load_action.call()

func _finish_new_game_setup():
	PlayerStats.delete_save_file()
	loading_screen.visible = false
	name_input.visible = true

func _finish_continue_game_setup():
	# 2. Đặt "cờ hiệu" cho world.gd biết cần phải load game
	PlayerStats.should_load_on_enter = true
	# 3. Chuyển màn hình
	get_tree().change_scene_to_file("res://Scene/world.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _on_accept_name_button_pressed(_new_text: String = ""):
	var player_name = name_line_edit.text
	# Kiểm tra xem người chơi đã nhập tên chưa
	if player_name.strip_edges().is_empty():
		# (Tùy chọn) Có thể thêm một Label báo lỗi ở đây
		print("Bạn tên là gì!")
		return
		
	# 1. Xóa save game cũ
	PlayerStats.delete_save_file()
	# 2. Lưu tên người chơi mới
	PlayerStats.player_name = player_name
	PlayerStats.add_item_to_warehouse("summon_scroll", 10)
	# 3. Chuyển sang màn hình game chính
	get_tree().change_scene_to_file("res://Scene/world.tscn")

func _on_back_button_pressed():
	name_input.visible = false
	main_buttons.visible = true
