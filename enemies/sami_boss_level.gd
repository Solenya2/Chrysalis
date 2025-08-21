class_name ShamanBossLevel
extends Level

@onready var shaman: SamiBoss = $ShamanBoss
@onready var boss_health_bar: BossHealthBarUI = $CanvasLayer/BossHealthBarUI

func _ready():
	await get_tree().process_frame  # Make sure everything's ready

	if shaman == null:
		push_error("Shaman boss not found!")
		return

	if shaman.stats == null:
		push_error("Shaman has no stats assigned!")
		return

	# Assign health bar to boss directly
	shaman.set_boss_health_bar(boss_health_bar)

	# Bind stats to the bar
	boss_health_bar.bind_to_boss(shaman.stats, "Shaman")

	# (Optional) Still track death if you want to hide UI externally
	shaman.stats.health_changed.connect(_on_boss_health_changed)

func _on_boss_health_changed(current_health: float) -> void:
	if current_health <= 0:
		boss_health_bar.visible = false
