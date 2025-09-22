extends State
class_name BlimboDirectionalAttackState

var anim: AnimationPlayer
var sprite: Sprite2D
var _dir: Vector2 = Vector2.RIGHT

# Safety: auto-finish if the animation never ends (loop/misnamed)
var max_attack_time: float = 1.2

var _listening := false
var _timeout_timer: SceneTreeTimer
var _active := false

func choose_direction_from(from: Vector2, to: Vector2) -> void:
	_dir = (from.direction_to(to)).normalized()

func enter() -> void:
	_active = true
	_listening = false
	var played := false

	# Decide which attack anim to play
	var ax := absf(_dir.x)
	var ay := absf(_dir.y)

	if ay >= ax:
		if _dir.y < 0.0:
			if anim and anim.has_animation("attack_up"):
				anim.play("attack_up")
				played = true
		else:
			if anim and anim.has_animation("attack_down"):
				anim.play("attack_down")
				played = true
	else:
		if sprite:
			sprite.flip_h = (_dir.x < 0.0)
		if anim and anim.has_animation("attack_side"):
			anim.play("attack_side")
			played = true

	# If we didn’t find a valid clip, exit immediately
	if not played:
		_finish()
		return

	# Listen for end of the attack_* clip
	if anim and not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
		_listening = true

	# Timer fallback via the ACTOR’s tree (states are RefCounted)
	if actor and actor.get_tree():
		_timeout_timer = actor.get_tree().create_timer(max_attack_time)
		_timeout_timer.timeout.connect(_finish)

func physics_process(_d: float) -> void:
	pass

func _on_anim_finished(name: StringName) -> void:
	if not _active:
		return
	if String(name).begins_with("attack_"):
		_finish()

func _finish() -> void:
	if not _active:
		return
	_active = false

	if _listening and anim and anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.disconnect(_on_anim_finished)
	_listening = false

	# Stop the timeout from calling us later
	if _timeout_timer and _timeout_timer.timeout.is_connected(_finish):
		_timeout_timer.timeout.disconnect(_finish)
	_timeout_timer = null

	finished.emit()

func exit() -> void:
	_active = false
	if _listening and anim and anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.disconnect(_on_anim_finished)
	_listening = false
	if _timeout_timer and _timeout_timer.timeout.is_connected(_finish):
		_timeout_timer.timeout.disconnect(_finish)
	_timeout_timer = null
