# FloatingTextManager.gd
extends Node

# Preload (tải trước) scene chữ bay để dùng nhanh hơn
var floating_text_scene = preload("res://Scene/UI/FloatingText.tscn")
var main_scene_root: Node

func _ready():
	# Chờ một frame để đảm bảo scene chính đã tải xong
	await get_tree().process_frame
	main_scene_root = get_tree().current_scene

# "API" để các script khác gọi đến
func show_text(text: String, color: Color, position: Vector2, is_crit: bool = false):
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.position = position
	label.set_scale(Vector2(2, 2) if is_crit else Vector2(2.5, 2.5))
	# Add label vào scene phù hợp
	get_tree().current_scene.add_child(label)
	# Start tween hoặc timer fade out rồi queue_free label
	start_fade_out(label)

func start_fade_out(label: Label) -> void:
	var tween = get_tree().create_tween()
	# Tween giảm alpha modulate
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Callback ẩn label khi hoàn thành tween
	tween.tween_callback(func ():
		if is_instance_valid(label):
			label.queue_free()
	)
	
