# MovementStats.gd — A reusable Resource that stores movement-related parameters.
# Meant to be assigned to characters (player, enemies) to define how they move.

class_name MovementStats
extends Resource

# Max movement speed in pixels/second.
# NOTE: This value is heavily tied to gameplay feel and will likely need tuning.
@export var max_speed: float = 80.0  # ← Placeholder for average walk speed

# Acceleration rate in pixels/sec² — how quickly the character reaches max speed.
# NOTE: Affects game responsiveness; tune for each character/enemy type.
@export var acceleration: float = 1000.0  # ← Very snappy; probably tuned down later

# Friction or deceleration rate in pixels/sec² — how quickly character slows down when not moving.
# NOTE: Affects sliding/stopping feel; should match gameplay genre (platformer vs tactical, etc.)
@export var friction: float = 1000.0  # ← May need balancing with acceleration for smooth motion
