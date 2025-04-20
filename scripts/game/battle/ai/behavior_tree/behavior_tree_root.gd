extends BehaviorTreeNode
class_name BehaviorTreeRoot
## 行为树根节点
## 行为树的入口点

# 根节点属性
var root_child = null

# 初始化
func _init(node_name: String = "Root"):
	super._init(node_name)

# 设置根子节点
func set_root(node) -> void:
	# 清空现有子节点
	clear_children()
	
	# 设置新的根子节点
	if node:
		add_child(node)
		root_child = node

# 更新行为树
func update(delta: float, context = null) -> int:
	# 如果没有根子节点，返回失败
	if not root_child:
		status = NodeStatus.FAILURE
		return status
	
	# 更新根子节点
	status = root_child.update(delta, context)
	return status
