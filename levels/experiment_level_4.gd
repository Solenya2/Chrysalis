class_name SignBossLevel
extends Level

 
@onready var boss_health_bar: BossHealthBarUI = $CanvasLayer/BossHealthBarUI
 
@onready var SignBoss: InteractSignBoss = $Signboss

func _ready() -> void:
	await get_tree().process_frame  # ensure nodes are ready

	if SignBoss == null:
		push_error("Blimbo boss not found!")
		return
	if SignBoss.stats == null:
		push_error("Blimbo has no stats assigned!")
		return
	if boss_health_bar == null:
		push_error("BossHealthBarUI not found at $CanvasLayer/BossHealthBarUI")
		return

	# 1) Hand the UI to Blimbo (so he can fade it in after the cutscene)
	SignBoss.set_boss_health_bar(boss_health_bar)

	# 2) Bind the bar to Blimbo's stats (name appears on the bar)
	boss_health_bar.bind_to_boss(SignBoss.stats, "Mr consequenses ")

	# 3) Optional: hide UI when boss dies
	if not SignBoss.stats.health_changed.is_connected(_on_boss_health_changed):
		SignBoss.stats.health_changed.connect(_on_boss_health_changed)

	# Blimbo script handles visibility: it keeps hidden pre-cutscene, fades in after evolve
	# If you want it hidden on load regardless of saved state:
	boss_health_bar.visible = false

func _on_boss_health_changed(current_health: float) -> void:
	if current_health <= 0.0 and is_instance_valid(boss_health_bar):
		boss_health_bar.visible = false
