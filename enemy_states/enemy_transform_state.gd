# EnemyTransformState.gd — FSM state that handles transformation sequences (e.g., bat → vampire).
# Plays smoke VFX, scales the sprite, triggers an animation, then finishes after it's done.

class_name EnemyTransformState
extends State

# Optional smoke/poof effect to spawn at transformation location.
const SMOKE_EFFECT_SCENE := preload("res://effects/smoke_effect.tscn")

# The name of the transformation animation to play (must exist in AnimationPlayer).
var transform_animation = "" : set = set_transform_animation

# Setter for chaining — lets you fluently assign the animation to play.
func set_transform_animation(value: String) -> EnemyTransformState:
	transform_animation = value
	return self

func enter() -> void:
	var enemy := actor as Enemy

	# Spawn a smoke effect where the enemy is.
	Utils.instantiate_scene_on_level(SMOKE_EFFECT_SCENE, enemy.global_position)

	# Tween: shrink enemy to 60% size (scale down) with exponential easing.
	var tween := enemy.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(enemy.sprite_2d, "scale", Vector2(0.6, 0.6), 0.25).from_current()
	await tween.finished

	# Play the transformation animation (e.g., bat-to-vampire sprite change).
	enemy.animation_player.play(transform_animation)

	# Tween: scale back up to full size (bounce back effect).
	tween = enemy.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(enemy.sprite_2d, "scale", Vector2.ONE, 0.25).from_current()
	await tween.finished

	# Transformation complete — move to next state.
	finished.emit()
