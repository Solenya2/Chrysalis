# ItemSlotManager.gd — Utility class for updating item slot visuals (icon and amount).
# Used by InventorySlotUI, ActionSlotUI, and other item-driven UI components.

class_name ItemSlotManager
extends RefCounted

# Default texture used when no item is present in the slot
const EMPTY_SLOT_TEXTURE := preload("res://ui/empty_inventory_slot.png")

# Updates the icon on a UI slot based on the item in the given ItemBox
# icon_property is the property name to assign to (e.g., "texture", "icon")
static func update_slot_icon(item_box: ItemBox, slot: Control, icon_property: String) -> void:
	var item := item_box.item
	if item is Item:
		slot[icon_property] = item.icon
	else:
		slot[icon_property] = EMPTY_SLOT_TEXTURE

# Updates the amount label (stack count) based on the ItemBox contents
static func update_slot_amount(item_box: ItemBox, amount_label: Label) -> void:
	if item_box is not ItemBox: return
	if amount_label is not Label: return

	# Hide label completely if no item is present
	if item_box.item is not Item:
		amount_label.hide()
	else:
		# Only show label if the item is stackable (not equipment)
		amount_label.visible = not item_box.item.is_equipment
		amount_label.text = str(item_box.amount)
