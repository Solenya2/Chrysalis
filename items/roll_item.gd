# RollItem.gd — Temporary or prototype item used to define roll behavior through the inventory system.
# May be removed later in favor of hardcoded or equipment-based movement logic.

class_name RollItem
extends Item

# Defines which animation to play when rolling — currently always "roll".
# NOTE: Using @export_enum makes it easier to expand with multiple roll styles if needed later.
@export_enum("roll") var animation: String = "roll"
