# Sound.gd — Global sound effect manager using pooled AudioStreamPlayers for efficient playback.
# Sounds are categorized and can be played from anywhere using Sound.play(...).

extends Node

# --- Hero Sounds ---
@export_group("Hero Sounds")
@export var swipe: AudioStream
@export var evade: AudioStream
@export var hurt: AudioStream
@export var drop: AudioStream

# --- World Sounds ---
@export_group("World Sounds")
@export var room_transition: AudioStream
@export var hit: AudioStream
@export var explosion: AudioStream

# --- UI Sounds ---
@export_group("UI Sounds")
@export var menu_move: AudioStream
@export var menu_select: AudioStream
@export var pause: AudioStream
@export var unpause: AudioStream

# Get all child AudioStreamPlayers on ready (used as a simple audio pool)
@onready var audio_stream_players = get_children()

# Plays a sound from the pool, with optional pitch and volume tweaks.
# If all players are busy, prints a warning.
func play(audio_stream: AudioStream, pitch_scale := 1.0, volume_db := 0.0) -> void:
	for audio_stream_player: AudioStreamPlayer in audio_stream_players:
		if not audio_stream_player.playing:
			audio_stream_player.pitch_scale = pitch_scale
			audio_stream_player.volume_db = volume_db
			audio_stream_player.stream = audio_stream
			audio_stream_player.play()
			return

	# All players are busy — sound won't be played.
	print("Too many sounds playing at once.")
