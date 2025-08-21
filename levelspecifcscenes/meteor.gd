extends StaticBody2D

@onready var interaction: Interaction = $Interaction
@onready var anim: AnimationPlayer = $AnimationPlayer

var _has_been_triggered := false

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	anim.play("Idle")

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

	# Step 4: Load the corrupted world level
	Utils.load_level("res://corupted_levels/corupted_outside.tscn")

	# Step 5: Fade back in
	FadeLayer.fade_from_black(2.0)
	await get_tree().create_timer(2.0).timeout
	anim.play("Idle")

	# Step 6: Wake up dialog
	Events.request_show_dialog.emit("urgh my head..")
