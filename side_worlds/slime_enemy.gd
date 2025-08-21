# SlimeEnemy.gd
class_name SlimeEnemy
extends Enemy

@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D

var hop_state: SlimeHopState
var knockback_state: EnemyKnockbackState
var fsm: FSM

func _ready() -> void:
	super()

	# --- States ---
	hop_state = SlimeHopState.new()
	hop_state.set_actor(self)
	hop_state.set_navigation_agent(navigation_agent_2d)

	knockback_state = EnemyKnockbackState.new()
	knockback_state.set_actor(self)

	fsm = FSM.new()
	fsm.set_state(hop_state)

	# --- Damage / hit reaction ---
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
		create_hit_particles(other_hitbox, load("res://effects/hit_particles.tscn"))
		stats.health -= other_hitbox.damage
	)

	# Return to hopping after knockback
	knockback_state.finished.connect(fsm.change_state.bind(hop_state))

func _physics_process(delta: float) -> void:
	fsm.state.physics_process(delta)
