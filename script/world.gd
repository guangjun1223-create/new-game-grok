# world.gd
extends Node2D
class_name World

@export var gate_connections: Array[GateConnection]

func _ready() -> void:
	await get_tree().process_frame
	# Bây giờ, việc gọi PlayerStats sẽ an toàn.
	PlayerStats.register_gate_connections(gate_connections)
	PlayerStats.initialize_world_references()
	
	if PlayerStats.should_load_on_enter:
		# Thực thi lệnh tải game
		PlayerStats.load_game()
		# Reset lại cờ hiệu để lần sau vào world không bị load lại
		PlayerStats.should_load_on_enter = false


func _on_village_boundary_body_entered(body: Node2D) -> void:
	# Kiểm tra xem đối tượng đi vào có phải là Hero không
	if body is Hero:
		var hero: Hero = body
		print("Hero '%s' đã vào làng, tắt chế độ Farming." % hero.name)
		hero.set_farming_mode(false) # Ra lệnh cho hero tắt farm


func _on_village_boundary_body_exited(body: Node2D) -> void:
	# Kiểm tra xem đối tượng đi ra có phải là Hero không
	if body is Hero:
		var hero: Hero = body
		print("Hero '%s' đã rời làng, bật chế độ Farming." % hero.name)
		hero.set_farming_mode(true) # Ra lệnh cho hero bật farm

func _unhandled_input(event: InputEvent) -> void:
	# Hàm này sẽ được gọi mỗi khi có một input (như click chuột)
	# mà không có Node nào khác (như Hero, UI) xử lý nó.
	# Tức là khi người chơi click vào khoảng không.

	# Kiểm tra xem đó có phải là một cú click chuột trái không
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Nếu đúng, phát đi tín hiệu "bỏ chọn hero" cho toàn game
		GameEvents.hero_deselected.emit()
