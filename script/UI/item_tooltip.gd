# res://script/UI/item_tooltip.gd (Phiên bản Hoàn thiện)
extends PopupPanel

# --- THAM CHIẾU NODE ---
# Đảm bảo các đường dẫn này khớp với scene ItemTooltip.tscn của bạn
@onready var name_label: RichTextLabel = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var description_label: RichTextLabel = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_label: RichTextLabel = $MarginContainer/VBoxContainer/StatsLabel

# --- CẤU HÌNH ---
# Các chỉ số không muốn hiển thị trên tooltip
const HIDDEN_STATS = ["attack_range_bonus", "attack_speed_mod", "bonus_aspd_flat"]

# Bảng dịch tên chỉ số để hiển thị cho người chơi
const STAT_DISPLAY_NAMES = {
	"str": "Sức mạnh", "agi": "Nhanh nhẹn", "vit": "Thể lực",
	"int": "Trí tuệ", "dex": "Khéo léo", "luk": "May mắn",
	"max_hp": "HP Tối đa", "max_sp": "SP Tối đa", "atk": "Sát thương",
	"matk": "Sát thương phép", "def": "Phòng thủ", "mdef": "Phòng thủ phép",
	"hit": "Chính xác", "flee": "Né tránh", "crit_rate": "Tỉ lệ chí mạng",
	"crit_dame": "ST chí mạng",
	"heal_amount": "Hồi phục HP", "sp_restore_amount": "Hồi phục SP"
}

# THAY THẾ TOÀN BỘ HÀM CŨ BẰNG HÀM NÀY
func update_tooltip(item_info: Variant, display_mode: String = "full") -> void:
	var item_id = ""
	var upgrade_level = 0

	# 1. NHẬN DIỆN DỮ LIỆU ĐẦU VÀO
	# Hàm này giờ có thể nhận cả String (ID) và Dictionary (thông tin item)
	if item_info is String:
		item_id = item_info
	elif item_info is Dictionary:
		if item_info.has("base_id"): # Đây là TRANG BỊ (cấu trúc mới)
			item_id = item_info.base_id
			upgrade_level = item_info.get("upgrade_level", 0)
		elif item_info.has("id"): # Đây là VẬT PHẨM THƯỜNG (cấu trúc cũ)
			item_id = item_info.id
	
	# Nếu không nhận diện được, ẩn tooltip và thoát
	if item_id.is_empty():
		hide()
		return

	# 2. LẤY DỮ LIỆU GỐC TỪ DATABASE
	var base_item_data = ItemDatabase.get_item_data(item_id)
	if base_item_data.is_empty():
		hide()
		return

	# 3. HIỂN THỊ TÊN VÀ CẤP NÂNG CẤP
	var item_name = base_item_data.get("item_name", "???")
	var name_text = "[b]%s[/b]" % item_name
	if upgrade_level > 0:
		name_text += " [color=gold]+%d[/color]" % upgrade_level
	name_label.text = name_text
	
	# 4. HIỂN THỊ LOẠI VẬT PHẨM
	var item_type_text = base_item_data.get("item_type", "").capitalize()
	var equip_slot_text = base_item_data.get("equip_slot", "")
	if not equip_slot_text.is_empty():
		type_label.text = "Loại: %s (%s)" % [item_type_text, equip_slot_text]
	else:
		type_label.text = "Loại: %s" % item_type_text

	# 5. HIỂN THỊ MÔ TẢ
	description_label.text = base_item_data.get("description", "")
	
	# 6. TÍNH TOÁN VÀ HIỂN THỊ CHỈ SỐ
	var base_stats = base_item_data.get("stats", {})
	var stats_text = ""
	
	if not base_stats.is_empty():
		stats_text += "\n[color=yellow]Thuộc tính:[/color]\n"
		
		# Tính toán hệ số nhân từ cấp nâng cấp (10% mỗi cấp)
		var multiplier = 1.0 + (upgrade_level * 0.10)

		for key in base_stats:
			if key in HIDDEN_STATS: continue
			
			var base_value = base_stats[key]
			# Áp dụng hệ số nhân cho chỉ số của trang bị
			var final_value = base_value * multiplier if base_item_data.get("item_type") == "EQUIPMENT" else base_value
			
			var display_name = STAT_DISPLAY_NAMES.get(key, key.capitalize())
			var color = "lime" if final_value >= 0 else "red"
			var sign_text = "+" if final_value > 0 else ""

			# Làm tròn số nếu là số thập phân
			var value_str = str(snapped(final_value, 0.01))
			
			stats_text += "  [color=%s]%s: %s%s[/color]\n" % [color, display_name, sign_text, value_str]

	# 7. HIỂN THỊ GIÁ (NẾU CÓ)
	var price = base_item_data.get("price", 0)
	if display_mode == "price" and price > 0:
		stats_text += "\n[color=gold]Giá bán: %d Vàng[/color]" % price

	if stats_text.is_empty():
		stats_label.hide()
	else:
		stats_label.text = stats_text
		stats_label.show()
