class_name ShopKeeper
extends CharacterBody2D
@export var greeting: String = "want some of the good stuff? "
@export var shop_items: Array[ShopItem]

@onready var interaction: Interaction = $Interaction

func _ready() -> void:
	interaction.interacted.connect(open_shop)

func open_shop() -> void:
	Events.request_show_dialog.emit(greeting)
	await Events.dialog_finished
	Events.request_open_shop.emit(shop_items)
