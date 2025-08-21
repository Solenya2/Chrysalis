extends Button

@onready var sold_overlay: TextureRect = $SoldOverlay   # ← new line
var shop_item: ShopItem

func setup(s_item: ShopItem):
	shop_item = s_item
	self.icon = shop_item.item.icon
	$PriceLabel.text = str(shop_item.price)


func _pressed() -> void:
	var inv := ReferenceStash.inventory
	var gold_item := load("res://items/gold_item.tres")

	var idx := inv.get_item_index(gold_item)
	if idx != -1:
		var box: ItemBox = inv.get_item_boxes()[idx]
		if box.amount >= shop_item.price:
			inv.remove_item(gold_item, shop_item.price)
			inv.add_item(shop_item.item, 1)
			Sound.play(Sound.menu_select)

			sold_overlay.visible = true      # ← mark as sold
			disabled = true                  # optional: stop further clicks
