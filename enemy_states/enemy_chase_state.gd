# EnemyChaseState.gd — FSM state for enemies that chase the player using pathfinding.
# Uses NavigationAgent2D to generate paths and CharacterMover to apply movement.

class_name EnemyChaseState
extends State

# NavigationAgent used to calculate and follow path to the hero.
var navigation_agent: NavigationAgent2D : set = set_navigation_agent

# Setter to assign the navigation agent and allow chaining.
func set_navigation_agent(value: NavigationAgent2D) -> EnemyChaseState:
	navigation_agent = value
	return self

func physics_process(delta: float) -> void:
	var enemy := actor as Enemy
	var hero := MainInstances.hero as Hero
	if enemy is RabbitEnemy and enemy.dodge_cooldown_timer > 0.0:
		return

	if hero is not Hero:
		return  # Fail-safe in case hero isn’t ready or not found
	
	# Make sure the navigation map is valid before requesting a path.
	var map_rid := navigation_agent.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return
	
	# Update the agent's target to the hero's position.
	navigation_agent.target_position = hero.global_position
	
	# Get the next point on the path to move toward.
	var next_point := navigation_agent.get_next_path_position()
	var direction := enemy.global_position.direction_to(next_point)
	
	# If moving left or right, flip the sprite and play the walk animation.
	if direction.x != 0:
		enemy.animation_player.play("move")
		enemy.sprite_2d.scale.x = sign(direction.x)
	
	# Accelerate toward the target direction and apply movement.
	CharacterMover.accelerate_in_direction(enemy, direction, enemy.movement_stats, delta)
	CharacterMover.move(enemy)
