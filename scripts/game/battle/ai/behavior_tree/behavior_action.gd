extends BehaviorTreeNode
class_name BehaviorAction
## 行为动作
## 执行具体的动作

# 动作函数
var action_func: Callable = Callable()

# 初始化
func _init(func_ref = null, node_name: String = "Action"):
	super._init(node_name)
	
	if func_ref:
		action_func = func_ref

# 设置动作函数
func set_action(func_ref) -> void:
	action_func = func_ref

# 更新节点
func update(delta: float, context = null) -> int:
	# 如果没有设置动作函数，返回失败
	if not action_func.is_valid():
		status = NodeStatus.FAILURE
		return status
	
	# 执行动作函数
	var result = action_func.call(context)
	
	# 根据动作函数结果设置状态
	if result is bool:
		status = NodeStatus.SUCCESS if result else NodeStatus.FAILURE
	elif result is int and result >= 0 and result <= 2:
		status = result
	else:
		status = NodeStatus.FAILURE
	
	return status
