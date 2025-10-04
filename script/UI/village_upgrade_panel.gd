# res://script/UI/village_upgrade_panel.gd
extends Control
class_name VillageUpgradePanel

# --- THAM CHIẾU NODE ---
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var level_info_label: Label = $PanelContainer/VBoxContainer/LevelInfoLabel
@onready var requirements_list_label: RichTextLabel = $PanelContainer/VBoxContainer/RequirementsListLabel
@onready var reward_description_label: Label = $PanelContainer/VBoxContainer/RewardHeaderLabel
@onready var upgrade_button: Button = $PanelContainer/VBoxContainer/UpgradeButton
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

signal panel_closed

func _ready():
	
	# Kết nối các tín hiệu
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Lắng nghe tín hiệu từ PlayerStats để tự cập nhật khi Làng lên cấp
	PlayerStats.village_level_changed.connect(_on_village_level_changed)
	
	# Cập nhật giao diện lần đầu tiên
	update_display()

# Hàm chính để "vẽ" lại toàn bộ thông tin trên panel
func update_display():
	var current_level = PlayerStats.village_level
	var next_level = current_level + 1
	
	level_info_label.text = "Nâng cấp từ Cấp %d -> Cấp %d" % [current_level, next_level]
	
	var upgrade_data = GameDataManager.get_village_level_data(str(next_level))
	if upgrade_data.is_empty():
		requirements_list_label.text = "Đã đạt cấp độ tối đa!"
		upgrade_button.disabled = true
		return
		
	var requirements_text = ""
	# 1. Yêu cầu Vàng
	var gold_cost = upgrade_data.get("gold_cost", 0)
	var player_has_gold = PlayerStats.player_gold
	
	if player_has_gold >= gold_cost:
		requirements_text += "[color=white]Vàng: %d / %d[/color]\n" % [player_has_gold, gold_cost]
	else:
		requirements_text += "[color=red]Vàng: %d / %d[/color]\n" % [player_has_gold, gold_cost]
		
	# 2. Yêu cầu Nguyên liệu
	var materials_needed = upgrade_data.get("materials", [])
	
	# === SỬA LẠI TÊN BIẾN Ở ĐÂY ===
	for material_data in materials_needed: # Đổi từ "material" thành "material_data"
		var item_id = material_data["id"]
		var required_qty = material_data["quantity"]
		# ============================
		
		var player_has_qty = PlayerStats.get_item_quantity_in_warehouse(item_id)
		var item_name = ItemDatabase.get_item_data(item_id).get("item_name", "???")
		
		if player_has_qty >= required_qty:
			requirements_text += "[color=white]%s: %d / %d[/color]\n" % [item_name, player_has_qty, required_qty]
		else:
			requirements_text += "[color=red]%s: %d / %d[/color]\n" % [item_name, player_has_qty, required_qty]
			
	requirements_list_label.text = requirements_text
	
	# Hiển thị phần thưởng
	reward_description_label.text = upgrade_data.get("unlocks_description", "Không có phần thưởng đặc biệt.")
	
	# Bật/tắt nút Nâng cấp
	upgrade_button.disabled = not PlayerStats.can_upgrade_village()

# Hàm được gọi khi nhấn nút Nâng Cấp
func _on_upgrade_button_pressed():
	PlayerStats.upgrade_village()

# Hàm được gọi khi PlayerStats phát tín hiệu làng đã lên cấp
func _on_village_level_changed(_new_level):
	# Chỉ cần gọi lại hàm update_display là mọi thứ sẽ tự làm mới
	update_display()
	
func _on_close_button_pressed():
	panel_closed.emit() # Phát tín hiệu báo rằng panel sắp đóng
	queue_free() 
