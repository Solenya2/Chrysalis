# VampireBoss.gd — Full FSM-driven enemy boss with a transformation and fireball attack loop.
# Transforms between vampire and bat forms, patrols via markers, and uses a stash system for persistence.

class_name VampireBoss
extends Enemy

# Optional explosion effect when the boss dies.
const EXPLOSION_EFFECT_SCENE := preload("res://effects/explosion_effect.tscn")

# Editor-assigned list of markers to use for movement (patrol points).
@export var target_markers: Array[Marker2D]

# Position node where fireballs spawn during attack state.
@onready var fireball_marker_2d: Marker2D = $Sprite2D/FireballMarker2D

# Used to remember if the boss was previously killed ("freed") for persistence across scenes.
@onready var stasher = Stasher.new().set_target(self)

# Individual FSM states — created and configured during _ready.
@onready var pause_state = EnemyPauseState.new().set_actor(self)

@onready var move_to_random_marker_state = (
	EnemyMoveToRandomMarkerState.new()
	.set_markers(target_markers)
	.set_actor(self)
)

@onready var transform_to_bat_state = (
	EnemyTransformState.new()
	.set_transform_animation("move")  # Assumes this animation changes sprite to bat form
	.set_actor(self)
)

@onready var transform_to_vampire_state = (
	EnemyTransformState.new()
	.set_transform_animation("idle")  # Assumes this animation reverts to vampire form
	.set_actor(self)
)

@onready var fireball_state = VampireFireballState.new().set_actor(self)

# Main finite state machine — starts paused
@onready var fsm: FSM = FSM.new().set_state(pause_state)

func _ready() -> void:
	# If the boss was already marked as dead (via stasher), remove it from the scene.
	if stasher.retrieve_property("freed"):
		queue_free()

	# State transition setup — defines the boss behavior loop.
	pause_state.finished.connect(fsm.change_state.bind(transform_to_bat_state))
	transform_to_bat_state.finished.connect(fsm.change_state.bind(move_to_random_marker_state))
	move_to_random_marker_state.finished.connect(fsm.change_state.bind(transform_to_vampire_state))
	transform_to_vampire_state.finished.connect(fsm.change_state.bind(fireball_state))
	fireball_state.finished.connect(fsm.change_state.bind(pause_state))

	# When the boss is hurt:
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		var damage = other_hitbox.damage

		# Flash effect for hit feedback
		await flasher.flash()

		# Small delay after flashing
		await get_tree().create_timer(0.1).timeout

		# Apply damage
		stats.health -= damage

		# If dead: spawn effect, stash status, play sound, and remove from scene
		if stats.is_health_gone():
			Utils.instantiate_scene_on_level(EXPLOSION_EFFECT_SCENE, global_position)
			stasher.stash_property("freed", true)
			Sound.play(Sound.explosion)
			queue_free()
	)

# Delegate logic each frame to the active FSM state
func _physics_process(delta: float) -> void:
	fsm.state.physics_process(delta)
