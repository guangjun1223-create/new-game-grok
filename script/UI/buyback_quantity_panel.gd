extends PanelContainer
class_name BuybackQuantityPanel

signal purchase_confirmed(hero, item_id, quantity)

@onready var item_name_label: Label = $VBoxContainer/ItemNameLabel
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel
@onready var total_cost_label: Label = $VBoxContainer/TotalCostLabel
@onready var quantity_slider: HSlider = $VBoxContainer/QuantitySlider
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $VBoxContainer/HBoxContainer/CancelButton

var _hero_ref: Hero
var _item_id: String
var _item_price: int = 0
var _max_quantity: int = 0
var _item_data: Dictionary
var _item_type: String

func _ready():
	quantity_slider.value_changed.connect(_on_quantity_slider_value_changed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(queue_free)

func setup(hero: Hero, item_info: Dictionary):
	_hero_ref = hero
	_item_id = item_info.get("id", "")
	_max_quantity = item_info.get("quantity", 0)
	_item_type = item_info.get("item_type", "")
	_item_data = ItemDatabase.get_item_data(_item_id)

	_item_price = _item_data.get("price", 0)
	item_name_label.text = "Mua: " + _item_data.get("item_name", "???")

	if _item_type == "EQUIPMENT":
		quantity_slider.hide()
		quantity_label.text = "Số lượng: 1"
		_update_labels(1)
	else:
		quantity_slider.show()
		quantity_slider.min_value = 1
		quantity_slider.max_value = _max_quantity
		quantity_slider.value = 1
		_update_labels(1)

func _on_confirm_button_pressed():
	var quantity = int(quantity_slider.value)
	if _item_type == "EQUIPMENT":
		quantity = 1
	var total_cost = _item_price * quantity

	if PlayerStats.player_gold >= total_cost:
		purchase_confirmed.emit(_hero_ref, _item_id, quantity)
		queue_free()
	else:
		push_warning("Không đủ tiền để mua!")

func _on_quantity_slider_value_changed(value: float):
	_update_labels(int(value))

func _update_labels(quantity: int):
	quantity_label.text = "Số lượng: " + str(quantity)
	var total_cost = _item_price * quantity
	total_cost_label.text = "Tổng chi phí: %d Vàng" % total_cost
	var can_afford = PlayerStats.player_gold >= total_cost
	confirm_button.disabled = not can_afford
	total_cost_label.modulate = Color.WHITE if can_afford else Color.RED
