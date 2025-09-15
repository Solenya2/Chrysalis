# Hitbox.gd — Area2D used to detect and apply damage to Hurtbox areas.
class_name Hitbox
extends Area2D

@export var damage := 1.0
@export var is_storing_targets: bool = false

# NEW: mark this hit as a knockout-type hit (non-lethal; triggers KO on enemy)
@export var is_knockout: bool = false

var knockback := Vector2.ZERO
var stored_targets := []
signal hit_hurtbox(hurtbox: Hurtbox)

func _ready() -> void:
	area_entered.connect(_on_hurtbox_entered)

func clear_stored_targets() -> void:
	stored_targets.clear()

func _on_hurtbox_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox.is_invincible:
		return
	if is_storing_targets and hurtbox in stored_targets:
		return
	elif is_storing_targets:
		stored_targets.append(hurtbox)
	hit_hurtbox.emit(hurtbox)
	hurtbox.hurt.emit(self)
