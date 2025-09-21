extends Enemy
class_name ShopKeeper

@export var greeting: String = "want some of the good stuff?"
@export var shop_items: Array[ShopItem]
@export var anger_line: String = "HEY! You pay for that."
@export var farewell_line: String = "well fuck you too then"                     # optional line on "no thanks"
@export var buy_choice_text: String = "yea i wanna buy"
@export var no_choice_text: String = "no thanks you capatlist pig"

@onready var interaction: Interaction = $Interaction
@onready var navigation_agent_2d: NavigationAgent2D = %NavigationAgent2D
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var fsm: FSM
var idle_state: ShopIdleState
var chase_state: EnemyChaseState
var knockback_state: EnemyKnockbackState

var hostile: bool = false
var _awaiting_choice: bool = false
var _opening_shot_done: bool = false
var _opening_shot_in_progress: bool = false
var _loot_given: bool = false

func _ready() -> void:
	super()

	# --- Build states (no chained init for clearer typing) ---
	idle_state = ShopIdleState.new()
	idle_state.set_actor(self)

	chase_state = EnemyChaseState.new()
	chase_state.set_actor(self)
	chase_state.set_navigation_agent(navigation_agent_2d)

	knockback_state = EnemyKnockbackState.new()
	knockback_state.set_actor(self)

	fsm = FSM.new()
	fsm.set_state(idle_state)

	# --- Signals (idempotent) ---
	if interaction and interaction.has_signal("interacted") and not interaction.interacted.is_connected(open_shop):
		interaction.interacted.connect(open_shop)

	if hurtbox and not hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.connect(_on_hurt)

	knockback_state.finished.connect(func ():
		if hostile:
			if (not _opening_shot_done) and anim and anim.has_animation("shoot"):
				_play_opening_shot()
			else:
				fsm.change_state(chase_state)
		else:
			fsm.change_state(idle_state)
	)

	if anim and not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

	if Events and Events.has_signal("dialog_choice_made") and not Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.connect(_on_dialog_choice_made)

func _exit_tree() -> void:
	if interaction and interaction.has_signal("interacted") and interaction.interacted.is_connected(open_shop):
		interaction.interacted.disconnect(open_shop)
	if hurtbox and hurtbox.hurt.is_connected(_on_hurt):
		hurtbox.hurt.disconnect(_on_hurt)
	if anim and anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.disconnect(_on_animation_finished)
	if Events and Events.has_signal("dialog_choice_made") and Events.dialog_choice_made.is_connected(_on_dialog_choice_made):
		Events.dialog_choice_made.disconnect(_on_dialog_choice_made)

func _physics_process(delta: float) -> void:
	fsm.state.physics_process(delta)

# ----------------- INTERACTION (greeting + choices) -----------------
func open_shop() -> void:
	# Block if hostile, dead, or already waiting for a choice
	if hostile or stats.health <= 0 or _awaiting_choice:
		return

	# Show greeting and IMMEDIATELY show choices (dialog stays open)
	Events.request_show_dialog.emit(greeting)
	_awaiting_choice = true
	if Events and Events.has_signal("request_dialog_choices"):
		Events.request_dialog_choices.emit([buy_choice_text, no_choice_text])

func _on_dialog_choice_made(choice_idx: int) -> void:
	if not _awaiting_choice:
		return
	_awaiting_choice = false

	# If he aggroed or died before the player chose, ignore the choice
	if hostile or stats.health <= 0:
		return

	if choice_idx == 0:
		# "yea i wanna buy"
		Events.request_open_shop.emit(shop_items)
	else:
		# "no thanks" → defer so it isn't swallowed by the dialog close
		if farewell_line.strip_edges() != "":
			call_deferred("_show_farewell_line")

func _show_farewell_line() -> void:
	# Wait one frame so the choice UI can close before showing new text
	await get_tree().process_frame
	if not hostile and stats.health > 0 and farewell_line.strip_edges() != "":
		Events.request_show_dialog.emit(farewell_line)

# ----------------- DAMAGE / HOSTILITY / LOOT -----------------
func _on_hurt(other_hitbox: Hitbox) -> void:
	if not hostile:
		_become_hostile()

	# Standard feedback flow (like BatEnemy)
	fsm.change_state(knockback_state.set_knockback(other_hitbox.knockback))
	create_hit_particles(other_hitbox, load("res://effects/hit_particles.tscn"))
	stats.health -= other_hitbox.damage

	if stats.health <= 0:
		_grant_items_to_player()

func _become_hostile() -> void:
	hostile = true
	_awaiting_choice = false  # cancel any pending choice UI

	# HARD-DISABLE interaction so it can't fire again
	if is_instance_valid(interaction):
		if interaction.has_signal("interacted") and interaction.interacted.is_connected(open_shop):
			interaction.interacted.disconnect(open_shop)
		# disable area/collision if present
		if "monitoring" in interaction:
			interaction.set_deferred("monitoring", false)
		if "collision_layer" in interaction:
			interaction.collision_layer = 0
		if "collision_mask" in interaction:
			interaction.collision_mask = 0
		if "visible" in interaction:
			interaction.visible = false
		interaction.queue_free()

	# Close any open shop UI
	if Events and Events.has_signal("request_close_shop"):
		Events.request_close_shop.emit()

	# Anger bark
	if anger_line.strip_edges() != "":
		Events.request_show_dialog.emit(anger_line)
	# Next state is decided after knockback finishes (opening shot → chase)

func _grant_items_to_player() -> void:
	if _loot_given:
		return
	_loot_given = true

	var inv := ReferenceStash.inventory
	for s in shop_items:
		# Safely read optional `.amount` (defaults to 1 if missing)
		var amt_var = s.get("amount")        # returns null if property doesn't exist
		var amount: int = 1
		if amt_var != null:
			amount = max(1, int(amt_var))
		inv.add_item(s.item, amount)

	Events.request_show_dialog.emit("You take the shopkeeper's stock.")
	# Optional: prevent duping on reload
	# shop_items.clear()

# ----------------- OPENING SHOT (one-time) -----------------
func _play_opening_shot() -> void:
	_opening_shot_in_progress = true
	# Stand still while shooting
	fsm.change_state(idle_state)
	if anim:
		anim.play("shoot")
	else:
		_opening_shot_done = true
		_opening_shot_in_progress = false
		fsm.change_state(chase_state)

func _on_animation_finished(anim_name: StringName) -> void:
	if _opening_shot_in_progress and String(anim_name) == "shoot":
		_opening_shot_in_progress = false
		_opening_shot_done = true
		fsm.change_state(chase_state)

# Call this from AnimationPlayer ("shoot" anim) via a Call Method Track
func _opening_shot_fire() -> void:
	# Plug into your existing attack spawn here (projectile/melee/hitbox).
	# Example (replace with your own):
	# Events.request_enemy_shot.emit(self, get_tree().get_first_node_in_group("hero"))
	pass
