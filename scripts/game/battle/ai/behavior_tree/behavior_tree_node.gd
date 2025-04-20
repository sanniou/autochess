extends Resource
class_name BehaviorTreeNode
## 行为树节点基类
## 所有行为树节点的基类

# 节点状态枚举
enum NodeStatus {
	SUCCESS,  # 成功
	FAILURE,  # 失败
	RUNNING   # 运行中
}

# 节点属性
var name: String = ""
var children: Array = []
var parent = null
var status: int = NodeStatus.FAILURE

# 初始化
func _init(node_name: String = ""):
	name = node_name if not node_name.is_empty() else get_class()

# 添加子节点
func add_child(child) -> void:
	children.append(child)
	child.parent = self

# 移除子节点
func remove_child(child) -> void:
	children.erase(child)
	child.parent = null

# 清空子节点
func clear_children() -> void:
	for child in children:
		child.parent = null
	children.clear()

# 更新节点
func update(delta: float, context = null) -> int:
	# 基类不实现具体逻辑，由子类重写
	return NodeStatus.FAILURE

# 重置节点
func reset() -> void:
	status = NodeStatus.FAILURE
	
	# 重置所有子节点
	for child in children:
		child.reset()

# 获取节点名称
func get_node_name() -> String:
	return name

# 获取节点状态
func get_status() -> int:
	return status

# 获取子节点数量
func get_child_count() -> int:
	return children.size()

# 获取子节点
func get_child(index: int):
	if index >= 0 and index < children.size():
		return children[index]
	return null
