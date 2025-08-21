class_name BossHealthBarUI
extends Control

@onready var bar: TextureProgressBar = $Bar
 
@onready var boss_name_label : Label = $BossNameLabel
var boss_name: String = "Test"

var boss_stats: Stats = null
var initialized := false

func _ready():
	visible = false  # Hide until bound
	initialized = true

	# If stats were passed in early, bind now
	if boss_stats != null:
		_bind_now()

func bind_to_boss(stats: Stats, name: String = "") -> void:
	boss_stats = stats
	boss_name = name

 

	# If already initialized, bind immediately
	if initialized:
		_bind_now()
	else:
		# Wait a frame to ensure UI nodes are ready
		await get_tree().process_frame
		_bind_now()

func _bind_now():
	if bar == null:
		push_error("BossHealthBarUI: 'bar' is null. Make sure Bar node exists.")
		return

	visible = true

	bar.max_value = 100
	bar.value = 100

	if boss_name_label != null and boss_stats != null:
		boss_name_label.text = boss_stats.get_name() if boss_name == "" else boss_name

	# Connect health updates
	if boss_stats != null:
		boss_stats.health_changed.connect(_on_health_changed)
		boss_stats.max_health_changed.connect(_on_max_health_changed)

func _on_health_changed(current_health: float) -> void:
	if boss_stats == null:
		return

	var percent := (current_health / boss_stats.max_health) * 100.0
	bar.value = clamp(percent, 0, 100)

	if percent <= 0:
		visible = false

func _on_max_health_changed(_new_max: int) -> void:
	# Recalculate based on new max
	if boss_stats != null:
		_on_health_changed(boss_stats.health)
