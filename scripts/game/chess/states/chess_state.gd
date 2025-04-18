extends Resource
class_name ChessState
## 棋子状态基类
## 所有棋子状态的基类，定义了状态的基本接口

# 状态拥有者
var owner = null

# 状态名称
var state_name: String = "base_state"

# 初始化状态
func initialize(state_owner) -> void:
	owner = state_owner

# 进入状态
func enter() -> void:
	pass

# 退出状态
func exit() -> void:
	pass

# 物理更新
func physics_process(delta: float) -> void:
	pass

# 处理输入
func handle_input(event: InputEvent) -> void:
	pass

# 检查状态转换
func check_transitions() -> String:
	return ""

# 获取状态名称
func get_name() -> String:
	return state_name
