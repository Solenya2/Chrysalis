class_name SamiWindUpState
extends EnemyWindUpState

func enter() -> void:
	var boss := actor as SamiBoss
	timer = 0.0

	if use_flash:
		boss.flasher.flash()

	# Build the correct animation name based on phase
	var phase_anim := "phase_%s_%s" % [_phase_to_text(boss.phase), windup_animation]
	var anim_player := boss.animation_player

	# Avoid restarting the same animation
	if anim_player.has_animation(phase_anim):
		if anim_player.current_animation != phase_anim:
			anim_player.play(phase_anim)
	else:
		if anim_player.current_animation != windup_animation:
			anim_player.play(windup_animation)

func _phase_to_text(phase: int) -> String:
	match phase:
		1: return "one"
		2: return "two"
		3: return "three"
		4: return "four"
		_: return "one"
