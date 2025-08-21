extends CharacterBody2D
class_name NPCMoralitySimple

@export_multiline var good_dialog:  String = "yo punk"
@export_multiline var evil_dialog:  String = "ahhhh go away mosnter"
@export_multiline var choice_a:     String = "Ask for directions."
@export_multiline var choice_b:     String = "boo!"
@export_multiline var good_reply_a: String = "To the right du uh"
@export_multiline var good_reply_b: String = "AHH! hey that was scary!"
@export_multiline var evil_reply_a: String = "south its south go south just leave me"
@export_multiline var evil_reply_b: String = "Eek!  I’ll do whatever you say!"

var already_talked := false
@onready var interaction: Interaction = $Interaction

func _ready() -> void:
	interaction.interacted.connect(show_dialog)

func show_dialog() -> void:
							  # NPC says nothing after first convo

	var alignment := ReferenceStash.alignment
	var intro := evil_dialog if alignment.evil_score >= 3 else good_dialog
	Events.request_show_dialog.emit(intro)

	# Wait until player advances dialog (Dialogbox emits dialog_finished).
	await Events.dialog_finished

	# Offer two simple choices.
	Events.request_dialog_choices.emit([choice_a, choice_b])

	# Wait for the player's selection (returns 0 or 1).
	var choice_idx : int = await Events.dialog_choice_made

	# Choose a follow-up line based on alignment AND choice.
	var reply : String
	if alignment.evil_score >= 3:
		reply = evil_reply_a if choice_idx == 0 else evil_reply_b
	else:
		reply = good_reply_a if choice_idx == 0 else good_reply_b

	Events.request_show_dialog.emit(reply)

	already_talked = true      # prevent repeat loop
