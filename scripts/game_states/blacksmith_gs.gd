extends "res://scripts/core/state_machine/base_game_state.gd"
class_name BlacksmithGS

# Called when entering the state
func on_enter(_owner_node, params: Dictionary = {}):
	super.on_enter(_owner_node, params)
	GlobalEventBus.gameflow.dispatch_event(GameFlowEvents.BlacksmithStateEnteredEvent.new(params))
	# GameManager._log_info("Dispatched BlacksmithStateEnteredEvent")

# Called when exiting the state
func on_exit(_owner_node):
	super.on_exit(_owner_node)
	GlobalEventBus.gameflow.dispatch_event(GameFlowEvents.BlacksmithStateExitedEvent.new())
	# GameManager._log_info("Dispatched BlacksmithStateExitedEvent")

# Called every physics frame
#func on_process_physics(_owner_node, _delta):
#	pass

# Called for unhandled input
#func on_process_input(_owner_node, _event):
#	pass
