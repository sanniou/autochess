extends Node
class_name GameStateMachine

var states: Dictionary = {}
var current_state_node: BaseGameState = null
var owner_node = null # Will be set to GameManager

# Optional: Signal for state changes, useful for debugging
signal state_changed(old_state_key: Variant, new_state_key: Variant)

func _init(p_owner_node):
	self.owner_node = p_owner_node

func add_state(state_key, state_node: BaseGameState):
	states[state_key] = state_node
	state_node.state_machine = self
	add_child(state_node) # Add state nodes as children for lifecycle management

func set_initial_state(state_key, params: Dictionary = {}):
	if states.has(state_key):
		current_state_node = states[state_key]
		current_state_node.on_enter(owner_node, params)
		emit_signal("state_changed", null, state_key)
	else:
		push_error("Initial state key not found: " + str(state_key))

func change_state(new_state_key, params: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("State key not found: " + str(new_state_key))
		return

	var old_state_key = null
	if current_state_node != null:
		for key in states: # Find the key of the current state node
			if states[key] == current_state_node:
				old_state_key = key
				break
		current_state_node.on_exit(owner_node)

	current_state_node = states[new_state_key]
	current_state_node.on_enter(owner_node, params)
	
	emit_signal("state_changed", old_state_key, new_state_key)

func process_physics(delta):
	if current_state_node != null and current_state_node.has_method("on_process_physics"):
		current_state_node.on_process_physics(owner_node, delta)

func process_input(event):
	if current_state_node != null and current_state_node.has_method("on_process_input"):
		current_state_node.on_process_input(owner_node, event)
