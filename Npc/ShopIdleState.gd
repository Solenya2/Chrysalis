extends State
class_name ShopIdleState

func enter() -> void:
	var e := actor         # Node2D from your base State
	if e:
		# Stop movement
		var enemy := e as Enemy
		if enemy:
			enemy.velocity = Vector2.ZERO

		# Snap visuals to idle
		var spr: Sprite2D = e.get_node_or_null("Sprite2D")
		if spr:
			# Only meaningful if hframes/vframes > 1 (Sprite2D spritesheet)
			spr.frame = 0

		var ap: AnimationPlayer = e.get_node_or_null("AnimationPlayer")
		if ap:
			if ap.has_animation("idle"):
				ap.play("idle")
			else:
				# No idle anim? Make sure nothing’s playing that could set frame=1
				if ap.is_playing():
					ap.stop()

func physics_process(_delta: float) -> void:
	pass

func exit() -> void:
	pass
