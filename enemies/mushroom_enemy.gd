class_name MushroomEnemy
extends Enemy

@onready var shoot_marker: Marker2D = $Sprite2D/ShootMarker2D

@onready var shoot_state = EnemyShootProjectileState.new().set_actor(self)
@onready var idle_state = EnemyPauseState.new().set_actor(self)
@onready var knockback_state = EnemyKnockbackState.new().set_actor(self)

@onready var fsm = FSM.new()

func _ready() -> void:
	# Setup shoot state
	shoot_state.projectile_scene = preload("res://enemies/spore_projectile.tscn")
	shoot_state.shoot_animation = "spit"
	shoot_state.shoot_marker_path = shoot_marker.get_path()
	shoot_state.fire_delay = 0.2
	shoot_state.projectile_speed = 100.0

	# Idle (pause) state
	idle_state.set_pause_time(1.5)

	# Connect FSM state transitions
	idle_state.finished.connect(fsm.change_state.bind(shoot_state))
	shoot_state.finished.connect(fsm.change_state.bind(idle_state))

	# Start FSM with idle
	fsm.set_state(idle_state)

	# Damage behavior
	hurtbox.hurt.connect(func(hitbox: Hitbox) -> void:
		stats.health -= hitbox.damage
		create_hit_particles(hitbox, preload("res://effects/hit_particles.tscn"))

		# Check if dead
		if stats.is_health_gone():
			die()
	)

func die() -> void:
	Utils.instantiate_scene_on_level(preload("res://effects/hit_particles.tscn"), global_position)
	queue_free()

func _physics_process(delta: float) -> void:
	fsm.state.physics_process(delta)
