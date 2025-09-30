class_name HeroClapState
extends State

func enter() -> void:
	var hero = actor as Hero
	print("Entering clap state")
	hero.animation_player.play("clap")
	await hero.animation_player.animation_finished
	finished.emit()

func physics_process(delta: float) -> void:
	# Do nothing during clap - player stays in place
	var hero: = actor as Hero
	CharacterMover.decelerate(hero, hero.movement_stats, delta)
	CharacterMover.move(hero)

func exit() -> void:
	print("Exiting clap state")
