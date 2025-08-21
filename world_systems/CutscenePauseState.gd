# CutscenePauseState.gd — FSM state for pausing actors during cutscenes
# Replaces AI/movement temporarily and listens for a signal to resume.
# Works on all FSM-based actors: enemies, bosses, NPCs, and even player if needed.

class_name CutscenePauseState
extends State

# External signal to resume the actor's FSM when the cutscene ends
signal resume_requested

# Optional: allow ambient animation (like idle breathing)
var allow_idle_animation := true

# Called when entering the pause state — disables AI and optionally plays idle anim
func enter() -> void:
	var actor := self.actor
	if actor == null:
		push_warning("CutscenePauseState entered with no actor set.")
		return

	# Optionally: play idle animation to avoid freeze-frame effect
	if allow_idle_animation and actor.has_node("AnimationPlayer"):
		var anim_player := actor.get_node("AnimationPlayer") as AnimationPlayer
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

	# FSM is effectively paused because we don’t emit `finished` here.
	# Instead, we wait until resume is manually triggered.
	# This means the actor stays in this state until told otherwise.

	await resume_requested  # Wait until external signal resumes us

	# Once resumed, we signal the FSM to continue
	finished.emit()

# Call this externally from CutscenePlayer (or anything) to resume actor
func resume() -> void:
	emit_signal("resume_requested")

# Optional: chaining function if you want to customize the behavior when creating the state
func set_allow_idle(value: bool) -> CutscenePauseState:
	allow_idle_animation = value
	return self
