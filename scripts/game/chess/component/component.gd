extends Resource
class_name Component
## 组件基类
## 所有棋子组件的基类

# 信号
signal initialized
signal enabled
signal disabled
signal updated(delta)

# 组件属性
var owner = null  # 组件所有者
var is_enabled: bool = true  # 是否启用
var priority: int = 0  # 优先级（用于更新顺序）
var component_name: String = ""  # 组件名称
var component_id: String = ""  # 组件唯一ID

# 初始化
func _init(p_owner = null, p_name: String = ""):
	owner = p_owner
	component_name = p_name if not p_name.is_empty() else get_script().resource_path.get_file().get_basename()
	component_id = component_name + "_" + str(randi())

# 初始化组件
func initialize() -> void:
	initialized.emit()

# 启用组件
func enable() -> void:
	if not is_enabled:
		is_enabled = true
		enabled.emit()

# 禁用组件
func disable() -> void:
	if is_enabled:
		is_enabled = false
		disabled.emit()

# 更新组件
func update(delta: float) -> void:
	if is_enabled:
		_process_update(delta)
		updated.emit(delta)

# 处理更新（由子类实现）
func _process_update(delta: float) -> void:
	pass

# 获取组件名称
func get_name() -> String:
	return component_name

# 获取组件ID
func get_id() -> String:
	return component_id

# 设置所有者
func set_owner(p_owner) -> void:
	owner = p_owner

# 获取所有者
func get_owner():
	return owner

# 获取优先级
func get_priority() -> int:
	return priority

# 设置优先级
func set_priority(p_priority: int) -> void:
	priority = p_priority

# 销毁组件
func destroy() -> void:
	disable()
	owner = null
