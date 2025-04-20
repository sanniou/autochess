extends Node
class_name FiniteStateMachine
## 有限状态机
## 用于管理实体的状态和状态转换

# 信号
signal state_changed(old_state, new_state)
signal state_entered(state)
signal state_exited(state)

# 状态字典 {状态名: 状态对象}
var states: Dictionary = {}

# 当前状态
var current_state = null
var previous_state = null

# 状态机所有者
#var owner = null

# 状态历史
var state_history: Array = []
var max_history_size: int = 10

# 状态转换表 {当前状态: {目标状态: 条件函数}}
var transition_table: Dictionary = {}

# 调试模式
var debug_mode: bool = false

# 初始化
func _init(p_owner = null):
	owner = p_owner

# 物理更新
func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("physics_process"):
		current_state.physics_process(delta)
	
	# 检查状态转换
	_check_transitions()

# 注册状态
func register_state(state_name: String, state) -> void:
	if state.has_method("initialize"):
		state.initialize(owner)
	
	states[state_name] = state
	
	if debug_mode:
		print("[FSM] 注册状态: " + state_name)

# 注册状态转换
func register_transition(from_state: String, to_state: String, condition_func: Callable) -> void:
	# 确保状态存在
	if not states.has(from_state):
		push_error("[FSM] 无法注册转换: 源状态不存在 " + from_state)
		return
	
	if not states.has(to_state):
		push_error("[FSM] 无法注册转换: 目标状态不存在 " + to_state)
		return
	
	# 初始化转换表
	if not transition_table.has(from_state):
		transition_table[from_state] = {}
	
	# 注册转换条件
	transition_table[from_state][to_state] = condition_func
	
	if debug_mode:
		print("[FSM] 注册转换: " + from_state + " -> " + to_state)

# 设置初始状态
func set_initial_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("[FSM] 无法设置初始状态: 状态不存在 " + state_name)
		return
	
	current_state = states[state_name]
	
	if current_state.has_method("enter"):
		current_state.enter()
	
	# 添加到历史
	_add_to_history(state_name)
	
	if debug_mode:
		print("[FSM] 设置初始状态: " + state_name)
	
	# 发送信号
	state_entered.emit(state_name)

# 切换状态
func change_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("[FSM] 无法切换状态: 状态不存在 " + state_name)
		return
	
	if current_state == states[state_name]:
		return
	
	# 保存前一个状态
	previous_state = current_state
	var previous_state_name = get_current_state_name()
	
	# 退出当前状态
	if current_state and current_state.has_method("exit"):
		current_state.exit()
		state_exited.emit(previous_state_name)
	
	# 设置新状态
	current_state = states[state_name]
	
	# 进入新状态
	if current_state.has_method("enter"):
		current_state.enter()
	
	# 添加到历史
	_add_to_history(state_name)
	
	if debug_mode:
		print("[FSM] 状态变更: " + previous_state_name + " -> " + state_name)
	
	# 发送信号
	state_changed.emit(previous_state_name, state_name)
	state_entered.emit(state_name)

# 检查状态转换
func _check_transitions() -> void:
	if not current_state:
		return
	
	var current_state_name = get_current_state_name()
	
	# 检查当前状态的转换条件
	if transition_table.has(current_state_name):
		var transitions = transition_table[current_state_name]
		
		for to_state in transitions:
			var condition = transitions[to_state]
			
			# 检查条件
			if condition.call():
				change_state(to_state)
				return

# 获取当前状态名称
func get_current_state_name() -> String:
	if not current_state:
		return ""
	
	for state_name in states:
		if states[state_name] == current_state:
			return state_name
	
	return ""

# 获取前一个状态名称
func get_previous_state_name() -> String:
	if not previous_state:
		return ""
	
	for state_name in states:
		if states[state_name] == previous_state:
			return state_name
	
	return ""

# 是否处于指定状态
func is_in_state(state_name: String) -> bool:
	return get_current_state_name() == state_name

# 添加到历史
func _add_to_history(state_name: String) -> void:
	state_history.append(state_name)
	
	# 限制历史大小
	if state_history.size() > max_history_size:
		state_history.pop_front()

# 获取状态历史
func get_state_history() -> Array:
	return state_history

# 清空历史
func clear_history() -> void:
	state_history.clear()

# 设置调试模式
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled

# 获取所有状态名称
func get_all_state_names() -> Array:
	return states.keys()

# 获取所有可能的转换
func get_all_transitions() -> Dictionary:
	return transition_table

# 重置状态机
func reset() -> void:
	# 退出当前状态
	if current_state and current_state.has_method("exit"):
		current_state.exit()
	
	# 清空状态
	current_state = null
	previous_state = null
	
	# 清空历史
	clear_history()
	
	if debug_mode:
		print("[FSM] 状态机已重置")
