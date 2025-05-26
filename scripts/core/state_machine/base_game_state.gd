extends Node
class_name BaseGameState

var state_machine = null # Will be set by the GameStateMachine

# Called when entering the state
func on_enter(_owner_node, _params: Dictionary = {}):
	pass

# Called when exiting the state
func on_exit(_owner_node):
	pass

# Called every physics frame
func on_process_physics(_owner_node, _delta):
	pass

# Called for unhandled input
func on_process_input(_owner_node, _event):
	pass
