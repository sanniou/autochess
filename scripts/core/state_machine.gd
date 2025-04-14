extends Node
## 状态机
## 通用状态机实现，用于管理游戏对象的状态

# 当前状态
var current_state = null

# 状态映射表 {状态名: 状态对象}
var states = {}

# 状态历史
var state_history = []

# 是否处于转换状态中
var _is_transitioning = false

# 状态变更信号
signal state_changed(old_state, new_state)

func _ready():
	# 初始化状态机
	_initialize_states()

## 初始化状态
## 子类应该重写此方法来注册状态
func _initialize_states() -> void:
	pass

## 注册状态
func register_state(state_name: String, state_obj) -> void:
	states[state_name] = state_obj

## 设置初始状态
func set_initial_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("状态不存在: " + state_name)
		return
	
	current_state = states[state_name]
	if current_state.has_method("enter"):
		current_state.enter()
	
	state_history.append(state_name)

## 切换到新状态
func change_state(state_name: String) -> void:
	if _is_transitioning:
		push_error("状态转换中，无法切换到: " + state_name)
		return
	
	if not states.has(state_name):
		push_error("状态不存在: " + state_name)
		return
	
	if current_state == states[state_name]:
		return
	
	_is_transitioning = true
	
	var old_state = current_state
	var old_state_name = _get_state_name(old_state)
	
	# 退出当前状态
	if current_state != null and current_state.has_method("exit"):
		current_state.exit()
	
	# 切换到新状态
	current_state = states[state_name]
	
	# 进入新状态
	if current_state.has_method("enter"):
		current_state.enter()
	
	# 记录状态历史
	state_history.append(state_name)
	if state_history.size() > 10:  # 限制历史记录长度
		state_history.pop_front()
	
	_is_transitioning = false
	
	# 发送状态变更信号
	state_changed.emit(old_state_name, state_name)

## 获取当前状态名
func get_current_state() -> String:
	return _get_state_name(current_state)

## 获取上一个状态名
func get_previous_state() -> String:
	if state_history.size() < 2:
		return ""
	
	return state_history[state_history.size() - 2]

## 返回上一个状态
func return_to_previous_state() -> void:
	if state_history.size() < 2:
		return
	
	var previous_state = state_history[state_history.size() - 2]
	change_state(previous_state)

## 处理输入事件
func handle_input(event) -> void:
	if current_state != null and current_state.has_method("handle_input"):
		current_state.handle_input(event)

## 物理更新
func physics_process(delta: float) -> void:
	if current_state != null and current_state.has_method("physics_process"):
		current_state.physics_process(delta)

## 普通更新
func process(delta: float) -> void:
	if current_state != null and current_state.has_method("process"):
		current_state.process(delta)

## 获取状态名
func _get_state_name(state_obj) -> String:
	if state_obj == null:
		return ""
	
	for state_name in states.keys():
		if states[state_name] == state_obj:
			return state_name
	
	return ""
