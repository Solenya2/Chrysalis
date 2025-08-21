class_name SamiPauseState
extends State

var pause_time := 1.0 : set = set_pause_time

func set_pause_time(value: float) -> SamiPauseState:
	pause_time = value
	return self

func enter() -> void:
	var enemy := actor as Enemy
	
	# Play a calm idle/breathe animation during the pause
	enemy.anim.play("idle")  # or "breathe", etc.

	await enemy.get_tree().create_timer(pause_time).timeout
	emit_signal("finished")
