# BossLevel.gd — A custom Level subclass for handling a boss arena with trigger/barrier logic.
# Manages camera focus, boss activation, and persistent progress tracking.

extends Level

# Node references in the boss level scene
@onready var camera_target: RemoteTransform2D = $CameraTarget
@onready var boss_barrier: StaticBody2D = $BossBarrier
@onready var trigger: Area2D = $Trigger
@onready var vampire_boss: VampireBoss = $VampireBoss

# Stasher is used to persist whether the trigger/barrier has been cleared before.
@onready var stasher = Stasher.new().set_target(self)

func _ready() -> void:
	# If the trigger was previously used (boss defeated), remove it.
	if stasher.retrieve_property("trigger_freed"):
		trigger.queue_free()

	# Call base Level _ready() to enable Y-sorting.
	super()

	# Set the camera to focus on this level's target on load.
	Events.request_camera_target.emit.call_deferred(camera_target)

	# When the player enters the trigger area:
	trigger.body_entered.connect(func(body: Node2D):
		# Show and activate the boss barrier.
		boss_barrier.show()
		boss_barrier.set_collision_layer_value(1, true)

		# Remove the trigger so it can't re-fire.
		trigger.queue_free()

		# Mark this trigger as "used" for persistence (so it doesn't reset on reload).
		stasher.stash_property("trigger_freed", true)
	)

	# When the vampire boss is defeated (health reaches 0):
	vampire_boss.stats.no_health.connect(func():
		# Disable the boss barrier so player can exit.
		boss_barrier.hide()
		boss_barrier.set_collision_layer_value(1, false)
	)
