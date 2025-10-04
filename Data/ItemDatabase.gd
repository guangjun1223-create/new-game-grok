extends Node

const ITEM_ATLAS = preload("res://texture/item001.png")

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
	
	# ƯU TIÊN 1: Tìm theo tọa độ Atlas
	if data.has("atlas_coords"):
		var coords = data["atlas_coords"]
		if coords is Dictionary and coords.has_all(["x", "y", "w", "h"]):
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = ITEM_ATLAS
			atlas_texture.region = Rect2(coords.x, coords.y, coords.w, coords.h)
			return atlas_texture

	# ƯU TIÊN 2: Nếu không có Atlas, tìm theo đường dẫn file .tres/.png
	if data.has("icon_path"):
		# Kiểm tra xem đường dẫn có hợp lệ không trước khi load
		if not data["icon_path"].is_empty() and ResourceLoader.exists(data["icon_path"]):
			return load(data["icon_path"])
		else:
			push_warning("ItemDatabase: Duong dan icon_path khong hop le cho item '%s'" % item_id)

	# Nếu không có cả hai, trả về null
	return null

func get_all_items_in_category(category_name: String) -> Array[String]:
	var items_in_category: Array[String] = []
	for item_type_key in _item_data:
		var items_of_type = _item_data[item_type_key]
		for item_id in items_of_type:
			var item_details = items_of_type[item_id]
			if item_details.get("category") == category_name:
				items_in_category.append(item_id)
	return items_in_category
	
func get_items_by_category(category_key_to_find: String) -> Dictionary:
	# Kiểm tra xem danh mục có tồn tại trong dữ liệu item không
	if _item_data.has(category_key_to_find):
		# Nếu có, trả về toàn bộ dictionary của danh mục đó
		return _item_data[category_key_to_find]
	else:
		# Nếu không, báo lỗi và trả về dictionary rỗng
		push_error("ItemDatabase: Không tìm thấy danh mục: '%s'" % category_key_to_find)
		return {}
		
func is_item_in_category(item_id: String, category_key: String) -> bool:
	# 1. Kiểm tra xem danh mục có tồn tại không
	if not _item_data.has(category_key):
		return false # Nếu không có danh mục "potion" thì trả về false luôn
	
	# 2. Nếu danh mục tồn tại, kiểm tra xem item có trong đó không
	return _item_data[category_key].has(item_id)
