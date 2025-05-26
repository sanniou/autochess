extends "res://scripts/core/state_machine/base_game_state.gd"
class_name NoneGS

# Called when entering the state
func on_enter(_owner_node, _params: Dictionary = {}):
	super.on_enter(_owner_node, _params)
	# No specific GameFlowEvent for entering NONE state.
	# GameManager might log or handle this directly if needed.
	print("Entered NoneGS")

# Called when exiting the state
func on_exit(_owner_node):
	super.on_exit(_owner_node)
	# No specific GameFlowEvent for exiting NONE state.
	print("Exited NoneGS")

# Called every physics frame
#func on_process_physics(_owner_node, _delta):
#	pass

# Called for unhandled input
#func on_process_input(_owner_node, _event):
#	pass
