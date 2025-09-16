extends Area2D

@export var target_group: String = "Paul"   # the group your 3 enemies are in
@export var hero_group: String = ""         # optional: put your hero in "player" and set this to "player"
@export var one_shot: bool = true

var _fired := false

func _ready() -> void:
	# Must have a CollisionShape2D and monitoring=true
	body_entered.connect(_on_body_entered)

	# Pause during cutscene, then re-check overlap when it ends (prevents “walked through while disabled”)
	if Events.has_signal("cutscene_started"):
		Events.cutscene_started.connect(func(): monitoring = false)
	if Events.has_signal("cutscene_finished"):
		Events.cutscene_finished.connect(func():
			monitoring = true
			_trigger_if_hero_inside()
		)

	# Debug: show if your group is empty at runtime
	call_deferred("_debug_groups")

func _debug_groups() -> void:
	var nodes := get_tree().get_nodes_in_group(target_group)
	if nodes.is_empty():
		push_warning("EnemyGroupActivator: no nodes found in group '%s'." % target_group)

func _on_body_entered(body: Node) -> void:
	if _fired:
		return
	if body == MainInstances.hero or (hero_group != "" and body.is_in_group(hero_group)):
		_activate()

func _trigger_if_hero_inside() -> void:
	if _fired:
		return
	var hero := MainInstances.hero
	# Works even if body_entered didn’t fire while we were disabled
	if hero and overlaps_body(hero):
		_activate()

func _activate() -> void:
	_fired = true
	var count := 0
	for n in get_tree().get_nodes_in_group(target_group):
		if n.has_method("set_active"):
			n.set_active(true)
			count += 1
	if count == 0:
		push_warning("Activator: found 0 nodes with set_active() in '%s'." % target_group)
	if one_shot:
		queue_free()
	else:
		monitoring = false
