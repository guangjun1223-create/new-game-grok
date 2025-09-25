# GateConnection.gd
extends Resource
class_name GateConnection

# SỬA LỖI: Thay vì lưu trực tiếp Node, chúng ta sẽ lưu đường dẫn đến Node đó.
# Kiểu dữ liệu NodePath được thiết kế đặc biệt cho việc này.
# Godot Editor sẽ tự động tạo một ô để bạn kéo thả Node vào,
# và nó sẽ tự chuyển đổi thành đường dẫn.
@export var area_from: NodePath
@export var area_to: NodePath
@export var gate_node: NodePath
