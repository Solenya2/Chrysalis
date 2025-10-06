extends CharacterBody2D
class_name TrappedBunny

@export_multiline var trapped_dialog: String = "The bunny is stuck in a bear trap, whimpering in pain."
@export_multiline var free_dialog: String = "The bunny hops around happily, grateful for your help!"
@export_multiline var dead_dialog: String = "..."
@export_multiline var choice_free: String = "Free the bunny"
@export_multiline var choice_kill: String = "Kill the bunny"

var state = "trapped" # trapped, freed, dead
var already_interacted = false
var death_timer := 0.0
var death_duration := 20.0
var timer_active := true
var awaiting_choice: bool = false

@onready var interaction: Interaction = $Interaction
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	
	# Start with trapped animation
	if animation_player.has_animation("trapped_idle"):
		animation_player.play("trapped_idle")
	
	# Listen for global dialog choice result
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
	if awaiting_choice:
		return
		
	match state:
		"trapped":
			show_trapped_dialog()
		"freed":
			show_freed_dialog()
		"dead":
			show_dead_dialog()

func show_trapped_dialog() -> void:
	# Stop the timer once player interacts
	timer_active = false
	
	# Show the trapped dialog and immediately show choices (no waiting)
	Events.request_show_dialog.emit(trapped_dialog)
	Events.request_dialog_choices.emit([choice_free, choice_kill, "Walk away"])
	awaiting_choice = true

func show_freed_dialog() -> void:
	Events.request_show_dialog.emit(free_dialog)
	# No need to wait for this one either

func show_dead_dialog() -> void:
	Events.request_show_dialog.emit(dead_dialog)
	# No need to wait for this one

func _on_dialog_choice_made(choice_idx: int) -> void:
	if not awaiting_choice:
		return
		
	awaiting_choice = false
	
	match choice_idx:
		0: # Free the bunny
			free_bunny()
		1: # Kill the bunny
			kill_bunny()
		2: # Walk away
			walk_away()

func free_bunny() -> void:
	state = "freed"
	ReferenceStash.alignment.good_score += 1
	
	# Change to free idle animation
	if animation_player.has_animation("free_idle"):
		animation_player.play("free_idle")
	
	Events.request_show_dialog.emit("You carefully free the bunny from the trap.")

func kill_bunny() -> void:
	_set_dead_state()
	ReferenceStash.alignment.evil_score += 1
	Events.bat_killed.emit()  # Optional, can rename later if needed
	Events.request_show_dialog.emit("You end the bunny's suffering... brutally.")

func walk_away() -> void:
	ReferenceStash.alignment.neutral_score += 1
	Events.request_show_dialog.emit("You decide to leave the bunny to its fate.")
	# Restart the death timer since player walked away
	if state == "trapped":
		timer_active = true
		death_timer = 0.0  # Reset timer

func _set_dead_state() -> void:
	state = "dead"
	timer_active = false
	
	# Change to dead idle animation
	if animation_player.has_animation("dead_idle"):
		animation_player.play("dead_idle")
