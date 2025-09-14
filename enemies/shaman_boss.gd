class_name SamiBoss
extends Enemy

# ────────────────────────────────────────────────
# Node References
# ────────────────────────────────────────────────
@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var summon_marker: Marker2D = %SummonMarker
@onready var camera_focus: RemoteTransform2D = $CameraFocus
@onready var cutscene_player: CutscenePlayer = $"../CutscenePlayer"
@onready var cutscene_dialogbox: CutsceneDialogbox = $"/root/World/UI/VBoxContainer/CutsceneDialogbox"

var ghost_scene: PackedScene = preload("res://enemies/ghost_deer_enemy.tscn")

# ────────────────────────────────────────────────
# FSM and Statesa
# ────────────────────────────────────────────────
var fsm: FSM
var decision_state: BossDecisionState

var chase_state: State
var slam_attack_state: State
var windup_state: State
var charge_state: State
var knockback_state: State

# ────────────────────────────────────────────────
# Phase and Gameplay Variables
# ────────────────────────────────────────────────
var phase := 1
var revived := false
var is_cutscene := false
var boss_health_bar: BossHealthBarUI

 
 
var is_summoning := false
var has_summoned := false
var slam_timer := 999.0
var charge_timer := 999.0
var summon_timer := 999.0

@export var slam_cooldown := 3.0
@export var charge_cooldown := 4.5
@export var summon_cooldown := 8.0

# ────────────────────────────────────────────────
# Setup and FSM Initialization
# ────────────────────────────────────────────────
func _ready() -> void:
	_init_fsm()
	_connect_hurtbox()

func set_boss_health_bar(bar: BossHealthBarUI) -> SamiBoss:
	boss_health_bar = bar
	return self
func _init_fsm() -> void:
	fsm = FSM.new()

	# Create all states
	chase_state         = BossChaseState.new().set_actor(self).set_navigation_agent(navigation_agent_2d)
	slam_attack_state   = SamiSlamAttackState.new().set_actor(self)
	windup_state        = SamiWindUpState.new().set_actor(self)
	charge_state        = SamiChargeState.new().set_actor(self)
	knockback_state     = EnemyKnockbackState.new().set_actor(self)

	# Create and link decision state
	decision_state = BossDecisionState.new()
	decision_state.actor = self
	decision_state.fsm = fsm
	decision_state.slam_state = slam_attack_state
	decision_state.charge_state = charge_state
	decision_state.summon_state = null # You can update this later
	decision_state.chase_state = chase_state

	# Connect transitions
	chase_state.finished.connect(fsm.change_state.bind(decision_state))
	slam_attack_state.finished.connect(fsm.change_state.bind(decision_state))
	charge_state.finished.connect(fsm.change_state.bind(decision_state))
	knockback_state.finished.connect(fsm.change_state.bind(decision_state))

	# Windup leads into charge
	windup_state.set_on_finish(func():
		var hero := MainInstances.hero
		if hero:
			var dir = global_position.direction_to(hero.global_position)
			charge_state.set_direction(dir)
			fsm.change_state(charge_state)
	)

	# Start with decision state
	fsm.set_state(decision_state)

	# Animation connections
	anim.animation_finished.connect(_on_animation_finished)
	anim.animation_finished.connect(Callable(slam_attack_state, "on_slam_finished"))


func _connect_hurtbox() -> void:
	if hurtbox:
		hurtbox.hurt.connect(func(other_hitbox: Hitbox):
			stats.health -= other_hitbox.damage
			_create_hit_particles(other_hitbox)
			fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
			if stats.is_health_gone():
				_on_phase_end()
		)

# ────────────────────────────────────────────────
# Main Process Loop
# ────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if revived or is_cutscene:
		return

	# 🔧 Cooldown timers tick here
	slam_timer += delta
	charge_timer += delta
	summon_timer += delta

	# Phase 2 manual summon trigger (can be removed once summon becomes FSM-driven)
	if phase == 2:
		summon_timer -= delta
		if not is_summoning and summon_timer <= 0.0:
			_start_summon()
			return

	# Forward delta to current FSM state
	if fsm.state:
		fsm.state.physics_process(delta)


# ────────────────────────────────────────────────
# Animation Helpers (Fixed to prevent flicker)
# ────────────────────────────────────────────────
func play_walk_animation() -> void:
	var target_anim = "phase_%s_walk" % _phase_to_text()
	if anim.current_animation != target_anim:
		anim.play(target_anim)

func play_slam_animation() -> void:
	var target_anim = "phase_%s_slam" % _phase_to_text()
	if anim.current_animation != target_anim:
		anim.play(target_anim)

func _phase_to_text() -> String:
	match phase:
		1:
			return "one"
		2:
			return "two"
		3:
			return "three"
		4:
			return "four"
		_:
			return "one"

# ────────────────────────────────────────────────
# Summoning Logic
# ────────────────────────────────────────────────
func _start_summon() -> void:
	is_summoning = true
	has_summoned = false
	summon_timer = summon_cooldown
	anim.play("phase_%s_summon" % _phase_to_text())

func _on_animation_finished(name: String) -> void:
	if "summon" in name and is_summoning:
		if not has_summoned:
			_spawn_ghost()
			has_summoned = true
		is_summoning = false
		fsm.set_state(chase_state)

func _spawn_ghost():
	if summon_marker:
		var ghost = ghost_scene.instantiate()
		get_tree().current_scene.add_child(ghost)
		ghost.global_position = summon_marker.global_position

# ────────────────────────────────────────────────
# Phase Transitions & Cutscene
# ────────────────────────────────────────────────
func _on_phase_end():
	revived = true
	if boss_health_bar:
		boss_health_bar.visible = false

	match phase:
		1:
			phase = 2
			is_cutscene = true
			stats.health = stats.max_health
			stats.health_changed.emit(stats.health)

			var s0 = func():
				Events.request_camera_target.emit(camera_focus)

			var s1 = func():
				anim.play("phase_one_deaddeer")
				await anim.animation_finished

			var s2 = func():
				await cutscene_dialogbox.type_dialog("[center]No...my friend...I REFUSE IT!")

			var s3 = func():
				var hero := MainInstances.hero
				if hero:
					hero.fsm.change_state(hero.cutscene_pause_state)
				fsm.state = null

			var s4 = func():
				Events.request_camera_screenshake.emit(8.0, 0.4)
				anim.play("phase_one_collapse")
				await get_tree().process_frame

			var s5 = func():
				var tree := get_tree()
				while anim.current_animation != "phase_one_collapse" or anim.current_animation_position < 15.5:
					await tree.process_frame

				await cutscene_dialogbox.type_dialog("[center]You will pay for your crimes.")

				if boss_health_bar:
					boss_health_bar.visible = true
					boss_health_bar.modulate.a = 0.0
					var bar_tween = create_tween()
					bar_tween.tween_property(boss_health_bar, "modulate:a", 1.0, 1.5)

			var s6 = func():
				await anim.animation_finished

			var s7 = func():
				_spawn_ghost()

			var s8 = func():
				_resume_after_cutscene()

			cutscene_player.play([s0, s1, s2, s3, s4, s5, s6, s7, s8])

		2:
			# Phase 3 logic
			pass

		_:
			queue_free()

# ────────────────────────────────────────────────
# Resume Gameplay (FSM refreshed)
# ────────────────────────────────────────────────
func _resume_after_cutscene():
	is_cutscene = false
	var hero := MainInstances.hero
	if hero:
		hero.fsm.change_state(hero.move_state)
		Events.request_camera_target.emit(hero.remote_transform_2d)

	var cam := get_tree().current_scene.get_node("CharacterCamera")
	cam.zoom = Vector2.ONE

	fsm.set_state(decision_state)

	fsm.state.enter()  # Force state to re-enter and refresh animation with correct phase

	if boss_health_bar:
		boss_health_bar.visible = true

	revived = false

# ────────────────────────────────────────────────
# Miscellaneous Helpers
# ────────────────────────────────────────────────
func _create_hit_particles(other_hitbox: Hitbox):
	var p = preload("res://effects/hit_particles.tscn").instantiate()
	p.global_position = global_position
	get_tree().current_scene.add_child(p)

func is_player_in_range(distance: float) -> bool:
	var hero := MainInstances.hero
	return hero and global_position.distance_to(hero.global_position) <= distance
