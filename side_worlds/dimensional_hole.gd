extends StaticBody2D

@onready var interaction: Interaction = $Interaction
@onready var anim: AnimationPlayer = $AnimationPlayer

var _busy := false

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")

func _on_interacted() -> void:
	if _busy:
		return
	_busy = true

	# Ask
	Events.request_show_dialog.emit("Wanna jump in?")
	await Events.dialog_finished

	# Choices
	Events.request_dialog_choices.emit(["Yes", "No"])
	var choice_idx: int = await Events.dialog_choice_made

	if choice_idx == 0:
		# optional flair
		if anim and anim.has_animation("suck_in"):
			anim.play("suck_in")
			# If you want it to fully finish before the fade, uncomment:
			# await anim.animation_finished

		FadeLayer.fade_to_black(1.0)
		await get_tree().create_timer(1.1).timeout

		Utils.load_level("res://side_worlds/waiting_room.tscn")

		# Optional: if you don't fade-in inside waiting_room, do it here:
		# FadeLayer.fade_from_black(1.0)

		# One-shot: prevent re-use
		if is_instance_valid(interaction):
			interaction.queue_free()
	else:
		_busy = false  # allow trying again if they picked "No"
