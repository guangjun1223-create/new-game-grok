# res://script/UI/hero_barracks_panel.gd
extends PanelContainer
class_name HeroBarracksPanel

# --- THAM CHIẾU & TÍN HIỆU ---
const HeroBarracksEntryScene = preload("res://Scene/UI/hero_barracks_entry.tscn")

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var hero_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/HeroListContainer
@onready var close_button: Button = $VBoxContainer/CloseButton

signal display_hero_info_requested(hero_object)

func _ready():
	add_to_group("panels")
	PlayerStats.hero_count_changed.connect(populate_barracks)
	close_button.pressed.connect(queue_free) # Nút đóng chỉ cần tự hủy
	populate_barracks()

# Hàm chính để "vẽ" danh sách Hero
func populate_barracks():
	for child in hero_list_container.get_children():
		child.queue_free()

	var heroes_in_barracks_count = 0
	
	# Lặp qua danh sách roster với cả chỉ số (index)
	for i in range(PlayerStats.hero_roster.size()):
		var hero_instance = PlayerStats.hero_roster[i]
		if hero_instance._current_state == Hero.State.IN_BARRACKS:
			heroes_in_barracks_count += 1
			var new_entry = HeroBarracksEntryScene.instantiate()
			hero_list_container.add_child(new_entry)
			
			# Nạp Hero và vị trí của nó vào thẻ
			new_entry.setup(hero_instance, i)
			# new_entry.info_requested.connect(_on_hero_info_requested)
			new_entry.info_requested.connect(_on_hero_info_requested)
			new_entry.dismiss_requested.connect(_on_hero_dismiss_requested)
	
	title_label.text = "Kho Hero Tạm (%d/%d)" % [heroes_in_barracks_count, PlayerStats.BARRACKS_SIZE]

func _on_hero_info_requested(hero_roster_index: int):
	# Kiểm tra index hợp lệ
	if hero_roster_index < 0 or hero_roster_index >= PlayerStats.hero_roster.size():
		return
	# Lấy đối tượng Hero từ index
	var hero_object = PlayerStats.hero_roster[hero_roster_index]
	# Phát tín hiệu ra ngoài, gửi kèm đối tượng Hero
	display_hero_info_requested.emit(hero_object)

# Khi nhấn nút "Sa thải", giờ chúng ta nhận được vị trí (index)
func _on_hero_dismiss_requested(hero_roster_index: int):
	if hero_roster_index < 0 or hero_roster_index >= PlayerStats.hero_roster.size():
		return
		
	var hero_to_dismiss = PlayerStats.hero_roster[hero_roster_index]
	
	# Nhờ UIController xử lý toàn bộ quá trình sa thải
	if is_instance_valid(PlayerStats.ui_controller_ref):
		PlayerStats.ui_controller_ref.request_hero_dismissal(hero_to_dismiss)
