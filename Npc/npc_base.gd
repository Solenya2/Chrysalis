extends CharacterBody2D
class_name NPCMoralitySimple

# Opening lines
@export_multiline var good_dialog: String = "yo punk"
@export_multiline var evil_dialog: String = "ahhhh go away monster"

# First player choice
@export_multiline var choice_a: String = "Ask for directions."
@export_multiline var choice_b: String = "boo!"

# NPC reply to first choice
@export_multiline var good_reply_a: String = "To the right, duh."
@export_multiline var good_reply_b: String = "AHH! hey that was scary!"
@export_multiline var evil_reply_a: String = "South. It's south—just leave me."
@export_multiline var evil_reply_b: String = "Eek! I’ll do whatever you say!"

# Final player choice (shown under reply1, no extra prompt)
@export_multiline var choice2_a: String = "Thanks. I’ll go now."
@export_multiline var choice2_b: String = "Better do as I say."

# NPC final reply
@export_multiline var good_final_a: String = "Good. Safe travels."
@export_multiline var good_final_b: String = "Okay… okay! Please don’t scare me again."
@export_multiline var evil_final_a: String = "…Fine. Just go."
@export_multiline var evil_final_b: String = "Yes—whatever you want!"

# Post-conversation lines
@export_multiline var post_good: String = "I already told you everything."
@export_multiline var post_evil: String = "I said go away. We're done."

@onready var interaction: Interaction = $Interaction

var _running: bool = false
var _completed: bool = false

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	# Avoid double-trigger on the same input that closed the dialog
	if get_tree().paused:
		return
	if _running:
		return

	if _completed:
		var a: AlignmentData = ReferenceStash.alignment
		var post_line := post_good
		if a.evil_score >= 3:
			post_line = post_evil
		Events.request_show_dialog.emit(post_line)
		return

	_run_conversation_once()

func _run_conversation_once() -> void:
	_running = true

	# Determine current tone from alignment (evil if >=3)
	var a: AlignmentData = ReferenceStash.alignment
	var is_evil := a.evil_score >= 3

	# 1) Opening line
	var opening := good_dialog
	if is_evil:
		opening = evil_dialog
	Events.request_show_dialog.emit(opening)

	# First choices while dialog is OPEN
	Events.request_dialog_choices.emit([choice_a, choice_b])

	# Wait for first pick (DialogBox closes itself after pick)
	var first_choice_index: int = await Events.dialog_choice_made
	await get_tree().process_frame  # small debounce to prevent click-through

	# Apply alignment delta for first choice
	if first_choice_index == 0:
		a.good_score += 1
	else:
		a.evil_score += 1

	# Recompute tone after the change
	is_evil = a.evil_score >= 3

	# 2) NPC reply to first pick (RE-OPEN)
	var reply1 := ""
	if is_evil:
		if first_choice_index == 0:
			reply1 = evil_reply_a
		else:
			reply1 = evil_reply_b
	else:
		if first_choice_index == 0:
			reply1 = good_reply_a
		else:
			reply1 = good_reply_b
	Events.request_show_dialog.emit(reply1)

	# 3) Final player choice (shown under reply1)
	Events.request_dialog_choices.emit([choice2_a, choice2_b])

	var second_choice_index: int = await Events.dialog_choice_made
	await get_tree().process_frame  # debounce

	# Apply alignment delta for second choice
	if second_choice_index == 0:
		a.good_score += 1
	else:
		a.evil_score += 1

	# Recompute tone again
	is_evil = a.evil_score >= 3

	# 4) Final NPC reply (RE-OPEN), then wait for close
	var reply2 := ""
	if is_evil:
		if second_choice_index == 0:
			reply2 = evil_final_a
		else:
			reply2 = evil_final_b
	else:
		if second_choice_index == 0:
			reply2 = good_final_a
		else:
			reply2 = good_final_b

	Events.request_show_dialog.emit(reply2)

	# Let the player close the final line
	await Events.dialog_finished

	# --- Safety: guarantee the tree is unpaused, even if something swallowed the close ---
	if get_tree().paused:
		# Ask the DialogBox to close (it will also emit dialog_finished + unpause)
		Events.request_close_dialog.emit()
		await get_tree().process_frame
		# Absolute fallback if some other UI didn't honor the close:
		if get_tree().paused:
			get_tree().paused = false
	# --- end safety ---

	_completed = true
	_running = false
