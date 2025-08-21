extends CanvasLayer

@onready var fade: ColorRect = $ScreenFade

func _ready():
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.visible = false

func fade_to_black(duration := 1.0) -> void:
	fade.visible = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, duration)

func fade_from_black(duration := 1.0) -> void:
	fade.visible = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): fade.visible = false)
