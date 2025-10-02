extends Node2D
class_name RapEligibleNPC

# Nodes
@onready var interaction_area: Area2D      = $Interaction
@onready var rap_proximity: Area2D         = $RapProximity

# Exposed data for the battle
@export var rap_bpm: float = 92.0
@export var rap_instrumental: AudioStream

# Availability gates
@export var rap_available: bool = true   # set by RapProximity enter/exit
@export var allow_voice_trigger: bool = true  # quick on/off if you need it

var _busy := false

func _ready() -> void:
	add_to_group("RapEligible")
	# Proximity gate: only near players may trigger via voice
	if rap_proximity:
		rap_proximity.body_entered.connect(_on_prox_entered)
		rap_proximity.body_exited.connect(_on_prox_exited)

	# Manual “press C to interact” path stays as you had it
	if interaction_area and interaction_area.has_signal("interacted"):
		interaction_area.interacted.connect(_on_interacted)

func _on_prox_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		rap_available = true
		add_to_group("RapEligibleActive") # optional stricter gate

func _on_prox_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		rap_available = false
		remove_from_group("RapEligibleActive") # optional

func _on_interacted() -> void:
	if _busy:
		return
	_busy = true
	# You may want to also require proximity for manual start; your call
	Events.request_show_dialog.emit("Wanna battle?")
	await Events.dialog_finished
	Events.request_dialog_choices.emit(["Yes","No"])
	var choice_idx: int = await Events.dialog_choice_made
	if choice_idx == 0:
		Events.rap_battle_requested.emit(self)  # VoiceReceiver can also load scene directly
	else:
		_busy = false

# API used by VoiceReceiver
func get_rap_bpm() -> float: return rap_bpm
func get_rap_instrumental() -> AudioStream: return rap_instrumental
