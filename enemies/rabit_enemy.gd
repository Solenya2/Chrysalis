class_name RabbitEnemy
extends Enemy

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgentOffset2D/NavigationAgent2D
var dodge_cooldown_timer: float = 0.0

@onready var chase_state: EnemyChaseState = (
	EnemyChaseState.new()
	.set_actor(self)
	.set_navigation_agent(nav_agent)
)

@onready var knockback_state: EnemyKnockbackState = EnemyKnockbackState.new().set_actor(self)
@onready var dodge_state: EnemyDodgeState = EnemyDodgeState.new().set_actor(self)

@onready var fsm: FSM = FSM.new().set_state(chase_state)

func _ready():
	var has_websocket := ClassDB.class_exists("WebSocketClient")
	print("WebSocketClient available: ", has_websocket)

	super()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	print("🐇 Rabbit is ready and FSM initialized")


	# Damage reaction
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		print("🐇 Rabbit got hit!")
		fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
		create_hit_particles(other_hitbox, load("res://effects/hit_particles.tscn"))
		stats.health -= other_hitbox.damage
	)

	# Return to chase after knockback
	knockback_state.finished.connect(fsm.change_state.bind(chase_state))

	# Listen for pre-attack signal from hero
	if not Events.hero_attacked.is_connected(_on_hero_attack):
		Events.hero_attacked.connect(_on_hero_attack)
		print("🐇 Rabbit connected to hero_attacked")

func _physics_process(delta: float) -> void:
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta

	fsm.state.physics_process(delta)

var last_dodge_time := 0.0
@export var dodge_cooldown := 0.0  # seconds

func _on_hero_attack(hero_pos: Vector2, hero_dir: Vector2) -> void:
	var to_rabbit := global_position - hero_pos
	var distance := to_rabbit.length()
	var angle := to_rabbit.angle_to(hero_dir)

	# ⚠️ Always dodge if too close — even if not directly in front
	if distance < 32.0:
		if fsm.state != dodge_state and dodge_cooldown_timer <= 0.0:
			var dodge_dir := get_safe_dodge_direction(hero_pos)
			fsm.change_state(dodge_state.configure(dodge_dir))
			return

	# Normal angle/distance check
	if distance < 96.0 and abs(angle) < deg_to_rad(45):
		if fsm.state != dodge_state and dodge_cooldown_timer <= 0.0:
			var dodge_dir := get_safe_dodge_direction(hero_pos)
			fsm.change_state(dodge_state.configure(dodge_dir))


func get_safe_dodge_direction(hero_pos: Vector2) -> Vector2:
	var escape_distance := 64.0  # ← How far to "look ahead" for each dodge direction
	var base_direction := (global_position - hero_pos).normalized()

	var directions = [
		base_direction,                          # Directly away
		base_direction.rotated(deg_to_rad(30)),  # Slight left
		base_direction.rotated(deg_to_rad(-30)), # Slight right
		Vector2.RIGHT.rotated(randf() * TAU)     # Random fallback
	]

	for dir in directions:
		var test_pos = global_position + dir * escape_distance
		if not is_obstructed(test_pos):
			return dir.normalized()
 
	# If all directions blocked, stil  l dodge away from player
	return base_direction
 

	return (global_position - hero_pos).normalized()  # Worst case: still dodge
func is_obstructed(pos: Vector2) -> bool:
	var params = PhysicsRayQueryParameters2D.create(global_position, pos)
	params.exclude = [self]
	var result = get_world_2d().direct_space_state.intersect_ray(params)
	return result.size() > 0
