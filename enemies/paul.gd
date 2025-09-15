# BatEnemy.gd — A flying enemy that chases the player using navigation and reacts to damage via FSM states.
# Uses EnemyChaseState and EnemyKnockbackState to control behavior via FSM.

class_name Paul
extends Enemy

# Cached reference to the NavigationAgent2D used for pathfinding toward the target.
@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D

# Chase state — follows the player using pathfinding.
# Actor and navigation agent are assigned immediately.
@onready var chase_state: EnemyChaseState = (
	EnemyChaseState.new()
	.set_actor(self)
	.set_navigation_agent(navigation_agent_2d)
)

# Knockback state — triggers on hit, with actor pre-assigned.
@onready var knockback_state = EnemyKnockbackState.new().set_actor(self)

# FSM controls the current behavior state of the bat.
# Starts in chase mode by default.
@onready var fsm = FSM.new().set_state(chase_state)

func _ready() -> void:
	super()  # Calls Enemy._ready(), which sets up flasher, sounds, etc.

	# When the bat is hurt, switch to knockback state, flash, play particles, and apply damage.
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))  # ← Apply knockback
		create_hit_particles(other_hitbox, load("res://effects/hit_particles.tscn"))  # ← VFX
		stats.health -= other_hitbox.damage  # ← Apply damage
	)

	# Once knockback finishes (stops moving), return to chasing.
	knockback_state.finished.connect(fsm.change_state.bind(chase_state))

func _physics_process(delta: float) -> void:
	# Delegate physics logic to the active FSM state.
	fsm.state.physics_process(delta)
