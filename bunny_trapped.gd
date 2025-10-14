extends CharacterBody2D
class_name TrappedBunny

@export_multiline var trapped_dialog: String = "The bunny is stuck in a bear trap, whimpering in pain."
@export_multiline var free_dialog: String = "The bunny hops around happily, grateful for your help!"
@export_multiline var dead_dialog: String = "..."
@export_multiline var choice_free: String = "Free the bunny"
@export_multiline var choice_kill: String = "Kill the bunny"
@export_multiline var choice_leave: String = "Walk away"

var state: String = "trapped" # "trapped" | "freed" | "dead"
var death_timer := 0.0
@export var death_duration := 20.0
var timer_active := true
var awaiting_choice: bool = false

@onready var interaction: Interaction = $Interaction
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

	# Start with trapped animation
	if animation_player and animation_player.has_animation("trapped_idle"):
		animation_player.play("trapped_idle")

	# Listen for choice
	if Events and not Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.connect(_on_dialog_choice_made)

func _exit_tree() -> void:
	if Events and Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.disconnect(_on_dialog_choice_made)

func _process(delta: float) -> void:
	if timer_active and state == "trapped" and not awaiting_choice:
		death_timer += delta
		if death_timer >= death_duration:
			_set_dead_state()
			timer_active = false

func _on_interacted() -> void:
	# Don’t start new UI while paused or mid-choice
	if get_tree().paused:
		return
	if awaiting_choice:
		return

	match state:
		"trapped":
			_show_trapped_staged()
		"freed":
			_show_freed_line()
		"dead":
			_show_dead_line()

# ─────────────────────────────────────────────────────────
# DIALOG FLOWS
# ─────────────────────────────────────────────────────────

func _show_trapped_staged() -> void:
	# Stop death timer while the player is deciding
	timer_active = false

	# STAGED: prompt → (player skip) → choices-only
	var opts := [choice_free, choice_kill, choice_leave]
	Events.request_prompt_then_choices.emit(trapped_dialog, opts)
	awaiting_choice = true
	# Choice result handled in _on_dialog_choice_made

func _show_freed_line() -> void:
	Events.request_show_dialog.emit(free_dialog)
	# No await required; let the player close it

func _show_dead_line() -> void:
	Events.request_show_dialog.emit(dead_dialog)
	# No await required

# ─────────────────────────────────────────────────────────
# CHOICES
# ─────────────────────────────────────────────────────────

func _on_dialog_choice_made(choice_idx: int) -> void:
	if not awaiting_choice:
		return
	awaiting_choice = false

	# Small debounce so the click doesn’t close the next line
	await get_tree().process_frame

	if choice_idx == 0:
		_free_bunny()
	elif choice_idx == 1:
		_kill_bunny()
	else:
		_walk_away()

func _free_bunny() -> void:
	state = "freed"
	ReferenceStash.alignment.good_score += 1

	# Animation
	if animation_player and animation_player.has_animation("free_idle"):
		animation_player.play("free_idle")

	# Confirmation line (re-open), then wait for close
	Events.request_show_dialog.emit("You carefully free the bunny from the trap.")
	await Events.dialog_finished
	_ensure_unpaused()

func _kill_bunny() -> void:
	_set_dead_state()
	ReferenceStash.alignment.evil_score += 1

	# Optional: you had this emit; keeping it in case something listens
	Events.bat_killed.emit()

	Events.request_show_dialog.emit("You end the bunny's suffering... brutally.")
	await Events.dialog_finished
	_ensure_unpaused()

func _walk_away() -> void:
	ReferenceStash.alignment.neutral_score += 1

	Events.request_show_dialog.emit("You decide to leave the bunny to its fate.")
	await Events.dialog_finished
	_ensure_unpaused()

	# Restart the death timer only if it’s still trapped
	if state == "trapped":
		timer_active = true
		death_timer = 0.0

# ─────────────────────────────────────────────────────────
# STATE + SAFETY
# ─────────────────────────────────────────────────────────

func _set_dead_state() -> void:
	state = "dead"
	timer_active = false
	if animation_player and animation_player.has_animation("dead_idle"):
		animation_player.play("dead_idle")

func _ensure_unpaused() -> void:
	if get_tree().paused:
		Events.request_close_dialog.emit()
		await get_tree().process_frame
		if get_tree().paused:
			get_tree().paused = false
