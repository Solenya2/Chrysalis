extends CharacterBody2D
class_name GuitaristNPC

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Connect to the guitar song signals
	Events.guitar_song_started.connect(_on_guitar_song_started)
	Events.guitar_song_ended.connect(_on_guitar_song_ended)

func _on_guitar_song_started() -> void:
	# Start guitar animation when song starts
	if animation_player:
		animation_player.play("guitar")

func _on_guitar_song_ended() -> void:
	# Stop guitar animation when song ends
	if animation_player:
		animation_player.stop()
