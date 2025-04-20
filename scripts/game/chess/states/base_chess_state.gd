extends Resource
class_name BaseChessState
## 棋子状态基类
## 所有棋子状态的基类，定义了状态的基本接口

# 状态拥有者
var owner = null

# 状态名称
var state_name: String = "base_state"

# 状态描述
var state_description: String = "基础状态"

# 状态数据
var state_data: Dictionary = {}

# 状态持续时间
var state_time: float = 0.0

# 初始化状态
func initialize(state_owner) -> void:
	owner = state_owner

# 进入状态
func enter() -> void:
	# 重置状态时间
	state_time = 0.0
	
	# 清空状态数据
	state_data.clear()
	
	# 记录日志
	if owner and owner.has_method("_log_debug"):
		owner._log_debug("进入状态: " + state_name)

# 退出状态
func exit() -> void:
	# 记录日志
	if owner and owner.has_method("_log_debug"):
		owner._log_debug("退出状态: " + state_name)

# 物理更新
func physics_process(delta: float) -> void:
	# 更新状态时间
	state_time += delta

# 处理输入
func handle_input(event: InputEvent) -> void:
	pass

# 获取状态名称
func get_name() -> String:
	return state_name

# 获取状态描述
func get_description() -> String:
	return state_description

# 获取状态数据
func get_state_data() -> Dictionary:
	return state_data

# 获取状态持续时间
func get_state_time() -> float:
	return state_time

# 设置状态数据
func set_state_data(key: String, value) -> void:
	state_data[key] = value

# 获取状态数据项
func get_state_data_item(key: String, default_value = null):
	return state_data.get(key, default_value)

# 清除状态数据项
func clear_state_data_item(key: String) -> void:
	if state_data.has(key):
		state_data.erase(key)

# 清除所有状态数据
func clear_all_state_data() -> void:
	state_data.clear()
