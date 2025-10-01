extends StaticBody2D

@onready var interaction: Interaction = $Interaction
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D

var _has_been_triggered := false
@onready var stasher := Stasher.new().set_target(self)

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	anim.play("Idle")
	if stasher.retrieve_property("collected"):
		set_collected()
		interaction.interacted.connect(collect_sword)

func _on_interacted() -> void:
	if _has_been_triggered:
		return

	_has_been_triggered = true
	interaction.queue_free()

	# Step 1: Show dialog
	Events.request_show_dialog.emit("There's something crawling inside... wha—")
	Events.dialog_finished.connect(_play_animation)

func _play_animation() -> void:
	Events.dialog_finished.disconnect(_play_animation)

	# Step 2: Parasite jumps
	anim.play("Parasite_jump")
	await anim.animation_finished

	# Step 3: Fade to black
	FadeLayer.fade_to_black(2.0)
	await get_tree().create_timer(2.5).timeout

	# Store reference to tree before scene change
	var scene_tree = get_tree()
	
	# Make this node persist across scene changes
	if get_parent() and scene_tree and scene_tree.root:
		get_parent().remove_child(self)
		scene_tree.root.add_child(self)
	
	# Step 4: Load the corrupted world level
	Utils.load_level("res://levels/metor_crash_site.tscn")
	
	# Wait a frame for the new scene to load
	await get_tree().process_frame
	
	# Step 5: Fade back in
	FadeLayer.fade_from_black(2.0)
	await get_tree().create_timer(2.0).timeout
	
	# Step 6: Wake up dialog
	Events.request_show_dialog.emit("urgh my head..")
	await Events.dialog_finished
	
	# Step 7: Start the cutscene
	Events.start_cutscene_one.emit()
	
	# Step 8: Clean up - remove this persistent node
	queue_free()

func collect_sword() -> void:
	var sword := load("res://items/sword_item.tres")
	var inventory := ReferenceStash.inventory as Inventory

	# Add the sword to inventory
	inventory.add_item(sword)
	var sword_index := inventory.get_item_index(sword)

	# If something went wrong, abort
	if sword_index == -1: 
		return

	# Mark this interaction as completed
	stasher.stash_property("collected", true)
	set_collected()

	# Show dialog with item name
	Events.request_show_dialog.emit("Mgh my arm")

func set_collected() -> void:
	# Visually mark sword as collected (e.g. switch to empty pedestal sprite)
	sprite_2d.frame = 0
	# Disable further interaction
	interaction.queue_free()
