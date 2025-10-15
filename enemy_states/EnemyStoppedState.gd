# EnemyStoppedState.gd - State for when enemy is stopped by voice command

class_name EnemyStoppedState
extends State

# We don't need to redeclare actor or set_actor since they're inherited from State

func enter() -> void:
	if actor and actor is Enemy:
		var enemy_actor: Enemy = actor as Enemy
		enemy_actor.velocity = Vector2.ZERO
		# Play stopped animation if available
		if enemy_actor.animation_player and enemy_actor.animation_player.has_animation("stopped"):
			enemy_actor.animation_player.play("stopped")
		elif enemy_actor.animation_player and enemy_actor.animation_player.has_animation("idle"):
			enemy_actor.animation_player.play("idle")
		print("[EnemyStoppedState] Entered stopped state")

func physics_process(delta: float) -> void:
	if actor and actor is Enemy:
		var enemy_actor: Enemy = actor as Enemy
		# Stay completely still
		enemy_actor.velocity = Vector2.ZERO
		enemy_actor.move_and_slide()

func exit() -> void:
	if actor and actor is Enemy:
		var enemy_actor: Enemy = actor as Enemy
		# Resume normal animation when leaving stopped state
		if enemy_actor.animation_player and enemy_actor.animation_player.has_animation("move"):
			enemy_actor.animation_player.play("move")
	print("[EnemyStoppedState] Exited stopped state")
