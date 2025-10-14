extends CharacterBody2D
class_name NPCMusician

# Dialog lines
@export_multiline var opening_dialog: String = "Hey there! I'm a musician. Want me to play a song for you?"
@export_multiline var playing_dialog: String = "Alright, here's a tune for you..."
@export_multiline var post_play_dialog: String = "Hope you enjoyed the music!"
@export_multiline var post_refuse_dialog: String = "Alright, maybe another time."

# Direct reference to the song file
@export var song_stream: AudioStream = preload("res://muisc_and_sounds/dadsongpreapere.mp3")

@onready var interaction: Interaction = $Interaction
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _running: bool = false

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	animation_player.play("idle")

func _on_interacted() -> void:
	if get_tree().paused or _running:
		return
	
	_run_conversation()

func _run_conversation() -> void:
	_running = true
	
	# Show initial dialog with choice
	Events.request_prompt_then_choices.emit(opening_dialog, ["Yes, play a song!", "No, thanks."])
	
	# Wait for player choice
	var choice_index: int = await Events.dialog_choice_made
	await get_tree().process_frame
	
	if choice_index == 0:  # Player said YES
		# Show "playing" message
		Events.request_show_dialog.emit(playing_dialog)
		await Events.dialog_finished
		
		# Start guitar animation on this NPC
		if animation_player:
			animation_player.play("song")
		
		# Emit signal that guitar song is starting
		Events.guitar_song_started.emit()
		
		# Fade out current music and play the song
		await Music.fade(0.75)
		Music.play(song_stream)
		
		# Wait for the full song to play (3 minutes 12 seconds = 192 seconds)
		await get_tree().create_timer(192.0).timeout
		
		# Stop guitar animation on this NPC
		if animation_player:
			animation_player.stop()
		
		# Emit signal that guitar song is ending
		Events.guitar_song_ended.emit()
		
		# Show final message
		Events.request_show_dialog.emit(post_play_dialog)
		await Events.dialog_finished
		
	else:  # Player said NO
		Events.request_show_dialog.emit(post_refuse_dialog)
		await Events.dialog_finished
	
	# Safety unpause
	if get_tree().paused:
		Events.request_close_dialog.emit()
		await get_tree().process_frame
		if get_tree().paused:
			get_tree().paused = false
	
	_running = false
