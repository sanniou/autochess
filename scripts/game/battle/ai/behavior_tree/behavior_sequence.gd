extends BehaviorTreeNode
class_name BehaviorSequence
## 行为序列
## 按顺序执行子节点，直到一个失败或全部成功

# 初始化
func _init(node_name: String = "Sequence"):
	super._init(node_name)

# 更新节点
func update(delta: float, context = null) -> int:
	# 如果没有子节点，返回成功
	if children.is_empty():
		status = NodeStatus.SUCCESS
		return status
	
	# 按顺序执行子节点，直到一个失败或全部成功
	for child in children:
		status = child.update(delta, context)
		
		# 如果子节点失败或正在运行，返回相应状态
		if status == NodeStatus.FAILURE or status == NodeStatus.RUNNING:
			return status
	
	# 所有子节点都成功，返回成功
	status = NodeStatus.SUCCESS
	return status
