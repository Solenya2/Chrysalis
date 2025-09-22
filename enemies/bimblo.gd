extends Enemy
class_name BlimboBoss

# ── Tuning ───────────────────────────────────────
@export var attack_range: float = 64.0
@export var attack_cooldown: float = 0.8

# RemoteTransform2D child used for camera focus during the evolution cutscene.
@export_node_path("RemoteTransform2D") var camera_focus_path: NodePath = NodePath("CameraFocus")

# ── States ───────────────────────────────────────
const BlimboDormantIdleState        = preload("res://bossstates/BlimboDormantIdleState.gd")
const BlimboDecisionState           = preload("res://bossstates/BlimboDecisionState.gd")
const BlimboDirectionalAttackState  = preload("res://bossstates/BlimboDirectionalAttackState.gd")
const BlimboChasePulseState         = preload("res://bossstates/BlimboChasePulseState.gd")

# ── Node refs ────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D
@onready var camera_focus: RemoteTransform2D = get_node_or_null(camera_focus_path) as RemoteTransform2D

# Injected from spawner
var boss_health_bar: BossHealthBarUI
func set_boss_health_bar(bar: BossHealthBarUI) -> BlimboBoss:
	boss_health_bar = bar
	return self

# ── FSM & states ─────────────────────────────────
var fsm: FSM
var dormant_state: BlimboDormantIdleState
var decision_state: BlimboDecisionState
var chase_state: BlimboChasePulseState
var attack_state: BlimboDirectionalAttackState
var knockback_state: EnemyKnockbackState

# ── Flags ────────────────────────────────────────
var evolved_started := false   # first hit triggers cutscene (no damage)
var evolved := false
var is_cutscene := false

func _ready() -> void:
	super()

	# Build states
	dormant_state = BlimboDormantIdleState.new().set_actor(self)

	chase_state = BlimboChasePulseState.new()
	chase_state.set_actor(self)
	chase_state.set_navigation_agent(nav_agent)

	attack_state = BlimboDirectionalAttackState.new().set_actor(self)
	attack_state.anim = anim
	attack_state.sprite = sprite

	knockback_state = EnemyKnockbackState.new().set_actor(self)

	decision_state = BlimboDecisionState.new()
	decision_state.actor = self
	decision_state.chase_state = chase_state
	decision_state.attack_state = attack_state
	decision_state.attack_range = attack_range
	decision_state.attack_cooldown = attack_cooldown

	fsm = FSM.new()
	decision_state.fsm = fsm
	fsm.set_state(dormant_state)

	# Transitions back to decision
	chase_state.finished.connect(fsm.change_state.bind(decision_state))
	attack_state.finished.connect(fsm.change_state.bind(decision_state))
	knockback_state.finished.connect(fsm.change_state.bind(decision_state))

	# Signals (guard against double connect)
	if anim and not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)
	if hurtbox and hurtbox.has_signal("hurt") and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

	# UI init
	if boss_health_bar:
		boss_health_bar.visible = false
		boss_health_bar.modulate.a = 0.0

	# Ensure we start in the dormant pose
	_apply_dormant_visual()

func _exit_tree() -> void:
	if anim and anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.disconnect(_on_animation_finished)
	if hurtbox and hurtbox.has_signal("hurt") and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)

func _physics_process(delta: float) -> void:
	if is_cutscene or fsm.state == null:
		return
	fsm.state.physics_process(delta)

# ── First hurt → evolution, otherwise normal damage ─────────────
func _on_hurt(other_hitbox: Hitbox) -> void:
	if not evolved_started:
		evolved_started = true
		_create_hit_particles(other_hitbox)
		_start_evolution_cutscene()
		return

	# Post-evolution: normal damage + knockback
	stats.health -= other_hitbox.damage
	_create_hit_particles(other_hitbox)
	fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
	if stats.is_health_gone():
		_on_boss_defeated()

# ── Evolution cutscene (robust: no hangs on bad clips) ──────────
func _start_evolution_cutscene() -> void:
	is_cutscene = true

	# Only disable hurtbox monitoring (keep layers/masks as set in Inspector)
	_set_monitoring_on("Hurtbox", false)
	fsm.state = null

	# Freeze hero + focus camera
	var hero := MainInstances.hero
	if hero:
		hero.fsm.change_state(hero.cutscene_pause_state)
	if camera_focus:
		Events.request_camera_target.emit(camera_focus)
	else:
		Events.request_cutscene_camera_focus.emit(self, Vector2(1.2, 1.2), 2.0)

	# to_egg → egg_break (safeguarded)
	await _play_and_wait("to_egg")
	await _play_and_wait("egg_break")

	# Switch to evolved visuals
	evolved = true
	_play_evolved_idle()

	# Bring up health bar
	if boss_health_bar:
		boss_health_bar.visible = true
		boss_health_bar.modulate.a = 0.0
		stats.health = stats.max_health
		stats.health_changed.emit(stats.health)
		var t = create_tween()
		t.tween_property(boss_health_bar, "modulate:a", 1.0, 1.2)

	# Return camera to hero and resume combat
	if hero:
		await get_tree().process_frame
		if hero.remote_transform_2d:
			Events.request_camera_target.emit(hero.remote_transform_2d)
		hero.fsm.change_state(hero.move_state)

	# Re-enable damage intake; leave Hitbox alone (anim drives it)
	_set_monitoring_on("Hurtbox", true)
	is_cutscene = false
	fsm.set_state(decision_state)

# ── Animation helpers ────────────────────────────────────────────
func _apply_dormant_visual() -> void:
	if sprite:
		sprite.top_level = false
		sprite.flip_h = false
		sprite.frame = 0
	if anim:
		if anim.has_animation("dormant_idle"):
			if anim.current_animation != "dormant_idle":
				anim.play("dormant_idle")
			else:
				anim.seek(0.0, true)
		elif anim.is_playing():
			anim.stop()

func _play_evolved_idle() -> void:
	if anim:
		if anim.has_animation("evolved_idle"):
			anim.play("evolved_idle")
		else:
			anim.stop()

# Optional helpers (your chase state checks these)
func play_walk_animation() -> void:
	if anim and anim.has_animation("evolved_walk") and anim.current_animation != "evolved_walk":
		anim.play("evolved_walk")

func play_idle_animation() -> void:
	_play_evolved_idle()

func _on_animation_finished(_name: StringName) -> void:
	# Attack state finishes itself; nothing global here
	pass

# Play and wait with a max time to avoid hangs if an anim is looped/misnamed
func _play_and_wait(name: String, max_time := 6.0) -> void:
	if anim and anim.has_animation(name):
		anim.play(name)
		var t := 0.0
		while anim.is_playing() and anim.current_animation == name and t < max_time:
			await get_tree().process_frame
			t += get_process_delta_time()

# (Unused if your attacks are anim-driven. Leaving empty is fine.)
func _attack_strike(_dir: Vector2) -> void:
	pass

func _attack_anim_finished() -> void:
	# Guard double transitions
	if fsm and fsm.state == attack_state:
		fsm.change_state(decision_state)

# ── Death / cleanup ──────────────────────────────────────────────
func _on_boss_defeated() -> void:
	if boss_health_bar:
		var t = create_tween()
		t.tween_property(boss_health_bar, "modulate:a", 0.0, 0.7)
		await t.finished
		boss_health_bar.visible = false
	queue_free()

# ── Small utilities ─────────────────────────────────────────────
func _set_monitoring_on(path: String, enabled: bool) -> void:
	var a := get_node_or_null(path) as Area2D
	if a:
		a.set_deferred("monitoring", enabled)

func _create_hit_particles(_other_hitbox: Hitbox):
	var p = preload("res://effects/hit_particles.tscn").instantiate()
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
