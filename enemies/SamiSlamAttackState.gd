class_name SamiSlamAttackState
extends State

@export var damage := 1

var has_attacked := false
var expected_animation := ""

func enter():
	has_attacked = false
	expected_animation = "phase_%s_swipe" % _phase_to_text()
	actor.velocity = Vector2.ZERO

	# Play swipe animation
	if actor.anim.current_animation != expected_animation:
		actor.anim.play(expected_animation)
		actor.anim.seek(0.0, true)

	print("Entered SamiSlamAttackState (Swipe), playing:", expected_animation)

func physics_process(delta: float):
	var hero := MainInstances.hero
	if not hero:
		return

	# Movement logic — chase the hero while swiping
	var dir := actor.global_position.direction_to(hero.global_position)

	if dir.x != 0:
		actor.sprite_2d.scale.x = sign(dir.x)

	# Accelerate and move (shared logic)
	CharacterMover.accelerate_in_direction(actor, dir, actor.movement_stats, delta)
	CharacterMover.move(actor)

# Animation end = finished
func on_slam_finished(name: String):
	if name == expected_animation:
		print("Swipe finished.")
		emit_signal("finished")

func _phase_to_text() -> String:
	match actor.phase:
		1: return "one"
		2: return "two"
		3: return "three"
		4: return "four"
		_: return "one"
