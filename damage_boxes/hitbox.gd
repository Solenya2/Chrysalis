# Hitbox.gd — Area2D used to detect and apply damage to Hurtbox areas.
# Attached to melee swings, projectiles, explosions, etc.

class_name Hitbox
extends Area2D

# Amount of damage this hitbox will apply when it connects.
# NOTE: Tweak this per attack/projectile/enemy.
@export var damage := 1.0  # ← placeholder, usually set per weapon/attack

# If true, the hitbox stores which targets it has already hit (prevents duplicate hits).
@export var is_storing_targets: bool = false

# Optional knockback applied to target when hit — to be interpreted by Hurtbox owner.
# NOTE: Needs to be manually set before triggering (not auto-calculated).
var knockback := Vector2.ZERO  # ← typically set by weapon swing or projectile direction

# Keeps track of which Hurtboxes were already hit (if is_storing_targets is true).
var stored_targets := []

# Emitted when a hurtbox is successfully hit.
# Used for playing VFX, sound, chaining reactions, etc.
signal hit_hurtbox(hurtbox: Hurtbox)

func _ready() -> void:
	# Connect internal callback for detecting overlaps with Hurtboxes.
	area_entered.connect(_on_hurtbox_entered)

# Clears stored_targets so this hitbox can affect the same targets again.
# Useful between attack phases or if reused from a pool.
func clear_stored_targets() -> void:
	stored_targets.clear()

# Called when an Area2D enters this hitbox — filters and handles valid hits.
func _on_hurtbox_entered(area: Area2D) -> void:
	# Ensure the collided area is a Hurtbox.
	if not area is Hurtbox:
 
		return
	
	var hurtbox := area as Hurtbox
	
	# Ignore invincible targets.
	if hurtbox.is_invincible:
		return
	
	# If storing targets, skip duplicate hits to the same hurtbox.
	if is_storing_targets and hurtbox in stored_targets:
		return
	elif is_storing_targets:
		stored_targets.append(hurtbox)
	
	# Notify other systems that a hit occurred.
	hit_hurtbox.emit(hurtbox)
	
	# Let the Hurtbox know it was hit.
	hurtbox.hurt.emit(self)
