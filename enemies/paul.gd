# Paul.gd
class_name Paul
extends Enemy

@export var start_active: bool = false   # set false in editor
@export var activation_distance: float = 0.0  # 0 = disabled (use Area2D). >0 = self-proximity wake.
var _active := false

@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D

@onready var chase_state: EnemyChaseState = (
	EnemyChaseState.new()
	.set_actor(self)
	.set_navigation_agent(navigation_agent_2d)
)
@onready var knockback_state = EnemyKnockbackState.new().set_actor(self)
@onready var fsm = FSM.new().set_state(chase_state)

func _ready() -> void:
	super()
	set_active(start_active)
	# Wake on hit (optional). Comment out if you want them to ignore hits while asleep.
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		if !_active:
			set_active(true)
		fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
		create_hit_particles(other_hitbox, load("res://effects/hit_particles.tscn"))
		stats.health -= other_hitbox.damage
	)
	knockback_state.finished.connect(fsm.change_state.bind(chase_state))
	# Keep _process on for optional distance check
	set_process(true)

func set_active(v: bool) -> void:
	_active = v
	set_physics_process(v)         # gates the FSM tick below
	if !v:
		velocity = Vector2.ZERO    # hard stop
		# If your chase state sets any target velocity elsewhere, zero it too as needed.

func _process(_dt: float) -> void:
	# Optional self-proximity wake (only if activation_distance > 0)
	if !_active and activation_distance > 0.0:
		var hero := MainInstances.hero
		if hero and global_position.distance_to(hero.global_position) <= activation_distance:
			set_active(true)

func _physics_process(delta: float) -> void:
	if !_active:
		return
	fsm.state.physics_process(delta)
