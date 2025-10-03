# VFX_Player.gd
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Tự hủy sau khi animation chạy xong
	animated_sprite.animation_finished.connect(queue_free)

# Hàm để chơi một animation cụ thể
func play_effect(animation_name: String):
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		print("Lỗi VFX: Không tìm thấy animation '%s'" % animation_name)
		queue_free() # Tự hủy nếu không có animation
