extends "res://scripts/core/state_machine/base_game_state.gd"
class_name GameOverGS

# Called when entering the state
func on_enter(_owner_node, _params: Dictionary = {}):
	super.on_enter(_owner_node, _params)
	GlobalEventBus.gameflow.dispatch_event(GameFlowEvents.GameOverStateEnteredEvent.new())
	# GameManager._log_info("Dispatched GameOverStateEnteredEvent")

# Called when exiting the state
func on_exit(_owner_node):
	super.on_exit(_owner_node)
	# No specific GameOverStateExitedEvent in GameFlowEvents
	# GameManager._log_info("Exited GameOverGS")
	pass

# Called every physics frame
#func on_process_physics(_owner_node, _delta):
#	pass

# Called for unhandled input
#func on_process_input(_owner_node, _event):
#	pass
