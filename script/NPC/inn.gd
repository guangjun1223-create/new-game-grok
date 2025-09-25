# Script Inn.gd (PHIÊN BẢN HOÀN CHỈNH)
extends StaticBody2D

const InnStatusBarScene = preload("res://Scene/inn_status_bar.tscn")

const FLAVOR_ANIMATIONS = [
	"Chagrin", "Communication", "Greeting", "Greeting_2", "Joy", "Idle", "Idle Blinking"
]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InnEntranceArea
@onready var animation_timer: Timer =$AnimationTimer
# Dictionary để quản lý các hero đang nghỉ: { hero_node: status_bar_node }
var resting_heroes: Dictionary = {}

func _ready():
	GameEvents.inn_room_chosen.connect(_on_hero_started_resting)
	PlayerStats.register_inn(self)
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta):
	# Nếu không có hero nào đang nghỉ, không làm gì cả
	if resting_heroes.is_empty():
		return
		
	# Lặp qua tất cả các hero đang nghỉ để hồi máu
	# .keys().duplicate() để tránh lỗi khi xóa phần tử trong lúc lặp
	for hero in resting_heroes.keys().duplicate():
		# Kiểm tra an toàn
		if not is_instance_valid(hero):
			_remove_resting_hero(hero)
			continue
			
		# Hồi HP và SP dựa trên % mỗi giây
		hero.current_hp += hero.max_hp * hero.current_heal_rate * delta
		hero.current_sp += hero.max_sp * hero.current_heal_rate * delta
		
		# Giới hạn không cho vượt max
		hero.current_hp = min(hero.current_hp, hero.max_hp)
		hero.current_sp = min(hero.current_sp, hero.max_sp)
		
		# Cập nhật thanh ProgressBar
		var status_bar = resting_heroes[hero]
		if is_instance_valid(status_bar):
			# Tính tổng % hồi phục để cập nhật thanh bar
			var progress_bar = status_bar.get_node_or_null("VBoxContainer/ProgressBar")
			
			if is_instance_valid(progress_bar):
				# Tính tổng % hồi phục để cập nhật thanh bar
				var total_percent = (hero.current_hp / hero.max_hp + hero.current_sp / hero.max_sp) / 2.0
				progress_bar.value = total_percent * 100
			else:
				# Nếu không tìm thấy, báo lỗi rõ ràng và dừng game để dễ debug
				push_error("LOI NGHIEM TRONG: Khong tim thay Node 'VBoxContainer/ProgressBar' trong InnStatusBar.tscn!")
				get_tree().paused = true # Tạm dừng game
			# ==============================
		
		# Kiểm tra nếu đã hồi đầy
		if hero.current_hp >= hero.max_hp and hero.current_sp >= hero.max_sp:
			print("Hero '%s' da hoi phuc day." % hero.name)
			_remove_resting_hero(hero)

func _on_hero_started_resting(hero, _heal_rate):
	var status_bar = InnStatusBarScene.instantiate()
	add_child(status_bar)

	var spawn_point = get_node_or_null("StatusBarSpawnPoint")
	if is_instance_valid(spawn_point):
		status_bar.global_position = spawn_point.global_position + Vector2(0, resting_heroes.size() * 40)
	else:
		status_bar.global_position = global_position - Vector2(50, 150 + resting_heroes.size() * 40)

	# === PHẦN SỬA LỖI QUAN TRỌNG ===
	# Tìm Node Label và ProgressBar bên trong status_bar
	var name_label = status_bar.get_node_or_null("VBoxContainer/Label")
	var progress_bar = status_bar.get_node_or_null("VBoxContainer/ProgressBar")
	
	# Chỉ gán giá trị nếu tìm thấy Node
	if is_instance_valid(name_label):
		name_label.text = hero.hero_name
	else:
		push_error("Loi: Khong tim thay Node 'VBoxContainer/Label' trong InnStatusBar.tscn!")

	if is_instance_valid(progress_bar):
		progress_bar.max_value = 100
	else:
		push_error("Loi: Khong tim thay Node 'VBoxContainer/ProgressBar' trong InnStatusBar.tscn!")
	# ==============================
	
	resting_heroes[hero] = status_bar


# Hàm dọn dẹp
func _remove_resting_hero(hero):
	# Kiểm tra xem hero có thực sự đang nghỉ ở đây không
	if resting_heroes.has(hero):
		var status_bar = resting_heroes[hero]
		if is_instance_valid(status_bar):
			status_bar.queue_free()
		resting_heroes.erase(hero)
		
	# Chỉ gọi finish_resting nếu hero vẫn còn tồn tại
	if is_instance_valid(hero):
		hero.finish_resting()


func _on_inn_entrance_area_body_entered(body: Node2D) -> void:
	if body is Hero:
		var hero = body as Hero
		if hero._current_state == Hero.State.NAVIGATING:
			print(">>> Inn: Phat hien hero '%s' da den." % hero.name)

			# === KẾT NỐI TÍN HIỆU (QUAN TRỌNG) ===
			# Kết nối với tín hiệu "bắt đầu nghỉ" của CHÍNH hero này
			# Điều này đảm bảo Inn luôn lắng nghe đúng hero
			if not hero.started_resting.is_connected(_on_hero_started_resting):
				hero.started_resting.connect(_on_hero_started_resting)
			# ======================================

			# Phát tín hiệu để UI mở bảng chọn phòng
			GameEvents.hero_arrived_at_inn.emit(hero)

func _on_animation_timer_timeout():
	# Chỉ chơi animation ngẫu nhiên nếu đang ở trạng thái rảnh rỗi (Idle)
	if animated_sprite.animation == "Idle" or animated_sprite.animation == "Idle Blinking":
		# Chọn một animation ngẫu nhiên từ danh sách
		var next_anim = FLAVOR_ANIMATIONS.pick_random()
		animated_sprite.play(next_anim)
	
	# Đặt lại thời gian chờ ngẫu nhiên cho lần tiếp theo (từ 5 đến 10 giây)
	animation_timer.wait_time = randf_range(5.0, 10.0)
	animation_timer.start()

# Hàm này được gọi khi một animation chơi xong
func _on_animation_finished():
	# Sau khi chơi xong bất kỳ animation nào, quay trở lại trạng thái Idle Blinking
	animated_sprite.play("Idle Blinking")
