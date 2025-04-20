extends BehaviorTreeNode
class_name BehaviorSelector
## 行为选择器
## 按顺序执行子节点，直到一个成功或全部失败

# 初始化
func _init(node_name: String = "Selector"):
	super._init(node_name)

# 更新节点
func update(delta: float, context = null) -> int:
	# 如果没有子节点，返回失败
	if children.is_empty():
		status = NodeStatus.FAILURE
		return status
	
	# 按顺序执行子节点，直到一个成功或全部失败
	for child in children:
		status = child.update(delta, context)
		
		# 如果子节点成功或正在运行，返回相应状态
		if status == NodeStatus.SUCCESS or status == NodeStatus.RUNNING:
			return status
	
	# 所有子节点都失败，返回失败
	status = NodeStatus.FAILURE
	return status
