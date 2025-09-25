# Script InnRoomSelection.gd
extends PanelContainer

# Tín hiệu này sẽ được phát ra khi người chơi chọn một phòng
signal room_selected(hero, inn_level)
# Tín hiệu này sẽ được phát ra khi người chơi đóng bảng
signal panel_closed(hero)

# Tham chiếu đến các Node con bên trong Scene này
@onready var room_list: VBoxContainer = $VBoxContainer # (Sửa lại đường dẫn nếu cần)

var _current_hero: Hero # Biến để lưu hero đang tương tác

# Hàm này sẽ được gọi từ bên ngoài (bởi ui.gd) để khởi tạo bảng
func setup(hero: Hero):
	_current_hero = hero
	_populate_room_list()

# Hàm này tạo ra danh sách các phòng
func _populate_room_list():
	# Xóa danh sách phòng cũ
	for child in room_list.get_children():
		child.queue_free()
	
	var player_inn_level = PlayerStats.current_inn_level
		
	for i in range(1, player_inn_level + 1):
		var level_data = GameDataManager.get_inn_level_data(i)
		if level_data.is_empty(): continue
		
		var cost = level_data["cost"]
		
		var room_button = Button.new()
		if i <= player_inn_level:
			room_button.text = "Phòng Cấp %d - Hồi %d%%/giây - Giá: %d Vàng" % [i, (level_data["heal_percent"] * 100), cost]
			
			if _current_hero.gold < cost:
				room_button.disabled = true
				
			room_button.pressed.connect(_on_room_button_pressed.bind(i))
		else:
			room_button.text = "Phòng cấp %d - [Đã Khóa]" % i
			room_button.disabled = true
			
		room_list.add_child(room_button)
	
	# Thêm nút đóng/quay lại
	var close_button = Button.new()
	close_button.text = "Quay Lại"
	close_button.pressed.connect(_on_close_button_pressed)
	room_list.add_child(close_button)

# Hàm được gọi khi một nút phòng được nhấn
func _on_room_button_pressed(level: int):
	print("Da chon phong cap ", level)
	# Phát tín hiệu ra bên ngoài, báo cho ui.gd biết
	room_selected.emit(_current_hero, level)
	# Tự hủy sau khi đã chọn
	queue_free()

# Hàm được gọi khi nút đóng được nhấn
func _on_close_button_pressed():
	# Phát tín hiệu ra bên ngoài
	panel_closed.emit(_current_hero)
	# Tự hủy
	queue_free()
