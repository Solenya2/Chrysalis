# Music.gd — Handles background music playback and fading, synced to the "Music" audio bus.
# Can play a single AudioStream or an AudioStreamPlaylist. Used as an autoloaded singleton.

extends Node

# Name of the audio bus used for music (must match Audio panel setup)
const MUSIC_BUS_STRING := "Music"

# AudioStreamPlayer node used to play music tracks
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Emitted after a fade completes (e.g., for syncing transitions)
signal fade_completed()

func _ready() -> void:
	pass  # Placeholder if needed later

# Gets the current dB volume of the music bus
func _get_bus_volume_db() -> float:
	var music_bus_index := AudioServer.get_bus_index(MUSIC_BUS_STRING)
	return AudioServer.get_bus_volume_db(music_bus_index)

# Returns true if the specified AudioStream is currently playing
func is_playing_song(song: AudioStream) -> bool:
	return (audio_stream_player.stream == song)

# Returns true if the specified playlist is currently playing
func is_playing_playlist(song_playlist: AudioStreamPlaylist) -> bool:
	return (audio_stream_player.stream == song_playlist)

# Starts playing the given song, syncing volume with the music bus
func play(song: AudioStream) -> void:
	audio_stream_player.volume_db = _get_bus_volume_db()
	audio_stream_player.stream = song
	audio_stream_player.play()

# Smoothly fades out the current song over the specified duration
func fade(duration: float = 0.75) -> void:
	if audio_stream_player.playing:
		var bus_volume := _get_bus_volume_db()

		# Tween fades to silence relative to the bus volume
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(audio_stream_player, "volume_db", -80 - bus_volume, duration)

		await tween.finished
		fade_completed.emit()
