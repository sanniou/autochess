extends Node
class_name StateMachine
## 状态机
## 用于管理对象的状态切换和更新

# 状态字典
var states = {}

# 当前状态
var current_state = null
var previous_state = null

# 状态机所有者
var state_owner = null

# 是否激活
var active = true

# 初始化
func _ready():
	# 获取所有者
	state_owner = get_parent()

	# 等待一帧，确保所有状态都已注册
	await get_tree().process_frame

	# 如果有初始状态，切换到初始状态
	if states.size() > 0 and current_state == null:
		var first_state = states.keys()[0]
		change_state(first_state)

# 物理更新
func physics_process(delta):
	if not active or current_state == null:
		return

	# 更新当前状态
	var state = states[current_state]
	if state.has("physics_process"):
		state.physics_process(delta)

# 注册状态
func register_state(state_name: String, state_dict: Dictionary) -> void:
	states[state_name] = state_dict

# 设置初始状态
func set_initial_state(state_name: String) -> void:
	if states.has(state_name):
		current_state = state_name

		# 调用进入状态回调
		var state = states[current_state]
		if state.has("enter"):
			state.enter()

# 切换状态
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_error("状态不存在: " + new_state_name)
		return

	if current_state == new_state_name:
		return

	# 调用退出状态回调
	if current_state != null and states.has(current_state):
		var state = states[current_state]
		if state.has("exit"):
			state.exit()

	# 保存前一个状态
	previous_state = current_state

	# 切换到新状态
	current_state = new_state_name

	# 调用进入状态回调
	var state = states[current_state]
	if state.has("enter"):
		state.enter()

# 获取当前状态
func get_current_state() -> String:
	return current_state

# 获取前一个状态
func get_previous_state() -> String:
	return previous_state

# 检查是否处于指定状态
func is_in_state(state_name: String) -> bool:
	return current_state == state_name

# 返回到前一个状态
func return_to_previous_state() -> void:
	if previous_state != null:
		change_state(previous_state)
