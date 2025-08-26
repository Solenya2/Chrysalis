# Music.gd — Autoload singleton for background music (Godot 4.4)
# Plays single tracks or playlists, supports fade, and key-based lookup.

extends Node

# --- Config ---
const MUSIC_BUS_STRING := "Music"  # must match your Audio bus name

# --- Nodes ---
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# --- Signals ---
signal fade_completed()

# --- Track lookup (voice-friendly keys) ---
# Pre-fill with your Mozart track. Add more keys as needed.
@export var track_map: Dictionary = {
	"mozart": preload("res://muisc_and_sounds/requiem-mozart-remix-265907.mp3")
}

func _ready() -> void:
	# If needed later, init here.
	pass


# =========================
# Queries
# =========================
func is_playing_song(song: AudioStream) -> bool:
	return audio_stream_player.stream == song

func is_playing_playlist(song_playlist: AudioStreamPlaylist) -> bool:
	return audio_stream_player.stream == song_playlist


# =========================
# Core playback
# =========================
func play(song: AudioStream) -> void:
	# Sync player volume with bus (keeps behavior consistent with your original script)
	audio_stream_player.volume_db = _get_bus_volume_db()
	audio_stream_player.stream_paused = false
	audio_stream_player.stream = song
	audio_stream_player.play()

func pause_music() -> void:
	audio_stream_player.stream_paused = true

func resume_music() -> void:
	audio_stream_player.stream_paused = false

func stop() -> void:
	audio_stream_player.stop()


# =========================
# Key-based helpers
# =========================
func play_track_by_key(key: String) -> bool:
	var stream := track_map.get(key) as AudioStream
	if stream == null:
		push_warning("Track key not found: %s" % key)
		return false

	if is_playing_song(stream):
		audio_stream_player.volume_db = _get_bus_volume_db()
		if not audio_stream_player.playing:
			audio_stream_player.play()
		audio_stream_player.stream_paused = false
		return true

	# Smooth handoff from whatever is playing (fire and forget)
	fade(0.75)   # no await here
	play(stream)
	return true



# =========================
# Fades
# =========================
func fade(duration: float = 0.75) -> void:
	if not audio_stream_player.playing:
		# Nothing to fade; just emit for consistency
		fade_completed.emit()
		return

	# Fade player down to silence. (Bus is applied after player; -80 dB here is effectively silent.)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(audio_stream_player, "volume_db", -80.0, duration)
	await tween.finished
	fade_completed.emit()


# =========================
# Internals
# =========================
func _get_bus_volume_db() -> float:
	var idx := AudioServer.get_bus_index(MUSIC_BUS_STRING)
	return AudioServer.get_bus_volume_db(idx)
