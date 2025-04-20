extends Node
class_name BaseStateMachine
## 通用状态机基类
## 提供统一的状态机接口和实现

# 信号
signal state_changed(old_state, new_state)

# 状态字典
var states = {}

# 当前状态
var current_state = null
var previous_state = null

# 状态机所有者
var state_owner = null

# 初始化
func _init(owner = null):
	state_owner = owner

# 注册状态
func register_state(state_name: String, state_obj) -> void:
	states[state_name] = state_obj
	
# 切换状态
func change_state(state_name: String) -> void:
	if not states.has(state_name):
		push_error("状态不存在: " + state_name)
		return
		
	previous_state = current_state
	current_state = states[state_name]
	
	# 退出前一个状态
	if previous_state != null and previous_state.has_method("exit"):
		previous_state.exit()
		
	# 进入新状态
	if current_state.has_method("enter"):
		current_state.enter()
		
	# 发送状态变更信号
	state_changed.emit(previous_state, current_state)
	
	# 同步到 StateManager
	if GameManager.state_manager != null:
		var entity_id = ""
		if state_owner != null and state_owner.has_method("get_id"):
			entity_id = state_owner.get_id()
		
		GameManager.state_manager.dispatch({
			"type": "UPDATE_ENTITY_STATE",
			"payload": {
				"entity_id": entity_id,
				"state": state_name
			}
		})

# 获取当前状态名称
func get_current_state_name() -> String:
	for state_name in states.keys():
		if states[state_name] == current_state:
			return state_name
	return ""

# 处理输入
func handle_input(event: InputEvent) -> void:
	if current_state != null and current_state.has_method("handle_input"):
		current_state.handle_input(event)

# 物理处理
func physics_process(delta: float) -> void:
	if current_state != null and current_state.has_method("physics_process"):
		current_state.physics_process(delta)

# 处理
func process(delta: float) -> void:
	if current_state != null and current_state.has_method("process"):
		current_state.process(delta)

# 获取状态
func get_state(state_name: String):
	if states.has(state_name):
		return states[state_name]
	return null

# 检查是否有状态
func has_state(state_name: String) -> bool:
	return states.has(state_name)

# 检查是否是当前状态
func is_current_state(state_name: String) -> bool:
	return current_state == get_state(state_name)

# 获取所有状态名称
func get_state_names() -> Array:
	return states.keys()

# 清除所有状态
func clear_states() -> void:
	states.clear()
	current_state = null
	previous_state = null
