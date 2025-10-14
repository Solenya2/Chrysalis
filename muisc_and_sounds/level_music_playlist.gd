# LevelMusicPlaylist.gd — Ensures a specific AudioStreamPlaylist plays for the current level.
# Fades out the current music (if different), then starts this level's playlist.

class_name LevelMusicPlaylist
extends Node

# Playlist to play while in this level (set via inspector)
@export var song_list: AudioStreamPlaylist

func _ready() -> void:
	# Fail-safe: warn if no playlist is assigned
	assert(song_list is AudioStreamPlaylist, "There were no songs in the playlist for this level!")

	# Only change music if it's not already playing this playlist
	if not Music.is_playing_playlist(song_list):
		await Music.fade()   # Smooth fade out of current music
		Music.play(song_list)
 
