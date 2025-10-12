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

# Final player choice (buttons-only under reply1)
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
	# Don’t start if UI is paused or we’re already running
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

	var a: AlignmentData = ReferenceStash.alignment
	var is_evil := a.evil_score >= 3

	# 1) Opening line — staged (prompt -> skip -> buttons)
	var opening := good_dialog
	if is_evil:
		opening = evil_dialog
	Events.request_prompt_then_choices.emit(opening, [choice_a, choice_b])

	# Player picks A/B; DialogBox closes itself
	var first_choice_index: int = await Events.dialog_choice_made
	await get_tree().process_frame  # debounce to avoid click-through

	# Update alignment from first pick
	if first_choice_index == 0:
		a.good_score += 1
	else:
		a.evil_score += 1
	is_evil = a.evil_score >= 3

	# 2) NPC reply to first pick (re-open)
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

	# >>> IMPORTANT <<< 
	# Wait for the player to close the reply (so their skip is fully consumed)
	await Events.dialog_finished
	# Small extra beat to avoid input bleed into the next open
	await get_tree().create_timer(0.06).timeout

	# 3) Final player choice — buttons-only (no extra skip, no race)
	# Re-open with empty text so only the buttons show.
	Events.request_show_dialog.emit("")                 # opens panel, no text
	# Wait one frame so DialogBox is visible before attaching buttons
	await get_tree().process_frame
	Events.request_dialog_choices.emit([choice2_a, choice2_b])

	var second_choice_index: int = await Events.dialog_choice_made
	await get_tree().process_frame  # debounce

	# Update alignment from second pick
	if second_choice_index == 0:
		a.good_score += 1
	else:
		a.evil_score += 1
	is_evil = a.evil_score >= 3

	# 4) Final NPC reply (re-open), then wait for close
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
	await Events.dialog_finished

	# Safety: guarantee unpause
	if get_tree().paused:
		Events.request_close_dialog.emit()
		await get_tree().process_frame
		if get_tree().paused:
			get_tree().paused = false

	_completed = true
	_running = false
