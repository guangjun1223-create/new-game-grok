extends Node

var _item_data: Dictionary = {}

func _ready():
	var file = FileAccess.open("res://Data/item_data.json", FileAccess.READ)
	if not file:
		push_error("ItemDatabase: Khong the mo file items.json!")
		return
		
	var content = file.get_as_text()
	var parse_result = JSON.parse_string(content)
	
	if parse_result:
		_item_data = parse_result
		var item_count = 0
		for category in _item_data:
			item_count += _item_data[category].size()
		print("ItemDatabase: Đã tải thành công %d vật phẩm từ JSON." % item_count)
	else:
		push_error("ItemDatabase: Loi khi doc file JSON!")

# === HÀM TÌM KIẾM ĐÃ ĐƯỢC NÂNG CẤP ===
func get_item_data(item_id: String) -> Dictionary:
	# Lặp qua tất cả các danh mục (weapons, equipment, v.v.)
	for category_key in _item_data:
		var category_dict = _item_data[category_key]
		# Kiểm tra xem vật phẩm có tồn tại trong danh mục này không
		if category_dict.has(item_id):
			# Nếu có, trả về dữ liệu của nó ngay lập tức
			return category_dict[item_id]
			
	# Nếu lặp hết mà không tìm thấy, báo lỗi và trả về dictionary rỗng
	push_error("ItemDatabase: Khong tim thay vat pham voi ID: '%s'" % item_id)
	return {}

# Hàm lấy icon không thay đổi nhiều, nhưng an toàn hơn
func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_data(item_id)
	if data.has("icon_path"):
		return load(data["icon_path"])
	return null
