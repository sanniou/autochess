extends BaseStateMachine
class_name ChessStateMachine
## 棋子状态机
## 管理棋子的状态切换和更新

# 初始化
func _init(state_owner):
	super._init(state_owner)

# 注册状态
func register_state(state: ChessState) -> void:
	state.initialize(owner)
	super.register_state(state.get_name(), state)

# 物理更新
func physics_process(delta: float) -> void:
	super.physics_process(delta)

	# 检查状态转换
	if current_state and current_state.has_method("check_transitions"):
		var next_state = current_state.check_transitions()
		if next_state != "" and next_state != get_current_state_name():
			change_state(next_state)

# 处理输入
func handle_input(event: InputEvent) -> void:
	super.handle_input(event)

# 获取当前状态名称
func get_current_state() -> String:
	return get_current_state_name()

# 获取前一个状态名称
func get_previous_state() -> String:
	for state_name in states.keys():
		if states[state_name] == previous_state:
			return state_name
	return ""

# 检查是否处于指定状态
func is_in_state(state_name: String) -> bool:
	return is_current_state(state_name)

# 返回到前一个状态
func return_to_previous_state() -> void:
	var prev_state_name = get_previous_state()
	if prev_state_name != "":
		change_state(prev_state_name)
