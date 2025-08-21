class_name SamiChargeState
extends EnemyChargeState

func enter() -> void:
	var boss := actor as SamiBoss
	_timer = 0.0

	var anim_player := boss.animation_player
	var phase_anim := "phase_%s_%s" % [_phase_to_text(boss.phase), charge_animation]

	# Play phase-specific animation only if it's different
	if anim_player.has_animation(phase_anim):
		if anim_player.current_animation != phase_anim:
			anim_player.play(phase_anim)
	elif anim_player.has_animation(charge_animation):
		if anim_player.current_animation != charge_animation:
			anim_player.play(charge_animation)

	# Enable hitbox if needed
	if enable_hitbox_during_charge:
		boss.hitbox.set_deferred("monitoring", true)

	# Apply knockback
	CharacterMover.apply_knockback(boss, _direction * charge_speed)

func _phase_to_text(phase: int) -> String:
	match phase:
		1: return "one"
		2: return "two"
		3: return "three"
		4: return "four"
		_: return "one"
