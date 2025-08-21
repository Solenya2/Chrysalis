# ParticleBurst.gd — One-shot particle effect for visual bursts (explosions, sparks, etc.).
# Automatically plays, sets important flags, and frees itself when finished.

class_name ParticleBurst
extends GPUParticles2D

func _ready() -> void:
	# Free the node when the particle effect finishes.
	finished.connect(queue_free)

	# Enable emission immediately on spawn.
	emitting = true

	# Explosiveness = 1 means all particles emit at once (not staggered over time).
	explosiveness = 1.0

	# One-shot mode = true so the effect doesn't loop forever.
	one_shot = true

	# Use local space for particles (they follow the parent node transform).
	local_coords = true

	# Restart ensures the particles begin playing immediately even if this node is reused.
	restart()
