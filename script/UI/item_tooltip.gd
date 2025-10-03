# item_tooltip.gd (Phiên bản đã được tối ưu)
extends PopupPanel

# --- THAM CHIẾU NODE ---
@onready var name_label: RichTextLabel = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var description_label: RichTextLabel = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_label: RichTextLabel = $MarginContainer/VBoxContainer/StatsLabel

# --- CẤU HÌNH ---
const HIDDEN_STATS = ["attack_range_bonus", "attack_speed_mod"]

const STAT_DISPLAY_NAMES = {
	"str": "Sức mạnh", "agi": "Nhanh nhẹn", "vit": "Thể lực",
	"int": "Trí tuệ", "dex": "Khéo léo", "luk": "May mắn",
	"max_hp": "HP Tối đa", "max_sp": "SP Tối đa", "atk": "Sát thương",
	"matk": "Sát thương phép", "def": "Phòng thủ", "mdef": "Phòng thủ phép",
	"hit": "Chính xác", "flee": "Né tránh", "crit_rate": "Tỉ lệ chí mạng",
	"heal_amount": "Hồi phục HP", "sp_restore_amount": "Hồi phục SP"
}

# Bảng màu cho phẩm chất trang bị
const QUALITY_COLORS = {
	"Hiếm": "red",
	"Rất Tốt": "gold",
	"Tốt": "palegreen",
	"Thường": "white",
	"Kém": "#AAAAAA" # Mã màu xám trắng
}

# Thay thế toàn bộ hàm update_tooltip trong file item_tooltip.gd

func update_tooltip(p_item_data_or_id, display_mode: String = "full") -> void:
	var item_data: Dictionary
	var item_id: String

	# 1. NHẬN DIỆN VÀ CHUẨN HÓA DỮ LIỆU
	if typeof(p_item_data_or_id) == TYPE_STRING:
		item_id = p_item_data_or_id
		item_data = ItemDatabase.get_item_data(item_id)
	elif typeof(p_item_data_or_id) == TYPE_DICTIONARY:
		item_data = p_item_data_or_id
		item_id = item_data.get("id", "")
	else:
		hide(); return

	if item_data.is_empty() and item_id.is_empty():
		hide(); return

	# Lấy dữ liệu gốc từ database để đảm bảo luôn có thông tin cơ bản
	var base_item_data = ItemDatabase.get_item_data(item_id)
	if base_item_data.is_empty():
		# Nếu không tìm thấy trong DB, cố gắng hiển thị từ dữ liệu được truyền vào
		if item_data.has("item_name"):
			name_label.text = item_data["item_name"]
			description_label.text = item_data.get("description", "")
			stats_label.hide()
			show()
		else:
			hide()
		return

	# 2. XỬ LÝ MÀU SẮC
	var item_name = item_data.get("item_name", base_item_data.get("item_name", "???"))
	var item_quality = item_data.get("quality", "Thường")
	var color_name = QUALITY_COLORS.get(item_quality, "white")
	name_label.text = "[color=" + color_name + "]" + item_name + "[/color]"

	# 3. HIỂN THỊ THÔNG TIN CÒN LẠI
	description_label.text = item_data.get("description", base_item_data.get("description", ""))
	var stats: Dictionary = item_data.get("stats", base_item_data.get("stats", {}))
	var price = base_item_data.get("price", 0)
	var stats_text = ""

	if not stats.is_empty():
		stats_text += "\n[color=yellow]Thuộc tính:[/color]\n"
		for key in stats:
			if key in HIDDEN_STATS: continue
			var value = stats[key]
			var display_name = STAT_DISPLAY_NAMES.get(key, key.capitalize())
			var color = "lime" if value > 0 else "red"
			var sign_text = "+" if value > 0 else ""
			stats_text += "  [color=%s]%s: %s%s[/color]\n" % [color, display_name, sign_text, str(value)]

	if display_mode == "price" and price > 0:
		stats_text += "\n[color=gold]Giá bán: %d Vàng[/color]" % price

	if stats_text.is_empty():
		stats_label.hide()
	else:
		stats_label.text = stats_text
		stats_label.show()

	reset_size()
