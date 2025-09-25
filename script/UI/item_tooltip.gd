# item_tooltip.gd (Phiên bản đã được tối ưu)
extends PopupPanel

# --- THAM CHIẾU NODE ---
@onready var name_label: RichTextLabel = $MarginContainer/VBoxContainer/NameLabel
@onready var description_label: RichTextLabel = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_label: RichTextLabel = $MarginContainer/VBoxContainer/StatsLabel


# --- CẤU HÌNH ---
# Danh sách các chỉ số kỹ thuật sẽ bị ẩn khỏi tooltip
const HIDDEN_STATS = ["attack_range_bonus", "attack_speed_mod"]

# "Từ điển" để dịch tên chỉ số từ code (ví dụ: "max_hp") sang tên hiển thị (ví dụ: "HP Tối đa")
# Cách này giúp script không bị phụ thuộc vào GameDataManager
const STAT_DISPLAY_NAMES = {
	"str": "Sức mạnh",
	"agi": "Nhanh nhẹn",
	"vit": "Thể lực",
	"int": "Trí tuệ",
	"dex": "Khéo léo",
	"luk": "May mắn",
	"max_hp": "HP Tối đa",
	"max_sp": "SP Tối đa",
	"atk": "Sát thương",
	"matk": "Sát thương phép",
	"def": "Phòng thủ",
	"mdef": "Phòng thủ phép",
	"hit": "Chính xác",
	"flee": "Né tránh",
	"crit_rate": "Tỉ lệ chí mạng",
	"heal_amount": "Lượng hồi phục"
}

# --- HÀM CHÍNH ---
func update_tooltip(item_id: String, display_mode: String = "full") -> void:
	var item_data: Dictionary = ItemDatabase.get_item_data(item_id)
	if item_data.is_empty():
		hide()
		return
	# Cập nhật tên và mô tả
	name_label.text = item_data.get("item_name", "???")
	match display_mode:
		"price":
			# Chế độ xem giá cho cửa hàng
			description_label.hide() # Ẩn mô tả
			stats_label.show()
			var price = item_data.get("price", 0)
			stats_label.text = "\n[color=gold]Giá bán: %d Vàng[/color]" % price

		"full":
			# Chế độ xem đầy đủ (như cũ)
			description_label.show()
			description_label.text = item_data.get("description", "")
			
			var stats: Dictionary = item_data.get("stats", {})
			if stats.is_empty():
				stats_label.hide()
			else:
				stats_label.show()
				var stats_text = "\n[color=yellow]Thuộc tính:[/color]\n"
				for key in stats:
					if key in HIDDEN_STATS: continue
					var value = stats[key]
					var display_name = STAT_DISPLAY_NAMES.get(key, key.capitalize())
					var color = "lime" if value > 0 else "red"
					var sign_text = "+" if value > 0 else ""
					stats_text += "  [color=%s]%s: %s%s[/color]\n" % [color, display_name, sign_text, str(value)]
				stats_label.text = stats_text
	
	# Yêu cầu panel tự tính toán lại kích thước sau khi cập nhật nội dung
	reset_size()
