extends Camera2D

@export_group("Controls")
@export var speed: float = 300.0
@export var pan_speed: float = 1.5

@export_group("Zoom")
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.3
@export var max_zoom: float = 0.8

var followed_hero: Node2D = null  # Lưu hero đang theo dõi

var is_zoom_locked: bool = false

func _ready() -> void:
	# Kết nối tín hiệu chọn hero với hàm on_hero_selected
	GameEvents.hero_selected.connect(on_hero_selected)
	GameEvents.ui_panel_opened.connect(lock_zoom)
	GameEvents.ui_panel_closed.connect(unlock_zoom)

func lock_zoom():
	is_zoom_locked = true
	print("Camera zoom LOCKED")

func unlock_zoom():
	is_zoom_locked = false
	print("Camera zoom UNLOCKED")

func _process(delta: float) -> void:
	# Giữ nguyên logic di chuyển camera của bạn
	if is_instance_valid(followed_hero):
		position = followed_hero.global_position
	else:
		var direction := Vector2.ZERO
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1
		if Input.is_action_pressed("ui_down"):
			direction.y += 1
		if Input.is_action_pressed("ui_left"):
			direction.x -= 1
		if Input.is_action_pressed("ui_right"):
			direction.x += 1
		direction = direction.normalized()
		position += direction * speed * delta
		
func _unhandled_input(event: InputEvent) -> void:
	# === BƯỚC KIỂM TRA QUAN TRỌNG NHẤT ===
	# Nếu "công tắc" đang bật (bị khóa), không làm gì cả và thoát ngay
	if is_zoom_locked:
		return
	# ======================================

	# Xử lý zoom bằng lăn chuột
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= Vector2.ONE * zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += Vector2.ONE * zoom_speed
		
		# Giới hạn mức độ zoom
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func _input(event: InputEvent) -> void:
	# Giữ lại logic kéo-thả bản đồ bằng chuột phải ở đây
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
		position -= event.relative * pan_speed

# Hàm xử lý khi một hero được chọn (click)
func on_hero_selected(hero_node: Node2D) -> void:
	if followed_hero == hero_node:
		# Click lại hero đang theo dõi -> bỏ theo dõi
		followed_hero = null
		print("Bỏ theo dõi hero")
	else:
		# Chọn hero mới để theo dõi
		followed_hero = hero_node

func on_hero_deselected():
	followed_hero = null
