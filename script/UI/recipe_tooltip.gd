# Script RecipeTooltip.gd
extends PopupPanel

@onready var item_name_label: RichTextLabel = $VBoxContainer/ItemNameLabel
@onready var materials_label: RichTextLabel = $VBoxContainer/MaterialsLabel
@onready var cost_label: RichTextLabel = $VBoxContainer/CostLabel

# Hàm này sẽ được gọi từ bên ngoài để xây dựng tooltip
func build_tooltip(recipe: Dictionary):

	var result_item_data = ItemDatabase.get_item_data(recipe["result"]["item_id"])
	
	# === HIỂN THỊ TÊN VẬT PHẨM ===
	if is_instance_valid(item_name_label):
		var item_name = result_item_data.get("item_name", "???")
		item_name_label.text = "[center][font_size=18]%s[/font_size][/center]" % item_name
	
	# === HIỂN THỊ NGUYÊN LIỆU ===
	if is_instance_valid(materials_label):
		var materials_text = "[font_size=18]Nguyên liệu:[/font_size]\n"
		var materials_needed = recipe.get("materials", [])
		for material in materials_needed:
			var required_item_id = material["item_id"]
			var required_quantity = material["quantity"]
			var material_data = ItemDatabase.get_item_data(required_item_id)
			
			var quantity_in_warehouse = 0
			for item_in_warehouse in PlayerStats.warehouse:
				if item_in_warehouse and item_in_warehouse["id"] == required_item_id:
					quantity_in_warehouse += item_in_warehouse["quantity"]
			
			var color = "lime" if quantity_in_warehouse >= required_quantity else "red"
			var material_name = material_data.get("item_name", "???")
			materials_text += "  [color=%s]● %s: %d/%d[/color]\n" % [color, material_name, quantity_in_warehouse, required_quantity]
			
		materials_label.text = materials_text
	
	# === HIỂN THỊ CHI PHÍ ===
	if is_instance_valid(cost_label):
		var cost = recipe.get("cost", 0)
		var cost_color = "lime" if PlayerStats.player_gold >= cost else "red"
		var cost_text = "[font_size=18]Chi phí: [/font_size][color=%s]%d Vàng[/color]" % [cost_color, cost]
		cost_label.text = cost_text
