class_name DeerEnemy
extends Enemy

# --- Nodes ---
@onready var navigation_agent_offset: Node2D = $NavigationAgentOffset2D
@onready var navigation_agent: NavigationAgent2D = navigation_agent_offset.get_node("NavigationAgent2D")

# --- FSM + States ---
var fsm: FSM
var chase_state: EnemyChaseState
var windup_state: EnemyWindUpState
var charge_state: EnemyChargeState
var knockback_state: EnemyKnockbackState

# --- Charge Timing ---
var time_since_last_charge := 0.0
@export var charge_cooldown := 2.5
@export var min_distance_to_charge := 96.0

# --- Mutation State ---
var mutated := false

# --- Near-Death Event Variables ---
var near_death_threshold := 0.3  # 30% health remaining
var near_death_triggered := false
var original_movement_stats: MovementStats
var is_friendly := false
var awaiting_choice := false

func _ready() -> void:
	super()
	
	# Store original movement stats for restoration
	original_movement_stats = movement_stats.duplicate()
	
	# Listen for mutation trigger from cutscene
	Events.infected_deer_mutate.connect(start_mutation_cutscene)
	
	# Listen for dialog choice events
	Events.dialog_choice_made.connect(_on_dialog_choice_made)
	
	# Stay in idle pose until mutation
	if animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Connect damage like the bat does
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		# Don't take damage if already friendly or dead
		if is_friendly or stats.is_health_gone():
			return
		
		# Apply knockback and damage like the bat
		if fsm and fsm.state != knockback_state:
			fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
		
		create_hit_particles(other_hitbox, preload("res://effects/hit_particles.tscn"))
		stats.health -= other_hitbox.damage
		
		# Check if near death after taking damage
		_check_near_death()
		
		# Check if the deer died from this hit
		if stats.is_health_gone():
			# Emit the bat_killed signal to update alignment
			Events.bat_killed.emit()
	)
	
	# Also check health on ready in case deer is already wounded when loaded
	_check_near_death()
	
	print("🦌 Deer ready. Waiting for mutation...")

func _exit_tree() -> void:
	# Disconnect from events when deer is removed
	if Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.disconnect(_on_dialog_choice_made)

func _physics_process(delta: float) -> void:
	if not mutated or fsm == null or fsm.state == null or is_friendly:
		return

	time_since_last_charge += delta

	# Basic chase behavior
	if fsm.state == chase_state:
		var hero := MainInstances.hero
		if hero:
			var dist := global_position.distance_to(hero.global_position)
			var direction := global_position.direction_to(hero.global_position)

			# Flip sprite
			if direction.x != 0:
				sprite_2d.scale.x = sign(direction.x)

			# Move animation
			if animation_player.has_animation("move"):
				animation_player.play("move")

			# Charge trigger
			if time_since_last_charge >= charge_cooldown and dist >= min_distance_to_charge:
				time_since_last_charge = 0.0
				fsm.change_state(windup_state)

	# FSM logic
	if fsm and fsm.state:
		fsm.state.physics_process(delta)

# --- FSM Setup ---
func _init_fsm() -> void:
	fsm = FSM.new()

	chase_state = EnemyChaseState.new().set_actor(self).set_navigation_agent(navigation_agent)
	knockback_state = EnemyKnockbackState.new().set_actor(self)
	charge_state = EnemyChargeState.new().set_actor(self)
	windup_state = EnemyWindUpState.new().set_actor(self)

	# Transitions
	windup_state.set_on_finish(_on_windup_finished)
	knockback_state.finished.connect(_on_knockback_finished)
	charge_state.finished.connect(_on_charge_finished)

	fsm.set_state(chase_state)

# --- Cutscene Triggered Mutation ---
func start_mutation_cutscene() -> void:
	print("🐛 Mutation started")
	mutated = true
	fsm = null  # Ensure old state is cleared if exists

	# Play mutation animation
	if animation_player.has_animation("mutating"):
		animation_player.play("mutating")
		await animation_player.animation_finished

	# Now begin behavior
	_init_fsm()
	
	# Connect knockback finished like the bat does
	knockback_state.finished.connect(_on_knockback_finished)
	
	print("🧠 FSM started — deer is now aggressive")

# --- FSM Transitions ---
func _on_charge_finished() -> void:
	fsm.change_state(chase_state)

func _on_windup_finished() -> void:
	var hero := MainInstances.hero as Hero
	if hero:
		var dir = global_position.direction_to(hero.global_position)
		charge_state.set_direction(dir)
		fsm.change_state(charge_state)

func _on_knockback_finished() -> void:
	fsm.change_state(chase_state)

# --- Near-Death Event Handling ---
func _check_near_death() -> void:
	# Only trigger once and only if mutated and not already friendly
	if not mutated or near_death_triggered or is_friendly:
		return
	
	# Check if health is below threshold
	if stats.health <= stats.max_health * near_death_threshold:
		near_death_triggered = true
		_trigger_near_death_event()

func _trigger_near_death_event() -> void:
	print("🦌 Deer is near death - triggering event")
	
	# Slow down the deer dramatically
	movement_stats.max_speed = original_movement_stats.max_speed * 0.2
	movement_stats.acceleration = original_movement_stats.acceleration * 0.3
	
	# Stop any aggressive behavior
	if fsm and fsm.state != knockback_state:
		fsm.change_state(chase_state)
	
	# Play wounded animation if available
	if animation_player.has_animation("wounded"):
		animation_player.play("wounded")
	elif animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Start the moral choice process
	_start_moral_choice_process()

func _start_moral_choice_process() -> void:
	# Pause gameplay
	Events.cutscene_started.emit()
	
	# Focus camera on the deer
	var deer_focus := get_node_or_null("RemoteTransform2D")
	if deer_focus is RemoteTransform2D:
		Events.request_camera_target.emit(deer_focus)
	
	# Show dialog asking the moral question
	Events.request_show_dialog.emit("[center]The deer is wounded and helpless...\nWhat will you do?")
	
	# Show choice options using your existing system
	Events.request_dialog_choices.emit(["Spare the deer", "Finish it"])
	
	# Set flag to indicate we're waiting for a choice
	awaiting_choice = true

# Handle the dialog choice result
func _on_dialog_choice_made(choice_idx: int) -> void:
	if not awaiting_choice:
		return
		
	awaiting_choice = false
	
	# Handle the choice (0 = first option, 1 = second option)
	handle_moral_choice(choice_idx == 0)
	
	# Return camera to player
	if MainInstances.hero and is_instance_valid(MainInstances.hero):
		Events.request_camera_target.emit(MainInstances.hero.remote_transform_2d)
	
	# Resume gameplay
	Events.cutscene_finished.emit()

# Handle the moral choice result
func handle_moral_choice(spare: bool) -> void:
	if spare:
		_spare_deer()
	else:
		# Player chose to kill - let the normal damage system handle it
		# Just ensure the deer can be killed with one more hit
		stats.health = 1  # Set to 1 so one hit will kill it
		# The normal damage system will handle the rest

func _spare_deer() -> void:
	print("🦌 Deer spared")
	is_friendly = true
	
	# Heal the deer
	stats.health = stats.max_health
	
	# Restore movement stats
	movement_stats = original_movement_stats.duplicate()
	
	# Stop FSM
	if fsm:
		fsm.set_state(null)
	
	# Play thankful animation if available
	if animation_player.has_animation("thankful"):
		animation_player.play("thankful")
	elif animation_player.has_animation("idle"):
		animation_player.play("idle")
	
	# Change to non-enemy group
	remove_from_group("enemies")
	add_to_group("friendlies")
	
	# Emit alignment event for sparing (good alignment)
	Events.alignment_changed.emit("good", 5)
