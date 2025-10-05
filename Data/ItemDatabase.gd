# res://autoload/ItemDatabase.gd
extends Node

# Atlas chính cho các icon được định nghĩa bằng tọa độ
const ITEM_ATLAS = preload("res://texture/item001.png")

var _item_data: Dictionary = {}
var _item_lookup: Dictionary = {} # "Mục lục" tra cứu nhanh theo ID
var _category_lookup: Dictionary = {} # "Mục lục" tra cứu nhanh theo Category

func _ready():
	var file = FileAccess.open("res://Data/item_data.json", FileAccess.READ)
	if not file:
		push_error("ItemDatabase: Khong the mo file item_data.json!")
		return
		
	var content = file.get_as_text()
	var parse_result = JSON.parse_string(content)
	
	if parse_result:
		_item_data = parse_result
		_build_lookup_tables() # <-- GỌI HÀM XÂY DỰNG "MỤC LỤC"
		print("ItemDatabase: Đã tải và phân loại thành công %d vật phẩm." % _item_lookup.size())
	else:
		push_error("ItemDatabase: Loi khi doc file JSON!")

# --- HÀM MỚI: Xây dựng "mục lục" để tra cứu siêu nhanh ---
func _build_lookup_tables():
	# Lặp qua tất cả các danh mục lớn (weapons, equipment, v.v.)
	for category_key in _item_data:
		var category_dict = _item_data[category_key]
		# Lặp qua từng vật phẩm trong danh mục đó
		for item_id in category_dict:
			var item_details = category_dict[item_id]
			
			# 1. Thêm vào mục lục tra cứu theo ID
			_item_lookup[item_id] = item_details
			
			# 2. Thêm vào mục lục tra cứu theo category bên trong
			var internal_category = item_details.get("category")
			if internal_category:
				if not _category_lookup.has(internal_category):
					_category_lookup[internal_category] = [] # Tạo danh sách mới nếu chưa có
				_category_lookup[internal_category].append(item_id)

# === CÁC HÀM GET DỮ LIỆU ĐÃ ĐƯỢC TỐI ƯU HÓA ===

# Hàm này giờ đây siêu nhanh, chỉ cần tra cứu trong "mục lục"
func get_item_data(item_id: String) -> Dictionary:
	if _item_lookup.has(item_id):
		return _item_lookup[item_id]
	
	push_error("ItemDatabase: Khong tim thay vat pham voi ID: '%s'" % item_id)
	return {}

# Hàm này giờ cũng siêu nhanh, chỉ cần tra cứu trong "mục lục"
func get_all_items_in_category(category_name: String) -> Array[String]:
	# Trả về danh sách ID vật phẩm thuộc category, hoặc một mảng rỗng nếu không có
	return _category_lookup.get(category_name, [])

# Hàm này vẫn giữ nguyên vì nó đã rất tốt
func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_data(item_id)
	if data.is_empty(): return null

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
		if not data["icon_path"].is_empty() and ResourceLoader.exists(data["icon_path"]):
			return load(data["icon_path"])
		else:
			push_warning("ItemDatabase: Duong dan icon_path khong hop le cho item '%s'" % item_id)

	return null

# Hai hàm get_items_by_category và is_item_in_category không còn cần thiết nữa
# vì hàm get_all_items_in_category mới đã mạnh mẽ và hiệu quả hơn.
# Việc giữ ít hàm hơn giúp code của bạn sạch sẽ hơn.
