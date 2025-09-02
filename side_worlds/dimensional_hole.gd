extends StaticBody2D

@onready var interaction: Interaction = $Interaction
@onready var anim: AnimationPlayer = $AnimationPlayer

var _busy := false
var _awaiting_choice := false

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")
	
	# Connect to the choice made signal
	Events.dialog_choice_made.connect(_on_dialog_choice_made)

func _exit_tree() -> void:
	# Disconnect to prevent errors
	if Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.disconnect(_on_dialog_choice_made)

func _on_interacted() -> void:
	if _busy:
		return
	_busy = true
	_awaiting_choice = true

	# Ask and show choices without waiting for dialog to finish
	Events.request_show_dialog.emit("Wanna jump in?")
	# Don't wait for dialog_finished - show choices immediately
	Events.request_dialog_choices.emit(["Yes", "No"])
	
	# Wait for the choice to be made
	while _awaiting_choice:
		await get_tree().process_frame

func _on_dialog_choice_made(choice_idx: int) -> void:
	if not _awaiting_choice:
		return
		
	_awaiting_choice = false
	
	if choice_idx == 0:  # Yes
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
	else:  # No
		_busy = false  # allow trying again if they picked "No"
