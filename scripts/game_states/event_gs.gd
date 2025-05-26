extends "res://scripts/core/state_machine/base_game_state.gd"
class_name EventGS

# Called when entering the state
func on_enter(_owner_node, params: Dictionary = {}):
	super.on_enter(_owner_node, params)
	GlobalEventBus.gameflow.dispatch_event(GameFlowEvents.EventStateEnteredEvent.new(params))
	# GameManager._log_info("Dispatched EventStateEnteredEvent")

# Called when exiting the state
func on_exit(_owner_node):
	super.on_exit(_owner_node)
	GlobalEventBus.gameflow.dispatch_event(GameFlowEvents.EventStateExitedEvent.new())
	# GameManager._log_info("Dispatched EventStateExitedEvent")

# Called every physics frame
#func on_process_physics(_owner_node, _delta):
#	pass

# Called for unhandled input
#func on_process_input(_owner_node, _event):
#	pass
