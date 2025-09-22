extends State
class_name BlimboDormantIdleState

func enter() -> void:
	var boss := actor as Enemy
	if boss:
		boss.velocity = Vector2.ZERO

	var spr := (actor as Node).get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		spr.top_level = false
		spr.flip_h = false
		spr.frame = 0

	var ap := (actor as Node).get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap:
		if ap.has_animation("dormant_idle"):
			if ap.current_animation != "dormant_idle":
				ap.play("dormant_idle")
			else:
				# optional: snap to the first frame of idle
				ap.seek(0.0, true)
		elif ap.is_playing():
			ap.stop()

func physics_process(_d: float) -> void:
	# nothing; boss sits still until first hit triggers the cutscene
	pass

func exit() -> void:
	pass
