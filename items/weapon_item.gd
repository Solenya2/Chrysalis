# WeaponItem.gd — A basic weapon item that defines stats for melee attacks.
# Used by the player's weapon state to control animation, damage, and knockback.

class_name WeaponItem
extends Item

# Damage dealt by this weapon when it hits a target.
# NOTE: Will likely vary between 0.5 for fast daggers and 10+ for heavy weapons.
@export var damage := 1.0  # ← Tweakable per weapon type

# Knockback force applied to the enemy upon hit.
# NOTE: Works with enemy knockback states and hitbox logic.
@export var knockback := 175.0  # ← High values for heavy or dramatic attacks

# Animation to play when this weapon is used (must exist in hero's AnimationPlayer).
# Currently only "sword", but enum allows future expansion (e.g., "spear", "axe").
@export_enum("sword", "centipede", "stick") var animation: String = "sword"  # Add "centipede" here
