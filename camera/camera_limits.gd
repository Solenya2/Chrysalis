# CameraLimits.gd — Utility node for setting camera movement boundaries in a level
# This node is placed in a level scene and emits itself to set the current camera limits when ready.

class_name CameraLimits
extends Control

func _ready() -> void:
	# When the node is ready, request that the camera system uses these limits.
	# 'call_deferred' ensures this happens *after* all nodes are initialized (prevents null errors).
	Events.request_camera_limits.emit.call_deferred(self)
	
	# Hide the node itself — it’s a data container, not a visible UI element so we dont need to see anythin.
	hide()
