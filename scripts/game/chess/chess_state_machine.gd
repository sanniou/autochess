extends Node
class_name ChessStateMachine
## 棋子状态机
## 管理棋子的状态切换和更新

# 状态字典
var states: Dictionary = {}

# 当前状态
var current_state: ChessState = null
var previous_state: ChessState = null

# 状态机所有者
var owner = null

# 状态变更信号
signal state_changed(old_state, new_state)

# 初始化
func _init(state_owner):
	owner = state_owner

# 注册状态
func register_state(state: ChessState) -> void:
	state.initialize(owner)
	states[state.get_name()] = state

# 设置初始状态
func set_initial_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("状态不存在: " + state_name)
		return
	
	current_state = states[state_name]
	current_state.enter()
	
	# 发送状态变更信号
	state_changed.emit("", state_name)

# 切换状态
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_error("状态不存在: " + new_state_name)
		return
	
	if current_state and current_state.get_name() == new_state_name:
		return
	
	var old_state_name = ""
	if current_state:
		old_state_name = current_state.get_name()
		current_state.exit()
	
	previous_state = current_state
	current_state = states[new_state_name]
	current_state.enter()
	
	# 发送状态变更信号
	state_changed.emit(old_state_name, new_state_name)

# 物理更新
func physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)
		
		# 检查状态转换
		var next_state = current_state.check_transitions()
		if next_state != "" and next_state != current_state.get_name():
			change_state(next_state)

# 处理输入
func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# 获取当前状态名称
func get_current_state() -> String:
	if current_state:
		return current_state.get_name()
	return ""

# 获取前一个状态名称
func get_previous_state() -> String:
	if previous_state:
		return previous_state.get_name()
	return ""

# 检查是否处于指定状态
func is_in_state(state_name: String) -> bool:
	return current_state and current_state.get_name() == state_name

# 返回到前一个状态
func return_to_previous_state() -> void:
	if previous_state:
		change_state(previous_state.get_name())
