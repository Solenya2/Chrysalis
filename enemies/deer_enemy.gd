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

func _ready() -> void:
	super()

	# Listen for mutation trigger from cutscene
	Events.infected_deer_mutate.connect(start_mutation_cutscene)

	# Stay in idle pose until mutation
	if animation_player.has_animation("idle"):
		animation_player.play("idle")

	# Do not activate FSM yet — wait until mutated
	print("🦌 Deer ready. Waiting for mutation...")

	# Connect damage
	hurtbox.hurt.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	if not mutated or fsm == null or fsm.state == null:
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

# --- Damage Handling ---
func _on_hurtbox_hit(other_hitbox: Hitbox) -> void:
	stats.health -= other_hitbox.damage
	create_hit_particles(other_hitbox, preload("res://effects/hit_particles.tscn"))
 
