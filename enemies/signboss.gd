extends BlimboBoss
class_name InteractSignBoss

@export_multiline var text_block: String = "Line 1\n\nLine 2\n\nLine 3"
@export var page_delimiter: String = "\n\n"
@export var boss_music: AudioStream = preload("res://muisc_and_sounds/signbossmusic.mp3")

@onready var interaction: Area2D = $Interaction

var interaction_complete: bool = false
var boss_fight_active: bool = false

func _ready() -> void:
	# First set up the boss functionality
	super._ready()
	
	# Then set up interaction
	if interaction and interaction.has_signal("interacted"):
		interaction.interacted.connect(_on_interacted)
	else:
		push_warning("Interaction node missing or has no 'interacted' signal.")
	
	# Start in true dormant state (not just visually)
	_enter_sign_mode()

func _enter_sign_mode() -> void:
	# Ensure we're in proper sign mode
	is_cutscene = false
	fsm.set_state(dormant_state)
	_apply_dormant_visual()
	
	# Make sure we can't take damage while in sign mode
	_set_monitoring_on("Hurtbox", false)

func _on_interacted() -> void:
	if interaction_complete:
		return
	
	# Show the dialog
	var pages: Array[String] = []
	for part in text_block.split(page_delimiter):
		var s := String(part).strip_edges()
		if s != "":
			pages.append(s)
	if pages.is_empty():
		return
	
	Events.request_show_lines.emit(pages)
	
	# Wait for dialog to complete
	await Events.dialog_finished
	
	interaction_complete = true
	_start_boss_fight()

func _start_boss_fight() -> void:
	# Start the evolution cutscene directly (bypassing the damage trigger)
	if not evolved_started:
		evolved_started = true
		boss_fight_active = true
		
		# Start boss music
		if boss_music:
			await Music.fade(0.75)
			Music.play(boss_music)
		
		_start_evolution_cutscene()

# Override the hurt method to prevent damage during sign phase
func _on_hurt(other_hitbox: Hitbox) -> void:
	# Don't take damage until the boss fight has started
	if not evolved_started:
		return
	
	# Once boss fight starts, use normal damage handling
	super._on_hurt(other_hitbox)

# Make sure we don't process physics while in sign mode
func _physics_process(delta: float) -> void:
	if not interaction_complete:
		return  # Don't run boss AI until interaction is complete
	
	# Check if hero is dead during boss fight
	if boss_fight_active and MainInstances.hero and MainInstances.hero.stats.health <= 0:
		_on_hero_died()
		return
	
	super._physics_process(delta)

# Override the boss defeated method to handle music
func _on_boss_defeated() -> void:
	boss_fight_active = false
	
	# Stop boss music when defeated
	Music.stop()
	
	# Find and restart the level music playlist
	var level_music_playlist = get_tree().current_scene.find_child("LevelMusicPlaylist", true, false)
	if level_music_playlist:
		level_music_playlist._ready()  # This will restart the level music
	
	if boss_health_bar:
		var t = create_tween()
		t.tween_property(boss_health_bar, "modulate:a", 0.0, 0.7)
		await t.finished
		boss_health_bar.visible = false
	queue_free()

# Handle hero death during boss fight
func _on_hero_died() -> void:
	boss_fight_active = false
	
	# Stop boss music
	Music.stop()
	
	# Find and restart the level music playlist
	var level_music_playlist = get_tree().current_scene.find_child("LevelMusicPlaylist", true, false)
	if level_music_playlist:
		level_music_playlist._ready()
	
	# Optional: Reset boss state if you want the fight to restart when player respawns
	# If you want the boss to remain defeated, don't reset these
	# evolved_started = false
	# interaction_complete = false
	# _enter_sign_mode()
