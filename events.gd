# Events.gd — Autoloaded global signal bus
# Used to emit and listen to signals across the game without direct node references.
# Helps decouple systems like UI, camera, player, dialogue, etc.

extends Node

# Emitted when the hero takes damage (used to trigger effects, update UI, etc.)
signal hero_hurt()

# Request to change the camera's tracking target.
# Typically connects to a camera controller that follows the given RemoteTransform2D.
signal request_camera_target(new_target: RemoteTransform2D)

# Request to set camera boundaries (limits for movement).
# Sends a reference to a CameraLimits node containing limit data.
signal request_camera_limits(camera_limits: CameraLimits)

# Request a camera shake effect.
# 'amount' controls intensity; 'duration' controls how long it lasts.
signal request_camera_screenshake(amount: float, duration: float)

# Request to display a UI description (tooltip, item info, etc.).
# Used by interactables or items to show title + richtext-style description.
signal request_description(title: String, description: String)

# Request to trigger a new action, often related to combat or inventory.
# action_index and item_index let the system know what logic or visuals to update.
signal request_new_action(action_index: int, item_index: int)

# Emitted when the current action changes (e.g., switching weapons or abilities).
# Same args as above — useful for UI sync.
signal action_changed(action_index: int, item_index: int)

# Emitted when a door is entered — likely used to trigger transitions or loading.
# The door node is passed so logic like destination or animation can be accessed.
signal door_entered(door: Door)

# Request to show a dialog box.
# Uses BBCode for formatting (e.g., colored text, line breaks).
signal request_show_dialog(bbcode: String)

# Emitted when a dialog finishes — useful for resuming gameplay or triggering follow-ups.
signal dialog_finished()

signal bat_killed()

signal request_dialog_choices(options)

signal dialog_choice_made(choice_idx: int)

signal request_open_shop(shop_items)
signal shop_closed()
signal cutscene_started
signal cutscene_finished
signal cutscene_resume
signal cutscene_pause
signal request_cutscene_camera_focus(target_node: Node2D, zoom: Vector2, duration: float)
signal hero_attacked(global_pos: Vector2, direction: Vector2)
signal infected_deer_mutate
# ==== Dimensional hole → Interstice → Judge → Routing ====

# Fired by a DimensionalHole node right before we swap scenes.
# source_scene is optional but handy for breadcrumbs/return.
# Fired when the player enters a dimensional hole
signal entered_dimensional_hole()

# Fired when the Interstice scene should trigger the Judge's appearance
signal request_judgment()

# Fired when the Judge decides where to send the player
signal interstice_route_decided(scene_path: String)

# ==== Rap Battle ====

# Fired when the player asks (voice or interact) to battle an eligible NPC.
signal rap_battle_requested(npc: Node)

# Emitted when the battle scene/track is live and the count-in finished.
signal rap_battle_started(npc: Node, bpm: float)

# Turn/beat updates for HUD and logic. bar_idx is absolute within the round (0..3 if 4 beats/bar & 2 bars/turn).
signal rap_turn_changed(is_player_turn: bool, round_idx: int, bar_idx: int)

# Judge result for the player's turn (from the speech server). Includes per-component and total.
# Example payload: { "rhyme": 0.62, "onbeat": 0.71, "variety": 0.48, "complete": 0.9, "total": 0.64, "rank": "B" }
signal rap_player_scored(round_idx: int, judge: Dictionary)

# Final outcome after all rounds. You can put totals/rank/rewards in result.
signal rap_battle_ended(npc: Node, result: Dictionary)
