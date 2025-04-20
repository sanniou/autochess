extends RefCounted
class_name BaseState
## 基本状态类
## 提供统一的状态接口

# 状态机引用
var state_machine = null

# 状态所有者
var owner = null

# 初始化
func _init(p_state_machine = null, p_owner = null):
	state_machine = p_state_machine
	owner = p_owner

# 进入状态
func enter() -> void:
	pass

# 退出状态
func exit() -> void:
	pass

# 处理输入
func handle_input(_event: InputEvent) -> void:
	pass

# 物理处理
func physics_process(_delta: float) -> void:
	pass

# 处理
func process(_delta: float) -> void:
	pass

# 获取状态名称
func get_name() -> String:
	return "BaseState"
